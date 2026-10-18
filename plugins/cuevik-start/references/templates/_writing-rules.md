# Writing Rules for Generated Documents

These rules apply to **every** document the cuevik-start runner produces. They are
referenced from `references/runner.md` §4 and applied on top of the per-document
template. The template owns each document's structure (its headings and order);
this file owns the shared writing standard that fills it.

## Tone

- Write for a reader who joins the project cold. Assume no shared context.
- Direct and specific. Cut filler, hedging, and restated headings.
- Every claim is checkable. If a sentence cannot be verified or acted on, drop it.

## Requirement language (RFC 2119)

Use these keywords deliberately. Do not use "must" casually for emphasis.

- **MUST / MUST NOT** — mandatory. A reviewer rejects the doc if it is not met.
- **SHOULD / SHOULD NOT** — strong default. Deviation requires a stated reason.
- **MAY** — genuinely optional.

## Measurability

- Every requirement, success criterion, and acceptance criterion MUST be
  verifiable without asking the author.
- Replace vague adjectives (`fast`, `secure`, `scalable`, `intuitive`) with
  numbers or observable conditions (`p95 < 200 ms`, `passwords hashed with
  Argon2id`, `supports 10k concurrent sessions`).

## Acronyms

- Define every acronym on first use in each document:
  `Single Sign-On (SSO)`. After the first use, the acronym alone is fine.

## Priority scale — MoSCoW

One priority vocabulary across all documents. `PRD.md` §6 (Functional
Requirements) and `BACKLOG.md` inherit it; do not introduce a second scale
(no P0/P1, no High/Medium/Low).

| Priority | Meaning |
| --- | --- |
| Must | Required for this release. Its absence makes the release a failure. |
| Should | Important but not release-blocking. Included unless capacity forces a cut. |
| Could | Desirable. Included only if time allows. |

The fourth MoSCoW band — **Won't (this release)** — is not a priority tag.
Record those items in the document's explicit **Out of Scope** section with a
reason, not as a prioritized requirement.

## Metadata block

Every templated document except `README.md` opens with the lean header block:

- **Owner** — the document's `owner` in `.cuevik/lineage.json`.
- **Last updated** — `YYYY-MM-DD`.
- **Source of truth for** — one line scoping what this document governs.
- **Derived from / Downstream** — the document's `upstream` in
  `.cuevik/lineage.json`, and the documents that reach it by following
  `upstream` links.

Keep the trailing `\` on the `Owner`, `Last updated` and `Derived from` lines: it is a hard line
break, without which GitHub renders the block as one run-on line.

There is no `Status` or `Version` field. Merge to `main` is the status; git
history is the version. A status flag in the file would only rot.

## Placeholders

- `[square-bracket text]` marks a value to fill from the interview.
- No `[placeholder]` may survive into a merged document. Replacing every
  placeholder is a reviewer-checklist item.

## Markdownlint

- Every generated document MUST pass `.markdownlint.json` at the repo root
  (written by `00-bootstrap`).
- Tables use compact style (single-space padding, `---` delimiter cells).
- Fenced code blocks declare a language. Headings, lists, tables, and fences
  are surrounded by blank lines.
