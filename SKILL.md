---
name: alby-hub-setup-planner
description: Step-by-step planner for setting up Alby Hub from scratch — fresh install, signet testing, NWC app creation, and recovery. Covers manual binary install, Docker, and cloud.
license: MIT
version: "0.4.3"
---

# Alby Hub Setup Planner

A thin, opinionated guide for getting Alby Hub running. Optimized for first-timers.

## Scope

This skill **plans and guides setup**. It does NOT manage a running hub — that's what `alby-hub-skill` is for. Once the hub is running, switch to `alby-hub-skill` for day-to-day operations.

## Setup Paths

### Path A: Manual Binary (Recommended for testing / signet)

Best for: quick testing, signet, disposable setups.

**1. Install the binary**

```bash
# Create install directory
sudo mkdir -p /opt/albyhub
cd /opt/albyhub

# Download latest server release (check https://github.com/getAlby/hub/releases)
# Naming format: albyhub-Server-Linux-x86_64.tar.bz2
wget https://github.com/getAlby/hub/releases/download/vX.Y.Z/albyhub-Server-Linux-x86_64.tar.bz2
tar -xjf albyhub-Server-Linux-x86_64.tar.bz2
chmod +x bin/albyhub

# Install hub-cli globally (do NOT pin to a version — use latest)
npm install -g @getalby/hub-cli

# Install helper scripts
sudo cp scripts/alby-hub-password.sh /usr/local/bin/alby-hub-password.sh
sudo chmod +x /usr/local/bin/alby-hub-password.sh
```

**2. Configure .env**

For **signet** (testing — free sats):
```env
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
WORK_DIR=.
```

For **mainnet** (real bitcoin):
```env
NETWORK=mainnet
WORK_DIR=.
```

> **IMPORTANT (signet only):** Alby's default signet Esplora server returns 404. Use Mutinynet's own Esplora (`mutinynet.com/api`). If that's unreachable, fall back to `https://mempool.space/signet/api`.
> **Transaction verification:** Signet: `https://mutinynet.com/tx/<txid>`. Mainnet: `https://mempool.space/tx/<txid>`.

See [references/mainnet.md](references/mainnet.md) for mainnet-specific guidance.

**2b. Generate and set a strong password**

Use the included password script to generate a random password and store it in `.env`:

```bash
# Generate password + add AUTO_UNLOCK_PASSWORD to .env
sudo /usr/local/bin/alby-hub-password.sh generate
```

This creates a 44-character random password, adds `AUTO_UNLOCK_PASSWORD=<password>` to `.env`, and sets `chmod 600` on the file. The hub will auto-unlock on every startup — no human input needed.

> **⚠️ Password handling:**
> - The password is shown ONCE during generation — **copy it to a password manager immediately**
> - The password is stored in `/opt/albyhub/.env` (chmod 600 — owner read-only)
> - **NEVER share the password in chat or messaging**
> - For mainnet: treat this password like a banking password — it controls real funds
>
> **Viewing your password:** Run this on the server terminal:
> ```bash
> sudo /usr/local/bin/alby-hub-password.sh show
> ```
>
> **Web UI access (optional):**
> - Open `http://<server-ip>:8080` in a browser
> - Enter the password shown above to unlock
> - To change the Web UI password to something memorable: go to `http://<server-ip>:8080/settings/change-unlock-password`
> - Changing the Web UI password does **not** affect `AUTO_UNLOCK_PASSWORD` — automation keeps working
> - The Web UI is optional — all operations are available via CLI
>
**3. Start the hub server**

```bash
# Start the HTTP server in the background
cd /opt/albyhub && ./bin/albyhub &
# The hub reads .env automatically from the working directory
# With AUTO_UNLOCK_PASSWORD set, the node auto-unlocks on startup
```

> **⚠️ Hermes terminal:** `nohup` and `&` backgrounding don't work in Hermes. Use `terminal(background=true)` to start the hub as a tracked background process. Then use separate `terminal()` calls for subsequent steps.

**4. Initialize wallet + authenticate**

```bash
# Get the password from .env (not from chat)
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)

# Step 4a: Initialize (one-time only — creates wallet + recovery phrase)
hub-cli setup --password "$HUB_PASS"

# Step 4b: Start the Lightning node + save JWT token
hub-cli start --password "$HUB_PASS" --save
# Token saved to ~/.hub-cli/token.jwt
```

> **IMPORTANT:** `hub-cli` is a global binary (`npm install -g @getalby/hub-cli`). Do NOT use `npx -y @getalby/hub-cli hub-cli` — it fails with "unknown command 'hub-cli'". Just use `hub-cli` directly.

