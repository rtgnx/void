ARG ARCH=x86_64
ARG VOID_BUILD_NO=20230628

# AMD64 - GLBIC https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20230628.tar.xz
# AMD64 - MUSL https://repo-default.voidlinux.org/live/current/void-x86_64-musl-ROOTFS-20230628.tar.xz
# AARCH64 - GLIBC https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS-20230628.tar.xz
# AARCH64 - MUSL https://repo-default.voidlinux.org/live/current/void-aarch64-musl-ROOTFS-20230628.tar.xz

FROM alpine:3.13 as build
ARG ARCH=x86_64
ARG VOID_BUILD_NO=20230628

RUN mkdir /rootfs
ADD https://repo-default.voidlinux.org/live/current/void-$ARCH-ROOTFS-$VOID_BUILD_NO.tar.xz /rootfs

WORKDIR /rootfs
RUN tar xvf *.tar.xz
RUN rm -rf *.tar.xz

FROM restic/restic:0.15.2 as restic
FROM ghcr.io/tailscale/tailscale:v1.44.0 as ts

FROM scratch

COPY --from=build /rootfs /
COPY --from=ts /usr/local/bin/tailscale /bin/tailscale
COPY --from=ts /usr/local/bin/tailscaled /bin/tailscaled
COPY --from=restic /usr/bin/restic /bin/restic

COPY ./etc /etc

RUN xbps-install -u xbps
RUN xbps-install -Sy socklog socklog-void cronie vsv
RUN mkdir -p /run/runit/runsvdir/current

RUN ln -sf /etc/sv/socklog-unix /var/service/
RUN ln -sf /etc/sv/cronie /var/service/

ENTRYPOINT ["runsvdir", "-P",  "/run/runit/runsvdir/current" ]
