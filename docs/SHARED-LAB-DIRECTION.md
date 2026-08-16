# Agent Lab Shared-Lab Architectural Direction

## Status and authority

This document is a **normative architectural direction**, not an
implementation promise. It records the strategic end state the Human
Steward has authorized for Agent Lab and the design constraints that
follow from it **from today onward**. It creates no claim that any
shared, multi-user, or remotely accessible service exists today. The
current deployment remains a single-user, single-node local lab; that
profile remains valid and supported.

Authority for this direction is the **Human Steward (Agent Lab)**. The
orchestrator/delegator that produced this document is not the authorizer;
it encodes Steward direction, it does not grant it.

## Strategic end state

The intended end state is **one durable, shared Agent Lab** — a
server-hosted (or durable-shared-environment-hosted) control plane and
lab services usable **concurrently by multiple devices** and,
**eventually, by multiple authorized people or teams** — rather than a
separate isolated lab installation duplicated for every person or
device.

The local single-node/single-user deployment that exists today remains a
**supported deployment profile**, not the architectural ceiling. It is
the simplest profile of the same architecture, not a divergent product.

Shared is the **direction**, not an irreversible centralized monopoly.
The architecture must still permit **independent lab instances** where
isolation, offline operation, or organizational separation is desired.
The goal is that shared operation is always *possible*; it is not that
every lab must be a single shared instance.

## Foundational design principle

Build today's components so they do not create **avoidable migration
blockers** toward shared operation. When a present-day choice would be
equally practical in either a local-only or a shared-preserving form,
prefer the shared-preserving form. This is a forward-compatibility
discipline applied to architecture and contracts, not a mandate to
implement shared features now.

## Architectural consequences and design constraints (from today)

The following constraints apply to new and evolving components, APIs,
storage, and contracts from today. They describe shape, not
implementation; none of them authorizes building the named subsystems
now (see "Non-goals now").

### Identity

- Use **explicit actor / user / service identity**. Do not assume a
  single implicit host user. Records, requests, jobs, and evidence must
  carry an identifiable actor rather than "the lab" or "the machine".

### Authentication and authorization

- Design **authentication and authorization boundaries suitable for
  remote/shared use**. Even where the current deployment has no auth
  because it binds to loopback, contracts must not assume an
  unauthenticated single principal.

### Roles, permissions, and governance

- The **role/permission model and Human Steward governance** must remain
  capable of supporting multiple authorized humans/teams later **without
  weakening existing gates**. Steward authorization, candidate review,
  and acceptance gates must not be refactored into a single-principal
  assumption that would later require weakening to admit a second
  principal.

### Project / workspace / tenant isolation

- Support **project/workspace/tenant isolation and ownership**. Do not
  assume one global mutable workspace shared by all work. Workspaces,
  projects, and their state must be separable and attributable.

### Concurrency, jobs, and durable lifecycle

- Use **concurrency-safe locking, explicit job identity, idempotency,
  and durable lifecycle/state**. No process-local-only truth for
  important work. If a process restarts, or a second client connects,
  in-flight and completed work must remain coherent.

### Canonical state and evidence provenance

- **Canonical state and evidence must identify actor, work ID, project,
  candidate, and provenance.** Records that today attribute actions to
  "the agent" or "the host" must be shaped so they can later attribute
  actions to a specific actor within a specific project/context.

### Secrets

- **Secrets must be scoped**, not held in one undifferentiated
  lab-global secret namespace. Today's per-host secret restoration may
  remain, but secret identity and access must be structured so that
  future multi-user/multi-project separation does not require a
  breaking rework of the secret model.

### Service interfaces

- Prefer **remote-capable service interfaces**. Avoid embedding
  localhost/single-device assumptions (fixed loopback hostnames,
  in-process-only calls, single-client assumptions) into contracts,
  even when the current deployment binds services to loopback for
  security. Binding to loopback is a deployment choice; the contract
  above it must remain transport-neutral.

### Network boundary

- The **network boundary must allow secure TLS / authenticated remote
  ingress later**. Today's loopback-only services may remain behind a
  future gateway/proxy; nothing in current contracts may preclude
  placing an authenticated, TLS-terminating gateway in front of them.

### Storage and state classes

