#!/usr/bin/env bash
# cuevik-start: where project initiation stands, read from git and GitHub.
#
# Usage:  bash init-state.sh              the status report
#         bash init-state.sh <step id>    the report, plus whether that step may start (its gate)
#
# Run it from the project repo's root. It changes nothing: it fetches origin (remote-tracking refs
# only) and reads. Needs git and gh (signed in). The steps come from steps.table beside this file,
# which is generated from steps.yml and express.yml.
#
# Output, in "== <name>" sections:
#   == report   Markdown: heading, progress line, table, Check lines. Print it as it is.
#   == next     The **Next:** line. Print it last, after any line the caller adds.
#   == steps    One line per step: id|slug|state|pr|merged|branch|via
#                 state   merged, mismatch, open, branch or none (the row's status)
#                 pr      the PR's number, or -          merged  YYYY-MM-DD, or -
#                 branch  the branch that PR is on, or - via     own, express or -
#   == gate     Only with <step id>: result (pass or stop), the previous step's PR, and the message
#               for the operator on a stop.
#
# Exit: 0 the report was written. 1 a preflight check or a GitHub query failed: the one line printed
# is the message for the operator. 2 wrong usage.
#
# Kept to what bash 3.2 (macOS) and Git Bash (Windows) both run: no associative arrays, no mapfile.

stop() { printf '%s\n' "$1"; exit 1; }

