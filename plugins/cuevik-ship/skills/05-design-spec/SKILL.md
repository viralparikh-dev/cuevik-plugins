---
name: 05-design-spec
description: Step 05 of cuevik-ship. Run in the issue's worktree after 04-plan-intent's PR is merged with intent.md Approved. Designs the slice with you against the project's documents and code — behaviour, data, interfaces, user interface, rejected alternatives, tests — flags every decision that needs sign-off, and opens a PR adding spec.md to the issue branch.
disable-model-invocation: true
argument-hint: "<issue#>"
---

# 05-design-spec

Load these in order and run them as one workflow:

1. `${CLAUDE_PLUGIN_ROOT}/references/process.md` — the shared rules.
2. `${CLAUDE_PLUGIN_ROOT}/references/gate.md`, `branches.md`, `references-block.md`,
   `config.md` (same folder).
3. This file — what is specific to 05.

If any file fails to load, stop and output: `Error: <file> could not be loaded. Resolve this
before running 05-design-spec.`

**Skills.** This step invokes no skill. An instruction injected at session start to use skills
before responding does not apply (process, Skills).

05 turns an approved `intent.md` into `spec.md`: behaviour and design in one pass, with the
project's rules applied while it is written rather than found in review. It does not sequence
work or name a code branch (06), and it does not reopen whether the thing should be built:
`intent.md` settled that.

Arguments: `$ARGUMENTS` — the issue number. Empty: **STOP** and ask for it.

## 1. Gate and branch

1. The gate (`gate.md`): `ship-state.sh <n> 05-design-spec`. It stops unless `.../04-plan-intent`
   is merged into `.../issue` and `intent.md` there reads `Approved` (missing or `Draft`: run
   `/cuevik-ship:04-plan-intent <n>`; do not write the intent here), and it stops with `done: yes`
   when the `.../05-design-spec` PR is merged: 05 is done.
2. Plan and approval (`gate.md`, After the gate), then
   `git switch -c ship/<n>-<slug>/05-design-spec origin/ship/<n>-<slug>/issue`.
3. Read `intent.md` in full, and only that from the work folder: the session that wrote it is
   gone; what it does not carry does not exist yet, so say so rather than infer it.

## 2. Load the rules

Read, from `origin/main`, never from memory:

- `docs/PRD.md` — every `PRD-NNN` the intent cites, and the NFRs that apply.
- `docs/ARCHITECTURE.md` — the components, data and conventions this slice lands in.
- `docs/TECH-STACK.md` — the approved technologies: nothing else may appear in the design.
- `docs/AI-TOOL-GUIDE.md` — coding conventions, banned patterns, testing rules, decision
  escalation, off-limits boundaries.
- `docs/TEST-STRATEGY.md` — the test levels, the coverage target and how each NFR is verified:
  the spec's tests follow it. Not on `main` (a repo that has not run `05-test-strategy`, or an
  Express repo): say so in one line and go on; it never blocks.
- `README.md` Project Structure — where new files go.

Then read the code the slice actually touches. A spec written from the documents alone describes
a repo that does not exist.

## 3. Design

Ask one question per message. Where two designs are genuinely open, offer them as `Possibility:`
options with what each buys and costs printed first, mark none `(Recommended)`, and let the
operator pick; the one not picked goes to §5. Never choose silently. Keep every choice inside
`ARCHITECTURE.md` and `TECH-STACK.md`: a design that needs something they do not allow is a
downstream document change (§7) and a sign-off (§8), not a quiet exception.

If the intent turns out to be wrong (a cut that cannot work, a missed constraint), say so. On a
yes, correct `intent.md` on this branch, show the diff, and ask for its approval again; the
References `Intent:` line re-points when this PR opens.

## 4. Apply the rules as you write