**5. Open a channel via LSP (recommended)**

See [references/lsp.md](references/lsp.md) for full LSP flow.

**6. Create NWC app**

See `alby-hub-skill` → `references/apps.md` for full NWC app creation.

> **Note:** The correct command is `hub-cli list-apps` (not `hub-cli apps` — that command doesn't exist in the current version).

**7. Back up recovery phrase**

```bash
# Get password from .env (not from chat)
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)
hub-cli backup-mnemonic --password "$HUB_PASS" --output ~/.hub-cli/albyhub.recovery
```

**7a. Instruct user to secure the recovery phrase OFFLINE**
- Tell user: "Your recovery phrase is at `~/.hub-cli/albyhub.recovery`"
- User MUST write down the 12 words on paper or metal
- User MUST store it in a safe place (fireproof safe, bank deposit box)
- User MUST NOT photograph it, type it into a password manager, or share it digitally
- **Confirm with user when done**

**7b. Delete recovery phrase from disk**
```bash
# ONLY after user confirms they have written it down offline
rm ~/.hub-cli/albyhub.recovery
```
> **Why:** The recovery phrase on disk is a security risk. Anyone with server access can read it. The ONLY copy should be the user's physical offline backup.

**7c. Back up static channel backups (self-hosted without Alby account)**

Without an Alby account, static channel backups are the ONLY way to recover spending balance if the server dies. Back them up after EVERY new channel open:

```bash
# Default location (when WORK_DIR=.)
cp -r /opt/albyhub/ldk/static_channel_backups/ /secure/backup/path/

# Or if using default data dir
cp -r ~/.local/share/albyhub/ldk/static_channel_backups/ /secure/backup/path/
```

> ⚠️ **Critical:** Without an Alby account, you MUST manually back up BOTH the recovery phrase AND the latest channel backup file. A new channel opened after your last backup is unrecoverable.

**8. Test: create an invoice and pay it**

This validates the full flow — hub can receive AND send lightning payments.

**8a. Test receiving (inbound)**

LSP channels give you inbound liquidity immediately. Test that the hub can receive:

```bash
# Create a small test invoice (e.g. 1000 sats)
hub-cli make-invoice --amount 1000 --description "Setup test invoice"
# Returns a BOLT11 invoice string

# Self-pay to verify (circular — no fees)
hub-cli pay-invoice <invoice>
```

✅ Verify: `pay-invoice` returns `"state": "settled"` with a preimage.

**8b. Get outbound liquidity (required before sending)**

LSP channels only provide **inbound** liquidity (can receive, cannot send). To test sending payments, push sats to the other side:

```bash
# Create a large invoice (e.g. 100,000 sats)
hub-cli make-invoice --amount 100000 --description "Outbound liquidity push"

# Pay this invoice from an external source:
# - On signet: https://faucet.mutinynet.com (paste the invoice)
# - On mainnet: pay from another wallet
```

After payment settles, `list-channels` will show `localBalanceSat` increased — this is now spendable outbound balance.

> **Why:** An LSP channel starts with remoteBalance >> localBalance. You can receive but not send. Pushing sats through (by receiving a large payment) rebalances the channel so you can send too.

**8c. Test sending (outbound)**

Now test a real outbound payment:

```bash
# Resolve a LNURL (e.g. refund@lnurl.mutinynet.com on signet)
curl -s "https://lnurl.mutinynet.com/.well-known/lnurlp/refund"
# Returns callback URL

# Request an invoice from the LNURL callback
curl -s "<callback>?amount=<amount_msat>"
# Returns a BOLT11 invoice

# Pay it
hub-cli pay-invoice <invoice>
```

✅ Verify: `pay-invoice` returns `"state": "settled"`. Fees should be < 100 sats for small amounts.

**8d. Verify final state**

```bash
hub-cli get-balances
hub-cli list-transactions --limit 10
```

Check that:
- `localBalanceSat` decreased by payment amount + fees
- `remoteBalanceSat` increased accordingly
- All transactions show `"state": "settled"`

### Path B: Docker

```yaml
version: "3"
services:
  albyhub:
    image: getalby/hub:latest
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - NETWORK=mainnet
      # or signet: NETWORK=signet
```

### Path C: Cloud (Alby Hub Cloud)

Sign up at https://getalby.com — managed hosting, no binary to install.

## Security Best Practices

See [references/security.md](references/security.md) for the full security guide. Key points:

- **NEVER** share passwords in chat — use `AUTO_UNLOCK_PASSWORD` in `.env` instead
- **NEVER** store recovery phrases digitally — write on paper/metal, store offline
- **ALWAYS** back up static channel backups after each new channel (self-hosted without Alby account)
- Set `chmod 600` on `.env`, `.recovery`, and `token.jwt` files
- Use strong random passwords for mainnet (not memorable ones)

For testing without real bitcoin, use Mutinynet signet. See:

- [references/mutinynet.md](references/mutinynet.md) — signet testing, faucet access, mutinynet-cli
- [references/mainnet.md](references/mainnet.md) — mainnet-specific considerations
- [references/pitfalls.md](references/pitfalls.md) — common issues and fixes

## Post-Setup Checklist

- [ ] Hub is running (`get-info` shows `"running": true`)
- [ ] LDK is synced (`get-node-status` shows `isReady: true`)
- [ ] Token saved to `~/.hub-cli/token.jwt`
- [ ] Recovery phrase backed up offline AND deleted from disk
- [ ] `.env` file permissions set to `chmod 600`
- [ ] LSP channel open and online (inbound liquidity confirmed)
- [ ] NWC app created for your use case
- [ ] **Test 1 — Receive:** Create invoice → self-pay → settled ✅
- [ ] **Rebalance:** Push sats through channel for outbound liquidity ✅
- [ ] **Test 2 — Send:** Pay external LNURL/invoice → settled ✅
- [ ] **Verify:** `list-transactions` shows all payments settled ✅

## Mainnet

For mainnet setup, the same 8-step flow applies — the only differences are which `.env` values to use and where funds come from. See [references/mainnet.md](references/mainnet.md) for the complete mainnet reference.

## Common Pitfalls

See [references/pitfalls.md](references/pitfalls.md) for the full list. Top issues:

1. **Signet Esplora** — Alby's default is broken; use `mutinynet.com/api`, fall back to `mempool.space/signet/api`
2. **hub-cli invocation** — use global `hub-cli` directly, NOT `npx -y @getalby/hub-cli hub-cli`
3. **LSP gives inbound only** — channel opens with 0 outbound balance; must push sats through to rebalance before sending payments
4. **LDK sync stalls** — Esplora server is down; check https://alby.instatus.com
5. **Channel stuck at 0 conf** — faucet txs may not propagate on public signet explorers; use LSP instead
6. **mutinynet-cli rate limits** — 1M sat cap per payment; smaller amounts = faster cooldown
7. **Budget flag** — use `--max-amount` (not `--budget-amount`)
8. **Wrong env vars** — use `NETWORK=signet`, NOT `LDK_BITCOIN_NETWORK=signet`
9. **Version pinning** — do NOT pin hub-cli to old versions; use `@getalby/hub-cli` without version
10. **Wrong upstream docs** — The official `alby-hub-skill` SKILL.md shows `npx -y @getalby/hub-cli hub-cli <cmd>` — this FAILS with "unknown command 'hub-cli'". Use global `hub-cli <cmd>` directly. Also, the upstream `apps.md` shows `hub-cli apps` — the correct command is `hub-cli list-apps`.
11. **JSON extraction in bash** — `hub-cli` returns JSON. Extract fields with `python3 -c "import sys,json; print(json.loads(sys.stdin.read())['key'])" <<< "$VAR"`, NOT with nested `$()` + `grep`/`awk` inside the same command — bash quoting breaks. Store hub-cli output in a variable first, then pipe to python3 in a separate step.
12. **Hermes backgrounding** — `nohup`/`&` don't work in Hermes terminal. Use `terminal(background=true)` to start the hub. Run subsequent commands in separate `terminal()` calls.
13. **CWD nuke risk** — `cd /tmp` before `rm -rf /opt/albyhub`. Killing the hub's working directory breaks the shell.
14. **Data remnants after nuke** — Kill hub FIRST with `pkill -f albyhub`, verify it's dead, THEN remove files. Running hub recreates deleted files immediately.

## Cleanup / Nuke

To start completely fresh:

```bash
# 1. Stop hub FIRST
pkill -9 -f albyhub
sleep 2
pgrep -f albyhub || echo "Hub dead ✓"

# 2. cd OUTSIDE /opt/albyhub before removing it
cd /tmp
sudo rm -rf /opt/albyhub

# 3. Remove data directories
rm -rf ~/.hub-cli
rm -rf ~/.local/share/albyhub
rm -rf ~/.config/albyhub
```

> See pitfalls #11-#14 above for common nuke mistakes (CWD, data remnants).

⚠️ WARNING: This destroys the wallet. Only do this if you have the recovery phrase backed up or are on signet.
