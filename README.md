# Cutthroat — Rogue helper for WoW TBC Classic (2.5.x)

A lightweight, **ban-safe** rogue HUD + alert addon. It **only reads game state and draws UI** — it never casts, queues, or presses a key for you, and uses no secure/protected frames. (Anything that auto-inputs spells is a Warden ban risk; this does none of that. Verified read-only by repeated GLM + Codex audits.)

> ⚠️ **Status:** feature-complete and code-audited, but **not yet tested in a live client.** Run `docs/SMOKE_TEST.md` in-game before relying on it. See "Verification" below.

## Features
- **Energy bar** — value + 20-energy tick marks, plus a sweeping **regen-tick spark** that self-calibrates to the energy tick cadence (helps you pool through a tick).
- **Combo-point pips** — light up 1→5; the row **pulses gold at 5 CP** so you finish instead of overcapping.
- **Finisher timers** — Slice and Dice (self), Rupture / Expose Armor / Garrote (your debuffs on the target). The label turns red + a sound plays as they run low, and a **"refresh-now" marker** sits at the threshold (TBC has no pandemic, so refresh just before expiry). The bar turns **green only when you can actually refresh** — energy for SnD; energy + a combo point + a live target for Rupture/Expose; never for Garrote (toggle `/cut smart`).
- **Cooldown row** — Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation, with cooldown sweep + desaturation. Icons show **only for spells you know**, so spec talents auto-hide.
- **Kick reminder** — a big pulsing icon when your target is casting an *interruptible* spell and Kick is off cooldown **and usable** (won't nag when you're energy-starved).
- **Poison check** — out of combat (incl. on login and after weapon swaps), warns if a weapon is missing its temporary enchant (poison/sharpening stone/etc.).
- **Stealth opener hint** — shows "Ambush / Garrote" when stealthed with a hostile target.
- **Options panel** — checkboxes + a scale slider in Interface → AddOns (`/cut config`), so you don't have to memorize slash commands.

## Install
1. Copy the **`Cutthroat`** folder into your AddOns directory:
   `World of Warcraft/_classic_/Interface/AddOns/`
   (Use whichever folder your TBC Anniversary client uses — usually `_classic_`.)
2. Restart WoW, or at the character screen open **AddOns** and tick Cutthroat.
3. If it shows "out of date", tick **"Load out of date AddOns"** — or set `## Interface:` in `Cutthroat.toc` to your client build (`/dump select(4,GetBuildInfo())` in-game shows it).

## Settings — `/cut`
Open the graphical panel with **`/cut config`**, or use slash commands (every command also works under `/cutthroat`):

| command | does |
|---|---|
| `/cut config` | open the options panel (alias `/cut options`) |
| `/cut lock` | lock / unlock the HUD so you can drag it |
| `/cut scale 0.9` | resize (0.4–3.0) |
| `/cut kick` | toggle Kick reminder |
| `/cut poison` | toggle poison check |
| `/cut opener` | toggle stealth opener hint |
| `/cut spark` | toggle energy regen-tick spark |
| `/cut ticks` | toggle the 20-energy mark lines (`/reload` to apply) |
| `/cut zone` | toggle the refresh-now marker on bars |
| `/cut smart` | green refresh cue only when CP/energy ready |
| `/cut finish` | toggle the max-CP overcap glow |
| `/cut sound` | toggle alert sounds |
| `/cut snd 3` | Slice and Dice warning threshold (seconds) |
| `/cut rup 2` | Rupture warning threshold (seconds) |
| `/cut reset` | reset HUD position |
| `/cut status` | print all current settings |
| `/cut help` | list commands |

Move the HUD: `/cut lock` to unlock, drag the dark box, `/cut lock` again. Settings save per-account in `CutthroatDB`.

## Safe by design
No `CastSpellByName`/`UseAction`/`RunMacro`/`RunScript`, no `SecureActionButton`, no hardware-event simulation, no combat attribute mutation. It reacts to events (`UNIT_POWER`, `UNIT_AURA`, `UNIT_SPELLCAST_*`, `SPELL_UPDATE_COOLDOWN`, …) and draws frames. `InCombatLockdown()` is used only to suppress the poison nag in combat.

## Verification
This addon can't be run headlessly, so the build process only proves it **parses clean** (`luac -p`) with **no leaked globals** (`luac -l` bytecode check). Real behavior must be checked in-game with the checklist in **`docs/SMOKE_TEST.md`**.

## How it was built
Hardened by a recurring **GLM + Codex triangulation loop** — each change is reviewed independently by two different models, their findings diffed, and only verified fixes applied. The full record is in `docs/`:
- `docs/DECISIONS.md` — what changed each version and why
- `docs/TRIANGULATION.md` — the GLM-vs-Codex diff/verdict per iteration
- `docs/ROADMAP.md` — shipped + planned + intentionally-dropped items
- `docs/SMOKE_TEST.md` — in-client test checklist
- `CHANGELOG.md` — version history

© 2026 Jesus Triana — MIT (see `LICENSE`).
