# syntax=docker/dockerfile:1-labs
FROM archlinux/archlinux:latest
RUN pacman -Syu --noconfirm && pacman -S --noconfirm arch-install-scripts qemu-user-static qemu-user-static-binfmt
WORKDIR /build/
COPY pacman.conf .
COPY keyrings/ ./keyrings/
COPY en.network .
COPY eth.network .
COPY gpg.conf .
COPY build.sh .


RUN chmod +x build.sh

CMD ["/build/build.sh"]
