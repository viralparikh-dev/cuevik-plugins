# cuevik-start Improvements — Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Read this first:** Tasks are split into **Track A (autonomous)** and **Track B (design-gated)**. A session with no human in the loop may implement Track A end to end. **It must NOT implement any Track B task**; for those it produces a design proposal and stops for human review (see Execution Mode). Do not merge any PR — the maintainer merges in the UI.

**Goal:** Apply eleven reviewed improvements to the `cuevik-start` plugin (the project-initiation framework: gated steps `00`–`08` + `status`/`cleanup`, each a Markdown skill driven by `references/runner.md` and `references/steps.yml`), raising content coverage and cutting process friction without weakening its writing discipline.

**Architecture:** `cuevik-start` is a layered prompt framework, not an application. `references/runner.md` is the workflow engine; `references/steps.yml` is step metadata; each `skills/<id>/SKILL.md` is the content contract for one step with a sibling `*.template.md`; `references/contracts/{config,lineage}/*.schema.json` define the generated `.cuevik/config.json` and `.cuevik/lineage.json`; `references/_writing-rules.md`, `_doc-references.md`, `templates.md`, and `roles/*.md` are shared partials. Changes are edits to these Markdown/YAML/JSON files. There is no unit-test suite; correctness is proven by each skill's own **reviewer checklist**, by structural validity (YAML/JSON parse, cross-references resolve), and — where noted — by a live dry-run of the step on a throwaway target repo.

**Tech stack:** Markdown (skills, templates, partials), YAML (`steps.yml`), JSON Schema (config, lineage), a Python docs-build script (`build_docs.py`). No runtime code.

**Spec:** Self-contained — this document carries every decision inline. It derives from an internal Senior-Product-Owner / Enterprise-Architect usage review of `cuevik-start`; the review and its scratch tracker are local-only working files and are **not** required (or present) at execution time.

## Global Constraints

Every task implicitly includes these. A violation fails the task regardless of its own acceptance check.

- **No personal, company, client, or employer names** anywhere in framework content, generated documents, templates, examples, or this plan's outputs. Use role words (operator, maintainer, team) and neutral placeholders only.
- **Preserve all rules in `plugins/cuevik-start/references/_writing-rules.md`.** Load-bearing ones: RFC-2119 keywords for requirements, MoSCoW priorities, measurable/testable statements, **no guessed numbers or versions**, and trace-to-source (nothing invented). New sections and new skills must enforce the same in their reviewer checklist.
- **One PR per task**, branched from `main`, targeting `main`. Branch name given per task. **Never self-merge** — open the PR and stop; the maintainer merges in the UI. Keep local branches until the whole plan is done (no per-task branch deletion).
- **Fold the task's rationale** (the "Why" line) into the PR description.
- **Run the docs build** (`build_docs.py --write`, which refreshes Available/Planned tags) only on a PR that adds or removes a command or step — flagged per task. Commit its output in the same PR.
- **Test target:** a disposable sandbox repo supplied at execution time; never a real project. Broader/organization testing is maintainer-run after merge and is out of scope here.
- Do not create, read, or commit any `*-review.md` or `*-action-items.md` working file; they are git-ignored and may be absent.

## Execution Mode

