# Board adapter

Every GitHub Projects (v2) call in cuevik-start is in this file. `00-bootstrap`, the runner (§7)
and `07-backlog` call an operation by its name and run no `gh project` or Projects GraphQL command
of their own. The board is optional (`.cuevik/config.json` `boardState`), and a board failure must
never stop initiation: this file says how each failure is classified, and the caller decides what
that means.

Placeholders: `<board-owner>` and `<project owner>` are the board's owner (`project.owner` in the
config, or the owner chosen in `00-bootstrap` §D.1); `<number>` is the board number; `<project id>`
and `<project.id>` are the board's node id.

## Results

Every operation ends in one of three results:

| Result | Meaning |
| --- | --- |
| `ok` | Done as asked. |
| `degraded` | The board is usable but one part did not complete. The operation names the part: `link`, `items`, `fields` or `workflows` (the `missing` set of the config contract). |
| `unavailable` | The board cannot be used at all: no access to Projects, it could not be created, or it has no single-select `Status` field. |

What a caller does with a result:

- **`00-bootstrap`** keeps a running list of the degraded parts and any `unavailable`. It writes
  them into `.cuevik/config.json` as `boardState` and `missing` (bootstrap §F) and into the PR body.
  It never stops on a board result. A STOP in bootstrap is for the repo, `CONTRIBUTING.md`,
  `.cuevik/`, the initiation issues, or the operator's own choice.
- **A step** (runner §7, `07-backlog`) reports a `degraded` or `unavailable` result in its PR body
  and carries on. Never create fields or options.
- **`boardState: none`:** a caller makes no call at all and says nothing.

## Operations

| Operation | Used by |
| --- | --- |
| `board.read` | bootstrap §D and §E.5; runner §7; `07-backlog` |
| `board.create` | bootstrap §E.1 |
| `board.link` | bootstrap §E.2 |
| `board.addItem` | bootstrap §E.4; `07-backlog` |
| `board.setField` | bootstrap §E.4; runner §7; `07-backlog` |
| `board.workflows` | bootstrap §E.5 |

### board.read

Variants. A read never changes the board.

- **`probe`** (before anything else): `gh project list --owner <board-owner> --limit 1`. Non-zero:
  `unavailable`, with the message `gh cannot read Projects for <board-owner>. In a local session,
  run gh auth refresh -s project. Cloud sessions cannot reach Projects v2.`
- **`id`** (a board now chosen or created): its node id, for `project.id`:
  `gh project view <number> --owner <board-owner> --format json --jq .id`.
- **`list`**: the open boards:
  `gh project list --owner <board-owner> --format json --jq '.projects[] | {number, title}'`.
- **`linked`** (an existing board):

  ```sh
  gh api graphql -f owner=<repo-owner> -f name=<repo-name> -f query='
    query($owner:String!,$name:String!){repository(owner:$owner,name:$name){
      projectsV2(first:50){nodes{number owner{... on User{login} ... on Organization{login}}}}}}' \
    --jq '.data.repository.projectsV2.nodes'
  ```

  Linked when a node has the board's number and owner.
- **`status`** (an existing board now; a new one after `board.create`):

  ```sh
  gh project field-list <number> --owner <board-owner> --format json \
    --jq '.fields[] | select(.name=="Status") | {id, type, options: (.options | map({(.name): .id}) | add)}'
  ```

  No output, or a `type` other than `ProjectV2SingleSelectField`: `unavailable` for this board, with
  the message that the board needs a single-select field named `Status`.
- **`template`** (a template board the operator named):
  `gh project view <template-number> --owner <template-owner> --format json --jq .title`.
  Non-zero: `unavailable` for this template, and say why.
- **`fields`**: read the board's fields once:
  `gh project field-list <number> --owner <project owner> --format json --limit 100`. Find a field
  by exact name; a single-select option by exact name in its `options`. A missing field or option:
  skip that update and say so in the PR body. This is not a `degraded` result.
