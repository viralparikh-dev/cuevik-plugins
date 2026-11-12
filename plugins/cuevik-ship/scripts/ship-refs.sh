#!/usr/bin/env bash
# cuevik-ship: refresh the References block in an issue's description (references-block.md).
#
# Usage:  bash ship-refs.sh <issue> show  [<options>]   print the block it would write, change nothing
#         bash ship-refs.sh <issue> apply [<options>]   write it into the issue (gh issue edit), if changed
#           --epic "#12"             set the Epic: line (written by 03-create-backlog)
#           --split-from "#30"       set the Split from: line
#           --split-into "#20, #21"  set the Split into: line
#         These three lines cannot be derived from a branch, so the step that knows them says them.
#
# The block holds links to the issue's work files and PRs, never file content. This script derives
# every line a branch or a PR can prove (Brainstorm, Docs PR, Intent, Spec, Plan, Code PR), keeps
# every line it cannot derive exactly as it is (Epic, Split from, Split into, anything unknown), and
# never removes a line. A file link points at a commit, so it survives cleanup: the latest commit on
# the issue branch that touched the file, or, while the file is only on its step's branch, that
# branch's tip. Only the text between the two markers changes; a body without them gets
# "## References" and the block appended. Two blocks, or an end before a start: it stops.
# Needs git and gh (signed in); the facts come from ship-state.sh, beside this file.
#
# Output: "== references", "action: unchanged|updated|created" and the block's lines.
# Exit: 0 done. 1 a precondition failed, the block is malformed or a GitHub call failed: the last
# line is the message. 2 wrong usage. Bash 3.2 and Git Bash safe.

stop() { printf '%s\n' "$1"; exit 1; }
usage() { printf 'usage: ship-refs.sh <issue> show|apply [--epic "#n"] [--split-from "#n"] [--split-into "#a, #b"]\n' >&2; exit 2; }

[ "$#" -ge 2 ] || usage
ISSUE="${1##*/}"; ISSUE="${ISSUE#\#}"
case "$ISSUE" in '' | *[!0-9]*) stop "The issue must be a number, #number or the issue's URL, not: $1" ;; esac
MODE="$2"
case "$MODE" in show | apply) ;; *) usage ;; esac
shift 2
SET_EPIC=""; SET_FROM=""; SET_INTO=""
while [ "$#" -gt 0 ]; do
  [ "$#" -ge 2 ] || usage
  case "$2" in '#'[0-9]*) ;; *) stop "$1 takes issue numbers written #n, not: $2" ;; esac
  case "$1" in --epic) SET_EPIC="$2" ;; --split-from) SET_FROM="$2" ;; --split-into) SET_INTO="$2" ;; *) usage ;; esac
  shift 2
done

SELF="${BASH_SOURCE[0]//\\//}"
case "$SELF" in */*) DIR="${SELF%/*}" ;; *) DIR="." ;; esac
[ -r "$DIR/ship-state.sh" ] || stop "Error: ship-state.sh could not be loaded."

STATE="$(bash "$DIR/ship-state.sh" "$ISSUE")" || { printf '%s\n' "$STATE" | tail -n 1; exit 1; }
field() { printf '%s\n' "$STATE" | sed -n "s/^$1: //p" | head -n 1 | tr -d '\r'; }
SLUG="$(field slug)"
[ "$(field block)" != "malformed" ] || stop "The References block in #$ISSUE is malformed (two blocks, or the end before the start). Fix the issue description by hand."
ISSUE_BRANCH_ON_GITHUB="$(field issue_branch)"
WORK="ship/$ISSUE-$SLUG"; ISSUE_BRANCH="$WORK/issue"

TMP="$(mktemp -d 2>/dev/null || mktemp -d -t cuevik)" || stop "Could not create a temporary folder."
trap 'rm -rf "$TMP"' EXIT
REPO_NAME="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null | tr -d '\r')"
[ -n "$REPO_NAME" ] || stop "Could not read the repository name from GitHub."
gh issue view "$ISSUE" --json body --jq '.body' > "$TMP/body.md" 2>/dev/null || stop "Could not read issue #$ISSUE from GitHub."

# ---- the block as it stands ---------------------------------------------------------------------
START='<!-- cuevik-ship:references -->'; END='<!-- /cuevik-ship:references -->'
awk -v s="$START" -v e="$END" '{ line = $0; sub(/\r$/, "", line) }
  line == s { f = 1; next } line == e { f = 0 } f && line != "" { print line }' "$TMP/body.md" > "$TMP/old.txt"
old_line() {  # the existing line that starts "- <label>:", or nothing
  awk -v p="- $1:" 'index($0, p) == 1 { print; exit }' "$TMP/old.txt"
}

# ---- the lines a branch or a PR can prove -------------------------------------------------------
step_pr() {  # the merged-or-open PR number of a step, or nothing
  printf '%s\n' "$STATE" | awk -F'|' -v s="$1" '$1 == s && ($4 == "merged" || $4 == "open") { print $5; exit }'
}
file_link() {  # file_link <label> <path under docs/ship/<n>-<slug>/> <step>: the line, or nothing
  local label="$1" path="docs/ship/$ISSUE-$SLUG/$2" step="$3" sha="" branch pr name
  [ "$SLUG" != "-" ] || return 0
  branch="$WORK/$step"
  if [ "$ISSUE_BRANCH_ON_GITHUB" = "yes" ] && git cat-file -e "origin/$ISSUE_BRANCH:$path" 2>/dev/null; then
    sha="$(git log -1 --format=%H "origin/$ISSUE_BRANCH" -- "$path" 2>/dev/null)"
  elif git cat-file -e "origin/$branch:$path" 2>/dev/null; then
    sha="$(git rev-parse "origin/$branch" 2>/dev/null)"
  fi
  [ -n "$sha" ] || return 0
  name="${2##*/}"; pr="$(step_pr "$step")"
  printf -- '- %s: [%s](https://github.com/%s/blob/%s/%s)' "$label" "$name" "$REPO_NAME" "$sha" "$path"
  [ -z "$pr" ] || printf ' · PR #%s' "$pr"
  printf '\n'
}
pr_line() {  # pr_line <label> <step>
  local pr; pr="$(step_pr "$2")"
  [ -z "$pr" ] || printf -- '- %s: #%s\n' "$1" "$pr"
}

