# Board core

The GitHub Projects (v2) operations that `cuevik-start` and `cuevik-ship` share. A caller names an
operation (`board.addItem`) and runs no `gh project` command of its own for it.

## When a call is made

The board is optional and only mirrors the work: the merged PR stays the source of truth. Read
`boardState` from `.cuevik/config.json` first.

- **`none`:** the repo has no board, which is valid. Make no call and say nothing about it.
- **Cloud session:** `echo "$CLAUDE_CODE_REMOTE"` prints `true`. Cloud sessions cannot reach GitHub
  Projects, so make no call and report the updates that were skipped, where the caller says.
- **`configured` or `partial`, in a local session:** make the call. `partial` behaves like
  `configured`.

A call that fails, or that needs a field, an option or an item the board lacks, never stops the
caller: skip it, report it where the caller says, and carry on. Never create fields or options.

## Placeholders

| Placeholder | Value |
| --- | --- |
| `<number>`, `<project owner>` | `project.number` and `project.owner` in the config |
| `<project id>` | `project.id` in the config |
| `<status field id>`, Status option ids | `project.statusField.id` and `project.statusField.options` in the config |
| `<issue url>` | `https://github.com/<owner>/<repo>/issues/<n>` |

## Operations

### board.read `fields`

The board's fields, read once per session:
`gh project field-list <number> --owner <project owner> --format json --limit 100`. Find a field by
exact name, and a single-select option by exact name in its `options`. A missing field or option:
skip that update.

### board.read `item`

An issue's board item and its current Status:

```sh
gh project item-list <number> --owner <project owner> --format json --limit 500 \
  --jq '.items[] | select(.content.url=="<issue url>") | {id, status}'
```

`id` is the item id and `status` the name of its current Status. No output: the issue is not on the
board. Skip the update, or add the issue first (`board.addItem`) where the caller adds issues.

### board.addItem

`gh project item-add <number> --owner <project owner> --url <issue url> --format json --jq .id`;
the output is the item's id. Adding an issue that is already on the board is harmless and returns
the same id. Never set Status here: the board's own workflows set it when an item is added and when
its issue closes.

### board.setField

Sets one value on one item; the caller names the item, the field and the value.

- **Status:** look the option id up by name in `project.statusField.options`, then
  `gh project item-edit --id <item id> --project-id <project id> --field-id <status field id> --single-select-option-id <option id>`.
- **Any other field:** look it up with `board.read` `fields`, then
  `gh project item-edit --id <item id> --project-id <project id> --field-id <field id>` plus
  `--single-select-option-id <option id>` for a single-select field, `--date <YYYY-MM-DD>` for a
  date field, `--number <n>` for a number field or `--iteration-id <iteration id>` for an iteration
  field.

A board without the field, or without that option, is a skip, not a failure.
