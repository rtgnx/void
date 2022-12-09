FROM alpine:3.13 as build

RUN mkdir /rootfs
ADD https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20221001.tar.xz /rootfs
WORKDIR /rootfs
RUN tar xvf *.tar.xz
RUN rm -rf *.tar.xz

FROM scratch

COPY --from=build /rootfs /

RUN xbps-install -u xbps
RUN xbps-install -Sy socklog socklog-void cronie vsv
RUN mkdir -p /run/runit/runsvdir/current

RUN ln -sf /etc/sv/socklog-unix /var/service/
RUN ln -sf /etc/sv/cronie /var/service/

ENTRYPOINT ["runsvdir", "-P",  "/run/runit/runsvdir/current" ]
