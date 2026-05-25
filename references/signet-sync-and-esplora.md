# Signet Sync & Esplora Behaviours

Session: 2026-05-23, 2026-05-24
Hub versions: v1.22.2 (2026-05-24), v2.3.0 (2026-05-23) · hub-cli 0.4.0 · signet (mutinynet.com)

---

## 0 · Alby Hub v1.22.2 — Fresh Setup Flow

**Correct env var for signet esplora:** `LDK_ESPLORA_SERVER` (NOT `ESPLORA_API_URL`)

```bash
cat > /opt/albyhub/.env << 'EOF'
NETWORK=signet
AUTO_UNLOCK_PASSWORD=<your-password>
RESCAN=1
WORK_DIR=/opt/albyhub
LDK_ESPLORA_SERVER=https://mutinynet.com/api
EOF
```

**Correct setup sequence:**

```bash
# 1. Start Hub
cd /opt/albyhub && ./bin/albyhub &

# 2. Initialise (can only run once)
hub-cli setup --password '<password>' --backend LDK
# OR via API:
curl -s -X POST http://localhost:8080/api/setup \
  -H "Content-Type: application/json" \
  -d '{"unlockPassword":"<password>","backendType":"LDK"}'

# 3. Start the LN node (returns JWT token)
curl -s -X POST http://localhost:8080/api/start \
  -H "Content-Type: application/json" \
  -d '{"unlockPassword":"<password>"}'
# Save the returned token to ~/.hub-cli/token.jwt

# 4. Verify
curl -s http://localhost:8080/api/info | python3 -c "
import json,sys; d=json.load(sys.stdin)
print('setupCompleted:', d.get('setupCompleted'))
print('running:', d.get('running'))
print('network:', d.get('network'))
print('startupError:', d.get('startupError'))
"
```

**Common pitfalls:**

| Symptom | Cause | Fix |
|---|---|---|
| `startupError: no LNBackendType specified` | `ESPLORA_API_URL` env ignored; Hub reads `LDK_ESPLORA_SERVER` | Use `LDK_ESPLORA_SERVER=https://mutinynet.com/api` |
| `WalletOperationFailed` on start | Hub used default mainnet esplora (`electrs.getalbypro.com`) instead of signet | Same as above — set `LDK_ESPLORA_SERVER` correctly |
| `Node is not running` from hub-cli | hub-cli start only returns a save token; node starts async. Wait ~10 s then check `/api/info` | Poll `/api/info` until `running: true` |
| `setupCompleted: false` after 204 | Setup succeeded but node hasn't been started yet | Call `/api/start` |
| `Invalid password` from API | Wrong field name — use `unlockPassword` not `password` | `{"unlockPassword":"...","permission":"full"}` |
| Echo/shell truncation of secrets | `echo $VAR` truncates at special characters or spaces | Use `read_file` tool or write with heredoc, then verify with `read_file` |

**Note on esplora URLs the Hub chooses:**
- Without `LDK_ESPLORA_SERVER` set → Hub defaults to `https://electrs.getalbypro.com` (mainnet only)
- With `NETWORK=signet` only → still defaults to mainnet esplora, causing `WalletOperationFailed`
- MUST explicitly set `LDK_ESPLORA_SERVER=https://mutinynet.com/api` for signet

---

## 1 · Esplora `confirmations` is unreliable during sync lag

The Esplora `/api/v1/tx/<txid>` endpoint may return `confirmations: null` even when the transaction is deeply confirmed on-chain (42+ confirmations observed at `https://mutinynet.com/tx/<txid>`).

Do not gate `hub-cli pay-invoice` on the API `confirmations` field. instead:

```bash
hub-cli get-node-status   # check LatestOnchainWalletSyncTimestamp
hub-cli get-balances       # check spendableSat
```

Only proceed when `spendableSat >= invoiceSat + feeSat` AND `hub-cli get-node-status` shows `LatestOnchainWalletSyncTimestamp` within ~30 s of `date +%s`.

---

## 2 · Hub sync lag on first signet start

On first start the Hub may lag the network tip by 70+ blocks. `LatestOnchainWalletSyncTimestamp` lags `date +%s` by thousands of seconds. `hub-cli get-balances` returns stale mempool-only amounts.

**Trigger a rescan:**

```bash
cd /opt/albyhub
hub-cli stop
RESCAN=1 ./bin/albyhub &
```

Watch `hub-cli get-node-status` until the gap closes and `LatestOnchainWalletSyncTimestamp` advances.

---

## 3 · Address derivation — fund the first displayed address

`hub-cli get-onchain-address` returns a fresh HD-derived address each call. Funding a *previous* address does not immediately show as spendable.

**Workflow:**
1. Run `hub-cli get-onchain-address` and fund the returned address
2. Run `hub-cli get-onchain-address` again — if the address changed, the Hub is *not* tracking the funded address; repeat step 1 until the returned address matches the funded one
3. Wait for `spendableSat` to increment above 0 in `hub-cli get-balances`

---

## 4 · Port/UI reachability without `lsof`

Minimal OS images may not have `lsof` installed. Use `ss` to check the Hub's listen state:

```bash
ss -tlnp | grep 8080
```

`*:8080` → Hub listens on all interfaces → reachable at `http://<EXTERNAL_IP>:8080`  
`127.0.0.1:8080` → Hub only listens locally → not externally reachable

JWT auth check (`/api/v1/health` with `Authorization: Bearer <jwt>`) returns the web-app HTML when the token is valid.

---

## 5 · LSP channel opening

```bash
# Peer (Megalith) may already be connected after LSP order:
hub-cli list-peers

# Pay the LSP invoice once balance is confirmed:
hub-cli pay-invoice lntbs… [invoice]
```

After channel opens: `hub-cli list-channels` shows `"status": "online"`, `"capacitySat"`, and `"localBalanceSat"/"remoteBalanceSat"` reflecting inbound/outbound split.
