# VULYK thin

A thin rewrite of VULYK as a Claude Code plugin: plan -> owner approval -> build -> review by a model of
another family -> local ship. Instructions first; scripts only where a guarantee must hold.

## Hard limits (owner, 2026-11-22; raising any number takes the owner's word)
- What ships to a project: at most 1,500 lines of instructions and scripts, at most 6 scripts.
- Tests and repo-only checks: their own cap, 500 lines.
- Mechanical checks (hooks) exist only for: secret leaks, loss of uncommitted work, publishing without the
  owner's word. Every other correction becomes a rule: a `.claude/rules/*.md` file with `paths:`, or a line in
  one always-loaded rules file with its own line cap. A project that wants a check keeps it in its own tests.
- Do not port the old VULYK machinery (cycle.sh state machine, councils with sealed receipts, installer merges,
  telemetry). Read the old code for ideas only.

## Working rules
- Write to the owner in Russian. Publish (push, tag, release) only on the owner's word, each step named.
- No Sonnet or Haiku in this repo: Opus builds, Fable reviews.
- On the owner's PC the projects run the released plugin (marketplace from GitHub, autoUpdate), not this folder:
  an edit here reaches them only through a release with a new `version` in plugin.json (same version: "already
  at the latest version", seen 2026-11-26). Try a draft with `claude --plugin-dir plugins/vulyk`.
- The reasoning and numbers behind these limits: `docs/origin/study-report.md`.
