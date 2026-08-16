# Work Ledger — AL-ARCH-001

- **Work ID:** AL-ARCH-001
- **Title:** Establish the Shared Agent Lab architectural direction
- **Component / area:** architecture / shared-lab direction
- **Steward:** Human Steward (Agent Lab)
- **Status:** CANDIDATE_READY
- **Opened at:** 2026-08-16 (exact time not recorded)
- **Closed at:** open
- **Canonical base:** `0de668801979db3b180e7f41159189cdd3f4ed5f`
- **Current canonical head:** `0de668801979db3b180e7f41159189cdd3f4ed5f`
- **Ledger version:** 1

## 1. Mission / Scope

**Mission.** Establish the shared, server-hosted, multi-device /
multi-person Agent Lab as the **strategic architecture direction** from
today onward — encoded as normative documentation and design constraints
— while the current single-user, single-node local deployment remains a
valid, supported profile. The strategic target is **one durable / shared
Agent Lab** serving multiple clients and potentially multiple authorized
humans/teams, rather than a separate isolated lab installation per
person or device. Local, independent, and offline lab instances remain
supported profiles; shared is the direction, not an irreversible
centralized monopoly.

**Architecture direction applies from today to future design decisions.**
Every future choice of tool, component, API, storage, or contract must be
evaluated against this direction (see `docs/SHARED-LAB-DIRECTION.md`,
"Architecture review rule").

**Scope.** This is documentation-only architecture / governance work. It
does **not** claim that shared, multi-user, or remotely accessible
service functionality exists today. No code, manifests, config, scripts,
`README.md`, `AGENTS.md`, `WORK-LEDGER.md`, or existing ledgers are
modified. No Docker, tests, web, or runtime commands are run. No commit,
push, merge, tag, or publish is performed.

Exact authorized changed-path ceiling (three paths only):

1. `docs/SHARED-LAB-DIRECTION.md` — new
2. `docs/PORTABILITY.md` — update
3. `docs/ledger/AL-ARCH-001.md` — new (this file)

No fourth path is touched. Candidate bound to canonical base
`0de668801979db3b180e7f41159189cdd3f4ed5f`.

## 2. Guardrails

- **Authority.** The Human Steward (Agent Lab) is the **authorizer** of
  this direction. The orchestrator/delegator that produced this candidate
  (`ChatGPT (orchestrator/delegator)`) only encoded the Steward's
  direction; it is not itself an authorizer and confers no authority
  beyond what the Steward has granted.
- **Documentation-only.** No runtime, build, install, image pull, network
  exposure, or acceptance execution is authorized or implied by this Work
  ID.
- **Three-path ceiling.** Only the three paths listed in section 1 may
  change. No fourth path.
- **No premature functionality claim.** This direction creates no claim
  that shared, multi-user, tenancy, or remote-access functionality exists
  today (see section 9).
- **Security principles preserved.** Local services may remain
  loopback-only until a governed remote-access gateway exists; internal
  services must not be exposed merely to satisfy future direction.
- **Non-self-referential binding rule (self-contained).** This ledger
  cannot self-embed the candidate's own final fingerprint, file SHAs,
  review, verification, bundle, commit, branch, PR, or merge values
  without invalidating the reviewed state — embedding a value that is a
  function of the file's own contents would either change those contents
  (making the value stale) or freeze the file around a self-asserted
  value that no external gate has confirmed. Such values are therefore
  recorded as `pending external binding` and must be backfilled by later
  governed maintenance after an independent review establishes them.
- **Finite closure rule (self-contained).** Closure of this Work ID may
  use one finite bookkeeping / closure update and need not recursively
  self-record that closure carrier's own identity; a closure step is not
  required to re-enter the non-self-referential binding discipline for
  its own bookkeeping record.
- **No implementation authorization for deferred follow-ups.** Listing a
  follow-up in section 11 does not authorize building it.

## 3. Current State / Next Gate

- **Current state:** CANDIDATE_READY. All three authorized documents are
  prepared within the three-path ceiling. The architecture direction is
  encoded in `docs/SHARED-LAB-DIRECTION.md`; portability is expanded in
  `docs/PORTABILITY.md`; this ledger uses this work's governed ledger
  structure (12 sections, self-contained).
- **Next gate:** fresh independent review. A prior independent review
  found an unsupported authority reference in an earlier draft of this
  ledger (see section 10); that finding was corrected by making this
  ledger self-contained, which makes the prior review stale. A fresh
  independent review must verify the three documents and this ledger
  against the Steward direction before any canonicalization. The
  candidate's review and verification bindings remain
  `pending external binding` until that gate completes.
- **Substantive terminal condition:** canonicalization of the
  architecture direction (accepted canonical head), followed by finite
  governed ledger closure maintenance if required. No runtime acceptance
  is part of this terminal condition (see section 9).

## 4. Artifact Manifest

