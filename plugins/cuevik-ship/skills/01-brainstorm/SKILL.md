---
name: 01-brainstorm
description: Step 01 of cuevik-ship. Takes a new idea (or an existing issue number), checks it is not a duplicate, files it as an idea issue at once, opens the issue's branch and worktree, and explores it with you until it can be approved or rejected; the decision lands as brainstorming/brainstorm.md in a PR into the issue branch. No requirements, no design.
disable-model-invocation: true
argument-hint: "[\"<idea>\" | <issue#>]"
---

# 01-brainstorm

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `branches.md`, `references-block.md`,
   `config.md` (same folder).
3. This file — what is specific to 01.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 01-brainstorm.`

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (process, Skills).

**Worktree root** (plugin option): `${user_config.worktree_root}` — resolve it as
`branches.md` says.

01 explores an idea until a person can say whether it should exist, and in what shape. It writes
no requirement (`PRD-NNN` is 02's), assigns no priority, picks no epic (03's), and designs
nothing (05's): options are explored at the level of what a user would see and why it matters.

Arguments: `$ARGUMENTS`

- **An idea** in words (`"repeat-order reminders"`): a working name; it seeds the slug.
- **An issue number** (`41`, `#41`, URL): explore an existing issue.
- **Empty:** list the open `idea` issues that have a `ship/<n>-*/01-brainstorm` branch and no
  merged 01 PR (`git ls-remote --heads origin 'refs/heads/ship/*/01-brainstorm'`), and ask which
  to resume, or whether to start a new idea.

## 1. Resolve

Run the gate (`gate.md`): `ship-state.sh --preflight` for a new idea, or `ship-state.sh <n>
01-brainstorm` for an issue number. Then:

- **Issue number.** The script's `== issue` section has its state, labels and title.
  - Closed: **STOP** — reopen it on GitHub first, or start a new idea.
  - Label `epic`: **STOP** — an epic is not one idea; brainstorm one of its stories, or a new
    idea.
  - Label `bug`: **STOP** — a bug fix starts at `/cuevik-ship:04-plan-intent <n>`.
  - A `ship/<n>-*` branch already exists: 01 PR merged → **STOP** and name the next step; a
    `.../01-brainstorm` branch with no merged PR → this is a **resume** (below).
  - A story (title starts `PRD-NNN:`): allowed; 03 later treats it as changed. Never add `idea`
    to it, and never close it in this step.
  - Anything else: it becomes an idea; the plan adds the `idea` label.
- **Resume.** The issue's worktree exists (`branches.md`, Find): this session must run inside it,
  or **STOP** and say which folder to open. Read `brainstorm.md` there, say which sections are
  thin and which open questions are unanswered, and continue from §4 below. Do not start a
  second file.

## 2. The idea, in the operator's words

Always ask, in chat: `Describe the idea in two or three sentences.` (for an existing issue,
show its body first as a starting point). Keep the sentences exactly as written: they open the
issue body and §1 of the file, unedited.

## 3. Duplicates, then file the issue (before any interview)

1. **Duplicates.** `gh issue list --label idea --state all --limit 500 --json
   number,title,state,url` and `gh issue list --label story --state all --limit 500 --json
   number,title,state,url`. Compare titles and, for close matches, bodies with the description.
   Report every overlap with its number and state. A likely duplicate: ask `Continue with a new
   idea anyway?` (`Yes` / `No`); on `No`, **STOP** and name the existing issue. A duplicate
   never gets a number.
2. **Slug** (`branches.md`, Names) from the working name or the description, shown in the plan.
3. **Plan and approval** (`gate.md`, After the gate): the issue to create (exact title, body,
   label), the board item (when the repo has a board), the branches, the worktree path and the
   folder. Title: the working
   name in sentence case. Body: the sentences, a blank line, then the empty References block
   (`references-block.md`). For an existing issue: only the `idea` label (if added) and the
   branches.
4. **Create**, in this order, once approved:

   ```sh
   gh label create idea --color C5DEF5 --description "cuevik-ship idea, not yet a story"   # if missing
   gh issue create --label idea --title "<title>" --body-file <tmp>/issue.md               # prints the URL; <n> is its last segment
   # board.addItem for the new issue (config.md): only with a board, in a local session
   git branch ship/<n>-<slug>/issue origin/main
   git push -u origin ship/<n>-<slug>/issue
   git worktree add <path> -b ship/<n>-<slug>/01-brainstorm origin/ship/<n>-<slug>/issue
   ```

   Then create `docs/ship/<n>-<slug>/brainstorming/` in the worktree and write `brainstorm.md`
   from the template below, with §1 filled and every other section empty. From here on, work in
   the worktree (absolute paths, or `git -C <path>`): findings are saved to the file as they
   come, from the first minute.

## 4. Read, then interview

