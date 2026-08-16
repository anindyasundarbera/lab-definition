# Agent Lab Work Ledger — Normative Schema and Workflow

This document defines the normative schema and workflow for Agent Lab work
ledgers. Every governed work item has one ledger file under
`docs/ledger/<WORK-ID>.md`. `AGENTS.md` states the binding rule; this
document specifies what a compliant ledger contains.

## One-file-per-work convention

Each work item is recorded in exactly one file at
`docs/ledger/<WORK-ID>.md`. Filenames use stable work-order IDs (for
example `OH-001D.md`); IDs do not change across the life of the work.
Related stages of the same mission share one ledger and are represented as
chronological events within it, not as separate files.

## Required header fields

Every ledger begins with a header block containing at least:

- **Work ID** — the stable work-order identifier (filename stem).
- **title** — short human title of the mission.
- **component/area** — the component or area affected (e.g. `openhands`).
- **steward** — the human steward accountable for authorization.
- **status** — current status value from the vocabulary below.
- **opened_at** — when the work was opened/authorized (absolute, or
  `not recorded` if unavailable).
- **closed_at** — when the work was institutionally closed, if any;
  otherwise `open` / `pending`.
- **canonical base** — the exact SHA the candidate work was based on.
- **current canonical head** — the current canonical repository head known
  at the time of the ledger update, whether or not it contains the current
  candidate; `not known` when unavailable. It is a snapshot of canonical
  state, not a claim that this work is merged or accepted.
- **ledger version** — monotonically increasing integer, bumped on each
  material ledger update.

## Status vocabulary

The status field uses this vocabulary (states may be combined or
represented as a current state plus an append-only event history):

- `PROPOSED`
- `AUTHORIZED`
- `IN_PROGRESS`
- `CANDIDATE_READY`
- `REVIEWED`
- `VERIFIED`
- `COMMIT_APPROVED`
- `COMMITTED`
- `PUBLICATION_APPROVED`
- `PUBLISHED`
- `PR_OPEN`
- `MERGED`
- `ACCEPTANCE_PENDING`
- `ACCEPTED`
- `BLOCKED`
- `REJECTED`
- `CLOSED`
- `SUPERSEDED`

`ACCEPTED` means runtime/mission acceptance: the work passed its actual
runtime or mission acceptance test, not merely that a change landed.
`CLOSED` means institutional closure: the ledger records closure evidence
and the final canonical state. A work item may be `MERGED` on canonical but
still `ACCEPTANCE_PENDING`, and is not `CLOSED` until closure evidence is
recorded. `SUPERSEDED` marks a ledger replaced by a later work item; the
superseding pointer must be recorded.

## Required sections

A compliant ledger contains the following sections, in order:

1. **Mission/Scope** — what the work item is and is not, including explicit
   non-goals.
2. **Guardrails** — constraints, isolation boundaries, and tool
   authorizations in force for this work.
3. **Current State/Next Gate** — the current status and the next gate that
   must pass.
4. **Artifact Manifest** — exact base SHA, changed paths, candidate
   fingerprint, file SHAs, and any derived artifacts.
5. **Decision Log** — material decisions and authorization points, each
   with actor, timestamp (or `not recorded`), and rationale.
6. **Event Ledger** — append-only chronological event rows (see below).
7. **Candidate/Review/Verification Evidence** — candidate job/fingerprint,
   review ID/verdict, verification ID/results, evidence bundle SHA.
8. **Commit/Publication/PR/Merge Evidence** — detached commit SHA, branch,
   PR URL/number, merge SHA, canonical sync SHA.
9. **Runtime/Acceptance Evidence** — runtime evidence paths/hashes and
   acceptance verdict, or `pending` with the reason.
10. **Failures/Rejections/Recoveries** — every failed attempt, rejected
    evidence, blocker, and recovery, with explicit status.
11. **Deferred Risks/Follow-ups** — known risks and follow-ups not closed by
    this work.
12. **Closure** — closure evidence and final canonical state, or `pending`
    with the remaining gate(s). When closed, records the **accepted
    canonical head** — the exact canonical commit whose substantive
    artifacts or runtime behavior were actually accepted — distinct from any
    later bookkeeping-only ledger carrier merge.

## Event row contract

The Event Ledger is append-only and chronological. Each event row records:

