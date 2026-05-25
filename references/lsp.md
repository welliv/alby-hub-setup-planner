# LSP Channel Opening (LSPS1)

The fastest way to get inbound liquidity. An LSP opens a channel TO your hub in
exchange for a small fee.

## When to use LSP

- You need inbound liquidity immediately
- Faucet channels are stuck at 0 conf (common on signet)
- First time opening a channel

## Hub CLI Flow (recommended)

```bash
# Step 1: Get channel suggestions to find LSP identifier and type
hub-cli get-channel-suggestions

# Step 2: Request LSPS1 order (returns bolt11 invoice)
hub-cli request-lsp-order \
  --amount <sats> \
  --lsp-type LSPS1 \
  --lsp-identifier <lspId>
```

Response:
```json
{
  "invoice": "lntbs...",
  "feeSat": <fee>,
  "invoiceAmountSat": <fee>,
  "incomingLiquiditySat": <sats>,
  "outgoingLiquiditySat": 0
}
```

The fee is included in the invoice amount (not added on top).
On signet: pay manually at https://faucet.mutinynet.com or via funded wallet.

```bash
# Step 3: Pay the LSP invoice
mutinynet-cli lightning pay '<bolt11-invoice>'
# (Quote the invoice to avoid shell interpretation of special characters)

# Step 4: Channel opens automatically after payment
hub-cli list-channels

# Step 5: Push outbound liquidity through the channel (see below)
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

On signet, this is the standard technique. On mainnet, you'd pay the invoice from
another wallet or from on-chain funds.

## Megalith Mutinynet Specifics (v1.22.2)

- LSP identifier: `megalith`
- Minimum channel size: 150,000 sats on v1.22.2 (was 200k on older Hub versions)
- The Mutinynet Megalith pubkey: `03e30fda71887a916ef5548a4d02b06fe04aaa1a8de9e24134ce7f139cf79d7579`
- Channel opens as private by default

Two Megalith entries are returned by `get-channel-suggestions` — one for mainnet
and one for Mutinynet signet. Use the signet one. On v1.22.2, `hub-cli request-lsp-order
--amount 150000 --lsp-identifier megalith` succeeds (the 200k minimum was an older
constraint that has been relaxed).

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

## Notes

- The Hub's LSPS1 offer endpoint at `/api/channels/lsps1/<lsp>/offer` returns empty 200 — use `hub-cli request-lsp-order` instead of calling the API directly
- The Node may show `address: ""` and `port: 0` right after setup — the LSP handshake helps the Hub discover its public address
- After channel open, status shows `confirmations: 0` until the funding tx confirms on signet

## Troubleshooting

| Issue | Fix |
|---|---|
| Invoice expired | Re-run `request-lsp-order`, invoices have a time limit |
| Payment won't route on signet | Common for faucet sats — use a fresh faucet account to pay |
| Channel not appearing | Wait 1-3 minutes, then check `hub-cli list-channels` |
| Fees look wrong | Compare fee (what you pay) not channel size (what you receive) |
| Can't send payments after LSP channel opens | You only have inbound liquidity. Push sats through the channel first |
| `CounterpartyForceClosed: below min chan size` | Amount was below the LSP minimum. On v1.22.2, use 150k for Megalith Mutinynet |
