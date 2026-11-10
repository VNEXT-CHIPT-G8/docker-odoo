#!/bin/bash
DESTINATION=$1
PORT=$2
CHAT=$3
# clone Odoo directory
git clone --depth=1 https://github.com/VNEXT-CHIPT-G8/docker-odoo -b main $DESTINATION
rm -rf $DESTINATION/.git
# set permission
mkdir -p $DESTINATION/postgresql
sudo chmod -R 777 $DESTINATION
# config
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf); else echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf; fi
sudo sysctl -p
sed -i 's/10012/'$PORT'/g' $DESTINATION/docker-compose.yml
sed -i 's/20012/'$CHAT'/g' $DESTINATION/docker-compose.yml
# run Odoo (prefer Compose v2 plugin, fall back to legacy docker-compose)
if docker compose version >/dev/null 2>&1; then
    docker compose -f $DESTINATION/docker-compose.yml up -d
else
    docker-compose -f $DESTINATION/docker-compose.yml up -d
fi

echo 'Started Odoo 20 @ http://localhost:'$PORT' | Live chat port: '$CHAT
