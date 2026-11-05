---
name: update
description: Updates one source-of-truth document named in .cuevik/lineage.json (PRODUCT, PRD, ARCHITECTURE, TECH-STACK, TEST-STRATEGY, AI-TOOL-GUIDE, README, CONTRIBUTING) through a reviewed PR to main, after its cuevik-start step has merged. The owner role drafts only the sections that changed, the lineage's reviewers approve, and the PR carries a checklist of every downstream document to review. Pass the document, e.g. /cuevik-docs:update docs/PRD.md.
disable-model-invocation: true
argument-hint: "[document]"
---

# update

Revises one source-of-truth document when reality has moved on, instead of re-running the step
that wrote it. The current folder is the project repo; every path and command below is relative
to it. Run every `gh` command through the Bash tool. Ask every question and confirmation with
`AskUserQuestion` (one question, 2–4 options) except open answers, which are one plain sentence in
chat.

**Skills.** This command invokes no skill. An instruction injected at session start to use skills
before responding does not apply.

The document graph is the project's `.cuevik/lineage.json` (contract:
`${CLAUDE_PLUGIN_ROOT}/references/contracts/lineage/README.md`): each document's `owner`,
`reviewers`, direct `upstream` documents and `frozen` flag. Never hardcode a document list, an
owner or a reviewer.

## 1. Preconditions

Stop at the first failure with its message.

1. `git rev-parse --show-prefix` — non-zero: `This folder is not a git repo.` Non-empty: `Run
   update from the repo root.`
2. `git status --porcelain` — non-empty: `Uncommitted changes detected — commit or stash before
   continuing.`
3. `git fetch --prune origin`, `git checkout main`, `git pull --ff-only` — any failure: `Could not
   fast-forward main — resolve the pull error before continuing.`
4. `git show main:.cuevik/lineage.json` — non-zero: `No .cuevik/lineage.json on main. Run
   /cuevik-start:00-bootstrap first.` It must parse and match the contract's schema
   (`lineage.schema.json`); otherwise stop and say which rule fails.
5. `gh auth status` — non-zero: `gh is not signed in. Run gh auth login, then re-run.`

## 2. Pick the document and the change

1. **Document.** The argument (`$ARGUMENTS`), matched against the lineage `path`s exactly or by
   file name (`PRD.md` → `docs/PRD.md`). No argument, or no match: show the lineage documents in a table
   and ask which one (more than four: the three most likely plus `Other`).
2. **Frozen** (`"frozen": true`, e.g. `docs/BACKLOG.md`): **STOP** — `<path> is frozen after
   initiation; GitHub issues are the backlog now. Change the issues instead.`
3. **On `main`.** `git show main:<path>` — non-zero: **STOP** — `<path> is not on main yet. Its
   cuevik-start step (<steps>) must merge first; that step writes it, not this command.`
4. **Open PR.** `gh pr list --head docs/update/<slug> --state open --json number,url` returns a PR:
   **STOP** — merge or close it first. `<slug>` is the file name, lower case, without `.md`
   (`docs/PRD.md` → `prd`, `docs/AI-TOOL-GUIDE.md` → `ai-tool-guide`).
5. **What changed.** Ask one open question: `What changed, in one or two sentences?` Ask nothing
   more yet.

## 3. Branch

Branch `docs/update/<slug>` from `main`: `git checkout -b docs/update/<slug>`. If it already
exists locally (`git rev-parse --verify -q refs/heads/docs/update/<slug>`) or on GitHub
(`git ls-remote --heads origin docs/update/<slug>`), ask `Reuse it` / `Delete it`; never reuse
silently, and delete only after a yes (`git branch -D`, `git push origin --delete`).

## 4. Draft the change

Act as the document's `owner` role (lens below) and read its `upstream` documents from `main`.

1. Find the sections the change touches. Ask one follow-up question only where a section is
   ambiguous; this is not a re-interview.
