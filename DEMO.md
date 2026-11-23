# Demo video script — The Gnome Tavern

Target length: ~2.5 minutes. Format: screen recording, terminal + browser
side by side. Narration lines are suggestions; captions can replace voice.

**Production note (sandbox):** when recording inside the Rena sandbox,
gnokey must use `-remote http://127.0.0.1:26657` (local relay to the real
Onyx RPC — same chain, same transactions) because the sandbox blocks
direct egress. On any normal machine use
`-remote https://rpc.onyx.testnets.gno.land:443`. Everything else below
is identical. Set `$REALM` once:

```sh
REALM=gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern
```

Pre-flight (before recording): tavernkeeper and patron keys funded;
tavern deployed (scripts/deploy.sh); run scripts/verify.sh once OFF
camera so the flow is rehearsed — then, for the clean take, the on-camera
run below uses fresh actions that still work on an already-seeded tavern
(serve/quest/claim depend on the day; if Bram already claimed today's
quests, either wait for the next tavern day — 2,000 blocks — or narrate
over the verify.sh transcript + gnoweb pages instead).

---

### Shot 1 — The tavern board (0:00-0:20)
- Browser: open https://latest.testnets.gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern
- Show: title, tavern day, gnome count, today's quest board, leaderboard, wall.
- Say: "This is the Gnome Tavern — a tavern that lives entirely on-chain
  on Gno.land's Onyx testnet. This page is rendered by the realm itself."

### Shot 2 — The code, briefly (0:20-0:35)
- Browser: gnoweb "Source" tab; scroll gnometavern.gno, then show the
  repo tree: pure package `p/tavernlogic` + realm `r/gnometavern`.
- Terminal: `gno test ./...` → both packages `ok`.
- Say: "All game rules live in a pure package with unit tests; the realm
  owns state, caller authentication and rendering. Twelve tests pass."

### Shot 3 — Register two gnomes (0:35-0:55)
- Terminal 1: `gnokey maketx call -pkgpath $REALM -func Register -args "Bram" ... tavernkeeper`
  → show the "Welcome to the Gnome Tavern, Bram!" result + TX HASH.
- Terminal 2: same with `-args "Zed"` and key `patron`.
- Say: "Two players, two real transactions. One gnome per address, and
  names are unique — a second registration aborts."

### Shot 4 — Work a shift (0:55-1:25)
- Terminal 1: `Serve -args 1` (Gnomebrew Ale) a few times; show the
  "+5 coins, +3 XP" responses and the level line.
- Try `Serve -args 5` (Dragonfire Stew) → show the abort: level too low.
- Say: "Serving pays Tavern Coins and XP. The good stuff is level-gated —
  Dragonfire Stew needs level 5."

### Shot 5 — The quest board pays out (1:25-1:50)
- Browser: open the `:quests` page; point at one quest Bram has finished.
- Terminal 1: `ClaimQuest -args <slot>` → "Quest complete: ...!"
- Browser: refresh the realm root — leaderboard now shows Bram ahead.
- Say: "The quest board rotates every tavern day — 2,000 blocks — and is
  identical for everyone. Finish the work, claim the reward, once."

### Shot 6 — Feast and the wall (1:50-2:15)
- Terminal 1: `Feast` → "-50 coins, +15 XP".
- Terminal 2: `PostNote -args "Save me a seat by the fire."`
- Browser: open `:wall` and `:gnome/<patron-address>` pages.
- Say: "Coins buy a feast for extra XP, and the wall keeps the tavern's
  memory — every note is a transaction."

### Shot 7 — Close (2:15-2:30)
- Browser: realm root, slow scroll: board, quests, leaderboard, wall.
- Say: "A complete little game — menu, levels, quests, feasts and a
  leaderboard — written in Gno, deployed on testnet, free for anyone to
  play. The Gnome Tavern is open."
- End card: realm path + gnoweb URL + repo URL (repo URL added once
  published).
