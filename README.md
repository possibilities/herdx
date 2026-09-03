# herdx

Workshop for the operator's fork of [herdr](https://github.com/herdrdev/herdr).
The fork carries one thing: `crates/agentstate`, a Rust crate and binary that
reproduce herdr's Claude Code and Codex agent state detection for other agent
development environments, compiled from herdr's own detection source by path.

- `MAINTAIN.md` is the specification the shared `/maintain` skill executes.
- `SCRATCHPAD.md` is current maintenance state.
- `scripts/gate.sh --worktree DIR` proves a candidate.
- `scripts/install.sh --install --sha SHA` installs `~/.local/bin/agentstate`
  from the published `fork/integration` commit.
- `scripts/reconcile-branches.sh` declares the branch model.

The crate's own documentation is `crates/agentstate/README.md` on the
integration branch of `possibilities/herdr`.
