FROM node:24-alpine

WORKDIR /app

RUN apk add --no-cache stress-ng

COPY package*.json ./

RUN npm ci --omit=dev

COPY src ./src

ENV NODE_ENV=production
ENV PORT=8080

EXPOSE 8080

CMD ["node", "src/server.js"]