---
name: 00-bootstrap
description: Step 00 of cuevik-start. Run first, in the project folder. Connects or creates the GitHub repo and project board, turns on auto-delete head branches, and opens a PR adding the CONTRIBUTING.md governance layer, .cuevik/config.json, .cuevik/lineage.json and .markdownlint.json.
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
use a value the operator has not given or confirmed.

## Order

Bootstrap runs before the folder is necessarily a repo, so its order differs from other steps:

1. **Auth** (§A).
2. **Repo** (§B). Repo creates are confirmed and run here, because every later check needs `main`
   on GitHub.
3. **Runner §1 checks 1, 2 and 7** — check 7 is the `steps.yml` special precondition plus §C.
4. **Board** (§D). Questions and reads only.
5. **Runner §2 checklist**, plus the remote changes from §E. Confirm each change on its own.
6. **Remote changes** (§E).
7. **Runner §3** — branch `init/00-bootstrap`.
8. **Outputs** (§F).
9. **Runner §5–§6** — commit, push on approval, PR (§G).

## A. Auth

1. `gh auth status`. Non-zero: **STOP** — `gh is not signed in. Run gh auth login, then re-run.`
2. The Projects probe runs in §D once the board owner is known, and the admin check in §C once the
   repo is known. Do not rely on the `X-OAuth-Scopes` header: fine-grained tokens do not send it.

## B. Repo

Detect the folder's state with:

- `git rev-parse --show-prefix` — non-zero: not a repo. Non-empty output: the folder is a
  subfolder of another repo — **STOP** and say so. (Do not compare `--show-toplevel` with the
  current path: on Windows the two use different path forms.)
- `git remote get-url origin` — the remote, if any.
- `ls -A` — empty output: empty folder.

| State | Action |
| --- | --- |
| Repo, `origin` on `github.com` | `gh repo view --json nameWithOwner,isEmpty`. Ask the operator to confirm it is the project repo. `isEmpty` true: B.4. |
| Repo, `origin` not on `github.com` | **STOP** — GitHub only. |
| Repo, no `origin` | Ask owner and name (B.1). Existing: connect it (B.2). Missing: create it (B.3). |
| Not a repo, empty folder | Ask owner and name (B.1). Existing: confirm, then `gh repo clone <owner>/<name> .` (an empty repo then needs B.4). Missing: `git init -b main`, then create it (B.3). |
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

**B.3 Create a missing repo.** Ask the visibility (`private` or `public`; suggest `private`).
The current branch (`git branch --show-current`) must be `main`, or **STOP**. Run B.4 if there is
no commit yet. Show the command, wait for `yes`, then:
`gh repo create <owner>/<name> --<visibility> --source . --remote origin --push`.

**B.4 Empty `main` on GitHub.** The GitHub repo is new (B.3) or empty (`isEmpty` true), so `main`
must be pushed before anything else.

- Local `main` has no commit (`git rev-parse --verify -q main` non-zero): run
  `git commit --allow-empty -m "chore: initialize repository"` on `main`. This is the only commit
  bootstrap makes on `main`; it holds no files.
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
4. `gh pr list --head init/00-bootstrap --state open --json url` returns nothing, or **STOP** and
   show the open PR.
5. `git show main:CONTRIBUTING.md`:
   - Non-zero: **new** mode — write the whole file.
   - Contains `<!-- BEGIN INITIATION-ONLY -->`: **STOP** — the governance layer is already there.
   - Otherwise: **insert** mode (§F).
6. `git show main:.markdownlint.json` exit 0: keep the repo's file. Do not write or commit it, and
   say so in the PR.

## D. Board (questions and reads only)

1. **Owner.** Ask: board owner is `<repo owner>`, or another user or organisation? A board can
   belong to a different owner than the repo.
2. **Projects probe.** `gh project list --owner <board-owner> --limit 1`. Non-zero: **STOP** —
   `gh cannot read Projects for <board-owner>. In a local session, run gh auth refresh -s project.
   Cloud sessions cannot reach Projects v2.`
3. **Pick or create.** List the open boards:
   `gh project list --owner <board-owner> --format json --jq '.projects[] | {number, title}'`.
   Ask which number to use, or whether to create a new board (suggest the repo name as title).
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

## E. Remote changes

List every change below that applies in the runner §2 checklist, with its exact command. Wait for
`yes` on each one separately, then run them in this order:

1. **Create the board** (if chosen):
   `gh project create --owner <board-owner> --title "<title>" --format json --jq .number`.
2. **Link the board** (unless already linked), from the repo folder so it links this repo:
   `gh project link <number> --owner <board-owner>`. A user-owned board linked to an
   organisation-owned repo is untested. If the link fails, **STOP** and show the error; do not
   retry with another owner.
3. **Auto-delete head branches** (unless
   `gh repo view <repo> --json deleteBranchOnMerge --jq .deleteBranchOnMerge` is already `true`):
   `gh repo edit <repo> --delete-branch-on-merge`.

Report each result. If one fails, **STOP** and report what was done and what was not. A re-run
finds the board in the list, sees the link and skips the setting, so nothing is created twice.

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
    "schemaVersion": 1,
    "project": {
      "owner": "<board-owner>",
      "number": <number>,
      "id": "<gh project view <number> --owner <board-owner> --format json --jq .id>",
      "statusField": {
        "id": "<Status field id from §D.5>",
        "options": { "<option name>": "<option id>" }
      }
    }
  }
  ```

  `options` holds every option from §D.5, as read. No `$schema` key. It must satisfy
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
- Board: owner, number, URL; created or existing; linked now or already linked.
- Repo settings changed: auto-delete head branches.
- `CONTRIBUTING.md` new or insert mode; `.markdownlint.json` written or kept.
- The reviewer checklist below, and the self-review gate from `CONTRIBUTING.md`.

## Reviewer checklist

- [ ] `CONTRIBUTING.md` holds the governance layer verbatim, with both `INITIATION-ONLY` markers.
      In insert mode, the existing text is unchanged.
- [ ] No stack-specific commands in `CONTRIBUTING.md`.
- [ ] `.cuevik/config.json` names the board that is linked to this repo, and its ids were read
      from GitHub.
- [ ] `.cuevik/lineage.json` matches the plugin's default lineage.
- [ ] `gh repo view --json deleteBranchOnMerge` returns `true`.
- [ ] No plugin machinery (runner, registry, templates, roles, contracts) is in the diff.
