#!/usr/bin/env bash
# caretaker.sh — keep the stable GitHub Pages entry point pointing at a LIVE
# game tunnel, unattended.
#
# Jeffrey's idea (Oct 13 2026): one permanent URL for Lisa, self-healing.
#   play  ->  https://hehg2.github.io/p-gec3z5kgvmz5/
#             which reads link.txt and forwards to the CURRENT tunnel
#
# What runs here, in order:
#   1. find the current tunnel URL (from the cloudflared log)
#   2. is it alive?  (curl /state, expect 200)
#   3. alive AND != what the page already says  -> publish the new URL
#   4. dead                                      -> restart the tunnel service,
#                                                   wait for a fresh URL, publish
#   5. page already correct                      -> do nothing (quiet, no commit)
#
# Safe to run as often as you like: it only writes when something changed.
set -uo pipefail

PROJ="/home/ffej/Documents/workspace/projects/debt-game"
REPO="$PROJ/redirect-repo"
LOG="$HOME/.cloudflared-tunnel.log"
SVC="debt-game-tunnel.service"

say(){ echo "[$(date '+%F %T')] $*"; }

# --- 1. current tunnel URL from the cloudflared log -------------------------
current_url(){
  grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" 2>/dev/null | tail -1
}

# --- 2. is a URL alive? -----------------------------------------------------
alive(){
  local u="$1"
  [ -n "$u" ] || return 1
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 12 "${u%/}/state" || echo 000)"
  [ "$code" = "200" ]
}

# --- what does the published page currently point at? ----------------------
published_url(){
  head -1 "$REPO/link.txt" 2>/dev/null | tr -d '[:space:]'
}

# --- 3/5. publish a URL to the page ----------------------------------------
publish(){
  local u="$1"
  printf '%s\n' "$u" > "$REPO/link.txt"
  cd "$REPO" || return 1
  if git diff --quiet -- link.txt 2>/dev/null; then
    say "page already points at $u (no change)"
    return 0
  fi
  git add link.txt
  git -c user.name="Freddy" -c user.email="freddy@openclaw.ai" \
      commit -q -m "caretaker: point at $u"
  if git push -q origin main 2>/dev/null; then
    say "published $u"
  else
    say "WARN: push failed for $u; will retry next run"
    return 1
  fi
}

# --- main -------------------------------------------------------------------
url="$(current_url)"

if alive "$url"; then
  pub="$(published_url)"
  if [ "$url" = "$pub" ]; then
    say "OK: $url alive, page already correct"
  else
    say "OK: $url alive, page was '$pub' -> updating"
    publish "$url"
  fi
  exit 0
fi

# dead (or no URL yet) -> restart the tunnel and wait for a fresh one
say "DEAD: '$url' not answering; restarting $SVC"
systemctl --user restart "$SVC" 2>/dev/null

for i in $(seq 1 20); do
  sleep 6
  url="$(current_url)"
  if [ "$url" != "$(published_url)" ] && alive "$url"; then
    say "new tunnel up after ${i} tries: $url"
    publish "$url"
    exit 0
  fi
done

say "ERROR: no live tunnel after 120s; leaving page as-is for the next run"
exit 1
