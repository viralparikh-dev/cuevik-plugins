# Document References (shared partial)

This block is the **single source** for the cross-document reference map. The
runner injects it into every generated cuevik-start document by replacing the
`<!-- @inject: _doc-references.md -->` marker with the content between the
`BEGIN INJECT` / `END INJECT` markers below. Edit the table here only — never
copy it into a template or a generated document.

The cuevik-start document set is fixed at seven docs. Adding, removing, or renaming
a document is a deliberate change made here, and it propagates to every doc on
the next generation.

<!-- BEGIN INJECT -->
## Document References

| # | Document | Role |
| --- | --- | --- |
| 1 | PRODUCT.md | What we are building and why |
| 2 | PRD.md | Testable requirements |
| 3 | ARCHITECTURE.md | System structure & design decisions |
| 4 | TECH-STACK.md | Approved technologies & usage rules |
| 5 | AI-TOOL-GUIDE.md | Rules & constraints for AI tools |
| 6 | README.md | Setup, env config, how to run |
| 7 | BACKLOG.md | Epics/stories manifest |
<!-- END INJECT -->
