#!/usr/bin/env bash
# cuevik-ship: where one issue stands, and whether a step may start on it.
#
# Usage:  bash ship-state.sh --preflight        only the common preconditions, for a step that runs
#                                                 before its issue exists (01 on a new idea, 04 on a
#                                                 free description); prints "preflight: ok"
#         bash ship-state.sh <issue> [<step>]
#           <issue>  41, #41 or the issue's URL
#           <step>   01-brainstorm 02-audit-prd 03-create-backlog 04-plan-intent 05-design-spec
#                    06-build-plan 07-execute-plan cleanup. With it the output also has the gate.
#
# Run it from the repo root or the issue's worktree root. It changes nothing but remote-tracking
# refs (it fetches origin). Needs git and gh (signed in). The rules are references/gate.md's.
#
# Output, in "== <name>" sections:
#   == issue      number, title, state, state_reason, url, labels (comma-separated)
#   == branches   slug (or -), slug_source (remote, local, worktree or none), issue_branch (yes or no,
#                 on GitHub), worktree (its path or -), here (yes when this folder is that worktree),
#                 main_checkout (yes when this folder is the main checkout, not a worktree)
#   == steps      one line per step with a branch: step|branch|base|state|pr|merged|title
#                   state  merged, open, closed, branch (a branch and no PR) or none
#   == artifacts  one line per work file on the issue branch: file|status|unticked
#                   status is the header's Status (Draft, Approved, Rejected) or - when missing;
#                   unticked counts the unticked boxes of spec.md section 8 (- for the others)
#   == references block (ok, missing or malformed), epic (#, or -), docs_pr (#, or -)
#   == gate       Only with <step>: result (pass or stop), done (yes or no), the step's own branch
#                 and where it exists (none, local, remote or both), and the message on a stop.
#
# Exit: 0 the state was written. 1 a precondition or a GitHub query failed: the one line printed is
# the message for the operator. 2 wrong usage. Bash 3.2 and Git Bash safe.

stop() { printf '%s\n' "$1"; exit 1; }
usage() { printf 'usage: ship-state.sh --preflight | ship-state.sh <issue> [<step>]   (a step is 01-brainstorm .. 07-execute-plan or cleanup)\n' >&2; exit 2; }

PREFLIGHT=""
if [ "${1:-}" = "--preflight" ]; then
  [ "$#" -eq 1 ] || usage
  PREFLIGHT="yes"; ISSUE=""; STEP="preflight"
else
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage
  ISSUE="${1##*/}"; ISSUE="${ISSUE#\#}"
  case "$ISSUE" in '' | *[!0-9]*) stop "The issue must be a number, #number or the issue's URL, not: $1" ;; esac
  STEP="${2:-}"
  case "$STEP" in
    '' | 01-brainstorm | 02-audit-prd | 03-create-backlog | 04-plan-intent | 05-design-spec | 06-build-plan | 07-execute-plan | cleanup) ;;
    *) usage ;;
  esac
fi

# ---- common preconditions (gate.md) -------------------------------------------------------------
PREFIX="$(git rev-parse --show-prefix 2>/dev/null)" || stop "This folder is not a git repo."
[ -z "$PREFIX" ] || stop "Run cuevik-ship from the repo or worktree root."
gh auth status >/dev/null 2>&1 || stop "gh is not signed in. Run gh auth login, then re-run."
git fetch --prune origin >/dev/null 2>&1 || stop "Could not fetch origin. cuevik-ship needs GitHub's current state."
git cat-file -e origin/main:.cuevik/config.json 2>/dev/null && git cat-file -e origin/main:.cuevik/lineage.json 2>/dev/null \
  || stop "This repo is not set up for cuevik. Run /cuevik-start:00-bootstrap first."
if [ "$STEP" != "cleanup" ] && [ -n "$STEP" ] && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  stop "Uncommitted changes detected — commit or stash before continuing."
fi
if [ -n "$PREFLIGHT" ]; then printf 'preflight: ok\n'; exit 0; fi

TMP="$(mktemp -d 2>/dev/null || mktemp -d -t cuevik)" || stop "Could not create a temporary folder."
trap 'rm -rf "$TMP"' EXIT

