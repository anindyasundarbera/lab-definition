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

Stage OH-001C closes the pre-installation provenance gate defined below and
adds the minimal lab-owned Python dependency input
(`manifests/openhands/pyproject.toml`). OH-001C also adopts the upstream
OpenHands third-party freshness guardrail (`exclude-newer = "7 days"` with
the two first-party packages exempt; see "Supply-chain freshness policy
(OH-001C)" below) and records the rejection of a previously generated
unguarded lock. OH-001C performs no installation, no transitive lock
generation, no image pull, no clone/fetch, no bootstrap, no acceptance, no
runtime start, and no Serena integration. The provenance evidence recorded
in OH-001C was observed by the Human Steward via a read-only upstream probe
on 2026-08-15; it is authoritative input for this candidate but was NOT
independently re-verified by Agent Lab, which has no network/clone
capability in this stage. OpenHands remains `enabled = false` and
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

Neither OH-001A, OH-001B, nor OH-001C performs any source clone, fetch,
pull, image pull, package install, transitive lock generation, or runtime
start. All three stages are record-only.

## Planned host-side packages

The planned host-side packages are exactly:

- `openhands-sdk==1.42.1`
- `openhands-tools==1.42.1`

OH-001C records these as a lab-owned direct dependency input
(`manifests/openhands/pyproject.toml`, see "Python dependency input" below).
Recording the input does not install them; no package install, transitive
lock generation, or materialization is performed in this stage.

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

OH-001C adds the Human-Steward-observed upstream tag-construction evidence
that closes the SHA-derived-image-tag gap: at the recorded source commit,
the upstream Agent Server build derives `SHORT_SHA` from `SDK_SHA` (or
`GITHUB_SHA`) and constructs the tag
`ghcr.io/openhands/agent-server:{sha[:7]}-python-{arch}`. The release
commit's `sha7` is therefore `167c1f9`, which is exactly the tag prefix
recorded in OH-001B. This evidence was observed read-only by the Human
Steward on 2026-08-15; Agent Lab did not re-derive it.

OH-001C also records the digest-qualified runtime manifest probe: the
reference
`ghcr.io/openhands/agent-server@sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02`
resolves directly as `application/vnd.oci.image.manifest.v1+json` with the
same digest. This confirms the digest-qualified runtime reference points
directly at the runnable `linux/amd64` image manifest (not at the OCI
index), closing the digest-qualified-runtime-ref gap. This too is
Human-Steward-observed evidence, not Agent-Lab-verified.

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

The three digests are distinct and must not be conflated:

- runnable `linux/amd64` image manifest digest:
  `sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02`
  (the runtime pin);
- OCI index digest:
  `sha256:f8f9de91b57685384944346e263910b1648ca09ee6abef70ecbf406caece030f`
  (the top-level index envelope, provenance only);
- attestation manifest digest:
  `sha256:a04dd37c5436d9f64c7db012167e010be1d3009775c625b7b5fab9ad97522186`
  (evidence only).

Runtime execution, if ever later authorized, must use the digest-qualified
runtime reference
(`ghcr.io/openhands/agent-server@sha256:67d3b88...08d02`), never the
mutable tag (`...:167c1f9-python-amd64`) alone. The mutable tag is recorded
only as the observed resolution input; the digest is the authoritative pin.

Resolving the image digest in OH-001B does NOT mean OpenHands is accepted
or installed. OpenHands remains `enabled = false` and
`status = "experimental"`. No image pull, runtime start, or acceptance
execution is performed or implied by this record.

## Manifest schema note

Agent Lab has no manifest schema or validator at this stage. The
`agent_server_*` fields in `manifests/components.toml` are declarative
provenance/evidence records; their field semantics are documented in place
in that file. Schema enforcement (type/format/range validation of those
fields) is intentionally deferred and is out of scope for OH-001C. No
validation subsystem is introduced; the manifest remains
permissive/declarative by design until a later, separately scoped stage
defines a schema and validator.

## Pre-installation provenance gate

Before any package installation or runtime materialization of OpenHands is
authorized, the following independent proof must be completed:

1. Prove that release tag `v1.42.1` dereferences to the exact source
   commit `167c1f924ac8a8acbeb0432bf9b1fcf77d5c2497` recorded in OH-001A.
   This must be verified independently of the artifact record above; the
   tag-to-commit binding is a precondition, not a consequence, of the
   artifact pin.
2. Validate that the release-matched host package identities and versions
   (`openhands-sdk==1.42.1`, `openhands-tools==1.42.1`) correspond to the
   same release, with no floating versions or surrogate packages.

### OH-001C: gate satisfaction (Steward-observed, not Agent-Lab-verified)

OH-001C records that both proofs above are satisfied per authoritative
Human-Steward evidence obtained by a read-only upstream probe on
2026-08-15:

1. Release binding PASS: `v1.42.1` dereferences to the exact source commit
   `167c1f924ac8a8acbeb0432bf9b1fcf77d5c2497`.
2. Host package binding PASS at that exact source commit:
   `openhands-sdk = 1.42.1` and `openhands-tools = 1.42.1`, with no floating
   versions or surrogate packages.

This satisfies and closes the pre-installation provenance gate for
purposes of proceeding to later dependency locking and runtime
materialization under separate Steward authorization. The Human-Steward
read-only upstream probe is the independent provenance proof the gate
requires; it was upstream-observed rather than independently re-verified
by Agent Lab tooling in this stage, but that observation does not reopen
the gate or add a new prerequisite. Agent Lab may later automate/replay
this proof (e.g. a deterministic, lab-managed re-probe) as a
reproducibility/acceptance enhancement; such an enhancement is not an
additional blocking gate unless separately authorized by the Steward.

## Python dependency input

OH-001C adds the minimal lab-owned direct dependency input at
`manifests/openhands/pyproject.toml`. It is a component-scoped, explicitly
non-package/virtual dependency-definition project (declared via
`[tool.uv] package = false`; no build-system, not a published package)
consumed by the lab-managed `uv`. It declares exactly:

- `requires-python = ">=3.13,<3.14"` (the Agent Lab Python 3.13 target), and
- the two direct, release-pinned host packages
  `openhands-sdk==1.42.1` and `openhands-tools==1.42.1`.

No transitive dependencies are hand-authored and no `uv.lock` is committed
or fabricated. No container reference appears in this file; the Agent
Server digest remains a separate pin in `manifests/components.toml` and is
never an input to the Python dependency lock.

### Supply-chain freshness policy (OH-001C)

The `[tool.uv]` table in `manifests/openhands/pyproject.toml` carries a
third-party resolution freshness guardrail matching the upstream OpenHands
repository policy:

- `exclude-newer = "7 days"` — third-party transitive resolutions are
  subject to a 7-day freshness cooldown. A transitive published less than
  seven days before resolution is excluded.
- `exclude-newer-package` exempts the two first-party OpenHands packages
  from that delay: `openhands-sdk = false` and `openhands-tools = false`.

The exemption is scoped deliberately. `openhands-sdk==1.42.1` and
`openhands-tools==1.42.1` are the only direct host inputs; they are
explicitly release-pinned and provenance-verified (the release-to-commit
and host-package bindings were closed by the OH-001C provenance gate
above). They are first-party and may be resolved at their pinned version
regardless of publication age. Third-party transitives are not
individually provenance-verified and must observe the cooldown.

The committed source policy is the *relative* 7-day rule. With the
lab-managed uv 0.12.0, a generated lock preserves that relative policy
using uv's sentinel/span representation: the inspected guarded lock records
`exclude-newer = "0001-01-01T00:00:00Z"` together with
`exclude-newer-span = "P7D"` and the package-specific first-party
exemptions. It does not freeze the policy into the wall-clock timestamp at
which resolution occurred. The lock nevertheless fixes the selected
package versions and artifact hashes for exact materialization. A future
deliberate re-lock may advance eligible versions as the seven-day window
advances. No additional dependency or source override is introduced by
this policy.

### Rejected unguarded lock

A first lock-generation probe using the lab-managed `uv` successfully
resolved, but inspection of the resulting `uv.lock` upload-time metadata
showed multiple third-party transitives were less than 7 days old at
resolution time, including some only hours old. That generated lock is
explicitly REJECTED: it is not authoritative, must not be imported or
committed, and must not be recreated in this stage. It was generated
without the freshness guardrail above. A fresh lab-managed `uv` lock must
be generated only after this supply-chain policy lands, and remains
PENDING EXECUTION (see "Deferred dependency locking and runtime
materialization" below). No `uv.lock` is committed or fabricated in
OH-001C.

### Guarded lock-generation evidence

After the freshness policy landed, the Human Steward generated a fresh
guarded lock from canonical base
`aedda94eb2b0c23db72f6cef5ba6fb08c6cb7aff` in a disposable detached
worktree using lab-managed uv 0.12.0 and CPython 3.13.14.

The generated artifact has SHA-256
`5c32db8d8ee93f05005b8e180e25fafd47890e25aef915ecaebe75be1c303cd2`.
`uv lock --check` passed. The universal lock contains 342 package records:
341 PyPI-registry records and one virtual root. Inspection found no Git,
direct-URL, editable, or local-path dependency sources. Downloadable
artifacts are hash-recorded. Lock generation created no project-local
environment, changed only `manifests/openhands/uv.lock` in the disposable
worktree, and left canonical `main` untouched.

Compared with the rejected unguarded lock
(`41e00944c6103481682c12da0e0d104da9562374af7a6f526e2fabba8ef3cf79`),
no package names were added or removed. The freshness policy changed 180
version selections: 162 belong to macOS-only `pyobjc*` records in the
universal lock, while 17 version changes are effective for Linux/Python
3.13. The newest selected third-party artifact observed in the guarded
lock is `starlette==1.6.0`, uploaded on 2026-08-08T18:27:57Z. The
first-party `openhands-sdk==1.42.1` and `openhands-tools==1.42.1` remain
selected through their explicit freshness exemptions.

For Linux/Python 3.13, dependency traversal reaches the virtual root plus
149 registry packages. Of those 149 registry packages, 148 have a
compatible wheel in the lock; `func-timeout==4.3.5` is the sole
sdist-only effective dependency and must be proven during materialization
and standalone acceptance.

`openhands-tools==1.42.1` also declares `browser-use` as an unconditional
dependency. The resulting broad host dependency graph is therefore an
intrinsic property of the published OpenHands tools package even though
Agent Lab's initial exposed tool set remains limited to `TerminalTool` and
`FileEditorTool`. This observation does not broaden Agent Lab's authorized
tool surface.

The guarded lock has been inspected and is acceptable for promotion, but
at the time of this record it remains an externally generated candidate
artifact: it is not yet committed, installed, or materialized.

## Deferred dependency locking and runtime materialization

OH-001C records the dependency *input* only. Dependency locking and
runtime materialization remain deferred and must be performed with the
lab-managed `uv` toolchain, not hand-authored. The deterministic lab
mechanism that will later generate the lock is:

    lab uv lock --project "$LAB_DEFINITION_ROOT/manifests/openhands"

`uv lock` does not create a project environment; it only resolves and
writes `manifests/openhands/uv.lock` (a universal lock constrained to
Python 3.13 by `requires-python`), using the lab-managed uv from
`bootstrap/bootstrap.sh` (pinned in `bootstrap/versions.env`). Resolution
runs under the "Supply-chain freshness policy (OH-001C)" guardrail above.
For the relative rule, uv preserves the seven-day span in the lock using
its sentinel/span encoding while fixing the selected versions and artifact
hashes. Once approved, the generated `uv.lock` is a committed definition
artifact kept next to the `pyproject.toml` under the definition tree.

The later materialization (sync) must keep runtime state OUT of the
definition tree. uv defaults the project environment to `.venv` adjacent
to the `pyproject.toml`, which would put persistent runtime state inside
the portable definition repository. The `lab uv` wrapper (`bin/lab`)
execs the lab-managed uv without overriding the project environment (it
sets `UV_PYTHON_INSTALL_DIR`, `UV_TOOL_DIR`, `UV_CACHE_DIR`, etc., but not
`UV_PROJECT_ENVIRONMENT`), so the sync command must set
`UV_PROJECT_ENVIRONMENT` explicitly to a portable path under `$LAB_ROOT`
consistent with existing runtime conventions (`$LAB_ROOT/runtime/...`):

    lab uv python install 3.13
    UV_PROJECT_ENVIRONMENT="$LAB_ROOT/runtime/openhands" \
        lab uv sync --locked --project "$LAB_DEFINITION_ROOT/manifests/openhands" --python 3.13

The lock and the sync/materialization above are PENDING EXECUTION and are
not performed in this stage. No lockfile or environment is committed or
created in this candidate.

The lab-managed `uv` lock covers only the Python host package dependency
graph derived from the release-pinned host packages above. The Agent
Server digest is a separate immutable runtime artifact pin and must remain
independently recorded and enforced; it is not an input to the Python
dependency lock. Runtime materialization remains gated on the
pre-installation provenance gate above being closed and on separate
Steward authorization.

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