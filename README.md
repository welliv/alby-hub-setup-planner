# Alby Hub Setup Planner + API Reference

> An [Agent Skill](https://agentskills.io/) that guides AI agents through setting up
> [Alby Hub](https://github.com/getAlby/hub) — a self-custodial Bitcoin Lightning node —
> and operating it day-to-day via the REST API.

## What This Is

A **two-in-one skill**:

1. **8-step setup planner** — install, configure, wallet init, LSP channel, NWC app,
   backup, payment testing
2. **REST API reference** — app management, transfers, Lightning addresses, LNURL pay,
   invoices, payments, pitfalls

Covers **signet** (free testing) and **mainnet** (real funds).

## Installation

```bash
# Clone into your agent's skills directory
git clone https://github.com/welliv/alby-hub-setup-planner.git

# Or let your agent do it:
npx skills add welliv/alby-hub-setup-planner
```

Compatible with Claude Code, Cursor, GitHub Copilot, OpenClaw, Hermes, and any agent
that reads `SKILL.md`.

## Example Prompts

- "Set up Alby Hub on signet"
- "Install Alby Hub and open a Lightning channel"
- "Initialize my Alby Hub wallet and create an NWC connection"
- "Guide me through a full Alby Hub test setup with signet"
- "Create an NWC app and transfer 10000 sats to it"
- "Set up a Lightning address for my Hub"

## Repo Structure

```
README.md                              ← You are here (human docs)
SKILL.md                               ← The skill (agent instructions)
scripts/
  alby-hub-password.sh                 ← Password generate/show/export
references/
  alby-hub-v1.22.2-setup.md            ← Complete v1.22.2 signet setup flow
  nuke-and-rebuild.md                  ← Full teardown procedure
  mutinynet.md                         ← Signet testing, faucet, mutinynet-cli
  signet-sync-and-esplora.md           ← Sync lag, Esplora behaviours, address derivation
  mainnet.md                           ← Mainnet-specific considerations
  lsp.md                               ← LSP channel opening flow, costs, troubleshooting
  lsp-channel-opening.md               ← LSPS1 via hub-cli request-lsp-order (from alby-hub-api)
  megalith-signet-lsp.md               ← Megalith minimums, CounterpartyForceClosed
  nwc-faucet-patterns.md               ← Full faucet identity + wallet creation flow
  lnurl-pay-endpoint.md                ← LNURL pay for LightningAddress SDK compatibility
  toappId-uint-string-bug.md           ← The expected=uint, got=string transfer bug
  pitfalls.md                          ← 29 common issues and fixes
  security.md                          ← Password, recovery, channel backups
```

## Signet vs Mainnet

The **same 8-step workflow** applies to both. Only the source of funds and risk level differ.

| | Signet | Mainnet |
|---|---|---|
| **Network** | `NETWORK=signet` | `NETWORK=mainnet` |
| **Esplora** | `mutinynet.com/api` | Default (Alby's) |
| **Block explorer** | `mutinynet.com/tx/<txid>` | `mempool.space/tx/<txid>` |
| **Cost** | Free (faucet) | Real sats (~13k fee for 150k channel) |
| **Recovery phrase** | Low stakes | Metal backup, bank vault |
| **LSP fee** | Free at faucet | Pay from funded wallet |
| **NWC budget** | Testing | Controls real spending |

## Prerequisites

- Linux server (x86_64)
- Node.js (for `hub-cli`)
- ~70MB free disk space
- Signet: a GitHub account (for faucet)
- Mainnet: a funded Bitcoin wallet

## License

MIT
