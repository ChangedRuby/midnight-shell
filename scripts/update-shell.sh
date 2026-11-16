#!/usr/bin/env bash
# Update the installed shell (midnight-ruby-git) from the fork's main branch.
#
#   scripts/update-shell.sh           build and install if origin/main has moved
#   scripts/update-shell.sh --check   only say whether an update is available
#   scripts/update-shell.sh --force   rebuild even when up to date
#
# Builds pkg/PKGBUILD, which clones github.com/ChangedRuby/midnight-shell (main).
# Push to origin/main first: the package is built from GitHub, not from your
# working tree. Installing asks for sudo through pacman.
set -euo pipefail

PKG=midnight-ruby-git
REMOTE_URL=https://github.com/ChangedRuby/midnight-shell.git
BRANCH=main

cd "$(git rev-parse --show-toplevel)/pkg"

remote_head=$(git ls-remote "$REMOTE_URL" "refs/heads/$BRANCH" | cut -c1-7)
[[ -n $remote_head ]] || { echo "error: could not read $BRANCH from $REMOTE_URL" >&2; exit 1; }

installed=$(pacman -Q "$PKG" 2>/dev/null | awk '{print $2}') || true
installed_head=${installed##*.}
installed_head=${installed_head%%-*}

if [[ -z $installed ]]; then
    echo "$PKG is not installed; origin/$BRANCH is at $remote_head"
elif [[ $installed_head == "$remote_head" ]]; then
    echo "up to date: $installed (origin/$BRANCH $remote_head)"
    [[ ${1:-} == --force ]] || exit 0
else
    echo "update available: $installed -> origin/$BRANCH $remote_head"
fi

[[ ${1:-} == --check ]] && exit 0

# caelestia-cli is a runtime dependency; before it is installed (first swap
# away from midnight-cli) makepkg must not try to resolve it.
# The check is on the package name: midnight-cli-git also *provides*
# caelestia-cli, which must not count as the real thing.
flags=(-fsi)
pacman -Qq | grep -Eqx 'caelestia-cli(-git)?' || {
    echo "note: caelestia-cli is not installed, building without dependency checks (--nodeps, no install)"
    flags=(-f --nodeps)
}

# makepkg rewrites pkgver inside PKGBUILD; keep the tracked file untouched.
trap 'git checkout -- PKGBUILD 2>/dev/null || true' EXIT

makepkg "${flags[@]}"
