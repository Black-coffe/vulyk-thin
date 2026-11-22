---
name: review
description: One review round of a VULYK spec by a model of another family than the builder. The reviewer sees the brief and the code, never the plan or the builder's notes. Use after a build, or when the owner asks for a review of a spec branch.
argument-hint: <spec slug>
---

Review: "$ARGUMENTS". Talk to the owner in their language.

## 1. Round

Read `docs/specs/<slug>/review.md` if it exists; the round number is the number of `## Round` headings plus
one. At most two rounds per spec. A third is the owner's call: show both reports' open findings and ask with
`AskUserQuestion` (ship as is, one more round, re-plan).

Collect:
- base: `git merge-base <default branch> vulyk/<slug>`;
- head: `git rev-parse vulyk/<slug>`;
- round 2: `since`, the head round 1 judged (written in review.md).

## 2. Dispatch

Dispatch one `vulyk:reviewer` agent with exactly these lines and nothing else:

```
brief: docs/specs/<slug>/brief.md
branch: vulyk/<slug>
base: <sha>
head: <sha>
since: <sha, round 2 only>
open findings: <round 2 only: round 1's findings verbatim>
test command: <from plan.md>
```

Never pass plan.md, story text, your summary of the work, or your opinion of it. The reviewer judges the
code against the owner's asks; what you believe about the code is what it checks.

The reviewer runs on Fable, a different family from the Opus builder. If Fable is unavailable (a usage
limit or an error), stop and tell the owner. Never review with the builder's model instead.

## 3. Record

Append the report to `docs/specs/<slug>/review.md` under `## Round <n> - <date> - head <short sha>`,
verbatim, and commit: `git commit -m "review(<slug>): round <n> <PASS|BLOCK>"`.

- PASS: tell the owner, quote any minor findings, and propose `/vulyk:ship <slug>`.
- BLOCK: fix each major finding on the branch (test first when it is a logic bug), commit, then run round 2.
  A finding you disagree with: say why in review.md under the round and let the owner decide; do not
  silently skip it.
