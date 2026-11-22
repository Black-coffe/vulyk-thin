---
name: build
description: Build an approved VULYK plan story by story on its own branch, test first where the plan says so, then hand over to review. Use when the owner runs /vulyk:build or approves a plan and asks to build it.
argument-hint: <spec slug>
disable-model-invocation: true
---

Build: "$ARGUMENTS". Talk to the owner in their language.

## 1. Preconditions

Read `docs/specs/<slug>/brief.md` and `plan.md`. Stop and tell the owner when:
- `**Approved:**` is `no` or missing: the plan needs `/vulyk:plan` first;
- `git status --porcelain` shows changes outside this spec: ask whether to commit or stash them. Never
  discard them.

Create or switch to the branch: `git switch vulyk/<slug>` or, when it does not exist,
`git switch -c vulyk/<slug>`.

## 2. Stories

Build the open stories (`- [ ]`) in order, yourself. For each:

1. Test first, when the story names one: write the test, run it, and show the owner the failing output in
   one or two lines. A test that passes before the code proves nothing: fix the test. A failure from a
   typo or a missing import is not the red you want; the test must fail on the missing behaviour.
2. Write the code. Stay inside the story's files; a file outside them goes into the story with a one-line
   reason.
3. Run the story's check and the plan's test command. Red means fix, not move on.
4. Tick the story (`- [x]`) and commit code, test and plan.md together:
   `git commit -m "<slug> S<n>: <title>"`.

Parallel workers are for stories whose files do not overlap and that each take real work. Dispatch one
`vulyk:worker` agent per such story, all in one message. Each gets the brief path, its story block
verbatim, and the test command. Each works in its own worktree and returns its branch and commit.
Merge each one into `vulyk/<slug>`, run the test command after every merge, tick the stories, commit.

## 3. Scope changes

The plan is the contract. When a story cannot be done as written:
- a smaller ask: only the owner removes a requirement. Ask; on yes add a `## Descoped` line in plan.md
  quoting their words, strike the ask in brief.md, commit both;
- a different design: stop and show the owner what you found and what you propose.

## 4. Done

When every story is ticked and the test command is green, run `/vulyk:review <slug>` with the Skill tool.
Report to the owner in a few lines: stories done, commits, the test command's result.

Never push. Never touch the default branch: `/vulyk:ship` merges.
