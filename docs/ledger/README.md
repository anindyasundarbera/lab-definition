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
| AL-WL-001 | Establish Agent Lab governed work ledger | CLOSED | [docs/ledger/AL-WL-001.md](AL-WL-001.md) |
| AL-ARCH-001 | Establish the Shared Agent Lab architectural direction | CLOSED | [docs/ledger/AL-ARCH-001.md](AL-ARCH-001.md) |
| OH-001D | OpenHands standalone materialization, lifecycle, and acceptance | MERGED / ACCEPTANCE_PENDING (open) | [docs/ledger/OH-001D.md](OH-001D.md) |

AL-WL-001 is the bootstrap adoption ledger for this ledger system itself.
It is CLOSED: its substantive terminal condition (canonicalization of the
five ledger-system docs) is met. LabBridge canonicalization verdict is
CANONICAL, method `exact_commit_ancestor`; the substantive commit
`e70b978369ed394953bf60271fc4c9ea850715bd` is reachable from origin `main`
tip `f6db7511634adba2204937e5bdaa365e24541ae8`. Accepted canonical head:
`e70b978369ed394953bf60271fc4c9ea850715bd`. The original candidate's exact
evidence (fingerprint `0ea6c732...`, review `b2d17142...`, verification
`42376a14...`, bundle `59193f88...`, detached commit `e70b978...`, branch
`agent/al-wl-001-governed-work-ledger`) was backfilled by the Phase 0 finite
closure ledger transaction. PR/merge are `not recorded` (no PR record in
LabBridge; not fabricated). The closure carrier's own self-binding metadata
is not self-embedded (recursion terminator; see `docs/WORK-LEDGER.md`).

AL-ARCH-001 is the shared Agent Lab architectural direction ledger. It is
CLOSED: its substantive terminal condition (canonicalization of the
architecture direction docs) is met. LabBridge canonicalization verdict is
CANONICAL, method `exact_commit_ancestor`; the substantive commit
`89e6a3d3f227437a0b5bbd5aa151d619b68674d5` is reachable from origin `main`
tip `f6db7511634adba2204937e5bdaa365e24541ae8`. Accepted canonical head:
`89e6a3d3f227437a0b5bbd5aa151d619b68674d5`. The original candidate's exact
evidence (fingerprint `9b0db7dc...`, review `f1dde982...`, verification
`d9a7c1d6...`, bundle `a765725c...`, detached commit `89e6a3d3...`, branch
`agent/al-arch-001-shared-lab-direction`) was backfilled by the Phase 0
finite closure ledger transaction. PR/merge are `not recorded` (no PR record
in LabBridge; not fabricated). The closure carrier's own self-binding
metadata is not self-embedded (recursion terminator; see
`docs/WORK-LEDGER.md`).

OH-001D's Stage 5 correction commit
(`ed8e789087225b976f5c84c5b2caf3de5e22a90f`) is canonical on `main`: LabBridge
canonicalization verdict is CANONICAL, method `exact_commit_ancestor`, with
the exact commit reachable from origin `main` tip
`f6db7511634adba2204937e5bdaa365e24541ae8` (publication branch
`agent/oh-001d-stage5-runtime-boundary-fix`; PR/merge `not recorded` in
LabBridge, not fabricated). Canonical implementation is not runtime
acceptance: the corrected Stage 5 host lifecycle acceptance run is the next
gate and remains pending, so the mission is OPEN / ACCEPTANCE_PENDING. The
rejected false outer PASS evidence is preserved auditably and is not
reinterpreted as success. The prior Stage 5 lifecycle boundary candidate is
merged on canonical as `0de668801979db3b180e7f41159189cdd3f4ed5f`. Later
gates (Stage 6 genuine standalone action, Stage 7 repeated fresh lifecycle,
permanent lab test openhands) are blocked until corrected Stage 5 acceptance
passes and are outside Phase 0.

## Phase 0 reconciliation candidate — combined authorization

The Human Steward explicitly authorized **one Phase 0-only reconciliation
candidate** covering three Work IDs under an exact five-path ceiling:
finite closure ledger maintenance for **AL-WL-001** and **AL-ARCH-001**
(backfilling their original substantive evidence and marking them CLOSED),
plus lifecycle maintenance for **OH-001D** (reconciling its correction as
canonical while preserving OPEN / ACCEPTANCE_PENDING). A single candidate
covers three Work IDs because this is one authorized ledger-reconciliation
transaction, not three separate work items; no new Work ID is created. This
reconciliation carrier's own review/verification/fingerprint/commit
bindings are external LabBridge evidence and are intentionally not
self-embedded in this candidate (non-self-referential / finite-closure
recursion terminators; see `docs/WORK-LEDGER.md`). No current or stale
carrier review ID, verdict, or follow-up claim is embedded here.

## Canonical component state snapshot

This is the minimal canonical-state snapshot for future reconstruction as
of the Phase 0 reconciliation (current canonical head
`f6db7511634adba2204937e5bdaa365e24541ae8`). It records state, not
architecture changes; architecture responsibility boundaries are preserved
(OpenHands = execution; Serena = semantic intelligence; Dagger =
deterministic verification; Temporal = durable lifecycle; Governance =
authorization; Ledger = institutional history; Control Plane = typed
coordination/delegation).

- **Serena** — ACCEPTED semantic intelligence; regression baseline accepted.
  Upstream/version binding (repository-supported in
  `manifests/components.toml` `[components.serena]`): `v1.6.1`, commit
  `bcac0969fb8685783ea6d0f2642468fcc47e6395`. No additional evidence is
  invented here.
- **OpenHands** — experimental/advanced MVP, `enabled = false`,
  `status = "experimental"`; standalone acceptance NOT COMPLETE (OH-001D
  ACCEPTANCE_PENDING; corrected Stage 5 host acceptance not yet run).
- **Dagger** — NOT ADOPTED (`enabled = false`).
- **Temporal** — NOT ADOPTED (`enabled = false`).
- **Unified candidate/job contract** — NOT IMPLEMENTED.
- **Permanent Agent Lab control plane** — NOT IMPLEMENTED.

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