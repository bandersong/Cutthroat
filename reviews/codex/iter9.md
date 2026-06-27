Reading additional input from stdin...
OpenAI Codex v0.142.2
--------
workdir: /Users/creative/WoWAddons/Cutthroat
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 019f09b0-2274-7692-be30-b0bac485f437
--------
user
DOCUMENTATION-DRIFT CHECK for this Cutthroat WoW TBC Classic 2.5.x Rogue addon: verify README.md and CHANGELOG.md match the actual code. Read README.md, CHANGELOG.md, config.lua, core.lua, cooldowns.lua, and grep the .lua files. Flag ONLY mismatches: (1) feature in README not implemented in code; (2) /cut command in README not handled in config.lua dispatch, OR a real dispatched command missing from README; (3) false ban-safety claim (grep CastSpell/UseAction/RunMacro/RunScript/SecureActionButton across all lua); (4) wrong defaults (README: SnD warn 3s, Rupture 2s, scale 0.4-3.0); (5) wrong file/version claims; (6) inaccurate cooldown spell list or settings list. For each mismatch: quote doc claim, state code reality, give fix. Skip accurate claims. Numbered. Do NOT edit files.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll audit docs against code only, no edits. I’m going to read the requested files and grep Lua for commands, defaults, spell lists, and protected API usage.
exec
/bin/zsh -lc 'pwd && rg --files' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

exec
/bin/zsh -lc "sed -n '1,260p' README.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
# Cutthroat — Rogue helper for WoW TBC Classic (2.5.x)

A lightweight, **ban-safe** rogue HUD + alert addon. It **only reads game state and draws UI** — it never casts, queues, or presses a key for you, and uses no secure/protected frames. (Anything that auto-inputs spells is a Warden ban risk; this does none of that. Verified read-only by repeated GLM + Codex audits.)

> ⚠️ **Status:** feature-complete and code-audited, but **not yet tested in a live client.** Run `docs/SMOKE_TEST.md` in-game before relying on it. See "Verification" below.

## Features
- **Energy bar** — value + 20-energy tick marks, plus a sweeping **regen-tick spark** that self-calibrates to the energy tick cadence (helps you pool through a tick).
- **Combo-point pips** — light up 1→5; the row **pulses gold at 5 CP** so you finish instead of overcapping.
- **Finisher timers** — Slice and Dice (self), Rupture / Expose Armor / Garrote (your debuffs on the target). Bars flash + sound as they run low, and show a **"refresh-now" marker** at the threshold (TBC has no pandemic, so refresh just before expiry). The bar turns **green only when you actually have the combo points + energy to refresh** (toggle `/cut smart`).
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
Open the graphical panel with **`/cut config`**, or use slash commands:

| command | does |
|---|---|
| `/cut config` | open the options panel |
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

exec
/bin/zsh -lc "sed -n '1,280p' config.lua" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "sed -n '1,260p' CHANGELOG.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Config: /cut slash command. Minimal, no external libs.
local ADDON, NS = ...
local Config = NS:RegisterModule("config", {})

local function on(v) return v and "|cff20ff40on|r" or "|cffff4040off|r" end

local function Print(msg) print("|cff00ff96Cutthroat|r: " .. msg) end

local function Help()
    Print("commands:")
    print("  |cffffff00/cut lock|r        toggle move/lock HUD")
    print("  |cffffff00/cut scale N|r      set scale (e.g. 0.9)")
    print("  |cffffff00/cut kick|r         toggle Kick reminder")
    print("  |cffffff00/cut poison|r       toggle poison check")
    print("  |cffffff00/cut opener|r       toggle stealth opener hint")
    print("  |cffffff00/cut sound|r        toggle alert sounds")
    print("  |cffffff00/cut ticks|r        toggle energy 20-mark lines")
    print("  |cffffff00/cut spark|r        toggle energy regen-tick spark")
    print("  |cffffff00/cut zone|r         toggle refresh-now marker on bars")
    print("  |cffffff00/cut smart|r        green only when CP/energy ready")
    print("  |cffffff00/cut finish|r       toggle max-CP overcap glow")
    print("  |cffffff00/cut snd N|r        SnD warning seconds")
    print("  |cffffff00/cut rup N|r        Rupture warning seconds")
    print("  |cffffff00/cut config|r       open the options panel")
    print("  |cffffff00/cut reset|r        reset position")
    print("  |cffffff00/cut status|r       show settings")
end

function Config:Init()
    SLASH_CUTTHROAT1 = "/cut"
    SLASH_CUTTHROAT2 = "/cutthroat"
    SlashCmdList["CUTTHROAT"] = function(msg)
        local db = NS.db
        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()

        if cmd == "" or cmd == "help" then
            Help()
        elseif cmd == "lock" then
            db.locked = not db.locked
            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
        elseif cmd == "scale" then
            local n = tonumber(arg)
            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
            else Print("scale needs 0.4-3.0") end
        elseif cmd == "kick" then
            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
        elseif cmd == "poison" then
            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
        elseif cmd == "opener" then
            db.openerHint = not db.openerHint; Print("opener hint " .. on(db.openerHint))
        elseif cmd == "sound" then
            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
        elseif cmd == "ticks" then
            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
        elseif cmd == "spark" then
            db.tickSpark = not db.tickSpark; Print("regen-tick spark " .. on(db.tickSpark))
        elseif cmd == "zone" then
            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
        elseif cmd == "smart" then
            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
        elseif cmd == "finish" then
            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
        elseif cmd == "snd" then
            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
        elseif cmd == "rup" then
            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
        elseif cmd == "config" or cmd == "options" then
            if NS.modules.options and NS.modules.options.Open then
                NS.modules.options:Open()
            end
        elseif cmd == "reset" then
            db.point = { "CENTER", nil, "CENTER", 0, -180 }
            Print("position reset (/reload to apply)")
        elseif cmd == "status" then
            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s",
                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound)))
            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
        else
            Help()
        end
        NS.CallAll("Refresh")
    end
end

function Config:Refresh() end

 succeeded in 0ms:
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

codex
`rg` isn’t installed in this environment, so I’m falling back to `find`/`grep`. The slash-command table in `config.lua` already matches most README entries; next I’m checking code defaults, cooldown definitions, options panel, and protected API grep.
exec
/bin/zsh -lc "sed -n '1,320p' core.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Cutthroat: Rogue helper for TBC Classic (2.5.x)
-- Pure read/display. No spell input automation (Warden-safe).

local ADDON, NS = ...
NS.name = "Cutthroat"
NS.modules = {}

-- ---- Saved variable defaults ----
local defaults = {
    locked = false,
    scale = 1.0,
    point = { "CENTER", nil, "CENTER", 0, -180 },
    sndWarn = 3,        -- seconds left on Slice and Dice before warning
    ruptureWarn = 2,    -- seconds left on Rupture before warning
    kickAlert = true,   -- flash when target casts an interruptible spell + Kick ready
    poisonCheck = true, -- warn when a weapon is missing poison out of combat
    openerHint = true,  -- show "Ambush / Garrote" hint when stealthed w/ target
    sound = true,
    energyTicks = true, -- show 20-energy tick marks
    tickSpark = true,   -- moving spark = progress to next ~2s energy regen tick
    refreshZone = true, -- mark the "refresh now" window near expiry on SnD/DoT bars
    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
    cpFinishGlow = true,-- pulse the combo pips at max CP (don't overcap -> finish)
}

-- ---- Class gate ----
local _, playerClass = UnitClass("player")

-- ---- Module registration ----
function NS:RegisterModule(name, mod)
    self.modules[name] = mod
    return mod
end

local function CallAll(method, ...)
    for _, mod in pairs(NS.modules) do
        if mod[method] then mod[method](mod, ...) end
    end
end
NS.CallAll = CallAll

-- ---- Event hub ----
local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CutthroatDB = CutthroatDB or {}
        for k, v in pairs(defaults) do
            if CutthroatDB[k] == nil then
                CutthroatDB[k] = (type(v) == "table") and CopyTable(v) or v
            end
        end
        -- Sanitize the values the HUD trusts, in case the save is corrupted. NOTE:
        -- point[2] is intentionally nil (relativeTo=UIParent), so validate fields by
        -- index — never use #point (a nil hole makes the length operator unreliable).
        local p = CutthroatDB.point
        if type(p) ~= "table" or type(p[1]) ~= "string" or type(p[3]) ~= "string"
            or type(p[4]) ~= "number" or type(p[5]) ~= "number" then
            CutthroatDB.point = CopyTable(defaults.point)
        end
        if type(CutthroatDB.scale) ~= "number" or CutthroatDB.scale < 0.4 or CutthroatDB.scale > 3 then
            CutthroatDB.scale = defaults.scale
        end
        NS.db = CutthroatDB
    elseif event == "PLAYER_LOGIN" then
        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
        -- works for everyone, then the rogue-only visual modules — hud BEFORE
        -- timers/cooldowns/alerts, which all anchor to hud.root.
        local function initModule(name)
            local m = NS.modules[name]
            if m and m.Init then m:Init() end
        end
        initModule("config")  -- slash commands work for everyone
        initModule("options") -- graphical settings panel works for everyone
        if playerClass == "ROGUE" then
            initModule("hud")
            initModule("timers")
            initModule("cooldowns")
            initModule("alerts")
            CallAll("Refresh")
        else
            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.")
        end
        -- TBC 2.5.x exposes the global GetAddOnMetadata; C_AddOns is a newer wrapper.
        local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
            or "1.0.0"
        print("|cff00ff96Cutthroat|r v" .. ver .. " loaded. |cffffff00/cut|r for options.")
    end
end)

