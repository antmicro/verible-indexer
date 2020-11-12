#!/bin/bash

set -e -u -o pipefail
shopt -s nullglob
shopt -s extglob

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
cd $SELF_DIR

SERVER_BIN=$SELF_DIR/bin/http_server
TABLES_DIR=$SELF_DIR/tables
PUBLIC_DIR=$SELF_DIR/web-ui

LISTEN="${1:-0.0.0.0:8080}"

$SERVER_BIN \
	--serving_table "$TABLES_DIR" \
	--public_resources "$PUBLIC_DIR" \
	-listen="$LISTEN"