# ---- the issue ----------------------------------------------------------------------------------
HEADLINE="$(gh issue view "$ISSUE" --json number,title,state,stateReason,url \
  --jq '[(.number | tostring), .title, .state, (.stateReason // "-"), .url] | join("\u001f")' 2>/dev/null)" \
  || stop "Issue #$ISSUE was not found (gh issue view failed)."
IFS=$'\037' read -r I_NUMBER I_TITLE I_STATE I_REASON I_URL <<EOF
${HEADLINE%$'\r'}
EOF
I_STATE="$(printf '%s' "$I_STATE" | tr 'A-Z' 'a-z')"
I_LABELS="$(gh issue view "$ISSUE" --json labels --jq '[.labels[].name] | join(",")' 2>/dev/null | tr -d '\r')"
gh issue view "$ISSUE" --json body --jq '.body' 2>/dev/null | tr -d '\r' > "$TMP/body.md" \
  || stop "Could not read issue #$ISSUE from GitHub."
has_label() { case ",$I_LABELS," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

# ---- the slug and the worktree (branches.md) ----------------------------------------------------
SLUGS=""
while read -r _ ref; do
  name="${ref#refs/heads/ship/$ISSUE-}"; [ "$name" != "$ref" ] || continue
  slug="${name%%/*}"
  case " $SLUGS " in *" $slug "*) ;; *) SLUGS="$SLUGS $slug" ;; esac
done <<EOF
$(git ls-remote --heads origin "refs/heads/ship/$ISSUE-*" 2>/dev/null)
EOF
SLUG_SOURCE="remote"
if [ -z "$SLUGS" ]; then   # the remote branches are gone (after cleanup): local branches, then worktrees
  while read -r ref; do
    name="${ref#ship/$ISSUE-}"; [ "$name" != "$ref" ] || continue
    slug="${name%%/*}"; case " $SLUGS " in *" $slug "*) ;; *) SLUGS="$SLUGS $slug" ;; esac
    SLUG_SOURCE="local"
  done <<EOF
$(git for-each-ref --format='%(refname:short)' "refs/heads/ship/$ISSUE-*/*")
EOF
fi
set -- $SLUGS
[ "$#" -le 1 ] || stop "More than one slug for #$ISSUE: $SLUGS. Resolve it by hand."
SLUG="${1:--}"
[ "$SLUG" != "-" ] || SLUG_SOURCE="none"
WORK="ship/$ISSUE-$SLUG"

WORKTREE="-"; wt=""; wt_branch=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "worktree "*) wt="${line#worktree }" ;;
    "branch refs/heads/ship/$ISSUE-$SLUG/"*) WORKTREE="$wt" ;;
  esac
done <<EOF
$(git worktree list --porcelain 2>/dev/null)
EOF
[ "$SLUG" != "-" ] || WORKTREE="-"
if [ "$SLUG_SOURCE" = "none" ] && [ "$WORKTREE" != "-" ]; then SLUG_SOURCE="worktree"; fi
TOP="$(git rev-parse --show-toplevel 2>/dev/null)"
HERE="no"; [ "$WORKTREE" != "-" ] && [ "${TOP%/}" = "${WORKTREE%/}" ] && HERE="yes"
[ "$WORKTREE" != "-" ] || HERE="-"
abs_dir() { (cd "$1" 2>/dev/null && pwd -P); }   # not git's --path-format: that needs Git 2.31
GIT_DIR_ABS="$(abs_dir "$(git rev-parse --git-dir 2>/dev/null)")"
COMMON_ABS="$(abs_dir "$(git rev-parse --git-common-dir 2>/dev/null)")"
MAIN_CHECKOUT="no"; [ -n "$GIT_DIR_ABS" ] && [ "$GIT_DIR_ABS" = "$COMMON_ABS" ] && MAIN_CHECKOUT="yes"

ISSUE_BRANCH="$WORK/issue"
ISSUE_BRANCH_ON_GITHUB="no"
[ "$SLUG" != "-" ] && git ls-remote --exit-code --heads origin "refs/heads/$ISSUE_BRANCH" >/dev/null 2>&1 && ISSUE_BRANCH_ON_GITHUB="yes"

