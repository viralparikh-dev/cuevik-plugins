---
name: migrate
description: Brings an older repo's .cuevik/ files up to the current contracts, in one PR. Any older config or lineage comes up to the current version (story keys and lineage steps renamed from numbered step ids to step slugs; boardState, backlogModel, the docs/TEST-STRATEGY.md entry and its upstream links added where an older file lacks them). Replaces the repo's merge-order workflow with the current one when the repo has one. Run in the project folder. A repo that is already current gets "Nothing to migrate." Changes nothing until you say yes, and never merges.
disable-model-invocation: true
---

# migrate

Edits the two `.cuevik/` files of an already-bootstrapped repo so the current plugins accept them,
replaces its merge-order workflow when it has one, and opens a PR with the edit. It is not a
numbered step: it does not follow the runner's workflow and has no story. It changes nothing until
the operator says yes, makes no other change on GitHub (no issue, no board call), does not touch
`CONTRIBUTING.md`, and never merges. The current folder is the project repo. It takes no arguments.
Run every `gh` command through the Bash tool. Ask with `AskUserQuestion` (runner, Asking The
Operator).

Load `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` (each step's `slug` and its `aliases`: the legacy
keys, the numbered ids it was stored under before steps had slugs),
`${CLAUDE_PLUGIN_ROOT}/references/contracts/config/config.schema.json`,
`${CLAUDE_PLUGIN_ROOT}/references/contracts/lineage/lineage.schema.json`,
`${CLAUDE_PLUGIN_ROOT}/references/contracts/lineage/lineage.example.json` (the default lineage) and
`${CLAUDE_PLUGIN_ROOT}/references/workflows/cuevik-init-order.yml` (the current merge-order
workflow). If any fails to load, stop and output: `Error: <file> could not be loaded.` Never
hardcode a key map: legacy key to slug comes from `aliases`.

## 1. Preflight

Stop at the first failure and output only its message.

1. `git rev-parse --show-prefix` — non-zero: `This folder is not a git repo.` Non-empty: `Run
   migrate from the repo root.`
2. `gh auth status` — non-zero: `gh is not signed in. Run gh auth login, then re-run.`
3. `git status --porcelain` is empty, or `Uncommitted changes detected — commit or stash before
   continuing.`
4. `git fetch --prune origin`, `git checkout main`, `git pull --ff-only`. Any fails: `Could not
   fast-forward main — resolve the pull error before continuing.`
5. `git show main:.cuevik/config.json` and `git show main:.cuevik/lineage.json` both exit 0, or
   `This repo is not bootstrapped. Run /cuevik-start:00-bootstrap (or /cuevik-start:express)
   first.` Each parses as JSON, or name the file that does not.
6. `gh pr list --head init/migrate --state open --json url` returns `[]`, or `A migration PR is
   already open: <url>. Merge it, or close it and delete its branch, then re-run.`

## 2. What changes

Read both files from `main`. The edits below are the whole migration. Everything else in either
file is left exactly as found, including project-specific owners, reviewers and extra documents.
Every edit applies only where the file still needs it, so a repo on any older version ends in the
same place.

**`.cuevik/config.json`**

1. `schemaVersion` becomes the `const` in the config schema.
2. No `boardState` key: add `"boardState": "configured"` right after `schemaVersion`. Every config
   of that age has a `project`; if `project` is missing, **STOP** —
   `config.json has no project, so it cannot be migrated safely. Fix it by hand.`
3. No `backlogModel` key: add `"backlogModel": "epic-grouped"` right after `boardState`. Every
   existing repo files epics, so the value is the same for all of them.
4. In `initiation.stories`, rename each key that is a legacy key (an `aliases` entry) to the
   `slug` of the step it belongs to: `04-tech-stack` becomes `tech-stack`. A key that is already
   a slug stays. A key that is neither stays, and is listed in the PR body. A legacy key and its
   slug both present, or two legacy keys of the same step: **STOP** and name them.

**`.cuevik/lineage.json`**

1. `schemaVersion` becomes the `const` in the lineage schema.
2. In every document's `steps`, replace each legacy key with the step's `slug`. A `steps` array
   that would then name one slug twice: **STOP** and name the document.
3. No document with path `docs/TEST-STRATEGY.md`: insert the entry of that path from the default
   lineage, right after the document `docs/TECH-STACK.md` (at the end if that document is absent).
