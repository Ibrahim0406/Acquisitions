# Base stage - shared across all environments
FROM node:20-alpine AS base
WORKDIR /app

# Install dependencies stage
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --only=production && \
    cp -R node_modules /tmp/node_modules_prod && \
    npm ci

# Development stage
FROM base AS development
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build stage - prepare for production
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Run migrations in production will be handled at runtime
RUN npm run db:generate || true

# Production stage
FROM base AS production
ENV NODE_ENV=production
COPY --from=deps /tmp/node_modules_prod ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/package.json ./
COPY --from=builder /app/drizzle.config.js ./
EXPOSE 3000
CMD ["npm", "start"]
