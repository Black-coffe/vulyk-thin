#!/usr/bin/env bash
# Hard limits from CLAUDE.md, checked on every commit (.githooks/pre-commit). Raising a number takes the
# owner's word: change it here and in CLAUDE.md in the same commit, quoting that word in the message.
#   shipped (plugins/vulyk): <= 1500 lines, <= 6 scripts;  tests and repo checks: <= 500 lines.
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1
lines() { git ls-files -co --exclude-standard -- "$@" | while IFS= read -r f; do [ -f "$f" ] && cat "$f"; done | wc -l; }
shipped=$(lines plugins/vulyk)
scripts=$(git ls-files -co --exclude-standard -- plugins/vulyk | grep -cE '\.(sh|bash|py|js|mjs|cjs|ts|ps1)$')
repo=$(lines tests .githooks)
echo "size: shipped $shipped/1500 lines, $scripts/6 scripts; tests and checks $repo/500 lines"
bad=0
[ "$shipped" -le 1500 ] || { echo "size: shipped lines over the cap"; bad=1; }
[ "$scripts" -le 6 ] || { echo "size: more than 6 shipped scripts"; bad=1; }
[ "$repo" -le 500 ] || { echo "size: tests and checks over the cap"; bad=1; }
exit $bad
