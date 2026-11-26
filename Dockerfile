# syntax=docker/dockerfile:1
# 9Router Rust (CoolLoong/9router-rs) — Railway template image.
# Upstream source is cloned at a pinned commit so the image is reproducible.
# Bump NINEROUTER_REF to move to a newer upstream build.

ARG NINEROUTER_REF=6e26df1953739470e186b974dcca55e42e7c9572

FROM node:22-bookworm-slim AS source
ARG NINEROUTER_REF
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git init -q \
    && git remote add origin https://github.com/CoolLoong/9router-rs.git \
    && (git fetch -q --depth 1 origin "$NINEROUTER_REF" || git fetch -q --depth 1 origin master) \
    && git checkout -q FETCH_HEAD \
    && rm -rf .git
# Dashboard is a Vite/React app; the Rust binary embeds dashboard/dist at compile time.
RUN npm --prefix dashboard ci --no-audit --no-fund \
    && npm --prefix dashboard run build

FROM rust:bookworm AS build
WORKDIR /app
COPY --from=source /src ./
RUN cargo build --release --locked --bin ninerouter

FROM debian:bookworm-slim
# ffmpeg: media/audio features. gosu: drop root after fixing volume ownership.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates ffmpeg gosu \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 1000 --user-group --create-home ninerouter \
    && install -d -o ninerouter -g ninerouter /app/data
COPY --from=build /app/target/release/ninerouter /usr/local/bin/9router
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV DATA_DIR=/app/data \
    PORT=20128 \
    AUTH_COOKIE_SECURE=true

EXPOSE 20128
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--host", "0.0.0.0", "--no-browser", "--log"]
