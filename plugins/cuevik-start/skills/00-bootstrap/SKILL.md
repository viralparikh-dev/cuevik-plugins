---
name: 00-bootstrap
description: Step 00 of cuevik-start. Run first, in the project folder. Connects or creates the GitHub repo, optionally connects or creates a project board, files the initiation epic and stories (on the board when there is one), turns on auto-delete head branches, and opens a PR adding the CONTRIBUTING.md governance layer, .cuevik/config.json, .cuevik/lineage.json and .markdownlint.json.
disable-model-invocation: true
---

# 00-bootstrap

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `00-bootstrap` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   commit message, PR summary, special preconditions and actions.
3. This file — what is specific to bootstrap.
4. `${CLAUDE_PLUGIN_ROOT}/references/board-adapter.md` — every board operation (`board.read`,
   `board.create`, …) and how its result is classified. This file holds the questions and calls
   the operations by name.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 00-bootstrap.` On conflict, precedence is runner > `steps.yml` > this file, except
where the runner defers to this file (runner §0 and §1 for `bootstrap: true`). The adapter owns the
board commands and results.

Owner and reviewers come from the `CONTRIBUTING.md` entry of
`${CLAUDE_PLUGIN_ROOT}/references/contracts/lineage/lineage.example.json` (runner Inputs §3).

GitHub only. Run every `gh` command through the Bash tool. Ask one question at a time and never
use a value the operator has not given or confirmed. Every question and confirmation goes through
`AskUserQuestion` (runner, Asking The Operator); the `(Recommended)` options here are `private`
(§B.3) and the Cuevik template (§D.6).

## Order

Bootstrap runs before the folder is necessarily a repo, so its order differs from other steps:

1. **Auth** (§A).
2. **Repo** (§B). Repo creates are confirmed and run here, because every later check needs `main`
   on GitHub.
3. **Runner §1 checks 1, 2 and 7** — check 7 is the `steps.yml` special precondition plus §C.
4. **Board** (§D). Optional. Questions and reads only.
5. **Runner §2.** Show the checks table, then the plan: every §E change that applies, with its
   commands. Ask once: `Make these <N> changes on GitHub? For more details, review my Plan that I
   articulated above.` (`Yes, make all <N>` · `No, stop`).
6. **Remote changes** (§E), in order, with no further confirmation. §E.5 (board workflows) then
   needs the operator in GitHub, so it guides and asks.
7. **Runner §3** — branch `init/00-bootstrap`.
8. **Outputs** (§F). Show the files and wait for approval before committing.
9. **Runner §5–§6** — commit, push on approval, PR (§G).

## A. Auth

1. `gh auth status`. Non-zero: **STOP** — `gh is not signed in. Run gh auth login, then re-run.`
2. The Projects probe runs in §D once the board owner is known, and the admin check in §C once the
   repo is known. Do not rely on the `X-OAuth-Scopes` header: fine-grained tokens do not send it.

## B. Repo

Detect the folder's state with:

- `git rev-parse --show-prefix` — non-zero: not a repo. Non-empty output: the folder is a
  subfolder of another repo — **STOP** — `This folder is inside the git repo at <git rev-parse
  --show-toplevel>. Run 00-bootstrap from the project repo's root, or, if that parent repo is not
  your project, move this folder out of it (or remove the stray .git there), then re-run.` Never
  delete a `.git` folder yourself. (Do not compare `--show-toplevel` with the current path: on
  Windows the two use different path forms.)
- `git remote get-url origin` — the remote, if any.
- `ls -A` — empty output: empty folder.

| State | Action |
| --- | --- |
| Repo, `origin` on `github.com` | `gh repo view --json nameWithOwner,isEmpty`. Ask the operator to confirm it is the project repo. `isEmpty` true: B.4. |
| Repo, `origin` on `github.com`, `gh repo view` fails | **STOP** — `origin points at <url>, which does not exist or you cannot access. Fix or remove origin, then re-run.` |
| Repo, `origin` not on `github.com` | **STOP** — GitHub only. |
| Repo, no `origin` | Ask owner and name (B.1). Existing: connect it (B.2). Missing: create it (B.3). |
| Not a repo, empty folder | Ask owner and name (B.1). Existing: confirm, then `gh repo clone <owner>/<name> .` (an empty repo then needs B.4). Missing: create it (B.3), which starts with `git init -b main`. |
| Not a repo, folder has files | **STOP** — `This folder has files but is not a git repo. Commit them to a repo yourself, then re-run.` Never commit the operator's files. |

**B.1 Owner and name.** Offer the signed-in user (`gh api user --jq .login`) and their
organisations (`gh api user/orgs --jq '.[].login'`) as owners. Then `gh repo view <owner>/<name>`:
exit 0 means the repo exists.

**B.2 Connect an existing repo.** Confirm, then `git remote add origin
https://github.com/<owner>/<name>.git` and `git fetch origin`.

