# 🍺 The Gnome Tavern

**An on-chain tavern game on Gno.land.** Register a gnome, work shifts
serving drinks and food from the tavern menu, complete a rotating daily
quest board, level up, feast, and leave notes on the tavern wall for the
next traveller. Every serve, quest and note is a real transaction, and
the tavern board you see on gnoweb is rendered by the realm itself —
there is no backend and no off-chain game state.

Built for the **Gnome Tavern Hackathon** (Gno.land) on DoraHacks.

## Play it live (Onyx testnet)

- **Realm:** `gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern`
- **Pure package:** `gno.land/p/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/tavernlogic`
- **On gnoweb:** https://latest.testnets.gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern
  - Pages: append `:menu`, `:quests`, `:leaderboard`, `:wall` or
    `:gnome/<your-address>` to the realm URL.
- **Network:** Onyx testnet, chain ID `onyx-1`, RPC
  `https://rpc.onyx.testnets.gno.land:443`. Get free test GNOT from
  [faucet.gno.land](https://faucet.gno.land).
- **Deployment evidence:** package tx
  `zM9pPBqUsX0Rn6JJ+txhG6ScBzLz3ULp+y9IgHrXymk=` (height 1344352),
  realm tx `G0gf3Nc07CX9ouZ0r261VvgPc80tXU9w0PVK3AeS/7M=` (height
  1344360). The full verification transcript — two players registering,
  serving, claiming quests and posting notes, with balances reconciled —
  is recorded in [BUILD-LOG.md](BUILD-LOG.md).

### How to play (gnokey)

```sh
REMOTE=https://rpc.onyx.testnets.gno.land:443
REALM=gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern

# 1. Register your gnome (one per address, names are unique)
gnokey maketx call -pkgpath $REALM -func Register -args "YourName" \
  -gas-fee 3000ugnot -gas-wanted 5000000 -chainid onyx-1 -remote $REMOTE yourkey

# 2. Serve menu items to earn Tavern Coins and XP (IDs on the :menu page)
gnokey maketx call -pkgpath $REALM -func Serve -args 1 \
  -gas-fee 3000ugnot -gas-wanted 5000000 -chainid onyx-1 -remote $REMOTE yourkey

# 3. Claim a finished quest from today's board (slots 0-2, see :quests)
gnokey maketx call -pkgpath $REALM -func ClaimQuest -args 0 \
  -gas-fee 3000ugnot -gas-wanted 5000000 -chainid onyx-1 -remote $REMOTE yourkey

# 4. Feast: spend 50 coins for +15 XP, once per tavern day
gnokey maketx call -pkgpath $REALM -func Feast \
  -gas-fee 3000ugnot -gas-wanted 5000000 -chainid onyx-1 -remote $REMOTE yourkey

# 5. Pin a note to the wall
gnokey maketx call -pkgpath $REALM -func PostNote -args "First round is on me!" \
  -gas-fee 3000ugnot -gas-wanted 5000000 -chainid onyx-1 -remote $REMOTE yourkey
```

### The game at a glance

- **Menu ladder:** 6 items, from Barley Soup (level 1) to Dragonfire
  Stew (level 5). Better items pay more coins and XP but need a higher
  level. Every 40 XP is a new level; at most 40 serves per tavern day.
- **Quest board:** 3 quests per tavern day, drawn deterministically from
  a pool of 8 (serve totals and per-item targets), so the board is the
  same for everyone and nobody can re-roll it. A tavern day lasts 2,000
  blocks; the board and daily counters reset when it rolls over.
- **Feast:** a coin sink — 50 coins buys +15 XP, once per day.
- **Leaderboard & wall:** the realm renders a top-10 board, a full
  leaderboard, per-gnome cards and a 30-note message wall on gnoweb.
- Tavern Coins are in-realm accounting only; no real funds move.

## Architecture

```
gnowork.toml                  workspace root
p/tavernlogic/                pure package: all game rules (no chain state)
  tavernlogic.gno             menu, levels, quest board, Gnome state machine
  tavernlogic_test.gno        7 unit tests for the rules
r/gnometavern/                the realm: state, caller auth, gnoweb rendering
  gnometavern.gno             Register / Serve / ClaimQuest / Feast / PostNote + views
  render.gno                  Render() pages: board, menu, quests, leaderboard, wall, gnome cards
  gnometavern_test.gno        5 end-to-end realm tests (two players)
scripts/
  deploy.sh                   deploy both packages to Onyx (after faucet funding)
  verify.sh                   two-player on-chain verification run
BUILD-LOG.md                  build diary: facts, test output, deployment evidence
DEMO.md                       demo video script
```

The split is deliberate: every rule (level gates, daily caps, quest
determinism, claim-once semantics) lives in the pure package and is
unit-tested without a chain; the realm is a thin layer that owns the
persistent maps, authenticates callers (`cur.Previous()` must be a
direct user call), and renders its own pages for gnoweb.

**Demo video:** a 2:31 walkthrough (narration + captions) of the live
realm — registration, a working shift with an on-camera level-up, quest
claims, a feast and the wall — is linked from the hackathon submission.

## Run the tests

Requires the Gno toolchain (v1.8.0 was used for this project).

```sh
gno test ./...
# ok  ./p/tavernlogic     (7 tests)
# ok  ./r/gnometavern     (5 tests)
```

12/12 tests pass; `gno lint` is clean.

## Run it locally

```sh
gnodev ./r/gnometavern   # local devnet + gnoweb on :8888, pre-funded keys
```

## A note on deploying

On the Onyx testnet, newly added packages start **inert** and are
enabled by the chain's automatic package approver (GPAS) after a review
pass. `scripts/deploy.sh` performs both `addpkg` transactions; expect
the packages to become callable once the approver enables them (for
this deployment: verdict + ~1 hour). `scripts/verify.sh` then plays a
full two-player session against the live realm and reads the state
back. The scripts expect a local `.secrets/` keybase (gitignored,
never committed) — see BUILD-LOG.md for the full story.

## License

MIT — see [LICENSE](LICENSE). In the hackathon spirit: fork the
tavern, open your own.
