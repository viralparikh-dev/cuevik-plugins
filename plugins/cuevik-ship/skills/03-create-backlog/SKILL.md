---
name: 03-create-backlog
description: Step 03 of cuevik-ship. Run after 02-audit-prd's docs PR is merged. Files the ratified requirements as GitHub issues — turns the idea issue into its story (PRD-NNN title, story and priority labels), finds or creates each story's epic (on a flat-backlog repo it files no epics and types the stories Feature instead), splits the idea into several stories when it covers several requirements, links sub-issues and blocked-by — after you approve one table. Writes to GitHub only (not docs/BACKLOG.md), with no branch and no PR.
disable-model-invocation: true
argument-hint: "<issue#> | PRD-NNN [PRD-NNN ...]"
---

# 03-create-backlog

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `references-block.md`, `config.md` (same folder).
3. This file — what is specific to 03.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 03-create-backlog.`

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding does not apply (process, Skills).

03 turns requirements that are on `main` into work on GitHub: one story issue per `PRD-NNN`, each
a sub-issue of the epic for its PRD section, prerequisites linked as blocked-by. It writes no
file and opens no PR; GitHub is the backlog after initiation, so `docs/BACKLOG.md` stays as it is.
Every write is visible to the team, so nothing is written before the table is approved.

**Backlog model.** Read `backlogModel` (`config.md`). Everything below describes `epic-grouped`.
On a `flat` repo (the Express lane): file no epic and no sub-issue-to-epic link — skip epic
resolution (§2 "Epic per ID"), the **New, new section** class (§3), and every epic write (§5); the
References block omits `Epic:`, and `04-plan-intent` gates on the `story` label. Each story, new or
converted, is typed `Feature` where the owner supports it (`config.md`, Issue types). `blocked_by`
links and everything else are unchanged.

Arguments: `$ARGUMENTS`

- **An issue number** — the normal path: the IDs come from that issue's ratification record.
- **One or more IDs** (`PRD-053 PRD-008`) — requirements that did not come through 02; each
  becomes a new story (no idea issue to convert). A range (`PRD-053..PRD-060`) is refused: IDs are
  not grouped by section, and a range silently includes or skips the wrong ones.
- **Empty:** **STOP** and ask.

## Conventions (shared with `/cuevik-start:08-backlog`)

- Labels only: `epic`; `story` plus one of `priority:must`, `priority:should`, `priority:could`.
  Never on an `initiation` issue, and `initiation` issues are never candidates.
- **Story** title `PRD-NNN: <requirement title> (<Must | Should | Could>)`. Body, above the
  References block:

  ```markdown
  <the requirement text, copied from PRD.md>

  **Acceptance criterion:** <copied from PRD.md §8; for an NFR, its target>

  Source: docs/PRD.md §6 "<section title>" (or §7)
  ```

- **Epic** title `Epic: <§6 section title>` (`Epic: Non-Functional Requirements` for §7). Body:

  ```markdown
  <one or two sentences: the user value, from PRD.md §4>

  Source: docs/PRD.md §6 "<section title>"
  Requirements: PRD-001, PRD-002, …
  ```

## 1. Gate

`gate.md` common preconditions 1–3 (no worktree needed: 03 has no branch). Then `git fetch
--prune origin` and read only from `origin/main`.

- **Issue number:** its References block has `Docs PR: #<q>`, and `gh pr view <q> --json
  state,baseRefName,body` is `MERGED` into `main`; otherwise **STOP** (02 is not merged). Parse the
  `<!-- cuevik-ship:ratified -->` YAML block in that body; missing or unreadable: **STOP**. IDs to
  file: `new`, `changed`, `retired`. Only `covered` (or nothing): **STOP** — nothing to file.
- **Every ID** is in `origin/main:docs/PRD.md` — a §6 or §7 item, or struck through as retired.
  Any missing: **STOP** and name it.

## 2. Read

For each ID, from `origin/main:docs/PRD.md`: its section, title, priority (NFRs have none: ask the
operator, as `08-backlog` does), requirement text, §8 criterion, and prerequisites (the
ratification record's `prerequisites`, plus any named in its text or §10).

Then GitHub (never `initiation` issues):

- **Existing story** per ID: `gh issue list --label story --state all --search "PRD-NNN in:title"
  --json number,title,state,body,url`, keeping only a title that starts exactly `PRD-NNN:`.
- **Epic** per ID (`epic-grouped` only — on a `flat` repo skip this, `config.md`), in this order (D6):
  1. the parent (`gh api repos/<owner>/<repo>/issues/<story>/parent`) of existing stories in the
     **same section**: exactly one → that epic; several → ask;
  2. else an `epic`-labelled issue whose body has `Source: docs/PRD.md §6 "<section title>"`;
  3. else `docs/BACKLOG.md` on `origin/main`: the epic of stories citing IDs from that section;
  4. else a **new epic**.
  Several candidates at any step: ask. Note an epic whose title has drifted from its section name
  (reported, never renamed here).
- **The issue itself:** its labels and current parent. A parent different from the resolved epic:
  ask whether to keep it or move it; never move without a yes.
- **Stale work folders:** for a changed ID whose story already has a `ship/<m>-*/issue` branch,
  note it (its intent or spec was written against the old requirement).

## 3. Classify

Each ID is exactly one of:

- **Convert** — the issue itself becomes the story for this ID.
- **New** — no story: create one under the section's epic (`flat`: just create the story, no epic).
- **New, new section** — no story and no epic: create the epic first (`epic-grouped` only; on a
  `flat` repo this collapses into **New** — no epic is created).
- **Changed, story open** — update its title and body to the PRD on `main`, and comment the docs
  PR link.
- **Changed, story closed** — the shipped work no longer matches: propose reopening it or filing a
  follow-up story; the operator picks.
- **Retired** — comment the docs PR link and close it as not planned, on a yes.
- **Already filed** — a story exists and matches the PRD text: skip. This makes a re-run after a
  partial failure safe.

**One ID or several.** The issue converts into exactly one story. With several new IDs (a
split), it keeps the **first in prerequisite order** (D9), overridable in the table; each other
ID becomes a new story under **its own section's epic** (D11), with no branch or worktree until
its own `/cuevik-ship:04-plan-intent`. An existing story given to 01 (D8) is **Changed**, not
converted. **No new ID** and the issue is not itself a story (the idea only changed requirements
that already have stories): nothing converts. The plan asks to close the issue as not planned
with a comment linking those stories (its brainstorm stays reachable through its References), and
the report names `04-plan-intent` for each changed story.

## 4. Approve one table

Print one table: ID · class · target (`#<n>`, `#<m>` or `new`) · title · epic (`#<e>` or `new`) ·
labels · blocked-by. Below it, the exact title and body of every issue to create or edit. Ask
`File these changes on GitHub?` (`Yes` / `No`); the operator may also name rows to drop (a partial
yes). Nothing is written before it.

