# cuevik-deck

Turn a Statement of Work into a project kickoff deck. A structured discovery questionnaire captures the engagement, technical landscape, agile ways of working, NFRs and governance, then renders a client-ready deck. Part of [cuevik-plugins](../../README.md).

## Commands

| Command | Does |
|---|---|
| `/cuevik-deck:kickoff-meeting [sow-path] [pptx\|slides\|design]` | Reads the SoW, runs the discovery questionnaire pre-filled from it, assembles a reviewed `KICKOFF-BRIEF.md`, then renders the deck as PowerPoint (default), Google Slides or Claude Design Slides. |

Writes two standalone files — `KICKOFF-BRIEF.md` and the deck — to a folder you choose. Unlike the other cuevik plugins it needs no git repo and opens no PR.

## Install

```text
/plugin marketplace add viralparikh-dev/cuevik-plugins
/plugin install cuevik-deck@cuevik-plugins
```

The repository is private: you need read access and git credentials on your machine (`gh auth login`, then `gh auth setup-git`).

## Requirements

None of the cuevik repo plumbing. For the deck: PowerPoint needs no setup; Google Slides needs the Google Workspace connector authorized; Claude Design Slides needs the artifacts slide-deck type available.

## Status

Built, not yet run live.

Full guide: [Walkthrough](../../docs/guides/Cuevik-Plugins_Walkthrough.md).
