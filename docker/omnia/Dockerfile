# ethsign build stage
FROM golang:1-alpine as ethsign-builder

RUN apk --no-cache add git

WORKDIR /go/src/ethsign
RUN git clone https://github.com/dapphub/dapptools.git .
RUN export CGO_ENABLED=0 \
  && mkdir dist \
  && cd src/ethsign/ \
  && go mod tidy \
  && go mod download \
  && go build -o ../../dist/ethsign ./ethsign.go

# Building Spire
FROM golang:1-alpine as spire-builder
RUN apk --no-cache add git gcc libc-dev linux-headers
WORKDIR /go/src/spire
RUN git clone https://github.com/makerdao/oracle-suite.git .
RUN export CGO_ENABLED=1 \
  && mkdir dist \
  && go mod download \
  && go build -o dist/spire ./cmd/spire

# Building final omnia container
FROM alpine:edge

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing ca-certificates jq bash curl git agrep perl nodejs datamash jshon parallel python3 py3-pip

COPY --from=ethsign-builder /go/src/ethsign/dist/ /usr/local/bin/
COPY --from=spire-builder /go/src/spire/dist/ /usr/local/bin/

COPY ./docker/starkware /home/omnia/starkware
COPY ./bin /home/omnia/bin/
COPY ./lib /home/omnia/lib/
COPY ./docker/keystore/ /home/omnia/keystore/
COPY ./docker/omnia/config/ /home/omnia/config/
COPY ./version /home/omnia/version

# Add a non-root user
RUN adduser -D omnia \
  && chown -R omnia:omnia /home/omnia

USER omnia
WORKDIR /home/omnia

# Downloading seth
RUN git clone https://github.com/dapphub/dapptools.git \
  && cp -R dapptools/src/seth/libexec/seth /home/omnia/seth \
  && rm -rf dapptools

# Installing setzer
RUN git clone https://github.com/makerdao/setzer-mcd.git \
  && cp -R setzer-mcd/libexec/setzer/ /home/omnia/setzer \
  && rm -rf setzer-mcd

# Requirements for starkware
RUN pip install mpmath sympy ecdsa==0.16.0

# Disabling parallel notification
RUN printf 'will cite' | parallel --citation; exit 0

# Setting up PATH for seth, setzer and omnia bin folder
# Here we have set of different pathes included:
# - /home/omnia/seth - For `seth` executable
# - /home/omnia/setzer - For `setzer` executable
# - /home/omnia/starkware - For Starkware python dependency
# - /home/omnia/bin - Omnia and transports executables
# - /home/omnia/.local/bin - for pip (Python 3) packages required for Starkware
ENV PATH="/home/omnia/seth:/home/omnia/setzer:/home/omnia/starkware:/home/omnia/bin:/home/omnia/.local/bin:${PATH}"

ENV OMNIA_CONFIG /home/omnia/config/feed.conf

CMD ["bin/omnia"]