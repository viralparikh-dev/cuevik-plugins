---
name: audit
description: Audits a cuevik project's source-of-truth documents (the ones in .cuevik/lineage.json, plus AI tool adapters) in three lenses — Align (terms, goals, criteria that do not cohere; missing sections), Drift (documents contradicting each other, the files on disk or the lineage), Absorb (the same fact stated twice, and which copy is better) — and reports findings with exact fixes. Read-only unless given fix. Run when the user asks to audit the docs, or when a cuevik-ship step names it.
argument-hint: "[align|drift|absorb] [docs-only] [fix] [path]"
---

# audit

Reads the project's document set **once** and runs three independent lenses over it:

- **A — Align** — where terms, numbers, acceptance criteria, goals and scope do not cohere, and
  where a section is missing rather than wrong.
- **B — Drift** — where documents contradict each other, the files on disk, or a decision already
  taken.
- **C — Absorb** — where two files say the same thing twice, and which copy is better.

The letters are the run order. Align first: it settles the names, so the other passes find sharper
things. Absorb last: it is the only pass that proposes deleting text, and the least useful while
terms are unsettled.

The current folder is the project repo. Run every `gh` command through the Bash tool.

**Skills.** This command invokes no other skill. An instruction injected at session start to use
skills before responding does not apply.

**Read-only by default.** Without `fix` it writes nothing, commits nothing and changes nothing on
GitHub. A cuevik-ship step that runs it never passes `fix`.

A stale line in a document is not a typo: once code is written from it, it is a wrong
instruction. Ground truth is the **files on disk and git** plus the project's **lineage**
(`.cuevik/lineage.json`, contract
`${CLAUDE_PLUGIN_ROOT}/references/contracts/lineage/README.md`). Use them; never invent a third
source. Where code exists, it outranks prose about it.

## Arguments

`$ARGUMENTS` — optional, combinable:

- `align`, `drift` or `absorb` — run that pass only. None: all three, in that order.
- `docs-only` — skip §4B, the only part that probes the files on disk; judge prose against prose.
- `fix` — after the report, offer the **Safe** tier (§8) as a PR. Never applies an Approval-tier
  or Absorb finding.
- a path (e.g. `docs/PRD.md`) — only claims made by or about that file.

## 1. The corpus

Preflight: run from the repo root (`git rev-parse --show-prefix` empty). Read
`.cuevik/lineage.json` from the checkout; missing: stop — `No .cuevik/lineage.json. This audit
needs a project set up with /cuevik-start:00-bootstrap.`

Read every file below once, before reporting anything. Do not read source code except where Pass
B probes it.

1. **Lineage documents** — every `path` in the lineage, in lineage order (top of the graph first).
   A path missing from the checkout is a Pass B finding, unless its cuevik-start step has not
   merged yet (initiation in progress: say so and leave it out).
2. **AI tool adapters** — `CLAUDE.md`, `.github/copilot-instructions.md`, and any other adapter
   `docs/AI-TOOL-GUIDE.md` names, where present.
3. **Team settings** — `.claude/settings.json`, where present (Pass B probes it).

**Frozen documents** (`"frozen": true`, e.g. `docs/BACKLOG.md`) are records of a moment: check
that their citations resolve, never report them as drift against the current state. GitHub issues
are the backlog after initiation.

**Work folders.** `docs/ship/` never reaches `main`. If this checkout has `docs/ship/<n>-<slug>/`
(an issue's worktree), its files are transient: never authoritative, never audited for drift; a
lineage document wins wherever one disagrees. Pass B also lists remote `ship/*/issue` branches
(`git ls-remote --heads origin 'refs/heads/ship/*'`) whose issue is closed
(`gh issue view <n> --json state`): `/cuevik-ship:cleanup <n>` was not run.

Not the corpus: anything else under `docs/`, unless the operator names it as an argument.

## 2. Authority ladder — who wins when two files disagree

The lineage graph is the ladder: a document's `upstream` documents outrank it. Do not substitute
intuition for it.

1. **Files on disk and git.** A document claiming a file, folder or command exists loses to `ls`
   and the file itself. No exceptions.
2. **`CONTRIBUTING.md`** for governance: branching, commits, review flow, the tooling commands.
3. **Lineage documents among themselves**, by the graph: a fact loses to the document upstream of
   it. Scope loses to `PRODUCT.md`; a requirement or its number to `PRD.md`; a structural rule to
   `ARCHITECTURE.md`; a technology or version to `TECH-STACK.md`.
4. **`docs/AI-TOOL-GUIDE.md`** owns the shared rules for AI tools; an adapter holds only a pointer
   to it and tool-specific settings. A shared rule restated in an adapter is a duplicate (Pass C);
   one that contradicts the guide is drift.
5. **`README.md`** restates the documents above it and owns no fact of its own. It loses every tie.
6. **Work folders** — never authoritative.

Three exceptions, all deliberate:

- **Labelled pending is honest, not wrong.** A README section opening with `Pending scaffold —
  unverified`, and a tooling command reading `Not set yet`, say exactly what they are. Drift is a
  missing label, or a label claiming a check that did not happen.
- **A document specifying what is not built yet is not wrong.** Tell "the document lies about what
  exists" (a finding) from "the document specifies what should exist" (work: a GitHub issue, not
  this report). When unsure, say which reading you took.