: > "$TMP/new.txt"
emit() {  # emit <label> <derived line>: the derived line, else the existing one (a line is never removed)
  local line="$2"
  [ -n "$line" ] || line="$(old_line "$1")"
  [ -z "$line" ] || printf '%s\n' "$line" >> "$TMP/new.txt"
}
emit "Brainstorm" "$(file_link Brainstorm brainstorming/brainstorm.md 01-brainstorm)"
emit "Docs PR" "$(pr_line "Docs PR" 02-audit-prd)"
emit "Epic" "${SET_EPIC:+- Epic: $SET_EPIC}"
emit "Intent" "$(file_link Intent intent.md 04-plan-intent)"
emit "Spec" "$(file_link Spec spec.md 05-design-spec)"
emit "Plan" "$(file_link Plan plan.md 06-build-plan)"
emit "Code PR" "$(pr_line "Code PR" 07-execute-plan)"
emit "Split from" "${SET_FROM:+- Split from: $SET_FROM}"
emit "Split into" "${SET_INTO:+- Split into: $SET_INTO}"
# a line this script does not know stays, after the known ones, in its own order
awk '!/^- (Brainstorm|Docs PR|Epic|Intent|Spec|Plan|Code PR|Split from|Split into):/' "$TMP/old.txt" >> "$TMP/new.txt"

# ---- splice it in -------------------------------------------------------------------------------
EOL=""; grep -q $'\r' "$TMP/body.md" && EOL=$'\r'
if grep -Eq "^$START"$'\r''?$' "$TMP/body.md"; then
  awk -v s="$START" -v e="$END" -v blockfile="$TMP/new.txt" -v eol="$EOL" '
    { line = $0; sub(/\r$/, "", line) }
    line == s { print; while ((getline l < blockfile) > 0) print l eol; skip = 1; next }
    line == e { skip = 0; print; next }
    !skip { print }' "$TMP/body.md" > "$TMP/out.md"
  ACTION="updated"
else
  { cat "$TMP/body.md"
    [ ! -s "$TMP/body.md" ] || [ -z "$(tail -c 1 "$TMP/body.md")" ] || printf '\n'
    printf '\n## References\n\n%s\n' "$START"
    cat "$TMP/new.txt"
    printf '%s\n' "$END"; } > "$TMP/out.md"
  ACTION="created"
fi
if cmp -s "$TMP/body.md" "$TMP/out.md"; then ACTION="unchanged"; fi

printf '== references\naction: %s\n' "$ACTION"
cat "$TMP/new.txt"
if [ "$MODE" = "apply" ] && [ "$ACTION" != "unchanged" ]; then
  gh issue edit "$ISSUE" --body-file "$TMP/out.md" >/dev/null 2>"$TMP/edit.err" \
    || stop "Could not update #$ISSUE: $(head -n 1 "$TMP/edit.err")"
fi
exit 0
