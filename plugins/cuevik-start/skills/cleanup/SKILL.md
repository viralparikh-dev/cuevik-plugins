---
name: cleanup
description: Tidies up after cuevik-start. Deletes the local init/* branches whose step PR is merged (GitHub already deleted the remote ones), skipping and reporting any that are not, and once 09-finalize is merged records the End date of the last initiation story and of the initiation epic on the board. Lists everything and asks first. Run it in the project folder, any time, typically after 09-finalize merges.
disable-model-invocation: true
---

# cleanup

Tidies the operator's machine and the board after initiation. It deletes only **local**
branches, never a remote branch, a file, a commit or an issue, and changes nothing until the
operator says yes. The current folder is the project repo. It takes no arguments. Run every
command through the Bash tool.

Load `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` (which step is last) and, for the board update,
the board core `${CLAUDE_PLUGIN_ROOT}/references/contracts/board/board.md` and runner §7 (Field
lookup, Item lookup, Set a value) in `${CLAUDE_PLUGIN_ROOT}/references/runner.md`. If either fails to
load, stop and output: `Error: <file> could not be loaded.` Never hardcode a step list.

This is not a numbered step: it does not follow the runner's workflow, opens no PR and has no
story. Ask with `AskUserQuestion` (runner, Asking The Operator).

## 1. Plan

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh" plan
```

Run it once, silently.

| The script | Do |
| --- | --- |
| exits 0 | Go on to §2 with its output. |
| exits 1 | Its last line is the whole answer: output it and stop. It is a preflight failure (not a git repo, not the repo root, `gh` not signed in, no fetch) or a GitHub query that failed. |
| cannot be run, or exits with anything else | Output `Error: cleanup.sh could not be run: <what the shell said>` and stop. There is no other way to decide what is safe to delete. |

It fetches `origin`, then looks at every local `init/*` branch, whether or not `steps.yml` names
it. A branch is **safe to delete** when a PR from it was merged into `main` and the branch's tip is
exactly that PR's last commit: a squash or rebase merge leaves the branch "unmerged" to git, so
`git branch -d` would refuse it, and the PR's commit id is the proof. Commits made after the PR's
last push are never deleted. Its output has these sections:

- `== branches`: `delete|<branch>|<pr>` for a safe one, `skip|<branch>|<reason>` for the others
  (no merged PR, with an open PR's number if there is one; local commits not in the PR; checked
  out with uncommitted changes).
- `== current`: the checked-out branch and whether the working tree is clean. A safe branch that is
  checked out is deleted after `git checkout main`, which the script does itself.
- `== remote`: `init/*` branches still on GitHub, left by a closed, unmerged PR. Report them; this
  command never deletes one.
- `== last_step`: the last step's id, the branch its merged PR was on and the date it merged
  (`YYYY-MM-DD`), or `-` when it has not merged.

## 2. Board End dates

Only when `merged:` in `== last_step` is a date. Otherwise skip this section and say initiation is
not complete yet.

1. `git show origin/main:.cuevik/config.json` (or `main`, after a pull). `boardState` `none`: skip
   this section silently; there is no board to update. No `initiation` key: skip, and say
   initiation is not tracked in issues.
2. The End date is that `merged:` date. It goes on two items:
   `initiation.stories["<last step's slug>"]` and `initiation.epic`. (Every earlier story got its End
   date when the next step started, runner §7.)
3. Look them up as runner §7 says. An item already showing that End date needs no change. A missing
   field or item: skip and report.

## 3. Confirm, then act

Print one plan: the branches to delete (with their PR numbers), any `git checkout main`, the End
date updates with their commands in a fenced `sh` block, and every skipped item with its reason.
Nothing to do: say so and stop.

Ask once: `Delete <N> local branches and set <M> End dates? For more details, review my Plan that
I articulated above.` (`Yes` / `No, stop`). Only `Yes` acts.

Then, in plan order, delete the branches with one call:

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh" delete <branch> <branch> ...
```

It deletes each branch only if it is still safe at that moment, and stops at the first
`refused|<branch>|<reason>` line: report which were deleted and which was not, and do not delete
anything by another command. Never run `git branch -D` yourself. Then the board updates: a failed
board update never stops cleanup; report it and carry on.

## 4. Report

One short summary: branches deleted, branches skipped with why, End dates set or skipped, remote
`init/*` branches left on GitHub. End with: `Revise a document any time with /cuevik-docs:update
<document>.`
