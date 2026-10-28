# Preconditions and gates

Run these before a step creates a branch, writes a file or changes GitHub. Stop at the first
failure with what to fix. Do not proceed on assumption.

## Common preconditions (every step)

1. **Repo root.** `git rev-parse --show-prefix` prints nothing (the main checkout or a worktree
   root). Otherwise **STOP**: `Run cuevik-ship from the repo or worktree root.`
2. **Project set up.** `git show origin/main:.cuevik/config.json` and `git show
   origin/main:.cuevik/lineage.json` both exit 0 (after `git fetch --prune origin`). Otherwise
   **STOP**: `This repo is not set up for cuevik. Run /cuevik-start:00-bootstrap first.`
3. **Signed in.** `gh auth status` exits 0, or **STOP**: `gh is not signed in. Run gh auth login,
   then re-run.`
4. **Clean tree.** `git status --porcelain` is empty, or **STOP**: `Uncommitted changes detected
   — commit or stash before continuing.` Never stash for the operator.
5. **Issue.** For a step that takes `<n>`: `gh issue view <n> --json
   number,title,state,labels,body,url` exits 0, or **STOP** naming the number. The argument may
   be `41`, `#41` or the issue URL.
6. **Slug and worktree.** Resolve them (`references/branches.md`): the issue's `ship/<n>-*/issue`
   branch, and this session's folder is that issue's worktree (except where the step creates
   it).

## The gate (previous step merged)

`gh pr list --head <branch> --base <base> --state merged --json number,url,mergedAt`. At least one
PR: merged. None: **STOP**, naming the PR that must merge first; an open PR does not count. Then
read the previous artifact's `**Status:**` from the issue branch:
`git show origin/ship/<n>-<slug>/issue:docs/ship/<n>-<slug>/<file>`.

| Step | Requires |
| --- | --- |
| 01 | Nothing before it. An existing issue is checked by the step (refuse epics, send bugs to 04). |
| 02 | `.../01-brainstorm` PR merged into `.../issue`; `brainstorm.md` reads `Approved` |
| 03 | `.../02-audit-prd` PR merged into `main` (the issue's References `Docs PR:` line names it); its ratified block in the PR body |
| 04 | After 03: References has an `Epic:` line and the issue has no `idea` label (no PR to check: 03 has none). Bug fix, refactor or split story with no `.../issue`: nothing; 04 creates it |
| 05 | `.../04-plan-intent` PR merged into `.../issue`; `intent.md` reads `Approved` |
| 06 | `.../05-design-spec` PR merged into `.../issue`; `spec.md` reads `Approved`; every §8 box ticked, or signed off in 06 itself |
| 07 | `.../06-build-plan` PR merged into `.../issue`; `plan.md` reads `Approved` |
| cleanup | `.../07-execute-plan` PR merged into `main`, or the issue closed as *not planned*; and no open PR whose head starts with `ship/<n>-` |

## Step not already done

A step whose artifact already reads `Approved` on the issue branch, or whose PR is already merged,
**STOPS**: the step is complete. A step with an open PR **STOPS** and names it: merge or close
it first. A step whose branch exists with no PR is a resume: ask `Reuse it` / `Delete it`
(`references/branches.md`).

## After the gate

Refresh the References block (`references/references-block.md`). Then print a ✓ table of the
checks in plain words, and the step's plan: the branch, the files, every GitHub change with its
command. Ask once: `Start <step> for #<n> on <branch>? For more details, review my Plan that I
articulated above.` (`Yes` / `No, stop`). This one approval covers the changes the plan lists;
later questions (approving the artifact, pushing) are asked where they happen.
