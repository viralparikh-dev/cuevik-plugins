# Decisions (temporary)

> **Temporary working log.** Delete this file, or shrink it to a short summary in `README.md`,
> once the plugins are built. Keep only what a future maintainer needs.

Status key: **Locked** = decided · **Proposed** = recommended, awaiting approval · **Open** = needs an answer

---

## 1. Marketplace and plugins — Locked

| Item | Value |
|---|---|
| GitHub repo | `viralparikh-dev/cuevik-plugins` (renamed 2026-10-17; local folder stays `vrp-cuevik-plugins`) |
| Marketplace `name` | `cuevik-plugins` |
| Plugins | `cuevik-start` (Cuevik Start), `cuevik-ship` (Cuevik Ship), `cuevik-docs` (Cuevik Docs) |
| Dependencies | `cuevik-start` and `cuevik-ship` both declare `"dependencies": ["cuevik-docs"]` |
| Out of scope | `cuevikflow` (product-specific, separate repo), `db-migrate` (Supabase-specific), kickstart `audit` (kit self-check) |
| Component type | `skills/` (preferred over `commands/` for new plugins) |

Install:

```text
/plugin marketplace add viralparikh-dev/cuevik-plugins
/plugin install cuevik-start@cuevik-plugins
/plugin install cuevik-ship@cuevik-plugins
```

Note: the repo is **private** — only accounts with read access can add the marketplace.

| Build | Value |
|---|---|
| Plan | [BUILD-PLAN.md](BUILD-PLAN.md) — one phase per session, one PR per phase |
| Test targets | `viralparikh-dev/cuevik-sandbox` (private, created 2026-10-17) every phase; `tx-QE4AIApps` once, after all phases |
| Shared contracts | separate files: `.cuevik/config.json` (settings) and `.cuevik/lineage.json` (doc lineage) |

## 2. Command names

Two-digit numbered steps; utilities unnumbered.

**cuevik-start — Locked**

`00-bootstrap` · `01-product-concept` · `02-product-requirements` · `03-architecture` ·
`04-tech-stack` · `05-ai-tool-guide` · `06-readme` · `07-backlog` · `08-finalize` · `status` · `cleanup`

**cuevik-docs — Locked**

`audit` (was `/doc-audit`) · `update` (was `/proj-init-doc-update`)

**cuevik-ship — Locked**

`01-brainstorm` · `02-audit-prd` · `03-create-backlog` (epic and stories) · `04-plan-intent` ·
`05-design-spec` · `06-build-plan` · `07-execute-plan` · `cleanup`

## 3. cuevik-start behaviour — Locked

- Runs **inside the project repo**; the current folder is the target (`00-bootstrap` makes it a
  repo if it is not one yet). No control-plane folder, no `.proj-init/state.json`.
- **`00-bootstrap` requires a GitHub repo and a project board, and creates whichever is missing**
  (decided 2026-10-17). Each create is listed and confirmed first.
  - Repo: if the current folder has no GitHub `origin`, ask for owner, name and visibility. An
    existing repo is connected as `origin`. A missing one is created with
    `gh repo create <owner>/<name> --<visibility> --source . --push` (after `git init` if needed).
  - Board: ask which board, listing `gh project list --owner <owner>`. A missing one is copied
    with `gh project copy` from a template board the skill asks for, default `viralparikh-dev/3`
    (public; decided 2026-10-17), and linked with `gh project link`. Unreadable answer: fall back
    to the default; unreadable default: the operator picks an existing board or a blank one
    (`gh project create`). Its ids are then read back into `.cuevik/config.json` (contract:
    `contracts/config/`).
  - No plugin `userConfig` for the template: in the Phase 03 sandbox test
    `${user_config.board_template}` reached the skill unsubstituted (cause unknown), so the skill
    asks instead.
  - Template `viralparikh-dev/3` is a copy of the team's org template: fields, views and all
    workflows copied identically, except the org's Priority (an org-level field with no options)
    became a Priority field with Urgent/High/Medium/Low. User-owned boards cannot carry GitHub's
    "template" flag; a copy does not need it.
  - Needs the `project` token scope and a local session: cloud sessions cannot reach Projects v2.
  - Unverified: linking a board owned by a user to a repo owned by an organisation (not covered by
    the sandbox or tx-QE4AIApps, both user-owned), and copying the public template as another user.
    The second is tested in the end-of-plan tx-QE4AIApps run.