- **`item`**: an issue's board item id:
  `gh project item-list <number> --owner <project owner> --format json --limit 500 --jq '.items[] | select(.content.url=="<issue url>") | .id'`,
  where the issue url is `https://github.com/<owner>/<repo>/issues/<n>`. Not on the board: skip.
- **`workflows`**: which workflows are on (a workflow that was never set up is not listed; treat it
  as off):

  ```sh
  gh api graphql -f o=<board-owner> -F n=<number> -f query='
    query($o:String!,$n:Int!){repositoryOwner(login:$o){... on ProjectV2Owner{projectV2(number:$n){
      workflows(first:50){nodes{name enabled}}}}}}' \
    --jq '.data.repositoryOwner.projectV2.workflows.nodes[] | "\(.enabled) \(.name)"'
  ```

### board.create

Creates a board from the template the operator chose (bootstrap §D.6), or a blank one. A failed
create is `unavailable`.

- From the template:
  `gh project copy <template-number> --source-owner <template-owner> --target-owner <board-owner> --title "<title>" --format json --jq .number`.
  Draft issues are not copied. Then compare the copy with the template. Run this once with the
  template (`> template.txt`) and once with the new board (`> board.txt`), writing both files in
  a temporary folder outside the repo. It prints one line per value, so `diff` output is
  readable. Use `gh`'s built-in `--jq`; do not assume a separate `jq` is installed.

  ```sh
  gh api graphql -f o=<owner> -F n=<number> -f query='
    query($o:String!,$n:Int!){repositoryOwner(login:$o){... on ProjectV2Owner{projectV2(number:$n){
      fields(first:50){nodes{... on ProjectV2FieldCommon{name dataType}
        ... on ProjectV2SingleSelectField{options{name}}
        ... on ProjectV2IterationField{configuration{duration startDay}}}}
      views(first:20){nodes{name layout filter
        fields(first:50){nodes{... on ProjectV2FieldCommon{name}}}
        groupByFields(first:5){nodes{... on ProjectV2FieldCommon{name}}}
        verticalGroupByFields(first:5){nodes{... on ProjectV2FieldCommon{name}}}
        sortByFields(first:5){nodes{direction field{... on ProjectV2FieldCommon{name}}}}}}
      workflows(first:20){nodes{name enabled}}}}}}' \
    --jq '.data.repositoryOwner.projectV2 | paths(scalars) as $p
          | "\($p | map(tostring) | join(".")) = \(getpath($p))"'
  ```

  Then `diff template.txt board.txt`. Check both files are non-empty first: two empty files
  also give "no differences". Report every difference; do not stop on one. The operator
  decides whether to fix it by hand. Say what the check cannot see: the settings inside each
  workflow (for example which Status "Item closed" sets) are not readable through the API.
- Blank (operator chose it in bootstrap §D.6):
  `gh project create --owner <board-owner> --title "<title>" --format json --jq .number`.

Then run `board.read` `status` on the new board.

### board.link

Unless the board is already linked (`board.read` `linked`), from the repo folder so it links this
repo: `gh project link <number> --owner <board-owner>`. It prints nothing on success, so re-run
`board.read` `linked` and confirm the board now appears. A user-owned board linked to an
organisation-owned repo is untested. If the link fails, the result is `degraded`, part `link`:
show the error; do not retry with another owner.

### board.addItem

`gh project item-add <number> --owner <board-owner> --url <issue url> --format json --jq .id`; the
output is the item's id. Adding an item that is already on the board is harmless and returns the
same id. Never set Status: the board's own workflows set it when an item is added and when its issue
closes. A failure is `degraded`, part `items` (a step reports it in its PR body).

### board.setField

Sets one value on one item; the caller names the item, the field and the value. Look the field up
first (`board.read` `fields`), then:
`gh project item-edit --id <item id> --project-id <project.id> --field-id <field id>`, plus
`--date <YYYY-MM-DD>` for a date field or `--single-select-option-id <option id>` for a
single-select field (for Status, use `project.statusField` from the config). For a number field,
`gh project item-edit ... --field-id <field id> --number <hours>`.