| Path | Kind | Status | Fingerprint / file SHA |
|------|------|--------|------------------------|
| `docs/SHARED-LAB-DIRECTION.md` | new | candidate | pending external binding |
| `docs/PORTABILITY.md` | update | candidate | pending external binding |
| `docs/ledger/AL-ARCH-001.md` | new | candidate | pending external binding |

Candidate bundle fingerprint: pending external binding. File SHAs and
bundle fingerprint are not self-embedded (section 2, non-self-referential
binding rule); they are to be established by the fresh independent review
gate.

## 5. Decision Log

1. **Strategic target set to shared lab.** Human Steward (Agent Lab)
   directed that Agent Lab's end state is a durable/shared,
   server-hosted lab serving multiple clients and potentially multiple
   authorized humans/teams, not a permanently single-user/single-device
   lab. Local single-node remains a supported profile, not the ceiling.
2. **Direction is normative, not an implementation promise.** The
   direction constrains shape from today; it does not schedule shared,
   multi-user, or remote-access features (non-goals recorded in
   `docs/SHARED-LAB-DIRECTION.md`).
3. **Foundational principle: no avoidable migration blockers.** Today's
   components must not create needless barriers to shared/multi-device/
   multi-user deployment; where a local-only and a shared-preserving form
   are equally practical, prefer the shared-preserving form.
4. **Three-path documentation-only scope.** Only the two direction docs
   and this ledger change; no code, manifests, config, scripts, or
   existing governance docs are touched.
5. **Non-self-referential and finite closure rules stated in-ledger.**
   The non-self-referential binding rule and finite closure rule are
   stated directly in this ledger (section 2) in self-contained terms,
   rather than by appeal to any external normative document.
6. **Ledger structure is this work's governed structure.** The 12-section
   ledger structure is this work's governed ledger structure; no external
   normative citation is claimed for it.
7. **Unsupported authority reference removed.** An earlier draft cited a
   non-canonical external ledger design as normative authority; that
   citation was removed and the ledger made self-contained after a
   review finding (see section 10).

## 6. Event Ledger

| timestamp | actor | action/gate | evidence/binding | outcome | next gate |
|-----------|-------|-------------|------------------|---------|-----------|
| 2026-08-16 | Human Steward (Agent Lab) | Steward direction and authorization | Steward direction recorded; Steward is authorizer; ChatGPT (orchestrator/delegator) is not an authorizer | Shared/server-hosted multi-device/multi-person lab established as strategic target; local profile preserved | Encode direction |
| 2026-08-16 | ChatGPT (orchestrator/delegator) | Base binding | canonical base `0de668801979db3b180e7f41159189cdd3f4ed5f` (current canonical head at open) | Candidate bound to canonical base | Encode direction |
| 2026-08-16 | ChatGPT (orchestrator/delegator) | Shared-lab direction encoded | `docs/SHARED-LAB-DIRECTION.md` created; fingerprint pending external binding | Strategic end state, design principle, architectural constraints, deployment profiles, non-goals, review rule, and preserved security principles recorded | Expand portability |
| 2026-08-16 | ChatGPT (orchestrator/delegator) | Portability expanded | `docs/PORTABILITY.md` updated; fingerprint pending external binding | Objective and acceptance criterion expanded to cover server-hosted reconstruction with attached clients; existing rules preserved | Bring ledger into governed structure |
| 2026-08-16 | ChatGPT (orchestrator/delegator) | Ledger brought into governed structure | `docs/ledger/AL-ARCH-001.md` rewritten to 12-section governed ledger structure; fingerprint pending external binding | Ledger uses this work's governed structure; abbreviated-structure finding corrected | Candidate ready |
| 2026-08-16 | ChatGPT (orchestrator/delegator) | Candidate ready | status set to CANDIDATE_READY; all three documents prepared within three-path ceiling | Candidate ready for independent review | Independent review (prior) |
| 2026-08-16 | independent review (prior) | Independent review gate | review and verification bindings pending external binding; review ID not embedded because a later file change makes this review stale | Prior review found unsupported authority reference to a non-canonical external ledger design | Review-requested correction |
| 2026-08-16 | ChatGPT (orchestrator/delegator) | Review-requested correction | unsupported authority reference removed; ledger made self-contained; non-self-referential and finite closure rules stated in-ledger; prior review made stale by file change, so its ID is not embedded | Ledger self-contained; ready for re-review | Fresh independent review |
| pending | fresh independent review | Fresh independent review gate | review and verification bindings pending external binding | pending | Canonicalization (terminal condition) |

## 7. Candidate / Review / Verification Evidence

- **Candidate final fingerprint:** pending external binding
- **Candidate file SHAs:** pending external binding
- **Candidate bundle fingerprint:** pending external binding
- **Independent review ID:** pending external binding
- **Independent review outcome:** pending external binding
- **Verification result:** pending external binding

