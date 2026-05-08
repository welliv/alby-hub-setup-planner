# LSP Channel Opening (LSPS1)

The fastest way to get inbound liquidity. An LSP opens a channel TO your hub in exchange for a small fee.

## When to use LSP

- You need inbound liquidity immediately
- Faucet channels are stuck at 0 conf (common on signet)
- First time opening a channel

## Flow

```bash
# 1. List available LSPs (returns LSPs in priority order, filter to your network)
hub-cli get-channel-suggestions

# 2. Request a channel invoice from the chosen LSP
# --lsp-type and --lsp-identifier come from get-channel-suggestions output
hub-cli request-lsp-order --amount 150000 --lsp-type LSPS1 --lsp-identifier megalith
# Returns: { "invoice": "lntbs...", "feeSat": 13126, "incomingLiquiditySat": 150000 }

# 3. Pay the LSP invoice (this is the fee, not the channel size)
# On signet: pay manually at https://faucet.mutinynet.com or via funded wallet

# 4. Channel opens automatically after payment
hub-cli list-channels

# 5. Push outbound liquidity through the channel (see below)
```

## ⚠️ LSP Gives INBOUND Only — You Need Outbound Too

After the LSP channel opens, all balance is on the remote side:
- **Can receive:** up to channel size ✅
- **Can send:** ~0 sats (minus reserve + base fee) ❌

To get outbound liquidity, push sats to the other side:

```bash
# Create a large invoice from YOUR hub
hub-cli make-invoice --amount 100000 --description "Outbound liquidity push"

# Pay that invoice from the Mutinynet faucet
# Go to https://faucet.mutinynet.com → paste the invoice → pay

# Now channel is balanced: you can both send and receive
hub-cli list-channels
```

On signet, this is the standard technique. On mainnet, you'd pay the invoice from another wallet or from on-chain funds.

## Expected Costs

| Channel Size | Typical LSP Fee |
|---|---|
| 50,000 sats | ~5,000 sats |
| 150,000 sats | ~13,000 sats |
| 500,000 sats | ~30,000 sats |

Fees vary by LSP and channel size.

## Choosing an LSP

- `get-channel-suggestions` returns LSPs in priority order — use the first one you don't already have a channel with
- Filter results to your network (signet or bitcoin)
- **Never open two channels with the same LSP**

## Troubleshooting

- **Invoice expired:** Re-run `request-lsp-order`, invoices have a time limit
- **Payment won't route on signet:** Common for faucet sats — use a fresh faucet account to pay
- **Channel not appearing:** Wait 1-3 minutes, then check `hub-cli list-channels`
- **Fees look wrong:** Compare fee (what you pay) not channel size (what you receive)
- **Can't send payments after LSP channel opens:** You only have inbound liquidity. Push sats through the channel first (see above)
