# Alby Hub Pitfalls

## 1. Signet Esplora — Alby's default is broken

**Symptom:** LDK sync stalls indefinitely or shows errors.

**Cause:** Alby's default signet Esplora (`electrs.getalbypro.com`) returns 404 for
signet endpoints.

**Fix:** Use Mutinynet's own Esplora in `.env`:
```env
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
```
If Mutinynet's Esplora is also unreachable, fall back to `https://mempool.space/signet/api`.

## 2. hub-cli command not found

**Symptom:** `hub-cli: command not found` or `error: unknown command 'hub-cli'`.

**Cause:** Two possible issues:
- `hub-cli` not installed globally — run `npm install -g @getalby/hub-cli`
- Using wrong invocation: `npx -y @getalby/hub-cli hub-cli` fails

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

**Cause:** Mutinynet faucet broadcasts transactions on its internal network but they
may not appear on public Esplora instances (mempool.space/signet).

**Fix:**
- Use Megalith LSP channel opening instead (LSPS1 flow) — paid via faucet, channel activates immediately
- Verify transactions at `https://mutinynet.com/tx/<txid>` — Mutinynet-internal txs appear here first

## 5. LSP channel opens but can't send payments

**Symptom:** Channel is active and online, but `pay-invoice` fails. `list-channels`
shows `localBalanceSat: ~660` (just the reserve + dust).

**Cause:** LSP channels only provide **inbound** liquidity. All balance is on the
remote side. You have ~0 outbound balance until you push sats through the channel.

**Fix:** Push sats to the other side:
```bash
hub-cli make-invoice --amount 100000 --description "Outbound liquidity"
# Pay it from the Mutinynet faucet: https://faucet.mutinynet.com
```
After payment settles, `localBalanceSat` grows and becomes spendable.

**Related:** if `forwardingFeeBaseSat` is high (e.g. 100,000 sats), even small payments
may fail until you cover the base fee.

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

## 9. Wrong hub-cli command names

**Symptom:** `error: unknown command 'apps'`.

**Fix:**
```bash
hub-cli list-apps          # List NWC apps (NOT "apps")
hub-cli list-channels      # List channels
hub-cli list-peers         # List peers
hub-cli list-transactions  # List payment history
```

## 10. AUTO_UNLOCK_PASSWORD not set

**Symptom:** Hub web UI shows "locked" after restart, CLI fails.

**Cause:** Without `AUTO_UNLOCK_PASSWORD` in `.env`, the node doesn't auto-start.

**Fix:** Either:
- Add `AUTO_UNLOCK_PASSWORD=yourpassword` to `.env`, or
- Manually run `hub-cli unlock --password YOUR_PASSWORD --save` after each restart

## 11. Recovery phrase file — never read it

**Symptom:** Agent reads or displays the recovery phrase in chat.

**Fix:** The agent MUST NOT read `.recovery` files. Tell the user the file path so
they can store it offline.

## 12. Channel has capacity but can't send payments (0 outbound)

**Symptom:** LSP channel is active, `localBalanceSat` is tiny (e.g. 660 sats),
`localSpendableBalanceSat` is 0. `pay-invoice` fails.

**Cause:** LSP channels open with almost all balance on the remote side.

**Fix:** Push sats through the channel to rebalance:
```bash
hub-cli make-invoice --amount 100000 --description "Rebalance"
# Pay from external source: faucet (signet) or another wallet (mainnet)
```

**Pre-check before sending:** Always check `localSpendableBalanceSat` in `list-channels`
output. If 0, rebalance first.

## 13. Wrong env var names

**Symptom:** Hub ignores network configuration.

**Fix — Correct signet `.env`:**
```env
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
WORK_DIR=.
AUTO_UNLOCK_PASSWORD=your-strong-random-password
```

Do NOT use `LDK_BITCOIN_NETWORK` — that var is not recognized.

## 14. Forgetting static channel backups

**Symptom:** Server dies, channels exist on-chain but spending balance is unrecoverable.

**Cause:** Without an Alby account, static channel backups are stored ONLY locally.

**Fix:** After every new channel open:
```bash
cp -r /opt/albyhub/ldk/static_channel_backups/ /secure/backup/path/
```

**Better fix:** Connect an Alby account — backups become automatic and encrypted.

## 15. Password shared in chat

**Symptom:** Hub password visible in conversation history.

**Fix:** For mainnet setups, do NOT share the password in chat.
- Use `AUTO_UNLOCK_PASSWORD` in `.env` for automation
- For manual operations, direct the user to run commands themselves
- The `.env` file (`chmod 600`) is the secure way to store the password
- Generate strong passwords: `sudo /usr/local/bin/alby-hub-password.sh generate`

## 16. Recovery phrase left on disk

**Symptom:** `~/.hub-cli/albyhub.recovery` file exists after setup.

**Risk:** Anyone with server access can steal all funds.

**Fix:** After the user confirms they've written down the recovery phrase offline:
```bash
rm ~/.hub-cli/albyhub.recovery
```

## 17. Weak passwords for mainnet

