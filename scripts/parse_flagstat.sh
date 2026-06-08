#!/usr/bin/env bash
set -euo pipefail

FLAGSTAT_FILE="${1:?Usage: scripts/parse_flagstat.sh <flagstat.txt>}"

awk '
/^[0-9]+ \+ [0-9]+ mapped \(/ {
    line = $0
    sub(/^.*\(/, "", line)
    sub(/%.*$/, "", line)
    print line
    exit
}
' "$FLAGSTAT_FILE"
