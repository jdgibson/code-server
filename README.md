# code-server Development Container

This repository includes a small Docker workflow for running [code-server](https://github.com/coder/code-server), a browser-accessible VS Code environment. The container is based on the LinuxServer.io image and mounts this repository into the editor at `/workspace`, so edits made in code-server are applied directly to the files on the host.

The workflow is defined in the [Makefile](Makefile). It is intended for local development where Docker provides the editor runtime while the repository remains on the host machine.

## What starts

`make start-dev` runs the following image by default:

```
lscr.io/linuxserver/code-server:latest
```

The container is configured with these defaults:

| Setting | Default | Purpose |
| --- | --- | --- |
| Container name | `code-server-dev` | Identifies the running container to Docker and Make targets. |
| Image | `lscr.io/linuxserver/code-server:latest` | LinuxServer.io's code-server image. |
| Host port | `8443` | Port used in the browser URL. |
| Container port | `8443` | Port exposed by code-server within the container. |
| Workspace mount | current repository directory -> `/workspace` | Makes the checkout available to the editor and preserves edits on the host. |
| User/group IDs | `1000` / `1000` | Passed to the LinuxServer image as `PUID` and `PGID` for file ownership. |
| Time zone | `Etc/UTC` | Passed to the container as `TZ`. |
| Restart policy | `unless-stopped` | Restarts the service after Docker restarts unless it was deliberately stopped. |

No credentials or configuration directory are supplied by this repository's Makefile. Consult the LinuxServer code-server image documentation for the image's current authentication and configuration defaults before exposing the service beyond a trusted local machine.

## Prerequisites

- Docker Engine or Docker Desktop, with permission to run `docker` commands.
- GNU Make. On Debian or Ubuntu, install it with `sudo apt install make`; on macOS it is normally included with the Command Line Tools.
- A browser that can reach the machine running Docker.

Check that Docker is available before starting:

```sh
docker version
docker info
```

If Docker is installed but access is denied, start Docker or configure your user for Docker access according to your platform's documentation.

## Start the editor

From the repository root, run:

```sh
make start-dev
```

Docker pulls the image on the first run, creates a detached container named `code-server-dev`, and mounts the current directory at `/workspace`. Once the container has started, open:

```
http://localhost:8443
```

The Makefile intentionally uses HTTP. Use `http://`, not `https://`, unless you add a reverse proxy or separately configure TLS.

In the code-server interface, open the `/workspace` folder. That folder is the same checkout from which `make start-dev` was run. Saving a file in the browser updates the host checkout immediately, and host-side edits are visible in the container through the bind mount.

## Manage the container

| Command | Result |
| --- | --- |
| `make start-dev` | Creates and starts the code-server container. |
| `make logs-dev` | Streams container logs; press `Ctrl+C` to stop following logs without stopping the container. |
| `make stop-dev` | Stops and removes the `code-server-dev` container. |
| `make help` | Prints the available Make targets. |

To check its status without Make:

```sh
docker ps --filter name=code-server-dev
```

`make stop-dev` removes the container but does not delete the repository files, because they are stored in the host directory mounted at `/workspace`.

## Override defaults

The Makefile defines `CONTAINER_NAME`, `IMAGE`, and `PORT` as overridable variables. Supply an assignment on the same command line when starting the container.

Use a different host port when `8443` is occupied:

```sh
make start-dev PORT=8080
```

Then browse to `http://localhost:8080`.

Use a specific image tag to avoid floating on `latest`:

```sh
make start-dev IMAGE=lscr.io/linuxserver/code-server:4.99.0
```

Use a different container name when running more than one instance:

```sh
make start-dev CONTAINER_NAME=my-project-code-server PORT=8081
make logs-dev CONTAINER_NAME=my-project-code-server
make stop-dev CONTAINER_NAME=my-project-code-server
```

Keep the same variable assignments for every lifecycle command that targets a non-default container.

## File ownership

The container receives `PUID=1000` and `PGID=1000`. These values are commonly the first regular Linux user's IDs, but they may not match your account. A mismatch can cause files created by tools inside code-server to have unexpected ownership on the host.

Check your IDs:

```sh
id -u
id -g
```

If they differ from `1000`, update the `PUID` and `PGID` values in the Makefile before starting the container. The current Makefile does not expose those two settings as command-line variables.

## Operational notes

- The image is referenced as `latest`; starting a new container after an image update can change the installed code-server version. Pin `IMAGE` to a tag when reproducibility matters.
- The Makefile uses `docker run`, not Docker Compose. Starting a second time while `code-server-dev` already exists fails with a name-conflict error. Stop the existing instance first, or choose another `CONTAINER_NAME`.
- Container configuration that is not stored under `/workspace` is removed by `make stop-dev`, because the command removes the container and the Makefile does not mount a separate configuration volume.
- The published port binds according to Docker's default behavior. Treat it as a local-development service unless you have intentionally configured network exposure, authentication, and TLS.

## Troubleshooting

### The browser cannot connect

Confirm that the container is running and inspect its logs:

```sh
docker ps --filter name=code-server-dev
make logs-dev
```

If the container is running, verify that you are using the configured host port and `http://`. For a remote Docker host, replace `localhost` with that host's reachable address and ensure the network and firewall rules permit the port.

### Port 8443 is already in use

Choose an unused host port:

```sh
make start-dev PORT=8080
```

### Docker reports that the container name already exists

Either remove the existing default instance:

```sh
make stop-dev
```

or use a distinct name and port:

```sh
make start-dev CONTAINER_NAME=code-server-alt PORT=8081
```

### Edits have unexpected ownership

Compare `id -u` and `id -g` with the `PUID` and `PGID` settings in the Makefile, then align the Makefile values with your host account before recreating the container.

## Clean shutdown

When you are done, remove the container with:

```sh
make stop-dev
```

The repository remains intact on the host. Restart later with `make start-dev`.
