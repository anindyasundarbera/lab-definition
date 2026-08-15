# Agent Lab Definition

This repository defines how Agent Lab is reconstructed.

It does not contain runtime state, canonical project repositories, secrets,
agent workspaces, or third-party source trees.

## Responsibilities

This repository owns:

- bootstrap logic
- portability requirements
- component declarations
- pinned component versions
- runtime declarations
- container topology
- default configuration
- acceptance-test definitions
- migration procedures

## Workspace

A reconstructed lab has the form:

agent-lab/
  lab-definition/
  components/
  control-plane/
  dagger/
  projects/
  config/
  state/
  workspaces/
  evidence/
  logs/
  secrets/
  scripts/
  docs/
  tmp/

The agent-lab workspace root itself is intentionally not a Git repository.

## Principle

The host runs Agent Lab.

The host does not define Agent Lab.
