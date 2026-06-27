# Triangulation Log — GLM vs Codex

Each iteration sends the **same** scoped review prompt to GLM and Codex, then diffs the outputs. The point is the **disagreements**: where one finds a bug the other missed, or they contradict each other, that's where the real signal (or the hallucination) is. Convergence is logged but never trusted on its own — every accepted finding is verified against the WoW 2.5.x API.

Legend: ✅ accepted (verified real) · ❌ rejected (false/hallucinated) · ⏳ needs in-client test · 🔁 deferred to roadmap

---

## Iteration 6 — 2026-06-27 — Combo-point overcap glow (v1.6.0)

Pip row pulses gold at max CP so you finish instead of overcapping. **Cleanest round yet — Codex found zero correctness bugs; GLM found zero bugs + two polish suggestions.** Convergence on quality. Raw: `reviews/glm/iter6.md`, `reviews/codex/iter6.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | Solid `SetColorTexture` flashes as a harsh box → `SetBlendMode("ADD")` for a soft glow | ✅ | — | ✅ **applied** | GLM-unique aesthetic; valid 2.5.x method, Codex neutral. Low-risk polish. |
| 2 | Target-drop could leave the glow lingering → guard `UnitExists("target")` | ✅ "ghosts" | ❌ "already hides" | ✅ **applied (defensive)** | **Disagreement.** Codex says no-target → `GetComboPoints`=0 so it already hides (ground-truth-correct). The guard is harmless either way and matches the addon's existing target-guard pattern → added for clarity, not blind deference. |
| N1 | MAX_CP=5 correct; GetComboPoints sig; BACKGROUND<ARTWORK layering; math.sin/GetTime; event+render idempotent; cp>=5 UX | ✅ | ✅ | ✅ no-op | Both independently confirmed every design choice. Both explicitly warned: don't add "is a finisher worth it" logic — that's rotation automation, violates read-only. |

**Lesson:** as the codebase matures, reviews converge toward "no bugs, minor polish" — the signal that the triangulation loop is reaching diminishing returns on this surface. The one disagreement (#2) was resolved by recognizing the fix is safe under *both* interpretations, so correctness doesn't hinge on settling it. Also: both models proactively guarded the read-only boundary (no rotation logic), which is the addon's core safety invariant.

---

## Iteration 5 — 2026-06-27 — Resource-aware refresh cue (v1.5.0)

The green "refresh-now" fill now only lights when you can actually refresh (CP/energy/live target). `/cut smart` toggle. **This round is the strongest case yet for triangulation: GLM produced 4 false positives, Codex cleared them and added the one real catch.** Raw: `reviews/glm/iter5.md`, `reviews/codex/iter5.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | Garrote returns `true` → green implies "refreshable" when it isn't (stealth-only in combat) | — | ✅ | ✅ **applied** | Codex-only real catch. Garrote now never cues green. |
| 2 | Rup/Exp CP gate needs a live attackable target guard | ✅ | ✅ | ✅ **applied** | Convergent. Added `UnitExists/UnitIsDead/UnitCanAttack` before the CP check. |
| 3 | **"TBC HAS pandemic, fix the comment"** | ✅ | — | ❌ **rejected** | **GLM contradicts its own iteration 4** (where it agreed TBC has none). Ground truth: pandemic = MoP 5.0 (2012); TBC Classic has none. False. |
| 4 | **`RegisterUnitEvent` doesn't exist in 2.5.x, silently breaks UNIT_AURA** | ✅ | — | ❌ **rejected** | Scary if true (3 files use it). But Codex reviewed timers.lua and flagged nothing; never flagged it in iters 1–2 either. RegisterUnitEvent is standard in Classic/TBC-Classic. GLM's own mechanism is self-inconsistent ("silently fails" — a nil method *errors*). False. |
| 5 | `Enum.PowerType.Energy` nil → must hardcode 3 | ✅ | ❌ "correct as-is" | ❌ **rejected** | The `or 3` fallback already handles it; Codex (#3) explicitly blessed it. No-op. |
| 6 | `markerDur` not reset on expiry (only OnHide) | ✅ | — | ❌ **already done** | iter-4 code already resets it in the expiry branch (timers.lua:146). GLM missed the existing line. |
| N1 | Energy cost 25, GetComboPoints sig, `>=1` gate, perf, dynamic green-on, Expose gating | ✅ confirm | ✅ confirm | ✅ no-op | Both independently confirmed everything I got right. |

**Lesson (the big one):** had I blindly applied GLM's review this round, I'd have (a) injected a *factually wrong* "TBC has pandemic" comment into the code, (b) possibly rewritten working `RegisterUnitEvent` calls, and (c) added a fragile speculative energy-predictor. **Codex as the independent verifier caught GLM's drift on every count.** This is exactly why the golden rule is "triangulate, do not blindly defer" — a single model, even a strong one, drifts and contradicts itself across sessions. The cross-check is the safety net.

Also: pre-build red-team killed the "poison-type awareness" roadmap item — `GetWeaponEnchantInfo` in 2.5.x exposes no enchant ID, so the applied poison can't be named. Marked infeasible.

---

## Iteration 4 — 2026-06-27 — Refresh-now marker on timer bars (v1.4.0)

Added a "refresh-now" marker + final-window green on the SnD/DoT bars. **Pre-build red-team caught my own roadmap error**: it said "pandemic ~30%", but TBC 2.5.x has no pandemic — early refresh clips. Reframed as refresh-before-expiry. GLM 6 findings, Codex 6. Raw: `reviews/glm/iter4.md`, `reviews/codex/iter4.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | **Marker position math** | "inverted, anchor RIGHT w/ −mx" | "correct as-is" | ❌ **GLM rejected** | **GLM contradicted *itself* mid-finding** (argued inverted, then the code comment admitted "the math is ALREADY correct"). Codex + my own derivation confirm: fill right-edge = `(rem/dur)*BAR_W`, so marker at `(warnAt/dur)*BAR_W` from LEFT is exactly right. GLM's RIGHT/−mx would put it near the *full* end — wrong. |
| 2 | Color set every render (~20×/s/bar) → churn | ✅ | ✅ | ✅ **applied** | Both. Converted to a transition state-machine (`inZone` for label+sound, `greenState` for fill); colors only change on transition. |
| 3 | `refreshZone` off while green → base color never restored | (implied) | ✅ | ✅ **applied** | Codex explicit; the `greenState` machine restores base on the toggle transition. |
| 4 | Marker reposition every frame | ✅ (#3a) | — | ✅ **applied** | Reposition only when `dur` changes (per cast), tracked via `b.markerDur`. |
| 5 | Stale marker on hidden bar | ✅ "won't hide" | ❌ "child texture, hides w/ parent" | ⚖️ **Codex right** | Marker is a child texture → hides with parent; GLM's worry unfounded. Added `marker:Hide()` + state reset in the expiry branch anyway as cheap hygiene. |
| 6 | UX: green="refresh now" only honest if `warnAt` is tight (TBC clips) | ✅ (gate on CP/energy) | ✅ ("final window" semantics) | 🔁 **roadmapped** | Both flag it. Kept the marker as the always-correct informational cue; green = final window. Resource-aware gating (only green if you *can* refresh) → new roadmap item. |

**Lesson:** two contradictions again — and this time **one model argued against itself** (#1). The discipline of deriving the math independently (not trusting either model's confidence) is what caught it. Also: the most valuable catch wasn't from either review — it was the *pre-build* red-team of my own roadmap's false "pandemic" premise.

---

## Iteration 3 — 2026-06-27 — Energy regen-tick predictor (hud.lua spark)

Shipped roadmap item 2: a thin spark on the energy bar sweeping 0→100% over the energy regen cycle, to help energy-pooling. GLM 9 points (4 bugs + 5 confirmations), Codex 8 (3 bugs + 5 confirm/optional). → v1.3.0. Raw: `reviews/glm/iter3.md`, `reviews/codex/iter3.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | **Adrenaline Rush: does it change tick *interval* or per-tick *amount*?** | "interval → 1s, hardcode breaks" | "phase unchanged, only amount" | ⚖️ **sidestepped** | **Direct factual contradiction on TBC mechanics.** Instead of betting, I now *measure* the tick cadence from gap-to-gap (clamped 0.8–2.2s) and sweep on the measured interval — correct under either model. GLM's `GetPowerRegen()` fix also risks not existing in 2.5.x. |
| 2 | Any positive energy delta resets the spark → false-sync on Relentless Strikes / Thistle Tea / Combat Potency procs | ✅ | ✅ | ✅ **applied** | Both caught it. Filter: only resync on `delta >= 10` (ignores small procs). GLM's `delta%20==0` was rejected — near-cap ticks add <20, would miss them. |
| 3 | 2px spark clips past the bar ends at frac 0/1 | ✅ | ✅ | ✅ **applied** | Clamp `x` to `[0, width − sparkWidth]`. |
| 4 | `energyMax` not hardened if `UnitPowerMax` returns nil | — | ✅ | ✅ **applied** | `(m and m>0) and m or 100`. |
| 5 | First-sample should return early for clarity/safety | — | ✅ | ✅ **applied** | `if self.lastEnergy == nil then ...; return end`. |
| 6 | Factor `Enum.PowerType.Energy or 3` into one constant | — | ✅ (optional) | ✅ **applied** | `local ENERGY` at top. |
| 7 | OnDragStop stores nil relativeTo + `root.bg` missing → anchor resets | ✅ | — | ❌ **rejected** | **False positive.** Verified in-file: `root.bg` assignment exists (hud.lua:31); storing nil is deliberate — re-anchors to UIParent with preserved x,y (hud.lua:18). Position is retained. |
| N1 | 2.0s base interval correct; nil-safety good; 0.05s poll perf fine; cap-hide good; Enum fallback fine | ✅ | ✅ | ✅ no-op | Both independently confirmed the parts I got right. |

**Lesson:** iteration 1 had convergence on the big bug; iteration 2 had one contradiction; **iteration 3's headline is a contradiction on game mechanics neither model could settle.** The right move wasn't to pick a winner — it was to redesign so the answer doesn't matter (measure, don't assume). Triangulation's value here was *surfacing* that the assumption was load-bearing and unverified.

