#!/bin/bash
# alby-hub-password.sh — Safely manage the Alby Hub password
# Usage:
#   ./alby-hub-password.sh generate   — Generate a new password and update .env
#   ./alby-hub-password.sh show       — Print the password (for manual use only)
#   ./alby-hub-password.sh env        — Print just the AUTO_UNLOCK_PASSWORD= line

ENV_FILE="/opt/albyhub/.env"

case "$1" in
  generate)
    NEW_PASS=$(openssl rand -base64 32)
    # Remove old AUTO_UNLOCK_PASSWORD line if present
    sed -i '/^AUTO_UNLOCK_PASSWORD=/d' "$ENV_FILE"
    echo "AUTO_UNLOCK_PASSWORD=$NEW_PASS" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "✅ New password generated and saved to $ENV_FILE"
    echo "   Length: ${#NEW_PASS} characters"
    echo ""
    echo "⚠️  Store this password in a password manager!"
    echo "   You'll need it if the .env file is lost or you migrate servers."
    echo "   Run './alby-hub-password.sh show' to display it when needed."
    ;;
  show)
    grep '^AUTO_UNLOCK_PASSWORD=' "$ENV_FILE" | cut -d= -f2
    ;;
  env)
    grep '^AUTO_UNLOCK_PASSWORD=' "$ENV_FILE"
    ;;
  *)
    echo "Usage: $0 {generate|show|env}"
    echo ""
    echo "  generate — Create new random password and update .env"
    echo "  show     — Display the current password"
    echo "  env      — Print 'AUTO_UNLOCK_PASSWORD=<value>' line"
    exit 1
    ;;
esac
