#!/usr/bin/env bash
# Shared by scripts/test-*.sh: a stub gh, temporary git repos and the expectation helpers.
# Source it; it is not run on its own.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
#   SCRIPT="<the script under test>"
#   NAME="a case"; new_repo; ...; run <args>; code 0; has "text"
#   finish "<suite name>"
#
# Needs: git, jq (the stub runs the script's own --jq expression through it).
#
# A case builds a bare "origin" and a clone of it in $REPO. The clone's origin URL names github.com
# and is redirected to the bare repo with url.<path>.insteadOf, so the script's own checks stay as
# they are. The pull requests GitHub would hold are lines in $GH_FIXTURE:
#   head|state|number|date|headRefOid|base|title      (the title is last: it may hold a pipe)
# The issue gh issue view returns is the JSON file $GH_ISSUE (see the stub below).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v jq >/dev/null || { echo "jq is needed to run these tests"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILED=0
CASES=0

# ---- the stub gh --------------------------------------------------------------------------------
#   gh auth status           exits 1 when $GH_NO_AUTH is set
#   gh repo view             test-owner/test-repo (name test-repo)
#   gh pr list               answers from $GH_FIXTURE; honours --head, --base, --state (open when
#                            absent, as the real gh does), --jq; fails for --head $GH_FAIL_HEAD
#   gh pr view <n>           the PR's JSON fields (headRefOid among them) and, when $GH_PR_BODIES/<n>.md
#                            exists, its body, with --jq
#   gh issue view <n>        $GH_ISSUE, with --jq; fails when it holds another issue number
#   gh issue edit <n> --body-file F    copies F to $GH_ISSUE_BODY_OUT and into $GH_ISSUE's body
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
pr_json() {  # the fixture lines that match, as one JSON array
  local h state number date oid base title
  while IFS='|' read -r h state number date oid base title || [ -n "$h" ]; do
    [ -n "$h" ] || continue
    [ -z "$HEAD" ] || [ "$h" = "$HEAD" ] || continue
    [ -z "$BASE" ] || [ "${base:-main}" = "$BASE" ] || continue
    case "$STATE" in
      all) ;;
      "") [ "$state" = "OPEN" ] || continue ;;
      *) [ "$state" = "$(printf '%s' "$STATE" | tr a-z A-Z)" ] || continue ;;
    esac
    jq -nc --arg head "$h" --arg state "$state" --argjson number "$number" --arg date "$date" \
      --arg title "$title" --arg oid "$oid" --arg base "${base:-main}" \
      '{number: $number, state: $state, title: $title, headRefName: $head, baseRefName: $base,
        headRefOid: $oid, createdAt: $date, mergedAt: (if $state == "MERGED" then $date else null end),
        url: ("https://github.com/test-owner/test-repo/pull/" + ($number | tostring))}'
  done < "$GH_FIXTURE" | jq -sc .
}
HEAD=""; BASE=""; STATE=""; EXPR=""; BODY_FILE=""; ARGS=("$@")
i=0
while [ "$i" -lt "${#ARGS[@]}" ]; do
  case "${ARGS[$i]}" in
    --head) HEAD="${ARGS[$((i + 1))]}"; i=$((i + 1)) ;;
    --base) BASE="${ARGS[$((i + 1))]}"; i=$((i + 1)) ;;
    --state) STATE="${ARGS[$((i + 1))]}"; i=$((i + 1)) ;;
    --jq) EXPR="${ARGS[$((i + 1))]}"; i=$((i + 1)) ;;
    --body-file) BODY_FILE="${ARGS[$((i + 1))]}"; i=$((i + 1)) ;;
  esac
  i=$((i + 1))
