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

## Loading

**No manual loading required.** The identity file at `~/.config/user-identity.yaml` should be read at session start by any agent, regardless of whether this skill is loaded. The file itself contains a policy header that tells the agent how to handle it.

**By Hermes:** Read the file at conversation start if it exists. The skill is only needed for advanced features (discovery scanning, write management).

**By other agents (OpenClaw, Cursor):** Read the YAML file directly. The policy header is self-explanatory.

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
| `aliases` | Name mappings — "ader"→aider, "clash"→Clash Verge, etc. |
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

## Security

| Measure | Status |
|---------|--------|
| File permissions | `chmod 600` — only owner can read/write |
| Secrets in file | ❌ None — tokens/keys referenced by env var name only |
| Write access | Only via authorized agent or explicit user command |
| Git ignore | Added to `~/.config/gitignore` — won't leak to public repos |
| Changelog | Every change logged with author, date, and description |

**Rules:**
- Never read the file content out loud in a public channel (DM only)
- Never paste the full file content into third-party services
- If asked "what's in the identity file", summarize, don't dump
- Never modify without appending to changelog

The file is designed to be consumed by any AI agent:

- **Hermes** — load via `skill_view('user-identity')`
- **OpenClaw** — read `~/.config/user-identity.yaml` directly (same file!)
- **Cursor/Claude Code** — reference the file in project rules
- **Any agent** — standard YAML, parseable by any language

This means: **update once, every agent knows.**

## Continuous Learning — Auto-Discovery

The identity file gets **smarter over time**. Every conversation is an opportunity to learn something new.

### Discovery Triggers

When you notice new information about the user, check this table:

| You notice | Example | Ask? |
|------------|---------|:----:|
| New tool | "我刚装了 Docker" | ✅ |
| New project | "我在做 XX 项目" | ✅ |
| Changed preference | "别叫我老板了" | ✅ |
| New service | "我换了机场" | ✅ |
| New contact | "我的新邮箱是 XX" | ✅ |
| Repeated behavior | 多次做同一件事 | ⚠️ 先确认 |

### Ask Pattern

1. **Notice** → "我注意到你提到了 XXX"
2. **Confirm** → "要不要加到身份卡里？"
3. **Act** → 同意则更新文件 + changelog
4. **Skip once** → 拒绝则这次跳过
5. **Skip forever** → 拒绝两次则不再问

### Changelog Entry

```yaml
changelog:
  - date: "2026-05-30"
    author: "discovery"
    change: "Added: services.docker (from conversation)"
```

### What NOT to auto-discover

- ❌ Secrets (passwords, API keys, credit cards)
- ❌ Temporary state (mood, today's tasks)
- ❌ One-off opinions
- ❌ Anything user said not to record

## Proactive Discovery — Environment Scan

In addition to real-time discovery during conversation, the identity can be enriched by **periodic environment scans**. This is especially useful for detecting tools and services the user installed but never mentioned.

### Scan Script

`scripts/discover.sh` runs a suite of probes and outputs suggested additions:

| Probe | What it checks | Example suggestion |
|-------|---------------|-------------------|
| `PATH` scan | New binaries not in identity | `aider`, `docker`, `code` |
| Config scan | New providers/tools in `config.yaml` | New model provider, new MCP server |
| Profile scan | New Hermes profiles | `xiaoming`, `model-trainer` |
| Service scan | New listening ports, known services | New proxy, new database |
| Brew scan (macOS) | Newly installed formulae | `brew list --installed` |

### Scan Frequency

- **On demand**: `bash ~/.hermes/skills/devops/user-identity/scripts/discover.sh`
- **As part of system-health**: integrated into the health check report
- **Periodic**: via cron (e.g., weekly) — suggests changes, never auto-writes

### Output Format

The script outputs a list of suggested changes in a structured format that you (the agent) can parse:

```
[SUGGEST] tool:aider — found in PATH, not in identity
[SUGGEST] service:docker — found in PATH, not in identity
[SUGGEST] config:model.provider — currently deepseek, identity has none
[INFO] profile:xiaoming — already in identity
```

You then ask the user: "环境扫描发现了一些新工具，要不要更新身份卡？"

## Quick Reference

```bash
# View identity
cat ~/.config/user-identity.yaml

# Edit (via agent)
"更新我的邮箱为 xxx@example.com"
"把我的称呼改成 '老大'"
"加一个项目：xxx"
```