---

## Iteration 2 — 2026-06-27 — CD tracker row (cooldowns.lua)

Shipped roadmap item 1: a read-only cooldown-icon row (Vanish/Evasion/Sprint/Blade Flurry/Adrenaline Rush/Cold Blood/Preparation), icons only for spells you know. GLM gave 5 findings, Codex 5. **Codex web-verified its API claims** against warcraft.wiki. Raw: `reviews/glm/iter2.md`, `reviews/codex/iter2.md`. → v1.2.0.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | `RegisterEvent("PLAYER_TALENT_UPDATE")` hard-errors — event doesn't exist in 2.5.x → breaks module load | ✅ | ✅ | ✅ **applied** | Triple-confirmed (both + my own pre-review red-team). Removed; `CHARACTER_POINTS_CHANGED` + `SPELLS_CHANGED` cover respec/learn. |
| 2 | `IsKnown` via `GetSpellCooldown(name) ~= nil` is unreliable → talent icons show for wrong specs | ✅ | ✅ | ✅ **applied** | Both prescribe the same fix: scan spellbook by name (`GetSpellName(i, BOOKTYPE_SPELL)`), cache it, rebuild on change. My original comment's premise was just wrong. |
| 3 | Horizontal centering off by GAP/2 | ✅ | ❌ "correct" | ❌ **rejected** | **Disagreement.** I verified the algebra: last icon center lands exactly at `+totalW/2 − ICON/2`, symmetric. GLM's "fix" is identical to the existing code. 2-of-3 + proof → reject. |
| 4 | Vertical anchor overlaps the bottom timer bar by ~4px | — | ✅ | ✅ **applied** | Codex-only, with the pixel math. Dropped `rowY` to `timerBottom − 8 − ICON/2` (−144). GLM said horizontal was wrong but missed the real vertical bug — union covers both axes. |
| 5 | `dur > 1.5` GCD filter is borderline | — | ✅ | ✅ **applied** | Bumped to `dur > 2` (all tracked CDs ≫ 2s; adds latency margin). |
| 6 | Dead `SpellName` helper (half-refactored) | — | ✅ | ✅ **applied** | Deleted. |
| 7 | `SPELLS_CHANGED` fires aggressively → relayout micro-stutter | ✅ | ❌ "perf fine" | ✅ **applied (light)** | **Disagreement.** GLM flags it, Codex says fine. Cheap insurance: coalesce layout-affecting events into one rebuild/frame via a dirty-flag. Adopted GLM's idea, lighter impl. |
| 8 | `cd:Hide()` on clear to kill 1-frame flash | ✅ | — | ❌ **rejected** | Would suppress the *next* cooldown's sweep (hidden frame won't re-show without a Show()); `Clear()` already handles it. |
| N1 | Ban-safety + init order + spell IDs + CooldownFrameTemplate usage | — | ✅ confirmed | ✅ no-op | Codex independently verified: read-only, hud-before-cooldowns init, all 7 spell IDs correct. |