NS.IsRogue = (playerClass == "ROGUE")

-- shared color helpers
NS.color = {
    energy  = { 1.0, 0.85, 0.20 },
    cp      = { 1.0, 0.20, 0.20 },
    good    = { 0.20, 1.0, 0.40 },
    warn    = { 1.0, 0.55, 0.10 },
    bad     = { 1.0, 0.15, 0.15 },
    dim     = { 0.45, 0.45, 0.45 },
}

exec
/bin/zsh -lc "sed -n '1,320p' cooldowns.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- cooldowns.lua: rogue defensive/utility cooldown icons with sweep timers.
-- READ-ONLY — shows cooldown state, never casts. Only icons for spells you KNOW
-- (so a Combat rogue won't see Cold Blood, an Assassination rogue won't see AR).

local ADDON, NS = ...
local CDs = NS:RegisterModule("cooldowns", {})

local ICON, GAP = 30, 4

-- Tracked by spellID; the name/texture are resolved at runtime (locale-safe).
-- Order = display order. Talent spells simply won't show if untrained.
local SPELL_IDS = {
    1856,   -- Vanish
    5277,   -- Evasion
    2983,   -- Sprint
    13877,  -- Blade Flurry   (Combat)
    13750,  -- Adrenaline Rush (Combat)
    14177,  -- Cold Blood     (Assassination)
    14185,  -- Preparation    (Subtlety)
}

-- Known-state is determined by scanning the player spellbook by localized name.
-- (GetSpellCooldown(name) does NOT reliably return nil for unlearned spells in
-- 2.5.x, so it can't gate the talent-spell icons — verified by GLM + Codex.)
local BOOK = BOOKTYPE_SPELL or "spell"

function CDs:Init()
    if not NS.IsRogue then return end
    if self.icons then return end -- idempotent: never double-init
    local root = NS.modules.hud.root
    self.icons = {}
    self.known = {}
    self.layoutDirty = false

    -- de-dupe the id list (guard against typos above) and resolve names/textures
    local seen = {}
    self.spells = {}
    for _, id in ipairs(SPELL_IDS) do
        if not seen[id] then
            seen[id] = true
            local name, _, tex = GetSpellInfo(id)
            if name then
                self.spells[#self.spells + 1] = { id = id, name = name, tex = tex }
            end
        end
    end

    -- anchor below the timer bars. Bar 1 top = -56; 4 bars at 14h/3gap → last bar
    -- bottom = -121. Icons are CENTER-anchored, so drop a full ICON/2 + gap below
    -- that to avoid clipping the bottom bar (caught by Codex: was overlapping ~4px).
    local timerBottom = -(18 + 6 + 22 + 10) - (3 * 17) - 14  -- -121
    local rowY = timerBottom - 8 - ICON / 2                   -- -144

    for i, s in ipairs(self.spells) do
        local f = CreateFrame("Frame", nil, root)
        f:SetSize(ICON, ICON)
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetAllPoints()
        f.icon:SetTexture(s.tex or GetSpellTexture(s.id))
        f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
        f.cd:SetAllPoints()
        if f.cd.SetDrawEdge then f.cd:SetDrawEdge(true) end
        f.spell = s
        f:Hide()
        self.icons[i] = f
    end
    self.rowY = rowY

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
    -- unknown event hard-errors and would break load. The two above cover respec.
    -- SPELLS_CHANGED fires aggressively, so coalesce layout rebuilds with a ONE-SHOT
    -- OnUpdate that removes itself after running — no permanent per-frame loop.
    local function flushLayout()
        ev:SetScript("OnUpdate", nil)
        self.layoutDirty = false
        self:RebuildKnown()
        self:Relayout()
    end
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        elseif not self.layoutDirty then
            self.layoutDirty = true
            ev:SetScript("OnUpdate", flushLayout) -- fires once next frame, then clears
        end
    end)
    self.ev = ev

    self:RebuildKnown()
    self:Relayout()
end

-- Cache the set of spells the player actually knows (by localized name).
function CDs:RebuildKnown()
    if not self.known then return end
    wipe(self.known)
    local i = 1
    while true do
        local n = GetSpellName(i, BOOK)
        if not n then break end
        self.known[n] = true
        i = i + 1
    end
end

-- Show only known spells, packed left-to-right and centered under the HUD.
function CDs:Relayout()
    if not self.icons then return end
    local root = NS.modules.hud.root
    local shown = {}
    for _, f in ipairs(self.icons) do
        if self.known[f.spell.name] then shown[#shown + 1] = f else f:Hide() end
    end
    local n = #shown
    local totalW = n * ICON + (n - 1) * GAP
    local startX = -totalW / 2 + ICON / 2
    for i, f in ipairs(shown) do
        f:ClearAllPoints()
        f:SetPoint("CENTER", root, "TOP", startX + (i - 1) * (ICON + GAP), self.rowY)
        f:Show()
    end
    self:UpdateCooldowns()
end

function CDs:UpdateCooldowns()
    if not self.icons then return end
    for _, f in ipairs(self.icons) do
        if f:IsShown() then
            local start, dur, enabled = GetSpellCooldown(f.spell.name)
            -- dur > 2 ignores the ~1s GCD sweep; all tracked CDs are far above it
            if start and dur and dur > 2 and enabled ~= 0 then
                f.cd:SetCooldown(start, dur)
                f.icon:SetDesaturated(true)
            else
                f.cd:Clear()
                f.icon:SetDesaturated(false)
            end
        end
    end
end

function CDs:Refresh()
    if self.icons then self:RebuildKnown(); self:Relayout() end
end

exec
/bin/zsh -lc "find . -maxdepth 2 -name '*.lua' -print" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua
./timers.lua
./alerts.lua
./config.lua
./options.lua
./cooldowns.lua
./core.lua

exec
/bin/zsh -lc "grep -RInE 'CastSpell|UseAction|RunMacro|RunScript|SecureActionButton|UseItem|Click\\(|SetAttribute|RegisterForClicks' -- *.lua 2>/dev/null" in /Users/creative/WoWAddons/Cutthroat
 exited 1 in 0ms:
codex
Protected API grep came back empty for the requested calls and adjacent secure/action patterns, so the ban-safety claim doesn’t look false on that axis. I’m now checking the remaining Lua modules and metadata so I can flag only real doc drift.
exec
/bin/zsh -lc "sed -n '1,340p' hud.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
local ADDON, NS = ...

local HUD = NS:RegisterModule("hud", {})

local WIDTH, HEIGHT = 240, 18
local CP_SIZE, CP_GAP = 22, 6
local MAX_CP = 5
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

function HUD:Init()
    if self.root then return end -- idempotent: never double-init frames
    local db = NS.db

    -- root anchor (movable)
    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
    root:SetSize(WIDTH, HEIGHT + CP_SIZE + 8)
    root:SetScale(db.scale)
    local p = db.point
    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
    root:SetMovable(true)
    root:EnableMouse(not db.locked)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", function(s) if not NS.db.locked then s:StartMoving() end end)
    root:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        local a, _, rp, x, y = s:GetPoint()
        NS.db.point = { a, nil, rp, x, y }
    end)
    self.root = root

    -- drag hint backdrop (only when unlocked)
    root.bg = root:CreateTexture(nil, "BACKGROUND")
    root.bg:SetAllPoints()
    root.bg:SetColorTexture(0, 0, 0, 0.25)

    -- ---- Energy bar ----
    local energy = CreateFrame("StatusBar", nil, root)
    energy:SetSize(WIDTH, HEIGHT)
    energy:SetPoint("TOP", root, "TOP", 0, 0)
    energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    energy:SetStatusBarColor(unpack(NS.color.energy))
    energy:SetMinMaxValues(0, 100)
    energy.bg = energy:CreateTexture(nil, "BACKGROUND")
    energy.bg:SetAllPoints()
    energy.bg:SetColorTexture(0.12, 0.10, 0.0, 0.85)
    energy.text = energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    energy.text:SetPoint("CENTER")
    self.energy = energy

    -- 20-energy tick marks
    energy.ticks = {}
    if db.energyTicks then
        for i = 1, 4 do
            local t = energy:CreateTexture(nil, "OVERLAY")
            t:SetColorTexture(0, 0, 0, 0.6)
            t:SetSize(1, HEIGHT)
            t:SetPoint("LEFT", energy, "LEFT", WIDTH * (i * 20 / 100), 0)
            energy.ticks[i] = t
        end
    end

    -- energy regen-tick spark: a thin marker sweeping the bar 0->100% over the
    -- ~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
    energy.spark = energy:CreateTexture(nil, "OVERLAY")
    energy.spark:SetColorTexture(1, 1, 1, 0.85)
    energy.spark:SetWidth(2)
    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
    energy.spark:Hide()
    self.lastEnergy = nil
    self.energyMax = 100
    self.lastTick = 0
    self.tickInterval = 2.0 -- self-calibrated from observed tick gaps

    -- ---- Combo point pips ----
    self.pips = {}
    local totalW = MAX_CP * CP_SIZE + (MAX_CP - 1) * CP_GAP
    local startX = (WIDTH - totalW) / 2
    for i = 1, MAX_CP do
        local pip = root:CreateTexture(nil, "ARTWORK")
        pip:SetSize(CP_SIZE, CP_SIZE)
        pip:SetPoint("TOPLEFT", root, "TOPLEFT", startX + (i - 1) * (CP_SIZE + CP_GAP), -(HEIGHT + 6))
        pip:SetTexture("Interface\\ComboFrame\\ComboPoint")
        pip:SetTexCoord(0, 0.375, 0, 1) -- the lit gem
        pip:SetVertexColor(unpack(NS.color.cp))
        pip:SetAlpha(0.15)
        self.pips[i] = pip
    end

    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
    -- spend them instead of overcapping (building past 5 CP is wasted generation).
    self.cpGlow = root:CreateTexture(nil, "BACKGROUND")
    self.cpGlow:SetPoint("TOPLEFT", self.pips[1], "TOPLEFT", -3, 3)
    self.cpGlow:SetPoint("BOTTOMRIGHT", self.pips[MAX_CP], "BOTTOMRIGHT", 3, -3)
    self.cpGlow:SetColorTexture(1, 0.82, 0, 1)
    self.cpGlow:SetBlendMode("ADD") -- additive => soft glow, not a harsh solid box
    self.cpGlow:Hide()

    -- Event-driven power updates, all unit-filtered to "player" so other units'
    -- power changes never wake this handler. Combo points have no reliable
    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
    -- and registering a wrong event name errors) — they're polled in timers:Tick.
    local ev = CreateFrame("Frame")
    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
    self.ev = ev
