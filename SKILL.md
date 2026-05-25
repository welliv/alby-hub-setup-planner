---
name: alby-hub-setup-planner
description: >
  Step-by-step planner for setting up Alby Hub from scratch — binary install, wallet
  initialization, LSP channel opening, NWC app creation, recovery backup, payment
  testing, and day-to-day REST API operations (app management, transfers, Lightning
  addresses, LNURL pay). Covers signet (free testing) and mainnet (real funds). Use
  when the user wants to install, initialize, configure, or operate an Alby Hub node.
license: MIT
version: "1.0.0"
---

# Alby Hub Setup Planner + API Reference

Two-in-one skill: an 8-step setup planner for fresh installs, plus a comprehensive
REST API reference for day-to-day operations.

**Scope:** Initial setup (Steps 1-8) then ongoing operations (app management, transfers,
Lightning addresses, LNURL pay, channel management).

## Prerequisites

- Linux x86_64 server
- Node.js installed
- `sudo` access
- ~70MB disk space

---

## Path A: Manual Binary (Recommended)

### Step 1: Install

```bash
sudo mkdir -p /opt/albyhub && cd /opt/albyhub
wget https://github.com/getAlby/hub/releases/download/vX.Y.Z/albyhub-Server-Linux-x86_64.tar.bz2
tar -xjf albyhub-Server-Linux-x86_64.tar.bz2 && chmod +x bin/albyhub
npm install -g @getalby/hub-cli
sudo cp scripts/alby-hub-password.sh /usr/local/bin/alby-hub-password.sh
sudo chmod +x /usr/local/bin/alby-hub-password.sh
```

✅ Verify: `bin/albyhub` exists, `hub-cli --version` works.

### Step 2: Configure .env

**Signet:**
```env
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
WORK_DIR=.
```

**Mainnet:**
```env
NETWORK=mainnet
WORK_DIR=.
```

Write to `/opt/albyhub/.env`. See [references/mainnet.md](references/mainnet.md) for
mainnet-specific guidance.

> **CRITICAL:** Use `LDK_ESPLORA_SERVER` (not `ESPLORA_API_URL`). Without it, the Hub
> defaults to mainnet esplora and LDK wallet fails with `WalletOperationFailed` on signet.

### Step 2b: Generate Password

```bash
sudo /usr/local/bin/alby-hub-password.sh generate
```

This creates a 44-char random password, adds `AUTO_UNLOCK_PASSWORD=<password>` to `.env`,
and sets `chmod 600`.

**Password rules:**
- Copy the password to a password manager immediately (shown once)
- Stored in `/opt/albyhub/.env` (chmod 600)
- NEVER share in chat
- View later: `sudo /usr/local/bin/alby-hub-password.sh show`
- Web UI password can be changed independently at `http://<ip>:8080/settings/change-unlock-password`

### Step 3: Start Hub

```bash
cd /opt/albyhub && ./bin/albyhub &
```

> **Hermes agents:** Use `terminal(background=true)`. Then use separate `terminal()` calls
> for subsequent steps.

✅ Verify: `curl -s http://localhost:8080/api/v1/health` returns a response (JWT error = OK,
means hub is up).

### Step 4: Initialize Wallet

For v1.22.2+, the setup flow is two-step:

```bash
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)

# Step A: Store config (204 No Content)
hub-cli setup --password "$HUB_PASS" --backend LDK

# Step B: Start node + save JWT token
hub-cli start --password "$HUB_PASS" --save
```

> **IMPORTANT:** Use global `hub-cli` directly. Do NOT use `npx -y @getalby/hub-cli hub-cli`.

✅ Verify: `hub-cli get-info` shows `"running": true`, `"unlocked": true`.

See [references/alby-hub-v1.22.2-setup.md](references/alby-hub-v1.22.2-setup.md) for the
complete v1.22.2 setup flow with troubleshooting.

### Step 5: Open LSP Channel

See [references/lsp.md](references/lsp.md) and
[references/lsp-channel-opening.md](references/lsp-channel-opening.md) for the full
LSPS1 flow.

```bash
hub-cli get-channel-suggestions   # Filter to your network (signet or bitcoin)
hub-cli request-lsp-order --amount 150000 --lsp-type LSPS1 --lsp-identifier megalith
# Pay the returned invoice (signet: faucet.mutinynet.com; mainnet: funded wallet)
```

✅ Verify: `hub-cli list-channels` shows channel `"status": "online"`.

