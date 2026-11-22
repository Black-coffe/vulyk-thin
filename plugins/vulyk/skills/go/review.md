# Phase: review

## 1. Round

Read the spec's `review.md` if it exists; the round number is the number of `## Round` headings plus one. At
most two rounds per spec. Before a third, show the owner the open findings of both rounds and ask with
`AskUserQuestion`: one more round, ship as is, re-plan. "Ship as is" is recorded under the last round as
`Owner: ship as is - "<their words>", <date>` and committed.

The reviewer works in this checkout, so leave it clean and on the spec branch: `git switch vulyk/<slug>`,
`git status --porcelain` empty. Collect:
- base: `git merge-base <default branch> vulyk/<slug>`;
- head: `git rev-parse vulyk/<slug>`;
- round 2: `since`, the head round 1 judged (written in review.md).

## 2. Dispatch

Dispatch one `vulyk:reviewer` agent with exactly these lines and nothing else:

```
brief: docs/specs/<slug>/brief.md
base: <sha>
head: <sha>
since: <sha, round 2 only>
open findings: <round 2 only: round 1's findings verbatim>
test command: <from plan.md>
```

Never pass plan.md, story text, your summary of the work, or your opinion of it. The reviewer judges the
code against the owner's asks; what you believe about the code is what it checks. Do not edit files while it
runs.

The reviewer runs on Fable, a different family from the Opus builder. If Fable is unavailable (a usage limit
or an error), stop and tell the owner. Never review with the builder's model instead.

## 3. Record and act

Append the report to the spec's `review.md` under `## Round <n> - <date> - head <short sha>`, verbatim, and
commit: `git commit -m "review(<slug>): round <n> <PASS|BLOCK>"`. That commit touches only the spec
directory, so the head stays reviewed.

- PASS: tell the owner, quote any minor findings, and go on to `ship.md`.
- BLOCK: fix each major finding on the branch (test first when it is a logic bug), commit, and run the next
  round. A finding you disagree with: say why in review.md under the round and let the owner decide; do not
  silently skip it.
