#!/bin/bash
set -euo pipefail

while read p; do
  echo "Starting $p"
  scp get-keys $p:/usr/local/bin
done <inventory