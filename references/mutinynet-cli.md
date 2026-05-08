# mutinynet-cli Reference

Fast signet bitcoin via Mutinynet.

## Installation

```bash
# From source
git clone https://github.com/benthecarman/mutinynet-cli.git
cd mutinynet-cli
cargo build --release
sudo cp target/release/mutinynet-cli /usr/local/bin/

# Authenticate
mutinynet-cli auth github
# Follow the device flow in browser
```

## Key Commands

```bash
# Check balance
mutinynet-cli balance

# Request sats from faucet
mutinynet-cli faucet --amount 100000

# Open a channel
mutinynet-cli channel open --amount 50000

# List channels
mutinynet-cli channel list
```

## Rate Limits

- **1M sat cap per payment** — requesting more fails
- **Amount-based cooldown** — larger amounts = longer wait between requests
- If you hit the limit, wait or use a fresh GitHub account
- `Too many payments` error = cooldown active; switch to a new GitHub account for immediate access

## Transaction Verification

Use Mutinynet's own block explorer for verifying signet transactions:

```
https://mutinynet.com/tx/<txid>
```

This is more reliable than mempool.space/signet for Mutinynet-internal transactions (faucet payouts, channel opens) which may not always appear on public signet explorers.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Too many payments` | Wait or use new GitHub account |
| `Device flow timeout` | Re-run `mutinynet-cli auth github` |
| Channel stuck at 0 conf | Expected on signet; use LSP instead |

## Cleanup

```bash
rm -rf ~/.mutinynet   # Remove token
sudo rm /usr/local/bin/mutinynet-cli
```
