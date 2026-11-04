# Usage Review for cuevik-start Plugin

> Reusable review prompt. Used to produce the cuevik-start usage review; adapt the plugin name
> and command prefix to reuse it for cuevik-ship or any other plugin.

Act as both a Senior Product Owner and Enterprise Product Architect.

Your responsibility is to critically evaluate the Cuevik Start plugin and all `cuevik-start-*` commands.

Do not assume the current design is correct.

Challenge assumptions, identify weaknesses, uncover gaps, and recommend improvements. Base findings on evidence from the plugin, its expected business value, and its usability throughout the project lifecycle. Prioritize practical usability, adoption, maintainability, and business value over documentation completeness.

## Context

Cuevik Start is a project acceleration and delivery framework that generates artifacts, templates, guidance, and documentation through various cuevik-start-* commands.

The goal is not to generate documentation for the sake of documentation.

Every generated artifact must provide measurable value by helping teams:

- Make better decisions
- Reduce delivery risk
- Improve product quality
- Improve stakeholder alignment
- Improve onboarding
- Accelerate delivery
- Improve architectural consistency
- Reduce ambiguity
- Improve maintainability
- Support governance where necessary

The framework should remain lean, practical, maintainable, and outcome-focused.

## Review Objectives

Evaluate Cuevik Start as a product platform, not merely a document generator.

Determine whether each command:

- Solves a real problem
- Produces actionable outputs
- Supports decision-making
- Improves engineering effectiveness
- Improves delivery outcomes
- Reduces project risk
- Improves communication
- Creates enough value to justify the effort required to maintain it

Identify:

- Missing capabilities
- Missing artifacts
- Missing workflows
- Missing governance mechanisms
- Missing product management support
- Missing architecture support
- Missing engineering support
- Redundant outputs
- Low-value outputs
- Over-engineered outputs
- High-maintenance outputs
- Opportunities for simplification
- Opportunities for automation

## Command-by-Command Assessment

For each cuevik-start-* command, assess:

- **Purpose:** Why does this command exist?
- **Target audience:** Who uses it?
- **Business outcome:** What measurable value does it create?
- **Problems solved:** Which specific problems does it address?
- **Outputs generated:** What artifacts are produced?
- **Decision support:** Which decisions are improved by these outputs?
- **Risk reduction:** Which risks are reduced?
- **Team adoption:** Will teams realistically use and maintain these outputs?
- **Maintenance burden:** How much effort is required to keep outputs current?
- **Automation potential:** What could be AI-generated or automated?
- **Recommendation:** Choose one of: Keep, Improve, Consolidate, Replace, or Remove.

## Artifact Evaluation

For every generated artifact, determine:

- Who owns it?
- Who consumes it?
- How often should it be updated?
- How quickly will it become stale?
- What business value does it provide?
- What maintenance effort is required?
- What ROI does it deliver?
- Should it be retained, improved, consolidated, or removed?

Classify every artifact as:

- Critical
- Valuable
- Optional
- Waste

Provide justification.

## Product and Architecture Gap Analysis

Evaluate whether Cuevik Start adequately supports:

- Product Vision
- Product Strategy
- Business Goals
- Stakeholder Alignment
- Product Discovery
- Requirements Management
- Domain-Driven Design
- Business Architecture
- Solution Architecture
- Technical Architecture
- Data Architecture
- Security
- Compliance
- Development Planning
- AI-Assisted Development
- Quality Assurance
- Testing Strategy
- DevOps
- CI/CD
- Release Planning
- Observability
- Operational Readiness
- Risk Management
- Knowledge Transfer
- Team Onboarding

Identify missing capabilities and recommend improvements.

## Anti-Bureaucracy Review

Challenge the framework and answer:

- What are we creating that nobody will read?
- What are we maintaining that nobody uses?
- Which artifacts are likely to become stale?
- What information is duplicated?
- Which outputs create overhead instead of value?
- What can be eliminated?
- What can be consolidated?
- What can be automated?

Be brutally honest.

## 80/20 Analysis

Assume a team only has 2 hours available to establish a new project.

Rank all generated artifacts by business impact.

Identify:

- Must Have
- Should Have
- Nice To Have
- Remove

Determine which 20% of artifacts provide 80% of the value.

## Scoring

Score each command from 1-10 for:

- Business Value
- Product Value
- Engineering Value
- Delivery Impact
- Decision Support
- Risk Reduction
- Team Adoption
- Maintainability
- Reusability
- ROI

Explain all scores.

## Deliverables

Provide:

1. Executive Summary
2. Overall Assessment Scores
3. Highest Value Commands
4. Lowest Value Commands
5. Missing Capabilities
6. Major Gaps
7. Redundant Artifacts
8. High-Maintenance / Low-ROI Artifacts
9. Commands to Add
10. Commands to Improve
11. Commands to Merge
12. Commands to Remove
13. AI Automation Opportunities
14. Recommended Future-State Architecture
15. Final Verdict

Determine whether Cuevik Start is:

- Under-Documented
- Balanced
- Over-Documented

Explain why.

Focus on outcomes, adoption, maintainability, and business value.

Assume every artifact must justify its existence.
