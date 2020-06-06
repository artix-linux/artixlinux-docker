FROM artixlinux/base
RUN pacman --noconfirm -Syu base openrc elogind-openrc
ENV LANG=en_US.UTF-8
CMD ["/usr/bin/openrc-init"]
