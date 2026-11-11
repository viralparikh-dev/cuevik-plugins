# cuevik-start

Start a project the governed way: ten steps (`00`–`09`) from an empty repo to a reviewed `CONTRIBUTING.md`, product concept, PRD, architecture, tech stack, test strategy, AI tool guide, README and backlog, each landed by its own PR. For an MVP or spike, `express` is the lean path: governance, a lean product concept and PRD, and the backlog, in one session and one PR. Part of [cuevik-plugins](../../README.md).

## Commands

| Command | Writes |
|---|---|
| `/cuevik-start:00-bootstrap` | Repo, an optional board, `CONTRIBUTING.md`, `.cuevik/` |
| `/cuevik-start:01-product-concept` | `docs/PRODUCT.md` |
| `/cuevik-start:02-product-requirements` | `docs/PRD.md` |
| `/cuevik-start:03-architecture` | `docs/ARCHITECTURE.md` |
| `/cuevik-start:04-tech-stack` | `docs/TECH-STACK.md`, tooling layer in `CONTRIBUTING.md` |
| `/cuevik-start:05-test-strategy` | `docs/TEST-STRATEGY.md` |
| `/cuevik-start:06-ai-tool-guide` | `docs/AI-TOOL-GUIDE.md`, tool adapters, `.claude/settings.json` |
| `/cuevik-start:07-readme` | `README.md` |
| `/cuevik-start:08-backlog` | `docs/BACKLOG.md` and the GitHub issues |
| `/cuevik-start:09-finalize` | Removes the initiation-only rules from `CONTRIBUTING.md` |
| `/cuevik-start:express` | The lean path in one PR: `CONTRIBUTING.md`, `.cuevik/`, a lean `docs/PRODUCT.md` and `docs/PRD.md`, `docs/BACKLOG.md` and the GitHub issues |
| `/cuevik-start:status` | Nothing (progress report) |
| `/cuevik-start:cleanup` | Deletes merged local `init/*` branches |
| `/cuevik-start:migrate` | A PR that brings an older repo's `.cuevik/` files up to the current versions and step ids |

Run one step per session, in order. Each step needs the previous step's PR open or merged, and every earlier step's PR merged. `express` is the exception: one session, one PR, for the work of `00`, `01`, `02` and `08`.

## Install

```text
/plugin marketplace add viralparikh-dev/cuevik-plugins
/plugin install cuevik-start@cuevik-plugins
```

The repository is private: you need read access and git credentials on your machine (`gh auth login`, then `gh auth setup-git`).

## Requirements

`gh` signed in (with the `project` scope if you want a board), a local Claude Code session, and admin rights on the repo. Depends on `cuevik-docs` and `superpowers@claude-plugins-official`.

## Status

`00`–`02` and `status` have been run end to end. `03`–`09`, `cleanup`, `express` and `migrate` are built but not yet run live.

Full guide: [Walkthrough](../../docs/guides/Cuevik-Plugins_Walkthrough.md).