end

function HUD:UpdatePower()
    if not self.energy then return end
    local e = UnitPower("player", ENERGY)
    local m = UnitPowerMax("player", ENERGY)
    m = (m and m > 0) and m or 100
    -- This is polled ~20x/s; only make the C-side bar calls when values change.
    if m ~= self.energyMax then
        self.energyMax = m
        self.energy:SetMinMaxValues(0, m)
    end
    if e ~= self.shownEnergy then
        self.shownEnergy = e
        self.energy:SetValue(e)
        self.energy.text:SetText(e)
    end

    if self.lastEnergy == nil then self.lastEnergy = e; return end
    -- A regen tick lands as a sizable positive delta. Small proc gains (Combat
    -- Potency etc.) are ignored with the >=10 filter so they don't yank the spark.
    -- We MEASURE the real tick cadence from gap to gap (clamped) instead of assuming
    -- 2.0s — GLM and Codex disagreed on whether Adrenaline Rush changes the tick
    -- interval or the per-tick amount, so measuring sidesteps the unresolved question.
    if e > self.lastEnergy and (e - self.lastEnergy) >= 10 then
        local now = GetTime()
        local gap = now - (self.lastTick or now)
        if gap >= 0.8 and gap <= 2.2 then self.tickInterval = gap end
        self.lastTick = now
    end
    self.lastEnergy = e
end

-- Move the regen-tick spark; called every render frame from timers:Render.
function HUD:UpdateEnergyTick()
    local s = self.energy and self.energy.spark
    if not s then return end
    -- hide when disabled or at full energy (no tick to wait for)
    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
        s:Hide(); return
    end
    local interval = self.tickInterval or 2.0
    local frac = (GetTime() - (self.lastTick or 0)) / interval
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
    local w = self.energy:GetWidth()
    local sw = s:GetWidth() or 2
    local x = frac * w
    if x > w - sw then x = w - sw end  -- keep the full 2px spark inside the bar
    if x < 0 then x = 0 end
    s:ClearAllPoints()
    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
    s:Show()
end

function HUD:UpdateCP()
    -- guard on a live target so the glow can't linger after detarget
    local cp = UnitExists("target") and (GetComboPoints("player", "target") or 0) or 0
    -- polled ~20x/s; only re-alpha the pips when the CP count actually changes
    if cp ~= self.shownCP then
        self.shownCP = cp
        for i = 1, MAX_CP do
            self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
        end
    end
    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
    local g = self.cpGlow
    if g then
        if cp >= MAX_CP and NS.db.cpFinishGlow then
            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
            if not g:IsShown() then g:Show() end
        elseif g:IsShown() then
            g:Hide()
        end
    end
end

function HUD:Refresh()
    if not self.root then return end
    self.root:SetScale(NS.db.scale)
    self.root:EnableMouse(not NS.db.locked)
    self.root.bg:SetShown(not NS.db.locked)
    self:UpdatePower()
    self:UpdateCP()
end

exec
/bin/zsh -lc "sed -n '1,380p' timers.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Timers: track YOUR finisher durations on the current target via combat log.
-- Slice and Dice (self buff) + Rupture / Expose Armor / Garrote (target debuffs).
-- Uses CLEU for application/refresh so it works pre-2.5 aura APIs reliably.

local ADDON, NS = ...
local Timers = NS:RegisterModule("timers", {})

-- spellID -> { label, base, perCP (optional) }  durations are *max* (5cp) approximations;
-- we read the real remaining time from auras when possible, CLEU is the fallback.
local TRACK = {
    -- Slice and Dice ranks share name; track by name (self buff)
    snd = { name = "Slice and Dice", isSelf = true,  color = "good" },
    rup = { name = "Rupture",        isSelf = false, color = "bad"  },
    exp = { name = "Expose Armor",   isSelf = false, color = "warn" },
    gar = { name = "Garrote",        isSelf = false, color = "bad"  },
}

local BAR_W, BAR_H = 200, 14
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

