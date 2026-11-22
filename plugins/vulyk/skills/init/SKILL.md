---
name: init
description: One-time VULYK setup in a project - a short rules block in CLAUDE.md, ask/deny permission rules for publishing, and the lessons file. Use when the owner runs /vulyk:init in a new or migrating project.
disable-model-invocation: true
---

Set up VULYK in this project. Talk to the owner in their language. Show every change before writing it, and
write nothing outside the files below.

## 1. Look first

Read `CLAUDE.md`, `.claude/settings.json`, `.claude/rules/` and `.claude/vulyk-version` if they exist.
Files of the old VULYK (`scripts/cycle.sh`, `.claude/commands/vulyk-*.md`, VULYK hooks in settings.json)
mean a migration: stop and tell the owner; migration is a separate step, not this one.

## 2. CLAUDE.md block

Keep everything the project wrote. Add or replace only the block between the two marker lines:

```
<!-- vulyk:begin -->
## VULYK
- Work goes plan -> owner approval -> build -> review -> ship: `/vulyk:plan`, `/vulyk:build`,
  `/vulyk:review`, `/vulyk:ship`. Small obvious fixes skip it.
- Specs live in `docs/specs/<slug>/`: `brief.md` keeps the owner's words verbatim and is the contract.
- Publishing (push, tag, release, deploy) only on the owner's explicit word, each step named.
- Never discard uncommitted work: no `git reset --hard`, `git checkout -- .`, `git clean -f` or
  `git stash drop` on changes that are not committed elsewhere. Ask.
- When the owner corrects your work and says why, record the lesson as a rule: a line in
  `.claude/rules/lessons.md` (at most 60 lines; merge or drop old lines to stay under), or a
  `.claude/rules/<topic>.md` with `paths:` when it applies to certain files. No new hooks or scripts for it:
  a check the project wants goes into its own tests.
<!-- vulyk:end -->
```

## 3. Permissions

Merge into `.claude/settings.json` (create it if missing; keep every existing key and rule):

```json
{
  "permissions": {
    "deny": ["Bash(git push --force*)", "Bash(git push -f*)", "Bash(git push --tags*)",
             "Bash(git push --mirror*)"],
    "ask": ["Bash(git push*)", "Bash(git tag*)", "Bash(gh release*)", "Bash(npm publish*)"]
  }
}
```

These rules catch honest mistakes, not a determined bypass; the plugin's hooks add the rest.

## 4. Lessons and marker

- `.claude/rules/lessons.md`: create with the line `# Lessons` and nothing else, if missing.
- `.claude/vulyk-version`: write `thin <version>`, the version `claude plugin list` shows for
  `vulyk@vulyk-thin`.

## 5. Commit

`git add CLAUDE.md .claude/settings.json .claude/rules/lessons.md .claude/vulyk-version` and commit
`chore: set up VULYK`. Only after the owner has seen the changes and said yes.
