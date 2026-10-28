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

## 1. Preconditions

1. `gate.md` common preconditions 1–3 and 5, then `git fetch --prune origin`.
2. **The main checkout, not a worktree.** `git rev-parse --git-dir` and `git rev-parse
   --git-common-dir` print the same folder; otherwise **STOP**: `Run cleanup from the main
   checkout, not from a worktree.` (It may be about to remove this very folder.)
3. **Slug** (`branches.md`, Names): from `git ls-remote --heads origin 'refs/heads/ship/<n>-*'`,
   or, when the remote branches are gone, from local `ship/<n>-*` branches or the worktree list.
   Nothing anywhere: **STOP** — nothing to clean for `#<n>`.

## 2. Gate

Both must hold, or **STOP** saying which:

- `gh pr list --head ship/<n>-<slug>/07-execute-plan --base main --state merged` returns a PR,
  **or** `gh issue view <n> --json state,stateReason` is `CLOSED` with reason `NOT_PLANNED`.
  There is no override flag.
- No open PR from any `ship/<n>-` branch:
  `gh pr list --state open --json number,headRefName --jq '.[] | select(.headRefName | startswith("ship/<n>-"))'`
  returns nothing. (An open 01 PR on a rejected idea is the record: merge it first.)

## 3. Inventory

Collect, silently, then show it all in §4:

1. **Worktree** — `git worktree list --porcelain`: the entry whose branch starts with
   `refs/heads/ship/<n>-<slug>/`. Refuse to remove it (and say why) when
   `git -C <path> status --porcelain` is not empty: uncommitted work.
2. **Local branches** — `git for-each-ref --format='%(refname:short) %(objectname)'
   'refs/heads/ship/<n>-<slug>/'`. A branch is safe to delete when its tip is reachable from a
   remote ref (`git branch -r --contains <tip>` prints a line), or equals the `headRefOid` of a
   merged or closed PR from it (`gh pr list --head <branch> --state all --json
   state,headRefOid`): squash merges leave merged work unreachable from any remote, which this
   second test covers. Any other branch has **unpushed commits**: refuse the whole cleanup and
   list them; never delete unpushed work.
3. **Archive** — the tag `ship-archive/<n>-<slug>` on `origin/ship/<n>-<slug>/issue`.
   `git ls-remote --tags origin ship-archive/<n>-<slug>` already lists it: fine if it points at
   the same commit (a re-run); a different commit: **STOP** and report both.
4. **Remote branches** — `ship/<n>-<slug>/issue` (archived, then deleted), plus any other remote
   `ship/<n>-<slug>/*` left by a closed, unmerged PR (deleted; there is no open PR, by §2).
   Merged step and code branches are already gone (auto-delete head branches).

## 4. Confirm, then act

Print the plan: the worktree path; each local branch; the tag and the commit it points at; each
remote branch to delete; every command in a fenced `sh` block; and anything refused, with why.

Ask once: `Remove the worktree and <N> local branches, archive and delete the issue branch?
For more details, review my Plan that I articulated above.` (`Yes` / `No, stop`). Then, in order:

```sh
git worktree remove <path>                                    # never --force
git worktree prune
git branch -D <each local ship/<n>-<slug>/* branch>           # -D: squash-merged branches look unmerged to git
git tag ship-archive/<n>-<slug> origin/ship/<n>-<slug>/issue  # skipped when §3.3 found it already
git push origin ship-archive/<n>-<slug>
git push origin --delete ship/<n>-<slug>/issue
git push origin --delete <each leftover remote step branch>
```

Removing the worktree also removes the local `docs/ship/<n>-<slug>/`, since `main` never has it.
The tag is pushed **before** the issue branch is deleted, so the commits every References
permalink points at stay reachable. Any command failing: **STOP** there and report what was done
and what was not; a re-run picks up from the inventory.

## 5. Report

What was removed, archived and deleted, and anything refused. The issue stays as it is; its
References links keep working through the archive tag.
