# Project Skills Guide

This directory contains procedural skills tailored specifically to this project's architecture and domain.

Organizational cross-cutting procedures (UI design, QA playbooks, host infrastructure) belong in your organization's centralized playbook catalog (`agent-skills`) or global agent skills configuration across supported IDEs/CLIs (e.g., `.agent/skills/`, Cursor, Antigravity, Claude Code).

## When to Create a Local Skill

Create a new skill in this folder (`.agent/skills/<name>/SKILL.md`) when:
1. A multi-step procedure (>3 steps) is repeated frequently across tasks.
2. An architectural convention requires strict sequencing (e.g., migrations, complex domain mutations).
3. The pattern involves specific MCP tools and local commands.

Use `000-template.md` as the baseline structure when drafting new skills.

## Hermetic Skills & Context Contract

Procedural guidelines and skills must be self-contained within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator. If a task references an external organizational skill not present in `.agent/skills/`, the agent must not wander the host filesystem; it should request the skill to be injected into the prompt or provisioned locally in `.agent/skills/`.
