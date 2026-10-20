---
name: 03-architecture
description: Step 03 of cuevik-start. Run after 02-product-requirements' PR is merged, in a new session in the project folder. Works through the system design with the Architect, one section at a time, every decision with its alternatives and trade-offs, and opens a PR adding docs/ARCHITECTURE.md — components, data, integrations, security and the structural answer to each requirement. No technology inventory.
disable-model-invocation: true
---

# 03-architecture

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `03-architecture` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   template, commit message, PR summary.
3. This file — what `docs/ARCHITECTURE.md` must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 03-architecture.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (runner, Skills).

`docs/ARCHITECTURE.md` turns `docs/PRD.md` into the structure the team builds against: the
components, how data moves between them, and the decisions behind them. It is the blueprint, not
the code, and not the stack inventory: named products, languages, frameworks and versions belong
in `docs/TECH-STACK.md` (`04-tech-stack`).

## What This Document Covers

The template (`ARCHITECTURE.template.md`) owns the headings and their order. This list owns what
each section must contain. Fill every section; add or drop none.

1. **System Architecture** — every component, module or service, each with its one
   responsibility and the `PRD-NNN` requirements it serves, and how they connect. At least one
   diagram: a fenced `mermaid` block (GitHub renders it) or a fenced `text` block.
2. **Data Design** — the core entities, their key attributes and relationships, which component
   owns each, and how long it is kept. Kinds of storage (relational, document, file, cache), not
   products.
3. **Data Flow & Interactions** — how data moves between components and external systems for the
   main `PRD.md` workflows: one numbered flow (or sequence diagram) per workflow, including what
   happens when a step fails.
4. **Key Design Decisions** — the structural choices (layering, sync vs async, service
   boundaries, state ownership, tenancy), one table row each. The Rationale cell names the
   requirement that forces the decision, the alternatives rejected and why, and the trade-off
   accepted.
5. **Implementation Conventions** — the structural rules developers follow: module boundaries,
   dependency direction, error handling, configuration, logging, naming at the level of structure.
   How to build, not the code.
6. **Integration Points** — every external API, service or system from `PRD.md` §10, with
   direction, contract (protocol and data exchanged) and the behaviour when it is unavailable.
7. **Security Posture & Data Classification** — each data category with its classification
   (public / internal / confidential / restricted) and handling; the authentication and
   authorization model; encryption at rest and in transit; trust boundaries and network exposure;
   each compliance requirement from `PRD.md` and the structural answer to it; the threat vectors
   the design accounts for.
8. **Non-Functional Approach** — every `PRD.md` §7 requirement not already answered in §7 above,
   by `PRD-NNN`, with the structure that meets its number.

## Interview

Ask open questions as one plain sentence in chat, not with `AskUserQuestion` (runner, Asking The
Operator, open interview questions). Confirmations and choices use `AskUserQuestion`.

At runner §4, read `docs/PRD.md` from `main` and the bodies of the merged `01-product-concept`
and `02-product-requirements` PRs:
`gh pr list --head <branch> --base main --state merged --json number,body --jq '.[0]'`, branches
from `steps.yml`. Their **Deferred to the Architect** lists are inputs to this step: each item is
answered in the document, handed to `04-tech-stack` (PR body, below), or named as not adopted,
with why.

Summarize `PRD.md` first in a short table: capabilities (§4) with their `PRD-NNN` ranges, the §7
targets, the §10 dependencies, the §11 constraints. Then work through the document in this order.
Each part ends with the operator's review: show the part, then ask `AskUserQuestion`
`Approve <part>?` (`Yes` / `No`). On `No`, ask what to change, revise, and show only what changed.
An approved part reopens only when a later answer contradicts it; say which, and review it again.

1. **§1 System Architecture** — ask how the operator sees the system splitting, then draft the
   components and the diagram. Every §4 capability in `PRD.md` lands in at least one component.
2. **§2 Data Design, then §3 Data Flow & Interactions** — questions first (what is stored, who
   owns it, what happens in each workflow and when a step fails), then the draft.
