#!/bin/sh
set -a; source /etc/environment; set +a;

export DATA_ROOT=${VOLUME_PATH:-/data}

## 1. Start tailscaled

TS_DATA_DIR="${DATA_ROOT}/tailscale/data"
TS_RUNTIME="/var/run/tailscale"

# create tailscale data driectories if not present
[ ! -d "$TS_DATA_DIR" ] && mkdir -p $TS_DATA_DIR
[ ! -d "$TS_RUNTIME" ] && mkdir -p $TS_RUNTIME

# start tailscale daemon
/bin/tailscaled \
  --statedir=$TS_DATA_DIR \
  --socket=$TS_RUNTIME/tailscaled.sock &

## 2. Login to tailscale

sleep 5; # wait 5s for tailscaled to startup
/bin/tailscale up \
  --ssh \
  --accept-routes \
  --auth-key "${TSKEY}" \
  --hostname "${TS_HOSTNAME:-$HOSTNAME}"

FQDN="$(tailscale status --json | jq --raw-output  .Self.DNSName | sed 's/\.$//')"

## 3. Generate certs
cd /tmp && tailscale cert "${FQDN}"

export TLS_CERT="/tmp/${FQDN}.crt"
export TLS_KEY="/tmp/${FQDN}.key"

## configure netauth
NETAUTH_DIR="/etc/netauth"
[ ! -d "$NETAUTH_DIR/keys" ] && mkdir -p "${NETAUTH_DIR}/keys"

if [ -n "$NETAUTH_SERVER" ]; then
  # fetch server certificate
  openssl s_client \
    -connect "${NETAUTH_SERVER}:1729" 2>/dev/null </dev/null | \
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${NETAUTH_DIR}/keys/tls.pem"

  envsubst < "${NETAUTH_DIR}/config.tpl.toml" > "${NETAUTH_DIR}/config.toml"

  # sync users and groups
  /bin/localize --min-gid 2000 --min-uid 2000
fi


## 5. Start bash or runit


RUNIT_SVDIR="/var/service"
RUNIT_CURRENT="/run/runit/runsvdir/current"

[ ! -d "$RUNIT_CURRENT" ] && mkdir -p "${RUNIT_CURRENT}"

#ln -sf "${RUNIT_CURRENT}" "${RUNIT_SVDIR}"
find /etc/sv/ -type f -name 'run' | xargs -L1 chmod +x
ln -sf /etc/sv/grafana ${RUNIT_CURRENT}/grafana

/sbin/runsvdir -P "/run/runit/runsvdir/current" 