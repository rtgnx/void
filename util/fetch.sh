#!/bin/sh

TARGETPLATFORM="${TARGETPLATFORM:-linux/amd64}"
ARCH="$(echo "${TARGETPLATFORM}" | sed 's/linux\/arm/aarch/' | sed 's/linux\/amd/x86_/')"

echo "$ARCH"

mkdir -p /rootfs
wget \
  -O /rootfs/rootfs.tar.xz \
  "https://repo-default.voidlinux.org/live/current/void-$ARCH-ROOTFS-$VOID_BUILD_NO.tar.xz"