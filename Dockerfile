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
        #dialog \
        #apt-utils \
        #sudo \
        #openssh-server \
        supervisor \
        whois \
        jwhois \
        crunch

# forward request and error logs to docker log collector
RUN mkdir -p /var/log/dcheck \
    && ln -sf /dev/stdout /var/log/dcheck/access.log \
    && ln -sf /dev/stderr /var/log/dcheck/error.log

### Start of OpenSSH setup
#RUN mkdir /var/run/sshd
#RUN mkdir /root/.ssh
#COPY root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#ENV NOTVISIBLE "in users profile"
#RUN echo "export VISIBLE=now" >> /etc/profile
#RUN echo -e '\ncd /root' >> /root/.bashrc
### End of OpenSSH setup

RUN rm -rf /var/lib/apt/lists/*

#EXPOSE 22

COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
