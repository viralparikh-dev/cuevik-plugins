# cuevik-start — Product & Architecture Usage Review

**Reviewer lens:** Senior Product Owner + Enterprise Product Architect
**Date:** 2026-11-01 · **Scope:** `cuevik-start` v0.2.0, all `/cuevik-start:*` commands
**Basis:** the plugin source (runner, steps.yml, 11 skills, templates, roles, contracts), read end to end. Siblings `cuevik-ship` and `cuevik-docs` consulted only to fix suite boundaries.

---

## 1. Executive Summary

`cuevik-start` is a well-engineered, genuinely governed project-initiation framework: nine gated steps (`00`–`08`) plus `status` and `cleanup` take an empty repo to seven source-of-truth documents, a wired GitHub Projects board, AI-tool config, and a filed backlog — each landed by its own reviewed PR. The internal engineering is strong and above the bar for a solo/small-team tool: a clean layer split (runner owns workflow, `steps.yml` owns metadata, each `SKILL.md` owns content, `lineage.json` owns the document graph, templates own structure), disciplined anti-hallucination rules (no guessed numbers, no guessed versions, trace-to-source, attack rounds), honest `STOP` conditions, and idempotent re-runs.

The problem is not the artifacts. Each document largely earns its place and the framework works hard to prevent the duplication it warns against. The problem is the **process weight**: nine sequential steps, one step per session, each refusing to run until the previous step's PR is *merged*, produce a strictly serialized waterfall of ~9 sessions and ~9 PRs before the project has a line of code or a validated assumption. A framework whose stated goal includes "accelerate delivery" measurably decelerates the first-code milestone.