Per the non-self-referential binding rule (section 2), these values are
not self-embedded; they are to be established by the fresh independent
review gate and backfilled by later governed maintenance.

## 8. Commit / Publication / PR / Merge Evidence

- **Commit:** pending external binding
- **Branch:** pending external binding
- **PR:** pending external binding
- **Merge:** pending external binding
- **Publication / tag:** pending external binding
- **Accepted canonical head:** pending external binding

No commit, push, merge, tag, or publication has been performed. These
bindings are to be established by the fresh independent review and
canonicalization gate.

## 9. Runtime / Acceptance Evidence

Documentation-only. No runtime, build, install, image pull, network
exposure, or acceptance execution is authorized, performed, or claimed.
No runtime acceptance claim is made.

The **substantive terminal condition** for this Work ID is
**canonicalization of the architecture direction** (an accepted canonical
head recorded in section 8), followed by **finite governed ledger closure
maintenance if required** (per the finite closure rule in section 2).
Runtime acceptance is not part of this terminal condition because this
work introduces no runtime component.

## 10. Failures / Rejections / Recoveries

Two pre-review governance findings were corrected; neither is a
substantive architecture failure, and no candidate was committed or
published at any point.

a. **Abbreviated first ledger draft (corrected before review).** The
   first draft of this ledger used an abbreviated structure missing
   required header fields, required section ordering, and required
   sections (such as Artifact Manifest, Decision Log, and a tabular
   Event Ledger). This was a governance-format deficiency. It was
   corrected by rewriting `docs/ledger/AL-ARCH-001.md` into the full
   12-section governed ledger structure before independent review.

b. **Unsupported authority reference found by independent review
   (corrected before fresh review).** A subsequent draft cited a
   non-canonical external ledger design as the normative authority for
   this ledger's structure and for the non-self-referential and finite
   closure rules. Independent review correctly noted that the referenced
   design is not canonical in this repository, so this ledger must not
   appeal to it as an existing normative/canonical authority. The
   citation was removed and the ledger was made self-contained: the
   12-section structure is described as this work's governed ledger
   structure, and the non-self-referential and finite closure rules are
   stated directly in section 2 in self-contained terms. Because
   correcting the file changes its contents, the prior review that found
   this issue is now stale; its review ID is therefore not embedded
   here, and the next gate is a fresh independent review (see section 6).
   This description records the finding without a self-reference.

- **No candidate was committed or published.** No commit, push, merge,
  tag, or publication occurred at any point, so no published artifact
  needs rejection or retraction.
- **No substantive architecture failure.** The architecture direction
  documents (`docs/SHARED-LAB-DIRECTION.md`, `docs/PORTABILITY.md`) are
  preserved byte-for-byte through these corrections; only this ledger
  was rewritten.

## 11. Deferred Risks / Follow-ups

Recorded as future architectural work the direction points toward. **No
implementation authorization is implied** by listing any item here.

- **Identity / RBAC architecture.** Explicit actor/user/service identity,
  roles, and permissions capable of supporting multiple authorized
  humans/teams later without weakening existing Steward gates.
- **Remote TLS / auth gateway.** Authenticated, TLS-terminating ingress
  in front of today's loopback-bound services; required before any
  remote exposure, under separate Steward authorization.
- **Tenant / project isolation.** Project/workspace/tenant isolation and
  ownership; no assumption of one global mutable workspace.
- **Durable orchestration / shared storage.** Durable lifecycle/state
  beyond one workstation filesystem; explicit state classes and
  export/import; no process-local-only truth for important work.
- **Scheduling / quotas.** Compute/resource scheduling and quotas;
  schedulable, non-exclusive GPU/CPU/runtime identity.
- **Stable actor identities / cryptographic transparency.** Audit and
  work-ledger records using stable actor identities, structured for later
  signing / hash chaining / Merkle transparency anchoring (Git + hashes
  + signatures + transparency-log preferred first).
- **Distributed / federated profile.** Multiple lab nodes and independent
  lab instances for isolation or offline operation.
- **Blockchain only if future cross-party trust requires it.** A
  distributed-ledger / blockchain shared-trust evolution is not required
  now and is recorded only as a possible future step when independent
  teams/nodes need mutually verifiable attestations.

## 12. Closure

**Closure: pending.**

Closure requires:

1. The fresh independent review gate (section 6, final row) to complete,
   with review and verification bindings transitioning from
   `pending external binding` to externally bound values (section 7).
2. Canonicalization of the architecture direction, with commit/branch/PR/
   merge and accepted canonical head bindings transitioning from
   `pending external binding` to externally bound values (section 8).
3. Finite governed ledger closure maintenance if required (per the finite
   closure rule in section 2); this one closure update need not
   recursively self-record its own identity.

No canonicalization, merge, promotion, or closure is implied by
`CANDIDATE_READY`. Accepted canonical head: pending external binding.