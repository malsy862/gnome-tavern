# Gnome Tavern — Build Log

Hackathon: Gnome Tavern Hackathon (Gno.land) on DoraHacks.
Submissions close: 18 Dec 2026 08:00 WIB. Judging: technical 40%, user appeal 20%, creativity 20%, docs+demo 20%.

## Status summary
- [x] Toolchain installed — gno/gnokey/gnodev **v1.8.0** (official installer, `~/.gno/bin`)
- [x] Testnet + namespace verified — Onyx `onyx-1`; address namespace needs no registration
- [x] Deployer account created — `tavernkeeper` = `g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h`;
      second player `patron` = `g15g63hzg36z8n5qjnzq6kxg4as5kms3vgqy42gw`.
      Key material lives ONLY in `.secrets/` (dir 700, files 600, gitignored); mnemonics were
      captured by redirecting `gnokey add` output straight to file and verified present
      (24-word line) without ever being printed.
- [ ] Deployer account funded — **BLOCKED: the Onyx faucet enforces hCaptcha**
      (`POST https://faucet.onyx.testnets.gno.land` drip → `invalid captcha request`).
      The Faucet Hub (faucet.gno.land) is the only Onyx faucet; it requires solving hCaptcha
      in a browser. Needs one browser step: open faucet.gno.land → Onyx Faucet → paste the
      tavernkeeper address → solve captcha → Request Drip (300 GNOT). Patron can be funded
      by a normal on-chain transfer from tavernkeeper afterwards.
- [x] RPC access from sandbox solved — gnokey ignores proxy env vars and direct egress is
      blocked, so a local relay (`/tmp/gno_rpc_relay.py`, plain HTTP on 127.0.0.1:26657 →
      CONNECT+TLS via the egress proxy → the real `rpc.onyx.testnets.gno.land`) is used for
      all gnokey commands. Verified: `gnokey query bank/balances/<addr>` answers through it.
- [x] Pure package written + tests pass — `p/tavernlogic`, 7/7 tests pass
- [x] Realm written + tests pass — `r/gnometavern`, 5/5 tests pass; `gno lint` clean
- [ ] Deployed to testnet — **BLOCKED on the faucet captcha (see above).**
      Everything else is ready: `scripts/deploy.sh` performs both `addpkg`
      txs (package `gno.land/p/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/tavernlogic`,
      then realm `gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern`)
      as soon as tavernkeeper holds test GNOT.
- [ ] Deployment verified end-to-end — scripted and ready: `scripts/verify.sh`
      funds patron (30 GNOT), registers Bram + Zed, serves 14 ales, claims a
      quest, posts wall notes, reads back qrender + qeval + balances.
- [x] README.md + DEMO.md written
- [ ] GitHub publication — MALSI'S STEP (account) — not done here
- [ ] DoraHacks submission — MALSI'S STEP (account) — not done here

## Facts established (2026-11-23, from docs.gno.land, read first-hand)
- Current testnet: **Onyx** (`-chainid onyx-1`), RPC `https://rpc.onyx.testnets.gno.land:443`
  (alias `https://rpc.latest.testnets.gno.land:443`). It runs mainnet's code/package set and
  "upgrades in place", so deployments persist across releases. Mainnet (`gnoland-1`) is NOT used.
- Namespace: every account gets an address-based namespace `gno.land/r/<g1-address>/…` —
  no name registration needed, only that account can deploy under it.
- Faucet: faucet.gno.land (web hub; rate-limited per address). Deploys lock a storage
  deposit of 100 ugnot per byte of code+state, plus gas.
- Toolchain: precompiled binaries via the official one-line installer into `~/.gno/bin`.

## Log
- 2026-11-23 — Build started. Environment checked: no Go/Gno preinstalled; proxy available.
- 2026-11-23 — Toolchain installed (v1.8.0). Note: the release binary looks for the stdlib
  under its CI path `/__w/gno/gno/gnovm/stdlibs`; fixed by symlinking that path to a
  shallow clone of gnolang/gno (`/tmp/gno-ref`), which also served as the API reference.