A board without the field, or without that option, is a skip, not a failure: say so in the PR body.
An `item-edit` that fails on a field the board has is `degraded`, part `fields`.

**The `Sprint` iteration field** (bootstrap only), only on a board whose `Sprint` field has
**no sprints at all** (current, upcoming or completed). Read them:

```sh
gh api graphql -f o=<board-owner> -F n=<number> -f query='
  query($o:String!,$n:Int!){repositoryOwner(login:$o){... on ProjectV2Owner{projectV2(number:$n){
    field(name:"Sprint"){... on ProjectV2IterationField{id configuration{duration
      iterations{id title} completedIterations{id title}}}}}}}}' \
  --jq '.data.repositoryOwner.projectV2.field'
```

- Both lists empty: create `Sprint-00`, starting today, for the field's `duration` in days.
  This call **replaces the field's whole sprint list**, which is why it runs only when the
  list is empty:

  ```sh
  gh api graphql -f fid=<field id> -f d=<YYYY-MM-DD> -F len=<duration> -f query='
    mutation($fid:ID!,$d:Date!,$len:Int!){updateProjectV2Field(input:{fieldId:$fid,
      iterationConfiguration:{startDate:$d,duration:$len,iterations:[{title:"Sprint-00",
      startDate:$d,duration:$len}]}}){projectV2Field{... on ProjectV2IterationField{
      configuration{iterations{id title}}}}}}'
  ```

  Then put the epic and every story in it:
  `gh project item-edit ... --field-id <field id> --iteration-id <Sprint-00 id>`.
- Any sprint already there: create none and leave the items' Sprint empty. Later sprints
  follow the same name format: `Sprint-01`, `Sprint-02`, ….
- No `Sprint` iteration field: skip and say so in the PR body.

### board.workflows

Used once, by bootstrap, when a board is recorded. The initiation cards move only through the
board's own workflows. These seven must be on:

| Workflow | Note |
| --- | --- |
| `Auto-add sub-issues to project` | |
| `Auto-add to project` | A template copy never has it on: it needs this repo in its filter |
| `Auto-close issue` | |
| `Item added to project` | |
| `Item closed` | |
| `Pull request linked to issue` | |
| `Pull request merged` | |

Read them with `board.read` `workflows`. No API turns a workflow on or changes its settings, so
guide the operator through each one that is off. Open
`https://github.com/users/<board-owner>/projects/<number>/workflows` (`orgs/` instead of `users/`
for an organisation), then for each workflow:

- Click it in the left list, click **Edit**, switch it **On**, click **Save and turn on**.
- `Auto-add to project` also needs its filter: in **Filters**, pick the repository
  `<repo-name>` and set the filter text to `is:issue,pr is:open label:bug`.

Ask with options `Done, check again`, `Skip workflows` and `Stop bootstrap`. On `Done`, re-read and
repeat until every required workflow is on.

- A board created by `board.create`: all seven are required.
- An existing board: only `Item closed` is required. List the others that are off and offer the
  same steps; the operator may decline, and the PR body says which are off.

The result is `ok` when every required workflow is on and the Status mapping below is confirmed.
`Skip workflows` ends the loop with `degraded`, part `workflows`; the PR body says what is off.
`Stop bootstrap` is the operator's own choice: the caller STOPs and reports what is on and what is
not.

The API shows only whether a workflow is on, not its settings, and cannot change them. The runner
relies on these Status values (runner §7), so show this table and ask the operator to check each one
on the board's Workflows page (click it, **Edit**, set the Status, **Save**):

| Workflow | Must set Status to |
| --- | --- |
| `Item added to project` | `Backlog` |
| `Pull request linked to issue` | `Reviewing` |
| `Item closed` | `Done` |
| `Pull request merged` | `Done` |

Then ask `Are these four set, and Auto-add to project filtered to <repo-name>?` with `Yes` /
`No, stop`. `No, stop` is `Stop bootstrap`. A board without one of these Status options: say which,
and that its cards will not move to it. Record the answer in the PR body.
