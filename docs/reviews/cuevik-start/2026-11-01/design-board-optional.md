# Design — Task 8: board optional in both lanes (item #9)

Status: **design settled with the maintainer on 2026-11-04; awaiting explicit approval. Nothing implemented.** Implementation is one PR, branch `feat/00-board-optional`, from `main`. Gated by the plan (Track B).

## Problem
`00-bootstrap` wires a GitHub Projects v2 board through GraphQL/`gh project` calls and relies on board workflows no API can toggle (§E.5, operator-set). A board failure can derail initiation, and `config.schema.json` currently *requires* `project`, so a board-less repo cannot be expressed. Governance (repo, `.cuevik/`, `CONTRIBUTING`, the initiation issues) is the trust boundary; the board is convenience.

## Options considered (config shape)
1. **Optional `project` key only** (absent = no board). Cannot say *partial*, and consumers cannot tell "absent on purpose" from "setup failed".
2. **`board.state` enum with the project facts nested under it.** Consumers branch on one field, but every reader of `project` breaks.
3. **Keep `project`, add sibling `boardState`.** Existing readers keep their path; contradictory combinations are blocked by a conditional schema. **Chosen.**

## Decisions
| # | Question | Decision |
|---|---|---|
| 1 | v2 configs after the bump | **Strict v3.** The schema accepts `schemaVersion: 3` only. No v2 tolerance. |
| 2 | Migration of existing repos | **Documented manual edit**, no new command. cuevik-ship's STOP, the runner's precondition and `status` each print the exact edit. |
| 3 | `partial` detail | **Recorded.** `partial` requires a non-empty `missing` list of fixed part names. |
| 4 | cuevik-ship with `boardState: none` | **Silent skip** of every `gh project` call. |
| 5 | Nudge to add a board (Standard lane) | **No extra prompt at 00.** The bootstrap PR body reports the state; the nudge is at `07` and in `status`. |
| 6 | Adding or repairing a board later | **Documented manual steps** in the config contract README; no flow, no command. |
| 7 | Adapter seam | **New `references/board-adapter.md`**, commands moved verbatim. |

## Design

### 1. Config contract (`contracts/config/`)
- `schemaVersion` const `3`. New required `boardState`: `configured | partial | none`.
- `project` becomes optional; its shape is unchanged.
- New optional `missing`: array, `uniqueItems`, `minItems 1`, items from the fixed set below.
- Conditional schema (`allOf` of `if/then`), so contradictions are unrepresentable:

| `boardState` | `project` | `missing` |
|---|---|---|
| `configured` | required | forbidden |
| `partial` | required | required |
| `none` | forbidden | forbidden |

