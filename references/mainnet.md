# Mainnet Setup Reference

## .env for Mainnet

```env
NETWORK=mainnet
WORK_DIR=.
```

That's it. No custom Esplora needed — Alby's defaults work on mainnet.
`AUTO_UNLOCK_PASSWORD` is added by the password script (same as signet).

## Mainnet vs Signet — What's Different

Everything in the planner is the same except where funds come from.

### Step 5: Pay LSP Fee
- **Signet:** Pay at https://faucet.mutinynet.com (free)
- **Mainnet:** Pay from a funded bitcoin wallet (real sats, ~13k sats for 150k channel)

### Step 8b: Rebalance (push outbound liquidity)
- **Signet:** Create invoice → pay at faucet.mutinynet.com
- **Mainnet:** Create invoice → pay from another wallet with real sats

### Step 8c: Test outbound payment
- **Signet:** Pay `refund@lnurl.mutinynet.com` (test LNURL, 0 fees)
- **Mainnet:** Pay any real LNURL/invoice (real routing fees apply)

## Mainnet-Only Considerations

1. **Recovery phrase** — This controls REAL money. Write on metal, store in a bank vault. Never photograph or store digitally.
2. **Password** — Use `alby-hub-password.sh generate` for a strong random password. Treat it like a banking password.
3. **Channel backups** — Critical on mainnet. Either:
   - Connect an Alby account (`hub-cli connect-alby-account`) for automatic encrypted backups, OR
   - Manually copy `/opt/albyhub/ldk/static_channel_backups/` after every new channel
4. **NWC budget** — `--max-amount` controls REAL spending. Set conservatively.
5. **LDK sync** — On mainnet, initial sync takes longer (5-15 minutes). Wait for `get-node-status` to show `isReady: true` before opening channels.

## Verifying Transactions

- **Mainnet:** `https://mempool.space/tx/<txid>`
- **Signet:** `https://mutinynet.com/tx/<txid>`

## Choosing an LSP on Mainnet

`hub-cli get-channel-suggestions` returns LSPs for both networks. Filter to `network: "bitcoin"` (not `"signet"`). Recommended: Megalith (identifier: `megalith`).

## Common Mainnet Mistakes

- **Opening a channel too small** — 150k sats minimum on most LSPs. Start with 500k+ for meaningful capacity.
- **Not rebalancing** — You can receive but not send until you push sats through. This trips up every first-timer.
- **Ignoring channel reserve** — ~354 sats is locked as reserve. Your spendable balance is always slightly less than localBalanceSat.
- **Forgetting about the 14-day wait** — Force-closing channels means a 14-day delay before funds are spendable on-chain.
