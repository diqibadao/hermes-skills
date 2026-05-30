# diqibadao/hermes-skills

Hermes Agent 技能包 — 开箱即用的系统工具。

## 快速开始

```bash
hermes skills tap add diqibadao/hermes-skills
hermes skills search
hermes skills install system-health
hermes skills install user-identity
```

---

## system-health — 系统健康监控

让你的 Hermes 学会自检。6 层检测，自动修复。

| 层 | 检测内容 | 自动修复 |
|----|---------|:--------:|
| 模型层 | Provider、API Key、降级保护 | 仅报告 |
| 记忆层 | Hindsight daemon、缓存 | 重启 daemon |
| 工具层 | CodeGraph、Aider、Exa 等 | 仅报告 |
| 系统层 | Gateway、磁盘 | 清理旧文件 |
| 连接层 | WeChat、飞书、GitHub | 仅报告 |
| 用户层 | Profile 配置、API Key | 仅报告 |

**特性：** 自适应检测、自动修复、可视化报告、防限流推送

```bash
hermes skills install system-health
bash ~/.hermes/skills/devops/system-health/scripts/health_check.sh
```

---

## user-identity — 通用身份卡

让所有 AI Agent 都认识你。一份档案，Hermes / OpenClaw / Cursor 都能读。

**特性：** 跨平台共享、持续学习（对话中自动发现）、每字段带时间戳、别名映射（ader -> aider）、安全审计

```bash
hermes skills install user-identity
cat ~/.config/user-identity.yaml
```

---

## 开发

提交 Issue 或 PR。
