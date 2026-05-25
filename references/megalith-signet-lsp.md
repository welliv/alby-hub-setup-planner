# Megalith Signet LSP — Session Notes

## Two Megalith entries returned by `get-channel-suggestions`

| Pubkey prefix | Name | Network | Min chan size |
|---------------|------|---------|---------------|
| `038a9e5…` | Megalith | mainnet | 150,000 sats |
| `03e30fda7…` | Megalith | Mutinynet signet | **150,000 sats on v1.22.2** (was 200k on older versions) |

The Mutinynet variant is the one already connected as a persisted peer for signet
operations. On v1.22.2, `hub-cli request-lsp-order --amount 150000 --lsp-identifier megalith`
succeeds. The 200k minimum was an older Hub/LDK constraint that has been relaxed.

## Channel open behaviour

```bash
# This works on v1.22.2:
hub-cli request-lsp-order \
  --amount 150000 \
  --lsp-type LSPS1 \
  --lsp-identifier megalith

# On older Hub versions, 150k would fail with:
# CounterpartyForceClosed: "chan size of 0.00150000 BTC is below min chan size of 0.00200000 BTC"
# Fix: use --amount 200000 on older versions
```

## Password mismatch recovery

If `hub-cli unlock --password '$FROM_ENV'` returns `Invalid password`:
1. Reset password via the web UI (`http://<IP>:8080 → Settings → Change password`)
2. Update `AUTO_UNLOCK_PASSWORD=<new>` in `.env`
3. Run `hub-cli unlock --password '<new>' --save`

Do NOT skip `--save`; without it `hub-cli` will call `/api/unlock` once and discard
the token, then emit `{"error":"invalid or expired jwt"}` for every subsequent request.
