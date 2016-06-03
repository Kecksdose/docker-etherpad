DOCKER ETHERPAD
===============

# Introduction
This is a Docker image which is nothing more than the basic test Etherpad setup
as described on https://github.com/ether/etherpad-lite.

# Quick start
To download the image from the Docker index, run:

```bash
docker pull moss/docker-etherpad
```

First, initialize a mysql container:

```bash
docker run -d -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=etherpad \
    -e MYSQL_USER=etherpaduser -e MYSQL_ROOT_PASSWORD=mysecret \
    --name ep_mysql mysql
```

Then, to run Etherpad on port 9001, run:

```bash
docker run -d --name=ep_moss --link=ep_mysql:mysql -p 9001:9001 \
    moss/etherpad
```

To run Etherpad on port 80, run:

```bash
docker run -d --name=ep_moss --link=ep_mysql:mysql -p 80:9001 moss/etherpad
```

# Customize with Environment Variables

To edit the Etherpad settings, you can use some environment variables.

`EP_TITLE`

String for your etherpad title (Default: Etherpad)

`EP_PORT`

Port to run your etherpad service **INSIDE THE CONTAINER** (Default: 9001)

`ADMIN_PASS`

Password for your admin user (Default: admin)

`FAVICON_URL`

Favicon url to show in your etherpad (Default: ./favicon.ico)

`DEBUG_ENTRYPOINT`

To debug what is happening on start, set this true. (Default: false)

# Volume

To persiste with `etherpad.log` you can use the `/data` volume.

### Example
```bash
docker run --rm --name=ep_moss --link=ep_mysql:mysql -v /srv/ether/:/data \
    -e EP_TITLE="YOUR TITLE" -e ADMIN_PASS=password \
    -e FAVICON_URL="http://www.google.com/s2/favicons?domain=www.google.com" \
    -e EP_PORT=9002 -p 9001:9002 moss/etherpad
```

# External database
For external database we have this environments variables:

`DB_HOST`

Host for your external database.

`DB_PORT`

Port for your external database.

`DB_NAME`

External database name.

`DB_USER`

External database user.

`DB_PASS`

External database password.


# Abiword enable

To use advanced import/export install abiword. For it, create a `Dockerfile`
with:

```bash
FROM moss/etherpad

RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    abiword \
    && rm -rf /var/lib/apt/lists/*
```

Execute a new build:

```bash
docker build -t <YOUR NAME>/etherpad .
```

And use `ABIWORD=true` on your run.


```bash
docker run --rm --name=moss_ether --link=ep_mysql:mysql -v /srv/ether/:/data \
    -e EP_TITLE="YOUR TITLE" -e ADMIN_PASS=password \
    -e FAVICON_URL="http://www.google.com/s2/favicons?domain=www.google.com" \
    -e ABIWORD=true -p 9001:9001 <yourname>/etherpad
```
