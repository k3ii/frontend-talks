---
theme: seriph
background: https://source.unsplash.com/collection/94734566/1920x1080
class: text-center
highlighter: shiki
lineNumbers: false
info: |
  ## Slidev Starter Template
  Presentation slides for developers.

  Learn more at [Sli.dev](https://sli.dev)
drawings:
  persist: false
transition: slide-left
title: Best Practices for containerizing a NodeJS Application
mdc: true
---

# Containerzing a Nodejs App

Best practice for dockerfile


<!--
The last comment block of each slide will be treated as slide notes. It will be visible and editable in Presenter Mode along with the slide. [Read more in the docs](https://sli.dev/guide/syntax.html#notes)
-->
---
theme: default
layout: center
---
# Jain Ramchurn

Linux and Open-source enthusiast

Platform Engineer at Ringier South Africa

Admin of Linux Mirrors in Mauritius

🌐 zain.mu

🐦 EdogawaZain 

---
theme: default
layout: center
---
# server.js

```js {all}
const express = require('express');
const app = express();
const port = 8080;

app.get('/', (_, res) => {
  res.send('Hello World!');
})

app.listen(port, () => {
  console.log(`Listening on port ${port}`);
})
```

<style>
.slidev-layout code {
  font-size: 1.9em;
  line-height: 1.1em;
}
</style>

<!--
The code import the Express module and create an express application. 
This app starts a server and listens on port 8080 for connections. 
The app responds with “Hello World!” for requests to the root URL (/) or route.
-->
---
theme: default
layout: center
---
# Directory Structure

``` 
.git
.gitignore
.README.md
node_modules
package.json
package-lock.json
server.js
```
<style>
.slidev-layout code {
  font-size: 1.9em;
  line-height: 1.1em;
}
</style>
---
layout: center
---

# DockerFile

```dockerfile
FROM node:20

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies and bundle app source
COPY . .

RUN npm ci
EXPOSE 8080
CMD ["node", "server.js"]
```
<!--
The containerfile:

uses the node image version 20,

copies all the files from the current directory into the image directory /usr/src/app,

run npm ci which a clean install of of the dependencies,

expose the port 8080 and run the app.

This command npm-ci is similar to npm install, except it’s meant to be used in automated environments such as test platforms, continuous integration, and deployment.
-->

---
layout: center
---

# .dockerignore

```dockerfile
.git
.gitignore
README.md
node_modules
```
<!--
This will prevent your local modules and debug logs from being copied onto your Docker image and thus increasing the size of the image. 
-->

---
layout: center
---

# Seperating modules and app code

```dockerfile {7,11|all}
FROM node:20

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies 
COPY packages*.json .

RUN npm ci

COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
```
<!--
One main reasons to seperate modules, packages, and source code is to take advantage of  caching efficiency.

Caching efficiency When building a Docker image, each step in the Dockerfile creates a new layer. These layers are cached by Docker, and if a layer remains unchanged between builds, Docker can reuse it from the cache. By separating the installation of app dependencies (usually managed through package.json) from the actual application code, you can take advantage of Docker’s layer caching. This way, only changes in the application code will result in rebuilding the layers that follow, making the build process more efficient.
-->
---
layout: center
---

# Run as non-root user

```dockerfile {2,8,12|all}
FROM node:20
USER node

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies 
COPY --chown=node:node packages*.json .

RUN npm ci

COPY --chown=node:node server.js .
EXPOSE 8080
CMD ["node", "server.js"]
```

<!--
By default, Docker runs commands inside the container as root which violates the Principle of Least Privilege (PoLP) when superuser permissions are not strictly required. The user node is provided by the image node
-->
---
layout: center
---

# Node.js Image 

Node.js Docker image is based on Debian.

For e.g: `node:bookworm`

Two other variants:
* slim - provides a functional NodeJs env and nothing more.
* alpine - based on Alpine Linux distro, but is an unofficial and is experimental.

---
layout: image 
image: image-vulnerabilities.png
---
<style>
.slidev-layout {
background-size: 80vw auto !important;
}
</style>

---
layout: center
---

# Deterministic tag

`node:alpine`

`node:20.4.0-alpine3.17`

---

# Minimize image size

```dockerfile {1|all}
FROM node:20.4.0-alpine3.17
USER node

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies 
COPY --chown=node:node packages*.json .

RUN npm ci

COPY --chown=node:node server.js .
EXPOSE 8080
CMD ["node", "server.js"]
```

<!--
Deterministic tag should be favoured, that is, instead of node:bookwork-slim or node:alpine, specify the nodejs runtime such as node:20.5.0-bookworm-slim or node:20.4.0-alpine3.17.
-->
---
layout: center
---

# Minimize image size

```bash {all}
REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
node-20-alpine   latest    ae76c5b808a2   12 seconds ago   185MB
node-20          latest    3abe3becfb39   14 minutes ago   1.1GB
```
---
layout: center
---

# Tini (short for Tiny Init)

* init for container
* Tiny helps address the "PID 1 problem" in Docker containers
* Docker expects the main process within a container to run as PID 1, but traditional processes don't handle signals correctly in this role.
* Tiny ensures that signals (such as SIGTERM) sent to the main Tini process are properly propagated to the child processes, allowing them to gracefully terminate when needed

<!--
Zombie process: a terminated child that remains in the system's process  table while waiting for its parent process to collect its exit status.

Tini acts as a signal proxy, ensuring that signals sent to the container are appropriately delivered to the processes within, preventing unexpected behavior during shutdown or other events.
-->
---
layout: center
---

# Tini

```dockerfile {2,15|all}
FROM node:20.4.0-alpine3.17
RUN apk add --no-cache tini
USER node

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies 
COPY --chown=node:node packages*.json .

RUN npm ci

COPY --chown=node:node server.js .
EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "-"]
CMD ["node", "server.js"]
```
---
layout: center
---

# Multi-stage build

```dockerfile {1,15|all}
FROM node:20.4.0-alpine3.17 AS base
RUN apk add --no-cache tini
USER node

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies 
COPY --chown=node:node packages*.json .

RUN npm ci

COPY --chown=node:node server.js .

FROM base AS APP
EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "-"]
CMD ["node", "server.js"]
```
---
layout: center
---

# Multi-stage build: better example

```dockerfile {all|2,15,16}
# syntax=docker/dockerfile:1
FROM golang:1.21 as build
WORKDIR /src
COPY <<EOF /src/main.go
package main

import "fmt"

func main() {
  fmt.Println("hello, world")
}
EOF
RUN go build -o /bin/hello ./main.go

FROM scratch
COPY --from=build /bin/hello /bin/hello
CMD ["/bin/hello"]
```
<!--
Each `FROM` instruction can use a different base, and each of them begins a new stage of the build. 
You can selectively copy artifacts from one stage to another, leaving behind everything you don't want in the final image.

The end result is a tiny production image with nothing but the binary inside. 
None of the build tools required to build the application are included in the resulting image.
-->
---
layout: center
---
# Buildkit

* Buildkit is a builder backend 
* default builder in Docker Engine as of version 23.0
* BuildKit efficiently skips unused stages and builds stages concurrently when possible.
* Enable Buildkit:
```
DOCKER_BUILDKIT=1 docker build .
```
* Alternatively
```
docker buildx build .
```


---
layout: two-cols
---

# Initial DockerFile 

```dockerfile
FROM node:20

WORKDIR /usr/src/app
COPY . .

RUN npm ci
EXPOSE 8080
CMD ["node", "server.js"]
```

::right::

# Improved DockerFile

```dockerfile 
FROM node:20.4.0-alpine3.17 AS base
RUN apk add --no-cache tini
USER node

WORKDIR /usr/src/app

COPY --chown=node:node packages*.json .

RUN npm ci
COPY --chown=node:node server.js .

FROM base AS APP
EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "-"]
CMD ["node", "server.js"]
```

---
layout: center
---

# Other tips

* Use cache mounts
* Leverage HEALTHCHECK
* Use linter

---
layout: center
---
Thank you!
---
layout: end
---
