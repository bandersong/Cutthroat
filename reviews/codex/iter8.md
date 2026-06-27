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
session id: 019f09a7-bca7-7670-a90a-b00ee71631be
--------
user
Review the NEW options.lua (graphical settings panel) in this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. It registers an Interface>AddOns panel with checkboxes (UICheckButtonTemplate) for 10 booleans + a scale slider (OptionsSliderTemplate), wired to NS.db + NS.CallAll('Refresh'), opened via /cut config. READ-ONLY. Verify for TBC Classic 2.5.x specifically: (1) InterfaceOptions_AddCategory exists and is correct for 2.5.x (Settings.* used only as guarded fallback)? (2) InterfaceOptionsFrame_OpenToCategory exists; double-call workaround valid? (3) UICheckButtonTemplate label at _G[name..'Text']? (4) OptionsSliderTemplate sub-regions _G[name..'Low'/'High'/'Text']? (5) SetObeyStepOnDrag guarded ok? (6) panel.name/panel.refresh legacy hooks correct? (7) initializing options for non-rogue ok? (8) checkbox/slider firing NS.CallAll('Refresh') when rogue modules uninitialized (non-rogue) safe? Read options.lua and core.lua. Numbered: file/function/bug/fix. Do NOT edit. Real bugs first.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll review this read-only in code-review mode: first the two files, then I’ll verify TBC-era API assumptions against the implementation and report only actionable issues.
exec
/bin/zsh -lc "sed -n '1,260p' options.lua" in /Users/creative/WoWAddons/Cutthroat
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
    if self.panel then return end -- idempotent
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
    s:SetScript("OnValueChanged", function(sl, v)
        v = math.floor(v * 20 + 0.5) / 20 -- snap to 0.05
        if _G[sl:GetName() .. "Text"] then
            _G[sl:GetName() .. "Text"]:SetText(string.format("Scale: %.2f", v))
        end
        if NS.db.scale ~= v then
            NS.db.scale = v
            NS.CallAll("Refresh")
        end
    end)
    self.scale = s

    -- legacy Interface Options "refresh" hook fires when the panel is shown
    panel.refresh = function() self:Load() end

    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(cat)
        self.category = cat
    end
    self:Load()
end

-- mirror the saved values into the widgets
function Options:Load()
    if not self.checks then return end
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
/bin/zsh -lc "rg -n \"InterfaceOptions|Settings\\.|UICheckButtonTemplate|OptionsSliderTemplate|SetObeyStepOnDrag|CallAll|Refresh|SlashCmdList|/cut|PLAYER_LOGIN|PLAYER_ENTERING_WORLD|db\" ." in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
zsh:1: command not found: rg

codex
`rg` is not installed in this environment, so I’m falling back to direct file reads/search. The key shape is clear already: `options` initializes before rogue-only modules, while `CallAll` only invokes methods present on registered module tables.
exec
/bin/zsh -lc 'ls -la' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
total 152
drwxr-xr-x@ 17 creative  staff   544 Jun 27 11:16 .
drwxr-xr-x@  4 creative  staff   128 Jun 27 09:56 ..
drwxr-xr-x@ 12 creative  staff   384 Jun 27 11:11 .git
-rw-r--r--@  1 creative  staff    30 Jun 27 09:57 .gitignore
-rw-r--r--@  1 creative  staff   417 Jun 27 11:16 Cutthroat.toc
-rw-r--r--@  1 creative  staff  1069 Jun 27 10:06 LICENSE
-rw-r--r--@  1 creative  staff  2248 Jun 27 09:56 README.md
-rw-r--r--@  1 creative  staff  5917 Jun 27 11:09 alerts.lua
-rw-r--r--@  1 creative  staff  4470 Jun 27 11:16 config.lua
-rw-r--r--@  1 creative  staff  5353 Jun 27 11:09 cooldowns.lua
-rw-r--r--@  1 creative  staff  4213 Jun 27 11:16 core.lua
drwxr-xr-x@  6 creative  staff   192 Jun 27 11:11 docs
-rw-r--r--@  1 creative  staff  7781 Jun 27 11:09 hud.lua
-rw-r--r--@  1 creative  staff  4184 Jun 27 11:15 options.lua
drwxr-xr-x@ 10 creative  staff   320 Jun 27 11:16 prompts
drwxr-xr-x@  4 creative  staff   128 Jun 27 09:57 reviews
-rw-r--r--@  1 creative  staff  8994 Jun 27 11:08 timers.lua

exec
/bin/zsh -lc "sed -n '1,240p' config.lua" in /Users/creative/WoWAddons/Cutthroat
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

