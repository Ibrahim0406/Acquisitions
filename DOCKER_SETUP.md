# Docker Setup for Acquasitions with Neon Database

This document explains how to run the Acquasitions application using Docker with different database configurations for development and production environments.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Development Setup (Neon Local)](#development-setup-neon-local)
- [Production Setup (Neon Cloud)](#production-setup-neon-cloud)
- [Environment Variables](#environment-variables)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project uses **two separate Docker configurations**:

1. **Development**: Uses **Neon Local** - a Docker-based proxy that creates ephemeral database branches automatically
2. **Production**: Connects directly to **Neon Cloud** database

### Architecture

#### Development (docker-compose.dev.yml)
```
┌─────────────────┐         ┌──────────────┐         ┌─────────────┐
│   Your App      │────────▶│  Neon Local  │────────▶│ Neon Cloud  │
│  (Container)    │         │   (Proxy)    │         │  Database   │
└─────────────────┘         └──────────────┘         └─────────────┘
```

#### Production (docker-compose.prod.yml)
```
┌─────────────────┐                                   ┌─────────────┐
│   Your App      │──────────────────────────────────▶│ Neon Cloud  │
│  (Container)    │          Direct Connection        │  Database   │
└─────────────────┘                                   └─────────────┘
```

---

## Prerequisites

Before you begin, ensure you have:

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installed (on Windows, make sure WSL2 is enabled)
- A [Neon account](https://console.neon.tech) with a project created
- Git (for branch-based development)

### Get Your Neon Credentials

1. Go to [Neon Console](https://console.neon.tech)
2. Select your project
3. Go to **Settings** → **General** to find:
   - `NEON_PROJECT_ID`
4. Go to **Settings** → **API Keys** to create:
   - `NEON_API_KEY`
5. Note your main branch ID (usually `main` or `br-...`)

---

## Development Setup (Neon Local)

### 1. Configure Environment Variables

Copy and edit the development environment file:

```powershell
# Windows PowerShell
Copy-Item .env.development .env
```

Edit `.env` and add your Neon credentials:

```env
NEON_API_KEY=neon_api_1a2b3c4d...
NEON_PROJECT_ID=summer-forest-12345678
PARENT_BRANCH_ID=main
DELETE_BRANCH=true
DATABASE_NAME=neondb
ARCJET_KEY=your_arcjet_key
```

### 2. Add .neon_local to .gitignore

Ensure `.neon_local/` is in your `.gitignore`:

```bash
echo ".neon_local/" >> .gitignore
```

### 3. Start Development Environment

```powershell
# Start all services (Neon Local + App)
docker-compose -f docker-compose.dev.yml up

# Or run in detached mode
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f app
```

### 4. How It Works

When you start the development environment:

1. **Neon Local container** starts and:
   - Creates an ephemeral branch from your `PARENT_BRANCH_ID`
   - Acts as a local Postgres proxy on `localhost:5432`
   - Routes queries to the ephemeral branch in Neon Cloud

2. **Your app container** starts and:
   - Connects to `postgres://neon:npg@neon-local:5432/neondb`
   - Uses hot-reload for code changes (via volume mounts)

3. When you stop the containers:
   - The ephemeral branch is automatically deleted (if `DELETE_BRANCH=true`)
   - No manual cleanup needed!

### 5. Access Your Application

- **App**: http://localhost:3000
- **Database**: `localhost:5432` (from host machine)

### 6. Run Database Migrations

```powershell
# Generate migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:generate

# Run migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Open Drizzle Studio
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

### 7. Stop Development Environment

```powershell
# Stop and remove containers
docker-compose -f docker-compose.dev.yml down

# Stop and remove volumes (clean slate)
docker-compose -f docker-compose.dev.yml down -v
```

---

## Production Setup (Neon Cloud)

### 1. Configure Production Environment Variables

Create or edit `.env.production`:

```env
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Your actual Neon Cloud connection string
DATABASE_URL=postgres://username:password@ep-xyz-123.us-east-2.aws.neon.tech/neondb?sslmode=require

ARCJET_KEY=your_production_arcjet_key
```

**⚠️ IMPORTANT**: Never commit `.env.production` to version control!

### 2. Build and Start Production Container

```powershell
# Build the production image
docker-compose -f docker-compose.prod.yml build

# Start production container
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Run Production Migrations

```powershell
# Run migrations against production database
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

### 4. Production Deployment Options

#### Option A: Using Docker Compose (Simple VPS)

Deploy to a VPS:

```bash
# On your server
git pull origin main
docker-compose -f docker-compose.prod.yml up -d --build
```

#### Option B: Using Environment Variables (Recommended)

For cloud platforms (AWS, Azure, GCP), inject secrets via environment variables:

```bash
docker run -d \
  -e NODE_ENV=production \
  -e DATABASE_URL=$DATABASE_URL \
  -e ARCJET_KEY=$ARCJET_KEY \
  -p 3000:3000 \
  your-registry/acquasitions:latest
```

#### Option C: Docker Secrets (Docker Swarm)

```bash
echo "$DATABASE_URL" | docker secret create db_url -
docker stack deploy -c docker-compose.prod.yml acquasitions
```

### 5. Monitor Production Container

```powershell
# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Check health status
docker-compose -f docker-compose.prod.yml ps

# Access container shell
docker-compose -f docker-compose.prod.yml exec app sh
```

---

## Environment Variables

### Development (.env.development)

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `NEON_API_KEY` | Your Neon API key | ✅ | - |
| `NEON_PROJECT_ID` | Your Neon project ID | ✅ | - |
| `PARENT_BRANCH_ID` | Branch to create ephemeral branches from | ❌ | `main` |
| `DELETE_BRANCH` | Auto-delete branches on container stop | ❌ | `true` |
| `DATABASE_NAME` | Database name | ❌ | `neondb` |
| `PORT` | Application port | ❌ | `3000` |
| `LOG_LEVEL` | Logging level | ❌ | `debug` |
| `ARCJET_KEY` | Arcjet API key | ✅ | - |

### Production (.env.production)

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DATABASE_URL` | Full Neon Cloud connection string | ✅ | - |
| `PORT` | Application port | ❌ | `3000` |
| `LOG_LEVEL` | Logging level | ❌ | `info` |
| `ARCJET_KEY` | Arcjet API key | ✅ | - |

---

## Common Commands

### Development

```powershell
# Start development environment
docker-compose -f docker-compose.dev.yml up

# Rebuild after dependency changes
docker-compose -f docker-compose.dev.yml up --build

# View app logs only
docker-compose -f docker-compose.dev.yml logs -f app

# View neon-local logs only
docker-compose -f docker-compose.dev.yml logs -f neon-local

# Execute commands in app container
docker-compose -f docker-compose.dev.yml exec app npm run lint

# Stop everything
docker-compose -f docker-compose.dev.yml down
```

### Production

```powershell
# Start production environment
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart app
docker-compose -f docker-compose.prod.yml restart

# Scale app (if needed)
docker-compose -f docker-compose.prod.yml up -d --scale app=3

# Stop production
docker-compose -f docker-compose.prod.yml down
```

### Switching Between Environments

```powershell
# Stop dev, start prod
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.prod.yml up -d

# Stop prod, start dev
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.dev.yml up
```

---

## Troubleshooting

### Issue: "Cannot connect to Neon Local"

**Solution**: Check if Neon Local is healthy:

```powershell
docker-compose -f docker-compose.dev.yml ps
docker-compose -f docker-compose.dev.yml logs neon-local
```

Verify your `NEON_API_KEY` and `NEON_PROJECT_ID` are correct.

### Issue: "SSL connection error" in development

**Solution**: Ensure your connection string includes `?sslmode=require`:

```
postgres://neon:npg@neon-local:5432/neondb?sslmode=require
```

### Issue: "Self-signed certificate" error (JavaScript)

If using `pg` or `postgres` libraries, add to your database configuration:

```javascript
ssl: { rejectUnauthorized: false }
```

### Issue: Port 5432 already in use

**Solution**: Stop local Postgres or change the port mapping:

```yaml
ports:
  - '5433:5432'  # Use 5433 on host instead
```

### Issue: Ephemeral branches not being deleted

**Solution**: Check Docker Desktop settings on Mac:
- Go to Settings → General
- Use **gRPC FUSE** instead of **VirtioFS**

### Issue: Migrations not running

**Solution**: Run migrations manually:

```powershell
# Development
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Production
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

### Issue: "Module not found" errors

**Solution**: Rebuild without cache:

```powershell
docker-compose -f docker-compose.dev.yml build --no-cache
```

---

## Advanced Configuration

### Persistent Branches Per Git Branch

To keep one database branch per git branch:

Edit `docker-compose.dev.yml`:

```yaml
neon-local:
  environment:
    DELETE_BRANCH: false
  volumes:
    - ./.neon_local/:/tmp/.neon_local
    - ./.git/HEAD:/tmp/.git/HEAD:ro
```

Add to `.gitignore`:

```
.neon_local/
```

### Using Neon Serverless Driver

If your app uses `@neondatabase/serverless`, configure it:

```javascript
import { neon, neonConfig } from '@neondatabase/serverless';

// Development only
if (process.env.NODE_ENV === 'development') {
  neonConfig.fetchEndpoint = 'http://neon-local:5432/sql';
  neonConfig.useSecureWebSocket = false;
  neonConfig.poolQueryViaFetch = true;
}

const sql = neon(process.env.DATABASE_URL);
```

---

## Security Best Practices

1. **Never commit** `.env`, `.env.production`, or `.env.development` to git
2. Use **Docker secrets** or cloud provider secret managers in production
3. Rotate your `NEON_API_KEY` regularly
4. Use **read-only** database users for application access when possible
5. Enable **SSL/TLS** for all database connections (`sslmode=require`)

---

## Additional Resources

- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Neon API Documentation](https://neon.com/docs/reference/api-reference)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Drizzle ORM Documentation](https://orm.drizzle.team/)

---

## Support

For issues related to:
- **Neon**: [Neon Support](https://neon.tech/docs/introduction/support)
- **Docker**: [Docker Forums](https://forums.docker.com/)
- **This App**: Open an issue on GitHub

---

**Happy Coding! 🚀**
