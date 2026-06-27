# Triangulation Log — GLM vs Codex

Each iteration sends the **same** scoped review prompt to GLM and Codex, then diffs the outputs. The point is the **disagreements**: where one finds a bug the other missed, or they contradict each other, that's where the real signal (or the hallucination) is. Convergence is logged but never trusted on its own — every accepted finding is verified against the WoW 2.5.x API.

Legend: ✅ accepted (verified real) · ❌ rejected (false/hallucinated) · ⏳ needs in-client test · 🔁 deferred to roadmap

---

## Iteration 12 — 2026-06-27 — Convergence audit → caught a real non-enUS bug (v1.7.1)

A skeptical, anti-gold-plating ship-readiness audit ("say NO REAL ISSUES if there's nothing — don't manufacture work"). The two models **split**, and that split was the whole value:

| | verdict |
|---|---|
| **GLM** | "NO REAL ISSUES — SHIP IT." Praised the architecture, ban-safety, all prior fixes. Missed the bug below. |
| **Codex** | "ONE REAL CORRECTNESS ISSUE." `timers.lua` hardcoded **English** aura names and compared them to `UnitAura` results, which are **localized** → on deDE/frFR/etc. the core timers silently never fire. |

**Verified + fixed (Codex right):** the bug is real and `cooldowns.lua` *already* resolved names locale-safely via `GetSpellInfo`, so timers were the inconsistent module. Switched TRACK to spellID + `GetSpellInfo`-resolved localized name (fallback enUS). Added a localization regression test (simulated German "Säbelrasseln" SnD → detected). 115 → **124 checks**, green on CI/5.1.

**Lesson — the single best argument for the whole loop:** had I trusted GLM's confident "ship it," a public addon would have shipped broken for every non-English player. One model's confidence is not ground truth; the independent skeptic caught what the optimist missed. This is *exactly* "🔍 convenient = bug till proven" and "🤖 triangulate, do not blindly defer." Convergence wasn't reached — and that's more useful than a false convergence would have been.

---

## Iteration 11 — 2026-06-27 — Deep regression coverage (93 → 115 checks)

