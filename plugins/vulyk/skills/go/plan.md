# Phase: plan

## 1. What comes back

Decide what the owner gets: changed code, or a document (a study, audit, comparison, "make me a plan").
- Small and obvious (a typo, a one-line fix, a rename): no paperwork. Say so in one line and do it.
- A document: write the brief (step 2), gather what you need as recon does (step 3), write `<specs>/<slug>/report.md`
  (findings with `file:line`, what you did not read or run, options with the recommended one first and why),
  commit it on the spec branch, show the owner its summary, then go to `ship.md` step 2 (the merge question).
  No stories, no build, no review.
- Code: go on.

When both readings are genuinely possible, ask one question.

## 2. Branch and brief

`<slug>` is a short kebab name plus the date as MMDD, e.g. `feed-retry-1122`. Start the spec branch from the
default branch, whatever is checked out now: `git switch -c vulyk/<slug> <default branch>`. Uncommitted changes
that are not yours: ask first. Write `<specs>/<slug>/brief.md`:

```
# <title> (brief)
**Date:** <YYYY-MM-DD> · **Owner:** <name>

## Request (verbatim)
> <the owner's words exactly, every line quoted; error text and stack traces too>

## Answers
<empty for now>

## Asks
1. <one testable outcome per line, in plain words>
```

Never paraphrase the request block. Before writing it, mask secrets: replace tokens, passwords, keys and
private URLs with `[REDACTED]`. Every later step traces back to `## Asks`.

## 3. Recon

This session carries everything it reads into every later call of the spec, so recon goes to agents: at most
two `Explore` agents in one message, each with `model: opus`, the brief's path and its own questions; one
follow-up agent when a report leaves open something the plan depends on. Between them they cover the files the
change touches and their tests, siblings that follow the same pattern, docs that describe the behaviour, the
command that runs the tests, how the change goes live (below), and the external facts the plan rests on
(prices, API behaviour: current official docs plus a second source). Each report gives `file:line` or a URL
with its date, short quotes, at most about 1,500 words, never whole files, and what it did not read or could
not confirm; an unconfirmed fact goes into the plan's Assumptions marked unverified. Yourself open, by any
tool (`cat` and web fetches included), only `CLAUDE.md`, `.claude/rules/` and line ranges a report cited. Run
the test command once and keep the last lines of its output: every story's `check:` must be a command that
runs today.

How the change goes live once it is merged: a scheduled run, CI, a deploy or an autorun that takes the
default branch. When the merge itself would run something live, paid or outward-facing that the brief keeps for
later, the plan says how it stays off (a switch, a flag) and that becomes an ask.

## 4. Questions

Ask only what changes the plan and that the code cannot answer, with `AskUserQuestion`: the recommended
option first, marked as recommended, with the reason in its description. At most two rounds. Record each
answer in `## Answers` as a dated line quoting the owner's choice, and adjust `## Asks`.

## 5. Plan

Write `<specs>/<slug>/plan.md`:

```
# <title> (plan)
**Brief:** [brief.md](brief.md) · **Branch:** `vulyk/<slug>` · **Approved:** no

## Goal
<one paragraph in your words>

## Assumptions
- <everything the plan rests on that the owner has not said, including what is not part of this work>
- Goes live: <what happens when this is merged>

## Stories
- [ ] S1 <title> - asks: 1, 2
  - files: <paths>
  - test first: <the behaviour the test checks and why it fails before the code, or "none: <why>">
  - check: <the command that shows it works>

## Test command
`<the project's command>`

## Descoped
(none)
```

`## Descoped` holds only asks the owner removed later, with their words; it starts as `(none)`.

Stories are review units, not tasks: one to three for most work, each one commit. Mark "test first" for
any story that adds a branch, a loop, a parser, or touches money, security or data writes. Every ask is
covered by at least one story; say which.

## 6. Approval

Commit the spec directory on the spec branch: `git add <specs>/<slug> && git commit -m "plan(<slug>): <title>"`.

Show the owner, in their language: the asks (numbered, verbatim from the brief), the stories (one line
each), the assumptions. Ask with `AskUserQuestion`: approve (first), change something. Plan mode is not
the approval: the owner may run with all permissions bypassed. Nothing mechanical checks this approval
either; it rests on this rule.

- Approved: set `**Approved:** <owner's words>, <date>` in plan.md, commit `plan(<slug>): approved`, and go
  on to `build.md` in this session.
- A change: edit the brief or the plan, commit, show again. A second change request means re-plan from
  step 2.