-- Can the player actually refresh this aura right now? Used to gate the green
-- "refresh-now" cue so it never implies an action you lack resources for.
-- Finisher cost is 25 energy; SnD needs only energy, Rupture/Expose also need CP.
local function HasRefreshResources(key)
    local e = UnitPower("player", ENERGY)
    if key == "snd" then
        return e >= 25 -- self-buff, only needs energy
    elseif key == "rup" or key == "exp" then
        -- finishers: need a live attackable target AND energy AND a combo point
        if not UnitExists("target") or UnitIsDead("target")
            or not UnitCanAttack("player", "target") then
            return false
        end
        return e >= 25 and (GetComboPoints("player", "target") or 0) >= 1
    end
    return false -- Garrote: stealth-only, can't refresh in combat -> never cue green
end

local function GetAura(unit, name, byPlayer)
    -- WoW aura filters are SPACE-separated tokens, not pipe-separated.
    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
    for i = 1, 40 do
        local n, dur, exp
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if not d then break end
            n, dur, exp = d.name, d.duration, d.expirationTime
        else
            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
            local dur2, exp2
            n, _, _, _, dur2, exp2 = UnitAura(unit, i, filter)
            if not n then break end
            dur, exp = dur2, exp2
        end
        if n == name and exp and exp > 0 then
            return exp, dur   -- absolute expiration time + full duration
        end
    end
    return nil
end

-- where each tracked aura lives
local SOURCE = {
    snd = { unit = "player", byPlayer = false },
    rup = { unit = "target", byPlayer = true  },
    exp = { unit = "target", byPlayer = true  },
    gar = { unit = "target", byPlayer = true  },
}

