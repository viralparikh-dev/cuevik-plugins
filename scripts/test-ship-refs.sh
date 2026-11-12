#!/usr/bin/env bash
# Tests plugins/cuevik-ship/scripts/ship-refs.sh against real temporary git repos and a stub gh.
#
# Usage:  bash scripts/test-ship-refs.sh
# Needs:  git, jq (see scripts/test-lib.sh, which holds the stub gh and the helpers)

source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
SCRIPT="$ROOT/plugins/cuevik-ship/scripts/ship-refs.sh"
W="ship/41-widget"
REPO_URL="https://github.com/test-owner/test-repo/blob"

sha_of() { git -C "$REPO" log -1 --format=%H "origin/$W/issue" -- "docs/ship/41-widget/$1"; }
body() { jq -rb .body "$GH_ISSUE"; }   # -b: no newline translation by a native Windows jq.exe
edited() { [ -f "$GH_ISSUE_BODY_OUT" ]; }
step_with_file() {  # step_with_file <step> <path> <status>: the step's branch holds the file, pushed, not merged
  git -C "$REPO" checkout -q -b "$W/$1" "origin/$W/issue"
  mkdir -p "$REPO/docs/ship/41-widget/$(dirname "$2")"
  printf '# T\n\n**Status:** %s\n' "$3" > "$REPO/docs/ship/41-widget/$2"
  git -C "$REPO" add -A && git -C "$REPO" commit -q -m "add $2" && git -C "$REPO" push -q origin "$W/$1"
  git -C "$REPO" checkout -q main
}

NAME="a body with no block gets one appended; nothing else changes"
new_repo; bootstrapped
printf 'The idea, in two sentences.\n\nMore detail.' > "$WORK/b.md"
issue 41 "Add widget" OPEN "" "idea" "$WORK/b.md"
run 41 apply; code 0; has 'action: created'
[ "$(body)" = "$(printf 'The idea, in two sentences.\n\nMore detail.\n\n## References\n\n<!-- cuevik-ship:references -->\n<!-- /cuevik-ship:references -->')" ] || fail "unexpected body: $(body)"
run 41 apply; code 0; has 'action: unchanged'

NAME="every provable line, with permalinks to the issue branch's latest commit and the PR numbers"
new_repo; bootstrapped
issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12' '- Split from: #30')"
issue_branch 41 widget
artifact 41 widget brainstorming/brainstorm.md Approved
artifact 41 widget intent.md Approved
pr "$W/01-brainstorm" MERGED 5 2026-11-02T10:00:00Z "b" "" "$W/issue"
pr "$W/02-audit-prd" MERGED 7 2026-11-04T10:00:00Z "docs"
pr "$W/04-plan-intent" MERGED 8 2026-11-03T10:00:00Z "i" "" "$W/issue"
pr "$W/07-execute-plan" OPEN 15 2026-11-08T10:00:00Z "code"
run 41 show; code 0; has 'action: updated'
has "- Brainstorm: [brainstorm.md]($REPO_URL/$(sha_of brainstorming/brainstorm.md)/docs/ship/41-widget/brainstorming/brainstorm.md) · PR #5"
has '- Docs PR: #7'; has '- Epic: #12'
has "- Intent: [intent.md]($REPO_URL/$(sha_of intent.md)/docs/ship/41-widget/intent.md) · PR #8"
has '- Code PR: #15'; has '- Split from: #30'
edited && fail "show must not edit the issue"
run 41 apply; code 0
B="$(body)"
case "$B" in *'- Docs PR: #7'*'- Epic: #12'*'- Intent: [intent.md]'*'- Code PR: #15'*'- Split from: #30'*) ;; *) fail "lines out of order: $B" ;; esac
run 41 apply; has 'action: unchanged'

NAME="a file only on its step's branch links that branch's tip, then re-points once merged and changed"
new_repo; bootstrapped
issue 41 "Add widget" OPEN "" "story" "$(refs '- Epic: #12')"
issue_branch 41 widget
step_with_file 05-design-spec spec.md Draft
pr "$W/05-design-spec" OPEN 9 2026-11-04T10:00:00Z "spec" "" "$W/issue"
TIP="$(git -C "$REPO" rev-parse "origin/$W/05-design-spec")"
run 41 apply; code 0; has "- Spec: [spec.md]($REPO_URL/$TIP/docs/ship/41-widget/spec.md) · PR #9"
artifact 41 widget spec.md Approved
pr "$W/05-design-spec" MERGED 9 2026-11-04T10:00:00Z "spec" "" "$W/issue"
: > "$GH_FIXTURE"; pr "$W/05-design-spec" MERGED 9 2026-11-04T10:00:00Z "spec" "" "$W/issue"
run 41 apply; has "- Spec: [spec.md]($REPO_URL/$(sha_of spec.md)/docs/ship/41-widget/spec.md) · PR #9"
OLD="$(sha_of spec.md)"
artifact 41 widget spec.md Approved "changed during the plan"
run 41 apply; has "- Spec: [spec.md]($REPO_URL/$(sha_of spec.md)/docs/ship/41-widget/spec.md)"
[ "$(sha_of spec.md)" != "$OLD" ] || fail "the permalink must move to the newer commit"

