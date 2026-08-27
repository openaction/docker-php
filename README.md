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
