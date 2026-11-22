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
- Before a release tag: the guard tests under bash 3.2 (the image has no git: `docker run --rm -v "$PWD":/r -w /r
  bash:3.2 bash -c 'apk add -q git && bash tests/guard.test.sh'`), on Linux (WSL), and on a Mac when at hand.