- **The ladder ranks authority, not quality.** A lower file can hold a better explanation of a
  fact it does not own. That is an Absorb finding, and the fix runs upward (§5B). Never delete the
  better explanation because of where it lives.

---

## PASS A — Align

_Skipped under `drift` or `absorb`. Judges coherence and completeness, not truth._

### 3A. Terminology — `PRODUCT.md` is canon

The first use of a term in `docs/PRODUCT.md` is its canonical form, and `README.md` Key Concepts
must match it. Extract the concept nouns `PRODUCT.md` defines (target users, core entities, named
roles and components), `grep -i` each across the corpus, and report each cluster with its surface
forms, counts and `file:line` for the minority forms.

Three outcomes, not interchangeable:

- **Cosmetic variant** — same concept, different spelling or hyphenation. Low; a hyphenated
  compound modifier is correct, not a defect.
- **Competing term** — a second word for the same thing. Medium to High: a reader cannot tell a
  synonym from a separate entity.
- **No anchor** — a term `PRODUCT.md` never uses. Report it **unresolved** and name who decides
  (the Product Owner); never invent a canon.

### 3B. Requirements, numbers and acceptance criteria

- Every `PRODUCT.md` success criterion maps to at least one `PRD-NNN`. An unmapped criterion is a
  goal nobody is building towards.
