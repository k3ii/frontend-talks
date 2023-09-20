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
title: Welcome to Slidev
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
---
theme: default
layout: center
---
# Directory Structure

```bash {all}
.git
.gitignore
.README.md
node_modules
package.json
package-lock.json
server.js
```
---
layout: center
class: text-4xl
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


---
layout: center
class: text-4xl
---

# .dockerignore

```dockerfile
.git
.gitignore
README.md
node_modules
```

---
layout: center
class: text-4xl
---

# Copy App code seperately

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
---
layout: center
class: text-4xl
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
---
layout: center
class: text-4xl
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
---
layout: center
class: text-4xl
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
layout: two-cols
---

# Initial DockerFile 

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

::right::

# Improved DockerFile

```dockerfile 
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
