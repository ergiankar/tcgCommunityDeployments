
# syntax=docker/dockerfile:1

# 1. Dependencias
FROM node:22-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# 2. Compilación
FROM node:22-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# 3. Ejecución
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

RUN addgroup -S nodejs \
    && adduser -S nextjs -G nodejs

COPY --from=builder --chown=nextjs:nodejs \
    /app/public ./public

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/standalone ./

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/static ./.next/static

# Datos que la app lee y escribe en ejecución (catálogo de cartas, imágenes oficiales descargadas y huellas visuales).
# En producción se monta aquí un volumen: un volumen nuevo hereda el dueño de esta carpeta, así que `nextjs` puede escribir.
RUN mkdir -p /app/data     && chown nextjs:nodejs /app/data

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
