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
Then run `/vulyk:init` once in the project.

## Commands

| Command | What it does |
|---|---|
| `/vulyk:init` | One-time setup: rules block in `CLAUDE.md`, ask/deny rules for publishing, lessons file |
| `/vulyk:plan <request>` | Brief with the owner's words, plan with stories, one approval stop |
| `/vulyk:build <slug>` | Builds the approved stories on `vulyk/<slug>`, then starts the review |
| `/vulyk:review <slug>` | One round by the `reviewer` agent on Fable; sees the brief and the code only |
| `/vulyk:ship <slug>` | Local merge after a PASS; prints the publish commands |

Size limits and scope are in `CLAUDE.md`. Only `plugins/vulyk/` ships to a project.
