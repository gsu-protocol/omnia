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

FROM alpine:edge

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  bash jq curl git nodejs python3 make jshon

# Downloading dapp
RUN git clone https://github.com/dapphub/dapptools.git \
  && cp -R dapptools/src/dapp/ /root/dapp \
  && cp -R dapptools/src/seth/libexec/seth /root/seth \
  && rm -rf dapptools

WORKDIR /home/dapp

COPY --from=ethsign-builder /go/src/ethsign/dist/ /usr/local/bin/

COPY ./docker/geth/bin/ /root/bin
COPY ./docker/keystore /root/keystore

ENV PATH="/root/dapp/libexec/dapp:/root/seth:/root/bin:${PATH}"

RUN git clone --recurse-submodules https://github.com/makerdao/testchain-medians.git . \
  && dapp build

ENV ETH_RPC_URL=http://geth.local:8545
ENV ETH_GAS=7000000
ENV ETH_KEYSTORE=/root/keystore
ENV ETH_PASSWORD=/root/keystore/password
ENV ETH_FROM=0x1bb90cde8a032cb4963813a5b4db4981afa5b9c6

ENTRYPOINT [ "" ]