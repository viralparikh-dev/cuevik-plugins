# Build log — phases 07–24 (temporary)

> **Temporary.** Record of the unattended build of BUILD-PLAN phases 07–24 on branch
> `build/phases-07-24`. Nobody approved a plan or ran a sandbox test during this run: every
> decision below was taken by the building session and every phase is built but untested (◐).
> Use this file to drive the live test pass, then delete it with the other design docs
> (Phase 25).

## Summary: riskiest untested assumption per phase

Filled in when the run ends.

## Setup

- Branch `build/phases-07-24` from `main` at `ce6e3c1`, pushed. The session was also told to use
  a harness branch (`claude/modest-mccarthy-i2ztyl`); the task named `build/phases-07-24`
  explicitly, so that is the branch used.
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
