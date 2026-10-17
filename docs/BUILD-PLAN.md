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

Finish by giving me exact steps to test this command on cuevik-sandbox and on tx-QE4AIApps.
Plan first and wait for my approval before writing files.
```

---

## Conventions (every phase)

- **Layout:** `plugins/<plugin>/skills/<command>/SKILL.md`; supporting files beside it or in
  `plugins/<plugin>/references/`. Reference them as `${CLAUDE_PLUGIN_ROOT}/...` — Claude Code
  substitutes it inside skill content. Never write state under `${CLAUDE_PLUGIN_ROOT}`.
- **Workflow steps are user-invoked only.** Frontmatter keeps the model from auto-running a step
  (verify the exact key, e.g. `disable-model-invocation`, against the current skills docs in
  Phase 01 and record it here).
- **No hardcoded project facts.** Owner/repo from the git remote; board number and field IDs from
  `.cuevik/config.json`; worktree root from plugin `userConfig` (DECISIONS D15).
- **Shared contracts** (`.cuevik/config.json`, `.cuevik/lineage.json`) are defined once in
  `contracts/` and copied into each plugin that reads them; `scripts/check-contracts.*` fails on
  drift (same pattern as `vrp-cuevikflow-plugin/contracts/` + `scripts/test_contract.py`).
- **Wording:** "story", never "PBI" (D5). `gh` via the Bash tool, not PowerShell.
- **Gate:** every step checks the previous step's PR is `MERGED` before doing anything.

## Testing

- **Install once, from the local folder** (loads in place, no version pinning, and avoids
  `viralparikh-tx` needing access to the private repo):

  ```text
  /plugin marketplace add D:/vrp-repos/vrp-cuevik-plugins
  /plugin install cuevik-start@cuevik-plugins
  /plugin install cuevik-ship@cuevik-plugins
  ```

  `cuevik-docs` is enabled automatically as a dependency. Start a new Claude session after each
  phase so the changed skill is loaded.
- **Order:** `viralparikh-dev/cuevik-sandbox` first (throwaway), then `tx-QE4AIApps`.
- The phase branch must be checked out in `D:\vrp-repos\vrp-cuevik-plugins` while testing.

---

## Phases

Status: ☐ not started · ◐ in progress · ☑ merged

| # | Phase | Builds | Main sources | Status |
|---|---|---|---|---|
| 00 | Scaffold | `marketplace.json`, 3 `plugin.json`, `docs/` | — | ◐ (this PR) |
| 01 | Contracts | `contracts/config.json` + `contracts/lineage.json` (schema + example + README), `scripts/check-contracts`, skills frontmatter key confirmed | DECISIONS §3–§5, D15; `vrp-cuevikflow-plugin/contracts/` | ☐ |
| 02 | cuevik-start foundation | `references/`: runner (from `_run-step.md`), step registry (from `_steps.yml`, renumbered 00–08, 01 merged into 00), templates, `_writing-rules`, `_doc-references` | `cs-kickstart/docs/guides/proj-init/` | ☐ |
| 03 | `cuevik-start:00-bootstrap` | In-repo check (git repo, remote, `gh` auth), governance + `CONTRIBUTING.md` PR, auto-delete head branches, writes `.cuevik/config.json` + `.cuevik/lineage.json` | `00-bootstrap.md`, `01-repo-setup.md`, `bootstrap-target-repo.mjs` | ☐ |
| 04 | `cuevik-start:status` | Step progress from git + PR state | `doc-status.md` | ☐ |
| 05 | `cuevik-start:01-product-concept` | `docs/PRODUCT.md` | `02-prod-concept.md` | ☐ |
| 06 | `cuevik-start:02-product-requirements` | `docs/PRD.md` | `03-prod-requirements.md` | ☐ |
| 07 | `cuevik-start:03-architecture` | `docs/ARCHITECTURE.md` | `04-architecture.md` | ☐ |
| 08 | `cuevik-start:04-tech-stack` | `docs/TECH-STACK.md`, CONTRIBUTING tooling layer | `05-tech-stack.md` | ☐ |
| 09 | `cuevik-start:05-ai-tool-guide` | AI tool guide + adapters | `06-ai-tool-guide.md` | ☐ |
| 10 | `cuevik-start:06-readme` | `README.md` | `07-readme.md` | ☐ |
| 11 | `cuevik-start:07-backlog` | `docs/BACKLOG.md` (frozen-after-initiation header, D7), epics + stories with `epic`/`story`/`priority:*` labels (D5) | `08-backlog.md` | ☐ |
| 12 | `cuevik-start:08-finalize` | Strip INITIATION-ONLY fence from `CONTRIBUTING.md` | `09-finalize.md` | ☐ |
| 13 | `cuevik-start:cleanup` | Delete merged local `init/*` branches | `cleanup.md`, DECISIONS §3 | ☐ |
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
| 25 | Tidy and release | Plugin READMEs; delete `DECISIONS.md`, `DRYRUN-01-03.md`, this file; tag `v0.1.0` | — | ☐ |

Source paths without a repo prefix are under `D:\vrp-repos\cs-kickstart\docs\guides\proj-init\`
(phases 02–14) or `D:\vrp-repos\cs-cueviksync\.claude\commands\` (phases 15–24).
