# Design proposal — Task 8: board optional in both lanes (item #9)

Status: **proposal for human review. Nothing implemented.** Gated by the plan (Execution Mode, Track B).

## Problem
`00-bootstrap` wires a GitHub Projects v2 board through GraphQL/`gh project` calls and relies on board workflows no API can toggle (§E.5, operator-set). A board failure can derail initiation, and `config.schema.json` currently *requires* `project`, so a board-less repo cannot be expressed. Governance (repo, `.cuevik/`, `CONTRIBUTING`) is the trust boundary; the board is convenience.

## Options considered
1. **Optional `project` key only** (absent = no board). Smallest change, but cannot say *partial* (board created, some fields/workflows missing) and consumers cannot tell "absent on purpose" from "setup failed".
2. **Explicit `board.state` enum `configured | partial | none` plus the existing project facts nested under it.** Consumers branch on one field; partial is first-class. Breaking config shape.
3. **Keep `project` as is, add sibling `boardState`.** Non-breaking for readers of `project`, but allows contradictory combinations (`none` with a `project` object).

## Chosen approach: option 3 with a conditional schema
- Add top-level `boardState` (`configured | partial | none`), required; bump `schemaVersion` 2 → 3 (a key is added, per the schema's own rule).
- `project` becomes optional; JSON Schema `if/then`: `boardState` ∈ {`configured`,`partial`} ⇒ `project` required; `none` ⇒ `project` forbidden. Contradictions are unrepresentable.
- Same for `initiation` issue map: issues are still filed without a board, so `initiation` stays required; its board-item bookkeeping simply no-ops when `none`.
- **Board-adapter seam:** one section in `00-bootstrap` (and the runner §7 reads) that lists every Projects v2 operation (create project, fields, link repo, add item, set field) behind named operations (`board.create`, `board.addItem`, `board.setField`, `board.read`). Each returns `ok | degraded | unavailable`. `board-template.json` stays the declarative field/option source for the adapter. No other file calls `gh project` directly.
- **Failure policy:** governance core (repo, `.cuevik/`, `CONTRIBUTING`) keeps STOP-on-failure. Any adapter call failing ⇒ state `partial` or `none`, reported in the PR body, never STOP.
- **Lane behavior:** Standard + `none`/`partial` ⇒ push the operator to add a board (prompt, not block), re-surfaced at `07` (Task 5 already does this) and in `status`. Express ⇒ default `none`, no push.
- **Consumers treat `none` as valid:** runner §7 (skip all board bookkeeping silently), `07` (Task 5's "no board" test switches from "`project` absent" to `boardState == none`), `08`, `status` (skip cross-check, show one line "no board"), and `cuevik-ship` readers of `config.json` (needs a check — cross-plugin impact).

## Touch-list
`skills/00-bootstrap/SKILL.md` (§D, §E, §F config write, checklist) · `references/runner.md` (§7, §1 where config is read) · `references/contracts/config/config.schema.json` + `config.example.json` + `README.md` in that folder · `references/board-template.json` (only if adapter ops need metadata) · `skills/status/SKILL.md` · `skills/07-backlog/SKILL.md` (swap the Task 5 test) · `plugins/cuevik-ship/**` readers of `project` (to audit). No docs-build (no command/step change).

## Open questions
1. Is bumping `schemaVersion` to 3 acceptable, and is there a migration path for already-bootstrapped repos (treat a v2 config with `project` as `configured`)?
2. Should `partial` record *which* parts are missing (e.g. `missing: ["statusWorkflow"]`) so `status` can say what to fix?
3. Does `cuevik-ship` hard-require a board? If yes it needs its own degrade rule or a documented "requires board" precondition.
4. Is "push the operator" at `00` a prompt at the end of bootstrap, or only at `07`/`status`?
