FROM golang:1.17-alpine3.15 as go-builder
RUN apk --no-cache add git

ARG CGO_ENABLED=0

ARG DAPP_BRANCH="master"

WORKDIR /go/src/dapptools
RUN git clone --depth 1 --branch ${DAPP_BRANCH} https://github.com/dapphub/dapptools.git .

WORKDIR /go/src/dapptools/src/ethsign
RUN go mod tidy && \
  go mod download && \
  go build .

ARG ORACLE_SUITE_BRANCH="v0.3.5"

WORKDIR /go/src/oracle-suite
RUN git clone --depth 1 --branch ${ORACLE_SUITE_BRANCH} https://github.com/chronicleprotocol/oracle-suite.git .

RUN go mod tidy && \
  go mod download && \
  go build ./cmd/spire && \
  go build ./cmd/gofer && \
  go build ./cmd/ssb-rpc-client

#FROM python:3.10.2-alpine3.15 # failing `test -x FILE`
#FROM python:3.9.10-alpine3.14 # same
FROM python:3.9.9-alpine3.15

ARG DAPP_BRANCH="dapp/0.34.1"
ARG SETZER_REF="b9ddabde9bba61d29a3694ba15b657e36c84b3e7"

RUN apk add --update --no-cache \
  jq curl git make perl g++ ca-certificates parallel tree \
  bash bash-doc bash-completion \
  util-linux pciutils usbutils coreutils binutils findutils grep iproute2 \
  nodejs \
  && apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  jshon agrep datamash

# Installing setzer
RUN wget https://github.com/makerdao/setzer-mcd/archive/${SETZER_REF}.zip \
  && unzip ${SETZER_REF}.zip \
  && cp -R setzer-mcd-${SETZER_REF}/libexec/setzer/ /root/setzer \
  && rm -rf setzer-mcd-${SETZER_REF} \
  && rm ${SETZER_REF}.zip

COPY ./docker/geth/bin/hevm-0.48.1 /usr/local/bin/hevm
COPY ./docker/geth/bin/solc-0.5.12 /usr/local/bin/solc

COPY --from=go-builder /go/src/dapptools/src/dapp/ /opt/dapp/
COPY --from=go-builder /go/src/dapptools/src/seth/ /opt/seth/

COPY --from=go-builder \
  /go/src/dapptools/src/ethsign/ethsign \
  /go/src/oracle-suite/spire \
  /go/src/oracle-suite/gofer \
  /go/src/oracle-suite/ssb-rpc-client \
  /usr/local/bin/

RUN printf 'will cite' | parallel --citation 1>/dev/null 2>/dev/null; exit 0

ENV PATH="/opt/dapp/bin:/opt/seth/bin:/opt/setzer/bin:${PATH}"
CMD ["/bin/bash"]