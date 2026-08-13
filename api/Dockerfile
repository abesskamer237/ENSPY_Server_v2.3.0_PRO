FROM node:24-alpine

WORKDIR /app

COPY dist/ ./dist/
COPY package.json ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Runtime tools + directories. The named uploads volume is created by Docker
# after image build, so permissions must be repaired at container start.
RUN apk add --no-cache su-exec \
    && mkdir -p /app/logs /app/uploads \
    && chown -R node:node /app \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

USER root

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "--enable-source-maps", "./dist/index.mjs"]
