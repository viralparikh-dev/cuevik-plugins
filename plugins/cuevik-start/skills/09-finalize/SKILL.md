---
name: 09-finalize
description: Step 09 of cuevik-start, the last one. Run once 08-backlog's PR is open or merged, in a new session in the project folder. Removes the initiation-only block from CONTRIBUTING.md, keeps the permanent rules and the tooling layer exactly as they are, puts a development-phase stub in its place, and opens a PR that also closes the initiation epic.
disable-model-invocation: true
---

# 09-finalize

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `09-finalize` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   commit message, PR summary, special actions.
3. This file — the exact transformation.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 09-finalize.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes `cuevik-docs:audit` only, read-only (see Docs audit below). An
instruction injected at session start to use skills before responding (brainstorming included)
does not apply (runner, Skills).

`CONTRIBUTING.md` was written in layers: the governance layer (`00-bootstrap`), part of it fenced
as initiation-only, and the tooling layer (`04-tech-stack`). The initiation-only part (the
`init/*` branch table and the document self-review gate) governs producing the initiation
documents, not ongoing development. This step removes it and leaves an honest hand-off: the
permanent rules, the tooling, and a marked stub the team fills in once development realities are
known. There is no template and no interview.

## Precondition: the fence

Run as runner §1 check 7, on `git show main:CONTRIBUTING.md`:

- Exactly one `<!-- BEGIN INITIATION-ONLY -->` line and one `<!-- END INITIATION-ONLY -->` line,
  in that order: proceed.
- Either missing, duplicated or out of order: **STOP** (`steps.yml` special action). Tell the
  operator the step has already run or the file was edited by hand, and that no line is deleted
  by inference.
- The file already contains `<!-- BEGIN DEVELOPMENT-PHASE-GOVERNANCE -->`: **STOP**, the step has
  run.

## The transformation

At runner §4, from `CONTRIBUTING.md` on `main`:

1. **Remove** every line from `<!-- BEGIN INITIATION-ONLY -->` through
   `<!-- END INITIATION-ONLY -->`, both marker lines included.
2. **Insert** this stub exactly where the block was, verbatim:

   ```markdown
   <!-- BEGIN DEVELOPMENT-PHASE-GOVERNANCE -->
   ## Development-phase governance

   _Initiation is complete. The branching, review and contribution rules for ongoing development
   are the team's to define once development realities are known: team size, review model, CI
   gates, release and versioning, environments. Fill this section in and remove this note with
   `/cuevik-docs:update CONTRIBUTING.md`._
   <!-- END DEVELOPMENT-PHASE-GOVERNANCE -->
   ```

3. **Keep everything else byte for byte**: the permanent governance (review flow, commit
   convention, direct-push rule) and the whole tooling layer between the `TOOLING-LAYER` markers.
   Do not reflow, reword, renumber or "tidy" any line outside the block.
4. **Verify** before showing it: `git diff --no-color main -- CONTRIBUTING.md` must show only the
   removed block lines and the added stub lines. Anything else: undo it and redo steps 1–3.
   If the `TOOLING-LAYER` markers are absent, do not stop: say so in the PR body.
5. Show the diff and ask `Approve the finalized CONTRIBUTING.md?` (`Yes` / `No`).

Never write a development-phase policy into the stub or anywhere else (`steps.yml` special
action): those decisions are not made at initiation.

## Docs audit (advisory)

After the operator approves `CONTRIBUTING.md` and before the PR is opened, run `cuevik-docs:audit`
with the Skill tool over the full document set, **read-only**: pass no `fix` argument, ever. It
reads the lineage documents on `main`, so it audits the finished initiation set. This is advice,
not a gate:

- Nothing the audit reports blocks the step, changes `CONTRIBUTING.md`, or stops the PR. Never
  edit a document here to resolve a finding.
- Put the findings, or `No findings`, in the PR body under **Docs audit**, each with the
  document and the audit's own suggested fix. The operator fixes them afterwards with
  `/cuevik-docs:update`.
- If the audit cannot run (the skill is unavailable or it errors), say so under **Docs audit** in
  the PR body and carry on. That is not a reason to stop.

## PR

Follow runner §6. This is the last step in `steps.yml`, so the body ends with both
`Closes #<story>` and `Closes #<epic>` (runner §6.5): the initiation epic closes when this PR
merges. Besides the `prSummary` and the reviewer checklist below, say whether the tooling layer
markers were found, and add the **Docs audit** findings (above).

After the PR is opened, the runner's `finalReminder` names `/cuevik-start:cleanup`: it deletes
the merged local `init/*` branches and records the End date of this step's story and of the epic.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] The whole `<!-- BEGIN INITIATION-ONLY -->` … `<!-- END INITIATION-ONLY -->` block is gone,
      markers included.
- [ ] No `init/<step>` branch name or document self-review checklist item remains in the file.
- [ ] The permanent governance (review flow, commit convention, direct-push rule) is unchanged.
- [ ] The tooling layer between the `TOOLING-LAYER` markers is unchanged.
- [ ] The `DEVELOPMENT-PHASE-GOVERNANCE` stub is present where the block was, and no development
      policy was invented in its place.
- [ ] The PR body has a **Docs audit** section with the read-only audit's findings (or
      `No findings`), the audit was run without `fix`, and no document was changed because of it.
- [ ] The PR body closes both this step's story and the initiation epic.