# ---- one PR query per step branch, in parallel --------------------------------------------------
# step|branch|base: 02 and 07 are cut from main, the others from the issue branch (branches.md).
STEPS_TABLE="01-brainstorm|$WORK/01-brainstorm|$ISSUE_BRANCH
02-audit-prd|$WORK/02-audit-prd|main
04-plan-intent|$WORK/04-plan-intent|$ISSUE_BRANCH
05-design-spec|$WORK/05-design-spec|$ISSUE_BRANCH
06-build-plan|$WORK/06-build-plan|$ISSUE_BRANCH
07-execute-plan|$WORK/07-execute-plan|main"

N=0
if [ "$SLUG" != "-" ]; then
  while IFS='|' read -r id branch base; do
    S_ID[$N]="$id"; S_BRANCH[$N]="$branch"; S_BASE[$N]="$base"
    ( gh pr list --head "$branch" --base "$base" --state all --limit 30 --json number,state,title,mergedAt,createdAt \
        --jq '.[] | [.state, (.number | tostring), (.mergedAt // .createdAt), .title] | @tsv' \
        > "$TMP/pr$N.out" 2> "$TMP/pr$N.err" || : > "$TMP/pr$N.failed" ) &
    N=$((N + 1))
  done <<EOF
$STEPS_TABLE
EOF
  wait
fi
i=0
while [ "$i" -lt "$N" ]; do
  if [ -e "$TMP/pr$i.failed" ]; then
    stop "Could not read pull requests for ${S_BRANCH[$i]} from GitHub: $(head -n 1 "$TMP/pr$i.err" 2>/dev/null)"
  fi
  i=$((i + 1))
done

branch_where() {  # none, local, remote or both
  local l="" r=""
  git show-ref --verify --quiet "refs/heads/$1" && l="yes"
  git show-ref --verify --quiet "refs/remotes/origin/$1" && r="yes"
  if [ -n "$l" ] && [ -n "$r" ]; then echo both; elif [ -n "$l" ]; then echo local; elif [ -n "$r" ]; then echo remote; else echo none; fi
}

i=0
while [ "$i" -lt "$N" ]; do
  best=0; best_date=""; st="none"; num="-"; at="-"; ttl="-"
  while IFS=$'\t' read -r state number date title || [ -n "$state" ]; do
    state="${state%$'\r'}"; title="${title%$'\r'}"
    case "$state" in MERGED) rank=3 ;; OPEN) rank=2 ;; CLOSED) rank=1 ;; *) continue ;; esac
    if [ "$rank" -gt "$best" ] || { [ "$rank" -eq "$best" ] && [[ "$date" > "$best_date" ]]; }; then
      best=$rank; best_date="$date"; num="$number"; ttl="$title"
      case "$state" in MERGED) st="merged"; at="${date%%T*}" ;; OPEN) st="open"; at="-" ;; *) st="closed"; at="-" ;; esac
    fi
  done < "$TMP/pr$i.out"
  if [ "$st" = "none" ] || [ "$st" = "closed" ]; then
    [ "$(branch_where "${S_BRANCH[$i]}")" = "none" ] || { [ "$st" = "closed" ] || st="branch"; }
  fi
  S_STATE[$i]="$st"; S_PR[$i]="$num"; S_MERGED[$i]="$at"; S_TITLE[$i]="$ttl"
  i=$((i + 1))
done
step_index() { local k=0; while [ "$k" -lt "$N" ]; do [ "${S_ID[$k]}" = "$1" ] && { echo "$k"; return; }; k=$((k + 1)); done; echo -1; }

# ---- the work files on the issue branch ---------------------------------------------------------
FILES="brainstorm.md|brainstorming/brainstorm.md
intent.md|intent.md
spec.md|spec.md
plan.md|plan.md"
A_NAMES=""
while IFS='|' read -r name path; do
  status="-"; unticked="-"
  if [ "$ISSUE_BRANCH_ON_GITHUB" = "yes" ]; then
    if git show "origin/$ISSUE_BRANCH:docs/ship/$ISSUE-$SLUG/$path" > "$TMP/$name" 2>/dev/null; then
      status="$(sed -n 's/^\*\*Status:\*\* *\([A-Za-z]*\).*$/\1/p' "$TMP/$name" | head -n 1 | tr -d '\r')"
      [ -n "$status" ] || status="-"
      if [ "$name" = "spec.md" ]; then
        unticked="$(awk '/^## 8\./ {f = 1; next} /^## / {f = 0} f && /^- \[ \]/ {n++} END {print n + 0}' "$TMP/$name")"
      fi
    fi
  fi
  A_STATUS_NAME="${name%.md}"
  eval "A_${A_STATUS_NAME}_STATUS=\"\$status\"; A_${A_STATUS_NAME}_UNTICKED=\"\$unticked\""
  A_NAMES="$A_NAMES $name"
