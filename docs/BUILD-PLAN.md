# Build plan (temporary)

> **Temporary.** Execution plan for building the three plugins, one phase per session, one PR per
> phase. Design lives in [DECISIONS.md](DECISIONS.md); 01/03 behaviour detail in
> [DRYRUN-01-03.md](DRYRUN-01-03.md). Delete all three in Phase 25 once their content is folded
> into each plugin's README.

---

## How each phase runs

1. Start a **new session** in `D:\vrp-repos\vrp-cuevik-plugins` with the prompt template below.
2. The session branches `build/phase-NN-<slug>` from an up-to-date `main` **in this folder** (no
   worktree — phases are sequential, and the local marketplace loads whatever is checked out here).
3. It reads `DECISIONS.md`, this file's Conventions, its phase row, and the listed sources — nothing
   else from earlier sessions.
4. It builds only its phase's files, bumps the patch version of each plugin it touched, runs
   `claude plugin validate .` and `claude plugin validate plugins/<plugin>`, and opens a PR to `main`.
5. You test (see Testing), then merge. The next phase starts only after the merge.

### Session prompt template

```text
Build Phase NN of the cuevik plugins: <phase title from docs/BUILD-PLAN.md>.

Repo: D:\vrp-repos\vrp-cuevik-plugins. Read docs/DECISIONS.md, then docs/BUILD-PLAN.md
(Conventions + the Phase NN row), then the sources that row lists. Where DECISIONS.md §5 and
docs/DRYRUN-01-03.md disagree, DECISIONS.md wins.

Branch build/phase-NN-<slug> from an up-to-date main in this folder (no worktree). Build only this
phase's files. Bump the patch version of each plugin you touch. Run
`claude plugin validate .` and `claude plugin validate plugins/<plugin>` and show the output.
Commit, push, open a PR to main. Do not start the next phase.

Finish by giving me exact steps to test this command on cuevik-sandbox.
Plan first and wait for my approval before writing files.
```

---

## Conventions (every phase)

- **Layout:** `plugins/<plugin>/skills/<command>/SKILL.md`; supporting files beside it or in
  `plugins/<plugin>/references/`. Reference them as `${CLAUDE_PLUGIN_ROOT}/...` — Claude Code
  substitutes it inside skill content. Never write state under `${CLAUDE_PLUGIN_ROOT}`.
- **Workflow steps are user-invoked only.** Every step's `SKILL.md` frontmatter sets
  `disable-model-invocation: true` (verified against code.claude.com/docs/en/skills, 2026-10-17:
  stops Claude loading the skill itself; it runs only via `/name`). Not `user-invocable: false`,
  which does the opposite: hides it from the `/` menu but leaves Claude free to invoke it.
- **Self-contained (DECISIONS §7).** Plugin files never name `cs-kickstart`, `proj-init`,
  `cuevikflow`, a local path, a `viralparikh-*` account (only exception:
  `references/board-template.json`) or these temporary docs, and depend on no
  other plugin except `cuevik-docs` (and, for `cuevik-start`, `superpowers`, §10). Port the
  content; drop the provenance.
- **Templates** live beside their step skill: `skills/<id>/<DOC>.template.md`.
- **No hardcoded project facts.** Owner/repo from the git remote; board number and field IDs from
  `.cuevik/config.json`; worktree root from plugin `userConfig` (DECISIONS D15).
- **Shared contracts** (`.cuevik/config.json`, `.cuevik/lineage.json`) are defined once in
  `contracts/<name>/` and copied into each plugin that uses them at
  `plugins/<plugin>/references/contracts/<name>/`. Declare each copy in `contracts/consumers.json`
  in the same PR; `python scripts/check-contracts.py` fails on an example that breaks its schema or
  a missing, drifted or undeclared copy (needs `pip install -r scripts/requirements.txt`; same pattern as `vrp-cuevikflow-plugin/contracts/` + `scripts/test_contract.py`).
- **Wording:** "story", never "PBI" (D5). `gh` via the Bash tool, not PowerShell.
- **Gate:** every step checks the previous step's PR is `MERGED` before doing anything.
- **Skills guard (02–08):** each step's `SKILL.md` says, right after its load block, which skill it
  invokes (or none) and that a session-start instruction to use skills first does not apply
  (runner, Skills). The skill body loads before the runner, so the guard must be in it.

