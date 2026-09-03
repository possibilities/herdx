# herdx agent guidance

This repository owns delivery and maintenance of the operator's herdr fork,
whose only carried feature is the `agentstate` crate. Read `CONTEXT.md`,
`MAINTAIN.md`, and `SCRATCHPAD.md` before changing the fork or its installer.

## Ownership

- `MAINTAIN.md` is the project specification and the whole of what the
  shared `maintain` skill knows about herdr. Its section headings are fixed;
  add to a section rather than renaming one.
- `/maintain` is the shared `maintain` skill in `~/code/agentguidance`.
  herdr-specific procedure belongs in `MAINTAIN.md`, never in a copy of the
  skill here.
- Every behavior the fork carries is reversed into `MAINTAIN.md` § Features
  by the same unit of work that builds it, as paired commits across the two
  repositories.
- `SCRATCHPAD.md` is current maintenance state, not a second specification.
- `scripts/install.sh` consumes the published `fork/integration` branch and
  never rebases, pushes, or changes the bound checkout's branch.
- `scripts/gate.sh` is the gate `MAINTAIN.md` names, run from a candidate
  worktree.
- `scripts/reconcile-branches.sh` is the thin entrypoint to the skill's
  shared branch script and declares the branch model only.

The checkout being maintained is `~/src/herdr`, `fork` pointing to
`possibilities/herdr` and `origin` to `herdrdev/herdr`. It stays on `master`;
it is shared with herdr's own managed worktrees on this machine. Build and
test only in worktrees.

The crate compiles herdr source by path. Never copy a herdr file into the
crate to work around a compile error; fix the shim or record the upstream
change as a repair in the cycle.

`CLAUDE.md` is a pointer to this file.
