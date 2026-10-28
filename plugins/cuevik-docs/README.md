# cuevik-docs

Keep a project's source-of-truth documents aligned: audit them for drift and redundancy, and update any of them through a reviewed PR. Part of [cuevik-plugins](../../README.md).

## Commands

| Command | Does |
|---|---|
| `/cuevik-docs:audit [align\|drift\|absorb] [docs-only] [fix] [path]` | Reports gaps (Align), contradictions (Drift) and duplication (Absorb). Read-only unless `fix`, which offers only safe fixes as one PR. |
| `/cuevik-docs:update <document>` | Revises one document through a PR to `main`, using its owner and reviewers from `.cuevik/lineage.json`, and lists the downstream documents to review. |

Documents come from `.cuevik/lineage.json`, written by `/cuevik-start:00-bootstrap`. `docs/BACKLOG.md` is frozen and cannot be updated.

## Requirements

`gh` signed in and a repo with `.cuevik/lineage.json` on `main`. `cuevik-start` and `cuevik-ship` both depend on this plugin.

## Status

Built, not yet run live.

Full guide: [Walkthrough](../../docs/guides/Cuevik-Plugins_Walkthrough.md).
