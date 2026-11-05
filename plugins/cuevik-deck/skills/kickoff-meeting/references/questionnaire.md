# Discovery questionnaire

Six sections, asked in this order. One `AskUserQuestion` call per section, its questions batched.
Pre-fill every answer the SoW already gave (present it as the first option to confirm or correct);
ask the rest cold. `multiSelect: true` where noted. Never invent a number — unknown targets become
`[TBD]`.

## 1. Engagement & scope (confirm against the SoW)

- **Objectives** — the 2–4 outcomes this engagement commits to.
- **In scope** — the deliverables and workstreams included.
- **Out of scope** — what is explicitly excluded.
- **Timeline** — start date, end date, and the named milestones.
- **Commercial model** — fixed-bid / time-and-materials / managed service / other.
- **Primary contacts** — client sponsor, client product owner, vendor delivery lead.

## 2. Technical landscape

- **Current stack** — languages, frameworks, databases, key platforms in play.
- **Target stack** — anything new this engagement introduces.
- **Integrations** — external systems, APIs and services to connect to.
- **Environments** — which exist (dev / test / staging / prod) and who owns them. *(multiSelect)*
- **Hosting & infra** — cloud provider / on-prem / hybrid; CI-CD in place.
- **Data** — sources, sensitivity (PII / PHI / PCI / none), migration or seeding needs.
- **Known technical constraints** — mandated tools, versions, standards, legacy limits.

## 3. Ways of working (Agile)

- **Methodology** — Scrum / Kanban / Scrumban / SAFe / hybrid / none yet.
- **Sprint length** — 1 / 2 / 3 weeks, or N/A for flow-based.
- **Ceremonies** — planning, daily stand-up, review/demo, retro, backlog refinement. *(multiSelect)*
- **Cadence** — demo and reporting rhythm (e.g. end of each sprint, fortnightly).
- **Tooling** — Jira / Azure DevOps / GitHub Projects / other for backlog and tracking.
- **Definition of Ready** — what a story needs before it is pulled in.
- **Definition of Done** — what "done" requires (tests, review, docs, deployed).
- **Release approach** — continuous / per-sprint / milestone-gated / client-scheduled.

## 4. Non-functional requirements (NFRs)

Push for a measurable target on each. No target given → record `[TBD]` and flag it; do not guess a number.

- **Performance** — response-time / throughput targets, and under what load.
- **Scalability** — expected and peak volumes (users, requests, data).
- **Availability** — uptime target and maintenance-window rules.
- **Security** — authn/authz model, encryption, standards (OWASP, SOC 2, ISO 27001). *(multiSelect)*
- **Compliance** — regulatory obligations (GDPR, HIPAA, PCI-DSS, local). *(multiSelect)*
- **Accessibility** — target (e.g. WCAG 2.1 AA) if the UI must meet one.
- **Observability** — logging, monitoring, alerting expectations.

## 5. Expectations & governance

- **RACI** — who is Responsible, Accountable, Consulted, Informed for delivery decisions.
- **Communication plan** — channels and the standing meetings (steering, delivery, operational).
- **Reporting** — status-report format and cadence; the KPIs/metrics the client tracks.
- **Escalation path** — how issues escalate, and the decision SLA at each level.
- **Success criteria** — how the client will judge the engagement a success.
- **Change control** — how scope changes are raised, assessed and approved.

## 6. Risks, assumptions, dependencies

- **Risks** — the top risks now, each with likelihood/impact if the user offers it.
- **Assumptions** — what the plan assumes is true (access, availability, third parties).
- **Dependencies** — external teams, vendors, approvals or systems delivery relies on.
