# cuevik-start Step Runner

Use this runner for every numbered cuevik-start step (`00-bootstrap` … `09-finalize`) and, through
§8, for the Express lane. Each step's `SKILL.md` is a thin entry point; this file owns the shared
workflow.

The current folder is the project repo. Every git command, `gh` call and output path below is
relative to it. Plugin files (this runner, `steps.yml`, templates, role files) are read from
`${CLAUDE_PLUGIN_ROOT}/references/` and are never copied into the repo.

GitHub only: run `gh` through the Bash tool.

## 0. Session Boundary (Required)

Run exactly one step per session.

- Do not execute two step commands in the same session. The one exception is `03-architecture`
  followed by `04-tech-stack`: they are tightly coupled, so `04` MAY run in the same session as
  `03` (or in a later one), gated per §1 check 4. They stay two documents and two PRs.
- The Express lane (§8) is the other exception: its skill runs `00`, `01`, `02` and `08` in one
  session and one PR.
- At the start of every step session, run §1 preconditions 1–2 (clean working tree, refresh
  `main`) first, then follow `${CLAUDE_PLUGIN_ROOT}/skills/status/SKILL.md` so status reflects
  what has been merged on GitHub. Give its script this step's id: the same run then answers §1
  check 4. Do not repeat preconditions 1–2 afterward.
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
   `initiation.stories.<slug>` is this step's story issue, keyed by the step's `slug` in
   `steps.yml`, never by its numbered id, and `initiation.epic` the epic (§6, absent on a `flat`
   repo), `boardState` says whether the board bookkeeping (§7) applies, and
   `backlogModel` is `epic-grouped` or `flat`. A step with `bootstrap: true` writes this file, so
   it has none of them.
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
`02-product-requirements`, `03-architecture`, `04-tech-stack`, `05-test-strategy`) are asked the same way: one plain
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
   - Exit 0 for both: proceed, after reading `schemaVersion` from each.
   - Non-zero for either: **STOP**. Tell the operator to run `/cuevik-start:00-bootstrap` and
     merge its PR first.
   - A file's `schemaVersion` is **current** when it equals the `schemaVersion` `const` in its
     contract's schema: `${CLAUDE_PLUGIN_ROOT}/references/contracts/config/config.schema.json` for
     the config, `.../lineage/lineage.schema.json` for the lineage. Either file below its current
     version (a file from before the current contract): **STOP**. Tell the operator: `<file> is
     schemaVersion <n>. Run /cuevik-start:migrate, merge its PR, then re-run.` (Config contract
     README, "Migrating from an older schemaVersion", for the edit by hand.) `bootstrap: true`
     steps skip this: they write the file.

4. **Previous step open or merged, earlier steps merged** — a step may start once its immediate
   predecessor's PR is **open or merged**, provided every step before that predecessor is already
   **merged**. This lets you work one step ahead of the review queue; the all-earlier-merged clamp
   keeps you at most one step ahead. Merge order itself is enforced by the repo's `main` ruleset
   and the `init-order` status check, not here (`CONTRIBUTING.md`).

   The check is made by `${CLAUDE_PLUGIN_ROOT}/scripts/init-state.sh`, not by you: read the
   `== gate` section of the run §0 made with this step's id (if that section is missing, run
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-state.sh" <step id>` now). The script looks each
   step's PR up under its `branch`, under its alias branches (a repo initiated before steps had
   slugs has the PR on the old numbered branch) and, for a step the Express lane covers, under the
   lane's branch. Never work the gate out with `gh pr list` calls of your own, and never proceed
   without its answer: a script that cannot run is a **STOP**, with what the shell said.

   - `result: pass`: proceed. Keep `predecessor_state` (`merged` or `open`), `predecessor_branch`
     and `predecessor_merged`: check 5 and §7 use them. The self-review checklist in
     `CONTRIBUTING.md` is the approval for a merged PR.
   - `result: stop`: **STOP** and tell the operator the `message` line: either the previous step's
     PR is neither open nor merged, or it is only open and an earlier step is not merged yet (at
     most one step ahead).