done
# jq -b: a native Windows jq.exe otherwise turns every newline into \r\n, so a body would gain a \r on
# each round trip through this stub (the real gh does not translate newlines).
emit() { if [ -n "$EXPR" ]; then jq -rb "$EXPR"; else cat; fi; }
case "$1 $2" in
  "auth status") [ -z "$GH_NO_AUTH" ]; exit $? ;;
  "repo view") if [ -n "$EXPR" ]; then echo '{"name":"test-repo","nameWithOwner":"test-owner/test-repo"}' | emit; else echo "test-owner/test-repo"; fi; exit 0 ;;
  "pr list")
    if [ -n "$GH_FAIL_HEAD" ] && [ "$HEAD" = "$GH_FAIL_HEAD" ]; then echo "HTTP 502: Bad Gateway" >&2; exit 1; fi
    pr_json | emit; exit 0 ;;
  "pr view")
    n="$3"; STATE=all; HEAD=""
    obj="$(pr_json | jq -c --argjson n "$n" '.[] | select(.number == $n)')"
    if [ -f "$GH_PR_BODIES/$n.md" ]; then obj="$(printf '%s' "$obj" | jq -c --rawfile b "$GH_PR_BODIES/$n.md" '.body = $b')"; fi
    printf '%s\n' "$obj" | emit; exit 0 ;;
  "issue view")
    { [ -f "$GH_ISSUE" ] && [ "$(jq -rb .number "$GH_ISSUE")" = "$3" ]; } || { echo "GraphQL: Could not resolve to an issue or pull request with the number of $3." >&2; exit 1; }
    emit < "$GH_ISSUE"; exit 0 ;;
  "issue edit")
    [ -n "$BODY_FILE" ] || { echo "stub gh: issue edit without --body-file" >&2; exit 64; }
    cp "$BODY_FILE" "$GH_ISSUE_BODY_OUT"
    jq --rawfile b "$BODY_FILE" '.body = $b' "$GH_ISSUE" > "$GH_ISSUE.tmp" && mv "$GH_ISSUE.tmp" "$GH_ISSUE"
    exit 0 ;;
esac
echo "stub gh: unexpected call: $*" >&2
exit 64
STUB
chmod +x "$WORK/bin/gh"
export PATH="$WORK/bin:$PATH"

# ---- building a case ----------------------------------------------------------------------------
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

# new_repo: an empty origin with a first commit on main, and a clone of it in $REPO.
new_repo() {
  CASES=$((CASES + 1))
  local base="$WORK/case$CASES"
  mkdir -p "$base"
  export GH_FIXTURE="$base/prs.txt"
  export GH_ISSUE="$base/issue.json"
  export GH_ISSUE_BODY_OUT="$base/issue-body-out.md"
  export GH_PR_BODIES="$base/pr-bodies"
  mkdir -p "$GH_PR_BODIES"
  : > "$GH_FIXTURE"
  unset GH_NO_AUTH GH_FAIL_HEAD
  git init -q --bare -b main "$base/origin.git"
  REPO="$base/repo"
  git init -q -b main "$REPO"
  git -C "$REPO" config user.name test
  git -C "$REPO" config user.email test@example.com
  git -C "$REPO" config commit.gpgsign false
  git -C "$REPO" config push.negotiate false
  git -C "$REPO" config "url.$(native "$base/origin.git").insteadOf" "https://github.com/test-owner/test-repo.git"
  git -C "$REPO" remote add origin "https://github.com/test-owner/test-repo.git"
  git -C "$REPO" commit -q --allow-empty -m "chore: initialize repository"
  git -C "$REPO" push -q -u origin main
}

# on_main <path> [<text>]: commit a file to main and push it.
on_main() {
  mkdir -p "$REPO/$(dirname "$1")"
  printf '%s\n' "${2:-content}" > "$REPO/$1"
  git -C "$REPO" add -A
  git -C "$REPO" commit -q -m "add $1"
  git -C "$REPO" push -q origin main
}

# bootstrapped [<backlogModel>]: the project is set up, as 00-bootstrap leaves it on main.
bootstrapped() {
  on_main .cuevik/config.json "{\"schemaVersion\": 6, \"boardState\": \"none\", \"backlogModel\": \"${1:-epic-grouped}\"}"
  on_main .cuevik/lineage.json '{"schemaVersion": 2}'
  on_main CONTRIBUTING.md '<!-- BEGIN INITIATION-ONLY --> rules <!-- END INITIATION-ONLY -->'
}