**Two honest verdicts, because the framework has two stated goals** (per the owner's own record: team use first, job-hunting showcase second):

- **As a working tool for a small team / solo owner:** over-engineered for the common case. Right content, too many gates, no lean lane.
- **As a reusable standard + portfolio artifact:** largely justified. Completeness and visible rigor *are* the value, and the engineering quality carries the demonstration.

The fix is not to cut documents. It is to (a) add an express lane for small projects, (b) relax inter-step serialization where the reviewing role does not change, (c) wire the existing `cuevik-docs:audit` in as a finalize-time consistency gate, and (d) close the product-discovery and test-strategy gaps — the latter being conspicuous given the owner's QE background.

**Determination: Over-Documented as a default delivery path; Balanced as a reusable standard.** Reasons in §14.

---

## 2. Overall Assessment Scores

Each command, 1–10, ten dimensions. Composite is the rounded mean. Outliers explained below the table; I did not pad 110 paragraphs.

| Command | Biz | Prod | Eng | Deliv | Decis | Risk | Adopt | Maint | Reuse | ROI | **Comp** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `00-bootstrap` | 8 | 6 | 9 | 7 | 5 | 8 | 6 | **3** | 9 | 7 | **6.8** |
| `01-product-concept` | 8 | 9 | 5 | 6 | 8 | 7 | 6 | 8 | 8 | 7 | **7.2** |
| `02-product-requirements` | 8 | 9 | 7 | 8 | 9 | 8 | 5 | 7 | 8 | 8 | **7.7** |
| `03-architecture` | 7 | 6 | 9 | 7 | 9 | 8 | 5 | 7 | 7 | 7 | **7.2** |
| `04-tech-stack` | 6 | 4 | 8 | 7 | 8 | 7 | 6 | 6 | 7 | 7 | **6.6** |
| `05-ai-tool-guide` | 7 | 6 | 8 | 7 | 7 | 7 | 8 | 8 | 9 | 8 | **7.5** |
| `06-readme` | 5 | 4 | 5 | 5 | 3 | 4 | 6 | 5 | 6 | 4 | **4.7** |
| `07-backlog` | 7 | 7 | 7 | 8 | 6 | 5 | 7 | 6 | 7 | 7 | **6.7** |
| `08-finalize` | 5 | 4 | 6 | 5 | 4 | 6 | 7 | 8 | 7 | 6 | **5.8** |
| `status` | 6 | 5 | 9 | 7 | 7 | 7 | 9 | 7 | 9 | 9 | **7.5** |
| `cleanup` | 4 | 3 | 7 | 4 | 3 | 6 | 7 | 7 | 7 | 6 | **5.4** |

**Score explanations (outliers only):**

- **`00-bootstrap` Maintainability = 3.** The single biggest liability in the plugin. It drives GitHub Projects v2 through pages of brittle GraphQL, depends on seven board workflows the API *cannot* toggle (manual operator steps), can't read workflow internals through the API (so it guides blind), and flags user-board/org-repo as untested. If GitHub changes Projects v2, `00` breaks and nothing else can run. High leverage, high reuse — but the framework's fragility is concentrated here.
- **`02` is the top composite (7.7).** It is the spine: every downstream doc and every backlog issue traces to a `PRD-NNN`. Decision support and risk reduction are highest here (attack rounds, measurable acceptance). Adoption scores low (5) because it is the heaviest step (LG / 12h, section-by-section attack) — valuable but draining.
- **`05-ai-tool-guide` (7.5)** is the most novel and the best-designed for low maintenance: one rule source, thin pointer adapters per tool, no rule duplication. Highest reuse in the set.
- **`status` (7.5)** is a pure automation win — free, read-only, always useful, and already the model for where the rest of the framework should head.
- **`06-readme` is the weakest (4.7).** In docs-first mode (the mode initiation usually hits), it is mostly "Pending scaffold — unverified" markers. A README full of untested instructions rots the fastest and helps the least until code exists.
- **`08-finalize` (5.8) and `cleanup` (5.4)** are low value but **correctly sized** (XS/housekeeping) and safely implemented (block-delete by marker, safe branch deletion by `headRefOid`). Low score is not a criticism; they are cheap and honest.

---

## 3. Highest-Value Commands

1. **`02-product-requirements`** — the testable-requirements spine. Everything coheres because this exists and is traced.
2. **`05-ai-tool-guide`** — novel, low-overhead, high-reuse; single source + thin adapters is the right pattern and the easiest to keep current.
3. **`status`** — automation done right; zero maintenance of generated output, immediate value any time.
4. **`00-bootstrap`** — highest leverage (it creates the whole governed environment) despite being the most fragile.

## 4. Lowest-Value Commands

1. **`06-readme` in docs-first mode** — pending-markers document; value deferred until scaffold.
2. **`cleanup`** — necessary hygiene, but low intrinsic value.
3. **`07-backlog`'s *document*** (not the step) — `BACKLOG.md` is explicitly frozen the moment it is filed; GitHub becomes the backlog. The doc is a receipt, not a living artifact.

---

## 5. Missing Capabilities

Scoped to what `cuevik-start` (initiation) should cover, crediting the suite boundary where a sibling owns it.

- **Product discovery / riskiest-assumption validation.** `PRODUCT.md` captures vision/problem/users but there is no artifact for assumptions-to-test, hypotheses, or a validation plan. For a Product Owner this is the largest gap: the framework jumps from "what we believe" to "testable requirements" with no "what we must prove first."
- **Stakeholder map / product strategy horizon.** No stakeholder alignment artifact, no roadmap/strategy band beyond the current release. Vision is present; strategy is thin.
- **Test strategy / QA.** Only `AI-TOOL-GUIDE §5` ("testing rules") and the test tool in `TECH-STACK`. No test-levels / coverage-target / environment-strategy artifact. Conspicuous given the owner's QE domain — this is the most on-brand gap to close.
- **Domain model / DDD.** `ARCHITECTURE §2` (data design) is adjacent but there is no bounded-context / ubiquitous-language artifact. Fine to skip for small projects; name the decision rather than leave it implicit.
- **Delivery / CI-CD / observability / operational readiness.** Deliberately out of scope — `08-finalize` refuses to write dev-phase policy and hands off to the team, and `cuevik-ship` owns the delivery loop. **But** even `cuevik-ship` (idea→code PR) does not obviously set up CI/CD, release, or observability. That is a *suite-level* gap, not a `cuevik-start` bug; flag it so it is an explicit decision, not an accident.

## 6. Major Gaps

1. **No lean lane.** The framework has one path and it is the maximal one. There is no "small project / MVP / spike" mode. This is the gap that makes the 2-hour test (§13) unpassable.
2. **Enforced serialization.** One step per session + previous PR must be *merged* forces calendar-serial initiation even where the thinking could be parallel and the reviewer is the same person.
3. **Half the framework is unrun.** The plugin's own README states `03`–`08` and `cleanup` are built but not yet run live. More than half the steps are unverified in practice — a real adoption and correctness risk, not a documentation nit.
4. **Docs-first artifacts are speculative until code lands.** `ARCHITECTURE`, `TECH-STACK`, and the `README` setup sections are explicitly "unverified" at initiation. Drift risk is highest the day code starts — which is exactly what `cuevik-docs:audit` is for, but nothing in `cuevik-start` triggers it.

---

## 7. Redundant Artifacts

The framework actively fights duplication (trace rules, "summarize don't restate," the injected reference map, reviewer checklists that reject verbatim overlap). Residual redundancy risk:

- **`PRODUCT.md` ↔ `PRD.md`** overlap on users / problems / features. The discipline mitigates it; the reader still reasonably asks "why two." Keep both — the abstraction boundary is real (value vs. testable behaviour) — but this is the pair to watch.
- **`03` ↔ `04`** are so tightly cross-deferred (03 defers products down to 04; 04 defers structure up to 03) that two sessions and two PRs create ceremony around what is one coherent design conversation. Not redundant *content*; redundant *process*.

## 8. High-Maintenance / Low-ROI Artifacts

- **The `00-bootstrap` GitHub Projects v2 surface** — highest maintenance in the plugin (see §2). Low ROI per line of that GraphQL relative to its breakage risk.
- **`BACKLOG.md`** — frozen receipt; do not treat as living. Low maintenance only if nobody edits it (the design already says so — enforce it).
- **Version pins in `TECH-STACK.md`** — rot by nature. Acceptable (they are decisions-at-a-time and `cuevik-docs:update` owns revision), but it is the artifact most guaranteed to go stale.

---

## 9. Commands to Add

1. **Express / MVP lane** (`/cuevik-start:express` or a flag) — one session, three lean artifacts (PRODUCT-lite, a thin ARCHITECTURE+stack note, backlog issues), one PR. Directly answers the 2-hour test and gives small projects a reason to adopt. **Highest-ROI addition.**
2. **A discovery / riskiest-assumptions artifact** — either a new `00.5` or a section in `01`. Closes the biggest Product gap for little weight.
3. **A lightweight test-strategy artifact** — levels, coverage target, env strategy. On-brand; can be an `ARCHITECTURE` addendum rather than a full step.

*Do not build a drift-audit command — it already exists as `cuevik-docs:audit` (three lenses: Align / Drift / Absorb) and is well-designed. See §13.*

## 10. Commands to Improve

- **`01-product-concept`** — it is the only pure blank-page interview. Let it draft a strawman from a one-paragraph pitch and have the operator *correct* rather than originate. Every later step already does "draft then challenge"; `01` should too.
- **`06-readme`** — make it conditional/deferrable. In docs-first mode, emit a minimal stub and defer the real README to when code lands (or fold it into `cuevik-ship`'s first scaffold). Stop producing a document that is mostly unverified markers.
- **`00-bootstrap`** — extract the Projects v2 setup behind a thinner, testable seam and degrade gracefully when the board/workflows cannot be configured, so a project can still be governed by PRs even if the board is partial. Reduce the single largest fragility.
- **`07-backlog`** — keep the issue-filing; demote `BACKLOG.md` to a clearly-generated snapshot (it already is frozen — label and treat it as a build artifact, not a maintained doc).

## 11. Commands to Merge

- **`03-architecture` + `04-tech-stack`** — keep the two *documents* (the abstraction split is correct) but allow them in **one session** and relax the merge-gate between them. They are one design conversation; forcing two merged PRs is the clearest process over-engineering.
- Consider letting **`05`→`06`** run in one session for the same reason (neither changes the reviewing role meaningfully in a solo context).

## 12. Commands to Remove

None outright — every command serves a real purpose and the two weakest (`08`, `cleanup`) are cheap and correct. The only thing to "remove" is **treatment**, not a command: stop treating `BACKLOG.md` as a living document.

---

## 13. AI Automation Opportunities

This is where the framework most under-delivers on its own premise — nearly every step is a human interview. In ranked order:

1. **Finalize-time consistency gate.** Wire the existing `cuevik-docs:audit` into `08-finalize` (read-only, no `fix`) so initiation ends with a proven-coherent document set instead of a hope. Zero new code — it is a call to a sibling that already exists.
2. **Near-one-shot backlog.** `07` is already almost deterministic (epics = PRD §6 subsections, stories = requirements, criteria copied verbatim). Automate the derivation fully; interview only NFR priorities. This step should be a review-and-confirm, not an interview.
3. **Strawman drafts everywhere, especially `01`.** Generate a first-pass from a short pitch + any existing repo signals; the operator corrects. Shifts human effort from origination to judgment.
4. **A pitch-to-skeleton bootstrap for the express lane** — one paragraph in, draft PRODUCT + thin design + backlog out, for correction.

`status` is already the right shape; nothing to automate there.

---

## 14. Recommended Future-State Architecture

Keep the engine — the layer split, lineage graph, trace discipline, and anti-hallucination rules are the framework's genuine moat; do not touch them.

- **Two lanes, one engine.** A **Standard lane** (today's 9 steps, for projects that warrant it) and an **Express lane** (one-to-three artifacts, one session, one PR, for MVPs/spikes/small teams). Same templates and rules, fewer gates.
- **Relax serialization within a role.** Allow `03+04` (and optionally `05+06`) in one session; keep the merge-gate only where the reviewing role or the risk actually changes.
- **Close the two content gaps** — a discovery/assumptions artifact and a lean test-strategy artifact — without adding full gated steps (sections or optional addenda).
- **Audit as a gate, not an afterthought.** `08-finalize` runs `cuevik-docs:audit` (read-only) before it hands off. Initiation is "done" only when the set is coherent.
- **Harden `00`.** Thin, testable seam around Projects v2; graceful degradation so PR governance survives a partial board.
- **Push automation** — strawman-first drafting, one-shot backlog derivation — so human time goes to challenge and judgment, which is where the framework's value actually is.

**Artifact classification (ROI basis):**

| Class | Artifacts |
|---|---|
| **Critical** | `PRD.md`; `PRODUCT.md`; the filed GitHub issues (07's real output); `.cuevik/config.json` + `lineage.json` (the graph that makes everything cohere); `CONTRIBUTING.md` governance layer |
| **Valuable** | `ARCHITECTURE.md`; `TECH-STACK.md`; `AI-TOOL-GUIDE.md` + adapters |
| **Optional** | `README.md` (docs-first); `DEVELOPMENT-PHASE` stub; initiation issues/board scaffolding |
| **Waste (as treated)** | `BACKLOG.md` as a *living* doc — keep as a generated frozen snapshot only |

**80/20 — the 2-hour new-project test:**

- **Must Have (the 20% → 80% of value):** PRODUCT core (vision, problem, users, scope), PRD core (requirements + acceptance criteria), backlog issues.
- **Should Have:** ARCHITECTURE, TECH-STACK.
- **Nice to Have:** AI-TOOL-GUIDE, README.
- **Drop from a 2-hour start:** the 9-session serialization, the `08` ceremony, `BACKLOG.md`-as-doc.
- **Result:** cuevik-start **cannot** do a 2-hour start today — it is a multi-day, multi-PR process. That is the single most actionable finding, and the express lane (§9.1) is the answer.

---

## 15. Final Verdict

`cuevik-start` is the work of someone who understands governance and clean plugin architecture. The engineering is real, the anti-hallucination discipline is better than most commercial tooling, and the honesty (explicit STOPs, "unverified" markers, no invented policy) is a credit. Judged as a reusable standard and a portfolio piece, it is justified and impressive.

Judged as the default way a small team or a solo owner should start a real project, it is **over-documented in process, not in content**. The documents mostly earn their place; the nine-gate serial waterfall does not, and the absence of a lean lane plus the fact that half the steps have never run live are the risks that will actually bite adoption.

**Do these four, in order:** (1) add the express lane; (2) relax `03+04` serialization; (3) wire `cuevik-docs:audit` into `08-finalize`; (4) run `03`–`08` live once and fix what breaks. None requires touching the engine, and together they turn a rigorous demo into a tool a busy team would actually pick up.

**Over-Documented as a default path · Balanced as a standard. Each artifact justified its existence; the sequencing did not.**
