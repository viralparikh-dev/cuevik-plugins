# Design — Express: no epic issues, native GitHub issue types

Status: **implemented 2026-11-06 (design approved 2026-11-05; open questions resolved with the
maintainer).** Shipped as two PRs from `main`, in order: `feat/express-no-epics` (cuevik-start,
incl. the schema bump + migration, #72) then `feat/ship-epicless` (cuevik-ship, which reads the new
marker, #73). Follow-on to the merged Express lane (`design-express-lane.md`) and board-optional
(`design-board-optional.md`); it does not reopen either.

Implementation notes (beyond the design below): all four plugins were aligned to `0.4.0` (deck
moved `0.1.0`→`0.3.0` via #71, then to `0.4.0`), and PR1 also fixed a pre-existing docs-build
overflow in the Walkthrough's command-summary table (a scoped `.tbl.wide` padding rule). The live
Express run on a disposable Cuevik-org repo remains maintainer-run.

## Problem

The Express lane files its issues as normal repo issues and never touches a board — by design. In
that board-less mode two things the lane inherits add no value:

1. **Epic issues.** `00-bootstrap` §E.4 files an `Epic: Project Initiation` issue and `08-backlog`
   files one `Epic: <capability>` per `PRD.md` §6 section, then links every story to its epic as a
   sub-issue. Without a board there is no hierarchy view to make that grouping pay off; it is extra
   issues and extra sub-issue plumbing for no reader benefit.
2. **No issue typing.** Every issue is distinguished only by labels. GitHub now has native issue
   types (`Task`, `Bug`, `Feature`) at the organization level, which give a typed view in the issue
   list with no board. The initiation stories are tasks; the backlog stories are features.

Goal: in the Express lane, **file no epic issues**, and **type** the issues it does file —
`INIT-*` as `Task`, `PRD-*` as `Feature` — while keeping the existing labels so nothing downstream
that reads labels breaks. The epic concept stays in `docs/BACKLOG.md` as a logical grouping.

The standard lane keeps epics + labels-only; its only change is writing the new required
`backlogModel` key. `cuevik-ship` is adapted so a later backlog extension on a `flat` repo does not
silently reintroduce epics (see §7 — the largest, riskiest part).

## Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Scope | **Express lane only**, plus `cuevik-ship` adapted to match. Standard `00-bootstrap` and `08-backlog` keep epics + labels-only (standard `00` gains one line: write `backlogModel`). |
| 2 | Epic issues in Express | **None filed.** Neither the initiation epic nor the backlog epics become GitHub issues. Epics remain in `docs/BACKLOG.md` as logical rows (`E1`, `E2`, …) with the Issue column `—`. |
| 3 | Issue types | `INIT-*` → `Task`, `PRD-*` → `Feature`, **additive** to the existing labels (`initiation`; `story` + `priority:*`). Types add a dimension; they do not replace labels. |
| 4 | Types unavailable | Probe `orgs/<owner>/issue-types`. Present → set, no prompt. **Org missing them** → ask; approve → create `Task`/`Feature` via the org issue-types API (org-admin; org-wide change) then type; disapprove → file untyped, note in PR. **User-owned repo** → types are org-only, nothing to enable: say so and file untyped. Never STOP. |
| 5 | Sub-issue links | **None in Express** — there is no epic to parent to. |
| 6 | Config schema | **Add a required `backlogModel` marker** (`epic-grouped` \| `flat`). New key → **bump `schemaVersion` 4→5** with a documented migration (all existing repos → `epic-grouped`). `initiation.epic` becomes optional in the same bump. Standard writes `epic-grouped`; Express writes `flat`. |
| 7 | `cuevik-ship` on a `flat` repo | **Preserve the flat, typed model** when extending: no epic resolution or creation, `Feature` type on new stories, `04-plan-intent` gated on the `story` label instead of the `Epic:` reference line. Detection **reads `backlogModel`** from config. Largest change; its own PR (PR2). |

Why decision 6 bumps the schema: adding `backlogModel` is a new key, which the contract's own rule
(schema `schemaVersion` description) says to bump for. `design-express-lane.md` (decision 1) had
avoided a discriminator to dodge a migration; the maintainer chose the explicit marker here
instead, accepting the v4→5 migration. It is deterministic — every existing repo (standard and
current-Express, both of which file epics today) becomes `epic-grouped`.

## Design

### 1. No epic issues in Express

**`00-bootstrap` §E.4 (initiation issues), Express profile.** File only the per-step stories
(`INIT-<NN>: <title>`), each with the `initiation` label and `--assignee @me`, as today. Drop the
`Epic: Project Initiation` issue and the sub-issue linking (`gh api … /sub_issues`).
`.cuevik/config.json` `initiation` then holds `stories` only, no `epic`; `backlogModel` is `flat`.

**`08-backlog` §4 Filing, Express profile.** File only the per-requirement stories
(`PRD-NNN: … (<Priority>)`), each with `story` + `priority:*`, as today. Drop epic creation (Filing
step 2) and the sub-issue linking (Filing step 3); the board step 4 stays skipped.

`docs/BACKLOG.md` is still written with its full structure (template unchanged): the **Epics**
section keeps its logical rows (`E1`, `E2`, …) mapped to `PRODUCT.md` goals, Issue column `—`; the
**Stories** section keeps the `Parent epic` column pointing at those logical IDs. Epics in the
document, not in GitHub.

### 2. Native issue types

- **Probe once** (after the owner is known):
  `gh api orgs/<owner>/issue-types --jq '[.[] | select(.is_enabled) | .name]'`. A user-owned repo
  returns 404 → no org, no types. Record whether `Task` and `Feature` are both present.
- **Create with a type:** `gh issue create … --type Task` (INIT) / `--type Feature` (PRD). Verified
  on `gh` 2.95 (`--type` on `create`/`edit`, `--remove-type`).
- **Reuse (re-run):** a reused issue missing its type gets `gh issue edit <n> --type <T>` — same
  reuse-by-exact-title path both steps already use after a partial failure.
- **Org missing the types** (owner is an org, `Task`/`Feature` absent): ask with `AskUserQuestion`
  `This org has no Task/Feature issue types. Add them?` (`Yes, add them` / `No, file untyped`).
  **Yes** → create the missing ones
  (`gh api -X POST orgs/<owner>/issue-types -f name=Task -F is_enabled=true …`; org-admin, an
  org-wide persistent change — the approval gates it), then set them; API/scope failure → report and
  fall through to untyped. **No** → file untyped. (Verify the POST endpoint + scope at
  implementation.)
- **User-owned repo** (probe 404s): issue types are an organization-only feature — nothing to
  enable. Say so once and file untyped. No prompt, no STOP.
- Either untyped path records in the PR body: `Issue types: not set (<reason>); labels carry the
  data.`

Types are orthogonal to priority: a `PRD-*` issue is `Feature` **and** keeps its `priority:*` label.

### 3. Config contract — `backlogModel` marker, schemaVersion 5

`contracts/config/config.schema.json`:

- `schemaVersion` const `4` → `5`.
- New **required** `backlogModel`: `enum ["epic-grouped", "flat"]`. `epic-grouped`: epics are filed
  as issues and stories are their sub-issues (standard). `flat`: no epic issues; stories are typed
  and ungrouped (Express).
- `initiation.required`: `["epic", "stories"]` → `["stories"]`; `epic` description notes it is
  absent on a `flat` repo.
- Conditional (match the `boardState` pattern): `backlogModel: flat` ⇒ `initiation.epic` forbidden;
  `epic-grouped` ⇒ `initiation.epic` required. Keeps contradictory configs unrepresentable.
- `config.example.json`: bump to `5`, add `"backlogModel": "epic-grouped"` (it keeps `epic`, valid).

Migration (documented manual edit, like v2→v3 in `design-board-optional.md`): every v4 config →
set `"schemaVersion": 5` and add `"backlogModel": "epic-grouped"` (all existing repos file epics).
Document it once in `contracts/config/README.md` ("Migrating from schemaVersion 4"); the `runner.md`
precondition, the `cuevik-ship` config gate and `status` quote the exact edit.

Edit order (contract README rule): edit `contracts/config/config.schema.json` at the repo root, copy
to `plugins/cuevik-start/references/contracts/config/` and
`plugins/cuevik-ship/references/contracts/config/`, run `python scripts/check-contracts.py`.

### 4. Express profiles + the one standard-lane change

- **`00-bootstrap` Express profile:** §E.4 files no epic and no sub-issue links, types each
  `INIT-*` story `Task` (§2); `.cuevik/config.json` has `initiation` without `epic` and
  `backlogModel: flat`. The "skips the board" text is unchanged.
- **`08-backlog` Express profile:** file no epic, no sub-issue links, type each `PRD-*` story
  `Feature` (§2); `BACKLOG.md` Epics rows carry `—`. The board-less wording stays.
- **Standard `00-bootstrap` §F (the only standard-lane change):** write the new required
  `backlogModel: "epic-grouped"`. Standard `08` is otherwise untouched.
- Both skills' **Express reviewer-checklist** lines: assert no `epic`-labelled issue was filed,
  stories carry their type (or the PR notes types unavailable / declined), no sub-issue link was
  created, and `backlogModel` is `flat`.

### 5. The `express` skill, `express.yml`, runner

- **`skills/express/SKILL.md`:** §D/§E — files no epic and no sub-issue links and types the issues;
  §E config writes `backlogModel: flat`; §F PR body and the **Express block** drop any "epic stays
  open" phrasing and add the no-epic / typed / `flat` assertions; `Board: none, issues filed only`
  stays.
- **`references/express.yml` `prSummary`:** mention issues filed with no epic, typed where
  available, `backlogModel flat`.
- **`references/runner.md`:** §1 check 3 — `schemaVersion` must be `5`, else STOP with the migration
  edit (as board-optional did for v2→v3); Inputs §4 names `backlogModel`. §8 defers issue mechanics
  to each step's Express profile — confirm no §8 row names the initiation epic (it does not).

### 6. `status`, `cleanup`

- **`status`:** read `backlogModel`; on a `flat` repo skip the initiation-epic cross-check (the
  config has no `epic`) and cross-check stories only; may surface the `backlogModel`. A
  `schemaVersion` 4 config → one Check line with the migration edit.
- **`cleanup`:** no epic reference found; no change.

### 7. `cuevik-ship` adaptation — the heavy part

`cuevik-ship:03-create-backlog` is epic-centric: per `PRD-NNN` it resolves the section's epic
(parent → `epic`-labelled issue → `BACKLOG.md` → **new epic**) and links the story as a sub-issue;
`04-plan-intent` gates (verified: `SKILL.md` row A + the `idea`-without-`Epic:` STOP) on the
`Epic:` reference line. On a `flat` repo it would fall through to "new epic" and reintroduce epics.

Flat mode:

- **Detect** from `.cuevik/config.json` `backlogModel`: `flat` → flat mode; `epic-grouped` →
  today's behavior.
- **03-create-backlog** in flat mode: skip epic resolution/creation (§2 "Epic per ID", §3 "New,
  new section", §5 epic writes); file/convert stories with `--type Feature` where the owner
  supports types (§2 probe, shared with cuevik-start); the References block omits `Epic:`; no
  sub-issue-to-epic link. `blocked_by` links are unaffected.
- **04-plan-intent** gate: in flat mode gate on the `story` label (and removed `idea` label)
  instead of the `Epic:` line.
- **`references/config.md`:** add the `backlogModel` read and the flat-mode + type-probe rule here,
  the way the `none` board rule is shared across the ship skills.

Largest, least certain change — isolated in PR2, landed after PR1 merges (the marker it reads is
defined there).

### 8. Docs

`python docs/guides/build_docs.py --write` after the cuevik-start edits (guides track; refreshes
Available/Planned tags). The Walkthrough's Express section gains the no-epic / typed-issues / `flat`
wording and the schemaVersion-5 migration note; commit the regenerated `.html`/`.pdf` in PR1. PR2
runs the build again only if its command/step surface changes (it should not).

## Out of scope

- Standard `00-bootstrap` / `08-backlog` behavior beyond writing `backlogModel`.
- Board behavior: Express stays board-less; no board change in either lane.
- A board in Express: still not offered.

## Touch-list

**cuevik-start (PR `feat/express-no-epics`)**
- `skills/express/SKILL.md` — §D, §E (incl. `backlogModel: flat`), §F PR body, Express block.
- `skills/00-bootstrap/SKILL.md` — Express profile; standard §F one line (`backlogModel:
  epic-grouped`); reviewer-checklist lines.
- `skills/08-backlog/SKILL.md` — Express profile; reviewer-checklist line.
- `references/express.yml` — `prSummary`.
- `references/runner.md` — §1 check 3 (`schemaVersion` 5 + migration message); Inputs §4.
- `skills/status/SKILL.md` — read `backlogModel`, guard the epic cross-check, migration Check line.
- `contracts/config/config.schema.json` (root) + `config.example.json` + `README.md` (migration
  section) + the two plugin copies; `scripts/check-contracts.py` run.
- `docs/guides/` — `build_docs.py --write` output (`.html`, `.pdf`), Walkthrough wording.
- `plugins/cuevik-start/.claude-plugin/plugin.json` — version bump `0.3.0` → `0.4.0`.
- Plugin `README.md` — if the Express row mentions epics (verify).

**cuevik-ship (PR `feat/ship-epicless`)**
- `skills/03-create-backlog/SKILL.md` — flat mode (§2, §3, §5) + the type probe.
- `skills/04-plan-intent/SKILL.md` — gate in flat mode.
- `references/config.md` — the shared `backlogModel` flat-mode + type-probe rule.
- `references/contracts/config/*` — the schema v5 copy (kept identical to root via
  `check-contracts.py`).
- `plugins/cuevik-ship/.claude-plugin/plugin.json` — version bump `0.3.0` → `0.4.0`.

**Unchanged:** `steps.yml`, `board-adapter.md`, `board-template.json`, the lineage contract,
`09-finalize`, `cleanup`.

## Verification

- `python scripts/check-contracts.py` passes (example valid at v5 with `backlogModel`; three copies
  identical).
- Schema cases from a scratch script (not committed): valid `epic-grouped` **with** `epic`; valid
  `flat` **without** `epic`; invalid `flat` **with** `epic`, `epic-grouped` **without** `epic`,
  missing `backlogModel`, `schemaVersion` 4; `stories` still required (min 1).
- `express.yml` and `steps.yml` parse; every `§` and `references/…` cross-reference in the edited
  text resolves.
- Mechanical: no Express path files an `epic`-labelled issue or a sub-issue link; a type is set only
  after the probe confirms `Task`/`Feature` (or the operator enabled them), else untyped-with-a-note.
- `gh` capability confirmed: `gh` 2.95 `--type` on create/edit; `orgs/<owner>/issue-types` probe
  returns the enabled set (404 for a user repo). The `POST /orgs/{org}/issue-types` create endpoint
  + scope to be verified at implementation.
- `python docs/guides/build_docs.py --check` passes after `--write`; PDFs committed.
- Live Express run on a disposable Cuevik-org repo (types available): INIT-* are `Task`, PRD-* are
  `Feature`, no epic issue exists, `BACKLOG.md` Epics rows show `—`, `backlogModel` is `flat`.
  Maintainer-run (a fresh un-bootstrapped repo — the sandbox is already bootstrapped).
- Global constraints: `_writing-rules.md` untouched; no personal, company, client or employer names
  in framework content or generated documents; no guessed numbers or versions.

## Resolved questions

1. **Ship detection:** a **config marker** — `backlogModel` read from `.cuevik/config.json` — not
   the absence of `epic` labels.
2. **PRs:** **two**, `feat/express-no-epics` (cuevik-start) then `feat/ship-epicless` (cuevik-ship);
   cuevik-start merges first.
3. **Schema:** marker form is **`backlogModel: epic-grouped | flat`**; adding it **bumps to
   `schemaVersion` 5** with a documented migration (all existing repos → `epic-grouped`);
   `initiation.epic` becomes optional in the same bump.
4. **Types unavailable:** probe, then **ask**; approve → help enable the org types and set them;
   disapprove → file untyped. A user-owned repo cannot have types, so it is noted and skipped.
5. **Version + test:** **bump both plugins to `0.4.0`** in their PRs (cuevik-start in PR1,
   cuevik-ship in PR2); live test is maintainer-run on a fresh disposable Cuevik-org repo.
