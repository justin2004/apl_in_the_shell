# vim: filetype=dockerfile
FROM ubuntu:26.04
USER root
RUN apt-get update && apt-get install -y curl terminfo
ARG uid=1000
ARG gid=1000
ARG user=containeruser
RUN groupadd -g $gid $user || true
RUN useradd $user --uid $uid --gid $gid --home-dir /home/$user && \
  mkdir /home/$user && \
  chown $uid:$gid /home/$user

# utf 8 support
RUN apt-get install -y locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /home/containeruser
RUN curl -O https://www.dyalog.com/uploads/php/download.dyalog.com/download.php?file=20.0/linux_64_20.0.53963_unicode.x86_64.deb
RUN dpkg -i download.php
USER $user
ADD apl.sh /home/containeruser
USER root
RUN chmod 555 /home/containeruser/apl.sh
USER $user

WORKDIR /mnt

