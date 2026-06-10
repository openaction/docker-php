#!/bin/sh
set -e

if [ -z "${BLACKFIRE_SERVER_ID:-}" ] || [ -z "${BLACKFIRE_SERVER_TOKEN:-}" ]; then
    echo "Blackfire agent disabled: set BLACKFIRE_SERVER_ID and BLACKFIRE_SERVER_TOKEN to enable it."
    exit 0
fi

agent_socket="${BLACKFIRE_SOCKET:-unix:///var/run/blackfire/agent.sock}"
export BLACKFIRE_SOCKET="$agent_socket"

case "$agent_socket" in
    unix://*) mkdir -p "$(dirname "${agent_socket#unix://}")" ;;
esac

export BLACKFIRE_CONFIG="${BLACKFIRE_CONFIG:-/dev/null}"
echo "Starting Blackfire agent on ${agent_socket}."
exec blackfire agent:start
