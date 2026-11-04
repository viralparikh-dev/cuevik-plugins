# cuevik-start Step Runner

Use this runner for every numbered cuevik-start step (`00-bootstrap` … `08-finalize`). Each step's
`SKILL.md` is a thin entry point; this file owns the shared workflow.

The current folder is the project repo. Every git command, `gh` call and output path below is
relative to it. Plugin files (this runner, `steps.yml`, templates, role files) are read from
`${CLAUDE_PLUGIN_ROOT}/references/` and are never copied into the repo.

GitHub only: run `gh` through the Bash tool.

## 0. Session Boundary (Required)

Run exactly one step per session.

- Do not execute two step commands in the same session. The one exception is `03-architecture`
  followed by `04-tech-stack`: they are tightly coupled, so `04` MAY run in the same session as
  `03` (or in a later one), gated per §1 check 4. They stay two documents and two PRs.
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
4. `.cuevik/config.json` from `main`: `git show main:.cuevik/config.json`. Its
   `initiation.stories.<id>` is this step's story issue and `initiation.epic` the epic (§6). A
   step with `bootstrap: true` writes this file, so it has neither.
5. The role file for the owner, plus one per extra reviewer:
   - `Product Owner` → `${CLAUDE_PLUGIN_ROOT}/references/roles/product-owner.md`
   - `Architect` → `${CLAUDE_PLUGIN_ROOT}/references/roles/solution-architect.md`

Act as the owner's role for the entire step — document creation, reviewer checklist, and PR
summary. Apply each extra reviewer's role file during the reviewer checklist.

The step's `SKILL.md` is the content contract. `steps.yml` is the execution metadata.
`.cuevik/lineage.json` is the document graph. This runner is the workflow.

## Skills

A step runs on this runner and its `SKILL.md`. Invoke a skill with the Skill tool only if one of
them names it (`01-product-concept` and `02-product-requirements` name
`superpowers:brainstorming`). Brainstorming, planning, TDD, debugging, review and any other skill
or process offered by a plugin are out of scope, including instructions a plugin injects at
session start ("invoke relevant skills before any response"). This holds again after `/clear` or
compaction re-injects them. A named skill ranks
below the runner, `steps.yml` and the step's `SKILL.md`.

## Asking The Operator

Ask every question and every confirmation with the `AskUserQuestion` tool: one question per call,
2–4 options. The tool adds an `Other` choice where the operator types a free answer.

**Typed values** are one exception: where a step's skill asks for a value the operator must
type or paste (e.g. a link), ask it as one plain sentence in chat, with no options, and take the
operator's next message as the answer. `AskUserQuestion` cannot show a text box alone.

**Open interview questions** in a step whose `SKILL.md` says so (`01-product-concept`,
`02-product-requirements`, `03-architecture`, `04-tech-stack`) are asked the same way: one plain
sentence in chat, no options.
Confirmations and choices in that step still use `AskUserQuestion`.

