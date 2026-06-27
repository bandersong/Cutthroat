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

## Iteration 8 — 2026-06-27 — Graphical options panel (v1.7.0)

**What:** A real settings panel in Interface → AddOns (`options.lua`) — checkboxes for all 10 toggles plus a scale slider, opened with `/cut config`. So the friend can click instead of memorizing slash commands. Read-only over SavedVariables.

**Why this over localization:** at a ship-ready milestone, a clickable settings panel is concrete value for an actual non-technical user; a localization scaffold for a 2-person enUS addon would be near-noise (heeded the recurring "don't add noise" warning).

**The risk was the API:** the options-panel API is version-specific — TBC Classic 2.5.x uses the legacy `InterfaceOptions_AddCategory` / `InterfaceOptionsFrame_OpenToCategory`; the modern `Settings.*` API is retail 10.0+. Built on the legacy API with a guarded `Settings.*` fallback, then had both models verify every call against 2.5.x. **Both confirmed all of it** (templates, sub-region names, the double-call open workaround, panel.name/refresh hooks).

**Fixes applied after review:**
1. Slider title is set in Init (was blank until you first dragged it) — GLM.
2. Dragging the scale slider now resizes the HUD live and cheaply (`hud.root:SetScale`) instead of firing a full module refresh on every step — Codex.
3. `NS.db` nil-guards in Init/Load and a tighter guard on the unused Settings fallback — both, defensive.

**Logged as smoke-test debt:** GLM and Codex disagreed on whether `OpenToCategory` lands on the right page with a frame vs a name argument in 2.5.x. The function accepts both and frame is standard (Codex-confirmed), so kept the frame — but added a smoke-test step with a ready one-line switch to `panel.name` if it misbehaves in-game.

---

## Iteration 7 — 2026-06-27 — Full cross-module audit + hardening (v1.6.1)

**What:** No new feature — a whole-addon integration audit (first review of all 7 files together) and the hardening it surfaced. Both GLM and Codex gave a ship-ready verdict.

**Why it mattered:** every prior review saw one file in isolation, so it couldn't catch *cross-module* issues. This pass found a different class of problem — architecture and shared-state hazards.

**Fixes applied:**
1. **cooldowns no longer runs a permanent per-frame loop.** It polled a "dirty" flag every frame forever; now a one-shot OnUpdate installs itself only when a spell/talent event fires, runs the rebuild next frame, and removes itself.
2. **timers render loop moved off the shared `hud.root`** onto its own private frame, so a future module putting an OnUpdate on root can't silently kill the timer/HUD updates.
3. **HUD stops making redundant C calls** — energy bar value/text and combo pip alpha are polled ~20×/s; now they only call the C-side setters when the value actually changed (kept the poll as a freshness safety net).
4. **SavedVariables sanitization** — validates `point` and `scale` on load and resets only if malformed, so a corrupted save can't break the HUD. (Validated by field index, not `#point`, because `point[2]` is intentionally nil.)
5. Removed dead `rnd` (Rend) tracking entry; fixed a stale init-order comment; added `/reload` double-init guards to every module.

