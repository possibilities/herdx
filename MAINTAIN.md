# herdr fork maintenance

This repository delivers and maintains our fork of
[`herdrdev/herdr`](https://github.com/herdrdev/herdr) for one purpose: the
`agentstate` crate and binary, which reproduce herdr's Claude Code and Codex
agent state detection for agent development environments that are not herdr.
`/maintain` — the shared `maintain` skill — runs a maintenance cycle from this
file; this file is the whole of what that skill knows about herdr.

## Purpose

Keep a published `integration` branch of herdr that carries the
`crates/agentstate` workspace member below, rebuilt on current upstream every
cycle, and installed on this machine as `~/.local/bin/agentstate` by this
repository's own installer. The fork is not a place to develop herdr: nothing
in herdr's own behavior is changed, and no herdr binary is built or
installed from it. A maintenance cycle exists so that upstream's manifest and
engine changes reach `agentstate` unmodified, since the crate compiles
herdr's detection source by path rather than carrying a copy.

## Upstream

- Bound checkout: `~/source/herdrdev--herdr`. `upstream` is `herdrdev/herdr`; `fork` is
  `possibilities/herdr`. Upstream's default branch is `master`. Read
  `~/source/herdrdev--herdr/CLAUDE.md` completely before touching herdr; it is the
  upstream guidance file. The bound checkout is also the shared checkout
  behind this machine's herdr-managed worktrees under `~/.herdr/worktrees/`,
  so it stays on `master` and is never checked out to `integration`.
- Contribution stance: downstream-only. herdr's guidance closes unsolicited
  implementation pull requests automatically and reserves contribution for
  listed accounts; we are not on that list and do not offer anything. The
  crate is a consumer of herdr's Apache-2.0 source, attributed in its
  `NOTICE`. A future upstream conversation would be a deliberate project
  decision outside a maintenance cycle.
- Upstream facts that matter to the carry: Claude Code and Codex are
  screen-manifest agents in herdr (their hooks report session identity
  only; state comes from the screen and OSC title), the manifest engine
  version is `MANIFEST_ENGINE_VERSION` in `src/detect/manifest_update.rs`,
  and the stabilization constants live in `src/pane/agent_detection.rs`.
  Watch every cycle for changes to `src/detect/manifest.rs`,
  `src/detect/manifests/claude.toml`, `src/detect/manifests/codex.toml`,
  `src/pane/agent_detection.rs`, the `AgentDetection` and `AgentState`
  types in `src/detect/mod.rs`, and the internal symbols the crate's shim
  mirrors. A shim compile failure is the expected signal that one moved.
- "Landed" does not apply: nothing is offered upstream. A carried feature is
  retired only if upstream ships an equivalent standalone crate or binary
  that agentmux can consume, decided by reading and exercising it.

## Branch model

- Mirror branch: `master`, an exact mirror of `herdrdev/herdr:master`
  locally and on the fork. Never an integration base with downstream-only
  commits.
- Integration branch: `integration`, every carried feature together. It is
  the only ref the installer builds from and never a development branch of
  its own: work lands on it through a rebased candidate.
- Composition: linear stack. `integration` is one linear series of commits
  above `upstream/master`, rebased as a whole onto current upstream in a
  scratch worktree every cycle, with each commit's subject the marker the
  inventory below refers to. There are no carry branches. A feature is
  repaired by editing its commit in place during the rebase; a new feature
  is a new commit at the top of the stack.
- Publication: standing authorization. Pushing `integration` to `fork` needs
  no per-cycle approval. A green gate on the exact candidate commit is the
  authority that permits it; an unproved candidate is never published. This
  authorizes only `fork/integration` and the `fork/master` mirror.
- Installation: immediate. A published Integration is installed as part of
  landing it with `scripts/install.sh --install --sha <published sha>`.
- Deletion marker prefix: `DELETEME/`. Creating, moving, or removing
  `DELETEME/<original-name>` requires an explicit human decision naming that
  branch. Maintenance never infers deletion. Every undeclared fork head
  remains unchanged.
- Open pull-request heads: not preserved. There are none.
- Rerere: not relied on. The stack is small and rebases are meant to be
  read; a recorded resolution would hide exactly the engine drift a cycle
  exists to notice.
- `scripts/reconcile-branches.sh` is this repository's entrypoint to the
  shared branch script; it declares these values and nothing else.
- Supervision: `scripts/reconcile-branches.sh --configure-supervision`
  converges this model into the bound checkout's own `supervisor.*` git
  config; `--check-supervision` verifies it.

## Features

Every feature is a commit in the stack; the scratchpad records which.
Absence is work. Work that adds a feature writes its entry in the same
change; an unrecorded feature is unfinished.

### Workspace crate

- The root `Cargo.toml` declares a `[workspace]` with member
  `crates/agentstate`. The crate builds with `cargo build -p agentstate`
  from a herdr checkout without building herdr itself and without Zig; its
  dependencies are `regex`, `serde`, `serde_json`, and `toml`, all already
  in herdr's lock file. It carries herdr's `LICENSE` and a `NOTICE` naming
  every herdr file it compiles.

### Engine by path include

- `crates/agentstate/src/detect/mod.rs` includes
  `src/detect/manifest.rs` by `#[path]`, and `crates/agentstate/src/lib.rs`
  includes `src/pane/agent_detection.rs` the same way. Neither herdr file
  is copied or modified; the bundled manifests are reached through
  `manifest.rs`'s own `include_str!` list. The library disables unit tests
  (`[lib] test = false`) because `manifest.rs` declares `#[cfg(test)] mod
  tests;`, which a path-included module cannot resolve; every test lives
  under `tests/`.

### Two-agent shim

- The crate's `config`, `detect`, `detect::manifest_update`, and `terminal`
  modules provide exactly the herdr-internal symbols the included files
  reach for: `config_dir`, the `Agent` enum with `ALL`,
  `SCREEN_MANIFEST_AGENTS`, `agent_label`, `parse_agent_label`,
  `AgentDetection`, `AgentState`, `detect_agent_with_osc`,
  `ManifestVersion` (verbatim), `MANIFEST_ENGINE_VERSION` (equal to
  herdr's), `AgentRemoteStatus`, `load_status`, `remote_manifest_path`, and
  `stabilize_agent_detection`. `Agent` has only `Claude` and `Codex`. Local
  overrides are read from `$AGENTSTATE_CONFIG_DIR/agent-detection/`,
  never from herdr's config directory. No remote manifest is ever fetched.

### Tracker timing parity

- `agentstate::Tracker` tracks any number of sessions with an explicit
  `Instant` clock and herdr's own policy functions: `Unknown` published at
  session start, a 3 s startup grace during which screens are held, the
  working-to-plain-idle hold that needs three 100 ms rechecks or 700 ms,
  transcript viewers that hold the previous state, OSC values retained until
  replaced, and publication on state change only. There is no standing
  blocker republish. `exit` drops a session and its timers without
  publishing.

### JSONL command line

- `agentstate explain --agent claude|codex --screen FILE [--osc-title T]
  [--osc-progress P]` prints herdr's explain JSON. `agentstate track` is a
  long-lived multi-session process: input lines carry `session` plus
  `agent` and `started`, or `screen` with optional `osc_title` and
  `osc_progress` (absent means unchanged, null means empty), or `exited`;
  output lines are `{session, state, rule, ts_ms}` on state change only;
  a malformed line is one stderr message and is skipped; stdout carries
  nothing but JSONL. `agentstate --version` prints the crate version and
  the herdr commit baked in through `AGENTSTATE_HERDR_SHA` at build time.

### Golden suite and fixtures

- `tests/golden.rs` carries the Claude and Codex cases from herdr's
  `src/detect/manifest/tests.rs` as assertions on state and rule id, plus
  `fixture_index_verdicts`, which checks every `tests/fixtures/<agent>/*.txt`
  screen against its sibling `.toml` expectation. `tests/tracker.rs` proves
  the timing policy with a fake clock. `tests/cli.rs` exercises the binary
  end to end. Consumer-contributed tmux captures are added as fixtures, and
  a fixture that changes verdict after an upstream rebase is a finding for
  the cycle, not a test to update silently.

## Gate

From the candidate worktree, run:

```sh
~/code/herdx/scripts/gate.sh --worktree "$candidate_worktree"
```

It runs `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`,
`cargo test`, and a release build, all scoped to `-p agentstate`, then runs
the fresh binary's `explain` against a fixture and `--version`, and checks
that `NOTICE` names every path-included file. It builds with
`CARGO_TARGET_DIR=$HOME/.cache/herdx/target` so cycle worktrees share
compiled dependencies. herdr's own `just check` is not part of the gate:
herdr needs Zig 0.15.2 and nothing in the stack changes herdr's behavior. If
a cycle ever touches a herdr source file, run `just check` in the candidate
as well and record it.

## Consumer

The installer. After the leased push succeeds, run:

```sh
~/code/herdx/scripts/install.sh --install --sha "$integration_sha"
```

It fetches `fork`, proves the SHA is on `fork/integration`, builds the crate
release from that exact commit in a detached temporary worktree of the
bound checkout with `AGENTSTATE_HERDR_SHA` set, atomically replaces
`~/.local/bin/agentstate`, writes commit and digest receipts under
`~/.local/state/herdx/`, and removes the worktree. It never changes the
bound checkout's branch.

agentmux (`~/code/agentmux`) is the consumer. It spawns
`agentstate track` from `PATH` and treats absence as every agent unknown;
it holds no pin, so the cycle is complete once the installer's receipt names
the published SHA. Tell the agentmux owner over the bus when a cycle changes
a verdict, the protocol, or a fixture.

## Notify

- Title: `herdr Maintenance`
- Group: `herdx.maintain`