- 2026-11-23 — Accounts created (tavernkeeper + patron, addresses in the status section).
  Faucet drip attempted via the faucet's JSON-RPC API → `invalid captcha request`:
  funding is hCaptcha-gated (browser-only). No alternative Onyx faucet exists.
- 2026-11-23 — Code written and tested. Two Gno v1.8 lessons worth keeping:
  (1) `testing.SetRealm` mutates the *test frame's* realm in place, so it must be called
  directly in the test body — wrapping it in a helper silently loses the identity switch.
  (2) Panics from crossing realm functions are *aborts*: plain `recover()` cannot catch
  them in tests; the `revive()` builtin can (same mechanism as p/nt/uassert).
  Final test run:
  ```
  $ gno test ./...
  ok      ./p/tavernlogic     (7 tests: levels, menu ladder, quest determinism,
                               serve/level-gate, daily cap + rollover, claim-once, feast)
  ok      ./r/gnometavern     (5 tests: register rules, serve flow, quest claim,
                               feast, wall + all Render pages)
  $ gno lint ./p/... ./r/...  (clean)
  ```
- 2026-11-23 — `scripts/deploy.sh` + `scripts/verify.sh` written and ready. Deployment
  itself is the only step left before the on-chain verification transcript exists.

## Verification result — 2026-11-23 ~12:45 WIB (checked again ~14:10 WIB)

- Deploy txs BOTH landed: package `tavernlogic` height 1344352, tx
  `zM9pPBqUsX0Rn6JJ+txhG6ScBzLz3ULp+y9IgHrXymk=`; realm `gnometavern`
  height 1344360, tx `G0gf3Nc07CX9ouZ0r261VvgPc80tXU9w0PVK3AeS/7M=`.
  Deployer balance after: ~267.79 GNOT (300 faucet − 30 sent to patron −
  deposits/gas).
- BUT the realm is NOT callable: every `MsgCall` in `verify.sh` panicked
  (`unexpected node with location .../gnometavern:0:0`), `qeval` says
  "package not found", and gnoweb shows "Not Yet Enabled".
- Root cause (verified live ~14:10 WIB, height 1345885, ~1,500 blocks
  after deploy): `qpkgmeta_json` for the realm reads
  `{"status":"inert","pending":true,"reason":"waiting for a package
  approver to enable it"}`. The package `tavernlogic` reads
  `{"status":"live"}` — so the package is live, the realm is inert
  pending a package approver. This is NOT an activation lag and NOT a
  code bug (12/12 tests pass; the realm simply cannot be called until
  enabled). Next step: find the enablement path (approver process) and
  re-run `scripts/verify.sh` once the realm reads "live".
- Malsy had been told (before the deploy ran) that he would hear back
  once deployment was verified; as of this log entry that result had not
  yet been reported to him.

## To finish the deployment (one browser step + one command) — DONE, see "Deployment VERIFIED LIVE" above
1. In a browser: open https://faucet.gno.land → choose **Onyx Faucet** → paste
   `g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h` → solve the hCaptcha → **Request Drip**
   (choose 300 GNOT). Tokens arrive in seconds.
2. Then run: `bash ~/workspace/gnome-tavern/scripts/deploy.sh` followed by
   `bash ~/workspace/gnome-tavern/scripts/verify.sh` and append their outputs here
   (tx hashes, qrender board, profiles, balances).

## Enablement — automatic approver queue (GPAS) — found 2026-11-23 ~14:13 WIB