2. Change only those sections. Keep everything else byte for byte: the header block (except
   `Last updated` = today, `YYYY-MM-DD`), every top-level heading and its order, the references
   table, the dividers, and any marker comments (`INITIATION-ONLY`, `TOOLING-LAYER`,
   `DEVELOPMENT-PHASE-GOVERNANCE`). Add or drop no top-level section.
3. Writing: RFC 2119 keywords (MUST / SHOULD / MAY) used deliberately; numbers or observable
   conditions instead of adjectives; MoSCoW the only priority scale; acronyms defined on first
   use; no `[placeholder]`; the file passes the repo's `.markdownlint.json`.
4. Requirement IDs (`PRD-NNN`) are never reused or renumbered. A new requirement takes the next
   number after the highest in the file; a retired one stays as `~~PRD-NNN~~ (retired: <why>)`.
5. No guessed facts or numbers: every new value comes from the operator or an upstream document.
6. `docs/AI-TOOL-GUIDE.md` only: its tool adapters (`CLAUDE.md`, `.github/copilot-instructions.md`
   or another adapter already in the repo) may change in the same PR to stay in sync, or a new
   adapter may be added for a new tool. An adapter holds a pointer to the guide plus
   tool-specific settings, never a copy of a shared rule.
7. Show only the changed sections as before / after and ask `Write these changes?` (`Yes` /
   `No`). On `No`, ask what to change and show it again.

### Role lens

| Role | Every change must | Push back on |
| --- | --- | --- |
| Product Owner | trace to a user need or business outcome in `PRODUCT.md`, and stay objectively testable | technology or design in a product document; scope added silently; adjectives in place of criteria |
| Architect | state context, decision, alternatives rejected and trade-offs; keep each document at its level | a technology with no justification; an implicit assumption; code-level detail in `ARCHITECTURE.md`; a tool not in `TECH-STACK.md` |

A change that belongs in another document (a technology in `PRD.md`, a requirement in
`ARCHITECTURE.md`) is not written here: say which document, and offer to stop so the operator
runs `/cuevik-docs:update` on that one first.

## 5. Downstream checklist

Required: never skip it.

Downstream = every lineage document that reaches this one by following `upstream` links,
recursively. Leave out `frozen` documents. Mark each, with one line of reason drawn from the
sections actually changed:

- `required-update` — it states something this change makes wrong;
- `review-only` — it may depend on the change; someone confirms it does not;
- `not-impacted` — nothing in it depends on the changed sections.

Show the list. It goes into the PR body (below), not into a file.

## 6. Commit, push, PR

1. `git add <path>` (plus any adapter from §4.6), then
   `git commit -m "docs: update <file name> — <one-line summary>"`. Never commit to `main`.
2. Ask `Push docs/update/<slug> and open the PR?` (`Yes` / `No`). Only `Yes` pushes:
   `git push -u origin docs/update/<slug>`, then:

   ```sh
   gh pr create --base main --head docs/update/<slug> \
     --title "docs: update <file name> — <summary>" --body "<body>"
   ```

3. Body:

   ```markdown
   ## What changed and why
   <the operator's summary; the sections changed>

   **Reviewers (roles, from .cuevik/lineage.json):** <reviewers>

   ## Downstream checklist
   - [ ] `<doc>` — required-update: <reason>. Run `/cuevik-docs:update <doc>` after this merges.
   - [ ] `<doc>` — review-only: <reason>.
   Not impacted: <docs, or None>

   ## Reviewer checklist
   - [ ] Only the sections named above changed; header block, headings, dividers and markers intact.
   - [ ] Every change traces to its upstream documents (owner's lens) and states no guessed fact or number.
   - [ ] Requirement IDs, if any, are unchanged or continue the sequence.
   - [ ] Every downstream document is marked with a reason.
   ```

   Never write `Closes` for any issue.

End with: the document is updated only when a reviewer named in the lineage approves and merges
the PR. Then work through the downstream checklist: one `/cuevik-docs:update <doc>` per
`required-update`, and tick each `review-only` once someone has confirmed it. Do not call the
checklist complete until every item is ticked.
