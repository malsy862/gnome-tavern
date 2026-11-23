#!/usr/bin/env bash
# Deploy the Gnome Tavern packages to the Gno.land **Onyx testnet** (onyx-1).
#
# Prerequisite: the deployer account (tavernkeeper) must hold testnet GNOT
# from the Faucet Hub (faucet.gno.land — hCaptcha-gated, browser only).
#
# The script talks to the real Onyx RPC through a local relay on
# 127.0.0.1:26657 (gnokey ignores HTTP proxy env vars and this sandbox's
# direct egress is blocked; the relay forwards via CONNECT+TLS to
# rpc.onyx.testnets.gno.land). It starts the relay if it is not running.
set -euo pipefail

export PATH="$PATH:$HOME/.gno/bin"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$ROOT/.secrets"
KEYHOME="$SECRETS/gnokey"
PASS="$(cat "$SECRETS/keypass.txt")"
REMOTE="http://127.0.0.1:26657"
CHAINID="onyx-1"
DEPLOYER_ADDR="g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h"
PKG_PATH="gno.land/p/$DEPLOYER_ADDR/tavernlogic"
REALM_PATH="gno.land/r/$DEPLOYER_ADDR/gnometavern"

# 1. Relay up?
if ! curl -s --max-time 5 http://127.0.0.1:26657/status >/dev/null; then
  echo "starting RPC relay..."
  nohup python3 "$SECRETS/gno_rpc_relay.py" >/tmp/relay.log 2>&1 &
  sleep 1
fi
curl -s http://127.0.0.1:26657/status | grep -o '"chain_id": *"[^"]*"' | head -1 || true

# 2. Balance check (need a few GNOT for storage deposits + gas).
echo "== deployer balance =="
gnokey query bank/balances/"$DEPLOYER_ADDR" --home "$KEYHOME" -remote "$REMOTE" || true

# 3. Deploy the pure package, then the realm.
echo "== addpkg $PKG_PATH =="
printf '%s\n' "$PASS" | gnokey maketx addpkg \
  -pkgpath "$PKG_PATH" -pkgdir "$ROOT/p/tavernlogic" \
  -gas-fee 41000ugnot -gas-wanted 40000000 -max-deposit 5000000ugnot \
  -chainid "$CHAINID" -remote "$REMOTE" \
  --home "$KEYHOME" -insecure-password-stdin tavernkeeper

echo "waiting for package activation..."
sleep 15

echo "== addpkg $REALM_PATH =="
printf '%s\n' "$PASS" | gnokey maketx addpkg \
  -pkgpath "$REALM_PATH" -pkgdir "$ROOT/r/gnometavern" \
  -gas-fee 41000ugnot -gas-wanted 40000000 -max-deposit 5000000ugnot \
  -chainid "$CHAINID" -remote "$REMOTE" \
  --home "$KEYHOME" -insecure-password-stdin tavernkeeper

echo "waiting for realm activation..."
sleep 15

echo
echo "Deployed:"
echo "  package: $PKG_PATH"
echo "  realm:   $REALM_PATH"
echo "  gnoweb:  https://latest.testnets.gno.land/r/$DEPLOYER_ADDR/gnometavern"
echo "Next: scripts/verify.sh"
