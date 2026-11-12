# The References block

The issue description carries a `## References` section: links to the issue's files and PRs,
**never file content**. It is the issue's progress record. Every command refreshes it after its
gate check and again when it opens its PR; operators do not edit between the markers.

## Format

```markdown
## References

<!-- cuevik-ship:references -->
- Brainstorm: [brainstorm.md](<permalink>) · PR #<p>
- Docs PR: #<q>
- Epic: #<e>
- Intent: [intent.md](<permalink>) · PR #<p>
- Spec: [spec.md](<permalink>) · PR #<p>
- Plan: [plan.md](<permalink>) · PR #<p>
- Code PR: #<c>
- Split from: #<m>
- Split into: #<a>, #<b>
<!-- /cuevik-ship:references -->
```

- One line per thing that exists, in this order; a line appears once its file or PR exists and
  is never removed.
- `Epic:` is written by `03-create-backlog` and is the signal `04-plan-intent` gates on — on a
  `flat` repo (`config.md`) there is no `Epic:` line, and `04-plan-intent` gates on the `story`
  label instead.
- `Docs PR:` is written by `02-audit-prd` when it opens the PR to `main`.
- `Split from:` / `Split into:` are written by `03-create-backlog` on a split.

## Permalinks

A file link points at a commit, never a branch name, so it keeps working after cleanup (the
archive tag keeps the commits reachable):

```text
https://github.com/<owner>/<repo>/blob/<sha>/docs/ship/<n>-<slug>/<file>
```

- File merged into `.../issue`: `<sha>` = `git log -1 --format=%H origin/ship/<n>-<slug>/issue --
  docs/ship/<n>-<slug>/<file>`, the latest commit on the issue branch that touched it.
- File only in an open PR: the PR's head commit (`gh pr view <p> --json headRefOid --jq
  .headRefOid`), re-pointed at the issue branch by the next refresh after the merge.
- When a later step changes an earlier file (e.g. `intent.md` edited during the spec), the
  refresh re-points that line too.

## Refresh

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ship-refs.sh" <n> apply [--epic "#e"] [--split-from "#m"] [--split-into "#a, #b"]
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ship-refs.sh" <n> show    # the block it would write; changes nothing
```

A script writes the block, not you: never edit the issue description by hand and never run `gh
issue edit` on it. It derives every line a branch or a PR can prove (`Brainstorm:`, `Docs PR:`,
`Intent:`, `Spec:`, `Plan:`, `Code PR:`) from the permalink and PR rules above, keeps every line it
cannot derive exactly as it is, and never removes one. `Epic:`, `Split from:` and `Split into:` are
written by the step that knows them, through the three options (`03-create-backlog`); a new value
replaces the old line.

- It changes nothing outside the markers. Markers missing: it appends `## References`, a blank
  line and the marked block at the end of the body.
- Two marker pairs, or an end marker before the start marker: it **STOPS**; report it, never
  guess which block is current.
- A refresh needs no confirmation of its own: it changes only the block, which belongs to
  cuevik-ship. Its output says whether the block was `created`, `updated` or `unchanged`: say in one
  line what it changed.
- Exit 1: its last line is the answer; output it and stop. Exit 2 or a script that cannot be run:
  `Error: ship-refs.sh could not be run: <what the shell said>`. There is no other way to refresh.
