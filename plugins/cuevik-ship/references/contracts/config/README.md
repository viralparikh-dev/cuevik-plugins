# Contract: `.cuevik/config.json`

Project facts the cuevik plugins need and cannot work out on their own. Committed in the project
repo, so every clone and every session sees the same values.

| File | What it is |
|---|---|
| `config.schema.json` | JSON Schema (2020-12). The definition. |
| `config.example.json` | A complete, fictional example. |

## What goes where

| Fact | Home |
|---|---|
| Whether the repo has a board, and how complete it is | **here** (`boardState`, `missing`) |
| How issues are organised: epics-as-issues, or flat/typed | **here** (`backlogModel`) |
| Project board: owner, number, node id, Status field id and option ids | **here** (`project`) |
| Initiation tracking issues: one story per step (plus an epic when `epic-grouped`) | **here** (`initiation`) |
| Repo owner/name | the git remote (`gh repo view --json nameWithOwner`) |
| Worktree root folder | `cuevik-ship` plugin `userConfig` (machine fact, not project fact) |

## Board state

The board is **optional**. `00-bootstrap` offers one and sets it up after confirmation, but a repo
can run without it. `boardState` says which case this repo is in, and the schema allows only the
combinations below, so a consumer branches on this one field:

| `boardState` | Meaning | `project` | `missing` |
|---|---|---|---|
| `configured` | A board is recorded and everything bootstrap requires of it is done. | required | forbidden |
| `partial` | A board is recorded but a part is incomplete. | required | required |
| `none` | No board is recorded: declined, or it could not be used. **A valid state, not an error.** | forbidden | forbidden |

A consumer that finds `none` skips every board call silently. `partial` behaves like `configured`;
a call that needs a part the board lacks is skipped and reported as it always was.

`missing` lists the incomplete parts of a `partial` board, from a fixed set:

| Part | Incomplete when |
|---|---|
| `link` | the board is not linked to the repo |
| `items` | an initiation issue is not on the board |
| `fields` | a value bootstrap tried to set on a field the board has could not be set |
| `workflows` | a required workflow is off, or its Status mapping is unconfirmed (required: all seven on a board bootstrap created, `Item closed` on an existing one) |

A field or option the board simply lacks is not listed: bootstrap skips it and says so in its PR.
A board with no single-select `Status` field cannot be recorded at all (`project.statusField` is
required), so that case is `none`.

## Backlog model

`backlogModel` says how this repo's issues are organised. It is set once at bootstrap and read by
both plugins:

| `backlogModel` | Meaning | `initiation.epic` |
|---|---|---|
| `epic-grouped` | Epics are filed as GitHub issues; stories are their sub-issues. The standard lane. | required |
| `flat` | No epic issues: stories are distinguished by native GitHub issue type (`Task` for initiation, `Feature` for the backlog) and have no epic parent. The Express lane. | forbidden |

A `flat` repo keeps epics only as logical groupings in `docs/BACKLOG.md`, never as issues. The
schema forbids `initiation.epic` on a `flat` repo and requires it on an `epic-grouped` one, so the
two cannot contradict. `cuevik-ship` reads `backlogModel` and, on a `flat` repo, files new stories
typed and ungrouped rather than resolving or creating an epic.

`project.owner` is stored because a board can belong to a different user or organisation than the
repo. `statusField.options` holds every option on the board, by the board's own names. Skills look
up an id by name; which names a skill moves cards to is decided by that skill, not by this
contract. The order of `options` carries no meaning (`gh --jq` sorts keys); read the board for its
order.

`initiation` holds the issue numbers `00-bootstrap` creates to show initiation's progress: one
`INIT-<NN>: <title>` story per step after `00-bootstrap` (its own story cannot exist before it
runs), keyed by step id, plus — on an `epic-grouped` repo — one `Epic: Project Initiation` epic in
`initiation.epic`. A `flat` repo files no epic and gives each story the native `Task` issue type
instead. The issues are filed whatever the `boardState`, and are added to the board when there is
one. They carry only the `initiation` label, never `epic` or `story`, so `cuevik-start:08-backlog`,
`docs/BACKLOG.md` and `cuevik-ship`'s epic lookup never pick them up. The merged PR stays the source
of truth for a step; the issues only mirror it.

