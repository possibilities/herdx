# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Delivered baseline

- Last delivery: 2026-09-04 maintenance cycle.
- Upstream base and `master` mirror:
  `7916be1656d8ee9c5882b52753cd47f5e58e3e7e` (`herdrdev/herdr:master`,
  "fix: make Windows Codex prompt delay size-aware (#3552)").
- Published Integration: `a92e5af78b9d7cd45077aa9e5b36a396b44d96b0`, two
  commits above the base.
- Installed: `~/.local/bin/agentstate`, receipt
  `~/.local/state/herdx/agentstate-built-commit` naming that SHA, sha256
  `27e82a9103dfed7409dcab1f4e6a000d637ea8951e732bc6e15e9b789e631dd3`,
  reporting `agentstate 0.1.0 (herdr a92e5af78b9d7cd45077aa9e5b36a396b44d96b0)`.
- Gate as last run: `scripts/gate.sh` PASS on the exact Integration SHA;
  fmt, clippy with `-D warnings`, 31 tests (18 golden, 10 tracker, 3 cli),
  release build, explain smoke, attribution.
- Consumer: agentmux (`~/code/agentmux`) holds no pin; it picks up the
  installed binary from `PATH`. Its owner was told over the bus on
  2026-09-04 that Codex gained the `startup_update` blocked verdict.

## Audited-upstream frontier

- Frontier: `7916be1656d8ee9c5882b52753cd47f5e58e3e7e`, audited 2026-09-04.
  Every upstream commit from the founding base `b07ba9ce` through it was
  read and every carried feature assigned a disposition.
- Herdr facts verified at the frontier and relied on by the carry:
  `MANIFEST_ENGINE_VERSION` is 3; `src/detect/manifest.rs` imports
  `agent_label`, `parse_agent_label`, `Agent`, `AgentDetection`,
  `AgentState`, and `manifest_update::ManifestVersion` from its parent and
  reaches `crate::config::config_dir`,
  `manifest_update::{remote_manifest_path, load_status,
  MANIFEST_ENGINE_VERSION, AgentRemoteStatus}`; `src/pane/agent_detection.rs`
  imports `crate::detect::{Agent, AgentDetection, AgentState}` and calls
  `crate::detect::detect_agent_with_osc` and
  `crate::terminal::state::stabilize_agent_detection` (still the identity
  on `detection.state`); Claude manifest version `2026.08.31.1`, Codex
  `2026.09.05.1` (adds the `startup_update` blocked rule, priority 950,
  `bottom_non_empty_lines(20)`).

## Carried state

The stack is two commits, both features of `MAINTAIN.md` § Features:

- `d55de007` "feat(agentstate): add crate with herdr detection engine and
  tracker" — Workspace crate, Engine by path include, Two-agent shim,
  Tracker timing parity. Replayed clean onto `7916be16`; shim symbols
  re-verified against the frontier.
- `a92e5af7` "feat(agentstate): add jsonl command line and golden tests" —
  JSONL command line, Golden suite and fixtures. Repaired this cycle:
  `tests/golden.rs` gained
  `codex_startup_update_requires_complete_live_chooser`, copied from
  herdr's `src/detect/manifest/tests.rs`, so the Golden suite still
  carries every Claude and Codex case herdr has.

Retirement condition for all of them: upstream ships a standalone crate or
binary agentmux can consume with the same verdicts and timing.

## Notes

- The GitHub fork was created with every upstream head copied (about 150
  `akbash/*`, `issue/*`, `fix/*`, and similar branches). They are undeclared
  heads the reconcile script leaves untouched. Deleting them is a human
  decision; none is a `DELETEME/` marker.
- The bound checkout `~/source/herdrdev--herdr` stays on `master`. A local
  `integration` branch exists there only so the namespace check can see it;
  it is never checked out.
- Zig 0.16.0 is installed and herdr requires 0.15.2, so herdr's `just
  check` is not runnable here. The gate is crate-only by design.
- Known input-contract gap for the consumer: herdr reads `rows` rows ending
  at the last non-blank viewport row, reaching into scrollback when the
  bottom of the screen is blank; agentmux sends the visible screen. Golden
  fixtures from real tmux captures decide whether that ever changes a
  verdict.
- herdr's own manifest tests cannot compile from the path-included module,
  so `tests/golden.rs` is the parity evidence. When upstream adds a Claude
  or Codex case to `src/detect/manifest/tests.rs`, copy it.
- The shared reconcile script refuses to force-move a checked-out mirror
  and requires local `integration` to equal `fork/integration` before it
  will plan. Because the bound checkout stays on `master` and the installer
  never moves branches, a cycle fast-forwards `master` with
  `git merge --ff-only <upstream sha>` in the clean bound checkout before
  `--apply`, and after the installer runs sets `integration` with
  `git branch --force integration <published sha>` before the final
  reconciliation. Both are the moves the script itself intends.
- The candidate push refspec must be written `"${sha}:refs/heads/..."`:
  zsh treats an unbraced `$sha:r` as a modifier and mangles the refspec.

## History

- 2026-09-03: Workshop seeded. Fork `possibilities/herdr` created, `master`
  mirrored at `b07ba9ce`, Integration `c3a862db` published and installed.
  Direction agreed with agentmux over the bus: one multi-session `track`
  per Instance, per-session `agent`, `started`/`exited` lifecycle lines,
  lean state-change output, no daemon, no standing blocker republish.
- 2026-09-04: Maintenance cycle. Audited `b07ba9ce..7916be16` (7 commits;
  compare https://github.com/herdrdev/herdr/compare/b07ba9ced8b57099f038bc633ed1c9a5f5b3a1ed...7916be1656d8ee9c5882b52753cd47f5e58e3e7e):
  Codex manifest 2026.09.05.1 adds the `startup_update` blocked verdict for
  Codex's launch-time update chooser; the rest is Windows packaging and
  installer work, Codex resume-session persistence, a size-aware Windows
  Codex prompt delay in the PTY actor, and kitty graphics on by default
  under a new `terminal.kitty_graphics` key. Dispositions: 0 retire, 1
  repair (Golden suite: new Codex case), 5 unchanged. No material stance
  change; the manifest reached the crate through the path include with no
  shim edit. Mirror `7916be16` on local and fork `master`; Integration
  `a92e5af7` published under lease `c3a862db` and installed; frontier
  advanced to `7916be16`. Final reconciliation: mirror and Integration as
  declared, 151 undeclared fork heads untouched, no `DELETEME/` markers.
  Bound checkout was found re-cloned at `6045fe6a` and fast-forwarded.