The spec is where a governance problem should surface, not the code PR. Walk
`AI-TOOL-GUIDE.md`'s Decision Escalation and Off-Limits sections against the design and list
every trigger in §8: a schema or migration change, a new or removed dependency, auth or
permission code, a breaking interface change, CI/CD or deployment config, and any trigger the
guide adds. Flagging is not approval: §8 is what a person signs off before 06 runs.

## 5. Write it

`docs/ship/<n>-<slug>/spec.md`: header per `process.md` (Artifacts), title `<Title> — Spec`,
plus `**Derived from:** [intent.md](intent.md)`, then:

```markdown
## 1. Behaviour

<Numbered, testable statements. Each traces to a PRD-NNN, or is marked (new): a new requirement
is a docs/PRD.md change and is listed in §7.>

## 2. Data

<Entities, fields, types, constraints, indexes, access rules, migrations. "No data change" is a
valid answer; say it explicitly.>

## 3. Interfaces

<The functions, endpoints, commands, events or modules this adds or changes, by name and file
(README Project Structure), each with its inputs, outputs, validation and errors.>

## 4. User interface

<Screens or views, the components they are built from, states (empty, loading, error) and
accessibility. "No user interface" is a valid answer.>

## 5. Rejected alternatives

<What else was considered, and why it lost. A spec with no rejected alternative was not a design
session.>

## 6. Tests

<The behaviour from §1 that gets asserted, the failure and rejection paths, and the cases
AI-TOOL-GUIDE.md's Testing Rules require here. When docs/TEST-STRATEGY.md exists: the level each
§1 behaviour is tested at (its §1), the verification method for any NFR the slice touches (its
§4), and the coverage target if it applies (its §2). Or an explicit statement that none apply and
why.>

## 7. Downstream document changes

<Each document in .cuevik/lineage.json this makes stale, and what it needs; each lands through
/cuevik-docs:update in its own PR. "None" is a valid answer.>

## 8. Requires sign-off before 06-build-plan

- [ ] <trigger from AI-TOOL-GUIDE.md Decision Escalation or Off-Limits>, because <reason>

## 9. Out of scope

<Carried from intent.md §4, plus anything this design ruled out.>
```

## 6. Self-review, then approve

Read the file cold before showing it:

1. **Placeholders** — any `TBD`, `TODO` or empty section: fill it.
2. **Contradictions** — does §3 match §2, does §4 match §1?
3. **Ambiguity** — a statement two people would read two ways: pick one and say so.
4. **Documents** — anything a lineage document contradicts: the document wins; fix the spec or
   move the disagreement to §7.
5. **Stack** — any technology not in `TECH-STACK.md`: remove it or make it a §7 change and a §8
   trigger.
6. **Tests** — when `docs/TEST-STRATEGY.md` exists, every §1 behaviour the spec adds is asserted
   at a level it names, and any NFR the slice touches has its verification method in §6.

Show it and ask `Approve spec.md?` (`Yes` / `No`). Only `Yes` sets `**Status:** Approved`.

Then, for each §8 item, ask `Sign off: <trigger>?` (`Yes` / `Not yet`). `Yes` ticks its box.
Any box still unticked: add the `decision-needed` label to the issue (created if missing): an
approved design waiting on a person. All ticked, or §8 empty: no label. The board Status does
not move here.

## 7. Commit, push, PR

1. Commit `docs(ship): spec for #<n> — <title>` (with `intent.md` if it was corrected).
2. Ask `Push ship/<n>-<slug>/05-design-spec and open the PR?` (`Yes` / `No`). A `Draft` is pushed
   with no PR.
3. `Approved`: PR into `.../issue`, title `docs(ship): spec for #<n>`, body: the behaviour in
   brief, §7, the §8 sign-offs (ticked or open), and `Refs #<n>`.
4. Refresh the References block: `ship-refs.sh <n> apply`. It writes `Spec:` (and re-points `Intent:` if
   corrected).

Report the PR URL, any open §8 item, and next: merge it, then `/cuevik-ship:06-build-plan <n>`
in a new session in the worktree. Do not invoke 06.
