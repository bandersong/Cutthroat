# Cutthroat — In-Client Smoke Test

This addon can't be tested without a running WoW client, so the loop only proves it *parses* (`luac -p`) and has no leaked globals. Everything below must be checked by a human in-game on the **TBC Classic 2.5.x** client. Merged from the GLM + Codex holistic audit (iter 7).

Tip: run with **BugSack/BugGrabber** (or `/console scriptErrors 1`) so any Lua error surfaces.

## 1. Load & gating
- [ ] Rogue login: no Lua errors; HUD appears (energy bar + 5 dim combo pips); `/cut status` prints two lines.
- [ ] Non-rogue login: no Lua errors; prints "not a rogue — HUD disabled"; **no HUD frames drawn**; `/cut` still works.
- [ ] `/reload` as rogue: no duplicate HUD/bars/icons; saved position + scale persist.

## 2. HUD core
- [ ] Generate combo points 1→5: pips light up in sequence.
- [ ] At 5 CP: gold overcap glow pulses smoothly; **drop target → glow clears immediately**.
- [ ] Energy bar value/text track in real time; 20-energy tick marks visible (if `/cut ticks` on).
- [ ] Energy regen-tick spark sweeps and resets on each tick; hides at full energy.

## 3. Timers (SnD / Rupture / Expose / Garrote)
- [ ] Cast Slice and Dice: green self-bar appears, counts down accurately.
- [ ] Near `sndWarn` (default 3s): label flashes red + sound; bar shows the refresh marker.
- [ ] Cast Rupture on a dummy: bar appears; **drop target → bar disappears cleanly**.
- [ ] Refresh marker (`/cut zone`) sits where the fill crosses the threshold; green only lights when you have CP+energy (`/cut smart` on).

## 4. Cooldowns
- [ ] Only **known** cooldowns show: Combat sees Blade Flurry/Adrenaline Rush; Assassination sees Cold Blood; Subtlety sees Preparation; everyone sees Vanish/Evasion/Sprint.
- [ ] Use Vanish/Evasion: radial sweep runs and icon desaturates while on CD.
- [ ] Respec talents: icon set updates **without** `/reload`.

## 5. Alerts
- [ ] Target an enemy casting an interruptible spell with Kick ready: **KICK!** flash pulses; on Kick CD or insufficient energy: no flash.
- [ ] Remove weapon poisons out of combat: warning shows; enter combat: it hides.
- [ ] Stealth + hostile target: "Opener: Ambush / Garrote" shows; unstealth/clear target: hides.

## 6. Settings & persistence
- [ ] `/cut lock` toggles the drag background; drag HUD; `/reload` → position persists.
- [ ] `/cut reset` returns to default position; `/cut scale 1.5` / `0.5` apply immediately.
- [ ] Toggle each: `/cut kick poison opener sound ticks spark zone smart finish` — behavior changes, no errors.

## 7. Stress
- [ ] `/eventtrace` or BugSack through a full combat: no Lua errors, no duplicate-event storms.
- [ ] Sustained combat: no noticeable FPS drop from the HUD.

> Record results here (date / build / pass-fail / notes) when run. Until then this is **verification debt** — the addon is parse-clean and audited but not yet client-verified.
