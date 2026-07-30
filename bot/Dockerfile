FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

# Consent records live here. Mount a volume so they survive redeploys —
# otherwise every member has to authorize again.
VOLUME /app/data
ENV DATA_FILE=/app/data/consents.json

EXPOSE 3000
CMD ["node", "src/index.js"]
