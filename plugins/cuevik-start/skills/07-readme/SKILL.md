---
name: 07-readme
description: Step 07 of cuevik-start. Run once 06-ai-tool-guide's PR is open or merged, in a new session in the project folder. Replaces the repo's README with the project's real entry point, built from the documents before it — overview, key concepts, prerequisites, environment, install, tests, structure — testing every command when code exists, marking setup as pending when it does not, and opens a PR.
disable-model-invocation: true
---

# 07-readme

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `07-readme` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   template, commit message, PR summary, special actions.
3. This file — what `README.md` must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 07-readme.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (runner, Skills).

`README.md` is the entry point for anyone, human or AI, opening the repo cold: what the project
is, how to get it running and how to work on it. It summarizes the documents before it and links
to them; it never restates them.

## No duplication

Two tiers. A value authored in two places drifts, so each value has one home.

1. **Narrative** (Project Overview, Key Concepts): summarize the source document and link to it.
   Never copy its prose, and never reproduce a list or paragraph from it.
2. **Operational values** (prerequisite versions, install / run / test commands) have a single
   source: versions live in `TECH-STACK.md`, commands in the `CONTRIBUTING.md` tooling layer. The
   README never authors one of them itself.
   - **Docs-first:** the README shows a pointer only (a one-line link to the source section),
     with no copied version and no copied command.
   - **Scaffolded:** the README MAY surface the commands, copied verbatim from the `CONTRIBUTING.md`
     tooling layer and verified by running them (below), each section naming that source.
     A README with no run commands is worse for the reader, which is why this is allowed.
     Prerequisite versions stay a pointer to `TECH-STACK.md` in both modes.

The badge row is a display of `TECH-STACK.md` §1 and §3 versions, not an authored value, and is
exempt. `cuevik-docs:audit`'s Absorb lens guards drift that gets through anyway.

## What This Document Covers

The template (`README.template.md`) owns the headings and their order. README is the header-block
exception (`references/templates.md`): no metadata block and no references table; its
**Further Reading** section is the cross-document map. Fill every section; add or drop none.

- **Header block** (under the H1, the project name):
  - **Tagline** — a blockquote that is a verbatim copy of the Vision line in `PRODUCT.md` §1.
    Never paraphrased.
  - **Badge row** — one static shields.io badge per core technology: each language and framework
    in `TECH-STACK.md` §1 that a developer installs or invokes, plus the primary platform in §3.
    A runtime the platform provides gets no badge of its own. Format
    `![<Name>](https://img.shields.io/badge/<Name>-<version>-blue)`, with `-` written `--` and a
    space written `_` inside the name or version. No live-endpoint badges.

1. **Project Overview** — three or four sentences for a developer on what the product does and
   why, then a link to `docs/PRODUCT.md` as the source of truth.
2. **Key Concepts** — three to five terms a developer needs before reading the code: mostly
   structural concepts from `ARCHITECTURE.md` (components, boundaries, data flow, patterns), plus
   only the domain nouns from `PRODUCT.md` §1–§2 that cannot be avoided. Never the `PRODUCT.md`
   §3 feature list.
3. **Prerequisites** — the accounts and access needed before setup, and a pointer to
   `TECH-STACK.md` for every tool and runtime version. No version is written here.
4. **Environment Setup** — how to create the env file, then one table row per variable:
   description, required or optional, where to get the value.
5. **Install & Run** — scaffolded: the install and run commands from the `CONTRIBUTING.md`
   tooling layer, verbatim. Docs-first: a pointer to that layer only.
6. **Run Tests** — scaffolded: the test command from the same layer, verbatim. Docs-first: a
   pointer only.
7. **Project Structure** — every top-level folder with a one-line purpose.
8. **Further Reading** — the template's four links, unchanged.

The footer's `Last updated` is today and `Maintainer` is the document's owner from the lineage.

## Mode: scaffolded or docs-first

