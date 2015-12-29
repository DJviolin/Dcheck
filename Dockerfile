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
        dialog \
        apt-utils \
        sudo \
        openssh-server \
        whois \
        jwhois \
        crunch

### Start of OpenSSH setup
RUN mkdir /var/run/sshd
RUN mkdir /root/.ssh
COPY root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN echo -e '\ncd /root' >> /root/.bashrc
### End of OpenSSH setup

RUN rm -rf /var/lib/apt/lists/*

EXPOSE 22

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/usr/sbin/sshd", "-D"]