# pr <head> <state> <number> <date> <title> [<oid> [<base>]]: a pull request GitHub holds.
pr() { printf '%s|%s|%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" "${6:-}" "${7:-main}" "$5" >> "$GH_FIXTURE"; }

# run [args]: run $SCRIPT in $REPO (or $REPO/$RUN_IN, or the folder $RUN_DIR); its output is $OUT and
# its exit status $CODE.
run() { OUT="$(cd "${RUN_DIR:-$REPO${RUN_IN:+/$RUN_IN}}" && bash "$SCRIPT" "$@" 2>&1)"; CODE=$?; }

# ---- cuevik-ship fixtures -------------------------------------------------------------------------
# issue <number> <title> <state> <reason> <labels, comma-separated> [<body file>]: the issue gh returns.
issue() {
  local body=""; [ -n "$6" ] && body="$(cat "$6")"
  local labels; labels="$(printf '%s' "$5" | jq -R 'split(",") | map(select(length > 0) | {name: .})')"
  jq -n --argjson n "$1" --arg t "$2" --arg st "$3" --arg r "$4" --argjson l "$labels" --arg b "$body" \
    '{number: $n, title: $t, state: $st, stateReason: (if $r == "" then null else $r end), labels: $l, body: $b,
      url: ("https://github.com/test-owner/test-repo/issues/" + ($n | tostring))}' > "$GH_ISSUE"
}
refs() {  # a References block with the given lines, as a body file
  { printf 'The idea.\n\n## References\n\n<!-- cuevik-ship:references -->\n'; printf '%s\n' "$@"; printf '<!-- /cuevik-ship:references -->\n'; } > "$WORK/body.md"
  echo "$WORK/body.md"
}

# issue_branch <n> <slug>: ship/<n>-<slug>/issue off main, pushed.
issue_branch() { git -C "$REPO" branch "ship/$1-$2/issue" main && git -C "$REPO" push -q origin "ship/$1-$2/issue"; }
# artifact <n> <slug> <path under docs/ship/<n>-<slug>/> <status> [<extra lines>]: a work file on the issue branch.
artifact() {
  local cur; cur="$(git -C "$REPO" branch --show-current)"
  git -C "$REPO" checkout -q "ship/$1-$2/issue"
  mkdir -p "$REPO/docs/ship/$1-$2/$(dirname "$3")"
  { printf '# Title\n\n**Issue:** [#%s x](u)\n**Date:** 2026-11-01\n**Status:** %s\n' "$1" "$4"; [ -z "$5" ] || printf '\n%s\n' "$5"; } > "$REPO/docs/ship/$1-$2/$3"
  git -C "$REPO" add -A && git -C "$REPO" commit -q -m "add $3" && git -C "$REPO" push -q origin "ship/$1-$2/issue"
  git -C "$REPO" checkout -q "$cur"
}
step_branch() { git -C "$REPO" branch "$1" "${2:-main}" && git -C "$REPO" push -q origin "$1"; }

# ---- expectations -------------------------------------------------------------------------------
fail() { FAILED=$((FAILED + 1)); printf 'FAIL  %s\n      %s\n' "$NAME" "$1"; printf '%s\n' "$OUT" | sed 's/^/      | /'; }
has() { case "$OUT" in *"$1"*) ;; *) fail "expected to find: $1" ;; esac; }
hasnt() { case "$OUT" in *"$1"*) fail "expected not to find: $1" ;; esac; }
code() { [ "$CODE" -eq "$1" ] || fail "expected exit $1, got $CODE"; }

# finish <suite>: print the verdict and exit.
finish() {
  if [ "$FAILED" -gt 0 ]; then
    echo "$1 tests: $FAILED expectations failed in $CASES cases"
    exit 1
  fi
  echo "$1 tests passed ($CASES cases)"
  exit 0
}
