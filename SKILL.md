---
name: alby-hub-setup-planner
description: >
  Step-by-step planner for setting up Alby Hub from scratch — binary install, wallet
  initialization, LSP channel opening, NWC app creation, recovery backup, and payment
  testing. Covers signet (free testing) and mainnet (real funds). Use when the user
  wants to install, initialize, or configure a new Alby Hub node. Do NOT use for
  day-to-day operations on an already-running hub — use alby-hub-skill for that.
license: MIT
version: "0.4.4"
---

# Alby Hub Setup Planner

Thin, opinionated 8-step planner. Each step has a verification checkpoint.

**Scope:** Initial setup only. Once the hub is running, switch to `alby-hub-skill` for operations.

## Prerequisites

- Linux x86_64 server
- Node.js installed
- `sudo` access
- ~70MB disk space

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

Write to `/opt/albyhub/.env`. See [references/mainnet.md](references/mainnet.md) for mainnet-specific guidance.

### Step 2b: Generate Password

```bash
sudo /usr/local/bin/alby-hub-password.sh generate
```

This creates a 44-char random password, adds `AUTO_UNLOCK_PASSWORD=<password>` to `.env`, and sets `chmod 600`.

**⚠️ Password rules:**
- Copy the password to a password manager immediately (shown once)
- Stored in `/opt/albyhub/.env` (chmod 600)
- NEVER share in chat
- View later: `sudo /usr/local/bin/alby-hub-password.sh show`
- Web UI password can be changed independently at `http://<ip>:8080/settings/change-unlock-password`

### Step 3: Start Hub

```bash
cd /opt/albyhub && ./bin/albyhub &
```

> **Hermes agents:** Use `terminal(background=true)`. Then use separate `terminal()` calls for subsequent steps.

✅ Verify: `curl -s http://localhost:8080/api/v1/health` returns a response (JWT error = OK, means hub is up).

### Step 4: Initialize Wallet

```bash
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)
hub-cli setup --password "$HUB_PASS"    # One-time: creates wallet + recovery phrase
hub-cli start --password "$HUB_PASS" --save  # Starts node, saves JWT to ~/.hub-cli/token.jwt
```

> **IMPORTANT:** Use global `hub-cli` directly. Do NOT use `npx -y @getalby/hub-cli hub-cli` — it fails.

✅ Verify: `hub-cli get-info` shows `"running": true`, `"unlocked": true`.

### Step 5: Open LSP Channel

See [references/lsp.md](references/lsp.md) for the full LSPS1 flow.

```bash
hub-cli get-channel-suggestions   # Filter to your network (signet or bitcoin)
hub-cli request-lsp-order --amount 150000 --lsp-type LSPS1 --lsp-identifier megalith
# Pay the returned invoice (signet: faucet.mutinynet.com; mainnet: funded wallet)
```

✅ Verify: `hub-cli list-channels` shows channel `"status": "online"`.

### Step 6: Create NWC App

See `alby-hub-skill` → `references/apps.md` for full NWC app creation.

> **Note:** Use `hub-cli list-apps` (not `hub-cli apps` — doesn't exist).

✅ Verify: `hub-cli list-apps` shows the new app.

### Step 7: Back Up Recovery Phrase

```bash
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)
hub-cli backup-mnemonic --password "$HUB_PASS" --output ~/.hub-cli/albyhub.recovery
```

**7a.** Tell user: "Your recovery phrase is at `~/.hub-cli/albyhub.recovery` — write the 12 words on paper or metal. Store offline. Do NOT photograph or store digitally."

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

## Cleanup / Nuke

```bash
pkill -9 -f albyhub && sleep 2
cd /tmp && sudo rm -rf /opt/albyhub
rm -rf ~/.hub-cli ~/.local/share/albyhub ~/.config/albyhub
```

⚠️ Destroys the wallet. Only do this with recovery phrase backed up or on signet.

## References

- [references/pitfalls.md](references/pitfalls.md) — 20 common issues and fixes
- [references/security.md](references/security.md) — Password, recovery, channel backups
- [references/lsp.md](references/lsp.md) — LSP channel opening (LSPS1)
- [references/mutinynet.md](references/mutinynet.md) — Signet testing, faucet, mutinynet-cli
- [references/mainnet.md](references/mainnet.md) — Mainnet-specific considerations
