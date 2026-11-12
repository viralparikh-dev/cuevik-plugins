#!/usr/bin/env bash
# cuevik-start: which local init/* branches are safe to delete, and deleting them.
#
# Usage:  bash cleanup.sh plan                  what is safe to delete, and what initiation's end date is
#         bash cleanup.sh delete <branch>...    delete exactly those branches, each only if still safe
#
# Run it from the project repo's root. `plan` changes nothing but remote-tracking refs (it fetches
# origin). `delete` removes only LOCAL branches, never a remote branch, a file or a commit.
# Needs git and gh (signed in). The last step comes from steps.table beside this file.
#
# `plan` prints "== <name>" sections:
#   == branches   delete|<branch>|<pr> or skip|<branch>|<reason>, one per local init/* branch
#   == current    branch: <name>   (or - when HEAD is detached)
#                 clean: yes|no    (whether the working tree has no uncommitted changes)
#   == remote     one init/* branch still on GitHub per line (left by a closed, unmerged PR)
#   == last_step  step: <id>, branch: <the branch its merged PR was on or ->, merged: <YYYY-MM-DD or ->
# `delete` prints deleted|<branch>|<pr> per branch, then stops at the first one it refuses:
#   refused|<branch>|<reason>
#
# A branch is safe to delete when a PR from it was merged into main and its tip is exactly that
# PR's last commit: a squash or rebase merge leaves the branch "unmerged" to git, so the PR's
# commit id is the proof. Commits made after the PR's last push are never deleted.
#
# Exit: 0 done. 1 a preflight check or a GitHub query failed, or `delete` refused a branch: the last
# line printed is the message. 2 wrong usage. Bash 3.2 and Git Bash safe.

stop() { printf '%s\n' "$1"; exit 1; }
usage() { printf 'usage: cleanup.sh plan | cleanup.sh delete <branch>...\n' >&2; exit 2; }

MODE="${1:-}"
case "$MODE" in
  plan) [ "$#" -eq 1 ] || usage ;;
  delete) [ "$#" -ge 2 ] || usage ;;
  *) usage ;;
esac

