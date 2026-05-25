# Nuke & Rebuild: Full Teardown Procedure

Session: 2026-05-24
Scope: Alby Hub local instance, Fly.io app, local nwc-faucet build

Use this when doing a clean slate rebuild of the entire stack.

---

## 1. Kill Alby Hub process

```bash
pkill -9 albyhub
# or if you know the PID:
kill <PID>
```

Verify: `ps aux | grep albyhub | grep -v grep` should return nothing.

---

## 2. Remove Alby Hub data and binary

```bash
rm -rf /opt/albyhub        # binary, config, nwc.db, ldk data, logs
rm -rf /root/.hub-cli      # saved JWT token
rm -f /tmp/albyhub-Server-Linux-x86_64.tar.bz2  # leftover download
```

Verify everything is gone:

```bash
echo "binary:"; which albyhub 2>&1
echo "data:"; ls /opt/albyhub 2>&1
echo "token:"; ls /root/.hub-cli/ 2>&1
echo "port 8080:"; ss -tlnp | grep 8080
echo "remnants:"; find / -maxdepth 4 -name "*albyhub*" 2>/dev/null | grep -v proc | grep -v node_modules
```

---

## 3. Destroy Fly.io app

Requires `FLY_API_TOKEN` env var:

```bash
export FLY_API_TOKEN="<token>"
flyctl apps list                                        # confirm app name
flyctl apps destroy <app-name> --yes
flyctl apps list                                        # confirm empty
```

There is no `flyctl volumes list` after destroy — volumes are deleted with the app.

---

## 4. Remove local nwc-faucet build

```bash
# Kill running process
kill <pid-of-node-dist-app-js>   # check: ps aux | grep "dist/app.js"

# Remove repo
rm -rf /root/nwc-faucet

# Verify port 3000 is free
ss -tlnp | grep 3000
```

---

## 5. Counter-check (full verification)

```bash
echo "=== ALBY HUB ==="
echo "binary:"; which albyhub 2>&1
echo "data:"; ls /opt/albyhub 2>&1
echo "token:"; ls /root/.hub-cli/ 2>&1
echo "process:"; ps aux | grep albyhub | grep -v grep
echo "port 8080:"; ss -tlnp | grep 8080

echo "=== NWC FAUCET ==="
echo "repo:"; ls /root/nwc-faucet 2>&1
echo "process:"; ps aux | grep "nwc-faucet\|faucet" | grep -v grep
echo "port 3000:"; ss -tlnp | grep 3000

echo "=== FLY.IO ==="
export FLY_API_TOKEN="<token>"
flyctl apps list

echo "=== SCRIPTS ==="
grep -rl "nwc\|faucet\|albyhub\|8080" /root/*.sh /root/*.py 2>/dev/null || echo "(none)"
```

All sections should show empty/nothing before proceeding to rebuild.

---

## Rebuild Order

1. Reinstall Alby Hub (download, extract to `/opt/albyhub`, configure `.env`)
2. Start Hub, unlock, save JWT
3. Wait for signet sync
4. Create Fly.io app
5. Deploy nwc-faucet from `welliv/nwc-faucet`

See the main SKILL.md for Hub install steps and signet-specific notes.