NAME="a line is never removed, and unknown lines stay after the known ones"
new_repo; bootstrapped
printf 'x\n\n## References\n\n<!-- cuevik-ship:references -->\n- Spec: [spec.md](https://example.com/old) · PR #9\n- Note: keep me\n- Epic: #12\n- Split into: #20, #21\n<!-- /cuevik-ship:references -->\n' > "$WORK/b.md"
issue 41 "Add widget" OPEN "" "story" "$WORK/b.md"
issue_branch 41 widget
run 41 show; code 0
has '- Spec: [spec.md](https://example.com/old) · PR #9'; has '- Epic: #12'; has '- Split into: #20, #21'; has '- Note: keep me'
[ "$(printf '%s\n' "$OUT" | grep -n '^- ' | tail -n 1 | cut -d: -f2-)" = "- Note: keep me" ] || fail "the unknown line must come last"

NAME="text outside the markers is untouched, including CRLF line endings"
new_repo; bootstrapped
issue_branch 41 widget
artifact 41 widget intent.md Approved
pr "$W/04-plan-intent" MERGED 8 2026-11-03T10:00:00Z "i" "" "$W/issue"
printf 'Line one\r\nLine two\r\n\r\n## References\r\n\r\n<!-- cuevik-ship:references -->\r\n<!-- /cuevik-ship:references -->\r\n\r\nTrailing words.\r\n' > "$WORK/crlf.md"
issue 41 "t" OPEN "" "story" "$WORK/crlf.md"
run 41 apply; code 0; has 'action: updated'
# Show every CR as a visible ~ with tr, then look for it with grep: Git for Windows' grep treats CRLF as the
# line end and cannot match a CR itself.
jq -rjb .body "$GH_ISSUE" | tr '\r' '~' > "$WORK/after.txt"
grep -q '^Line one~$' "$WORK/after.txt" || fail "CRLF before the block must survive"
grep -q '^Trailing words\.~$' "$WORK/after.txt" || fail "text after the block must survive with its CRLF"
grep -q '^- Intent: \[intent.md\].*~$' "$WORK/after.txt" || fail "inserted lines must use the body's CRLF"
[ "$(grep -vc '~$' "$WORK/after.txt")" = 0 ] || fail "every line of a CRLF body must end with a CR"

NAME="the lines a branch cannot prove are set by the step that knows them, and replaced when said again"
new_repo; bootstrapped
issue 41 "Add widget" OPEN "" "idea" "$(refs '- Epic: #1')"
run 41 show --epic "#12" --split-from "#30" --split-into "#20, #21"; code 0
has '- Epic: #12'; has '- Split from: #30'; has '- Split into: #20, #21'
[ "$(printf '%s\n' "$OUT" | grep -c '^- Epic:')" = 1 ] || fail "the old Epic line must be replaced, not kept beside the new one"
edited && fail "show must not edit the issue"
run 41 apply --epic "#12" --split-from "#30"; code 0
case "$(body)" in *'- Epic: #12'*'- Split from: #30'*) ;; *) fail "the lines must be in the body: $(body)" ;; esac
run 41 apply --epic "#12"; has 'action: unchanged'; has '- Split from: #30'
run 41 apply --epic 12; code 1; has '--epic takes issue numbers written #n, not: 12'
run 41 apply --bogus "#1"; code 2; run 41 apply --epic; code 2

NAME="a refresh adds nothing to the body: no trailing newline appears, none is lost, however often it runs"
new_repo; bootstrapped
issue_branch 41 widget; artifact 41 widget intent.md Approved
pr "$W/04-plan-intent" MERGED 8 2026-11-03T10:00:00Z "i" "" "$W/issue"
printf 'Head\n\n<!-- cuevik-ship:references -->\n<!-- /cuevik-ship:references -->\nTail with no final newline' > "$WORK/nonl.md"
issue 41 "t" OPEN "" "story" "$WORK/nonl.md"
run 41 apply; code 0; has 'action: updated'
case "$(jq -rjb .body "$GH_ISSUE" | tr '\n' '^')" in *'-->^Tail with no final newline') ;; *) fail "the tail must be byte for byte as it was: $(jq -rjb .body "$GH_ISSUE" | tr '\n' '^')" ;; esac
run 41 apply; has 'action: unchanged'
printf 'Body ends with newlines\n\n' > "$WORK/nl.md"
issue 41 "t" OPEN "" "story" "$WORK/nl.md"
run 41 apply; code 0
A="$(jq -rjb .body "$GH_ISSUE" | tr '\n' '^')"
case "$A" in 'Body ends with newlines^^^## References^^<!-- cuevik-ship:references -->^- Intent: '*'^<!-- /cuevik-ship:references -->^') ;; *) fail "unexpected body: $A" ;; esac
run 41 apply; has 'action: unchanged'
[ "$(jq -rjb .body "$GH_ISSUE" | tr '\n' '^')" = "$A" ] || fail "a second refresh must not change the body"

NAME="a malformed block stops, and nothing is written"
new_repo; bootstrapped
printf '<!-- /cuevik-ship:references -->\n- Epic: #1\n<!-- cuevik-ship:references -->\n' > "$WORK/bad.md"
issue 41 "Add widget" OPEN "" "story" "$WORK/bad.md"
run 41 apply; code 1; has 'The References block in #41 is malformed'
edited && fail "nothing may be written"

NAME="preconditions and usage"
new_repo
issue 41 "Add widget" OPEN "" "story" "$(refs)"
run 41 apply; code 1; has 'This repo is not set up for cuevik.'
bootstrapped
run; code 2; run 41; code 2; run 41 frobnicate; code 2; run abc apply; code 1; has 'The issue must be a number'
rm -f "$GH_ISSUE"; run 41 apply; code 1; has 'Issue #41 was not found'

finish "ship-refs"
