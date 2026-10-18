---
name: 00-bootstrap
description: Step 00 of cuevik-start. Run first, in the project folder. Connects or creates the GitHub repo and project board, files the initiation epic and stories on the board, turns on auto-delete head branches, and opens a PR adding the CONTRIBUTING.md governance layer, .cuevik/config.json, .cuevik/lineage.json and .markdownlint.json.
disable-model-invocation: true
---

# 00-bootstrap

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `00-bootstrap` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch, outputs,
   commit message, PR summary, special preconditions and actions.
3. This file — what is specific to bootstrap.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 00-bootstrap.` On conflict, precedence is runner > `steps.yml` > this file, except
where the runner defers to this file (runner §0 and §1 for `bootstrap: true`).

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
4. **Board** (§D). Questions and reads only.
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
   bootstrap changes a repo setting and links a board.
3. `git show main:.cuevik/config.json` and `git show main:.cuevik/lineage.json` both non-zero, or
   **STOP**: `This repo is already bootstrapped.` Change the board through a PR that edits
   `.cuevik/config.json`.
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

1. **Owner.** Ask: `Use <repo owner> as the board owner? (yes, or name another user or
   organisation)`. A board can belong to a different owner than the repo.
2. **Projects probe.** `gh project list --owner <board-owner> --limit 1`. Non-zero: **STOP** —
   `gh cannot read Projects for <board-owner>. In a local session, run gh auth refresh -s project.
   Cloud sessions cannot reach Projects v2.`
3. **Pick or create.** List the open boards:
   `gh project list --owner <board-owner> --format json --jq '.projects[] | {number, title}'`.
   Ask which number to use, or whether to create a new board (suggest the repo name as title).
   For a new board, resolve the template first (D.6).
4. **Already linked?** For an existing board:

   ```sh
   gh api graphql -f owner=<repo-owner> -f name=<repo-name> -f query='
     query($owner:String!,$name:String!){repository(owner:$owner,name:$name){
       projectsV2(first:50){nodes{number owner{... on User{login} ... on Organization{login}}}}}}' \
     --jq '.data.repository.projectsV2.nodes'
   ```

   Linked when a node has the board's number and owner.
5. **Status field.** For an existing board, check now; for a new one, after it is created (§E):

   ```sh
   gh project field-list <number> --owner <board-owner> --format json \
     --jq '.fields[] | select(.name=="Status") | {id, type, options: (.options | map({(.name): .id}) | add)}'
   ```

   No output, or a `type` other than `ProjectV2SingleSelectField`: **STOP** — the board needs a
   single-select field named `Status`.
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
   - **Check** the chosen template can be read:
     `gh project view <template-number> --owner <template-owner> --format json --jq .title`.
     Exit 0: the new board is a copy of it (§E.1), with its fields, views and workflows.
     Non-zero: say so and why, then ask the first question again.
   - **Blank board:** confirm with `Yes` / `No` that a board with only GitHub's default Status
     options and no custom fields or views is wanted. Never pick for the operator.

## E. Remote changes

List every change below that applies in the runner §2 plan, with its exact command. Run them,
once approved there, in this order:

1. **Create the board** (if chosen):
   - From the template (D.6):
     `gh project copy <template-number> --source-owner <template-owner> --target-owner <board-owner> --title "<title>" --format json --jq .number`.
     Draft issues are not copied. Then compare the copy with the template. Run this once with the
     template (`> template.txt`) and once with the new board (`> board.txt`), writing both files in
     a temporary folder outside the repo. It prints one line per value, so `diff` output is
     readable. Use `gh`'s built-in `--jq`; do not assume a separate `jq` is installed.

     ```sh
     gh api graphql -f o=<owner> -F n=<number> -f query='
       query($o:String!,$n:Int!){repositoryOwner(login:$o){... on ProjectV2Owner{projectV2(number:$n){
         fields(first:50){nodes{... on ProjectV2FieldCommon{name dataType}
           ... on ProjectV2SingleSelectField{options{name}}
           ... on ProjectV2IterationField{configuration{duration startDay}}}}
         views(first:20){nodes{name layout filter
           fields(first:50){nodes{... on ProjectV2FieldCommon{name}}}
           groupByFields(first:5){nodes{... on ProjectV2FieldCommon{name}}}
           verticalGroupByFields(first:5){nodes{... on ProjectV2FieldCommon{name}}}
           sortByFields(first:5){nodes{direction field{... on ProjectV2FieldCommon{name}}}}}}
         workflows(first:20){nodes{name enabled}}}}}}' \
       --jq '.data.repositoryOwner.projectV2 | paths(scalars) as $p
             | "\($p | map(tostring) | join(".")) = \(getpath($p))"'
     ```

     Then `diff template.txt board.txt`. Check both files are non-empty first: two empty files
     also give "no differences". Report every difference; do not stop on one. The operator
     decides whether to fix it by hand. Say what the check cannot see: the settings inside each
     workflow (for example which Status "Item closed" sets) are not readable through the API.
   - Blank (operator chose it in D.6):
     `gh project create --owner <board-owner> --title "<title>" --format json --jq .number`.

   Then run D.5 on the new board.
2. **Link the board** (unless already linked), from the repo folder so it links this repo:
   `gh project link <number> --owner <board-owner>`. It prints nothing on success, so re-run the
   D.4 query and confirm the board now appears. A user-owned board linked to an
   organisation-owned repo is untested. If the link fails, **STOP** and show the error; do not
   retry with another owner.
3. **Auto-delete head branches** (unless
   `gh repo view <repo> --json deleteBranchOnMerge --jq .deleteBranchOnMerge` is already `true`):
   `gh repo edit <repo> --delete-branch-on-merge`.
4. **Initiation issues.** They show initiation's progress on the board: one epic, plus one story
   per step in `steps.yml` without `bootstrap: true`, in order (this step has none: the board does
   not exist before it). They carry only the `initiation` label, never `epic` or `story`, which
   belong to the real backlog. This is one change in the §2 plan; list every title there.
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
   - Board: `gh project item-add <number> --owner <board-owner> --url <issue url>` for the epic and
     each story, with `--format json --jq .id` to get each item's id. Adding an item that is
     already on the board is harmless and returns the same id. Do not set Status; the board's own
     workflows set it when an item is added and when its issue closes.
   - Fields: set `Priority` and `Size` on each story's item from the step's `storyPriority` and
     `storySize` in `steps.yml`, and `Priority` `High` on the epic. Set `Item Type` to `Epic` on the
     epic and `Story` on each story (a custom field: GitHub reserves the name `Type` for
     organisation Issue Types). Look the fields up by name
     (runner §7, Field lookup), then
     `gh project item-edit --id <item id> --project-id <project id> --field-id <field id> --single-select-option-id <option id>`.
     A board without the field, or without that option: skip it and say so in the PR body. Never
     create fields or options.
   - Efforts: set the `Efforts` number field on each story's item to the step's `storyEfforts`
     (hours): `gh project item-edit ... --field-id <field id> --number <hours>`. Leave the epic's
     empty: the board sums its stories. No `Efforts` field: skip, as above.
   - Sprint: only on a board whose `Sprint` iteration field has **no sprints at all** (current,
     upcoming or completed). Read them:

     ```sh
     gh api graphql -f o=<board-owner> -F n=<number> -f query='
       query($o:String!,$n:Int!){repositoryOwner(login:$o){... on ProjectV2Owner{projectV2(number:$n){
         field(name:"Sprint"){... on ProjectV2IterationField{id configuration{duration
           iterations{id title} completedIterations{id title}}}}}}}}' \
       --jq '.data.repositoryOwner.projectV2.field'
     ```

     - Both lists empty: create `Sprint-00`, starting today, for the field's `duration` in days.
       This call **replaces the field's whole sprint list**, which is why it runs only when the
       list is empty:

       ```sh
       gh api graphql -f fid=<field id> -f d=<YYYY-MM-DD> -F len=<duration> -f query='
         mutation($fid:ID!,$d:Date!,$len:Int!){updateProjectV2Field(input:{fieldId:$fid,
           iterationConfiguration:{startDate:$d,duration:$len,iterations:[{title:"Sprint-00",
           startDate:$d,duration:$len}]}}){projectV2Field{... on ProjectV2IterationField{
           configuration{iterations{id title}}}}}}'
       ```

       Then put the epic and every story in it:
       `gh project item-edit ... --field-id <field id> --iteration-id <Sprint-00 id>`.
     - Any sprint already there: create none and leave the items' Sprint empty. Later sprints
       follow the same name format: `Sprint-01`, `Sprint-02`, ….
     - No `Sprint` iteration field: skip and say so in the PR body.

   Report the epic and story numbers; §F writes them to `.cuevik/config.json`.
5. **Board workflows.** The initiation cards move only through the board's own workflows. These
   seven must be on:

   | Workflow | Note |
   | --- | --- |
   | `Auto-add sub-issues to project` | |
   | `Auto-add to project` | A template copy never has it on: it needs this repo in its filter |
   | `Auto-close issue` | |
   | `Item added to project` | |
   | `Item closed` | |
   | `Pull request linked to issue` | |
   | `Pull request merged` | |

   Read them (a workflow that was never set up is not listed; treat it as off):

   ```sh
   gh api graphql -f o=<board-owner> -F n=<number> -f query='
     query($o:String!,$n:Int!){repositoryOwner(login:$o){... on ProjectV2Owner{projectV2(number:$n){
       workflows(first:50){nodes{name enabled}}}}}}' \
     --jq '.data.repositoryOwner.projectV2.workflows.nodes[] | "\(.enabled) \(.name)"'
   ```

   No API turns a workflow on or changes its settings, so guide the operator through each one
   that is off. Open `https://github.com/users/<board-owner>/projects/<number>/workflows`
   (`orgs/` instead of `users/` for an organisation), then for each workflow:
   - Click it in the left list, click **Edit**, switch it **On**, click **Save and turn on**.
   - `Auto-add to project` also needs its filter: in **Filters**, pick the repository
     `<repo-name>` and set the filter text to `is:issue,pr is:open label:bug`.

   Ask with options `Done, check again` and `Stop bootstrap`. On `Done`, re-read and repeat until
   all seven are on. On `Stop`, **STOP** and report what is on and what is not.
   - A board created in §E.1: all seven are required.
   - An existing board: only `Item closed` is required. List the others that are off and offer
     the same steps; the operator may decline, and the PR body says which are off.

   The API shows only whether a workflow is on, not its settings, and cannot change them. The
   runner relies on these Status values (runner §7), so show this table and ask the operator to
   check each one on the board's Workflows page (click it, **Edit**, set the Status, **Save**):

   | Workflow | Must set Status to |
   | --- | --- |
   | `Item added to project` | `Backlog` |
   | `Pull request linked to issue` | `Reviewing` |
   | `Item closed` | `Done` |
   | `Pull request merged` | `Done` |

   Then ask `Are these four set, and Auto-add to project filtered to <repo-name>?` with `Yes` /
   `No, stop`. A board without one of these Status options: say which, and that its cards will
   not move to it. Record the answer in the PR body.