5. **Upstream documents on `main`** — for every upstream document from Inputs §3, run
   `git show main:<document>`.
   - Exit 0 for every document: proceed.
   - Non-zero for any document: **STOP** and tell the operator which document is missing from
     `main`. Exception: when check 4 gave `predecessor_state: open`, read that predecessor's
     **primary output** (the first entry of its `outputs` in `steps.yml`) from the PR's branch
     instead of `main`: `git fetch origin <predecessor branch>` then
     `git show origin/<predecessor branch>:<primary output>`, where `<predecessor branch>` is
     check 4's `predecessor_branch` (an alias branch in a migrated repo). Every other upstream
     document still comes from `main`; one missing there is a real STOP — it means an earlier step
     is unmerged, so you are trying to run more than one step ahead.
   - Empty `upstream`: no upstream document is required.

6. **Step not already finalized** — unless the step sets `replacesExisting: true`, run
   `git show main:<primary-output>`.
   - Non-zero (not on `main`): proceed — the step has not been finalized.
   - Exit 0 (already on `main`): **STOP**. The step is already complete. Tell the operator the
     document is final and to run `/cuevik-docs:update <document>` to revise it instead of
     re-running the step. Do not branch or regenerate.
   - `replacesExisting: true` (e.g. `07-readme`, which overwrites the repo's existing README):
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
   - the previous step's PR is open or merged, and every earlier step is merged (§1 check 4);
   - the documents this step reads are on `main`;
   - this step's document is not on `main` yet (or the step replaces it);
   - no uncommitted changes, and `main` is up to date;
   - GitHub sign-in works, plus any `specialPreconditions`.

   Any check that fails: **STOP** with what to fix. There is no question to answer.
2. **Plan.** Print what the step will do as a short table: the branch it creates, the files it
   writes, and every change on GitHub, including the §7 board updates unless `boardState` is
   `none` (with the exact commands in a fenced `sh` block below it).
3. **Approve.** Ask once, naming the count and pointing at the plan, e.g. `Make these 4 changes
   on GitHub? For more details, review my Plan that I articulated above.` or `Start 01 Product
   Concept on branch init/product-concept? For more details, review my Plan that I articulated
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
  truth — except the one predecessor document §1 check 5 allows reading from its open PR branch
  when you are working one step ahead.
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
and merges the PR. The next step may *start* while this PR is open (§1 check 4, one step ahead),
but the repo's `main` ruleset blocks it from *merging* until this PR merges and forces it to
re-sync with `main` afterward — so if this document changes during review, regenerate the next
step against the new version before merging it.

## 7. Board Bookkeeping

The board is optional. Read `boardState` from `.cuevik/config.json` (Inputs §4):

- `none`: skip this whole section. Make no call, report nothing, and add no board line to the PR
  body. This is a valid repo, not a problem.
- `configured` or `partial`: do the bookkeeping below. `partial` behaves like `configured`: a call
  that needs a part the board lacks is skipped and reported, as any failed call is.

Every board call in this section is an operation in the board core,
`${CLAUDE_PLUGIN_ROOT}/references/contracts/board/board.md` (shared with cuevik-ship); load it only
when `boardState` is not `none`. This section holds no `gh project` command. In a cloud session
the core makes no call: say in one line of the PR body which board updates were skipped.

The initiation issues mirror the steps on the board (`.cuevik/config.json` `initiation`). The
merged PR stays the source of truth, so a board update that fails never stops a step: report it
in the PR body and carry on. Never create fields or options.

**Field lookup:** `board.read` `fields`, once. A missing field or option: skip that update and say
so in the PR body.

**Item lookup:** `board.read` `item`, for an issue's board item id and its current Status. Not on
the board: skip.

**Set a value:** `board.setField` (for Status, use `project.statusField` from the config).

**Step start** (after §3, for a step with a story; a `bootstrap: true` step has none):

1. This step's story: `Start date` = today, and `Status` = `Working`.
2. The epic: `Start date` = today if it is empty, and `Status` = `Working` if it is still
   `Backlog`. Read its current Status from the item lookup's `.status`. Checking `Backlog`, not
   "first step", also repairs a board where an earlier step ran before this rule.
3. The previous step's story, if it has one: `End date` = the date its PR merged, which is
   `predecessor_merged` from §1 check 4. The PR merges on GitHub while no step runs, so the next
   step records it. The last step's End date, and the epic's, are set by `/cuevik-start:cleanup`.
   If it is `-` (you started this step while the previous one's PR is still open, one step ahead),
   skip its End date. Also set `End date` on any earlier story that has a merged PR but an empty
   `End date`, so a late-merged previous step's date is recorded by the step after it: each
   step's merge date is the fifth field of its line in the script's `== steps` section. Each step
   keeps its own story, `Start date` and `Working` status; nothing is shared.

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

## 8. Express Lane

`/cuevik-start:express` runs `00-bootstrap`, `01-product-concept`, `02-product-requirements` and
`08-backlog` in one session, on one branch, as one PR. Its metadata is `references/express.yml`
(`branch`, `covers`, `closes`). The lane is not a numbered step: it has no `steps.yml` entry and
only `skills/express/SKILL.md` uses this section. Each covered step still writes its own output
from its own template, under its skill's **Express profile**. The table lists what the lane
replaces; every runner rule it does not mention applies as written.

| Runner part | In the Express lane |
| --- | --- |
| §0 | One session for the four covered steps; any other step still needs its own. The status call is skipped: the repo is not bootstrapped yet. |
| Inputs §3, §4 | The lane writes `.cuevik/lineage.json` and `.cuevik/config.json` itself, so owners and reviewers come from the default lineage it is about to write (as for `bootstrap: true`). Upstream documents for `02` and `08` are read from the working branch, not `main`. |
| §1 | Checks 1 and 2 once, at the start. Checks 3, 4 and 5 do not apply. Check 6 runs for `docs/PRODUCT.md`, `docs/PRD.md` and `docs/BACKLOG.md`. Check 7: the preconditions of `00` (§C), the `superpowers` precondition of `01` and `02`, and no open PR from the lane's `branch`. |
| §2 | One checks table, one plan, one approval. The plan lists the branch, the files, and the GitHub changes of `00` §E.3 and §E.4; it says `08`'s labels and issues are listed for approval at that part. |
| §3 | One branch, the lane's `branch`, created after the §2 approval; the reuse-or-delete rule applies. |
| §4 | The covered steps in the order of `covers`; each part follows its step's `SKILL.md`, Express profile included. In every header block, `Derived from` and `Downstream` list only documents that exist on the branch; the lineage file keeps the full lists. Each output is shown and approved before its commit. |
| §5 | One commit per covered step, in order, each with that step's `commitMessage`. |
| §6 | One push on approval and one PR to `main`. The title names the lane and its outputs. The body has the lane's `prSummary`, the `00` checklist as the Architect's group, the `01`, `02` and `08` checklists as the Product Owner's group (each with its Express profile changes), the Express block from `skills/express/SKILL.md`, and each covered step's PR-body lists once. It ends with `Closes #<story>` for each step in `closes`, one line each, from `initiation.stories`: never the epic, never another issue. Then the `finalReminder`. |
| §7 | Not applicable: the lane writes `boardState` `none` and makes no board call. |

**Graduation.** After the Express PR merges, the standard `03`–`07` run as usual: §1 check 4's
Express-lane lookup accepts the Express PR for `02`, the full lineage has their entries, and
`initiation.stories` has their stories. `09-finalize` finds the `INITIATION-ONLY` markers it needs,
because the Express variant of the block keeps them; like any `09` run it still needs its upstream
documents, so it follows `04`. Standard `00`, `01`, `02` and `08` stop at their existing "already
bootstrapped" and "already final" checks.

## Rules

- This runner owns workflow rules. Do not duplicate them in step skills.
- `steps.yml` owns step metadata. Do not hard-code branches, outputs or commit messages in skills.
- `.cuevik/lineage.json` owns upstream documents, owners and reviewers. Do not copy them into
  `steps.yml`, skills or role files.
- Each step's `SKILL.md` owns document-specific requirements and special behavior.
- If workflow changes, update this file first, then keep step skills thin.
