# vim: filetype=dockerfile
# FROM debian:11
FROM ubuntu:22.04
USER root
RUN apt-get update && apt-get install -y curl libtinfo5
ARG uid=1000
ARG gid=1000
ARG user=containeruser
RUN groupadd -g $gid $user || true
RUN useradd $user --uid $uid --gid $gid --home-dir /home/$user && \
  mkdir /home/$user && \
  chown $uid:$gid /home/$user

WORKDIR /home/containeruser
RUN curl -O https://www.dyalog.com/uploads/php/download.dyalog.com/download.php?file=18.2/linux_64_18.2.45405_unicode.x86_64.deb
RUN dpkg -i linux_64_18.2.45405_unicode.x86_64.deb
USER $user
ADD apl.sh /home/containeruser
USER root
RUN chmod 555 /home/containeruser/apl.sh
USER $user

WORKDIR /mnt

