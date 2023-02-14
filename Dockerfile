FROM alpine:3.13 as build

RUN mkdir /rootfs
ADD https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20221001.tar.xz /rootfs
WORKDIR /rootfs
RUN tar xf *.tar.xz
RUN rm -rf *.tar.xz


FROM ghcr.io/tailscale/tailscale:v1.34.1 as ts
FROM ghcr.io/netauth/netauth:v0.6.1 as netauth
FROM grafana/agent:latest as grafana
FROM dopplerhq/cli:3 as doppler

FROM golang:1.19-alpine as localizer
RUN apk add git
WORKDIR /src

RUN git clone --branch v0.1.3 https://github.com/netauth/localizer /src

RUN go mod vendor && \
      CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o /localize cmd/localize/*.go

FROM scratch

COPY --from=build /rootfs /

RUN xbps-install -Suy xbps
RUN xbps-install -Sy gettext jq vsv openssh

COPY --from=ts /usr/local/bin/tailscale /bin/tailscale
COPY --from=ts /usr/local/bin/tailscaled /bin/tailscaled
COPY --from=grafana /bin/grafana-agent /bin/grafana-agent

COPY --from=netauth /n /bin/netauth
COPY --from=localizer /localize /bin/localize
COPY --from=doppler /bin/doppler /bin/doppler

COPY ./etc /etc
RUN chmod 0400 /etc/sudoers
COPY ./entrypoint.sh /entrypoint
RUN chmod +x /entrypoint
COPY ./init.sh /sbin/init
RUN chmod +x /sbin/init
RUN ln -sf /etc/sv/sshd /run/runit/runsvdir/current/sshd

ENTRYPOINT [ "/bin/doppler" , "run", "--" , "/entrypoint.sh"]