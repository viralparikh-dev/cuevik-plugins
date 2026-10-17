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

### Cuevik Start

| Command | What it does |
|---|---|
| `/cuevik-start:00-bootstrap` | Connects your GitHub repo and sets the working rules. |
| `/cuevik-start:01-product-concept` | Captures what the product is, who it is for and why. |
| `/cuevik-start:02-product-requirements` | Turns the concept into clear, testable requirements. |
| `/cuevik-start:03-architecture` | Designs how the system fits together, and why. |
| `/cuevik-start:04-tech-stack` | Chooses and locks the technologies to be used. |
| `/cuevik-start:05-ai-tool-guide` | Sets the rules AI coding assistants must follow. |
| `/cuevik-start:06-readme` | Writes the project's front page, ready to share. |
| `/cuevik-start:07-backlog` | Breaks the requirements into a prioritised backlog. |
| `/cuevik-start:08-finalize` | Hands over the permanent rules and closes out setup. |
| `/cuevik-start:status` | Shows how far project setup has got. |
| `/cuevik-start:cleanup` | Tidies up after setup is complete. |

### Cuevik Ship

| Command | What it does |
|---|---|
| `/cuevik-ship:01-brainstorm` | Explores a new idea and decides whether it goes ahead. |
| `/cuevik-ship:02-audit-prd` | Checks the idea against the requirements. |
| `/cuevik-ship:03-create-backlog` | Turns approved requirements into tracked work. |
| `/cuevik-ship:04-plan-intent` | States the problem and scope before any solution. |
| `/cuevik-ship:05-design-spec` | Writes the detailed design: behaviour, data and tests. |
| `/cuevik-ship:06-build-plan` | Turns the design into an ordered list of tasks. |
| `/cuevik-ship:07-execute-plan` | Builds the plan and delivers it for review. |
| `/cuevik-ship:cleanup` | Tidies up once the work is delivered. |

### Cuevik Docs

| Command | What it does |
|---|---|
| `/cuevik-docs:audit` | Reviews documents for gaps, contradictions and repeats. |
| `/cuevik-docs:update` | Changes a core document through the same review. |
