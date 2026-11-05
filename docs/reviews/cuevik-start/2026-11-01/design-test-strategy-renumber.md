# Design — Task 10: TEST-STRATEGY step + renumber (item #6)

Status: **design settled with the maintainer on 2026-11-05; awaiting explicit approval. Nothing implemented.** Implementation is one PR, branch `feat/test-strategy-renumber`, from `main` after all Track A PRs and Tasks 8 and 9 (#63, #64) merged, so it renames the final file set.

## Problem
No project-level test strategy artifact exists. Add `docs/TEST-STRATEGY.md` as a first-class step. Chosen standalone (not a second output of `04`) for showcase value, accepting the renumber ripple. Owner: Architect. Upstream: PRD + ARCHITECTURE + TECH-STACK.

## Options considered (numbering)
1. **Second output of `04`.** No renumber, but hides the artifact and overloads `04`. Rejected in the plan.
2. **Insert as `05`, renumber `05`–`08` to `06`–`09`.** Clean order, widest ripple. **Chosen.**
3. **`04b-test-strategy` or append as `09`.** `04b` violates the id pattern `^[0-9]{2}-[a-z0-9-]+$` that both contract schemas enforce. Appending writes the strategy after the documents that should use it and breaks the "`08-finalize` is last" assumption.

## Decisions
| # | Question | Decision |
|---|---|---|
| 1 | Numbering | `05-test-strategy`, after `04-tech-stack`; `05`–`08` become `06`–`09`. |
| 2 | Already-initiated repos | **Strict versions plus an alias map plus a migrate command.** Config `schemaVersion` 4. Old PR branches (`init/05-ai-tool-guide` …) are history and cannot be renamed, so `steps.yml` carries `aliases` used for PR lookup. Old repos are brought current by `/cuevik-start:migrate`. |
| 3 | Migrate scope | **Everything to current**: config v2 or v3 up to v4 and the lineage, in one PR. A current repo gets "nothing to migrate". |
| 4 | Lineage version | **Stays 1**: no key changed (the contract's own bump rule). Config v4 is the trigger; migrate edits both files. `cuevik-docs` keeps working on an old lineage. |
| 5 | Reviewers | Architect owns, **Product Owner co-reviews**, as for `ARCHITECTURE.md`. No new role file. |
| 6 | Upstream links | `TEST-STRATEGY.md` is upstream of `AI-TOOL-GUIDE.md`, `README.md` and `BACKLOG.md`. README only links to it (Task 7 rule); the backlog still derives scope from the PRD alone. |
| 7 | Sections | Six: Test Levels, Coverage Target, Test Environment & Data, NFR Verification, Quality Ownership, **Defect Management**. |
| 8 | Story fields | `storyPriority` High, `storySize` MD, `storyEfforts` 6: copied from `04-tech-stack`, not estimated. |

## Design

### 1. Renames
| Old id | New id | Old branch to alias |
|---|---|---|
| (new) | `05-test-strategy` | none |
| `05-ai-tool-guide` | `06-ai-tool-guide` | `init/05-ai-tool-guide` |
| `06-readme` | `07-readme` | `init/06-readme` |
| `07-backlog` | `08-backlog` | `init/07-backlog` |
| `08-finalize` | `09-finalize` | `init/08-finalize` |

`00`–`04` are unchanged. The four skill folders are moved with `git mv` (history kept); each skill's frontmatter `name`, "Step NN" text, "Run after NN-…" descriptions, `Error:` strings and every cross-reference change with it. Order in `steps.yml` stays the run order.

### 2. The new step `05-test-strategy`
- `steps.yml` entry: branch `init/05-test-strategy`, output `docs/TEST-STRATEGY.md`, template `TEST-STRATEGY.template.md`, `commitMessage` `docs: add TEST-STRATEGY.md (05-test-strategy)`, `storyPriority` High, `storySize` MD, `storyEfforts` 6, `prSummary` and `finalReminder` in the shape of `04`.
- `skills/05-test-strategy/{SKILL.md,TEST-STRATEGY.template.md}`. Header block, injected references, numbered `##` sections, dividers, as the other templates. Sections: 1 Test Levels · 2 Coverage Target · 3 Test Environment & Data · 4 NFR Verification · 5 Quality Ownership · 6 Defect Management.
- Content contract (what each section must hold):
  - **Test Levels**: each level in use, what it covers, and which PRD requirement classes map to it. Every Must requirement of the PRD maps to at least one level.
  - **Coverage Target**: the coverage measure and its target. **The number comes from the operator, never a default** (`_writing-rules.md`); no number given: the step cannot finish.
  - **Test Environment & Data**: the environments tests run in and where test data comes from, from ARCHITECTURE and TECH-STACK, not invented.
  - **NFR Verification**: each PRD §7 requirement with the method that verifies it and its pass threshold (the PRD's own number, copied).
  - **Quality Ownership**: which role is accountable for each level and for the strategy itself. Roles, not accounts.
  - **Defect Management**: how defects are classified, triaged and tracked, on GitHub issues with the `bug` label `cuevik-ship` already uses. Any response or fix target is an operator number.
- Interview and reviewer checklist follow `04`: open questions asked in chat (the runner's list of open-interview steps gains `05-test-strategy`), the Architect challenge sequence with the test-specific rules above in the skill's own checklist, RFC 2119 and measurability enforced.
- Gate: the normal merged gate on `04` (previous step). It does **not** join the `03`+`04` same-session relaxation. Not in Express.
- Lineage entry: `docs/TEST-STRATEGY.md`, steps `["05-test-strategy"]`, upstream `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/TECH-STACK.md`, owner Architect, reviewers Architect and Product Owner, inserted after `TECH-STACK.md`. `docs/TEST-STRATEGY.md` is added to the `upstream` of `AI-TOOL-GUIDE.md`, `README.md` and `BACKLOG.md`, right after `docs/TECH-STACK.md` in each list. `CONTRIBUTING.md` steps become `["00-bootstrap","04-tech-stack","09-finalize"]`.
- `_doc-references.md`: "fixed at seven" becomes eight, with a `TEST-STRATEGY.md` row after `TECH-STACK.md` and the numbering shifted. It propagates to documents generated from then on.

### 3. Alias map
- `steps.yml` gains `aliases:` (a list of legacy ids) on the four renamed steps, documented in its header comment.
- Used only to find merged PRs: `status` §2 (the step's PR query and its branch lists try `init/<id>` and `init/<alias>`), and `runner.md` §1 check 4 (the previous step's PR). Nothing else reads aliases: config story keys and lineage step ids are not aliased, because migrate renames them.
- A repo that has not been migrated is stopped before any of this matters (section 5).

### 4. Contracts
- `contracts/config/`: `schemaVersion` const 4; description updates (story keys); example uses the new ids and adds `05-test-strategy`; README: "Migrating" now covers 2 and 3 (first choice `/cuevik-start:migrate`; the manual edit for the v3 to v4 change as a before/after of the renamed keys); consumers table. Edited at the root, copied to the two plugin copies, `python scripts/check-contracts.py`.
- `contracts/lineage/`: schema unchanged (still version 1). Example: renamed `steps` ids, the new document, the new upstream links. README: the step ids mentioned.
- The three lineage copies (`cuevik-start`, `cuevik-docs`, `cuevik-ship`) and the two config copies are refreshed the same way.

### 5. `/cuevik-start:migrate` (new skill, not a numbered step)
- Runs in the project folder; checks: repo root, `gh` signed in, clean tree, refresh `main`. Reads `.cuevik/config.json` and `.cuevik/lineage.json` from `main`; either missing: STOP, run `00-bootstrap` first.
- Config at version 4 and lineage already carrying the new ids and `docs/TEST-STRATEGY.md`: `Nothing to migrate.` and stop. Otherwise it prints the exact edits and asks once (`Yes` / `No`).
- **Config edits.** Version 2: add `"boardState": "configured"` (every v2 config has `project`; missing `project`: STOP). Set `"schemaVersion": 4`. Rename the `initiation.stories` keys with the alias map. It files no issue: there is no story for `05-test-strategy` in a migrated repo.
- **Lineage edits.** Rename the ids in every `steps` array with the alias map; add the `docs/TEST-STRATEGY.md` entry as in the default lineage, if absent; insert it into the `upstream` of `docs/AI-TOOL-GUIDE.md`, `README.md` and `docs/BACKLOG.md` right after `docs/TECH-STACK.md`, where those entries exist. Everything else, including any project-specific owner or reviewer, is left as found.
- Checks the result against both schemas, then branch `init/migrate` (so `cleanup` handles it like a step branch), one commit `chore: migrate .cuevik files to config v4`, push on approval, PR to `main`. Not merged by the command. A branch or PR that already exists follows the runner §3 reuse-or-delete rule.
- It does not touch `CONTRIBUTING.md` (the init-only branch table there keeps the old ids until `09-finalize` removes the block) and makes no other GitHub change. The PR body says both.
- Messages that point to it: runner §1 check 3 (replacing the v3 text: `schemaVersion` below 4 STOPs), `status` (a Check line), `cuevik-ship` `config.md`. Each says: `.cuevik/config.json is schemaVersion <n>. Run /cuevik-start:migrate, merge its PR, then re-run.` The manual route stays documented in the config README.
- A command, so docs build in this PR.

### 6. Other consumers of the renumber
- `runner.md`: the `06-readme` `replacesExisting` example, §6 last step, §1 check 4 special cases, the open-interview list, §8 table text, the Express ids; `status`: `00–08` becomes `00–09`, the `08-finalize` file-check row, progress denominator, the story rule below; `cleanup`; `00-bootstrap` ("nine" to "ten" wherever it appears; the initiation issues are generated from `steps.yml`, so new repos get a story for `05`); `board-adapter.md`; `templates.md`; `contributing-governance.md` (the nine-step table gets ten rows, "nine" becomes "ten"; the Express variant has no table); plugin `README.md` and `plugin.json` description ("nine steps (00–08)" becomes ten (00–09); version untouched).
- Express: `express.yml` (`07-backlog` becomes `08-backlog` in `covers` and `closes`; `notCovered` gains `05-test-strategy` and takes the new ids), the `express` skill, the profiles in `01`, `02` and `08-backlog`, the Express block (adds `docs/TEST-STRATEGY.md` to the files that must not be in the diff). Not covered: the strategy depends on ARCHITECTURE and TECH-STACK.
- `status` story rule: `no story for <id>` is not reported while the step's row is `— not started`, so a migrated repo (which has no story for `05`) is not nagged. Once the step starts the check applies.
- Other plugins: `cuevik-ship` `03-create-backlog` and its contract copies mention `cuevik-start:07-backlog`; `cuevik-docs` `update` lists the documents it can update (adds `TEST-STRATEGY.md`).
- Docs: the Walkthrough (headings, the generated `step-<id>` blocks, a new `05-test-strategy` section, a `migrate` section, both command tables, troubleshooting rows, known limits), the Overview rows, regenerated by `python docs/guides/build_docs.py --write` with HTML and PDFs committed.

### 7. Known consequences (accepted)
- A finished old repo, once migrated, shows `05-test-strategy` as `— not started`, so status reads 9 of 10 with Next pointing at it; its closed initiation epic then trips status' existing "epic closed while a step is not merged" Check. Running `05` clears both. The migration PR body says so.
- Until a repo is migrated, `cuevik-start` (from `01`) and `cuevik-ship` stop on it with the migrate message.
- `CONTRIBUTING.md` in a migrated repo keeps the old ids in its init-only table until `09-finalize`.

## Implementation notes (found while building; no decision changed)
- The rename pass could not be a plain find-and-replace: generated-block markers (`gen:step-<id>`) and the bare step numbers in prose (`07` for the backlog, `1/9`, "nine steps", the `00`–`08` ranges) were done as separate, asserted edits.
- `templates.md` gains a row for the new template; the AI tool guide, README and backlog skills name `TEST-STRATEGY.md` as an upstream document (Testing Rules source, link-only, context-only respectively).
- A step-05 NFR section degrades instead of failing when `PRD.md` §7 is empty or is the Express stub: it says so and lists the gap under **Upstream changes needed**.
- `cuevik-ship` messages and `config.md` carry the same migrate text as the runner. `cuevik-ship`'s design and plan steps do not read `TEST-STRATEGY.md` yet; that is a possible follow-up, not part of this PR.
- Verified by script: the migrate rules turn the pre-change default lineage into the new default lineage exactly, leave the new one unchanged, keep project-specific edits, and give the same result from a version 2 or a version 3 config.

- A live run of the migrate rules on a real old-format repo (config version 2, only `00` merged) gave a two-file PR that validated and matched the new default lineage; it showed the edits must be minimal text edits that keep the files' formatting, and that a refused push must stop the command. Both are in the skill.

## Out of scope
- A QA role file; plugin version bumps; filing the new initiation story during migration; rewriting `CONTRIBUTING.md` during migration.
- CI/CD and operational readiness (deferred in the plan).

## Touch-list
- New: `skills/05-test-strategy/{SKILL.md,TEST-STRATEGY.template.md}`, `skills/migrate/SKILL.md`.
- Moved with `git mv`: `skills/05-ai-tool-guide` to `06-ai-tool-guide`, `06-readme` to `07-readme`, `07-backlog` to `08-backlog`, `08-finalize` to `09-finalize`.
- Modified: `references/steps.yml`, `references/express.yml`, `references/runner.md`, `references/_doc-references.md`, `references/templates.md`, `references/contributing-governance.md`, `references/board-adapter.md`, `skills/{00-bootstrap,01-product-concept,02-product-requirements,03-architecture,04-tech-stack,express,status,cleanup}/SKILL.md` as they mention step ids, the four moved skills, `plugins/cuevik-start/README.md`, `.claude-plugin/plugin.json` (description), `plugins/cuevik-ship` (`config.md`, `03-create-backlog`), `plugins/cuevik-docs` (`update`), the contract folders at the root and in the three plugins, `docs/guides/*` and the regenerated output.
- Unchanged: the lineage schema, `consumers.json`, `_writing-rules.md`, the role files.
- Docs build: yes (new steps and a new command).

## Verification
- `python scripts/check-contracts.py` passes (config v4 example, lineage example, five copies).
- Config schema cases from a scratch script: valid v4 in each `boardState`; invalid v3 and v2. Legacy story keys still match the key pattern, so rename completeness is checked separately.
- **Migration rules check** (scratch script): applying section 5's rules to the pre-change default lineage must give exactly the new default lineage; applying them to the pre-change config examples (v2 shape and v3 shape) must give a config that validates and has the new story keys.
- `steps.yml` and `express.yml` parse; `aliases` map to exactly the four old ids; ids unique and in order; every `§`, file and step-id reference in the edited files resolves.
- Rename completeness: no old id (`05-ai-tool-guide`, `06-readme`, `07-backlog`, `08-finalize`) remains outside the alias lists, the migrate skill, the contract README's migration text, the Walkthrough version history and `docs/reviews`.
- Reviewer checklists of the new and renamed skills re-read; `python docs/guides/build_docs.py --write`, then `--check`, pass; PDFs committed.
- A live run of `/cuevik-start:migrate` needs an old-format repo; the existing sandbox is one. Decision requested at approval.
- Global constraints: `_writing-rules.md` untouched; no personal, company, client or employer names; no guessed numbers or versions (the story fields and the coverage rule above are the only numbers, copied or operator-supplied).

## Resolved questions
1. `05-test-strategy`, with `05`–`08` shifted to `06`–`09`.
2. Old repos: strict config v4, alias map for PR history, migrate command.
3. No QA role file: Architect owns, Product Owner co-reviews.
4. `TEST-STRATEGY.md` feeds `AI-TOOL-GUIDE`, `README` and `BACKLOG` upstream.
5. Six sections, defect management included.
