# cuevik-start Step Runner

Use this runner for every numbered cuevik-start step (`00-bootstrap` … `08-finalize`). Each step's
`SKILL.md` is a thin entry point; this file owns the shared workflow.

The current folder is the project repo. Every git command, `gh` call and output path below is
relative to it. Plugin files (this runner, `steps.yml`, templates, role files) are read from
`${CLAUDE_PLUGIN_ROOT}/references/` and are never copied into the repo.

GitHub only: run `gh` through the Bash tool.

## 0. Session Boundary (Required)

Run exactly one step per session.

- Do not execute two step commands in the same session.
- At the start of every step session, run §1 preconditions 1–2 (clean working tree, refresh
  `main`) first, then follow `${CLAUDE_PLUGIN_ROOT}/skills/status/SKILL.md` so status reflects
  what has been merged on GitHub. Do not repeat preconditions 1–2 afterward.
- Continue only the single requested step after status is known.
- If the user asks to run a different step in the same session, stop and tell them to start a new
  session for that step.

A step with `bootstrap: true` skips the status call (there is nothing to report before `.cuevik/`
exists) and runs §1 checks 1–2 only where its `SKILL.md` order says, once the folder is a repo
with `main` on GitHub.

## Inputs

Before starting, load:

1. The requested step entry from `${CLAUDE_PLUGIN_ROOT}/references/steps.yml`.
2. The step's own `SKILL.md` (`${CLAUDE_PLUGIN_ROOT}/skills/<id>/SKILL.md`).
3. `.cuevik/lineage.json` from `main`: `git show main:.cuevik/lineage.json`. Find the entry whose
   `path` is the step's primary output (the first entry in `outputs`). That entry gives:
   - **upstream** — its `upstream` list. Read each document from `main`:
     `git show main:<document>`.
   - **owner** and **reviewers** — its `owner` and `reviewers`.
   - **downstream** — every document that reaches it by following `upstream` links (derived, not
     stored).

   A step with `bootstrap: true` runs before `.cuevik/lineage.json` exists. It takes its owner and
   reviewers from the default lineage it is about to write, and has no upstream documents.
4. The role file for the owner, plus one per extra reviewer:
   - `Product Owner` → `${CLAUDE_PLUGIN_ROOT}/references/roles/product-owner.md`
   - `Architect` → `${CLAUDE_PLUGIN_ROOT}/references/roles/solution-architect.md`

Act as the owner's role for the entire step — document creation, reviewer checklist, and PR
summary. Apply each extra reviewer's role file during the reviewer checklist.

The step's `SKILL.md` is the content contract. `steps.yml` is the execution metadata.
`.cuevik/lineage.json` is the document graph. This runner is the workflow.

## 1. Preconditions

Run these checks before creating a branch or writing files. Do not proceed on assumption.

A step with `bootstrap: true` runs only checks 1, 2 and 7, and only once its `SKILL.md` has made
the folder a git repo with a GitHub `origin`. Every other step runs all of them.

1. **Clean working tree** — run `git status --porcelain`.
   - Empty output: proceed.
   - Non-empty output: **STOP** and tell the operator: `Uncommitted changes detected — commit or
     stash before continuing.`

2. **Refresh `main`** — run `git fetch --prune origin`, `git checkout main`, then
   `git pull --ff-only`. PRs merge on GitHub, so the local `main` is stale until it is pulled, and
   every `main:` check below reads the local ref. Fetching first makes `checkout`'s status line
   current and drops remote-tracking refs of branches GitHub auto-deleted after merge.
   - Both succeed: proceed.
   - Any fails (no network or remote access, or local `main` has diverged from `origin/main`):
     **STOP** and tell the operator: `Could not fast-forward main — resolve the pull error before
     continuing.` Never run the checks below against a stale `main`.

3. **Bootstrap on `main`** — run `git show main:.cuevik/lineage.json` and
   `git show main:.cuevik/config.json`.
   - Exit 0 for both: proceed.
   - Non-zero for either: **STOP**. Tell the operator to run `/cuevik-start:00-bootstrap` and
     merge its PR first.

4. **Previous step merged** — take the step listed immediately before this one in `steps.yml` and
   run `gh pr list --head <its branch> --base main --state merged --json number,url`.
   - At least one PR returned: proceed. The self-review checklist in `CONTRIBUTING.md` was the
     approval.
   - None returned: **STOP**. Tell the operator which step's PR must be merged first, and that a
     merely open PR does not count.

5. **Upstream documents on `main`** — for every upstream document from Inputs §3, run
   `git show main:<document>`.
   - Exit 0 for every document: proceed.
   - Non-zero for any document: **STOP** and tell the operator which document is missing from
     `main`.
   - Empty `upstream`: no upstream document is required.

