# herdx context

**Workshop** — This repository, which owns the specification (`MAINTAIN.md`),
maintenance state, gate, and installer for the local herdr fork; the
maintenance procedure itself is the shared `maintain` skill.
_Avoid_: wrapper, patch repo.

**agentstate** — The crate and binary at `crates/agentstate` on the
integration branch: herdr's Claude Code and Codex detection compiled by path,
a two-agent shim, a clock-driven tracker, and a JSONL command line.
_Avoid_: herdr-lite, state daemon.

**Integration branch** — `possibilities/herdr:integration`, upstream
`master` plus the linear stack that adds agentstate, and the only source the
installer builds.
_Avoid_: install branch, local main.

**Mirror branch** — Local `master` and `possibilities/herdr:master`, both
fast-forwarded to the exact current `herdrdev/herdr:master` every cycle. Also
the branch the bound checkout stays on.
_Avoid_: main, integration base.

**Path include** — The `#[path]` module attribute by which the crate compiles
`src/detect/manifest.rs` and `src/pane/agent_detection.rs` from the enclosing
herdr checkout without copying them.
_Avoid_: vendored copy, sync.

**Shim** — The crate modules that provide the herdr-internal symbols the
path-included files reach for. A shim compile failure after a rebase is the
cycle's signal that herdr moved something.
_Avoid_: polyfill, stub.

**Snapshot** — One observation of a session: screen text, OSC title, OSC
progress. The tracker keeps the last one per session and re-evaluates it from
its own timer.
_Avoid_: frame, capture (that is the consumer's act, not the tracker's input).

**Transition** — One published state change: session, state, rule, time.
_Avoid_: event, update.

**Consumer** — agentmux, which spawns `agentstate track` and feeds it every
agent it runs.
_Avoid_: client, customer.
