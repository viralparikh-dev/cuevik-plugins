# cuevik-ship

The daily delivery loop for repos set up with `cuevik-start`: idea, requirements, backlog, intent, spec, plan, executed PR. One issue per worktree, one step per session, one approval per step. Part of [cuevik-plugins](../../README.md).

## Commands

| Command | Does | PR to |
|---|---|---|
| `/cuevik-ship:01-brainstorm` | Explores an idea or existing issue; approve or reject | `ship/<n>-<slug>/issue` |
| `/cuevik-ship:02-audit-prd` | Checks the idea against PRODUCT and PRD, ratifies requirements | `main` |
| `/cuevik-ship:03-create-backlog` | Files the epic and stories on GitHub | none |
| `/cuevik-ship:04-plan-intent` | `intent.md`: problem and scope | `ship/<n>-<slug>/issue` |
| `/cuevik-ship:05-design-spec` | `spec.md`: behaviour, data, rules, tests | `ship/<n>-<slug>/issue` |
| `/cuevik-ship:06-build-plan` | `plan.md`: ordered tasks | `ship/<n>-<slug>/issue` |
| `/cuevik-ship:07-execute-plan` | Builds the plan, opens the code PR (`Closes #<n>`) | `main` |
| `/cuevik-ship:cleanup <n>` | Removes the worktree and local branches, archives the issue branch as a tag | none |

Files under `docs/ship/<n>-<slug>/` live on the issue's own branch and never reach `main`.

## Install

```text
/plugin marketplace add viralparikh-dev/cuevik-plugins
/plugin install cuevik-ship@cuevik-plugins
```

The repository is private: you need read access and git credentials on your machine (`gh auth login`, then `gh auth setup-git`).

## Requirements

A repo bootstrapped with `/cuevik-start:00-bootstrap` (it reads `.cuevik/config.json`), `gh` (with the `project` scope when the repo has a board), a local Claude Code session. Depends on `cuevik-docs`. Optional plugin setting `worktree_root`: the folder where each issue's worktree is created.

## Status

Built, not yet run live.

Full guide: [Walkthrough](../../docs/guides/Cuevik-Plugins_Walkthrough.md).