4. For each of `docs/AI-TOOL-GUIDE.md`, `README.md` and `docs/BACKLOG.md` that the lineage has and
   whose `upstream` lacks `docs/TEST-STRATEGY.md`: insert it right after `docs/TECH-STACK.md` in
   that list (at the end if that is absent).

**`.github/workflows/cuevik-init-order.yml`** (the `init-order` check of the repo's `main` ruleset)

1. On `main` and different from the plugin's file (line endings ignored): replace it with a
   byte-for-byte copy of the plugin's file (copy the file; do not retype it). The current one
   accepts a step's `init/<slug>` branch and its older numbered branches; an older copy passes
   every `init/<slug>` PR ungated.
2. Not on `main`: leave it absent. The repo was bootstrapped before the check existed and has no
   ruleset that needs it; setting one up is not a migration.

**Already current.** Each file's `schemaVersion` equals the `const` in its schema, `backlogModel` is
present, no legacy key is left in either file, the lineage has the `docs/TEST-STRATEGY.md` entry
and the upstream links of step 4, and the workflow is absent or matches the plugin's: output
`Nothing to migrate.` and stop.

## 3. Show and approve

Print what will change as a short table (file, edit), then the changed lines of each file as a
diff in a fenced `diff` block; for the workflow, say it is replaced with the plugin's current file
and show no diff. Ask `Open a PR with these edits to <the files that change>?` (`Yes` / `No`).
Only `Yes` acts.

## 4. Act

1. Branch `init/migrate` from `main`. If it exists locally or on GitHub, the runner §3 rule
   applies (ask `Reuse it` / `Delete it`, delete only after a yes). `/cuevik-start:cleanup`
   removes the local branch after the PR merges.
2. Edit the two `.cuevik/` files in place with minimal text edits and keep their formatting (an
   inline array stays inline; the new lineage entry is copied as text from the default lineage),
   so the diff shows only the changes listed in section 2. Do not re-serialize the JSON. Copy the
   workflow file when section 2 replaces it.
3. Check each result against its schema: re-read the schema files and check every rule before
   committing. For the lineage also: every `upstream` path is the path of a document in the file,
   no document lists itself, no cycle. Any failure: stop, show it, change nothing more.
4. `git add .cuevik/config.json .cuevik/lineage.json` (and
   `.github/workflows/cuevik-init-order.yml` when it was replaced), then `git commit` with the
   message `chore: migrate .cuevik files to the current contract versions`.
5. Ask `Push and open the PR?` (`Yes` / `No`). Never push without a yes.
6. `git push -u origin init/migrate`. If the push is refused (for example a 403 because git holds
   another account's credentials than `gh`, or, when the workflow file changed, a token without
   the `workflow` scope: `gh auth refresh -s workflow`), say so and stop: the commit stays local
   and the operator fixes the credentials. Then `gh pr create --base main --head init/migrate`,
   title the commit message. Body, in this order: the edits (as in step 3); the key renames and any
   unknown story key left in place; then these notes that apply:
   - Step branches are now `init/<slug>`, for example `init/tech-stack`. A PR already merged or
     open on an older numbered `init/` branch still counts for its step.
   - (Only if the workflow was replaced.) `.github/workflows/cuevik-init-order.yml` is the
     plugin's current copy.
   - (Only if the repo has no such workflow.) This repo has no `init-order` check, so nothing on
     GitHub enforces the order in which step PRs merge: merge them in step order.
   - (Only if this run added the `docs/TEST-STRATEGY.md` entry.) No initiation story exists for
     `05-test-strategy` and none was filed. `status` lists that step as not started; running
     `/cuevik-start:05-test-strategy` writes the strategy. If initiation was already complete,
     `status` shows one step outstanding and may note the closed initiation epic; running
     `05-test-strategy` clears both.
   - (Only if `CONTRIBUTING.md` on `main` has the `INITIATION-ONLY` block.) Its branch table keeps
     the old branch names until `09-finalize` removes the block; the steps still to run use
     `init/<slug>`.

   End with `Not merged — left for review.`
7. Report the PR URL and: `Merge it on GitHub, then re-run the step you wanted.`

## Rules

- The only files written are `.cuevik/config.json`, `.cuevik/lineage.json` and, when the repo
  already has one, `.github/workflows/cuevik-init-order.yml`, on `init/migrate`.
- No board call, no issue, no label, no edit to `CONTRIBUTING.md`, no merge.
- Re-running on a migrated repo is safe: it ends at `Nothing to migrate.`
