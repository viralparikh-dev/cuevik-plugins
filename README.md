# Cuevik Plugins

**From empty repo to merged PR: Claude drafts each step, you approve it.**

Cuevik Plugins turn project delivery into a sequence of numbered steps, each one a Claude Code command that runs inside your own repository. One plugin starts a project from an empty repo, one ships work an issue at a time through to a merged code PR, and one keeps the source-of-truth documents aligned throughout. Each later step checks that the previous step's PR is merged before it runs, so work only moves forward once it has been reviewed.

| Plugin | Use it to | Entry command |
| --- | --- | --- |
| `cuevik-start` | Take an empty repo to a clean, governed, build-ready state: contributing rules, product concept, PRD, architecture, tech stack, AI tool guide, README and backlog | `/cuevik-start:00-bootstrap` |
| `cuevik-ship` | Ship one issue at a time: brainstorm → requirements → backlog → intent → spec → plan → code PR | `/cuevik-ship:01-brainstorm` |
| `cuevik-docs` | Audit source-of-truth docs for drift and update them through a PR. Both plugins depend on it | `/cuevik-docs:audit` |

## Prerequisites

- [GitHub CLI](https://cli.github.com) (`gh`), signed in with the `project` scope: `gh auth refresh -s project`
- A GitHub account. `/cuevik-start:00-bootstrap` creates the repo and Projects board if they are missing, after you confirm each one
- A local Claude Code session. Cloud sessions cannot reach GitHub Projects
- Read access to this repository (it is private)

## Install

In Claude Code:

```text
/plugin marketplace add viralparikh-dev/cuevik-plugins
/plugin install cuevik-start@cuevik-plugins
/plugin install cuevik-ship@cuevik-plugins
```

## License

© 2026 Viral Parikh. All rights reserved. See [LICENSE](LICENSE).
