#!/usr/bin/env bash
# cuevik-ship: clean up one issue once its code PR is merged (or the issue closed as not planned).
#
# Usage:  bash ship-cleanup.sh <issue> plan     what would be removed, archived and deleted
#         bash ship-cleanup.sh <issue> apply    do it, after re-checking everything
#
# Run it from the MAIN checkout (not a worktree) at the repo root. `plan` changes nothing but
# remote-tracking refs. `apply` removes the issue's worktree and its local ship/<n>-<slug>/* branches,
# tags origin/ship/<n>-<slug>/issue as ship-archive/<n>-<slug> and pushes the tag, then deletes the
# issue branch and any other remote ship/<n>-<slug>/* branch. The tag is pushed BEFORE the branch is
# deleted, so every References permalink keeps working. It never forces anything.
# Needs git and gh (signed in); the gate is ship-state.sh's, beside this file.
#
# `plan` prints "== <name>" sections:
#   == worktree  path (or -), removable (yes or no), reason
#   == local     delete|<branch>|reachable   (its tip is on a remote branch)
#                delete|<branch>|pr          (its tip is the last commit of a merged or closed PR)
#                refuse|<branch>|unpushed commits
#   == archive   tag, state (create, exists, conflict or none), target, tag_sha
#   == remote    delete|<branch> per remote ship/<n>-<slug>/* branch (the issue branch first)
#   == verdict   result (ready or refused) and message
# `apply` runs `plan`'s checks again, and stops without touching anything when the verdict is refused.
# Otherwise it prints done|<what> per action and stops at the first failure: failed|<what>|<why>.
#
# Exit: 0 `plan` printed, or `apply` finished. 1 refused, a gate stop, a failed action or a failed
# query: the last line is the message. 2 wrong usage. Bash 3.2 and Git Bash safe.

stop() { printf '%s\n' "$1"; exit 1; }
usage() { printf 'usage: ship-cleanup.sh <issue> plan | ship-cleanup.sh <issue> apply\n' >&2; exit 2; }

[ "$#" -eq 2 ] || usage
ISSUE="${1##*/}"; ISSUE="${ISSUE#\#}"
case "$ISSUE" in '' | *[!0-9]*) stop "The issue must be a number, #number or the issue's URL, not: $1" ;; esac
MODE="$2"
case "$MODE" in plan | apply) ;; *) usage ;; esac