function Timers:Init()
    if self.bars then return end -- idempotent: never double-init frames/scripts
    local root = NS.modules.hud.root
    self.bars = {}
    self.cache = {} -- key -> { exp = absolute, dur = full }
    local order = { "snd", "rup", "exp", "gar" }
    local y = -(18 + 6 + 22 + 10) -- below the CP pips
    for idx, key in ipairs(order) do
        local b = CreateFrame("StatusBar", nil, root)
        b:SetSize(BAR_W, BAR_H)
        b:SetPoint("TOP", root, "TOP", 0, y - (idx - 1) * (BAR_H + 3))
        b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local c = NS.color[TRACK[key].color]
        b:SetStatusBarColor(c[1], c[2], c[3])
        b.baseColor = c
        b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
        b.bg:SetColorTexture(0, 0, 0, 0.6)
        -- "refresh now" marker: when the fill shrinks past this line you're in the
        -- window to refresh without significant clipping (TBC has no pandemic).
        b.marker = b:CreateTexture(nil, "OVERLAY")
        b.marker:SetColorTexture(1, 1, 1, 0.9)
        b.marker:SetSize(2, BAR_H)
        b.marker:Hide()
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.label:SetPoint("LEFT", 4, 0); b.label:SetText(TRACK[key].name)
        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.time:SetPoint("RIGHT", -4, 0)
        b:Hide()
        -- reset transient render state on hide (set ONCE, not per tick)
        b:SetScript("OnHide", function(s) s.inZone = nil; s.greenState = nil; s.markerDur = nil end)
        self.bars[key] = b
    end

    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
    local scan = CreateFrame("Frame")
    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
    scan:SetScript("OnEvent", function() self:Scan() end)
    self.scan = scan

    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
    -- Use a PRIVATE frame, not hud.root, so a future module setting an OnUpdate on
    -- root can't silently clobber the render loop (shared-state hazard).
    self.elapsed = 0
    self.renderFrame = CreateFrame("Frame", nil, root)
    self.renderFrame:SetScript("OnUpdate", function(_, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed < 0.05 then return end
        self.elapsed = 0
        self:Render()
    end)
    self:Scan()
end

-- Refresh the aura cache from the game (only on aura/target change events).
function Timers:Scan()
    if not NS.IsRogue or not self.cache then return end
    local hasTarget = UnitExists("target") and not UnitIsDead("target")
    for key, src in pairs(SOURCE) do
        local exp, dur
        if src.unit == "player" or hasTarget then
            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
        end
        self.cache[key] = exp and { exp = exp, dur = dur } or nil
    end
end

-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
function Timers:Render()
    if not NS.IsRogue then return end
    NS.modules.hud:UpdateCP()
    NS.modules.hud:UpdatePower()
    NS.modules.hud:UpdateEnergyTick()

    local now = GetTime()
    for key, b in pairs(self.bars) do
        local c = self.cache[key]
        local rem = c and (c.exp - now) or 0
        if not c or rem <= 0 then
            self.cache[key] = nil
            if b:IsShown() then
                b:Hide(); b.marker:Hide()
                b.inZone = nil; b.greenState = nil; b.markerDur = nil
            end
        else
            local warnAt = (key == "snd" and NS.db.sndWarn)
                or (key == "rup" and NS.db.ruptureWarn) or 2
            local dur = (c.dur and c.dur > 0) and c.dur or rem
            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
            b:SetValue(rem)
            b.time:SetText(string.format("%.1f", rem))

            -- refresh-now marker: the fill's right edge crosses it at rem==warnAt.
            -- Reposition only when the duration changes (per new cast), not per frame.
            if NS.db.refreshZone then
                if b.markerDur ~= dur then
                    b.markerDur = dur
                    local frac = warnAt / dur
                    if frac > 1 then frac = 1 elseif frac < 0 then frac = 0 end
                    b.marker:ClearAllPoints()
                    b.marker:SetPoint("CENTER", b, "LEFT", frac * BAR_W, 0) -- centered on edge
                end
                if not b.marker:IsShown() then b.marker:Show() end
            elseif b.marker:IsShown() then
                b.marker:Hide()
            end

            -- color state machine: only call Set*Color on a transition (avoids ~20
            -- redundant C calls/sec/bar). label flash + entry sound gated by inZone;
            -- fill-green gated separately so /cut zone toggles live and restores base.
            local want = rem <= warnAt
            if want ~= b.inZone then
                b.inZone = want
                b.label:SetTextColor(want and NS.color.bad[1] or 1,
                                     want and NS.color.bad[2] or 1,
                                     want and NS.color.bad[3] or 1)
                if want and NS.db.sound then
                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
                end
            end
            local green = want and NS.db.refreshZone
            if green and NS.db.smartRefresh then green = HasRefreshResources(key) end
            if green ~= b.greenState then
                b.greenState = green
                b:SetStatusBarColor(unpack(green and NS.color.good or b.baseColor))
            end

            if not b:IsShown() then b:Show() end
        end
    end
end

function Timers:Refresh() if self.cache then self:Scan() end end

exec
/bin/zsh -lc "sed -n '1,340p' options.lua" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "sed -n '1,360p' alerts.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- options.lua: graphical settings panel in Interface > AddOns, so you don't have
-- to memorize the /cut slash toggles. Read-only over the addon's SavedVariables.
local ADDON, NS = ...
local Options = NS:RegisterModule("options", {})

-- boolean settings -> checkbox label (order = top-to-bottom in the panel)
local TOGGLES = {
    { "locked",       "Lock HUD position" },
    { "kickAlert",    "Kick interrupt reminder" },
    { "poisonCheck",  "Poison missing warning" },
    { "openerHint",   "Stealth opener hint" },
    { "sound",        "Alert sounds" },
    { "energyTicks",  "Energy 20-mark lines (reload to apply)" },
    { "tickSpark",    "Energy regen-tick spark" },
    { "refreshZone",  "Refresh-now marker on bars" },
    { "smartRefresh", "Green only when CP/energy ready" },
    { "cpFinishGlow", "Max-CP overcap glow" },
}

function Options:Init()
    if self.panel then return end   -- idempotent
    if not NS.db then return end    -- SavedVariables must be loaded first
    local panel = CreateFrame("Frame", "CutthroatOptions", UIParent)
    panel.name = "Cutthroat"
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Cutthroat |cff00ff96Rogue|r")
    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetText("Ban-safe HUD + alerts. Changes apply instantly.")

    self.checks = {}
    local y = -64
    for _, t in ipairs(TOGGLES) do
        local key, label = t[1], t[2]
        local cb = CreateFrame("CheckButton", "CutthroatOpt_" .. key, panel, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, y)
        local txt = _G[cb:GetName() .. "Text"]
        if txt then txt:SetText(label) end
        cb:SetScript("OnClick", function(b)
            NS.db[key] = b:GetChecked() and true or false
            NS.CallAll("Refresh")
        end)
        self.checks[key] = cb
        y = y - 28
    end

    -- scale slider (uses the legacy OptionsSliderTemplate, present in 2.5.x)
    local s = CreateFrame("Slider", "CutthroatOptScale", panel, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, y - 20)
    s:SetMinMaxValues(0.4, 3.0)
    s:SetValueStep(0.05)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:SetWidth(220)
    local sn = s:GetName()
    if _G[sn .. "Low"] then _G[sn .. "Low"]:SetText("0.4") end
    if _G[sn .. "High"] then _G[sn .. "High"]:SetText("3.0") end
    if _G[sn .. "Text"] then _G[sn .. "Text"]:SetText("Scale") end -- title before first drag
    s:SetScript("OnValueChanged", function(sl, v)
        v = math.floor(v * 20 + 0.5) / 20 -- snap to 0.05
        if _G[sl:GetName() .. "Text"] then
            _G[sl:GetName() .. "Text"]:SetText(string.format("Scale: %.2f", v))
        end
        if NS.db.scale ~= v then
            NS.db.scale = v
            -- apply live + cheap (only the HUD scales) instead of a full CallAll per drag step
            local hud = NS.modules.hud
            if hud and hud.root then hud.root:SetScale(v) end
        end
    end)
    self.scale = s

    -- legacy Interface Options "refresh" hook fires when the panel is shown
    panel.refresh = function() self:Load() end

    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(cat)
        self.category = cat
    end
    self:Load()
end

-- mirror the saved values into the widgets
function Options:Load()
    if not self.checks or not NS.db then return end
    for key, cb in pairs(self.checks) do
        cb:SetChecked(NS.db[key] and true or false)
    end
    if self.scale then self.scale:SetValue(NS.db.scale or 1.0) end
end

function Options:Refresh() self:Load() end

-- open the panel (called by /cut config)
function Options:Open()
    if not self.panel then return end
    if InterfaceOptionsFrame_OpenToCategory then
        -- Blizzard bug: first call sometimes lands on the wrong page; call twice
        InterfaceOptionsFrame_OpenToCategory(self.panel)
        InterfaceOptionsFrame_OpenToCategory(self.panel)
    elseif Settings and Settings.OpenToCategory and self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end

 succeeded in 0ms:
-- Alerts: reactive reminders. ALERTS ONLY — never casts/queues a spell (Warden-safe).
--   * Kick reminder: target is casting an interruptible spell AND Kick is off CD -> flash icon.
--   * Poison check: out of combat, MH/OH missing a weapon enchant -> reminder text.
--   * Stealth opener: in stealth with a target -> show Ambush/Garrote hint.

local ADDON, NS = ...
local Alerts = NS:RegisterModule("alerts", {})

local KICK = GetSpellInfo and GetSpellInfo(1766) or "Kick" -- localized name

local function SpellReady(name)
    if not name then return false end
    -- don't nag to Kick when it can't actually be cast (e.g. not enough energy)
    local usable, noMana = IsUsableSpell(name)
    if not usable or noMana then return false end
    local start, dur, enabled = GetSpellCooldown(name)
    if not start or enabled == 0 then return false end
    return (start == 0) or (start + dur - GetTime() <= 0.2)
end

function Alerts:Init()
    if self.ev then return end -- idempotent: never double-init frames/events
    local root = NS.modules.hud.root

    -- ---- Kick flash icon (center, above HUD) ----
    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
    kick:SetSize(64, 64)
    kick:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    kick.icon = kick:CreateTexture(nil, "ARTWORK")
    kick.icon:SetAllPoints()
    kick.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    kick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    kick.txt = kick:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    kick.txt:SetPoint("TOP", kick, "BOTTOM", 0, -2)
    kick.txt:SetText("KICK!")
    kick.txt:SetTextColor(unpack(NS.color.bad))
    kick:Hide()
    -- pulse
    local ag = kick:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    kick.ag = ag
    self.kick = kick

    -- ---- Poison reminder text ----
    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pz:SetPoint("BOTTOM", root, "TOP", 0, 6)
    pz:SetTextColor(unpack(NS.color.warn))
    pz:Hide()
    self.poison = pz

    -- ---- Stealth opener hint ----
    local op = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    op:SetPoint("BOTTOM", root, "TOP", 0, 28)
    op:SetTextColor(unpack(NS.color.good))
    op:Hide()
    self.opener = op

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("UNIT_SPELLCAST_START")
    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
    ev:RegisterEvent("UPDATE_STEALTH")
    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    ev:SetScript("OnEvent", function(_, e, unit) Alerts:OnEvent(e, unit) end)
    self.ev = ev
end

function Alerts:OnEvent(e, unit)
    if not NS.IsRogue then return end
    if e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_ENTERING_WORLD" or e == "UNIT_INVENTORY_CHANGED" then
        self:CheckPoison()
    elseif e == "PLAYER_REGEN_DISABLED" then
        self.poison:Hide()
    end
    if e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_ENTERING_WORLD" then
        self:CheckOpener()
    end
    -- Kick logic on any cast event affecting the target
    self:CheckKick(e, unit)
end

function Alerts:CheckKick(e, unit)
    if not NS.db.kickAlert then return end
    if unit ~= "target" then
        -- still re-evaluate on target change / cooldown updates
        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
    end
    local casting = false
    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if not name then
        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
    end
    if name and not notInterruptible then casting = true end

    if casting and SpellReady(KICK) then
        if not self.kick:IsShown() then
            self.kick:Show()
            self.kick.ag:Stop(); self.kick.ag:Play() -- reset loop state cleanly
            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
        end
    else
        if self.kick:IsShown() then self.kick.ag:Stop(); self.kick:Hide() end
    end
end

function Alerts:CheckPoison()
    if not NS.db.poisonCheck then self.poison:Hide(); return end
    if InCombatLockdown() then return end -- only nag out of combat
    -- TBC 2.5 sig: hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges (no enchantID)
    local mh, _, _, oh = GetWeaponEnchantInfo()
    local missing = {}
    if not mh then missing[#missing + 1] = "Main-hand" end
    -- only warn off-hand if one is equipped
    if GetInventoryItemLink("player", 17) and not oh then missing[#missing + 1] = "Off-hand" end
    if #missing > 0 then
        self.poison:SetText("No poison: " .. table.concat(missing, " & "))
        self.poison:Show()
    else
        self.poison:Hide()
    end
end

function Alerts:CheckOpener()
    if not NS.db.openerHint then self.opener:Hide(); return end
    local stealthed = IsStealthed and IsStealthed()
    if stealthed and UnitExists("target") and UnitCanAttack("player", "target") then
        self.opener:SetText("Opener: Ambush / Garrote")
        self.opener:Show()
    else
        self.opener:Hide()
    end
end

function Alerts:Refresh()
    if self.kick then self.kick:Hide() end
    if NS.IsRogue then
        self:CheckPoison()  -- hides itself if disabled / in combat
        self:CheckOpener()  -- hides itself if disabled
    end
end

exec
/bin/zsh -lc "sed -n '1,120p' Cutthroat.toc 2>/dev/null || true" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
## Interface: 20504
## Title: Cutthroat |cff00ff96Rogue|r
## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
## Author: Cutthroat
## Version: 1.7.0
## SavedVariables: CutthroatDB
## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate

core.lua
hud.lua
timers.lua
cooldowns.lua
alerts.lua
options.lua
config.lua

codex
I found one likely semantics drift in the smart refresh wording: the README says CP + energy, while code treats Slice and Dice as energy-only. I’m doing a final metadata/docs existence and broad Lua grep pass before I give the numbered list.
exec
/bin/zsh -lc 'find docs -maxdepth 1 -type f -print 2>/dev/null | sort' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
docs/DECISIONS.md
docs/ROADMAP.md
docs/SMOKE_TEST.md
docs/TRIANGULATION.md

exec
/bin/zsh -lc "grep -nE '/cut|ban-safe|SecureActionButton|CastSpell|UseAction|RunMacro|RunScript|Cooldown row|Options panel|SnD|Rupture|scale|1\\.7\\.0|1\\.6\\.1|cooldown' README.md CHANGELOG.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
README.md:3:A lightweight, **ban-safe** rogue HUD + alert addon. It **only reads game state and draws UI** — it never casts, queues, or presses a key for you, and uses no secure/protected frames. (Anything that auto-inputs spells is a Warden ban risk; this does none of that. Verified read-only by repeated GLM + Codex audits.)
README.md:10:- **Finisher timers** — Slice and Dice (self), Rupture / Expose Armor / Garrote (your debuffs on the target). Bars flash + sound as they run low, and show a **"refresh-now" marker** at the threshold (TBC has no pandemic, so refresh just before expiry). The bar turns **green only when you actually have the combo points + energy to refresh** (toggle `/cut smart`).
README.md:11:- **Cooldown row** — Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation, with cooldown sweep + desaturation. Icons show **only for spells you know**, so spec talents auto-hide.
README.md:12:- **Kick reminder** — a big pulsing icon when your target is casting an *interruptible* spell and Kick is off cooldown **and usable** (won't nag when you're energy-starved).
README.md:15:- **Options panel** — checkboxes + a scale slider in Interface → AddOns (`/cut config`), so you don't have to memorize slash commands.
README.md:24:## Settings — `/cut`
README.md:25:Open the graphical panel with **`/cut config`**, or use slash commands:
README.md:29:| `/cut config` | open the options panel |
README.md:30:| `/cut lock` | lock / unlock the HUD so you can drag it |
README.md:31:| `/cut scale 0.9` | resize (0.4–3.0) |
README.md:32:| `/cut kick` | toggle Kick reminder |
README.md:33:| `/cut poison` | toggle poison check |
README.md:34:| `/cut opener` | toggle stealth opener hint |
README.md:35:| `/cut spark` | toggle energy regen-tick spark |
README.md:36:| `/cut ticks` | toggle the 20-energy mark lines (`/reload` to apply) |
README.md:37:| `/cut zone` | toggle the refresh-now marker on bars |
README.md:38:| `/cut smart` | green refresh cue only when CP/energy ready |
README.md:39:| `/cut finish` | toggle the max-CP overcap glow |
README.md:40:| `/cut sound` | toggle alert sounds |
README.md:41:| `/cut snd 3` | Slice and Dice warning threshold (seconds) |
README.md:42:| `/cut rup 2` | Rupture warning threshold (seconds) |
README.md:43:| `/cut reset` | reset HUD position |
README.md:44:| `/cut status` | print all current settings |
README.md:45:| `/cut help` | list commands |
README.md:47:Move the HUD: `/cut lock` to unlock, drag the dark box, `/cut lock` again. Settings save per-account in `CutthroatDB`.
README.md:50:No `CastSpellByName`/`UseAction`/`RunMacro`/`RunScript`, no `SecureActionButton`, no hardware-event simulation, no combat attribute mutation. It reacts to events (`UNIT_POWER`, `UNIT_AURA`, `UNIT_SPELLCAST_*`, `SPELL_UPDATE_COOLDOWN`, …) and draws frames. `InCombatLockdown()` is used only to suppress the poison nag in combat.
CHANGELOG.md:5:## [1.7.0] — 2026-06-27
CHANGELOG.md:6:- **Graphical options panel** in Interface → AddOns (checkboxes + scale slider), opened with `/cut config`. Built on the legacy `InterfaceOptions_*` API correct for TBC 2.5.x.
CHANGELOG.md:8:## [1.6.1] — 2026-06-27
CHANGELOG.md:9:- Cross-module audit hardening: cooldowns dropped its permanent per-frame loop for a one-shot self-clearing OnUpdate; the timer render loop moved off the shared `hud.root` to a private frame; HUD stops making redundant per-frame C calls; SavedVariables `point`/`scale` are sanitized on load; `/reload` double-init guards added; dead `rnd` entry removed. Both reviewers: ship-ready, zero taint.
CHANGELOG.md:12:- **Combo-point overcap glow**: the pip row pulses gold at 5 CP so you finish instead of wasting combo generation. `/cut finish`.
CHANGELOG.md:15:- **Resource-aware refresh cue**: the green "refresh-now" bar fill only lights when you can actually refresh (energy for SnD; energy + a combo point + a live target for Rupture/Expose; never for Garrote). `/cut smart`.
CHANGELOG.md:18:- **Refresh-now marker** on the timer bars at the warn threshold + a final-window green fill. (TBC has no pandemic, so this means "refresh just before expiry without clipping.") `/cut zone`.
CHANGELOG.md:21:- **Energy regen-tick predictor**: a spark sweeps the energy bar over the regen cycle to help pooling. Self-calibrates its interval from observed ticks, so it stays correct under Adrenaline Rush. `/cut spark`.
CHANGELOG.md:24:- **Cooldown row**: Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation — sweep + desaturation; only shows spells you know.
CHANGELOG.md:30:- Initial scaffold: energy bar + combo pips, SnD/Rupture/Expose/Garrote timers, Kick reminder, poison check, stealth opener hint, `/cut` config. Ban-safe (alerts/HUD only).

exec
/bin/zsh -lc "grep -RInE 'SlashCmdList|SLASH_|elseif cmd ==|cmd ==|sndWarn|ruptureWarn|scale|SPELL_IDS|TOGGLES|GetSpellInfo\\(|GetSpellCooldown|PlaySound|SetAlpha|Animation|SetScript\\(\"OnUpdate\"|CastSpell|UseAction|RunMacro|RunScript|SecureActionButton' -- *.lua 2>/dev/null" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "grep -nE '"'^## (Interface|Version)|''^(core|hud|timers|cooldowns|alerts|options|config)'"\\.lua"'$'"' Cutthroat.toc" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
1:## Interface: 20504
5:## Version: 1.7.0
9:core.lua
10:hud.lua
11:timers.lua
12:cooldowns.lua
13:alerts.lua
14:options.lua
15:config.lua

 succeeded in 0ms:
alerts.lua:9:local KICK = GetSpellInfo and GetSpellInfo(1766) or "Kick" -- localized name
alerts.lua:16:    local start, dur, enabled = GetSpellCooldown(name)
alerts.lua:39:    local ag = kick:CreateAnimationGroup()
alerts.lua:41:    local a = ag:CreateAnimation("Alpha")
alerts.lua:108:            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
config.lua:12:    print("  |cffffff00/cut scale N|r      set scale (e.g. 0.9)")
config.lua:30:    SLASH_CUTTHROAT1 = "/cut"
config.lua:31:    SLASH_CUTTHROAT2 = "/cutthroat"
config.lua:32:    SlashCmdList["CUTTHROAT"] = function(msg)
config.lua:37:        if cmd == "" or cmd == "help" then
config.lua:39:        elseif cmd == "lock" then
config.lua:42:        elseif cmd == "scale" then
config.lua:44:            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
config.lua:45:            else Print("scale needs 0.4-3.0") end
config.lua:46:        elseif cmd == "kick" then
config.lua:48:        elseif cmd == "poison" then
config.lua:50:        elseif cmd == "opener" then
config.lua:52:        elseif cmd == "sound" then
config.lua:54:        elseif cmd == "ticks" then
config.lua:56:        elseif cmd == "spark" then
config.lua:58:        elseif cmd == "zone" then
config.lua:60:        elseif cmd == "smart" then
config.lua:62:        elseif cmd == "finish" then
config.lua:64:        elseif cmd == "snd" then
config.lua:65:            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
config.lua:66:        elseif cmd == "rup" then
config.lua:67:            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
config.lua:68:        elseif cmd == "config" or cmd == "options" then
config.lua:72:        elseif cmd == "reset" then
config.lua:75:        elseif cmd == "status" then
config.lua:76:            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s",
config.lua:77:                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound)))
cooldowns.lua:12:local SPELL_IDS = {
cooldowns.lua:23:-- (GetSpellCooldown(name) does NOT reliably return nil for unlearned spells in
cooldowns.lua:38:    for _, id in ipairs(SPELL_IDS) do
cooldowns.lua:41:            local name, _, tex = GetSpellInfo(id)
cooldowns.lua:79:        ev:SetScript("OnUpdate", nil)
cooldowns.lua:89:            ev:SetScript("OnUpdate", flushLayout) -- fires once next frame, then clears
cooldowns.lua:134:            local start, dur, enabled = GetSpellCooldown(f.spell.name)
core.lua:11:    scale = 1.0,
core.lua:13:    sndWarn = 3,        -- seconds left on Slice and Dice before warning
core.lua:14:    ruptureWarn = 2,    -- seconds left on Rupture before warning
core.lua:62:        if type(CutthroatDB.scale) ~= "number" or CutthroatDB.scale < 0.4 or CutthroatDB.scale > 3 then
core.lua:63:            CutthroatDB.scale = defaults.scale
hud.lua:18:    root:SetScale(db.scale)
hud.lua:87:        pip:SetAlpha(0.15)
hud.lua:172:            self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
hud.lua:179:            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
hud.lua:189:    self.root:SetScale(NS.db.scale)
options.lua:7:local TOGGLES = {
options.lua:36:    for _, t in ipairs(TOGGLES) do
options.lua:50:    -- scale slider (uses the legacy OptionsSliderTemplate, present in 2.5.x)
options.lua:66:        if NS.db.scale ~= v then
options.lua:67:            NS.db.scale = v
options.lua:68:            -- apply live + cheap (only the HUD scales) instead of a full CallAll per drag step
options.lua:73:    self.scale = s
options.lua:95:    if self.scale then self.scale:SetValue(NS.db.scale or 1.0) end
timers.lua:117:    self.renderFrame:SetScript("OnUpdate", function(_, dt)
timers.lua:157:            local warnAt = (key == "snd" and NS.db.sndWarn)
timers.lua:158:                or (key == "rup" and NS.db.ruptureWarn) or 2
timers.lua:189:                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")

codex
Final pass confirms defaults, TOC version, file list, cooldown spell IDs, options toggles, and protected-call grep are consistent. The remaining mismatches are documentation wording and undocumented command aliases.
exec
/bin/zsh -lc "nl -ba README.md | sed -n '1,70p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	# Cutthroat — Rogue helper for WoW TBC Classic (2.5.x)
     2	
     3	A lightweight, **ban-safe** rogue HUD + alert addon. It **only reads game state and draws UI** — it never casts, queues, or presses a key for you, and uses no secure/protected frames. (Anything that auto-inputs spells is a Warden ban risk; this does none of that. Verified read-only by repeated GLM + Codex audits.)
     4	
     5	> ⚠️ **Status:** feature-complete and code-audited, but **not yet tested in a live client.** Run `docs/SMOKE_TEST.md` in-game before relying on it. See "Verification" below.
     6	
     7	## Features
     8	- **Energy bar** — value + 20-energy tick marks, plus a sweeping **regen-tick spark** that self-calibrates to the energy tick cadence (helps you pool through a tick).
     9	- **Combo-point pips** — light up 1→5; the row **pulses gold at 5 CP** so you finish instead of overcapping.
    10	- **Finisher timers** — Slice and Dice (self), Rupture / Expose Armor / Garrote (your debuffs on the target). Bars flash + sound as they run low, and show a **"refresh-now" marker** at the threshold (TBC has no pandemic, so refresh just before expiry). The bar turns **green only when you actually have the combo points + energy to refresh** (toggle `/cut smart`).
    11	- **Cooldown row** — Vanish, Evasion, Sprint, Blade Flurry, Adrenaline Rush, Cold Blood, Preparation, with cooldown sweep + desaturation. Icons show **only for spells you know**, so spec talents auto-hide.
    12	- **Kick reminder** — a big pulsing icon when your target is casting an *interruptible* spell and Kick is off cooldown **and usable** (won't nag when you're energy-starved).
    13	- **Poison check** — out of combat (incl. on login and after weapon swaps), warns if a weapon is missing its temporary enchant (poison/sharpening stone/etc.).
    14	- **Stealth opener hint** — shows "Ambush / Garrote" when stealthed with a hostile target.
    15	- **Options panel** — checkboxes + a scale slider in Interface → AddOns (`/cut config`), so you don't have to memorize slash commands.
    16	
    17	## Install
    18	1. Copy the **`Cutthroat`** folder into your AddOns directory:
    19	   `World of Warcraft/_classic_/Interface/AddOns/`
    20	   (Use whichever folder your TBC Anniversary client uses — usually `_classic_`.)
    21	2. Restart WoW, or at the character screen open **AddOns** and tick Cutthroat.
    22	3. If it shows "out of date", tick **"Load out of date AddOns"** — or set `## Interface:` in `Cutthroat.toc` to your client build (`/dump select(4,GetBuildInfo())` in-game shows it).
    23	
    24	## Settings — `/cut`
    25	Open the graphical panel with **`/cut config`**, or use slash commands:
    26	
    27	| command | does |
    28	|---|---|
    29	| `/cut config` | open the options panel |
    30	| `/cut lock` | lock / unlock the HUD so you can drag it |
    31	| `/cut scale 0.9` | resize (0.4–3.0) |
    32	| `/cut kick` | toggle Kick reminder |
    33	| `/cut poison` | toggle poison check |
    34	| `/cut opener` | toggle stealth opener hint |
    35	| `/cut spark` | toggle energy regen-tick spark |
    36	| `/cut ticks` | toggle the 20-energy mark lines (`/reload` to apply) |
    37	| `/cut zone` | toggle the refresh-now marker on bars |
    38	| `/cut smart` | green refresh cue only when CP/energy ready |
    39	| `/cut finish` | toggle the max-CP overcap glow |
    40	| `/cut sound` | toggle alert sounds |
    41	| `/cut snd 3` | Slice and Dice warning threshold (seconds) |
    42	| `/cut rup 2` | Rupture warning threshold (seconds) |
    43	| `/cut reset` | reset HUD position |
    44	| `/cut status` | print all current settings |
    45	| `/cut help` | list commands |
    46	
    47	Move the HUD: `/cut lock` to unlock, drag the dark box, `/cut lock` again. Settings save per-account in `CutthroatDB`.
    48	
    49	## Safe by design
    50	No `CastSpellByName`/`UseAction`/`RunMacro`/`RunScript`, no `SecureActionButton`, no hardware-event simulation, no combat attribute mutation. It reacts to events (`UNIT_POWER`, `UNIT_AURA`, `UNIT_SPELLCAST_*`, `SPELL_UPDATE_COOLDOWN`, …) and draws frames. `InCombatLockdown()` is used only to suppress the poison nag in combat.
    51	
    52	## Verification
    53	This addon can't be run headlessly, so the build process only proves it **parses clean** (`luac -p`) with **no leaked globals** (`luac -l` bytecode check). Real behavior must be checked in-game with the checklist in **`docs/SMOKE_TEST.md`**.
    54	
    55	## How it was built
    56	Hardened by a recurring **GLM + Codex triangulation loop** — each change is reviewed independently by two different models, their findings diffed, and only verified fixes applied. The full record is in `docs/`:
    57	- `docs/DECISIONS.md` — what changed each version and why
    58	- `docs/TRIANGULATION.md` — the GLM-vs-Codex diff/verdict per iteration
    59	- `docs/ROADMAP.md` — shipped + planned + intentionally-dropped items
    60	- `docs/SMOKE_TEST.md` — in-client test checklist
    61	- `CHANGELOG.md` — version history
    62	
    63	© 2026 Jesus Triana — MIT (see `LICENSE`).

exec
/bin/zsh -lc "nl -ba config.lua | sed -n '28,86p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
    28	
    29	function Config:Init()
    30	    SLASH_CUTTHROAT1 = "/cut"
    31	    SLASH_CUTTHROAT2 = "/cutthroat"
    32	    SlashCmdList["CUTTHROAT"] = function(msg)
    33	        local db = NS.db
    34	        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    35	        cmd = (cmd or ""):lower()
    36	
    37	        if cmd == "" or cmd == "help" then
    38	            Help()
    39	        elseif cmd == "lock" then
    40	            db.locked = not db.locked
    41	            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
    42	        elseif cmd == "scale" then
    43	            local n = tonumber(arg)
    44	            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
    45	            else Print("scale needs 0.4-3.0") end
    46	        elseif cmd == "kick" then
    47	            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
    48	        elseif cmd == "poison" then
    49	            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
    50	        elseif cmd == "opener" then
    51	            db.openerHint = not db.openerHint; Print("opener hint " .. on(db.openerHint))
    52	        elseif cmd == "sound" then
    53	            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
    54	        elseif cmd == "ticks" then
    55	            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
    56	        elseif cmd == "spark" then
    57	            db.tickSpark = not db.tickSpark; Print("regen-tick spark " .. on(db.tickSpark))
    58	        elseif cmd == "zone" then
    59	            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
    60	        elseif cmd == "smart" then
    61	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
    62	        elseif cmd == "finish" then
    63	            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
    64	        elseif cmd == "snd" then
    65	            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
    66	        elseif cmd == "rup" then
    67	            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
    68	        elseif cmd == "config" or cmd == "options" then
    69	            if NS.modules.options and NS.modules.options.Open then
    70	                NS.modules.options:Open()
    71	            end
    72	        elseif cmd == "reset" then
    73	            db.point = { "CENTER", nil, "CENTER", 0, -180 }
    74	            Print("position reset (/reload to apply)")
    75	        elseif cmd == "status" then
    76	            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s",
    77	                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound)))
    78	            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
    79	                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
    80	        else
    81	            Help()
    82	        end
    83	        NS.CallAll("Refresh")
    84	    end
    85	end
    86	

exec
/bin/zsh -lc "nl -ba alerts.lua | sed -n '35,47p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '20,50p;180,204p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
    35	    kick.txt:SetText("KICK!")
    36	    kick.txt:SetTextColor(unpack(NS.color.bad))
    37	    kick:Hide()
    38	    -- pulse
    39	    local ag = kick:CreateAnimationGroup()
    40	    ag:SetLooping("BOUNCE")
    41	    local a = ag:CreateAnimation("Alpha")
    42	    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    43	    kick.ag = ag
    44	    self.kick = kick
    45	
    46	    -- ---- Poison reminder text ----
    47	    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")

 succeeded in 0ms:
    20	
    21	-- Can the player actually refresh this aura right now? Used to gate the green
    22	-- "refresh-now" cue so it never implies an action you lack resources for.
    23	-- Finisher cost is 25 energy; SnD needs only energy, Rupture/Expose also need CP.
    24	local function HasRefreshResources(key)
    25	    local e = UnitPower("player", ENERGY)
    26	    if key == "snd" then
    27	        return e >= 25 -- self-buff, only needs energy
    28	    elseif key == "rup" or key == "exp" then
    29	        -- finishers: need a live attackable target AND energy AND a combo point
    30	        if not UnitExists("target") or UnitIsDead("target")
    31	            or not UnitCanAttack("player", "target") then
    32	            return false
    33	        end
    34	        return e >= 25 and (GetComboPoints("player", "target") or 0) >= 1
    35	    end
    36	    return false -- Garrote: stealth-only, can't refresh in combat -> never cue green
    37	end
    38	
    39	local function GetAura(unit, name, byPlayer)
    40	    -- WoW aura filters are SPACE-separated tokens, not pipe-separated.
    41	    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
    42	    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
    43	    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
    44	    for i = 1, 40 do
    45	        local n, dur, exp
    46	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    47	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    48	            if not d then break end
    49	            n, dur, exp = d.name, d.duration, d.expirationTime
    50	        else
   180	            -- redundant C calls/sec/bar). label flash + entry sound gated by inZone;
   181	            -- fill-green gated separately so /cut zone toggles live and restores base.
   182	            local want = rem <= warnAt
   183	            if want ~= b.inZone then
   184	                b.inZone = want
   185	                b.label:SetTextColor(want and NS.color.bad[1] or 1,
   186	                                     want and NS.color.bad[2] or 1,
   187	                                     want and NS.color.bad[3] or 1)
   188	                if want and NS.db.sound then
   189	                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
   190	                end
   191	            end
   192	            local green = want and NS.db.refreshZone
   193	            if green and NS.db.smartRefresh then green = HasRefreshResources(key) end
   194	            if green ~= b.greenState then
   195	                b.greenState = green
   196	                b:SetStatusBarColor(unpack(green and NS.color.good or b.baseColor))
   197	            end
   198	
   199	            if not b:IsShown() then b:Show() end
   200	        end
   201	    end
   202	end
   203	
   204	function Timers:Refresh() if self.cache then self:Scan() end end

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

