#!/bin/bash

set -euo pipefail

# The herdx gate, run from a candidate worktree of the herdr fork. It proves
# the agentstate crate on that exact tree: formatting, lints, tests, a
# release build, the fresh binary, and attribution. It never builds herdr.

die() {
    printf 'herdx gate: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/gate.sh --worktree DIR\n'
}

[ "$#" -eq 2 ] && [ "$1" = --worktree ] || {
    usage >&2
    exit 64
}
worktree=$(cd "$2" 2>/dev/null && pwd) || die "no such worktree: $2"
[ -f "$worktree/Cargo.toml" ] || die "$worktree has no Cargo.toml"
[ -d "$worktree/crates/agentstate" ] || die "$worktree carries no crates/agentstate"

export CARGO_TARGET_DIR="${HERDX_TARGET_DIR:-$HOME/.cache/herdx/target}"
mkdir -p "$CARGO_TARGET_DIR"
manifest="$worktree/Cargo.toml"

step() {
    printf '\nherdx gate: %s\n' "$*"
}

step "cargo fmt --check"
cargo fmt --manifest-path "$manifest" -p agentstate --check

step "cargo clippy -- -D warnings"
cargo clippy --manifest-path "$manifest" -p agentstate --lib --bins --tests -- -D warnings

step "cargo test"
cargo test --manifest-path "$manifest" -p agentstate

step "cargo build --release"
cargo build --manifest-path "$manifest" -p agentstate --release
bin="$CARGO_TARGET_DIR/release/agentstate"
[ -x "$bin" ] || die "release binary missing at $bin"

step "explain smoke"
fixture="$worktree/crates/agentstate/tests/fixtures/claude/idle-prompt-box.txt"
state=$("$bin" explain --agent claude --screen "$fixture" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')
[ "$state" = idle ] || die "explain smoke expected idle, got $state"
"$bin" --version | grep -q '^agentstate ' || die "--version output unexpected"

step "attribution"
notice="$worktree/crates/agentstate/NOTICE"
[ -f "$notice" ] || die "NOTICE missing"
[ -f "$worktree/crates/agentstate/LICENSE" ] || die "LICENSE missing"
for included in $(grep -rho '#\[path = "[^"]*"\]' "$worktree/crates/agentstate/src" | sed 's/.*"\(.*\)".*/\1/'); do
    rel=$(printf '%s' "$included" | sed 's#^\(\.\./\)*##')
    grep -q "$rel" "$notice" || die "NOTICE does not name path-included file $rel"
done

printf '\nherdx gate: PASS %s\n' "$(git -C "$worktree" rev-parse HEAD)"
