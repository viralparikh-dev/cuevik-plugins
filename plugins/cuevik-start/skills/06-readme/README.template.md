# [Project Name]

> [Vision — verbatim copy of the Vision line from PRODUCT.md §1 Overview. Do not
paraphrase.]

[Badge row — one static shields.io badge per core technology: each Language &
Framework from TECH-STACK.md §1 that a developer directly installs or invokes, plus
the primary platform from §3. Exclude platform-managed runtimes (one the §3 platform
provides) — the platform badge covers them. No live-endpoint badges.]

## Project Overview

[Condensed cold-start summary for a developer — 3–4 sentences on what the product
does and why it exists. Summarize PRODUCT.md; do not restate it in full. Link to
PRODUCT.md as the source of truth.]

## Key Concepts

[Developer glossary — 3–5 terms or ideas a new developer must understand before
reading the code. Draw primarily on structural concepts from ARCHITECTURE.md
(components, boundaries, data flow, key patterns), plus only the few unavoidable
domain nouns from PRODUCT.md §1/§2. Do not restate PRODUCT.md §3 Features here —
that is a product capability list, not a glossary.]

- **[Term]** — [plain-language definition]

## Prerequisites

[Exact tools, runtimes, and accounts required before setup, with version
numbers.]

- [Tool / runtime] [version]

## Environment Setup

[Step-by-step configuration. Document every key in `.env.example`: description,
required or optional, and where to obtain the value.]

```bash
cp .env.example .env
```

| Variable | Required | Description | Where to obtain |
| --- | --- | --- | --- |
| [KEY] | [yes/no] | [what it configures] | [service dashboard / team wiki] |

## Install & Run

[Exact commands to install dependencies and start the app locally.]

```bash
[install command]
[run command]
```

## Run Tests

[Exact command(s) to run the test suite.]

```bash
[test command]
```

## Project Structure

[Top-level folder map with one line per folder.]

```text
[folder]/   [purpose]
```

## Further Reading

- [PRD.md](docs/PRD.md) — requirements and feature scope
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — system structure and design decisions
- [TECH-STACK.md](docs/TECH-STACK.md) — approved technologies and usage rules
- [AI-TOOL-GUIDE.md](docs/AI-TOOL-GUIDE.md) — rules and constraints for AI tools

---

> _Last updated:_ [YYYY-MM-DD] · _Maintainer:_ [owner / team]
