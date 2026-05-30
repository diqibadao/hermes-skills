
# diqibadao/hermes-skills

Hermes Agent 技能包 — 由 diqibadao 开发和维护。

## 技能列表

### system-health — 系统健康监控

监控 Hermes Agent 的核心系统健康状态，覆盖 6 层检测：

| 层 | 检查内容 |
|----|---------|
| Model | 模型 provider、默认模型、API Key、降级保护 |
| Memory | Hindsight daemon、数据库、模型缓存 |
| Tools | CodeGraph / Exa MCP / Aider / lark-cli |
| System | Gateway 进程、磁盘空间 |
| Connectivity | WeChat / 飞书 / GitHub |
| Profile | 所有 profile 配置和 API Key |

**特性：**
- 自适应检测：你的环境有什么就检什么，没有的自动跳过
- 自动修复：daemon 挂了自动重启、缓存缺了自动下载
- 可视化报告：一目了然
- 防限流推送：状态变更才推，每天最多 4 次

**安装：**
```
hermes tap add diqibadao/hermes-skills
hermes install system-health
```

**使用：**
```
bash ~/.hermes/skills/devops/system-health/scripts/health_check.sh
```