exec
/bin/zsh -lc "grep -RIn \"function .*Refresh\\|Refresh =\\|RegisterModule\\|SlashCmdList\\|config\\|InterfaceOptions\\|Settings\\.\\|SetObeyStepOnDrag\" ." in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua:4:local HUD = NS:RegisterModule("hud", {})
./hud.lua:187:function HUD:Refresh()
./Cutthroat.toc:15:config.lua
./timers.lua:6:local Timers = NS:RegisterModule("timers", {})
./timers.lua:24:local function HasRefreshResources(key)
./timers.lua:204:function Timers:Refresh() if self.cache then self:Scan() end end
./docs/TRIANGULATION.md:20:| 6 | Init-order comment said "hud first / config last" but config inits first | — | ✅ | ✅ **applied** | Codex doc-accuracy catch; comment corrected. |
./docs/TRIANGULATION.md:126:| 2 | Module init order via `pairs()` nondeterministic → timers/alerts may init before `hud.root` → Lua error | — | ✅ | ✅ **applied** | Codex-only. Real crash risk. core.lua now inits in explicit order (config, hud, timers, alerts). |
./docs/TRIANGULATION.md:136:| 12 | Stealth opener hint not toggleable / can mislead | ✅ | — | ✅ **applied** | GLM-only. Added `openerHint` config + `/cut opener`. |
./docs/DECISIONS.md:140:2. **core: explicit init order.** `pairs(NS.modules)` was nondeterministic; timers/alerts anchor to `hud.root`, so a bad order = load-time Lua error. Now: config → hud → timers → alerts. Codex-only catch.
./docs/DECISIONS.md:150:12. **alerts/config: stealth opener toggle.** New `openerHint` setting + `/cut opener`.
./alerts.lua:7:local Alerts = NS:RegisterModule("alerts", {})
./alerts.lua:143:function Alerts:Refresh()
./config.lua:3:local Config = NS:RegisterModule("config", {})
./config.lua:24:    print("  |cffffff00/cut config|r       open the options panel")
./config.lua:32:    SlashCmdList["CUTTHROAT"] = function(msg)
./config.lua:61:            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./config.lua:68:        elseif cmd == "config" or cmd == "options" then
./config.lua:87:function Config:Refresh() end
./README.md:37:- It works on non-rogues only for the config menu; the HUD is rogue-only.
./options.lua:4:local Options = NS:RegisterModule("options", {})
./options.lua:54:    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
./options.lua:74:    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
./options.lua:75:    if InterfaceOptions_AddCategory then
./options.lua:76:        InterfaceOptions_AddCategory(panel)
./options.lua:77:    elseif Settings and Settings.RegisterCanvasLayoutCategory then
./options.lua:78:        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
./options.lua:79:        Settings.RegisterAddOnCategory(cat)
./options.lua:94:function Options:Refresh() self:Load() end
./options.lua:96:-- open the panel (called by /cut config)
./options.lua:99:    if InterfaceOptionsFrame_OpenToCategory then
./options.lua:101:        InterfaceOptionsFrame_OpenToCategory(self.panel)
./options.lua:102:        InterfaceOptionsFrame_OpenToCategory(self.panel)
./options.lua:103:    elseif Settings and Settings.OpenToCategory and self.category then
./options.lua:104:        Settings.OpenToCategory(self.category:GetID())
./prompts/review_iter1.txt:16:config.lua
./prompts/review_iter1.txt:43:function NS:RegisterModule(name, mod)
./prompts/review_iter1.txt:95:local HUD = NS:RegisterModule("hud", {})
./prompts/review_iter1.txt:193:function HUD:Refresh()
./prompts/review_iter1.txt:208:local Timers = NS:RegisterModule("timers", {})
./prompts/review_iter1.txt:317:function Timers:Refresh() end
./prompts/review_iter1.txt:326:local Alerts = NS:RegisterModule("alerts", {})
./prompts/review_iter1.txt:453:function Alerts:Refresh()
./prompts/review_iter1.txt:457:===== FILE: config.lua =====
./prompts/review_iter1.txt:460:local Config = NS:RegisterModule("config", {})
./prompts/review_iter1.txt:483:    SlashCmdList["CUTTHROAT"] = function(msg)
./prompts/review_iter1.txt:522:function Config:Refresh() end
./prompts/review_iter3.txt:1:Review the energy regen-tick predictor just added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a thin 'spark' on the energy bar that sweeps 0->100% over the ~2s energy regen cycle and resets when energy is observed to increase, to help energy-pooling. READ-ONLY, no automation. Changed files: hud.lua (spark texture + UpdatePower gain-detection + UpdateEnergyTick), timers.lua (calls UpdateEnergyTick each render ~0.05s), config.lua (/cut spark toggle), core.lua (tickSpark default). CHECK: (1) is the 2.0s energy tick interval correct for TBC 2.5.x rogues? (2) gain-detection via positive UnitPower delta — does it falsely reset on ability-refunds/Relentless Strikes/Thistle Tea, and does that matter? (3) UnitPower/UnitPowerMax signatures + Enum.PowerType.Energy fallback to 3 in 2.5.x; (4) spark anchor math (SetPoint TOP/BOTTOM to TOPLEFT/BOTTOMLEFT with x offset) — correct & does it clip at bar ends? (5) does polling UpdatePower every 0.05s from timers:Render cause false gain-resets or perf issues? (6) behavior at energy cap / Adrenaline Rush (faster ticks); (7) any nil-safety holes (lastEnergy nil on first call). For each: file, function, bug, concrete fix. Numbered list, real bugs first.
./prompts/review_iter3.txt:7:local HUD = NS:RegisterModule("hud", {})
./prompts/review_iter3.txt:142:function HUD:Refresh()
./prompts/review_iter2.txt:9:local CDs = NS:RegisterModule("cooldowns", {})
./prompts/review_iter2.txt:127:function CDs:Refresh()
./prompts/review_iter2.txt:157:function NS:RegisterModule(name, mod)
./prompts/review_iter2.txt:184:        -- config last. pairs() order is nondeterministic, so never rely on it here.
./prompts/review_iter2.txt:189:        initModule("config") -- slash command / options work for everyone
./prompts/review_iter2.txt:225:local Timers = NS:RegisterModule("timers", {})
./prompts/review_iter6.txt:7:local HUD = NS:RegisterModule("hud", {})
./prompts/review_iter6.txt:176:function HUD:Refresh()
./prompts/review_iter5.txt:9:local Timers = NS:RegisterModule("timers", {})
./prompts/review_iter5.txt:28:local function HasRefreshResources(key)
./prompts/review_iter5.txt:199:function Timers:Refresh() if self.cache then self:Scan() end end
./prompts/review_iter4.txt:9:local Timers = NS:RegisterModule("timers", {})
./prompts/review_iter4.txt:170:function Timers:Refresh() if self.cache then self:Scan() end end
./prompts/review_iter8.txt:1:Review a NEW graphical options panel (options.lua) added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. It registers an Interface>AddOns settings panel with checkboxes for 10 boolean settings + a scale slider, wired to NS.db + NS.CallAll('Refresh'). Opened via /cut config. READ-ONLY settings UI. CRITICAL API QUESTIONS for TBC Classic 2.5.x: (1) Does InterfaceOptions_AddCategory exist and is it the CORRECT registration API for 2.5.x (vs the retail Settings.* API which I used only as a guarded fallback)? (2) Does InterfaceOptionsFrame_OpenToCategory exist in 2.5.x and is the double-call workaround correct? (3) Is UICheckButtonTemplate the right checkbox template, and is the label really at _G[name..'Text'] in 2.5.x? (4) Is OptionsSliderTemplate present in 2.5.x and are the Low/High/Text sub-regions named _G[name..'Low'/'High'/'Text']? (5) SetObeyStepOnDrag availability (I guarded it). (6) panel.name + panel.refresh hook — correct for the legacy InterfaceOptions system? (7) any issue initializing options for NON-rogue players (it inits for everyone)? (8) does the checkbox OnClick + slider OnValueChanged firing NS.CallAll('Refresh') cause problems when rogue visual modules aren't initialized (non-rogue)? Real bugs first. file/function/bug/fix. Numbered.
./prompts/review_iter8.txt:7:local Options = NS:RegisterModule("options", {})
./prompts/review_iter8.txt:57:    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
./prompts/review_iter8.txt:77:    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
./prompts/review_iter8.txt:78:    if InterfaceOptions_AddCategory then
./prompts/review_iter8.txt:79:        InterfaceOptions_AddCategory(panel)
./prompts/review_iter8.txt:80:    elseif Settings and Settings.RegisterCanvasLayoutCategory then
./prompts/review_iter8.txt:81:        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
./prompts/review_iter8.txt:82:        Settings.RegisterAddOnCategory(cat)
./prompts/review_iter8.txt:97:function Options:Refresh() self:Load() end
./prompts/review_iter8.txt:99:-- open the panel (called by /cut config)
./prompts/review_iter8.txt:102:    if InterfaceOptionsFrame_OpenToCategory then
./prompts/review_iter8.txt:104:        InterfaceOptionsFrame_OpenToCategory(self.panel)
./prompts/review_iter8.txt:105:        InterfaceOptionsFrame_OpenToCategory(self.panel)
./prompts/review_iter8.txt:106:    elseif Settings and Settings.OpenToCategory and self.category then
./prompts/review_iter8.txt:107:        Settings.OpenToCategory(self.category:GetID())
./prompts/review_iter8.txt:134:        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
./prompts/review_iter8.txt:141:        initModule("config")  -- slash commands work for everyone
./prompts/audit_iter7.txt:25:    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./prompts/audit_iter7.txt:33:function NS:RegisterModule(name, mod)
./prompts/audit_iter7.txt:60:        -- config last. pairs() order is nondeterministic, so never rely on it here.
./prompts/audit_iter7.txt:65:        initModule("config") -- slash command / options work for everyone
./prompts/audit_iter7.txt:99:local HUD = NS:RegisterModule("hud", {})
./prompts/audit_iter7.txt:270:function HUD:Refresh()
./prompts/audit_iter7.txt:285:local Timers = NS:RegisterModule("timers", {})
./prompts/audit_iter7.txt:304:local function HasRefreshResources(key)
./prompts/audit_iter7.txt:480:function Timers:Refresh() if self.cache then self:Scan() end end
./prompts/audit_iter7.txt:488:local CDs = NS:RegisterModule("cooldowns", {})
./prompts/audit_iter7.txt:627:function CDs:Refresh()
./prompts/audit_iter7.txt:638:local Alerts = NS:RegisterModule("alerts", {})
./prompts/audit_iter7.txt:773:function Alerts:Refresh()
./prompts/audit_iter7.txt:781:===== config.lua =====
./prompts/audit_iter7.txt:784:local Config = NS:RegisterModule("config", {})
./prompts/audit_iter7.txt:812:    SlashCmdList["CUTTHROAT"] = function(msg)
./prompts/audit_iter7.txt:841:            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./prompts/audit_iter7.txt:863:function Config:Refresh() end
./prompts/audit_iter7.txt:879:config.lua
./cooldowns.lua:6:local CDs = NS:RegisterModule("cooldowns", {})
./cooldowns.lua:147:function CDs:Refresh()
./.git/hooks/pre-rebase.sample:111:to be "next", but it is trivial to make it configurable via
./.git/hooks/pre-rebase.sample:112:$GIT_DIR/config mechanism.
./.git/hooks/sendemail-validate.sample:16:# The following config variables can be set to change the default remote and
./.git/hooks/sendemail-validate.sample:50:	remote=$(git config --default origin --get sendemail.validateRemote) &&
./.git/hooks/sendemail-validate.sample:51:	ref=$(git config --default HEAD --get sendemail.validateRemoteRef) &&
./.git/hooks/sendemail-validate.sample:54:	git config --replace-all sendemail.validateWorktree "$worktree"
./.git/hooks/sendemail-validate.sample:56:	worktree=$(git config --get sendemail.validateWorktree)
./.git/hooks/sendemail-validate.sample:74:	git config --unset-all sendemail.validateWorktree &&
./.git/hooks/pre-commit.sample:19:allownonascii=$(git config --type=bool hooks.allownonascii)
./.git/hooks/pre-commit.sample:43:  git config hooks.allownonascii true
./.git/hooks/fsmonitor-watchman.sample:17:# 'git config core.fsmonitor .git/hooks/query-watchman'
./.git/hooks/update.sample:46:allowunannotated=$(git config --type=bool hooks.allowunannotated)
./.git/hooks/update.sample:47:allowdeletebranch=$(git config --type=bool hooks.allowdeletebranch)
./.git/hooks/update.sample:48:denycreatebranch=$(git config --type=bool hooks.denycreatebranch)
./.git/hooks/update.sample:49:allowdeletetag=$(git config --type=bool hooks.allowdeletetag)
./.git/hooks/update.sample:50:allowmodifytag=$(git config --type=bool hooks.allowmodifytag)
./.git/hooks/push-to-checkout.sample:8:# receive.denyCurrentBranch configuration variable is set to
./core.lua:22:    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./core.lua:30:function NS:RegisterModule(name, mod)
./core.lua:67:        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
./core.lua:74:        initModule("config")  -- slash commands work for everyone
./reviews/codex/iter4.md:36:local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter4.md:197:function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter4.md:319:   167	function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter5.md:36:local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter5.md:55:local function HasRefreshResources(key)
./reviews/codex/iter5.md:226:function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter5.md:246:     6	local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter5.md:265:    25	local function HasRefreshResources(key)
./reviews/codex/iter5.md:436:   196	function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter5.md:456:./config.lua:57:            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
./reviews/codex/iter5.md:457:./config.lua:59:            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./reviews/codex/iter5.md:458:./config.lua:61:            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
./reviews/codex/iter5.md:459:./config.lua:63:            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
./reviews/codex/iter5.md:460:./config.lua:69:                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound), on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh)))
./reviews/codex/iter5.md:473:./prompts/review_iter3.txt:1:Review the energy regen-tick predictor just added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a thin 'spark' on the energy bar that sweeps 0->100% over the ~2s energy regen cycle and resets when energy is observed to increase, to help energy-pooling. READ-ONLY, no automation. Changed files: hud.lua (spark texture + UpdatePower gain-detection + UpdateEnergyTick), timers.lua (calls UpdateEnergyTick each render ~0.05s), config.lua (/cut spark toggle), core.lua (tickSpark default). CHECK: (1) is the 2.0s energy tick interval correct for TBC 2.5.x rogues? (2) gain-detection via positive UnitPower delta — does it falsely reset on ability-refunds/Relentless Strikes/Thistle Tea, and does that matter? (3) UnitPower/UnitPowerMax signatures + Enum.PowerType.Energy fallback to 3 in 2.5.x; (4) spark anchor math (SetPoint TOP/BOTTOM to TOPLEFT/BOTTOMLEFT with x offset) — correct & does it clip at bar ends? (5) does polling UpdatePower every 0.05s from timers:Render cause false gain-resets or perf issues? (6) behavior at energy cap / Adrenaline Rush (faster ticks); (7) any nil-safety holes (lastEnergy nil on first call). For each: file, function, bug, concrete fix. Numbered list, real bugs first.
./reviews/codex/iter5.md:502:./core.lua:22:    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./reviews/codex/iter5.md:528:    22	    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./reviews/codex/iter5.md:535:    29	function NS:RegisterModule(name, mod)
./reviews/codex/iter5.md:562:    56	        -- config last. pairs() order is nondeterministic, so never rely on it here.
./reviews/codex/iter5.md:567:    61	        initModule("config") -- slash command / options work for everyone
./reviews/codex/iter5.md:598:/bin/zsh -lc "nl -ba config.lua | sed -n '1,100p'" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter5.md:602:     3	local Config = NS:RegisterModule("config", {})
./reviews/codex/iter5.md:629:    30	    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter5.md:658:    59	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./reviews/codex/iter5.md:676:    77	function Config:Refresh() end
./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter1.md:43:./config.lua
./reviews/codex/iter1.md:60:     7	local Alerts = NS:RegisterModule("alerts", {})
./reviews/codex/iter1.md:187:   134	function Alerts:Refresh()
./reviews/codex/iter1.md:192:/bin/zsh -lc 'nl -ba config.lua' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter1.md:196:     3	local Config = NS:RegisterModule("config", {})
./reviews/codex/iter1.md:219:    26	    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter1.md:258:    65	function Config:Refresh() end
./reviews/codex/iter1.md:289:    25	function NS:RegisterModule(name, mod)
./reviews/codex/iter1.md:341:     4	local HUD = NS:RegisterModule("hud", {})
./reviews/codex/iter1.md:439:   102	function HUD:Refresh()
./reviews/codex/iter1.md:463:    13	config.lua
./reviews/codex/iter1.md:473:     6	local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter1.md:582:   115	function Timers:Refresh() end
./reviews/codex/iter1.md:594:/bin/zsh -lc 'grep -RInE "GetSpellCooldown|C_Spell|UnitAura|C_UnitAuras|GetWeaponEnchantInfo|GetComboPoints|UNIT_POWER|UNIT_COMBO|Register(Unit)?Event|OnUpdate|Cast|UseAction|RunScript|RunMacro" core.lua hud.lua timers.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter1.md:671:./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter1.md:705:   Fix: initialize modules in explicit order, e.g. `hud`, `timers`, `alerts`, `config`, or make dependent modules defer until `hud.root` exists.
./reviews/codex/iter1.md:709:   Fix: if `playerClass ~= "ROGUE"`, skip HUD/timer/alert init or hide/disable those modules; still allow config if desired.
./reviews/codex/iter1.md:754:   Fix: initialize modules in explicit order, e.g. `hud`, `timers`, `alerts`, `config`, or make dependent modules defer until `hud.root` exists.
./reviews/codex/iter1.md:758:   Fix: if `playerClass ~= "ROGUE"`, skip HUD/timer/alert init or hide/disable those modules; still allow config if desired.
./reviews/codex/iter8.md:14:Review the NEW options.lua (graphical settings panel) in this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. It registers an Interface>AddOns panel with checkboxes (UICheckButtonTemplate) for 10 booleans + a scale slider (OptionsSliderTemplate), wired to NS.db + NS.CallAll('Refresh'), opened via /cut config. READ-ONLY. Verify for TBC Classic 2.5.x specifically: (1) InterfaceOptions_AddCategory exists and is correct for 2.5.x (Settings.* used only as guarded fallback)? (2) InterfaceOptionsFrame_OpenToCategory exists; double-call workaround valid? (3) UICheckButtonTemplate label at _G[name..'Text']? (4) OptionsSliderTemplate sub-regions _G[name..'Low'/'High'/'Text']? (5) SetObeyStepOnDrag guarded ok? (6) panel.name/panel.refresh legacy hooks correct? (7) initializing options for non-rogue ok? (8) checkbox/slider firing NS.CallAll('Refresh') when rogue modules uninitialized (non-rogue) safe? Read options.lua and core.lua. Numbered: file/function/bug/fix. Do NOT edit. Real bugs first.
./reviews/codex/iter8.md:29:local Options = NS:RegisterModule("options", {})
./reviews/codex/iter8.md:79:    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
./reviews/codex/iter8.md:99:    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
./reviews/codex/iter8.md:100:    if InterfaceOptions_AddCategory then
./reviews/codex/iter8.md:101:        InterfaceOptions_AddCategory(panel)
./reviews/codex/iter8.md:102:    elseif Settings and Settings.RegisterCanvasLayoutCategory then
./reviews/codex/iter8.md:103:        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
./reviews/codex/iter8.md:104:        Settings.RegisterAddOnCategory(cat)
./reviews/codex/iter8.md:119:function Options:Refresh() self:Load() end
./reviews/codex/iter8.md:121:-- open the panel (called by /cut config)
./reviews/codex/iter8.md:124:    if InterfaceOptionsFrame_OpenToCategory then
./reviews/codex/iter8.md:126:        InterfaceOptionsFrame_OpenToCategory(self.panel)
./reviews/codex/iter8.md:127:        InterfaceOptionsFrame_OpenToCategory(self.panel)
./reviews/codex/iter8.md:128:    elseif Settings and Settings.OpenToCategory and self.category then
./reviews/codex/iter8.md:129:        Settings.OpenToCategory(self.category:GetID())
./reviews/codex/iter8.md:157:    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./reviews/codex/iter8.md:165:function NS:RegisterModule(name, mod)
./reviews/codex/iter8.md:202:        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
./reviews/codex/iter8.md:209:        initModule("config")  -- slash commands work for everyone
./reviews/codex/iter8.md:241:/bin/zsh -lc "rg -n \"InterfaceOptions|Settings\\.|UICheckButtonTemplate|OptionsSliderTemplate|SetObeyStepOnDrag|CallAll|Refresh|SlashCmdList|/cut|PLAYER_LOGIN|PLAYER_ENTERING_WORLD|db\" ." in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter8.md:259:-rw-r--r--@  1 creative  staff  4470 Jun 27 11:16 config.lua
./reviews/codex/iter6.md:37:local HUD = NS:RegisterModule("hud", {})
./reviews/codex/iter6.md:206:function HUD:Refresh()
./reviews/codex/iter6.md:223:     4	local HUD = NS:RegisterModule("hud", {})
./reviews/codex/iter6.md:392:   173	function HUD:Refresh()
./reviews/codex/iter6.md:440:./config.lua:21:    print("  |cffffff00/cut finish|r       toggle max-CP overcap glow")
./reviews/codex/iter6.md:441:./config.lua:61:        elseif cmd == "finish" then
./reviews/codex/iter6.md:442:./config.lua:62:            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
./reviews/codex/iter6.md:443:./config.lua:73:            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
./reviews/codex/iter6.md:444:./config.lua:74:                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
./reviews/codex/iter6.md:466:./prompts/review_iter3.txt:1:Review the energy regen-tick predictor just added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a thin 'spark' on the energy bar that sweeps 0->100% over the ~2s energy regen cycle and resets when energy is observed to increase, to help energy-pooling. READ-ONLY, no automation. Changed files: hud.lua (spark texture + UpdatePower gain-detection + UpdateEnergyTick), timers.lua (calls UpdateEnergyTick each render ~0.05s), config.lua (/cut spark toggle), core.lua (tickSpark default). CHECK: (1) is the 2.0s energy tick interval correct for TBC 2.5.x rogues? (2) gain-detection via positive UnitPower delta — does it falsely reset on ability-refunds/Relentless Strikes/Thistle Tea, and does that matter? (3) UnitPower/UnitPowerMax signatures + Enum.PowerType.Energy fallback to 3 in 2.5.x; (4) spark anchor math (SetPoint TOP/BOTTOM to TOPLEFT/BOTTOMLEFT with x offset) — correct & does it clip at bar ends? (5) does polling UpdatePower every 0.05s from timers:Render cause false gain-resets or perf issues? (6) behavior at energy cap / Adrenaline Rush (faster ticks); (7) any nil-safety holes (lastEnergy nil on first call). For each: file, function, bug, concrete fix. Numbered list, real bugs first.
./reviews/codex/iter6.md:564:./reviews/codex/iter5.md:473:./prompts/review_iter3.txt:1:Review the energy regen-tick predictor just added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a thin 'spark' on the energy bar that sweeps 0->100% over the ~2s energy regen cycle and resets when energy is observed to increase, to help energy-pooling. READ-ONLY, no automation. Changed files: hud.lua (spark texture + UpdatePower gain-detection + UpdateEnergyTick), timers.lua (calls UpdateEnergyTick each render ~0.05s), config.lua (/cut spark toggle), core.lua (tickSpark default). CHECK: (1) is the 2.0s energy tick interval correct for TBC 2.5.x rogues? (2) gain-detection via positive UnitPower delta — does it falsely reset on ability-refunds/Relentless Strikes/Thistle Tea, and does that matter? (3) UnitPower/UnitPowerMax signatures + Enum.PowerType.Energy fallback to 3 in 2.5.x; (4) spark anchor math (SetPoint TOP/BOTTOM to TOPLEFT/BOTTOMLEFT with x offset) — correct & does it clip at bar ends? (5) does polling UpdatePower every 0.05s from timers:Render cause false gain-resets or perf issues? (6) behavior at energy cap / Adrenaline Rush (faster ticks); (7) any nil-safety holes (lastEnergy nil on first call). For each: file, function, bug, concrete fix. Numbered list, real bugs first.
./reviews/codex/iter6.md:578:./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter6.md:599:./reviews/codex/iter1.md:594:/bin/zsh -lc 'grep -RInE "GetSpellCooldown|C_Spell|UnitAura|C_UnitAuras|GetWeaponEnchantInfo|GetComboPoints|UNIT_POWER|UNIT_COMBO|Register(Unit)?Event|OnUpdate|Cast|UseAction|RunScript|RunMacro" core.lua hud.lua timers.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter6.md:625:./reviews/codex/iter1.md:671:./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter6.md:691:./reviews/codex/iter2.md:1635:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter6.md:827:/bin/zsh -lc "nl -ba config.lua | sed -n '1,90p'" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter6.md:831:     3	local Config = NS:RegisterModule("config", {})
./reviews/codex/iter6.md:859:    31	    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter6.md:888:    60	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./reviews/codex/iter6.md:910:    82	function Config:Refresh() end
./reviews/codex/iter6.md:934:    22	    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./reviews/codex/iter6.md:942:    30	function NS:RegisterModule(name, mod)
./reviews/codex/iter2.md:48:local CDs = NS:RegisterModule("cooldowns", {})
./reviews/codex/iter2.md:166:function CDs:Refresh()
./reviews/codex/iter2.md:181:./config.lua
./reviews/codex/iter2.md:187:./.git/config
./reviews/codex/iter2.md:242:function NS:RegisterModule(name, mod)
./reviews/codex/iter2.md:269:        -- config last. pairs() order is nondeterministic, so never rely on it here.
./reviews/codex/iter2.md:274:        initModule("config") -- slash command / options work for everyone
./reviews/codex/iter2.md:320:config.lua
./reviews/codex/iter2.md:360:    26	function NS:RegisterModule(name, mod)
./reviews/codex/iter2.md:387:    53	        -- config last. pairs() order is nondeterministic, so never rely on it here.
./reviews/codex/iter2.md:392:    58	        initModule("config") -- slash command / options work for everyone
./reviews/codex/iter2.md:428:     6	local CDs = NS:RegisterModule("cooldowns", {})
./reviews/codex/iter2.md:546:   124	function CDs:Refresh()
./reviews/codex/iter2.md:566:    14	config.lua
./reviews/codex/iter2.md:571:/Users/creative/.config/gcloud/virtenv/lib/python3.14/site-packages/grpc/beta/interfaces.py
./reviews/codex/iter2.md:572:/Users/creative/.config/gcloud/virtenv/lib/python3.14/site-packages/grpc/beta/__pycache__/interfaces.cpython-314.pyc
./reviews/codex/iter2.md:573:/Users/creative/.config/gcloud/virtenv/lib/python3.14/site-packages/grpc/framework/interfaces
./reviews/codex/iter2.md:780:     4	local HUD = NS:RegisterModule("hud", {})
./reviews/codex/iter2.md:880:   104	function HUD:Refresh()
./reviews/codex/iter2.md:897:     6	local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter2.md:1035:   144	function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter2.md:1046:     7	local Alerts = NS:RegisterModule("alerts", {})
./reviews/codex/iter2.md:1181:   142	function Alerts:Refresh()
./reviews/codex/iter2.md:1190:/bin/zsh -lc "nl -ba config.lua | sed -n '1,240p'" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter2.md:1194:     3	local Config = NS:RegisterModule("config", {})
./reviews/codex/iter2.md:1218:    27	    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter2.md:1259:    68	function Config:Refresh() end
./reviews/codex/iter2.md:1329:local CDs = NS:RegisterModule("cooldowns", {})
./reviews/codex/iter2.md:1447:function CDs:Refresh()
./reviews/codex/iter2.md:1462:./config.lua
./reviews/codex/iter2.md:1468:./.git/config
./reviews/codex/iter2.md:1635:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter2.md:1664:./config.lua
./reviews/codex/iter2.md:1681:     7	local Alerts = NS:RegisterModule("alerts", {})
./reviews/codex/iter2.md:1808:   134	function Alerts:Refresh()
./reviews/codex/iter2.md:1813:/bin/zsh -lc 'nl -ba config.lua' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter2.md:1817:     3	local Config = NS:RegisterModule("config", {})
./reviews/codex/iter2.md:1840:    26	    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter2.md:1919:**File:** `alerts.lua` (Lines 163-172) & `config.lua`
./reviews/codex/iter2.md:1921:**Fix:** This should be a dynamically calculated hint based on position, or simply removed/gated behind a config boolean if you want to keep the UI clean. At minimum, tie it to a config setting:
./reviews/codex/iter2.md:1929:*(Note: You will need to add `openerHint = true` to `defaults` in `core.lua` and a slash command toggle in `config.lua` if you implement this).*
./reviews/codex/iter3.md:36:local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter3.md:175:function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter3.md:183:local HUD = NS:RegisterModule("hud", {})
./reviews/codex/iter3.md:318:function HUD:Refresh()
./reviews/codex/iter3.md:499:   145	function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter7.md:14:HOLISTIC CROSS-MODULE AUDIT of this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. Read ALL files: core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc. Prior reviews each saw only one file; this is the first whole-addon review. Focus on INTEGRATION issues per-file reviews miss: (a) module init order + cross-module deps (timers/cooldowns/alerts anchor to NS.modules.hud.root; core inits hud first, rogue-only); (b) event-frame proliferation/leaks/duplicate registrations across modules; (c) multiple OnUpdate loops — timers:Render @0.05s calls hud UpdateCP/UpdatePower/UpdateEnergyTick, cooldowns has its own per-frame OnUpdate checking a dirty flag — redundant/wasteful?; (d) SavedVariables defaults merge + migration when keys added across versions; (e) taint/secure-frame (verify none); (f) /reload re-init safety; (g) NS.db/NS.IsRogue gating consistency; (h) dead code, unused locals, leaked globals (missing local); (i) shared-state hazards. Then give a SHIP-READINESS verdict + a concise IN-CLIENT SMOKE-TEST CHECKLIST for a human. Numbered: file, function, issue, concrete fix. Do NOT edit files. Real issues first.
./reviews/codex/iter7.md:24:/bin/zsh -lc "pwd && rg --files -g 'core.lua' -g 'hud.lua' -g 'timers.lua' -g 'cooldowns.lua' -g 'alerts.lua' -g 'config.lua' -g 'Cutthroat.toc'" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:38:/bin/zsh -lc "find . -maxdepth 2 \\( -name core.lua -o -name hud.lua -o -name timers.lua -o -name cooldowns.lua -o -name alerts.lua -o -name config.lua -o -name Cutthroat.toc \\) -print" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:44:./config.lua
./reviews/codex/iter7.md:49:/bin/zsh -lc 'wc -l core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:56:      82 config.lua
./reviews/codex/iter7.md:88:    22	    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./reviews/codex/iter7.md:96:    30	function NS:RegisterModule(name, mod)
./reviews/codex/iter7.md:123:    57	        -- config last. pairs() order is nondeterministic, so never rely on it here.
./reviews/codex/iter7.md:128:    62	        initModule("config") -- slash command / options work for everyone
./reviews/codex/iter7.md:162:     4	local HUD = NS:RegisterModule("hud", {})
./reviews/codex/iter7.md:333:   175	function HUD:Refresh()
./reviews/codex/iter7.md:350:     6	local CDs = NS:RegisterModule("cooldowns", {})
./reviews/codex/iter7.md:489:   145	function CDs:Refresh()
./reviews/codex/iter7.md:494:/bin/zsh -lc 'nl -ba config.lua' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:498:     3	local Config = NS:RegisterModule("config", {})
./reviews/codex/iter7.md:526:    31	    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter7.md:555:    60	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./reviews/codex/iter7.md:577:    82	function Config:Refresh() end
./reviews/codex/iter7.md:587:     6	local Timers = NS:RegisterModule("timers", {})
./reviews/codex/iter7.md:606:    25	local function HasRefreshResources(key)
./reviews/codex/iter7.md:782:   201	function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter7.md:793:     7	local Alerts = NS:RegisterModule("alerts", {})
./reviews/codex/iter7.md:928:   142	function Alerts:Refresh()
./reviews/codex/iter7.md:952:    14	config.lua
./reviews/codex/iter7.md:955:The first integration pass shows the load path is mostly deliberate: TOC loads `core.lua` before modules, modules register at file load, and `PLAYER_LOGIN` initializes rogue modules after SavedVariables are assigned. I’m checking the remaining cross-module edges now: slash refresh behavior, duplicate events, and stale UI state after config toggles.
./reviews/codex/iter7.md:957:/bin/zsh -lc "grep -RIn \"RegisterEvent\\|RegisterUnitEvent\\|SetScript(\\\"OnUpdate\\|function [A-Za-z_]\\|"'^[A-Za-z_][A-Za-z0-9_]* =" core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:959:core.lua:30:function NS:RegisterModule(name, mod)
./reviews/codex/iter7.md:971:hud.lua:175:function HUD:Refresh()
./reviews/codex/iter7.md:972:timers.lua:25:local function HasRefreshResources(key)
./reviews/codex/iter7.md:980:timers.lua:201:function Timers:Refresh() if self.cache then self:Scan() end end
./reviews/codex/iter7.md:990:cooldowns.lua:145:function CDs:Refresh()
./reviews/codex/iter7.md:1009:alerts.lua:142:function Alerts:Refresh()
./reviews/codex/iter7.md:1010:config.lua:5:local function on(v) return v and "|cff20ff40on|r" or "|cffff4040off|r" end
./reviews/codex/iter7.md:1011:config.lua:7:local function Print(msg) print("|cff00ff96Cutthroat|r: " .. msg) end
./reviews/codex/iter7.md:1012:config.lua:9:local function Help()
./reviews/codex/iter7.md:1013:config.lua:28:function Config:Init()
./reviews/codex/iter7.md:1014:config.lua:82:function Config:Refresh() end
./reviews/codex/iter7.md:1017:/bin/zsh -lc "grep -RIn \"NS\\.db\\|NS\\.modules\\|NS\\.IsRogue\\|CreateFrame\\|SlashCmdList\\|_G\\[\" core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:1066:config.lua:31:    SlashCmdList["CUTTHROAT"] = function(msg)
./reviews/codex/iter7.md:1067:config.lua:32:        local db = NS.db
./reviews/codex/iter7.md:1100:6. `core.lua`, comments vs actual init order, lines 56-62: comment says “hud first” and “config last”, but code initializes `config` first.
./reviews/codex/iter7.md:1101:Runtime is okay because config needs no HUD and slash commands should work for everyone.
./reviews/codex/iter7.md:1102:Concrete fix: update the comment to say config initializes first, rogue visual modules initialize after HUD.
./reviews/codex/iter7.md:1104:7. `timers.lua`, `TRACK`, lines 10-17: `rnd = Rend` is dead config.
./reviews/codex/iter7.md:1108:8. `core.lua`, `NS:RegisterModule`, line 30: method is global on `NS`, which is intended. No accidental leaked locals found in the requested files.
./reviews/codex/iter7.md:1109:Expected globals: `CutthroatDB`, `SLASH_CUTTHROAT1`, `SLASH_CUTTHROAT2`, `SlashCmdList`.
./reviews/codex/iter7.md:1164:6. `core.lua`, comments vs actual init order, lines 56-62: comment says “hud first” and “config last”, but code initializes `config` first.
./reviews/codex/iter7.md:1165:Runtime is okay because config needs no HUD and slash commands should work for everyone.
./reviews/codex/iter7.md:1166:Concrete fix: update the comment to say config initializes first, rogue visual modules initialize after HUD.
./reviews/codex/iter7.md:1168:7. `timers.lua`, `TRACK`, lines 10-17: `rnd = Rend` is dead config.
./reviews/codex/iter7.md:1172:8. `core.lua`, `NS:RegisterModule`, line 30: method is global on `NS`, which is intended. No accidental leaked locals found in the requested files.
./reviews/codex/iter7.md:1173:Expected globals: `CutthroatDB`, `SLASH_CUTTHROAT1`, `SLASH_CUTTHROAT2`, `SlashCmdList`.
./reviews/glm/iter5.md:16:local function HasRefreshResources(key)
./reviews/glm/iter1.md:74:**File:** `alerts.lua` (Lines 163-172) & `config.lua`
./reviews/glm/iter1.md:76:**Fix:** This should be a dynamically calculated hint based on position, or simply removed/gated behind a config boolean if you want to keep the UI clean. At minimum, tie it to a config setting:
./reviews/glm/iter1.md:84:*(Note: You will need to add `openerHint = true` to `defaults` in `core.lua` and a slash command toggle in `config.lua` if you implement this).*

