#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <target-org-alias>" >&2
  exit 2
fi

if ! command -v sf >/dev/null 2>&1; then
  echo "Salesforce CLI (sf) is required but was not found on PATH." >&2
  exit 127
fi

sf project deploy start \
  --metadata-dir src \
  --target-org "$1" \
  --wait 60
