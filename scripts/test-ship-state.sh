#!/usr/bin/env bash
# Tests plugins/cuevik-ship/scripts/ship-state.sh against real temporary git repos and a stub gh.
#
# Usage:  bash scripts/test-ship-state.sh
# Needs:  git, jq (see scripts/test-lib.sh, which holds the stub gh and the helpers)

source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
SCRIPT="$ROOT/plugins/cuevik-ship/scripts/ship-state.sh"

W="ship/41-widget"
SPEC8='## 7. Changes

x

## 8. Requires sign-off before 06-build-plan

- [x] schema change, because a column
- [ ] new dependency, because a lib
- [ ] auth change, because a role

## 9. After'

NAME="a fresh idea: no ship branches yet, step 01 may start"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "idea" "$(refs)"
run 41 01-brainstorm; code 0
has 'number: 41'; has 'title: Add widget'; has 'state: open'; has 'labels: idea'
has 'slug: -'; has 'slug_source: none'; has 'issue_branch: no'; has 'main_checkout: yes'
has 'block: ok'; has 'epic: -'; has 'docs_pr: -'; has 'backlog_model: epic-grouped'
has 'result: pass'; has 'done: no'
run "#41"; code 0; hasnt '== gate'
run "https://github.com/test-owner/test-repo/issues/41"; code 0; has 'number: 41'

NAME="common preconditions"
new_repo; issue 41 "Add widget" OPEN "" "idea" "$(refs)"
run 41 01-brainstorm; code 1; has 'This repo is not set up for cuevik. Run /cuevik-start:00-bootstrap first.'
bootstrapped; rm -f "$GH_ISSUE"
run 41 01-brainstorm; code 1; has 'Issue #41 was not found'
issue 41 "Add widget" OPEN "" "idea" "$(refs)"
export GH_NO_AUTH=1; run 41 01-brainstorm; code 1; has 'gh is not signed in. Run gh auth login, then re-run.'; unset GH_NO_AUTH
echo dirty > "$REPO/scratch.txt"
run 41 02-audit-prd; code 1; has 'Uncommitted changes detected — commit or stash before continuing.'
run 41; code 0; hasnt 'Uncommitted'
run 41 cleanup; code 0
rm "$REPO/scratch.txt"
mkdir -p "$REPO/sub"; RUN_IN=sub; run 41 01-brainstorm; unset RUN_IN; code 1; has 'Run cuevik-ship from the repo or worktree root.'
run; code 2; run abc; code 1; has 'The issue must be a number'; run 41 99-nope; code 2; run 41 01-brainstorm extra; code 2
REPO="$WORK/not-a-repo"; mkdir -p "$REPO"; run 41 01-brainstorm; code 1; has 'This folder is not a git repo.'

NAME="02 needs 01 merged and brainstorm.md Approved"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "idea" "$(refs)"
issue_branch 41 widget
artifact 41 widget brainstorming/brainstorm.md Draft
run 41 02-audit-prd; code 0
has 'slug: widget'; has 'slug_source: remote'; has 'issue_branch: yes'
has 'brainstorm.md|Draft|-'
has 'result: stop'; has "message: 01-brainstorm has no merged PR: run /cuevik-ship:01-brainstorm 41 first."
pr "$W/01-brainstorm" OPEN 5 2026-11-02T10:00:00Z "brainstorm" "" "$W/issue"
run 41 02-audit-prd; has "message: 01-brainstorm's PR #5 is still open: merge it into $W/issue first. An open PR does not count."
pr "$W/01-brainstorm" MERGED 5 2026-11-02T10:00:00Z "brainstorm" "" "$W/issue"
run 41 02-audit-prd; has 'message: brainstorm.md reads Draft, not Approved: finish it with /cuevik-ship:01-brainstorm 41.'
artifact 41 widget brainstorming/brainstorm.md Rejected
run 41 02-audit-prd; has 'message: brainstorm.md reads Rejected: the idea has been decided.'
artifact 41 widget brainstorming/brainstorm.md Approved
run 41 02-audit-prd; has 'brainstorm.md|Approved|-'; has 'result: pass'; has 'message: -'
run 41 01-brainstorm; has 'result: stop'; has 'done: yes'; has '01-brainstorm is already done for #41 (PR #5 merged). Next is 02-audit-prd.'
has "01-brainstorm|$W/01-brainstorm|$W/issue|merged|5|2026-11-02|brainstorm"

