---
name: 07-backlog
description: Step 07 of cuevik-start. Run after 06-readme's PR is merged, in a new session in the project folder. Derives the initial epics and stories from docs/PRD.md, shows them for the Product Owner's approval, files them as GitHub issues (labels epic, story, priority:*), and opens a PR adding docs/BACKLOG.md — the frozen manifest of what initiation filed. From then on GitHub is the backlog.
disable-model-invocation: true
---

# 07-backlog

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `07-backlog` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   template, commit message, PR summary, special actions.
3. This file — how the backlog is derived and filed, and what `docs/BACKLOG.md` must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 07-backlog.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (runner, Skills).

This step turns `docs/PRD.md` into GitHub issues the team works from, and records what it filed in
`docs/BACKLOG.md`. That file is a snapshot: it is frozen once this PR merges, and GitHub issues
are the backlog from then on. Later requirements reach GitHub through `/cuevik-ship:03-create-backlog`,
never through an edit of `BACKLOG.md`.

## What This Document Covers

The template (`BACKLOG.template.md`) owns the headings and their order, and the frozen note under
the header block. This list owns what each section must contain. Fill every section; add or drop
none.

1. **Summary** — epic count, story count, and the Must / Should / Could breakdown of the stories
   filed.
2. **Epics** — one row per epic: local ID (`E1`, `E2`, …), title, the `PRODUCT.md` goal or
   feature area it serves, issue number.
3. **Stories** — one row per story: local ID (`S1`, …), parent epic, the `PRD-NNN` it fulfils,
   priority, issue number, and the acceptance criterion copied from `PRD.md`, not rewritten.
4. **Out-of-Scope Notes** — every `PRD.md` requirement not filed, with why (deferred by the
   Product Owner, already filed, or covered by another story).

## Conventions (shared with cuevik-ship)

`/cuevik-ship:03-create-backlog` finds and extends this backlog later, so these conventions are
exact:

- **Labels only**, no GitHub issue types: `epic` on epics; `story` plus one of `priority:must`,
  `priority:should`, `priority:could` on stories. Never `initiation` (that label belongs to the
  initiation issues `00-bootstrap` filed).
- **Epics** — one per `PRD.md` §6 capability subsection, titled `Epic: <subsection title>`, plus
  one `Epic: Non-Functional Requirements` when §7 has requirements. Body:

  ```markdown
  <one or two sentences: the user value, from PRD.md §4>

  Source: docs/PRD.md §6 "<subsection title>"
  Product goal: <PRODUCT.md feature area>
  Requirements: PRD-001, PRD-002, …
  ```

  The non-functional epic cites `Source: docs/PRD.md §7`.
- **Stories** — one per requirement, never several requirements in one story. Title
  `PRD-NNN: <requirement title> (<Priority>)`, priority `Must`, `Should` or `Could`. Body:

  ```markdown
  <the requirement text, copied from PRD.md>

  **Acceptance criterion:** <copied from PRD.md §8; for an NFR, its target>

  Source: docs/PRD.md §6 "<subsection title>" (or §7)
  ```

- **Parent** — every story is a sub-issue of its epic. No story without an epic.

## Interview

At runner §4, read every upstream document from `main`. `ARCHITECTURE.md`, `TECH-STACK.md`,
`AI-TOOL-GUIDE.md` and `README.md` are context only: no backlog scope comes from them.

1. **Existing issues.** `gh issue list --state all --limit 500 --json number,title,labels,state`.
   Leave out every issue labelled `initiation`. An open issue whose title matches a planned epic
   or story exactly is reused, not created again (a re-run after a partial failure); a closed one
   is reported and the operator decides whether that row is filed again.
2. **Derive** the epics and stories from `PRD.md` with the conventions above. NFRs have no MoSCoW
   priority in `PRD.md`: list them in chat and ask the Product Owner for each one's priority, or
   `Won't` to leave it out (it then goes to §4 with the reason). Every other priority is copied
   from `PRD.md` §6.
3. **Approve the backlog** (`steps.yml` special action: nothing is written before this). Print one
   table per epic: local ID, title, labels, `PRD-NNN`, priority, `new` or `reuse #n`; then the
   Out-of-Scope rows. Ask `AskUserQuestion` `File these <E> epics and <S> stories on GitHub?`
   (`Yes` / `No`). On `No`, ask what to change and show the table again. Apply the Product Owner
   challenge sequence (`roles/product-owner.md`) to anything the operator adds: a story with no
   `PRD-NNN` is not filed; list it in the PR body under **Proposed PRD.md changes** for a
   `/cuevik-docs:update docs/PRD.md` first. Never change a requirement or its criterion here.

The runner §2 plan names the label creates and says the issues are listed for approval here; this
approval is what allows them.

## Filing

After `Yes`, on GitHub, in this order, one issue at a time (`steps.yml` special action), capturing
each number from the URL `gh issue create` prints:

1. **Labels** — create each missing one:
   `gh label create <name> --color <hex> --description "<text>"` (`epic` 5319E7, `story`
   1D76DB, `priority:must` B60205, `priority:should` FBCA04, `priority:could` C2E0C6).
2. **Epics** — `gh issue create --label epic --title "<title>" --body "<body>"`.
3. **Stories** — `gh issue create --label story --label priority:<p> --title "<title>" --body
   "<body>"`, then link it to its epic:
   `gh api -X POST repos/<owner>/<repo>/issues/<epic>/sub_issues -F sub_issue_id=<id>`, where
   `<id>` is `gh api repos/<owner>/<repo>/issues/<story> --jq .id`.
4. **Board** — add each epic and story:
   `gh project item-add <number> --owner <project owner> --url <issue url> --format json --jq .id`
   (from `.cuevik/config.json`), and set `Item Type` to `Epic` or `Story` (runner §7, Field
   lookup and Set a value). Never set Status, Priority, Size, Sprint or an assignee: sprint
   planning does that. A failed board call never stops the step: report it in the PR body.

Any other `gh` failure: **STOP** and report what was filed and what was not. A re-run reuses the
filed issues by exact title (Interview step 1).

## BACKLOG.md

Fill the template with the issue numbers just captured, then show it and ask `Approve
BACKLOG.md?` (`Yes` / `No`). Every row has a real issue number; none is left blank or pending.

## PR body

Follow runner §6. Besides the `prSummary` (epic count, story count, priority breakdown) and the
reviewer checklist below, list:

- **Issues filed** — each epic with its stories, by number; reused ones marked.
- **Board** — items added and Item Type set, or each failure.
- **Proposed PRD.md changes** — gaps found while deriving the backlog, or `None`.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] Output matches the template skeleton — header block, frozen note, all four sections in
      order, and the references table present; no top-level section added or removed, and no
      `[placeholder]` left unfilled.
- [ ] Every epic maps to a `PRD.md` §6 capability (or §7) and a `PRODUCT.md` goal or feature area.
- [ ] Every story cites exactly one `PRD-NNN`, has a parent epic, and its acceptance criterion
      matches `PRD.md` word for word.
- [ ] Every row has a GitHub issue number, and every issue carries its labels: `epic`, or `story`
      plus one `priority:*`. No `initiation` label on any of them.
- [ ] No requirement was invented: everything traces to `PRD.md`.
- [ ] Every `PRD.md` requirement not filed is in §4 with a reason.