# ---- the last step ------------------------------------------------------------------------------
SELF="${BASH_SOURCE[0]//\\//}"
case "$SELF" in */*) DIR="${SELF%/*}" ;; *) DIR="." ;; esac
[ -r "$DIR/steps.table" ] || stop "Error: steps.table could not be loaded."
LAST_ID=""; LAST_BRANCHES=""
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  case "$line" in step\|*) ;; *) continue ;; esac
  IFS='|' read -r _ id _ branch aliases _ <<EOF
$line
EOF
  LAST_ID="$id"
  if [ "$aliases" = "-" ]; then LAST_BRANCHES="$branch"; else LAST_BRANCHES="$branch $aliases"; fi
done < "$DIR/steps.table"
[ -n "$LAST_ID" ] || stop "Error: steps.table could not be loaded."

# ---- preflight ----------------------------------------------------------------------------------
PREFIX="$(git rev-parse --show-prefix 2>/dev/null)" || stop "This folder is not a git repo."
[ -z "$PREFIX" ] || stop "Run cleanup from the repo root."
gh auth status >/dev/null 2>&1 || stop "gh is not signed in. Run gh auth login, then re-run."
git fetch --prune origin >/dev/null 2>&1 || stop "Could not fetch origin. Cleanup needs GitHub's current state."

CURRENT="$(git branch --show-current 2>/dev/null)"
tree_clean() { [ -z "$(git status --porcelain 2>/dev/null)" ]; }

# merged <branch>: sets MERGED_OUT to the merged PRs into main from that branch,
# "number<TAB>headRefOid<TAB>mergedAt" per line, newest first. Stops the script when GitHub cannot be
# asked: no answer must never read as "no merged PR", which would skip a branch silently. Called
# without a command substitution, so that stop ends the script and not a subshell.
merged() {
  local out
  out="$(gh pr list --head "$1" --base main --state merged --limit 30 --json number,headRefOid,mergedAt \
    --jq 'sort_by(.mergedAt) | reverse | .[] | [(.number | tostring), .headRefOid, .mergedAt] | @tsv' 2>&1)" \
    || stop "Could not read pull requests for $1 from GitHub: $(printf '%s' "$out" | head -n 1)"
  MERGED_OUT="$(printf '%s\n' "$out" | tr -d '\r')"
}

# classify <branch>: sets C_VERDICT (delete or skip), C_PR and C_REASON.
classify() {
  local branch="$1" tip prs num oid at open
  C_VERDICT="skip"; C_PR=""; C_REASON=""
  tip="$(git rev-parse --verify -q "refs/heads/$branch" 2>/dev/null)" || { C_REASON="no such local branch"; return; }
  merged "$branch"
  prs="$MERGED_OUT"
  if [ -z "$prs" ]; then
    C_REASON="no merged PR"
    open="$(gh pr list --head "$branch" --state open --json number --jq '.[0].number // empty' 2>/dev/null | tr -d '\r')"
    if [ -n "$open" ]; then C_REASON="no merged PR (open PR #$open)"; fi
    return
  fi
  while IFS=$'\t' read -r num oid at; do
    if [ "$oid" = "$tip" ]; then
      C_VERDICT="delete"; C_PR="$num"
      if [ "$branch" = "$CURRENT" ] && ! tree_clean; then
        C_VERDICT="skip"; C_REASON="checked out with uncommitted changes; PR #$num is merged"
      fi
      return
    fi
  done <<EOF
$prs
EOF
  num="${prs%%$'\t'*}"
  C_REASON="local commits not in PR #$num"
}

# ---- delete -------------------------------------------------------------------------------------
if [ "$MODE" = "delete" ]; then
  shift
  for branch in "$@"; do
    case "$branch" in init/*) ;; *) printf 'refused|%s|not an init/* branch\n' "$branch"; exit 1 ;; esac
    classify "$branch"
    if [ "$C_VERDICT" != "delete" ]; then
      printf 'refused|%s|%s\n' "$branch" "$C_REASON"
      exit 1
    fi
    if [ "$branch" = "$CURRENT" ]; then
      git checkout -q main 2>/dev/null || { printf 'refused|%s|could not switch to main first\n' "$branch"; exit 1; }
      CURRENT="main"
    fi
    git branch -D "$branch" >/dev/null 2>&1 || { printf 'refused|%s|git could not delete it\n' "$branch"; exit 1; }
    printf 'deleted|%s|%s\n' "$branch" "$C_PR"
  done
  exit 0
fi

# ---- plan ---------------------------------------------------------------------------------------
printf '== branches\n'
while read -r branch; do
  [ -n "$branch" ] || continue
  classify "$branch"
  if [ "$C_VERDICT" = "delete" ]; then printf 'delete|%s|%s\n' "$branch" "$C_PR"; else printf 'skip|%s|%s\n' "$branch" "$C_REASON"; fi
done <<EOF
$(git for-each-ref --format='%(refname:short)' refs/heads/init/)
EOF

printf '\n== current\n'
printf 'branch: %s\n' "${CURRENT:--}"
if tree_clean; then printf 'clean: yes\n'; else printf 'clean: no\n'; fi

printf '\n== remote\n'
git ls-remote --heads origin 'refs/heads/init/*' 2>/dev/null | while read -r _ ref; do printf '%s\n' "${ref#refs/heads/}"; done

printf '\n== last_step\n'
LAST_PR_BRANCH="-"; LAST_PR_DAY="-"; LAST_PR_AT=""
for b in $LAST_BRANCHES; do
  merged "$b"
  at="$(printf '%s\n' "$MERGED_OUT" | head -n 1 | cut -f3)"
  if [ -n "$at" ] && [[ "$at" > "$LAST_PR_AT" ]]; then LAST_PR_AT="$at"; LAST_PR_BRANCH="$b"; LAST_PR_DAY="${at%%T*}"; fi
done
printf 'step: %s\nbranch: %s\nmerged: %s\n' "$LAST_ID" "$LAST_PR_BRANCH" "$LAST_PR_DAY"
exit 0
