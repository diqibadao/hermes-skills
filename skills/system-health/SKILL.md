---
name: system-health
description: "Monitor Hermes system health — check model config, memory daemon, tools, gateway, disk, cron jobs, and all profiles. Configurable delivery and check frequency."
version: 1.0.0
author: diqibadao
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [devops, monitoring, health, system, diagnostics]
    category: devops
    requires_toolsets: [terminal]
    config:
      - key: health.deliver
        description: "Where to send health reports"
        default: "local"
        prompt: "Report delivery target (weixin / feishu / telegram / local)"
      - key: health.schedule
        description: "Cron schedule for automatic reports"
        default: "30 10,22 * * *"
        prompt: "Report schedule (cron format, e.g. 30 10,22 * * *)"
      - key: health.modules
        description: "Modules to check"
        default: "all"
        prompt: "Modules (all or comma-separated: model,memory,tools,system,connectivity,profile)"
      - key: health.enable_events
        description: "Track changes between reports"
        default: true
        prompt: "Enable event tracking? (true/false)"
      - key: health.max_daily_reports
        description: "Max reports per day"
        default: 4
        prompt: "Max reports per day (anti-flood)"
---

# System Health Monitor

Monitor Hermes system health with comprehensive checks. Configurable delivery, modular checks, and built-in anti-flood protection.

## When to Use

- "Check system health"
- "Show me the daily report"
- "Is everything running OK?"

## Quick Start

```bash
# Run a health check
bash ~/.hermes/skills/devops/system-health/scripts/health_check.sh
```

### Configuration

Set delivery target, schedule, and modules:
```bash
hermes config set skills.config.health.deliver weixin
hermes config set skills.config.health.schedule "30 10,22 * * *"
```

## Scripts

### `scripts/health_check.sh`

Runs all enabled modules and outputs a structured report. Saves state to prevent duplicate pushes.

**Usage:**
```bash
bash scripts/health_check.sh                              # All modules
HEALTH_MODULES=model,system bash scripts/health_check.sh   # Specific modules
```

## Report Format

```
━━━ Model ━━━
  Provider: deepseek
  默认模型: deepseek/deepseek-v4-flash
  API Key: 存在
  降级保护: 就位

━━━ Memory ━━━
  Provider: hindsight
  Daemon: 运行中
  模型缓存: 2/2

━━━ Tools ━━━
  CodeGraph: 就绪
  Exa MCP: 已配置
  Aider: 0.82.3
  lark-cli: 就绪

━━━ System ━━━
  Gateway: PID=11604 (65MB)
  磁盘: 179Gi (已用 60%)

━━━ Connectivity ━━━
  WeChat: 运行中
  飞书: 可达
  GitHub: 可达

━━━ Profiles ━━━
  default  | model=deepseek | memory=hindsight | key:正常
  xiaoming | model=deepseek | memory=hindsight | key:正常
```

## Anti-Flood

Minimum 1 hour between pushes. Max 4 per day. Only pushes on state changes.

## Agent Remediation

The script detects issues. You decide what to fix:

| Finding | Action |
|---------|--------|
| Daemon not responding | Run `hindsight-embed daemon start` |
| Model cache missing | Run `restore-hf-cache.sh` |
| Gateway not running | Run `hermes gateway run` |
| Disk > 90% | Clean old session files |
| API key missing | Report to user — never auto-fill |

## Common Pitfalls

1. First run has no event baseline — run twice for change detection
2. If delivery target is misconfigured, push fails silently
3. Only scans `~/.hermes/profiles/*/config.yaml`
