---
name: hermes-crypto-agent
description: "Autonomous AI crypto trading agent for OKX - Grid bots, DCA strategies, smart money tracking, and 24/7 market monitoring. Use when user wants to trade crypto, run bots, manage positions, or track smart money."
version: 1.0.0
author: hermes-crypto-agent
license: MIT
metadata:
  hermes:
    tags: [crypto, trading, okx, grid, dca, automation, bot, smart-money]
    homepage: https://github.com/a918124259a/hermes-crypto-agent
---

# Hermes Crypto Agent

Autonomous cryptocurrency trading agent for Hermes AI Agent. Manages OKX grid bots, DCA strategies, and smart money tracking.

## Prerequisites

- OKX account with API key configured (`okx config init`)
- Hermes Agent with OKX CLI installed (`npm install -g @okx_ai/okx-trade-cli`)
- Sufficient USDT balance for trading

## Bot Types

### 1. Grid Bot (Range Trading)
Best for sideways/ranging markets. Places buy/sell orders at regular intervals within a price range.

```
okx bot grid create --instId BTC-USDT --algoOrdType grid \
  --minPx <low> --maxPx <high> --gridNum <count> --quoteSz <usdt_amount>
```

### 2. DCA Bot (Trend Following)
Best for volatile/trending markets. Averages down with safety orders.

```
okx bot dca create --algoOrdType spot_dca --instId BTC-USDT --direction long \
  --initOrdAmt <usdt> --safetyOrdAmt <usdt> --maxSafetyOrds <count> \
  --pxSteps <pct> --pxStepsMult <mult> --volMult <mult> --tpPct <pct>
```

### 3. Contract Grid (Leveraged)
Same as grid but with leverage for amplified returns (and risk).

```
okx bot grid create --instId BTC-USDT-SWAP --algoOrdType contract_grid \
  --minPx <low> --maxPx <high> --gridNum <count> \
  --direction neutral --lever <x> --sz <usdt_margin>
```

## AI-Recommended Parameters

When user asks to create a bot without specifying parameters:

1. Get current price: `okx market ticker BTC-USDT`
2. Calculate range: ±10-15% from current price
3. Grid count: 10-30 depending on volatility
4. Position size: 5-10% of available balance
5. TP: 2-5%

## Smart Money Commands

```bash
# Get top traders
okx smartmoney leaderboard --type weekly --limit 20

# Get consensus signal
okx smartmoney consensus --instId BTC-USDT

# Get whale positions
okx smartmoney positions --instId BTC-USDT --minUsd 100000
```

## Monitoring

```bash
# List active bots
okx bot grid orders --algoOrdType grid
okx bot dca orders --algoOrdType spot_dca

# Get PnL
okx bot grid details --algoOrdType grid --algoId <id>
okx bot dca details --algoOrdType spot_dca --algoId <id>
```

## Safety Rules

- Always confirm parameters before creating bots (WRITE operations)
- Start with demo mode: `okx --demo bot grid create ...`
- Never auto-transfer funds
- Report balance shortfalls to user
- Stop-loss always recommended for contract bots