# ---- the step table ---------------------------------------------------------------------------
SELF="${BASH_SOURCE[0]//\\//}"                      # a Windows path arrives with backslashes
case "$SELF" in */*) DIR="${SELF%/*}" ;; *) DIR="." ;; esac
[ -r "$DIR/steps.table" ] || stop "Error: steps.table could not be loaded."

N=0
EXPRESS_BRANCH=""
EXPRESS_COVERS=" "
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  case "$line" in '' | '#'*) continue ;; esac
  IFS='|' read -r kind f1 f2 f3 f4 f5 f6 <<EOF
$line
EOF
  case "$kind" in
    express) EXPRESS_BRANCH="$f1"; EXPRESS_COVERS=" $f2 " ;;
    step)
      ID[$N]="$f1"; SLUG[$N]="$f2"; BRANCH[$N]="$f3"; OUTPUT[$N]="$f5"; CHECK[$N]="$f6"
      if [ "$f4" = "-" ]; then ALIASES[$N]=""; else ALIASES[$N]="$f4"; fi
      N=$((N + 1)) ;;
  esac
done < "$DIR/steps.table"
[ "$N" -gt 0 ] || stop "Error: steps.table could not be loaded."

GATE_STEP="${1:-}"
GATE_INDEX=-1
if [ -n "$GATE_STEP" ]; then
  i=0
  while [ "$i" -lt "$N" ]; do
    if [ "${ID[$i]}" = "$GATE_STEP" ]; then GATE_INDEX=$i; fi
    i=$((i + 1))
  done
  if [ "$GATE_INDEX" -lt 0 ] || [ "$#" -gt 1 ]; then
    printf 'usage: init-state.sh [<step id>]   (%s is not a step id)\n' "$GATE_STEP" >&2
    exit 2
  fi
fi

# ---- preflight --------------------------------------------------------------------------------
PREFIX="$(git rev-parse --show-prefix 2>/dev/null)" \
  || stop "This folder is not a git repo. Run /cuevik-start:00-bootstrap first."
[ -z "$PREFIX" ] || stop "Run status from the repo root."
ORIGIN="$(git config --get remote.origin.url 2>/dev/null)"
case "$ORIGIN" in
  *github.com[:/]*) ;;
  *) stop "No GitHub origin. Run /cuevik-start:00-bootstrap first." ;;
esac
gh auth status >/dev/null 2>&1 || stop "gh is not signed in. Run gh auth login, then re-run."
git fetch --prune origin >/dev/null 2>&1 || stop "Could not fetch origin. Status needs GitHub's current state."
SHA="$(git rev-parse --verify -q origin/main 2>/dev/null)" \
  || stop "origin has no main branch. Run /cuevik-start:00-bootstrap first."

# ---- one PR query per branch, a few at a time ---------------------------------------------------
TMP="$(mktemp -d 2>/dev/null || mktemp -d -t cuevik)" || stop "Could not create a temporary folder."
trap 'rm -rf "$TMP"' EXIT

Q=0
add_query() { QBRANCH[$Q]="$1"; Q=$((Q + 1)); }
i=0
while [ "$i" -lt "$N" ]; do
  add_query "${BRANCH[$i]}"
  for b in ${ALIASES[$i]}; do add_query "$b"; done
  i=$((i + 1))
done
[ -z "$EXPRESS_BRANCH" ] || add_query "$EXPRESS_BRANCH"

q=0
while [ "$q" -lt "$Q" ]; do
  (
    gh pr list --head "${QBRANCH[$q]}" --base main --state all --limit 30 \
      --json number,state,title,mergedAt,createdAt \
      --jq '.[] | [.state, (.number | tostring), (.mergedAt // .createdAt), .title] | @tsv' \
      > "$TMP/$q.out" 2> "$TMP/$q.err" || : > "$TMP/$q.failed"
  ) &
  q=$((q + 1))
  if [ $((q % 6)) -eq 0 ]; then wait; fi
done
wait
q=0
while [ "$q" -lt "$Q" ]; do
  if [ -e "$TMP/$q.failed" ]; then
    stop "Could not read pull requests for ${QBRANCH[$q]} from GitHub: $(head -n 1 "$TMP/$q.err" 2>/dev/null)"
  fi
  q=$((q + 1))
done

# pick <branch>...: the PR that stands for those branches. The newest merged one, else the newest
# open one, else the newest closed one. Sets P_STATE (MERGED, OPEN, CLOSED or NONE), P_NUM, P_DATE,
# P_TITLE and P_BRANCH.
pick() {
  local b q state num date title rank best_rank=0 best_date=""
  P_STATE="NONE"; P_NUM=""; P_DATE=""; P_TITLE=""; P_BRANCH=""
  for b in "$@"; do
    q=0
    while [ "$q" -lt "$Q" ]; do
      if [ "${QBRANCH[$q]}" = "$b" ]; then
        while IFS=$'\t' read -r state num date title || [ -n "$state" ]; do
          state="${state%$'\r'}"; title="${title%$'\r'}"
          case "$state" in MERGED) rank=3 ;; OPEN) rank=2 ;; CLOSED) rank=1 ;; *) continue ;; esac
          if [ "$rank" -gt "$best_rank" ] || { [ "$rank" -eq "$best_rank" ] && [[ "$date" > "$best_date" ]]; }; then
            best_rank=$rank; best_date="$date"
            P_STATE="$state"; P_NUM="$num"; P_DATE="$date"; P_TITLE="$title"; P_BRANCH="$b"
          fi
        done < "$TMP/$q.out"
      fi
      q=$((q + 1))
    done
  done
}

on_main() { git cat-file -e "$SHA:$1" 2>/dev/null; }
has_branch() { git show-ref --verify --quiet "refs/$1/$2"; }

E_STATE="NONE"; E_NUM=""; E_DATE=""; E_TITLE=""
if [ -n "$EXPRESS_BRANCH" ]; then
  pick "$EXPRESS_BRANCH"
  E_STATE="$P_STATE"; E_NUM="$P_NUM"; E_DATE="$P_DATE"; E_TITLE="$P_TITLE"
fi

# ---- one row per step ---------------------------------------------------------------------------
MERGED_ROWS=0
FIRST_OPEN=-1          # the first row that is not merged decides the Next line
FIRST_UNCOVERED=-1     # the first step the Express lane does not cover
CHECKS=""
i=0
while [ "$i" -lt "$N" ]; do
  # shellcheck disable=SC2086  # the alias list is split on purpose
  pick "${BRANCH[$i]}" ${ALIASES[$i]}
  via="own"
  covered=""
  case "$EXPRESS_COVERS" in *" ${ID[$i]} "*) covered="yes" ;; esac
  if [ -z "$covered" ] && [ "$FIRST_UNCOVERED" -lt 0 ]; then FIRST_UNCOVERED=$i; fi
  # The lane's one PR stands for a step it covers, unless the step has a better PR of its own.
  if [ -n "$covered" ]; then
    if { [ "$E_STATE" = "MERGED" ] && [ "$P_STATE" != "MERGED" ]; } \
      || { [ "$E_STATE" = "OPEN" ] && [ "$P_STATE" != "MERGED" ] && [ "$P_STATE" != "OPEN" ]; }; then
      P_STATE="$E_STATE"; P_NUM="$E_NUM"; P_DATE="$E_DATE"; P_TITLE="$E_TITLE"; P_BRANCH="$EXPRESS_BRANCH"
      via="express"
    fi
  fi
  PR_STATE[$i]="$P_STATE"; PR_NUM[$i]="$P_NUM"; PR_BRANCH[$i]="$P_BRANCH"; VIA[$i]="$via"
  PR_DAY[$i]=""
  if [ "$P_STATE" = "MERGED" ]; then PR_DAY[$i]="${P_DATE%%T*}"; fi
  label="PR #$P_NUM"
  if [ "$via" = "express" ]; then label="express PR #$P_NUM"; fi

  # the file check on main: pass, fail or none
  fc="none"; what=""
  case "${CHECK[$i]}" in
    bootstrap)
      fc="pass"
      for f in .cuevik/config.json .cuevik/lineage.json; do
        if ! on_main "$f"; then fc="fail"; what="$f is missing"; fi
      done ;;
    finalize)
      if ! on_main "${OUTPUT[$i]}"; then
        fc="fail"; what="${OUTPUT[$i]} is missing"
      elif git show "$SHA:${OUTPUT[$i]}" 2>/dev/null | grep -q "INITIATION-ONLY"; then
        fc="fail"; what="${OUTPUT[$i]} still has its INITIATION-ONLY block"
      else
        fc="pass"
      fi ;;
    file)
      if on_main "${OUTPUT[$i]}"; then fc="pass"; else fc="fail"; what="${OUTPUT[$i]} is missing"; fi ;;
  esac

  # which of the step's branches still exist
  loc=""; rem=""
  for b in "${BRANCH[$i]}" ${ALIASES[$i]}; do
    if has_branch heads "$b"; then loc="yes"; fi
    if has_branch remotes/origin "$b"; then rem="yes"; fi
  done

  if [ "$P_STATE" = "MERGED" ] && [ "$fc" != "fail" ]; then
    state="merged"; cell="✓ merged"; detail="$label"
    if [ -n "$loc" ]; then detail="$detail; local branch left — /cuevik-start:cleanup"; fi
    if [ -n "$rem" ]; then detail="$detail; branch left on GitHub"; fi
  elif [ "$P_STATE" = "MERGED" ]; then
    state="mismatch"; cell="⚠ mismatch"; detail="$label merged, but $what on origin/main"
  elif [ "$fc" = "pass" ]; then
    state="mismatch"; cell="⚠ mismatch"
    detail="${OUTPUT[$i]} on origin/main without a merged ${BRANCH[$i]} PR; the next step's gate needs this step's PR open or merged"
  elif [ "$P_STATE" = "OPEN" ]; then
    state="open"; cell="⟳ PR open"; detail="$label — \"$P_TITLE\""
  elif [ -n "$loc$rem" ]; then
    state="branch"; cell="⊙ branch"
    if [ -n "$loc" ] && [ -n "$rem" ]; then detail="local + GitHub"
    elif [ -n "$loc" ]; then detail="local"
    else detail="GitHub"; fi
    if [ "$P_STATE" = "CLOSED" ]; then detail="$detail, closed PR #$P_NUM"; fi
  else
    state="none"; cell="— not started"; detail=""
  fi
  STATE[$i]="$state"

  out="${OUTPUT[$i]}"
  if [ "${CHECK[$i]}" = "bootstrap" ]; then out="$out, .cuevik/"; fi
  ROW[$i]="| ${ID[$i]} | $out | $cell | ${detail//|/\\|} |"

  if [ "$state" = "merged" ]; then
    MERGED_ROWS=$((MERGED_ROWS + 1))
    # A merged step after one that is not merged ran out of order. The lane's own PR is exempt:
    # it covers later steps by design.
    if [ "$FIRST_OPEN" -ge 0 ] && [ "$via" != "express" ]; then
      CHECKS="$CHECKS**Check:** ${ID[$i]} is merged, but ${ID[$FIRST_OPEN]} before it is not: the steps ran out of order."$'\n'
    fi
  else
    if [ "$FIRST_OPEN" -lt 0 ]; then FIRST_OPEN=$i; fi
    if [ "$state" = "mismatch" ]; then CHECKS="$CHECKS**Check:** ${ID[$i]}: $detail."$'\n'; fi
  fi
  i=$((i + 1))
done

# ---- == report ----------------------------------------------------------------------------------
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)"
[ -n "$REPO" ] || REPO="$ORIGIN"
BAR=""
i=0
while [ "$i" -lt "$N" ]; do
  if [ "${STATE[$i]}" = "merged" ]; then BAR="$BAR█"; else BAR="$BAR░"; fi
  i=$((i + 1))
done
if [ "$FIRST_OPEN" -lt 0 ]; then TAIL="complete"; else TAIL="next: ${ID[$FIRST_OPEN]}"; fi

printf '== report\n'
printf '## Initiation status — %s (origin/main @ %s)\n\n' "$REPO" "$(git rev-parse --short "$SHA")"
printf '`%s %s/%s · %s`\n\n' "$BAR" "$MERGED_ROWS" "$N" "$TAIL"
printf '| Step | Output | Status | Detail |\n| --- | --- | --- | --- |\n'
i=0
while [ "$i" -lt "$N" ]; do
  printf '%s\n' "${ROW[$i]}"
  i=$((i + 1))
done
if [ -n "$CHECKS" ]; then printf '\n%s' "$CHECKS"; fi

# ---- == next ------------------------------------------------------------------------------------
printf '\n== next\n'
if [ "$FIRST_OPEN" -lt 0 ]; then
  NEXT="Initiation complete. Run /cuevik-start:cleanup to delete merged local init/* branches. Revise a document with /cuevik-docs:update <document>."
else
  f=$FIRST_OPEN
  id="${ID[$f]}"
  case "${STATE[$f]}" in
    mismatch) NEXT="blocked — $id does not add up (see Check)." ;;
    open)
      if [ "${VIA[$f]}" = "express" ]; then
        NEXT="merge express PR #${PR_NUM[$f]}; the lane is then complete."
      elif [ "$f" -eq $((N - 1)) ]; then
        NEXT="merge PR #${PR_NUM[$f]} ($id); initiation is then complete."
      else
        NEXT="merge PR #${PR_NUM[$f]} ($id) when it is ready. /cuevik-start:${ID[$((f + 1))]} may start now (one step ahead), but the main ruleset blocks it from merging until PR #${PR_NUM[$f]} merges."
      fi ;;
    branch)
      b="${PR_BRANCH[$f]}"
      [ -n "$b" ] || b="${BRANCH[$f]}"
      NEXT="/cuevik-start:$id in a new session. Branch $b exists; the runner asks whether to reuse or delete it." ;;
    *)
      if [ "$f" -eq "$FIRST_UNCOVERED" ] && [ "$E_STATE" = "MERGED" ]; then
        NEXT="Express lane complete (express PR #$E_NUM). To graduate, /cuevik-start:$id in a new session; optional."
      else
        NEXT="/cuevik-start:$id in a new session."
        if [ "${CHECK[$f]}" = "finalize" ]; then
          NEXT="$NEXT It strips the INITIATION-ONLY block from CONTRIBUTING.md; the last step."
        fi
      fi ;;
  esac
fi
printf '**Next:** %s\n' "$NEXT"

# ---- == steps -----------------------------------------------------------------------------------
printf '\n== steps\n'
i=0
while [ "$i" -lt "$N" ]; do
  printf '%s|%s|%s|%s|%s|%s|%s\n' "${ID[$i]}" "${SLUG[$i]}" "${STATE[$i]}" "${PR_NUM[$i]:--}" \
    "${PR_DAY[$i]:--}" "${PR_BRANCH[$i]:--}" "$([ "${PR_STATE[$i]}" = "NONE" ] && echo - || echo "${VIA[$i]}")"
  i=$((i + 1))
done

# ---- == gate ------------------------------------------------------------------------------------
# A step may start once the previous step's PR is open or merged; while it is only open, every
# step before it must be merged, which keeps the operator at most one step ahead.
if [ "$GATE_INDEX" -ge 0 ]; then
  g=$GATE_INDEX
  RESULT="pass"; MESSAGE="-"; P="-"; P_PR="-"; P_ST="-"; P_BR="-"; P_DAY="-"
  if [ "${CHECK[$g]}" != "bootstrap" ] && [ "$g" -gt 0 ]; then
    p=$((g - 1))
    P="${ID[$p]}"
    case "${PR_STATE[$p]}" in
      MERGED) P_ST="merged"; P_PR="${PR_NUM[$p]}"; P_BR="${PR_BRANCH[$p]}"; P_DAY="${PR_DAY[$p]}" ;;
      OPEN)
        P_ST="open"; P_PR="${PR_NUM[$p]}"; P_BR="${PR_BRANCH[$p]}"
        i=0
        while [ "$i" -lt "$p" ]; do
          if [ "${PR_STATE[$i]}" != "MERGED" ] && [ "$RESULT" = "pass" ]; then
            RESULT="stop"
            MESSAGE="You can be at most one step ahead: ${ID[$i]}'s PR must merge before ${ID[$g]} starts while $P's PR is still open."
          fi
          i=$((i + 1))
        done ;;
      *)
        RESULT="stop"
        MESSAGE="$P's PR must be open or merged before ${ID[$g]} can start. Run /cuevik-start:$P first." ;;
    esac
  fi
  printf '\n== gate\n'
  printf 'step: %s\nresult: %s\n' "${ID[$g]}" "$RESULT"
  printf 'predecessor: %s\npredecessor_state: %s\npredecessor_pr: %s\n' "$P" "$P_ST" "$P_PR"
  printf 'predecessor_branch: %s\npredecessor_merged: %s\nmessage: %s\n' "$P_BR" "$P_DAY" "$MESSAGE"
fi
exit 0