**Lesson reinforced:** the two *direct contradictions* this round (#3 horizontal, #7 perf) are where triangulation earns its keep — resolved one by independent proof, one by "cheap insurance wins." And the highest-impact bug (#1) was caught by all three independent passes, which is the convergence signal you actually want.

## Iteration 1 — 2026-06-27

GLM gave 6 findings, Codex gave 11. **Neither was a superset of the other** — the headline result of this loop. Raw reviews: `reviews/glm/iter1.md`, `reviews/codex/iter1.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | Aura filter `"HARMFUL\|PLAYER"` uses pipe, not space → filter invalid → **timers never render** | ✅ | — | ✅ **applied** | GLM-only. The single highest-impact bug; whole timer module was dead. Fixed to space-separated `"HARMFUL PLAYER"` / `"HELPFUL"`. |
| 2 | Module init order via `pairs()` nondeterministic → timers/alerts may init before `hud.root` → Lua error | — | ✅ | ✅ **applied** | Codex-only. Real crash risk. core.lua now inits in explicit order (config, hud, timers, alerts). |
| 3 | Non-rogues still init full HUD despite "disabled" message | — | ✅ | ✅ **applied** | core.lua gates hud/timers/alerts behind `playerClass == "ROGUE"`. |
| 4 | `UNIT_POWER_UPDATE` registered globally (unfiltered) → every unit wakes handler | — | ✅ | ✅ **applied** | Removed the redundant global reg; `UNIT_POWER_FREQUENT` is already unit-filtered to player. |
| 5 | Perf: OnUpdate scans ~160 `UnitAura` calls / 0.1s | ⚠️ (Lua-cap warning) | ✅ | ✅ **applied** | Refactored to UNIT_AURA-driven cache; OnUpdate now only renders cached countdowns (0 scans/frame). |
| 6 | `maxSeen` makes the bar lie when an aura is refreshed shorter | ✅ | ✅ | ✅ **applied (Codex fix)** | Both found it. Codex's fix (use the real `duration` already returned by GetAura) is cleaner than GLM's prevRem heuristic → took Codex's. |
| 7 | `OnHide` closure re-created every tick (GC churn) | — | ✅ | ✅ **applied** | Set once at bar creation. |
| 8 | Kick alerts even when unusable (not enough energy) | — | ✅ | ✅ **applied** | SpellReady now checks `IsUsableSpell` + cooldown `enabled`. |
| 9 | Poison check only runs on leaving combat → missing pre-pull / on login | ✅ | ✅ | ✅ **applied** | Added `PLAYER_ENTERING_WORLD` + `UNIT_INVENTORY_CHANGED`; guarded out-of-combat. |
| 10 | Toggling `/cut poison` off doesn't hide a visible warning | — | ✅ | ✅ **applied** | Alerts:Refresh now re-evaluates poison + opener. |
| 11 | `C_AddOns.GetAddOnMetadata` is newer API; 2.5.x has global `GetAddOnMetadata` | — | ✅ | ✅ **applied** | Prefer the global, fall back to C_AddOns. |
| 12 | Stealth opener hint not toggleable / can mislead | ✅ | — | ✅ **applied** | GLM-only. Added `openerHint` config + `/cut opener`. |
| D1 | **Combo-point event name** | `UNIT_POWER_UPDATE` | `UNIT_COMBO_POINTS` | ⏳ sidestepped | **Disagreement = signal.** Registering a wrong event name errors in WoW, so instead of betting on either, CP is polled in the render tick (build-independent). Verify true event name in-client later. |
| N1 | `GetWeaponEnchantInfo` off-hand position | — | ✅ confirmed correct | ✅ no-op | Codex independently verified the v1.0.0 fix. |
| N2 | Ban-safety (no CastSpell/UseAction/RunMacro/secure-button) | ✅ clean | ✅ clean | ✅ no-op | Both confirm: alerts/HUD only. |

**Lesson:** running both was worth it. GLM alone would have shipped a build that still crashes on init-order and burns CPU; Codex alone would have shipped a build whose timers never appear (missed the pipe filter). The union is the value.