- Old Step-01 (repo setup / governance / `CONTRIBUTING.md`) is **merged into `00-bootstrap`**;
  steps renumbered 00–08 with no gap.
- Each step opens a PR to `main`; the next step refuses to run until that PR is merged.
- `00-bootstrap` turns on the host's **auto-delete head branches** setting, so every merged PR's
  source branch (`init/*`, ship step branches, code branches) is removed on the remote automatically.
- `cleanup`: deletes **local** `init/*` branches whose PR is merged; skips and reports unmerged
  ones; lists and confirms before deleting. Run any time, typically after `08-finalize` merges.

## 4. cuevik-ship behaviour

**Locked**

- Work folder: `docs/ship/<issue#>-<slug>/`, brainstorming in `docs/ship/<issue#>-<slug>/brainstorming/`.
- `docs/ship/` **never reaches `main`**.
- One separate working copy (git worktree) per issue, so several stories run in parallel.
- `01-brainstorm` takes an idea (creates the GitHub issue first) or an existing issue number (D8).
- `07-execute-plan`'s PR carries only the code / final outcome to `main`.
- Each step's PR must be merged before the next step runs.
- Issue description carries a `## References` section of permalinks to the issue's files, refreshed
  when later steps change earlier files (e.g. `intent.md` edited during spec).
- `## References` = **links only**, no file content.
- An idea that splits into several stories at step 03: each extra story starts its own branch set at
  `04-plan-intent`, linking back to the original issue's brainstorming.

**Locked — the simple model**

One rule: **files under `docs/ship/` go to the issue branch; everything else goes to `main`.**

| Step | Branch it works on | PR target |
|---|---|---|
| 01-brainstorm | `ship/<n>-<slug>/01-brainstorm` | `ship/<n>-<slug>/issue` |
| 02-audit-prd | `ship/<n>-<slug>/02-audit-prd`, branched from `main` (edits `PRODUCT.md` / `PRD.md`) | **`main`** (`Refs #n`, never `Closes`) |
| 03-create-backlog | none (writes to GitHub only) | — |
| 04–06 | `ship/<n>-<slug>/<NN-step>` | `ship/<n>-<slug>/issue` |
| 07-execute-plan | `ship/<n>-<slug>/07-execute-plan`, branched from `main` | **`main`** |

- `ship/<n>-<slug>/issue` is the parent branch. It holds only `docs/ship/<n>-<slug>/`, is created
  by `01-brainstorm` (or by `04-plan-intent` for any issue that has none — bug fix or split story)
  from `main`, and never merges.
- All branches share the `ship/<n>-<slug>/` prefix, so `cleanup` deletes `ship/<n>-<slug>/*`.
  (Git cannot have both `X` and `X/child` as branches, hence `.../issue` rather than a bare `ship/<n>-<slug>`.)
- `02-audit-prd` goes to `main` because `PRD.md` / `PRODUCT.md` are shared by every issue and
  `PRD-NNN` numbers must be allocated in one place.
- `07-execute-plan` branches from `main`, reads `plan.md` from the issue branch, so no `docs/ship/` file
  can leak into the code PR.
- Gate = each command checks the previous step's PR is `MERGED` before doing anything. Solo:
  GitHub does not let you approve your own PR, so the self-review checklist is the approval.
- References block lives between `<!-- cuevik-ship:references -->` markers in the issue body. Every
  command refreshes it after its gate check and when it opens its PR; links point at the latest
  commit on `.../issue` that touched each file.
**Locked — `/cuevik-ship:cleanup <issue#>`**

