FROM node:fermium-bullseye as stage1

WORKDIR /opt

RUN npm install --global vite

COPY .git /opt/.git
COPY AdGuardHome /opt/AdGuardHome

WORKDIR /opt/AdGuardHome
RUN make js-deps js-build

FROM golang:1.18-bullseye as stage2

COPY --from=stage1 /opt /opt

WORKDIR /opt/AdGuardHome
RUN make go-deps go-build

FROM ghcr.io/cimisc/foundation:latest

COPY --from=stage2 --chown=nobody:nogroup\
    /opt/AdGuardHome/AdGuardHome /opt/AdGuardHome/AdGuardHome

RUN setcap 'cap_net_bind_service=+eip' /opt/AdGuardHome/AdGuardHome && \
    mkdir -p /opt/workon

WORKDIR /opt/AdGuardHome

ENTRYPOINT ["/opt/AdGuardHome/AdGuardHome"]

CMD [ \
    "--no-check-update", \
    "-h", "0.0.0.0", \
    "-w", "/opt/workon" \
]
