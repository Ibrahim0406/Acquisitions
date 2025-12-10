# Docker Setup Quick Reference

## 🚀 Quick Start

### Development (with Neon Local)

1. **Copy environment file**:
   ```powershell
   Copy-Item .env.development .env
   ```

2. **Edit `.env`** with your Neon credentials:
   - `NEON_API_KEY` - Get from [Neon Console](https://console.neon.tech) → Settings → API Keys
   - `NEON_PROJECT_ID` - Get from Neon Console → Settings → General
   - `ARCJET_KEY` - Your Arcjet API key

3. **Start development environment**:
   ```powershell
   # Using the quick start script
   .\start-dev.ps1

   # Or manually
   docker-compose -f docker-compose.dev.yml up
   ```

4. **Access your app**: http://localhost:3000

### Production (with Neon Cloud)

1. **Edit `.env.production`** with your production credentials:
   - `DATABASE_URL` - Your Neon Cloud connection string
   - `ARCJET_KEY` - Your production Arcjet key

2. **Start production environment**:
   ```powershell
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 📚 Full Documentation

See **[DOCKER_SETUP.md](./DOCKER_SETUP.md)** for complete documentation including:

- Architecture diagrams
- Detailed setup instructions
- Environment variable reference
- Troubleshooting guide
- Advanced configuration options
- Production deployment strategies

## 🏗️ Files Created

```
📦 Acquasitions/
├── 🐳 Dockerfile                 # Multi-stage build for dev & prod
├── 🐳 docker-compose.dev.yml     # Development with Neon Local
├── 🐳 docker-compose.prod.yml    # Production with Neon Cloud
├── ⚙️  .env.development           # Dev environment template
├── ⚙️  .env.production            # Prod environment template
├── 🚫 .dockerignore              # Docker build exclusions
├── 📜 start-dev.ps1              # Quick start script (Windows)
├── 📖 DOCKER_SETUP.md            # Full documentation
└── 📖 README_DOCKER.md           # This file
```

## 🔑 Key Features

✅ **Ephemeral database branches** for dev (auto-created/deleted)  
✅ **Hot reload** in development with volume mounts  
✅ **Production-optimized** builds with multi-stage Dockerfile  
✅ **Separate configurations** for dev vs prod  
✅ **Health checks** for all services  
✅ **Git branch integration** for persistent branches per feature  

## 🛠️ Common Commands

```powershell
# Development
docker-compose -f docker-compose.dev.yml up              # Start dev
docker-compose -f docker-compose.dev.yml logs -f app     # View logs
docker-compose -f docker-compose.dev.yml down            # Stop dev

# Production
docker-compose -f docker-compose.prod.yml up -d          # Start prod
docker-compose -f docker-compose.prod.yml logs -f        # View logs
docker-compose -f docker-compose.prod.yml down           # Stop prod

# Database
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate   # Run migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:studio    # Open Drizzle Studio
```

## 🔐 Security Notes

- **Never commit** `.env`, `.env.production`, or `.env.development` to Git
- Use secrets managers (AWS Secrets Manager, Azure Key Vault, etc.) in production
- The `.gitignore` has been updated to exclude all sensitive files

## 📞 Support

For issues, see the [Troubleshooting section](./DOCKER_SETUP.md#troubleshooting) in the full documentation.

---

**Made with ❤️ for modern development workflows**
