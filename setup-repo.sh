#!/bin/bash
# Point a sibling checkout at the fork-and-PR workflow in AGENTS.md.
# Usage: ./setup-repo.sh ~/openedx/openedx-platform
#
# Remotes are named after the GitHub owner they point at. Exactly one of them --
# `rokamelyk` -- can be pushed to; every other one gets its push URL broken.
#
# Safe to re-run. Undo instructions are in AGENTS.md.

set -euo pipefail

checkout="${1:?usage: setup-repo.sh <path-to-checkout>}"
cd "$checkout"

name="$(basename "$(git rev-parse --show-toplevel)")"
upstream="kdmccormick/$name"
mine="rokamelyk/$name"

# kdmccormick has to be a remote already. Repointing someone else's remote is not
# this script's business, so bail and let a human look.
upstream_url="$(git remote get-url kdmccormick 2>/dev/null || true)"
if [[ "$upstream_url" != *"$upstream"* ]]
then
    echo "remote 'kdmccormick' is '${upstream_url:-unset}', expected $upstream -- fix by hand" >&2
    exit 1
fi

if ! gh repo view "$mine" >/dev/null 2>&1
then
    echo "Forking $upstream..."
    gh repo fork "$upstream" --clone=false --remote=false
fi

git remote remove rokamelyk 2>/dev/null || true
git remote add rokamelyk "git@github.com:$mine"
git fetch --quiet rokamelyk

# A bare `git push` goes to the AI's fork. Fetch and branch tracking still
# follow the read-only remotes.
git config --local remote.pushDefault rokamelyk

# An explicit `git push <anything else>` now fails here rather than at GitHub.
# Every remote, not just kdmccormick: a checkout may also carry the real upstream
# (`openedx`, `overhangio`), and pushing there would be worse, not better.
for remote in $(git remote)
do
    if [[ "$remote" != "rokamelyk" ]]
    then
        git remote set-url --push "$remote" DISABLED_READ_ONLY_UPSTREAM
        echo "push disabled: $remote"
    fi
done

# Without this, `gh pr create` would default its base to the fork network's root,
# which for openedx-platform would mean filing against openedx/openedx-platform.
gh repo set-default "$upstream"

echo
echo "$name ready: rokamelyk=$mine (the only pushable remote)"
echo "Add a row for it to the table in AGENTS.md."
