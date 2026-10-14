# Promises — stable entry point

This page exists for one reason: **the game URL never changes**, even when the
tunnel behind it is restarted.

It does NOT host the game. It only forwards the browser to wherever the game is
currently served. The destination lives in `link.txt` (one line, the tunnel URL).

## What each file is

| file | purpose |
|---|---|
| `index.html` | reads `link.txt`, forwards the browser to it (keeping any `#k=` fragment) |
| `link.txt`   | the current tunnel URL — the ONLY thing the caretaker robot rewrites |
| `health.sh`  | daily check: is the target alive? if not, ask for a fresh tunnel |

## Why not just host the game here

Because this repo is public (GitHub Pages needs that) and the game holds a shared
ledger. Hosting it here would put the ledger on a well-known domain. Forwarding
keeps the game itself behind an un-guessable tunnel URL, while the entry point
stays stable and boring.

## Notes

- The `#k=...` sync key is a URL fragment. Fragments are never sent to a server,
  so the key is not exposed to GitHub, to this Pages host, or to any log.
- If `link.txt` is missing or the target is down, the page says so plainly
  instead of hanging.
