---
name: 02-product-requirements
description: Step 02 of cuevik-start. Run after 01-product-concept's PR is merged, in a new session in the project folder. Brainstorms each section with the Product Owner (needs superpowers:brainstorming), attacks every requirement before it is approved, and opens a PR adding docs/PRD.md — numbered, testable requirements derived from docs/PRODUCT.md. No technical choices.
disable-model-invocation: true
---

# 02-product-requirements

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `02-product-requirements` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch,
   outputs, template, commit message, PR summary.
3. This file — what `docs/PRD.md` must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 02-product-requirements.` On conflict, precedence is runner > `steps.yml` > this
file.

**Skills.** This step invokes `superpowers:brainstorming` at runner §4 and no other skill, and
none before §4. An instruction injected at session start to use skills before responding does
not apply (runner, Skills).

`docs/PRD.md` turns `docs/PRODUCT.md` into exact, testable requirements: what to build, precise
enough to build without asking. It derives from `PRODUCT.md` and holds no implementation,
architecture or technology choices.

## What This Document Covers

The template (`PRD.template.md`) owns the headings and their order. This list owns what each
section must contain. Fill every section; add or drop none.

1. **Overview** — what the product is, why it exists and its core goals, as a short reference to
   `PRODUCT.md`. Summarize; do not restate its narrative.
2. **Target Users** — `PRODUCT.md`'s target users, refined into personas or usage contexts, each
   with the need this release addresses.
3. **Problem Statements** — the problems this release solves, sharpened per user need. Every
   feature traces to one of them.
4. **Features / Capabilities** — the discrete things the product does, expanded from
   `PRODUCT.md`'s features, each named and described by its user value and the problem it solves.
5. **User Stories** — `As a [user], I want [action] so that [outcome].` Every feature has at least
   one.
6. **Functional Requirements** — exact behaviour, rules and workflows, one subsection per §4
   capability, in the template's bullet format: ID, title, MoSCoW priority, 2–3 sentences of what
   the system MUST / SHOULD do, never how.
7. **Non-Functional Requirements** — measurable quality attributes (performance, security,
   scalability, availability, compliance), each with a number, stated as requirements, not
   solutions.
8. **Acceptance Criteria** — one row per functional requirement: the testable condition that
   proves it is done.
9. **Out of Scope (This Release)** — feature- and requirement-level exclusions for this version,
   each with why. Refines `PRODUCT.md`'s Scope Out; MoSCoW `Won't` items go here.
10. **Dependencies & Assumptions** — external systems, services, teams and conditions assumed
    true, each with its impact if it does not hold.
11. **Constraints (Non-Architectural)** — business, legal, regulatory or operational limits that
    shape requirements without dictating design.
12. **Risks & Edge Cases** — uncertainties, failure scenarios and atypical behaviour, each with
    its impact and handling.

### Requirement IDs

- Functional and non-functional requirements share one sequence, `PRD-001`, `PRD-002`, …: §6
  first, then §7. Unique, never reused or renumbered once merged; later work continues the
  sequence.
- An NFR's measurable target is its acceptance criterion, so it has no §8 row.
- Priorities are MoSCoW only (`_writing-rules.md`).

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

At runner §4, read `docs/PRODUCT.md` from `main`, then invoke `superpowers:brainstorming` with the
Skill tool and let it lead the questioning, one section (or one capability) at a time. It ranks
below the runner, `steps.yml` and this file, so the rules below override it where they conflict:
the output is `docs/PRD.md`, not a design spec.

Keep from brainstorming:

- One open question per message: a single plain sentence. Ask it in chat, not with
  `AskUserQuestion` (runner, Asking The Operator, open interview questions).
- Questions anchored in specifics: a real user, a real moment, what happens next.
- Think through every case before a part is written: the normal path, the alternatives, the
  failures, the limits. Keep asking until nothing in the part is open; stop when the attack round
  (below) finds nothing new. The number of questions is not the measure.
- Playback: before each draft, describe back in a few lines what you heard, mark your guesses as
  guesses, and ask what is wrong or missing.