> **LSP gives inbound only.** After opening, you can receive but NOT send. Push sats
> through the channel first. See [references/lsp.md](references/lsp.md) Step "LSP Gives
> INBOUND Only".

### Step 6: Create NWC App

```bash
hub-cli create-app --name "My App" --max-amount 100000 --budget-renewal monthly
```

See the [API Endpoints — App Management](#app-management) section below for the full
REST API pattern including scopes, pagination, and delete.

> **Note:** Use `hub-cli list-apps` (not `hub-cli apps`).

✅ Verify: `hub-cli list-apps` shows the new app.

### Step 7: Back Up Recovery Phrase

```bash
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)
hub-cli backup-mnemonic --password "$HUB_PASS" --output ~/.hub-cli/albyhub.recovery
```

**7a.** Tell user: "Your recovery phrase is at `~/.hub-cli/albyhub.recovery` — write the
12 words on paper or metal. Store offline. Do NOT photograph or store digitally."

**7b.** After user confirms: `rm ~/.hub-cli/albyhub.recovery`

**7c.** Back up channel backups (self-hosted without Alby account):
```bash
cp -r /opt/albyhub/ldk/static_channel_backups/ /secure/backup/path/
```

✅ Verify: `.recovery` file deleted. Channel backups copied.

### Step 8: Test Payments

**8a. Test inbound (self-pay):**
```bash
hub-cli make-invoice --amount 1000 --description "Test"
hub-cli pay-invoice <invoice>
```
✅ Verify: `"state": "settled"`, `"feesPaidSat": 0`

**8b. Rebalance for outbound liquidity:**
```bash
hub-cli make-invoice --amount 100000 --description "Rebalance"
# Pay from external source (signet: faucet.mutinynet.com; mainnet: another wallet)
```
✅ Verify: `list-channels` shows `localBalanceSat` increased.

**8c. Test outbound:**
```bash
# Signet: curl -s "https://lnurl.mutinynet.com/.well-known/lnurlp/refund"
# Mainnet: any real LNURL/invoice
hub-cli pay-invoice <invoice>
```
✅ Verify: `"state": "settled"`, fees < 100 sats.

**8d. Final check:**
```bash
hub-cli get-balances
hub-cli list-transactions --limit 10
```
✅ Verify: All transactions `"state": "settled"`. Balances consistent.

---

## Path B: Docker

```yaml
version: "3"
services:
  albyhub:
    image: getalby/hub:latest
    ports: ["8080:8080"]
    volumes: ["./data:/data"]
    environment:
      - NETWORK=mainnet  # or signet
```

## Path C: Cloud

Sign up at https://getalby.com — managed hosting, no binary to install.

---

## API Reference

Once the hub is running, use these patterns for day-to-day operations.

### Authentication

Every request requires four headers:

```typescript
const headers = {
  Authorization: `Bearer ${process.env.AUTH_TOKEN}`,
  "AlbyHub-Name": process.env.ALBY_HUB_NAME || "",
  "AlbyHub-Region": process.env.ALBY_HUB_REGION || "",
  "Content-Type": "application/json",
  Accept: "application/json",
};
```

Where:
- `AUTH_TOKEN` — full-permission API token from Alby Hub settings
- `ALBY_HUB_NAME` — the hub's display name (short alphanumeric, e.g. `nwce280eaafdb`)
- `ALBY_HUB_REGION` — the hub's region code (e.g. `fra`)

### App Management

**List apps:**
```
GET /api/apps
```
Returns: `{ apps: App[] }` where each app has `id` (number), `name`, `appPubkey` (hex),
`walletPubkey`, `balance`, `createdAt`, `scopes`, `metadata`, etc.

The `appPubkey` field appears ONLY in the listing response — it is NOT returned by
`POST /api/apps`.

**Find an app by name:**
```
GET /api/apps?filters=${JSON.stringify({ name: appName })}
```

**Find an app by Lightning address (lud16):**
```typescript
const apps = await listApps();
const target = apps.find(a => a.metadata?.lud16 === "username@domain.com");
```

The app's `appPubkey` is used for DELETE operations. The `walletPubkey` is what appears
in the NWC connection URI. These are different values — do not confuse them.

**Pagination — page by page-length, not `totalCount`:**
```typescript
const pageSize = 100;
let offset = 0;
let pageLength = pageSize;
while (pageLength === pageSize) {
  const resp = await fetch(new URL(`/api/apps?limit=${pageSize}&offset=${offset}`, albyHubUrl), { headers });
  const { apps } = await resp.json();
  // …process apps…
  pageLength = apps.length;   // gate on returned count, NOT totalCount
  offset += pageSize;
  await sleep(1000);          // avoid rate-limiting
}
```

**Create app (sub-wallet):**
```
POST /api/apps
Body: {
  name: string,
  scopes: string[],       // e.g. ["get_info","pay_invoice","get_balance","make_invoice","lookup_invoice","list_transactions","notifications"]
  maxAmount: 0,           // 0 = unlimited
  budgetRenewal: "monthly",
  isolated: true,         // true = sub-wallet
  metadata?: { app_store_app_id?: string },
  expiresAt?: string | null,
  pubkey?: string,        // pass "" for new wallet, or hex pubkey to reuse existing
}

Response: {
  id: number,             // numeric uint — used for transfers (toAppId) and lightning addresses
  name: string,
  pairingUri: string,     // NWC connection string
  walletPubkey: string,   // hex key (different from appPubkey)
  // Note: appPubkey is NOT in this response. Only appears in GET /api/apps listing.
}
```

**Create vs listing response mismatch:**

| Field | `POST /api/apps` (create) | `GET /api/apps` (listing) |
|-------|--------------------------|--------------------------|
| `id` | ✅ number | ✅ number |
| `appPubkey` | ❌ absent | ✅ present |
| `walletPubkey` | ✅ present | ❌ absent |

**Delete app:**
```
DELETE /api/apps/{appPubkey}
```
Returns 204 on success. Uses `appPubkey` (hex), NOT the numeric `id` or `walletPubkey`.

To delete an app you just created (where you only have the numeric `id`), list all apps
and find by `id`:
```typescript
const { apps } = await (await fetch(new URL("/api/apps", albyHubUrl), { headers })).json();
const target = apps.find((a) => String(a.id) === String(newAppId));
if (target?.appPubkey) {
  await fetch(new URL(`/api/apps/${target.appPubkey}`, albyHubUrl), { method: "DELETE", headers });
}
```

### Transfers

**Transfer sats to an app:**
```
POST /api/transfers
Body: {
  toAppId: number,        // the app's numeric id, NOT a string, NOT the hex appPubkey
  amountSat: number,
}
```

Uses the app's **numeric `id`**, not the hex `appPubkey`.

**Critical: `toAppId` must be a JavaScript `number`, not a `string`.** The Hub's Go
backend strictly expects a JSON `uint`. If stored as a string in JSON and read back
without `Number()` conversion, the Hub returns `400 Bad Request: Unmarshal type error`.
See [references/toappId-uint-string-bug.md](references/toappId-uint-string-bug.md).

**Safe pattern for persisted app IDs:**
```typescript
// Writing — store as number
function saveUsernameAppId(username: string, appId: number): void {
  const map = readMap();
  map[username] = appId;
  writeMap(map);
}

// Reading — JSON.parse returns number for unquoted values
function getAppIdByUsername(username: string): number | undefined {
  const map = readMap();
  const raw = map[username];
  if (raw === undefined) return undefined;
  const n = Number(raw);
  return Number.isNaN(n) ? undefined : n;
}
```

### Lightning Addresses

**Create Lightning address:**
```
POST /api/lightning-addresses
Body: {
  address: string,        // username part only (e.g. "alice"), NOT the full address
  appId: number,          // the app's numeric id, NOT the hex appPubkey
}
```

> **Lightning address OAuth dependency:** `POST /api/lightning-addresses` requires the
> Hub to have a live Alby account OAuth session. On self-hosted Hubs, this can fail with
> `"oauth2: token expired and refresh token is not set"` even when the JWT is valid.
> Check `GET /api/info`: if `oauthRedirect` is `false` or `albyAccountConnected` is
> `false`, treat lightning-address creation as best-effort. The NWC connection and
> `lud16` remain fully usable without it.

See [references/lnurl-pay-endpoint.md](references/lnurl-pay-endpoint.md) for serving
`/.well-known/lnurlp/<username>` directly from your backend as a workaround.

### Invoices

**Create invoice:**
```
POST /api/invoices
Body: { amountSat: number, description: string }
```
Response uses `invoice` (not `paymentRequest`) as the field name.

### Payments

**Pay invoice:**
```
POST /api/payments
Body: { invoice: string }
```

**Check payment status:**
```
GET /api/payments/{paymentHash}
```

### LSP Channel Opening

See [references/lsp-channel-opening.md](references/lsp-channel-opening.md) and
[references/megalith-signet-lsp.md](references/megalith-signet-lsp.md).

```bash
# Request LSP channel offer
hub-cli request-lsp-order \
  --amount <sats> \
  --lsp-type LSPS1 \
  --lsp-identifier <identifier>

# Returns: { "invoice": "lntbs...", "feeSat": <fee>, "incomingLiquiditySat": <sats> }
# Pay the invoice (signet: faucet.mutinynet.com; mainnet: funded wallet)
```

**Megalith Mutinynet specifics (v1.22.2):**
- LSP identifier: `megalith`
- Minimum channel size: 150,000 sats on v1.22.2 (was 200k on older versions)
- Use `hub-cli request-lsp-order` (not direct `/api/lsps1/*` calls — those serve the web UI)

### LNURL Pay Workaround

When `POST /api/lightning-addresses` fails (OAuth expired), serve LNURL pay endpoints
directly from your backend. See
[references/lnurl-pay-endpoint.md](references/lnurl-pay-endpoint.md) for the full
implementation including `/.well-known/lnurlp/<username>` metadata and
`/lnurlp/<username>/callback` invoice creation.

---

## Common Response Patterns

| Code | Meaning |
|------|---------|
| 204 | Successful DELETE (no content) |
| 200 with JSON | Successful GET/POST |
| 200 with HTML | Path returned web app, not an API endpoint |
| 404 | App not found (usually wrong identifier type — appPubkey vs id) |
| 400 | Type error (common: `toAppId` string instead of uint) |
| 502 | Rate limited or upstream error (slow down, add delays) |

## Known Limitations

- **No transfer history API** — `GET /api/transfers` returns HTML, not JSON
- **No batch operations** — apps must be created/deleted one at a time
- **Rate limiting** — bulk DELETEs may 502 if sent too fast. Safe: 3 concurrent, 1s pause every 10
- **LDK `lookup_invoice`** — only finds invoices created by that app session; use persistent NWC clients
- **Transaction `confirmations`** — Esplora may return `null` even when confirmed; check `mutinynet.com/tx/<txid>` for signet or `mempool.space/tx/<txid>` for mainnet

## Nuke & Rebuild

See [references/nuke-and-rebuild.md](references/nuke-and-rebuild.md) for the full
teardown procedure.

```bash
pkill -9 -f albyhub && sleep 2
cd /tmp && sudo rm -rf /opt/albyhub
rm -rf ~/.hub-cli ~/.local/share/albyhub ~/.config/albyhub
```

⚠️ Destroys the wallet. Only do this with recovery phrase backed up or on signet.

---

## References

### Setup & Operations
- [alby-hub-v1.22.2-setup.md](references/alby-hub-v1.22.2-setup.md) — Complete v1.22.2 signet setup flow (start here for fresh installs)
- [nuke-and-rebuild.md](references/nuke-and-rebuild.md) — Full teardown procedure

### Signet
- [mutinynet.md](references/mutinynet.md) — Signet testing, faucet, mutinynet-cli
- [mutinynet-cli.md](references/mutinynet-cli.md) — Device-flow auth, on-chain funding, Bolt 11 payments
- [signet-sync-and-esplora.md](references/signet-sync-and-esplora.md) — Sync lag, Esplora behaviours, address derivation
- [mainnet.md](references/mainnet.md) — Mainnet-specific considerations

### Lightning Channels
- [lsp.md](references/lsp.md) — LSP channel opening flow, costs, troubleshooting
- [lsp-channel-opening.md](references/lsp-channel-opening.md) — LSPS1 via `hub-cli request-lsp-order`, Megalith Mutinynet specifics
- [megalith-signet-lsp.md](references/megalith-signet-lsp.md) — Channel minimums, `CounterpartyForceClosed`, password recovery

### NWC & Application Development
- [nwc-faucet-patterns.md](references/nwc-faucet-patterns.md) — Full faucet identity + wallet creation flow
- [lnurl-pay-endpoint.md](references/lnurl-pay-endpoint.md) — LNURL pay for LightningAddress SDK compatibility
- [toappId-uint-string-bug.md](references/toappId-uint-string-bug.md) — The `expected=uint, got=string` transfer bug and fix

### Pitfalls & Security
- [pitfalls.md](references/pitfalls.md) — 22 common issues and fixes
- [security.md](references/security.md) — Password, recovery, channel backups
