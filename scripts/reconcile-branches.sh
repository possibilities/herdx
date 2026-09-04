#!/bin/bash

set -euo pipefail

# herdx's entrypoint to the maintain skill's shared namespace script. It
# declares what MAINTAIN.md's Branch model says — the checkout, the remotes,
# the branch names, the linear-stack model — and nothing else; the mechanics
# (a read-only check from a disposable snapshot and one atomic exact-leased
# push of declared refs that leaves all other heads unchanged) are the skill's
# and are tested there.

skill_dir="${MAINTAIN_SKILL_DIR:-$HOME/.local/share/agentstart/resources/skills/maintain}"
script="$skill_dir/scripts/reconcile-branches.sh"
if [ ! -f "$script" ]; then
    printf 'herdx branches: the maintain skill is not installed at %s (run ~/code/agentstart/scripts/sync-skills, or set MAINTAIN_SKILL_DIR)\n' \
        "$skill_dir" >&2
    exit 1
fi

MAINTAIN_WORKSHOP="$(cd "$(dirname "$0")/.." && pwd)"
export MAINTAIN_WORKSHOP
export MAINTAIN_CHECKOUT="${HERDX_HERDR_CHECKOUT:-$HOME/source/herdrdev--herdr}"
export MAINTAIN_FORK_REPO=possibilities/herdr
export MAINTAIN_UPSTREAM_REPO=herdrdev/herdr
export MAINTAIN_FORK_REMOTE=fork
export MAINTAIN_UPSTREAM_REMOTE=upstream
export MAINTAIN_MAIN_BRANCH=master
export MAINTAIN_INTEGRATION_BRANCH=integration
export MAINTAIN_CARRY_PREFIX=''
export MAINTAIN_QUARANTINE_PREFIX=DELETEME/
export MAINTAIN_PRESERVE_OPEN_PRS=0

exec bash "$script" "$@"
