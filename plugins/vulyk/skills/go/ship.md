# Phase: ship

## 1. Check

Stop and tell the owner when any of these fails:
- the last round in the spec's `review.md` is PASS, or the owner's "ship as is" words follow it;
- that round's head is `git rev-parse vulyk/<slug>`, or every commit since touches only `<specs>/<slug>/`
  (`git diff --name-only <round head>..vulyk/<slug>`); anything else needs a new round;
- every story in plan.md is ticked or listed under `## Descoped`;
- `git status --porcelain` is empty.

A document spec (a `report.md`, no plan.md) has no review: only the last check applies, and the question below
names the report instead of a round.

## 2. Ask

Ask the owner with `AskUserQuestion`: "<slug>: review PASS, round <n>. Merge into <default branch>?", merge
first and recommended. The question quotes what a PASS can hide: the round's `TESTS:` line when it is not a
pass, the minor findings, descoped asks, findings the owner kept, and the "ship as is" words. No, or no way to
ask: stop and say the spec is ready to ship.

## 3. Merge

1. `git switch <default branch>`, then `git merge --no-ff vulyk/<slug> -m "ship(<slug>): <title>"`.
   A conflict: stop, show the files, ask. Never resolve by taking one side wholesale.
2. Run the plan's test command on the merge. Red: `git reset --hard ORIG_HEAD` is allowed here only
   because the tree was clean in step 1; tell the owner what failed.
3. Add `**Shipped:** <date>, <merge sha>` under the title of plan.md and commit it.

The branch stays until the owner deletes it.

## 4. Publish

Say plainly that merged is not live: name the plan's `Goes live:` line and what has not run yet.

Print, in a code block, the commands that would publish this, each on its own line: the push of the default
branch and, when the project versions releases, the tag and its push. Name each step in one line.

Publishing (push, tag, release, deploy) happens only on the owner's explicit word in this session, one named
step at a time; the merge question is not that word. When the owner gives it for a step, run that step yourself.
