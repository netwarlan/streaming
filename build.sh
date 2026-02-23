#!/bin/bash
set -e

docker build -t ghcr.io/netwarlan/streaming "$@" .