Initiation can reach this step before any application code exists, so first decide the mode.
List the files on `main` (`git ls-tree -r --name-only main`) and leave out what initiation wrote:
`docs/`, `.cuevik/`, `.claude/`, `.github/copilot-instructions.md`, `README.md`,
`CONTRIBUTING.md`, `CLAUDE.md`, `.markdownlint.json`, `LICENSE`, `.gitignore`, and any other
adapter path 06 wrote. Show what is left, propose **Scaffolded** if anything is, else
**Docs-first**, and confirm with `AskUserQuestion` (`Scaffolded` / `Docs-first`). The operator's
answer is the mode; state it in the PR body.

- **Scaffolded.** Every command in Environment Setup, Install & Run and Run Tests, and every
  prerequisite check the README names, is run in this session before the commit (`steps.yml` special action), from a clean state, and
  works. A long-running command (a dev server, a watcher) is started, checked to come up without
  an error, then stopped. A command that fails is fixed with the operator or left out and listed
  in the PR body; never presented as working. Environment Setup lists every key of the repo's
  env example file (e.g. `.env.example`) and no key that is not in it; no example file: ask
  whether one should exist, and list the gap in the PR body.
- **Docs-first.** Nothing can be run. Prerequisites, Install & Run and Run Tests hold pointers
  only (see No duplication). Environment Setup is written from the operator and `TECH-STACK.md`
  as the intended setup, and opens with this marker:

  ```markdown
  > **Pending scaffold — unverified.** These steps follow TECH-STACK.md and have not been run
  > yet. They will be tested and corrected when the app is scaffolded.
  ```

  Environment variables come from the operator and `TECH-STACK.md` §6, flagged for checking when
  the scaffold lands. Each pointer section says the commands are pending until the scaffold
  lands. Project Structure lists the folders that exist plus the ones
  `ARCHITECTURE.md` §5 plans, each planned one marked `(planned)`.

A tooling-layer command that reads `Not set yet` is written as that sentence in prose, never as a
command in a code block, in both modes.

## Interview

At runner §4, read every upstream document from `main` and `CONTRIBUTING.md` (its tooling layer).
Draft the whole README from them, each point marked with its source in chat
(`From TECH-STACK.md §1`), then ask only for what they do not give: environment variables and
where to get each value, accounts, and anything the operator says is missing. Show the draft,
revise one section at a time, and approve it with `AskUserQuestion` `Approve README.md?`
(`Yes` / `No`).

- Link to `ARCHITECTURE.md`, `TECH-STACK.md` and `TEST-STRATEGY.md` rather than copying from them. Do not paste a
  version or a command into the draft except as the No duplication rule allows.
- The current `README.md` on `main` is replaced whole (`steps.yml` special actions): name in the
  plan that it is overwritten, and keep none of its boilerplate. Anything in it worth keeping is
  offered to the operator section by section before the draft, not carried over silently.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, add:

- **Mode** — `Scaffolded` or `Docs-first`, and why.
- **Commands run** (scaffolded) — each command and its result; or `None (docs-first)`.
- **Gaps** — commands left out or `Not set yet`, missing env example keys; `None` when empty.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template — tagline and badge row directly under the H1, all eight
      sections in order, **Further Reading** with its four links; no top-level section added or
      removed, and no `[placeholder]` left unfilled.
- [ ] The tagline is the `PRODUCT.md` §1 Vision line verbatim, and the badge row covers the core
      stack (no separate badge for a platform-provided runtime).
- [ ] Project Overview is a condensed summary that links to `PRODUCT.md`.
- [ ] Key Concepts is a developer glossary, not the `PRODUCT.md` feature list.
- [ ] The mode is stated in the PR body and the setup sections match it:
  - Scaffolded: every setup command was run and works from a clean state; every env key is
    documented with where to get its value.
  - Docs-first: Environment Setup opens with the `Pending scaffold — unverified` marker, the other
    setup sections are pointers, and no command is presented as tested.
- [ ] No value is authored in two places: no prerequisite version appears in the README (it points
      to `TECH-STACK.md`), and every command shown traces verbatim to the `CONTRIBUTING.md`
      tooling layer. Docs-first has pointers only, with no copied version or command. Flag any
      duplicate.
- [ ] Project Overview and Key Concepts summarize and link; neither restates source prose.
- [ ] Project Structure has a one-line purpose per top-level folder.
- [ ] No leftover boilerplate from the previous README.