- **Gate:** `07-execute-plan`'s code PR is merged, **or** the issue is closed as *not planned*
  (rejection is recorded and the issue closed by 01/02, not by cleanup). No `--abandon` flag.
- Runs from the main checkout, never from inside the worktree it removes.
- Removes the issue's worktree (refuses on uncommitted or unpushed changes) — this also removes the
  local `docs/ship/<n>-<slug>/`, since `main` never has it — and local `ship/<n>-<slug>/*` branches.
- **Archives** the remote `.../issue` branch as tag `ship-archive/<n>-<slug>`, then deletes the
  branch. The tag keeps the commits reachable, so References permalinks keep working.
- Remote step/code branches: already gone via auto-delete head branches (§3).
- Does not close the issue (the code PR's `Closes #n` does). Split stories are cleaned per issue.
- Lists everything it will delete and confirms first.

## 5. 01 → 03 behaviour — Locked (from the dry run)

Build input: `docs/DRYRUN-01-03.md` §2–§3 (proposed 01/03 behaviour). Where it disagrees with the
list below, **this list wins** (D2 and D13 override it).

- **D1** `01` files a plain issue labelled `idea`; `03` converts it to a story (title
  `PRD-NNN: <Title> (<Priority>)`, `idea` label removed).
- **D2** `01` first runs the duplicate check (existing `idea` issues in any state, and stories) —
  cheap, no interrogation — so a duplicate never gets a number. Then it creates the issue **at the
  very start**, from the 2–3 sentence description, then the
  `.../issue` branch, worktree and `brainstorming/` folder — so findings can be saved from the first
  minute. Abandoned ideas are closed *not planned* and cleaned up like rejections.
- **D3** Labels only — no GitHub issue types (null on user-owned repos).
- **D4** Ratification record = machine-readable block in 02's PR body + `Docs PR:` line in References.
  The brainstorm file keeps only 01's decision.
- **D5** One word: **story**. Labels `epic`, `story`, `priority:*`, plus the `PRD-NNN:` title prefix,
  shared by `cuevik-start:07-backlog` and `cuevik-ship:03-create-backlog`.
- **D6** Epic lookup: parent of existing stories in the same PRD §6 section → `label:epic` citing the
  section → `docs/BACKLOG.md` → new epic. Several candidates → ask. Never move a parent without a yes.
- **D7** `docs/BACKLOG.md` is frozen after initiation; GitHub is the backlog. `07-backlog` writes a
  header saying so; `cuevik-docs:update` drops "update when epics/stories added".
- **D8** `01` given an existing issue: refuse epics, redirect bugs to 04, allow existing stories (03
  treats as Changed); never closes a pre-existing story.
- **D9** On a split, the original issue keeps the first ID in prerequisite order; overridable in
  03's approval table.
- **D10** `04`'s gate after `03`: References has an `Epic:` line and the issue has no `idea` label.
- **D11** Split stories go under their own PRD section's epic.
- **D12** Rejected at 01: its PR into `.../issue` is the record, close *not planned* on yes. Rejected
  at 02: comment + close, no PR. `cleanup` refuses while any `ship/<n>-*` PR is open.
- **D13** `docs/ship/<n>-<slug>/brainstorming/` holds `brainstorm.md` **plus attachments and any
  other files found during brainstorming**.
- **D14** Ideas may land on the project board at 01; the card carries through when the idea becomes
  the story.
- **D15** Config split: project facts (board number, Status field/option IDs) in committed
  `.cuevik/config.json`, written by `00-bootstrap`; owner/repo read from the git remote; machine
  facts (worktree root) in plugin `userConfig`.
- Unverified: sub-issue and blocked-by REST calls from a cloud session — test when building `03`.

## 6. Step 03 name — Locked

`03-create-backlog` covers both epic and stories. Overlaps in wording with
`/cuevik-start:07-backlog` (which writes `docs/BACKLOG.md`); the descriptions must make clear that
03 writes GitHub issues. Its exact epic/story logic is settled by the dry run (§5).
