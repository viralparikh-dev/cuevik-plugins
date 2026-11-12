# Preconditions and gates

Run these before a step creates a branch, writes a file or changes GitHub. Stop at the first
failure with what to fix. Do not proceed on assumption.

A script does the checking, not you:

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ship-state.sh" <issue> <step>     # a step that takes an issue
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ship-state.sh" --preflight        # before the issue exists
```

`<issue>` is the number as the operator gave it (`41`, `#41` or the issue's URL) and `<step>` the
step's own id (`02-audit-prd`, …, `07-execute-plan`, or `cleanup`). Run it once, silently, from the
repo root or the issue's worktree root. Never work a gate out with `gh pr list`, `git show` or
`git ls-remote` calls of your own, and never go on without its answer.

| The script | Do |
| --- | --- |
| exits 0, `result: pass` | The step may start. Read the sections below for what the step needs. |
| exits 0, `result: stop` | **STOP** and tell the operator the `message` line. `done: yes` means the step is complete. |
| exits 1 | Its one line is the whole answer: output it and stop. A common precondition failed, or a GitHub query did. |
| exits 2, or cannot be run | Output `Error: ship-state.sh could not be run: <what the shell said>` and stop. There is no other way to run a gate. |

`--preflight` is for the two cases with no issue yet (`01-brainstorm` on a new idea,
`04-plan-intent` on a free description). It checks the common preconditions only and prints
`preflight: ok`; once the issue exists, run the full gate.

## What the script checks

**Common preconditions** (every step; `cleanup` skips 4 and 6):

1. **Repo root.** The folder is the main checkout or a worktree root, not a subfolder.
2. **Project set up.** `.cuevik/config.json` and `.cuevik/lineage.json` are on `origin/main`
   (after `git fetch --prune origin`).
3. **Signed in.** `gh auth status` succeeds.
4. **Clean tree.** `git status --porcelain` is empty. Never stash for the operator.
5. **Issue.** `gh issue view <n>` finds it.
6. **Slug and worktree** (`branches.md`). The issue's `ship/<n>-<slug>/…` branches give one slug;
   more than one is a stop. A step that works in the issue's worktree (every step but `03` and
   `cleanup`) stops when one exists and this folder is not it.

**The gate** (the previous step's PR is **merged**; an open PR does not count):

| Step | Requires |
| --- | --- |
| 01 | Nothing before it. An existing issue is checked by the step (refuse epics, send bugs to 04). |
| 02 | `.../01-brainstorm` PR merged into `.../issue`; `brainstorm.md` reads `Approved` |
| 03 | The `.../02-audit-prd` PR merged into `main` (the one the issue's References `Docs PR:` line names, else the branch's), with its `<!-- cuevik-ship:ratified -->` block in the PR body |
| 04 | The issue is open, not an epic. After 03 (an `.../issue` branch exists): no `idea` label and a References `Epic:` line — on a `flat` repo (`config.md`), the `story` label instead. Otherwise (a bug fix, refactor or split story): no `idea` label |
| 05 | `.../04-plan-intent` PR merged into `.../issue`; `intent.md` reads `Approved` |
| 06 | `.../05-design-spec` PR merged into `.../issue`; `spec.md` reads `Approved`. Every §8 box ticked, or signed off in 06 itself: the script only counts them (`spec_unticked`) |
| 07 | `.../06-build-plan` PR merged into `.../issue`; `plan.md` reads `Approved` |
| cleanup | `.../07-execute-plan` PR merged into `main`, or the issue closed as *not planned*; no open PR whose head starts with `ship/<n>-`; run from the main checkout |

**Step not already done.** A step whose PR is merged, or whose work file already reads `Approved`
on the issue branch, **STOPS** with `done: yes`: the step is complete. A step with an open PR
**STOPS** and names it: merge or close it first. A step whose branch exists with no PR is a resume:
`step_branch_state` says where (`local`, `remote` or `both`); ask `Reuse it` / `Delete it`
(`branches.md`).

## The output

`== issue` (number, title, state, labels), `== branches` (`slug`, `slug_source`, `issue_branch`,
`worktree`, `here`, `main_checkout`), `== steps` (one line per step branch: step, branch, base,
state, PR number, merge date, PR title), `== artifacts` (each work file's `Status`, and the
unticked §8 boxes of `spec.md`), `== references` (whether the References block is `ok`, `missing`
or `malformed`, the `Epic:` and `Docs PR:` numbers, and `backlog_model`) and, given a step,
`== gate` (`result`, `done`, `step_branch`, `step_branch_state`, `message`). Take every fact from
it: a step never recomputes one.

## After the gate

Refresh the References block (`references-block.md`). Then print a ✓ table of the
checks in plain words, and the step's plan: the branch, the files, every GitHub change with its
command. Ask once: `Start <step> for #<n> on <branch>? For more details, review my Plan that I
articulated above.` (`Yes` / `No, stop`). This one approval covers the changes the plan lists;
later questions (approving the artifact, pushing) are asked where they happen.