NAME="a step with an open PR stops; a branch with no PR is a resume"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
artifact 41 widget brainstorming/brainstorm.md Approved
pr "$W/01-brainstorm" MERGED 5 2026-11-02T10:00:00Z "b" "" "$W/issue"
step_branch "$W/04-plan-intent" "$W/issue"
run 41 04-plan-intent; code 0
has "04-plan-intent|$W/04-plan-intent|$W/issue|branch|-|-|-"
has 'result: pass'; has "step_branch: $W/04-plan-intent"; has 'step_branch_state: both'
git -C "$REPO" branch -D "$W/04-plan-intent" -q
run 41 04-plan-intent; has 'step_branch_state: remote'
pr "$W/04-plan-intent" OPEN 8 2026-11-03T10:00:00Z "intent" "" "$W/issue"
run 41 04-plan-intent; has 'result: stop'; has '04-plan-intent already has an open PR #8: merge or close it first.'

NAME="03 needs the 02 PR merged into main with its ratified block"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "idea" "$(refs '- Docs PR: #7')"
issue_branch 41 widget
run 41 03-create-backlog; has 'result: stop'; has '02-audit-prd has no merged PR: PR #7 was not found. Run /cuevik-ship:02-audit-prd 41.'
has 'docs_pr: 7'
pr "$W/02-audit-prd" OPEN 7 2026-11-04T10:00:00Z "docs"
run 41 03-create-backlog; has "02-audit-prd's PR #7 is still open: merge it into main first."
: > "$GH_FIXTURE"; pr "$W/02-audit-prd" MERGED 7 2026-11-04T10:00:00Z "docs"
printf 'Requirements.\n' > "$GH_PR_BODIES/7.md"
run 41 03-create-backlog; has 'result: stop'; has 'PR #7 (02-audit-prd) has no ratified block in its body: re-run /cuevik-ship:02-audit-prd 41.'
printf 'Requirements.\n<!-- cuevik-ship:ratified -->\nids: [PRD-1]\n<!-- /cuevik-ship:ratified -->\n' > "$GH_PR_BODIES/7.md"
run 41 03-create-backlog; has 'result: pass'; has '02-audit-prd|'"$W"'/02-audit-prd|main|merged|7|2026-11-04|docs'

NAME="03 without a Docs PR line uses the 02 branch's PR; a PR not merged into main stops"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "idea" "$(refs)"
issue_branch 41 widget
pr "$W/02-audit-prd" MERGED 7 2026-11-04T10:00:00Z "docs"
printf '<!-- cuevik-ship:ratified -->\nids: []\n<!-- /cuevik-ship:ratified -->\n' > "$GH_PR_BODIES/7.md"
run 41 03-create-backlog; has 'docs_pr: -'; has 'result: pass'
: > "$GH_FIXTURE"; pr "$W/02-audit-prd" CLOSED 7 2026-11-04T10:00:00Z "docs"
run 41 03-create-backlog; has 'result: stop'; has "02-audit-prd's PR #7 is not merged into main (CLOSED main)"

NAME="a step that works in the worktree stops when run from another folder; 03 does not"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
artifact 41 widget intent.md Approved
pr "$W/04-plan-intent" MERGED 8 2026-11-03T10:00:00Z "intent" "" "$W/issue"
git -C "$REPO" worktree add -q -b "$W/01-brainstorm" "$WORK/wt-case1" "origin/$W/issue" 2>/dev/null
run 41 05-design-spec; has 'result: stop'; has 'message: #41 has a worktree: open a session in '; has '/wt-case1 and run /cuevik-ship:05-design-spec 41 there.'
RUN_DIR="$WORK/wt-case1"; run 41 05-design-spec; unset RUN_DIR; has 'result: pass'
run 41 04-plan-intent; has '04-plan-intent is already done'

NAME="preflight: only the common preconditions, no issue needed"
new_repo
run --preflight; code 1; has 'This repo is not set up for cuevik.'
bootstrapped
run --preflight; code 0; has 'preflight: ok'; hasnt '== issue'
echo dirty > "$REPO/scratch.txt"; run --preflight; code 1; has 'Uncommitted changes detected'
rm "$REPO/scratch.txt"; run --preflight 41; code 2

