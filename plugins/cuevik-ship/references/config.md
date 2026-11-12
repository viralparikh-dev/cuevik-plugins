# Project facts and the board

Never hardcode an owner, repo, board number, field id or folder. Read them:

| Fact | Source |
| --- | --- |
| Repo owner and name | the git remote: `gh repo view --json nameWithOwner --jq .nameWithOwner` |
| Whether there is a board | `git show origin/main:.cuevik/config.json` `boardState` (contract: `references/contracts/config/`) |
| Board owner, number, node id, Status field and option ids | the same file's `project`, present unless `boardState` is `none` |
| How to call the board | the board core (`references/contracts/board/board.md`) |
| Backlog model (epics or flat) | the same file's `backlogModel` (contract: `references/contracts/config/`) |
| Source-of-truth documents, owners, reviewers, upstream links | `git show origin/main:.cuevik/lineage.json` (contract: `references/contracts/lineage/`) |
| Worktree root | the plugin's `worktree_root` option (`references/branches.md`) |

Read the two `.cuevik/` files from `origin/main`, never from a work branch. If one fails its
contract's schema, **STOP** and say which rule fails. A config below `schemaVersion` 6, or a lineage
below `schemaVersion` 2, fails it: say
`<file> is schemaVersion <n>. Run /cuevik-start:migrate, merge its PR, then re-run.`

## Board state

`boardState` decides whether the board rules in this file apply:

- `none`: the repo has no board, which is valid. Make no `gh project` call anywhere, in a local or
  a cloud session, and say nothing about it: not in a report, not as a list of board updates to make
  by hand.
- `configured` or `partial`: the rules under "The board" below. `missing` (only with `partial`) is
  for humans and `cuevik-start`'s `status`; a part the board lacks is skipped and reported by the
  per-call rules there.

## Backlog model

`backlogModel` decides how the backlog is shaped. It is required (config contract, since
`schemaVersion` 5):

- `epic-grouped`: stories are filed under an `Epic:` issue for their PRD section and linked as its
  sub-issues (the standard lane). `03-create-backlog` resolves or creates the epic, and
  `04-plan-intent` gates on the story's `Epic:` reference line. This is the default behaviour the
  ship steps describe.
- `flat`: no epic issues (the Express lane writes this). `03-create-backlog` files no epic and no
  sub-issue-to-epic link, the References block omits `Epic:`, and `04-plan-intent` gates on the
  `story` label instead. `blocked_by` links are unchanged. Epics live only as logical rows in
  `docs/BACKLOG.md`. Each story is typed `Feature` where the owner supports it (below).

Where a step's text and a flat-mode rule disagree, flat mode wins on a `flat` repo and the step's
text applies on an `epic-grouped` repo.

### Issue types (flat mode)

On a `flat` repo, give each story the native `Feature` issue type when the owner is an organisation
that has it. Probe once, after the owner is known
(`gh repo view --json owner --jq .owner.login`):

`gh api orgs/<owner>/issue-types --jq '[.[] | select(.is_enabled) | .name]'`

- `Feature` present → create with `gh issue create … --type Feature`; a reused or converted issue
  missing its type → `gh issue edit <n> --type Feature`.
- Owner is an organisation but `Feature` is absent → ask once with `AskUserQuestion`: `This
  organisation has no Feature issue type. Add it?` (`Yes, add it` · `No, file untyped`). This is an
  org-wide, persistent change, so the question is the approval. `Yes` → create it
  (`gh api -X POST orgs/<owner>/issue-types -f name=Feature -F is_enabled=true`), then type the
  stories; a create that fails on scope or permission → say so and file untyped. `No` → file
  untyped.
- Probe returns 404 (the owner is a user, not an organisation) → issue types are an
  organisation-only feature and cannot be enabled on a personal account: say so once and file
  untyped. Do not ask.

Never **STOP** for types. Types are additive: a story keeps its `story` and `priority:*` labels
either way. When any story is filed untyped, the step's report records `Issue types: not set
(<reason>); labels carry the data.`

## The board

Every board call is an operation in the board core, `references/contracts/board/board.md` (shared
with `cuevik-start`): `board.read` `item` and `fields`, `board.addItem` and `board.setField`. Load
it when `boardState` is not `none`; cuevik-ship runs no `gh project` command of its own. The core
says when a call is made (never on a `boardState` `none` repo, never in a cloud session) and that a
failed or skipped call never stops a step. What cuevik-ship adds:

- **Cloud session:** say which board updates the operator should make locally (or that the board's
  `Auto-add to project` workflow covers new issues). Everything else works the same.
- **Item:** `board.read` `item`. Not on the board: add it with `board.addItem` when the step adds
  issues; otherwise skip and report.
- **Status:** `board.setField`, with the Status named in the table below. A name the board does
  not have: skip and report.
- **Other fields** (`Item Type`): `board.setField`, field and option by exact name; missing: skip.

Status moves, by step. The board's own workflows (`Item added to project`, `Pull request linked to
issue`, `Item closed`) set the rest:

| When | Status | Labels | Set by |
| --- | --- | --- | --- |
| 01 files an idea | board default (`Item added to project`) | `idea` | 01 |
| 03 turns the idea into a story | unchanged | −`idea`, +`story`, +`priority:*` | 03 |
| 04 creates the work folder | unchanged | +`shaping` | 04 |
| 05 approves a spec with an unticked §8 box | unchanged | +`decision-needed` | 05 |
| 06 approves the plan | `Ready` | −`shaping`, −`decision-needed` | 06 |
| 07 starts building | `Working` | — | 07 |
| 07 opens the code PR (`Closes #<n>`) | `Reviewing` | — | board, `Pull request linked to issue` |
| the code PR merges, closing the issue | `Done` | — | board, `Item closed` |

`shaping` on an issue means a work folder is open for it whose plan is not approved: 04 adds it,
06 removes it. Create a missing label before first use:
`gh label create <name> --color <hex> --description "<text>"` (`idea` C5DEF5, `shaping` D4C5F9,
`decision-needed` E99695).