No edits made. Mismatches found:

1. Doc claim: README says finisher timer “Bars flash + sound as they run low” at [README.md:10](/Users/creative/WoWAddons/Cutthroat/README.md:10).
   Code reality: [timers.lua:182](/Users/creative/WoWAddons/Cutthroat/timers.lua:182) only changes the label text color and plays sound; no timer bar flash/alpha/animation exists.
   Fix: change to “Labels turn red + sound as they run low,” or implement an actual bar flash.

2. Doc claim: README says the bar turns green only when you have “combo points + energy to refresh” at [README.md:10](/Users/creative/WoWAddons/Cutthroat/README.md:10), repeated as `/cut smart` “CP/energy ready” at [README.md:38](/Users/creative/WoWAddons/Cutthroat/README.md:38).
   Code reality: Slice and Dice is energy-only in [timers.lua:26](/Users/creative/WoWAddons/Cutthroat/timers.lua:26); Rupture/Expose require target + energy + CP; Garrote never greens.
   Fix: use the changelog’s more precise wording: “energy for SnD; energy + CP + live target for Rupture/Expose; never Garrote.”

3. Missing README command: `config.lua` dispatches `/cut options` as an alias for `/cut config` at [config.lua:68](/Users/creative/WoWAddons/Cutthroat/config.lua:68), but README only lists `/cut config`.
   Fix: add `/cut options` to the settings table or remove the alias.