| Track | Tasks | A no-human session may… |
|---|---|---|
| **A — autonomous** | 1–7 (items #1, #5, #7, #2, #3, #10, #11, #8) | implement fully, one PR each, in listed order, then stop. |
| **B — design-gated** | 8–10 (items #9, #4, #6) | **NOT implement.** For each, write a design proposal in this review folder (`docs/reviews/cuevik-start/2026-11-01/design-<name>.md`) (brainstorm output: options, chosen approach, exact file touch-list, open questions) and stop for human review. These were deliberately gated on an interactive design pass; their key decisions (the board-adapter seam shape, Express scope, and the exact step renumbering) are not settled here. |

Track A tasks touch different files from each other and may each be reviewed and merged independently. Track B task 10 (renumber) must run **after** all Track A step-content changes exist, so it renames the final file set.

## Review Focus

Failure modes the tasks imply but no single acceptance check fully exercises — verify these across the whole change:

- **Board-absent repos:** after #9/#10, every consumer (`lineage`, `07-backlog`, the `08` audit, `status`) must treat an intentionally board-less and/or `BACKLOG.md`-present-but-frozen repo as valid, not a missing-artifact error.
- **Renumber integrity (#6):** after inserting a new step, all cross-references resolve — `steps.yml`, branch names (`init/NN-*`), `.cuevik/lineage.json` nodes, `_doc-references.md` doc-set count, `README.md`, and the per-step initiation issues.
- **Relaxed gate (#3):** when `04` runs before `03` is merged, board/story bookkeeping and the two separate PRs still hold.
- **README non-duplication (#8):** no operational value (prerequisite versions, install/run/test commands) is independently authored in two places; docs-first mode shows a pointer only.
- **Express graduation (#4):** a lean repo that later runs standard `03`–`06` slots the new docs into existing lineage nodes without collision.

---

## Track A — Autonomous

### Task 1 — Stakeholders + Key Assumptions sections in PRODUCT.md (item #1, #5) — PR-1

**Why:** The product doc captures target users but not who sponsors/funds/is affected by the product, nor the riskiest bets it rests on — both are standard discovery outputs and cheap to elicit in the existing `01` interview.

**Files:**
- Modify: `plugins/cuevik-start/skills/01-product-concept/SKILL.md`
- Modify: `plugins/cuevik-start/skills/01-product-concept/PRODUCT.template.md`

**Change:**
- Add a **Stakeholders** subsection: who the project/product's stakeholders are — sponsors/funders/affected parties — explicitly distinct from target users.
- Add a **Key Assumptions & Validation** section: the 3–5 riskiest product/market assumptions, each as *assumption · why risky · cheapest test*. Distinct from PRD delivery assumptions (that stays in `02`). Source answers from the existing interview; invent nothing.
- Extend the skill's reviewer checklist: reject a Stakeholders list that just restates users; reject vague assumptions or lazy "we'll validate later" tests.

**Acceptance:** skill + template still parse as the other steps' do; both new sections appear in the template with guidance; reviewer-checklist lines added; no guessed content introduced. Optional dry-run of `01` on the sandbox yields both sections populated from interview answers only.

**PR:** branch `feat/01-stakeholders-assumptions`; title "feat(01): add Stakeholders and Key Assumptions to PRODUCT.md"; do not merge. (No docs-build: no new command/step.)

### Task 2 — Opt-in pitch-seeded strawman in 01 (item #7) — PR-2

**Why:** Starting `01` from a blank interview is slow when the operator already has a pitch; a *sourced* strawman accelerates it and doubles as the Express entry ramp — without loosening anti-guessing rules.

> May be folded into PR-1 (same skill) if the reviewer prefers one `01` PR; kept separate here because it changes interview behavior, not just adds sections.

**Files:**
- Modify: `plugins/cuevik-start/skills/01-product-concept/SKILL.md`

**Change:** Accept an optional one-paragraph pitch. If given, draft a strawman `PRODUCT.md` whose every statement is traceable to the pitch, then run the normal challenge/interview over it. If absent, behave exactly as today. Preserve every anti-guessing rule — nothing invented, no guessed numbers/versions; unknowns stay explicit gaps. Reviewer checklist: strawman claims must trace to the pitch.

**Acceptance:** with no pitch, behavior unchanged; with a pitch, strawman contains only pitch-sourced claims. Reviewer-checklist line added.

**PR:** branch `feat/01-strawman`; title "feat(01): optional pitch-seeded strawman"; do not merge.

### Task 3 — DDD out-of-scope note in ARCHITECTURE (item #2) — PR-3

**Why:** Readers assume formal domain-driven design is expected; one line sets the boundary.

**Files:**
- Modify: `plugins/cuevik-start/skills/03-architecture/SKILL.md`
- Modify: `plugins/cuevik-start/skills/03-architecture/ARCHITECTURE.template.md` (section 2)

**Change:** Add a one-line note: formal DDD / bounded contexts are out of scope unless the operator opts in.

**Acceptance:** note present in template §2 and referenced by the skill; nothing else changed.

**PR:** branch `feat/03-ddd-scope-note`; title "docs(03): mark formal DDD out of scope by default"; do not merge.

### Task 4 — Relax the 03→04 gate (item #3) — PR-4

**Why:** `03` (architecture) and `04` (tech-stack) are tightly coupled and better authored in one sitting; forcing a merge of `03` before `04` starts adds a round-trip with no safety gain.

**Files:**
- Modify: `plugins/cuevik-start/references/runner.md` (§0 session model; §1 check 4, the merge gate)

**Change (Option A, chosen):** Allow `03` and `04` in one session. Gate `04` on `03`'s branch/PR being **open**, not merged. Keep two separate documents and two separate PRs. Add the minimal special-case to the merge-gate check rather than removing it globally.

**Acceptance:** runner text permits `03`+`04` in one session with `04` gated on `03` open; all other step gates unchanged. Dry-run: starting `04` with `03`'s PR open is allowed; board/story bookkeeping still records both.

**Caveat to verify:** confirm board and story bookkeeping hold when `04` runs before `03` is merged.

**PR:** branch `feat/runner-relax-03-04`; title "feat(runner): allow 03+04 in one session, gate 04 on 03 open"; do not merge.

### Task 5 — BACKLOG.md as frozen snapshot + file issues at 07 (item #10) — PR-5

**Why:** `BACKLOG.md` drifts the moment issues move; make it an explicitly-labeled build artifact and let GitHub issues be the live backlog.

**Files:**
- Modify: `plugins/cuevik-start/skills/07-backlog/SKILL.md`
- Modify: `plugins/cuevik-start/skills/07-backlog/BACKLOG.template.md` (header)

**Change (Option A, chosen):** `BACKLOG.md` is always generated, with a header marking it a frozen point-in-time build output (issues are authoritative). At `07`, always file issues. If the repo has no board (per `.cuevik/config.json` board state — see Task 8), push the operator to set one up, then add the filed issues to the board. (Express lane: no push — see Task 9.)

**Acceptance:** template header states it is a frozen snapshot; skill always files issues; board-absent path prompts for a board then adds issues; board-present path adds directly. `BACKLOG.md` remains a permanent lineage node.

**PR:** branch `feat/07-backlog-snapshot`; title "feat(07): frozen BACKLOG.md snapshot; always file issues"; do not merge.

### Task 6 — Advisory docs audit at 08-finalize (item #11) — PR-6

**Why:** Finalize is the natural place to catch doc drift before closing, but it must advise, not block.

**Files:**
- Modify: `plugins/cuevik-start/skills/08-finalize/SKILL.md`
- Modify: `plugins/cuevik-start/references/steps.yml` (08 summary / invokes clause)

**Change:** At `08`, run `cuevik-docs:audit` **read-only** over the full doc set; report findings in the PR body; the operator fixes via `cuevik-docs:update`. Not a hard gate. Change `08`'s "invokes no skill" clause to "invokes `cuevik-docs:audit` only" in both the skill and `steps.yml`. (Express lane: no finalize audit — it skips `08`.)

**Acceptance:** `08` invokes the audit read-only (never `fix`); findings land in the PR body; no blocking gate added; `steps.yml` matches.

**PR:** branch `feat/08-finalize-audit`; title "feat(08): advisory docs audit at finalize"; do not merge.

### Task 7 — Conditional, non-duplicating README (item #8) — PR-7

**Why:** `06` can restate upstream docs, creating drift; make it summarize-and-link, with one source of truth for operational values.

**Files:**
- Modify: `plugins/cuevik-start/skills/06-readme/SKILL.md`
- Modify: `plugins/cuevik-start/skills/06-readme/README.template.md`

**Change:** Two-tier no-duplication rule. (1) Narrative sections (Overview, Key Concepts) summarize and link to the source doc, never restate its prose. (2) Operational values (prerequisite versions, install/run/test commands) have a single source (`TECH-STACK` / `CONTRIBUTING`): in docs-first mode the README shows a pointer only; in scaffolded mode it MAY surface the **verified** commands pulled from `CONTRIBUTING` (a README with no run commands is worse UX). Reviewer checklist: flag any value authored in two places. The `cuevik-docs:audit` Absorb lens guards residual drift.

**Judgment call to confirm with maintainer:** scaffolded mode keeping verified commands (sourced from `CONTRIBUTING`) rather than going strictly link-only.

**Acceptance:** docs-first README contains pointers, no copied versions/commands; scaffolded README's commands trace to `CONTRIBUTING`; reviewer-checklist line added.

**PR:** branch `feat/06-readme-no-dup`; title "feat(06): conditional, non-duplicating README"; do not merge.

---

## Track B — Design-gated (do not implement without human review)

For each: produce a proposal in this review folder (`docs/reviews/cuevik-start/2026-11-01/design-<name>.md`) using superpowers:brainstorming, then stop. The proposal states options considered, the chosen approach, the exact file touch-list, and open questions. Implementation is a separate, human-approved pass.

### Task 8 — Harden 00-bootstrap: board optional in both lanes (item #9)

**Why / top risk reduced:** `00` wires a GitHub Projects v2 board via brittle GraphQL plus workflows no API can toggle; a board failure currently can derail initiation. Decouple governance (always required) from the board (always optional).

**Design must cover:**
- Governance core (repo + `.cuevik/` + `CONTRIBUTING`) always runs and STOPs on failure — this is the trust boundary and must not degrade.
- Board setup is attempted but **degrades, never STOPs**. Isolate every Projects v2 call behind one board-adapter seam (see `plugins/cuevik-start/references/board-template.json`).
- Record board state `configured | partial | none` in `.cuevik/config.json`; extend `plugins/cuevik-start/references/contracts/config/config.schema.json` (and the example) accordingly.
- Standard lane with no board → push the operator to add one (surfaced again at `07` and in `status`). Express lane → no push.
- Consumers must treat board state `none` as valid.

**Touch-list (expected):** `skills/00-bootstrap/SKILL.md`, `references/runner.md` (§7), `references/contracts/config/config.schema.json` (+ example), possibly `references/board-template.json`, `skills/status/SKILL.md`.

**Enables:** Task 9 (Express reuses the board-optional seam).

### Task 9 — Express lane `/cuevik-start:express` (item #4)

**Why:** For MVPs/spikes, the full 9-gate path is heavy; offer a one-session, one-PR lean path that reuses existing step skills.

**Depends on:** Task 8 (board-optional seam) and Task 2 (strawman entry ramp).

**Agreed design (confirm, then detail):**
- Separate command `/cuevik-start:express`, single session, inter-step gates relaxed — not a `--express` flag.
- Produces in one PR: lean bootstrap (repo + `.cuevik/config.json` + reduced `.cuevik/lineage.json` + minimal `CONTRIBUTING.md`, no init-only branch table) · lean `PRODUCT.md` (`01`) · lean `PRD.md` (`02`) · backlog issues (`07`).
- Skips: `ARCHITECTURE`, `TECH-STACK`, `AI-TOOL-GUIDE`, `README`, `08-finalize`, inter-step merge gates.
- Board skipped by default (issues only, no Projects v2); no push.
- Keep the two-altitude PRODUCT/PRD split (do not collapse to one doc).
- Graduation supported: same doc types occupy lineage slots; running standard `03`–`06` later adds the missing docs; `cuevik-docs:update` deepens the lean ones.

**Touch-list (expected):** new orchestrator skill + command, reduced lineage variant, reuse of `01`/`02`/`07`; new command ⇒ docs-build (`build_docs.py --write`) in the implementing PR.

### Task 10 — New TEST-STRATEGY step + renumber (item #6) — LAST

**Why:** There is no project-level test strategy artifact; add one as a first-class step. Chosen standalone (not a second output of `04`) for showcase value, accepting the renumber ripple.

**Must run after all Track A step-content changes exist**, so it renames the final file set.

**Design must cover:**
- New step producing `docs/TEST-STRATEGY.md`: test levels · coverage target · test env + data · NFR verification · quality ownership. Owner: Architect. Upstream: PRD + ARCHITECTURE + TECH-STACK.
- Placement after `04`, before `05` ⇒ renumber `05`–`08` → `06`–`09` (or a justified non-standard id). Decide exact numbering here.
- Update everything the renumber touches: `references/steps.yml`, branch names (`init/NN-*`), skill folders, `.cuevik/lineage.json` (+ schema/example), `references/_doc-references.md` (doc-set count), `README.md`, per-step initiation issues. Consider adding a QA reviewer role under `references/roles/`.
- Not in Express (depends on ARCHITECTURE/TECH-STACK).
- New step ⇒ docs-build (`build_docs.py --write`) in the implementing PR.

---

## Deferred / out of scope (do not implement)

- **Roadmap horizon** ("direction for next 1–2 releases" in `PRODUCT.md`) — parked in the repo's `TODO.md`; act only on explicit demand.
- **CI/CD, observability, operational readiness** — suite-level gaps belonging to a separate `cuevik-ship` review, not `cuevik-start`.
- **05→06 gate merge, command removals** — reviewed and declined; leave as-is.

## Self-review (author's check, informational)

- **Coverage:** all eleven reviewed items map to a task (A: #1,#5,#7,#2,#3,#10,#11,#8; B: #9,#4,#6); deferred items explicitly parked.
- **Dependencies:** #9→#4 and #7→#4 and (#8/#10/#11 content)→#6 are encoded in track order and the "run last / enables" notes.
- **No invented facts:** every change preserves `_writing-rules.md`; no numbers/versions introduced.
- **Proportion:** decisions and exact paths only; bodies and procedures left to the implementer and to each skill's own contract.
