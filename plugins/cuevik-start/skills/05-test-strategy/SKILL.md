---
name: 05-test-strategy
description: Step 05 of cuevik-start. Run once 04-tech-stack's PR is open or merged, in a new session in the project folder. Interviews the Architect on how the product will be verified and opens a PR adding docs/TEST-STRATEGY.md — test levels, a coverage target, test environments and data, how each NFR is verified, who owns quality, and how defects are handled. No test code and no tool choices.
disable-model-invocation: true
---

# 05-test-strategy

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `05-test-strategy` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   template, commit message, PR summary.
3. This file — what `docs/TEST-STRATEGY.md` must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 05-test-strategy.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (runner, Skills).

`docs/TEST-STRATEGY.md` says how the product is verified: which levels of testing exist, what
coverage is expected, where tests run, how each non-functional requirement is checked, who is
accountable for quality, and how defects are handled. It derives from `PRD.md`,
`ARCHITECTURE.md` and `TECH-STACK.md`. It holds no test code and names no tool that
`TECH-STACK.md` does not list; test commands live in the `CONTRIBUTING.md` tooling layer and are
not restated.

## What This Document Covers

The template (`TEST-STRATEGY.template.md`) owns the headings and their order. This list owns what
each section must contain. Fill every section; add or drop none.

1. **Test Levels** — each level in use (named by the operator), what it covers in terms of
   `ARCHITECTURE.md` components and integrations, and the `PRD-NNN` requirements it verifies.
   Every Must requirement in `PRD.md` §6 maps to at least one level.
2. **Coverage Target** — the measure, its target and what it applies to. **The target is a number
   from the operator**, never a default (`_writing-rules.md`, no guessed numbers).
3. **Test Environment & Data** — each environment tests run in, which levels run there, and where
   its test data comes from, taken from `ARCHITECTURE.md` and `TECH-STACK.md`, not invented.
4. **NFR Verification** — one row per `PRD.md` §7 requirement: the method that verifies it, the
   level it runs at, and the PRD's own pass threshold, copied. No new number.
5. **Quality Ownership** — the role accountable for each level and for this strategy. Roles from
   `.cuevik/lineage.json` and the team's own, not accounts.
6. **Defect Management** — how defects are classified, who triages them, and where they are
   tracked: GitHub issues with the `bug` label that `cuevik-ship` already uses. Any response or
   fix target is a number from the operator.

Requirements use RFC 2119 keywords and are measurable (`_writing-rules.md`).

## Interview

Ask open questions as one plain sentence in chat, not with `AskUserQuestion` (runner, Asking The
Operator, open interview questions). Confirmations and choices use `AskUserQuestion`.

At runner §4, read `docs/PRD.md`, `docs/ARCHITECTURE.md` and `docs/TECH-STACK.md` from `main`.
Summarize first, in a short table, what needs verifying: each Must requirement of `PRD.md` §6,
each §7 requirement, each `ARCHITECTURE.md` component and integration, and the test tools
`TECH-STACK.md` lists. Then go section by section in template order. Each section ends with
`AskUserQuestion` `Approve <section>?` (`Yes` / `No`); on `No`, ask what to change and show only
what changed.

- **Levels.** The operator names the levels. Ask which requirement classes each level verifies,
  and what no level covers yet. A Must requirement no level covers is not written over: it goes
  to the PR body under **Not covered by any level**.
- **Numbers.** The coverage target and every threshold come from the operator. A guess names the
  measure and asks for its number. Being told to pick, invent or use any number is not a number:
  say so and ask once more. Still none for the coverage target: **STOP** before drafting, and
  tell the operator the step cannot finish until they give one.
- **NFRs.** Copy each §7 requirement and its number from `PRD.md`; ask only for the method and
  the level. If §7 is empty or does not state a number for a requirement (for example `PRD.md`
  came from the Express lane and §7 holds its stub line), write `No verifiable non-functional
  requirement in PRD.md §7.` in §4 for that gap and list it in the PR body under **Upstream
  changes needed**, for a `/cuevik-docs:update docs/PRD.md` first.
- **Tools.** A test tool not listed in `TECH-STACK.md` is not named: list it under **Upstream
  changes needed**. Never edit an upstream document in this step.
- **Unknowns.** A value the operator does not know yet is written as `Not set yet: <what is
  missing>`, never guessed, and listed in the PR body under **Not set yet**.

### Challenges

- Apply the Architect challenge sequence (`roles/solution-architect.md`): scope fit, decisions
  with their trade-offs, blast radius. A level or environment that maps to no requirement or
  component is speculative: say so, and leave it out unless the operator names what it serves.
- Product Owner co-review (`roles/product-owner.md`) checks the strategy against the requirements
  and success criteria: a gap between what `PRD.md` promises and what any level verifies is raised
  in the PR, not accepted inline.
- Push back on a target with no measure, an NFR method that cannot produce its pass threshold, and
  a quality owner who is a team rather than a role.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add four lists, one
line per item, `None` when empty:

- **Not covered by any level** — Must requirements no test level verifies.
- **Upstream changes needed** — tools, requirements or numbers missing from `TECH-STACK.md` or
  `PRD.md`.
- **Not set yet** — values left as `Not set yet`.
- **Deferred to the Architect** — technical points the operator raised that belong in an upstream
  document.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template skeleton — header block, all six sections in order, and the
      references table present; no top-level section added or removed, and no `[placeholder]`
      left unfilled.
- [ ] Every Must requirement in `PRD.md` §6 maps to at least one test level, or is listed in the
      PR body under **Not covered by any level**.
- [ ] The coverage target and every threshold is a number the operator gave; none is a default or
      a guess.
- [ ] Every NFR row copies its threshold from `PRD.md` §7 and names a verification method and a
      level defined in §1.
- [ ] Environments and data sources trace to `ARCHITECTURE.md` or `TECH-STACK.md`.
- [ ] Every owner is a role. Defect tracking uses GitHub issues, with no tracker invented.
- [ ] No test code, and no tool that `TECH-STACK.md` does not list.
- [ ] Statements are measurable and use RFC 2119 keywords (`_writing-rules.md`).
