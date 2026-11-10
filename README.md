# Quick install

Installing Odoo 20 with one command.

(Supports multiple Odoo instances on one server)

Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/) yourself, then run:
``` bash
sudo apt update && apt upgrade
sudo apt install docker docker-compose -y
```
Upgrade docker-compose
``` bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.14.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version
```



Then
``` bash
curl -s https://raw.githubusercontent.com/VNEXT-CHIPT-G8/docker-odoo/main/run.sh | sudo bash -s odoo-one 10012 20012
```

to set up first Odoo instance @ `localhost:10012` (default master password: `Masterpass`)

and

``` bash
curl -s https://raw.githubusercontent.com/VNEXT-CHIPT-G8/docker-odoo/main/run.sh | sudo bash -s odoo-two 11012 21012
```

to set up another Odoo instance @ `localhost:11012` (default master password: `Masterpass`)

Some arguments:
* First argument (**odoo-one**): Odoo deploy folder
* Second argument (**10012**): Odoo port
* Third argument (**20012**): live chat port

If `curl` is not found, install it:

``` bash
$ sudo apt-get install curl
# or
$ sudo yum install curl
```

# Usage

Start the container:
``` sh
docker-compose up
```

* Then open `localhost:10012` to access Odoo 20.0. If you want to start the server with a different port, change **10012** to another value in **docker-compose.yml**:

```
ports:
 - "10012:8069"
```

Run Odoo container in detached mode (be able to close terminal without stopping Odoo):

```
docker-compose up -d
```

**If you get the permission issue**, change the folder permission to make sure that the container is able to access the directory:

``` sh
$ git clone https://github.com/VNEXT-CHIPT-G8/docker-odoo
$ sudo chmod -R 777 addons
$ sudo chmod -R 777 etc
$ mkdir -p postgresql
$ sudo chmod -R 777 postgresql
```

Increase maximum number of files watching from 8192 (default) to **524288**. In order to avoid error when we run multiple Odoo instances. This is an *optional step*. These commands are for Ubuntu user:

```
$ if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf); else echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf; fi
$ sudo sysctl -p    # apply new config immediately
```

# Custom addons, Enterprise & third-party apps

```
addons/
├── enterprise/        # Odoo Enterprise 20.0 modules (git-ignored, licensed)
├── third-party/       # 3rd-party apps (Odoo Apps Store, OCA, vendors...)
│   ├── some_module/   #   - flat: module folders directly here
│   └── oca-web/       #   - or one sub-folder per git repo (cloned as-is)
└── my_module/         # your custom addons (addons/ root, as before)
```

`etc/odoo.conf` already loads them in this order:

```
addons_path = /mnt/extra-addons/enterprise,/mnt/extra-addons/third-party,/mnt/extra-addons/third-party/*,/mnt/extra-addons
```

Empty folders are skipped with a warning, so the stack runs fine with Community only.

## Odoo Enterprise

Requires a valid Odoo Enterprise subscription.

1. Get the **20.0** enterprise source (same version as the `odoo:20.0` image):
   * partners / customers with GitHub access: `git clone --depth=1 -b 20.0 git@github.com:odoo/enterprise.git /tmp/enterprise`
   * or download the *Enterprise source (tgz)* from https://www.odoo.com/page/download (log in with the subscription account) and extract it.
2. Copy the **module folders** (`web_enterprise`, `account_accountant`, ...) directly into `addons/enterprise/`:
   ``` bash
   cp -r /tmp/enterprise/* addons/enterprise/
   sudo chmod -R 777 addons
   ```
   `addons/enterprise/web_enterprise/__manifest__.py` must exist (no extra nesting level).
3. Restart and update the app list, then install `web_enterprise` (new database: install any app, Enterprise UI is used automatically):
   ``` bash
   docker compose restart odoo
   ```
4. Register the subscription code in *Settings → General Settings → Odoo Enterprise Subscription*.

Upgrading an existing Community database to Enterprise: install the `web_enterprise` module (*Apps → remove the "Apps" filter → search `web_enterprise`*).

## Third-party apps

1. Put the app into `addons/third-party/`:
   * Odoo Apps Store zip → extract so that `addons/third-party/<module>/__manifest__.py` exists.
   * Git repo with many modules (e.g. OCA) → clone the whole repo as a sub-folder, it is picked up by `third-party/*`:
     ``` bash
     git clone --depth=1 -b 20.0 https://github.com/OCA/web.git addons/third-party/oca-web
     ```
2. Make sure the app version is **20.0** (`"version": "20.0.x.y.z"` in `__manifest__.py`) and its dependencies (other modules) are also present.
3. Python dependencies (listed in `external_dependencies` of `__manifest__.py`): add them to `etc/requirements.txt` and uncomment this line in `docker-compose.yml` so they are installed at startup:
   ```
   - ./entrypoint.sh:/entrypoint.sh
   ```