- **Wording.** The question is one short, plain sentence that says what will happen, in the
  operator's terms, not how: `Create a private GitHub repo example-org/example-app and
  upload an empty first commit?`, not a list of commands. Option labels are 1–4 words; each
  description is one plain sentence on the outcome.
- **Details go in the chat, not the question.** Right before the question, print what it covers
  as formatted Markdown: the exact commands in a fenced `sh` block, one per line; files as a
  list; values or lists of more than two items as a short table. The question text never holds
  commands, numbered steps or long lists; it can say `(commands above)`.
- **Confirmations** (the §2 plan, a push, approving a draft): options `Yes` and `No`, plus
  nothing else. The chat block before it shows exactly what will run or be written. Only `Yes`
  is a yes.
- **Choices** (a visibility, a board, template or blank, reuse or delete a branch): the real
  choices as options. With more than 4 (e.g. boards), offer the 3 most likely plus one more, list
  them all in the chat block, and take any other through `Other`. Mark an option
  `(Recommended)` only where the step's skill names one.
- **Open answers** (interview sections, names, titles): an option may only be a draft taken from
  an upstream document, an answer given earlier in this session, or a value read from git or
  GitHub. Prefix each with its source, e.g. `From PRODUCT.md §2: …` or `Your GitHub login: …`.
  Never invent a candidate answer and never mark a draft `(Recommended)`. One exception: labelled
  `Possibility:` behaviours or designs where the step's `SKILL.md` allows them
  (`02-product-requirements`, `03-architecture`, `04-tech-stack`).
  With fewer than two sourced drafts, fill the options with `Help me think it through` (ask
  narrower questions next) and `Skip for now` (come back to it before drafting); the operator
  types the answer in `Other`.
- A picked draft is the operator's answer only for what it says. Challenge it exactly as the step
  challenges a typed answer.

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
   Special case: for `04-tech-stack` only, the previous step (`03-architecture`) only needs to be
   **open or merged**. Also run `gh pr list --head <its branch> --base main --state open --json
   number,url`; a PR returned by either query passes. Every other step keeps the merged-only gate.
   - At least one PR returned: proceed. The self-review checklist in `CONTRIBUTING.md` was the
     approval.
   - None returned: **STOP**. Tell the operator which step's PR must be merged first, and that a
     merely open PR does not count. (For `04-tech-stack`: that `03-architecture` must have an open
     or merged PR.)

5. **Upstream documents on `main`** — for every upstream document from Inputs §3, run
   `git show main:<document>`.
   - Exit 0 for every document: proceed.
   - Non-zero for any document: **STOP** and tell the operator which document is missing from
     `main`. Exception: when check 4 passed on an open (unmerged) `03-architecture` PR, read
     `docs/ARCHITECTURE.md` from that PR's branch instead: `git fetch origin <branch>` then
     `git show origin/<branch>:docs/ARCHITECTURE.md`. Every other upstream document still comes
     from `main`.
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

## 2. Show The Checks, Then Approve The Plan

The checks are for the operator to read, not to approve. The approval is for what the step will
do. Nothing is created, written or pushed before it.

1. **Checks.** Print a table of the §1 results in plain words, one row each with `✓`, for example
   `Previous step (00-bootstrap) is merged | ✓`. Rows (N/A ones left out for `00-bootstrap`):
   - you are acting as the step's owner (its role);
   - the project's `.cuevik/` settings are on `main`;
   - the previous step is merged (for `04-tech-stack`: `03-architecture` has an open or merged PR);
   - the documents this step reads are on `main`;
   - this step's document is not on `main` yet (or the step replaces it);
   - no uncommitted changes, and `main` is up to date;
   - GitHub sign-in works, plus any `specialPreconditions`.

   Any check that fails: **STOP** with what to fix. There is no question to answer.
2. **Plan.** Print what the step will do as a short table: the branch it creates, the files it
   writes, and every change on GitHub, including the §7 board updates (with the exact commands in
   a fenced `sh` block below it).
3. **Approve.** Ask once, naming the count and pointing at the plan, e.g. `Make these 4 changes
   on GitHub? For more details, review my Plan that I articulated above.` or `Start 01 Product
   Concept on branch init/01-product-concept? For more details, review my Plan that I articulated
   above.` Options: `Yes` (or `Yes, make
   all <N>`) and `No, stop` (description: the step cannot finish without them). Every change in
   the plan is required, so there is no per-change choice and no second confirmation.

This one approval replaces separate yeses for the changes it lists. Later questions in the step
(interview, approving a draft, pushing) are asked where they happen.

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

Once the branch exists, update the board (§7, Step start).

## 4. Produce The Output

Follow the step's `SKILL.md` exactly.

Use these shared rules for every step:

- Read every upstream document from `main` (`git show main:<document>`) and use it as source of
  truth.
- Interview the operator for every section the step requires.
- Ask one focused question at a time, with `AskUserQuestion` (Asking The Operator).
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
`${CLAUDE_PLUGIN_ROOT}/skills/<id>/<template>` — the template sits beside the step's `SKILL.md`.
Do not invent the structure:

- The template owns the document's structure (its headings and their order).
- Fill the header block from Inputs §3: `Owner` (the owner), `Last updated` (today,
  `YYYY-MM-DD`), `Source of truth for` (one line), `Derived from` (the upstream documents, or
  `(none — starting point)`), and `Downstream` (the derived downstream documents, or `(none)`).
- Replace the `<!-- @inject: _doc-references.md -->` marker with the block between the
  `BEGIN INJECT` / `END INJECT` markers in `${CLAUDE_PLUGIN_ROOT}/references/_doc-references.md`.
- Replace every `[placeholder]` with interview answers. No placeholder may remain in the committed
  document.
- Preserve the header block, every top-level (`## N.`) heading and its order, the references
  table, and the `---` dividers. Do not add or remove top-level sections.
