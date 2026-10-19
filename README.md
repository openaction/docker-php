# Docker PHP base image for OpenAction projects

## Development base image

```
FROM ghcr.io/openaction/docker-php/dev
```

## Production base image

```
FROM ghcr.io/openaction/docker-php/prod
```

## CI base image

```
FROM ghcr.io/openaction/docker-php/ci:8.4
```

The CI image uses the same PHP foundation as the development image and adds the
Symfony CLI, the latest Composer 2, NVM, Node.js 22, Corepack/Yarn, Docker CLI
with Buildx and Docker Compose, and common build and automation tools. NVM is
loaded automatically by Bash and is also available explicitly:

```bash
. /etc/profile.d/nvm.sh
nvm --version
```

## Blackfire

All images include the Blackfire PHP probe and the `blackfire` CLI. The Blackfire agent starts only when server credentials are provided through environment variables.

```bash
docker run --rm -p 8080:80 \
    -e BLACKFIRE_SERVER_ID=your-server-id \
    -e BLACKFIRE_SERVER_TOKEN=your-server-token \
    -e BLACKFIRE_CLIENT_ID=your-client-id \
    -e BLACKFIRE_CLIENT_TOKEN=your-client-token \
    ghcr.io/openaction/docker-php/prod:8.4
```

`BLACKFIRE_SERVER_ID` and `BLACKFIRE_SERVER_TOKEN` enable the in-container agent. `BLACKFIRE_CLIENT_ID` and `BLACKFIRE_CLIENT_TOKEN` are used by the Blackfire CLI, for example:

```bash
docker exec <container> blackfire run php bin/console app:command
```

The default agent socket is `unix:///var/run/blackfire/agent.sock`. If you need a TCP socket, configure both sides when running the image:

```bash
docker run --rm -p 8080:80 \
    -e BLACKFIRE_SERVER_ID=your-server-id \
    -e BLACKFIRE_SERVER_TOKEN=your-server-token \
    -e BLACKFIRE_CLIENT_ID=your-client-id \
    -e BLACKFIRE_CLIENT_TOKEN=your-client-token \
    -e BLACKFIRE_SOCKET=tcp://0.0.0.0:8307 \
    -e BLACKFIRE_AGENT_SOCKET=tcp://127.0.0.1:8307 \
    ghcr.io/openaction/docker-php/prod:8.4
```

When Blackfire is configured in the development image, `pcov` is disabled at container startup because it conflicts with Blackfire. Set `BLACKFIRE_DISABLE_PCOV=0` to keep `pcov` enabled.

## Logs

Nginx and PHP-FPM write their logs on stdout, one JSON object per line, for log sinks such as Fluent Bit:

- Nginx access log: one event per request, except the requests from the container itself (healthchecks).
- Nginx error log and PHP-FPM log: warnings and errors only, converted by `conf/log-to-json.awk` into
  `{"source", "time", "level", "message"}`. PHP notices, deprecations and stack traces are dropped. The PHP-FPM
  access log and slow request traces are disabled (the slow request warning stays).
- JSON lines written by the application through PHP-FPM workers (for example Monolog on `php://stdout`) are kept
  unchanged.

Access log fields:

| Field | Value |
| --- | --- |
| `source` | `nginx` (`php-fpm` for PHP-FPM events) |
| `time` | ISO 8601 timestamp |
| `host` | Requested hostname |
| `client_ip` | `CF-Connecting-IP` header |
| `proxy_ip` | `X-Real-IP` header |
| `method`, `path`, `query` | Request method, original path and query string |
| `status`, `bytes_sent` | Response status and bytes sent, headers included |
| `ttfb_ms` | Time to first byte in ms, see below |
| `referer`, `user_agent` | Request headers |
| `app_route`, `app_time` | `X-App-Route` and `X-App-Time` response headers of the application |
| `current_user_type`, `current_user_id` | `X-Current-User-Type` and `X-Current-User-Id` response headers |

The `X-App-*` and `X-Current-User-*` headers are logged and removed from the response. `ttfb_ms` is the time
between the reception of the request by nginx and the sending of the response headers to the client: nginx
evaluates `$request_time` in the `X-Response-Time` response header when it sends the headers, and the access log
converts this header to milliseconds. It is neither the total request time nor the upstream header time.