4. Missing README slash alias: `config.lua` registers `/cutthroat` at [config.lua:31](/Users/creative/WoWAddons/Cutthroat/config.lua:31), but README documents only `/cut`.
   Fix: add a note that `/cutthroat` is also supported, or remove the alias.
tokens used
36,436
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

No edits made. Mismatches found:

1. Doc claim: README says finisher timer “Bars flash + sound as they run low” at [README.md:10](/Users/creative/WoWAddons/Cutthroat/README.md:10).
   Code reality: [timers.lua:182](/Users/creative/WoWAddons/Cutthroat/timers.lua:182) only changes the label text color and plays sound; no timer bar flash/alpha/animation exists.
   Fix: change to “Labels turn red + sound as they run low,” or implement an actual bar flash.

2. Doc claim: README says the bar turns green only when you have “combo points + energy to refresh” at [README.md:10](/Users/creative/WoWAddons/Cutthroat/README.md:10), repeated as `/cut smart` “CP/energy ready” at [README.md:38](/Users/creative/WoWAddons/Cutthroat/README.md:38).
   Code reality: Slice and Dice is energy-only in [timers.lua:26](/Users/creative/WoWAddons/Cutthroat/timers.lua:26); Rupture/Expose require target + energy + CP; Garrote never greens.
   Fix: use the changelog’s more precise wording: “energy for SnD; energy + CP + live target for Rupture/Expose; never Garrote.”

3. Missing README command: `config.lua` dispatches `/cut options` as an alias for `/cut config` at [config.lua:68](/Users/creative/WoWAddons/Cutthroat/config.lua:68), but README only lists `/cut config`.
   Fix: add `/cut options` to the settings table or remove the alias.

4. Missing README slash alias: `config.lua` registers `/cutthroat` at [config.lua:31](/Users/creative/WoWAddons/Cutthroat/config.lua:31), but README documents only `/cut`.
   Fix: add a note that `/cutthroat` is also supported, or remove the alias.