- **timestamp** — absolute, or `not recorded` when unavailable.
- **actor** — the agent, tool, or human that performed the action.
- **action/gate** — what happened / which gate.
- **evidence/binding** — exact IDs, SHAs, fingerprints, or evidence paths
  that bind the event.
- **outcome** — the result (e.g. PASS, FAIL, APPROVE, REJECT, granted,
  denied, committed, interrupted).
- **next gate** — the gate that must pass next.

Exact bindings recorded in events include, when applicable: exact base
SHA; changed paths; candidate fingerprint; review ID/verdict; verification
ID/results; evidence bundle SHA; detached commit SHA; branch; PR
URL/number; merge SHA; canonical sync SHA; runtime evidence paths/hashes;
and rejected/superseded evidence. Absent values are recorded as
`not recorded`, never invented. A value that exists externally but cannot
yet be embedded in the candidate being gated (because the ledger is inside
that candidate) is recorded as `pending external binding` and backfilled at
the next governed maintenance point or the closure ledger transaction (see
"Non-self-referential binding").

## Evidence path references

Runtime evidence lives outside the definition repo under `$LAB_ROOT`.
Evidence path references in ledgers may use the `$LAB_ROOT` prefix (for
example `$LAB_ROOT/evidence/openhands/oh-001d/...`). The definition repo
must not absorb runtime logs, runtime state, or secrets. A ledger records
the path and the SHA-256 of the external evidence, not its contents.

## Ledger identity and finite closure

A ledger belongs to its original Work ID for the life of that work. Updates
made while the work is open are lifecycle-maintenance of that same work,
not new work IDs. The work's ordinary implementation, publication, merge,
and runtime/acceptance events are appended to that same ledger through its
lifecycle.

### Ledger maintenance workflow

Ledger maintenance must still use a detached candidate, independent review,
deterministic verification, human commit approval, publication approval,
remote branch, draft PR, and human merge. Ledgers are not mutated directly
on canonical `main` outside the governed workflow. Maintenance remains part
of the same Work ID; it does not spawn a new work item for each update.

### Closure ledger transaction (recursion terminator)

After a work reaches its substantive terminal condition (for example
runtime/mission acceptance, or doc-only mission completion), at most one
dedicated **closure ledger transaction** is performed for that Work ID if
post-merge/post-runtime facts were not already canonical. That transaction
records the exact substantive work merge SHA, the canonical sync SHA if
applicable, the runtime acceptance evidence, and the exact **accepted
canonical head**, then marks the work CLOSED.

The closure ledger transaction's own Git carrier commit, branch, PR, and
merge are NOT a new work item and do NOT require another self-referential
ledger update. The closure transaction is proven by canonical Git history
containing the CLOSED ledger blob; its own carrier merge SHA need not be
embedded inside itself. Carrier metadata may be discoverable from Git
history or later index maintenance, but closure does not depend on
embedding the closure transaction's own merge SHA inside itself. This is
the explicit recursion terminator: closure is finite, not infinitely
self-recording.

### accepted canonical head

`accepted canonical head` is the exact canonical commit whose substantive
artifacts or runtime behavior were actually accepted. It is distinct from
any later bookkeeping-only ledger carrier merge and from `current canonical
head` (which is only a snapshot of canonical state at update time).

### Non-self-referential binding

A ledger file that is itself part of a candidate cannot embed that same
candidate's final fingerprint, file SHAs, review ID, verification ID, or
evidence bundle before freeze/review/verification, because writing those
values changes the candidate and invalidates the binding. The normative
rule must not require an impossible fixed point.

- Operational gate evidence — candidate fingerprint, review ID,
  verification ID, evidence bundle, detached commit, branch, PR, and merge
  — is authoritative when produced by the governing tool/Git/runtime, even
  if it cannot yet be embedded in the unchanged candidate being gated.
- If the work ledger is inside the candidate being gated, values that only
  exist after freeze/review/verification/commit MUST be recorded as
  `pending external binding` in that candidate and backfilled in the next
  governed ledger-maintenance update or the finite closure ledger
  transaction.
- Never mutate a reviewed/verified candidate merely to embed the
  review/verification evidence for that same candidate; doing so
  invalidates the binding. The binding is produced externally, not by
  self-embedding.
