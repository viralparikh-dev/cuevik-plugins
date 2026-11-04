# Design proposal — Task 9: Express lane `/cuevik-start:express` (item #4)

Status: **proposal for human review. Nothing implemented.** Depends on Task 8 (board-optional seam) and Task 2 (strawman entry ramp, PR open).

## Problem
The full path is nine gated steps and nine PRs. For an MVP or spike that is heavy. Offer a one-session, one-PR lean path reusing the existing step skills.

## Options considered
1. **`--express` flag on each step.** Touches every skill, spreads lane logic through all of them, easy to mis-gate.
2. **Separate orchestrator command `/cuevik-start:express`** (agreed in the plan). One new skill sequences lean variants of `00`, `01`, `02`, `07` in one session and one PR; existing step skills are reused, not forked.
3. **A second `steps.yml` profile** with the runner switching on profile. Cleanest data model, but changes runner semantics for all steps (gates, branch names) — larger blast radius.

## Chosen approach: option 2, with a small `lane` notion in config
- New skill `skills/express/SKILL.md` + command. Runs in a single session on one branch (proposed `init/express`), one PR to `main`, inter-step merge gates (runner §1 check 4) not applied; check 5 reads upstream docs from the working branch.
- **Produces:** lean bootstrap — repo, `.cuevik/config.json`, a reduced `.cuevik/lineage.json`, minimal `CONTRIBUTING.md` (no init-only branch table); lean `PRODUCT.md` (reusing `01`, strawman entry from Task 2 as the default ramp); lean `PRD.md` (reusing `02`); backlog issues (reusing `07`'s derive/file logic).
- **Skips:** `ARCHITECTURE`, `TECH-STACK`, `AI-TOOL-GUIDE`, `README`, `08-finalize` (so no finalize audit — consistent with Task 6), inter-step gates.
- **Board:** default `boardState: none` (issues only), no push (consumes Task 8). `07` must therefore not prompt in Express (add a `lane` input to its board branch from Task 5).
- Keep the two-altitude PRODUCT/PRD split.
- **Lean means fewer sections, not looser rules:** an `express` profile in each reused skill lists which template sections are mandatory; all `_writing-rules.md` constraints (RFC 2119, MoSCoW, measurability, no guessed numbers, trace-to-source) and reviewer checklists still apply to what is written.
- **Lineage:** record `lane: "express"` in config; lineage uses the same document slots (`docs/PRODUCT.md`, `docs/PRD.md`, `docs/BACKLOG.md`, `CONTRIBUTING.md`) with the missing documents simply absent. Graduation = running standard `03`–`06` later; the runner's gate checks must tolerate steps `00`–`02`/`07` having shipped via Express (not via their own `init/NN-*` PRs) — `status` needs an "express" mapping.

## Touch-list
New `skills/express/SKILL.md` · new command registration (plugin manifest/README) · `references/steps.yml` (express profile metadata, or a separate `express.yml`) · `references/runner.md` (lane-aware §1/§3 for the one-branch flow) · `references/contracts/config/*` (`lane` field) · `references/contracts/lineage/*` (reduced variant, schema allows absent docs) · `skills/01`, `02`, `07` (express profile hooks) · `skills/status/SKILL.md` · `plugins/cuevik-start/README.md`. New command ⇒ run `build_docs.py --write` in the implementing PR.

## Open questions
1. Branch name and commit granularity: one commit per lean document (reviewable) or one squashed?
2. Which sections are mandatory in the lean `PRODUCT.md`/`PRD.md`? Proposed starting point: PRODUCT = Overview, Target Users, Scope, Success Criteria; PRD = Functional Requirements, Out of Scope, acceptance criteria. Needs maintainer sign-off.
3. How does the standard `status`/runner recognize an Express repo mid-graduation (e.g. `04` start with no `03` merged and no `init/03-*` PR)? Needs a rule distinct from Task 4's relaxed gate.
4. Is the Product Owner/Architect two-role review model kept in a single PR, or reduced to one reviewer?
5. Does Express need its own reviewer checklist, or is the union of reused skills' checklists enough?
