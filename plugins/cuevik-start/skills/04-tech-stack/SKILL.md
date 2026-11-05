---
name: 04-tech-stack
description: Step 04 of cuevik-start. Run once 03-architecture's PR is open or merged, in the same session as 03 or a new one in the project folder. Picks each technology with the Architect against its alternatives, pins its version, and opens a PR adding docs/TECH-STACK.md plus the tooling layer of CONTRIBUTING.md (versions, install, run, test, lint and build commands, hooks) using only the approved technologies.
disable-model-invocation: true
---

# 04-tech-stack

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `04-tech-stack` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   template, commit message, PR summary, special actions.
3. This file — what `docs/TECH-STACK.md` and the tooling layer must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 04-tech-stack.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (runner, Skills).

`docs/TECH-STACK.md` lists every approved technology with its version, its reason and what it may
be used for. It is the gate for adding anything new: a tool not listed here is not used. It
records choices and limits, not how the parts are wired together (`docs/ARCHITECTURE.md`).

## What This Document Covers

The template (`TECH-STACK.template.md`) owns the headings and their order. This list owns what
each section must contain. Fill every section; add or drop none.

1. **Languages & Frameworks** — each with a pinned version, a one-line reason, and the
   `PRD-NNN` (or `ARCHITECTURE.md` component) it serves.
2. **Datastores** — one per storage kind in `ARCHITECTURE.md` §2, with version, the data it
   holds and why it fits.
3. **Cloud & Infrastructure Services** — the hosting and platform services relied on, each with
   purpose and its region, tier or limit.
4. **Key Libraries / Tools** — the dependencies a developer must know about (not every transitive
   one), each with version and its scoped purpose, including the formatter, linter and test
   tools the tooling layer uses.
5. **Selection Trade-offs** — every major choice, the alternatives rejected and why it won.
6. **Versions & Constraints** — pinned and minimum versions, supported platforms, licence limits,
   and the usage rules that cut across tools (e.g. "no second HTTP client").

Every Reason or Used-for cell scopes the technology to its purpose, so it reads as a usage rule:
`Server-side rendering only`, not just `Popular`.

## Interview

Ask open questions as one plain sentence in chat, not with `AskUserQuestion` (runner, Asking The
Operator, open interview questions). Confirmations and choices use `AskUserQuestion`.

At runner §4, read `docs/PRD.md` from `main`, `docs/ARCHITECTURE.md` from `main` (or, while the
`03-architecture` PR is still open, from its branch — runner §1 check 5), and the body of the
`03-architecture` PR, merged or open:
`gh pr list --head <branch> --base main --state all --json number,body --jq '.[0]'`, branch
from `steps.yml`. Its **Deferred to Tech Stack** list is the starting point: the products the
operator already named.

Summarize first, in a short table, what needs a technology: each `ARCHITECTURE.md` component and
storage kind, each integration, and the `PRD.md` §7 and §11 items that limit the choice (hosting,
licence, compliance, team skills). Then go section by section in template order. Each section
ends with `AskUserQuestion` `Approve <section>?` (`Yes` / `No`); on `No`, ask what to change and
show only what changed.

### Choosing a technology

- A technology the operator already named (the Deferred list, or now): ask what else was
  considered and why it lost, for §5.
- An open choice: offer two or three candidates as an `AskUserQuestion` choice. Print each in
  chat first with what it buys and costs against this project's requirements, label each option
  `Possibility: …`, and mark none `(Recommended)`. The operator's pick, or their own answer
  through `Other`, is the choice; the others go to §5 as alternatives rejected. This is the
  runner's exception for this step (Asking The Operator, open answers).
- Apply the Architect challenge sequence (`roles/solution-architect.md`): scope fit, alternatives
  and trade-offs, blast radius. A tool that maps to no requirement or component is speculative:
  say so, and leave it out unless the operator names what it serves.
- A choice that needs a structural change to `ARCHITECTURE.md`, or behaviour `PRD.md` does not
  state, is not written in here: list it in the PR body under **Upstream changes needed**. Never
  edit an upstream document in this step.

### Versions

Every version comes from the operator, or from the technology's own release page or package
registry read in this session after the operator says yes. Never write a version from memory: it
is likely stale. Pin exact versions for runtimes and frameworks (`20.11.1`, `16.x` only where the
operator wants a range, written as such in §6).

## Tooling layer (`CONTRIBUTING.md`)

After `TECH-STACK.md` is approved, run the `steps.yml` special action: append the tooling layer to
`CONTRIBUTING.md` from `main`.

- **STOP** if `CONTRIBUTING.md` on `main` already contains `<!-- BEGIN TOOLING-LAYER -->`: the
  layer exists; revise it with `/cuevik-docs:update CONTRIBUTING.md`.
- Keep every existing line verbatim, the `INITIATION-ONLY` block included. Append at the end of
  the file, after one blank line:

  ````markdown
  <!-- BEGIN TOOLING-LAYER -->
  ## Tooling

  Approved technologies and versions: [docs/TECH-STACK.md](docs/TECH-STACK.md). Do not add a tool
  that is not listed there.

  ### Versions

  - [runtime / language] [version], matching TECH-STACK.md §6

  ### Commands

  ```sh
  [install command]
  [run command]
  [test command]
  [lint command]
  [build command]
  ```

  ### Hooks

  - [formatter / linter / commit-time check and when it runs]
  <!-- END TOOLING-LAYER -->
  ````

- Ask each command as an open question (`How do you run the tests?`). Every tool in a command is
  listed in `TECH-STACK.md`; a command naming any other tool is not written. A command the
  operator does not know yet (no code exists at initiation) is written as
  `Not set yet: <what is missing>`, never guessed, and listed in the PR body under
  **Commands not set yet**. A hook not wanted: `None`.
- These commands are not run in this step: the repo has no code yet. `07-readme` reuses them.
- Show the diff of `CONTRIBUTING.md` and ask `Approve the tooling layer?` (`Yes` / `No`).

The `TOOLING-LAYER` markers let `09-finalize` and `/cuevik-docs:update` find the layer; never
remove them.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add three lists, one
line per item, `None` when empty:

- **Deferred items answered** — each item from 03's **Deferred to Tech Stack** list and where
  `TECH-STACK.md` answers it, or why it was not adopted.
- **Upstream changes needed** — choices that need an `ARCHITECTURE.md` or `PRD.md` change first.
- **Commands not set yet** — tooling commands left as `Not set yet`.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template skeleton — header block, all six sections in order, and the
      references table present; no top-level section added or removed, and no `[placeholder]`
      left unfilled.
- [ ] Every technology has a version and a one-line reason, scoped to its purpose.
- [ ] Every technology maps to at least one `PRD.md` requirement or `ARCHITECTURE.md` component:
      no speculative additions.
- [ ] Every major choice names its alternatives rejected in §5.
- [ ] No wiring or integration detail: that belongs in `ARCHITECTURE.md`.
- [ ] `CONTRIBUTING.md` ends with the tooling layer between the `TOOLING-LAYER` markers:
      versions, install, run, test, lint and build commands (or `Not set yet`), hooks; every tool
      in it is in `TECH-STACK.md`.
- [ ] The rest of `CONTRIBUTING.md`, including the `INITIATION-ONLY` block, is unchanged.
