---
name: status
description: Shows where project initiation stands. A progress line, then for each cuevik-start step (00–08) whether the step's init/<id> PR is merged, open, only a branch, or not started, read from git and GitHub, with the initiation issues on the board cross-checked, then the next command. Read-only. Run it any time in the project folder; steps 01–08 also run it first.
disable-model-invocation: true
---

# status

A read-only report of cuevik-start step progress. It writes no files, creates and deletes no
branches, changes nothing on GitHub, and asks no questions. The current folder is the project
repo. It takes no arguments. Run every `gh` command through the Bash tool.

Load `${CLAUDE_PLUGIN_ROOT}/references/steps.yml`. Its steps are the rows, in its order. Each
entry supplies `id`, `branch`, `outputs` (the first is the primary output), `bootstrap` and
`replacesExisting`. Never hardcode a step list. If the file fails to load, stop and output:
`Error: steps.yml could not be loaded.`

Run every check silently, then render the report once. Do not print intermediate command output.

## 1. Preflight

Stop at the first failure and output only its message.

1. `git rev-parse --show-prefix`. Non-zero: `This folder is not a git repo. Run
   /cuevik-start:00-bootstrap first.` Non-empty output: `Run status from the repo root.`
2. `git remote get-url origin`. Missing, or not on `github.com`: `No GitHub origin. Run
   /cuevik-start:00-bootstrap first.`
3. `gh auth status`. Non-zero: `gh is not signed in. Run gh auth login, then re-run.`
4. `git fetch --prune origin`. This updates only remote-tracking refs, and drops the ones whose
   branches GitHub deleted. Non-zero: `Could not fetch origin. Status needs GitHub's current
   state.` Never check out, pull, or change a local branch.
5. `git rev-parse --verify -q origin/main`. Non-zero: `origin has no main branch. Run
   /cuevik-start:00-bootstrap first.` Otherwise its output is `<sha>`.

Every file check below reads `<sha>`, the commit `origin/main` points at, not local `main`, which
can be behind GitHub when status runs on its own. When a step's runner follows this file (runner
§0), `main` has just been pulled, so the two are the same. Always write `<sha>:<path>`, never
`origin/main:<path>`: Git Bash on Windows rewrites an argument shaped like `origin/main:.cuevik/x`
into a Windows path list, and the check then fails on a file that exists.

## 2. Per step

Read the branches once:

- On GitHub: `git ls-remote --heads origin`. Keep lines whose ref starts with `refs/heads/init/`.
- Local: `git for-each-ref --format='%(refname:short)' refs/heads/init/`.

Then, for each step:

1. **PR.** `gh pr list --head <branch> --base main --state all --json number,state,title,url`.
   This is the same query runner §1 check 4 uses to gate the next step. Take the newest `MERGED`
   PR if there is one, else the `OPEN` one, else the newest `CLOSED` one, else none.
2. **File check** on `<sha>`. `git cat-file -e <sha>:<path>` exit 0 means the file is there.

   | Step | Passes when |
   | --- | --- |
   | `bootstrap: true` | `.cuevik/config.json` and `.cuevik/lineage.json` are both there (runner §1 check 3) |
   | `08-finalize` | `CONTRIBUTING.md` is there and `git show <sha>:CONTRIBUTING.md` has no `INITIATION-ONLY` text |
   | any other `replacesExisting: true` step | no file check: its output is on `main` before it runs |
   | every other step | the primary output is there |

3. **Status.** The first matching row wins:

   | Condition | Status | Detail |
   | --- | --- | --- |
   | merged PR, file check passes or none | `✓ merged` | `PR #n` |
   | merged PR, file check fails | `⚠ mismatch` | `PR #n merged, but <what failed> on origin/main` |
   | no merged PR, file check passes | `⚠ mismatch` | `<output> on origin/main without a merged <branch> PR; the next step's gate will refuse` |
   | open PR | `⟳ PR open` | `PR #n — "<title>"` |
   | branch local or on GitHub | `⊙ branch` | `local`, `GitHub` or `local + GitHub`, plus `closed PR #n` if there is one |
   | none of the above | `— not started` | |

   On a `✓ merged` row whose branch still exists, append `local branch left —
   /cuevik-start:cleanup` (local) or `branch left on GitHub` (GitHub).

