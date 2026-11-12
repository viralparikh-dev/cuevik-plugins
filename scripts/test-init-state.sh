#!/usr/bin/env bash
# Tests plugins/cuevik-start/scripts/init-state.sh against real temporary git repos and a stub gh.
#
# Usage:  bash scripts/test-init-state.sh
# Needs:  git, jq (see scripts/test-lib.sh, which holds the stub gh and the helpers)
# Any failed expectation prints the output it saw and makes the run exit 1.

source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
SCRIPT="$ROOT/plugins/cuevik-start/scripts/init-state.sh"

# ---- cases --------------------------------------------------------------------------------------
NAME="bootstrap merged, 01 open: 02 may start, 03 may not"
new_repo; bootstrapped
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "docs: add repo governance baseline (00-bootstrap)"
pr init/product-concept OPEN 4 2026-11-02T10:00:00Z "docs: add PRODUCT.md (01-product-concept)"
run 02-product-requirements; code 0
has '## Initiation status — test-owner/test-repo (origin/main @ '
has '`█░░░░░░░░░ 1/10 · next: 01-product-concept`'
has '| 00-bootstrap | CONTRIBUTING.md, .cuevik/ | ✓ merged | PR #1 |'
has '| 01-product-concept | docs/PRODUCT.md | ⟳ PR open | PR #4 — "docs: add PRODUCT.md (01-product-concept)" |'
has '| 02-product-requirements | docs/PRD.md | — not started |  |'
has '**Next:** merge PR #4 (01-product-concept) when it is ready. /cuevik-start:02-product-requirements may start now (one step ahead)'
has '00-bootstrap|bootstrap|merged|1|2026-11-01|init/bootstrap|own'
has '01-product-concept|product-concept|open|4|-|init/product-concept|own'
has '02-product-requirements|product-requirements|none|-|-|-|-'
has 'result: pass'; has 'predecessor: 01-product-concept'; has 'predecessor_state: open'
has 'predecessor_branch: init/product-concept'; hasnt '**Check:**'
run 03-architecture; code 0
has 'result: stop'
has "message: 02-product-requirements's PR must be open or merged before 03-architecture can start. Run /cuevik-start:02-product-requirements first."
run; code 0; hasnt '== gate'

NAME="two steps open: the third is more than one step ahead"
new_repo; bootstrapped
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "bootstrap"
pr init/product-concept OPEN 4 2026-11-02T10:00:00Z "concept"
pr init/product-requirements OPEN 5 2026-11-03T10:00:00Z "prd"
run 03-architecture; code 0
has 'result: stop'
has "message: You can be at most one step ahead: 01-product-concept's PR must merge before 03-architecture starts while 02-product-requirements's PR is still open."

NAME="a repo from before slugs: PRs on numbered branches still count"
new_repo; bootstrapped
on_main docs/PRODUCT.md; on_main docs/PRD.md; on_main docs/ARCHITECTURE.md
pr init/00-bootstrap MERGED 1 2026-10-01T10:00:00Z "bootstrap"
pr init/01-product-concept MERGED 2 2026-10-02T10:00:00Z "concept"
pr init/02-product-requirements MERGED 3 2026-10-03T10:00:00Z "prd"
pr init/03-architecture MERGED 6 2026-10-05T09:30:00Z "architecture"
pr init/03-architecture CLOSED 5 2026-10-04T10:00:00Z "architecture, first try"
run 04-tech-stack; code 0
has '`████░░░░░░ 4/10 · next: 04-tech-stack`'
has '| 03-architecture | docs/ARCHITECTURE.md | ✓ merged | PR #6 |'
has '03-architecture|architecture|merged|6|2026-10-05|init/03-architecture|own'
has '**Next:** /cuevik-start:04-tech-stack in a new session.'
has 'result: pass'; has 'predecessor_state: merged'; has 'predecessor_branch: init/03-architecture'
has 'predecessor_merged: 2026-10-05'

NAME="an old-numbered alias: 05-ai-tool-guide is step 06"
new_repo; bootstrapped
pr init/05-ai-tool-guide OPEN 9 2026-10-09T10:00:00Z "ai tool guide"
run; code 0
has '| 06-ai-tool-guide | docs/AI-TOOL-GUIDE.md | ⟳ PR open | PR #9 — "ai tool guide" |'
has '| 05-test-strategy | docs/TEST-STRATEGY.md | — not started |  |'

