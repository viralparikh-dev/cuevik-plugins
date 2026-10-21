# AI-TOOL-GUIDE.md — Rules for AI Tools

**Owner:** [owner — from .cuevik/lineage.json]\
**Last updated:** [YYYY-MM-DD]\
**Source of truth for:** [one line — how AI tools must behave on this project]

> Derived from: [upstream documents — from .cuevik/lineage.json]\
> Downstream: [downstream documents — derived from .cuevik/lineage.json]

<!-- @inject: _doc-references.md -->

---

## 1. Project Context

[Brief summary of what the project is, how it is structured, and the tech stack
in use — enough for an AI tool to orient without reading every other doc.]

## 2. Coding Conventions

[Naming, formatting, and file-structure rules for this project.]

- [Convention]

## 3. Scope Boundaries

[What AI tools are and are not allowed to touch. Name specific files,
directories, or actions.]

- [In bounds / out of bounds]

## 4. Banned Patterns

[Things AI must never generate or suggest. Project-specific — reference actual
libraries or anti-patterns flagged in ARCHITECTURE.md, not generic boilerplate.]

- [Banned pattern] — [why]

## 5. Testing Rules

[How tests must be written and what counts as a valid test.]

- [Rule]

## 6. Documentation Rules

[When and how to comment; what to leave out.]

- [Rule]

## 7. Decision Escalation

[Concrete scenarios where AI must stop and get approval — new package additions,
schema/migration changes, auth-related code, breaking API changes, anything
touching CI/CD or deployment config.]

- [Scenario requiring escalation]

## 8. Agent Behavior Rules

[How AI agents must operate on this project.]

- **Plan before execute** — show a plan and wait for approval on non-trivial work
- **Ask, don't assume** — one clarifying question over a guessed intent
- **Scope discipline** — touch only what was asked; flag the rest
- **Stop and report** — surface blockers immediately

## 9. Off-Limits Boundaries

[Files and areas AI must never touch without explicit human instruction.]

- **Secrets and env files** — `.env`, `.env.*`, anything holding keys or tokens
- **Lock files** — `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- **Database migrations** — never create, modify, or delete autonomously
- **CI/CD config** — pipeline and deployment configs require human review
- **Auth-related code** — tokens, sessions, permissions, identity
- **Dependency additions** — state the package and reason; get approval first

## 10. Workflow Conventions

[Branching, commits, PRs, pushing, and breaking-change sign-off.]

- **Branch creation** — a human action, not autonomous
- **Commit messages** — follow the project convention (default: Conventional Commits)
- **PRs** — not opened, closed, or commented on without instruction
- **Pushing to remote** — never without explicit human approval
- **Team plugins** — [plugins enabled in .claude/settings.json, and manual prerequisites; or None]
