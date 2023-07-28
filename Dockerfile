#ARG ARCH=x86_64
ARG VOID_BUILD_NO=20230628
ARG BUILDPLATFORM
ARG TARGETPLATFORM

# AMD64 - GLBIC https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20230628.tar.xz
# AMD64 - MUSL https://repo-default.voidlinux.org/live/current/void-x86_64-musl-ROOTFS-20230628.tar.xz
# AARCH64 - GLIBC https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS-20230628.tar.xz
# AARCH64 - MUSL https://repo-default.voidlinux.org/live/current/void-aarch64-musl-ROOTFS-20230628.tar.xz

FROM alpine:3.13 as build
#ARG ARCH=x86_64
ARG VOID_BUILD_NO=20230628
ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN mkdir /rootfs
ADD ./util/fetch.sh /bin/fetch
RUN chmod +x /bin/fetch
RUN /bin/fetch

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
RUN xbps-install -Sy $(cat /etc/packages.txt | tr '\n' ' ')

RUN mkdir -p /run/runit/runsvdir/current

RUN rm -rf /var/cache
RUN rm -rf /usr/share/kbd /usr/share/i18n /usr/share/man
RUN rm -rf /usr/share/info



RUN find /etc/sv -type f -name 'run' | xargs -L1 chmod +x
RUN ln -sf /etc/sv/init /var/service/

ENTRYPOINT ["runsvdir", "-P",  "/run/runit/runsvdir/current" ]