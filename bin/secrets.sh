#!/bin/bash

export DOPPLER_TOKEN="$(cat /etc/doppler.secret)"

/bin/doppler setup --project infra --config dev --no-interactive

export $(doppler run -- env | xargs)