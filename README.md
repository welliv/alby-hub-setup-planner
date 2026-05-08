# Alby Hub Setup Planner

A step-by-step planner for setting up [Alby Hub](https://github.com/getAlby/hub) from scratch — binary install, wallet init, channel opening, NWC app creation, and recovery. Tested on both **signet** (free) and **mainnet** (real funds).

## What This Is

A thin, opinionated skill that guides an AI agent (or a human) through the full Alby Hub setup process:

- **Manual binary install** — fastest path, recommended for testing and production
- **Signet testing** — free bitcoin, zero risk, same workflow as mainnet
- **Mainnet deployment** — real money, same steps, higher stakes
- **Docker and Cloud** paths — for managed setups

The planner is **8 steps**, fully tested on clean slate. Each step has verification criteria.

## Quickstart

```bash
# 1. Install binary + hub-cli
sudo mkdir -p /opt/albyhub && cd /opt/albyhub
wget https://github.com/getAlby/hub/releases/download/v1.21.6/albyhub-Server-Linux-x86_64.tar.bz2
tar -xjf albyhub-Server-Linux-x86_64.tar.bz2 && chmod +x bin/albyhub
npm install -g @getalby/hub-cli

# 2. Configure (signet or mainnet — see SKILL.md step 2)
sudo tee /opt/albyhub/.env > /dev/null << 'EOF'
NETWORK=signet
LDK_ESPLORA_SERVER=https://mutinynet.com/api
MEMPOOL_API=https://mutinynet.com/api
TX_EXPLORER=https://mutinynet.com/tx
WORK_DIR=.
EOF

# 3. Generate password
sudo cp scripts/alby-hub-password.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/alby-hub-password.sh
sudo alby-hub-password.sh generate

# 4. Start hub, init wallet, open channel, create NWC app, test
# → Follow the full 8-step planner in SKILL.md
```

**For mainnet:** Change `NETWORK=mainnet` in `.env`. See [references/mainnet.md](references/mainnet.md) for differences.

## Repo Structure

```
README.md                   ← You are here
SKILL.md                    ← The 8-step planner (the actual skill)
scripts/
  alby-hub-password.sh      ← Password generate/show/env
references/
  pitfalls.md               ← 20 common issues and fixes
  security.md               ← Password, recovery phrase, channel backups
  lsp.md                    ← LSP channel opening (LSPS1)
  mutinynet.md              ← Signet testing, faucet, mutinynet-cli
  mainnet.md                ← Mainnet-specific considerations
```

## Signet vs Mainnet

| | Signet | Mainnet |
|---|---|---|
| **Cost** | Free (faucet) | Real sats (~13k fee for 150k channel) |
| **Recovery phrase** | Low stakes | Metal backup, bank vault |
| **LSP fee** | Free at faucet.mutinynet.com | Pay from funded wallet |
| **Rebalance** | Free at faucet | Pay from real wallet |
| **NWC budget** | Testing | Controls real spending |

The workflow is identical — only the source of funds changes.

## Prerequisites

- Linux server (x86_64)
- Node.js (for `hub-cli`)
- ~70MB disk space
- For signet: a GitHub account (for faucet auth)
- For mainnet: a funded bitcoin wallet

## Related

- [Alby Hub](https://github.com/getAlby/hub) — the Lightning node
- [alby-hub-skill](https://github.com/getAlby/hub-skill) — day-to-day operations (post-setup)
- [Mutinynet](https://mutinynet.com) — signet for testing