done <<EOF
$FILES
EOF

# ---- the References block (references-block.md) -------------------------------------------------
STARTS="$(grep -c '^<!-- cuevik-ship:references -->' "$TMP/body.md")"
ENDS="$(grep -c '^<!-- /cuevik-ship:references -->' "$TMP/body.md")"
REFERENCES="ok"
if [ "$STARTS" -eq 0 ] && [ "$ENDS" -eq 0 ]; then
  REFERENCES="missing"
elif [ "$STARTS" -ne 1 ] || [ "$ENDS" -ne 1 ] \
  || [ "$(grep -n '^<!-- cuevik-ship:references -->' "$TMP/body.md" | cut -d: -f1)" -gt "$(grep -n '^<!-- /cuevik-ship:references -->' "$TMP/body.md" | cut -d: -f1)" ]; then
  REFERENCES="malformed"
fi
ref_number() {  # the issue or PR number on a "- <label>: #<n>" line of the block, or -
  [ "$REFERENCES" = "ok" ] || { echo "-"; return; }
  awk -v label="$1" '/^<!-- cuevik-ship:references -->/ {f = 1; next} /^<!-- \/cuevik-ship:references -->/ {f = 0}
    f && index($0, "- " label ":") == 1 { if (match($0, /#[0-9]+/)) { print substr($0, RSTART + 1, RLENGTH - 1); exit } }' "$TMP/body.md" | head -n 1
}
EPIC="$(ref_number Epic)"; [ -n "$EPIC" ] || EPIC="-"
DOCS_PR="$(ref_number "Docs PR")"; [ -n "$DOCS_PR" ] || DOCS_PR="-"
BACKLOG_MODEL="$(git show origin/main:.cuevik/config.json 2>/dev/null | grep -o '"backlogModel"[[:space:]]*:[[:space:]]*"[a-z-]*"' | head -n 1 | sed 's/.*"\([a-z-]*\)"$/\1/')"

# ---- the state ----------------------------------------------------------------------------------
printf '== issue\n'
printf 'number: %s\ntitle: %s\nstate: %s\nstate_reason: %s\nurl: %s\nlabels: %s\n' "$I_NUMBER" "$I_TITLE" "$I_STATE" "$I_REASON" "$I_URL" "$I_LABELS"
printf '\n== branches\n'
printf 'slug: %s\nslug_source: %s\nissue_branch: %s\nworktree: %s\nhere: %s\nmain_checkout: %s\n' \
  "$SLUG" "$SLUG_SOURCE" "$ISSUE_BRANCH_ON_GITHUB" "$WORKTREE" "$HERE" "$MAIN_CHECKOUT"
printf '\n== steps\n'
i=0
while [ "$i" -lt "$N" ]; do
  printf '%s|%s|%s|%s|%s|%s|%s\n' "${S_ID[$i]}" "${S_BRANCH[$i]}" "${S_BASE[$i]}" "${S_STATE[$i]}" "${S_PR[$i]}" "${S_MERGED[$i]}" "${S_TITLE[$i]}"
  i=$((i + 1))
done
printf '\n== artifacts\n'
printf 'brainstorm.md|%s|-\nintent.md|%s|-\nspec.md|%s|%s\nplan.md|%s|-\n' \
  "$A_brainstorm_STATUS" "$A_intent_STATUS" "$A_spec_STATUS" "$A_spec_UNTICKED" "$A_plan_STATUS"
printf '\n== references\n'
printf 'block: %s\nepic: %s\ndocs_pr: %s\nbacklog_model: %s\n' "$REFERENCES" "$EPIC" "$DOCS_PR" "${BACKLOG_MODEL:--}"

[ -n "$STEP" ] || exit 0

# ---- the gate (gate.md) -------------------------------------------------------------------------
RESULT="pass"; DONE="no"; MESSAGE="-"
fail_gate() { if [ "$RESULT" = "pass" ]; then RESULT="stop"; MESSAGE="$1"; fi; }
state_of() { local k; k="$(step_index "$1")"; [ "$k" -ge 0 ] && echo "${S_STATE[$k]}" || echo none; }
pr_of() { local k; k="$(step_index "$1")"; [ "$k" -ge 0 ] && echo "${S_PR[$k]}" || echo -; }
next_of() { case "$1" in 01-brainstorm) echo 02-audit-prd ;; 02-audit-prd) echo 03-create-backlog ;; 03-create-backlog) echo 04-plan-intent ;;
  04-plan-intent) echo 05-design-spec ;; 05-design-spec) echo 06-build-plan ;; 06-build-plan) echo 07-execute-plan ;; 07-execute-plan) echo cleanup ;; esac; }
