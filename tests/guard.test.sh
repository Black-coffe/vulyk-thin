#!/usr/bin/env bash
# Tests for plugins/vulyk/hooks/guard.sh. Run: bash tests/guard.test.sh
# Secret-shaped values are built from pieces so the guard does not refuse writing this file.
set -u
here=$(cd "$(dirname "$0")" && pwd)
guard="$here/../plugins/vulyk/hooks/guard.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

repo() { # fresh repo: $1 = clean | tracked | untracked
  rm -rf "$tmp/r" && mkdir -p "$tmp/r" && cd "$tmp/r" || exit 1
  git init -q . && git config user.email t@t && git config user.name t && git config core.autocrlf false
  [ -d "$tmp/other" ] || { git init -q "$tmp/other" && git -C "$tmp/other" commit -q --allow-empty -m o; }
  echo a > a.txt && git add a.txt && git commit -qm init
  case "$1" in tracked) echo b >> a.txt ;; untracked) echo n > new.txt ;; esac
}

run() { # $1 tool, $2 key, $3 raw JSON string value -> prints deny | ask | none
  local out
  out=$(printf '{"session_id":"x","tool_name":"%s","tool_input":{"%s":"%s"}}' "$1" "$2" "$3" |
    CLAUDE_PROJECT_DIR="${PROJ:-$tmp/r}" bash "$guard")
  case "$out" in *'"deny"'*) echo deny ;; *'"ask"'*) echo ask ;; '') echo none ;; *) echo "bad:$out" ;; esac
}

