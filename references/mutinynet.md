# Mutinynet

Mutinynet is a bitcoin signet for testing. Use it to test the hub without spending
real bitcoin.

> **Only use Mutinynet when the user explicitly asks for it** (e.g. mentions
> "mutinynet", "testnet", "test setup", or "no real funds"). Mainnet is always the
> default — do not suggest Mutinynet proactively.

## Hub Setup for Mutinynet

```env
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
WORK_DIR=.
```

> **IMPORTANT:** Use `NETWORK=signet` (NOT `LDK_BITCOIN_NETWORK`). Use Mutinynet's
> own Esplora (`mutinynet.com/api`). Fall back to `https://mempool.space/signet/api`
> only if Mutinynet's is unreachable.

Then run the hub:
```bash
cd /opt/albyhub && ./bin/albyhub &
```
Hub reads `.env` automatically — do not source it. Do NOT redirect stdout. Logs go to
`{WORK_DIR}/log/nwc.log`.

## Getting Test Funds

### Via Web Faucet

```bash
hub-cli get-onchain-address
# Visit https://faucet.mutinynet.com and paste the address
```

### Via mutinynet-cli

`mutinynet-cli` is a Rust binary for signet funding and LSP channel opening.

```bash
# Install
git clone https://github.com/benthecarman/mutinynet-cli.git
cd mutinynet-cli && cargo build --release
sudo cp target/release/mutinynet-cli /usr/local/bin/

# Authenticate (GitHub device flow — run once, keep alive)
mutinynet-cli login
# Go to: https://github.com/login/device
# Enter code: XXXX-XXXX

# Request on-chain signet coins
mutinynet-cli onchain --address <hub-onchain-address> --amount 100000

# Open an LSP channel (via Hub-returned Bolt 11 invoice)
mutinynet-cli lightning pay '<bolt11-invoice>'
```

> **Each `login` generates a new device code.** Run once, keep the process alive with
> `background(true)` + PTY. Multiple rapid invocations invalidate previous codes.

## Transaction Verification

Signet:
```
https://mutinynet.com/tx/<txid>
```

Mainnet:
```
https://mempool.space/tx/<txid>
```

Mutinynet-internal transactions (faucet payouts, channel opens) appear on mutinynet
first and may not propagate to public signet explorers.

## Rate Limits

- **1M sat cap per payment** — requesting more fails
- **Amount-based cooldown** — larger amounts = longer wait between requests
- `Too many payments` error = cooldown active; switch to a new GitHub account

## Getting Inbound Capacity (Recommended Path)

Opening a channel via an LSP is the recommended first step — no on-chain deposit
required.

```bash
hub-cli get-channel-suggestions
hub-cli request-lsp-order --amount 150000 --lsp-type LSPS1 --lsp-identifier megalith
```

Pay the LSP invoice at https://faucet.mutinynet.com or via `mutinynet-cli`.

> ⚠️ LSP channels only give **inbound** liquidity. After opening, you can receive but
> NOT send. To get outbound liquidity, push sats through the channel. See
> [lsp.md](lsp.md).

## Address Derivation

After initial setup, each call to `hub-cli get-onchain-address` returns a fresh
HD-derived address. Fund the FIRST address returned, then confirm the Hub is tracking
it before paying invoices. See
[signet-sync-and-esplora.md](signet-sync-and-esplora.md) for details.

## Esplora Sync

- Esplora's guaranteed path: `GET /api/v1/tx/<txid>`
- Block tip: `GET /api/v1/blocks/tip/height` (integer)
- `confirmations` may be `null` even when confirmed; use `mutinynet.com/tx/<txid>`
- Initial signet sync may lag by 70+ blocks; wait for `LatestOnchainWalletSyncTimestamp`
  within 30 seconds of `date +%s` before paying invoices

## Notes

- Hub reads `.env` automatically
- `get-channel-suggestions` returns all networks; filter to signet/Mutinynet entries
- Mutinynet transactions use signet coins with no real value

## Troubleshooting

| Issue | Fix |
|---|---|
| `Too many payments` | Wait or use new GitHub account |
| `Device flow timeout` | Re-run `mutinynet-cli login` |
| Channel stuck at 0 conf | Expected on signet; use LSP instead |
| Port 8080 not listening | Hub crashed — check `tail -30 /opt/albyhub/log/nwc.log` |
| Height 0 forever | Esplora not responding — check `LDK_ESPLORA_SERVER` URL |

## Cleanup

```bash
rm -rf ~/.mutinynet   # Remove token
sudo rm /usr/local/bin/mutinynet-cli
```
