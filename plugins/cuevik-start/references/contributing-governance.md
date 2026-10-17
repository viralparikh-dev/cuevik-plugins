# CONTRIBUTING.md Governance Layer (shared content)

`00-bootstrap` writes the content between the `BEGIN CONTENT` / `END CONTENT` markers below to
the project's `CONTRIBUTING.md`, verbatim. It is fixed text, not a template: there is nothing to
interview for, and `08-finalize` depends on the `INITIATION-ONLY` markers being exact.

- No `CONTRIBUTING.md` on `main`: write the content as the whole file.
- `CONTRIBUTING.md` already on `main`: keep the existing text verbatim and insert the content
  after the file's first `#` heading, without the content's own `# Contributing` line (see
  `skills/00-bootstrap/SKILL.md`).

Layers written later, never here:

- **Tooling layer** — appended by `04-tech-stack` from `docs/TECH-STACK.md`.
- **Development-phase stub** — `08-finalize` replaces the `INITIATION-ONLY` block with it.

<!-- markdownlint-disable MD025 -->
<!-- BEGIN CONTENT -->
# Contributing

## Review flow

- Every change reaches `main` through a pull request (PR) from its own branch, created from an
  up-to-date `main`.
- A change is final only when its PR is merged to `main`. Branch content is a draft.
- GitHub deletes a PR's branch when the PR merges (the repo's auto-delete head branches setting).

## Commit convention

Use [Conventional Commits](https://www.conventionalcommits.org/): `type: summary`, where `type` is
one of `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `build`, `ci`.

## Direct-push rule

- Never push to `main`.
- Never force-push a branch someone else may have pulled.

<!-- BEGIN INITIATION-ONLY -->
## Initiation branching and self-review gate

Project initiation runs as nine `/cuevik-start` steps, one session and one PR per step.

### Branch per step

| Step | Branch | Writes |
| --- | --- | --- |
| `00-bootstrap` | `init/00-bootstrap` | `CONTRIBUTING.md` (this governance layer), `.cuevik/`, `.markdownlint.json` |
| `01-product-concept` | `init/01-product-concept` | `docs/PRODUCT.md` |
| `02-product-requirements` | `init/02-product-requirements` | `docs/PRD.md` |
| `03-architecture` | `init/03-architecture` | `docs/ARCHITECTURE.md` |
| `04-tech-stack` | `init/04-tech-stack` | `docs/TECH-STACK.md`, `CONTRIBUTING.md` tooling layer |
| `05-ai-tool-guide` | `init/05-ai-tool-guide` | `docs/AI-TOOL-GUIDE.md`, tool adapters |
| `06-readme` | `init/06-readme` | `README.md` |
| `07-backlog` | `init/07-backlog` | `docs/BACKLOG.md`, epic and story issues |
| `08-finalize` | `init/08-finalize` | `CONTRIBUTING.md` (removes this block) |

- One branch per step, created from an up-to-date `main`.
- `main` holds only merged, final documents.
- A step refuses to run until the previous step's PR is merged. An open PR does not count.

### Self-review gate

Initiation is solo and process-enforced: GitHub does not let an author approve their own PR, so
this checklist is the approval. Complete it in the PR before merging any `init/*` PR:

- [ ] At least a few hours, ideally a full day, have passed since writing the document
      (fresh-eyes pass).
- [ ] The document covers every section its step requires.
- [ ] No upstream document changed on `main` after this branch was created.
- [ ] The change is in a PR. Nothing was pushed to `main` directly.
<!-- END INITIATION-ONLY -->
<!-- END CONTENT -->
