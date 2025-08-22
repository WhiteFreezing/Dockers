FROM eclipse-temurin:24-jdk

LABEL maintainer="whitefreezing@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/WhiteFreezing/Dockers"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget unzip git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/container

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]