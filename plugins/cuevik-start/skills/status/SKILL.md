---
name: status
description: Shows where project initiation stands. A progress line, then for each cuevik-start step (00–09) whether the step's init/<slug> PR is merged, open, only a branch, or not started, read from git and GitHub, with the initiation issues on the board cross-checked, then the next command. Read-only. Run it any time in the project folder; steps 01–08 also run it first.
disable-model-invocation: true
---

# status

A read-only report of cuevik-start step progress. It writes no files, creates and deletes no
branches, changes nothing on GitHub, and asks no questions. The current folder is the project
repo. It takes no arguments. Run every command through the Bash tool.

The rows are worked out by a script that ships with the plugin, not by you. Never hardcode a step
list, and never run `gh pr list`, `git ls-remote` or a file check of your own to build or to
second-guess a row.

## 1. Run the script

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-state.sh"
```

When a step's runner follows this file (runner §0), add that step's id as the one argument, for
example `bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-state.sh" 03-architecture`: the output then
also has the `== gate` section runner §1 check 4 reads. Run it once, silently.

| The script | Do |
| --- | --- |
| exits 0 | Go on to §2 with its output. |
| exits 1 | Its one line is the whole answer: output it and stop. It is a preflight failure (not a git repo, not the repo root, no GitHub origin, `gh` not signed in, no `main` on GitHub) or a GitHub query that failed. |
| cannot be run, or exits with anything else | Output `Error: init-state.sh could not be run: <what the shell said>` and stop. There is no other way to produce the report. |

What it does, so its output can be read: it fetches `origin` (remote-tracking refs only; it never
checks out, pulls or changes a branch), then for each step, in `steps.yml` order, finds the
step's PR and checks its output on `origin/main`.

- **The PR** is looked up under the step's `branch` and under each `init/<alias>` of its
  `aliases`: a repo initiated before steps had slugs has the PR on the old numbered branch. For a
  step the Express lane covers, the lane's one PR stands for it unless the step has a merged or
  open PR of its own (Detail then starts `express PR #n`). The newest merged PR wins, else the
  open one, else the newest closed one.
- **The file check:** a `bootstrap: true` step needs both `.cuevik/` files on `origin/main`;
  `09-finalize` needs `CONTRIBUTING.md` there without its `INITIATION-ONLY` block; any other
  `replacesExisting: true` step has no file check (its output is on `main` before it runs); every
  other step needs its primary output there.
- **The row's status**, first match wins:

  | Condition | Status | `== steps` state |
  | --- | --- | --- |
  | merged PR, file check passes or none | `✓ merged` | `merged` |
  | merged PR, file check fails | `⚠ mismatch` | `mismatch` |
  | no merged PR, file check passes | `⚠ mismatch` | `mismatch` |
  | open PR | `⟳ PR open` | `open` |
  | a branch of the step, local or on GitHub | `⊙ branch` | `branch` |
  | none of the above | `— not started` | `none` |

Its output has these sections, each starting at a `== <name>` line:

- `== report`: the heading, the progress line, the table and the script's own `**Check:**` lines
  (one per `⚠ mismatch` row, one per step merged out of order).
- `== next`: the `**Next:**` line, decided by the first row that is not `✓ merged`.
- `== steps`: one line per step, `id|slug|state|pr|merged|branch|via`. §2 reads `state` and `pr`
  from it; the runner reads the rest.
- `== gate` (only with a step id): for the runner, not for this report.

## 2. Initiation issues

The issues `00-bootstrap` filed mirror the steps, on the board when the repo has one. The merged PR
stays the source of truth: this section never changes a row's Status or the Next line; it only adds
`**Check:**` lines where GitHub's issues disagree with the rows, and one `**Board:**` line (step 5).

A step's row is its line in the script's `== steps` section: `slug` is the second field, `state`
the third (`merged` is a `✓ merged` row, `none` a `— not started` one) and `pr` the fourth.
`<sha>` is the output of `git rev-parse origin/main`. Always write `<sha>:<path>`, never
`origin/main:<path>`: Git Bash on Windows rewrites an argument shaped like `origin/main:.cuevik/x`
into a Windows path list, and the read then fails on a file that exists.

1. `git show <sha>:.cuevik/config.json`. Non-zero (not bootstrapped yet): skip this section
   silently. either file's `schemaVersion` below its current one (runner §1 check 3; the lineage
   is `git show <sha>:.cuevik/lineage.json`): one Check line per file,
   `<file> is schemaVersion <n>. Run /cuevik-start:migrate, merge its PR, then re-run.`, then go on.
   No `initiation` key: one Check line,
   `.cuevik/config.json has no initiation issues, so initiation is not tracked in issues.`, then
   skip the rest.
2. `gh issue list --label initiation --state all --limit 100 --json number,state`, once.
3. For each entry in `initiation.stories`, with story `#n`. Its key is a step's `slug`; in a
   config not migrated yet it is one of the step's `aliases`. `<id>` below is that step's id:

   | Condition | Check line |
   | --- | --- |
   | `#n` not in the list | `story #n (<id>) is not an initiation issue on GitHub (deleted, transferred or relabelled)` |
   | `#n` closed, row not `✓ merged` | `story #n (<id>) is closed, but <id> has no merged PR` |
   | `#n` open, row `✓ merged` | `story #n (<id>) is still open, though PR #m merged` |

   A step without `bootstrap: true` that has no entry in `initiation.stories`: `no story for <id>
   in .cuevik/config.json`, unless its row is `— not started` (a repo migrated after the step was
   added has no story for it).
4. The epic `initiation.epic` (only on an `epic-grouped` repo; a `flat` repo has no epic, so skip
   this): not in the list, closed while any row is not `✓ merged`, or open while every row is
   `✓ merged` — one Check line saying which.
5. The board, from `boardState`. `none` is a valid state, not a mismatch, so it is a `**Board:**`
   line, not a Check line: `**Board:** none (issues only). To add one, open a PR on
   .cuevik/config.json (config contract README, "Adding or repairing a board").` In a repo with a
   merged Express PR (a `== steps` line with state `merged` and last field `express`), print no
   `**Board:**` line for `none`: the lane asks for no board. `partial`: `**Board:** partial,
   missing <parts from missing>. To repair it, open a PR on .cuevik/config.json (config
   contract README, "Adding or repairing a board").` `configured`: no line. The issue cross-check
   above runs in every state: it reads the issues, not the board.

## 3. Report

Print, in this order and nothing else:

1. The `== report` section, exactly as the script wrote it (without the `== report` line).
2. One `**Check:**` line for each issue disagreement from §2.
3. The `**Board:**` line from §2 step 5, if there is one.
4. The `== next` section's `**Next:**` line, exactly as the script wrote it.

Never print the `== steps` or `== gate` sections, and never reword a row, a Check line or the
Next line: they are the script's.

## Nothing else

Do not suggest fixes, ask questions, or offer to run any command. The only advice is the Next line
and the pointer inside a `**Board:**` or migration Check line. When a step's runner follows this
file, render the report, then return to the runner; the step continues from there.
