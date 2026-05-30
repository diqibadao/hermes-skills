#!/bin/bash
# User Identity — Environment Discovery Script
# Scans the system for new tools, services, and config changes
# Outputs structured suggestions for identity enrichment

IDENTITY_FILE="$HOME/.config/user-identity.yaml"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

echo "# Identity Discovery Scan"
echo "# $(date '+%Y-%m-%d %H:%M')"
echo ""

# ---- 1. PATH Scan: binaries not in identity ----
if [ -f "$IDENTITY_FILE" ]; then
    for cmd in aider docker code cursor node npm brew kubectl terraform gh jq yq; do
        if which "$cmd" 2>/dev/null >/dev/null; then
            if ! grep -q "$cmd" "$IDENTITY_FILE" 2>/dev/null; then
                echo "[SUGGEST] tool:$cmd — found in PATH, not in identity"
            fi
        fi
    done
fi

# ---- 2. Config Scan: new providers/tools ----
if [ -f "$HERMES_HOME/config.yaml" ]; then
    # Check model provider
    mp=$(grep -A3 "^model:" "$HERMES_HOME/config.yaml" 2>/dev/null | grep "provider:" | head -1 | awk '{print $2}')
    if [ -n "$mp" ]; then
        if ! grep -q "$mp" "$IDENTITY_FILE" 2>/dev/null; then
            echo "[SUGGEST] model_provider:$mp — configured, not in identity"
        fi
    fi
fi

# ---- 3. Profile Scan ----
if [ -d "$HERMES_HOME/profiles" ]; then
    for p in $(ls -1 "$HERMES_HOME/profiles/" 2>/dev/null); do
        # default is always handled
        if ! grep -q "$p" "$IDENTITY_FILE" 2>/dev/null; then
            echo "[SUGGEST] profile:$p — exists, not in identity"
        fi
    done
fi

# ---- 4. Service Scan: known ports ----
for port_info in "7892:TNTCloud proxy" "7897:Clash Verge mixed" "9177:Hindsight daemon"; do
    port=$(echo "$port_info" | cut -d: -f1)
    name=$(echo "$port_info" | cut -d: -f2)
    if lsof -iTCP:"$port" -P 2>/dev/null >/dev/null; then
        if ! grep -q "$name\|$port" "$IDENTITY_FILE" 2>/dev/null; then
            echo "[SUGGEST] service:$name (port $port) — running, not in identity"
        fi
    fi
done

# ---- 5. Brew Scan (macOS only) ----
if which brew 2>/dev/null >/dev/null; then
    for formula in ollama mysql postgresql redis nginx; do
        if brew list "$formula" 2>/dev/null >/dev/null; then
            if ! grep -q "$formula" "$IDENTITY_FILE" 2>/dev/null; then
                echo "[SUGGEST] brew:$formula — installed, not in identity"
            fi
        fi
    done
fi

echo ""
echo "# Scan complete"
