---
name: ship
description: Merge a reviewed VULYK spec branch into the default branch locally and print the publish commands for the owner. Never publishes. Use when the owner runs /vulyk:ship.
argument-hint: <spec slug>
disable-model-invocation: true
---

Ship: "$ARGUMENTS". Talk to the owner in their language.

## 1. Check

Stop and tell the owner when any of these fails:
- the last round in `docs/specs/<slug>/review.md` is PASS and its head is `git rev-parse vulyk/<slug>`
  (a commit after the review needs a new round, unless it only touches `docs/specs/<slug>/`);
- every story in plan.md is ticked or listed under `## Descoped`;
- `git status --porcelain` is empty.

## 2. Merge

1. `git switch <default branch>`, then `git merge --no-ff vulyk/<slug> -m "ship(<slug>): <title>"`.
   A conflict: stop, show the files, ask. Never resolve by taking one side wholesale.
2. Run the plan's test command on the merge. Red: `git reset --hard ORIG_HEAD` is allowed here only
   because the tree was clean in step 1; tell the owner what failed.
3. Add `**Shipped:** <date>, <merge sha>` under the title of plan.md and commit it.

The branch stays until the owner deletes it.

## 3. Publish

Print, in a code block, the commands that would publish this, each on its own line: the push of the default
branch and, when the project versions releases, the tag and its push. Name each step in one line.

Do not run them. Publishing (push, tag, release, deploy) happens only on the owner's explicit word in this
session, one named step at a time. "Ship" is not that word.