- Use **durable/shared storage interfaces and explicit state classes**
  (reconstructible, portable persistent, disposable — as already
  defined in `docs/PORTABILITY.md`). Do not rely on one workstation
  filesystem as institutional truth. The lab definition must remain
  sufficient to reconstruct state, but durable persistent state must be
  exportable/importable to a shared host.

### Compute and resource scheduling

- **Compute/resource scheduling and quotas should remain possible.** Do
  not hardwire exclusive access to one GPU/CPU/runtime. A contract that
  assumes "the GPU" or "the runtime" as a singleton is a migration
  blocker; prefer a schedulable, quota-able resource identity.

### Audit and work-ledger records

- **Audit/work-ledger records should use stable actor identities** and
  be structured to be suitable for later **cryptographic signing,
  hash chaining, or Merkle transparency anchoring**. Records need not
  be signed today, but their shape (stable identity, content-addressable
  fields, ordered events) must not preclude it.

### Distributed ledger / blockchain

- A **distributed ledger or blockchain is NOT required now**, and is not
  a near-term goal. Record it only as a **possible future shared-trust
  evolution** for when independent teams/nodes need mutually verifiable
  attestations. The preferred evolution path is **Git + hashes +
  signatures + transparency-log** techniques first; blockchain is a
  later option only if that proves insufficient for cross-party trust.

### Portability scope

- **Portability includes moving/reconstructing a server-hosted lab and
  connecting clients**, not merely reproducing a developer workstation.
  The portable architecture must support reconstructing the durable lab
  on a supported host/server and attaching authorized clients/devices
  without embedding workstation identity, path, or port assumptions
  (see `docs/PORTABILITY.md`).

## Deployment profiles (conceptual only)

These profiles describe the shape of deployments the architecture must
support. They are **not implemented** here and create no implementation
authorization.

1. **Single-node / local.** One host, one user, services on loopback.
   This is today's profile and remains valid. It is the simplest
   profile of the same architecture.

2. **Shared single-server.** One durable host/server hosts the control
   plane and lab services; multiple devices (and later multiple
   authorized humans/teams) connect as clients. This is the strategic
   target. Loopback-bound services may sit behind a governed
   authenticated/TLS gateway.

3. **Distributed / federated (future).** Multiple lab nodes, potentially
   across organizations, with mutually verifiable attestations where
   needed. Independent lab instances remain permitted for isolation or
   offline operation. This is a possible future evolution, not a
   current goal.

## Non-goals now

The following are **explicitly not authorized or implied** by this
direction:

- No multi-user authentication implementation.
- No tenancy implementation.
- No network exposure of any currently loopback-bound service.
- No blockchain or distributed-ledger implementation.
- No distributed consensus.
- No cloud dependency; the architecture must not require any specific
  cloud provider or cloud service.
- No forced central-server requirement for current development. The
  local single-node profile remains a first-class way to develop.

This direction constrains *shape*; it does not schedule *features*.

## Architecture review rule

When choosing tools, components, APIs, storage, or contracts, the
reviewer must explicitly ask:

> Does this choice create a needless barrier to shared, multi-device, or
> multi-user deployment?

If the answer is yes, prefer an equally practical option that preserves
the path to shared operation. If no shared-preserving option is equally
practical, record the trade-off and the migration cost explicitly in the
relevant work ledger before proceeding. The discipline is to make the
barrier *visible and governed*, not to forbid every local convenience.

## Security principles preserved

This direction does not relax any existing security principle.

- Local services **may remain loopback-only** until a governed
  remote-access gateway exists.
- **Never expose internal services merely to satisfy future direction.**
  Remote exposure requires its own Steward authorization, an
  authenticated/TLS gateway, and a review of the expanded attack
  surface — none of which is granted by this document.
- Existing isolation boundaries (Docker lifecycle adapter boundary,
  workspace isolation, secret handling, digest-pinned images) are
  unchanged and remain authoritative for current runtime work.

## Relationship to portability

This direction extends, and does not replace, `docs/PORTABILITY.md`.
Portability ensures the lab can be *reconstructed* on a supported host
without host-specific assumptions; this direction ensures that
reconstruction can target a *shared server* with *attached clients*, not
only a replacement workstation. The two documents are mutually
reinforcing: portability removes host-identity assumptions that would
block shared deployment, and this direction names shared deployment as
the strategic target those portability rules serve.