FROM ubuntu:24.10

ARG PUBKEY
ARG PRIVKEY
ARG EMAIL
ENV PUBKEY=$PUBKEY
ENV PRIVKEY=$PRIVKEY
ENV EMAIL=$EMAIL

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "sh", "-c", "/entrypoint.sh" ]
