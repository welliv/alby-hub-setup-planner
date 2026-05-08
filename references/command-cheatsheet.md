# Alby Hub CLI Command Cheatsheet

Verified working commands for hub-cli v0.4.0. These correct errors found in the official alby-hub-skill docs.

## Invocation

```bash
# CORRECT — global binary after npm install -g @getalby/hub-cli
hub-cli <command> [options]

# WRONG — shown in official alby-hub-skill SKILL.md, fails with "unknown command"
npx -y @getalby/hub-cli hub-cli setup
npx -y @getalby/hub-cli@0.4.0 hub-cli setup
```

## Verified Command List

| Operation | Correct Command | Wrong Command (from upstream docs) |
|-----------|----------------|-----------------------------------|
| Setup wallet | `hub-cli setup --password PASS` | — |
| Start node | `hub-cli start --password PASS --save` | — |
| Unlock (already running) | `hub-cli unlock --password PASS --save` | — |
| Get info | `hub-cli get-info` | — |
| Get balances | `hub-cli get-balances` | — |
| List channels | `hub-cli list-channels` | — |
| List NWC apps | `hub-cli list-apps` | ~~`hub-cli apps`~~ (doesn't exist) |
| List peers | `hub-cli list-peers` | — |
| List transactions | `hub-cli list-transactions` | — |
| Create invoice | `hub-cli make-invoice --amount N --description "desc"` | — |
| Pay invoice | `hub-cli pay-invoice <invoice>` | — |
| Create NWC app | `hub-cli create-app --name "name"` | — |
| LSP suggestions | `hub-cli get-channel-suggestions` | — |
| Request LSP channel | `hub-cli request-lsp-order --amount N --lsp-type LSPS1 --lsp-identifier megalith` | — |
| On-chain address | `hub-cli get-onchain-address` | — |
| Backup mnemonic | `hub-cli backup-mnemonic --password PASS --output FILE` | — |
| Change password | `hub-cli change-password --current-password OLD --confirm-current-password OLD --new-password NEW` | — |
| Node status | `hub-cli get-node-status` | — |
| Health check | `hub-cli get-health` | — |

## Signet-Specific

| Operation | Command/URL |
|-----------|------------|
| Faucet (web) | https://faucet.mutinynet.com |
| Transaction explorer | `https://mutinynet.com/tx/<txid>` |
| Resolve LNURL | `curl -s "https://lnurl.mutinynet.com/.well-known/lnurlp/<name>"` |
| LNURL pay invoice | `curl -s "<callback>?amount=<msat>"` → get `pr` field → `hub-cli pay-invoice <pr>` |
