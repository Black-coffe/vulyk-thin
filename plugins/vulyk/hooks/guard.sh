#!/usr/bin/env bash
# VULYK guard, a PreToolUse hook. Three mechanical checks and nothing else (CLAUDE.md, hard limits):
#   1. uncommitted work: deny git commands that throw it away while the tree holds it;
#   2. publishing: ask before push, release or publish;
#   3. secrets: deny writing or committing a value shaped like a credential.
# It catches honest mistakes, not a determined bypass. Input: the hook JSON on stdin.
# Output: one decision JSON, or nothing. Needs bash 3.2+, awk, grep -E, git 2.31+.

input=$(cat)

decide() { # $1 = deny | ask, $2 = reason without double quotes
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  exit 0
}

# The string values of the given JSON keys, one per line, unescaped enough for matching ($2 = raw: still
# JSON-escaped). An escaped newline becomes ";".
values() {
  printf '%s' "$input" | grep -oE "\"($1)\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" |
    sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//; s/"$//' |
    if [ "${2:-}" = raw ]; then cat; else
      sed -E 's/\\\\/@BS@/g; s/\\[nr]/;/g; s/\\t/ /g; s/\\"/"/g; s/@BS@/\\/g'; fi
}

# Splits a JSON-escaped shell command into one simple command per line. Outside quotes ; & | and newlines
# separate, a backslash escapes the next character (a newline: the line continues; in PowerShell a backtick),
# a word starting with # is a comment, and a heredoc body is dropped unless a shell or interpreter reads it.
# Quoted text of one word stays a word. Quoted text of several words is data (it becomes Q), except as a first
# word or after a shell -c (-ec, -lc...), -Command, eval, git -C or checkout: there it is read as words.
# A quoted path after -C, cd or -Path, and an escaped space, keep their spaces as \037 (one word).
read -r -d '' SPLIT <<'AWK'
{
  s = $0; n = length(s); out = ""; q = ""; qb = ""; keep = 0; esc = 0; cmt = 0; skip = ""; pend = ""; line = ""; raw = ""
  for (k = 1; k <= n; k++) {
    c = substr(s, k, 1)
    if (c == "\\") {
      k++; e = substr(s, k, 1)
      if (e == "n" || e == "r") c = "\n"; else if (e == "t") c = " "; else if (e == "u") { k += 4; c = "?" } else c = e
    }
    if (skip != "") { if (c == "\n") { if (line == skip) skip = ""; line = "" } else if (c != " ") line = line c; continue }
    if (cmt) { if (c == "\n") { cmt = 0; out = out "\n"; raw = c }; continue }
    if (esc) { esc = 0; if (c == "\n") c = " "; else if (c == " ") c = "\037"
      if (q != "") qb = qb (c ~ /[$`"\\\n]/ ? "" : "\\") c; else out = out c; raw = c; continue } # "C:\x" keeps \
    if (!ps && c == "\\" && q != "'") { esc = 1; continue } # in PowerShell a backslash is a path separator
    if (q != "") {
      if (c == q) { q = ""; out = out ((keep || qb !~ / /) ? qb : "Q"); qb = "" } # the word goes on after a quote
      else qb = qb (c ~ /[\n;&|]/ ? " " : (sp && c == " ") ? "\037" : c)
      raw = c; continue
    }
    if (c == "\n") {
      if (ps && raw == "`") { out = substr(out, 1, length(out) - 1) " "; raw = " "; continue }
      out = out "\n"; raw = c
      if (pend != "") { skip = pend; pend = ""; line = "" }
      continue
    }
    if (c == "#" && (out == "" || out ~ /[ \n]$/)) { cmt = 1; continue }
    if (c == "\"" || c == "'") {
      t = out; sub(/[ ]+$/, "", t); sub(/.*[ \n]/, "", t)
      q = c; qb = ""; keep = (t == "" || t ~ /^-[A-Za-z]*c$/ || t ~ /^(-Command|-command|\/[cC]|-C|eval|checkout)$/)
      sp = (t ~ /^(-C|cd|chdir|pushd|sl|[Ss]et-[Ll]ocation|[Pp]ush-[Ll]ocation|-Path|-LiteralPath|--git-dir=?|--work-tree=?)$/)
      out = out " "; raw = c; continue
    }
    if (c == "<" && substr(s, k + 1, 1) == "<" && substr(s, k + 2, 1) != "<") {
      w = substr(s, k + 2); sub(/^-/, "", w); sub(/^[ ]*/, "", w); sub(/^(\\"|')/, "", w)
      t = out; sub(/[ ]+$/, "", t); sub(/.*[ \n\/]/, "", t) # a shell or interpreter reads the body as commands
      if (t !~ /^(bash|sh|zsh|dash|ksh|pwsh|powershell|python3?|node|eval|xargs)$/ && match(w, /^[A-Za-z_][A-Za-z0-9_]*/))
        pend = substr(w, 1, RLENGTH)
      k++; out = out " "; raw = " "; continue
    }
    if (c ~ /[;&|]/) { out = out "\n"; raw = c; continue }
    if (c ~ /[()`<>]/) { out = out " "; raw = c; continue }
    out = out c; raw = c
  }
  print out qb
}
AWK

b='(^|[^A-Za-z0-9_-])'
SECRET="-----BEGIN ([A-Z]+ )*PRIVATE KEY-----|${b}AKIA[0-9A-Z]{16}|${b}gh[pousr]_[A-Za-z0-9]{36}"
SECRET="$SECRET|${b}github_pat_[A-Za-z0-9_]{50,}|${b}glpat-[A-Za-z0-9_-]{20}|${b}sk-[A-Za-z0-9_-]{32,}"
SECRET="$SECRET|${b}xox[abprs]-[A-Za-z0-9-]{10,}|${b}AIza[0-9A-Za-z_-]{35}|${b}[0-9]{8,10}:AA[A-Za-z0-9_-]{33}"
SECRET_WHY='VULYK guard: this looks like a credential (key, token or private key). Put [REDACTED] or an environment variable reference instead of the value'

case "$input" in
  *'"tool_name":"Bash"'* | *'"tool_name": "Bash"'* | *'"tool_name":"PowerShell"'* | *'"tool_name": "PowerShell"'*) ;;
  *)
    if values 'content|new_string|new_source' | LC_ALL=C grep -qE -e "$SECRET"; then decide deny "$SECRET_WHY."; fi
    exit 0 ;;
esac

cwd=$(values cwd | head -n 1)
cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
start=$PWD
LOSS='VULYK guard: this git command would throw away uncommitted work. Commit or stash it first, or ask the owner to run it with the ! prefix.'
PUBLISH='VULYK guard: publishing (push, release, publish) needs the word of the owner for this step: the owner approves this prompt, or runs the command with the ! prefix.'
OUTSIDE='VULYK guard: this git command works in a repository that is not the project, and the guard runs no git there before approval (its config may run code). The owner approves this prompt, or runs the command with the ! prefix.'
abs() { case "$1" in *$'
'* | '') return 1 ;; /* | [A-Za-z]:/*) return 0 ;; esac; return 1; } # git < 2.31: no
pc=$(git -C "${CLAUDE_PROJECT_DIR:-$start}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
abs "$pc" || pc=''
G() { git --no-optional-locks -c core.fsmonitor=false "$@"; } # every probe; rev-parse runs no repository code

ours() { # $1 = dir; g = --git-dir/--work-tree. True for the project's repository (worktrees and submodules
  # included) or none at all. Another repository's config may run code (core.fsmonitor, filters): ask instead.
  local c; c=$(git -C "$1" "${g[@]}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 0
  [ -n "$c" ] || return 0
  if [ -n "$pc" ] && abs "$c"; then case "$c/" in "$pc/"*) return 0 ;; esac; fi
  [ -n "$ask" ] || ask=$OUTSIDE
  return 1
}

dirty1() { # $1 = repo dir, $2 = all (untracked files count too) or ignored (ignored ones too); g = git's
  local o=--porcelain # --git-dir and --work-tree from the command, so the tree it touches is the one checked
  ours "$1" || return 1
  [ "${2:-}" = ignored ] && o="--porcelain --ignored"
  o="$o --ignore-submodules=dirty" # a repository embedded in the project is not probed through it
  if [ -n "${2:-}" ]; then G -C "$1" "${g[@]}" status $o 2>/dev/null | grep -q .
  else G -C "$1" "${g[@]}" status $o 2>/dev/null | grep -qv '^??'; fi
}
dirty() { # a followed cd may have ended (subshell, popd, cd -): the tree the command started in is checked too
  local here=$PWD r=1
  dirty1 "$@" && return 0
  [ "$PWD" != "$start" ] && cd "$start" 2>/dev/null && { dirty1 "$@"; r=$?; cd "$here"; }
  return $r
}

leaks() { # $1 = repo dir (ours), $2 = wide (working tree and untracked files) or narrow (the index); g as in
  local d base=--cached f # dirty1; prints files, named from the top of the tree
  d=$(git -C "$1" "${g[@]}" rev-parse --show-toplevel 2>/dev/null) || return 0
  if [ "$2" = wide ]; then
    git -C "$1" "${g[@]}" rev-parse -q --verify HEAD >/dev/null 2>&1 && base=HEAD
    G -C "$1" "${g[@]}" ls-files -oz --exclude-standard --full-name -- ':/' |
      (cd "$d" && LC_ALL=C xargs -0 grep -lE -e "$SECRET" -- 2>/dev/null)
  fi
  G -C "$1" "${g[@]}" diff --ignore-submodules=dirty "$base" --name-only -z 2>/dev/null | while IFS= read -r -d '' f; do
    G -C "$1" "${g[@]}" diff --no-ext-diff --no-textconv "$base" -- ":(top,literal)$f" | grep '^+' |
      LC_ALL=C grep -qE -e "$SECRET" &&
      echo "$f"
  done
}

TOOLS=' git gh docker podman npm pnpm yarn bun uv poetry cargo hatch flit twine gem '
ask='' wide=''
set -f
ps=0; case "$input" in *'"tool_name":"PowerShell"'* | *'"tool_name": "PowerShell"'*) ps=1 ;; esac
segments=$(values command raw | awk -v ps="$ps" "$SPLIT")
judge() { # $1 = index of a tool word in w; $2 = full (every check) or publish (only the publish question)
  local i=$(($1 + 1)) tool dir=. sub a first x hit new files m t=${w[$1]##*/}
  local -a g=()
  t=${t##*\\}; tool=${t%.exe}; tool=${tool%.EXE}
  if [ "$tool" = git ]; then # skip git's global options; keep -C, --git-dir and --work-tree
    while [ "$i" -lt "$n" ]; do
      case "${w[$i]}" in
        -C) dir=${w[$((i + 1))]:-.}; i=$((i + 2)) ;;
        --git-dir | --work-tree) g+=("${w[$i]}=${w[$((i + 1))]:-}"); i=$((i + 2)) ;;
        --git-dir= | --work-tree=) g+=("${w[$i]}${w[$((i + 1))]:-}"); i=$((i + 2)) ;; # a quoted value
        --git-dir=* | --work-tree=*) g+=("${w[$i]}"); i=$((i + 1)) ;;
        -c | --namespace) i=$((i + 2)) ;;
        -*) i=$((i + 1)) ;;
        *) break ;;
      esac
    done
  fi
  sub=${w[$i]:-} args=("${w[@]:$((i + 1))}")
  a=" ${args[*]:-} " first=${args[0]:-}

  # 2. publishing, for every tool word in the command
  case "$tool:$sub" in
    git:push | docker:push | podman:push | twine:upload | gem:push) ask=$PUBLISH ;;
    gh:release) case "$first" in create | upload | edit | delete) ask=$PUBLISH ;; esac ;;
    gh:pr) case "$first" in create | merge) ask=$PUBLISH ;; esac ;;
    docker:compose | podman:compose) case "$first:$a" in push:* | *" --push "*) ask=$PUBLISH ;; esac ;;
    gh:repo | docker:* | podman:*) case "$a" in *" --push "*) ask=$PUBLISH ;; esac ;;
    npm:* | pnpm:* | yarn:* | bun:* | uv:* | poetry:* | cargo:* | hatch:* | flit:*)
      case " $sub $a" in *" publish "*) ask=$PUBLISH ;; esac ;;
  esac
  [ "$2" = full ] || return 0

  case "$tool:$sub" in
    # 1. uncommitted work
    git:stash) case "$first" in drop | clear) decide deny "$LOSS" ;; esac ;;
    git:reset) case "$a" in *" --hard "*) dirty "$dir" && decide deny "$LOSS" ;; esac ;;
    git:checkout | git:switch)
      hit='' new=''
      for x in "${args[@]:-}"; do
        case "$x" in
          -- | . | -f | --force | --discard-changes | -p | --patch) hit=1 ;;
          -b | -B | --orphan | -c | -C) new=1 ;; # the next word is a new branch name, not a path
          -*) ;;
          *) [ -z "$new" ] && [ "$sub" = checkout ] && [ -n "$x" ] && [ -e "$dir/$x" ] && hit=1; new='' ;;
        esac
      done
      [ -n "$hit" ] && dirty "$dir" && decide deny "$LOSS" ;;
    git:restore)
      case "$a" in
        *" --staged "* | *" -S "*) case "$a" in *" --worktree "* | *" -W "*) dirty "$dir" && decide deny "$LOSS" ;; esac ;;
        *) dirty "$dir" && decide deny "$LOSS" ;;
      esac ;;
    git:clean)
      for x in "${args[@]:-}"; do case "$x" in -n | --dry-run | -[A-Za-z]*n*) return 0 ;; esac; done
      m=all # -x and -X also delete ignored files (.env, local state)
      for x in "${args[@]:-}"; do case "$x" in --*) ;; -*[xX]*) m=ignored ;; esac; done
      for x in "${args[@]:-}"; do case "$x" in --force | -f* | -[A-Za-z]*f*) dirty "$dir" "$m" && decide deny "$LOSS" ;; esac; done ;;
    git:worktree) case "$first:$a" in remove:*" --force "* | remove:*" -f "*) decide deny "$LOSS" ;; esac ;;
    git:rm | git:checkout-index)
      case "$a" in *" --cached "* | *" --temp "*) return 0 ;; esac # the tree is left alone
      case "$a" in *" --prefix=../"*) return 0 ;; esac # only an export clearly outside the tree is let through
      for x in "${args[@]:-}"; do case "$x" in --force | -f* | -[A-Za-z]*f*) dirty "$dir" && decide deny "$LOSS" ;; esac; done ;;
    git:read-tree) case "$a" in *" --reset "*) [[ $a =~ \ -[A-Za-z]*u[A-Za-z]*\  ]] && dirty "$dir" && decide deny "$LOSS" ;; esac ;;
    git:add | git:stage) wide=1 ;;
    # 3. secrets in a commit. The hook runs before the command: an earlier `git add` in the same command, or a
    # commit that may take files itself (-a, -i, -o, paths, any long option not known to be safe), is judged on
    # everything that could go in.
    git:commit)
      for x in "${args[@]:-}"; do
        case "$x" in
          --amend | --message* | --allow-empty* | --no-verify | --signoff | --author* | --date* | --file* | \
          --no-edit | --edit | --quiet | --verbose | --fixup* | --squash* | --cleanup* | --gpg-sign* | \
          --no-gpg-sign | --trailer* | --reset-author | --status | --no-status | --reuse-message* | --reedit-message*) ;;
          --*) wide=1 ;;
          -*[aio]*) wide=1 ;;
          -*) ;;
          *) [ -n "$x" ] && [ -e "$dir/$x" ] && wide=1 ;;
        esac
      done
      ours "$dir" || return 0
      files=$(leaks "$dir" "$([ -n "$wide" ] && echo wide || echo narrow)" | sort -u | tr '\n' ' ' |
        LC_ALL=C tr -d '"\\\000-\037\177')
      [ -n "$files" ] && decide deny "$SECRET_WHY. Files: ${files% }" ;;
  esac
}

while IFS= read -r seg; do
  IFS=$' \t' read -r -a w <<<"$seg"
  n=${#w[@]} i=0 mode=full
  [ "$n" -gt 0 ] && w=("${w[@]//$'\037'/ }")
  case "${w[0]:-}" in # follow cd, so the tree a later git command touches is the one checked
    cd | chdir | pushd | sl | [Ss]et-[Ll]ocation | [Pp]ush-[Ll]ocation)
      x=-; for a in "${w[@]:1}"; do case "$a" in -*) ;; *) x=$a; break ;; esac; done
      [ "$n" -eq 1 ] && x=$HOME
      case "$x" in '~'*) x=$HOME${x#\~} ;; esac
      [ "$x" = - ] || cd -- "$x" >/dev/null 2>&1 ;; # CDPATH would print the dir before the decision
  esac
  while [ "$i" -lt "$n" ]; do # every known tool word, with any path and .exe stripped
    t=${w[$i]##*/}; t=${t##*\\}; t=${t%.exe}; t=${t%.EXE}
    case "$TOOLS" in *" $t "*) judge "$i" "$mode"; mode=publish ;; esac
    i=$((i + 1))
  done
done <<EOF
$segments
EOF

[ -n "$ask" ] && decide ask "$ask"
exit 0
