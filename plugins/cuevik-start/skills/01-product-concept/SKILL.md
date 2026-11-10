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
   "everyone" or "all users". Includes a **Stakeholders** subsection: the sponsors, funders and
   affected parties of the product, each with their interest in it. Stakeholders are distinct from
   target users: a stakeholder need not use the product, and a list that only restates the target
   users is not a stakeholder list.
3. **Features** — high-level capability areas, each tied to a target user's problem. Themes of
   value, not requirements (those live in `PRD.md`), and not a re-listing of scope.
4. **Scope (In / Out)** — what we are building and, explicitly, what we are not.
5. **Success Criteria** — what "good" looks like, each criterion measurable without asking the
   author (`_writing-rules.md`, Measurability).
6. **Key Assumptions & Validation** — the three to five riskiest product or market assumptions
   the product rests on, each as *assumption · why it is risky · cheapest test*. Product and market
   bets only: delivery assumptions (dependencies, constraints, timing) belong in `PRD.md`.
7. **Anti-Patterns** — approach and behaviour guardrails, each with why. Not feature exclusions;
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

### Optional pitch

Before the first question, offer once: the operator MAY paste a one-paragraph pitch. Ask it in
chat as a single plain sentence, and accept "no" without comment.

- **No pitch:** behave exactly as described above and below. Nothing in this subsection applies.
- **Pitch given:** draft a strawman of `docs/PRODUCT.md` from it, then run the interview below
  over the strawman instead of a blank page.
  - Every statement in the strawman MUST trace to a phrase in the pitch. Show the operator the
    strawman with each statement's source phrase beside it.
  - Invent nothing. A section the pitch does not support stays an explicit gap (`Gap: not in the
    pitch`), to be filled from the operator's answers. Success Criteria numbers, baselines,
    thresholds and time frames are never taken from a guess: a pitch without them leaves a gap.
  - The strawman is a draft, not an answer. Nothing in it counts as confirmed until the operator
    confirms or rewrites it, section by section, in the playback and challenge steps above. Apply
    the Product Owner challenge sequence to the strawman as you would to a fresh answer.
  - All other rules in this file still apply: no technology, architecture or implementation in
    the document, no `docs/superpowers/` files, `AskUserQuestion` only for the draft approval.

Cover these sections, in this order, then write the document in template order:

1. Problem Statement
2. Target Users, then Stakeholders
3. Objective
4. Vision
5. Description
6. Features
7. Scope (In / Out)
8. Success Criteria
9. Key Assumptions & Validation
10. Anti-Patterns

The problem and the users come first because the objective and vision are sharper once those are
pinned down.

- Apply the Product Owner challenge sequence (`roles/product-owner.md`) to every feature: the
  user problem it solves, and which target user has it. Push back on a vague answer before
  writing it.
- Stakeholders and Key Assumptions come from the operator's answers like every other section:
  nothing invented, no guessed numbers. An assumption the operator cannot name stays an explicit
  gap, not a plausible-sounding guess. Ask who sponsors or funds the product and who else is
  affected, separately from who uses it; ask what would have to be true for the product to fail,
  then the cheapest way to find out.
- Push back on any target user that names no role or no problem, any criterion that cannot be
  measured, and any anti-pattern that is really a feature exclusion (offer to move it to Scope).
- When an answer names a technology, architecture or implementation, do not write it into
  `PRODUCT.md`. Restate the underlying need in product terms, and keep the technical point for the
  PR body (below).

## Express profile

When `/cuevik-start:express` runs this step, the following applies and nothing else in this file
changes. The lane asks for the optional pitch itself, before anything else; do not ask again.

- **Written sections:** 1 Overview, 2 Target Users (Stakeholders included), 3 Features, 4 Scope,
  5 Success Criteria. Skip interview items 9 (Key Assumptions & Validation) and 10 (Anti-Patterns).
- **Skipped sections stay.** Sections 6 and 7 keep their headings, in template order, and hold
  exactly one line and nothing else: `Not covered in the Express lane. Add it with /cuevik-docs:update
  docs/PRODUCT.md.`
- **Board metadata:** not applicable. Express is `boardState none`, so the Board metadata section
  is skipped — the lane makes no board call.
- **Unchanged:** the interview rules, the pitch handling, the Product Owner challenge sequence, no
  guessed numbers, no technology in the document, the approval of the draft.
- **Checklist.** "All seven sections in order" means: sections 1–5 filled, sections 6 and 7 holding
  only the line above. The Key Assumptions and Anti-Patterns lines do not apply. Every other line
  applies as written.

## Board metadata

After the draft is approved and committed (runner §5), carry the product concept onto the board's
front page. This is a board write, so runner §7's gate governs it: read `boardState` from
`.cuevik/config.json`.

- **`none`** (every Express repo, and any standard repo with no board): skip silently. Make no
  call and add no board line to the PR body.
- **`configured` or `partial`:** call `board.setMeta`
  (`${CLAUDE_PLUGIN_ROOT}/references/board-adapter.md`) once, with:
  - **short description** = a one-line distillation of the **Objective** from §1 Overview: one
    plain sentence capturing the outcome, drawn only from the Objective and adding nothing it does
    not say.
  - **README** = the **Description** from §1 Overview, verbatim.

  Invent nothing: the README is the `docs/PRODUCT.md` prose as written, and the short description
  says only what the Objective says. A failed call never stops the step (runner §7): report it in
  the PR body and carry on.

Report the result in the PR body: `Board: short description + README set from PRODUCT.md`, or the
`degraded` reason when the call failed.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add a **Deferred to
the Architect** list: each technical point the operator raised during the interview, one line
each, for `03-architecture` and `04-tech-stack` to pick up. Write `None` when there were none.
When the repo has a board, add the board line from **Board metadata**; with `boardState` `none`,
omit it.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template skeleton — header block, all seven sections in order, and the
      references table present; no top-level section added or removed, and no `[placeholder]`
      left unfilled.
- [ ] Target users are specific — not "anyone" or "all users"; a real person with a real problem.
- [ ] Stakeholders are sponsors, funders or affected parties with a stated interest — not the
      target users restated.
- [ ] Scope explicitly lists what is **not** being built — not just what is.
- [ ] Success criteria are measurable — you could verify them without asking the author.
- [ ] Key Assumptions lists three to five product/market assumptions, each with why it is risky
      and a concrete cheapest test — not "we'll validate later", not a delivery assumption, and
      nothing the operator did not state.
- [ ] Anti-patterns are approach/behaviour guardrails, not feature exclusions (those belong in
      Scope).
- [ ] Nothing in this document dictates implementation, architecture, or tech choices.
- [ ] When the repo has a board, its short description is a one-line distillation of the PRODUCT.md
      Objective (one sentence, nothing not in the Objective) and its README is the PRODUCT.md
      Description verbatim; or the PR body records why the board call was skipped or degraded. No
      board repo (`boardState none`): N/A.
- [ ] If the operator gave a pitch, every statement in the document traces to the pitch or to the
      operator's confirmed answers; no strawman claim was kept without confirmation.