Added behavioral + negative regression tests that lock the logic past iterations fixed, then triangulated for *coverage gaps*. GLM and Codex independently named the **same top 3** (aura filter, real-duration scaling, tick calibration) — Codex more precise (and it knew `maxSeen` was already removed; GLM's #3 assert referenced the dead variable). Raw: `reviews/glm/iter11.md`, `reviews/codex/iter11.md`.

| Behavior locked (was untested) | source | how |
|---|---|---|
| **Aura filter** HELPFUL vs HARMFUL PLAYER (the iter-1 #1 bug) | both #1 | mock made filter-aware + **rejects pipe filters** so the old `HARMFUL\|PLAYER` regresses to a test failure; asserts our SnD/Rupture found, target-cast Rupture ignored |
| **Real-duration bar scaling + marker math** | both #2 | record SetMinMaxValues/SetPoint; bar max = real dur (16→8 on refresh, no stale scaling); marker at `warnAt/dur*BAR_W` (25→50) |
| **Self-calibrating tick interval** | both #3 | two consecutive ticks → interval adapts (1.0s then 2.0s); +5 proc ignored |
| **Cooldown one-shot OnUpdate self-cleanup** | both (bonus) | OnUpdate installed+dirty after SPELLS_CHANGED; nil+clean after flush |
| **/reload double-init idempotency** | (my brainstorm) | re-Init() errors none, creates no new frames, keeps same root |
| Kick non-interruptible & unusable gating; smart-refresh CP gating; poison-clear; opener visibility; spark-at-cap | (my brainstorm) | negative asserts with flags reset to defaults |

**Rejected:** GLM's `maxSeen` clamp test — stale (variable removed in iter 1/2); used the live "bar max == real duration" assertion instead.

**Self-caught (red-team of my own tests):** 3 test bugs surfaced and were fixed (asserted `_desat` on the frame not its texture; expected a hidden icon to be `nil`; missing an *establishing* tick before measuring the calibration gap) — none were addon bugs. The harness being strict enough to fail my own wrong assertions is the value.

**Lesson:** with the addon mature, the loop's leverage shifts from finding bugs to *preventing regressions* — converting every hard-won fix into an executable guard. Test-gap mining is a great triangulation use: two models converging on the same untested behaviors is high signal about where the real risk sits.

---

## Iteration 10 — 2026-06-27 — Headless test harness + CI (execution ground truth)

The loop's real weakness: 9 rounds of parse-check + LLM opinion, but the addon had **never executed**. Built `test/run.lua` — stubs the WoW API, loads all modules, runs lifecycle/gameplay/slash/edge paths, asserts behavior. First run: 42/10. The 10 failures traced to **one missing mock global** (`GetInventoryItemLink`, a real 2.5.x API the addon correctly uses) — i.e., the harness *worked*, surfacing a real dependency. After the stub: 52/0, then both models adversarially reviewed the harness itself. Raw: `reviews/glm/iter10.md`, `reviews/codex/iter10.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | No-op `__index` masks bad API calls + (my realization) returns a truthy fn for unset data fields, corrupting boolean logic | ✅ | ✅ | ✅ **applied** | Both ranked #1. Rewrote the mock as a **method table**: known methods resolve, unknown keys → nil (typo'd method calls now error; unset data fields read nil correctly). |
| 2 | No event-name validation | ✅ | (implied) | ✅ **applied** | Added a 2.5.x event allowlist; `RegisterEvent` errors on an unknown event — auto-regression for the iter-2 `PLAYER_TALENT_UPDATE` bug class. |
| 3 | Lua 5.1 vs 5.5 host → green-here ≠ works-in-WoW | ✅ | ✅ | ✅ **applied** | Can't run 5.1 locally, so the **CI runs on real `lua5.1`** — resolves the fidelity gap automatically on every push. |
| 4 | State contamination between scenarios (shared frames/globals/DB) | — | ✅ | ✅ **applied** | Codex-only. Added `resetWorld()`; split into 3 isolated scenarios (rogue / corrupt-DB / non-rogue). |
| 5 | Tautological "no-error" asserts; want behavioral + negative cases | ✅ | ✅ | ✅ **applied** | Added: db-mutation-after-slash, poison text content, cooldown desaturation, corrupt-SavedVariables sanitization, non-rogue gating. |
| 6 | Strict `_G` read-error on any unmocked global | ✅ | — | ❌ **rejected** | Would break the addon's *legitimate* optional-global probing (`Enum and …`, `C_UnitAuras and …`). Wrong for this code. |
| N1 | Honestly relabel "execution ground truth" → smoke/regression | ✅ | ✅ | ✅ **applied** | Both. Docstring now states exactly what it does and does NOT prove. |

**Self-caught (red-team of my own tests):** after hardening, 2 asserts failed — both were *my test bugs* (asserted `_desat` on the icon frame instead of its texture; expected a hidden icon to be `nil` instead of created-but-hidden), not addon bugs. Fixed → **83/0**. The harness being strict enough to catch wrong assertions is the point.

**Lesson — the most important of the whole loop:** GLM kept warning "upward without grounding = confident bullshit," and it was right. Nine iterations of two models agreeing on Lua they never ran is exactly the echo chamber. This iteration re-anchors the loop to **execution** (and CI on the real runtime). From here, "ship-ready" means *tests pass on Lua 5.1*, not *two models think it looks fine*.

---

## Iteration 9 — 2026-06-27 — Docs brought current + accuracy-checked (v1.7.0)

No code change — rewrote the stale README (was frozen at v1.0.0, missing 8 versions of features) and added `CHANGELOG.md`, then used the loop to **verify the docs against the actual code** (doc-vs-code drift is a real bug class). Raw: `reviews/glm/iter9.md`, `reviews/codex/iter9.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | README says "Bars flash" but code only recolors the **label** + sound | — | ✅ | ✅ **applied** | Codex-only, precise. Reworded to "label turns red + sound." |
| 2 | "green when CP + energy" is imprecise (SnD is energy-only) | — | ✅ | ✅ **applied** | Codex-only. Reworded to the exact per-aura rule. |
| 3 | `/cut options` alias undocumented | ✅ | ✅ | ✅ **applied** | Both. Noted as alias of `/cut config`. |
| 4 | `/cutthroat` slash alias undocumented | — | ✅ | ✅ **applied** | Codex-only. Added a note. |
| 5 | "kick/poison/opener missing from README table AND Help()" | ✅ | — | ❌ **rejected (false)** | Verified directly: README table has all three; `Help()` prints all three. GLM was simply wrong. |
| 6 | "RunScript may leak via InterfaceOptions XML templates" | ✅ | — | ❌ **rejected (false FUD)** | Speculation ("while not explicitly listed in the snippets…"). Grepped all lua: zero banned functions. |

**Lesson:** Codex clearly outperformed GLM on this factual-accuracy pass — 4 precise, code-grounded catches vs GLM's 1 real + 2 false positives (one a verifiable wrong claim, one evidence-free FUD). Reinforces the pattern across the whole loop: GLM is a useful idea generator but drifts/hallucinates on specifics, so **every GLM finding gets verified against ground truth before action** — which is exactly the "triangulate, don't blindly defer" rule. A built install zip (`~/WoWAddons/Cutthroat.zip`) now bundles the addon + user docs, excluding internal review/prompt artifacts.

---

## Iteration 8 — 2026-06-27 — Graphical options panel (v1.7.0)

Added `options.lua` — an Interface → AddOns panel (checkboxes + scale slider) so the non-technical end user isn't stuck memorizing 9 slash toggles. The whole point was verifying the **version-specific options API** (legacy `InterfaceOptions_*` for 2.5.x, NOT the retail `Settings.*`). Raw: `reviews/glm/iter8.md`, `reviews/codex/iter8.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | All 8 of my 2.5.x API assumptions (AddCategory, OpenToCategory+double-call, UICheckButtonTemplate label `_G[..Text]`, OptionsSliderTemplate sub-regions, SetObeyStepOnDrag guard, panel.name/refresh, non-rogue safety) | ✅ confirm | ✅ confirm | ✅ verified | Both independently validated every API call against 2.5.x. The uncertainty that triggered this build is resolved. |
| 2 | `OpenToCategory(frame)` may land on a generic page in 2.5.x → pass `panel.name` | ✅ | ❌ "frame is fine" | ⚖️ **kept frame, flagged for in-client** | Disagreement. Function accepts both; frame is the documented standard and Codex confirms it. Can't verify without a client → kept frame, added a smoke-test step to switch to name if it misbehaves. |
| 3 | Slider title "Scale" only set on first drag → blank label on first open | ✅ | — | ✅ **applied** | GLM-unique, real. Title now set in Init. |
| 4 | Slider fires full `CallAll("Refresh")` on every drag step | — | ✅ | ✅ **applied** | Codex-unique. Now applies scale live & cheaply (`hud.root:SetScale`) instead of a full refresh per step. |
| 5 | `NS.db` nil guard in Init/Load; guard the Settings fallback | ✅ | ✅ | ✅ **applied** | Both (different spots). Cheap defensive. |

**Lesson:** when a feature hinges on a version-specific API, triangulation is mostly *confirmation* — both models verifying the same calls against ground truth gives real confidence the legacy API choice is right for 2.5.x. The one disagreement (frame vs name) is genuinely unresolvable without a client, so it's logged as smoke-test debt with a ready fix, rather than guessed at.

---

## Iteration 7 — 2026-06-27 — Full cross-module audit (v1.6.1)

First whole-addon review (prior rounds saw one file each). Both gave a ship-ready verdict (GLM "ready for alpha/beta", Codex "conditionally ship-ready") + a smoke-test checklist. Raw: `reviews/glm/iter7.md`, `reviews/codex/iter7.md`.

| # | Finding | GLM | Codex | Verdict | Notes |
|---|---------|:---:|:----:|---------|-------|
| 1 | cooldowns runs a permanent per-frame OnUpdate just to poll a dirty flag | ✅ | ✅ | ✅ **applied** | Both. Took Codex's design (one-shot OnUpdate that removes itself after the rebuild) over GLM's (couple it into timers) — keeps the module self-contained. |
| 2 | timers OnUpdate installed on shared `hud.root` → a future module could clobber it | — | ✅ | ✅ **applied** | Codex-only architecture catch. Moved to a private `renderFrame` parented to root. |
| 3 | UpdatePower/UpdateCP set C-side bar/text/alpha 20×/s even when unchanged | ✅ | ✅ | ✅ **applied** | Both. Gated all C calls on actual value change; kept the poll as a freshness safety net (rejected Codex's fuller "split render from state" as overkill). |
| 4 | SavedVariables `point`/`scale` not validated; a corrupt save could break the HUD | ✅ | ✅ | ✅ **applied (safe version)** | Both flagged. Added index-wise validation (can't use `#point` — it has an intentional nil hole). **Rejected GLM's force-reset of `point` on a version bump** — it would wipe the user's saved position. |
| 5 | Dead `rnd` (Rend) entry in TRACK | ✅ | ✅ | ✅ **applied** | Removed. |
| 6 | Init-order comment said "hud first / config last" but config inits first | — | ✅ | ✅ **applied** | Codex doc-accuracy catch; comment corrected. |
| 7 | No `/reload` double-init guard | — | ✅ (optional) | ✅ **applied** | Added `if self.root/bars/icons/ev then return end` idempotency guards. Cheap insurance. |
| 8 | `wipe` global is "hazardous, could be hooked" | ✅ | ❌ (didn't flag) | ❌ **rejected** | Codex didn't flag it; `wipe` is a universal 2.5.x global. GLM's "could be hooked" is cargo-cult defensiveness. |
| 9 | Both `cooldowns` + `alerts` register `SPELL_UPDATE_COOLDOWN` | ✅ "fine" | ✅ "fine" | ✅ no-op | Both: different purposes, acceptable at this scale. |
| N1 | Taint / secure-frame review | ✅ clean | ✅ clean | ✅ no-op | Both confirm: display-only, no secure templates, no spell execution. `InCombatLockdown` used only to suppress the poison nag. |
| N2 | No leaked globals | — | ✅ confirm | ✅ verified | Independently confirmed by my `luac -l \| grep SETGLOBAL` bytecode check across all 6 files. |

**Lesson:** the holistic pass found a *different class* of issue than the per-feature rounds — architecture/shared-state hazards (the `hud.root` OnUpdate clobber, the permanent dirty-poll) that are invisible when you review one file in isolation. Worth doing a whole-system pass periodically, not just per-change. The smoke-test checklist (merged from both) is now `docs/SMOKE_TEST.md`.

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
