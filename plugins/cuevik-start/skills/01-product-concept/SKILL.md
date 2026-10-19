---
name: 01-product-concept
description: Step 01 of cuevik-start. Run after 00-bootstrap's PR is merged, in a new session in the project folder. Interviews the Product Owner in depth (needs superpowers:brainstorming) and opens a PR adding docs/PRODUCT.md — what the product is, who it is for and why it exists. No technical choices.
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

## Precondition: superpowers

The interview runs the `superpowers:brainstorming` skill, so the `superpowers` plugin from the
`claude-plugins-official` marketplace must be installed and enabled. cuevik-start declares it as a
dependency, so it normally comes with cuevik-start. Check it as runner §1 check 7:

- Run `claude plugin list --json`. It lists `superpowers@claude-plugins-official` with
  `"enabled": true`: proceed.
- The `claude` command is not found (an IDE extension may not put it on the path): proceed if
  `superpowers:brainstorming` is in this session's list of available skills.
- Otherwise **STOP** and output these lines (the first only if that marketplace is missing, the
  last instead of the install if the plugin is installed but disabled), then run this step in a
  new session:

  ```text
  /plugin marketplace add anthropics/claude-plugins-official
  /plugin install superpowers@claude-plugins-official
  /plugin enable superpowers@claude-plugins-official
  ```

## Interview

At runner §4, invoke `superpowers:brainstorming` with the Skill tool and let it lead the
conversation: it finds out what the operator wants and why. It ranks below the runner,
`steps.yml` and this file, so the rules below override it where they conflict: the output is
`docs/PRODUCT.md`, not a design spec.

Keep from brainstorming:

- One open question per message: a single plain sentence, with no list of example answers. Ask
  it in chat, not with `AskUserQuestion` (runner, Asking The Operator, open interview questions).
- Questions anchored in specifics: the last time the problem happened, who was there, what it
  cost.
- Playback as you go: once a part is understood (the problem and who has it, say), describe it
  back in about 200–300 words, mark your guesses as guesses, and end by asking what is wrong or
  missing.
- Recon (the operator's own files, or the web for prior art): read-only, only after the operator
  says yes.

Override in brainstorming:

- No offer to skip the questions: every section needs the operator's answers. The first message
  is one open question about the problem.
- No sizing, no spike, no "how it gets made": this document holds no technology (below).
- No visual companion unless the operator asks for one.
- No unprompted guesses. Only when the operator asks you to guess, propose one concrete answer in
  chat, labelled `My guess:`, never as an `AskUserQuestion` option. It is their answer only once
  they confirm or rewrite it.
- One section per guess, even when asked to guess several or all: guess the next section, get it
  confirmed or rewritten, then the next.
- No guessed numbers. Every target, threshold, baseline and time frame in Success Criteria comes
  from the operator; a guess names the measure and asks for its number. Being told to pick,
  invent or use any number is not a number: say so and ask once more. Still none: **STOP**
  before drafting, and tell the operator the step cannot finish until they give the numbers.
- The written design is `docs/PRODUCT.md`, filled from the template (runner §4). Write no file
  under `docs/superpowers/`, run no builder check, and invoke no other skill, `writing-plans`
  included. Approve the draft with `AskUserQuestion` (`Yes` / `No`); after `Yes`, go on to runner
  §5.

Cover these sections, in this order, then write the document in template order:

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
