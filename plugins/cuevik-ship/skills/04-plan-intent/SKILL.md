---
name: 04-plan-intent
description: Step 04 of cuevik-ship. Run for a story after 03-create-backlog, or directly for a bug fix, refactor or split story (it creates the issue's branch and worktree when missing, and files the issue first for a free description). Interviews you until the problem and the cut are stated, before any solution, and opens a PR adding intent.md to the issue branch.
disable-model-invocation: true
argument-hint: "[<issue#> | \"<description>\"]"
---

# 04-plan-intent

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `branches.md`, `references-block.md`,
   `config.md` (same folder).
3. This file — what is specific to 04.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 04-plan-intent.`

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (process, Skills).

**Worktree root** (plugin option): `${user_config.worktree_root}` — resolve it as
`branches.md` says.

04 writes `intent.md`: the problem, stated, before anyone proposes a solution. It does not design
(05) or plan (06): no schema, no file names, no components, no libraries. The moment a solution
appears in this session, the step has failed at the one thing it exists to do.

Arguments: `$ARGUMENTS`

- **An issue number** — work already on GitHub.
- **A free description** (quoted) — work not on GitHub yet, such as a bug fix or a refactor. The
  issue is filed after the interview (§4).
- **Empty:** list the issues with a `ship/<n>-*/issue` branch whose `plan.md` is missing or not
  `Approved`, and ask which to resume.

## 1. Resolve the path

Run the gate (`gate.md`): `ship-state.sh <n> 04-plan-intent` for an issue number, or
`ship-state.sh --preflight` for a free description. Then decide which path this is:

| Path | When | Gate | Branches |
| --- | --- | --- | --- |
| **A. After 03** | the issue has a `ship/<n>-*/issue` branch | the 04 row: References has `Epic:`, and no `idea` label — on a `flat` repo (`config.md`), a `story` label instead of the `Epic:` line, and no `idea` label | in the issue's worktree (this session must run there) |
| **B. New work item** | an open issue with no `ship/<n>-*` branch, not labelled `epic` or `idea` (a bug, a refactor, a split story, or a story filed at initiation) | none | 04 creates `.../issue` and the worktree |
| **C. Free description** | text, not a number | none | as B, once the issue exists |

- An `idea` issue (the script's gate stops it; on a `flat` repo too): it has not been through 02
  and 03. An `epic`, or a closed issue: the gate stops those as well.
- An `Approved` `intent.md` on the issue branch, or a merged `.../04-plan-intent` PR: **STOP**,
  04 is done; next is 05. A `.../04-plan-intent` branch with no PR: resume (refine that file; do
  not start a second one).

Read the issue: `gh issue view <n> --json number,title,body,labels,url`.

## 2. Pick the mode

Search the issue title and body for a `PRD-NNN`.

- **Found: slice contract.** The problem is already stated in `docs/PRD.md`; restating it teaches
  nothing. The job is the **cut**: why this slice now, what is in it, and, the part that earns the
  file, what is deliberately not.
- **Not found: problem statement.** Bugs, refactors, anything labelled `decision-needed`, and free
  descriptions: nothing upstream states the problem, so this file states it first.

Say which mode and why, so the operator can overrule it.

## 3. Interview

Read `docs/PRODUCT.md`, `docs/PRD.md` and `docs/ARCHITECTURE.md` from `origin/main` first; never
recall them. Then ask one open question per message, a single plain sentence, anchored in
specifics. Push on whichever of these stays soft; they are the file's sections:

- **Why now** — what changes if this waits a month? "It's next on the board" is not a reason.
- **Outcome** — what is observably true when this is done that is not true today: something a
  person can check, not work completed.
- **The cut** — what is in this slice, and at least one plausible thing that is out. A slice with
  nothing excluded has not been cut.
- **Affected users and systems** — which target users, which existing components, data and
  integrations from `ARCHITECTURE.md`.
- **Constraints** — every one cited to a document and section (`docs/ARCHITECTURE.md §7`), read,
  not recalled.
- **Open questions** — what is not known yet, and which must be settled before 05 can run.

Play back each part in a few lines before it is written, mark guesses as guesses, and challenge
the answers. A solution offered by the operator is noted for 05 (`intent.md` §7, deferred), never
written as the intent.

## 4. The gate, then the branches

Every open question is either answered or explicitly deferred with a reason ("deferred:
duplicate-merge behaviour, because nothing in this slice creates duplicates"). An unmarked open
question: say which, and write nothing.

Then the plan and approval (`gate.md`, After the gate), listing what applies:

- **Path C:** the issue to file — exact title, body (a short statement of the problem from §1 and
  §2, then the empty References block) and labels (`bug` for a bug, none for a refactor), and the
  board item (local sessions, when the repo has a board). It is filed only now: a title written before the interview
  describes the first guess.
- **Paths B and C:** `.../issue` from `origin/main` and the worktree (`branches.md`); from then on
  work in the worktree by absolute path.
- **All:** the branch `.../04-plan-intent`, the file `docs/ship/<n>-<slug>/intent.md`, and the
  `shaping` label on the issue (created if missing; it means a work folder is open whose plan is
  not approved — 06 removes it).

## 5. Write it

On `ship/<n>-<slug>/04-plan-intent` (from `origin/ship/<n>-<slug>/issue`), write `intent.md`:
header per `process.md` (Artifacts), title `<Title> — Intent`, plus a `**Mode:**` line, then:

```markdown
## 1. Problem

<Slice contract: why this cut, now. Problem statement: what is broken or missing, in plain terms,
with no solution in it.>

## 2. Outcome

<What is observably true when this is done. Checkable, not "implemented X".>

## 3. In this slice

- <...>

## 4. Explicitly not in this slice

- <...> — <why it is out>

## 5. Affected users and systems

- **Users:** <target users>
- **Existing components and data:** <from ARCHITECTURE.md>
- **Integrations:** <external systems touched, or none>

## 6. Constraints

- <constraint> — docs/<FILE>.md §<n>

## 7. Open questions

- **<question>** — answered: <answer>
- **<question>** — deferred: <why it can wait past 05-design-spec>
```

Show it and ask `Approve intent.md?` (`Yes` / `No`). Only `Yes` sets `**Status:** Approved`; on
`No`, revise and ask again, or leave it `Draft` (a later run resumes it). The board Status does
not move here: `shaping` already says the item is in hand.

## 6. Commit, push, PR

1. Commit `docs(ship): intent for #<n> — <title>`.
2. Ask `Push ship/<n>-<slug>/04-plan-intent and open the PR?` (`Yes` / `No`). A `Draft` is pushed
   with no PR.
3. `Approved`: PR into `.../issue` (`branches.md`, PRs), title `docs(ship): intent for #<n>`,
   body: the mode, the outcome, the cut, and `Refs #<n>`.
4. Refresh the References block: `ship-refs.sh <n> apply`. It writes `Intent:` with the PR head permalink
   and the PR number.

Report the PR URL and next: merge it, then `/cuevik-ship:05-design-spec <n>` in a new session in
the worktree. Do not invoke 05.
