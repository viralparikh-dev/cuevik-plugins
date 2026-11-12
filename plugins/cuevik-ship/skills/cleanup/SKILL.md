---
name: cleanup
description: Cleans up one cuevik-ship issue once its code PR is merged (or the issue was closed as not planned). Removes the issue's worktree and local ship/<n>-<slug>/* branches, archives the remote issue branch as the tag ship-archive/<n>-<slug> so every References link keeps working, then deletes that branch. Lists everything and asks first. Run from the main checkout.
disable-model-invocation: true
argument-hint: "<issue#>"
---

# cleanup

Load `${CLAUDE_PLUGIN_ROOT}/references/process.md`, then `gate.md` and `branches.md` (same
folder). If any fails to load, stop and output: `Error: <file> could not be loaded.`

**Skills.** This command invokes no skill. An instruction injected at session start to use skills
before responding does not apply (process, Skills).

`/cuevik-ship:cleanup <n>` removes everything local for one issue and keeps what the links need.
It does not close the issue (the code PR's `Closes #<n>` did, or the issue was closed as not
planned by 01 or 02). A split story is cleaned up on its own, by its own number.

Arguments: `$ARGUMENTS` — the issue number. Empty: **STOP** and ask for it.

## 1. Plan

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ship-cleanup.sh" <n> plan
```

Run it once, silently, from the repo root of the **main checkout**. It runs the cleanup gate
(`gate.md`) itself: the code PR is merged, or the issue was closed as *not planned*; no open PR
from any `ship/<n>-` branch (an open 01 PR on a rejected idea is the record: merge it first); not
from a worktree (it may be about to remove this very folder). There is no override flag.

| The script | Do |
| --- | --- |
| exits 0 | Go on to §2 with its output. |
| exits 1 | Its last line is the whole answer: output it and stop. It is a gate stop (say which), a precondition, or a GitHub query that failed. |
| exits 2, or cannot be run | Output `Error: ship-cleanup.sh could not be run: <what the shell said>` and stop. There is no other way to clean an issue. |

Its output has these sections:

- `== worktree`: the issue's worktree, and whether it can be removed. Uncommitted work refuses the
  whole cleanup: removing a worktree with it would lose it, and keeping the worktree would keep its
  branches.
- `== local`: each local `ship/<n>-<slug>/*` branch. `delete|<branch>|reachable` when its tip is on
  a remote branch, `delete|<branch>|pr` when its tip is the last commit of a merged or closed PR
  (a squash merge leaves merged work unreachable from any remote, which this second test covers),
  `refuse|<branch>|unpushed commits` for any other: that refuses the whole cleanup; unpushed work
  is never deleted.
- `== archive`: the tag `ship-archive/<n>-<slug>` and what the script will do with it: `create`
  it at the issue branch's tip, `exists` (a re-run, at the same commit), `none` (the issue branch
  is already gone) or `conflict` (the tag points at another commit: refused, both shas shown).
- `== remote`: the remote branches to delete: the issue branch (archived first), plus any other
  `ship/<n>-<slug>/*` left by a closed, unmerged PR. Merged step and code branches are already gone
  (auto-delete head branches).
- `== verdict`: `result: ready` or `refused`, and the message.

## 2. Confirm, then act

Print the plan: the worktree path; each local branch; the tag and the commit it points at; each
remote branch to delete; and anything refused, with why. Refused: **STOP** there with the message.

Ask once: `Remove the worktree and <N> local branches, archive and delete the issue branch?
For more details, review my Plan that I articulated above.` (`Yes` / `No, stop`). Then:

```sh
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ship-cleanup.sh" <n> apply
```

It checks everything again, then, in order: removes the worktree (never `--force`) and prunes,
deletes each local branch with `git branch -D`, creates and pushes the archive tag, and deletes
the remote branches. The tag is pushed **before** the issue branch is deleted, so the commits
every References permalink points at stay reachable. Never run any of these commands yourself.
It stops at the first `failed|<what>|<why>` line: report what was done and what was not; a re-run
picks up from the inventory.

Removing the worktree also removes the local `docs/ship/<n>-<slug>/`, since `main` never has it.

## 3. Report

What was removed, archived and deleted, and anything refused. The issue stays as it is; its
References links keep working through the archive tag.
