# Root Dockerfile to build and run the backend explicitly
FROM node:20-alpine

# Create app dir
WORKDIR /app

# Copy root package files (to allow npm install and postinstall)
COPY package.json package-lock.json* ./

# Install root deps (this will run postinstall which installs backend deps)
RUN npm ci --omit=dev || true

# Copy entire repo
COPY . .

# Install backend production deps explicitly
WORKDIR /app/backend
RUN npm ci --only=production

# Use non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S montajati -u 1001 && \
    chown -R montajati:nodejs /app
USER montajati

WORKDIR /app/backend

# Let the platform provide PORT via env; fallback to 3002
EXPOSE 3002

CMD ["node", "official_montajati_server.js"]