check() { # $1 expected, $2 label, rest = run args
  local want=$1 label=$2 got; shift 2
  got=$(run "$@")
  if [ "$got" = "$want" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $label: want $want, got $got"; fi
}

# 1. uncommitted work
repo tracked
check deny 'reset --hard, dirty'            Bash command 'git reset --hard'
check deny 'reset via -C and chain'         Bash command 'cd x && git -C . reset --hard HEAD~1'
check deny 'checkout -- file'               Bash command 'git checkout -- a.txt'
check deny 'checkout .'                     Bash command 'git checkout .'
check deny 'restore file'                   Bash command 'git restore a.txt'
check deny 'restore staged + worktree'      Bash command 'git restore --staged --worktree a.txt'
check none 'restore --staged only'          Bash command 'git restore --staged a.txt'
check deny 'switch --discard-changes'       Bash command 'git switch --discard-changes main'
check deny 'stash drop'                     Bash command 'git stash drop'
check deny 'powershell reset'               PowerShell command 'git reset --hard; Write-Host ok'
check deny 'bash -c wrapper'                Bash command 'bash -c \"git reset --hard\"'
check none 'checkout -b'                    Bash command 'git checkout -b feature/x'
check none 'status'                         Bash command 'git status --porcelain'
check deny 'checkout a modified path'       Bash command 'git checkout a.txt'
check deny 'checkout HEAD path'             Bash command 'git checkout HEAD a.txt'
check deny 'worktree remove --force'        Bash command 'git worktree remove --force ../wt'
check deny 'rm -f a modified file'          Bash command 'git rm -f a.txt'
check none 'rm --cached keeps the file'     Bash command 'git rm --cached a.txt'
check deny 'checkout-index -f'              Bash command 'git checkout-index -f -a'
check deny 'read-tree -u --reset'           Bash command 'git read-tree -u --reset HEAD'
check deny 'second line of a script'        Bash command 'git restore --staged a.txt\ngit reset --hard'
check none 'commit message with restore'    Bash command 'git commit -m \"restore retry on feed timeout\"'
check none 'commit message with stash'      Bash command 'git commit -m \"stash results and clear cache\"'
check none 'message names git reset'        Bash command 'git commit -m \"avoid git reset --hard here\"'
check none 'add a path named restore'       Bash command 'git add src/restore/handler.py'
check none 'grep for restore'               Bash command 'git grep -n restore'
check none 'switch -c to new branch'        Bash command 'git switch -c fix/restore'
check none 'checkout branch, ls . later'    Bash command 'git checkout main\nls .'
check none 'git -C clean other repo'        Bash command "git -C $tmp/other reset --hard"
if command -v cygpath >/dev/null; then # Windows only: a PowerShell path keeps its backslashes
  winr=$(cygpath -w "$tmp/r" | sed 's/\\/\\\\/g')
  check deny 'powershell -C windows path'   PowerShell command "git -C $winr reset --hard"
fi
check none 'multi-line message'             Bash command 'git commit -am \"fix feed\n\ngit reset --hard was wrong\"'
check none 'heredoc message'                Bash command 'git commit -F - <<'"'"'EOF'"'"'\ngit reset --hard was wrong\nEOF'
check none 'grep for the phrase'            Bash command 'grep -rn \"git reset --hard\" docs'
check deny 'quoted --hard'                  Bash command "git reset '--hard'"
check deny 'continued line'                 Bash command 'git reset \\\n  --hard'
check deny 'bash -c with a chain inside'    Bash command 'bash -c \"cd x; git reset --hard\"'
mkdir -p docs
check none 'checkout -b docs'               Bash command 'git checkout -b docs'
repo clean
check none 'reset --hard, clean tree'       Bash command 'git reset --hard ORIG_HEAD'
check none 'clean -fd, clean tree'          Bash command 'git clean -fd'
check deny 'stash clear, clean tree'        Bash command 'git stash clear'
repo untracked
check none 'reset --hard, only untracked'   Bash command 'git reset --hard'
check deny 'clean -fd, untracked'           Bash command 'git clean -fd'
check deny 'clean --force, untracked'       Bash command 'git clean --force'
check none 'clean -n, untracked'            Bash command 'git clean -n'

# 2. publishing
repo clean
check ask  'git push'                       Bash command 'git push origin main'
check ask  'git -C push'                    Bash command 'git -C . push'
check ask  'push after chain'               Bash command 'git add . && git commit -m x && git push'
check ask  'git.exe path push'              PowerShell command '& \"C:/Program Files/Git/cmd/git.exe\" push'
check ask  'gh release create'              Bash command 'gh release create v1.0.0'
check ask  'gh pr create'                   Bash command 'gh pr create --fill'
check ask  'npm publish'                    Bash command 'npm publish --access public'
check ask  'push in background'             Bash command 'git push&'
check ask  'uv publish'                     Bash command 'uv publish'
check ask  'docker buildx --push'           Bash command 'docker buildx build --push .'
check ask  'gh repo create --push'          Bash command 'gh repo create x --source . --push'
check none 'commit message with push'       Bash command 'git commit --allow-empty -m \"push retry fix\"'
check ask  'push behind uv run'             Bash command 'uv run git push'
check ask  'push into a redirect'           Bash command 'git push>out.txt'
check ask  'docker compose push'            Bash command 'docker compose push'
check ask  'windows path starting with n'   Bash command 'git -C E:\\x\\news push'
check ask  'bash -c push'                   Bash command 'bash -c \"git add . && git push\"'
check ask  'quoted subcommand'              Bash command 'git \"push\"'
check ask  'bash -ec push'                  Bash command 'bash -ec \"git push\"'
check ask  'push after a comment with an apostrophe' Bash command "# don't forget\ngit push\necho 'done now'"
check ask  'push inside a bash heredoc'     Bash command 'bash <<EOF\ngit push\nEOF'
check ask  'hash right after a quote'       Bash command 'echo \"a\"#; git push'
check none 'escaped quotes in a message'    Bash command 'git commit --allow-empty -m \"say \\\" git push \\\" later\"'
check none 'message mentions git push'      Bash command 'git commit --allow-empty -m \"do not git push yet\"'
check none 'pr body mentions npm publish'   Bash command 'gh pr view 1 --json body'
check ask  'push behind docker run'         Bash command 'docker run img git push origin main'
check none 'gh release list'                Bash command 'gh release list'
check none 'git log'                        Bash command 'git log --oneline -5'
check none 'plain ls'                       Bash command 'ls -la'

# 3. secrets
gh_tok="ghp""_$(printf 'a%.0s' $(seq 36))"
aws="AKIA""ABCDEFGHIJKLMNOP"
key="-----BEGIN RSA ""PRIVATE KEY-----"
ant="sk-""ant-api03-$(printf 'x%.0s' $(seq 40))"
check deny 'write github token'             Write content "TOKEN=$gh_tok"
check deny 'edit aws key'                   Edit new_string "aws_key = '$aws'"
check deny 'write private key'              Write content "$key\\nMIIE..."
check deny 'write anthropic key'            Write content "export ANTHROPIC_API_KEY=$ant"
check none 'write placeholder'              Write content 'TOKEN=[REDACTED]'
check none 'slug that contains sk-'         Write content 'task-feed-retry-1122-and-a-long-tail-of-words'
check none 'old_string with secret is fine' Edit old_string "$gh_tok"
repo clean
echo "TOKEN=$gh_tok" > leak.txt && git add leak.txt
check deny 'commit staged token'            Bash command 'git commit -m add'
git reset -q && rm leak.txt && echo "k=$aws" >> a.txt
check none 'commit, token only unstaged'    Bash command 'git commit -m add'
check deny 'commit -am, token unstaged'     Bash command 'git commit -am add'

git checkout -q a.txt && echo "TOKEN=$gh_tok" > new.env
check deny 'add then commit in one command' Bash command 'git add . && git commit -m x'
check deny 'commit -i with a path'          Bash command 'git commit -i new.env -m x'
check none 'commit, secret file untouched'  Bash command 'git commit -m x'
echo "k=$aws" >> a.txt
check deny 'commit with a path'             Bash command 'git commit a.txt -m x'
reason=$(printf '{"tool_name":"Bash","tool_input":{"command":"git commit -am x"}}' | CLAUDE_PROJECT_DIR="${PROJ:-$tmp/r}" bash "$guard")
case "$reason" in *'a.txt'*'new.env'* | *'new.env'*'a.txt'*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL: reason names files: $reason" ;; esac

check deny 'unknown long option is wide'    Bash command 'git commit --pathspec-from-file=l.txt -m x'
mkdir -p sub
PROJ=$tmp/r/sub check deny 'cwd in a subdirectory' Bash command 'git add -A && git commit -m x'
if bash -n "$guard"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: guard.sh syntax"; fi

echo "guard: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
