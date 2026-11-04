# Design proposal — Task 10: TEST-STRATEGY step + renumber (item #6)

Status: **proposal for human review. Nothing implemented.** Must be implemented **last**, after all Track A PRs have merged, so it renames the final file set (Track A touches `01`, `03`, `04`, `06`, `07`, `08`, `runner.md`, `steps.yml`).

## Problem
No project-level test strategy artifact exists. Add `docs/TEST-STRATEGY.md` as a first-class step (test levels · coverage target · test environment and data · NFR verification · quality ownership). Owner: Architect. Upstream: PRD + ARCHITECTURE + TECH-STACK.

## Options considered
1. **Second output of `04`.** No renumber, but hides the artifact and overloads `04` (rejected in the plan: showcase value).
2. **Insert as `05`, renumber `05`–`08` → `06`–`09`.** Clean ordering, widest ripple.
3. **Non-standard id (e.g. `04b-test-strategy`)** or append as `09`. No renumber, but breaks the "order in list = run order, id = `NN-name`" convention, or places the doc after READMEs/backlog that should consume it.

## Chosen approach: option 2
- New id `05-test-strategy`, branch `init/05-test-strategy`, after `04`, before AI-TOOL-GUIDE. Renumber: `05-ai-tool-guide`→`06`, `06-readme`→`07`, `07-backlog`→`08`, `08-finalize`→`09`.
- Lineage: `docs/TEST-STRATEGY.md`, owner Architect, upstream `PRD.md`, `ARCHITECTURE.md`, `TECH-STACK.md`. Downstream additions: add it to `upstream` of `AI-TOOL-GUIDE` (test rules for AI tools), `README` (it may link, not copy — Task 7 rule) and `BACKLOG` (test stories can trace to it). Final `upstream` lists to be decided in implementation.
- **No guessed numbers:** the coverage target and any threshold come from the operator, never a default (`_writing-rules.md`); the skill's reviewer checklist must enforce this and RFC 2119/measurability.
- Add a QA reviewer role file under `references/roles/` (open question below).
- **Not in Express** (it depends on ARCHITECTURE/TECH-STACK).
- **Relation to Task 4:** `03`+`04` relaxed gate stays; decide whether `05` may also be authored in that session (proposal: no — normal merged gate on `04`).

## Rename ripple — exhaustive touch-list
- `skills/05..08` folders → `06..09`, plus each skill's frontmatter `name`, "Step NN" text, "Run after NN-…" descriptions, `Error:` strings, and every cross-reference to a step id.
- New `skills/05-test-strategy/{SKILL.md,TEST-STRATEGY.template.md}`.
- `references/steps.yml` (ids, branches, entries, prSummary/finalReminder text, "08 is last" assumptions) and `references/runner.md` (every hard-coded step id: 06-readme `replacesExisting` example, §6.5 last step, §1.4 gate special case from Task 4).
- `references/contracts/lineage/{lineage.example.json,lineage.schema.json,README.md}` (step ids in `steps`, new document, `frozen`), and `references/contracts/config` example (`initiation` issue map keys, story count).
- `references/_doc-references.md`: doc set "fixed at seven" → eight; propagate to every template via the injection mechanism.
- `skills/00-bootstrap/SKILL.md` (initiation issue list, branch table fence, step count), `references/contributing-governance.md` (init-only `init/NN-*` table), `skills/status/SKILL.md` (00–08 → 00–09), `skills/cleanup/SKILL.md`.
- `plugins/cuevik-start/README.md`, repo `README.md`, `docs/guides/Cuevik-Plugins_Walkthrough.{md,html}` (also stale after Track A: "six sections"), `build_docs.py --write`.
- Cross-plugin: `plugins/cuevik-docs` and `plugins/cuevik-ship` references to step ids or `README.md`/`BACKLOG.md` lineage paths (to audit).
- **Existing bootstrapped repos:** their `.cuevik/config.json` `initiation` map and `init/NN-*` PR history use the old numbering. Need a migration/compat rule.

## Open questions
1. Final numbering: `05-test-strategy` as above, or keep `05` slot and shift only later ids another way?
2. In-flight/already-initiated repos: break, or support both numberings via a `schemaVersion` bump and an id alias map?
3. QA reviewer role: new `roles/qa.md`, or Architect self-review plus Product Owner as co-reviewer (as for ARCHITECTURE)?
4. Must the new doc feed `AI-TOOL-GUIDE`, `README` and `BACKLOG` upstream, or only be linked from Further Reading?
5. Section list: levels · coverage target · test environment and data · NFR verification · quality ownership — is anything (test automation approach, defect management) in or out?
