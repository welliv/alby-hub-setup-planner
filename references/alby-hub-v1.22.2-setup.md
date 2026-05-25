# Alby Hub v1.22.2 — Fresh Signet Setup (2026-05-24)

Complete steps to get a fresh Alby Hub v1.22.2 running on signet from scratch.

## Prerequisites

- Linux x86_64 machine with port 8080 and 9735 open
- `/opt/albyhub` directory with `bin/albyhub` and `lib/libldk_node.so`
- `hub-cli` on PATH (v0.4.0 confirmed working)

## 1. Write .env

```bash
mkdir -p /opt/albyhub
cat > /opt/albyhub/.env << 'EOF'
NETWORK=signet
AUTO_UNLOCK_PASSWORD=<your-strong-password>
RESCAN=1
WORK_DIR=/opt/albyhub
LDK_ESPLORA_SERVER=https://mutinynet.com/api
EOF
```

**CRITICAL:** Use `LDK_ESPLORA_SERVER` NOT `ESPLORA_API_URL`. The Hub binary reads the envconfig tag `LDK_ESPLORA_SERVER`. Without it, Hub defaults to `https://electrs.getalbypro.com` (mainnet) and LDK wallet sync fails with `WalletOperationFailed`.

Verify the file was written correctly (echo truncates secrets):
```bash
cat /opt/albyhub/.env   # verify all 5 lines present
```

## 2. Start Hub

```bash
cd /opt/albyhub
./bin/albyhub &
```

Wait 8-10 seconds, then verify:
```bash
ss -tlnp | grep 8080
curl -s http://localhost:8080/api/info | python3 -c "
import json,sys; d=json.load(sys.stdin)
print('version:', d.get('version'))
print('setupCompleted:', d.get('setupCompleted'))
print('autoUnlockPasswordEnabled:', d.get('autoUnlockPasswordEnabled'))
"
```

Expected: `setupCompleted: false`, `autoUnlockPasswordEnabled: true`

## 3. Setup (first run only)

```bash
hub-cli setup --password '<your-password>' --backend LDK
# Response: {"success": true, "message": "Hub setup complete"}
```

## 4. Start LN Node + Save Token

```bash
curl -s -X POST http://localhost:8080/api/start \
  -H "Content-Type: application/json" \
  -d '{"unlockPassword":"<your-password>"}'
# Response: {"token": "eyJhbG..."}
```

Save the token:
```bash
echo -n "<token>" > ~/.hub-cli/token.jwt
```

## 5. Verify Running State

```bash
curl -s http://localhost:8080/api/info | python3 -c "
import json,sys; d=json.load(sys.stdin)
for k in ['setupCompleted','running','unlocked','network','startupState','startupError']:
    print(f'{k}: {d.get(k)}')
"
```

Expected when healthy:
```
setupCompleted: true
running: true
unlocked: false
network: signet
startupState: (empty)
startupError: (empty)
```

## 6. Get Node Info for LSP Channel

Public connection details for LSP:
- IPv4: `curl -s https://api.ipify.org`
- Port: 9735
- Node ID: extract from `/opt/albyhub/log/nwc.log` (search for `nodeId`)

## 7. Post-Setup

- **Funding**: Use a signet faucet to fund the on-chain address from `hub-cli get-onchain-address`
- **LSP Channel**: Open via web UI at `http://<IP>:8080` or `hub-cli open-channel`
- **Megalith Mutinynet minimum**: 150k sats on v1.22.2 (was 200k on older Hub versions — see `references/megalith-signet-lsp.md`)

## Troubleshooting

| Error | Meaning | Fix |
|---|---|---|
| `startupError: no LNBackendType specified` | Hub didn't read esplora from env | Add `LDK_ESPLORA_SERVER` to `.env`, wipe DB, restart |
| `WalletOperationFailed` | LDK wallet init failed (wrong esplora) | Same as above |
| `setupCompleted: false` after setup 204 | Normal — need to call `/api/start` | Call start endpoint |
| `Node is not running` (hub-cli) | hub-cli returns token but node starts async | Wait 10s, check `/api/info` |
| `Invalid password` (401) | Wrong field name in JSON body | Use `unlockPassword` not `password` |
| Port 8080 not listening | Hub crashed — check logs | `tail -30 /opt/albyhub/log/nwc.log` |
| Height 0 forever | Esplora not responding or wrong network | Check `LDK_ESPLORA_SERVER` URL |