**Rejected:** GLM's claim that the `wipe` global is hazardous (Codex didn't flag it; it's universal in 2.5.x), and GLM's force-reset of `point` on version bump (would wipe the user's saved HUD position).

**Confirmed by both + an independent bytecode check:** zero taint/secure-frame risk, zero leaked globals.

**Artifact:** merged in-client smoke-test checklist → `docs/SMOKE_TEST.md` (the addon is parse-clean and audited but still needs a human to verify in-game — tracked as verification debt).

---

## Iteration 6 — 2026-06-27 — Combo-point overcap glow (v1.6.0)

**What:** The combo-point pip row pulses gold when you're at max combo points (5), nudging you to spend them on a finisher instead of overcapping (building past 5 is wasted generation = lost DPS). `/cut finish` toggle. Read-only — it's a cue, not rotation advice.

**Triangulation:** the cleanest round so far — **Codex found zero correctness bugs; GLM found zero bugs plus two polish ideas.** Both independently confirmed every design choice (5 is the TBC cap, the API call, the BACKGROUND-behind-ARTWORK layering, the per-frame pulse cost) and both proactively warned against adding "is a finisher worth it" logic, since that would cross into rotation automation and break the read-only contract.

**Applied (polish):**
1. `SetBlendMode("ADD")` on the glow so it reads as a soft additive glow rather than a harsh opaque box (GLM).
2. Guard `UnitExists("target")` before reading combo points, so the glow can't linger after you drop target. Codex judged this unnecessary (no-target already returns 0 CP) but it's harmless and matches the addon's existing target-guard pattern.

**Dropped from roadmap:** "spec detection for talent-aware finisher durations" — low value, because the timer bars already display the real aura duration straight from the game, so talents like Improved SnD are reflected automatically.

---

## Iteration 5 — 2026-06-27 — Resource-aware refresh cue (v1.5.0)

**What:** The green "refresh-now" fill on the timer bars now only lights when you can actually act on it — SnD needs ≥25 energy; Rupture/Expose need ≥25 energy + ≥1 combo point + a live attackable target; Garrote never cues green (it's a stealth opener, not refreshable in combat). New `/cut smart` toggle (on by default) to disable the gating if you prefer pure-time green.

**Triangulation — the clearest win for the cross-check method so far.** GLM's review this round had **four false positives**, and Codex (the independent verifier) cleared every one while contributing the single real catch:
- GLM claimed *"TBC has pandemic, fix the comment"* — but it had **agreed the opposite in iteration 4**, and pandemic is a MoP-2012 mechanic absent from TBC Classic. Applying it would have written a factually wrong comment into the code.
- GLM claimed `RegisterUnitEvent` doesn't exist in 2.5.x and "silently breaks" the aura scanner — false (it's standard in Classic; a missing method would error, not silently fail; Codex flagged nothing).
- GLM wanted the `Enum.PowerType.Energy or 3` fallback hardcoded — Codex confirmed the fallback is already correct.
- GLM flagged a missing `markerDur` reset that iteration 4 already added.

The lesson: even a strong model drifts and contradicts itself across sessions. **Blindly applying one model's review would have degraded the code.** The independent second opinion is the safety net — this is why we triangulate rather than defer.

**Fixes applied (the real ones):**
1. **Garrote never green** under smart mode (Codex catch) — you can't refresh it in combat.
2. **Live-target guard** for Rupture/Expose before the combo-point check (both reviewers) — `UnitExists` + not `UnitIsDead` + `UnitCanAttack`.

**Confirmed correct by both:** 25-energy finisher cost (no TBC talent reduces it), `GetComboPoints("player","target")` signature, `>=1` gate, per-frame perf, dynamic green-on as energy ticks to 25, Expose-on-CP gating.

**Roadmap pruned:** "poison-type awareness" marked **infeasible** — `GetWeaponEnchantInfo` in 2.5.x returns no enchant ID, so the applied poison can't be identified (present/absent only).

---

## Iteration 4 — 2026-06-27 — Refresh-now marker on timer bars (v1.4.0)

**What:** Each SnD/Rupture/Expose/Garrote bar now shows a "refresh-now" marker at the point the shrinking fill crosses the warn threshold, plus the fill turns green in the final window. `/cut zone` toggle. Read-only.

**Roadmap correction (caught before building):** the roadmap had called this a "pandemic ~30% refresh window." TBC 2.5.x has **no pandemic** — refreshing a DoT/SnD early simply clips the remainder. Reframed the feature as "refresh just before expiry to keep uptime without wasting duration."

**Triangulation:** GLM + Codex. Notable: GLM **argued against itself** on the marker math (claimed it was inverted, then its own code comment conceded it was correct). I'd derived it independently — fill right-edge sits at `(rem/dur)·width`, so a marker at `(warnAt/dur)·width` from the left is exactly where the fill crosses `rem==warnAt` — and Codex confirmed. GLM's "anchor RIGHT with −mx" was rejected (would misplace it near the full end).

**Fixes applied:**
1. **Color state-machine** — was calling `SetStatusBarColor` ~20×/s/bar. Now `inZone` (label flash + entry sound) and `greenState` (fill color) only fire on transitions. Both reviewers flagged the churn.
2. **Restore base color when `/cut zone` is toggled off mid-window** — the `greenState` transition handles it (Codex catch).
3. **Marker repositioned only when the duration changes** (per new cast), not every frame.
4. **Marker centered on the threshold edge**; explicit `marker:Hide()` + state reset when the bar expires (hygiene).

**Deferred to roadmap:** both reviewers noted green = "refresh now" is only fully honest if the threshold is tight or gated on actually having the combo points / energy to refresh. Added a "resource-aware refresh cue" roadmap item; for now the marker is the precise informational cue and green = final window.

---

## Iteration 3 — 2026-06-27 — Energy regen-tick predictor (v1.3.0)

**What:** Shipped roadmap item 2 — a thin "spark" on the energy bar that sweeps left→right over the energy regen cycle and resets on each tick, so you can time energy pooling / pre-tick finishers. New `/cut spark` toggle. Read-only.

**Triangulation:** GLM + Codex. The interesting part was a **direct factual disagreement about how Adrenaline Rush works** — GLM said AR halves the tick interval (so a hardcoded 2.0s sweep would break), Codex said AR only changes energy-per-tick and leaves the 2.0s phase alone. I couldn't verify which is true without a live client, and `GetPowerRegen()` (GLM's proposed fix) may not exist in 2.5.x. **Resolution: stop assuming, start measuring** — the spark now self-calibrates its interval from the observed gap between real ticks (clamped 0.8–2.2s), which is correct no matter which AR model is right.

**Fixes applied:**
1. **Self-calibrating tick interval** (replaces hardcoded 2.0s) — measured from tick-to-tick gaps; robust to the unresolved AR mechanic.
2. **Proc filter** — only treat a `+≥10` energy delta as a tick, so Combat Potency / small refunds don't yank the spark back to 0. (GLM's `delta%20==0` was rejected: near-cap ticks add fewer than 20.)
3. **Spark clamp** — keep the full 2px marker inside the bar at both ends.
4. **Hardened `energyMax`** against a nil `UnitPowerMax`, and added an explicit first-sample early return.
5. **`ENERGY` power-type constant** factored to the top.

**Rejected:** GLM's claim that `OnDragStop` loses the anchor and `root.bg` is unassigned — verified false in-file (assignment present; storing nil relativeTo is intentional and position is preserved via UIParent + x,y).

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
