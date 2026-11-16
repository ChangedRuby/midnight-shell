#!/usr/bin/env bash
# Merge caelestia-dots/shell into this fork on a sync/caelestia branch.
#
#   scripts/sync-caelestia.sh --dry-run    list what would conflict, touch nothing
#   scripts/sync-caelestia.sh              merge, auto-resolve what the policy covers
#   scripts/sync-caelestia.sh --continue   finish after resolving the rest by hand
#   scripts/sync-caelestia.sh --abort      drop the merge in progress
#
# Never pushes. Review sync/caelestia, then merge it into main yourself.
#
# Conflicts are resolved from scripts/sync-caelestia.policy:
#   ours   <glob>   keep midnight's version (design that is deliberately different)
#   theirs <glob>   take Caelestia's version (code we never changed on purpose)
# Anything the policy does not cover stops the script with the merge still open,
# so design-level differences get discussed instead of guessed.
set -euo pipefail

REMOTE=caelestia
REMOTE_URL=https://github.com/caelestia-dots/shell.git
UPSTREAM_BRANCH=main
SYNC_BRANCH=sync/caelestia
BASE_BRANCH=main

cd "$(git rev-parse --show-toplevel)"
POLICY=scripts/sync-caelestia.policy

die() { echo "error: $*" >&2; exit 1; }

merge_in_progress() { git rev-parse -q --verify MERGE_HEAD >/dev/null; }

unmerged_files() { git diff --name-only --diff-filter=U; }

# Resolve every conflicted file the policy covers; print the ones left over.
apply_policy() {
    local file side glob rule resolved=0 left=()
    while IFS= read -r file; do
        side=
        if [[ -f $POLICY ]]; then
            while read -r rule glob; do
                [[ -z ${rule:-} || $rule == \#* ]] && continue
                # shellcheck disable=SC2053  # glob match is intended
                if [[ $file == $glob ]]; then side=$rule; fi
            done <"$POLICY"
        fi

        case $side in
            ours)   git checkout --ours   -- "$file" && git add -- "$file"; echo "  ours    $file"; resolved=$((resolved + 1)) ;;
            theirs) git checkout --theirs -- "$file" && git add -- "$file"; echo "  theirs  $file"; resolved=$((resolved + 1)) ;;
            *)      left+=("$file") ;;
        esac
    done < <(unmerged_files)

    echo "auto-resolved by policy: $resolved"
    if ((${#left[@]})); then
        echo "left for you (${#left[@]}):"
        printf '  %s\n' "${left[@]}"
        return 1
    fi
}

finish() {
    [[ -z $(unmerged_files) ]] || die "unresolved files remain (git status)"
    git commit --no-edit
    echo "merged. Branch $SYNC_BRANCH is ready to review; nothing was pushed."
}

case ${1:-} in
    --abort)
        merge_in_progress && git merge --abort
        echo "merge aborted"
        exit 0
        ;;
    --continue)
        merge_in_progress || die "no merge in progress"
        apply_policy || true
        finish
        exit 0
        ;;
    --dry-run | "") ;;
    *) die "unknown option: $1" ;;
esac

git remote get-url "$REMOTE" >/dev/null 2>&1 || git remote add "$REMOTE" "$REMOTE_URL"
git fetch "$REMOTE" --no-tags --prune
TARGET=$REMOTE/$UPSTREAM_BRANCH

# Let git remember each hand-made resolution and replay it next time.
git config rerere.enabled true
git config rerere.autoupdate true

BASE=$(git merge-base "$BASE_BRANCH" "$TARGET")
echo "Caelestia is $(git rev-list --count "$BASE..$TARGET") commits ahead of the last sync ($(git log -1 --format='%h %ad' --date=short "$BASE"))"
git log --no-merges --format='  %h %ad %s' --date=short "$BASE..$TARGET" | head -40

if [[ ${1:-} == --dry-run ]]; then
    echo
    echo "dry run (nothing is touched):"
    out=$(git merge-tree --write-tree --name-only --no-messages "$BASE_BRANCH" "$TARGET" || true)
    conflicts=$(sed '1d;/^$/d' <<<"$out")
    if [[ -z $conflicts ]]; then
        echo "no conflicts"
    else
        echo "would conflict ($(wc -l <<<"$conflicts") files):"
        sed 's/^/  /' <<<"$conflicts"
    fi
    exit 0
fi

[[ -z $(git status --porcelain --untracked-files=no) ]] || die "working tree has uncommitted changes"
merge_in_progress && die "a merge is already in progress (use --continue or --abort)"

git checkout -B "$SYNC_BRANCH" "$BASE_BRANCH"
echo "merging $TARGET ($(git rev-parse --short "$TARGET")) into $SYNC_BRANCH"

if git merge --no-ff -m "Merge caelestia-dots/shell $UPSTREAM_BRANCH ($(git rev-parse --short "$TARGET"))" "$TARGET"; then
    echo "clean merge, no conflicts."
    exit 0
fi

echo "conflicts, applying $POLICY:"
if apply_policy; then
    finish
else
    echo
    echo "Resolve the files above, then: scripts/sync-caelestia.sh --continue"
    echo "Or give up with:               scripts/sync-caelestia.sh --abort"
    exit 1
fi
