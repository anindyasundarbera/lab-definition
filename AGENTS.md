# Agent Lab Agent Conduct

Agent Lab work is governed. Every governed work item produces a durable
ledger so that any later agent or steward can reconstruct exactly what
happened, what was authorized, what evidence exists, what failed and
recovered, and which gate is next. The ledger is institutional memory, not
a scratchpad.

## Work ledger rule

Every governed Agent Lab work item MUST have exactly one ledger file at
`docs/ledger/<WORK-ID>.md`. The ledger is created at authorization or start,
or retroactively when this rule is adopted for work already in flight. A
work item with no ledger is not a governed work item.

The ledger is updated at every material lifecycle gate, including but not
limited to:

- authorization
- base binding
- candidate creation and fingerprint
- independent review
- deterministic verification
- evidence bundle
- human commit approval
- detached commit
- publication approval
- remote branch
- draft PR
- human merge
- canonical sync
- host/runtime acceptance
- rejection, blocker, or recovery
- closure

Every material gate must be captured in authoritative external evidence
immediately when it happens (by the governing tool, Git, or runtime) and
backfilled into the ledger at the next governed maintenance point. No work
may be marked CLOSED until all substantive gates are canonical in the
ledger. Operational gate evidence is authoritative when produced by the
governing tool/Git/runtime even if it cannot yet be embedded in the
unchanged candidate being gated.

## Integrity rules

- Never silently rewrite or remove a failed attempt. Append to it or
  supersede it with an explicit status and evidence. Failed evidence is
  evidence; it stays in the ledger marked rejected/superseded.
- Never store secrets, raw credentials, private tokens, or secret-bearing
  command output in the ledger or any committed artifact.
- Canonical source-of-truth priority: exact commit SHAs, fingerprints,
  changed paths, evidence IDs, and hashes outrank prose summaries. When
  prose and an exact binding disagree, the binding wins.
- Gate separation is mandatory and is never collapsed:
  - review and verification are not commit approval;
  - commit is not publication approval;
  - a PR is not a merge;
  - implementation is not runtime/mission acceptance.
- Work cannot be called CLOSED or ACCEPTED until its ledger records the
  closure evidence and the final canonical state.
- When a tool or session interruption occurs during a mutation, record the
  interruption and verify authoritative state before retrying the mutation.

## Ledger identity and finite closure

A ledger belongs to its original Work ID for the life of that work.
Updates made while the work is open are lifecycle-maintenance of that same
work, not new work IDs. The work's ordinary implementation, publication,
merge, and runtime/acceptance events are appended to that same ledger
through its lifecycle.

After a work reaches its substantive terminal condition (for example
runtime/mission acceptance, or doc-only mission completion), at most one
dedicated **closure ledger transaction** is performed for that Work ID if
post-merge/post-runtime facts were not already canonical. That transaction
records the exact substantive work merge SHA, the canonical sync SHA if
applicable, the runtime acceptance evidence, and the exact **accepted
canonical head** — the canonical commit whose substantive artifacts or
runtime behavior were actually accepted — and then marks the work CLOSED.

The closure ledger transaction's own Git carrier commit, branch, PR, and
merge are NOT a new work item and do NOT require another self-referential
ledger update. The closure transaction is proven by canonical Git history
containing the CLOSED ledger blob; its own carrier merge SHA need not be
embedded inside itself. This is the explicit recursion terminator: closure
is finite, not infinitely self-recording.

`accepted canonical head` is distinct from any later bookkeeping-only
ledger carrier merge. Ledger maintenance still uses a detached candidate,
independent review, deterministic verification, human commit approval,
publication approval, PR, and human merge; the non-recursion rule only
means the maintenance remains part of the same Work ID and the closure
carrier metadata is not recursively self-recorded.

## Non-self-referential binding rule

A ledger file that is itself part of a candidate cannot embed that SAME
candidate's final fingerprint, file SHAs, review ID, verification ID, or
evidence bundle before freeze/review/verification, because writing those
values changes the candidate and invalidates the binding. The normative
rule must not require an impossible fixed point.

- Operational gate evidence — candidate fingerprint, review ID,
  verification ID, evidence bundle, detached commit, branch, PR, and merge
  — is authoritative when produced by the governing tool/Git/runtime, even
  if it cannot yet be embedded in the unchanged candidate being gated.
- If the work ledger is itself inside the candidate being gated, values
  that only exist after freeze/review/verification/commit MUST be recorded
  as `pending external binding` in that candidate and backfilled in the next
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
  recursion/self-reference terminator.
- Before a Work ID can be marked CLOSED, the canonical ledger MUST contain
  all substantive work bindings/evidence required for reconstruction:
  substantive candidate fingerprint/path manifest (if applicable),
  review/verification/bundle, substantive commit/publication/PR/merge,
  accepted canonical head, runtime acceptance or mission-completion
  evidence, and failures/recoveries. Only the bookkeeping carrier's own
  self-binding metadata is exempt.

## Normative schema and workflow

The ledger schema, status vocabulary, required sections, event-row
contract, evidence-path conventions, recovery protocol, and a reusable
template are defined in `docs/WORK-LEDGER.md`. That document is normative
for all ledgers under `docs/ledger/`.