- `initiation` stays required in every state: the issues are filed without a board and `Closes #<story>` works without one. Only its description changes ("on the board" becomes "on the board, when there is one").
- `missing` parts (fixed set): `link` (board not linked to the repo) · `items` (an initiation issue not added to the board) · `fields` (a value bootstrap tried to set on a field the board has, and the set failed) · `workflows` (a required workflow is off or its Status mapping unconfirmed; required = all seven on a board bootstrap created, `Item closed` on an existing one).
- A field or option the board simply lacks is **not** a `missing` part: it stays a "skipped, said in the PR body" item, as today. Otherwise a deliberate blank board would always read `partial`.
- A board without a single-select `Status` field cannot be recorded (`project.statusField` is required), so it yields `none`, not `partial`.
- Edit order (the contract's own rule): edit `contracts/config/` at the repo root, copy to `plugins/cuevik-start/references/contracts/config/` and `plugins/cuevik-ship/references/contracts/config/` (declared in `contracts/consumers.json`), run `python scripts/check-contracts.py`.

### 2. Board-adapter seam (`plugins/cuevik-start/references/board-adapter.md`, new)
- Six named operations; the existing `gh`/GraphQL commands move into the file **verbatim** from `00-bootstrap` §D/§E, `runner.md` §7 and `07-backlog` §4 (21 call sites today):
  `board.create` (copy or blank, plus the template diff check) · `board.link` · `board.read` (variants: `probe`, `list`, `linked`, `status`, `fields`, `item`, `workflows`) · `board.addItem` · `board.setField` (Status, dates, Item Type, Priority, Size, Efforts, Sprint) · `board.workflows` (read the seven, guide the operator through turning them on).
- Result contract: `ok` · `degraded` (the board is usable, a part did not complete) · `unavailable` (the board cannot be used at all).
- `00`, runner §7 and `07` call operations by name and hold no `gh project` command. `board-template.json` stays the declarative source for the template and is read by `board.create`.
- The seam is per plugin. Plugins cannot share a reference file, so cuevik-ship's seam stays `references/config.md` (§5 below).

### 3. `00-bootstrap`
- Governance core (repo, `CONTRIBUTING.md`, `.cuevik/`, `.markdownlint.json`, auto-delete branches, the initiation issues and their sub-issue links) is unchanged: it STOPs on failure.
- Board failures degrade. Final state is computed at §F: no board recorded → `none`; recorded and nothing degraded → `configured`; recorded and at least one degraded → `partial` with the distinct parts in `missing`.

| Point | Today | After |
|---|---|---|
| §D.2 Projects probe fails | STOP | `unavailable` → `none`; reason in the PR body (a cloud session cannot reach Projects; locally `gh auth refresh -s project`) |
| §D.3 pick or create | pick or create | adds a **No board** choice → `none`, deliberate, not reported as a failure |
| §D.5 no single-select `Status` | STOP | say so and ask §D.3 again (another board, or No board) |
| §E.1 create or copy fails | STOP | `unavailable` → `none` |
| §E.2 link fails | STOP | `degraded` → `partial`, `missing: ["link"]` |
| §E.4 board item-add fails | not specified | `degraded` → `partial`, `missing: ["items"]` |
| §E.4 field, Efforts, Sprint set fails on a field the board has | skip, say so | `degraded` → `partial`, `missing: ["fields"]` |
| §E.5 required workflow off | STOP on "Stop bootstrap" | adds **Skip workflows** (→ `partial`, `missing: ["workflows"]`). **Stop bootstrap** stays, as the operator's own choice. |

- §F writes `boardState`, writes `project` only for `configured`/`partial`, and `missing` only for `partial`. The `schemaVersion` example becomes 3.
- §G PR body: Board line states the state and, for `partial`, the `missing` parts. In the Standard lane, with `none` or `partial`, it adds the repair pointer (contract README). Express's "no push" is Task 9.
- Reviewer checklist: the board line becomes conditional ("names the linked board, ids read from GitHub" only when a board is recorded); add a line that `boardState`/`project`/`missing` agree with reality and with the schema table.
- `description` frontmatter and `steps.yml` `00` `prSummary`/`entries` wording: "and project board" becomes optional. `steps.yml` `summary` and titles are not touched (build_docs derives from them).

### 4. Other cuevik-start consumers
- **`runner.md` §1 check 3** (bootstrap on `main`; the config is read there): `schemaVersion` must be 3, else STOP with the migration line. `bootstrap: true` steps are exempt (they write the file). Inputs §4 also names `boardState`.
- **`runner.md` §2:** the plan lists the §7 board updates only when `boardState` is not `none`.
- **`runner.md` §7:** `none` skips the whole section silently (no report line, nothing in the PR body). `configured` and `partial` behave as today: a failed call is reported and never stops a step. §7 calls adapter operations by name.
- **`07-backlog` §4:** `none` → `AskUserQuestion` `Pause to set up a board` / `Continue without a board`. Pause stops cleanly with the contract README pointer; a re-run reuses the filed issues by exact title (Interview step 1). Continue records `Board: none, issues filed only` in the PR body. `configured`/`partial` add directly through `board.addItem` and `board.setField`; `partial` adds a PR-body line naming `missing`, with no prompt. This replaces Task 5's test ("a `project` object with a board `number`") with `boardState`, and its "Set up a board now" option with "Pause", because setting up a board is now a manual config PR.
- **`status` §3:** keeps the initiation-issue cross-check in every state (it reads issues, not the board). Adds a `**Board:**` line: `none` → `no board (issues only)` plus the repair pointer; `partial` → `partial, missing: <parts>` plus the pointer. `schemaVersion` 2 → one Check line with the migration edit.
- **`cleanup` §3:** `none` skips the End-date section silently.
- **`08-finalize`:** no board reference found; unchanged.
- Plugin `README.md` row for `00-bootstrap`: "Repo and board" becomes "Repo, optional board".

### 5. cuevik-ship (cross-plugin)
- Audit result: ship does **not** hard-require a board. It reads `project` through `references/config.md` only; `gate.md` merely checks the file exists. Board calls already skip and report on failure.
- `references/config.md`: add the `boardState` rule. `none` → skip every `gh project` call silently, in local and cloud sessions alike. `configured` and `partial` → as today (a missing part is skipped and reported by the existing per-call rules; `missing` is informational, for `status` and humans). Source-table row for `project` becomes conditional.
- `references/config.md` line 12 (schema failure → STOP) gains the v2 migration message.
- One-line pointers to the rule in `skills/03-create-backlog` §5 (Board bullet) and `skills/07-execute-plan` gate 3 / §2.1. Skills 01, 04, 05, 06 delegate to `config.md` and need no change.
- `README.md`: the prerequisite "`gh` with the `project` scope" becomes "when the repo has a board".

### 6. Migration v2 → v3 (documented manual edit)
Every v2 config has `project`, so the mapping is deterministic. Operator opens a PR on `.cuevik/config.json`: set `"schemaVersion": 3` and add `"boardState": "configured"`; leave `project` and `initiation` as is. Documented once, in the contract README ("Migrating from schemaVersion 2"); the three STOP/Check messages quote it.

### 7. Adding or repairing a board later (documented manual steps)
Contract README section: create or link the board by hand, read the ids with the `gh` commands already in the README, add the initiation issues to the board, then open a PR on `.cuevik/config.json` that adds `project`, sets `boardState`, and sets or clears `missing`. This is the target of every nudge.

## Implementation notes (found while building; no design decision changed)
- The runner reads the config in §1 check 3, not check 4; the design text above is corrected.
- `board.read` gained an `id` variant (the board node id for `project.id`), so no `gh project` command stays in `00` §F.
- `status` ends with "Do not suggest fixes"; that rule now allows the Next line and the pointer inside a `**Board:**` or migration line.
- `cuevik-ship` skills `01-brainstorm` and `04-plan-intent` list "the board item" in their plans; both now say "when the repo has a board". `07-execute-plan` §2.1 also skips silently for `none`.
- Left as found, flagged in the PR: the runner's item lookup returns only `.id` while Step start reads its `.status`.

## Out of scope
- Express lane behavior and a `lane` field: Task 9. (Task 8 only guarantees `none` is valid everywhere.)
- `docs/guides/` Walkthrough wording ("the board is required", lines on board setup): not edited here. Guide PDFs are refreshed only in Tasks 9 and 10, so the board wording is carried into Task 9's guide pass.
- Plugin version bumps: a release decision, not made here.
- Live dry-run: the plan names none for Task 8. Optional on the sandbox if requested at approval; the cheap trigger for the degrade path is bootstrapping with a token lacking the `project` scope.

## Touch-list
- `contracts/config/{config.schema.json,config.example.json,README.md}` and the two plugin copies.
- `plugins/cuevik-start/references/board-adapter.md` (new) · `references/runner.md` (§1, §2, §7) · `references/steps.yml` (`00` wording only) · `skills/00-bootstrap/SKILL.md` · `skills/07-backlog/SKILL.md` · `skills/status/SKILL.md` · `skills/cleanup/SKILL.md` · `README.md`.
- `plugins/cuevik-ship/references/config.md` · `skills/03-create-backlog/SKILL.md` · `skills/07-execute-plan/SKILL.md` · `README.md`.
- Unchanged: `references/board-template.json`, `08-finalize`, `docs/guides/`.
- No docs-build (no command or step change).

## Verification
- `python scripts/check-contracts.py` passes (example valid, three copies identical).
- Schema cases, run from a scratch script, not committed: valid `configured`, `partial` with `missing`, `none`; invalid `none` with `project`, `partial` without `missing`, `configured` with `missing`, `schemaVersion` 2, unknown `missing` value.
- `steps.yml` parses; every `references/…` and `§` cross-reference in the edited files resolves.
- Mechanical move check: every `gh project` / `gh api graphql` command in the pre-change `00-bootstrap`, `runner.md` and `07-backlog` appears in `board-adapter.md`, and none remains outside it in cuevik-start.
- No remaining Task 5 test ("`project` object", "Set up a board now") in cuevik-start.
- Reviewer checklists of `00-bootstrap` and `07-backlog` updated and re-read against the change.
- Global constraints: `_writing-rules.md` untouched; no personal, company, client or employer names; no guessed numbers or versions.

## Resolved questions
1. `schemaVersion` 3, strict; migration is a documented manual edit.
2. `partial` records `missing`.
3. cuevik-ship does not hard-require a board; `none` is a silent skip.
4. No prompt at `00`; the nudge is at `07` and in `status`.
