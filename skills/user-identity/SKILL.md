---
name: user-identity
description: "Universal user identity card — read who the user is, how they prefer to work, and which tools/services they use. Designed for cross-platform use: Hermes, OpenClaw, Cursor, Claude Code, and any AI agent can consume the same file."
version: 1.0.0
author: diqibadao
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [identity, profile, user, preferences, cross-platform]
    category: devops
---

# User Identity — Universal Profile

Read `~/.config/user-identity.yaml` to learn who the user is and how they prefer to work. This file follows a standard format that any AI agent (Hermes, OpenClaw, Cursor, etc.) can consume.

## File Location

```
~/.config/user-identity.yaml
```

This is the XDG standard config path — every Unix-like system respects it.

## What's Inside

| Section | Content |
|---------|---------|
| `profile` | Name, role, preferred name, timezone, language |
| `contacts` | Email, phone, messengers (wechat, feishu, etc.), GitHub |
| `device` | OS, model, arch, shell, input method |
| `communication` | Style preference, response format, things to avoid |
| `workflow` | Dev pipeline, code review rules, debug stages, tool preferences |
| `projects` | Active projects with descriptions |
| `services` | Proxy/VPN config, installed tools |
| `changelog` | Who changed what and when |

## Reading the File

Always read the full file first:

```python
import yaml
with open(os.path.expanduser('~/.config/user-identity.yaml')) as f:
    identity = yaml.safe_load(f)
```

Key fields to pay attention to:

- `profile.preferred_name` — what to call the user
- `communication.style` — how to phrase responses
- `communication.avoid` — things never to do
- `workflow.development.pipeline` — how dev work flows
- `workflow.development.code_red_line` — hard rules
- `services.proxy` — proxy config (if running behind one)

## Permission Model

| Role | Read | Write |
|------|:----:|:-----:|
| Any agent (Hermes, OpenClaw, etc.) | ✅ Always | ❌ Not without authorization |
| Authorized agents | ✅ | ✅ Via identity management tool |
| Human (direct edit) | ✅ | ⚠️ Possible but not recommended |

**Rules:**
- **Read** — always allowed. Any agent on this machine can read the identity.
- **Write** — only through the identity management tool or explicit user command. Never modify the file directly without logging the change in `changelog`.
- **Secrets** — API keys and tokens are stored in `~/.hermes/.env` (or the platform's equivalent), never in the identity file. The identity file only references them by env var name.

## Writing / Updating

When the user asks to update their identity:

1. Read the current file
2. Parse the requested change
3. Write the new value
4. Append to `changelog` with date, author, and what changed
5. Confirm the change with the user

```yaml
# Changelog entry format
changelog:
  - date: "2026-05-30"
    author: "Hermes (default)"
    change: "Initial creation"
```

## Cross-Platform Compatibility

The file is designed to be consumed by any AI agent:

- **Hermes** — load via `skill_view('user-identity')`
- **OpenClaw** — read `~/.config/user-identity.yaml` directly (same file!)
- **Cursor/Claude Code** — reference the file in project rules
- **Any agent** — standard YAML, parseable by any language

This means: **update once, every agent knows.**

## Quick Reference

```bash
# View identity
cat ~/.config/user-identity.yaml

# Edit (via agent)
"更新我的邮箱为 xxx@example.com"
"把我的称呼改成 '老大'"
"加一个项目：xxx"
```
