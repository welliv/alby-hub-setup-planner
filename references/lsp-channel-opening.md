# LSP Channel Opening via LSPS1

## Hub CLI Flow (recommended)

The correct way to open an LSP channel on Alby Hub v1.22.2:

```bash
# Step 1: Get channel suggestions to find LSP identifier and type
hub-cli get-channel-suggestions

# Step 2: Request LSPS1 order (returns bolt11 invoice)
hub-cli request-lsp-order \
  --amount <sats> \
  --lsp-type LSPS1 \
  --lsp-identifier <lspId> \
  --token "$JWT"
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

## Paying the LSP Invoice with mutinynet-cli

```bash
# Pay bolt11 invoice (needs -- separator for invoices containing !)
mutinynet-cli lightning -- "lntbs131260n1p..."

# Response: payment hash on success
```

## Verify Channel Opened

```bash
# Check channels
hub-cli list-channels

# Look for:
# - status: "online"
# - active: true
# - remoteBalanceSat: incoming liquidity
```

## Mutinynet Megalith specifics (v1.22.2)

- LSP identifier: `megalith`
- Minimum channel size: 150,000 sats (v1.22.2 — previously noted as 200k for older Hub versions)
- The Mutinynet Megalith pubkey `03e30fda71887a916ef5548a4d02b06fe04aaa1a8de9e24134ce7f139cf79d7579`
- Channel opens as private by default (use `--public` for public)

## Notes

- The Hub's LSPS1 offer endpoint at `/api/channels/lsps1/<lsp>/offer` returns empty 200 — use `hub-cli request-lsp-order` instead of calling the API directly
- The Node may show `address: ""` and `port: 0` in connection info right after setup — the LSP handshake helps the Hub discover its public address
- After channel open, status shows `confirmations: 0` until the funding tx confirms on signet
