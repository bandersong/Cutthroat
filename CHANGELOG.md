# Changelog

All notable changes to Cutthroat. Each version was hardened by an independent GLM + Codex review (see `docs/TRIANGULATION.md`).

## [1.7.0] — 2026-06-27
- **Graphical options panel** in Interface → AddOns (checkboxes + scale slider), opened with `/cut config`. Built on the legacy `InterfaceOptions_*` API correct for TBC 2.5.x.

## [1.6.1] — 2026-06-27
- Cross-module audit hardening: cooldowns dropped its permanent per-frame loop for a one-shot self-clearing OnUpdate; the timer render loop moved off the shared `hud.root` to a private frame; HUD stops making redundant per-frame C calls; SavedVariables `point`/`scale` are sanitized on load; `/reload` double-init guards added; dead `rnd` entry removed. Both reviewers: ship-ready, zero taint.

## [1.6.0] — 2026-06-27
- **Combo-point overcap glow**: the pip row pulses gold at 5 CP so you finish instead of wasting combo generation. `/cut finish`.

## [1.5.0] — 2026-06-27
- **Resource-aware refresh cue**: the green "refresh-now" bar fill only lights when you can actually refresh (energy for SnD; energy + a combo point + a live target for Rupture/Expose; never for Garrote). `/cut smart`.

## [1.4.0] — 2026-06-27
- **Refresh-now marker** on the timer bars at the warn threshold + a final-window green fill. (TBC has no pandemic, so this means "refresh just before expiry without clipping.") `/cut zone`.

## [1.3.0] — 2026-06-27
- **Energy regen-tick predictor**: a spark sweeps the energy bar over the regen cycle to help pooling. Self-calibrates its interval from observed ticks, so it stays correct under Adrenaline Rush. `/cut spark`.

## [1.2.0] — 2026-06-27
- **Cooldown row**: Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation — sweep + desaturation; only shows spells you know.

## [1.1.0] — 2026-06-27
- First triangulated hardening pass on the scaffold: fixed the dead aura filter (pipe vs space) that hid all timers, nondeterministic module init order, an unfiltered power event, a 160-`UnitAura`-calls/0.1s perf hole, Kick usability gating, pre-pull poison checks, and the `GetWeaponEnchantInfo` off-hand position.

## [1.0.0] — 2026-06-27
- Initial scaffold: energy bar + combo pips, SnD/Rupture/Expose/Garrote timers, Kick reminder, poison check, stealth opener hint, `/cut` config. Ban-safe (alerts/HUD only).
