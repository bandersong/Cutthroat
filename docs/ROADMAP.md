# Cutthroat — Roadmap

"Ever upwards." Each loop iteration should leave the addon strictly better. Candidate features, roughly prioritized. Items move to `DECISIONS.md` when shipped.

## Near-term (next iterations)
- [x] **CD tracker row**: Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation — icon cooldown swipes. *(shipped v1.2.0, iter 2)*
- [x] **Energy tick predictor**: spark marks progress to the next energy regen tick; self-calibrating interval. *(shipped v1.3.0, iter 3)*
- [x] **SnD/Rupture refresh-window marker**: ~~pandemic 30%~~ corrected — TBC has no pandemic, so a "refresh-now" marker at the warn threshold + green final-window cue. *(shipped v1.4.0, iter 4)*
- [x] **Resource-aware refresh cue**: bar only turns green when you have the CP/energy (and a live target) to refresh. `/cut smart` toggle. *(shipped v1.5.0, iter 5)*
- [ ] **Spec detection**: read talents, adjust finisher durations (SnD/Rupture scale with talents like Improved SnD).

## Mid-term
- [ ] **Combat log DPS/energy efficiency mini-readout.**
- [~] **Poison type awareness**: ~~name which poison is missing~~ — INFEASIBLE in 2.5.x: `GetWeaponEnchantInfo` returns has-enchant/expiry/charges but no enchant ID/name, so the applied poison can't be identified. Present/absent only.
- [ ] **Localization scaffold** (enUS strings table → other locales).
- [ ] **In-client smoke test checklist** (the loop can't run WoW; record manual test results).

## Verification debt (loop can't run WoW — needs friend/in-client)
- [ ] Confirm `## Interface:` matches the live Anniversary build (`/dump select(4,GetBuildInfo())`).
- [ ] Confirm `IsStealthed`, `UnitChannelInfo`, `UnitCastingInfo` return signatures on the 2.5.x client.
- [ ] Confirm `ComboPoint` texture path + texcoords render correctly.
- [ ] No Lua errors on load with a fresh `CutthroatDB`.
