# OpenHands Component Record

## Lifecycle status

EXPERIMENTAL.

OpenHands is recorded as a candidate Agent Lab component. It is not
accepted, not baseline, and not installed. As of stage OH-001A this record
was provenance and definition only: no runtime, bootstrap, acceptance, or
Serena behavior was modified. Stage OH-001B extends the record with an
immutable Agent Server artifact pin while keeping the manifest `enabled =
false` and `status = "experimental"`. OH-001B performs no installation,
image pull, clone, fetch, bootstrap, acceptance, runtime start, or Serena
integration. Image resolution is not acceptance.

## Provenance

- repository: `OpenHands/software-agent-sdk`
- release/version: `v1.42.1`
- exact source commit: `167c1f924ac8a8acbeb0432bf9b1fcf77d5c2497`
- runtime: `python`
- Agent Lab Python target: `3.13`

The source commit SHA is 40 hexadecimal characters and must appear
identically wherever it is recorded. It is the immutable provenance anchor
for this candidate and is independent of any later runtime artifact.

## Source checkout vs runtime installation

Recording provenance here does not install OpenHands. A pinned source
checkout and a pinned runtime installation are independent concerns:

- The source commit fixes what the component *is* for review and audit.
- The runtime installation fixes what executes, including host-side
  packages and the Agent Server container image.
- A later stage may install from the same release without re-deriving
  provenance, but installation is gated separately below.

Neither OH-001A nor OH-001B performs any source clone, fetch, pull, image
pull, package install, or runtime start. Both stages are record-only.

## Planned host-side packages

When runtime installation is later authorized in OH-001C or later (a later
runtime-materialization stage), the planned host-side packages are exactly:

- `openhands-sdk==1.42.1`
- `openhands-tools==1.42.1`

`openhands-workspace` and `openhands-agent-server` are not host-installed
initially. The workspace package is not needed on the host because Agent
Lab owns the disposable candidate workspace lifecycle. The Agent Server is
not host-installed because it must run in a release-matched container (see
below). Floating `latest-python` tags are not permitted; all packages are
release-pinned to `1.42.1`.

## Agent Server image: OH-001B artifact record

OH-001B resolves the previously unresolved Agent Server image digest. The
image was observed via `docker buildx imagetools inspect` against the tag
`ghcr.io/openhands/agent-server:167c1f9-python-amd64`. The tag prefix
`167c1f9` corresponds to the recorded OpenHands source commit prefix from
OH-001A (`167c1f924ac8a8acbeb0432bf9b1fcf77d5c2497`).

Observed and recorded immutable metadata (mirrored in
`manifests/components.toml` under `[components.openhands]`):

- observed tag: `ghcr.io/openhands/agent-server:167c1f9-python-amd64`
- platform: `linux/amd64`
- OCI index media type: `application/vnd.oci.image.index.v1+json`
- OCI index digest:
  `sha256:f8f9de91b57685384944346e263910b1648ca09ee6abef70ecbf406caece030f`
- concrete linux/amd64 image manifest digest (the runtime pin):
  `sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02`
- runtime reference (digest-qualified, the only runnable form):
  `ghcr.io/openhands/agent-server@sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02`

The runtime pin is the platform-specific manifest digest
(`sha256:67d3b88...08d02`). The OCI index digest
(`sha256:f8f9de9...030f`) is retained as supply-chain/provenance
evidence; it is the OCI image index / top-level index envelope that
contains one runnable `linux/amd64` image manifest plus an attestation
manifest with platform `unknown/unknown`. It is not itself the runnable
image, and must not be substituted for the concrete linux/amd64 manifest
digest as the runtime pin.

An attestation manifest digest was also observed:
`sha256:a04dd37c5436d9f64c7db012167e010be1d3009775c625b7b5fab9ad97522186`.
This is evidence only. It is not the runtime image and must not be mistaken
for the runnable image. It is recorded in the manifest as
`agent_server_attestation_digest` for traceability.

Runtime execution, if ever later authorized, must use the digest-qualified
runtime reference
(`ghcr.io/openhands/agent-server@sha256:67d3b88...08d02`), never the
mutable tag (`...:167c1f9-python-amd64`) alone. The mutable tag is recorded
only as the observed resolution input; the digest is the authoritative pin.

