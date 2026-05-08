# Mutinynet

Mutinynet is a bitcoin signet used for testing. Use it to test the hub without spending real bitcoin.

> **Only use Mutinynet when the user explicitly asks for it** (e.g. mentions "mutinynet", "testnet", "test setup", or "no real funds"). Mainnet is always the default — do not suggest Mutinynet proactively.

## Hub Setup for Mutinynet

Create a `.env` file in the folder where you run the hub. Hub reads it automatically — do not pass env vars inline and do not `source` it manually:

```
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
WORK_DIR=.
```

> **IMPORTANT:** Use `NETWORK=signet` (NOT `LDK_BITCOIN_NETWORK=signet` — that var is not recognized). Use Mutinynet's own Esplora (`mutinynet.com/api`). Fall back to `https://mempool.space/signet/api` only if Mutinynet's is unreachable.

Then run the hub in the background:

```bash
cd /opt/albyhub && ./bin/albyhub &
```

Do **not** redirect stdout. Logs go to `{WORK_DIR}/log/nwc.log`.

## Transaction Verification

Use Mutinynet's own explorer for signet transactions:

```
https://mutinynet.com/tx/<txid>
```

Mutinynet-internal transactions (faucet payouts, channel opens) appear here first and may not propagate to public signet explorers.

## Getting Inbound Capacity (Recommended Path)

Opening a channel via an LSP is the recommended first step — no on-chain deposit required.

```bash
# Use global hub-cli (NOT npx -y @getalby/hub-cli hub-cli)
hub-cli get-channel-suggestions
hub-cli request-lsp-order --amount 150000 --lsp-type LSPS1 --lsp-identifier megalith
```

Pay the LSP invoice at https://faucet.mutinynet.com or via `mutinynet-cli`.

> ⚠️ LSP channels only give **inbound** liquidity. After opening, you can receive but NOT send. To get outbound liquidity, push sats through the channel (create a large invoice, pay it from the faucet). See [lsp.md](lsp.md) for details.

## Getting Test Funds (On-Chain)

```bash
hub-cli get-onchain-address
```

Visit https://faucet.mutinynet.com to send test sats to the address, or use `mutinynet-cli faucet --amount <sats>`.

## Notes

- Hub reads `.env` automatically — do not source it or pass vars inline.
- `get-channel-suggestions` returns all networks; filter to signet/Mutinynet entries only.
- Mutinynet transactions use signet coins with no real value.
- mutinynet-cli has a 1M sat cap per payment. Use smaller amounts for faster cooldown.
- See [mutinynet-cli.md](mutinynet-cli.md) for faucet access and rate limit details.