NAME="04: epics, ideas and closed issues are refused; after 03 it needs an Epic line (or the story label when flat)"
new_repo; bootstrapped; issue 50 "Epic: X" OPEN "" "epic" "$(refs)"
run 50 04-plan-intent; has 'result: stop'; has '#50 is an epic: plan one of its stories.'
issue 51 "Idea" OPEN "" "idea" "$(refs)"; run 51 04-plan-intent; has '#51 is still an idea: it has not been through 02 and 03.'
issue 52 "Old" CLOSED COMPLETED "story" "$(refs)"; run 52 04-plan-intent; has '#52 is closed.'; has 'state: closed'
issue 53 "A bug" OPEN "" "bug" "$(refs)"; run 53 04-plan-intent; has 'result: pass'
git -C "$REPO" branch "ship/54-feature/issue" main; git -C "$REPO" push -q origin "ship/54-feature/issue"
issue 54 "Story" OPEN "" "story" "$(refs)"; run 54 04-plan-intent; has 'result: stop'; has 'The References block of #54 has no Epic: line: it has not been through 03.'
issue 54 "Story" OPEN "" "story" "$(refs '- Epic: #12')"; run 54 04-plan-intent; has 'result: pass'; has 'epic: 12'
issue 54 "Story" OPEN "" "story,idea" "$(refs '- Epic: #12')"; run 54 04-plan-intent; has '#54 is still an idea'

NAME="04 on a flat repo needs the story label, not an Epic line"
new_repo; bootstrapped flat
git -C "$REPO" branch "ship/54-feature/issue" main; git -C "$REPO" push -q origin "ship/54-feature/issue"
issue 54 "Story" OPEN "" "story" "$(refs)"; run 54 04-plan-intent; has 'backlog_model: flat'; has 'result: pass'
issue 54 "Story" OPEN "" "bug" "$(refs)"; run 54 04-plan-intent; has 'result: stop'; has '#54 has no story label: it has not been through 03.'

NAME="05 and 07 need the previous PR merged and its file Approved"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
run 41 05-design-spec; has 'result: stop'; has '04-plan-intent has no merged PR'
pr "$W/04-plan-intent" MERGED 8 2026-11-03T10:00:00Z "intent" "" "$W/issue"
run 41 05-design-spec; has 'result: stop'; has 'intent.md is missing on '"$W"'/issue: run /cuevik-ship:04-plan-intent 41.'
artifact 41 widget intent.md Approved
run 41 05-design-spec; has 'result: pass'; has 'intent.md|Approved|-'
pr "$W/06-build-plan" MERGED 11 2026-11-06T10:00:00Z "plan" "" "$W/issue"
artifact 41 widget plan.md Draft
run 41 07-execute-plan; has 'result: stop'; has 'plan.md reads Draft, not Approved: finish it with /cuevik-ship:06-build-plan 41.'
artifact 41 widget plan.md Approved
run 41 07-execute-plan; has 'result: pass'; has "step_branch: $W/07-execute-plan"; has 'step_branch_state: none'
pr "$W/07-execute-plan" MERGED 15 2026-11-08T10:00:00Z "code" "" main
run 41 07-execute-plan; has 'result: stop'; has 'done: yes'; has '07-execute-plan is already done for #41 (PR #15 merged). Next is cleanup.'

NAME="06 reports the unticked boxes of the spec's section 8 and does not stop on them"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
pr "$W/05-design-spec" MERGED 9 2026-11-04T10:00:00Z "spec" "" "$W/issue"
artifact 41 widget spec.md Approved "$SPEC8"
run 41 06-build-plan; code 0
has 'spec.md|Approved|2'; has 'result: pass'; has 'spec_unticked: 2'
artifact 41 widget spec.md Approved '## 8. Requires sign-off before 06-build-plan

- [x] schema change, because a column

## 9. After'
run 41 06-build-plan; has 'spec.md|Approved|0'; has 'spec_unticked: 0'

NAME="an artifact that already reads Approved is a finished step even with no merged PR"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
artifact 41 widget intent.md Approved
run 41 04-plan-intent; has 'result: stop'; has 'done: yes'; has '04-plan-intent is already done for #41: its work file reads Approved. Next is 05-design-spec.'