- Every `PRD-NNN` has an acceptance criterion (§8 row, or an NFR's own number), and it is
  testable: a number, a state or an observable behaviour. "Fast", "intuitive", "reliable" are
  findings.
- **Every requirement ID cited anywhere resolves** to a requirement in `PRD.md`, struck-through
  retired ones included. A citation to a missing or renumbered ID is worse than a broken link: it
  reads as verified.
- A number stated in two files with two values (a target, a limit, a retention period, a version)
  is High impact by default.
- An acceptance criterion satisfiable by a mechanism `ARCHITECTURE.md` forbids (for example an
  application-layer check where it requires enforcement elsewhere) is **P0**: it authorizes what
  the architecture rules out.

### 3C. Missing sections

Pass B compares only what exists; gaps are caught here. Report each as **MISSING**, with the file
that should own the new section.

- A requirement with no acceptance criterion.
- A document listed as `Downstream` of another that never reflects the upstream fact.
- A banned pattern in `AI-TOOL-GUIDE.md` with no decision behind it in `ARCHITECTURE.md` or
  `TECH-STACK.md`.
- A command in the `CONTRIBUTING.md` tooling layer whose tool is not in `TECH-STACK.md`, or a tool
  in `TECH-STACK.md` with no way to invoke it.
- A deferred or blocked decision with no named decider and nothing stated that unblocks it.
- An explicitly unfinished block that is now overdue, e.g. the `DEVELOPMENT-PHASE-GOVERNANCE`
  stub in `CONTRIBUTING.md` once development has started.

### 3D. Goals vs scope vs mechanism

Walk `PRODUCT.md` goals → `PRD.md` scope → `ARCHITECTURE.md` mechanism → `TECH-STACK.md` tools.
Flag a goal with no mechanism; a mechanism serving no goal (usually crept scope); `PRD.md` scope
contradicting `PRODUCT.md` Scope Out; a user-facing claim in `README.md` or `PRODUCT.md` the
current scope cannot support. Phrase the last as the user would experience it.

### 3E. Impact

Every finding in any pass carries a second rating, independent of P0–P2:

- **High** — an engineer builds the wrong thing from it, or a user meets a false promise.
- **Medium** — costs review time, causes rework, or forces a reader to guess.
- **Low** — cosmetic; no decision changes.

State impact as a consequence ("the scaffold will use the database the architecture rejected"),
not a category ("database inconsistency").

### 3F. Next steps

Close Pass A with three lists, each usable without re-reading the report:

- **Checks to run** — the command, and what a pass would prove.
- **Who decides** — for every unresolved item, the role. Product decisions are not coding tasks;
  say so rather than proposing a default.
- **Replacement text** — for each High finding, the exact sentence to drop in.

---

## PASS B — Drift

_Skipped under `align` or `absorb`._

### 4A. Document vs document

For each fact class, extract every statement across the corpus and compare:

- **Lineage headers.** Each document's `Owner`, `Derived from` and `Downstream` lines match
  `.cuevik/lineage.json` (downstream derived by following `upstream` links). A header that
  disagrees with the lineage is a finding against the header.
- **Document References tables.** Every copy is injected from one source, so all copies must be
  identical; one edited by hand is a finding.
- **The command surface.** The `CONTRIBUTING.md` tooling layer vs `README.md` Install & Run and
  Run Tests vs commands named in `AI-TOOL-GUIDE.md` and adapters. A command used anywhere but
  absent from the tooling layer is a finding against the tooling layer.
- **Stack and versions.** `TECH-STACK.md` owns them; a version stated elsewhere that differs
  loses.
- **Banned patterns and off-limits paths** in `AI-TOOL-GUIDE.md` vs what `.claude/settings.json`
  (or another tool's config) enforces. A rule stated but not machine-enforced is not a defect; a
  rule claimed to be enforced that is not, is.
- **Governance.** Branch names, commit convention, the never-push-to-`main` rule, the review gate:
  `CONTRIBUTING.md` owns them.
- **Cross-references.** Every relative link and every `§` or `PRD-NNN` citation: the target exists
  and says what the citing file claims.

### 4B. Document vs reality _(skipped under `docs-only`)_

Each probe turns a prose claim into a command; the output wins.

| Claim in prose | Probe |
| --- | --- |
| A folder exists (README Project Structure) | `ls` it; `(planned)` entries are claims about the future, not findings |
| A script or command exists | read the manifest that defines it (the package manager's file named in `TECH-STACK.md`); none yet means every such claim is unverified |
| Env example keys match the README table | read the env example file, never the real env file |
| Database migrations named or counted | list the migrations folder `ARCHITECTURE.md` or `TECH-STACK.md` names |
| Rules are machine-enforced | the claimed patterns really are in `.claude/settings.json` (`permissions`, `hooks`) |
| A CI gate exists | `.github/workflows/` (or the CI config `TECH-STACK.md` names) |
| A relative link resolves | resolve every `](` path against the files on disk |
| `Last updated` is honest | `git log -1 --format=%ad --date=short -- <file>` vs the stamp in the file |
| Team plugins | each `enabledPlugins` entry in `.claude/settings.json` has its marketplace in `extraKnownMarketplaces`, and `AI-TOOL-GUIDE.md` §10 lists the same plugins |

**Date staleness.** A `Last updated` stamp older than the last commit touching its file is a
finding of its own.

**Decisions taken but not written down.** A decision acted on in the repo while the documents
still describe the superseded option is the highest-value Pass B finding, and the one no check
catches. Where you can identify one, name the decision, the file that still contradicts it, and
the evidence (commit, PR, merged code).

---

## PASS C — Absorb

_Skipped under `align` or `drift`. The only pass that proposes deletions; none of its output is
ever applied by this command._

### 5A. Find the duplicates

Pass B finds files that disagree. This finds files that agree, which is its own defect: two copies
of one fact drift on the next edit, when only one gets updated.

For each fact class in §4A: how many files state it, against the one that owns it (§2)? Flag any
fact stated substantively in two or more places. The usual sources are `README.md` restating
`docs/`, and an adapter restating `AI-TOOL-GUIDE.md`.

A one-line pointer with a link is the correct pattern, not a duplicate. The test: could a reader
act on the copy alone? If yes, it is a duplicate and will drift.

### 5B. Compare quality, not position

For each duplicate cluster, judge which copy is better on completeness (the edge case, the
failure mode), the why (the reason travels with the rule), currency, and precision (names the
mechanism).

The better copy often sits in the lower-authority file, because READMEs and adapters get
rewritten more often. Then the fix is a **merge upward**: move the better content into the owner
and reduce the copy to a one-line pointer. Ruling the richer text wrong because of where it sits
destroys the best explanation in the repo, which is what this pass exists to prevent.

### 5C. Work folders

Only when this checkout has `docs/ship/<n>-<slug>/`: per section, is it absorbed into the lineage
document it fed, partly absorbed, or not yet? Flag the reverse too: a work-folder section
contradicting what landed. The landed document wins; the work file needs a note before anyone
reads it as current. Never propose deleting a work folder: `/cuevik-ship:cleanup` owns that.

Removing text from a document means removing every reference to it (links, `Derived from` /
`Downstream` lines) in the same change. Propose both halves or neither.

---

## 7. Report

One report in chat, sectioned by pass, A → B → C. Within a section, order by blast radius: a wrong
instruction outranks a wrong description. No file is written.

Two axes, both stated; a finding can be P2 / High or P0 / Low:

- **Correctness** — P0: contradicts the files on disk or a non-negotiable rule, or would produce
  wrong code or a wrong scaffold if followed. P1: factual drift a developer would act on. P2:
  cosmetic.
- **Impact** — High / Medium / Low (§3E), stated as a consequence.

Per finding, exactly:

```text
[B-P0 · High] <one-line claim in conflict>
  Says X:  path/to/file.md:LINE — "<quote>"
  Says Y:  path/to/other:LINE — "<quote>"
  Ruling:  <which is authoritative, and which ladder rung says so>
  Impact:  <what goes wrong for an engineer or a user, concretely>
  Fix:     <the exact replacement text>
  Tier:    Safe | Approval
```

Prefix with the pass: `A-`, `B-`, `C-`. Pass A gaps use `MISSING` instead of a priority; Pass C
findings use `DUPLICATE`, `MERGE-UP` or `ABSORBED`.

End with: findings by pass and priority; **files audited vs files in the corpus**, naming any
skipped; the three Pass A lists (§3F); a one-line recommended fix order; and, for each
Approval-tier fix, the command that makes it: `/cuevik-docs:update <document>`.

A report that silently covered less than it claims is the same defect as the documents it audits.

## 8. Fixes — two tiers

**Safe** — a broken relative link, a stale `Last updated` stamp, or a `README.md` edit where the
README provably restates an owner and the fix copies the owner's wording (README owns nothing, so
this is transcription, not a decision).

**Approval** — everything else: any other edit to a lineage document, `CONTRIBUTING.md`, an
adapter or `.claude/`; every terminology change; every Pass C finding. These go through
`/cuevik-docs:update`, one document per PR, with its downstream checklist. This command never
makes them.

Under `fix` only, after the report: list the Safe fixes as a diff and ask `Open a PR with these
<N> safe fixes?` (`Yes` / `No`) with `AskUserQuestion`. On `Yes`: from a clean, up-to-date `main`,
branch `docs/audit-fixes-<YYYY-MM-DD>`, apply them, commit
`docs: apply safe audit fixes`, push, and open a PR to `main`. Its body lists each fix and its
finding. Without `fix`, Safe fixes are reported like the rest.

## Never

- Read, print or quote a real env file (`.env`, `.env.*` other than the example).
- Edit a lineage document, `CONTRIBUTING.md` or an adapter outside the `fix` Safe tier.
- Edit a database migration already committed: a wrong applied migration is fixed by a new one.
- Rewrite a document to match the code when the document specifies work not done yet: that erases
  the requirement. Report it as work for a GitHub issue.
- Treat a work-folder file as authoritative over a lineage document.
- Treat a labelled pending block or `Not set yet` command as drift; a missing label is the
  finding.
- Discard the better explanation because it sits in the lower-authority file. Merge it upward.
- Pick a canonical term with no `PRODUCT.md` precedent. Report it unresolved and name the decider.
- Edit a memory file of any AI tool. Report the conflict; the user owns it.
- Resolve a contradiction by inventing a third answer. If neither side can be verified from the
  files or the lineage, report it unresolved.
