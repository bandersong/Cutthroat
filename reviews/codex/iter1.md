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
session id: 019f095f-4d63-73a3-9a27-a23d06170a76
--------
user
Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll do this as a read-only code review: first map the requested files and line numbers, then verify API-sensitive spots against TBC 2.5.x expectations and report only concrete risks.
exec
/bin/zsh -lc 'pwd && rg --files' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

exec
/bin/zsh -lc 'git status --short' in /Users/creative/WoWAddons/Cutthroat
 exited 128 in 0ms:
fatal: not a git repository (or any of the parent directories): .git

codex
`rg` is not installed here, so I’m falling back to basic shell reads. This directory also is not a git repo, which is fine for a read-only review.
exec
/bin/zsh -lc 'find . -maxdepth 2 -type f | sort' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./.gitignore
./Cutthroat.toc
./README.md
./alerts.lua
./config.lua
./core.lua
./docs/DECISIONS.md
./docs/TRIANGULATION.md
./hud.lua
./prompts/review_iter1.txt
./timers.lua

exec
/bin/zsh -lc 'nl -ba alerts.lua' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Alerts: reactive reminders. ALERTS ONLY — never casts/queues a spell (Warden-safe).
     2	--   * Kick reminder: target is casting an interruptible spell AND Kick is off CD -> flash icon.
     3	--   * Poison check: out of combat, MH/OH missing a weapon enchant -> reminder text.
     4	--   * Stealth opener: in stealth with a target -> show Ambush/Garrote hint.
     5	
     6	local ADDON, NS = ...
     7	local Alerts = NS:RegisterModule("alerts", {})
     8	
     9	local KICK = GetSpellInfo and GetSpellInfo(1766) or "Kick" -- localized name
    10	
    11	local function SpellReady(name)
    12	    if not name then return false end
    13	    local start, dur = GetSpellCooldown(name)
    14	    if not start then return false end
    15	    return (start == 0) or (start + dur - GetTime() <= 0.2)
    16	end
    17	
    18	function Alerts:Init()
    19	    local root = NS.modules.hud.root
    20	
    21	    -- ---- Kick flash icon (center, above HUD) ----
    22	    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
    23	    kick:SetSize(64, 64)
    24	    kick:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    25	    kick.icon = kick:CreateTexture(nil, "ARTWORK")
    26	    kick.icon:SetAllPoints()
    27	    kick.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    28	    kick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    29	    kick.txt = kick:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    30	    kick.txt:SetPoint("TOP", kick, "BOTTOM", 0, -2)
    31	    kick.txt:SetText("KICK!")
    32	    kick.txt:SetTextColor(unpack(NS.color.bad))
    33	    kick:Hide()
    34	    -- pulse
    35	    local ag = kick:CreateAnimationGroup()
    36	    ag:SetLooping("BOUNCE")
    37	    local a = ag:CreateAnimation("Alpha")
    38	    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    39	    kick.ag = ag
    40	    self.kick = kick
    41	
    42	    -- ---- Poison reminder text ----
    43	    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    44	    pz:SetPoint("BOTTOM", root, "TOP", 0, 6)
    45	    pz:SetTextColor(unpack(NS.color.warn))
    46	    pz:Hide()
    47	    self.poison = pz
    48	
    49	    -- ---- Stealth opener hint ----
    50	    local op = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    51	    op:SetPoint("BOTTOM", root, "TOP", 0, 28)
    52	    op:SetTextColor(unpack(NS.color.good))
    53	    op:Hide()
    54	    self.opener = op
    55	
    56	    local ev = CreateFrame("Frame")
    57	    ev:RegisterEvent("UNIT_SPELLCAST_START")
    58	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    59	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
    60	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    61	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    62	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    63	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
    64	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
    65	    ev:RegisterEvent("UPDATE_STEALTH")
    66	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    67	    ev:SetScript("OnEvent", function(_, e, unit) Alerts:OnEvent(e, unit) end)
    68	    self.ev = ev
    69	end
    70	
    71	function Alerts:OnEvent(e, unit)
    72	    if not NS.IsRogue then return end
    73	    if e == "PLAYER_REGEN_ENABLED" then
    74	        self:CheckPoison()
    75	    elseif e == "PLAYER_REGEN_DISABLED" then
    76	        self.poison:Hide()
    77	    elseif e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" then
    78	        self:CheckOpener()
    79	    end
    80	    -- Kick logic on any cast event affecting the target
    81	    self:CheckKick(e, unit)
    82	end
    83	
    84	function Alerts:CheckKick(e, unit)
    85	    if not NS.db.kickAlert then return end
    86	    if unit ~= "target" then
    87	        -- still re-evaluate on target change / cooldown updates
    88	        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
    89	    end
    90	    local casting = false
    91	    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    92	    if not name then
    93	        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
    94	    end
    95	    if name and not notInterruptible then casting = true end
    96	
    97	    if casting and SpellReady(KICK) then
    98	        if not self.kick:IsShown() then
    99	            self.kick:Show(); self.kick.ag:Play()
   100	            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
   101	        end
   102	    else
   103	        if self.kick:IsShown() then self.kick.ag:Stop(); self.kick:Hide() end
   104	    end
   105	end
   106	
   107	function Alerts:CheckPoison()
   108	    if not NS.db.poisonCheck then return end
   109	    -- TBC 2.5 sig: hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges (no enchantID)
   110	    local mh, _, _, oh = GetWeaponEnchantInfo()
   111	    local missing = {}
   112	    if not mh then missing[#missing + 1] = "Main-hand" end
   113	    -- only warn off-hand if one is equipped
   114	    if GetInventoryItemLink("player", 17) and not oh then missing[#missing + 1] = "Off-hand" end
   115	    if #missing > 0 then
   116	        self.poison:SetText("No poison: " .. table.concat(missing, " & "))
   117	        self.poison:Show()
   118	    else
   119	        self.poison:Hide()
   120	    end
   121	end
   122	
   123	function Alerts:CheckOpener()
   124	    local stealthed = IsStealthed and IsStealthed()
   125	    if stealthed and UnitExists("target") and UnitCanAttack("player", "target") then
   126	        local behind = "" -- can't reliably detect facing; suggest both
   127	        self.opener:SetText("Opener: Ambush / Garrote")
   128	        self.opener:Show()
   129	    else
   130	        self.opener:Hide()
   131	    end
   132	end
   133	
   134	function Alerts:Refresh()
   135	    if self.kick then self.kick:Hide() end
   136	end

exec
/bin/zsh -lc 'nl -ba config.lua' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Config: /cut slash command. Minimal, no external libs.
     2	local ADDON, NS = ...
     3	local Config = NS:RegisterModule("config", {})
     4	
     5	local function on(v) return v and "|cff20ff40on|r" or "|cffff4040off|r" end
     6	
     7	local function Print(msg) print("|cff00ff96Cutthroat|r: " .. msg) end
     8	
     9	local function Help()
    10	    Print("commands:")
    11	    print("  |cffffff00/cut lock|r        toggle move/lock HUD")
    12	    print("  |cffffff00/cut scale N|r      set scale (e.g. 0.9)")
    13	    print("  |cffffff00/cut kick|r         toggle Kick reminder")
    14	    print("  |cffffff00/cut poison|r       toggle poison check")
    15	    print("  |cffffff00/cut sound|r        toggle alert sounds")
    16	    print("  |cffffff00/cut ticks|r        toggle energy tick marks")
    17	    print("  |cffffff00/cut snd N|r        SnD warning seconds")
    18	    print("  |cffffff00/cut rup N|r        Rupture warning seconds")
    19	    print("  |cffffff00/cut reset|r        reset position")
    20	    print("  |cffffff00/cut status|r       show settings")
    21	end
    22	
    23	function Config:Init()
    24	    SLASH_CUTTHROAT1 = "/cut"
    25	    SLASH_CUTTHROAT2 = "/cutthroat"
    26	    SlashCmdList["CUTTHROAT"] = function(msg)
    27	        local db = NS.db
    28	        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    29	        cmd = (cmd or ""):lower()
    30	
    31	        if cmd == "" or cmd == "help" then
    32	            Help()
    33	        elseif cmd == "lock" then
    34	            db.locked = not db.locked
    35	            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
    36	        elseif cmd == "scale" then
    37	            local n = tonumber(arg)
    38	            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
    39	            else Print("scale needs 0.4-3.0") end
    40	        elseif cmd == "kick" then
    41	            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
    42	        elseif cmd == "poison" then
    43	            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
    44	        elseif cmd == "sound" then
    45	            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
    46	        elseif cmd == "ticks" then
    47	            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
    48	        elseif cmd == "snd" then
    49	            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
    50	        elseif cmd == "rup" then
    51	            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
    52	        elseif cmd == "reset" then
    53	            db.point = { "CENTER", nil, "CENTER", 0, -180 }
    54	            Print("position reset (/reload to apply)")
    55	        elseif cmd == "status" then
    56	            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | sound %s | ticks %s",
    57	                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.sound), on(db.energyTicks)))
    58	        else
    59	            Help()
    60	        end
    61	        NS.CallAll("Refresh")
    62	    end
    63	end
    64	
    65	function Config:Refresh() end

