# Phase: build

## 1. Preconditions

Read the spec's `brief.md` and `plan.md`. `**Approved:**` must hold the owner's words; otherwise go back to
`plan.md`, step 6. `git switch vulyk/<slug>`. When `git status --porcelain` shows changes outside this spec,
ask whether to commit or stash them. Never discard them.

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

Parallel workers are only for stories whose files do not overlap and that each take real work. Dispatch one
`vulyk:worker` agent per such story, all in one message. Each gets: the brief path, the spec branch, its
story block verbatim, the test command, and the absolute path of this checkout (its worktree has no ignored
files such as `.venv` or `node_modules`). Each returns its branch and commit. For each: merge its branch into
`vulyk/<slug>`, run the test command, then `git worktree remove <its worktree>` and `git branch -d <its
branch>`. Tick the stories and commit.

## 3. Scope changes

The plan is the contract. When a story cannot be done as written:
- a smaller ask: only the owner removes a requirement. Ask; on yes add a `## Descoped` line in plan.md
  quoting their words, strike the ask in brief.md, commit both;
- a different design: stop and show the owner what you found and what you propose.

## 4. Done

When every story is ticked and the test command is green, go on to `review.md`. Never push, never touch the
default branch: the ship phase merges.
