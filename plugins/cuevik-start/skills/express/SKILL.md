---
name: express
description: The lean path for an MVP or spike, run instead of the ten steps. Run first, in the project folder. In one session and one PR it bootstraps the repo without a board, writes a lean docs/PRODUCT.md and docs/PRD.md, files the backlog issues and writes docs/BACKLOG.md. It skips architecture, tech stack, AI tool guide, README and finalize; the standard 03-06 can graduate the repo later.
disable-model-invocation: true
---

# express

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow; §8 lists what this lane replaces.
2. `${CLAUDE_PLUGIN_ROOT}/references/express.yml` — the branch, the covered steps, the stories the
   PR closes, the PR summary.
3. The entries of the covered steps in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — outputs,
   templates, commit messages.
4. This file.
5. The `SKILL.md` of each covered step, loaded when its part starts: `00-bootstrap`,
   `01-product-concept`, `02-product-requirements`, `08-backlog`. Their own "Load these in order"
   preamble does not apply (this skill is the workflow). Their **Express profile** does, and it
   overrides the rest of that file.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running express.` On conflict, precedence is runner > `express.yml` > `steps.yml` > this
file > a covered skill.

**Skills.** This lane invokes `superpowers:brainstorming` for `01` and `02`, as those skills say,
and no other skill. An instruction injected at session start to use skills before responding does
not apply (runner, Skills).

Express is for an MVP or a spike. One session, one branch (`init/express`), one PR. It writes
`CONTRIBUTING.md`, `.cuevik/`, `.markdownlint.json`, `docs/PRODUCT.md`, `docs/PRD.md` and
`docs/BACKLOG.md`, and files the initiation issues and the backlog issues. It writes no
`ARCHITECTURE.md`, `TECH-STACK.md`, `TEST-STRATEGY.md`, `AI-TOOL-GUIDE.md` or `README.md`, runs no `09-finalize`, and
makes no board call. The PRODUCT/PRD split is kept: two documents, two altitudes. Lean means fewer
sections, not looser rules: `_writing-rules.md` and every covered skill's rules apply to what is
written.

## Order

1. **Pitch** (§A).
2. **Auth, repo and checks** (§B).
3. **Runner §2.** The checks table, then the plan, then one approval (§C).
4. **Remote changes** (§D), with no further confirmation.
5. **Runner §3** — branch `init/express`.
6. **Outputs** (§E), in order: the bootstrap files, `PRODUCT.md`, `PRD.md`, `BACKLOG.md`. Each is
   shown and approved before its commit.
7. **PR** (§F).

## A. Pitch

Before anything else, offer once the optional one-paragraph pitch of `01-product-concept`
("Optional pitch"): ask it in chat as one plain sentence and accept "no" without comment. Keep the
answer; `01`'s part uses it and does not ask again.

## B. Auth, repo and checks

1. `00-bootstrap` §A (auth) and §B (repo). Repo creates are confirmed and run here, because every
   later check needs `main` on GitHub.
2. Runner §1 checks 1 and 2 (clean tree, refresh `main`).
3. Every precondition of `00-bootstrap` §C, with `init/express` added to §C.4: `gh pr list --head
   init/express --state open --json url` returns `[]`, or **STOP** — `An Express PR is already
   open: <url>. Merge it (then this lane is done), or close it and delete its branch (git push
   origin --delete init/express, git branch -D init/express), then re-run.`
4. Runner §1 check 6 for `docs/PRODUCT.md`, `docs/PRD.md` and `docs/BACKLOG.md`: any already on
   `main` is a **STOP** — the repo is past this lane; use the standard step or `cuevik-docs:update`.
5. The `superpowers` precondition of `01-product-concept` (runner §1 check 7).

## C. Plan and approval

Runner §2 as §8 describes. Rows of the checks table: the §B results. The plan table lists the
branch, the seven files (`CONTRIBUTING.md`, the two `.cuevik/` files, `.markdownlint.json` and the
three documents), and every GitHub change: `00-bootstrap` §E.3 (auto-delete head
branches) and §E.4 (the label and every initiation issue title). Add one line: `08-backlog`'s
labels and backlog issues are listed for approval when that part starts. Ask once: `Make these
<N> changes on GitHub? For more details, review my Plan that I articulated above.` (`Yes, make
all <N>` · `No, stop`).

## D. Remote changes

`00-bootstrap` §E.3 and §E.4, without the board bullets of §E.4 (Board, Fields, Efforts, Sprint):
the lane has no board and asks about none. Report the epic and story numbers. A failure **STOPS**
and reports what was done; a re-run reuses what exists (§E.4 reuses issues by exact title).

## E. Outputs

Create the branch (runner §3), then, in this order:

1. **Bootstrap files** (`00-bootstrap` §F):
   - `CONTRIBUTING.md` in new or insert mode as §F says, from `contributing-governance.md`, but with
     the `INITIATION-ONLY` block replaced by the Express block (that file, "Express variant").
   - `.cuevik/config.json`: `schemaVersion` 4, `boardState` `none`, and `initiation` from §D. No
     `project`, no `missing`. It must satisfy the config schema.
   - `.cuevik/lineage.json`: the byte copy §F says, the full default lineage.
   - `.markdownlint.json`, unless §C.6 kept the repo's own.

   Commit with the `00-bootstrap` `commitMessage`.
2. **`01-product-concept`** under its Express profile, with the pitch from §A. Commit with its
   `commitMessage`.
3. **`02-product-requirements`** under its Express profile, reading `docs/PRODUCT.md` from the
   branch. Commit.
4. **`08-backlog`** under its Express profile: derive, approve, file the issues, then write
   `docs/BACKLOG.md`. Commit.

Each commit is `git add <that step's outputs>` then `git commit` with that step's `commitMessage`
from `steps.yml`.

