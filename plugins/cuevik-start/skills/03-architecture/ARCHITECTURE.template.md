# ARCHITECTURE.md — System Architecture

**Owner:** [owner — from .cuevik/lineage.json]\
**Last updated:** [YYYY-MM-DD]\
**Source of truth for:** [one line — the system structure and design decisions]

> Derived from: [upstream documents — from .cuevik/lineage.json]\
> Downstream: [downstream documents — derived from .cuevik/lineage.json]

<!-- @inject: _doc-references.md -->

---

## Contents

1. [System Architecture](#1-system-architecture)
2. [Data Design](#2-data-design)
3. [Data Flow & Interactions](#3-data-flow--interactions)
4. [Key Design Decisions](#4-key-design-decisions)
5. [Implementation Conventions](#5-implementation-conventions)
6. [Integration Points](#6-integration-points)
7. [Security Posture & Data Classification](#7-security-posture--data-classification)
8. [Non-Functional Approach](#8-non-functional-approach)

---

## 1. System Architecture

[High-level breakdown of components, modules, or services and how they connect.
At least one diagram is required — a fenced text diagram is acceptable; a
whitebox or sequence diagram is preferred.]

```text
[diagram — components and how they connect]
```

- [Component] — [its responsibility]

## 2. Data Design

[Core entities, schema/storage layout, and how data is structured.]

> Formal domain-driven design (bounded contexts) is out of scope unless the operator opts in.

## 3. Data Flow & Interactions

[How data moves between components and external systems.]

## 4. Key Design Decisions

[Structural choices — layering, sync vs async, service boundaries — each with
rationale. Technology selection lives in TECH-STACK.md.]

| Decision | Choice | Rationale |
| --- | --- | --- |
| [the decision point] | [what was chosen] | [why — what it buys, what it trades] |

## 5. Implementation Conventions

[Patterns, standards, and structural rules developers must follow — how to
build, not the code itself.]

- [Convention] — [what it requires]

## 6. Integration Points

[How the system connects with external APIs, services, or dependencies.]

- [Integration] — [protocol/contract and direction]

## 7. Security Posture & Data Classification

[Data sensitivity (public / internal / confidential / restricted); auth and
authorization model; encryption at rest and in transit; trust boundaries and
network exposure; compliance requirements from PRD.md and how the architecture
satisfies them; known threat vectors the design accounts for.]

| Data category | Classification | Handling |
| --- | --- | --- |
| [data type] | [public / internal / confidential / restricted] | [how it is protected] |

## 8. Non-Functional Approach

[How the remaining PRD.md non-functional requirements — scale, performance,
availability, resilience — are met structurally.]