## 3. Initiation issues

The board mirrors the steps through the issues `00-bootstrap` filed. The merged PR stays the
source of truth: this section never changes a row's Status or the Next line; it only adds
`**Check:**` lines where GitHub's issues disagree with the rows.

1. `git show <sha>:.cuevik/config.json`. Non-zero (not bootstrapped yet): skip this section
   silently. No `initiation` key: one Check line, `.cuevik/config.json has no initiation issues,
   so the board does not track initiation.`, then skip the rest.
2. `gh issue list --label initiation --state all --limit 100 --json number,state`, once.
3. For each step in `initiation.stories`, with story `#n`:

   | Condition | Check line |
   | --- | --- |
   | `#n` not in the list | `story #n (<id>) is not an initiation issue on GitHub (deleted, transferred or relabelled)` |
   | `#n` closed, row not `✓ merged` | `story #n (<id>) is closed, but <id> has no merged PR` |
   | `#n` open, row `✓ merged` | `story #n (<id>) is still open, though PR #m merged` |

   A step without `bootstrap: true` that has no entry in `initiation.stories`: `no story for <id>
   in .cuevik/config.json`.
4. The epic `initiation.epic`: not in the list, closed while any row is not `✓ merged`, or open
   while every row is `✓ merged` — one Check line saying which.

## 4. Report

```markdown
## Initiation status — <owner>/<repo> (origin/main @ <short sha>)

`█░░░░░░░░ 1/9 · next: 01-product-concept`

| Step | Output | Status | Detail |
| --- | --- | --- | --- |
| 00-bootstrap | CONTRIBUTING.md, .cuevik/ | ✓ merged | PR #1 |
| 01-product-concept | docs/PRODUCT.md | ⟳ PR open | PR #4 — "docs: add PRODUCT.md (01-product-concept)" |
| 02-product-requirements | docs/PRD.md | — not started | |

**Next:** merge PR #4 (01-product-concept). /cuevik-start:02-product-requirements refuses to run until then.
```

- Repo: `gh repo view --json nameWithOwner --jq .nameWithOwner`. Sha: `git rev-parse --short
  origin/main`.
- Output: the primary output. A `bootstrap: true` step also lists `.cuevik/`.
- Progress line, in a code span: one cell per row in `steps.yml` order, `█` for `✓ merged` and
  `░` for any other status; then `<merged>/<rows>`; then `· next: <id>`, the row the Next line
  is decided by. Every row `✓ merged`: `· complete`.

After the table, print one `**Check:**` line for each `⚠ mismatch` row, for each `✓ merged`
row that comes after a step that is not merged (steps ran out of order), and for each issue
disagreement from §3. Then print one
`**Next:**` line. It is decided by the first row in `steps.yml` order that is not `✓ merged`:

- `⚠ mismatch`: `blocked — <id> does not add up (see Check).`
- `⟳ PR open`: `merge PR #n (<id>). /cuevik-start:<next id> refuses to run until then.` If it is
  the last step: `merge PR #n (<id>); initiation is then complete.`
- `⊙ branch`: `/cuevik-start:<id> in a new session. Branch <branch> exists; the runner asks
  whether to reuse or delete it.`
- `— not started`: `/cuevik-start:<id> in a new session.` For `08-finalize`, add `It strips the
  INITIATION-ONLY block from CONTRIBUTING.md; the last step.`
- Every row `✓ merged`: `Initiation complete. Run /cuevik-start:cleanup to delete merged local
  init/* branches. Revise a document with /cuevik-docs:update <document>.`

## Nothing else

Do not suggest fixes, ask questions, or offer to run any command. When a step's runner follows
this file, render the report, then return to the runner; the step continues from there.
