# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Delivered baseline

- Workshop seeded: 2026-09-03. Initial delivery, not a maintenance cycle.
- Upstream base and `master` mirror:
  `b07ba9ced8b57099f038bc633ed1c9a5f5b3a1ed` (`herdrdev/herdr:master`,
  "fix: reject Android in Unix installer (#3577)").
- Published Integration: `c3a862db19a540d443a0c187f5459476e167a8ad`, two
  commits above the base.
- Installed: `~/.local/bin/agentstate`, receipt
  `~/.local/state/herdx/agentstate-built-commit` naming that SHA, sha256
  `8f62c6fe6a07d843c198be7c4a4e0acc4fb68828a733e3911bb9468f1cb750d9`,
  reporting `agentstate 0.1.0 (herdr c3a862db19a540d443a0c187f5459476e167a8ad)`.
- Gate as last run: `scripts/gate.sh` PASS on the exact Integration SHA;
  fmt, clippy with `-D warnings`, 30 tests (17 golden, 10 tracker, 3 cli),
  release build, explain smoke, attribution.
- Consumer: agentmux (`~/code/agentmux`) holds no pin; its owner was told
  the binary path over the bus on 2026-09-03 and is building its `track`
  client against the protocol in `MAINTAIN.md` § JSONL command line.

## Audited-upstream frontier

- Frontier: `b07ba9ced8b57099f038bc633ed1c9a5f5b3a1ed`, the founding base.
  Every carried feature was written against this commit, so it is audited
  by construction; no upstream range has been reviewed yet.
- Herdr facts verified at the frontier and relied on by the carry:
  `MANIFEST_ENGINE_VERSION` is 3; `src/detect/manifest.rs` imports
  `agent_label`, `parse_agent_label`, `Agent`, `AgentDetection`,
  `AgentState`, and `manifest_update::ManifestVersion` from its parent and
  reaches `crate::config::config_dir`,
  `manifest_update::{remote_manifest_path, load_status,
  MANIFEST_ENGINE_VERSION, AgentRemoteStatus}`; `src/pane/agent_detection.rs`
  imports `crate::detect::{Agent, AgentDetection, AgentState}` and calls
  `crate::detect::detect_agent_with_osc` and
  `crate::terminal::state::stabilize_agent_detection`; Claude manifest
  version `2026.08.31.1`, Codex `2026.08.28.1`.

## Carried state

The stack is two commits, both features of `MAINTAIN.md` § Features:

- `3e03f51c` "feat(agentstate): add crate with herdr detection engine and
  tracker" — Workspace crate, Engine by path include, Two-agent shim,
  Tracker timing parity.
- `c3a862db` "feat(agentstate): add jsonl command line and golden tests" —
  JSONL command line, Golden suite and fixtures.

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

## History

- 2026-09-03: Workshop seeded. Fork `possibilities/herdr` created, `master`
  mirrored at `b07ba9ce`, Integration `c3a862db` published and installed.
  Direction agreed with agentmux over the bus: one multi-session `track`
  per Instance, per-session `agent`, `started`/`exited` lifecycle lines,
  lean state-change output, no daemon, no standing blocker republish.
