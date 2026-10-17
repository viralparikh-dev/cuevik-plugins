# cuevik-start Output Templates

These are the **output templates** for the documents the cuevik-start steps
generate (`PRODUCT.md`, `PRD.md`, `ARCHITECTURE.md`, …). Each template is a
self-contained, fill-in-the-blanks skeleton: a lean header block, the
cross-document reference map, and the canonical numbered sections for that
document.

They standardize the *format and structure* of generated docs. They do **not**
change the section content model the step skills enforce.

## The layer model

| Layer | Owns | Lives in |
| --- | --- | --- |
| Template | Structure — the literal headings and their order | `templates/<DOC>.template.md` |
| Step skill | Meaning — what each section must contain | `skills/<id>/SKILL.md` |
| Writing rules | The shared writing standard | `templates/_writing-rules.md` |
| References | The cross-document map | `templates/_doc-references.md` |
| Lineage | Owner, upstream and downstream of each document | the project's `.cuevik/lineage.json` |

The template and the step skill describe the same sections from two angles. The
rule that keeps them from diverging: **the template is the only place headings
are enumerated; the skill never re-lists headings as prose.** A skill's "What
This Document Covers" is a one-line-per-section map whose bold lead text matches
the template heading exactly.

## How the runner consumes a template

`references/runner.md` §4 drives this. For a document-producing step:

1. Load the template named in the step's `template:` field (`references/steps.yml`).
2. Fill the header block — `Owner`, `Last updated`, `Source of truth for`, and
   `Derived from` / `Downstream`. `Owner`, `Derived from` and `Downstream` come
   from the document's entry in `.cuevik/lineage.json` (downstream is derived by
   following `upstream` links); the templates never hardcode them.
3. Replace the `<!-- @inject: _doc-references.md -->` marker with the block
   between the `BEGIN INJECT` / `END INJECT` markers in `_doc-references.md`.
4. Replace every `[placeholder]` with interview answers.
5. Preserve the header block, every top-level (`## N.`) heading, and the
   dividers. Do not add or drop top-level sections.
6. Apply `_writing-rules.md` to all prose, requirements, and tables.

## The inject marker

`<!-- @inject: _doc-references.md -->` is replaced verbatim with the injectable
block from `_doc-references.md`. Editing the reference map in one place
propagates it to every generated document. `README.template.md` is the
exception: it carries its own **Further Reading** section instead of the
references table (see that template).

## Inventory

| Template | Document | Notes |
| --- | --- | --- |
| `PRODUCT.template.md` | PRODUCT.md | Full skeleton |
| `PRD.template.md` | PRD.md | Full skeleton + TOC |
| `ARCHITECTURE.template.md` | ARCHITECTURE.md | Full skeleton + TOC |
| `TECH-STACK.template.md` | TECH-STACK.md | Full skeleton |
| `README.template.md` | README.md | Header-block exception |
| `AI-TOOL-GUIDE.template.md` | AI-TOOL-GUIDE.md | Main doc only; adapters excluded |
| `BACKLOG.template.md` | BACKLOG.md | Manifest skeleton |

`CONTRIBUTING.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` are not
templated here — they are appended layers or tool config with preserved blocks,
governed by `references/steps.yml` special actions.
