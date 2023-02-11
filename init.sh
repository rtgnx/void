#!/bin/sh
set -a; source /etc/environment; set +a;
/bin/doppler setup --project infra --config dev --no-interactive
/bin/doppler run -- /entrypoint