NAME="Express lane merged: its PR stands for the four covered steps"
new_repo; bootstrapped
on_main docs/PRODUCT.md; on_main docs/PRD.md; on_main docs/BACKLOG.md
pr init/express MERGED 2 2026-11-04T08:00:00Z "docs: express lane"
run 03-architecture; code 0
has '| 00-bootstrap | CONTRIBUTING.md, .cuevik/ | ✓ merged | express PR #2 |'
has '| 02-product-requirements | docs/PRD.md | ✓ merged | express PR #2 |'
has '| 08-backlog | docs/BACKLOG.md | ✓ merged | express PR #2 |'
has '| 03-architecture | docs/ARCHITECTURE.md | — not started |  |'
has '`███░░░░░█░ 4/10 · next: 03-architecture`'
has '**Next:** Express lane complete (express PR #2). To graduate, /cuevik-start:03-architecture in a new session; optional.'
has '08-backlog|backlog|merged|2|2026-11-04|init/express|express'
has 'result: pass'; has 'predecessor_branch: init/express'
hasnt 'ran out of order'

NAME="Express lane open"
new_repo
pr init/express OPEN 2 2026-11-04T08:00:00Z "docs: express lane"
run; code 0
has '| 00-bootstrap | CONTRIBUTING.md, .cuevik/ | ⟳ PR open | express PR #2 — "docs: express lane" |'
has '**Next:** merge express PR #2; the lane is then complete.'

NAME="a document on main with no merged PR is a mismatch"
new_repo; bootstrapped
on_main docs/PRODUCT.md
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "bootstrap"
pr init/product-concept OPEN 4 2026-11-02T10:00:00Z "concept"
run; code 0
has '| 01-product-concept | docs/PRODUCT.md | ⚠ mismatch | docs/PRODUCT.md on origin/main without a merged init/product-concept PR;'
has '**Check:** 01-product-concept: docs/PRODUCT.md on origin/main without a merged init/product-concept PR;'
has '**Next:** blocked — 01-product-concept does not add up (see Check).'
has '01-product-concept|product-concept|mismatch|4|-|init/product-concept|own'

NAME="a merged PR whose document is not on main is a mismatch"
new_repo; bootstrapped
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "bootstrap"
pr init/product-concept MERGED 4 2026-11-02T10:00:00Z "concept"
run; code 0
has '| 01-product-concept | docs/PRODUCT.md | ⚠ mismatch | PR #4 merged, but docs/PRODUCT.md is missing on origin/main |'

NAME="branches without a PR, and a merged step whose branches were left behind"
new_repo; bootstrapped
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "bootstrap"
pr init/product-concept CLOSED 3 2026-11-02T10:00:00Z "concept, abandoned"
git -C "$REPO" branch init/bootstrap
git -C "$REPO" push -q origin init/bootstrap
git -C "$REPO" branch init/product-concept
run; code 0
has '| 00-bootstrap | CONTRIBUTING.md, .cuevik/ | ✓ merged | PR #1; local branch left — /cuevik-start:cleanup; branch left on GitHub |'
has '| 01-product-concept | docs/PRODUCT.md | ⊙ branch | local, closed PR #3 |'
has '**Next:** /cuevik-start:01-product-concept in a new session. Branch init/product-concept exists; the runner asks whether to reuse or delete it.'

NAME="a merged step after an unmerged one ran out of order"
new_repo; bootstrapped
on_main docs/PRD.md
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "bootstrap"
pr init/product-requirements MERGED 5 2026-11-03T10:00:00Z "prd"
run; code 0
has '**Check:** 02-product-requirements is merged, but 01-product-concept before it is not: the steps ran out of order.'

NAME="every step merged: complete"
new_repo
on_main .cuevik/config.json; on_main .cuevik/lineage.json; on_main CONTRIBUTING.md 'permanent rules only'
n=0
for s in bootstrap product-concept product-requirements architecture tech-stack test-strategy ai-tool-guide readme backlog finalize; do
  n=$((n + 1)); pr "init/$s" MERGED "$n" "2026-11-0${n#1}T10:00:00Z" "$s"
