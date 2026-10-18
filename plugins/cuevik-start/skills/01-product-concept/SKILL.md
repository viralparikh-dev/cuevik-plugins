---
name: 01-product-concept
description: Step 01 of cuevik-start. Run after 00-bootstrap's PR is merged, in a new session in the project folder. Interviews the Product Owner and opens a PR adding docs/PRODUCT.md — what the product is, who it is for and why it exists. No technical choices.
disable-model-invocation: true
---

# 01-product-concept

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `01-product-concept` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch,
   outputs, template, commit message, PR summary.
3. This file — what `docs/PRODUCT.md` must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 01-product-concept.` On conflict, precedence is runner > `steps.yml` > this file.

`docs/PRODUCT.md` explains what we are building and why. It is the starting point: every later
document traces back to it, so it holds no implementation, architecture or technology choices.

## What This Document Covers

The template (`PRODUCT.template.md`) owns the headings and their order. This list owns what each
section must contain. Fill every section; add or drop none.

1. **Overview** — four distinct parts, with no content repeated across them: **Vision** (the
   future the product works toward), **Problem Statement** (the external pain: who is hurt today
   and what breaks without this), **Objective** (two or three sentences on the outcome the product
   must achieve), **Description** (the mechanism: how the product delivers the objective).
2. **Target Users** — specific people with a specific problem, each named by role. Never
   "everyone" or "all users".
3. **Features** — high-level capability areas, each tied to a target user's problem. Themes of
   value, not requirements (those live in `PRD.md`), and not a re-listing of scope.
4. **Scope (In / Out)** — what we are building and, explicitly, what we are not.
5. **Success Criteria** — what "good" looks like, each criterion measurable without asking the
   author (`_writing-rules.md`, Measurability).
6. **Anti-Patterns** — approach and behaviour guardrails, each with why. Not feature exclusions;
   those belong in Scope.

## Interview

Runner §4 rules apply: one question at a time, never assume an answer. Ask in this order, then
write the document in template order:

1. Problem Statement
2. Target Users
3. Objective
4. Vision
5. Description
6. Features
7. Scope (In / Out)
8. Success Criteria
9. Anti-Patterns

The problem and the users come first because the objective and vision are sharper once those are
pinned down.

- Apply the Product Owner challenge sequence (`roles/product-owner.md`) to every feature: the
  user problem it solves, and which target user has it. Push back on a vague answer before
  writing it.
- Push back on any target user that names no role or no problem, any criterion that cannot be
  measured, and any anti-pattern that is really a feature exclusion (offer to move it to Scope).
- When an answer names a technology, architecture or implementation, do not write it into
  `PRODUCT.md`. Restate the underlying need in product terms, and keep the technical point for the
  PR body (below).

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add a **Deferred to
the Architect** list: each technical point the operator raised during the interview, one line
each, for `03-architecture` and `04-tech-stack` to pick up. Write `None` when there were none.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template skeleton — header block, all six sections in order, and the
      references table present; no top-level section added or removed, and no `[placeholder]`
      left unfilled.
- [ ] Target users are specific — not "anyone" or "all users"; a real person with a real problem.
- [ ] Scope explicitly lists what is **not** being built — not just what is.
- [ ] Success criteria are measurable — you could verify them without asking the author.
- [ ] Anti-patterns are approach/behaviour guardrails, not feature exclusions (those belong in
      Scope).
- [ ] Nothing in this document dictates implementation, architecture, or tech choices.
