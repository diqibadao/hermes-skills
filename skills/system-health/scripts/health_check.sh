#!/bin/bash
# System Health Check — Hermes system-health skill

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
STATE_FILE="${HEALTH_STATE_FILE:-$HERMES_HOME/logs/.system-health-state}"
NOW=$(date "+%Y-%m-%d %H:%M:%S")
REPORT=""
ALL_MODULES=${HEALTH_MODULES:-all}

has_binary() { which "$1" 2>/dev/null >/dev/null; }
has_config() { grep -q "$1" "$HERMES_HOME/config.yaml" 2>/dev/null; }
has_process() { pgrep -f "$1" 2>/dev/null >/dev/null; }

get_key() {
    local file="$1" name="$2"
    grep "^${name}=" "$file" 2>/dev/null | cut -d= -f2-
}

check_model() {
    local r=""
    local mp=$(grep -A3 "^model:" "$HERMES_HOME/config.yaml" | grep "provider:" | head -1 | awk '{print $2}')
    r="${r}  $([ -n "$mp" ] && echo "✅" || echo "❌") Provider: ${mp:-未配置}\n"
    local mn=$(grep "default:" "$HERMES_HOME/config.yaml" | head -1 | awk '{print $2}')
    r="${r}  ✅ 默认模型: ${mn:-未设置}\n"
    local kv=$(get_key "$HERMES_HOME/.env" "MINIMAX_API_KEY")
    if [ -n "$kv" ] && [ ${#kv} -gt 20 ]; then
        r="${r}  ✅ API Key: 已配置\n"
    else
        r="${r}  ❌ API Key: 未配置\n"
    fi
    local cd=$(grep -c "timeout=3" "$HERMES_HOME/hermes-agent/agent/memory_manager.py" 2>/dev/null || echo 0)
    r="${r}  $([ "$cd" -ge 2 ] && echo "✅" || echo "⚠️") 降级保护: $([ "$cd" -ge 2 ] && echo "就位" || echo "未检测")\n"
    echo -e "$r"
}

check_memory() {
    local r=""
    local prov=$(grep -A5 "^memory:" "$HERMES_HOME/config.yaml" | grep "provider:" | head -1 | awk '{print $2}')
    r="${r}  $([ -n "$prov" ] && echo "✅" || echo "⚠️") Provider: ${prov:-未配置}\n"
    if [ "$prov" = "hindsight" ]; then
        if curl -sf --max-time 3 http://localhost:9177/health 2>/dev/null | grep -q '"status":"healthy"'; then
            r="${r}  ✅ Daemon: 运行中\n"
        else
            r="${r}  ❌ Daemon: 无响应\n"
        fi
    fi
    local ck=0
    for m in "models--cross-encoder--ms-marco-MiniLM-L-6-v2" "models--BAAI--bge-small-en-v1.5"; do
        [ -d "$HOME/.cache/huggingface/hub/$m" ] && ck=$((ck+1))
    done
    r="${r}  $([ "$ck" -eq 2 ] && echo "✅" || echo "❌") 模型缓存: ${ck}/2\n"
    echo -e "$r"
}

check_tools() {
    local r=""
    local cg="$HERMES_HOME/node/bin/codegraph"
    if [ -f "$cg" ] && has_config "codegraph"; then
        r="${r}  ✅ CodeGraph: 就绪\n"
    else
        r="${r}  ⚠️ CodeGraph: 未就绪\n"
    fi
    r="${r}  $(has_config "exa" && echo "✅" || echo "⚠️") Exa MCP: $(has_config "exa" && echo "已配置" || echo "未配置")\n"
    if has_binary aider; then
        local ver=$(pip3 show aider-chat 2>/dev/null | grep "^Version:" | awk '{print $2}')
        [ -z "$ver" ] && ver="已安装"
        r="${r}  ✅ Aider: ${ver}\n"
    else
        r="${r}  ⚠️ Aider: 未安装\n"
    fi
    r="${r}  $([ -f "$HERMES_HOME/node/bin/lark-cli" ] && echo "✅" || echo "⚠️") lark-cli: $([ -f "$HERMES_HOME/node/bin/lark-cli" ] && echo "就绪" || echo "未安装")\n"
    echo -e "$r"
}

check_system() {
    local r=""
    if has_process "hermes.*gateway"; then
        local pid=$(pgrep -f "hermes.*gateway" | head -1)
        local rss=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{printf "%.0fMB", $1/1024}')
        r="${r}  ✅ Gateway: PID=$pid (${rss})\n"
    else
        r="${r}  ❌ Gateway: 未运行\n"
    fi
    local avail=$(df -h "$HOME" | tail -1 | awk '{print $4}')
    local pct=$(df -h "$HOME" | tail -1 | awk '{print $5}' | tr -d '%')
    if [ "$pct" -gt 90 ]; then
        r="${r}  🔴 磁盘: ${avail} (已用 ${pct}% — 紧张)\n"
    else
        r="${r}  ✅ 磁盘: ${avail} (已用 ${pct}%)\n"
    fi
    echo -e "$r"
}

check_connectivity() {
    local r=""
    r="${r}  $(has_process "hermes.*gateway" && echo "✅" || echo "⚠️") WeChat: $(has_process "hermes.*gateway" && echo "运行中" || echo "未运行")\n"
    if curl -sf --max-time 3 https://open.feishu.cn >/dev/null 2>&1; then
        r="${r}  ✅ 飞书: 可达\n"
    else
        r="${r}  ⚠️ 飞书: 不可达\n"
    fi
    if curl -sf --max-time 3 https://api.github.com >/dev/null 2>&1; then
        r="${r}  ✅ GitHub: 可达\n"
    else
        r="${r}  ⚠️ GitHub: 不可达\n"
    fi
    echo -e "$r"
}

check_profiles() {
    local r=""
    for p in default $(ls -1 "$HERMES_HOME/profiles/" 2>/dev/null); do
        [ "$p" = "default" ] && cfg="$HERMES_HOME/config.yaml" envf="$HERMES_HOME/.env" \
            || cfg="$HERMES_HOME/profiles/$p/config.yaml" envf="$HERMES_HOME/profiles/$p/.env"
        [ ! -f "$cfg" ] && continue
        local mp=$(grep -A3 "^model:" "$cfg" | grep "provider:" | head -1 | awk '{print $2}')
        local mem=$(grep -A5 "^memory:" "$cfg" | grep "provider:" | head -1 | awk '{print $2}')
        local kv=$(get_key "$envf" "MINIMAX_API_KEY")
        local ks="未配置"; [ -n "$kv" ] && [ ${#kv} -gt 20 ] && ks="正常"
        local emoji="✅"; [ "$ks" = "未配置" ] && emoji="⚠️"
        r="${r}  ${emoji} $p | model=${mp:--} | memory=${mem:--} | key:$ks\n"
    done
    echo -e "$r"
}

MODULE_LIST="model memory tools system connectivity profile"
[ "$ALL_MODULES" != "all" ] && MODULE_LIST=$(echo "$ALL_MODULES" | tr ',' ' ')

for mod in $MODULE_LIST; do
    case $mod in
        model) REPORT="${REPORT}━━━ Model ━━━\n$(check_model)\n" ;;
        memory) REPORT="${REPORT}━━━ Memory ━━━\n$(check_memory)\n" ;;
        tools) REPORT="${REPORT}━━━ Tools ━━━\n$(check_tools)\n" ;;
        system) REPORT="${REPORT}━━━ System ━━━\n$(check_system)\n" ;;
        connectivity) REPORT="${REPORT}━━━ Connectivity ━━━\n$(check_connectivity)\n" ;;
        profile) REPORT="${REPORT}━━━ Profiles ━━━\n$(check_profiles)\n" ;;
    esac
done

echo -e "$REPORT"
echo "ok" > "$STATE_FILE" 2>/dev/null || true