done
for f in PRODUCT PRD ARCHITECTURE TECH-STACK TEST-STRATEGY AI-TOOL-GUIDE BACKLOG; do on_main "docs/$f.md"; done
run 09-finalize; code 0
has '`██████████ 10/10 · complete`'
has '**Next:** Initiation complete. Run /cuevik-start:cleanup to delete merged local init/* branches.'
has 'result: pass'; hasnt '**Check:**'

NAME="the last step is next: finalize, and CONTRIBUTING.md still has its block"
new_repo; bootstrapped
n=0
for s in bootstrap product-concept product-requirements architecture tech-stack test-strategy ai-tool-guide readme backlog; do
  n=$((n + 1)); pr "init/$s" MERGED "$n" "2026-11-0${n}T10:00:00Z" "$s"
done
for f in PRODUCT PRD ARCHITECTURE TECH-STACK TEST-STRATEGY AI-TOOL-GUIDE BACKLOG; do on_main "docs/$f.md"; done
run; code 0
has '| 09-finalize | CONTRIBUTING.md | — not started |  |'
has '**Next:** /cuevik-start:09-finalize in a new session. It strips the INITIATION-ONLY block from CONTRIBUTING.md; the last step.'
pr init/finalize OPEN 10 2026-11-10T10:00:00Z "finalize"
run; code 0
has '**Next:** merge PR #10 (09-finalize); initiation is then complete.'

NAME="a title with a pipe does not break the table"
new_repo; bootstrapped
pr init/bootstrap OPEN 1 2026-11-01T10:00:00Z "docs: a | b"
run; code 0
has '| 00-bootstrap | CONTRIBUTING.md, .cuevik/ | ⚠ mismatch |'
new_repo
pr init/bootstrap OPEN 1 2026-11-01T10:00:00Z "docs: a | b"
run; code 0
has '⟳ PR open | PR #1 — "docs: a \| b" |'

NAME="the bootstrap step has no gate"
new_repo
run 00-bootstrap; code 0
has 'result: pass'; has 'predecessor: -'
has '`░░░░░░░░░░ 0/10 · next: 00-bootstrap`'
has '**Next:** /cuevik-start:00-bootstrap in a new session.'

NAME="a failed GitHub query stops the report instead of reading as no PR"
new_repo; bootstrapped
pr init/bootstrap MERGED 1 2026-11-01T10:00:00Z "bootstrap"
export GH_FAIL_HEAD=init/tech-stack
run; code 1
has 'Could not read pull requests for init/tech-stack from GitHub: HTTP 502: Bad Gateway'
hasnt '== report'

NAME="preflight: not signed in, not at the root, no GitHub origin, not a repo, unknown step"
new_repo
export GH_NO_AUTH=1
run; code 1; has 'gh is not signed in. Run gh auth login, then re-run.'; hasnt '== report'
unset GH_NO_AUTH
mkdir -p "$REPO/sub"
RUN_IN=sub; run; unset RUN_IN; code 1; has 'Run status from the repo root.'
run no-such-step; code 2; has 'no-such-step is not a step id'
git -C "$REPO" remote set-url origin "https://gitlab.com/test-owner/test-repo.git"
run; code 1; has 'No GitHub origin. Run /cuevik-start:00-bootstrap first.'
REPO="$WORK/not-a-repo"; mkdir -p "$REPO"
run; code 1; has 'This folder is not a git repo. Run /cuevik-start:00-bootstrap first.'

NAME="a step table checked out with CRLF line endings still loads"
new_repo
mkdir -p "$WORK/crlf"
cp "$SCRIPT" "$WORK/crlf/init-state.sh"
sed 's/$/\r/' "$ROOT/plugins/cuevik-start/scripts/steps.table" > "$WORK/crlf/steps.table"
OUT="$(cd "$REPO" && bash "$WORK/crlf/init-state.sh" 01-product-concept 2>&1)"; CODE=$?
code 0; has '| 09-finalize | CONTRIBUTING.md | — not started |  |'; has 'predecessor: 00-bootstrap'

finish "init-state"
