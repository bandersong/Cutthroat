# Cutthroat — Rogue helper for TBC Classic (2.5.x)

A lightweight, **ban-safe** rogue HUD + alert addon. It **only reads game state and shows UI** — it never casts, queues, or presses a key for you. (Anything that auto-inputs spells is a Warden ban risk; this does none of that.)

## Features
- **Energy bar** with 20-energy tick marks + numeric readout.
- **Combo point pips** for your current target.
- **Finisher timers**: Slice and Dice (self), Rupture / Expose Armor / Garrote on target. Bars flash + sound when about to drop.
- **Kick reminder**: big pulsing icon when your target is casting an *interruptible* spell and Kick is off cooldown.
- **Poison check**: out of combat, warns if main-hand / off-hand is missing a weapon enchant (poison/sharpening, etc.).
- **Stealth opener hint**: shows "Ambush / Garrote" when stealthed with a hostile target.

## Install
1. Copy the **`Cutthroat`** folder into:
   `World of Warcraft/_classic_/Interface/AddOns/`
   (Use whatever your TBC Anniversary client folder is — it's `_classic_` for most.)
2. Restart WoW, or at the character screen open **AddOns** and tick Cutthroat.
3. If it shows "out of date", check **"Load out of date AddOns"** in that same panel. (You can also bump `## Interface:` in `Cutthroat.toc` to match your client build — type `/dump select(4,GetBuildInfo())` in game to see it.)

## Commands — `/cut`
| command | does |
|---|---|
| `/cut lock` | lock / unlock the HUD so you can drag it |
| `/cut scale 0.9` | resize |
| `/cut kick` | toggle Kick reminder |
| `/cut poison` | toggle poison check |
| `/cut sound` | toggle alert sounds |
| `/cut ticks` | toggle energy tick marks |
| `/cut snd 3` | SnD warning threshold (seconds) |
| `/cut rup 2` | Rupture warning threshold (seconds) |
| `/cut reset` | reset HUD position |
| `/cut status` | print current settings |

## Notes
- Move the HUD: `/cut lock` to unlock, drag the dark box, `/cut lock` again.
- Settings save per-account in `CutthroatDB`.
- It works on non-rogues only for the config menu; the HUD is rogue-only.

## Safe by design
No `RunMacro`, no `CastSpellByName` automation, no hardware-event simulation. It reacts to events (`UNIT_POWER`, `UNIT_SPELLCAST_*`, auras) and draws frames. That's it.