6. **Step not already finalized** — unless the step sets `replacesExisting: true`, run
   `git show main:<primary-output>`.
   - Non-zero (not on `main`): proceed — the step has not been finalized.
   - Exit 0 (already on `main`): **STOP**. The step is already complete. Tell the operator the
     document is final and to run `/cuevik-docs:update <document>` to revise it instead of
     re-running the step. Do not branch or regenerate.
   - `replacesExisting: true` (e.g. `06-readme`, which overwrites the repo's existing README):
     skip this check — the file's presence on `main` is expected and is not proof the step ran.
     Rely on the §3 branch check and operator confirmation.

7. **Additional step preconditions** — apply any `specialPreconditions` from `steps.yml` and any
   preconditions in the step's `SKILL.md`.

## 2. Confirm Before Proceeding

Present the precondition results as a checklist and wait for an explicit `yes` before creating a
branch, writing files, creating GitHub issues, or pushing anything.

The checklist must include:

- Operator role matches the step's owner, and the corresponding role file has been loaded.
- `.cuevik/config.json` and `.cuevik/lineage.json` are on `main` (N/A for `00-bootstrap`).
- The previous step's PR is merged (N/A for `00-bootstrap`).
- Upstream documents are final on `main`.
- This step's output is not already final on `main`, or the step is marked `replacesExisting: true`.
- Working tree is clean and work will branch from an up-to-date `main`.
- `gh auth status` succeeds, plus any stricter requirement in `specialPreconditions`.

If any item fails, stop and resolve it before continuing.

## 3. Create The Working Branch

From an up-to-date `main`, create and switch to the branch named in the step's `branch` field:
`git checkout -b <branch>`.

First check whether the branch already exists locally (`git rev-parse --verify -q
refs/heads/<branch>` exits 0) or on GitHub (`git ls-remote --heads origin <branch>` prints a line).
A closed, unmerged PR leaves both behind: auto-delete only fires on merge. If either exists, do not
reuse it silently. Ask the operator to:

- **Reuse it** — `git checkout <branch>`, or `git checkout -b <branch> --track origin/<branch>`
  when it exists only on GitHub; then continue from its content.
- **Delete it** — after a `yes`, `git branch -D <branch>` and/or
  `git push origin --delete <branch>`; then create it fresh as above.

Never use a different branch name: the next step's gate (§1 check 4) finds this step's PR by
its exact `branch`.

## 4. Produce The Output

Follow the step's `SKILL.md` exactly.

Use these shared rules for every step:

- Read every upstream document from `main` (`git show main:<document>`) and use it as source of
  truth.
- Interview the operator for every section the step requires.
- Ask one focused question at a time.
- Ask as many focused questions as needed until every required section is complete and every
  template placeholder is resolved.
- Never assume an answer.
- Write only the files listed in `outputs`, plus any conditional outputs explicitly allowed by the
  step's `SKILL.md`.
- Show drafts and revise until the operator approves the content.

Use these token optimization rules for every step:

- Load only the requested step entry, its `SKILL.md`, and its upstream documents. Do not load
  other steps' skills.
- Reuse facts already confirmed in the current step session. Do not re-ask answered questions.
- Keep prompts and responses compact: one question at a time, one decision at a time.
- Show only changed sections when revising drafts; do not reprint unchanged sections.
- Summarize long upstream content into concise decision inputs before asking the next question.
- Stop asking once all required sections are complete and no placeholders remain.

If the step has a `template` field, produce the primary output by filling
`${CLAUDE_PLUGIN_ROOT}/references/templates/<template>` — do not invent the structure:

- The template owns the document's structure (its headings and their order).
- Fill the header block from Inputs §3: `Owner` (the owner), `Last updated` (today,
  `YYYY-MM-DD`), `Source of truth for` (one line), `Derived from` (the upstream documents, or
  `(none — starting point)`), and `Downstream` (the derived downstream documents, or `(none)`).
- Replace the `<!-- @inject: _doc-references.md -->` marker with the block between the
  `BEGIN INJECT` / `END INJECT` markers in `${CLAUDE_PLUGIN_ROOT}/references/templates/_doc-references.md`.
- Replace every `[placeholder]` with interview answers. No placeholder may remain in the committed
  document.
- Preserve the header block, every top-level (`## N.`) heading and its order, the references
  table, and the `---` dividers. Do not add or remove top-level sections.
- Apply `${CLAUDE_PLUGIN_ROOT}/references/templates/_writing-rules.md` to all prose, requirements,
  and tables of every generated document.

If the step has `specialActions`, perform them in the order listed after the step's interview rules
are satisfied.

## 5. Commit

Commit the files listed in `outputs` and any conditional outputs the step's `SKILL.md` generated:
`git add <outputs>` then `git commit`.

Use the `commitMessage` from `steps.yml`.

Never commit to `main`.

## 6. Open The PR

Never push without explicit operator approval.

After approval:

1. Push the step branch: `git push -u origin <branch>`.
2. Open a PR targeting `main`: `gh pr create --base main --head <branch>`.
3. Use a title that names the step id and its primary output.
4. In the body, include the step's `prSummary` and the reviewer checklist from the step's
   `SKILL.md`.

End with the step's `finalReminder`: the output becomes final only when the reviewer gate approves
and merges the PR, and the next step refuses to run until then.

## Rules

- This runner owns workflow rules. Do not duplicate them in step skills.
- `steps.yml` owns step metadata. Do not hard-code branches, outputs or commit messages in skills.
- `.cuevik/lineage.json` owns upstream documents, owners and reviewers. Do not copy them into
  `steps.yml`, skills or role files.
- Each step's `SKILL.md` owns document-specific requirements and special behavior.
- If workflow changes, update this file first, then keep step skills thin.
