# ethsign build stage
FROM golang:1-alpine as ethsign-builder

ARG ETH_SIGN_BRANCH="ethsign/0.17.0"

RUN apk --no-cache add git

WORKDIR /go/src/ethsign

RUN git clone -b ${ETH_SIGN_BRANCH} https://github.com/dapphub/dapptools.git .

RUN export CGO_ENABLED=0 \
  && mkdir dist \
  && cd src/ethsign/ \
  && go mod tidy \
  && go mod download \
  && go build -o ../../dist/ethsign ./ethsign.go

# Final image
FROM alpine:edge

ARG DAPP_BRANCH="dapp/0.34.1"

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  bash jq curl git nodejs python3 make jshon

# Downloading dapp
RUN git clone -b ${DAPP_BRANCH} https://github.com/dapphub/dapptools.git \
  && cp -R dapptools/src/dapp/ /root/dapp \
  && cp -R dapptools/src/seth/libexec/seth /root/seth \
  && rm -rf dapptools

COPY --from=ethsign-builder /go/src/ethsign/dist/ /usr/local/bin/

COPY ./docker/geth/bin/hevm-0.48.1 /usr/local/bin/hevm
COPY ./docker/geth/bin/solc-0.5.12 /usr/local/bin/solc

ENV PATH="/root/dapp/libexec/dapp:/root/seth:${PATH}"

CMD ["/bin/bash"]