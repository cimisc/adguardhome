FROM node:iron-bookworm AS stage1

ENV NODE_OPTIONS=--openssl-legacy-provider
WORKDIR /opt

RUN npm install --global vite

COPY .git /opt/.git
COPY AdGuardHome /opt/AdGuardHome

WORKDIR /opt/AdGuardHome
RUN make js-deps js-build

FROM golang:1.25.1-bookworm AS stage2

COPY --from=stage1 /opt /opt

WORKDIR /opt/AdGuardHome
RUN make go-deps go-build

FROM debian:bookworm

COPY --from=stage2 --chown=nobody:nogroup\
    /opt/AdGuardHome/AdGuardHome /opt/AdGuardHome/AdGuardHome

RUN apt-get update && apt-get -y install libcap2-bin dnsutils ca-certificates && \
    rm -rf /var/cache/apt && \
    setcap 'cap_net_bind_service=+eip' /opt/AdGuardHome/AdGuardHome && \
    mkdir -p /opt/workon

WORKDIR /opt/AdGuardHome

ENTRYPOINT ["/opt/AdGuardHome/AdGuardHome"]

CMD [ \
    "--no-check-update", \
    "-h", "0.0.0.0", \
    "-w", "/opt/workon" \
]