codex
I’ve confirmed `/cut config` routes through `config.lua` to `options:Open()`, and `core.lua` gives `NS.db` before `PLAYER_LOGIN` initializes config/options. I’m pulling line numbers now so the findings are anchored precisely.
exec
/bin/zsh -lc "nl -ba options.lua | sed -n '1,130p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba core.lua | sed -n '1,120p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- options.lua: graphical settings panel in Interface > AddOns, so you don't have
     2	-- to memorize the /cut slash toggles. Read-only over the addon's SavedVariables.
     3	local ADDON, NS = ...
     4	local Options = NS:RegisterModule("options", {})
     5	
     6	-- boolean settings -> checkbox label (order = top-to-bottom in the panel)
     7	local TOGGLES = {
     8	    { "locked",       "Lock HUD position" },
     9	    { "kickAlert",    "Kick interrupt reminder" },
    10	    { "poisonCheck",  "Poison missing warning" },
    11	    { "openerHint",   "Stealth opener hint" },
    12	    { "sound",        "Alert sounds" },
    13	    { "energyTicks",  "Energy 20-mark lines (reload to apply)" },
    14	    { "tickSpark",    "Energy regen-tick spark" },
    15	    { "refreshZone",  "Refresh-now marker on bars" },
    16	    { "smartRefresh", "Green only when CP/energy ready" },
    17	    { "cpFinishGlow", "Max-CP overcap glow" },
    18	}
    19	
    20	function Options:Init()
    21	    if self.panel then return end -- idempotent
    22	    local panel = CreateFrame("Frame", "CutthroatOptions", UIParent)
    23	    panel.name = "Cutthroat"
    24	    self.panel = panel
    25	
    26	    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    27	    title:SetPoint("TOPLEFT", 16, -16)
    28	    title:SetText("Cutthroat |cff00ff96Rogue|r")
    29	    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    30	    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    31	    sub:SetText("Ban-safe HUD + alerts. Changes apply instantly.")
    32	
    33	    self.checks = {}
    34	    local y = -64
    35	    for _, t in ipairs(TOGGLES) do
    36	        local key, label = t[1], t[2]
    37	        local cb = CreateFrame("CheckButton", "CutthroatOpt_" .. key, panel, "UICheckButtonTemplate")
    38	        cb:SetPoint("TOPLEFT", 16, y)
    39	        local txt = _G[cb:GetName() .. "Text"]
    40	        if txt then txt:SetText(label) end
    41	        cb:SetScript("OnClick", function(b)
    42	            NS.db[key] = b:GetChecked() and true or false
    43	            NS.CallAll("Refresh")
    44	        end)
    45	        self.checks[key] = cb
    46	        y = y - 28
    47	    end
    48	
    49	    -- scale slider (uses the legacy OptionsSliderTemplate, present in 2.5.x)
    50	    local s = CreateFrame("Slider", "CutthroatOptScale", panel, "OptionsSliderTemplate")
    51	    s:SetPoint("TOPLEFT", 20, y - 20)
    52	    s:SetMinMaxValues(0.4, 3.0)
    53	    s:SetValueStep(0.05)
    54	    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    55	    s:SetWidth(220)
    56	    local sn = s:GetName()
    57	    if _G[sn .. "Low"] then _G[sn .. "Low"]:SetText("0.4") end
    58	    if _G[sn .. "High"] then _G[sn .. "High"]:SetText("3.0") end
    59	    s:SetScript("OnValueChanged", function(sl, v)
    60	        v = math.floor(v * 20 + 0.5) / 20 -- snap to 0.05
    61	        if _G[sl:GetName() .. "Text"] then
    62	            _G[sl:GetName() .. "Text"]:SetText(string.format("Scale: %.2f", v))
    63	        end
    64	        if NS.db.scale ~= v then
    65	            NS.db.scale = v
    66	            NS.CallAll("Refresh")
    67	        end
    68	    end)
    69	    self.scale = s
    70	
    71	    -- legacy Interface Options "refresh" hook fires when the panel is shown
    72	    panel.refresh = function() self:Load() end
    73	
    74	    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
    75	    if InterfaceOptions_AddCategory then
    76	        InterfaceOptions_AddCategory(panel)
    77	    elseif Settings and Settings.RegisterCanvasLayoutCategory then
    78	        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    79	        Settings.RegisterAddOnCategory(cat)
    80	        self.category = cat
    81	    end
    82	    self:Load()
    83	end
    84	
    85	-- mirror the saved values into the widgets
    86	function Options:Load()
    87	    if not self.checks then return end
    88	    for key, cb in pairs(self.checks) do
    89	        cb:SetChecked(NS.db[key] and true or false)
    90	    end
    91	    if self.scale then self.scale:SetValue(NS.db.scale or 1.0) end
    92	end
    93	
    94	function Options:Refresh() self:Load() end
    95	
    96	-- open the panel (called by /cut config)
    97	function Options:Open()
    98	    if not self.panel then return end
    99	    if InterfaceOptionsFrame_OpenToCategory then
   100	        -- Blizzard bug: first call sometimes lands on the wrong page; call twice
   101	        InterfaceOptionsFrame_OpenToCategory(self.panel)
   102	        InterfaceOptionsFrame_OpenToCategory(self.panel)
   103	    elseif Settings and Settings.OpenToCategory and self.category then
   104	        Settings.OpenToCategory(self.category:GetID())
   105	    end
   106	end

 succeeded in 0ms:
     1	-- Cutthroat: Rogue helper for TBC Classic (2.5.x)
     2	-- Pure read/display. No spell input automation (Warden-safe).
     3	
     4	local ADDON, NS = ...
     5	NS.name = "Cutthroat"
     6	NS.modules = {}
     7	
     8	-- ---- Saved variable defaults ----
     9	local defaults = {
    10	    locked = false,
    11	    scale = 1.0,
    12	    point = { "CENTER", nil, "CENTER", 0, -180 },
    13	    sndWarn = 3,        -- seconds left on Slice and Dice before warning
    14	    ruptureWarn = 2,    -- seconds left on Rupture before warning
    15	    kickAlert = true,   -- flash when target casts an interruptible spell + Kick ready
    16	    poisonCheck = true, -- warn when a weapon is missing poison out of combat
    17	    openerHint = true,  -- show "Ambush / Garrote" hint when stealthed w/ target
    18	    sound = true,
    19	    energyTicks = true, -- show 20-energy tick marks
    20	    tickSpark = true,   -- moving spark = progress to next ~2s energy regen tick
    21	    refreshZone = true, -- mark the "refresh now" window near expiry on SnD/DoT bars
    22	    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
    23	    cpFinishGlow = true,-- pulse the combo pips at max CP (don't overcap -> finish)
    24	}
    25	
    26	-- ---- Class gate ----
    27	local _, playerClass = UnitClass("player")
    28	
    29	-- ---- Module registration ----
    30	function NS:RegisterModule(name, mod)
    31	    self.modules[name] = mod
    32	    return mod
    33	end
    34	
    35	local function CallAll(method, ...)
    36	    for _, mod in pairs(NS.modules) do
    37	        if mod[method] then mod[method](mod, ...) end
    38	    end
    39	end
    40	NS.CallAll = CallAll
    41	
    42	-- ---- Event hub ----
    43	local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
    44	f:RegisterEvent("ADDON_LOADED")
    45	f:RegisterEvent("PLAYER_LOGIN")
    46	f:SetScript("OnEvent", function(self, event, arg1)
    47	    if event == "ADDON_LOADED" and arg1 == ADDON then
    48	        CutthroatDB = CutthroatDB or {}
    49	        for k, v in pairs(defaults) do
    50	            if CutthroatDB[k] == nil then
    51	                CutthroatDB[k] = (type(v) == "table") and CopyTable(v) or v
    52	            end
    53	        end
    54	        -- Sanitize the values the HUD trusts, in case the save is corrupted. NOTE:
    55	        -- point[2] is intentionally nil (relativeTo=UIParent), so validate fields by
    56	        -- index — never use #point (a nil hole makes the length operator unreliable).
    57	        local p = CutthroatDB.point
    58	        if type(p) ~= "table" or type(p[1]) ~= "string" or type(p[3]) ~= "string"
    59	            or type(p[4]) ~= "number" or type(p[5]) ~= "number" then
    60	            CutthroatDB.point = CopyTable(defaults.point)
    61	        end
    62	        if type(CutthroatDB.scale) ~= "number" or CutthroatDB.scale < 0.4 or CutthroatDB.scale > 3 then
    63	            CutthroatDB.scale = defaults.scale
    64	        end
    65	        NS.db = CutthroatDB
    66	    elseif event == "PLAYER_LOGIN" then
    67	        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
    68	        -- works for everyone, then the rogue-only visual modules — hud BEFORE
    69	        -- timers/cooldowns/alerts, which all anchor to hud.root.
    70	        local function initModule(name)
    71	            local m = NS.modules[name]
    72	            if m and m.Init then m:Init() end
    73	        end
    74	        initModule("config")  -- slash commands work for everyone
    75	        initModule("options") -- graphical settings panel works for everyone
    76	        if playerClass == "ROGUE" then
    77	            initModule("hud")
    78	            initModule("timers")
    79	            initModule("cooldowns")
    80	            initModule("alerts")
    81	            CallAll("Refresh")
    82	        else
    83	            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.")
    84	        end
    85	        -- TBC 2.5.x exposes the global GetAddOnMetadata; C_AddOns is a newer wrapper.
    86	        local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
    87	            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
    88	            or "1.0.0"
    89	        print("|cff00ff96Cutthroat|r v" .. ver .. " loaded. |cffffff00/cut|r for options.")
    90	    end
    91	end)
    92	
    93	NS.IsRogue = (playerClass == "ROGUE")
    94	
    95	-- shared color helpers
    96	NS.color = {
    97	    energy  = { 1.0, 0.85, 0.20 },
    98	    cp      = { 1.0, 0.20, 0.20 },
    99	    good    = { 0.20, 1.0, 0.40 },
   100	    warn    = { 1.0, 0.55, 0.10 },
   101	    bad     = { 1.0, 0.15, 0.15 },
   102	    dim     = { 0.45, 0.45, 0.45 },
   103	}

exec
/bin/zsh -lc "nl -ba config.lua | sed -n '24,92p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
    24	    print("  |cffffff00/cut config|r       open the options panel")
    25	    print("  |cffffff00/cut reset|r        reset position")
    26	    print("  |cffffff00/cut status|r       show settings")
    27	end
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
    87	function Config:Refresh() end

exec
/bin/zsh -lc "nl -ba Cutthroat.toc | sed -n '1,40p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	## Interface: 20504
     2	## Title: Cutthroat |cff00ff96Rogue|r
     3	## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
     4	## Author: Cutthroat
     5	## Version: 1.7.0
     6	## SavedVariables: CutthroatDB
     7	## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate
     8	
     9	core.lua
    10	hud.lua
    11	timers.lua
    12	cooldowns.lua
    13	alerts.lua
    14	options.lua
    15	config.lua

codex
The API questions look clean for 2.5.x. The only thing I’m treating as a real behavioral risk is not the legacy Interface Options wiring, but refresh side effects from option changes, especially on non-rogues and during slider drag.
exec
/bin/zsh -lc "nl -ba hud.lua | sed -n '170,205p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '196,208p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
   196	                b:SetStatusBarColor(unpack(green and NS.color.good or b.baseColor))
   197	            end
   198	
   199	            if not b:IsShown() then b:Show() end
   200	        end
   201	    end
   202	end
   203	
   204	function Timers:Refresh() if self.cache then self:Scan() end end

 succeeded in 0ms:
   170	        self.shownCP = cp
   171	        for i = 1, MAX_CP do
   172	            self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
   173	        end
   174	    end
   175	    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
   176	    local g = self.cpGlow
   177	    if g then
   178	        if cp >= MAX_CP and NS.db.cpFinishGlow then
   179	            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
   180	            if not g:IsShown() then g:Show() end
   181	        elseif g:IsShown() then
   182	            g:Hide()
   183	        end
   184	    end
   185	end
   186	
   187	function HUD:Refresh()
   188	    if not self.root then return end
   189	    self.root:SetScale(NS.db.scale)
   190	    self.root:EnableMouse(not NS.db.locked)
   191	    self.root.bg:SetShown(not NS.db.locked)
   192	    self:UpdatePower()
   193	    self:UpdateCP()
   194	end

exec
/bin/zsh -lc "nl -ba cooldowns.lua | sed -n '142,152p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
   142	            end
   143	        end
   144	    end
   145	end
   146	
   147	function CDs:Refresh()
   148	    if self.icons then self:RebuildKnown(); self:Relayout() end
   149	end

exec
/bin/zsh -lc "nl -ba alerts.lua | sed -n '138,148p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
   138	    else
   139	        self.opener:Hide()
   140	    end
   141	end
   142	
   143	function Alerts:Refresh()
   144	    if self.kick then self.kick:Hide() end
   145	    if NS.IsRogue then
   146	        self:CheckPoison()  -- hides itself if disabled / in combat
   147	        self:CheckOpener()  -- hides itself if disabled
   148	    end

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

No blocking TBC Classic 2.5.x API bugs found in `options.lua`.

1. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:59), `Options:Init`, minor perf risk: slider `OnValueChanged` calls `NS.CallAll("Refresh")` on every snapped value during drag. This is safe, but can cause repeated HUD/timer refresh work while dragging.
   Fix: only refresh on mouse release, or throttle. Keep label live if desired.

2. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:75), `Options:Init`, bug: none for 2.5.x. `InterfaceOptions_AddCategory(panel)` is the correct legacy API for Interface 20504. The guarded `Settings.*` branch is not used in TBC.
   Fix: none required. If keeping the retail fallback, also guard `Settings.RegisterAddOnCategory`.

3. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:99), `Options:Open`, bug: none. `InterfaceOptionsFrame_OpenToCategory` exists in TBC Classic 2.5.x, and calling it twice is a valid common workaround for Blizzard’s legacy category-selection weirdness.
   Fix: none.

4. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:37), `Options:Init`, bug: none. `UICheckButtonTemplate` is right, and the label global at `_G[name .. "Text"]` is correct for this template.
   Fix: none.

5. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:50), `Options:Init`, bug: none. `OptionsSliderTemplate` and `_G[name.."Low"]`, `_G[name.."High"]`, `_G[name.."Text"]` are the expected legacy subregions.
   Fix: none.

6. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:54), `Options:Init`, bug: none. `SetObeyStepOnDrag` is safely guarded.
   Fix: none.

7. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:23), `Options:Init`, bug: none. `panel.name` and `panel.refresh` are correct legacy Interface Options hooks.
   Fix: none.

8. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:74), `PLAYER_LOGIN` init path, bug: none. Initializing config/options for non-rogues is okay; rogue visuals are skipped.
   Fix: none.

9. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:35), `NS.CallAll`, bug: none for non-rogues. Uninitialized rogue module `Refresh` methods are nil-safe: HUD checks `root`, timers checks `cache`, cooldowns checks `icons`, alerts gates rogue work with `NS.IsRogue`.
   Fix: none.

Read-only review only; no files edited.
tokens used
36,311
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

No blocking TBC Classic 2.5.x API bugs found in `options.lua`.

1. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:59), `Options:Init`, minor perf risk: slider `OnValueChanged` calls `NS.CallAll("Refresh")` on every snapped value during drag. This is safe, but can cause repeated HUD/timer refresh work while dragging.
   Fix: only refresh on mouse release, or throttle. Keep label live if desired.

2. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:75), `Options:Init`, bug: none for 2.5.x. `InterfaceOptions_AddCategory(panel)` is the correct legacy API for Interface 20504. The guarded `Settings.*` branch is not used in TBC.
   Fix: none required. If keeping the retail fallback, also guard `Settings.RegisterAddOnCategory`.

3. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:99), `Options:Open`, bug: none. `InterfaceOptionsFrame_OpenToCategory` exists in TBC Classic 2.5.x, and calling it twice is a valid common workaround for Blizzard’s legacy category-selection weirdness.
   Fix: none.

4. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:37), `Options:Init`, bug: none. `UICheckButtonTemplate` is right, and the label global at `_G[name .. "Text"]` is correct for this template.
   Fix: none.

5. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:50), `Options:Init`, bug: none. `OptionsSliderTemplate` and `_G[name.."Low"]`, `_G[name.."High"]`, `_G[name.."Text"]` are the expected legacy subregions.
   Fix: none.

6. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:54), `Options:Init`, bug: none. `SetObeyStepOnDrag` is safely guarded.
   Fix: none.

7. [options.lua](/Users/creative/WoWAddons/Cutthroat/options.lua:23), `Options:Init`, bug: none. `panel.name` and `panel.refresh` are correct legacy Interface Options hooks.
   Fix: none.

8. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:74), `PLAYER_LOGIN` init path, bug: none. Initializing config/options for non-rogues is okay; rogue visuals are skipped.
   Fix: none.

9. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:35), `NS.CallAll`, bug: none for non-rogues. Uninitialized rogue module `Refresh` methods are nil-safe: HUD checks `root`, timers checks `cache`, cooldowns checks `icons`, alerts gates rogue work with `NS.IsRogue`.
   Fix: none.

Read-only review only; no files edited.