Report each result. If one fails, **STOP** and report what was done and what was not. A re-run
finds the board in the list, sees the link, skips the setting and reuses the `initiation` issues by
title, so nothing is created twice.

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
    "schemaVersion": 2,
    "project": {
      "owner": "<board-owner>",
      "number": <number>,
      "id": "<gh project view <number> --owner <board-owner> --format json --jq .id>",
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

  `options` holds every option from §D.5, as read. `stories` has one entry per story from §E.4,
  keyed by step id. No `$schema` key. It must satisfy
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

## G. PR

Follow runner §5–§6. The PR body covers the `prSummary`:

- Repo: connected or created (owner, name, visibility), and any first commit from B.4.
- Board: owner, number, URL; existing, copied from the template (with any differences), or blank;
  linked now or already linked.
- Repo settings changed: auto-delete head branches.
- Initiation issues: the epic and each story, by number, created now or reused; assignee, and the
  Item Type, Priority, Size and Efforts set, and Sprint-00 created and used (or each skipped, with
  why).
- Board workflows: which of the seven (§E.5) are on, and that `Auto-add to project` filters this
  repo with `is:issue,pr is:open label:bug`.
- `CONTRIBUTING.md` new or insert mode; `.markdownlint.json` written or kept.
- The reviewer checklist below, and the self-review gate from `CONTRIBUTING.md`.

## Reviewer checklist

- [ ] `CONTRIBUTING.md` holds the governance layer verbatim, with both `INITIATION-ONLY` markers.
      In insert mode, the existing text is unchanged.
- [ ] No stack-specific commands in `CONTRIBUTING.md`.
- [ ] `.cuevik/config.json` names the board that is linked to this repo, and its ids were read
      from GitHub.
- [ ] `.cuevik/lineage.json` matches the plugin's default lineage.
- [ ] `.cuevik/config.json` `initiation` matches the `initiation`-labelled issues: the epic and one
      story per step after 00, each a sub-issue of the epic and on the board. No `epic` or `story`
      label on any of them.
- [ ] `gh repo view --json deleteBranchOnMerge` returns `true`.
- [ ] The board's seven workflows (§E.5) are on; `Auto-add to project` names this repo.
- [ ] No plugin machinery (runner, registry, templates, roles, contracts) is in the diff.
