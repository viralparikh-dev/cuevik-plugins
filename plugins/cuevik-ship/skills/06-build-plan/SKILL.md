---
name: 06-build-plan
description: Step 06 of cuevik-ship. Run in the issue's worktree after 05-design-spec's PR is merged with spec.md Approved and its sign-offs given. Turns the spec into plan.md — dependency-ordered tasks, each with its files and a proof command that fails before the task — that a fresh session can execute cold, moves the card to Ready, and opens a PR adding plan.md to the issue branch. Writes no code.
disable-model-invocation: true
argument-hint: "<issue#>"
---

# 06-build-plan

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `branches.md`, `references-block.md`,
   `config.md` (same folder).
3. This file — what is specific to 06.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 06-build-plan.`

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (planning or test-driven development included) does not apply (process,
Skills).

06 turns an approved `spec.md` into `plan.md`: task blocks a session with no memory of this
conversation can execute and turn into a code PR. It plans; not one line of the change is written
here. Write for the coldest possible reader: the executing session gets `plan.md` and the repo,
nothing else.

Arguments: `$ARGUMENTS` — the issue number. Empty: **STOP** and ask for it.

## 1. Gates and branch

1. `gate.md`: common preconditions, then the 06 row — `.../05-design-spec` merged into
   `.../issue`, and `spec.md` there reads `Approved` (missing or `Draft`: run
   `/cuevik-ship:05-design-spec <n>`). A merged `.../06-build-plan` PR: **STOP**, 06 is done.
2. Plan and approval (`gate.md`, After the gate): the branch, `plan.md`, any §8 sign-off edit to
   `spec.md`, the board move to `Ready` and the label removals.
3. `git switch -c ship/<n>-<slug>/06-build-plan origin/ship/<n>-<slug>/issue`.
4. **Sign-offs.** Every box in `spec.md` §8 must be ticked. For each unticked one, ask `Sign off:
   <trigger>?` (`Yes` / `Not yet`); `Yes` ticks it in `spec.md` on this branch. Any still
   unticked: **STOP**, name them, and make sure the issue carries `decision-needed`. Never plan
   around an unsigned trigger, and never plan it as a "pending approval" task. All ticked: remove
   `decision-needed` if present.

Read `spec.md` in full and `intent.md` §4 (what is out); nothing else from the work folder.

## 2. Read the code

Read every file the spec says this touches, and find the ones it missed: a plan written from the
spec alone names files that do not exist and misses those that do. Confirm where each new file
goes against `README.md` Project Structure and `docs/ARCHITECTURE.md` §5. Take the lint, test,
format and build commands from the tooling layer of `CONTRIBUTING.md` (`TOOLING-LAYER` block);
one that reads `Not set yet` is named as a risk, and the task that needs it says how the
executing session finds out.

## 3. Decompose

Break the work into tasks small enough that one agent holds a whole task in context. For each:

- **depends-on** — the tasks whose output this one reads. Minimal and honest: "I'd do this
  first" is not a dependency, and it serialises work that could run in parallel.
- **files** — every path it creates or edits. Two tasks that can run in parallel never name the
  same file; if they do, they are one task, or mis-split.
- **do** — what changes, precisely enough that two agents would write the same thing.
- **proof** — one copy-pasteable command that passes only when the task is done (a named test
  file, not "tests pass"). **It must fail before the task starts**: that is what makes it proof.
  Where the proof is a test, writing that test is part of the same task.

Group the tasks into waves: wave 1 has no dependencies, wave 2 depends only on wave 1, and so on.

## 4. Write it

`docs/ship/<n>-<slug>/plan.md`: header per `process.md` (Artifacts), title `<Title> — Plan`, plus
`**Derived from:** [spec.md](spec.md)` and `**Code branch:** ship/<n>-<slug>/07-execute-plan`,
then:

```markdown
## Execution contract

Read this before starting, and again whenever the repo does not look the way a task expects.

1. A task is done when its proof command passes, not when the code looks right.
2. When the repo contradicts the plan (a file not where it says, an interface that differs, a
   test that cannot be written as described), stop: append it to Deviations, open the code PR as
   a draft titled with what blocked, and report. Do not improvise past a wrong plan.
3. Scope is the task list: no refactor, abstraction or extra handling no task asked for.
4. Ship gate before the PR: <the lint, format, type and test commands from CONTRIBUTING.md>. All
   pass: a regular PR. Any fails: a draft PR titled with the failure, then stop. Never weaken a
   check to get green.
5. Never push to main, never force-push, never merge or close the PR.
6. The code PR ends with `Closes #<n>`: the board moves the card to Reviewing, and to Done when the
   operator merges.

## Waves

- **Wave 1:** <task numbers> — no dependencies
- **Wave 2:** <task numbers> — after wave 1

## Tasks

### Task 1 — <imperative title>

- **depends-on:** []
- **files:** `path/one`, `path/two`
- **do:** <...>
- **proof:** `<command>`

## Risks

- <what could make this plan wrong, and the task where it would surface>

## Deviations

<Empty at planning time. The executing session appends what the plan said, what the repo held,
and the task it stopped at.>
```

## 5. Self-review, then approve

Before showing it:

1. **Cold read** — does any task rely on something said in this session but not in the file?
2. **Collisions** — do two tasks in one wave name the same file?
3. **Proof coverage** — does every task have a proof, and is every `spec.md` §1 behaviour
   asserted by at least one?
4. **Scope** — does any task do what neither `spec.md` nor `intent.md` asked for?
5. **Sign-offs** — does any task do something §8 flagged and nobody signed off?

Show it and ask `Approve plan.md?` (`Yes` / `No`). Only `Yes` sets `**Status:** Approved`. Then,
locally (`config.md`): move the card to `Ready`, and remove `shaping` (and `decision-needed`)
from the issue: the work folder is complete. In a cloud session, skip the card and say so.

## 6. Commit, push, PR

1. Commit `docs(ship): plan for #<n> — <title>` (with `spec.md` if a sign-off was ticked).
2. Ask `Push ship/<n>-<slug>/06-build-plan and open the PR?` (`Yes` / `No`). A `Draft` is pushed
   with no PR.
3. `Approved`: PR into `.../issue`, title `docs(ship): plan for #<n>`, body: the waves, the task
   count, the risks, and `Refs #<n>`.
4. Refresh the References block: `Plan:` (and `Spec:` if it changed).

Report the PR URL and next: merge it, then `/cuevik-ship:07-execute-plan <n>` in a new session in
the worktree. Executing the plan is a separate session: that is the point of writing it down.
