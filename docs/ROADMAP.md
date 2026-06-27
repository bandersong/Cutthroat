# Cutthroat — Roadmap

"Ever upwards." Each loop iteration should leave the addon strictly better. Candidate features, roughly prioritized. Items move to `DECISIONS.md` when shipped.

## Near-term (next iterations)
- [ ] **CD tracker row**: Vanish, Evasion, Blade Flurry, Adrenaline Rush, Cold Blood, Sprint — icon cooldown swipes.
- [ ] **Energy tick predictor**: mark the next +20 energy regen tick (2s cadence) on the bar.
- [ ] **SnD/Rupture refresh-window highlight**: green zone when refreshing is optimal (pandemic-style, ~30% remaining).
- [ ] **Spec detection**: read talents, adjust finisher durations (SnD/Rupture scale with talents like Improved SnD).

## Mid-term
- [ ] **Combat log DPS/energy efficiency mini-readout.**
- [ ] **Poison type awareness**: name *which* poison is missing (Instant/Deadly/Wound) per weapon, not just "missing".
- [ ] **Localization scaffold** (enUS strings table → other locales).
- [ ] **In-client smoke test checklist** (the loop can't run WoW; record manual test results).

## Verification debt (loop can't run WoW — needs friend/in-client)
- [ ] Confirm `## Interface:` matches the live Anniversary build (`/dump select(4,GetBuildInfo())`).
- [ ] Confirm `IsStealthed`, `UnitChannelInfo`, `UnitCastingInfo` return signatures on the 2.5.x client.
- [ ] Confirm `ComboPoint` texture path + texcoords render correctly.
- [ ] No Lua errors on load with a fresh `CutthroatDB`.
