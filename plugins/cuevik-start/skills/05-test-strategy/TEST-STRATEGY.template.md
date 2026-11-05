# TEST-STRATEGY.md — Test Strategy

**Owner:** [owner — from .cuevik/lineage.json]\
**Last updated:** [YYYY-MM-DD]\
**Source of truth for:** [one line — how the product is verified: test levels, coverage target, environments and data, NFR verification, quality ownership and defect handling]

> Derived from: [upstream documents — from .cuevik/lineage.json]\
> Downstream: [downstream documents — derived from .cuevik/lineage.json]

<!-- @inject: _doc-references.md -->

---

## 1. Test Levels

[Each level of testing in use, what it covers, and the requirements it verifies. Every Must
requirement in PRD.md §6 maps to at least one level.]

| Level | What it covers | PRD requirements verified |
| --- | --- | --- |
| [level] | [scope of the level, tied to an ARCHITECTURE.md component or integration] | [PRD-00N] |

## 2. Coverage Target

[The measure, its target and what it applies to. Every number comes from the operator.]

| Measure | Target | Applies to |
| --- | --- | --- |
| [what is measured] | [target, from the operator] | [level or code area] |

## 3. Test Environment & Data

[Where tests run and where their data comes from.]

| Environment | Used for | Data source |
| --- | --- | --- |
| [environment] | [which levels run here] | [where its test data comes from] |

## 4. NFR Verification

[How each non-functional requirement in PRD.md §7 is verified. The threshold is the PRD's own,
copied; never a new number.]

| PRD requirement | Verification method | Level | Pass threshold |
| --- | --- | --- | --- |
| [PRD-00N] | [how it is checked] | [level from §1] | [the PRD's number] |

## 5. Quality Ownership

[Who is accountable for each level and for this strategy. Roles, not accounts.]

| Area | Accountable role |
| --- | --- |
| [level or this document] | [role] |

## 6. Defect Management

[How defects are classified, triaged and tracked.]

- **Classification:** [the severity or priority scheme, if any]
- **Triage:** [who triages, and when]
- **Tracking:** [where defects are tracked and how they are labelled]
- **Targets:** [any response or fix target, with its number from the operator]
