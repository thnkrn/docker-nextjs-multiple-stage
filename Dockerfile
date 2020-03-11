# Base stage
# Using node as base
FROM node:12.16-alpine AS base

# Creating directory by adding permission on read/write
WORKDIR /opt/app

COPY ./package*.json ./

# install node_modules by looking the version in packacge lock for only prod dependencies
RUN npm ci --only=production && npm cache clean --force


# Dev stage
# Using image from base as dev
FROM base AS development

# Setting ENV
ENV NODE_ENV=development
ENV PATH=/opt/app/node_modules/.bin:$PATH

# install only dev dependencies
RUN npm install --only=development

# Expose at port 9229
EXPOSE 9229
# Run CMD For dev mode
CMD ["nodemon", "--watch", "./server.js", "--exec", "node", "./server.js", "--inspect=0.0.0.0.9929"]


# Test Stage
# Using image from base as test
FROM base AS test


ENV NODE_ENV=testing
ENV PATH=/opt/app/node_modules/.bin:$PATH

COPY ./ ./

RUN npm install --only=development

# Run CMD For testing
RUN npm run test


# Builder stage
# Using image from base as builder
FROM base AS builder

ENV NODE_ENV=production
ENV PATH=/opt/app/node_modules/.bin:$PATH

COPY ./ ./

RUN npm install --only=development

RUN npm run build


# Production stage
# Using image from base as production
FROM base AS production

ENV NODE_ENV=production
ENV PATH=/opt/app/node_modules/.bin:$PATH

# Copy .next and server.js from builder
COPY --from=builder /opt/app/.next ./.next
COPY --from=builder /opt/app/server.js ./

# Expose at port 8000
EXPOSE 8000
# Run CMD for start on production
CMD ["node", "./server.js"]