**Symptom:** Password like "Hermes123" used for the hub.

**Fix:** Always generate a strong random password:
```bash
sudo /usr/local/bin/alby-hub-password.sh generate
```
This creates a 44-character random password. Store it in a password manager.

## 18. Password lost / forgot .env contents

**Symptom:** `.env` file is corrupted or lost.

**Fix (prevention):**
- Store the password in a password manager during initial setup
- View current password: `sudo /usr/local/bin/alby-hub-password.sh show`
- Recovery requires the 12-word phrase — lightning channels will need force-close (14-day wait)

## 19. Thinking the Web UI is required for setup

**Reality:** The entire setup is designed to be fully automated via CLI. No Web UI
interaction is needed.

**If you want to use the Web UI later:**
- The password is the same as `AUTO_UNLOCK_PASSWORD` initially
- Change at: `http://<server-ip>:8080/settings/change-unlock-password`
- Changing the Web UI password does NOT affect `AUTO_UNLOCK_PASSWORD` — automation keeps working

## 20. `nohup`/`&` doesn't work in Hermes terminal

**Fix:** Use `terminal(background=true)` to start the hub. Then run all subsequent
commands in separate `terminal()` calls.

## 21. CWD nuked during cleanup

**Symptom:** After `rm -rf /opt/albyhub`, all subsequent commands fail.

**Cause:** Shell's current working directory was `/opt/albyhub`.

**Fix:** Always `cd /tmp` or `cd /tmp` BEFORE running `rm -rf /opt/albyhub`.

## 22. Data remnants after nuke

**Symptom:** New hub starts with old data (old channels, old wallet).

**Cause:** Hub process was still running when files were deleted.

**Fix:** Kill the hub FIRST:
```bash
pkill -9 -f albyhub
sleep 2
pgrep -f albyhub && echo "STILL RUNNING" || echo "Dead"
cd /tmp
sudo rm -rf /opt/albyhub
```

## 23. appPubkey vs id confusion

**Symptom:** `404 Not Found` when deleting an app.

**Cause:** `DELETE /api/apps/{key}` requires the hex `appPubkey`, NOT the numeric `id`.
The numeric `id` is used for transfers (`toAppId`) and listing.

**Fix:** List all apps and find by numeric `id`, then use the `appPubkey` from the
listing for deletion.

## 24. Transfer `toAppId` type error

**Symptom:** `400 Bad Request: Unmarshal type error: expected=uint, got=string, field=toAppId`

**Cause:** The Hub's Go backend strictly expects a JSON number. If the ID was stored
as a string in JSON and read back without `Number()` conversion, it fails.

**Fix:** Store as number in JSON, read back with `Number()`. Never call `String()`
on the ID before passing it to the request body. See
[toappId-uint-string-bug.md](toappId-uint-string-bug.md).

## 25. v1.22.2 two-step setup required

**Symptom:** `setupCompleted: false` after calling `/api/setup`.

**Cause:** v1.22.2 requires two separate calls: `/api/setup` (stores config, returns 204)
then `/api/start` (starts LDK node, returns JWT).

**Fix:**
```bash
hub-cli setup --password '<password>' --backend LDK
hub-cli start --password '<password>' --save
```

## 26. Lightning address OAuth failure

**Symptom:** `POST /api/lightning-addresses` returns
`"oauth2: token expired and refresh token is not set"`.

**Cause:** The Hub doesn't have a live Alby account OAuth session. The JWT is valid
but lightning address creation requires OAuth.

**Fix:** Treat `createLightningAddress` as best-effort. The NWC connection and `lud16`
remain fully usable. Serve `/.well-known/lnurlp/<username>` from your backend instead.
See [lnurl-pay-endpoint.md](lnurl-pay-endpoint.md).

## 27. Megalith minimum channel size confusion

**Symptom:** `CounterpartyForceClosed: chan size below min chan size` when using 150k.

**Cause:** On older Hub versions, Megalith Mutinynet required 200k minimum.

**Fix:** On v1.22.2, 150k works. Use `hub-cli request-lsp-order --amount 150000 --lsp-identifier megalith`.

## 28. Esplora `confirmations` is null during signet sync lag

**Symptom:** Esplora returns `confirmations: null` for a transaction that is deeply
confirmed (42+ confirmations visible at `https://mutinynet.com/tx/<txid>`).

**Fix:** Don't gate `pay-invoice` on the API `confirmations` field. Check
`hub-cli get-node-status` for `LatestOnchainWalletSyncTimestamp` and ensure sync lag
is under 30 seconds. Verify at `https://mutinynet.com/tx/<txid>` (signet) or
`https://mempool.space/tx/<txid>` (mainnet).

## 29. mutinynet-cli login device code invalidation

**Symptom:** GitHub device code expires before you can auth.

**Cause:** Each `mutinynet-cli login` call generates a new code and invalidates the
previous one.

**Fix:** Run once, keep the process alive with `background(true)` + PTY, and auth the
code it shows. See [mutinynet-cli.md](mutinynet-cli.md).
