# CONTRIBUTING.md Governance Layer (shared content)

`00-bootstrap` writes the content between the `BEGIN CONTENT` / `END CONTENT` markers below to
the project's `CONTRIBUTING.md`, verbatim. It is fixed text, not a template: there is nothing to
interview for, and `09-finalize` depends on the `INITIATION-ONLY` markers being exact.

- No `CONTRIBUTING.md` on `main`: write the content as the whole file.
- `CONTRIBUTING.md` already on `main`: keep the existing text verbatim and insert the content
  after the file's first `#` heading, without the content's own `# Contributing` line (see
  `skills/00-bootstrap/SKILL.md`).

Layers written later, never here:

- **Tooling layer** — appended by `04-tech-stack` from `docs/TECH-STACK.md`.
- **Development-phase stub** — `09-finalize` replaces the `INITIATION-ONLY` block with it.

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

- Never push to `main`. The one exception is the empty `chore: initialize repository` commit
  `/cuevik-start:00-bootstrap` pushes to a new or empty repo; it holds no files.
- Never force-push a branch someone else may have pulled.

<!-- BEGIN INITIATION-ONLY -->
## Initiation branching and self-review gate

Project initiation runs as ten `/cuevik-start` steps, one session and one PR per step.

### Branch per step

| Step | Branch | Writes |
| --- | --- | --- |
| `00-bootstrap` | `init/00-bootstrap` | `CONTRIBUTING.md` (this governance layer), `.cuevik/`, `.markdownlint.json` |
| `01-product-concept` | `init/01-product-concept` | `docs/PRODUCT.md` |
| `02-product-requirements` | `init/02-product-requirements` | `docs/PRD.md` |
| `03-architecture` | `init/03-architecture` | `docs/ARCHITECTURE.md` |
| `04-tech-stack` | `init/04-tech-stack` | `docs/TECH-STACK.md`, `CONTRIBUTING.md` tooling layer |
| `05-test-strategy` | `init/05-test-strategy` | `docs/TEST-STRATEGY.md` |
| `06-ai-tool-guide` | `init/06-ai-tool-guide` | `docs/AI-TOOL-GUIDE.md`, tool adapters |
| `07-readme` | `init/07-readme` | `README.md` |
| `08-backlog` | `init/08-backlog` | `docs/BACKLOG.md`, epic and story issues |
| `09-finalize` | `init/09-finalize` | `CONTRIBUTING.md` (removes this block) |

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
- [ ] The change is in a PR. Nothing was pushed to `main` directly, apart from bootstrap's empty
      initial commit.
<!-- END INITIATION-ONLY -->
<!-- END CONTENT -->

## Express variant of the initiation-only block

`/cuevik-start:express` writes the CONTENT text above with the whole `INITIATION-ONLY` block (both
marker lines included) replaced by the text between the `BEGIN EXPRESS BLOCK` / `END EXPRESS
BLOCK` markers below. The `INITIATION-ONLY` markers stay exact so `09-finalize`, `status` and
`00-bootstrap`'s "already bootstrapped" check work on an Express repo unchanged. The self-review
gate is the same text as in the block above: change one, change both.

<!-- BEGIN EXPRESS BLOCK -->
<!-- BEGIN INITIATION-ONLY -->
## Initiation branching and self-review gate

Project initiation runs as the `/cuevik-start:express` lane: one session and one PR, from the
branch `init/express`, which writes `CONTRIBUTING.md`, `.cuevik/`, `.markdownlint.json`,
`docs/PRODUCT.md`, `docs/PRD.md` and `docs/BACKLOG.md`.

### Self-review gate

Initiation is solo and process-enforced: GitHub does not let an author approve their own PR, so
this checklist is the approval. Complete it in the PR before merging any `init/*` PR:

- [ ] At least a few hours, ideally a full day, have passed since writing the document
      (fresh-eyes pass).
- [ ] The document covers every section its step requires.
- [ ] No upstream document changed on `main` after this branch was created.
- [ ] The change is in a PR. Nothing was pushed to `main` directly, apart from bootstrap's empty
      initial commit.
<!-- END INITIATION-ONLY -->
<!-- END EXPRESS BLOCK -->