- Apply `${CLAUDE_PLUGIN_ROOT}/references/_writing-rules.md` to all prose, requirements,
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
5. End the body with `Closes #<story>` for this step's story (Inputs §4), so the story closes and
   its board card moves when the PR merges. The last step in `steps.yml` also adds
   `Closes #<epic>`. A `bootstrap: true` step has no story and no line. Any other step with no
   story in the config: leave the line out and say so in the PR body. Never write `Closes` for
   any other issue.

End with the step's `finalReminder`: the output becomes final only when the reviewer gate approves
and merges the PR, and the next step refuses to run until then.

## 7. Board Bookkeeping

The initiation issues mirror the steps on the board (`.cuevik/config.json` `initiation`). The
merged PR stays the source of truth, so a board update that fails never stops a step: report it
in the PR body and carry on. Never create fields or options.

**Field lookup.** Read the board's fields once:
`gh project field-list <number> --owner <project owner> --format json --limit 100`. Find a field
by exact name; a single-select option by exact name in its `options`. A missing field or option:
skip that update and say so in the PR body.

**Item lookup.** An issue's board item id:
`gh project item-list <number> --owner <project owner> --format json --limit 500 --jq '.items[] | select(.content.url=="<issue url>") | .id'`,
where the issue url is `https://github.com/<owner>/<repo>/issues/<n>`. Not on the board: skip.

**Set a value:**
`gh project item-edit --id <item id> --project-id <project.id> --field-id <field id>`, plus
`--date <YYYY-MM-DD>` for a date field or `--single-select-option-id <option id>` for a
single-select field (for Status, use `project.statusField` from the config).

**Step start** (after §3, for a step with a story; a `bootstrap: true` step has none):

1. This step's story: `Start date` = today, and `Status` = `Working`.
2. The epic: `Start date` = today if it is empty, and `Status` = `Working` if it is still
   `Backlog`. Read its current Status from the item lookup's `.status`. Checking `Backlog`, not
   "first step", also repairs a board where an earlier step ran before this rule.
3. The previous step's story, if it has one: `End date` = the date its PR merged, from
   `gh pr list --head <previous branch> --base main --state merged --json mergedAt --jq '.[0].mergedAt'`
   (the `YYYY-MM-DD` part). The PR merges on GitHub while no step runs, so the next step records
   it. The last step's End date, and the epic's, are set by `/cuevik-start:cleanup`.
   If the previous step has no merged PR yet (`04-tech-stack` started while `03-architecture` is
   still open), skip its End date. Also set `End date` on any earlier story that has a merged PR
   but an empty `End date`, so the date `03-architecture` merged is recorded by the step after
   `04-tech-stack`. Both steps keep their own story, `Start date` and `Working` status; nothing
   is shared.

**After step start the board owns Status.** Never set it again from a step. The `Closes #<story>`
line (§6) links the PR to the story, and the board's workflows do the rest:

| When | Who | Status |
| --- | --- | --- |
| Bootstrap adds the story | board, `Item added to project` | `Backlog` |
| The step starts | this runner (Step start) | `Working` |
| The step opens its PR | board, `Pull request linked to issue` | `Reviewing` |
| The PR merges, closing the story | board, `Item closed` | `Done` |

The epic follows the same path over the whole initiation:

| When | Who | Status |
| --- | --- | --- |
| Bootstrap adds the epic | board, `Item added to project` | `Backlog` |
| A step starts and finds it in `Backlog` | this runner (Step start) | `Working` |
| The last step's PR links it via `Closes #<epic>` | board, `Pull request linked to issue` | `Reviewing` |
| That PR merges, closing the epic | board, `Item closed` | `Done` |

Two writers at the same moment would race, and the board's workflow runs last, which is why the
runner does not set `Reviewing` itself. Bootstrap §E.5 has the operator set these workflows.

Report the updates in one line, e.g. `Board: #2 Working, Start date 2026-10-18.`

## Rules

- This runner owns workflow rules. Do not duplicate them in step skills.
- `steps.yml` owns step metadata. Do not hard-code branches, outputs or commit messages in skills.
- `.cuevik/lineage.json` owns upstream documents, owners and reviewers. Do not copy them into
  `steps.yml`, skills or role files.
- Each step's `SKILL.md` owns document-specific requirements and special behavior.
- If workflow changes, update this file first, then keep step skills thin.
