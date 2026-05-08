# Alby Hub Setup Planner

> An [Agent Skill](https://agentskills.io/) that guides AI agents through setting up [Alby Hub](https://github.com/getAlby/hub) — a self-custodial Bitcoin Lightning node.

## What This Is

A **thin, opinionated planner** that an agent executes step-by-step. It covers:

- **Manual binary install** — fastest path, works on any Linux server
- **Signet testing** — free bitcoin, zero risk, same workflow as mainnet
- **Mainnet deployment** — real money, same steps, higher security stakes
- **NWC app creation** — connect wallets, allocate budgets
- **Recovery & backup** — mnemonic handling, channel backups

The planner is **8 steps**. Each step has verifiable success criteria (e.g. `"state": "settled"`).

## Installation

```bash
# Clone into your agent's skills directory
git clone https://github.com/welliv/alby-hub-setup-planner.git

# Or let your agent do it:
npx skills add welliv/alby-hub-setup-planner
```

Compatible with Claude Code, Cursor, GitHub Copilot, OpenClaw, Hermes, and any agent that reads `SKILL.md`.

## Example Prompts

Use these prompts to trigger the skill:

- "Set up Alby Hub on signet"
- "Install Alby Hub and open a Lightning channel"
- "Initialize my Alby Hub wallet and create an NWC connection"
- "Guide me through a full Alby Hub test setup with signet"

## Repo Structure

```
README.md                    ← You are here (human docs)
SKILL.md                     ← The skill (agent instructions)
scripts/
  alby-hub-password.sh       ← Password generate/show/export
references/
  pitfalls.md                ← Common issues + fixes (loaded on demand)
  security.md                ← Password, recovery, backups
  lsp.md                     ← LSP channel opening flow
  mutinynet.md               ← Signet testing, faucet, mutinynet-cli
  mainnet.md                 ← Mainnet-specific considerations
```

## Signet vs Mainnet

The **same 8-step workflow** applies to both. Only the source of funds and risk level differ.

| | Signet | Mainnet |
|---|---|---|
| **Network** | `NETWORK=signet` | `NETWORK=mainnet` |
| **Esplora** | `mutinynet.com/api` | Default (Alby's) |
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

## After Setup

Once the hub is running, switch to **[alby-hub-skill](https://github.com/getAlby/hub-skill)** for day-to-day operations (paying invoices, checking balances, managing channels).

## License

MIT
