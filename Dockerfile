FROM ubuntu:24.10

ARG PUBKEY
ARG PRIVKEY
ARG EMAIL
ENV PUBKEY=$PUBKEY
ENV PRIVKEY=$PRIVKEY
ENV EMAIL=$EMAIL

RUN apt-get update && apt-get install -y sudo
COPY ./build_ppa.sh /entrypoint.sh

ENTRYPOINT [ "sh", "-c", "/entrypoint.sh" ]
