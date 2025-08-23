FROM eclipse-temurin:24-jdk

LABEL       author="whitefreezing_" maintainer="whitefreezing@gmail.com"
LABEL       org.opencontainers.image.source="https://github.com/WhiteFreezing/Dockers"
LABEL       org.opencontainers.image.licenses="MIT"

COPY /home/container/templates/install_packages.sh /tmp/install_packages.sh
RUN chmod +x /tmp/install_packages.sh && /tmp/install_packages.sh && rm /tmp/install_packages.sh

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]