3. **§6 Integration Points** — from `PRD.md` §10, one integration at a time.
4. **§7 Security Posture & Data Classification** — from `PRD.md` §7 and §11: classify each data
   category, then the auth model, encryption, trust boundaries, compliance and threats.
5. **§8 Non-Functional Approach** — every remaining `PRD.md` §7 requirement by ID.
6. **§5 Implementation Conventions** — last, because the conventions follow from the structure.
7. **§4 Key Design Decisions** — collected as they are made in parts 1–6, reviewed together at the
   end.

### Possibilities

When a structural choice is open, offer two or three possible designs as an `AskUserQuestion`
choice: print each in chat first with what it buys and what it costs, label each option
`Possibility: …`, and mark none `(Recommended)`. The operator's pick, or their own answer through
`Other`, is the decision; the options not picked are its alternatives rejected in §4. This is the
runner's exception for this step (Asking The Operator, open answers). Never record a decision the
operator did not make or confirm.

### Attack round

Before §1–§3 and §7 are each reviewed, ask two or three pointed questions against the draft, one
per message, each naming the requirement or component it attacks
(`PRD-012: what happens to an order when the payment service times out?`). Aim at failure of a
component or integration, load at the §7 targets, data loss, a compromised component and a
change the design would make expensive. Fold each answer into the section, §4 or §8, and say
which.

### Numbers

Every number in the document (capacity, latency, retention, recovery time) comes from `PRD.md`,
cited by `PRD-NNN`, or from the operator. No guessed numbers: being told to pick any number is not
a number; say so and ask once more. A structural answer that needs a number nobody gives is
written without it and listed in the PR body under **Open numbers**.

### Challenges

- Apply the Architect challenge sequence (`roles/solution-architect.md`) to every decision: scope
  fit, decision completeness (alternatives and trade-offs), blast radius.
- Every component and decision traces to at least one `PRD-NNN`. A structure that serves no
  requirement is gold-plating: say so, and leave it out unless the operator names the requirement.
- A design that needs behaviour `PRD.md` does not state, or contradicts it, is a scope conflict.
  Never write it in silently and never edit `PRD.md`: record it in the PR body under **Scope
  conflicts**, for a `PRD.md` update through `/cuevik-docs:update` first (Product Owner
  co-review, `roles/product-owner.md`).
- When an answer names a product, language, framework, library or version, write the kind of
  thing it is (a relational store, a message queue), and keep the product for the PR body under
  **Deferred to Tech Stack**.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add four lists, one
line per item, `None` when empty:

- **Deferred to Tech Stack** — products, languages and versions named during the interview, for
  `04-tech-stack`.
- **Deferred items answered** — each item from the 01 and 02 **Deferred to the Architect** lists:
  where the document answers it, or that it went to Tech Stack, or why it was not adopted.
- **Scope conflicts** — designs that need a `PRD.md` change first.
- **Open numbers** — structural answers still waiting on a number.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.
The Architect reviews all of it; the Product Owner reviews scope only (the last two items).

- [ ] Output matches the template skeleton — header block, all eight sections in order, and the
      references table present; no top-level section added or removed, and no `[placeholder]`
      left unfilled.
- [ ] Every major component is named with its responsibility and the `PRD-NNN` it serves.
- [ ] At least one diagram is present (`mermaid` or `text`).
- [ ] Every key design decision names the alternatives rejected and the trade-off, not just "we
      chose X".
- [ ] Every structural choice traces to at least one requirement in `PRD.md`: no gold-plating.
- [ ] §7 names the data classifications, the auth and authorization model, encryption at rest and
      in transit, and the trust boundaries.
- [ ] Each compliance requirement in `PRD.md` is named in §7 with its architectural answer, not
      deferred.
- [ ] Every `PRD.md` non-functional requirement is answered structurally in §7 or §8, by ID.
- [ ] No technology inventory (that is `TECH-STACK.md`) and no code.
- [ ] (Product Owner) The architecture neither contradicts nor widens the scope in `PRD.md`; any
      conflict is listed under **Scope conflicts**, not resolved in this document.
- [ ] (Product Owner) Every `PRD.md` §4 capability lands in at least one component.