4. Restart, then *Settings → Activate developer mode → Apps → Update Apps List* and install:
   ``` bash
   docker compose restart odoo
   # or install / upgrade from the command line
   docker compose exec odoo odoo --db_host db --db_user odoo --db_password odoo -d <db_name> -i <module_name> --stop-after-init --no-http
   docker compose restart odoo
   ```

Add an extra folder (e.g. another vendor) by appending its container path to `addons_path` in `etc/odoo.conf`.

# Odoo configuration & log

* To change Odoo configuration, edit file: **etc/odoo.conf**.
* Log file: **etc/odoo-server.log**
* Default database password (**admin_passwd**) is `Masterpass`, please change it @ [etc/odoo.conf#L55](/etc/odoo.conf#L55)

# Odoo container management

**Run Odoo**:

``` bash
docker-compose up -d
```

**Restart Odoo**:

``` bash
docker-compose restart
```

**Stop Odoo**:

``` bash
docker-compose down
```
**Upgrade pip and install lib paramiko**:
``` bash

pip install --upgrade pip

#install setuptools.

pip install setuptools==39.1.0

#install pyparser.

pip install pyparser==1.0
pip install pyparsing==2.1.0

#install cffi.

pip install cffi==1.11.5

#install cryptography.

pip install cryptography==2.2.2
pip install paramiko

```



**Docker commit**:

``` bash
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
```
**Docker push**:

``` bash
docker push [OPTIONS] NAME[:TAG]

docker docker push thaichikma/image
```
**Docker save**:

``` bash
docker save [OPTIONS] IMAGE [IMAGE...]

docker save image > image.zip
```
**Docker Load**:

``` bash
docker load [OPTIONS]

docker load < image.zip
```

More info: https://docs.docker.com/engine/reference/commandline/inspect/
# Examples:
$ **docker ps**

``` bash
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS              NAMES
c3f279d17e0a        ubuntu:12.04        /bin/bash           7 days ago          Up 25 hours                            desperate_dubinsky
197387f1b436        ubuntu:12.04        /bin/bash           7 days ago          Up 25 hours                            focused_hamilton
```
**docker commit c3f279d17e0a  svendowideit/testimage:version3**
``` bas
f5283438590d
```
$ **docker images**

``` bas
REPOSITORY                        TAG                 ID                  CREATED             SIZE
svendowideit/testimage            version3            f5283438590d        16 seconds ago      335.7 MB
```

# Live chat

In [docker-compose.yml](docker-compose.yml), we exposed port **20012** (container port 8072, `gevent_port`) for live-chat / websocket on host.

Since Odoo 16+, live chat & bus use **websocket** at `/websocket` (the old `/longpolling/` route is gone). Configuring **nginx** (in production, with `workers > 0`):

``` conf
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    #...
    location /websocket {
        proxy_pass http://127.0.0.1:20012;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
    }
    #...
}
```
# **Docker Portainer**
* Install
``` bas
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```
# docker-compose.yml

* odoo:20.0 (Ubuntu noble, Python 3.12)
* pgvector/pgvector:pg17 (PostgreSQL 17 + `vector` extension; Odoo 20 requires PostgreSQL >= 16, and the **AI** apps need pgvector for embeddings)

Check pgvector is available:

``` bash
docker compose exec db psql -U odoo -d postgres -c "SELECT name, default_version FROM pg_available_extensions WHERE name = 'vector';"
```

The `odoo` DB user is a superuser, so Odoo can run `CREATE EXTENSION vector` itself when the AI module is installed. To enable it manually on a database: `CREATE EXTENSION IF NOT EXISTS vector;`

# Upgrading from an older version of this repo (Odoo 16 / postgres:15)

> Restore steps below work the same with the `pgvector/pgvector:pg17` image.

* The `./postgresql` data folder created by postgres:15 **cannot** be opened by PostgreSQL 17. Dump it first with the old stack, then restore into the new one:

``` bash
# with the OLD stack still running (postgres:15)
docker compose exec db pg_dumpall -U odoo > backup.sql
docker compose down
mv postgresql postgresql-pg15 && mkdir postgresql && sudo chmod -R 777 postgresql
# switch to this version, then
docker compose up -d db
cat backup.sql | docker compose exec -T db psql -U odoo -d postgres
docker compose up -d
```

* An Odoo 16 database is **not** usable directly by Odoo 20: it must be migrated (Odoo upgrade service or OpenUpgrade). Custom addons in `addons/` must be ported to Odoo 20.
* Extra Python packages in `etc/requirements.txt` are installed with `pip --break-system-packages` (PEP 668 on Ubuntu noble) when `entrypoint.sh` is mounted.