- The ledger-maintenance carrier candidate's own fingerprint/file
  SHA/review/verification/commit/merge metadata is not required to be
  self-embedded. It remains externally content-addressed and auditable
  through LabBridge/Git history. This is a second explicit
  recursion/self-reference terminator, alongside the finite closure
  transaction.
- Before a Work ID can be marked CLOSED, the canonical ledger MUST contain
  all substantive work bindings/evidence required for reconstruction:
  substantive candidate fingerprint/path manifest (if applicable),
  review/verification/bundle, substantive commit/publication/PR/merge,
  accepted canonical head, runtime acceptance or mission-completion
  evidence, and failures/recoveries. Only the bookkeeping carrier's own
  self-binding metadata is exempt.

## Recovery protocol after interrupted mutations

When a tool or session interruption occurs during a mutation (for example a
JSON-RPC session terminated mid-commit):

1. Record the interruption in the Event Ledger with actor, action,
   timestamp (or `not recorded`), and the transport failure.
2. Inspect authoritative state first — the candidate job, the fingerprint,
   and the canonical head — before any retry.
3. Retry idempotently only if inspection shows no mutation occurred.
4. If a mutation did occur, do not replay it; reconcile against
   authoritative state instead.
5. Record the resolution (retried successfully, already applied, or
   abandoned) with the binding evidence.

## Template

The fenced block below is the reusable ledger template. Copy it into
`docs/ledger/<WORK-ID>.md` and fill the fields. `not recorded` is the
correct value for any unknown timestamp or SHA; never invent one. If the
ledger file is itself part of the candidate being gated, use `pending
external binding` for the candidate fingerprint, file SHAs, review/verdict,
verification/result, evidence bundle, and commit/branch/PR/merge values,
because embedding those values would change the candidate and invalidate
the binding (see "Non-self-referential binding"). These are backfilled at
the next governed maintenance point or the closure ledger transaction;
they are compliant, not omissions.

```markdown
# Work Ledger — <WORK-ID>

- Work ID: <WORK-ID>
- title: <short mission title>
- component/area: <area>
- steward: <human steward>
- status: PROPOSED
- opened_at: <absolute date or not recorded>
- closed_at: open
- canonical base: <40-hex SHA or not recorded>
- current canonical head: <current canonical repo head at update time, or not known>
- ledger version: 1

## Mission/Scope

<what this work item is and is not; explicit non-goals>

## Guardrails

<constraints, isolation boundaries, authorized tools>

## Current State/Next Gate

<current status and the next gate that must pass>

## Artifact Manifest

- base SHA: <40-hex or not recorded>
- changed paths: <exact paths>
- candidate job: <job id or not recorded>
- candidate fingerprint: <sha256, or pending external binding if this ledger is inside the candidate>
- file SHAs: <path -> sha256, or pending external binding if this ledger is inside the candidate>

## Decision Log

- <timestamp or not recorded> — <actor> — <decision> — <rationale>

## Event Ledger

| timestamp | actor | action/gate | evidence/binding | outcome | next gate |
| --- | --- | --- | --- | --- | --- |
| <ts or not recorded> | <actor> | <gate> | <binding> | <outcome> | <next gate> |

## Candidate/Review/Verification Evidence

- candidate job: <id>
- fingerprint: <sha256, or pending external binding>
- review ID: <id> — verdict: <APPROVE/REJECT, or pending external binding>
- verification ID: <id> — result: <PASS/FAIL, or pending external binding>
- evidence bundle: <sha256, or pending external binding>

## Commit/Publication/PR/Merge Evidence

- detached commit: <sha or not recorded, or pending external binding>
- branch: <name or not recorded, or pending external binding>
- PR: <url/number or not recorded, or pending external binding>
- merge SHA: <sha or not recorded, or pending external binding>
- canonical sync SHA: <sha or not recorded, or pending external binding>

## Runtime/Acceptance Evidence

- evidence path: <$LAB_ROOT/... or not recorded>
- evidence SHA-256: <sha256 or not recorded>
- verdict: <PASS/FAIL or pending (reason)>

## Failures/Rejections/Recoveries

- <failed attempt / rejected evidence / recovery, with explicit status>

## Deferred Risks/Follow-ups

- <known risks and follow-ups not closed by this work>

## Closure

<closure evidence and final canonical state, or pending (remaining gates)>
- accepted canonical head: <canonical commit whose artifacts/runtime were accepted, or not recorded>
```