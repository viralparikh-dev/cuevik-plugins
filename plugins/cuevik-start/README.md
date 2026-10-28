# cuevik-start

Start a project the governed way: nine steps (`00`–`08`) from an empty repo to a reviewed `CONTRIBUTING.md`, product concept, PRD, architecture, tech stack, AI tool guide, README and backlog, each landed by its own PR. Part of [cuevik-plugins](../../README.md).

## Commands

| Command | Writes |
|---|---|
| `/cuevik-start:00-bootstrap` | Repo and board, `CONTRIBUTING.md`, `.cuevik/` |
| `/cuevik-start:01-product-concept` | `docs/PRODUCT.md` |
| `/cuevik-start:02-product-requirements` | `docs/PRD.md` |
| `/cuevik-start:03-architecture` | `docs/ARCHITECTURE.md` |
| `/cuevik-start:04-tech-stack` | `docs/TECH-STACK.md`, tooling layer in `CONTRIBUTING.md` |
| `/cuevik-start:05-ai-tool-guide` | `docs/AI-TOOL-GUIDE.md`, tool adapters, `.claude/settings.json` |
| `/cuevik-start:06-readme` | `README.md` |
| `/cuevik-start:07-backlog` | `docs/BACKLOG.md` and the GitHub issues |
| `/cuevik-start:08-finalize` | Removes the initiation-only rules from `CONTRIBUTING.md` |
| `/cuevik-start:status` | Nothing (progress report) |
| `/cuevik-start:cleanup` | Deletes merged local `init/*` branches |

Run one step per session, in order. Each step needs the previous step's PR merged.

## Requirements

`gh` signed in with the `project` scope, a local Claude Code session, and admin rights on the repo. Depends on `cuevik-docs` and `superpowers@claude-plugins-official`.

## Status

`00`–`02` and `status` have been run end to end. `03`–`08` and `cleanup` are built but not yet run live.

Full guide: [Walkthrough](../../docs/guides/Cuevik-Plugins_Walkthrough.md).
