#!/usr/bin/env bash
# End-to-end verification of the deployed Gnome Tavern on Onyx testnet:
# funds the second player, registers two gnomes, serves drinks, claims a
# quest, posts wall notes, and reads the realm back via qrender/qeval.
# Run after scripts/deploy.sh. Individual quest-claim attempts may
# legitimately fail (only 3 of 8 quests are on today's board); the script
# reports which slot succeeded.
set -uo pipefail

export PATH="$PATH:$HOME/.gno/bin"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$ROOT/.secrets"
KEYHOME="$SECRETS/gnokey"
PASS="$(cat "$SECRETS/keypass.txt")"
REMOTE="http://127.0.0.1:26657"
CHAINID="onyx-1"
DEPLOYER_ADDR="g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h"
PATRON_ADDR="g15g63hzg36z8n5qjnzq6kxg4as5kms3vgqy42gw"
REALM_PATH="gno.land/r/$DEPLOYER_ADDR/gnometavern"

call() { # key func args...
  local key="$1" func="$2"; shift 2
  printf '%s\n' "$PASS" | gnokey maketx call \
    -pkgpath "$REALM_PATH" -func "$func" "$@" \
    -gas-fee 6000ugnot -gas-wanted 5000000 \
    -chainid "$CHAINID" -remote "$REMOTE" \
    --home "$KEYHOME" -insecure-password-stdin "$key"
}

echo "== fund patron with 30 testnet GNOT from tavernkeeper =="
printf '%s\n' "$PASS" | gnokey maketx send \
  -to "$PATRON_ADDR" -send 30000000ugnot \
  -gas-fee 2000ugnot -gas-wanted 2000000 \
  -chainid "$CHAINID" -remote "$REMOTE" \
  --home "$KEYHOME" -insecure-password-stdin tavernkeeper

echo "== tavernkeeper registers gnome Bram =="
call tavernkeeper Register -args "Bram"

echo "== patron registers gnome Zed =="
call patron Register -args "Zed"

echo "== Bram serves 14 Gnomebrew Ales (covers First Round / Morning Rush / Ale Baron / Full House) =="
for i in $(seq 1 14); do call tavernkeeper Serve -args 1 | grep -E "served|OK!" | head -2; done

echo "== Bram tries to claim each quest slot (at least one should succeed) =="
for slot in 0 1 2; do echo "-- slot $slot"; call tavernkeeper ClaimQuest -args "$slot" 2>&1 | grep -E "Quest complete|Error|panic" | head -2 || true; done

echo "== Zed serves and posts a wall note; Bram posts one too =="
call patron Serve -args 0 | grep -E "served|OK!" | head -2
call patron PostNote -args "Save me a seat by the fire."
call tavernkeeper PostNote -args "First round is on me!"

echo "== read back: qrender board =="
gnokey query vm/qrender --home "$KEYHOME" -remote "$REMOTE" -data "$REALM_PATH:" | head -40

echo "== read back: qeval Profile(tavernkeeper) =="
gnokey query vm/qeval --home "$KEYHOME" -remote "$REMOTE" -data "$REALM_PATH.Profile(\"$DEPLOYER_ADDR\")" || true

echo "== balances after =="
gnokey query bank/balances/"$DEPLOYER_ADDR" --home "$KEYHOME" -remote "$REMOTE"
gnokey query bank/balances/"$PATRON_ADDR" --home "$KEYHOME" -remote "$REMOTE"
