---
name: 07-execute-plan
description: Step 07 of cuevik-ship. Run in the issue's worktree after 06-build-plan's PR is merged with plan.md Approved. Builds the plan task by task on a code branch cut from main (each proof failing first, then passing), runs the ship gate, and opens the code PR to main with Closes #<n>; the only ship PR that reaches main with code. No docs/ship file can leak into it.
disable-model-invocation: true
argument-hint: "<issue#>"
---

# 07-execute-plan

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `branches.md`, `references-block.md`,
   `config.md` (same folder).
3. This file — what is specific to 07.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 07-execute-plan.`

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (test-driven development, debugging or review included) does not apply
(process, Skills). The plan's Execution contract is the discipline.

07 takes an approved `plan.md` and builds it. It writes no artifact. The plan is its only input:
the sessions that wrote the intent, spec and plan are gone.

Arguments: `$ARGUMENTS` — the issue number. Empty: **STOP** and ask; starting a build is too
consequential to guess.

## 1. Gates

The gate (`gate.md`): `ship-state.sh <n> 07-execute-plan`, then, each hard (fail one: say which
and stop, move nothing):

1. **The plan and no previous run.** The script stops unless `.../06-build-plan` is merged into
   `.../issue` and `plan.md` there reads `Approved`. It also covers the plan's `**Code branch:**`
   (`ship/<n>-<slug>/07-execute-plan`): an open PR from it → **STOP** and name it; a merged one →
   **STOP**, 07 is done. The branch on GitHub or local with no PR (`step_branch_state` not `none`)
   → ask `Reuse it` / `Delete it` (a reuse continues from its commits and the plan's first task
   whose proof still fails).
2. **The card** (local sessions): `Ready` → proceed. `Working` → a run may already be live: ask
   `Continue anyway?` (`Yes` / `No`). Anything else → report it and ask the same. Not on the board
   or a cloud session: say so and proceed. `boardState` `none`: there is no card; proceed, saying
   nothing.

Then the plan and approval (`gate.md`, After the gate): the code branch from `origin/main`, the
card to `Working`, the waves and task count, the ship gate commands, and the code PR to `main`
(regular, or draft if the gate fails or the plan stops). This one approval covers the push and
the PR.

## 2. Start

1. Card to `Working` (local; `config.md`). Cloud: skip and report. `boardState` `none`: skip,
   silently.
2. In the worktree: `git switch -c ship/<n>-<slug>/07-execute-plan origin/main` (reuse: switch to
   it). This branch has no `docs/ship/`.
3. Read the plan from the issue branch (`git show origin/ship/<n>-<slug>/issue:...plan.md`) in
   full. Keep a working copy outside the repo if useful; never write it into the worktree.

## 3. Execute

Follow the plan's Execution contract. These rules hold on top of it:

- **Wave by wave**, in the plan's order. Tasks within a wave may run in parallel through
  subagents when the session has them and the tasks share no file; otherwise one at a time.
- **Proof first.** Before a task, run its proof and see it fail; a proof that already passes
  means the plan is wrong about the repo (a contradiction, below). After the task, run it and see
  it pass. Where the proof is a test, write the test first.
- **One commit per task**, `<feat | fix | refactor | test>: <task title> (#<n>)`, after its proof
  passes.
- **Contradictions** (a file not where the plan says, an interface that differs, a test that
  cannot be written as described, an unsigned decision): stop at that task. Record what the plan
  said, what the repo held, and the task, as a **Deviation**, push what passed, and open the PR as
  a **draft** titled `Blocked: <what>` (§4). Never improvise past a wrong plan, and never ask the
  operator to approve a change to the plan mid-run: a new plan comes from `06-build-plan`.
- **Scope** is the task list. No refactor, abstraction or handling no task asked for; no
  dependency the plan does not name (`AI-TOOL-GUIDE.md` escalation rules apply).
- **Cloud session** (`config.md`): no questions at all; anything that would need an answer is a
  contradiction.

## 4. Ship gate, push, PR

1. Run the plan's ship gate (its lint, format, type and test commands). All pass: a regular PR.
   Any fails: a draft PR titled `Failing: <check>`. Never weaken, skip or disable a check.
2. **Leak check.** `git diff --name-only origin/main...HEAD` lists nothing under `docs/ship/`;
   otherwise **STOP** and remove it from the branch before pushing.
3. `git push -u origin ship/<n>-<slug>/07-execute-plan`, then
   `gh pr create --base main --head ship/<n>-<slug>/07-execute-plan` (`--draft` when §3 or the
   gate says so). Title `<type>: <issue title without its PRD prefix> (#<n>)`. Body:
   - **What** — one paragraph from the plan.
   - **Tasks** — each task with its proof command and result.
   - **Ship gate** — each command and result.
   - **Deviations** — each one, or `None`.
   - **Follow-up documents** — `spec.md` §7's downstream changes, each for
     `/cuevik-docs:update <document>`, or `None`.
   - Last line: `Closes #<n>`. The board moves the card to `Reviewing` when the PR links, and to
     `Done` when it merges and closes the issue. Do not set either yourself.
4. **Deviations** also go on the issue as one comment (`gh issue comment <n>`): the plan lives on
   the issue branch, which this branch must not touch.
5. **Final References refresh:** `ship-refs.sh <n> apply`. It writes `Code PR: #<c>` and re-points every
   file line at the latest commit on `.../issue` that touched it.

## 5. Report

End with, and nothing after:

- the code PR URL, and whether it is a draft (and why);
- the code branch and its head commit;
- every deviation, or `none`;
- next: review and merge the code PR (the operator's act), then run `/cuevik-ship:cleanup <n>`
  from the main checkout, not from this worktree.