1. **Read** `docs/PRODUCT.md` and `docs/PRD.md` from `origin/main`; never recall them. Before
   the first question, report the `PRD-NNN` this idea overlaps, extends or contradicts, and the
   `PRODUCT.md` section it lands in or pushes against. Write this into §6 as you go.
2. **Interview** — one open question per message, a single plain sentence, anchored in
   specifics (a real user, the last time it happened, what it cost). Push on whichever of these
   stays soft; they are the file's sections, so a soft answer is a hole in it:
   - **Problem** — what is broken or missing today, for whom; no solution in it.
   - **Who** — which target users from `PRODUCT.md` / `PRD.md`.
   - **Why it matters** — what changes for the user if this exists, and what its absence costs.
     "Competitors have it" is not a reason on its own.
   - **Options** — at least two shapes, including the smallest useful one, each with what it is
     for and against.
   - **Recommendation** — which option, and why it beat the others.
   - **Out of scope** — at least one plausible thing it deliberately leaves out.
   - **Open questions** — what is still unknown.
3. **Play back** each part in a few lines before writing it, mark guesses as guesses, and ask
   what is wrong or missing. Challenge the answers: agreement before pressure-testing is worth
   nothing. No unprompted guesses; a guess only when asked, labelled `My guess:`.
4. **Recon** (the operator's files, the web for prior art): read-only, only after the operator
   says yes. Attachments the operator gives, and any useful file found, are saved in the same
   `brainstorming/` folder and linked from the section they inform.

**Abandoned.** If the operator drops the idea partway: ask `Close #<n> as not planned?` (`Yes` /
`No`). On `Yes`, commit and push what exists (as for `Not yet`, below), comment why and close it
(`gh issue close <n> --reason "not planned" --comment "<why>"`), then name
`/cuevik-ship:cleanup <n>`. Never close a pre-existing story.

## 5. The gate

Every open question in §8 is either answered or explicitly deferred, and the only valid reason to
defer is that `02-audit-prd` can settle it against the PRD. An unmarked open question: say which,
and do not move to the decision.

## 6. Decide

Show the file and ask `What is the decision on this idea?` with options `Approved`, `Rejected`,
`Not yet`:

- **Approved** — it should exist in the recommended shape. `**Status:** Approved`.
- **Rejected** — it should not. `**Status:** Rejected`, and one line in §9 saying why. A rejected
  idea stays a record: the next person with the same idea finds it.
- **Not yet** — stays `Draft`; a later run resumes it.

Only an explicit answer sets a status.

## 7. Commit, push, PR

1. `git add docs/ship/<n>-<slug>/` and commit `docs(ship): brainstorm #<n> — <title>`.
2. Ask `Push ship/<n>-<slug>/01-brainstorm<, and open the PR>?` (`Yes` / `No`). Push even a
   `Draft`: the branch is how a later run resumes.
3. `Approved` or `Rejected` only: open the PR into the issue branch (`branches.md`, PRs), title
   `docs(ship): brainstorm for #<n> — <Approved | Rejected>`, body: the one-line decision, the
   recommendation or the reason, and `Refs #<n>`. `Not yet`: no PR.
4. Refresh the References block (`references-block.md`): `ship-refs.sh <n> apply`. It writes `Brainstorm:` with
   the PR head permalink and the PR number.
5. **Rejected:** ask `Close #<n> as not planned?` (`Yes` / `No`); on `Yes`, comment the reason
   and close it. A pre-existing story is never closed here: retiring a requirement is 02's job.

Report the issue URL, the PR URL (if any), the worktree path, and what comes next:

- `Approved` → merge the PR, then run `/cuevik-ship:02-audit-prd <n>` in a new session opened in
  the worktree.
- `Rejected` → merge the PR (it is the record), then `/cuevik-ship:cleanup <n>` from the main
  checkout.
- `Not yet` → `/cuevik-ship:01-brainstorm <n>` in a new session in the worktree.

## brainstorm.md

Header per `process.md` (Artifacts), title `<Title> — Brainstorm`, then:

```markdown
<One plain sentence: what this idea is.>

## 1. The idea

<The sentences from section 2, exactly as written.>

## 2. Problem and who has it

## 3. Why it matters

## 4. Options explored

- **<option>** — <what it is>. For: <...>. Against: <...>.

## 5. Recommendation

## 6. Fit with the product

- **PRODUCT.md:** <section it extends or pushes against>
- **PRD.md:** <PRD-NNN it overlaps, extends or contradicts; the §6 sections it lands in>

## 7. Out of scope

- <...> — <why it is out>

## 8. Open questions

- **<question>** — answered: <answer>
- **<question>** — deferred to 02-audit-prd: <what it will be settled against>

## 9. Decision

<Approved / Rejected and why, in one line. Requirements are recorded in 02's PR, not here.>
```

Attachments and other files found during the brainstorm sit beside it in `brainstorming/`.
