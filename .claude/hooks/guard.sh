#!/usr/bin/env bash
# exit 2 = blocks tool call and shows stderr Claudovi
input=$(cat)
f=$(printf '%s' "$input" | grep -oE '"file_path"[^,]*' | sed -E 's/.*:\s*"([^"]+)".*/\1/')
case "$f" in
 *.env|*.env.*|*/secrets/*)
  echo "BLOCKED: refusing to edit secret file $f" >&2; exit 2;;
 */preload/*|*/main/index.ts|*/main/index.js)
  echo "WARNING: security-sensitive Electron file $f — verify contextIsolation/sandbox/nodeIntegration." >&2; exit 2;;
esac
exit 0