- The remote has commits, the local repo has none: `git checkout -B main origin/main`.
- Both have commits: `git merge-base --is-ancestor main origin/main` must exit 0. Otherwise
  **STOP** — local `main` has commits GitHub does not; the operator reconciles them.
- The remote is empty: go to B.4.

**B.3 Create a missing repo.** In this order:

1. Ask the visibility (`private` or `public`; suggest `private`).
2. Show every command below that applies as one list and wait for one `yes`:
   - `git init -b main` (folder is not a repo yet);
   - the B.4 empty commit (`main` has no commit yet);
   - `gh repo create <owner>/<name> --<visibility> --source . --remote origin --push`.
3. Run them in that order. In an existing repo, the current branch (`git branch --show-current`)
   must be `main` before the create, or **STOP**.

**B.4 Empty `main` on GitHub.** The GitHub repo is new (B.3) or empty (`isEmpty` true), so `main`
must be pushed before anything else.

- Local `main` has no commit (`git rev-parse --verify -q main` non-zero): run
  `git commit --allow-empty -m "chore: initialize repository"` on `main`. This is the only commit
  bootstrap makes on `main`; it holds no files. Use exactly that message: no body, no
  `Co-Authored-By` or other trailer, whatever the session's own commit attribution says.
- Push `main`: B.3's `--push`, or `git push -u origin main`.

Confirm the commit and push with the create or connect that needs them.

Report what was created or connected before going on.

## C. Bootstrap preconditions (runner §1 check 7)

Run after runner §1 checks 1 and 2. Repo = `<owner>/<name>` from §B.

1. `gh repo view <repo> --json defaultBranchRef --jq .defaultBranchRef.name` is `main`, or
   **STOP**: the runner and every step use `main`.
2. `gh repo view <repo> --json viewerPermission --jq .viewerPermission` is `ADMIN`, or **STOP**:
   bootstrap changes a repo setting, and links a board when there is one.
3. `git show main:.cuevik/config.json` and `git show main:.cuevik/lineage.json` both non-zero, or
   **STOP**: `This repo is already bootstrapped.` Add or change the board through a PR that edits
   `.cuevik/config.json` (the config contract README, "Adding or repairing a board").
4. `gh pr list --head init/00-bootstrap --state open --json url` returns `[]`, or **STOP** —
   `A 00-bootstrap PR is already open: <url>. Merge it (then this step is done), or close it and
   delete its branch (git push origin --delete init/00-bootstrap, git branch -D init/00-bootstrap),
   then re-run.`
5. `git show main:CONTRIBUTING.md`:
   - Non-zero: **new** mode — write the whole file.
   - Contains `<!-- BEGIN INITIATION-ONLY -->`: **STOP** — the governance layer is already there.
   - Otherwise: **insert** mode (§F).
6. `git show main:.markdownlint.json` exit 0: keep the repo's file. Do not write or commit it, and
   say so in the PR.
7. `gh repo view <repo> --json hasIssuesEnabled --jq .hasIssuesEnabled` is `true`, or **STOP**:
   bootstrap files the initiation issues (§E.4). Turn on Issues in the repo settings, then re-run.

## D. Board (questions and reads only)

The board is optional. Every board call is an operation in
`${CLAUDE_PLUGIN_ROOT}/references/board-adapter.md` (the adapter); this section holds the
questions. A board result never stops bootstrap: `unavailable`, or the operator choosing `No
board`, ends the board work with state `none` (§F), and a `degraded` result becomes a `missing`
part.

