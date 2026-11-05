---
name: cleanup
description: Tidies up after cuevik-start. Deletes the local init/* branches whose step PR is merged (GitHub already deleted the remote ones), skipping and reporting any that are not, and once 09-finalize is merged records the End date of the last initiation story and of the initiation epic on the board. Lists everything and asks first. Run it in the project folder, any time, typically after 09-finalize merges.
disable-model-invocation: true
---

# cleanup

Tidies the operator's machine and the board after initiation. It deletes only **local**
branches, never a remote branch, a file, a commit or an issue, and changes nothing until the
operator says yes. The current folder is the project repo. It takes no arguments. Run every `gh`
command through the Bash tool.

Load `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` (the steps, their `branch` fields, and which
step is last) and, for the board update, `${CLAUDE_PLUGIN_ROOT}/references/runner.md` §7 (Field
lookup, Item lookup, Set a value). If either fails to load, stop and output: `Error: <file> could
not be loaded.` Never hardcode a step list.

This is not a numbered step: it does not follow the runner's workflow, opens no PR and has no
story. Ask with `AskUserQuestion` (runner, Asking The Operator).

## 1. Preflight

Stop at the first failure and output only its message.

1. `git rev-parse --show-prefix` — non-zero: `This folder is not a git repo.` Non-empty: `Run
   cleanup from the repo root.`
2. `gh auth status` — non-zero: `gh is not signed in. Run gh auth login, then re-run.`
3. `git fetch --prune origin` — non-zero: `Could not fetch origin. Cleanup needs GitHub's current
   state.`

## 2. Branches

1. Local candidates: `git for-each-ref --format='%(refname:short) %(objectname)' refs/heads/init/`.
   None: say so and go to §3.
2. For each, `gh pr list --head <branch> --base main --state merged --json number,headRefOid,mergedAt`.

   | Condition | Action |
   | --- | --- |
   | No merged PR | **Skip** — report `<branch>: no merged PR` (and an open PR's number, if `gh pr list --head <branch> --state open` finds one) |
   | Merged PR, local tip equals a merged PR's `headRefOid` | **Delete** |
   | Merged PR, local tip differs (commits made after the PR's last push) | **Skip** — report `<branch>: local commits not in PR #n`; never delete unpushed work |

   A branch not named in `steps.yml` but under `init/` follows the same rules.
3. The current branch (`git branch --show-current`) is a delete candidate: it must be left first.
   Clean working tree (`git status --porcelain` empty): the plan includes `git checkout main`.
   Otherwise skip that branch and report why.
4. Remote `init/*` branches still on GitHub (`git ls-remote --heads origin 'refs/heads/init/*'`,
   left by a closed, unmerged PR): report them; never delete them here.

Deletion uses `git branch -D <branch>`: a squash or rebase merge leaves the branch "unmerged" to
git, so `-d` would refuse a branch whose PR is merged. The `headRefOid` check above is what makes
`-D` safe.

## 3. Board End dates

Only when the last step in `steps.yml` (today `09-finalize`) has a merged PR, from §2's query or
`gh pr list --head <its branch> --base main --state merged --json mergedAt --jq '.[0].mergedAt'`.
Otherwise skip this section and say initiation is not complete yet.

1. `git show origin/main:.cuevik/config.json` (or `main`, after a pull). `boardState` `none`: skip
   this section silently; there is no board to update. No `initiation` key: skip, and say
   initiation is not tracked in issues.
2. The End date is the `YYYY-MM-DD` part of that `mergedAt`. It goes on two items:
   `initiation.stories["<last step id>"]` and `initiation.epic`. (Every earlier story got its End
   date when the next step started, runner §7.)
3. Look them up as runner §7 says. An item already showing that End date needs no change. A missing
   field or item: skip and report.

## 4. Confirm, then act

Print one plan: the branches to delete (with their PR numbers), any `git checkout main`, the End
date updates with their commands in a fenced `sh` block, and every skipped item with its reason.
Nothing to do: say so and stop.

Ask once: `Delete <N> local branches and set <M> End dates? For more details, review my Plan that
I articulated above.` (`Yes` / `No, stop`). Only `Yes` acts.

Then run them in plan order. A failed branch delete stops the branch deletes and reports which
were done. A failed board update never stops cleanup: report it and carry on.

## 5. Report

One short summary: branches deleted, branches skipped with why, End dates set or skipped, remote
`init/*` branches left on GitHub. End with: `Revise a document any time with /cuevik-docs:update
<document>.`
