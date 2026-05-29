#!/bin/bash
# hermes-crypto-agent: Automated trading script for OKX
# Runs as a cron job to monitor and manage trading bots

set -euo pipefail

LOG_FILE="$HOME/.hermes/logs/crypto-agent.log"
STATE_FILE="$HOME/.hermes/crypto-agent-state.json"
ALERT_THRESHOLD=5  # Alert if PnL drops more than 5%

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Initialize state if not exists
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"bots":[],"total_pnl":0,"last_check":"'$(date -Iseconds)'"}' > "$STATE_FILE"
    fi
}

# Check account balance
check_balance() {
    local balance
    balance=$(okx account balance --json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
total = sum(float(a.get('availBal',0)) for a in d.get('details',[]) if a.get('ccy')=='USDT')
print(f'{total:.2f}')
" 2>/dev/null || echo "0")
    echo "$balance"
}

# List active bots with PnL
check_bots() {
    log "Checking active bots..."
    
    # Grid bots
    local grid_bots
    grid_bots=$(okx bot grid orders --algoOrdType grid --json 2>/dev/null || echo "[]")
    
    # DCA bots
    local dca_bots
    dca_bots=$(okx bot dca orders --algoOrdType spot_dca --json 2>/dev/null || echo "[]")
    
    # Parse and report
    python3 << PYEOF
import json, sys

try:
    grid = json.loads('''$grid_bots''')
    if isinstance(grid, dict):
        grid = grid.get('data', grid.get('bots', []))
except:
    grid = []

try:
    dca = json.loads('''$dca_bots''')
    if isinstance(dca, dict):
        dca = dca.get('data', dca.get('bots', []))
except:
    dca = []

total_pnl = 0.0
alerts = []

for bot in grid + dca:
    pnl = float(bot.get('pnl', bot.get('upl', 0)))
    pnl_ratio = float(bot.get('pnlRatio', 0))
    inst = bot.get('instId', 'unknown')
    algo_type = bot.get('algoOrdType', 'unknown')
    total_pnl += pnl
    
    status = "✅" if pnl >= 0 else "❌"
    print(f"{status} [{algo_type}] {inst}: PnL={pnl:.4f} USDT ({pnl_ratio:.2%})")
    
    if pnl_ratio < -$ALERT_THRESHOLD/100:
        alerts.append(f"ALERT: {inst} PnL dropped to {pnl_ratio:.2%}")

print(f"\nTotal PnL: {total_pnl:.4f} USDT")

if alerts:
    print("\n⚠️ ALERTS:")
    for a in alerts:
        print(f"  {a}")
PYEOF
}

# Smart money check
check_smart_money() {
    log "Checking smart money signals..."
    
    okx smartmoney consensus --instId BTC-USDT --json 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    signal = d.get('signal', d.get('data', {}).get('signal', 'neutral'))
    confidence = d.get('confidence', d.get('data', {}).get('confidence', 0))
    print(f'Consensus: {signal} (confidence: {confidence})')
except:
    print('No signal data')
" 2>/dev/null || log "Smart money check failed (may need auth)"
}

# Main monitoring loop
main() {
    log "=== Crypto Agent Check ==="
    
    local balance
    balance=$(check_balance)
    log "USDT Balance: $balance"
    
    check_bots
    check_smart_money
    
    log "=== Check Complete ==="
}

# Create a new grid bot with smart parameters
create_smart_grid() {
    local pair="${1:-BTC-USDT}"
    local invest="${2:-100}"
    
    # Get current price
    local price_info
    price_info=$(okx market ticker "$pair" --json 2>/dev/null)
    local current_price
    current_price=$(echo "$price_info" | python3 -c "import json,sys; d=json.load(sys.stdin); print(float(d['last']))" 2>/dev/null || echo "0")
    
    if [ "$current_price" = "0" ]; then
        log "ERROR: Cannot get price for $pair"
        return 1
    fi
    
    # Calculate range: ±12% from current price
    local low high
    low=$(python3 -c "print(f'{$current_price * 0.88:.2f}')")
    high=$(python3 -c "print(f'{$current_price * 1.12:.2f}')")
    
    log "Creating grid bot: $pair, range $low - $high, grids: 20, investment: $invest USDT"
    
    okx bot grid create \
        --instId "$pair" \
        --algoOrdType grid \
        --minPx "$low" \
        --maxPx "$high" \
        --gridNum 20 \
        --quoteSz "$invest"
}

# Entry point
case "${1:-monitor}" in
    monitor)
        init_state
        main
        ;;
    create-grid)
        create_smart_grid "${2:-BTC-USDT}" "${3:-100}"
        ;;
    balance)
        check_balance
        ;;
    bots)
        check_bots
        ;;
    *)
        echo "Usage: $0 {monitor|create-grid|balance|bots}"
        exit 1
        ;;
esac