status_of() { eval "echo \"\$A_${1%.md}_STATUS\""; }

# need_previous <step> <artifact-or-"">: the previous step's PR is merged, and its artifact reads Approved.
need_previous() {
  local prev="$1" file="$2" st pr status
  st="$(state_of "$prev")"; pr="$(pr_of "$prev")"
  case "$st" in
    merged) ;;
    open) fail_gate "$prev's PR #$pr is still open: merge it into ${S_BASE[$(step_index "$prev")]} first. An open PR does not count."; return ;;
    *) fail_gate "$prev has no merged PR: run /cuevik-ship:$prev $ISSUE first."; return ;;
  esac
  [ -n "$file" ] || return
  status="$(status_of "$file")"
  case "$status" in
    Approved) ;;
    Rejected) fail_gate "$file reads Rejected: the idea has been decided." ;;
    -) fail_gate "$file is missing on $ISSUE_BRANCH: run /cuevik-ship:$prev $ISSUE." ;;
    *) fail_gate "$file reads $status, not Approved: finish it with /cuevik-ship:$prev $ISSUE." ;;
  esac
}

if [ "$REFERENCES" = "malformed" ]; then fail_gate "The References block in #$ISSUE is malformed (two blocks, or the end before the start). Fix the issue description by hand."; fi

if [ "$STEP" = "cleanup" ]; then
  [ "$MAIN_CHECKOUT" = "yes" ] || fail_gate "Run cleanup from the main checkout, not from a worktree."
  [ "$SLUG" != "-" ] || fail_gate "Nothing to clean for #$ISSUE: no ship/$ISSUE-* branch or worktree anywhere."
  if [ "$RESULT" = "pass" ]; then
    k="$(step_index 07-execute-plan)"
    if [ "${S_STATE[$k]}" != "merged" ] && ! { [ "$I_STATE" = "closed" ] && [ "$I_REASON" = "NOT_PLANNED" ]; }; then
      fail_gate "The code PR is not merged and #$ISSUE was not closed as not planned. There is no override."
    fi
  fi
  if [ "$RESULT" = "pass" ]; then
    open="$(gh pr list --state open --limit 100 --json number,headRefName \
      --jq ".[] | select(.headRefName | startswith(\"ship/$ISSUE-\")) | \"#\\(.number) \\(.headRefName)\"" 2>/dev/null | tr -d '\r' | tr '\n' ' ')" \
      || stop "Could not list open pull requests from GitHub."
    open="${open% }"
    [ -z "$open" ] || fail_gate "Open PRs from ship/$ISSUE-* branches: $open. Merge or close them first."
  fi
  printf '\n== gate\nstep: cleanup\nresult: %s\ndone: no\nstep_branch: -\nstep_branch_state: -\nmessage: %s\n' "$RESULT" "$MESSAGE"
  exit 0
fi

STEP_BRANCH="-"; STEP_WHERE="-"
k="$(step_index "$STEP")"
if [ "$k" -ge 0 ]; then
  STEP_BRANCH="${S_BRANCH[$k]}"; STEP_WHERE="$(branch_where "$STEP_BRANCH")"
  case "${S_STATE[$k]}" in
    merged) DONE="yes"; fail_gate "$STEP is already done for #$ISSUE (PR #${S_PR[$k]} merged). Next is $(next_of "$STEP")." ;;
    open) fail_gate "$STEP already has an open PR #${S_PR[$k]}: merge or close it first." ;;
  esac
