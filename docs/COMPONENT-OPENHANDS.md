# OpenHands Component Record

## Lifecycle status

EXPERIMENTAL.

OpenHands is recorded as a candidate Agent Lab component. It is not
accepted, not baseline, and not installed as of stage OH-001A. This stage
is provenance and definition only. No runtime, bootstrap, acceptance, or
Serena behavior is modified. The manifest entry is `enabled = false` with
`status = "experimental"`.

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

No source tree, clone, fetch, pull, or image pull is performed in OH-001A.

## Planned host-side packages

When runtime installation is later authorized in OH-001B, the planned
host-side packages are exactly:

- `openhands-sdk==1.42.1`
- `openhands-tools==1.42.1`

`openhands-workspace` and `openhands-agent-server` are not host-installed
initially. The workspace package is not needed on the host because Agent
Lab owns the disposable candidate workspace lifecycle. The Agent Server is
not host-installed because it must run in a release-matched container (see
below). Floating `latest-python` tags are not permitted; all packages are
release-pinned to `1.42.1`.

## Agent Server image: hard gate for OH-001B

The Agent Server will later run in a release-matched Docker image pinned by
an immutable OCI digest. That digest is intentionally unresolved in
OH-001A. It must be resolved and recorded before any runtime installation
or Agent Server start. No fake placeholder digest is inserted in the
manifest or in this document. Resolving the digest is a hard gate for
OH-001B.

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