#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

. $SELF_DIR/common.inc.sh

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SERVER="indexer@34.123.203.237"
SERVER_DIR="~/indexer"

rsync -avrz --delete -e "ssh -o StrictHostKeyChecking=no" "$ARTIFACTS_DIR"/* "$SERVER:$SERVER_DIR/"

