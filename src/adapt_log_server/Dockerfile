# Build a partir da raiz do monorepo: docker build -f src/adapt_log_server/Dockerfile .
FROM dart:stable AS build
WORKDIR /app
COPY src/adapt_log ./src/adapt_log
COPY src/adapt_log_remote_protocol ./src/adapt_log_remote_protocol
COPY src/adapt_log_server ./src/adapt_log_server
WORKDIR /app/src/adapt_log_server
RUN dart pub get && dart compile exe bin/adapt_log_server.dart -o /app/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/server /usr/local/bin/adapt_log_server
ENV PORT=8080 HOST=0.0.0.0 ADAPT_LOG_DB=/data/adapt_log.sqlite
VOLUME /data
EXPOSE 8080
CMD ["adapt_log_server"]
