# Contract: `.cuevik/lineage.json`

The project's source-of-truth documents: which `cuevik-start` step writes each one, which documents
it is written from, and who owns and reviews it.

`steps` names each step by its slug (`tech-stack`, not `04-tech-stack`), so renumbering the steps
changes nothing here. Version 1 used the numbered ids: bring an older file current with
`/cuevik-start:migrate` (by hand: the config contract README, "Migrating from an older
schemaVersion").

| File | What it is |
|---|---|
| `lineage.schema.json` | JSON Schema (2020-12). The definition. |
| `lineage.example.json` | The default lineage. `00-bootstrap` writes this content. |

## Upstream only

Each document lists only its **direct** upstream documents. Downstream is derived: the downstream
set of `X` is every document that reaches `X` by following `upstream` links. Storing one direction
means the two can never disagree. `check-contracts` rejects unknown paths and cycles.

From the default lineage:

| Changed | Downstream (derived) |
|---|---|
| `docs/PRODUCT.md` | PRD, ARCHITECTURE, TECH-STACK, TEST-STRATEGY, AI-TOOL-GUIDE, README, BACKLOG, CONTRIBUTING |
| `docs/PRD.md` | ARCHITECTURE, TECH-STACK, TEST-STRATEGY, AI-TOOL-GUIDE, README, BACKLOG, CONTRIBUTING |
| `docs/ARCHITECTURE.md` | TECH-STACK, TEST-STRATEGY, AI-TOOL-GUIDE, README, BACKLOG, CONTRIBUTING |
| `docs/TECH-STACK.md` | TEST-STRATEGY, AI-TOOL-GUIDE, README, BACKLOG, CONTRIBUTING |
| `docs/TEST-STRATEGY.md` | AI-TOOL-GUIDE, README, BACKLOG |
| `docs/AI-TOOL-GUIDE.md` | README, BACKLOG |
| `README.md` | BACKLOG |
| `docs/BACKLOG.md`, `CONTRIBUTING.md` | none |

## Choices in the default

- Upstream links are broad on purpose: a PRD or ARCHITECTURE change also flags README.
- `CONTRIBUTING.md` is written by three steps (`00` governance, `04` tooling layer, `09` finalize).
  Its upstream is `docs/TECH-STACK.md`, because the tooling layer is written from it. The PRD and
  ARCHITECTURE are TECH-STACK's inputs, not CONTRIBUTING's, and `09-finalize` needs BACKLOG merged
  only as a run gate, not as a content source.
- `docs/TEST-STRATEGY.md` feeds the AI tool guide, README and BACKLOG, following the same pattern:
  each later document is downstream of the earlier ones. README only links to it.
- `docs/BACKLOG.md` is `frozen`: GitHub is the backlog after initiation. Consumers skip it
  when flagging downstream updates.
- Tool adapters (`CLAUDE.md`, `.github/copilot-instructions.md`) are not listed. They are
  conditional outputs of `06-ai-tool-guide`, not source-of-truth documents.
- `owner` and `reviewers` are roles, not GitHub handles.

## Consumers

| Plugin | Uses it to | Access |
|---|---|---|
| `cuevik-start` | `00-bootstrap` writes it | write |
| `cuevik-docs` | `update`: reviewer gate and downstream checklist. `audit`: which documents to audit | read |
| `cuevik-ship` | which documents a work item may cite or change | read |

Each consumer keeps a copy of this folder at `plugins/<plugin>/references/contracts/lineage/`,
declared in [`../consumers.json`](../consumers.json).

## Changing it

1. Edit `lineage.schema.json` and/or the example. Increase `schemaVersion` when a key is added,
   removed or renamed.
2. Copy this folder over every consumer's copy listed in `consumers.json`.
3. Run `python scripts/check-contracts.py` (once: `python -m pip install -r scripts/requirements.txt`).
   It fails on an invalid example or any copy that differs. `--target <repo>` also checks that
   repo's `.cuevik/` files.
