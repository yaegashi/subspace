FROM golang:1.23 as build

RUN apt-get update \
    && apt-get install -y git make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY Makefile ./
# go.mod and go.sum if exists
COPY go.* ./
COPY cmd/ ./cmd
COPY web ./web

ARG BUILD_VERSION=unknown
ARG GOARCH=amd64

ENV GODEBUG="netdns=go http2server=0"

RUN make build BUILD_VERSION=${BUILD_VERSION}

FROM alpine:3.11.6
LABEL maintainer="github.com/subspacecommunity/subspace"

ENV DEBIAN_FRONTEND noninteractive
RUN apk add --no-cache \
    iproute2 \
    iptables \
    ip6tables \
    dnsmasq \
    socat  \
    wireguard-tools \
    runit

COPY --from=build  /src/subspace /usr/bin/subspace
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/my_init /sbin/my_init

RUN chmod +x /usr/bin/subspace /usr/local/bin/entrypoint.sh /sbin/my_init

ENTRYPOINT ["/usr/local/bin/entrypoint.sh" ]

CMD [ "/sbin/my_init" ]
