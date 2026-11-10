#!/bin/bash
# Install one Odoo 20 instance with Docker.
# Usage: run.sh <folder> [odoo_port=10012] [live_chat_port=20012]
set -e

DESTINATION=$1
PORT=${2:-10012}
CHAT=${3:-20012}
REPO=https://github.com/VNEXT-CHIPT-G8/docker-odoo
BRANCH=20.0

if [ -z "$DESTINATION" ]; then
    echo "Usage: $0 <folder> [odoo_port] [live_chat_port]" >&2
    exit 1
fi
if [ -e "$DESTINATION" ]; then
    echo "Folder '$DESTINATION' already exists, choose another name or remove it first." >&2
    exit 1
fi
for cmd in git docker; do
    command -v $cmd >/dev/null 2>&1 || { echo "'$cmd' is not installed." >&2; exit 1; }
done
if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    echo "Docker Compose is not installed." >&2
    exit 1
fi

# clone Odoo directory
git clone --depth=1 "$REPO" -b "$BRANCH" "$DESTINATION"
rm -rf "$DESTINATION/.git"

# set permission
mkdir -p "$DESTINATION/postgresql"
chmod -R 777 "$DESTINATION"

# allow more inotify watches (Linux only, avoids errors with several instances)
if [ "$(uname -s)" = "Linux" ] && [ -w /etc/sysctl.conf ]; then
    if ! grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
    fi
    sysctl -p >/dev/null || true
fi

# ports (portable sed: GNU on Linux, BSD on macOS)
sed -i.bak -e "s/10012:/$PORT:/" -e "s/20012:/$CHAT:/" "$DESTINATION/docker-compose.yml"
rm -f "$DESTINATION/docker-compose.yml.bak"

# run Odoo
$COMPOSE -f "$DESTINATION/docker-compose.yml" up -d

echo "Started Odoo 20 @ http://localhost:$PORT | Live chat port: $CHAT"
echo "Logs: $DESTINATION/etc/odoo.log"
