# Design — Task 9: Express lane `/cuevik-start:express` (item #4)

Status: **design settled with the maintainer on 2026-11-04; awaiting explicit approval. Nothing implemented.** Implementation is one PR, branch `feat/express-lane`, from `main`. Task 8 (board optional, #63) and Task 2 (pitch-seeded strawman, #55) are merged.

## Problem
The full path is nine gated steps and nine PRs. For an MVP or spike that is heavy. Offer a one-session, one-PR lean path that reuses the existing step skills.

## Options considered
1. **`--express` flag on each step.** Touches every skill, spreads lane logic through all of them, easy to mis-gate.
2. **Separate orchestrator command `/cuevik-start:express`.** One new skill sequences lean variants of `00`, `01`, `02`, `07` in one session and one PR; the step skills are reused, not forked. **Chosen** (agreed in the plan).
3. **A second `steps.yml` profile** switched by the runner. Cleanest data model, but changes runner semantics for every step.

## Decisions
| # | Question | Decision |
|---|---|---|
| 1 | How is an Express repo recognized after its PR merges | From a **merged `init/express` PR**. No `lane` field in `config.json`, so no `schemaVersion` bump and no second migration. |
| 2 | Lineage | The **full default lineage, byte copy**, exactly what `00` writes. No reduced variant, no graduation merge rule. |
| 3 | Initiation issues | **Same as standard**: epic plus one story per step `01`–`08`, by the unchanged `00` logic. The Express PR closes the stories for `01`, `02`, `07`. The epic and the other stories stay open. |
| 4 | Lean sections | **PRODUCT mandatory:** 1 Overview, 2 Target Users, 3 Features, 4 Scope, 5 Success Criteria. **PRD mandatory:** 1 Overview, 4 Features/Capabilities, 6 Functional Requirements, 8 Acceptance Criteria, 9 Out of Scope. Every other heading **stays**, with one line `Not covered in the Express lane.` plus the pointer below. |
| 5 | Commits | **One commit per output**, four on `init/express`, each with the covered step's `commitMessage` from `steps.yml`. |
| 6 | Review | **Both roles.** Each document is written in its lineage owner's role; the PR body has one checklist group per role and needs both approvals. |
| 7 | Checklist | **Union of the reused checklists plus an Express block.** |
| 8 | `CONTRIBUTING.md` | Permanent layer plus **one `INITIATION-ONLY` fence holding only the self-review gate** and a one-line `init/express` branch note. No nine-step table. |

Why 4 differs from the proposal: `07` sources an epic's user value from `PRD.md` §4 and its product goal from `PRODUCT.md` §3, so the proposed list (without them) would have broken `07`. The runner forbids removing top-level sections, hence stubs, which also keep section numbers valid for `07` and the audit.
Why 1 and 2 differ from the plan: a `lane` key would force another strict migration; and `00` already copies a lineage whose documents do not exist yet, so a reduced one buys nothing.

## Design

### 1. Command and files
- `skills/express/SKILL.md` (new; `disable-model-invocation: true` like the other skills). The skill name is the command.
- `references/express.yml` (new; a separate file because `status` and `build_docs` treat every `steps.yml` entry as one of the nine steps with branch `init/<id>`): `branch: init/express`; `covers` in order `00-bootstrap`, `01-product-concept`, `02-product-requirements`, `07-backlog`; `prSummary`; `finalReminder`; the stories it closes (`01`, `02`, `07`, never the epic). Commit messages are read from the covered steps' `steps.yml` entries, not restated.
- `references/contributing-governance.md` gains an Express variant of the initiation-only block, between its own markers (decision 8). Express writes the standard text with that block swapped in. The self-review gate bullets are identical in both blocks.

### 2. Flow (one session)
1. Ask for the optional one-paragraph pitch first; it is `01`'s strawman entry (Task 2). No pitch: `01` behaves as it does today.
2. Checks once: runner §1 checks 1 and 2, the `00` bootstrap preconditions (§C, including "not already bootstrapped" and no open `init/express` PR) and, for each of `docs/PRODUCT.md`, `docs/PRD.md`, `docs/BACKLOG.md`, check 6 (not already on `main`; if it is, use the standard step or `cuevik-docs:update`). Checks 3, 4, 5 do not apply.
3. One plan and one approval (runner §2): the branch, the files, and every change on GitHub (repo create or connect, label, the issues, `07`'s labels and backlog issues, the auto-delete setting).
4. Bootstrap part, reusing `00`: §A, §B, §C, §E.3, §E.4, §F. §D, §E.1, §E.2, §E.5 are skipped: `boardState` is `none` without a question. `config.json` is `schemaVersion` 3, `boardState: none`, `initiation`; no `project`, no `missing`. Lineage is the byte copy. `.markdownlint.json` as in `00`.
5. Branch `init/express` from `main`. Commit 1: bootstrap files.
6. `01` under its Express profile, commit 2 (`docs/PRODUCT.md`). `02`, commit 3 (`docs/PRD.md`). `07`, commit 4 (`docs/BACKLOG.md`); it files the backlog issues as it does today. Upstream documents are read from the working branch, not `main` (runner §1 check 5 reads `main` for the standard steps only).
7. One push on approval and one PR to `main`. Body: `prSummary`, the reviewer checklists (decision 6 and 7), and `Closes #<story>` for `01`, `02`, `07`. `00` has no story; the epic is never closed.

### 3. Runner (`runner.md`)
- New **§8 Express Lane**: a table of which sections the `express` skill replaces (§0 session boundary lifted for the four covered steps; §1 as in flow step 2; §2 one plan; §3 branch `init/express`; §5 four commits; §6 one PR with the body above; §7 not applicable, `boardState` is `none`).
- **§1 check 4**, a second special case, distinct from the `03`+`04` one: a covered step with no `init/<id>` PR passes if a **merged `init/express` PR** exists. This is what lets standard `03` run after Express.
- Graduation: standard `03`–`06` find their lineage entries (full lineage) and stories (decision 3) and read `PRODUCT.md`/`PRD.md` from `main` as usual. Standard `01`, `02`, `00` stop at their existing "already final" / "already bootstrapped" checks. `08` finds the fence it requires (decision 8) and, as in any repo, still needs its upstream documents, so it follows `04`.

### 4. Express profiles in the reused skills
- `01`, `02`: a short **Express profile** listing the mandatory sections (decision 4), the stub line for the rest, and which checklist lines apply (the mandatory sections only; every other section must be exactly the stub line). Stub lines: `Not covered in the Express lane. Add it with /cuevik-docs:update docs/PRODUCT.md.` and the same for `docs/PRD.md`. The two-altitude PRODUCT/PRD split is kept. `_writing-rules.md` applies to everything written.
- `07`: no board prompt in Express (`boardState` is `none`; PR body says `Board: none, issues filed only`). `BACKLOG.md` is written as today: the frozen snapshot of what Express filed.
- `00`: a short note that Express drives §A–§C, §E.3–§E.4, §F and skips the board sections; §G and the checklist are replaced by the Express PR body.

### 5. `status`
- Reads `gh pr list --head init/express --base main --state all`.
- Merged: rows `00`, `01`, `02`, `07` are `✓ merged`, Detail `express PR #n`. Open: `⟳ PR open`, `express PR #n`. The rows for `03`–`06`, `08` are unchanged (`— not started`). The `08` file check fails while the fence stands, so there is no false mismatch.
- Next line for an Express repo: `Express lane complete. To graduate, /cuevik-start:03-architecture in a new session; optional.`
- The Task 8 `**Board:**` line is not printed for an Express repo (no push). The initiation-issue cross-check is unchanged: stories `03`–`06`, `08` and the epic are open and their rows are not merged, which agrees.
- `cleanup` needs no change: it already treats any `init/*` branch like a step branch.

### 6. Express block in the PR reviewer checklist
- One branch `init/express`, four commits in the order bootstrap, PRODUCT, PRD, BACKLOG, each with the covered step's commit message.
- `config.json`: `schemaVersion` 3, `boardState: none`, no `project`; `lineage.json` byte-identical to the default; `initiation` as `00` writes it.
- Every mandatory section filled; every other heading present, in template order, holding only the stub line; no `[placeholder]`.
- `docs/ARCHITECTURE.md`, `TECH-STACK.md`, `AI-TOOL-GUIDE.md`, `README.md` are not in the diff.
- `CONTRIBUTING.md`: permanent layer, exactly one `INITIATION-ONLY` fence holding the gate only.
- The PR closes stories `01`, `02`, `07`; not the epic.
- No board prompt was asked; the PR body says `Board: none, issues filed only`.

### 7. Docs
`build_docs.py` requires every skill on disk to appear in the Walkthrough's "What each command does" table and every non-step command in "Branches and files". So the Walkthrough gets an `express` row in both, an Express section under section 5, and the board-optional wording Task 8 left behind (the bootstrap Board and Remote changes bullets, the `config.json` line, the troubleshooting rows). `python docs/guides/build_docs.py --write` runs once in this PR; its output, including the PDFs, is committed. Plugin version unchanged.

## Implementation notes (found while building; no decision changed)
- Runner header and §0 name the lane as the second one-session exception; the `status` skill also loads `express.yml` and stops if it is missing.
- `status` and the runner read the lane's branch from `express.yml`; only the lane's skill, `express.yml` and the Express block name `init/express`.
- `00-bootstrap` §C.4 is extended in the lane's skill with a check for an open `init/express` PR; `00`'s own text is unchanged there.
- Docs build: the Overview may not use "pull request" (its internal-term check), and a long Writes cell made the commands PDF table overflow, so both rows were shortened. The generated `cmd-cuevik-start-express` block was added to the Walkthrough.
- The board wording Task 8 left in the Walkthrough (prerequisites, the config.json line, the bootstrap Board, Remote changes and Initiation issue bullets, `07`, `status`, `cleanup`, the ship board bullets, troubleshooting) is updated in this PR.

## Out of scope
- `cuevik-ship`, `cuevik-docs`: no change. Ship's gate needs only the two `.cuevik/` files; the audit already treats an unwritten lineage document as "initiation in progress".
- TEST-STRATEGY and the renumber: Task 10. It must then rename the step ids used in `express.yml`, the skill, the guides and the Express block.
- A board in Express: not offered. An operator adds one later through the documented manual steps (config contract README).

## Touch-list
- New: `skills/express/SKILL.md`, `references/express.yml`.
- Modified: `references/runner.md` (§1 check 4, new §8) · `references/contributing-governance.md` · `skills/00-bootstrap/SKILL.md` (note) · `skills/01-product-concept/SKILL.md` · `skills/02-product-requirements/SKILL.md` · `skills/07-backlog/SKILL.md` · `skills/status/SKILL.md` · `plugins/cuevik-start/README.md` · `docs/guides/Cuevik-Plugins_Walkthrough.md` (and `Overview.md` if it lists commands) · the `build_docs.py --write` output (`.html`, `.pdf`).
- Unchanged: `steps.yml`, the config and lineage contracts and their copies, `board-adapter.md`, `cleanup`, `08-finalize`, `cuevik-ship`, `cuevik-docs`.
- Docs build: yes (new command).

## Verification
- `python scripts/check-contracts.py` still passes (no contract change); `steps.yml` and `express.yml` parse.
- Each reused skill's reviewer checklist, plus the Express block, re-read against the change; every `§` and file reference in the new text resolves.
- Mechanical: the Express fence has exactly one `INITIATION-ONLY` pair and its gate bullets equal the standard block's; no covered step id is hard-coded outside `express.yml` and the runner's special case.
- `python docs/guides/build_docs.py --write`, then `--check`, pass; PDFs committed.
- A live Express run needs an un-bootstrapped disposable repo (the existing sandbox is already bootstrapped). Decision requested at approval.
- Global constraints: `_writing-rules.md` untouched; no personal, company, client or employer names; no guessed numbers or versions.

## Resolved questions
1. Branch `init/express`; one commit per output.
2. The mandatory sections are as in decision 4.
3. Recognition is the merged-`init/express` rule in §1 check 4 and in `status`, separate from the `03`+`04` relaxation.
4. Both roles review.
5. The union of checklists plus the Express block.
