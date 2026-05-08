# Alby Hub Setup Pitfalls

## 1. Signet Esplora — Alby's default is broken

**Symptom:** LDK sync stalls indefinitely or shows errors.

**Cause:** Alby's default signet Esplora (`electrs.getalbypro.com`) returns 404 for signet endpoints.

**Fix:** Use Mutinynet's own Esplora in `.env`:
```env
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
```
If Mutinynet's Esplora is also unreachable, fall back to `https://mempool.space/signet/api`.

## 2. hub-cli command not found (or "unknown command 'hub-cli'")

**Symptom:** `hub-cli: command not found` or `error: unknown command 'hub-cli'`.

**Cause:** Two possible issues:
- `hub-cli` not installed globally — run `npm install -g @getalby/hub-cli`
- Using wrong invocation: `npx -y @getalby/hub-cli hub-cli` fails because npx doesn't chain subcommands that way

**Fix:** Install globally, then call directly:
```bash
npm install -g @getalby/hub-cli
hub-cli setup --password YOUR_PASSWORD
hub-cli start --password YOUR_PASSWORD --save
```

## 3. LDK sync stalls on mainnet

**Symptom:** Sync progress stops, block height doesn't increase.

**Cause:** Alby's Esplora API is having an outage.

**Fix:** Check https://alby.instatus.com. Wait for recovery — no local fix.

## 4. Signet channel stuck at 0 confirmations

**Symptom:** Channel shows 0 local / 0 remote balance, state "pending".

**Cause:** Mutinynet faucet broadcasts transactions on its internal network but they may not appear on public Esplora instances (mempool.space/signet).

**Fix:**
- Use Megalith LSP channel opening instead (LSPS1 flow) — paid via faucet, channel activates immediately
- Verify transactions at `https://mutinynet.com/tx/<txid>` — Mutinynet-internal txs appear here first

## 5. LSP channel opens but can't send payments

**Symptom:** Channel is active and online, but `pay-invoice` fails with "Failed to send the given payment". `list-channels` shows `localBalanceSat: ~660` (just the reserve + dust).

**Cause:** LSP channels only provide **inbound** liquidity. All balance is on the remote side. You have ~0 outbound balance until you push sats through the channel.

**Fix:** Push sats to the other side:
```bash
# Create a large invoice from your hub
hub-cli make-invoice --amount 100000 --description "Outbound liquidity"

# Pay it from the Mutinynet faucet: https://faucet.mutinynet.com

# Now localBalanceSat ≈ 100k, and you can send payments
```

This is expected behavior — the LSP gives you a "receive-only" channel by design. You need outbound liquidity to send payments.

**Related:** if `forwardingFeeBaseSat` is high (e.g. 100,000 sats), even small payments may fail until you push enough to cover the base fee.

## 6. mutinynet-cli rate limits

**Symptom:** `Too many payments` error from faucet.

**Cause:** Mutinynet has a 1M sat cap per payment and amount-based cooldown.

**Fix:**
- Request smaller amounts (under 500k sats = shorter cooldown)
- Use a fresh GitHub account if you hit the limit

## 7. NWC budget flag name

**Symptom:** `unknown flag: --budget-amount` error.

**Cause:** The correct flag is `--max-amount`.

**Fix:**
```bash
hub-cli create-app --name "My App" --max-amount 100000 --budget-renewal monthly
```

## 8. Token lost after shell exit

**Symptom:** `hub-cli` commands fail with "unauthorized".

**Cause:** Token was not saved — it was ephemeral in the shell session.

**Fix:** Always use `--save` with `start`:
```bash
hub-cli start --password YOUR_PASSWORD --save
```

## 8b. Wrong hub-cli command names

**Symptom:** `error: unknown command 'apps'`

**Cause:** Some command names differ from what you might expect.

**Fix:**
```bash
hub-cli list-apps      # List NWC apps (NOT "apps")
hub-cli list-channels  # List channels
hub-cli list-peers     # List peers
hub-cli list-transactions  # List payment history
```

## 9. AUTO_UNLOCK_PASSWORD not set

**Symptom:** Hub web UI shows "locked" after restart, CLI fails.

**Cause:** Without `AUTO_UNLOCK_PASSWORD` in `.env`, the node doesn't auto-start.

**Fix:** Either:
- Add `AUTO_UNLOCK_PASSWORD=yourpassword` to `.env`, or
- Manually run `hub-cli unlock --password YOUR_PASSWORD --save` after each restart

