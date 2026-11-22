---
paths: ["**/*.sh", ".githooks/*"]
---
# Shell scripts: they run on Git Bash, Linux and macOS (bash 3.2, BSD tools)

- bash 3.2: no associative arrays, `mapfile`, `${x,,}`, `|&` or `&>>`. Empty array under `set -u`: `"${a[@]:-}"`.
- BSD tools: `sed -E`, never `-r`; no `\n` in a sed replacement (use awk); no `sort -V`, `grep -P`, or `\b` in
  `grep -E`; a pattern that starts with `-` goes after `-e`.
- `awk -v` cannot carry a newline: pass multi-line text on stdin.
- A command inside `while read` that reads stdin eats the list: give it `< /dev/null`.
- A check fails on missing or empty input; it never passes with nothing checked.
- Before a release tag: `bash tests/guard.test.sh` under bash 3.2 (`docker run --rm -v "$PWD":/r -w /r bash:3.2`)
  and on Linux (WSL), and on a Mac when one is at hand.
