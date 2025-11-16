FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Use npm install instead of npm ci
RUN npm install --only=production

# Create non-root user
RUN addgroup -g 1001 -S appuser && adduser -S appuser -u 1001

# Copy app code with proper ownership
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8081

ENV NODE_ENV=production
ENV PORT=8081
CMD ["npm", "start"]