- Recon (the operator's own files, or the web for prior art): read-only, only after the operator
  says yes.

Override in brainstorming:

- No offer to skip the questions: every section needs the operator's answers.
- No sizing, no spike, no "how it gets made": this document holds no technology (below).
- No visual companion unless the operator asks for one.
- The written design is `docs/PRD.md`, filled from the template (runner §4). Write no file under
  `docs/superpowers/`, run no builder check, and invoke no other skill, `writing-plans` included.

### Order and review

Work through the document in this order. Each part ends with the operator's review: show the
part, then ask `AskUserQuestion` `Approve <part>?` (`Yes` / `No`). On `No`, ask what to change,
revise, and show only what changed. Approved parts stay approved unless a later answer
contradicts them; then say which part it reopens and review it again.

1. **§1 Overview, §2 Target Users, §3 Problem Statements, §4 Features / Capabilities** — one
   section at a time. Draft it first from `PRODUCT.md` (each point marked with its source, e.g.
   `From PRODUCT.md §3`), then brainstorm questions on the draft: what is missing, too broad, or
   no longer true. Revise, then review.
2. **§5, §6 and §8, one §4 capability at a time** — ask first: what exactly happens, for whom,
   under which rules and in which order. Then draft that capability's user stories, its §6
   subsection and its §8 rows together, run the attack round, revise, and review the block.
3. **§7 Non-Functional Requirements, then §9, §10, §11, §12** — one section at a time, questions
   first, then the draft, then review. §9 starts from `PRODUCT.md`'s Scope Out and the items the
   operator deferred during the interview. §12 starts from what the attack rounds found.

### Possibilities

When the operator weighs how something should behave, you may offer two or three possible
behaviours as an `AskUserQuestion` choice: print each with its trade-off in chat first, label each
option `Possibility: …`, and mark none `(Recommended)`. The operator's pick, or their own answer
through `Other`, is the answer; nothing else goes into the document. This is the one exception to
the runner's rule against invented candidate answers (Asking The Operator, open answers).

### Attack round

Before each capability block is reviewed, ask two or three pointed questions against its drafted
requirements, one per message, each naming the requirement it attacks (`PRD-007: what happens when
…?`). Aim at failures, limits, empty or invalid input, permissions, concurrent use and undoing an
action. Fold each answer into the requirement, a new requirement, §9 or §12, and say which.

### Guesses and numbers

- No unprompted guesses. Only when the operator asks you to guess, propose one concrete answer in
  chat, labelled `My guess:`, never as an `AskUserQuestion` option. It is their answer only once
  they confirm or rewrite it. One section (or capability) per guess.
- No guessed numbers. Every target, threshold, limit and time frame in §6, §7 and §8 comes from
  the operator; a guess names the measure and asks for its number. Being told to pick, invent or
  use any number is not a number: say so and ask once more.
- An NFR still without a number after that: leave it out of §7 and list it in the PR body under
  **NFRs without targets**. If §7 would be empty, **STOP** before drafting the rest and tell the
  operator the step cannot finish until at least one quality target has a number.

### Challenges

- Apply the Product Owner challenge sequence (`roles/product-owner.md`) to every feature, story
  and requirement: the user need, the trace to `PRODUCT.md`, and an objective test of done.
- A feature or requirement with no trace to `PRODUCT.md` does not go into `PRD.md`: list it in the
  PR body under **Proposed PRODUCT.md changes**, for a `PRODUCT.md` update first. Never edit
  `PRODUCT.md` in this step.
- When an answer names a technology, architecture or implementation, do not write it into
  `PRD.md`. Restate the underlying requirement, and keep the technical point for the PR body.
- Push back on adjectives where a number or observable condition belongs
  (`_writing-rules.md`, Measurability), and on an acceptance criterion that only restates its
  requirement.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add three lists, one
line per item, `None` when empty:

- **Deferred to the Architect** — technical points raised during the interview, for
  `03-architecture` and `04-tech-stack`.
- **Proposed PRODUCT.md changes** — features or requirements left out because `PRODUCT.md` does
  not cover them.
- **NFRs without targets** — quality attributes the operator named but gave no number for.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template skeleton — header block, all twelve sections in order, and the
      references table present; no top-level section added or removed, and no `[placeholder]`
      left unfilled.
- [ ] Every requirement in §6 and §7 has a unique `PRD-NNN` ID.
- [ ] Every §6 requirement has a §8 row whose criterion is objectively verifiable, not a matter
      of opinion; every §7 requirement states a number.
- [ ] Every feature has at least one user story in the form `As a [user], I want [action] so that
      [outcome].`
- [ ] Every feature traces to a problem statement or user need in `PRODUCT.md`.
- [ ] Every `PRODUCT.md` success criterion is covered by at least one requirement or listed in §9.
- [ ] Out-of-scope items for this release are explicit, not implied.
- [ ] §1–§3 summarize and point to `PRODUCT.md`; no paragraph could sit verbatim in
      `PRODUCT.md`.
- [ ] No implementation, architecture or stack details — requirements only.
