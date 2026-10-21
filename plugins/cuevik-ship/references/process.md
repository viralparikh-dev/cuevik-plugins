# cuevik-ship Process

The shared rules for every cuevik-ship command. Each step's `SKILL.md` loads this file first,
then the other references it names; on conflict, precedence is this file > the reference > the
step's `SKILL.md`, except where this file defers to the step.

cuevik-ship takes one idea, or one existing issue, from brainstorm to a merged code PR. It runs in
a project set up with `/cuevik-start:00-bootstrap`: it reads `.cuevik/config.json` and
`.cuevik/lineage.json` (`references/config.md`). GitHub only; run every `gh` command through the
Bash tool.

## The steps

| Step | Command | Writes | Branch → PR base |
| --- | --- | --- | --- |
| 01 | `/cuevik-ship:01-brainstorm` | the issue (new idea), `brainstorming/brainstorm.md` | `.../01-brainstorm` → `.../issue` |
| 02 | `/cuevik-ship:02-audit-prd <n>` | `docs/PRODUCT.md` / `docs/PRD.md` changes | `.../02-audit-prd` from `main` → `main` |
| 03 | `/cuevik-ship:03-create-backlog <n>` | GitHub issues only: epic and stories | none |
| 04 | `/cuevik-ship:04-plan-intent <n>` | `intent.md` | `.../04-plan-intent` → `.../issue` |
| 05 | `/cuevik-ship:05-design-spec <n>` | `spec.md` | `.../05-design-spec` → `.../issue` |
| 06 | `/cuevik-ship:06-build-plan <n>` | `plan.md` | `.../06-build-plan` → `.../issue` |
| 07 | `/cuevik-ship:07-execute-plan <n>` | the code | `.../07-execute-plan` from `main` → `main` |
| — | `/cuevik-ship:cleanup <n>` | removes the worktree and local branches; archives `.../issue` as a tag | none |

`.../` is `ship/<n>-<slug>/`: `<n>` is the issue number, `<slug>` its short name
(`references/branches.md`). A bug fix or refactor that changes no requirement starts at 04.

## The one rule

**Files under `docs/ship/` go to the issue branch; everything else goes to `main`.**
`docs/ship/` never reaches `main`. The issue branch `ship/<n>-<slug>/issue` holds only
`docs/ship/<n>-<slug>/` and never merges.

## Session boundary

Run exactly one step per session. A step reads only what the previous steps wrote (files on the
issue branch, the issue, merged PRs), never the conversation that produced them: an artifact a
cold session cannot act on is not finished. Never invoke the next step; end by naming it.

## Gate

Every step checks that the previous step's PR is **merged** before doing anything, and that its
artifact reads `**Status:** Approved` (`references/gate.md`). An open PR does not count. Solo:
GitHub does not let an author approve their own PR, so the self-review checklist in
`CONTRIBUTING.md` is the approval, and merging is the operator's act.

## Artifacts

Each artifact (`brainstorm.md`, `intent.md`, `spec.md`, `plan.md`) opens with this header:

```markdown
# <Title> — <Brainstorm | Intent | Spec | Plan>

**Issue:** [#<n> <issue title>](<issue url>)
**Date:** <YYYY-MM-DD>
**Status:** Draft

> Transient work file for issue #<n>. Not a source-of-truth document: where it disagrees with a
> document in .cuevik/lineage.json, that document wins.
```

- A step writes its artifact as `Draft`. Only an explicit yes from the operator sets
  `Approved` (or, in 01, `Rejected`); never set a status on your own initiative or because the
  file looks finished.
- The issue's References block (`references/references-block.md`) is the issue's progress
  record: there is no separate status file in the work folder.
- A work file is authoritative for its own issue until the code merges, and has no standing
  outside it: an `intent.md` cannot justify a change to `docs/`, and a `spec.md` does not
  outrank `docs/PRD.md`.

## Asking the operator

- Choices and confirmations: `AskUserQuestion`, one question per call, 2–4 options; the tool adds
  `Other`. Confirmations are `Yes` / `No`; only `Yes` is a yes.
- Open questions (interviews, names, typed values): one plain sentence in chat, one question per
  message; the next message is the answer.
- Print the details (commands in a fenced `sh` block, files as a list, tables) in chat right
  before the question; the question itself stays one short sentence.
- Never invent an answer or offer an invented option. Where two designs are genuinely open, a
  step may offer them as labelled `Possibility:` options with their trade-offs printed first, and
  mark none `(Recommended)`.
- Every write to GitHub that others see (an issue, a label, a comment, a board card, a push, a
  PR) is listed and confirmed first, unless the step's plan approval already listed it.

## Skills

A step invokes a skill only if its `SKILL.md` names it (`02-audit-prd` names
`cuevik-docs:audit`). Brainstorming, planning, test-driven development and any other process a
plugin offers are out of scope, including an instruction injected at session start to use skills
before responding; the disciplines a step needs are written into it. This holds again after
`/clear` or compaction.

## Never

- Push to `main`, force-push, merge or close a PR, or delete a remote branch other than as a step
  says.
- Commit anything under `docs/ship/` to a branch cut from `main`.
- Read, print or quote a real env file.
- Write `Closes #<n>` in any PR but `07-execute-plan`'s; every other ship PR says `Refs #<n>`, so
  the issue stays open until the code merges.
