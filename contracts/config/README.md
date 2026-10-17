# Contract: `.cuevik/config.json`

Project facts the cuevik plugins need and cannot work out on their own. Committed in the project
repo, so every clone and every session sees the same values (DECISIONS D15).

| File | What it is |
|---|---|
| `config.schema.json` | JSON Schema (2020-12). The definition. |
| `config.example.json` | A complete, fictional example. |

## What goes where

| Fact | Home |
|---|---|
| Project board: owner, number, node id, Status field id and option ids | **here** |
| Repo owner/name | the git remote (`gh repo view --json nameWithOwner`) |
| Worktree root folder | `cuevik-ship` plugin `userConfig` (machine fact, not project fact) |

The board is **required**: `00-bootstrap` asks for one and creates and links it, after
confirmation, when it does not exist (DECISIONS §3). `project.owner` is stored because a board can
belong to a different user or organisation than the repo.

`statusField.options` holds every option on the board, by the board's own names. Skills look up an
id by name; which names a skill moves cards to is decided by that skill, not by this contract.

## Where the values come from

```sh
gh project view <number> --owner <owner> --format json --jq .id
gh project field-list <number> --owner <owner> --format json \
  --jq '.fields[] | select(.name=="Status") | {id, options}'
```

Both need the `read:project` token scope. A recreated board gets new ids: re-read them, never guess.

## Consumers

| Plugin | Uses it to | Access |
|---|---|---|
| `cuevik-start` | `00-bootstrap` writes it | write |
| `cuevik-ship` | add issues to the board and move their Status | read |

Each consumer keeps a copy of this folder at `plugins/<plugin>/references/contracts/config/`,
declared in [`../consumers.json`](../consumers.json).

## Changing it

1. Edit `config.schema.json` and the example. Increase `schemaVersion` when a key is added,
   removed or renamed.
2. Copy this folder over every consumer's copy listed in `consumers.json`.
3. Run `python scripts/check-contracts.py` (once: `python -m pip install -r scripts/requirements.txt`).
   It fails on an invalid example or any copy that differs. `--target <repo>` also checks that
   repo's `.cuevik/` files.
