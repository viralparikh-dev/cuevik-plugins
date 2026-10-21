# Cuevik Plugins — Overview

**Plugins:** Cuevik Start, Cuevik Ship, Cuevik Docs  ·  **Author:** Viral Parikh

Claude Code plugins that take a software project from an empty folder to delivered work, with every document and change reviewed and approved by a person before it counts.

---

## What you get

### Cuevik Start

Set a project up the governed way. Nine guided steps take an empty repository to an approved product concept, requirements, architecture, tech stack, AI coding rules, README and backlog.

### Cuevik Ship

Deliver one piece of work at a time, from idea to reviewed code: brainstorm, requirements check, backlog, plan, design and build.

### Cuevik Docs

Keep the documents that define the project honest: audit them for gaps, contradictions and repeats, and change any of them through the same review.

## How it works

- **Reviewed, not trusted.** Every step ends in a change that a person approves. Nothing counts until it is approved.
- **One step at a time.** Each command does one job and will not run until the step before it is approved.
- **Clear ownership.** Each document has a named owner and reviewers, so the right person signs off. On a small team one person can hold both roles.
- **Built on GitHub.** Works with your GitHub repository and project board.

## Who signs off

### Product Owner

Owns what gets built: the product concept, the requirements and the backlog.

### Architect

Owns how it gets built: the architecture, the technology choices, the AI coding rules, the README and the project's working rules.

## Every command

Commands tagged **Planned** are in design and arrive as they are built.

### Cuevik Start

| Command | What it does | Status |
|---|---|---|
| `/cuevik-start:00-bootstrap` | Connects your GitHub repo and sets working rules. | Available |
| `/cuevik-start:01-product-concept` | Captures what the product is, who it is for and why. | Available |
| `/cuevik-start:02-product-requirements` | Turns the concept into testable requirements. | Available |
| `/cuevik-start:03-architecture` | Designs how the system fits together, and why. | Available |
| `/cuevik-start:04-tech-stack` | Chooses and locks the technologies to be used. | Available |
| `/cuevik-start:05-ai-tool-guide` | Sets the rules AI coding assistants must follow. | Available |
| `/cuevik-start:06-readme` | Writes the project's front page, ready to share. | Available |
| `/cuevik-start:07-backlog` | Breaks the requirements into a prioritised backlog. | Available |
| `/cuevik-start:08-finalize` | Hands over permanent rules and closes out setup. | Available |
| `/cuevik-start:status` | Shows how far project setup has got. | Available |
| `/cuevik-start:cleanup` | Tidies up after setup is complete. | Available |

### Cuevik Ship

| Command | What it does | Status |
|---|---|---|
| `/cuevik-ship:01-brainstorm` | Explores a new idea and decides if it goes ahead. | Available |
| `/cuevik-ship:02-audit-prd` | Checks the idea against the requirements. | Available |
| `/cuevik-ship:03-create-backlog` | Turns approved requirements into tracked work. | Available |
| `/cuevik-ship:04-plan-intent` | States the problem and scope before any solution. | Planned |
| `/cuevik-ship:05-design-spec` | Writes the design: behaviour, data and tests. | Planned |
| `/cuevik-ship:06-build-plan` | Turns the design into an ordered list of tasks. | Planned |
| `/cuevik-ship:07-execute-plan` | Builds the plan and delivers it for review. | Planned |
| `/cuevik-ship:cleanup` | Tidies up once the work is delivered. | Planned |

### Cuevik Docs

| Command | What it does | Status |
|---|---|---|
| `/cuevik-docs:audit` | Reviews documents for gaps, contradictions and repeats. | Available |
| `/cuevik-docs:update` | Changes a core document through the same review. | Available |
