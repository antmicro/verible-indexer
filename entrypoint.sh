#!/usr/bin/env bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Start the http server

echo "Starting the http server"

LISTEN="${1-:0.0.0.0:8080}"

/home/indexer/indexer/run-kythe-server.sh $LISTEN

exit 0
