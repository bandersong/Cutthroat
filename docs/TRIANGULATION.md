# Triangulation Log — GLM vs Codex

Each iteration sends the **same** scoped review prompt to GLM and Codex, then diffs the outputs. The point is the **disagreements**: where one finds a bug the other missed, or they contradict each other, that's where the real signal (or the hallucination) is. Convergence is logged but never trusted on its own — every accepted finding is verified against the WoW 2.5.x API.

Legend: ✅ accepted (verified real) · ❌ rejected (false/hallucinated) · ⏳ needs in-client test · 🔁 deferred to roadmap

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
