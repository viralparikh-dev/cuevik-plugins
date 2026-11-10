# Cuevik Plugins

**From empty repo to merged PR: Claude drafts each step, you approve it.**

Cuevik Plugins turn project delivery into a sequence of numbered steps, each one a Claude Code command that runs inside your own repository. One plugin starts a project from an empty repo, one ships work an issue at a time through to a merged code PR, and one keeps the source-of-truth documents aligned throughout. Each later step checks that the previous step's PR is merged before it runs, so work only moves forward once it has been reviewed.

| Plugin | Use it to | Version |
| --- | --- | --- |
| `cuevik-start` | Take an empty repo to a clean, governed, build-ready state: contributing rules, product concept, PRD, architecture, tech stack, test strategy, AI tool guide, README and backlog; or the lean `express` path for an MVP | 0.5.1 |
| `cuevik-ship` | Ship one issue at a time: brainstorm → requirements → backlog → intent → spec → plan → code PR | 0.5.0 |
| `cuevik-docs` | Audit source-of-truth docs for drift and update them through a PR. Both plugins depend on it | 0.5.0 |
| `cuevik-deck` | Turn a Statement of Work into a project kickoff deck: discovery questionnaire → reviewed brief → PowerPoint, Google Slides or Claude Design Slides. Standalone, no repo | 0.5.0 |

## Prerequisites

- [GitHub CLI](https://cli.github.com) (`gh`), signed in (`gh auth login`); add the `project` scope to use a project board: `gh auth refresh -s project`
- A GitHub account. `/cuevik-start:00-bootstrap` creates the repo if it is missing, and a Projects board if you want one, after you confirm each
- A local Claude Code session. Cloud sessions cannot reach GitHub Projects, so a cloud session sets up no board
- The `superpowers` plugin from the official Claude marketplace (`claude-plugins-official`): `cuevik-start` installs it as a dependency, and `/cuevik-start:01-product-concept` runs its brainstorming skill for the interview
- Read access to this repository (it is private)

## Install

In Claude Code:

```text
/plugin marketplace add anthropics/claude-plugins-official
/plugin marketplace add viralparikh-dev/cuevik-plugins
/plugin install cuevik-start@cuevik-plugins
/plugin install cuevik-ship@cuevik-plugins
```

## Versioning

Each plugin is versioned independently. A plugin's `version` in its `plugin.json` follows [semver](https://semver.org) and is bumped only when that plugin's own installable behaviour changes — documentation-only edits (READMEs, guides) do not bump it. As a result the three plugins can sit at different versions at the same time; that is expected, not drift. The authoritative version for any plugin is the `version` field in its `plugin.json`.

The repository git tag (`vX.Y.Z`) marks a repo-wide release milestone — the state of the whole marketplace at a point in time — not an assertion that every plugin is at that number. The Version column in the plugin table above lists each plugin's current `plugin.json` version.

Cutting a release: bump only the plugins whose behaviour changed, update the Version column in the plugin table to match, then tag the repo.

## License

© 2026 Viral Parikh. All rights reserved. See [LICENSE](LICENSE).
