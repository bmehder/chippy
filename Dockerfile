FROM ghcr.io/gleam-lang/gleam:v1.18.1-erlang-alpine AS build

WORKDIR /app
COPY gleam.toml manifest.toml ./
RUN gleam deps download
COPY src ./src
COPY assets/reference/docs_config.js ./assets/reference/docs_config.js
RUN gleam docs build --target erlang \
    && cp assets/reference/docs_config.js build/dev/docs/chippy/docs_config.js \
    && gleam export erlang-shipment

FROM erlang:29-alpine AS runtime

RUN addgroup -S chippy && adduser -S chippy -G chippy
WORKDIR /app
COPY --from=build --chown=chippy:chippy /app/build/erlang-shipment ./
COPY --from=build --chown=chippy:chippy /app/build/dev/docs/chippy ./reference
COPY --chown=chippy:chippy assets ./assets
COPY --chown=chippy:chippy routes ./routes
COPY --chown=chippy:chippy site.toml ./site.toml

ENV HOST=0.0.0.0 \
    PORT=8000

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --spider http://127.0.0.1:${PORT}/ || exit 1

USER chippy
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
CMD ["run"]
