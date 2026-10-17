# TECH-STACK.md — Approved Technologies

**Owner:** [owner — from .cuevik/lineage.json]
**Last updated:** [YYYY-MM-DD]
**Source of truth for:** [one line — the approved technologies and usage rules]

> Derived from: [upstream documents — from .cuevik/lineage.json]
> Downstream: [downstream documents — derived from .cuevik/lineage.json]

<!-- @inject: _doc-references.md -->

---

## 1. Languages & Frameworks

| Technology | Version | Reason | Maps to PRD req |
| --- | --- | --- | --- |
| [language / framework] | [pinned version] | [one-line reason] | [PRD-00N] |

## 2. Datastores

[Databases and storage, each with the role it fills and why it fits.]

| Datastore | Version | Role | Reason |
| --- | --- | --- | --- |
| [datastore] | [version] | [what it stores] | [why it fits] |

## 3. Cloud & Infrastructure Services

[The platform services relied on.]

| Service | Purpose | Notes |
| --- | --- | --- |
| [service] | [what it provides] | [region / tier / constraint] |

## 4. Key Libraries / Tools

[Non-obvious dependencies that shape the build — the ones a developer must know
about, not every transitive dependency.]

| Library / tool | Version | Used for |
| --- | --- | --- |
| [library] | [version] | [its scoped purpose] |

## 5. Selection Trade-offs

[Why each major choice beat its alternatives.]

| Choice | Alternatives rejected | Why |
| --- | --- | --- |
| [chosen tech] | [what was considered] | [why the choice won] |

## 6. Versions & Constraints

[Pinned versions, minimum versions, and known limits contributors must respect.]

- [Constraint — e.g. "Node >= 20", "Postgres 16.x only"]