1. **Owner.** Ask: `Use <repo owner> as the board owner? (yes, or name another user or
   organisation)`. A board can belong to a different owner than the repo.
2. **Projects probe.** `board.read` `probe`. `unavailable`: say why, in the adapter's words, and
   that bootstrap goes on without a board. The state is `none`: skip the rest of §D, §E.1, §E.2,
   §E.5 and the board lines of §E.4. A cloud session ends up here, because it cannot reach Projects.
3. **Pick, create or skip.** `board.read` `list`. Ask `Which board should track this project?` with
   up to two of the most likely open boards (labelled `#<number> <title>`), `Create a new board`
   (suggest the repo name as title) and `No board`. List every open board in the chat block above
   the question; any other number comes through `Other`.
   - `No board`: the operator's choice, not a failure. The state is `none`: skip as in step 2, and
     do not report it as a problem.
   - A new board: resolve the template first (D.6).
4. **Already linked?** For an existing board, `board.read` `linked`.
5. **Status field.** For an existing board, `board.read` `status` now; for a new one, after it is
   created (§E). `unavailable` (no single-select field named `Status`): say so and ask step 3
   again, so the operator can pick another board or `No board`.
6. **Template** (new board only). Read the Cuevik template's `owner`, `number`, `title` and `url`
   from `${CLAUDE_PLUGIN_ROOT}/references/board-template.json`; never write them from memory. Ask
   `How should the new board start?` with these options, in this order:

   | Label | Description |
   | --- | --- |
   | `Cuevik template (Recommended)` | `Copies <title>: fields, views and workflows ready to use.` |
   | `Your template` | `Copies a board you choose; you pick or paste its link next.` |
   | `Blank board` | `An empty board with only Todo, In Progress and Done.` |

   - **Your template:** ask in plain chat, not with `AskUserQuestion` (runner, Asking The
     Operator, typed values): `Paste the link to your template board.` Offer no options or list;
     the operator's next message is the answer. Accept
     `https://github.com/users/<owner>/projects/<number>`, the `orgs/` form, or `<owner>/<number>`.
     Anything else: say what form is expected and ask again.
   - **Check** the chosen template can be read: `board.read` `template`. Exit 0: the new board is a
     copy of it (§E.1), with its fields, views and workflows. `unavailable`: say so and why, then
     ask the first question again.
   - **Blank board:** confirm with `Yes` / `No` that a board with only GitHub's default Status
     options and no custom fields or views is wanted. Never pick for the operator.

## E. Remote changes

List every change below that applies in the runner §2 plan, with its exact command. Run them,
once approved there, in this order. A board operation (the adapter) never stops bootstrap: note
its result for §F and the PR body (`degraded` with its part, or `unavailable`) and go on. Any other
failure **STOPS**.

1. **Create the board** (if chosen): `board.create`, then `board.read` `status` on the new board
   (D.5). `unavailable`: report why. The state is `none`: skip §E.2, §E.5 and the board lines of
   §E.4.
2. **Link the board** (unless already linked): `board.link`. `degraded` (part `link`): show the
   error and go on.
3. **Auto-delete head branches** (unless
   `gh repo view <repo> --json deleteBranchOnMerge --jq .deleteBranchOnMerge` is already `true`):
   `gh repo edit <repo> --delete-branch-on-merge`.
