# Omnia

For more information see: https://github.com/makerdao/oracles-v2

## Working with Docker

We introduced Docker environment for local omnia development.

Please follow several steps to build and run it.

#### Building omnia image

NOTE: You have to build it from repo root.

```bash
$ docker build -t omnia -f docker/omnia/Dockerfile .
```

Running omnia with your local environment:

```bash
$ doc run -it --rm -v "$(pwd)"/lib:/home/omnia/lib -v "$(pwd)"/test:/home/omnia/test omnia /bin/bash
```

It will start bash session into docker comtainer with mounted `lib` and `test` folders.

To run `omnia` in container from prev command you can use `omnia` command:

```bash
$ omnia
Importing configuration from /home/omnia/config/feed.conf...
```