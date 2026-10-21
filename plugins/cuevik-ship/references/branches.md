# Branches and worktrees

One separate working copy (git worktree) per issue, so several issues can be in flight at once.
All of an issue's branches share the prefix `ship/<n>-<slug>/`, so cleanup finds them by prefix.
(Git cannot hold both `X` and `X/child` as branches, hence `.../issue`, not a bare
`ship/<n>-<slug>`.)

## Names

- `<n>` — the issue number, as GitHub shows it (no padding).
- `<slug>` — kebab-case, at most five words, lower case, from the idea's working name or the
  issue title with any `PRD-NNN:` prefix and `(<Priority>)` suffix removed. Fixed when
  `.../issue` is created and never renamed, even if the issue title changes later, so no link,
  commit or PR reference goes stale.
- Finding an existing slug: `git ls-remote --heads origin 'refs/heads/ship/<n>-*'`. More than one
  slug for the same `<n>`: **STOP** and report them.

| Branch | Created by | From | Holds |
| --- | --- | --- | --- |
| `ship/<n>-<slug>/issue` | `01-brainstorm`, or `04-plan-intent` for an issue without one | `origin/main` | only `docs/ship/<n>-<slug>/` |
| `ship/<n>-<slug>/01-brainstorm`, `/04-plan-intent`, `/05-design-spec`, `/06-build-plan` | that step | `origin/ship/<n>-<slug>/issue` | that step's artifact |
| `ship/<n>-<slug>/02-audit-prd`, `/07-execute-plan` | that step | `origin/main` | changes for `main` only |

The issue branch starts at `main`'s current commit and is pushed at once, so it exists on GitHub
before any PR targets it:

```sh
git branch ship/<n>-<slug>/issue origin/main
git push -u origin ship/<n>-<slug>/issue
```

Remote step and code branches are deleted by GitHub when their PR merges (the repo's
auto-delete head branches setting, turned on by `00-bootstrap`). The issue branch never merges;
`/cuevik-ship:cleanup` archives it as the tag `ship-archive/<n>-<slug>` and deletes it.

## The worktree

- **Root.** The folder that holds worktrees is a machine fact, not a project fact. Each step that
  needs it shows the plugin's `worktree_root` option in its `SKILL.md` (only skill text gets the
  value substituted, not this file). Resolve it in this order:
  1. That value, unless it is empty or still reads as a literal `${user_config...}` placeholder.
  2. `git config --global --get cuevik-ship.worktreeRoot`.
  3. Ask the operator in chat for an absolute folder (typed value), then ask `Save it for next
     time?` (`Yes` / `No`); on `Yes`, `git config --global cuevik-ship.worktreeRoot <folder>`.
  Never pick a folder for them. The folder is created if missing (`mkdir -p`).
- **Path.** `<root>/<repo name>/<n>-<slug>`, the repo name from `gh repo view --json name --jq
  .name`.
- **Create** (from the main checkout, clean working tree):

  ```sh
  git fetch origin
  git worktree add <path> -b ship/<n>-<slug>/<NN-step> origin/ship/<n>-<slug>/issue
  ```

- **Find**: `git worktree list --porcelain` — the entry whose `branch` starts with
  `refs/heads/ship/<n>-<slug>/`. A step run from the main checkout for an issue that already has
  a worktree tells the operator to open a session in that folder and stops.
- **Each step works inside the issue's worktree.** It creates its own branch there, after the
  previous step's PR has merged and the tree is clean:

  ```sh
  git fetch --prune origin
  git switch -c ship/<n>-<slug>/<NN-step> origin/ship/<n>-<slug>/issue   # 04–06
  git switch -c ship/<n>-<slug>/<NN-step> origin/main                    # 02, 07
  ```

  A branch cut from `origin/main` has no `docs/ship/` folder: read the issue's files with
  `git show origin/ship/<n>-<slug>/issue:docs/ship/<n>-<slug>/<file>`.
- **The branch already exists** (locally or on GitHub, e.g. after a closed PR): ask `Reuse it` /
  `Delete it`; delete only after a yes. Never use another name: the next step's gate finds this
  step's PR by its exact branch.
- Never stash, reset or discard the operator's changes to make a switch or a worktree work: stop
  and say what is in the way.

## PRs

- Step PRs into `.../issue` (01, 04, 05, 06): `gh pr create --base ship/<n>-<slug>/issue --head
  ship/<n>-<slug>/<NN-step>`; body ends `Refs #<n>`.
- PRs to `main` (02, 07): `--base main`; 02 says `Refs #<n>`, 07 says `Closes #<n>`.
- Title: `<type>(ship): <what> (#<n>)`, e.g. `docs(ship): intent for #41`.
- Push only after the operator says yes: `git push -u origin <branch>`.
