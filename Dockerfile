FROM debian:unstable
MAINTAINER Istvan Lantos <info@lantosistvan.com>
LABEL Description="Domain Checker" Vendor="Istvan Lantos" Version="1.0"

ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive
RUN ln -sf /bin/bash /bin/sh && ln -sf /bin/bash /bin/sh.distrib

RUN echo -e "\
deb http://httpredir.debian.org/debian unstable main contrib non-free\n\
deb-src http://httpredir.debian.org/debian unstable main contrib non-free" > /etc/apt/sources.list
RUN apt-get -y update && apt-get -y dist-upgrade \
    && apt-get -y install \
        supervisor \
        whois \
        jwhois \
        crunch

RUN mkdir -p /var/log/supervisord

RUN rm -rf /var/lib/apt/lists/*

#COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
