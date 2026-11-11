---
name: 06-ai-tool-guide
description: Step 06 of cuevik-start. Run once 05-test-strategy's PR is open or merged, in a new session in the project folder. Asks which AI coding tools the team uses, then opens a PR adding docs/AI-TOOL-GUIDE.md (the one set of rules every AI tool follows), a thin adapter per tool (CLAUDE.md, .github/copilot-instructions.md, others on request) and, for Claude Code, the team's plugins in .claude/settings.json.
disable-model-invocation: true
---

# 06-ai-tool-guide

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/runner.md` — the workflow.
2. The `06-ai-tool-guide` entry in `${CLAUDE_PLUGIN_ROOT}/references/steps.yml` — branch,
   outputs, template, commit message, PR summary, special actions.
3. This file — what the guide, the adapters and the team plugin settings must contain.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 06-ai-tool-guide.` On conflict, precedence is runner > `steps.yml` > this file.

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding (brainstorming included) does not apply (runner, Skills).

`docs/AI-TOOL-GUIDE.md` is the single source of the rules AI tools follow on this project. Each
tool the team uses gets a thin adapter at the path that tool reads, pointing to the guide. Rules
live once, in the guide, so the tools cannot drift apart.

## What This Document Covers

The template (`AI-TOOL-GUIDE.template.md`) owns the headings and their order. This list owns what
each section must contain. Fill every section; add or drop none. The template's pre-filled
bullets in §8–§10 are defaults: keep each unless the operator changes it, and make it concrete
for this project.

1. **Project Context** — what the project is, its structure and its stack, in a few lines, with
   links to `ARCHITECTURE.md` and `TECH-STACK.md`: enough for a tool to orient.
2. **Coding Conventions** — naming, formatting and file-structure rules, consistent with
   `ARCHITECTURE.md` §5 and the formatter and linter in `TECH-STACK.md`.
3. **Scope Boundaries** — the files, directories and actions AI tools may and may not touch,
   named by path.
4. **Banned Patterns** — what AI must never generate, each with why: the anti-patterns and
   rejected alternatives in `ARCHITECTURE.md` §4 and `TECH-STACK.md` §5, and any tool not in
   `TECH-STACK.md`. Project-specific, not generic.
5. **Testing Rules** — how tests are written with the approved test tools, and what counts as a
   valid test, consistent with the levels and coverage target in `TEST-STRATEGY.md`.
6. **Documentation Rules** — when and how to comment, and which documents a change must update.
7. **Decision Escalation** — concrete scenarios where AI stops for approval: adding a package, a
   schema or migration change, auth code, a breaking API change, CI/CD or deployment config, and
   any project-specific ones. Each one a tool can check by itself, never "when in doubt".
8. **Agent Behavior Rules** — how agents operate: plan before execute, ask don't assume, scope
   discipline, stop and report, one change at a time, no invented scope, uncertainty stated.
9. **Off-Limits Boundaries** — files never touched without instruction, with this project's real
   paths: the lock files of the package manager in `TECH-STACK.md` (not a generic list), env and
   secret files, migrations, CI/CD config, auth code, dependency changes.
