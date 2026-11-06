
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

# El catálogo y las huellas se generan durante la construcción, donde hay acceso
# a Internet. Así la imagen final no depende de que se ejecuten scripts en el
# servidor de despliegue.
ARG CARD_DATA_BUILD_ID
RUN echo "Generando datos de cartas: ${CARD_DATA_BUILD_ID}" \
    && npm run catalog \
    && npm run fingerprints

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

# Datos de solo lectura generados durante la construcción.
COPY --from=builder --chown=nextjs:nodejs \
    /app/data/card-catalog.json ./data/card-catalog.json

COPY --from=builder --chown=nextjs:nodejs \
    /app/data/card-fingerprints.json ./data/card-fingerprints.json

# La caché de imágenes se guarda en un volumen independiente en producción.
RUN mkdir -p /app/data/card-images \
    && chown -R nextjs:nodejs /app/data

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
