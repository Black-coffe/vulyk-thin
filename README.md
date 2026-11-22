# VULYK thin

Work in progress. A small Claude Code plugin for one way of working: the owner's request is kept verbatim in a
brief, a short plan gets one approval, the work is built on its own branch (test first where it matters), a model
of another family reviews it against the brief alone, and the branch is merged locally. Publishing stays a
command printed for the owner, never run without their word.

## Install (local, until the gate spec passes)

```
claude plugin marketplace add E:/Projects/vulyk-thin
claude plugin install vulyk@vulyk-thin --scope project
```

The plugin is read in place from `plugins/vulyk/`: edits apply at the next session or `/reload-plugins`.

## One command

`/vulyk:go <what to build>` starts new work; `/vulyk:go` alone continues the open spec from where it stands.
Asking in plain words to do something "through VULYK" starts it too. The spec's files decide the next step:
setup on first use, brief and plan, the owner's approval, build (a fresh `builder` agent on Opus per story, so
the main session stays small), review by the `reviewer` agent on Fable (it sees the brief and the code, never
the plan), local merge. It stops only for the owner: questions on the brief,
the approval, a third review round, the merge question, and any publishing.

What rests on rules, not on a check: the approval, test first, and the reviewer not reading the plan.

## Guard

One `PreToolUse` hook, `plugins/vulyk/hooks/guard.sh` (bash, grep, awk, git), on Bash, PowerShell and file
writes. It denies git commands that throw away uncommitted work, asks before any push, release or publish,
and denies writing or committing a credential-shaped value. It catches honest mistakes, not a determined bypass.

## Developing

Size limits and scope are in `CLAUDE.md`. Only `plugins/vulyk/` ships to a project.

```
git config core.hooksPath .githooks   # once per clone: size cap on every commit
bash tests/guard.test.sh
bash tests/size-cap.sh
```