- **Mechanism (sources: docs.gno.land + live chain state + GPAS):** Onyx runs
  `code_submission_policy=inert`. `MsgAddPackage` parks a package (charged
  only preprocess gas; storage deposit deferred to enable time) and it becomes
  callable only after the chain's `PkgApprovers` send `MsgEnablePackage`.
  The approver is the **GPAS service** — the Gno Package Approval Service at
  https://gpas.onyx.testnets.gno.land (aka gpas.latest.testnets.gno.land).
  Its own header: "automatic: Packages that pass the checks are enabled
  automatically." It runs review passes about every 10 minutes; a package
  that passes gets a verdict timestamp and an "enabling at" time exactly
  +1 hour after the verdict, then the approver enables it on-chain.
  Official docs (https://docs.gno.land/builders/getting-started/): "The
  testnet enables a new package a few seconds after addpkg; if call fails
  right after a deploy, wait and retry. https://gpas.latest.testnets.gno.land
  says why a package was refused: look yours up by its exact package path.
  If it still says the package is not known after a minute, ask on Discord."
  (The docs' "a few seconds" understates the observed delay: verdict +1h.)
- **No deployer action exists or is needed.** The deployer cannot self-enable
  (MsgEnablePackage is approver-only); there is no portal/form to submit and
  no govdao proposal to file. Discord is only the fallback if a package is
  refused or never appears. Nothing to request anywhere for our packages —
  both are in the automatic queue and both PASSED.
- **Observed timeline (UTC):**
  - tavernlogic: verdict 05:40:33Z → "enabling at 06:40:33Z" → LIVE by
    06:41 (qfile lists its files; `qinertpaths` for the p/ prefix empty;
    deployer charged a 2,122,400 ugnot storage deposit at enable:
    269,916,000 → 267,793,600 ugnot).
  - gnometavern: "in review queue" through passes 05:51 / 06:01 / 06:11 /
    06:21 / 06:31 (no verdict) → **verdict 06:40:42Z, "enabling at
    2026-11-23T07:40:42Z"** (first pass after its dependency tavernlogic went
    live — the realm's checks evidently need the dependency enabled).
  - Next: realm should read "live" shortly after 07:40:42Z; then re-run
    `scripts/verify.sh` in full. (Note: verify.sh will send patron another
    30 GNOT — patron already holds 30 from the first run; harmless, deployer
    balance is ample. The realm's own storage deposit, ~2.1M ugnot, will
    also land on the deployer at enable.)
- **verify.sh fix (script only, no game code changed):** the qrender call
  passed the bare realm path and the chain answered
  "expected <pkgpath>:<path>"; the `-data` argument is now `"$REALM_PATH:"`
  (trailing colon), matching the working manual qrender calls.

## Deployment VERIFIED LIVE — 2026-11-23 ~14:47 WIB (07:47 UTC)

- **Realm went live at 07:40:42Z** as GPAS promised: `qpkgmeta_json` for
  `gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern` reads
  `{"status":"live","creator":"g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h",
  "height":1344360,"max_deposit":"5000000ugnot"}`; `qinertpaths` empty;
  `qfile` lists gnometavern.gno / gnometavern_test.gno / gnomod.toml.
  Realm storage deposit charged at enable: 2,525,000 ugnot
  (deployer 267,793,600 → 265,268,600).
- **First post-live verify attempt (run 2) was interrupted by a runtime
  restart** mid-script: only its patron-funding send landed (balances
  proved it: deployer 235,266,600, patron 60,000,000; its tx hash was not
  captured — the log was in /tmp, which restarts wipe). GnomeCount stayed 0.
- **Run 2 (log: verify-run2.log), pre-gas-fix:** funding send landed
  (tx hash unrecovered — see above). Both `Register` calls
  failed OUT OF GAS in simulation (used 3,555,844 / 3,551,436 vs
  gas-wanted 3,000,000; chain suggested ~3,733,637) — no state changed, no
  fee charged. Every downstream call then failed with the realm's own guard
  "Gnome Tavern: no gnome registered for your address; call Register
  first" — itself proof the realm executes and enforces its rules.
  The qrender board DID render (day 673, 0 gnomes, quest board visible).
- **Fix (script only — NO game code changed, so no test re-run required):**
  `scripts/verify.sh` `call()` gas-wanted 3,000,000 → 5,000,000 and
  gas-fee 3000 → 6000ugnot. (The earlier qrender `-data "$REALM_PATH:"`
  fix from the enablement section still stands.)
- **Run 3 (log: verify-run3.log) — FULL PASS, all on-chain:**
  - Fund patron 30 GNOT: tx `jhwt+wjD301rn6eO5ruc93JnQ9OU5KM1J8KDHr3oJgY=`,
    height 1346544.
  - Register Bram (tavernkeeper, gnome #1): tx
    `ySpiNbDKkfoWnVYqeD3rSoQqy1dvCC/M9CKkvr+Mmy0=`, height 1346546,
    gas used 3,555,834, storage 2400 bytes.
  - Register Zed (patron, gnome #2): tx
    `F+HREfd45Z+3w7KILfd0oxZSdbimtiPziHZHJ6K8Gqc=`, height 1346548,
    gas used 3,803,241.
  - Bram serves 14× Gnomebrew Ale: all 14 OK; +5 coins/+3 XP each;
    **levelled up to Level 2 on the 14th serve** (70 coins, 42 XP).
  - ClaimQuest slot 0 "First Round": SUCCESS — +15 coins +8 XP
    (Bram 85 coins). Slot 1 "Whisky Business": correctly REFUSED
    (needs 3 Emberwhiskies, Bram served none). Slot 2 "Full House":
    SUCCESS — +55 coins +26 XP (Bram 140 coins).
  - Zed serves Barley Soup: +3 coins +2 XP. Zed PostNote
    "Save me a seat by the fire.": tx
    `/ARTaIbsAtu4L+1KRMuCyyLF4nwphkv/ZKyY7dCinBg=`, height 1346585.
    Bram PostNote "First round is on me!": tx
    `ZDyqtfgJPfswpbnR/GS3xNQwhJ2FmEJtlyrPK7jB8Yo=`, height 1346587.
  - **Read-backs (live state proven):** qrender board — "Tavern day 673 ·
    2 gnomes registered · 15 items served all time"; leaderboard
    Bram L2 / 76 XP / 140 coins / 14 serves, Zed L1 / 2 XP / 3 coins /
    1 serve; wall shows both notes with day 673. qeval
    Profile(tavernkeeper): "Bram — level 2, 76 XP, 140 coins,
    14 lifetime serves."
  - Balances after: deployer 174,830,900 ugnot; patron 119,676,200 ugnot
    (both reconcile exactly with sends + tx costs).
- **Deployment is DONE and verified live.** Remaining for the entry:
  demo video (per DEMO.md), GitHub publication, DoraHacks submission
  (Malsy's-account steps; deadline 18 Dec 2026 08:00 WIB).
  Live links: gnoweb
  https://latest.testnets.gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern
  · GPAS status https://gpas.onyx.testnets.gno.land/?path=gno.land/r/g17dvvky49vjqj6a4cjhwcvzctteqjm9stee000h/gnometavern

## Demo video — PRODUCED 2026-11-23 (~15:00 WIB)

- **File:** `~/workspace/gnome-tavern/gnome-tavern-demo.mp4` — MP4 (H.264,
  1280×720, 30 fps, yuv420p, faststart) + AAC narration, **151.0 s (2:31)**,
  2.84 MB. Narration: DEMO.md's lines spoken verbatim (one wording tweak:
  "2,000 blocks" spoken as "two thousand blocks") via edge-tts
  en-US-ChristopherNeural at −8% rate, PLUS the same lines burned in as
  captions. (The sandbox edge-tts venv needed its documented certifi patch
  re-applied after the VM replacement — done, see AGENTS.md.)
- **Capture method (deviation from DEMO.md's screen-recording plan, forced
  by the sandbox):** no browser/Chromium exists in this environment, so the
  video is composited with ffmpeg/PIL from REAL material only — browser
  frames are the realm's own rendered content extracted from the live
  gnoweb pages fetched over HTTPS from latest.testnets.gno.land (post-action
  state), typeset into a browser-chrome frame showing the real URL;
  terminal frames are typeset from real captured outputs (files in
  `demo-assets/`). Nothing is fabricated; framing annotations in terminal
  frames are marked `#`.
- **Fresh on-chain actions recorded for the video** (log:
  `demo-session.log`, tavern day 673, via the usual relay):
  - Bram Serve×3 Gnomebrew Ale — txs `nvJLHE7KKv9yiEN4gHdpMfwo4M35E1Fb/VQFRRCqABw=`
    (h 1346651), `lfyEuC1cOv44Y4brSCR8k7Y5PfitAUhxiBZlyNu/yc8=` (h 1346653 —
    **Bram levelled up to Level 3**, 82 XP), `NXl2SR+J0HOilJ/DH+drQDu96mpe+KwGbD9/xhXtjy4=`
    (h 1346655).
  - Bram Feast — tx `3zJtjtrC58MAh5d073gsx76hDaiNnScNx61FN2y5ihk=` (h 1346658).
  - Zed PostNote "Back again - the ale is still worth the walk." — tx
    `rjR0CJxVaTxObcR6HDsGZ5VIWjPEJP5+iOUF4jkjbVg=` (h 1346660).
  - Two refused calls (simulation only, nothing broadcast, no fee): a second
    Register → "Gnome Tavern: you already have a gnome"; Serve(5) →
    "Gnome Tavern: your level is too low for this item" (log:
    `demo-assets/refusals.log`).
  - State after: Bram L3 / 100 XP / 105 coins / 17 lifetime serves; Zed
    unchanged (L1). Balances reconcile exactly (deployer 174,806,900 ugnot;
    patron 119,610,200 ugnot).
- **Shot by shot:**
  1. (0:00–0:20) Tavern board — live gnoweb root page (post-action state:
     day 673, 18 serves all time, Bram L3 on the leaderboard, all 3 wall
     notes), slow scroll. Per script.
  2. (0:20–0:35) Code — terminal: repo listing + the verbatim menu ladder
     from `p/tavernlogic/tavernlogic.gno`, then the REAL `gno test -v ./...`
     output re-run today (12/12 PASS; the sandbox stdlib symlink had to be
     restored first — v1.8.0 tag, `/tmp/gno-ref`). Deviation: DEMO.md wanted
     the gnoweb Source tab; no browser renderer exists here, so the source
     is shown from the local tree (the deployed files are these files —
     deploy used them verbatim; `qfile` confirmed the on-chain file list).
  3. (0:35–0:55) Register — terminal transcript of the REAL registrations
     from verify run 3 (Bram tx `ySpiNbDK…`, Zed tx `F+HREfd4…`), then the
     fresh duplicate-Register refusal recorded today. Deviation (per
     DEMO.md's own pre-flight fallback): both addresses already hold
     gnomes, so the original registrations are shown from the run-3
     transcript and the uniqueness rule is demonstrated live instead.
  4. (0:55–1:25) Work a shift — the 3 fresh Serve txs above, incl. the
     on-camera level-up to 3, then the fresh Serve(5) level-gate refusal.
     Per script (DEMO.md's "show the level line" — we got a level-up).
  5. (1:25–1:50) Quest board — live gnoweb `:quests` page, then the run-3
     ClaimQuest transcript (First Round +15 coins/+8 XP and Full House
     +55 coins/+26 XP claimed; Whisky Business refused). Deviation (per
     DEMO.md's sanctioned fallback): today's board was already claimed in
     run 3 and the remaining quest needs L3 Emberwhiskies on a fresh day,
     so claims are narrated over the real transcript; the frame is labelled
     "verification run — tavern day 673".
  6. (1:50–2:15) Feast + wall — fresh Feast and PostNote txs (above), then
     live gnoweb `:wall` (all 3 notes incl. the new one) and Zed's live
     `:gnome/<patron>` card. Per script, except the on-camera note is a new
     text (the scripted line was already pinned in run 3 and is shown on
     the wall page).
  7. (2:15–2:31) Close — root page slow scroll (lower half), then end card
     with realm path + gnoweb URL. Deviation: no repo URL on the card —
     GitHub publication is still pending (Malsy's step); add it once live.
- **Remaining for the entry:** GitHub publication + DoraHacks submission
  (Malsy's-account steps; deadline 18 Dec 2026 08:00 WIB).
