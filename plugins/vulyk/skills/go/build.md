# Phase: build

## 1. Preconditions

Read the spec's `brief.md` and `plan.md`. `**Approved:**` must hold the owner's words; otherwise go back to
`plan.md`, step 6. `git switch vulyk/<slug>`. When `git status --porcelain` shows changes outside this spec,
ask whether to commit or stash them. Never discard them.

## 2. Stories

You orchestrate; a fresh `vulyk:builder` agent does each story, so this session does not carry the code. For
each open story (`- [ ]`), in order and one at a time, dispatch `vulyk:builder` with exactly:

```
brief: docs/specs/<slug>/brief.md
plan: docs/specs/<slug>/plan.md
story: S<n>
test command: <from plan.md>
```

Read only its report; do not read the diff or the files it wrote. Show the owner its `RED` and `TESTS` lines.
`RED` that names a missing import or module, or `none` on a story marked test first: dispatch it once more
with that line as the problem. `BLOCKED`: go to step 3. Otherwise the next story.

## 3. Scope changes

The plan is the contract. When a story cannot be done as written:
- a smaller ask: only the owner removes a requirement. Ask; on yes add a `## Descoped` line in plan.md
  quoting their words, strike the ask in brief.md, commit both;
- a different design: stop and show the owner what you found and what you propose.

## 4. Done

When every story is ticked and the last report's tests are green, go on to `review.md`. Never push, never touch the
default branch: the ship phase merges.
