# Build log — phases 07–24 (temporary)

> **Temporary.** Record of the unattended build of BUILD-PLAN phases 07–24, one stacked branch
> and PR per phase (`build/phase-NN-<slug>`, each based on the previous phase's branch). Nobody
> approved a plan or ran a sandbox test during this run: every decision below was taken by the
> building session and every phase is built but untested (◐). Use this file to drive the live
> test pass, then delete it with the other design docs (Phase 25).

## Summary: riskiest untested assumption per phase

Filled in when the run ends.

## Setup

- Branch `build/phases-07-24` from `main` at `ce6e3c1`, pushed. The session was also told to use
  a harness branch (`claude/modest-mccarthy-i2ztyl`); the task named `build/phases-07-24`
  explicitly, so that is the branch used.
- PR plan changed by the user after Phase 07's commit: one PR per phase, stacked. Phases 07–14
  were already committed in a line on `build/phases-07-24`, so each got a branch on its own
  commit and a PR based on the previous one (#17 for 07 against `main`, then #18–#24). Draft PR
  #16 was closed with links to them; `build/phases-07-24` gets no further pushes. From Phase 15
  each phase branches off the previous phase's branch.
- Sources cloned outside the repo (`/home/user/sources/`), default branches. Nothing copied in.
- Checks, run per phase from the repo root:
  - `claude plugin validate .` and `claude plugin validate plugins/<plugin>` (Claude Code
    2.1.305). The `ICON_MISSING` directory warning is pre-existing and does not fail validation.
  - `python scripts/check-contracts.py`.
  - markdownlint: `markdownlint-cli2` 0.23.3 over every `*.md`, with `default: true`, `MD013`
    at 100 characters with tables and code blocks excluded, `MD024` siblings only. Findings are
    counted per file and rule and compared with a `main` worktree (baseline 325 findings, none
    in skill files). "No growth" means no file and rule count went up.
  - `python docs/guides/build_docs.py --check`. Its check 7 fails when a built command is still
    tagged Planned, so every phase that adds a skill also flips its tag in both guides and runs
    `build_docs.py --write` to regenerate the HTML and PDFs. The build wants Chrome; the
    container has only Playwright's Chromium, so `/opt/google/chrome/chrome` was symlinked to it
    (outside the repo). The PDFs therefore come from Chromium 1194, not Chrome: re-run the build
    on the usual machine before release if the rendering differs.
  - Case-sensitive grep of `plugins/` for `cs-kickstart`, `cs-cueviksync`, `CuevikSync`,
    `cueviksync`, `proj-init`, `cuevikflow`, `viralparikh`, `DECISIONS.md`, `BUILD-PLAN`,
    `DRYRUN`, `D:\`, `vrp-repos`, `Cueserve`, `Supabase` (`references/board-template.json`
    excepted).

## Phase 07 — `cuevik-start:03-architecture`

Built: `skills/03-architecture/SKILL.md`; runner names 03 in the open-question and Possibility
rules; cuevik-start 0.1.10 → 0.1.11; guides tag 03 Available.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Interview driver | No skill; the runner interview, with 02's attack round and Possibility choices ported | Brainstorming is built for discovering intent; architecture attacks a draft (DECISIONS §10: "reconsider grilling for 02, 03"). Keeps the runner's Skills list unchanged. |
| Skills guard | "invokes no skill", right after the load block | BUILD-PLAN skills-guard convention for 02–08 |
| Open questions | Plain chat sentences (runner exception extended to 03) | Same interview style as 01/02 |
| Design options | `Possibility:` choices allowed (runner exception extended to 03); unpicked options become the alternatives rejected | The Architect decision format needs alternatives; options must not be invented answers, so the operator picks |
| Section order | §1 → §2/§3 → §6 → §7 → §8 → §5 → §4 reviewed last | Structure first; conventions follow the structure; decisions accumulate across parts |
| Decision format | Kept the template's 3-column table; the Rationale cell must name requirement, alternatives rejected and trade-off | Small diff: no template change |
| Diagram | `mermaid` or `text` fence | GitHub renders mermaid; markdownlint needs a fence language |
| Upstream deferrals | Reads the merged 01/02 PR bodies' "Deferred to the Architect" lists; each item answered, handed on, or rejected | Closes the loop 01/02 opened |
| Product names | Kept out; listed under "Deferred to Tech Stack" in the PR body | `TECH-STACK.md` owns the inventory |
| Scope conflicts | Never edit `PRD.md`; listed in the PR body for a `/cuevik-docs:update` | Product Owner co-review rule (roles) |
| Numbers | Only from `PRD.md` (by ID) or the operator; missing ones listed under "Open numbers" | Same hard number rule as 01/02 |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- `gh pr list ... --json number,body` returns the 01/02 PR bodies and the step finds their
  Deferred lists.
- The section order works in practice and §4 collects the decisions without re-asking.
- `Possibility:` options do not drift into Claude-invented decisions; the operator's pick lands
  in §4 with the others as alternatives rejected.
- No superpowers skill is invoked despite its session-start hook.
- A `mermaid` diagram passes the target repo's `.markdownlint.json`.
- Board: `#<INIT-03>` goes Working with a Start date, and INIT-02's End date is 02's merge date.

## Phase 08 — `cuevik-start:04-tech-stack`

Built: `skills/04-tech-stack/SKILL.md`; runner names 04 in the open-question and Possibility
rules; `steps.yml` 04 special action names the `TOOLING-LAYER` markers; cuevik-start 0.1.11 →
0.1.12; guides tag 04 Available.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Interview driver | No skill; runner interview, template order, one approval per section | Choices against alternatives, not intent discovery |
| Open choices | `Possibility:` candidates with trade-offs (runner exception extended to 04); unpicked ones fill §5 | §5 needs alternatives rejected; the operator still decides |
| Starting input | 03's merged PR body, **Deferred to Tech Stack** list | 03 parks product names there |
| Versions | From the operator or the release page / registry read after a yes; never from memory | Model memory of versions is stale |
| Usage rules | No template change; each Reason / Used-for cell is written as a scope rule, cross-cutting rules in §6 | Source checklist wants per-technology usage rules; the template has no column for it |
| Tooling layer location | Appended at the end of `CONTRIBUTING.md` between `<!-- BEGIN TOOLING-LAYER -->` / `<!-- END TOOLING-LAYER -->` | 08-finalize must keep it verbatim and docs:update must find it; markers make that deterministic |
| Tooling layer content | `## Tooling`: link to TECH-STACK, Versions, Commands (install/run/test/lint/build in one `sh` fence), Hooks | The source's three parts (run commands, hooks, versions) |
| Unknown commands | `Not set yet: <what is missing>`, listed in the PR body; commands are not run | At initiation there is no code to run them against |
| Re-run guard | STOP when the `TOOLING-LAYER` marker is already on `main` | Prevents a second append |
| Upstream conflicts | Listed under "Upstream changes needed"; never edit PRD/ARCHITECTURE | Same rule as 03 |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- The appended layer keeps the `INITIATION-ONLY` block byte-identical (08 depends on it) and the
  nested ```` fence example renders as intended for Claude.
- Claude does not write versions from memory; the web read happens only after a yes.
- `Not set yet` commands are acceptable to 06-readme, whose special action says to test every
  README command (likely conflict at initiation; see Phase 10).
- Board: INIT-04 Working + Start date, INIT-03 End date from 03's `mergedAt`.

## Phase 09 — `cuevik-start:05-ai-tool-guide`

Built: `skills/05-ai-tool-guide/SKILL.md`; template §10 gains a **Team plugins** bullet;
`steps.yml` 05 adds `.claude/settings.json` to `outputs` (conditional) and a special action;
cuevik-start 0.1.12 → 0.1.13; guides tag 05 Available and mention the settings file.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Interview driver | No skill; guide drafted per section from ARCHITECTURE/TECH-STACK with sources marked, then questioned | Most content derives from upstream; nothing to brainstorm |
| Tool question | One `multiSelect` AskUserQuestion (Claude Code / Copilot / Another tool); other tools' name + path typed | First `steps.yml` special action; never assume a config path |
| Template defaults §8–§10 | Kept as defaults, made concrete (lock files from TECH-STACK's package manager) | The template pre-fills them; generic lock-file list would be wrong for non-JS stacks |
| `CLAUDE.md` pointer | `@docs/AI-TOOL-GUIDE.md` import line | Claude Code loads imports with CLAUDE.md, so the rules actually reach the model; a link alone is not followed |
| Other adapters' pointer | One sentence + repo-root link, no copied rules | Source rule: never duplicate shared rules |
| Existing adapter on `main` | Keep lines verbatim, add pointer on top, show diff | No silent overwrite |
| Where Team plugins are listed | New **Team plugins** bullet in template §10 | BUILD-PLAN: graphify "listed in the guide"; §10 is the workflow section; no new top-level section |
| Candidate list | DECISIONS §8's six plugins, shown in a table, none Recommended | Locked list; operator picks |
| Marketplace / plugin names | Read from each repo's `.claude-plugin/marketplace.json` via `gh api` at run time | Names for `pbakaus/impeccable` and `leonxlnx/taste-skill` are not known to this build; never hardcode a guess |
| Cuevik marketplace | Asked as a typed `owner/repo`, never written in the plugin | DECISIONS §7/§8: no account in plugin files |
| Settings content | Only `extraKnownMarketplaces` (`source: {source: github, repo}`) + `enabledPlugins` (`plugin@marketplace: true`); merge into an existing file | Phase scope; permissions/hooks are the team's |
| graphify | Yes/No question; install link typed by the operator; listed in §10 | Not a plugin (DECISIONS §8); no install source from memory |
| claude.ai skills for CLI users | Stated as unsolved if asked | DECISIONS §8 Open item |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- The `.claude/settings.json` shape (from Claude Code's documented settings keys, not checked
  against the current docs in this run): a teammate opening the repo is prompted to install the
  marketplaces and the plugins are enabled.
- `gh api .../contents/.claude-plugin/marketplace.json` works for all three candidate repos
  (the two third-party repos may keep the file elsewhere or not have one).
- Claude Code actually expands `@docs/AI-TOOL-GUIDE.md` in the committed `CLAUDE.md`.
- `multiSelect` AskUserQuestion behaves as expected with `Other`.
- Runner §5 commits only the conditional outputs actually written (`git add` of a missing
  `.github/copilot-instructions.md` would fail).

## Phase 10 — `cuevik-start:06-readme`

Built: `skills/06-readme/SKILL.md`; `steps.yml` 06 special action split by mode; cuevik-start
0.1.13 → 0.1.14; guides tag 06 Available and describe the two modes.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Interview driver | No skill; whole draft from upstream with sources marked, then ask only for gaps (env vars, accounts) | README summarizes; little to interview |
| Scaffold detection | Files on `main` minus what initiation wrote → propose a mode, operator confirms | The source checked `package.json`, which is JavaScript-only; a stack-neutral check plus confirmation avoids a wrong guess |
| Docs-first marker | Source's fixed opener `> **Pending scaffold — unverified.**` on the four setup sections | Ported as is; deterministic for review |
| "Test every command" special action | Rewritten: scaffolded mode tests; docs-first marks pending | Resolves the conflict noted in Phase 08 (no code at initiation) |
| Long-running commands | Start, confirm it comes up, stop | A dev server never exits; running it blocking would hang the step |
| `Not set yet` commands | Written as prose, never in a code block | Never present an unknown command as runnable |
| Badges | Static shields.io, `<Name>-<version>-blue`, `-`→`--`, space→`_` | Source required shields.io; a fixed colour avoids inventing per-brand styling |
| Old README | Replaced whole; anything worth keeping is offered section by section first | `replacesExisting`; no silent carry-over |
| Planned folders (docs-first) | Existing folders plus `ARCHITECTURE.md` §5 planned ones marked `(planned)` | Structure section must not claim folders exist |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- The mode detection excludes exactly what 00–05 wrote on the sandbox (a missed file would
  propose Scaffolded wrongly; the confirmation is the safety net).
- The shields.io badge format renders (escaping of versions like `20.11.1`).
- Scaffolded mode on a repo with code: commands run, a dev server is stopped cleanly.
- The pending marker passes the target repo's markdownlint (blockquote spanning two lines).
- `README.md` on `main` (from repo creation, or none) is handled: no README at all is not covered
  by `replacesExisting` wording but should just write the file.

## Phase 11 — `cuevik-start:07-backlog`

Built: `skills/07-backlog/SKILL.md`; `BACKLOG.template.md` gains the frozen note (D7) after the
references marker; cuevik-start 0.1.14 → 0.1.15; guides tag 07 Available.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Epic granularity | One epic per `PRD.md` §6 capability subsection, `Epic: <subsection>`, body cites `Source: docs/PRD.md §6 "<subsection>"` | cuevik-ship's D6 lookup searches epics by that citation; PRD §6 is already grouped by capability |
| NFRs | Filed as stories under one `Epic: Non-Functional Requirements` (`Source: docs/PRD.md §7`) | Source rule "one story per requirement item"; NFRs share the `PRD-NNN` sequence |
| NFR priority | Asked from the Product Owner (or `Won't` → §4) | PRD §7 bullets carry no MoSCoW; the PO owns backlog priority; never invented |
| Story title / labels | `PRD-NNN: <Title> (<Priority>)`; `story` + `priority:must/should/could`; epics `epic` | D5, shared with cuevik-ship 03 |
| Story body | Requirement text + `**Acceptance criterion:**` (copied) + `Source:` line | Copy, never rewrite (source rule); the Source line feeds cuevik-ship |
| Parent link | REST `sub_issues`, same call bootstrap uses | D6 step 1 finds epics via parents |
| `initiation` issues | Excluded from the existing-issue scan; never labelled | DECISIONS §9 |
| Re-run | Reuse open issues by exact title; closed match → operator decides | Mirrors bootstrap's reuse; safe after a partial failure |
| Approval | One table, one `Yes`, before any GitHub write; runner §2 plan only names label creates | Special action "wait for approval before any writes"; issues are unknown at §2 |
| Board | `item-add` + `Item Type` only; no Status/Priority/Size/Sprint/assignee; failures reported, never fatal | DECISIONS §9 says 07 should set Item Type; Priority field options (Urgent/High/…) do not map to MoSCoW, so no mapping invented; sprint planning owns the rest |
| `PENDING` IDs | Dropped: a non-board `gh` failure stops the step instead | `gh` is required anyway; a manifest with pending rows would freeze wrong |
| Label colours | Fixed hex per label | Need some value; cosmetic |
| Gaps | **Proposed PRD.md changes** in the PR body; PRD never edited | Source rule |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- `gh issue create` with multi-line bodies via the Bash tool (quoting), and capturing numbers.
- Sub-issue linking for dozens of stories (rate limits; the REST id vs number).
- `gh issue list --limit 500` is enough and the `initiation` exclusion works.
- Board `item-add` for many items, and the `Item Type` option lookup.
- PO answers NFR priorities in one round without the step inventing defaults.
- Whether every story being created during the session conflicts with the runner's "one question
  at a time" token rules on a large PRD.

## Phase 12 — `cuevik-start:08-finalize`

Built: `skills/08-finalize/SKILL.md`; cuevik-start 0.1.15 → 0.1.16; guides tag 08 Available.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Interview | None; a fixed transformation | Source: deterministic removal, no judgement |
| Fence check | Exactly one BEGIN and one END marker in order, else STOP; stub already present → STOP | `steps.yml` special action; also catches a hand-edited or duplicated fence |
| Stub text | Source stub ported, command renamed to `/cuevik-docs:update CONTRIBUTING.md` | Same hand-off; no provenance |
| Verification | `git diff main -- CONTRIBUTING.md` must show only the removed block and the stub | Byte-for-byte preservation is the whole point of the step |
| Missing `TOOLING-LAYER` markers | Proceed and report | The 04 markers are new in this build; an older 04 run would lack them; 08's job is only the INITIATION-ONLY block |
| Epic closing | Body ends `Closes #<story>` and `Closes #<epic>` (runner §6.5 already says so) | DECISIONS §9 |
| After-merge | `finalReminder` points at `/cuevik-start:cleanup` for End dates | Runner §7 |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- Claude's Edit leaves every other line byte-identical (trailing spaces, final newline) and the
  diff check catches it if not.
- Two `Closes` lines: GitHub links the PR to both issues and the board moves the epic to
  Reviewing then Done.
- The stub passes the target repo's markdownlint (italic paragraph spanning lines).

## Phase 13 — `cuevik-start:cleanup`

Built: `skills/cleanup/SKILL.md`; cuevik-start 0.1.16 → 0.1.17; guides tag cleanup Available and
mention the End dates.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Runner | Not used (utility, like `status`); reads `steps.yml` and runner §7 for the board commands | No branch, PR or story |
| Merged test | `gh pr list --head <branch> --state merged`, then local tip must equal the PR's `headRefOid` | Squash merges make `git branch -d` refuse; the oid check makes `-D` safe and protects unpushed commits |
| Current branch | `git checkout main` in the plan when the tree is clean; else skip | Git cannot delete the checked-out branch; never stash |
| Remote leftovers | Reported, never deleted | DECISIONS §3: local branches only |
| End dates | Only when the last step's PR merged; last story + epic = the date part of its `mergedAt`; skip if already set | Runner §7 / DECISIONS §9 |
| Earlier stories missing End dates | Not repaired | Out of the phase's scope; each step start sets them |
| Confirmation | One plan, one `Yes` | Same pattern as runner §2 |
| Not complete yet | Branch deletes still allowed; End dates skipped | DECISIONS §3: "run any time" |
| Cloud session | Board updates fail and are reported, never fatal | Projects v2 is unreachable from cloud sessions |

Checks: validate `.` pass · validate `plugins/cuevik-start` pass (pre-existing icon warning) ·
contracts pass · markdownlint no growth (325 → 325) · build_docs `--check` pass · forbidden
terms clean.

Untested — a live sandbox run must verify:

- `headRefOid` equals the local tip after a normal step (the runner pushes the branch and opens
  the PR from it, so it should).
- `git ls-remote --heads origin 'refs/heads/init/*'` pattern matching on Windows Git Bash.
- End date updates land on the right items; the epic and last story show the 08 merge date.

## Phase 14 — `cuevik-docs:update`

Built: `plugins/cuevik-docs/skills/update/SKILL.md`; the lineage contract copied to
`plugins/cuevik-docs/references/contracts/lineage/` and declared in `contracts/consumers.json`
(its README already names cuevik-docs as a consumer); cuevik-docs 0.1.0 → 0.1.1; guides tag
update Available.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Document list | Read from `.cuevik/lineage.json`, matched by path or file name | Source hardcoded seven docs; the lineage is the contract (DECISIONS D15, §7) |
| Contract copy | Lineage contract copied into cuevik-docs | BUILD-PLAN convention: each consumer keeps a declared copy |
| Frozen docs | Refused (`docs/BACKLOG.md`) and skipped downstream | D7 |
| `CONTRIBUTING.md` | Supported (it is a lineage document); markers kept byte for byte | 08-finalize's stub says to fill it via this command |
| Branch | `docs/update/<file name, lower case, no .md>` (`prd`, `ai-tool-guide`) | Source + Walkthrough |
| Role files | Not copied; a two-row role lens table in the skill | cuevik-docs cannot read cuevik-start files (§7); the full role files reference runner/steps.yml that cuevik-docs does not have |
| Writing rules / step checklists | Compact editing rules + a generic reviewer checklist in the skill, not the per-document checklists | Same self-containment reason; trade-off: a reviewer does not get the step's full checklist |
| Downstream checklist | In the PR body (required / review-only / not impacted, each with a reason), not a committed `.claude/reconciliation/` file | Keeps tool scratch off `main`; the PR is where reviewers look. Trade-off: no file to tick after merge other than the merged PR |
| `PRD-NNN` | Never reused or renumbered; new ones continue the sequence; retired ones struck through with a reason | 02 rule; cuevik-ship relies on stable IDs |
| AI-TOOL-GUIDE adapters | May change (or a new one be added) in the same PR | Source: adding a tool goes through doc-update |
| Arguments | `$ARGUMENTS` and `argument-hint: "[document]"` frontmatter | Standard skill argument mechanism |
| Cross-document changes | Stop and point to the right document's update first | Each document at its own level |

Checks: validate `.` pass · validate `plugins/cuevik-docs` pass (icon warning, same as the other
plugins) · contracts pass (3 plugin copies) · markdownlint: **grew by 14**, all
`MD060/table-column-style` in the new `plugins/cuevik-docs/references/contracts/lineage/README.md`.
That file must stay byte-identical to `contracts/lineage/README.md` (check-contracts enforces it),
whose two existing copies carry the same 14 findings; fixing it means changing the shared contract
and every copy, which is outside this phase. Accepted as the one exception and added to the
comparison baseline; no other file grew · build_docs `--check` pass · forbidden terms clean.

Untested — a live sandbox run must verify:

- `$ARGUMENTS` substitution in a plugin skill (and the no-argument path).
- Claude keeps every unchanged byte (header, markers) when editing a section.
- The derived downstream list matches the Walkthrough table for each document.
- The PR body's multi-line `--body` survives the Bash tool quoting.

## Phase 15 — `cuevik-docs:audit`

Built: `plugins/cuevik-docs/skills/audit/SKILL.md`; cuevik-docs 0.1.1 → 0.1.2; guides tag audit
Available and describe the report and `fix`. Branch `build/phase-15-docs-audit`, stacked on
Phase 14.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Corpus | Every `.cuevik/lineage.json` document + AI tool adapters + `.claude/settings.json` | The source hardcoded one product's file list; the lineage is the project's own list |
| Authority ladder | Files on disk/git → `CONTRIBUTING.md` (governance) → lineage graph (upstream wins) → `AI-TOOL-GUIDE.md` over adapters → `README.md` owns nothing | Source ladder, rebuilt on the lineage and on this suite's guide/adapter split (05) |
| Product specifics | Removed: domain terms, numbers, database/hosting vendor, tracker link, the dated "known-open findings" section | BUILD-PLAN Phase 15: generalised, no product specifics |
| Requirement IDs | `PRD-NNN` only (NFRs share the sequence), retired IDs struck through count as resolving | Matches 02 and docs:update |
| References tables | All injected copies must be identical | Here the tables are injected from one source; the source's "copies are a regression" rule was product-specific and inverted |
| Lineage headers | Each document's Owner / Derived from / Downstream must match the lineage | The lineage is the stored truth; headers are copies of it |
| Labelled pending | `Pending scaffold — unverified` (06) and `Not set yet` (04) are honest, not drift | Same exception as the source, extended to 04's marker |
| Frozen docs | Only their citations are checked; never drift against the current state | D7 |
| Work folders | `docs/ship/` in an issue worktree is transient; remote `ship/*/issue` branches of closed issues reported (cleanup not run) | Replaces the source's "closed work folder still present" check for the ship model |
| Model invocation | **No** `disable-model-invocation`, unlike every other skill | `cuevik-ship:02-audit-prd` must run it with the Skill tool, which `disable-model-invocation: true` blocks. Read-only by default, and the description limits it to an explicit ask or a cuevik-ship step |
| `fix` | Safe tier only (broken link, stale stamp, README transcription), on a `docs/audit-fixes-<date>` branch, as one PR after a `Yes` | The source edited files in place; here every change reaches `main` through a PR |
| Approval tier | Never applied; the report names `/cuevik-docs:update <document>` for each | One document per PR, with its downstream checklist |
| Report | In chat only, no file; source finding format and two axes kept | Walkthrough: "a findings report"; nothing to commit |

Checks: validate `.` pass · validate `plugins/cuevik-docs` pass (icon warning) · contracts pass ·
markdownlint no growth (339 → 339, baseline incl. the Phase 14 contract-copy exception) ·
build_docs `--check` pass · forbidden terms clean.

Untested — a live sandbox run must verify:

- `cuevik-ship:02-audit-prd` can invoke `cuevik-docs:audit` with the Skill tool (cross-plugin,
  no `disable-model-invocation`), and Claude does not run it unasked in unrelated sessions.
- The report is usable on a real initiation corpus without timing out on the read-everything
  pass.
- `git ls-remote --heads origin 'refs/heads/ship/*'` + `gh issue view` correctly flags issue
  branches of closed issues.
- `fix` opens a PR with only Safe-tier edits.

## Phase 16 — cuevik-ship foundation

Built: `plugins/cuevik-ship/references/` — `process.md` (steps, the one rule, session boundary,
artifacts, asking, skills, nevers), `branches.md` (names, worktree, PR bases), `references-block.md`
(format, permalinks, refresh), `gate.md` (common preconditions, per-step gate table, plan
approval), `config.md` (project facts, local vs cloud, board Status and labels); config and lineage
contracts copied in and declared; `userConfig.worktree_root` in `plugin.json`; cuevik-ship 0.1.0 →
0.1.1. No command yet, so the guides are unchanged. Branch `build/phase-16-ship-foundation`.

Phase 15 needed a second commit (a BUILD-LOG header line over 100 characters, flagged by the
lint run after the first commit). The commit flow now refuses to commit while lint grows.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Reference split | Five files, one per BUILD-PLAN item (process, branch/worktree, References block, gate, config read) | Maps 1:1 to the row; steps load what they need |
| Where steps run | One worktree per issue, created by 01 (or 04); every later step switches branches inside it (`origin/.../issue` for 04–06, `origin/main` for 02 and 07) after the previous PR merged | DECISIONS §4: one worktree per issue; branching 02/07 from `main` keeps `docs/ship/` out of their PRs |
| Worktree path | `<root>/<repo>/<n>-<slug>` | Several repos can share one root |
| Worktree root | `userConfig.worktree_root` shown in each SKILL; fallback `git config --global cuevik-ship.worktreeRoot`; else ask and offer to save | D15 says userConfig, but Phase 03 saw `${user_config.*}` arrive unsubstituted, and substitution only happens in skill text, not in files read later; git config is a reliable machine-local store |
| Issue branch start | `main`'s commit, pushed at once, no extra commit | A PR base must exist on GitHub; no empty commit needed |
| Artifact status | `**Status:** Draft` → `Approved` only on an explicit yes, plus the merged PR | Source rule; the gate checks both |
| Folder README rollup | Dropped; the issue's References block is the progress record | One record per issue, already refreshed by every step; avoids a second status file that can drift |
| Asking style | cuevik-start's: one question per message, AskUserQuestion for choices, `Possibility:` for genuinely open designs | The source batched questions per its own repo rules; one suite, one style |
| superpowers skills | Not invoked by any cuevik-ship step; the disciplines (interrogation, TDD-shaped proofs) are written into the steps | cuevik-ship declares only `cuevik-docs` (DECISIONS §7); superpowers is cuevik-start's one exception (§10). Trade-off: less depth than brainstorming in 01/04 |
| Board model | 06 → `Ready`, 07 → `Working`; Reviewing/Done by board workflows via `Closes #<n>` on the code PR only; labels `idea`, `shaping`, `decision-needed` | Source board model, fitted to the runner's rule that board workflows own Status after start; `Refs` (not `Closes`) on every other PR keeps cards still |
| Missing Status option (`Ready`) | Skip and report | The Cuevik template's option list is not known to this build; never create options |
| Cloud | `CLAUDE_CODE_REMOTE=true` → skip `gh project` calls and report | Projects v2 unreachable from cloud sessions |
| Permalinks | Latest commit on `.../issue` touching the file; PR head commit while unmerged | DECISIONS §4 + DRYRUN §1 |

Checks: validate `.` pass · validate `plugins/cuevik-ship` pass (icon warning) · contracts pass
(5 plugin copies) · markdownlint: grew by 29, all in the two new contract READMEs under
`plugins/cuevik-ship/references/contracts/` (byte-identical copies; same exception as Phase 14,
added to the baseline); no other file grew · build_docs `--check` pass · forbidden terms clean.

Untested — a live sandbox run must verify:

- `${user_config.worktree_root}` substitution in a cuevik-ship SKILL (it failed for cuevik-start
  in Phase 03); the git config fallback works on Windows.
- `git worktree add` + `git switch -c ... origin/main` inside a worktree, and that the tree is
  clean after each merged PR.
- `gh issue edit --body-file` keeps the issue body byte-identical outside the markers.
- The board has a `Ready` option; `Pull request linked to issue` fires only for `Closes`, not
  `Refs`.

## Phase 17 — `cuevik-ship:01-brainstorm`

Built: `plugins/cuevik-ship/skills/01-brainstorm/SKILL.md`; cuevik-ship 0.1.1 → 0.1.2; guides tag
01-brainstorm Available. Branch `build/phase-17-brainstorm`.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Order | Describe → duplicate check → plan approval → create issue, `.../issue`, worktree, folder → read docs → interview → gate → decide | D2: duplicates first (cheap), issue at the very start so findings are saved from the first minute |
| Duplicate check | Titles (and close-match bodies) of `idea` and `story` issues in any state; a likely duplicate needs a yes to continue | D2; a duplicate never gets a number |
| Issue | Plain issue, label `idea`, body = the operator's sentences + empty References block | D1, D3 |
| Board | The new idea is added to the board (local sessions); Status left to the board | D14: ideas may land on the board at 01 and the card carries through |
| Existing issue | Refuse closed, `epic`; send `bug` to 04; allow a story (never labelled `idea`, never closed here) | D8 |
| Interview driver | No superpowers skill; one question per message, anchors, playback, read-only recon on a yes | Foundation decision (cuevik-ship declares no superpowers dependency) |
| Where the session works | Starts in the main checkout, creates the worktree, then works in it by absolute path; later runs must open in the worktree | Worktree is created mid-session; a resume needs the worktree's files |
| File template | Source's sections with §9 "Decision" instead of "Ratified as" | D4: the ratification record lives in 02's PR body |
| Attachments | Saved beside `brainstorm.md` in `brainstorming/` | D13 |
| Not yet | Commit and push, no PR | Resume needs the branch on GitHub |
| Rejected / abandoned | PR into `.../issue` as the record (rejected), close not planned on a yes; pre-existing story never closed | D12, D2, D8 |
| References at 01 | `Brainstorm:` line with the PR head permalink | DRYRUN §1: the file is not on `.../issue` until the PR merges |

Checks: validate `.` pass · validate `plugins/cuevik-ship` pass (icon warning) · contracts pass ·
markdownlint no growth (368 → 368) · build_docs `--check` pass · forbidden terms clean.

Untested — a live sandbox run must verify:

- Working in a worktree created mid-session (absolute paths, `git -C`) without touching the
  main checkout.
- `gh issue create --body-file` and capturing the number from the printed URL.
- The duplicate check is useful at sandbox scale and does not over-match.
- `$ARGUMENTS` with a quoted idea vs a number vs empty.
- A rejected idea's PR into `.../issue` merges cleanly and `cleanup` then accepts the closed issue.

## Phase 18 — `cuevik-ship:02-audit-prd`

Built: `plugins/cuevik-ship/skills/02-audit-prd/SKILL.md`; cuevik-ship 0.1.2 → 0.1.3; guides tag
02-audit-prd Available. Branch `build/phase-18-audit-prd`.

Decisions:

| Decision | Chosen | Why |
| --- | --- | --- |
| Branch | `.../02-audit-prd` from `origin/main`, switched to inside the issue worktree; brainstorm read with `git show origin/.../issue:...` | DECISIONS §4: 02 goes to `main`; no `docs/ship/` can leak |
| Gate | 01 PR merged into `.../issue` and `brainstorm.md` `Approved` | gate.md 02 row |
| Retired IDs | Stay in place as `~~PRD-NNN~~ (retired: <why>)` (not moved to §9 as `(was PRD-NNN)`) | One convention across docs:update, audit and 03 |
| PRD line format | This suite's PRD template form (`***Title***`, `*(Must)*`) | The project's PRD comes from 02-product-requirements' template |
| New NFRs | Continue the shared `PRD-NNN` sequence | Same rule as 02-product-requirements |
| One commit per document | PRODUCT first, then PRD, each a diff + downstream named + yes | Source rule; keeps review clean |
| Audit | `cuevik-docs:audit` via the Skill tool, read-only; caused-by fixed here, pre-existing listed; audit unavailable → no PR | Source rule; requires audit to be model-invocable (Phase 15) |
| Ratification record | Fenced YAML between `<!-- cuevik-ship:ratified -->` markers in the PR body: `issue`, `new`, `changed`, `retired`, `covered`, `prerequisites` (pairs), `product`, `later_release` | D4: machine-readable for 03 |
| Covered-only / rejected at 02 | No PR; comment + close not planned on a yes; then cleanup | D12, DRYRUN scenario 6b |
| `Refs #<n>`, never `Closes` | PR body last line | Steps 04–07 need the issue open |
| References | `Docs PR: #<q>` after the PR opens | D4 |

Checks: validate `.` pass · validate `plugins/cuevik-ship` pass (icon warning) · contracts pass ·
markdownlint no growth (368 → 368) · build_docs `--check` pass · forbidden terms clean.

Untested — a live sandbox run must verify:

- The Skill tool can invoke `cuevik-docs:audit` from a cuevik-ship step.
- The YAML ratification block survives `gh pr create --body` and 03 can parse it from
  `gh pr view --json body`.
- Switching the worktree from the `.../issue` line to an `origin/main` branch and back is clean.
- An ID numbered from "highest + 1" is right when retired (struck-through) IDs are the highest.