10. **Workflow Conventions** — branching, commits (`CONTRIBUTING.md`'s convention), PRs, pushing,
    breaking-change sign-off, and **Team plugins**: the plugins `.claude/settings.json` enables
    and any manual prerequisite (below), or `None`.

## Interview

At runner §4, read `docs/ARCHITECTURE.md`, `docs/TECH-STACK.md` and `docs/TEST-STRATEGY.md` from `main`, and
`CONTRIBUTING.md` for the commit convention and tooling commands. Then, in this order:

1. **Tools.** Run the first `steps.yml` special action: ask which AI tools the team uses, as an
   `AskUserQuestion` with `multiSelect: true` and options `Claude Code`, `GitHub Copilot`,
   `Another tool`. For each other tool, ask in chat for its name and the config path it reads
   (runner, Asking The Operator, typed values). Never assume a path for a tool you are not told.
2. **Guide.** Section by section in template order: draft from the upstream documents, each point
   marked with its source (`From ARCHITECTURE.md §4`), then ask what is missing or wrong, then
   `AskUserQuestion` `Approve <section>?` (`Yes` / `No`). Never invent a project rule; a section
   whose upstream gives nothing is asked as an open question.
3. **Adapters**, then **team plugins** (Claude Code only), below.

## Adapters

Generate an adapter only for each selected tool (`steps.yml` special actions):

| Tool | Adapter |
| --- | --- |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Another tool | the path the operator gave |

Each adapter has two layers:

1. **Pointer** — the guide is the source of the shared rules. `CLAUDE.md` imports it on its own
   line as `@docs/AI-TOOL-GUIDE.md`, which Claude Code loads with the file. Every other adapter
   says in one sentence that all shared rules are in `docs/AI-TOOL-GUIDE.md` and must be read
   first, with a repo-root link.
2. **Tool-specific settings** — only what has no equivalent in other tools (for example memory or
   tone settings for Claude Code, suggestion filters for Copilot), asked from the operator. None:
   the adapter is the pointer alone.

Never copy a rule from the guide into an adapter. An adapter file already on `main`: keep its
lines verbatim, add the pointer at the top, and show the diff for approval. Never copy the
cuevik-start runner or any plugin file into an adapter.

## Team plugins (Claude Code only)

Committing `.claude/settings.json` makes Claude Code offer the same plugins to everyone who opens
the repo. Run this only when Claude Code is selected; otherwise write no settings file and set
**Team plugins** in §10 to `None`.

1. Show the candidates in a table, then ask with `AskUserQuestion` `multiSelect: true` which to
   enable (more than four: offer the four most likely, take the rest through `Other`). Mark none
   `(Recommended)`.

   | Plugin | Marketplace repo | Does |
   | --- | --- | --- |
   | `superpowers` | `anthropics/claude-plugins-official` | Brainstorming, planning and TDD skills; cuevik-start already needs it |
   | `code-review` | `anthropics/claude-plugins-official` | Reviews a diff or PR |
   | `skill-creator` | `anthropics/claude-plugins-official` | Creates and tests skills |
   | `frontend-design` | `anthropics/claude-plugins-official` | Front-end design guidance |
   | `impeccable` | `pbakaus/impeccable` | Front-end design quality |
   | `taste-skill` | `leonxlnx/taste-skill` | UI taste guidance |

2. **This project's own marketplace.** Ask `Should teammates also get the Cuevik plugins (ship and
   docs) from this repo?` (`Yes` / `No`). On `Yes`, ask in chat for the marketplace's GitHub
   `owner/repo` (typed value). Never write it from memory: it is not in this plugin.
3. **Read each chosen marketplace.** The settings key is the marketplace's own `name`, and each
   plugin's name must exist in it. For each repo:
   `gh api repos/<owner>/<repo>/contents/.claude-plugin/marketplace.json --jq .content`, then
   decode the base64 to read `name` and `plugins[].name`. Unreadable, or the plugin is not
   listed: say so, drop that plugin, and report it in the PR body. Never guess a name.
4. **Write `.claude/settings.json`.** On `main` already: keep every other key and value, add only
   the missing entries, and show the diff. Otherwise:

   ```json
   {
     "extraKnownMarketplaces": {
       "<marketplace name>": {
         "source": { "source": "github", "repo": "<owner>/<repo>" }
       }
     },
     "enabledPlugins": {
       "<plugin>@<marketplace name>": true
     }
   }
   ```

   One `extraKnownMarketplaces` entry per marketplace, one `enabledPlugins` entry per plugin. No
   other keys: permissions, hooks and models are the team's to set.
5. **Manual prerequisites.** Ask `Does the team use graphify?` (`Yes` / `No`). graphify is not a
   plugin, so it cannot go in the settings file. On `Yes`, ask in chat where its install
   instructions are, and list it under **Team plugins** as a manual prerequisite with that link.
   Ask the same for any other non-plugin tool the operator names. Never write an install source
   from memory.

The claude.ai skills (documents, spreadsheets, PDFs) do not reach Claude Code users through this
file. If the operator asks, say so; it is not solved here.

## PR body

Follow runner §6. Besides the `prSummary` and the reviewer checklist below, list:

- **Adapters** — each file written, and its tool.
- **Team plugins** — each marketplace and plugin enabled, each dropped (with why), and each
  manual prerequisite; or `Claude Code not selected`.

## Reviewer checklist

Before approving the PR, verify every item. An unchecked item is a reason to request changes.

- [ ] `AI-TOOL-GUIDE.md` matches the template skeleton — header block, all ten sections in order,
      and the references table present; no top-level section added or removed, and no
      `[placeholder]` left unfilled.
- [ ] Every AI tool the team uses has an adapter, and no adapter exists for an unused tool.
- [ ] Scope boundaries and off-limits files name this project's real paths.
- [ ] Banned patterns are project-specific, tracing to `ARCHITECTURE.md` or `TECH-STACK.md`.
- [ ] Every escalation scenario is concrete enough for a tool to check by itself.
- [ ] Adapters hold the pointer and tool-specific settings only: no shared rule is repeated.
- [ ] `.claude/settings.json` (Claude Code only) holds only `extraKnownMarketplaces` and
      `enabledPlugins` entries the operator chose, each name read from its marketplace; manual
      prerequisites are listed in §10, not in the file.