fi
# A step whose artifact already reads Approved on the issue branch is done too.
case "$STEP" in
  01-brainstorm) art="$A_brainstorm_STATUS" ;; 04-plan-intent) art="$A_intent_STATUS" ;;
  05-design-spec) art="$A_spec_STATUS" ;; 06-build-plan) art="$A_plan_STATUS" ;; *) art="" ;;
esac
if [ "$art" = "Approved" ] && [ "$DONE" = "no" ]; then DONE="yes"; fail_gate "$STEP is already done for #$ISSUE: its work file reads Approved. Next is $(next_of "$STEP")."; fi

if [ "$RESULT" = "pass" ] && [ "$STEP" != "03-create-backlog" ] && [ "$WORKTREE" != "-" ] && [ "$HERE" != "yes" ]; then
  fail_gate "#$ISSUE has a worktree: open a session in $WORKTREE and run /cuevik-ship:$STEP $ISSUE there."
fi
if [ "$RESULT" = "pass" ]; then
  case "$STEP" in
    01-brainstorm) ;;
    02-audit-prd) need_previous 01-brainstorm brainstorm.md ;;
    03-create-backlog)
      pr="$DOCS_PR"; [ "$pr" != "-" ] || pr="$(pr_of 02-audit-prd)"
      if [ "$pr" = "-" ]; then
        fail_gate "02-audit-prd has no merged PR: run /cuevik-ship:02-audit-prd $ISSUE first."
      else
        info="$(gh pr view "$pr" --json state,baseRefName --jq '.state + " " + .baseRefName' 2>/dev/null | tr -d '\r')"
        case "$info" in
          "MERGED main")
            gh pr view "$pr" --json body --jq '.body' 2>/dev/null | grep -q '<!-- cuevik-ship:ratified -->' \
              || fail_gate "PR #$pr (02-audit-prd) has no ratified block in its body: re-run /cuevik-ship:02-audit-prd $ISSUE." ;;
          "OPEN "*) fail_gate "02-audit-prd's PR #$pr is still open: merge it into main first. An open PR does not count." ;;
          "") fail_gate "02-audit-prd has no merged PR: PR #$pr was not found. Run /cuevik-ship:02-audit-prd $ISSUE." ;;
          *) fail_gate "02-audit-prd's PR #$pr is not merged into main ($info): run /cuevik-ship:02-audit-prd $ISSUE." ;;
        esac
      fi ;;
    04-plan-intent)
      if [ "$I_STATE" = "closed" ]; then fail_gate "#$ISSUE is closed."
      elif has_label epic; then fail_gate "#$ISSUE is an epic: plan one of its stories."
      elif [ "$ISSUE_BRANCH_ON_GITHUB" = "yes" ]; then
        # after 03: the issue is a story
        if has_label idea; then fail_gate "#$ISSUE is still an idea: it has not been through 02 and 03."
        elif [ "$BACKLOG_MODEL" = "flat" ]; then has_label story || fail_gate "#$ISSUE has no story label: it has not been through 03."
        else [ "$EPIC" != "-" ] || fail_gate "The References block of #$ISSUE has no Epic: line: it has not been through 03."; fi
      else
        has_label idea && fail_gate "#$ISSUE is still an idea: it has not been through 02 and 03."
      fi ;;
    05-design-spec) need_previous 04-plan-intent intent.md ;;
    06-build-plan) need_previous 05-design-spec spec.md ;;
    07-execute-plan) need_previous 06-build-plan plan.md ;;
  esac
fi

printf '\n== gate\nstep: %s\nresult: %s\ndone: %s\nstep_branch: %s\nstep_branch_state: %s\nspec_unticked: %s\nmessage: %s\n' \
  "$STEP" "$RESULT" "$DONE" "$STEP_BRANCH" "$STEP_WHERE" "${A_spec_UNTICKED}" "$MESSAGE"
exit 0
