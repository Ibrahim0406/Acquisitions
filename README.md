# Acquisitions

A modern, production-ready REST API built with Express.js, featuring authentication, user management, and secure database operations with Neon PostgreSQL.

## Features

- **Authentication & Authorization** - JWT-based authentication with secure cookie management
- **User Management** - Complete CRUD operations for user profiles
- **Security First** - Helmet, CORS, Arcjet protection, and bcrypt password hashing
- **Modern Architecture** - Clean MVC structure with service layer pattern
- **Database Integration** - Drizzle ORM with Neon PostgreSQL (supports both local dev and cloud prod)
- **Docker Support** - Full Docker setup with separate dev/prod configurations
- **Developer Experience** - Hot reload, ESLint, Prettier, comprehensive logging
- **Testing Ready** - Jest configuration for unit and integration tests

## Tech Stack

- **Runtime**: Node.js (ESM)
- **Framework**: Express.js v5
- **Database**: Neon PostgreSQL with Drizzle ORM
- **Authentication**: JWT + bcrypt
- **Security**: Helmet, Arcjet, CORS
- **Validation**: Zod
- **Logging**: Winston + Morgan
- **Testing**: Jest + Supertest
- **Containerization**: Docker + Docker Compose

## Quick Start

### Prerequisites

- Node.js 18+ (for local development)
- Docker Desktop (for containerized development)
- A Neon account ([sign up here](https://console.neon.tech))

### Local Development (Without Docker)

1. Clone the repository:
\`\`\`bash
git clone https://github.com/Ibrahim0406/Acquasitions.git
cd Acquasitions
\`\`\`

2. Install dependencies:
\`\`\`bash
npm install
\`\`\`

3. Configure environment variables:
\`\`\`bash
cp .env.example .env
\`\`\`

Edit `.env` with your configuration:
\`\`\`env
NODE_ENV=development
PORT=3000
DATABASE_URL=your_neon_connection_string
ARCJET_KEY=your_arcjet_key
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d
\`\`\`

4. Run database migrations:
\`\`\`bash
npm run db:generate
npm run db:migrate
\`\`\`

5. Start the development server:
\`\`\`bash
npm run dev
\`\`\`

The API will be available at `http://localhost:3000`

### Docker Development (Recommended)

Docker development uses Neon Local for automatic ephemeral database branches.

1. Configure environment:
\`\`\`bash
cp .env.development .env
\`\`\`

Edit `.env` with your Neon credentials:
\`\`\`env
NEON_API_KEY=neon_api_1a2b3c4d...
NEON_PROJECT_ID=your-project-id
PARENT_BRANCH_ID=main
DELETE_BRANCH=true
ARCJET_KEY=your_arcjet_key
\`\`\`

2. Start the development environment:
\`\`\`bash
docker-compose -f docker-compose.dev.yml up
\`\`\`

3. Access the application:
- API: `http://localhost:3000`
- Database: `localhost:5432`

## API Endpoints

### Health Check
\`\`\`
GET /health
\`\`\`

### Authentication
\`\`\`
POST /api/auth/register    - Register new user
POST /api/auth/login       - Login user
POST /api/auth/logout      - Logout user
GET  /api/auth/me          - Get current user
\`\`\`

### Users
\`\`\`
GET    /api/users          - Get all users (admin)
GET    /api/users/:id      - Get user by ID
PUT    /api/users/:id      - Update user
DELETE /api/users/:id      - Delete user
\`\`\`

## Project Structure

\`\`\`
acquasitions/
├── src/
│   ├── config/           # Configuration files (database, logger, arcjet)
│   ├── controllers/      # Request handlers
│   ├── middleware/       # Custom middleware (auth, security)
│   ├── models/          # Database models (Drizzle schema)
│   ├── routes/          # Route definitions
│   ├── services/        # Business logic layer
│   ├── utils/           # Utility functions (JWT, cookies, formatting)
│   ├── validations/     # Zod validation schemas
│   ├── app.js           # Express app configuration
│   ├── server.js        # Server entry point
│   └── index.js         # Main entry file
├── drizzle/             # Database migrations
├── scripts/             # Shell scripts for Docker
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Dockerfile
└── package.json
\`\`\`

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm start` | Start production server |
| `npm run dev` | Start development server with hot reload |
| `npm run lint` | Run ESLint |
| `npm run lint:fix` | Fix ESLint errors |
| `npm run format` | Format code with Prettier |
| `npm run format:check` | Check code formatting |
| `npm run db:generate` | Generate database migrations |
| `npm run db:migrate` | Run database migrations |
| `npm run db:studio` | Open Drizzle Studio |
| `npm test` | Run tests |

## Environment Variables

### Development
| Variable | Description | Required |
|----------|-------------|----------|
| `NODE_ENV` | Environment mode | ✅ |
| `PORT` | Server port | ❌ (default: 3000) |
| `DATABASE_URL` | Database connection string | ✅ |
| `ARCJET_KEY` | Arcjet API key | ✅ |
| `JWT_SECRET` | JWT signing secret | ✅ |
| `JWT_EXPIRES_IN` | JWT expiration time | ❌ (default: 7d) |

### Docker Development (Neon Local)
| Variable | Description | Required |
|----------|-------------|----------|
| `NEON_API_KEY` | Neon API key | ✅ |
| `NEON_PROJECT_ID` | Neon project ID | ✅ |
| `PARENT_BRANCH_ID` | Parent branch for ephemeral branches | ❌ (default: main) |
| `DELETE_BRANCH` | Auto-delete branches on stop | ❌ (default: true) |


## Security Features

- **Helmet.js** - Security headers
- **CORS** - Cross-origin resource sharing
- **Arcjet** - Rate limiting and bot protection
- **bcrypt** - Password hashing
- **JWT** - Token-based authentication
- **HTTP-only cookies** - Secure token storage
- **Input validation** - Zod schema validation
- **SQL injection protection** - Parameterized queries via Drizzle ORM

## Database Schema

The application uses Drizzle ORM with the following schema:

### Users Table
\`\`\`sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
\`\`\`

To view the full schema:
\`\`\`bash
npm run db:studio
\`\`\`

## Testing

Run the test suite:
\`\`\`bash
npm test
\`\`\`

Run tests in watch mode:
\`\`\`bash
npm test -- --watch
\`\`\`

## Deployment

### Production with Docker

1. Configure production environment:
\`\`\`bash
cp .env.production.example .env.production
\`\`\`

2. Build and start:
\`\`\`bash
docker-compose -f docker-compose.prod.yml up -d --build
\`\`\`

3. Run migrations:
\`\`\`bash
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
\`\`\`

### Manual Deployment

1. Build the application:
\`\`\`bash
npm install --production
\`\`\`

2. Run migrations:
\`\`\`bash
npm run db:migrate
\`\`\`

3. Start the server:
\`\`\`bash
npm start
\`\`\`

### Code Style

This project uses ESLint and Prettier for code formatting. Run before committing:
\`\`\`bash
npm run lint:fix
npm run format
\`\`\`

## Troubleshooting

### Common Issues

**Port already in use**
\`\`\`bash
# Find and kill the process
lsof -ti:3000 | xargs kill -9
\`\`\`

**Database connection error**
- Verify your `DATABASE_URL` is correct
- Ensure your Neon database is active
- Check network connectivity

---
