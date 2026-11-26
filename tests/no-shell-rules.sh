#!/usr/bin/env bash
# Shipped settings carry no Bash(...) or PowerShell(...) permission rules. On Windows, Claude Code turns the
# PowerShell tool off when a deny rule names Bash and no rule names PowerShell (seen in 2.1.330, 26.11.2026);
# publishing is guarded by hooks/guard.sh for both shells. Checked on every commit (.githooks/pre-commit).
root=$(cd "$(dirname "$0")/.." && pwd)
if grep -rnE --include='*.md' --include='*.json' '"(Bash|PowerShell)\(' "$root/plugins/vulyk"; then
  echo "no-shell-rules: shipped permission rule for a shell (above); leave publishing to guard.sh"; exit 1
fi
