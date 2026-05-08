# Alby Hub Security Best Practices

## Password Management

### Design Principle: Fully Automated, Zero UI

The hub password is generated randomly once, stored in `.env`, and never needs human input again. The agent manages everything via CLI — no Web UI required at any point.

If the user wants to access the Web UI later (`http://<server-ip>:8080`), they retrieve the password from `.env` themselves. Changing the Web UI password does NOT affect `AUTO_UNLOCK_PASSWORD` — automation keeps working.

### The Password Problem
The hub password is needed for: wallet setup, unlock, backup, and recovery. It must be:
1. **Strong** — random, not memorable (especially for mainnet)
2. **Stored securely** — not in chat, not in plain text world-readable files
3. **Accessible** — the agent needs it for automated operations

### Recommended Approach

**Generate a strong random password:**
```bash
sudo /usr/local/bin/alby-hub-password.sh generate
```
This generates a 44-char random password, adds `AUTO_UNLOCK_PASSWORD=<password>` to `.env`, and sets `chmod 600`.

**For the server (automated access):**
- Store in `/opt/albyhub/.env` as `AUTO_UNLOCK_PASSWORD=<password>`
- Set `chmod 600` on `.env` (owner read-only)
- The hub reads `.env` automatically — no need to source it
- The agent reads it via: `grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2`

**For the user (manual access):**
- Copy the password to a password manager (KeePassXC, Bitwarden, 1Password, etc.)
- To view on server: `sudo /usr/local/bin/alby-hub-password.sh show` (run in your own terminal)
- **NEVER share the password in chat, messaging, or email**

### Why .env despite the risks?
On a headless server without a desktop keyring (gnome-keyring, KWallet), the practical options are:
- `.env` file with `chmod 600` ✅ — good enough for self-hosted
- `pass` (unix password store with GPG) — better, but requires GPG key management
- Hardware security module — overkill for most setups

The `.env` file is a reasonable trade-off: it's protected by filesystem permissions and is the standard approach for server-side configuration.

### AUTO_UNLOCK_PASSWORD
Add to `.env` for unattended/agent-managed servers:
```env
AUTO_UNLOCK_PASSWORD=your-strong-random-password
```
**Trade-off:** Anyone with `.env` file access can unlock the hub. Acceptable when you control the filesystem.

## Recovery Phrase (12 words)

### Backup
```bash
# Get password from .env (not from chat)
HUB_PASS=$(grep AUTO_UNLOCK_PASSWORD /opt/albyhub/.env | cut -d= -f2)
hub-cli backup-mnemonic --password "$HUB_PASS" --output ~/.hub-cli/albyhub.recovery
```

### Storage rules
- **NEVER** store digitally (no password manager, no cloud, no chat, no screenshots)
- Write on paper or stamp on metal
- Store in a safe or bank vault
- After copying offline, **delete the digital copy** from the server
- The agent MUST NEVER read `.recovery` files

## Static Channel Backups

### Why they matter
- Recovery phrase alone only recovers on-chain funds
- Static channel backups are needed to recover lightning spending balance
- Without them: channels can only be force-closed (14-day wait)

### Self-hosted WITHOUT Alby account (manual)
Back up after EVERY new channel:
```bash
# When WORK_DIR=.
cp -r /opt/albyhub/ldk/static_channel_backups/ /secure/backup/path/

# Default data dir
cp -r ~/.local/share/albyhub/ldk/static_channel_backups/ /secure/backup/path/
```

### Self-hosted WITH Alby account (automatic)
- Channel backups are encrypted and synced to your Alby account automatically
- Only the recovery phrase is needed for full recovery
- Connect via: `hub-cli connect-alby-account`

### Pro/Pro Cloud
- Automatic encrypted backups to Alby account
- Only need: recovery phrase + Alby account access

## File Permissions

```bash
chmod 600 /opt/albyhub/.env                    # Owner read/write only
chmod 600 ~/.hub-cli/albyhub.recovery          # Owner read/write only
chmod 600 ~/.hub-cli/token.jwt                 # Owner read/write only
```

## Backup Checklist by Setup Type

| Setup | Recovery Phrase | Channel Backups | Alby Account |
|-------|----------------|-----------------|--------------|
| Pro Cloud | Required | Automatic | Required |
| Pro | Required | Automatic | Required |
| Self-hosted + Alby account | Required | Automatic | Required |
| Self-hosted (no Alby) | Required | Manual, every channel | No |

## Recovery Process

If the server dies:
1. Install Alby Hub on new machine
2. Run `hub-cli setup --password NEW_PASSWORD` (creates new wallet)
3. Choose "Restore from recovery phrase" in web UI
4. Enter 12-word phrase
5. On-chain funds: recovered immediately
6. Lightning funds: use `hub-recovery` tool with channel backup file
   - Force-closes all channels
   - Funds return in up to 14 days
   - Must reopen channels to transact again