Resolving the image digest in OH-001B does NOT mean OpenHands is accepted
or installed. OpenHands remains `enabled = false` and
`status = "experimental"`. No image pull, runtime start, or acceptance
execution is performed or implied by this record.

## Pre-installation provenance gate

Before any package installation or runtime materialization of OpenHands is
authorized, the following independent proof must be completed (it is NOT
claimed to be completed in this candidate):

1. Prove that release tag `v1.42.1` dereferences to the exact source
   commit `167c1f924ac8a8acbeb0432bf9b1fcf77d5c2497` recorded in OH-001A.
   This must be verified independently of the artifact record above; the
   tag-to-commit binding is a precondition, not a consequence, of the
   artifact pin.
2. Validate that the release-matched host package identities and versions
   (`openhands-sdk==1.42.1`, `openhands-tools==1.42.1`) correspond to the
   same release, with no floating versions or surrogate packages.

This gate is a hard precondition for any OH-001C-or-later installation
stage. Until it is satisfied, no host-side package install or Agent Server
runtime materialization may proceed.

## Deferred dependency locking and runtime materialization

Dependency locking and runtime materialization are deferred to the next
stage. When authorized, they must be performed with the lab-managed `uv`
toolchain, not hand-authored. No transitive dependency lock is invented or
hand-authored in OH-001B; no fabricated lockfile is committed. The
lab-managed `uv` lock covers only the Python host package dependency graph
derived from the release-pinned host packages above. The Agent Server
digest is a separate immutable runtime artifact pin and must remain
independently recorded and enforced; it is not an input to the Python
dependency lock. Both are gated on the pre-installation provenance gate
above passing.

## Docker execution boundary

OpenHands execution in Agent Lab must use an Agent Lab-owned Docker
lifecycle adapter with the following boundary:

- loopback-only dynamic port binding (`127.0.0.1:<dynamic>:8000`, or a
  future private network);
- authentication enabled;
- no access to the Docker socket;
- no access to host `HOME`;
- no mount of canonical project working trees;
- only the disposable candidate workspace is mounted.

Stock OpenHands `DockerWorkspace` behavior must not be treated as the
Agent Lab security boundary. Agent Lab owns the lifecycle adapter and
imposes the isolation policy above; the upstream workspace runtime is
treated as untrusted with respect to host resources. This is why
`openhands-agent-server` is not host-installed and why the container image
is digest-pinned rather than run from a floating tag.

## Model abstraction

Model configuration is planned for later via environment variables only:

- `OPENHANDS_LLM_MODEL` — model identifier;
- `OPENHANDS_LLM_BASE_URL` — optional base URL override;
- `OPENHANDS_LLM_API_KEY` — secret, restored per host, never committed.

No ChatGPT OAuth flow or account state is used for certification. Agent
Lab authenticates to the model provider via API key material only.

## Initial tools and acceptance sequencing

Initial OpenHands tools, when runtime is authorized, are limited to:

- `TerminalTool`
- `FileEditorTool`

Standalone OpenHands acceptance must pass before any Serena integration.
OpenHands must be verified in isolation against its own acceptance
criteria first; Serena integration is a later, separately gated stage.

## OpenHands and Serena workspace model

Future per-job Serena MCP integration must operate on the same isolated
candidate workspace used by OpenHands. Serena remains semantic code
intelligence; it is not a sandboxing layer. Sandbox isolation is owned by
the Agent Lab Docker lifecycle adapter described above.

## Responsibility split

- OpenHands: think and execute.
- Serena: semantic understanding.
- Dagger: deterministic verification.
- Temporal: durable lifecycle.
- Steward: authorization.

## Portability

This record introduces no host-specific assumptions. It defines no
`/home` path, username, fixed host port, secret material, GPU dependency,
or host Python/Node dependency. Ports are dynamic and loopback-bound;
Python is the Agent Lab-managed `3.13` target; the container image is
digest-pinned when resolved. All constraints are consistent with
`docs/PORTABILITY.md`.