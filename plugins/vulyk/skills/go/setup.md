# Phase: setup (once per project)

Show the owner every change before writing it, ask once with `AskUserQuestion` (apply first), and write
nothing outside the files named here. The result is one commit the owner can revert.

## 1. Look first

Read `CLAUDE.md`, `.claude/settings.json`, `.gitignore`, `.claude/rules/` and `.claude/vulyk-version`.
A `.claude/vulyk-manifest` file means the old VULYK is installed: do step 2 first. `git status --porcelain`
must be empty, or the owner says what to do with the changes; never discard them.

## 2. Moving from the old VULYK

The old VULYK copied its files into the project and listed them in `.claude/vulyk-manifest`. The project's
own data stays as it is: `docs/specs/`, `docs/defects/`, `memory/`, and everything the manifest does not list.

1. An old spec still in progress (a `docs/specs/*/plan.md` with open stories and no ship line): stop and ask;
   finish or park it on the old VULYK first.
2. Before removing any file: in `.claude/settings.json` remove the hook entries whose command runs a file you
   will remove, and nothing else. An old hook that fails closed on a missing script blocks every tool.
3. For each file the manifest lists, except `.claude/settings.json` (edited above): when
   `.claude/vulyk-commit` names a commit and the old VULYK repo is on this machine, compare the file with that
   commit's copy. Identical: remove it. Changed by the project: show the owner the difference and ask. No way to
   compare: show the list and ask once.
4. In `CLAUDE.md` keep every line the project wrote. The old constitution sits either in a section of it or in
   a separate file it imports (for example an `@CLAUDE.vulyk.md` line). Move the project's own blocks from
   there (its Profile, test commands, conventions) into `CLAUDE.md`, show the rest to the owner, then drop that
   section or the file and its `@` line, and add the block in step 3. Lines about removed machinery (`/vulyk-*`
   commands, librarian, defect hooks, `scripts/`) go to the owner to delete or reword; `memory/` is now an archive.
5. Remove `.claude/vulyk-manifest`, `.claude/vulyk-commit`, `.claude/vulyk-setup` and `.claude/state.json`
   if present. `docs/defects/` cards stay; turning them into rules is a later, separate step.

## 3. CLAUDE.md block

Add or replace only the block between the two marker lines:

```
<!-- vulyk:begin -->
## VULYK
- Work goes through `/vulyk:go`: brief with the owner's words, plan, one approval, build, review by
  another model family, local merge. Small obvious fixes skip it.
- Specs: `docs/specs` (each spec in `<folder>/<slug>/`; `brief.md` keeps the owner's words verbatim and is
  the contract). A project that keeps specs elsewhere writes its folder here.
- Publishing (push, tag, release, deploy) only on the owner's explicit word, each step named.
- Never discard uncommitted work: no `git reset --hard`, `git checkout -- .`, `git clean -f` or
  `git stash drop` on changes that are not committed elsewhere. Ask.
- When the owner corrects your work and says why, record the lesson as a rule: a line in
  `.claude/rules/lessons.md` (at most 60 lines; merge or drop old lines to stay under), or a
  `.claude/rules/<topic>.md` with `paths:` when it applies to certain files. No new hooks or scripts for it:
  a check the project wants goes into its own tests.
<!-- vulyk:end -->
```

## 4. Settings and files

Merge into `.claude/settings.json`, keeping every existing key and rule:

```json
{
  "extraKnownMarketplaces": {
    "vulyk-thin": { "source": { "source": "github", "repo": "Black-coffe/vulyk-thin" } }
  },
  "enabledPlugins": { "vulyk@vulyk-thin": true }
}
```

Do not add `Bash(...)` or `PowerShell(...)` permission rules: on Windows, Claude Code turns the PowerShell
tool off when a deny rule names Bash and no rule names PowerShell. Publishing is guarded by the plugin's hook.

Collaborators who clone the project get the marketplace once they trust the folder, then run
`claude plugin install vulyk@vulyk-thin --scope project` once; say so to the owner in a shared repository.

- `.claude/rules/lessons.md`: create with the line `# Lessons`, if missing.
- `.claude/vulyk-version`: `thin <version>`, the version `claude plugin list` shows for `vulyk@vulyk-thin`.

## 5. Commit

One commit after the owner's yes: `chore: set up VULYK thin` (or `chore: move to VULYK thin` after step 2).
