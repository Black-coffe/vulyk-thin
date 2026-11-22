# Phase: review

## 1. Round

Read the spec's `review.md` if it exists; the round number is the number of `## Round` headings plus one. At
most two rounds per spec. Before every round after the second, unless an `Owner: one more round` line already
follows the last round, show the owner the open findings and ask with
`AskUserQuestion`: one more round, ship as is, re-plan. Their answer is recorded under the last round as
`Owner: <one more round | ship as is | re-plan> - "<their words>", <date>` and committed.

The reviewer works in this checkout, so leave it clean and on the spec branch: `git switch vulyk/<slug>`,
`git status --porcelain` empty. Collect:
- base: `git merge-base <default branch> vulyk/<slug>`;
- head: `git rev-parse vulyk/<slug>`;
- round 2 and later: `since`, the head the previous round judged (written in review.md).

## 2. Dispatch

Dispatch one `vulyk:reviewer` agent with exactly these lines and nothing else:

```
brief: <specs>/<slug>/brief.md
specs: <specs>
base: <sha>
head: <sha>
since: <sha, round 2 and later>
open findings: <round 2 and later: the previous round's findings verbatim, numbered F1, F2..., minus those
  the owner kept>
test command: <from plan.md>
```

Never pass plan.md, story text, your summary of the work, or your opinion of it. The reviewer judges the
code against the owner's asks; what you believe about the code is what it checks. Do not edit files while it
runs.

The reviewer runs on Fable, a different family from the Opus builder. If Fable is unavailable (a usage limit
or an error), stop and tell the owner. Never review with the builder's model instead.

## 3. Record and act

`VERDICT: NOT RUN` (the checkout was not at head) is not a round: record nothing, fix the checkout, dispatch
again once. The same for a report with no `VERDICT:` line, or one that leaves a past finding's number without
an answer: dispatch again once, then tell the owner. Otherwise append the report to the spec's `review.md` under `## Round <n> - <date> - head <full
sha>`, verbatim, and commit: `git commit -m "review(<slug>): round <n> <PASS|BLOCK>"`. That commit touches
only the spec directory, so the head stays reviewed.

- PASS: tell the owner, quote any minor findings, and go on to `ship.md`.
- BLOCK in round 2 or later: ask the owner first (step 1); fix only on "one more round".
- BLOCK: dispatch one `vulyk:builder` with the brief and plan paths, the test command, and `findings: round
  <n>` followed by the round's major findings and its "not delivered" or "partly" ask lines, verbatim. It
  turns each finding's test into the red test, fixes, commits, and reports. Read only its report, then check
  the tree is clean as in `build.md`. A `DISPUTED` finding: write why under the round and ask the owner with
  `AskUserQuestion`. "Fix it": dispatch the builder again with the owner's words as final. "Keep the code":
  record their words; that finding is left out of later `open findings`. Then run the next round.