NAME="a closed PR with its branch gone leaves the step startable"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
pr "$W/04-plan-intent" CLOSED 8 2026-11-03T10:00:00Z "intent, abandoned" "" "$W/issue"
run 41 04-plan-intent; has "04-plan-intent|$W/04-plan-intent|$W/issue|closed|8|-|intent, abandoned"; has 'result: pass'

NAME="two slugs for one issue stop"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs)"
issue_branch 41 widget; issue_branch 41 gadget
run 41 05-design-spec; code 1; has 'More than one slug for #41:'; has 'widget'; has 'gadget'

NAME="the References block: malformed stops every step, a missing one is only reported"
new_repo; bootstrapped
printf 'x\n<!-- /cuevik-ship:references -->\n- Epic: #1\n<!-- cuevik-ship:references -->\n' > "$WORK/bad.md"
issue 41 "Add widget" OPEN "" "story" "$WORK/bad.md"
run 41 01-brainstorm; code 0; has 'block: malformed'; has 'result: stop'; has 'The References block in #41 is malformed'
printf 'two blocks\n<!-- cuevik-ship:references -->\n<!-- /cuevik-ship:references -->\n<!-- cuevik-ship:references -->\n<!-- /cuevik-ship:references -->\n' > "$WORK/two.md"
issue 41 "Add widget" OPEN "" "story" "$WORK/two.md"; run 41 01-brainstorm; has 'block: malformed'
printf 'no block at all\n' > "$WORK/none.md"; issue 41 "Add widget" OPEN "" "story" "$WORK/none.md"
run 41 01-brainstorm; has 'block: missing'; has 'result: pass'

NAME="the worktree is found, and this folder is recognised as it"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs)"
issue_branch 41 widget
git -C "$REPO" worktree add -q -b "$W/01-brainstorm" "$WORK/wt-case2" "origin/$W/issue" 2>/dev/null
run 41; code 0; has 'worktree: '; has '/wt-case2'; has 'here: no'; has 'main_checkout: yes'
RUN_DIR="$WORK/wt-case2"; run 41 01-brainstorm; unset RUN_DIR
has 'here: yes'; has 'main_checkout: no'

NAME="cleanup: the code PR merged, no open ship PR, main checkout"
new_repo; bootstrapped; issue 41 "Add widget" CLOSED COMPLETED "story" "$(refs)"
issue_branch 41 widget
run 41 cleanup; code 0; has 'result: stop'; has 'The code PR is not merged and #41 was not closed as not planned. There is no override.'
pr "$W/07-execute-plan" MERGED 15 2026-11-08T10:00:00Z "code" "" main
run 41 cleanup; has 'result: pass'; has 'step: cleanup'
pr "$W/05-design-spec" OPEN 9 2026-11-04T10:00:00Z "spec" "" "$W/issue"
run 41 cleanup; has 'result: stop'; has 'Open PRs from ship/41-* branches: #9 '"$W"'/05-design-spec.'
RUN_DIR="$WORK/none"; mkdir -p "$WORK/none"
git -C "$REPO" worktree add -q -b "$W/04-plan-intent" "$WORK/wt-case3" "origin/$W/issue" 2>/dev/null
RUN_DIR="$WORK/wt-case3"; run 41 cleanup; unset RUN_DIR
has 'result: stop'; has 'Run cleanup from the main checkout, not from a worktree.'

NAME="cleanup: closed as not planned passes; with the remote branches gone the slug comes from local branches"
new_repo; bootstrapped; issue 41 "Add widget" CLOSED NOT_PLANNED "idea" "$(refs)"
git -C "$REPO" branch "$W/issue" main
run 41 cleanup; code 0; has 'slug: widget'; has 'slug_source: local'; has 'issue_branch: no'; has 'result: pass'
run 99 cleanup; code 1; has 'Issue #99 was not found'
issue 99 "Nothing" CLOSED NOT_PLANNED "idea" "$(refs)"; run 99 cleanup; has 'result: stop'; has 'Nothing to clean for #99'

NAME="a failed GitHub query stops the state"
new_repo; bootstrapped; issue 41 "Add widget" OPEN "" "story" "$(refs)"
issue_branch 41 widget
export GH_FAIL_HEAD="$W/05-design-spec"
run 41 05-design-spec; code 1; has "Could not read pull requests for $W/05-design-spec from GitHub: HTTP 502: Bad Gateway"; hasnt '== issue'

finish "ship-state"
