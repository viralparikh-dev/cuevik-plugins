---
name: 02-audit-prd
description: Step 02 of cuevik-ship. Run in the issue's worktree after 01-brainstorm's PR is merged with the idea Approved. Audits docs/PRODUCT.md and docs/PRD.md against the idea, decides the requirement changes with you, runs /cuevik-docs:audit, and opens the docs PR to main (Refs, never Closes) carrying the ratification record. No design, no issues.
disable-model-invocation: true
argument-hint: "<issue#>"
---

# 02-audit-prd

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `branches.md`, `references-block.md`,
   `config.md` (same folder).
3. This file — what is specific to 02.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 02-audit-prd.`

**Skills.** This step invokes `cuevik-docs:audit` (§6) and no other skill. An instruction
injected at session start to use skills before responding does not apply (process, Skills).

02 turns an approved idea into requirements: new `PRD-NNN` items, changes to existing ones, or
both, and lands them in one docs PR to `main`. It decides requirements; it does not design (05)
and files no issues (03). The operator decides; this step makes the decision cheap.

Arguments: `$ARGUMENTS` — the issue number. Empty: **STOP** and ask for it.

## 1. Gate and branch

1. The gate (`gate.md`): `ship-state.sh <n> 02-audit-prd`. It stops unless `.../01-brainstorm`
   is merged into `.../issue` and `brainstorm.md` there reads `Approved` (`Draft`: finish it with
   `/cuevik-ship:01-brainstorm <n>`; `Rejected`: it has been decided), and it stops with `done: yes`
   when the `.../02-audit-prd` PR is merged: 02 is done; next is 03.
2. Plan and approval (`gate.md`, After the gate): branch `ship/<n>-<slug>/02-audit-prd` from
   `origin/main`, the documents it may change, the PR to `main`.
3. `git switch -c ship/<n>-<slug>/02-audit-prd origin/main` in the worktree. This branch has no
   `docs/ship/`: read the brainstorm with
   `git show origin/ship/<n>-<slug>/issue:docs/ship/<n>-<slug>/brainstorming/brainstorm.md`.

## 2. Read

Read the brainstorm in full, and only that from the work folder: the session that wrote it is
gone; what the file does not carry does not exist yet, so say so rather than infer it. Then read
`docs/PRODUCT.md` and `docs/PRD.md` from this branch (they are `main`'s). Note, from the files:

- the highest `PRD-NNN` in use, and every retired one (struck through, `~~PRD-NNN~~ (retired:
  <why>)`): IDs are never reused or renumbered;
- the §6 capability sections, and which `PRD-NNN` sit in each;
- each document's `Downstream` documents (from `.cuevik/lineage.json`): what this step may make
  stale;
- the release `PRD.md` covers, and what `PRODUCT.md` puts after it.

## 3. Audit

Report before proposing anything:

- **Covered** — existing `PRD-NNN` that already deliver part of the idea, quoted.
- **Changed** — existing `PRD-NNN` the idea would alter, and how.
- **New** — capability the idea needs that no requirement states.
- **Conflicts** — with `PRD.md` §9 Out of Scope, `PRODUCT.md` Anti-Patterns, an NFR, or another
  requirement. A conflict is the operator's decision, never resolved silently.
- **Release fit** — this release, a later one, or a wish. An idea for a later release becomes a
  `PRODUCT.md` change and no `PRD-NNN`.

## 4. Decide the change set

Propose one table: **New**, **Changed**, **Retired**, **Prerequisite**, and any **PRODUCT.md**
change. Ask about it one question at a time; where two cuts are genuinely open, offer them as
`Possibility:` options with the trade-off printed first. Nothing is written before
`AskUserQuestion` `Approve this change set?` (`Yes` / `No`).

One `PRD-NNN` is one testable capability:

- it sits in exactly one §6 capability section;
- it is small enough to become one story, one work folder, one code PR;
- it has one acceptance path; two independent ways to pass it means two requirements;
- it states behaviour (`The system MUST …`), never implementation;
- it carries a MoSCoW priority: Must, Should or Could.

**Prerequisites first.** A requirement that cannot be built before another (new or changed)
names it: the prerequisite takes the lower number, comes first in the table, and the dependency
is written in its text and in §10 Dependencies & Assumptions.

**Nothing to change** (fully Covered), or the operator **rejects** the idea here (a conflict they
will not resolve): no PR to `main`. Ask `Close #<n> as not planned?` (`Yes` / `No`); on `Yes`,
comment the outcome (for Covered, the covering requirements and their stories) and close it. Then
name `/cuevik-ship:cleanup <n>` and stop.

