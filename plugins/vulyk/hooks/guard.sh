#!/usr/bin/env bash
# VULYK guard, a PreToolUse hook. Three mechanical checks and nothing else (CLAUDE.md, hard limits):
#   1. uncommitted work: deny git commands that throw it away while the tree holds it;
#   2. publishing: ask before push, release or publish, in any spelling the words survive;
#   3. secrets: deny writing or committing a value shaped like a credential.
# It catches honest mistakes, not a determined bypass. Input: the hook JSON on stdin.
# Output: one decision JSON, or nothing. Needs bash 3.2+, awk, grep -E, git.

input=$(cat)

decide() { # $1 = deny | ask, $2 = reason without double quotes
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  exit 0
}

# The string values of the given JSON keys, one per line, unescaped enough for matching.
values() {
  printf '%s' "$input" | grep -oE "\"($1)\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" |
    sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\[nrt]/ /g; s/\\"/"/g; s/\\\\/\\/g'
}

b='(^|[^A-Za-z0-9_-])'
SECRET="-----BEGIN ([A-Z]+ )*PRIVATE KEY-----|${b}AKIA[0-9A-Z]{16}|${b}gh[pousr]_[A-Za-z0-9]{36}"
SECRET="$SECRET|${b}github_pat_[A-Za-z0-9_]{50,}|${b}glpat-[A-Za-z0-9_-]{20}|${b}sk-[A-Za-z0-9_-]{32,}"
SECRET="$SECRET|${b}xox[abprs]-[A-Za-z0-9-]{10,}|${b}AIza[0-9A-Za-z_-]{35}|${b}[0-9]{8,10}:AA[A-Za-z0-9_-]{33}"
SECRET_WHY='VULYK guard: this looks like a credential (key, token or private key). Put [REDACTED] or an environment variable reference instead of the value.'

case "$input" in
  *'"tool_name":"Bash"'* | *'"tool_name": "Bash"'* | *'"tool_name":"PowerShell"'* | *'"tool_name": "PowerShell"'*) ;;
  *)
    if values 'content|new_string|new_source' | grep -qE -e "$SECRET"; then decide deny "$SECRET_WHY"; fi
    exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true

# Tracked changes (any = 1) or, with "all", untracked files too.
dirty() {
  if [ "$1" = all ]; then git status --porcelain 2>/dev/null | grep -q .
  else git status --porcelain 2>/dev/null | grep -qv '^??'; fi
}
LOSS='VULYK guard: this git command would throw away uncommitted work. Commit or stash it first, or ask the owner to run it with the ! prefix.'

ask=''
# One command segment per line; quotes, parens, slashes and .exe become spaces so words stand alone.
segments=$(values command | awk '{ gsub(/&&|\|\||;|\|/, "\n"); gsub(/["'"'"'()`\/]/, " "); gsub(/\\/, " "); gsub(/\.exe/, ""); gsub(/\t/, " "); print }')
while IFS= read -r seg; do
  s=" ${seg// /  } " # doubled spaces: neighbouring words in a pattern each get their own
  case "$s" in *" git "*) ;; *" gh "* | *" npm "* | *" pnpm "* | *" yarn "* | *" cargo "* | *" twine "* | *" docker "*) ;; *) continue ;; esac

  # 1. uncommitted work
  case "$s" in
    *" git "*" stash "*" drop "* | *" git "*" stash "*" clear "*) decide deny "$LOSS" ;;
    *" git "*" reset "*" --hard "*) dirty && decide deny "$LOSS" ;;
    *" git "*" checkout "*" -- "* | *" git "*" checkout "*" . "* | *" git "*" checkout "*" -f "* | *" git "*" checkout "*" --force "*)
      dirty && decide deny "$LOSS" ;;
    *" git "*" switch "*" --discard-changes "* | *" git "*" switch "*" -f "* | *" git "*" switch "*" --force "*)
      dirty && decide deny "$LOSS" ;;
    *" git "*" restore "*)
      case "$s" in *" --staged "* | *" -S "*) case "$s" in *" --worktree "* | *" -W "*) dirty && decide deny "$LOSS" ;; esac ;;
        *) dirty && decide deny "$LOSS" ;; esac ;;
    *" git "*" clean "*)
      if [[ $s =~ \ (-[A-Za-z]*f[A-Za-z]*|--force)\  ]]; then dirty all && decide deny "$LOSS"; fi ;;
  esac

  # 2. publishing
  case "$s" in
    *" git "*" push "* | *" gh "*" release "*" create "* | *" gh "*" release "*" upload "* | \
    *" gh "*" release "*" edit "* | *" gh "*" release "*" delete "* | *" gh "*" pr "*" create "* | \
    *" gh "*" pr "*" merge "* | *" npm "*" publish "* | *" pnpm "*" publish "* | *" yarn "*" publish "* | \
    *" cargo "*" publish "* | *" twine "*" upload "* | *" docker "*" push "*)
      ask='VULYK guard: publishing (push, release, publish) needs the word of the owner for this step: the owner approves this prompt, or runs the command with the ! prefix.' ;;
  esac

  # 3. secrets in a commit
  case "$s" in
    *" git "*" commit "*)
      range=--cached
      [[ $s =~ \ (-[A-Za-z]*a[A-Za-z]*|--all)\  ]] && range=HEAD
      if git diff "$range" 2>/dev/null | grep '^+' | grep -qE -e "$SECRET"; then decide deny "$SECRET_WHY"; fi ;;
  esac
done <<EOF
$segments
EOF

[ -n "$ask" ] && decide ask "$ask"
exit 0
