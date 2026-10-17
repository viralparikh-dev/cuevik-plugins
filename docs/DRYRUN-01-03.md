# Dry run — cuevik-ship 01 → 03: issue, epic, PBI (temporary)

> **Temporary.** Paper dry run of `/cuevik-ship:01-brainstorm`, `02-audit-prd`, `03-create-backlog`
> against [DECISIONS.md](DECISIONS.md) §4–§6. Delete once the decisions below are folded into
> DECISIONS.md. Nothing here is locked.

Sources read: `DECISIONS.md`; `cs-cueviksync/.claude/commands/work/1-brainstorm.md`, `2-audit-prd.md`,
`3-epic.md`, `4-intent.md` (Phase 1 only); `cs-cueviksync/docs/work/README.md`;
`cs-kickstart/docs/guides/proj-init/08-backlog.md` + `templates/BACKLOG.template.md` + `PRD.template.md`.

Verified with read-only `gh` (2026-10-17):

- `Cueserve/cs-cueviksync` has issue types `Task`, `Bug`, `Feature`; `viralparikh-dev/cuevik-plugins`
  (user-owned) returns `issueTypes: null`. **Issue types are not portable** → anything that must work
  in every repo has to be a label.
- Epics in cs-cueviksync are `label:epic`; PBIs link as sub-issues (`GET issues/41/parent` → #24).
- cuevik-start's backlog step (kickstart 08) labels `epic` / `story` / `priority:*` and writes
  `docs/BACKLOG.md` as the "source of truth for the epics/stories manifest and host item IDs".
  cs-cueviksync's `3-epic` uses `epic` + a module label and puts priority in the title. **Two
  conventions already exist.**

---

## 0. Weakest points (read these first)

1. **The ratification record has nowhere to live.** Old flow: 02 wrote `§9 Ratified as` into the
   idea file and that file reached `main` in the docs PR; old 03 gated on reading it from
   `origin/main`. New rule: `docs/ship/` never reaches `main`, and 02's PR goes to `main`. So 02
   cannot update the brainstorm file without a second PR to `.../issue`, and 03 cannot read it from
   `main`. → Decision 4.
2. **02's branch must be cut from `main`, and the table doesn't say so.** If `02-audit-prd` is cut
   from `.../issue` (the natural thing inside the issue's worktree), its PR to `main` carries
   `docs/ship/` — the exact leak the model forbids. 07 has "branched from `main`"; 02 needs it too.
3. **03 makes `docs/BACKLOG.md` stale.** cuevik-start leaves BACKLOG.md as the epics/stories
   manifest on `main`, and its doc-update map says it changes when "epics or stories added". 03
   "writes to GitHub only" — no branch, no PR. Contradiction. → Decision 7.
4. **03 has no PR, so 04's gate has nothing to check.** "Each step's PR must be merged before the
   next runs" — 04 after 03 has no PR. → Decision 10.
5. **02's PR to `main` must not say `Closes #n`.** Merging it would auto-close the issue that 04–07
   still need. Only 07's PR closes it.
6. **"Read every existing brainstorm" (old Phase 2) breaks.** Brainstorms now live on per-issue
   `.../issue` branches, not on `main`. The index of past ideas becomes the issue list
   (`label:idea`, open + closed). → part of Decision 1.

---

## 1. Scenario table

`n` = the issue 01 works on. `S` = its slug. `W` = its worktree. Branch prefix `ship/<n>-<S>/`.
"PR→issue" = PR into `ship/<n>-<S>/issue`.

| # | Scenario | 01-brainstorm | 02-audit-prd | 03-create-backlog | Ends with | Flags |
|---|---|---|---|---|---|---|
| 1 | New idea, no issue, no epic fits | Interrogate → gate → **create #n** (`idea` label) → `.../issue` from `main` → `W` on `.../01-brainstorm` → PR→issue | Branch from `main`; new §6 section + `PRD-NNN`; PR→`main` (`Refs #n`) | No PBI in that section, no epic → **create epic**; convert #n to PBI under it | #n = PBI, sub-issue of new epic | D1, D2, D4, D6 |
| 2 | New idea, existing epic fits | Same as 1 | `PRD-NNN` lands in an **existing** §6 section | Section's existing PBIs share a parent → **reuse that epic**; convert #n under it | #n = PBI under existing epic | D6 — "fits" is decided by 02's section, not by the user at 01 |
| 3 | Existing issue #n, already under epic E | Read #n; refuse if `epic` label; redirect if `bug`; check no `ship/<n>-*` branch exists (else resume); **no create**; then as 1 | Usually **Changed** `PRD-NNN` (if #n is already a PBI) or New | Section epic == E → keep. ≠ E → **ask**: keep, or move (`replace_parent`). Never move silently | #n stays/moves | D8, D6 |
| 4 | Existing issue #n, no epic | As 3, add `idea` label if #n is not a PBI | As 1/2 | As 1 or 2 by section | #n = PBI under resolved epic | D8 |
| 5 | Splits into 3 PBIs at 03 | As 1 | Ratifies e.g. `PRD-053`, `PRD-054`, `PRD-055` | #n takes one ID (D9); **create #a, #b**; each under its section's epic (may differ — D11); blocked-by links; References updated both ways | #n continues at 04 in `W`; #a, #b have **no branches** until their own `04-plan-intent` | D9, D10, D11 |
| 6a | Rejected at 01 | Status `Rejected`; PR→issue (the record); on yes close #n **not planned**. Pre-existing PBI: **do not close** (D8) | — | — | User merges PR → `cleanup <n>`; remote `.../issue` kept as archive | D12 |
| 6b | Rejected / fully Covered at 02 | — | No PRD change → **no PR to `main`**; on yes comment + close #n not planned (Covered: link covering PBIs) | Refuses: nothing ratified | `cleanup <n>`; brainstorm file still reads `Approved` on archive branch (D4) | D4, D12 |

### Per-scenario walk (only what the table can't hold)

**Scenario 1 — new idea, no epic**

- 01 reads: `PRODUCT.md`, `PRD.md` on `origin/main`; `gh issue list --label idea --state all` and
  PBIs by title for duplicates (replaces the old "read every brainstorm file").
- 01 asks: 2–3 sentences, interrogation batches, the gate, then **the exact issue title/body/labels
  — explicit yes** before `gh issue create`.
- Creation order is forced by naming: **issue → number → slug → branches → worktree → file.**
  1. `gh issue create --title "<idea title>" --label idea --body "<sentences + empty References block>"`
  2. `git branch ship/<n>-<S>/issue origin/main && git push -u origin ship/<n>-<S>/issue`
  3. `git worktree add <W> -b ship/<n>-<S>/01-brainstorm ship/<n>-<S>/issue`
  4. write `docs/ship/<n>-<S>/brainstorming/brainstorm.md` (filename: D13), commit, push
  5. `gh pr create --base ship/<n>-<S>/issue` — Approved or Rejected only; Draft pushes, no PR.
- References at 01 PR-open — the file is not on `.../issue` yet, so "latest commit on `.../issue`"
  has nothing to point at. Proposed: link the PR head commit (stays reachable via `refs/pull/*`);
  02's post-gate refresh re-points it at `.../issue`.

  ```markdown
  ## References
  <!-- cuevik-ship:references -->
  - Brainstorm: [brainstorm.md](https://github.com/<o>/<r>/blob/<pr-head-sha>/docs/ship/<n>-<S>/brainstorming/brainstorm.md) · PR #<p>
  <!-- /cuevik-ship:references -->
  ```

- 02: gate = 01's PR `MERGED` + brainstorm `Status: Approved` (read via
  `git show origin/ship/<n>-<S>/issue:docs/ship/<n>-<S>/brainstorming/brainstorm.md`). Branch
  `ship/<n>-<S>/02-audit-prd` **from `origin/main`**. PR→`main`, body says `Refs #n`, carries a
  machine-readable ratified block (D4). References gains `Docs PR: #<q>`.
- 03 (after the docs PR merges): creates `Epic: <§6 section>`, edits #n into a PBI, sub-issue link,
  board add (local only). References after:

  ```markdown
  - Brainstorm: [brainstorm.md](…/blob/<issue-branch-sha>/docs/ship/<n>-<S>/brainstorming/brainstorm.md)
  - Docs PR: #<q>
  - Epic: #<e>
  ```

- Board: if the project's Auto-add workflow is on with `is:issue`, #n hit the board at step 01 as an
  idea. D14.

**Scenario 2 — existing epic fits**

- Identical to 1 until 03. The user cannot "pick an epic" at 01 — nothing at 01 knows the epic.
  "Fits" means 02 put `PRD-NNN` in an existing §6 section. If the user wants a different epic than
  the section implies, that's a 03 question, not a 01 one.

**Scenario 3 — existing issue, already under epic E**

- 01 refuses on: `epic` label (an epic is not one idea — D8), an existing `ship/<n>-*` remote
  branch with 01 merged (it's past 01; say which step is next), an existing branch with 01 unmerged
  (resume it).
- `bug` label / `Bug` type → stop, point at `04-plan-intent <n>` (DECISIONS: bug fixes start at 04).
- Slug from the issue title with any `PRD-NNN:` prefix and `(Priority)` suffix stripped.
- If #n is already a PBI (`PRD-NNN:` title), 02 most likely produces **Changed**; 03 updates #n's
  body to the new PRD text and comments the docs PR link (old 3-epic "Changed, PBI open").
- Parent conflict (section epic F ≠ current parent E): ask; move with
  `POST issues/<F>/sub_issues -F sub_issue_id=<id> -F replace_parent=true` only on yes.

**Scenario 4 — existing issue, no epic**

- As 3 at 01 (no create). Adds `idea` label unless #n is already a PBI. 03 resolves the epic as in
  1 or 2. If #n was already on the board with a Status, nothing here moves it.

**Scenario 5 — splits into 3 PBIs**

- 03 maps IDs to issues in the approval table: #n takes one ID (D9), two new issues are created.
- Order: epics → prerequisites → the rest (so blocked-by always has a target).
- Extras' bodies: PBI template + their own References block, links only:

  ```markdown
  - Split from: #<n>
  - Brainstorm: [brainstorm.md](…/blob/<issue-branch-sha>/docs/ship/<n>-<S>/brainstorming/brainstorm.md)
  - Docs PR: #<q>
  - Epic: #<e2>
  ```

- Original's References gains `- Split into: #<a>, #<b>`.
- No branch, folder or worktree for #a / #b at 03. Their `04-plan-intent` creates
  `ship/<a>-<Sa>/issue` from `main` and a new worktree. **DECISIONS says `.../issue` is created by
  01 "or 04 for a bug fix" — needs "or 04 for any issue that has none" (bug fix or split PBI).**
- Extras' links stay valid because `cleanup` keeps the remote `.../issue` of #n.
- #n's slug came from the idea; after 03 it may be the PBI for a narrower `PRD-NNN` with a different
  title. Names are fixed, so the slug no longer matches the title. Acceptable; flagging only.

**Scenario 6 — rejected**

- At 01: the brainstorm file is the record → it still gets a PR into `.../issue` (no `main` PR, ever).
  On yes, `gh issue comment` + `gh issue close --reason "not planned"`. Merge is the user's. Then
  `cleanup <n>`: worktree, local branches, local folder; remote `.../issue` stays as archive. A closed
  `idea` issue is the searchable record — better than before (old rejected ideas only reached `main`
  if someone opened an optional PR).
- At 02 (conflict, or fully Covered): no PRD change ⇒ nothing to PR to `main`. Outcome recorded on
  the issue (comment), issue closed on yes. Unmerged `02-audit-prd` branch, if any, is deleted by
  `cleanup`.
- Pre-existing PBI rejected at 01 = retiring a ratified requirement. That's 02's job (`(was PRD-NNN)`),
  not a close at 01. D8.

---

## 2. Proposed behaviour — `01-brainstorm`

Arguments: idea text · issue number/URL · empty (list open `label:idea` issues with a
`ship/<n>-*/01-brainstorm` branch, ask which to resume).

1. **Resolve.** `git fetch origin`.
   - Issue number: `gh issue view`. Refuse on `epic`; redirect `bug` to 04; if
     `ship/<n>-*/issue` exists → resume (01 unmerged) or stop with next step (01 merged).
   - Idea text: nothing created yet.
2. **Describe.** Ask for 2–3 sentences, always (for an existing issue, offer its body as a starting
   point). Kept verbatim for §1 of the file.
3. **Read.** `PRODUCT.md`, `PRD.md` from `origin/main`; existing `label:idea` issues (all states) and
   PBIs for overlap. Report overlap before the first question.
4. **Interrogate + gate.** Unchanged from old 1-brainstorm Phases 3–4. Every open question answered or
   deferred-to-02 with reason; otherwise write nothing, create nothing.
5. **File the issue (new idea only).** Show exact title, body, labels; explicit yes; `gh issue create
   --label idea`. Body = the 2–3 sentences + empty References markers. No PRD number, no priority, no
   epic, no board write. Existing issue: add `idea` label unless already a PBI; no other edit.
6. **Branches + worktree.** `.../issue` from `origin/main` (push), worktree on `.../01-brainstorm`.
   Stop if the main checkout is dirty in a way that blocks `git worktree add`; never stash.
7. **Write** `docs/ship/<n>-<S>/brainstorming/brainstorm.md` — old template minus `§9 Ratified as`
   (D4), header `**Issue:** #<n>` instead of `**Idea:** NNN`.
8. **Decide** Approved / Rejected / Not yet — explicit answer only.
9. **Commit, push, PR.** Approved or Rejected → PR into `.../issue`. Not yet → push only. Refresh
   References (PR-head permalink). Rejected → offer close-as-not-planned (pre-existing PBI: never).
10. **Report** issue URL, PR URL, worktree path, next: `/cuevik-ship:02-audit-prd <n>` once merged.

What 01 never does: create or pick an epic, assign `PRD-NNN`, set priority, touch the board, open a PR
to `main`.

## 3. Proposed behaviour — `03-create-backlog`

Arguments: issue number (normal path) · `PRD-NNN …` (requirements that didn't come through 02 — old
behaviour, kept).

1. **Gate.** `git fetch origin`. #n's References has `Docs PR: #<q>`; `gh pr view <q>` is `MERGED` into
   `main`. Read the ratified block from that PR's body (D4). Every ID exists in
   `origin/main:docs/PRD.md` (§6 item or `(was PRD-NNN)`). Ratified block says Covered-only →
   nothing to file, stop.
2. **Read PRD side.** Per ID: §6 section, title, priority, requirement text, §8 criterion,
   prerequisites (§10 / text).
3. **Read GitHub side.** Existing PBI per ID (exact `PRD-NNN:` title prefix). Epic per ID, in order:
   1. parents (`GET issues/<pbi>/parent`) of existing PBIs in the **same §6 section** — exactly one →
      reuse; several → ask;
   2. else `label:epic` issues whose body cites that §6 section (`Source: docs/PRD.md §6 "<section>"`);
   3. else `docs/BACKLOG.md` on `main` — stories citing IDs from that section → their epic's Host ID
      (covers projects whose 07-backlog didn't create sub-issue links);
   4. else → **new epic** row in the table.
   - #n already has a parent ≠ resolved epic → ask (Scenario 3).
4. **Classify** (old 3-epic classes, plus one): New · New, new section · Changed, PBI open · Changed,
   PBI closed (ask) · Retired · Already filed · **Convert** — #n itself becoming the PBI for its ID.
5. **Approve one table.** ID · class · target issue (#n / new) · title · epic (#e / new) · labels ·
   blocked-by. Plus exact title/body of every create/edit. Partial yes allowed. Nothing written before.
6. **Write, dependency order.** Epics → #n conversion (title `PRD-NNN: <Title> (<Priority>)`, body
   above the References markers replaced by the PBI template, `idea` label removed, story/priority
   labels per D5, sub-issue link) → extras (create, sub-issue, References with `Split from`) →
   blocked-by → epic `Requirements:` line → #n References gains `Epic:` and `Split into:`.
   - Board: **local** → `gh project item-add` for #n and each new issue; Status untouched.
     **Cloud** (`CLAUDE_CODE_REMOTE=true`) → skip every `gh project` call.
   - Any non-board `gh` failure → stop, report written vs not; re-run classifies written rows as
     Already filed.
7. **Report.** Issues by epic, blocked-by links, stale work folders (Changed PBIs that already have a
   `ship/<m>-*/issue` branch), epic-title drift; cloud runs: the URLs to `item-add` locally unless
   Auto-add is on. Next: `04-plan-intent <n>` and `04-plan-intent <a>` / `<b>` for unblocked extras.

**Cloud note.** Old 3-epic assumed issue, label, sub-issue and blocked-by REST calls pass the cloud
GitHub proxy and only Projects v2 is blocked. I haven't verified that for sub-issues/dependencies —
it's carried over from the old command, not tested.

---

## 4. Knock-on changes 01/03 force elsewhere (not designed here)

- **02:** branch from `origin/main`; `Refs #n`, never `Closes`; writes the ratified block (D4) and
  `Docs PR:` in References; never edits the brainstorm file.
- **04:** creates `.../issue` for any issue without one; its gate after 03 is D10, not a PR.
- **DECISIONS §4 table:** row 02 "branched from `main`"; `.../issue` creator "01, or 04 for any issue
  with no `.../issue`".

---

## 5. Decisions needed

1. **Issue kind at 01.** Plain issue + `idea` label, converted to a PBI by 03 *(recommended — at 01
   there's no PRD-NNN, priority or epic, and a rejected "PBI" pollutes the backlog)* — or a PBI from
   the start.
2. **When 01 files the issue.** After the gate *(recommended — matches old 4-intent's "grill first,
   file second"; "first" in DECISIONS then means "before branch/folder")* — or at the start, so an
   abandoned session still leaves a resumable issue.
3. **Issue types.** Labels only *(recommended — `issueTypes` is null on user-owned repos)* — or set
   the type too where the org has them.
4. **Where the ratification record lives.** (a) machine-readable block in 02's PR body + `Docs PR:` in
   References; brainstorm file keeps only 01's decision *(recommended — one PR per step, no
   `docs/ship` write from a `main`-bound step)*; (b) 02 opens a second PR into `.../issue` to update
   brainstorm §9.
5. **Label convention for PBIs/epics.** cuevik-start's (`epic`, `story`, `priority:*`) or
   cs-cueviksync's (`epic` + module label, priority in title). Must be one, shared by
   `cuevik-start:07-backlog` and `03`. Recommend cuevik-start's labels **plus** the `PRD-NNN:` title
   prefix (03's lookup depends on it). Also: "PBI" or "story" — pick one word.
6. **Epic resolution chain** as in §3 step 3, with "several candidates → ask" and "never move a parent
   without a yes". Confirm.
7. **`docs/BACKLOG.md` after initiation.** Freeze it as the initial manifest; GitHub is the backlog
   truth from then on *(recommended — keeps 03 PR-less)* — or 03 opens a PR to `main` updating it
   (breaks "03: no branch").
8. **Existing issue given to 01.** Refuse epics; redirect bugs to 04; allow existing PBIs (03 treats
   as Changed); 01 never closes a pre-existing PBI. Confirm, or allow epics (then "the original issue
   continues at 04" breaks — an epic isn't a PBI).
9. **Which ID #n keeps on a split.** User picks in 03's table; default = first in prerequisite order
   (it's buildable first). Alternative: close #n as "split into" and make all PBIs fresh — breaks
   #n's branch set continuing, so not recommended.
10. **04's gate after 03** (no PR to check). Proposed: References has an `Epic:` line and #n has no
    `idea` label. Confirm or pick another signal.
11. **Split across epics.** Allow each PBI to go under its own section's epic *(recommended — follows
    the PRD)*, or force all under #n's epic.
12. **Rejection mechanics.** At 01: PR into `.../issue` as the record, close #n not planned on yes,
    user merges, then `cleanup`. At 02: comment + close, no PR. Also: should `cleanup` refuse while a
    `ship/<n>-*` PR is still open?
13. **Brainstorm filename** inside `brainstorming/` (proposed `brainstorm.md`) — and why it's a folder
    if it holds one file. I don't know the intent behind the folder.
14. **Ideas on the board.** If the project's Auto-add filter is `is:issue`, every `idea` lands on the
    board at 01. Exclude ideas (filter on label — I don't know if Auto-add supports negated labels,
    unverified) or accept them as Backlog cards.
15. **Plugin config** (owner/repo, project number, Status field/option IDs, worktree root path) — old
    commands hardcoded Cueserve/project 17. Needs a home before 01/03 can be written generically.
