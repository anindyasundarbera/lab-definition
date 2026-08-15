# Agent Lab Portability Contract

## Objective

Agent Lab must be reconstructible on a supported clean host without relying
on software, language runtimes, ports, paths, credentials, or configuration
that happen to exist on the originating machine.

## Host boundary

The host is infrastructure, not part of Agent Lab.

Agent Lab may assume only a documented minimum bootstrap surface.

Preferred minimum host capabilities:

- Git
- an OCI-compatible container runtime
- basic POSIX shell support where applicable
- network connectivity during initial bootstrap

Additional runtimes and development tools must be installed, pinned, or
containerized by Agent Lab rather than implicitly inherited from the host.

## Filesystem

The workspace root is discovered dynamically.

No implementation may assume a specific username or absolute path such as:

    /home/user/agent-lab

Runtime paths must derive from LAB_ROOT.

## Language runtimes

System Python, Node.js, Java, Go, Rust, and similar host runtimes are not
authoritative dependencies.

Required runtime versions must be:

1. explicitly declared,
2. reproducibly installed or containerized,
3. independently upgradeable,
4. verified during bootstrap.

## Components

Third-party components must declare:

- upstream repository,
- pinned release, tag, or commit,
- expected installation mechanism,
- architecture/platform constraints,
- configuration requirements.

Using an unpinned `latest` version is not permitted in the reproducible
baseline.

## Containers

Container images used by the baseline must be version-pinned.

Image digests should be recorded where practical for reproducibility and
supply-chain verification.

## Ports

Fixed host-port assumptions are prohibited.

Services must support configurable host ports.

The lab must detect collisions before startup or allocate ports through
configuration.

## Secrets

Secrets are never committed to the lab definition.

Portable configuration contains only secret names and requirements.

Secret material is restored separately on each host.

## State

Runtime state must be separated into:

- reconstructible state,
- portable persistent state,
- disposable state.

The lab definition must be sufficient to recreate all reconstructible state.

Persistent state must eventually have an explicit export/import procedure.

Disposable state must be safe to delete.

## Canonical projects

Canonical project repositories are separate Git repositories beneath
LAB_PROJECTS_ROOT.

Agents must not depend on modifying canonical working trees directly.

Agent execution should occur in isolated workspaces.

## Hardware

GPU availability is optional unless a specific profile explicitly requires it.

CPU architecture and operating-system compatibility must be checked during
bootstrap.

Hardware-specific acceleration must degrade gracefully to a portable baseline.

## Acceptance criterion

A second supported machine should be able to:

1. clone the lab definition,
2. run bootstrap,
3. restore secrets and optional persistent state,
4. acquire declared components,
5. start the control plane,
6. execute the same acceptance tests,

without manually reconstructing knowledge from the original host.
