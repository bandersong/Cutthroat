# Cutthroat — Decision Log

Plain-language record of *what changed and why*. Newest first. Every iteration of the triangulation loop appends here. This is the synthesis layer — not a transcript dump. Raw reviews live in `reviews/glm/` and `reviews/codex/`; the diff/judgment lives in `docs/TRIANGULATION.md`.

## How this project is built

This addon is hardened by a recurring **triangulation loop**:
1. Snapshot current code → send the *same scoped review prompt* to **GLM** (`glm-ask`) and **Codex** (`codex exec`) independently.
2. Diff their findings in `docs/TRIANGULATION.md`. Agreement ≠ correctness (shared training biases) — each claim is checked against the real WoW 2.5.x API before acting.
3. Apply only **high-confidence, verified** fixes. Log each here with before/after.
4. Commit + push to `main`. (No PRs — solo repo.)

Success criteria for the addon: loads clean on a TBC Anniversary client, zero Lua errors, no FPS regression from OnUpdate loops, and **provably no spell-input automation** (Warden-safe).

---

## Iteration 2 — 2026-06-27 — CD tracker row (v1.2.0)

**What:** Shipped roadmap item 1 — `cooldowns.lua`, a read-only row of cooldown icons (with sweep timers + desaturation) for rogue defensives/utility: Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation. Icons appear **only for spells you actually know**, so spec-specific talents (Cold Blood, AR/Blade Flurry, Preparation) auto-hide for the wrong build. Still read-only — no casting.

**Triangulation:** GLM (5) + Codex (5), Codex web-verified its API claims. Full table in `docs/TRIANGULATION.md`. Net: **6 fixes applied, 2 rejected.**

**Fixes applied:**
1. **Removed `PLAYER_TALENT_UPDATE` registration.** That event doesn't exist in TBC 2.5.x and `RegisterEvent` on an unknown event hard-errors — it would have broken the whole module on load. Caught by GLM, Codex, *and* my own pre-review pass. `CHARACTER_POINTS_CHANGED` + `SPELLS_CHANGED` cover respec/learning.
2. **Rewrote the known-spell test.** Was `GetSpellCooldown(name) ~= nil`, which doesn't reliably return nil for unlearned spells in 2.5.x → every talent icon would show regardless of spec. Now scans the spellbook by name (`GetSpellName(i, BOOKTYPE_SPELL)`), caches the set, and rebuilds it on spell/talent change.
3. **Fixed vertical overlap.** Icon row was clipping the bottom timer bar by ~4px; dropped the anchor to `timerBottom − 8 − ICON/2`. (Codex's pixel math.)
4. **GCD filter `>1.5` → `>2`** so the ~1s global cooldown never briefly sweeps the icons.
5. **Throttled `SPELLS_CHANGED`** (fires aggressively in TBC) by coalescing layout rebuilds to one-per-frame via a dirty flag.
6. **Deleted a dead `SpellName` helper** left from a half-refactor.

**Rejected (with reasons):** GLM's "horizontal centering off by GAP/2" — verified false by algebra *and* Codex; the proposed fix was identical to the existing code. GLM's `cd:Hide()` on clear — would suppress the next cooldown's sweep.

---

## Iteration 1 — 2026-06-27 — Repo + first triangulated review

**What:** Created the GitHub repo, doc system, and ran the first GLM+Codex review pass on the v1.0.0 scaffold.

**Pre-existing fixes already in v1.0.0 (from scaffold review):**
- `GetWeaponEnchantInfo` — corrected to TBC signature (off-hand = return 4, not 5; no `enchantID` arg in 2.5.x).
- Removed dead `MakeBar` stub (invalid `StatusFrame` frame type).
- `C_UnitAuras` → `UnitAura` fallback so aura reads work on the 2.5.x client.

**Triangulation result:** GLM (6 findings) and Codex (11 findings) overlapped on only 2 — neither was a superset. Full diff in `docs/TRIANGULATION.md`. Applied **12 verified fixes**, bumped to **v1.1.0**. All 5 Lua files parse clean (`luac -p`).

**Fixes applied (v1.1.0):**
1. **timers: aura filter** `"HARMFUL|PLAYER"` (pipe) → `"HARMFUL PLAYER"` / `"HELPFUL"` (space). *Why:* WoW aura filters are space-separated; the pipe made every filter invalid, so **no timer bar ever showed**. GLM-only catch, highest impact.
2. **core: explicit init order.** `pairs(NS.modules)` was nondeterministic; timers/alerts anchor to `hud.root`, so a bad order = load-time Lua error. Now: config → hud → timers → alerts. Codex-only catch.
3. **core: rogue-gate the HUD.** Non-rogues printed "HUD disabled" but still built every frame. Now hud/timers/alerts only init for rogues; `/cut` still works for all.
4. **hud: drop unfiltered `UNIT_POWER_UPDATE`.** Every unit's power change was waking the player HUD. `UNIT_POWER_FREQUENT` is already filtered to player.
5. **timers: event-driven aura cache.** Was scanning ~160 `UnitAura` calls every 0.1s. Now re-scans only on `UNIT_AURA`/target-change; OnUpdate just renders cached countdowns. Kills the FPS risk GLM flagged.
6. **timers: bar uses real aura `duration`** (already returned by GetAura) instead of a `maxSeen` high-water mark that made refreshed-shorter auras render as a stuck sliver. Took Codex's cleaner fix over GLM's prevRem heuristic.
7. **timers: `OnHide` set once** at bar creation, not re-created every tick (GC churn).
8. **alerts: Kick usability.** `SpellReady` now checks `IsUsableSpell` + cooldown `enabled` so it won't scream KICK when you're energy-starved.
9. **alerts: poison check pre-pull.** Added `PLAYER_ENTERING_WORLD` + `UNIT_INVENTORY_CHANGED` (out-of-combat guarded) so a missing poison is caught on login and after swaps, not only after leaving combat.
10. **alerts: live toggles.** `Alerts:Refresh` re-evaluates poison + opener so `/cut poison`/`/cut opener` hide an already-visible warning.
11. **core: `GetAddOnMetadata`** global preferred over the newer `C_AddOns.` wrapper (2.5.x has the global) so the version string is real.
12. **alerts/config: stealth opener toggle.** New `openerHint` setting + `/cut opener`.

**Deferred (disagreement — verify in-client):** GLM and Codex named *different* combo-point events (`UNIT_POWER_UPDATE` vs `UNIT_COMBO_POINTS`). Registering a wrong event name errors in WoW, so CP is now **polled in the render tick** — correct regardless of build. Confirm the real event later and switch to event-driven if cheaper.

**Independently confirmed safe by both:** `GetWeaponEnchantInfo` positions correct; zero spell-input automation (no CastSpell/UseAction/RunMacro/secure-button). Warden-safe holds.
