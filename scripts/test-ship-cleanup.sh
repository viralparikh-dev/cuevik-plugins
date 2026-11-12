#!/usr/bin/env bash
# Tests plugins/cuevik-ship/scripts/ship-cleanup.sh against real temporary git repos and a stub gh.
#
# Usage:  bash scripts/test-ship-cleanup.sh
# Needs:  git, jq (see scripts/test-lib.sh, which holds the stub gh and the helpers)

source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
SCRIPT="$ROOT/plugins/cuevik-ship/scripts/ship-cleanup.sh"
W="ship/41-widget"

local_branch() {  # local_branch <name> <base> [no-push]: a local branch with one commit of its own; prints its tip
  git -C "$REPO" checkout -q -b "$1" "$2"
  git -C "$REPO" commit -q --allow-empty -m "work on $1"
  [ "$3" = "no-push" ] || git -C "$REPO" push -q origin "$1"
  git -C "$REPO" rev-parse HEAD
  git -C "$REPO" checkout -q main
}
remote_has() { git -C "$REPO" ls-remote --exit-code --heads origin "refs/heads/$1" >/dev/null 2>&1; }
remote_tag() { git -C "$REPO" ls-remote --tags origin "refs/tags/$1" | cut -f1; }
local_has() { git -C "$REPO" show-ref --verify --quiet "refs/heads/$1"; }

# a finished issue: the code PR merged, the issue branch and work files on GitHub
finished() {
  new_repo; bootstrapped
  issue 41 "Add widget" CLOSED COMPLETED "story" "$(refs)"
  issue_branch 41 widget
  artifact 41 widget intent.md Approved
  pr "$W/07-execute-plan" MERGED 15 2026-11-08T10:00:00Z "code" "" main
}

NAME="plan: a finished issue with a worktree and local branches"
finished
git -C "$REPO" worktree add -q -b "$W/06-build-plan" "$WORK/wt-a" "origin/$W/issue" 2>/dev/null
WT="$(cd "$WORK/wt-a" && pwd)"
local_branch "$W/05-design-spec" "origin/$W/issue" > /dev/null
run 41 plan; code 0
has "path: $WT"; has 'removable: yes'
has "delete|$W/05-design-spec|reachable"; has "delete|$W/06-build-plan|reachable"
has "tag: ship-archive/41-widget"; has 'state: create'; has "target: $(git -C "$REPO" rev-parse "origin/$W/issue")"
has "delete|$W/issue"; has "delete|$W/05-design-spec"
has 'result: ready'; has 'message: -'
git -C "$REPO" ls-remote --exit-code --heads origin "$W/issue" > /dev/null || fail "plan must not delete anything"

NAME="apply: removes the worktree and local branches, tags and pushes the tag, then deletes the remote branches"
RUN_DIR=""; run 41 apply; code 0
has "done|worktree $WT removed"; has 'done|worktrees pruned'
has "done|branch $W/05-design-spec deleted"; has "done|branch $W/06-build-plan deleted"
has "done|tag ship-archive/41-widget created at "; has 'done|tag ship-archive/41-widget pushed'
has "done|remote branch $W/issue deleted"; has "done|remote branch $W/05-design-spec deleted"
[ ! -d "$WORK/wt-a" ] || fail "the worktree folder must be gone"
local_has "$W/05-design-spec" && fail "local branch must be gone"
remote_has "$W/issue" && fail "issue branch must be gone from GitHub"
[ -n "$(remote_tag ship-archive/41-widget)" ] || fail "the archive tag must be on GitHub"
TIP="$(git -C "$REPO" rev-parse "refs/tags/ship-archive/41-widget")"
git -C "$REPO" cat-file -e "$TIP:docs/ship/41-widget/intent.md" 2>/dev/null || fail "the tag must keep the work files reachable"
run 41 apply; code 1; has 'Nothing to clean for #41: no ship/41-* branch or worktree anywhere.'

NAME="a re-run after a partial cleanup: the tag exists and matches, nothing is created twice"
finished
SHA="$(git -C "$REPO" rev-parse "origin/$W/issue")"
git -C "$REPO" tag ship-archive/41-widget "$SHA"; git -C "$REPO" push -q origin ship-archive/41-widget
run 41 plan; code 0; has 'state: exists'; hasnt 'state: create'; has "tag_sha: $SHA"
run 41 apply; code 0; hasnt 'done|tag'; has "done|remote branch $W/issue deleted"