## 10. Recovery phrase file — never read it

**Symptom:** Agent reads or displays the recovery phrase in chat.

**Fix:** The agent MUST NOT read `.recovery` files. Tell the user the file path so they can store it offline.

## 11. Channel has capacity but can't send payments (0 outbound)

**Symptom:** LSP channel is active, `localBalanceSat` is tiny (e.g. 660 sats), `localSpendableBalanceSat` is 0. `pay-invoice` fails with "Failed to send the given payment."

**Cause:** LSP channels open with almost all balance on the remote side. You have **inbound** liquidity (can receive) but **0 outbound** (cannot send).

**Fix:** Push sats through the channel to rebalance:
```bash
hub-cli make-invoice --amount 100000 --description "Rebalance"
# Pay from external source: faucet (signet) or another wallet (mainnet)
```
After payment settles, `localBalanceSat` grows and becomes spendable.

**Pre-check before sending:** Always check `localSpendableBalanceSat` in `list-channels` output. If 0, rebalance first.

## 13. Wrong env var names

**Symptom:** Hub ignores network configuration.

**Cause:** Using outdated var names. The hub reads `.env` automatically (don't source it).

**Correct signet `.env`:**
```env
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
WORK_DIR=.
AUTO_UNLOCK_PASSWORD=your-strong-random-password
```

Do NOT use `LDK_BITCOIN_NETWORK` — that var is not recognized.

## 14. Forgetting static channel backups (self-hosted without Alby account)

**Symptom:** Server dies, channels exist on-chain but spending balance is unrecoverable.

**Cause:** Without an Alby account, static channel backups are stored ONLY locally.

**Fix:** After every new channel open, copy backups to a separate secure location:
```bash
cp -r /opt/albyhub/ldk/static_channel_backups/ /secure/backup/path/
```

**Better fix:** Connect an Alby account — backups become automatic and encrypted.

## 15. Password shared in chat

**Symptom:** Hub password visible in conversation history.

**Fix:** For mainnet setups, do NOT share the password in chat. Instead:
- Use `AUTO_UNLOCK_PASSWORD` in `.env` for agent automation
- For manual operations, direct the user to run commands themselves
- The `.env` file (`chmod 600`) is the secure way to store the password on the server
- Generate strong random passwords: `openssl rand -base64 24`

## 16. Recovery phrase left on disk

**Symptom:** `~/.hub-cli/albyhub.recovery` file exists on the server after setup.

**Risk:** Anyone with server access can read the file and steal all funds.

**Fix:** After the user confirms they've written down the recovery phrase offline:
```bash
rm ~/.hub-cli/albyhub.recovery
```
The ONLY copy of the recovery phrase should be the user's physical offline backup.

## 17. Using weak or memorable passwords for mainnet

**Symptom:** Password like "Hermes123" or "password123" used for the hub.

**Risk:** Brute-force attacks, credential stuffing, or simple guessing can compromise the wallet and all funds.

**Fix:** Always generate a strong random password:
```bash
sudo /usr/local/bin/alby-hub-password.sh generate
```
This creates a 44-character random password. Store it in a password manager — you won't need to type it manually since `AUTO_UNLOCK_PASSWORD` in `.env` handles it automatically.

## 18. Password lost / forgot .env contents

**Symptom:** `.env` file is corrupted, lost, or server is reinstalled. `AUTO_UNLOCK_PASSWORD` is unknown.

**Risk:** Cannot unlock the hub. Cannot run `backup-mnemonic`. Full re-setup required (new wallet).

**Fix (prevention):**
- Store the password in a password manager during initial setup
- To recover: if you have the recovery phrase, you can reinstall and restore the wallet, but lightning channels will need to be force-closed (14-day wait)
- View current password anytime: `sudo /usr/local/bin/alby-hub-password.sh show`

## 19. Thinking the Web UI is required for setup

**Symptom:** User opens `http://<server-ip>:8080` and tries to set up the wallet through the browser.

**Reality:** The entire setup is designed to be fully automated via CLI. No Web UI interaction is needed at any point.

**If you want to use the Web UI later:**
- The password is the same as `AUTO_UNLOCK_PASSWORD` in `.env` initially
- You can change the Web UI password in Settings without affecting automation
- Run `sudo /usr/local/bin/alby-hub-password.sh show` in your terminal to get the current password
- The Web UI is optional — for monitoring, channel management, or casual use. All operations are available via CLI.