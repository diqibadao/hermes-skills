---
name: system-health
description: "Monitor your Hermes Agent system health — check model config, hindsight memory daemon, tools availability, gateway process, disk space, external connectivity, and all profile configs. Auto-remediates common issues. Generates structured daily reports with change tracking. Configurable delivery and modular checks."
version: 1.0.0
author: diqibadao
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [devops, monitoring, health, system, daily-report, diagnostics, remediation]
    category: devops
    requires_toolsets: [terminal]
    config:
      - key: health.deliver
        description: "Where to send health reports (weixin/feishu/telegram/local)"
        default: "local"
        prompt: "Report delivery target (weixin / feishu / telegram / local)"
      - key: health.schedule
        description: "Cron schedule for automatic reports"
        default: "30 10,22 * * *"
        prompt: "Report schedule in cron format (default: 30 10,22 * * * for 10:30 and 22:30)"
      - key: health.modules
        description: "Modules to check (all or comma-separated)"
        default: "all"
        prompt: "Modules to check (all or comma-separated: model,memory,tools,system,connectivity,profile)"
      - key: health.enable_events
        description: "Track version/config changes between reports"
        default: true
        prompt: "Enable change tracking between reports? (true/false)"
      - key: health.max_daily_reports
        description: "Maximum report pushes per day (anti-flood)"
        default: 4
        prompt: "Max report pushes per day (anti-flood, default 4)"
---

# System Health Monitor

Monitor your Hermes Agent's core system health with a single command. This skill checks every critical layer of your Hermes setup, detects problems, and where safe, fixes them automatically.

## What It Does

This skill runs a battery of health checks against your Hermes installation and produces a structured, easy-to-read report. Think of it as a **health checkup** for your agent — it probes:

| Layer | What It Checks |
|-------|---------------|
| **Model** | Is your model provider configured? Is the default model set? Is your API key present and valid? Is the 3-second degradation timeout in place? |
| **Memory** | Is the hindsight daemon running and healthy? Is the database connected? Are the required ML models (cross-encoder, bge-small) cached on disk? |
| **Tools** | Are CodeGraph, Exa MCP, Aider, and lark-cli available? Are they properly configured in config.yaml? |
| **System** | Is the gateway process alive? How much disk space is left? (Alerts at >80%, 🔴 at >90%) |
| **Connectivity** | Can Hermes reach its messaging platforms (WeChat, Feishu)? Can it reach GitHub API? |
| **Profile** | For each Hermes profile (default, xiaoming, etc.): is the config intact? Is the API key set? |

## Output Format

Every check produces a clean, visual report:

```
━━━ Model ━━━
  ✅ Provider: deepseek
  ✅ 默认模型: deepseek/deepseek-v4-flash
  ✅ API Key: 已配置
  ✅ 降级保护: 就位

━━━ Memory ━━━
  ✅ Provider: hindsight
  ❌ Daemon: 无响应      ← agent will auto-remediate this
  ✅ 模型缓存: 2/2

━━━ Tools ━━━
  ✅ CodeGraph: 就绪
  ✅ Exa MCP: 已配置
  ✅ Aider: 0.82.3
  ⚠️ lark-cli: 未安装    ← informational, not an error

━━━ System ━━━
  ✅ Gateway: PID=11604 (65MB)
  ✅ 磁盘: 179Gi (已用 60%)

━━━ Connectivity ━━━
  ✅ WeChat: 运行中
  ⚠️ 飞书: 不可达        ← WeChat works, suggest switching
  ✅ GitHub: 可达

━━━ Profiles ━━━
  ✅ default | model=deepseek | memory=hindsight | key:正常
  ✅ xiaoming | model=deepseek | memory=hindsight | key:正常
```

Each item uses a clear visual indicator:
- **✅** — everything OK
- **❌** — problem detected (agent can auto-fix or needs attention)
- **⚠️** — warning, non-critical (informational)
- **🔴** — critical (disk >90%, needs cleanup)

## Adaptive Detection

The skill automatically adapts to YOUR environment. It doesn't assume you have specific tools or services:

- No hindsight memory? → skips daemon check silently
- No CodeGraph installed? → skips that check
- Only one profile? → only checks that one
- Air-gapped machine? → connectivity shows as N/A, not error

This means the **same skill works for everyone** without configuration.

## Auto-Remediation

The health check script **only detects** issues. When you (the agent) load this skill and see problems, you decide what to fix using this guide:

| Symptom | What To Do | Safe? |
|---------|-----------|:-----:|
| Daemon not responding | `hindsight-embed daemon start` | ✅ auto-fix |
| Model cache missing | `bash ~/.hermes/scripts/restore-hf-cache.sh` | ✅ auto-fix |
| Gateway not running | `hermes gateway run` | ✅ auto-fix |
| Disk >90% | `find ~/.hermes/sessions/ -name '*.json' -mtime +7 -delete` | ⚠️ safe for old files |
| Cron missing | Ask user for schedule, recreate | ⚠️ needs user |
| API key missing | Report to user — **never auto-fill** | 🔴 ask user |
| Degradation code missing | Inform user — code change needed | ℹ️ info only |

## Quick Start

```bash
# 1. Run a health check right now
bash ~/.hermes/skills/devops/system-health/scripts/health_check.sh

# 2. Check the report
cat ~/.hermes/logs/latest-daily-report.txt   # if generated

# 3. Configure delivery
hermes config set skills.config.health.deliver weixin
hermes config set skills.config.health.schedule "30 10,22 * * *"

# 4. Set up automatic daily reports
hermes cron create "30 10,22 * * *" \
  --name "system-health" \
  --script health_check.sh
```

## File Structure

```
~/.hermes/skills/devops/system-health/
├── SKILL.md                        ← This file — instructions for the agent
├── scripts/
│   └── health_check.sh             ← Standalone check script (bash, no deps)
└── templates/
    └── config.yaml                 ← Example configuration
```

## Anti-Flood Protection

Built-in rate limiting to prevent notification spam:

- **Min interval**: 1 hour between pushes
- **Daily cap**: 4 reports per day (configurable)
- **State-change only**: pushes only when healthy↔degraded transitions
- **Silent on steady state**: nothing to report = no push

## Configuration

All settings declared via `metadata.hermes.config` — Hermes prompts you on first load:

| Key | Default | Description |
|-----|---------|-------------|
| `health.deliver` | `local` | Where to send: weixin, feishu, telegram, or local |
| `health.schedule` | `30 10,22 * * *` | Cron schedule |
| `health.modules` | `all` | Modules: model,memory,tools,system,connectivity,profile |
| `health.enable_events` | `true` | Track version/config changes |
| `health.max_daily_reports` | `4` | Anti-flood cap |

Set via:
```bash
hermes config set skills.config.health.deliver weixin
hermes config set skills.config.health.schedule "0 9 * * *"
```

## Common Pitfalls

1. **First run has no event baseline** — run the health check twice to see change tracking
2. **Delivery to unconfigured platform fails silently** — check `skills.config.health.deliver`
3. **skips profiles in non-standard paths** — only scans `~/.hermes/profiles/*/`
4. **Rate-limited on push platforms** — reduce `health.max_daily_reports` if hitting limits