## 5. Write, in dependency order

Epics first, then prerequisites, then the rest, so every link has a target:

```sh
gh label create <name> --color <hex> --description "<text>"     # each missing label (08-backlog colours)
gh issue create --label epic --title "<title>" --body-file <tmp>/epic.md
gh issue create --label story --label priority:<p> --title "<title>" --body-file <tmp>/story.md
gh api repos/<owner>/<repo>/issues/<n> --jq .id                   # the REST id the links need
gh api -X POST repos/<owner>/<repo>/issues/<epic>/sub_issues -F sub_issue_id=<id>
gh api -X POST repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by -F issue_id=<prerequisite id>
gh issue edit <n> --title "<title>" --body-file <tmp>/body.md
gh issue comment <n> --body "Requirement changed in <docs PR url>."
```

- **Convert** the issue: title as above; replace its body **above** the References block with the
  story body (keep the block); `gh issue edit <n> --remove-label idea --add-label story --add-label
  priority:<p>`; link it under its epic (moving a parent needs `-F replace_parent=true`, only on a
  yes).
- **Split extras:** each body ends with its own References block: `Split from: #<n>`, the
  `Brainstorm:` permalink copied from `#<n>`, `Docs PR: #<q>`, `Epic: #<e>`.
- A story joining an existing epic: add its ID to the epic's `Requirements:` line.
- **Board** (local sessions only, `config.md`; none when `boardState` is `none`): `board.addItem`
  for every new issue, and `board.setField` `Item Type` `Epic` or `Story` on new items and on the
  converted issue. Never set Status. In a cloud session skip it and list the URLs to add.
- Any other `gh` failure: **STOP** and report what was written and what was not; a re-run
  classifies the written rows as **Already filed**.

Then refresh the References block of the issue: `Epic: #<e>` and, on a split,
`Split into: #<a>, #<b>`. The `Epic:` line and the removed `idea` label are what
`04-plan-intent` gates on (D10). On a `flat` repo there is no `Epic:` line (the block keeps only
`Split into:` where it applies); the `story` label and the removed `idea` label are what
`04-plan-intent` gates on instead (`config.md`).

## 6. Report

End with, and nothing after:

- every issue created, edited or closed — number, title, URL — grouped by epic;
- the blocked-by links added;
- cloud runs with a board: the URLs to add to the board locally, unless its `Auto-add to project`
  workflow covers them;
- stale work folders, and epics whose title drifted from the section name;
- next: `/cuevik-ship:04-plan-intent <n>` in a new session in the issue's worktree, and
  `/cuevik-ship:04-plan-intent <m>` for each split story nothing blocks (it creates their branch
  and worktree).
