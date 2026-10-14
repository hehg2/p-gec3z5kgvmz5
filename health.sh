#!/usr/bin/env bash
# health.sh — is the game reachable through the tunnel in link.txt?
#
# Exit codes:
#   0  target is alive (HTTP 200 on /state)
#   1  target is dead / stale — a fresh tunnel is needed
#
# The caretaker robot runs this on a schedule. It is deliberately tiny and
# dependency-free (curl only) so it can never rot.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK_FILE="$HERE/link.txt"

[ -f "$LINK_FILE" ] || { echo "DEAD: no link.txt"; exit 1; }
URL="$(head -1 "$LINK_FILE" | tr -d '[:space:]')"
[ -n "$URL" ] || { echo "DEAD: link.txt empty"; exit 1; }

CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 12 "${URL%/}/state" || echo 000)"
if [ "$CODE" = "200" ]; then
  echo "ALIVE: $URL ($CODE)"
  exit 0
fi
echo "DEAD: $URL ($CODE)"
exit 1
