# Cuevik Plugins — Walkthrough

**Plugins:** `cuevik-start`, `cuevik-ship`, `cuevik-docs`  ·  **Marketplace:** `cuevik-plugins`  ·  **Author:** Viral Parikh

Draft. This page only proves the build pipeline (markdown to HTML to PDF). The walkthrough itself is written in later steps.

---

## 1. Pipeline check

A paragraph with **bold**, `inline code` and a [link to the table](#2-table-check).

```
/cuevik-start:00-bootstrap
```

### Sub-heading

- First point
- Second point

---

## 2. Table check

| Plugin | Command | Output |
|---|---|---|
| `cuevik-start` | `/cuevik-start:00-bootstrap` | CONTRIBUTING.md |
| `cuevik-ship` | `/cuevik-ship:01-brainstorm` | Brainstorm file |
| `cuevik-docs` | `/cuevik-docs:audit` | Audit report |