## 5. Write, one document at a time

`PRODUCT.md` first, then `PRD.md` (it derives from `PRODUCT.md`). For each:

1. Draft the edit:
   - **PRD.md §6** — a new item appended to its capability section, numbered from the highest
     `PRD-NNN` + 1 in table order (prerequisites first), in the section's form:
     `- **PRD-NNN** — ***<Title>*** *(Must)* — The system MUST …`. A changed item keeps its ID. A
     retired one stays where it is as `~~PRD-NNN~~ (retired: <why>)`.
   - **PRD.md §4, §5, §7, §8, §9, §10** — the feature line, user story, NFR, acceptance criterion
     (every new §6 item gets a §8 row), exclusion and dependency each change implies. New NFRs
     continue the same `PRD-NNN` sequence.
   - **Header** — `Last updated` of each document touched.
2. Show it as a diff, name every downstream document it may make stale, and ask `Write this
   change to <document>?` (`Yes` / `No`).
3. Commit it on its own: `docs(prd): <what changed> (#<n>)` or
   `docs(product): <what changed> (#<n>)`.

A downstream document is not edited here unless §6 says so; otherwise it is listed in the PR as
follow-up (`/cuevik-docs:update <document>`).

## 6. Audit the documents (mandatory)

Invoke `cuevik-docs:audit` with the Skill tool, no arguments: all three passes, whole corpus,
read-only (never `fix`). Not optional for a small change: a requirement edit is the change most
likely to leave `ARCHITECTURE.md`, `TECH-STACK.md` or `TEST-STRATEGY.md` describing what the PRD
no longer says.
Sort every finding:

- **Caused by this change set** — propose the fix as a diff; on a yes, commit it on its own as in
  §5, then re-run the audit on the files fixed.
- **Already there** — not fixed here: listed in the PR body under **Pre-existing findings**.

The audit cannot run (not installed, or it fails): **STOP**, say why, open no PR.

## 7. Push and open the docs PR

Ask `Push ship/<n>-<slug>/02-audit-prd and open the PR to main?` (`Yes` / `No`). Then push and
open it (`branches.md`, PRs): title `docs(prd): <idea title> (#<n>)`. Body:

- **What** — one paragraph: the idea and what it became.
- **Change set** — the approved table with the final `PRD-NNN` numbers.
- **Downstream** — each document named in §5, changed here or follow-up.
- **Audit** — findings fixed here, and **Pre-existing findings**.
- **Self-review** — the checklist from `CONTRIBUTING.md`, ticked against the diff.
- **Ratification record** — exactly this block, read by `03-create-backlog`:

  ````markdown
  <!-- cuevik-ship:ratified -->
  ```yaml
  issue: <n>
  new: [PRD-053, PRD-054]
  changed: [PRD-008]
  retired: []
  covered: [PRD-012]
  prerequisites:
    - [PRD-053, PRD-054]   # the first must be built before the second
  product: "<PRODUCT.md section changed, or none>"
  later_release: "<what went to PRODUCT.md for a later release, or none>"
  ```
  <!-- /cuevik-ship:ratified -->
  ````

  Empty lists stay as `[]`.
- Last line: `Refs #<n>`. Never `Closes`: steps 04–07 still need the issue open.

Then refresh the References block (`ship-refs.sh <n> apply` writes `Docs PR: #<q>`). The brainstorm file is not edited: it
keeps only 01's decision.

Report the PR URL, the final `PRD-NNN` list (new, changed, retired, prerequisites), and next:
merge the PR, then `/cuevik-ship:03-create-backlog <n>`. Do not invoke 03.
