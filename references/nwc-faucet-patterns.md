# NWC Faucet — Full Identity + Wallet Creation Flow

This reference documents the end-to-end flow used by the nwc-faucet (forked from getAlby/nwc-faucet) to create a full Nostr test identity with Lightning wallet.

## Sequence

1. **Username validation** — 4–20 chars, lowercase, `a-z0-9-_`. Check availability via NIP-05 file (`.well-known/nostr.json`).
2. **Nostr key generation** — use `nostr-tools` `generateSecretKey()` + `getPublicKey()` + `npub.encode()`.
3. **Create Alby Hub app** — `POST /api/apps` with name `nwc${Date.now()}` and full scopes.
4. **Transfer funds** — `POST /api/transfers` with `toAppId: newApp.id` (the numeric id, not hex appPubkey) and `amountSat: 10000`.
5. **Create Lightning address** — `POST /api/lightning-addresses` with `address: "${username}"` (username part only) and `appId: newApp.id` (the numeric id, not hex appPubkey).
6. **Set up NIP-05** — add entry to `.well-known/nostr.json`: `"${username}": "${npub}"`.
7. **Save mapping** — store `username → appPubkey` for top-up functionality.
8. **Build connection secret** — `nostr+walletconnect://${appPubkey}?relay=wss://relay.damus.io&secret=${connectionSecret}&lud16=${username}@${domain}`

## Guardrails

- Wallet creation must succeed or the username is released (no NIP-05 entry saved, no transfer made).
- **Orphaned app cleanup**: If creating the Lightning address fails after the Alby Hub app was already created, the app MUST be deleted to prevent orphaned wallets. Declare `newApp` outside the try block so it's accessible in the catch block. Since `POST /api/apps` does NOT return `appPubkey`, you must list all apps and find by numeric `id`:
  ```typescript
  const listResp = await fetch(new URL("/api/apps", albyHubUrl), { headers });
  const { apps } = await listResp.json();
  const orphanedApp = apps.find((a: { id: number }) => String(a.id) === String(newApp.id));
  if (orphanedApp?.appPubkey) {
    await fetch(new URL(\`/api/apps/\${orphanedApp.appPubkey}\`, albyHubUrl), {
      method: "DELETE", headers,
    });
  }
  ```
  **Two bugs to avoid:** (1) `newApp.appPubkey` is always undefined — the create response does not include it; (2) `newApp.id` is a number at runtime — use `String(a.id) === String(newApp.id)` not `String(a.id) === newApp.id` which fails strict equality on mixed types.
- Minimum username length is 4 characters (Alby Hub constraint).
- The `lud16` parameter in the connection secret ties the wallet to the Lightning address.

## Relay Health Checks

Server-side WebSocket health checks with 5-second timeout. Default relays tested this session:
- wss://relay.damus.io (464ms)
- wss://nos.lol (533ms)
- wss://relay.primal.net (553ms)
- wss://relay.nostr.net (693ms)
- wss://purplepag.es (611ms)
- wss://nostr.mom (745ms)

## Frontend UI

- Custom username input field with availability check
- Big "Create Full Test Identity + Wallet" button
- Relay health status indicators (✅/❌ + latency)
- Copy buttons for: Lightning address/NIP-05 (same line), npub, nsec (with strong warning), connection secret
- "Download Details" button (creates a `.txt` file with all credentials)

## NIP-05 File

Stored at `public/.well-known/nostr.json`:
```json
{"names": {"${username}": "${npub}"}, "relays": {}}
```
Served with `Cache-Control: no-cache, no-store, must-revalidate`.

## Mapping File

`username-appid.json` persisted to `public/.well-known/` for top-up lookups. **Must store numeric `id` (not `appPubkey`, not string):**

```json
{"${username}": ${numericAppId}}
```

Example: `{"getyn": 239}`

**Critical:** The value must be a JSON number, not a string. `JSON.stringify({getyn: 239})` produces `{"getyn":239}` (number). `JSON.stringify({getyn: "239"})` produces `{"getyn":"239"}` (string). The Hub's `/api/transfers` endpoint rejects string values with `expected=uint, got=string`.

**TypeScript pattern:**
```typescript
// Store as number
function saveUsernameAppId(username: string, appId: number): void {
  const map = readMap();
  map[username] = appId; // number
  writeMap(map);
}

// Read back as number
function getAppIdByUsername(username: string): number | undefined {
  const raw = readMap()[username];
  if (raw === undefined) return undefined;
  const n = Number(raw); // defensive: handles both string and number
  return Number.isNaN(n) ? undefined : n;
}
```

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | Serve frontend HTML |
| POST | `/create-custom-identity` | Create identity + wallet (JSON body: `{username}`) |
| GET | `/.well-known/nostr.json` | NIP-05 lookup |
| POST | `/make-invoice` | Create invoice for top-up |
| POST | `/pay-invoice` | Pay invoice |
| GET | `/health/relays` | Relay health check results |