SELF="${BASH_SOURCE[0]//\\//}"
case "$SELF" in */*) DIR="${SELF%/*}" ;; *) DIR="." ;; esac
[ -r "$DIR/ship-state.sh" ] || stop "Error: ship-state.sh could not be loaded."

# The gate: preconditions, the code PR merged (or not planned), no open ship PR, the main checkout.
STATE="$(bash "$DIR/ship-state.sh" "$ISSUE" cleanup)" || { printf '%s\n' "$STATE" | tail -n 1; exit 1; }
field() { printf '%s\n' "$STATE" | sed -n "s/^$1: //p" | head -n 1 | tr -d '\r'; }
[ "$(field result)" = "pass" ] || stop "$(field message)"
SLUG="$(field slug)"; WORKTREE="$(field worktree)"
WORK="ship/$ISSUE-$SLUG"; ISSUE_BRANCH="$WORK/issue"; TAG="ship-archive/$ISSUE-$SLUG"

# ---- the worktree -------------------------------------------------------------------------------
REMOVABLE="-"; REASON="-"
if [ "$WORKTREE" != "-" ]; then
  if [ -n "$(git -C "$WORKTREE" status --porcelain 2>/dev/null)" ]; then
    REMOVABLE="no"; REASON="uncommitted changes in $WORKTREE: commit, push or discard them first"
  else
    REMOVABLE="yes"
  fi
fi

# ---- local branches -----------------------------------------------------------------------------
LOCAL_PLAN=""; UNPUSHED=""
while read -r branch tip; do
  [ -n "$branch" ] || continue
  if [ -n "$(git branch -r --contains "$tip" 2>/dev/null)" ]; then
    LOCAL_PLAN="$LOCAL_PLAN""delete|$branch|reachable"$'\n'
    continue
  fi
  # A squash merge leaves merged work unreachable from any remote: the PR's last commit proves it.
  oids="$(gh pr list --head "$branch" --state all --limit 30 --json state,headRefOid \
    --jq '.[] | select(.state == "MERGED" or .state == "CLOSED") | .headRefOid' 2>&1)" \
    || stop "Could not read pull requests for $branch from GitHub: $(printf '%s' "$oids" | head -n 1)"
  case "$(printf '%s\n' "$oids" | tr -d '\r')" in
    *"$tip"*) LOCAL_PLAN="$LOCAL_PLAN""delete|$branch|pr"$'\n' ;;
    *) LOCAL_PLAN="$LOCAL_PLAN""refuse|$branch|unpushed commits"$'\n'; UNPUSHED="$UNPUSHED $branch" ;;
  esac
done <<EOF
$(git for-each-ref --format='%(refname:short) %(objectname)' "refs/heads/$WORK/")
EOF

# ---- the archive tag ----------------------------------------------------------------------------
ISSUE_SHA="$(git ls-remote --heads origin "refs/heads/$ISSUE_BRANCH" 2>/dev/null | cut -f1)"
TAG_SHA="$(git ls-remote --tags origin "refs/tags/$TAG" 2>/dev/null | cut -f1)"
if [ -n "$ISSUE_SHA" ] && [ -z "$TAG_SHA" ]; then ARCHIVE="create"
elif [ -n "$ISSUE_SHA" ] && [ "$TAG_SHA" = "$ISSUE_SHA" ]; then ARCHIVE="exists"
elif [ -n "$ISSUE_SHA" ]; then ARCHIVE="conflict"
elif [ -n "$TAG_SHA" ]; then ARCHIVE="exists"
else ARCHIVE="none"; fi

# ---- remote branches ----------------------------------------------------------------------------
REMOTE_BRANCHES=""
[ -z "$ISSUE_SHA" ] || REMOTE_BRANCHES="$ISSUE_BRANCH"
while read -r _ ref; do
  [ -n "$ref" ] || continue
  name="${ref#refs/heads/}"
  [ "$name" != "$ISSUE_BRANCH" ] || continue
  REMOTE_BRANCHES="$REMOTE_BRANCHES $name"
done <<EOF
$(git ls-remote --heads origin "refs/heads/$WORK/*" 2>/dev/null)
EOF

# ---- the verdict --------------------------------------------------------------------------------
VERDICT="ready"; MESSAGE="-"
if [ "$REMOVABLE" = "no" ]; then VERDICT="refused"; MESSAGE="The worktree has $REASON."
elif [ -n "$UNPUSHED" ]; then VERDICT="refused"; MESSAGE="Unpushed commits on:$UNPUSHED. Push them or delete them yourself; cleanup never deletes unpushed work."
elif [ "$ARCHIVE" = "conflict" ]; then VERDICT="refused"; MESSAGE="The tag $TAG points at $TAG_SHA but origin/$ISSUE_BRANCH is at $ISSUE_SHA. Resolve it by hand."
fi

if [ "$MODE" = "plan" ]; then
  printf '== worktree\npath: %s\nremovable: %s\nreason: %s\n' "$WORKTREE" "$REMOVABLE" "$REASON"
  printf '\n== local\n%s' "$LOCAL_PLAN"
  printf '\n== archive\ntag: %s\nstate: %s\ntarget: %s\ntag_sha: %s\n' "$TAG" "$ARCHIVE" "${ISSUE_SHA:--}" "${TAG_SHA:--}"
  printf '\n== remote\n'
  for b in $REMOTE_BRANCHES; do printf 'delete|%s\n' "$b"; done
  printf '\n== verdict\nresult: %s\nmessage: %s\n' "$VERDICT" "$MESSAGE"
  exit 0
fi

# ---- apply --------------------------------------------------------------------------------------
[ "$VERDICT" = "ready" ] || stop "$MESSAGE"
act() {  # act <what> <command...>: run it, report it, stop at the first failure
  local what="$1" out; shift
  out="$("$@" 2>&1)" || { printf 'failed|%s|%s\n' "$what" "$(printf '%s' "$out" | head -n 1)"; exit 1; }
  printf 'done|%s\n' "$what"
}
if [ "$WORKTREE" != "-" ]; then
  act "worktree $WORKTREE removed" git worktree remove "$WORKTREE"   # never --force
  act "worktrees pruned" git worktree prune
fi
printf '%s' "$LOCAL_PLAN" | while IFS='|' read -r verdict branch _; do
  [ "$verdict" = "delete" ] || continue
  out="$(git branch -D "$branch" 2>&1)" || { printf 'failed|branch %s deleted|%s\n' "$branch" "$(printf '%s' "$out" | head -n 1)"; exit 1; }
  printf 'done|branch %s deleted\n' "$branch"
done || exit 1
if [ "$ARCHIVE" = "create" ]; then
  act "tag $TAG created at $ISSUE_SHA" git tag "$TAG" "$ISSUE_SHA"
  act "tag $TAG pushed" git push origin "$TAG"
fi
for b in $REMOTE_BRANCHES; do
  act "remote branch $b deleted" git push origin --delete "$b"
done
exit 0
