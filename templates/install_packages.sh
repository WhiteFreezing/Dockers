#!/bin/sh
set -eu

if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get -y install --no-install-recommends \
        curl ffmpeg iproute2 git sqlite3 python3 tzdata ca-certificates \
        dnsutils fontconfig libfreetype6 libstdc++6 lsof build-essential locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    useradd -m -d /home/container container
    locale-gen en_US.UTF-8

elif command -v apk >/dev/null 2>&1; then
    apk update && apk add --no-cache \
        curl ffmpeg iproute2 git sqlite python3 tzdata ca-certificates \
        bind-tools fontconfig freetype libstdc++ lsof build-base \
    && adduser -D -h /home/container container
    echo "en_US.UTF-8" > /etc/locale.gen && locale-gen

else
    echo "Unsupported package manager!" >&2
    exit 1
fi