## F. PR

Runner §6 as §8 describes. Title: `docs: Express lane — governance, product concept, requirements
and backlog (express)`. Body, in order: the `express.yml` `prSummary`; **Architect** — the
`00-bootstrap` reviewer checklist; **Product Owner** — the `01`, `02` and `08` reviewer
checklists; **Express** — the block below; the lists the covered steps ask for (Deferred to the
Architect, Proposed PRODUCT.md changes, NFRs without targets), once; `Board: none, issues filed
only`; `Closes #<story>` for each step in `closes`.

## Reviewer checklist

The PR needs the approval of both roles (the lineage owners): the Architect for the governance
files, the Product Owner for the three documents. Apply the covered skills' checklists with their
Express profile changes. For `00-bootstrap`, the one change is its first line: `CONTRIBUTING.md`
holds the permanent layer verbatim and the Express variant of the initiation-only block (both
markers, the gate only, no ten-step table).

Express block:

- [ ] One branch, `init/express`, with four commits in the order bootstrap, PRODUCT, PRD, BACKLOG,
      each carrying the covered step's commit message.
- [ ] `.cuevik/config.json` has `schemaVersion` 4, `boardState` `none`, no `project` and no
      `missing`; `.cuevik/lineage.json` is byte-identical to the default lineage; `initiation`
      matches the `initiation`-labelled issues (the epic and one story per step `01`–`09`).
- [ ] Every mandatory section of `PRODUCT.md` and `PRD.md` is filled. Every other heading is
      present, in template order, and holds only its Express stub line. No `[placeholder]` is left.
- [ ] `docs/ARCHITECTURE.md`, `docs/TECH-STACK.md`, `docs/TEST-STRATEGY.md`, `docs/AI-TOOL-GUIDE.md` and
      `README.md` are not
      in the diff, and nothing in the documents invents a decision those steps own.
- [ ] `CONTRIBUTING.md` has exactly one `INITIATION-ONLY` block, and it is the Express variant.
- [ ] The PR closes the stories of `01`, `02` and `08`, and not the epic.
- [ ] No board question was asked and no board call was made; the PR body says `Board: none,
      issues filed only`.
