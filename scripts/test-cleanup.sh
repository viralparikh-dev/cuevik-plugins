#!/usr/bin/env bash
# Tests plugins/cuevik-start/scripts/cleanup.sh against real temporary git repos and a stub gh.
#
# Usage:  bash scripts/test-cleanup.sh
# Needs:  git, jq (see scripts/test-lib.sh, which holds the stub gh and the helpers)

source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
SCRIPT="$ROOT/plugins/cuevik-start/scripts/cleanup.sh"

# branch <name> [<commit message>]: a local branch off main with one commit; prints its tip.
branch() {
  git -C "$REPO" checkout -q -b "$1" main
  git -C "$REPO" commit -q --allow-empty -m "${2:-work on $1}"
  git -C "$REPO" rev-parse HEAD
  git -C "$REPO" checkout -q main
}
exists() { git -C "$REPO" show-ref --verify --quiet "refs/heads/$1"; }
must_exist() { exists "$1" || fail "expected branch $1 to exist"; }
must_not_exist() { ! exists "$1" || fail "expected branch $1 to be gone"; }

NAME="a merged branch whose tip is the PR's last commit is safe; the others are skipped"
new_repo; bootstrapped
TIP="$(branch init/product-concept)"
pr init/product-concept MERGED 4 2026-11-02T10:00:00Z "concept" "$TIP"
branch init/product-requirements > /dev/null
branch init/architecture > /dev/null
pr init/architecture OPEN 7 2026-11-03T10:00:00Z "architecture" "abc"
OLD="$(branch init/tech-stack)"
git -C "$REPO" checkout -q init/tech-stack && git -C "$REPO" commit -q --allow-empty -m "after the PR" && git -C "$REPO" checkout -q main
pr init/tech-stack MERGED 9 2026-11-04T10:00:00Z "stack" "$OLD"
run plan; code 0
has 'delete|init/product-concept|4'
has 'skip|init/product-requirements|no merged PR'
has 'skip|init/architecture|no merged PR (open PR #7)'
has 'skip|init/tech-stack|local commits not in PR #9'
has 'branch: main'; has 'clean: yes'

NAME="a squash-merged branch: the PR's commit id is the proof, not git ancestry"
new_repo; bootstrapped
TIP="$(branch init/readme)"
pr init/readme MERGED 12 2026-11-05T10:00:00Z "readme" "$TIP"
run plan; code 0
has 'delete|init/readme|12'

NAME="two merged PRs from one branch: the one at the tip counts"
new_repo; bootstrapped
TIP="$(branch init/backlog)"
pr init/backlog MERGED 3 2026-11-01T10:00:00Z "first try" "0000000000000000000000000000000000000001"
pr init/backlog MERGED 5 2026-11-06T10:00:00Z "second try" "$TIP"
run plan; code 0
has 'delete|init/backlog|5'

NAME="old numbered branches and migrate are init/* branches too"
new_repo; bootstrapped
A="$(branch init/03-architecture)"; B="$(branch init/migrate)"
pr init/03-architecture MERGED 6 2026-10-05T10:00:00Z "architecture" "$A"
pr init/migrate MERGED 20 2026-11-11T10:00:00Z "migrate" "$B"
run plan; code 0
has 'delete|init/03-architecture|6'; has 'delete|init/migrate|20'

NAME="the checked-out branch: switched to main first, but not with uncommitted changes"
new_repo; bootstrapped
TIP="$(branch init/finalize)"
pr init/finalize MERGED 30 2026-11-09T10:00:00Z "finalize" "$TIP"
git -C "$REPO" checkout -q init/finalize
run plan; code 0
has 'delete|init/finalize|30'; has 'branch: init/finalize'; has 'clean: yes'
echo dirty > "$REPO/scratch.txt"
run plan; code 0
has 'skip|init/finalize|checked out with uncommitted changes; PR #30 is merged'; has 'clean: no'
rm "$REPO/scratch.txt"
run delete init/finalize; code 0
has 'deleted|init/finalize|30'
[ "$(git -C "$REPO" branch --show-current)" = "main" ] || fail "expected to be on main after deleting the current branch"
must_not_exist init/finalize

NAME="delete removes only what is still safe, and stops at the first refusal"
new_repo; bootstrapped
A="$(branch init/product-concept)"; branch init/product-requirements > /dev/null
pr init/product-concept MERGED 4 2026-11-02T10:00:00Z "concept" "$A"
run delete init/product-concept init/product-requirements init/readme; code 1
has 'deleted|init/product-concept|4'
has 'refused|init/product-requirements|no merged PR'
hasnt 'init/readme'
must_not_exist init/product-concept; must_exist init/product-requirements

NAME="delete refuses a branch that is not init/*, and one whose PR moved on"
new_repo; bootstrapped
branch feature/x > /dev/null
run delete feature/x; code 1; has 'refused|feature/x|not an init/* branch'; must_exist feature/x
TIP="$(branch init/readme)"
pr init/readme MERGED 12 2026-11-05T10:00:00Z "readme" "$TIP"
git -C "$REPO" checkout -q init/readme && git -C "$REPO" commit -q --allow-empty -m "late" && git -C "$REPO" checkout -q main
run delete init/readme; code 1; has 'refused|init/readme|local commits not in PR #12'; must_exist init/readme

NAME="remote init/* branches left on GitHub are listed, never deleted"
new_repo; bootstrapped
branch init/architecture > /dev/null
git -C "$REPO" push -q origin init/architecture
pr init/architecture CLOSED 8 2026-11-03T10:00:00Z "abandoned" "$(git -C "$REPO" rev-parse init/architecture)"
run plan; code 0
has '== remote'; has 'init/architecture'
has 'skip|init/architecture|no merged PR'
git -C "$REPO" ls-remote --exit-code --heads origin init/architecture > /dev/null || fail "the remote branch must still exist"

NAME="the last step's merge date, from its branch or an alias"
new_repo; bootstrapped
run plan; code 0; has 'step: 09-finalize'; has 'merged: -'
pr init/08-finalize MERGED 31 2026-11-09T14:00:00Z "finalize, old name" "x"
run plan; code 0; has 'branch: init/08-finalize'; has 'merged: 2026-11-09'
pr init/finalize MERGED 40 2026-11-12T09:00:00Z "finalize" "y"
run plan; code 0; has 'branch: init/finalize'; has 'merged: 2026-11-12'

NAME="no init/* branches at all"
new_repo; bootstrapped
run plan; code 0; has '== branches'; hasnt 'delete|'; hasnt 'skip|'

NAME="a failed GitHub query stops instead of reading as no merged PR"
new_repo; bootstrapped
branch init/readme > /dev/null
export GH_FAIL_HEAD=init/readme
run plan; code 1; has 'Could not read pull requests for init/readme from GitHub: HTTP 502: Bad Gateway'
hasnt 'skip|'
run delete init/readme; code 1; has 'Could not read pull requests for init/readme'; must_exist init/readme

NAME="preflight and usage"
new_repo
export GH_NO_AUTH=1; run plan; code 1; has 'gh is not signed in. Run gh auth login, then re-run.'; unset GH_NO_AUTH
mkdir -p "$REPO/sub"; RUN_IN=sub; run plan; unset RUN_IN; code 1; has 'Run cleanup from the repo root.'
run; code 2; run delete; code 2; run plan extra; code 2; run frobnicate; code 2
REPO="$WORK/not-a-repo"; mkdir -p "$REPO"; run plan; code 1; has 'This folder is not a git repo.'

finish "cleanup"
