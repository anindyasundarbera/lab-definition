# Agent Lab Work Ledgers

This directory holds the durable work ledgers for governed Agent Lab work
items. Each work item has one ledger file named `<WORK-ID>.md` recording
its full lifecycle, evidence, failures, recoveries, and closure.

The ledger rule, normative schema, status vocabulary, event-row contract,
recovery protocol, and reusable template are defined in
`docs/WORK-LEDGER.md`. `AGENTS.md` states the binding requirement that
every governed work item has a ledger here.

## Naming

Ledger filenames use stable work-order IDs (for example `OH-001D.md`).
The ID is the filename stem and never changes across the life of the work.
Related stages of one mission are recorded as chronological events within
the single ledger for that work ID, not as separate files.

## Index

| Work ID | Title | Status | Ledger |
| --- | --- | --- | --- |
| AL-WL-001 | Establish Agent Lab governed work ledger | CANDIDATE_READY | [docs/ledger/AL-WL-001.md](AL-WL-001.md) |
| OH-001D | OpenHands standalone materialization, lifecycle, and acceptance | COMMITTED / ACCEPTANCE_PENDING | [docs/ledger/OH-001D.md](OH-001D.md) |

AL-WL-001 is the bootstrap adoption ledger for this ledger system itself.
It is CANDIDATE_READY: candidate fingerprint and review/verification/commit/
publication/PR/merge are pending until candidate freeze and independent
review. Because `docs/ledger/AL-WL-001.md` is itself one of the files inside
its own candidate, those values are intentionally recorded as `pending
external binding` — embedding them before freeze would change the
candidate and invalidate the binding. They are backfilled after
freeze/review/verification/merge per the non-self-referential binding rule;
this is compliant, not an omission (see `docs/WORK-LEDGER.md`).

OH-001D's current Stage 5 correction commit exists as a detached commit
(`ed8e789087225b976f5c84c5b2caf3de5e22a90f`) but is unpublished. The next
gate for OH-001D is Human Steward **publication approval** for
`ed8e789087225b976f5c84c5b2caf3de5e22a90f`: it has not been pushed and has
not been merged to canonical. After publish/PR/merge, a guarded canonical
sync and a corrected Stage 5 host acceptance run remain; Stage 5 acceptance
is pending, so the mission is ACCEPTANCE_PENDING. The prior Stage 5
lifecycle boundary candidate is merged on canonical as
`0de668801979db3b180e7f41159189cdd3f4ed5f`.

## Adding new work

New governed work must:

1. create `docs/ledger/<WORK-ID>.md` from the template in
   `docs/WORK-LEDGER.md` at authorization or start;
2. maintain it at every material lifecycle gate per `AGENTS.md`; and
3. add or update its row in the index table above.

Ledger maintenance follows the normal governed workflow (detached candidate,
review, verification, human approval, publication, PR, human merge) and is
not mutated directly on canonical `main` outside that workflow. Maintenance
remains part of the same Work ID; it does not spawn a new work item per
update. Closure is finite: at most one closure ledger transaction after the
substantive terminal condition, and its own carrier merge is not recursively
self-recorded (recursion terminator; see `docs/WORK-LEDGER.md`).