## Where the values come from

```sh
gh project view <number> --owner <owner> --format json --jq .id
gh project field-list <number> --owner <owner> --format json \
  --jq '.fields[] | select(.name=="Status") | {id, options}'
```

Both need the `read:project` token scope. A recreated board gets new ids: re-read them, never guess.
The `initiation` numbers are the ones `gh issue create` printed when `00-bootstrap` filed them.

## Migrating from an older schemaVersion

Version 3 added `boardState`. Version 4 renamed four step ids, which are the keys of
`initiation.stories`, when the test strategy step was inserted. Version 5 added `backlogModel`.
Older configs are not accepted: `cuevik-start` and `cuevik-ship` stop on one and say so.

Bring a repo current with `/cuevik-start:migrate`. It opens one PR that edits both
`.cuevik/config.json` and `.cuevik/lineage.json`. By hand, open a PR that does this to
`.cuevik/config.json`:

1. set `"schemaVersion": 5`;
2. for a version 2 config, add `"boardState": "configured"` (every version 2 config has a
   `project`, so the value is the same for all of them);
3. add `"backlogModel": "epic-grouped"` (every existing repo files epics, so the value is the same
   for all of them);
4. rename these keys in `initiation.stories`: `05-ai-tool-guide` to `06-ai-tool-guide`,
   `06-readme` to `07-readme`, `07-backlog` to `08-backlog`, `08-finalize` to `09-finalize`;
5. leave everything else as it is;

and this to `.cuevik/lineage.json`, in the same PR:

1. rename the same four ids in every `steps` array;
2. add the `docs/TEST-STRATEGY.md` entry from the default lineage (`lineage.example.json`);
3. insert `docs/TEST-STRATEGY.md` right after `docs/TECH-STACK.md` in the `upstream` of
   `docs/AI-TOOL-GUIDE.md`, `README.md` and `docs/BACKLOG.md`.

Merge it, then re-run the step.

## Adding or repairing a board

For a repo whose `boardState` is `none`, or `partial` with a `missing` list. This is the target of
every "add a board" or "repair the board" pointer in the plugins.

1. Create the board, or pick one that has a single-select `Status` field, and link it to the repo
   (from the repo folder: `gh project link <number> --owner <owner>`).
2. Read its ids with the commands under "Where the values come from".
3. Add the initiation epic and every story in `initiation` to the board.
4. Turn on the board's workflows as `cuevik-start`'s `00-bootstrap` requires (listed in the
   plugin's `references/board-adapter.md`). GitHub offers no API for this: use the board's
   Workflows page.
5. Open a PR on `.cuevik/config.json` that adds `project` (the ids from step 2) and sets
   `boardState`: `configured` when everything is done, or `partial` with `missing` listing what is
   not. Remove `missing` once nothing is.

## Consumers

| Plugin | Uses it to | Access |
|---|---|---|
| `cuevik-start` | `00-bootstrap` writes it; the runner adds `Closes #<story>` to each step's PR; `status` cross-checks the issues and reports the board state | write, read |
| `cuevik-ship` | add issues to the board and move their Status, when `boardState` is not `none` | read |

Each consumer keeps a copy of this folder at `plugins/<plugin>/references/contracts/config/`,
declared in [`../consumers.json`](../consumers.json).

## Changing it

1. Edit `config.schema.json` and the example. Increase `schemaVersion` when a key is added,
   removed or renamed.
2. Copy this folder over every consumer's copy listed in `consumers.json`.
3. Run `python scripts/check-contracts.py` (once: `python -m pip install -r scripts/requirements.txt`).
   It fails on an invalid example or any copy that differs. `--target <repo>` also checks that
   repo's `.cuevik/` files.
