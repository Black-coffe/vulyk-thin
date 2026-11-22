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
  git init -q . && git config user.email t@t && git config user.name t
  echo a > a.txt && git add a.txt && git commit -qm init
  case "$1" in tracked) echo b >> a.txt ;; untracked) echo n > new.txt ;; esac
}

run() { # $1 tool, $2 key, $3 raw JSON string value -> prints deny | ask | none
  local out
  out=$(printf '{"session_id":"x","tool_name":"%s","tool_input":{"%s":"%s"}}' "$1" "$2" "$3" |
    CLAUDE_PROJECT_DIR="$tmp/r" bash "$guard")
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

echo "guard: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