## Testing

- **Install once, from the local folder** (loads in place, no version pinning, and avoids
  `viralparikh-tx` needing access to the private repo):

  ```text
  /plugin marketplace add D:/vrp-repos/vrp-cuevik-plugins
  /plugin install cuevik-start@cuevik-plugins
  /plugin install cuevik-ship@cuevik-plugins
  ```

  `cuevik-docs` (and `superpowers`, for `cuevik-start`) is enabled automatically as a dependency. Start a new Claude session after each
  phase so the changed skill is loaded.
- **Target:** every phase is tested on `viralparikh-dev/cuevik-sandbox` (throwaway) only.
  `tx-QE4AIApps` is tested once, after all phases are merged.
- The phase branch must be checked out in `D:\vrp-repos\vrp-cuevik-plugins` while testing.
- **Restart Claude Code before each test, not just a new chat.** A skill's `SKILL.md` body is read
  once per process and cached: in the Phase 05a test a new VS Code chat ran a `SKILL.md` three
  commits old, while files the skill opens with Read (the runner) were current. In VS Code run
  **Developer: Reload Window**; in the desktop app, quit and reopen.

---

## Phases

Status: ☐ not started · ◐ in progress · ☑ merged

| # | Phase | Builds | Main sources | Status |
|---|---|---|---|---|
| 00 | Scaffold | `marketplace.json`, 3 `plugin.json`, `docs/` | — | ☑ |
| 01 | Contracts | `contracts/config/` + `contracts/lineage/` (schema + example + README), `contracts/consumers.json`, `scripts/check-contracts.py`, skills frontmatter key confirmed | DECISIONS §3–§5, D15; `vrp-cuevikflow-plugin/contracts/` | ☑ |
| 02 | cuevik-start foundation | `references/`: runner (from `_run-step.md`), step registry (from `_steps.yml`, renumbered 00–08, 01 merged into 00), templates, `_writing-rules`, `_doc-references` | `cs-kickstart/docs/guides/proj-init/` | ☑ |
| 03 | `cuevik-start:00-bootstrap` | `gh` auth check; repo + board: ask, or create and link on confirmation (DECISIONS §3); governance + `CONTRIBUTING.md` PR, auto-delete head branches, writes `.cuevik/config.json` + `.cuevik/lineage.json` | `00-bootstrap.md`, `01-repo-setup.md`, `bootstrap-target-repo.mjs` | ☑ |
| 04 | `cuevik-start:status` | Step progress from git + PR state | `doc-status.md` | ☑ |
| 05 | `cuevik-start:01-product-concept` | `docs/PRODUCT.md` | `02-prod-concept.md` | ☑ |
| 05a | Pre-06 design changes | Templates beside skills; self-contained plugin (one exception: `references/board-template.json`); bootstrap: board choice Cuevik template / your template / blank, initiation epic + `INIT-NN` stories (`initiation` label, assignee, Item Type, Priority, Size, Efforts, `Sprint-00` on an empty Sprint field), 7 workflows with required Status settings, one plan approval, no trailer on the empty commit; config v2 (`initiation`); runner: AskUserQuestion rules, `Closes #n`, board bookkeeping (Working + dates); status progress line + issue cross-check. Tested live: bootstrap on the sandbox (new repo, Cuevik template) and on tx-QE4AIApps (existing repo + board). One PR. | DECISIONS §3, §7–§9 | ☑ |
| 05b | 01 deep interview | `01-product-concept` interview driven by the required `superpowers:brainstorming` (its spec file and `writing-plans` hand-off switched off; PRODUCT.md is the only output); dependency mechanism; then the deferred sandbox 01 test (Working → Reviewing → Done, `Closes #2`, Start/End dates) | DECISIONS §10 | ☑ |
| 06 | `cuevik-start:02-product-requirements` | `docs/PRD.md` | `03-prod-requirements.md` | ◐ |
| 07 | `cuevik-start:03-architecture` | `docs/ARCHITECTURE.md` | `04-architecture.md` | ◐ |
| 08 | `cuevik-start:04-tech-stack` | `docs/TECH-STACK.md`, CONTRIBUTING tooling layer | `05-tech-stack.md` | ◐ |
| 09 | `cuevik-start:05-ai-tool-guide` | AI tool guide + adapters; team plugin setup: the target repo's `.claude/settings.json` (`extraKnownMarketplaces` + `enabledPlugins`, per project), graphify as a manual prerequisite (DECISIONS §8) | `06-ai-tool-guide.md` | ◐ |
| 10 | `cuevik-start:06-readme` | `README.md` | `07-readme.md` | ◐ |
| 11 | `cuevik-start:07-backlog` | `docs/BACKLOG.md` (frozen-after-initiation header, D7), epics + stories with `epic`/`story`/`priority:*` labels (D5); ignores `initiation` issues (DECISIONS §9) | `08-backlog.md` | ◐ |
| 12 | `cuevik-start:08-finalize` | Strip INITIATION-ONLY fence from `CONTRIBUTING.md` | `09-finalize.md` | ☐ |
| 13 | `cuevik-start:cleanup` | Delete merged local `init/*` branches; set the last initiation story's and the epic's `End date` from the 08 PR's merge date (runner §7) | `cleanup.md`, DECISIONS §3 | ☐ |
| 14 | `cuevik-docs:update` | Update any source-of-truth doc via PR, driven by `.cuevik/lineage.json` | `doc-update.md` | ☐ |
| 15 | `cuevik-docs:audit` | Align / Drift / Absorb audit, generalised (no CuevikSync specifics) | `cs-cueviksync/.claude/commands/doc-audit.md` | ☐ |
| 16 | cuevik-ship foundation | `references/`: process overview, branch/worktree model, References-block format, gate check, config read | `cs-cueviksync/docs/work/README.md`, DECISIONS §4 | ☐ |
| 17 | `cuevik-ship:01-brainstorm` | D1, D2, D8, D12, D13 | `work/1-brainstorm.md`, DRYRUN §2 | ☐ |
| 18 | `cuevik-ship:02-audit-prd` | Branch from `main`, `Refs #n`, ratified block (D4), calls `cuevik-docs:audit` | `work/2-audit-prd.md` | ☐ |
| 19 | `cuevik-ship:03-create-backlog` | Epic resolution (D6), convert/split (D9, D11), board add local only | `work/3-epic.md`, DRYRUN §3 | ☐ |
| 20 | `cuevik-ship:04-plan-intent` | Creates `.../issue` + worktree when missing; D10 gate | `work/4-intent.md` | ☐ |
| 21 | `cuevik-ship:05-design-spec` | `spec.md` | `work/5-spec.md` | ☐ |
| 22 | `cuevik-ship:06-build-plan` | `plan.md` | `work/6-plan.md` | ☐ |
| 23 | `cuevik-ship:07-execute-plan` | Code branch from `main`, code PR to `main`, final References refresh | `work/7-execute.md` | ☐ |
| 24 | `cuevik-ship:cleanup` | Gate, worktree + local branches, `ship-archive/<n>-<slug>` tag | DECISIONS §4 cleanup | ☐ |
| 25 | Tidy and release | Plugin READMEs; delete `DECISIONS.md`, `DRYRUN-01-03.md`, this file; delete `D:\vrp-repos\cs-kickstart` (Phase 14 is the last phase that reads it); tag `v0.1.0` | — | ☐ |

Source paths without a repo prefix are under `D:\vrp-repos\cs-kickstart\docs\guides\proj-init\`
(phases 02–14) or `D:\vrp-repos\cs-cueviksync\.claude\commands\` (phases 15–24).

---

## TODO after the current phases: existing-project mode

Not built, not scheduled. Running cuevik-start on a project that already has code ("reverse
engineering") needs its own design pass:

- Code cannot supply PRODUCT / PRD intent. The mode drafts from evidence (code, issues, docs), then
  interviews the owner to confirm or correct it.
- Keep-or-replace for an existing `CONTRIBUTING.md`, `README.md` and docs.
- Branch protection on a live repo with other contributors.
- Import existing issues for `07-backlog` instead of deriving every story fresh.
- Store the mode (`new` / `existing`) in `.cuevik/config.json` (a contract change).
- `00-bootstrap`, `01-product-concept` and `status` need rework for it.
