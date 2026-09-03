#!/bin/bash

set -euo pipefail

# Consumes the published fork/integration branch of the herdr fork: builds
# the agentstate crate release from one exact commit in a detached temporary
# worktree and installs the binary atomically. It never rebases, pushes, or
# changes the bound checkout's branch.

die() {
    printf 'herdx installer: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/install.sh --install --sha SHA|--check\n'
}

check_only=0
case "${1:-}" in
    --install)
        [ "$#" -eq 3 ] && [ "${2:-}" = --sha ] || {
            usage >&2
            exit 64
        }
        expected_sha=$3
        [ "${#expected_sha}" -eq 40 ] || die "--sha must be a full lowercase commit SHA"
        case "$expected_sha" in
            *[!0-9a-f]*) die "--sha must be a full lowercase commit SHA" ;;
        esac
        ;;
    --check)
        check_only=1
        [ "$#" -eq 1 ] || {
            usage >&2
            exit 64
        }
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 64
        ;;
esac

checkout="${HERDX_HERDR_CHECKOUT:-$HOME/src/herdr}"
branch=integration
fork_url="${HERDX_FORK_URL:-https://github.com/possibilities/herdr.git}"
bin="${HERDX_BIN:-$HOME/.local/bin/agentstate}"
state_dir="${HERDX_STATE_DIR:-$HOME/.local/state/herdx}"
commit_receipt="$state_dir/agentstate-built-commit"
digest_receipt="$state_dir/agentstate-built-sha256"
export CARGO_TARGET_DIR="${HERDX_TARGET_DIR:-$HOME/.cache/herdx/target}"

if [ "$check_only" -eq 1 ]; then
    cat <<EOF
agentstate installation:
  checkout: $checkout
  source: fork/$branch ($fork_url)
  binary: $bin
  receipts: $state_dir
  installed commit: $(cat "$commit_receipt" 2>/dev/null || printf none)
  installed digest: $(cat "$digest_receipt" 2>/dev/null || printf none)
  action: build crates/agentstate release from the exact published commit in a detached worktree and install atomically
EOF
    exit 0
fi

command -v git >/dev/null 2>&1 || die "git is required"
command -v cargo >/dev/null 2>&1 || die "cargo is required"
command -v shasum >/dev/null 2>&1 || die "shasum is required"
[ -d "$checkout/.git" ] || die "bound checkout missing at $checkout"

actual_fork=$(git -C "$checkout" remote get-url fork 2>/dev/null || true)
case "$actual_fork" in
    "$fork_url"|"${fork_url%.git}"|git@github.com:possibilities/herdr.git|git@github.com:possibilities/herdr)
        ;;
    *) die "remote fork is '$actual_fork', expected $fork_url" ;;
esac

git -C "$checkout" fetch --quiet fork "$branch"
published=$(git -C "$checkout" rev-parse "refs/remotes/fork/$branch")
git -C "$checkout" merge-base --is-ancestor "$expected_sha" "$published" ||
    die "$expected_sha is not on fork/$branch (published tip $published)"
[ -d "$checkout/crates" ] && die "bound checkout carries crates/: it must stay on the master mirror"

tmp_worktree=$(mktemp -d "${TMPDIR:-/tmp}/herdx-build.XXXXXX")
cleanup() {
    git -C "$checkout" worktree remove --force "$tmp_worktree" >/dev/null 2>&1 || rm -rf "$tmp_worktree"
    git -C "$checkout" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT
rmdir "$tmp_worktree"
git -C "$checkout" worktree add --quiet --detach "$tmp_worktree" "$expected_sha"
[ "$(git -C "$tmp_worktree" rev-parse HEAD)" = "$expected_sha" ] || die "worktree is not at $expected_sha"

mkdir -p "$CARGO_TARGET_DIR" "$state_dir" "$(dirname "$bin")"
AGENTSTATE_HERDR_SHA="$expected_sha" \
    cargo build --quiet --manifest-path "$tmp_worktree/Cargo.toml" -p agentstate --release
built="$CARGO_TARGET_DIR/release/agentstate"
[ -x "$built" ] || die "build produced no binary at $built"
"$built" --version | grep -q "$expected_sha" || die "built binary does not report $expected_sha"

digest=$(shasum -a 256 "$built" | awk '{ print $1 }')
install_tmp="$bin.herdx-tmp.$$"
cp "$built" "$install_tmp"
chmod 755 "$install_tmp"
mv -f "$install_tmp" "$bin"
printf '%s\n' "$expected_sha" >"$commit_receipt.tmp"
mv -f "$commit_receipt.tmp" "$commit_receipt"
printf '%s\n' "$digest" >"$digest_receipt.tmp"
mv -f "$digest_receipt.tmp" "$digest_receipt"

printf 'herdx installer: installed %s\n  commit %s\n  sha256 %s\n' "$bin" "$expected_sha" "$digest"
"$bin" --version
