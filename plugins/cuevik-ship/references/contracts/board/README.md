# Contract: the board core

The GitHub Projects (v2) operations more than one plugin runs, written once so the plugins cannot
drift apart on a command or on when a call is made.

| File | What it is |
|---|---|
| `board.md` | The operations (`board.read` `fields` and `item`, `board.addItem`, `board.setField`) and the rules for when a call is made. Skills load this file. |

Unlike the other contracts it has no schema: it describes calls, not a file in the project repo.
What it reads from the project is `.cuevik/config.json` (`boardState`, `project`), defined by the
[config contract](../config/README.md).

## What is not here

Operations only one plugin runs stay in that plugin: creating and linking a board, its workflows,
the `Sprint` field and the board's description are `cuevik-start`'s
(`plugins/cuevik-start/references/board-adapter.md`). Which Status a step moves a card to, and
what it reports when a call is skipped, is decided by the caller, not by this contract.

## Consumers

| Plugin | Uses it to |
|---|---|
| `cuevik-start` | add the initiation and backlog issues to the board and set their fields (`00-bootstrap`, the runner, `08-backlog`) |
| `cuevik-ship` | add new issues to the board, read a card's Status and move it |

Each consumer keeps a copy of this folder at `plugins/<plugin>/references/contracts/board/`,
declared in [`../consumers.json`](../consumers.json).

## Changing it

1. Edit `board.md`.
2. Copy this folder over every consumer's copy listed in `consumers.json`.
3. Run `python scripts/check-contracts.py`. It fails on any copy that differs.
