#!/bin/bash
# Point a sibling checkout at the fork-and-PR workflow in AGENTS.md.
# Usage: ./setup-repo.sh /openedx/openedx-platform
#
# Safe to re-run. Undo instructions are in AGENTS.md.

set -euo pipefail

checkout="${1:?usage: setup-repo.sh <path-to-checkout>}"
cd "$checkout"

name="$(basename "$(git rev-parse --show-toplevel)")"
upstream="kdmccormick/$name"
aifork="kylemakor-ai/$name"

# origin has to be Kyle's fork already. Repointing someone else's remote is not
# this script's business, so bail and let a human look.
origin_url="$(git remote get-url origin)"
if [[ "$origin_url" != *"$upstream"* ]]
then
    echo "origin is $origin_url, expected $upstream -- fix by hand" >&2
    exit 1
fi

if ! gh repo view "$aifork" >/dev/null 2>&1
then
    echo "Forking $upstream..."
    gh repo fork "$upstream" --clone=false --remote=false
fi

git remote remove aifork 2>/dev/null || true
git remote add aifork "git@github.com:$aifork"
git fetch --quiet aifork

# Commits are the AI's, not Kyle's.
git config --local user.name "Kyle D McCormick's AI"
git config --local user.email "ai@kylemccormick.me"

# A bare `git push` goes to the AI's fork. Fetch and branch tracking still
# follow origin.
git config --local remote.pushDefault aifork

# An explicit `git push origin` now fails here rather than at GitHub.
git remote set-url --push origin DISABLED_READ_ONLY_UPSTREAM

# Without this, `gh pr create` would default its base to the fork network's root,
# which for openedx-platform would mean filing against openedx/openedx-platform.
gh repo set-default "$upstream"

echo
echo "$name ready: origin=$upstream (fetch only), aifork=$aifork"
echo "Add a row for it to the table in AGENTS.md."