exec
/bin/zsh -lc 'nl -ba core.lua' in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc 'nl -ba hud.lua' in /Users/creative/WoWAddons/Cutthroat
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
    17	    sound = true,
    18	    energyTicks = true, -- show 20-energy tick marks
    19	}
    20	
    21	-- ---- Class gate ----
    22	local _, playerClass = UnitClass("player")
    23	
    24	-- ---- Module registration ----
    25	function NS:RegisterModule(name, mod)
    26	    self.modules[name] = mod
    27	    return mod
    28	end
    29	
    30	local function CallAll(method, ...)
    31	    for _, mod in pairs(NS.modules) do
    32	        if mod[method] then mod[method](mod, ...) end
    33	    end
    34	end
    35	NS.CallAll = CallAll
    36	
    37	-- ---- Event hub ----
    38	local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
    39	f:RegisterEvent("ADDON_LOADED")
    40	f:RegisterEvent("PLAYER_LOGIN")
    41	f:SetScript("OnEvent", function(self, event, arg1)
    42	    if event == "ADDON_LOADED" and arg1 == ADDON then
    43	        CutthroatDB = CutthroatDB or {}
    44	        for k, v in pairs(defaults) do
    45	            if CutthroatDB[k] == nil then
    46	                CutthroatDB[k] = (type(v) == "table") and CopyTable(v) or v
    47	            end
    48	        end
    49	        NS.db = CutthroatDB
    50	    elseif event == "PLAYER_LOGIN" then
    51	        if playerClass ~= "ROGUE" then
    52	            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. /cut to view options.")
    53	        end
    54	        CallAll("Init")
    55	        CallAll("Refresh")
    56	        print("|cff00ff96Cutthroat|r v" .. (C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "1.0.0") ..
    57	              " loaded. |cffffff00/cut|r for options.")
    58	    end
    59	end)
    60	
    61	NS.IsRogue = (playerClass == "ROGUE")
    62	
    63	-- shared color helpers
    64	NS.color = {
    65	    energy  = { 1.0, 0.85, 0.20 },
    66	    cp      = { 1.0, 0.20, 0.20 },
    67	    good    = { 0.20, 1.0, 0.40 },
    68	    warn    = { 1.0, 0.55, 0.10 },
    69	    bad     = { 1.0, 0.15, 0.15 },
    70	    dim     = { 0.45, 0.45, 0.45 },
    71	}

 succeeded in 0ms:
     1	-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
     2	local ADDON, NS = ...
     3	
     4	local HUD = NS:RegisterModule("hud", {})
     5	
     6	local WIDTH, HEIGHT = 240, 18
     7	local CP_SIZE, CP_GAP = 22, 6
     8	local MAX_CP = 5
     9	
    10	function HUD:Init()
    11	    local db = NS.db
    12	
    13	    -- root anchor (movable)
    14	    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
    15	    root:SetSize(WIDTH, HEIGHT + CP_SIZE + 8)
    16	    root:SetScale(db.scale)
    17	    local p = db.point
    18	    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
    19	    root:SetMovable(true)
    20	    root:EnableMouse(not db.locked)
    21	    root:RegisterForDrag("LeftButton")
    22	    root:SetScript("OnDragStart", function(s) if not NS.db.locked then s:StartMoving() end end)
    23	    root:SetScript("OnDragStop", function(s)
    24	        s:StopMovingOrSizing()
    25	        local a, _, rp, x, y = s:GetPoint()
    26	        NS.db.point = { a, nil, rp, x, y }
    27	    end)
    28	    self.root = root
    29	
    30	    -- drag hint backdrop (only when unlocked)
    31	    root.bg = root:CreateTexture(nil, "BACKGROUND")
    32	    root.bg:SetAllPoints()
    33	    root.bg:SetColorTexture(0, 0, 0, 0.25)
    34	
    35	    -- ---- Energy bar ----
    36	    local energy = CreateFrame("StatusBar", nil, root)
    37	    energy:SetSize(WIDTH, HEIGHT)
    38	    energy:SetPoint("TOP", root, "TOP", 0, 0)
    39	    energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    40	    energy:SetStatusBarColor(unpack(NS.color.energy))
    41	    energy:SetMinMaxValues(0, 100)
    42	    energy.bg = energy:CreateTexture(nil, "BACKGROUND")
    43	    energy.bg:SetAllPoints()
    44	    energy.bg:SetColorTexture(0.12, 0.10, 0.0, 0.85)
    45	    energy.text = energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    46	    energy.text:SetPoint("CENTER")
    47	    self.energy = energy
    48	
    49	    -- 20-energy tick marks
    50	    energy.ticks = {}
    51	    if db.energyTicks then
    52	        for i = 1, 4 do
    53	            local t = energy:CreateTexture(nil, "OVERLAY")
    54	            t:SetColorTexture(0, 0, 0, 0.6)
    55	            t:SetSize(1, HEIGHT)
    56	            t:SetPoint("LEFT", energy, "LEFT", WIDTH * (i * 20 / 100), 0)
    57	            energy.ticks[i] = t
    58	        end
    59	    end
    60	
    61	    -- ---- Combo point pips ----
    62	    self.pips = {}
    63	    local totalW = MAX_CP * CP_SIZE + (MAX_CP - 1) * CP_GAP
    64	    local startX = (WIDTH - totalW) / 2
    65	    for i = 1, MAX_CP do
    66	        local pip = root:CreateTexture(nil, "ARTWORK")
    67	        pip:SetSize(CP_SIZE, CP_SIZE)
    68	        pip:SetPoint("TOPLEFT", root, "TOPLEFT", startX + (i - 1) * (CP_SIZE + CP_GAP), -(HEIGHT + 6))
    69	        pip:SetTexture("Interface\\ComboFrame\\ComboPoint")
    70	        pip:SetTexCoord(0, 0.375, 0, 1) -- the lit gem
    71	        pip:SetVertexColor(unpack(NS.color.cp))
    72	        pip:SetAlpha(0.15)
    73	        self.pips[i] = pip
    74	    end
    75	
    76	    -- event-driven updates (cheap; no OnUpdate polling for power)
    77	    local ev = CreateFrame("Frame")
    78	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    79	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    80	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    81	    ev:RegisterEvent("UNIT_POWER_UPDATE")
    82	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
    83	    self.ev = ev
    84	end
    85	
    86	function HUD:UpdatePower()
    87	    if not self.energy then return end
    88	    local e = UnitPower("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
    89	    local m = UnitPowerMax("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
    90	    self.energy:SetMinMaxValues(0, m > 0 and m or 100)
    91	    self.energy:SetValue(e)
    92	    self.energy.text:SetText(e)
    93	end
    94	
    95	function HUD:UpdateCP()
    96	    local cp = GetComboPoints("player", "target") or 0
    97	    for i = 1, MAX_CP do
    98	        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
    99	    end
   100	end
   101	
   102	function HUD:Refresh()
   103	    if not self.root then return end
   104	    self.root:SetScale(NS.db.scale)
   105	    self.root:EnableMouse(not NS.db.locked)
   106	    self.root.bg:SetShown(not NS.db.locked)
   107	    self:UpdatePower()
   108	    self:UpdateCP()
   109	end

exec
/bin/zsh -lc 'nl -ba Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	## Interface: 20504
     2	## Title: Cutthroat |cff00ff96Rogue|r
     3	## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
     4	## Author: Cutthroat
     5	## Version: 1.0.0
     6	## SavedVariables: CutthroatDB
     7	## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate
     8	
     9	core.lua
    10	hud.lua
    11	timers.lua
    12	alerts.lua
    13	config.lua

exec
/bin/zsh -lc 'nl -ba timers.lua' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Timers: track YOUR finisher durations on the current target via combat log.
     2	-- Slice and Dice (self buff) + Rupture / Expose Armor / Garrote (target debuffs).
     3	-- Uses CLEU for application/refresh so it works pre-2.5 aura APIs reliably.
     4	
     5	local ADDON, NS = ...
     6	local Timers = NS:RegisterModule("timers", {})
     7	
     8	-- spellID -> { label, base, perCP (optional) }  durations are *max* (5cp) approximations;
     9	-- we read the real remaining time from auras when possible, CLEU is the fallback.
    10	local TRACK = {
    11	    -- Slice and Dice ranks share name; track by name (self buff)
    12	    snd = { name = "Slice and Dice", isSelf = true,  color = "good" },
    13	    rup = { name = "Rupture",        isSelf = false, color = "bad"  },
    14	    exp = { name = "Expose Armor",   isSelf = false, color = "warn" },
    15	    gar = { name = "Garrote",        isSelf = false, color = "bad"  },
    16	    rnd = { name = "Rend",           isSelf = false, color = "warn" }, -- harmless if unused
    17	}
    18	
    19	local BAR_W, BAR_H = 200, 14
    20	local active = {}  -- key -> { expires=, duration= }
    21	
    22	local function GetAuraRemaining(unit, name, byPlayer)
    23	    -- try modern C_UnitAuras first, fall back to UnitAura loop
    24	    for i = 1, 40 do
    25	        local n, _, _, _, dur, exp, source
    26	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    27	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
    28	            if not d then
    29	                -- also check helpful for self buffs
    30	                d = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|PLAYER")
    31	            end
    32	            if not d then break end
    33	            n, dur, exp = d.name, d.duration, d.expirationTime
    34	        else
    35	            n, _, _, _, dur, exp, source = UnitAura(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
    36	            if not n then break end
    37	        end
    38	        if n == name then
    39	            if exp and exp > 0 then return exp - GetTime(), dur end
    40	        end
    41	    end
    42	    return nil
    43	end
    44	
    45	function Timers:Init()
    46	    local root = NS.modules.hud.root
    47	    self.bars = {}
    48	    local order = { "snd", "rup", "exp", "gar" }
    49	    local y = -(18 + 6 + 22 + 10) -- below the CP pips
    50	    for idx, key in ipairs(order) do
    51	        local b = CreateFrame("StatusBar", nil, root)
    52	        b:SetSize(BAR_W, BAR_H)
    53	        b:SetPoint("TOP", root, "TOP", 0, y - (idx - 1) * (BAR_H + 3))
    54	        b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    55	        local c = NS.color[TRACK[key].color]
    56	        b:SetStatusBarColor(c[1], c[2], c[3])
    57	        b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
    58	        b.bg:SetColorTexture(0, 0, 0, 0.6)
    59	        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    60	        b.label:SetPoint("LEFT", 4, 0); b.label:SetText(TRACK[key].name)
    61	        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    62	        b.time:SetPoint("RIGHT", -4, 0)
    63	        b:Hide()
    64	        self.bars[key] = b
    65	    end
    66	
    67	    -- poll remaining time on a light throttle (0.1s) — only updates shown bars
    68	    self.elapsed = 0
    69	    root:SetScript("OnUpdate", function(_, dt)
    70	        self.elapsed = self.elapsed + dt
    71	        if self.elapsed < 0.1 then return end
    72	        self.elapsed = 0
    73	        self:Tick()
    74	    end)
    75	end
    76	
    77	function Timers:Tick()
    78	    if not NS.IsRogue then return end
    79	    local hasTarget = UnitExists("target") and not UnitIsDead("target")
    80	
    81	    -- SnD = self buff, always relevant
    82	    local sndRem = GetAuraRemaining("player", TRACK.snd.name, false)
    83	    self:Set("snd", sndRem, TRACK.snd.name, NS.db.sndWarn)
    84	
    85	    -- target debuffs
    86	    for _, key in ipairs({ "rup", "exp", "gar" }) do
    87	        local rem = hasTarget and GetAuraRemaining("target", TRACK[key].name, true) or nil
    88	        self:Set(key, rem, TRACK[key].name, key == "rup" and NS.db.ruptureWarn or 2)
    89	    end
    90	end
    91	
    92	function Timers:Set(key, rem, name, warnAt)
    93	    local b = self.bars[key]
    94	    if not rem or rem <= 0 then b:Hide(); return end
    95	    if not b.maxSeen or rem > b.maxSeen then b.maxSeen = rem end
    96	    b:SetMinMaxValues(0, b.maxSeen or rem)
    97	    b:SetValue(rem)
    98	    b.time:SetText(string.format("%.1f", rem))
    99	    -- flash label when low
   100	    if rem <= warnAt then
   101	        b.label:SetTextColor(unpack(NS.color.bad))
   102	        if not b.warned and NS.db.sound then
   103	            PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
   104	            b.warned = true
   105	        end
   106	    else
   107	        b.label:SetTextColor(1, 1, 1)
   108	        b.warned = false
   109	    end
   110	    b:Show()
   111	    -- reset maxSeen when bar was hidden then reappears
   112	    b:SetScript("OnHide", function(s) s.maxSeen = nil; s.warned = false end)
   113	end
   114	
   115	function Timers:Refresh() end

codex
I’ve got the first pass. I’m doing one targeted cross-check on the TBC-specific API/event assumptions before I finalize, because the likely failures here are version compatibility rather than broad Lua style.
exec
/bin/zsh -lc "glm-ask \"Review these WoW TBC Classic 2.5.4 Lua addon snippets for concrete API correctness issues only. APIs/events to check: C_AddOns.GetAddOnMetadata in interface 20504, CreateFrame BackdropTemplate availability, RegisterUnitEvent availability, UNIT_POWER_FREQUENT/UNIT_POWER_UPDATE in TBC Classic, GetComboPoints('player','target'), C_UnitAuras availability and UnitAura filter 'HARMFUL|PLAYER', UnitCastingInfo notInterruptible return position in 2.5.x, GetWeaponEnchantInfo return signature, PlaySound SOUNDKIT availability. Answer concise with likely real bugs and fixes.\"" in /Users/creative/WoWAddons/Cutthroat
 exited 6 in 0ms:
curl: (6) Could not resolve host: api.z.ai

codex
The GLM cross-check command could not reach its API (`Could not resolve host`), so I’m not going to pretend that happened. I’m continuing from the source and known 2.5.x API behavior.
exec
/bin/zsh -lc 'grep -RInE "GetSpellCooldown|C_Spell|UnitAura|C_UnitAuras|GetWeaponEnchantInfo|GetComboPoints|UNIT_POWER|UNIT_COMBO|Register(Unit)?Event|OnUpdate|Cast|UseAction|RunScript|RunMacro" core.lua hud.lua timers.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
core.lua:39:f:RegisterEvent("ADDON_LOADED")
core.lua:40:f:RegisterEvent("PLAYER_LOGIN")
hud.lua:76:    -- event-driven updates (cheap; no OnUpdate polling for power)
hud.lua:78:    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
hud.lua:79:    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
hud.lua:80:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
hud.lua:81:    ev:RegisterEvent("UNIT_POWER_UPDATE")
hud.lua:96:    local cp = GetComboPoints("player", "target") or 0
timers.lua:23:    -- try modern C_UnitAuras first, fall back to UnitAura loop
timers.lua:26:        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
timers.lua:27:            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
timers.lua:30:                d = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|PLAYER")
timers.lua:35:            n, _, _, _, dur, exp, source = UnitAura(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
timers.lua:69:    root:SetScript("OnUpdate", function(_, dt)
alerts.lua:13:    local start, dur = GetSpellCooldown(name)
alerts.lua:57:    ev:RegisterEvent("UNIT_SPELLCAST_START")
alerts.lua:58:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
alerts.lua:59:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
alerts.lua:60:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
alerts.lua:61:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
alerts.lua:62:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
alerts.lua:63:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
alerts.lua:64:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
alerts.lua:65:    ev:RegisterEvent("UPDATE_STEALTH")
alerts.lua:66:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
alerts.lua:91:    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
alerts.lua:110:    local mh, _, _, oh = GetWeaponEnchantInfo()

exec
/bin/zsh -lc "grep -RInE \"CastSpell|UseAction|RunScript|RunMacro|Click\\(|SpellStop|TargetUnit|InteractUnit|Pickup|PlaceAction|SetBinding|SecureActionButton|SetAttribute|C_UnitAuras|UnitAura|GetWeaponEnchantInfo|GetComboPoints|UNIT_POWER|UNIT_COMBO|GetSpellCooldown|UnitCastingInfo|UnitChannelInfo|OnUpdate|RegisterUnitEvent|C_AddOns|BackdropTemplate|PlaySound\" ." in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua:14:    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
./hud.lua:76:    -- event-driven updates (cheap; no OnUpdate polling for power)
./hud.lua:78:    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
./hud.lua:79:    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
./hud.lua:81:    ev:RegisterEvent("UNIT_POWER_UPDATE")
./hud.lua:96:    local cp = GetComboPoints("player", "target") or 0
./timers.lua:23:    -- try modern C_UnitAuras first, fall back to UnitAura loop
./timers.lua:26:        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
./timers.lua:27:            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
./timers.lua:30:                d = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|PLAYER")
./timers.lua:35:            n, _, _, _, dur, exp, source = UnitAura(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
./timers.lua:69:    root:SetScript("OnUpdate", function(_, dt)
./timers.lua:103:            PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
./docs/ROADMAP.md:19:- [ ] Confirm `IsStealthed`, `UnitChannelInfo`, `UnitCastingInfo` return signatures on the 2.5.x client.
./docs/DECISIONS.md:13:Success criteria for the addon: loads clean on a TBC Anniversary client, zero Lua errors, no FPS regression from OnUpdate loops, and **provably no spell-input automation** (Warden-safe).
./docs/DECISIONS.md:22:- `GetWeaponEnchantInfo` — corrected to TBC signature (off-hand = return 4, not 5; no `enchantID` arg in 2.5.x).
./docs/DECISIONS.md:24:- `C_UnitAuras` → `UnitAura` fallback so aura reads work on the 2.5.x client.
./alerts.lua:13:    local start, dur = GetSpellCooldown(name)
./alerts.lua:91:    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
./alerts.lua:93:        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
./alerts.lua:100:            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
./alerts.lua:110:    local mh, _, _, oh = GetWeaponEnchantInfo()
./README.md:40:No `RunMacro`, no `CastSpellByName` automation, no hardware-event simulation. It reacts to events (`UNIT_POWER`, `UNIT_SPELLCAST_*`, auras) and draws frames. That's it.
./prompts/review_iter1.txt:1:You are reviewing a World of Warcraft TBC Classic (2.5.x, interface 20504) Rogue addon called Cutthroat. Lua 5.1 runtime, WoW API. GOAL: find correctness bugs, WoW-API misuse, performance issues (OnUpdate/CLEU loops), and ban-safety problems (it MUST NOT automate spell input). Be specific: file, line/function, the bug, the fix. Prioritize REAL bugs over style. Output a numbered list.
./prompts/review_iter1.txt:74:        print("|cff00ff96Cutthroat|r v" .. (C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "1.0.0") ..
./prompts/review_iter1.txt:105:    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
./prompts/review_iter1.txt:167:    -- event-driven updates (cheap; no OnUpdate polling for power)
./prompts/review_iter1.txt:169:    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
./prompts/review_iter1.txt:170:    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
./prompts/review_iter1.txt:172:    ev:RegisterEvent("UNIT_POWER_UPDATE")
./prompts/review_iter1.txt:187:    local cp = GetComboPoints("player", "target") or 0
./prompts/review_iter1.txt:225:    -- try modern C_UnitAuras first, fall back to UnitAura loop
./prompts/review_iter1.txt:228:        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
./prompts/review_iter1.txt:229:            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
./prompts/review_iter1.txt:232:                d = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|PLAYER")
./prompts/review_iter1.txt:237:            n, _, _, _, dur, exp, source = UnitAura(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
./prompts/review_iter1.txt:271:    root:SetScript("OnUpdate", function(_, dt)
./prompts/review_iter1.txt:305:            PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
./prompts/review_iter1.txt:332:    local start, dur = GetSpellCooldown(name)
./prompts/review_iter1.txt:410:    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
./prompts/review_iter1.txt:412:        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
./prompts/review_iter1.txt:419:            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
./prompts/review_iter1.txt:429:    local mh, _, _, oh = GetWeaponEnchantInfo()
./core.lua:56:        print("|cff00ff96Cutthroat|r v" .. (C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "1.0.0") ..
./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter1.md:66:    13	    local start, dur = GetSpellCooldown(name)
./reviews/codex/iter1.md:144:    91	    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
./reviews/codex/iter1.md:146:    93	        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
./reviews/codex/iter1.md:153:   100	            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
./reviews/codex/iter1.md:163:   110	    local mh, _, _, oh = GetWeaponEnchantInfo()
./reviews/codex/iter1.md:320:    56	        print("|cff00ff96Cutthroat|r v" .. (C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "1.0.0") ..
./reviews/codex/iter1.md:351:    14	    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
./reviews/codex/iter1.md:413:    76	    -- event-driven updates (cheap; no OnUpdate polling for power)
./reviews/codex/iter1.md:415:    78	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
./reviews/codex/iter1.md:416:    79	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
./reviews/codex/iter1.md:418:    81	    ev:RegisterEvent("UNIT_POWER_UPDATE")
./reviews/codex/iter1.md:433:    96	    local cp = GetComboPoints("player", "target") or 0
./reviews/codex/iter1.md:490:    23	    -- try modern C_UnitAuras first, fall back to UnitAura loop
./reviews/codex/iter1.md:493:    26	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
./reviews/codex/iter1.md:494:    27	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
./reviews/codex/iter1.md:497:    30	                d = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|PLAYER")
./reviews/codex/iter1.md:502:    35	            n, _, _, _, dur, exp, source = UnitAura(unit, i, byPlayer and "HARMFUL|PLAYER" or "HELPFUL")
./reviews/codex/iter1.md:536:    69	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter1.md:570:   103	            PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
./reviews/codex/iter1.md:587:/bin/zsh -lc "glm-ask \"Review these WoW TBC Classic 2.5.4 Lua addon snippets for concrete API correctness issues only. APIs/events to check: C_AddOns.GetAddOnMetadata in interface 20504, CreateFrame BackdropTemplate availability, RegisterUnitEvent availability, UNIT_POWER_FREQUENT/UNIT_POWER_UPDATE in TBC Classic, GetComboPoints('player','target'), C_UnitAuras availability and UnitAura filter 'HARMFUL|PLAYER', UnitCastingInfo notInterruptible return position in 2.5.x, GetWeaponEnchantInfo return signature, PlaySound SOUNDKIT availability. Answer concise with likely real bugs and fixes.\"" in /Users/creative/WoWAddons/Cutthroat
./reviews/glm/iter1.md:5:**Bug:** You are registering for `UNIT_POWER_FREQUENT`, which in TBC 2.5.x *does not fire* for Energy regeneration ticks or Combo Point changes while the player is stealthed. This was changed to `UNIT_POWER_UPDATE` in the 2.5.4 patch specifically to fix stealth addons. Because you also don't update CP on `PLAYER_ENTERING_WORLD` or after casting, CPs will often visually freeze at 0 until a target swap occurs. 
./reviews/glm/iter1.md:6:**Fix:** Swap the event registration and update the script to use `UNIT_POWER_UPDATE`.
./reviews/glm/iter1.md:9:    ev:RegisterUnitEvent("UNIT_POWER_UPDATE", "player") -- Use this instead of FREQUENT
./reviews/glm/iter1.md:14:        if event == "UNIT_POWER_UPDATE" and powerType == "ENERGY" then
./reviews/glm/iter1.md:26:**Bug:** `GetAuraRemaining` attempts to find self buffs (like Slice and Dice) by passing `byPlayer and "HARMFUL|PLAYER" or "HELPFUL|PLAYER"`. Because Slice and Dice is called with `isSelf = false` (Line 64), the filter evaluates to `"HELPFUL|PLAYER"`. In WoW's API, combining `HELPFUL` and `PLAYER` is an invalid filter string, which causes `C_UnitAuras.GetAuraDataByIndex` to silently return `nil`. This completely breaks tracking for SnD, and also fundamentally breaks tracking for any target debuff that isn't directly cast by the player (e.g. Mangle/Trauma debuff extensions applied by other players). 
./reviews/glm/iter1.md:29:-- Replace the C_UnitAuras logic block inside GetAuraRemaining
./reviews/glm/iter1.md:32:    local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:30), `CallAll`
   Bug: module init order is nondeterministic because `pairs(NS.modules)` is used. `timers.lua` and `alerts.lua` both assume `NS.modules.hud.root` already exists. If `timers` or `alerts` initializes before `hud`, this can Lua-error.
   Fix: initialize modules in explicit order, e.g. `hud`, `timers`, `alerts`, `config`, or make dependent modules defer until `hud.root` exists.

2. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:51), `PLAYER_LOGIN`
   Bug: non-rogues still initialize every module after printing “HUD disabled.” The HUD is not actually disabled.
   Fix: if `playerClass ~= "ROGUE"`, skip HUD/timer/alert init or hide/disable those modules; still allow config if desired.

3. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:78), `HUD:Init`
   Bug: combo points are likely stale because the HUD does not register the TBC combo-point event. `GetComboPoints("player", "target")` itself is correct, but updates depend on power/target events only.
   Fix: register `UNIT_COMBO_POINTS` and call `HUD:UpdateCP()` from it. Keep `PLAYER_TARGET_CHANGED`.

4. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:81), `HUD:Init`
   Bug/perf: `UNIT_POWER_UPDATE` is registered globally, not unit-filtered, so every unit’s power changes can update the player HUD.
   Fix: use `ev:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")` if available, or check `unit == "player"` in the handler.

5. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:67), `Timers:Init` / `Timers:Tick`
   Perf: every 0.1s it scans up to 40 auras for player plus up to 3 target debuffs. That can be ~160 `UnitAura` calls every tenth second while idle.
   Fix: refresh aura expiration data from `UNIT_AURA` for `player`/`target`; use `OnUpdate` only to render already-known countdowns.

6. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:95), `Timers:Set`
   Bug: `maxSeen` is used as bar duration, so refreshing with a shorter duration while the bar remains visible keeps the old max and makes the bar lie.
   Fix: use the real aura `duration` returned by `GetAuraRemaining`; pass `rem, dur` into `Set` and call `b:SetMinMaxValues(0, dur)`.

7. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:112), `Timers:Set`
   Perf/GC: `b:SetScript("OnHide", function...)` runs every tick for every visible bar, creating repeated closures.
   Fix: set the `OnHide` script once when each bar is created.

8. [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:11), `SpellReady`
   Bug: `GetSpellCooldown` is used without checking `enabled` or spell usability. Kick can alert while unusable, for example insufficient energy or other unusable states.
   Fix: check `IsUsableSpell(KICK)` and the third return from `GetSpellCooldown`; only alert when usable and cooldown-ready.

9. [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:107), `CheckPoison`
   Bug: poison reminder only updates after leaving combat. It can be missing on login/reload and stale after applying poison or swapping weapons out of combat.
   Fix: register `PLAYER_ENTERING_WORLD` and `UNIT_INVENTORY_CHANGED`/equipment-change style events; when out of combat, call `CheckPoison()`.

10. [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:134), `Alerts:Refresh`
   Bug: toggling `/cut poison` off does not hide an already-visible poison warning; `Refresh` only hides Kick.
   Fix: hide `self.poison` when poison checks are disabled, and refresh opener/poison state consistently.

11. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:56), `PLAYER_LOGIN`
   Compatibility issue: TBC Classic 2.5.x should use global `GetAddOnMetadata`; `C_AddOns.GetAddOnMetadata` is a later-style API. Current fallback avoids a crash if `C_AddOns` is nil, but will show hardcoded `"1.0.0"` instead of TOC metadata.
   Fix: use `(GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version")) or "1.0.0"`.

Not findings: [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:110) uses the TBC `GetWeaponEnchantInfo()` positions correctly for main/off-hand, and I found no `CastSpell*`, `UseAction`, `RunMacro`, `RunScript`, secure-button click, or input automation calls. Ban-safety looks clean from these files.
tokens used
29,298
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:30), `CallAll`
   Bug: module init order is nondeterministic because `pairs(NS.modules)` is used. `timers.lua` and `alerts.lua` both assume `NS.modules.hud.root` already exists. If `timers` or `alerts` initializes before `hud`, this can Lua-error.
   Fix: initialize modules in explicit order, e.g. `hud`, `timers`, `alerts`, `config`, or make dependent modules defer until `hud.root` exists.

2. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:51), `PLAYER_LOGIN`
   Bug: non-rogues still initialize every module after printing “HUD disabled.” The HUD is not actually disabled.
   Fix: if `playerClass ~= "ROGUE"`, skip HUD/timer/alert init or hide/disable those modules; still allow config if desired.

3. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:78), `HUD:Init`
   Bug: combo points are likely stale because the HUD does not register the TBC combo-point event. `GetComboPoints("player", "target")` itself is correct, but updates depend on power/target events only.
   Fix: register `UNIT_COMBO_POINTS` and call `HUD:UpdateCP()` from it. Keep `PLAYER_TARGET_CHANGED`.

4. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:81), `HUD:Init`
   Bug/perf: `UNIT_POWER_UPDATE` is registered globally, not unit-filtered, so every unit’s power changes can update the player HUD.
   Fix: use `ev:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")` if available, or check `unit == "player"` in the handler.

5. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:67), `Timers:Init` / `Timers:Tick`
   Perf: every 0.1s it scans up to 40 auras for player plus up to 3 target debuffs. That can be ~160 `UnitAura` calls every tenth second while idle.
   Fix: refresh aura expiration data from `UNIT_AURA` for `player`/`target`; use `OnUpdate` only to render already-known countdowns.

6. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:95), `Timers:Set`
   Bug: `maxSeen` is used as bar duration, so refreshing with a shorter duration while the bar remains visible keeps the old max and makes the bar lie.
   Fix: use the real aura `duration` returned by `GetAuraRemaining`; pass `rem, dur` into `Set` and call `b:SetMinMaxValues(0, dur)`.

7. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:112), `Timers:Set`
   Perf/GC: `b:SetScript("OnHide", function...)` runs every tick for every visible bar, creating repeated closures.
   Fix: set the `OnHide` script once when each bar is created.

8. [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:11), `SpellReady`
   Bug: `GetSpellCooldown` is used without checking `enabled` or spell usability. Kick can alert while unusable, for example insufficient energy or other unusable states.
   Fix: check `IsUsableSpell(KICK)` and the third return from `GetSpellCooldown`; only alert when usable and cooldown-ready.

9. [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:107), `CheckPoison`
   Bug: poison reminder only updates after leaving combat. It can be missing on login/reload and stale after applying poison or swapping weapons out of combat.
   Fix: register `PLAYER_ENTERING_WORLD` and `UNIT_INVENTORY_CHANGED`/equipment-change style events; when out of combat, call `CheckPoison()`.

10. [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:134), `Alerts:Refresh`
   Bug: toggling `/cut poison` off does not hide an already-visible poison warning; `Refresh` only hides Kick.
   Fix: hide `self.poison` when poison checks are disabled, and refresh opener/poison state consistently.

11. [core.lua](/Users/creative/WoWAddons/Cutthroat/core.lua:56), `PLAYER_LOGIN`
   Compatibility issue: TBC Classic 2.5.x should use global `GetAddOnMetadata`; `C_AddOns.GetAddOnMetadata` is a later-style API. Current fallback avoids a crash if `C_AddOns` is nil, but will show hardcoded `"1.0.0"` instead of TOC metadata.
   Fix: use `(GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version")) or "1.0.0"`.

Not findings: [alerts.lua](/Users/creative/WoWAddons/Cutthroat/alerts.lua:110) uses the TBC `GetWeaponEnchantInfo()` positions correctly for main/off-hand, and I found no `CastSpell*`, `UseAction`, `RunMacro`, `RunScript`, secure-button click, or input automation calls. Ban-safety looks clean from these files.
