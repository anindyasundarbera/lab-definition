# OpenHands Component Record

## Lifecycle status

EXPERIMENTAL.

OpenHands is recorded as a candidate Agent Lab component. It is not
accepted, not baseline, and not enabled. The host-side OpenHands SDK/tools
runtime has been materialized under OH-001D Stage 2 (outside this
definition repo). Under OH-001D Stage 4 the exact immutable Agent Server
image was pulled and locally verified, but no Agent Server container has
yet been started or accepted. As of stage OH-001A this record was
provenance and definition only: no runtime, bootstrap, acceptance, or
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
unguarded lock. OH-001C performs no installation, no image pull, no
clone/fetch, no bootstrap, no acceptance, no runtime start, and no Serena
integration; it adds the dependency input and the committed guarded
transitive lock. The provenance evidence recorded
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

Neither OH-001A nor OH-001B performs any source clone, fetch, pull, image
pull, package install, transitive lock generation, or runtime start; both
are record-only. OH-001C adds the dependency input and the committed
guarded transitive lock but performs no source clone, fetch, pull, image
pull, package install, or runtime start.

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

No transitive dependencies are hand-authored. A guarded `uv.lock` is
committed next to this input and is authoritative for host materialization
(see "Guarded lock-generation evidence" and "OH-001D build-constraint
hardening and host materialization" below). No container reference appears
in this file; the Agent Server digest remains a separate pin in
`manifests/components.toml` and is never an input to the Python dependency
lock.

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
without the freshness guardrail above. A fresh lab-managed `uv` lock was
subsequently generated under the freshness policy and committed; see
"Guarded lock-generation evidence" below.

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

The guarded lock was inspected, accepted, and committed next to the
`pyproject.toml` (canonical commit `9f41884`, "build: lock OpenHands host
dependencies"). Its committed SHA-256 is
`5c32db8d8ee93f05005b8e180e25fafd47890e25aef915ecaebe75be1c303cd2`. Host
materialization was later performed under OH-001D; see "OH-001D
build-constraint hardening and host materialization" below.

## Deferred dependency locking and runtime materialization

OH-001C records the dependency *input* and the committed guarded lock.
Dependency locking and runtime materialization are performed with the
lab-managed `uv` toolchain, never hand-authored. The deterministic lab
mechanism for generating or re-locking is:

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

The guarded lock is committed, and host materialization was performed
under OH-001D Stage 2 with `UV_PROJECT_ENVIRONMENT` kept outside the
definition tree (see "OH-001D build-constraint hardening and host
materialization" below). The commands above remain the reference for
deliberate future relocks and re-materialization.

The lab-managed `uv` lock covers only the Python host package dependency
graph derived from the release-pinned host packages above. The Agent
Server digest is a separate immutable runtime artifact pin and must remain
independently recorded and enforced; it is not an input to the Python
dependency lock. Runtime materialization was Steward-authorized and performed under OH-001D
(see "OH-001D build-constraint hardening and host materialization" below);
any further runtime execution remains separately gated. The
pre-installation provenance gate above is closed (OH-001C).

## OH-001D build-constraint hardening and host materialization

OH-001D hardens the committed guarded lock with a build-time constraint and
performs the first host runtime materialization of the OpenHands candidate,
all on canonical base `7cdd114b86687e8d8bd2f4ee85b70412c6a8dcd3`. OpenHands
remains `enabled = false` and `status = "experimental"`; this stage is
host-side dependency hardening and smoke only. It is NOT standalone
OpenHands acceptance and NOT Agent Server/container acceptance.

### Stage 1: baseline

Stage 1 baseline passed on canonical
`7cdd114b86687e8d8bd2f4ee85b70412c6a8dcd3` against the committed guarded
lock (SHA-256
`5c32db8d8ee93f05005b8e180e25fafd47890e25aef915ecaebe75be1c303cd2`).

### Stage 2: host materialization and sdist build evidence

Stage 2 materialized the host runtime *outside* the definition repo under
Agent Lab-managed CPython 3.13.14 and uv 0.12.0 using `--locked`. Exact
installed versions:

- `openhands-sdk==1.42.1`
- `openhands-tools==1.42.1`
- `func-timeout==4.3.5`

`func-timeout==4.3.5` is sdist-only in the guarded graph (no compatible
wheel). A fresh no-cache isolated PEP 517 build resolved
`setuptools>=40.8.0` to `setuptools==84.0.0` and built successfully.

### Stage 3: host-only SDK/tool smoke

Stage 3 host-only SDK/tool smoke passed. The authorized external tool
specification is exactly `terminal` and `file_editor`. No LLM,
Conversation, executor, Agent Server, or provider was invoked.

### Build-constraint hardening

A disposable uv 0.12.0 probe proved that adding
`build-constraint-dependencies = ["setuptools==84.0.0"]` to
`manifests/openhands/pyproject.toml` makes the prior guarded lock stale,
constrains the fresh `func-timeout` build to `setuptools==84.0.0`,
preserves the exact OpenHands runtime versions
(`openhands-sdk==1.42.1`, `openhands-tools==1.42.1`, `func-timeout==4.3.5`),
and requires only the three-line `[manifest]` lock delta:

    [manifest]
    build-constraints = [{ name = "setuptools", specifier = "==84.0.0" }]

The constraint is build-time only; it does not add `setuptools` as a runtime
or direct dependency and does not broaden the installed dependency graph.
After applying that exact lab-generated delta to the committed guarded lock,
the new guarded lock SHA-256 is
`a171282a9a00821e63196f66f4a434e45a68e586c68494c790028b05ca25c66b`.

The disposable probe evidence log is
`$LAB_ROOT/evidence/openhands/oh-001d/build-constraint-probe-20260816T031653Z.log`
(SHA-256
`d50f64e6983690eb607edb31ae504e07837b94c22f7528cabb108dc942be2c95`).

### Stage 4: Agent Server image record

Stage 4 pulled and locally verified the exact immutable Agent Server image.
The runnable image is the digest-qualified `linux/amd64` manifest reference
`ghcr.io/openhands/agent-server@sha256:67d3b88984dd0537de78cf5a354898942d601b8fab9b633a655a4d57bed08d02`
(the runtime pin from OH-001B). The digest-qualified image was pulled with
platform `linux/amd64`, and the local image id/digest binding was verified;
no Agent Server container was created and no runtime execution occurred.
The canonical definition stayed clean. Stage 4 evidence is captured in
`$LAB_ROOT/evidence/openhands/oh-001d/stage4-agent-server-image-20260816T033850Z.log`
(SHA-256
`62c75c6a631710c41b4f11c9d50f39a74a6ccefccd1d96e2a5bd75c5550bceb0`).
Stage 4 is an image pull and local-verification record only: no container
was started and no acceptance was performed. OpenHands remains
`enabled = false` and `status = "experimental"`.

### Stage 5: lifecycle adapter and image-contract preflight

Stage 5 adds the Agent Lab-owned OpenHands Agent Server lifecycle adapter
(`scripts/openhands-lifecycle.sh`, exposed as `lab openhands start|status|stop`
via `bin/lab`) and its lifecycle acceptance script
(`scripts/test-openhands-lifecycle.sh`, exposed as `lab test
openhands-lifecycle`). The adapter enforces the Agent Lab isolation boundary:

- immutable digest-qualified image ref only (no mutable tag);
- `--pull never`, `--platform linux/amd64`, baked entrypoint/user (never
  overridden), `--security-opt no-new-privileges:true`, `--cap-drop ALL`,
  `-e OH_ENABLE_VNC=false`;
- exactly one bind mount of an approved workspace to `/workspace` (rw);
- loopback-only dynamic port binding (`127.0.0.1::<dynamic>:8000`); port
  `8002` is never published;
- no Docker socket, host `HOME` root or arbitrary host-HOME paths, lab
  definition repo, secrets/state/runtime host mount, privileged mode, or extra
  mount; only the explicitly approved `$LAB_ROOT/workspaces/...` bind is
  allowed;
- workspace validation: an existing real path must resolve strictly below
  `$LAB_ROOT/workspaces/`; symlink/path escape, `$LAB_DEFINITION_ROOT`, `/`,
  host `HOME` itself, Docker sockets, and anything outside
  `$LAB_ROOT/workspaces` are rejected. An approved workspace may legitimately
  sit below host `HOME` because Agent Lab itself lives under `HOME` on the
  accepted host; only `HOME` as the mounted root, or any path outside
  `$LAB_ROOT/workspaces`, is forbidden;
- `SESSION_API_KEY` is generated fresh every start (>=256-bit entropy from
  `/dev/urandom` + coreutils, no new dependency); `OH_SECRET_KEY` is generated
  once, persisted outside Git at `$LAB_ROOT/secrets/openhands/oh-secret-key`
  (directory `0700`, file `0600`), reused across restarts so persisted
  encrypted secrets remain decryptable, never printed, and never deleted by
  `stop`. Per-instance credentials/state remain under
  `$LAB_ROOT/state/openhands` and are cleared on stop; all secrets are never
  printed;
- state dir `$LAB_ROOT/state/openhands` mode `0700`; credentials file mode
  `0600`; container identity/name, workspace, dynamic host port/url, and
  immutable image ref/id are stored as non-executable parsed data and never
  `source`d;
- one active managed server with mandatory ownership labels; stop/remove
  verify labels + recorded container id before any destructive action; stop
  is idempotent, requires successful graceful stop/remove, and never deletes
  the workspace or the persistent `OH_SECRET_KEY`.

The Stage 5 image-contract preflight recorded the baked image contract that
the adapter relies on (the adapter overrides none of these): Entrypoint
`["tini","--","/usr/local/bin/openhands-agent-server"]`; Cmd null; User
`openhands`; WorkingDir `/`; ports `8000/tcp` and `8002/tcp` exposed; no
`Volumes`; no `Healthcheck`. Preflight evidence is captured in
`$LAB_ROOT/evidence/openhands/oh-001d/stage5-image-contract-preflight-20260816T034737Z.log`
(SHA-256
`e23822a2d3a7be865b6fccc9f9fe12c9efc0a81bcf8417197095c1452f1bc5fb`).

Stage 5 implements the lifecycle adapter and acceptance script but does NOT
execute Docker/runtime in the definition repo. Lifecycle acceptance is
pending post-merge host acceptance (the adapter must be exercised on a host
with the immutable image present and the Docker daemon reachable).
OpenHands remains `enabled = false` and `status = "experimental"`; Stage 5
is implementation only and does not claim lifecycle acceptance passed.

Secrets (`SESSION_API_KEY`, `OH_SECRET_KEY`) are passed to the container as
environment via Docker `--env-file`; they are never committed, never printed
by the adapter or acceptance test, and not placed literally on the `docker
run` process command line. Because Docker environment is visible to any
principal with Docker-daemon or container-inspect access, Agent Lab treats
Docker-daemon access as privileged trusted host control-plane access; the
loopback-only binding, no Docker-socket mount, and disposable workspace
isolation are the boundary between the untrusted upstream workspace runtime
and that trusted control plane. The adapter also serializes starts with an
atomic `mkdir`-based state-directory lock (`$OH_STATE_DIR/start.lock`) so
concurrent `lab openhands start` invocations cannot corrupt each other's
state/credentials; a losing start fails without touching the winner's state.

### Status after OH-001D

The guarded lock is committed and authoritative for host materialization;
the relative 7-day freshness rule remains the policy for deliberate future
relocks. OpenHands remains experimental/disabled. The Stage 5 lifecycle
adapter and acceptance script are implemented but pending post-merge host
acceptance; standalone OpenHands acceptance and Agent Server/container
acceptance are NOT yet complete.

## Docker execution boundary

OpenHands execution in Agent Lab must use an Agent Lab-owned Docker
lifecycle adapter with the following boundary:

- loopback-only dynamic port binding (`127.0.0.1:<dynamic>:8000`, or a
  future private network);
- authentication enabled;
- no access to the Docker socket;
- no mount of the host `HOME` root or arbitrary host-HOME paths; only the
  explicitly approved `$LAB_ROOT/workspaces/...` bind is allowed (Agent Lab
  itself lives under `HOME` on the accepted host, so an approved workspace may
  be a descendant of `HOME`);
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