# Devbox base images

Each base image has its own directory under `images/`.

- [`images/debian/Dockerfile`](images/debian/Dockerfile): Debian 13 (`trixie-slim`) with Git, mise, and CA certificates. No SSH configuration yet.
- [`images/arch/Dockerfile`](images/arch/Dockerfile): Arch Linux with the same tools.

Build locally with Docker:

```sh
make build
```

Build the Arch image:

```sh
make build-arch
```

Run Debian locally with SSH in the first terminal:

```sh
make run
```

Wait for `Server listening`, then connect from a second terminal:

```sh
make ssh
```

The local runner installs SSH at startup without changing the base image. It accepts public-key login as `devbox` on `127.0.0.1:2222` only. The host keeps the generated test key in `.local/ssh/`; only its public key is mounted into the devbox.

Press Ctrl+C in the first terminal to stop and remove the container. Files inside it are discarded; this is not a persistent workspace yet.

Image publishing and Kubernetes deployment are separate stages.