4. **Initiation issues.** They show initiation's progress, on the board when there is one: one
   epic, plus one story per step in `steps.yml` without `bootstrap: true`, in order (this step has
   none: it runs before the issues exist). They carry only the `initiation` label, never `epic` or
   `story`, which belong to the real backlog. This is one change in the §2 plan; list every title
   there. The issues are filed whatever the board state.
   - Label, unless `gh label list --search initiation --json name --jq '.[].name'` prints
     `initiation`: `gh label create initiation --color 0E8A16 --description "cuevik-start initiation tracking"`.
   - Existing: `gh issue list --label initiation --state all --limit 100 --json number,title,state,url`.
     Reuse an open issue whose title matches exactly; create only the missing ones. A matching
     issue that is closed: say so and ask whether to reopen it (`gh issue reopen <n>`) or stop.
   - Epic, title `Epic: Project Initiation`:
     `gh issue create --label initiation --assignee @me --title "Epic: Project Initiation" --body "<body>"`. Body: `Tracks
     project initiation with /cuevik-start. Each sub-issue closes when its step's PR merges into
     main; the last step's PR closes this epic.` It prints the issue URL; the number is its last
     path segment.
   - One story per step, title `INIT-<NN>: <title>` (`<NN>` is the id's two-digit prefix,
     `<title>` the step's `title`), e.g. `INIT-01: Product Concept`. Body: `Run
     /cuevik-start:<id> in a new session. Writes <primary output>. Closes when the <branch> PR
     merges into main.` Create it the same way, with `--assignee @me`.
   - Assignee: every initiation issue is assigned to the signed-in user who runs bootstrap
     (`@me`). A reused issue without that assignee: `gh issue edit <n> --add-assignee @me`.
   - Sub-issues: link each story to the epic, unless
     `gh api repos/<repo>/issues/<epic>/sub_issues --jq '.[].number'` already lists it:
     `gh api -X POST repos/<repo>/issues/<epic>/sub_issues -F sub_issue_id=<id>`, where `<id>` is
     `gh api repos/<repo>/issues/<story> --jq .id` (the REST id, not the number).
   - Board (only when a board is recorded): `board.addItem` for the epic and each story. Do not set
     Status. `degraded`: part `items`.
   - Fields (same condition): `board.setField` for these values. `Priority` and `Size` on each
     story's item from the step's `storyPriority` and `storySize` in `steps.yml`, and `Priority`
     `High` on the epic. `Item Type` `Epic` on the epic and `Story` on each story (a custom field:
     GitHub reserves the name `Type` for organisation Issue Types). A board without the field, or
     without that option: skip it and say so in the PR body. Never create fields or options. A set
     that fails on a field the board has: part `fields`.
   - Efforts: `board.setField` the `Efforts` number field on each story's item to the step's
     `storyEfforts` (hours). Leave the epic's empty: the board sums its stories. No `Efforts`
     field: skip, as above.
   - Sprint: the adapter's `Sprint` procedure (`board.setField`), then the epic and every story go
     in `Sprint-00` when it was created. No `Sprint` iteration field: skip and say so in the PR
     body.

   Report the epic and story numbers; §F writes them to `.cuevik/config.json`.
5. **Board workflows** (only when a board is recorded): `board.workflows`. All seven are required
   on a board created in §E.1; on an existing board only `Item closed`. Its result `degraded`
   (part `workflows`) when the operator picks `Skip workflows`; `Stop bootstrap` is the operator's
   own choice, so **STOP** and report what is on and what is not.

Report each result. If a change that is not a board operation fails, **STOP** and report what was
done and what was not. A re-run finds the board in the list, sees the link, skips the setting and
reuses the `initiation` issues by title, so nothing is created twice.

## F. Outputs (on `init/00-bootstrap`)

Write exactly these files (`steps.yml` `outputs`), nothing else:

- **`CONTRIBUTING.md`** — from `${CLAUDE_PLUGIN_ROOT}/references/contributing-governance.md`, the
  text between `<!-- BEGIN CONTENT -->` and `<!-- END CONTENT -->`, verbatim.
  - New mode: that text is the whole file.
  - Insert mode: keep the existing file verbatim. Insert the text, without its `# Contributing`
    line, after the existing file's first `#` heading line (at the top if it has none). Show the
    diff and wait for approval.
- **`.cuevik/config.json`** — from the values read in §D and §E, never typed or guessed:

  ```json
  {
    "schemaVersion": 3,
    "boardState": "<configured | partial | none>",
    "missing": ["<link | items | fields | workflows>"],
    "project": {
      "owner": "<board-owner>",
      "number": <number>,
      "id": "<board.read id>",
      "statusField": {
        "id": "<Status field id from §D.5>",
        "options": { "<option name>": "<option id>" }
      }
    },
    "initiation": {
      "epic": <epic number from §E.4>,
      "stories": { "<step id>": <story number from §E.4> }
    }
  }
  ```

  `boardState` comes from the board results of §D and §E, never from a guess:
  - no board recorded (`No board`, the probe or `board.create` `unavailable`, or no usable
    `Status` field): `none`. Write neither `project` nor `missing`.
  - a board recorded and no `degraded` result: `configured`. Write `project`, not `missing`.
  - a board recorded and at least one `degraded` result: `partial`. Write `project`, and `missing`
    with each degraded part once (`link`, `items`, `fields`, `workflows`).

  `options` holds every option from §D.5, as read. `stories` has one entry per story from §E.4,
  keyed by step id. `initiation` is always written: the issues are filed whatever the state. No
  `$schema` key. It must satisfy
  `${CLAUDE_PLUGIN_ROOT}/references/contracts/config/config.schema.json`: re-read the file and check
  each rule there before committing.
- **`.cuevik/lineage.json`** — a byte-for-byte copy of
  `${CLAUDE_PLUGIN_ROOT}/references/contracts/lineage/lineage.example.json` (copy the file; do not
  retype it).
- **`.markdownlint.json`** — unless §C.6 kept the repo's own:

  ```json
  {
    "default": true,
    "MD013": false,
    "MD024": { "siblings_only": true }
  }
  ```

Do not add stack-specific commands to `CONTRIBUTING.md`; `04-tech-stack` appends them. Never copy
the runner, `steps.yml`, templates, roles or contracts into the repo.

## Express profile

`/cuevik-start:express` drives §A, §B, §C, §E.3, §E.4 and §F. It skips §D, §E.1, §E.2 and §E.5 and
the board bullets of §E.4: the lane has no board, so the state is `none` without a question. In §F
it writes `CONTRIBUTING.md` with the Express variant of the initiation-only block
(`contributing-governance.md`, "Express variant") and `.cuevik/config.json` with `boardState`
`none`. The branch, the commit and the PR (§G) belong to the lane, not to this step. The reviewer
checklist applies with one change: its first line accepts the Express variant of the block.

## G. PR

Follow runner §5–§6. The PR body covers the `prSummary`:

- Repo: connected or created (owner, name, visibility), and any first commit from B.4.
- Board: the `boardState` recorded. For `configured` or `partial`: owner, number, URL; existing,
  copied from the template (with any differences), or blank; linked now or already linked. For
  `partial`: each `missing` part and why. For `none`: why (the operator chose no board, or the
  adapter's reason). `none` and `partial` end with: `Add or repair the board through a PR on
  .cuevik/config.json (config contract README, "Adding or repairing a board"). 07 and status remind
  you.`
- Repo settings changed: auto-delete head branches.
- Initiation issues: the epic and each story, by number, created now or reused; assignee. With a
  board: the Item Type, Priority, Size and Efforts set, and Sprint-00 created and used (or each
  skipped, with why).
- Board workflows (with a board): which of the seven (§E.5) are on, and that `Auto-add to project`
  filters this repo with `is:issue,pr is:open label:bug`.
- `CONTRIBUTING.md` new or insert mode; `.markdownlint.json` written or kept.
- The reviewer checklist below, and the self-review gate from `CONTRIBUTING.md`.

## Reviewer checklist

- [ ] `CONTRIBUTING.md` holds the governance layer verbatim, with both `INITIATION-ONLY` markers.
      In insert mode, the existing text is unchanged.
- [ ] No stack-specific commands in `CONTRIBUTING.md`.
- [ ] `.cuevik/config.json` has `schemaVersion` 3 and a `boardState` that matches what happened:
      `none` has neither `project` nor `missing`; `configured` has `project` and no `missing`;
      `partial` has `project` and a non-empty `missing`. The PR body says why for `none` and
      `partial`.
- [ ] With a board recorded, `project` names the board that is linked to this repo (unless
      `missing` lists `link`), and its ids were read from GitHub.
- [ ] `.cuevik/lineage.json` matches the plugin's default lineage.
- [ ] `.cuevik/config.json` `initiation` matches the `initiation`-labelled issues: the epic and one
      story per step after 00, each a sub-issue of the epic, and on the board when there is one
      (unless `missing` lists `items`). No `epic` or `story` label on any of them.
- [ ] `gh repo view --json deleteBranchOnMerge` returns `true`.
- [ ] With a board recorded, its required workflows (§E.5) are on, or `missing` lists `workflows`;
      `Auto-add to project` names this repo.
- [ ] No plugin machinery (runner, registry, templates, roles, contracts) is in the diff.
