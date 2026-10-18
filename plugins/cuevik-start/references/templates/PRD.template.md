# PRD.md — Product Requirements Document

**Owner:** [owner — from .cuevik/lineage.json]\
**Last updated:** [YYYY-MM-DD]\
**Source of truth for:** [one line — the testable requirements for this release]

> Derived from: [upstream documents — from .cuevik/lineage.json]\
> Downstream: [downstream documents — derived from .cuevik/lineage.json]

<!-- @inject: _doc-references.md -->

---

## Contents

1. [Overview](#1-overview)
2. [Target Users](#2-target-users)
3. [Problem Statements](#3-problem-statements)
4. [Features / Capabilities](#4-features--capabilities)
5. [User Stories](#5-user-stories)
6. [Functional Requirements](#6-functional-requirements)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [Acceptance Criteria](#8-acceptance-criteria)
9. [Out of Scope (This Release)](#9-out-of-scope-this-release)
10. [Dependencies & Assumptions](#10-dependencies--assumptions)
11. [Constraints (Non-Architectural)](#11-constraints-non-architectural)
12. [Risks & Edge Cases](#12-risks--edge-cases)

---

## 1. Overview

[What the product is, why it exists, and its core goals — a concise reference
anchored to PRODUCT.md. Summarize; don't restate the narrative.]

## 2. Target Users

[Who the product is for — the personas/usage contexts from PRODUCT.md §2,
refined for requirement clarity. Reference, don't re-describe.]

- [Persona / usage context] — [the need this release addresses]

## 3. Problem Statements

[The specific problems being solved — drawn from PRODUCT.md's Problem Statement,
sharpened per user need. Every feature must trace to one of these. Summarize,
don't restate.]

- [Problem statement — the user need it reflects]

## 4. Features / Capabilities

[The discrete things the product does, expanded from PRODUCT.md, each described
in terms of user value.]

- [Feature name] — [what it does and the value it delivers]

## 5. User Stories

[Every feature maps to at least one story.]

- As a [user], I want [action] so that [outcome].

## 6. Functional Requirements

Group requirements under a subsection per capability (mirroring §4). Each requirement
is a single bullet: **bold ID**, then a ***bold-italic title***, then an *italic
MoSCoW priority* (Must / Should / Could), then 2–3 sentences of exact behaviour.
Every requirement has a unique ID; state what the system MUST / SHOULD do, never how.

### [Capability group — from §4]

- **PRD-001** — ***[requirement title]*** *(Must)* — [The exact system behaviour,
  rule, or workflow, in 2–3 sentences. No implementation, architecture, or stack
  detail.]

## 7. Non-Functional Requirements

[Measurable quality attributes — performance, security, scalability,
availability, compliance. State numbers, not adjectives. These are
requirements, not solutions.]

- [Attribute] — [measurable target, e.g. "p95 response < 200 ms"]

## 8. Acceptance Criteria

[Testable conditions defining when each requirement is done. Reference the
requirement ID.]

| Requirement ID | Acceptance criteria |
| --- | --- |
| PRD-001 | [testable condition that proves the requirement is met] |

## 9. Out of Scope (This Release)

[Explicit feature- and requirement-level exclusions for this version.]

- [Excluded item] — [why it is out for this release]

## 10. Dependencies & Assumptions

[External systems, services, integrations, teams, and conditions assumed true.]

- [Dependency or assumption] — [impact if it does not hold]

## 11. Constraints (Non-Architectural)

[Business, legal, regulatory, or operational limits that shape requirements
without dictating design.]

- [Constraint] — [what it limits]

## 12. Risks & Edge Cases

[Known uncertainties, failure scenarios, and atypical behaviours to handle.]

| Risk / edge case | Impact | Handling |
| --- | --- | --- |
| [risk or edge case] | [impact if unhandled] | [how it is handled] |