NAME="a squash-merged local branch is proven by the PR's last commit"
finished
SQ="$(local_branch "$W/04-plan-intent" "origin/$W/issue" no-push)"
run 41 plan; code 0; has "refuse|$W/04-plan-intent|unpushed commits"; has 'result: refused'
pr "$W/04-plan-intent" MERGED 8 2026-11-03T10:00:00Z "intent" "$SQ" "$W/issue"
run 41 plan; has "delete|$W/04-plan-intent|pr"; has 'result: ready'

NAME="unpushed commits refuse the whole cleanup and nothing is touched"
finished
git -C "$REPO" worktree add -q -b "$W/06-build-plan" "$WORK/wt-b" "origin/$W/issue" 2>/dev/null
local_branch "$W/05-design-spec" "origin/$W/issue" no-push > /dev/null
run 41 apply; code 1; has "Unpushed commits on: $W/05-design-spec."
[ -d "$WORK/wt-b" ] || fail "the worktree must still be there"
remote_has "$W/issue" || fail "the issue branch must still be on GitHub"
local_has "$W/05-design-spec" || fail "the local branch must still be there"
[ -z "$(remote_tag ship-archive/41-widget)" ] || fail "no tag must have been pushed"

NAME="uncommitted work in the worktree refuses the cleanup"
finished
git -C "$REPO" worktree add -q -b "$W/06-build-plan" "$WORK/wt-c" "origin/$W/issue" 2>/dev/null
echo dirty > "$WORK/wt-c/scratch.txt"
run 41 plan; code 0; has 'removable: no'; has 'result: refused'; has 'uncommitted changes in '
run 41 apply; code 1; has 'The worktree has uncommitted changes'
[ -d "$WORK/wt-c" ] || fail "the worktree must still be there"

NAME="a tag that points elsewhere refuses; the gate stops are passed through"
finished
git -C "$REPO" tag ship-archive/41-widget main; git -C "$REPO" push -q origin ship-archive/41-widget
run 41 plan; code 0; has 'state: conflict'; has 'result: refused'; has 'Resolve it by hand.'
run 41 apply; code 1; has 'The tag ship-archive/41-widget points at'
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs)"; issue_branch 41 widget
run 41 plan; code 1; has 'The code PR is not merged and #41 was not closed as not planned. There is no override.'
RUN_DIR="$WORK"; mkdir -p "$WORK/elsewhere"; RUN_DIR="$WORK/elsewhere"; run 41 plan; unset RUN_DIR; code 1

NAME="remote step branches left by a closed PR are deleted with the issue branch"
finished
local_branch "$W/05-design-spec" "origin/$W/issue" > /dev/null
pr "$W/05-design-spec" CLOSED 9 2026-11-04T10:00:00Z "spec, closed" "" "$W/issue"
run 41 plan; code 0; has "delete|$W/issue"; has "delete|$W/05-design-spec"
run 41 apply; code 0
remote_has "$W/05-design-spec" && fail "the leftover remote branch must be gone"

NAME="closed as not planned, with the remote branches already gone: only local work remains"
new_repo; bootstrapped; issue 41 "Add widget" CLOSED NOT_PLANNED "idea" "$(refs)"
git -C "$REPO" branch "$W/issue" main
run 41 plan; code 0; has 'state: none'; has "delete|$W/issue|reachable" ; has 'result: ready'
run 41 apply; code 0; has "done|branch $W/issue deleted"; hasnt 'done|tag'; hasnt 'done|remote'

NAME="nothing to clean, bad arguments, a failed query"
new_repo; bootstrapped; issue 99 "Nothing" CLOSED NOT_PLANNED "idea" "$(refs)"
run 99 plan; code 1; has 'Nothing to clean for #99'
run; code 2; run 41; code 2; run 41 frobnicate; code 2; run abc plan; code 1; has 'The issue must be a number'
finished
local_branch "$W/05-design-spec" "origin/$W/issue" no-push > /dev/null
export GH_FAIL_HEAD="$W/05-design-spec"
run 41 plan; code 1; has "Could not read pull requests for $W/05-design-spec from GitHub: HTTP 502: Bad Gateway"

finish "ship-cleanup"
