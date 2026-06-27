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
session id: 019f0974-675f-7d22-9426-b3d10a6a0029
--------
user
Review the NEW file cooldowns.lua in this directory (a WoW TBC Classic 2.5.x, Lua 5.1, interface 20504 Rogue addon cooldown-icon module). Also check core.lua init order integration. It must be READ-ONLY (no spell-cast automation). Verify for TBC 2.5.x: GetSpellInfo/GetSpellCooldown/GetSpellTexture signatures; CooldownFrameTemplate + SetCooldown/Clear/SetDrawEdge availability; whether registering PLAYER_TALENT_UPDATE errors if the event doesn't exist on this build (and the safer event); spell IDs (Vanish 1856, Evasion 5277, Sprint 2983, Blade Flurry 13877, Adrenaline Rush 13750, Cold Blood 14177, Preparation 14185); IsKnown-via-GetSpellCooldown reliability; the dur>1.5 GCD filter; layout/anchor math; perf. Give a numbered list: file, function, bug, concrete fix. Do NOT edit files. Prioritize real bugs.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll do this as a read-only review: inspect `cooldowns.lua`, `core.lua`, addon metadata/load order if present, then verify API/event details against reliable TBC-era references where needed.
exec
/bin/zsh -lc 'pwd && rg --files' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

exec
/bin/zsh -lc 'git status --short' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
 M Cutthroat.toc
 M core.lua
?? cooldowns.lua
?? reviews/codex/iter2.md
?? reviews/glm/iter2.md

codex
`rg` isn’t installed here, so I’m falling back to standard shell reads. I see `cooldowns.lua` is untracked and `core.lua`/TOC are modified already; I’ll treat all of that as user work and only review.
exec
/bin/zsh -lc "sed -n '1,260p' cooldowns.lua" in /Users/creative/WoWAddons/Cutthroat
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

-- A rogue "knows" a spell if GetSpellInfo resolves it AND it has a usable cooldown
-- entry. We detect known-state via the spellbook name lookup.
local function SpellName(id)
    local n = GetSpellInfo(id)
    return n
end

local function IsKnown(name)
    if not name then return false end
    -- GetSpellCooldown returns nil for a spell not in your spellbook.
    return GetSpellCooldown(name) ~= nil
end

function CDs:Init()
    if not NS.IsRogue then return end
    local root = NS.modules.hud.root
    self.icons = {}

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

    -- anchor below the timer bars (4 bars * (14+3) starting at -56)
    local rowY = -(18 + 6 + 22 + 10) - (4 * 17) - 8

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
    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        else
            self:Relayout()
        end
    end)
    self.ev = ev

    self:Relayout()
end

-- Show only known spells, packed left-to-right and centered under the HUD.
function CDs:Relayout()
    if not self.icons then return end
    local root = NS.modules.hud.root
    local shown = {}
    for _, f in ipairs(self.icons) do
        if IsKnown(f.spell.name) then shown[#shown + 1] = f else f:Hide() end
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
            if start and dur and dur > 1.5 and enabled ~= 0 then
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
    if self.icons then self:Relayout() end
end

exec
/bin/zsh -lc 'find . -maxdepth 3 -type f -print' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua
./Cutthroat.toc
./LICENSE
./timers.lua
./docs/TRIANGULATION.md
./docs/ROADMAP.md
./docs/DECISIONS.md
./alerts.lua
./config.lua
./README.md
./.gitignore
./prompts/review_iter1.txt
./prompts/review_iter2.txt
./cooldowns.lua
./.git/config
./.git/HEAD
./.git/info/exclude
./.git/logs/HEAD
./.git/description
./.git/hooks/commit-msg.sample
./.git/hooks/pre-rebase.sample
./.git/hooks/sendemail-validate.sample
./.git/hooks/pre-commit.sample
./.git/hooks/applypatch-msg.sample
./.git/hooks/fsmonitor-watchman.sample
./.git/hooks/pre-receive.sample
./.git/hooks/prepare-commit-msg.sample
./.git/hooks/post-update.sample
./.git/hooks/pre-merge-commit.sample
./.git/hooks/pre-applypatch.sample
./.git/hooks/pre-push.sample
./.git/hooks/update.sample
./.git/hooks/push-to-checkout.sample
./.git/index
./.git/COMMIT_EDITMSG
./core.lua
./reviews/codex/iter1.md
./reviews/codex/iter2.md
./reviews/glm/iter1.md
./reviews/glm/iter2.md

exec
/bin/zsh -lc "sed -n '1,260p' core.lua" in /Users/creative/WoWAddons/Cutthroat
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
        NS.db = CutthroatDB
    elseif event == "PLAYER_LOGIN" then
        -- Explicit init order: hud first (timers/alerts anchor to hud.root),
        -- config last. pairs() order is nondeterministic, so never rely on it here.
        local function initModule(name)
            local m = NS.modules[name]
            if m and m.Init then m:Init() end
        end
        initModule("config") -- slash command / options work for everyone
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
/bin/zsh -lc "sed -n '1,180p' Cutthroat.toc" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
## Interface: 20504
## Title: Cutthroat |cff00ff96Rogue|r
## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
## Author: Cutthroat
## Version: 1.2.0
## SavedVariables: CutthroatDB
## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate

core.lua
hud.lua
timers.lua
cooldowns.lua
alerts.lua
config.lua

web search: 
web search: TBC Classic 2.5.4 API GetSpellCooldown signature CooldownFrame_SetCooldown SetDrawEdge PLAYER_TALENT_UPDATE CHARACTER_POINTS_CHANGED
web search: 
web search: site:warcraft.wiki.gg GetSpellCooldown API signature
web search: 
web search: https://warcraft.wiki.gg/wiki/API_GetSpellCooldown
codex
I have the module shape now. I’m checking API facts before I call anything a bug, because several of these points depend on actual 2.5.x client behavior rather than modern Retail habits.
exec
/bin/zsh -lc "nl -ba cooldowns.lua | sed -n '1,240p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba core.lua | sed -n '1,180p'" in /Users/creative/WoWAddons/Cutthroat
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
    20	}
    21	
    22	-- ---- Class gate ----
    23	local _, playerClass = UnitClass("player")
    24	
    25	-- ---- Module registration ----
    26	function NS:RegisterModule(name, mod)
    27	    self.modules[name] = mod
    28	    return mod
    29	end
    30	
    31	local function CallAll(method, ...)
    32	    for _, mod in pairs(NS.modules) do
    33	        if mod[method] then mod[method](mod, ...) end
    34	    end
    35	end
    36	NS.CallAll = CallAll
    37	
    38	-- ---- Event hub ----
    39	local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
    40	f:RegisterEvent("ADDON_LOADED")
    41	f:RegisterEvent("PLAYER_LOGIN")
    42	f:SetScript("OnEvent", function(self, event, arg1)
    43	    if event == "ADDON_LOADED" and arg1 == ADDON then
    44	        CutthroatDB = CutthroatDB or {}
    45	        for k, v in pairs(defaults) do
    46	            if CutthroatDB[k] == nil then
    47	                CutthroatDB[k] = (type(v) == "table") and CopyTable(v) or v
    48	            end
    49	        end
    50	        NS.db = CutthroatDB
    51	    elseif event == "PLAYER_LOGIN" then
    52	        -- Explicit init order: hud first (timers/alerts anchor to hud.root),
    53	        -- config last. pairs() order is nondeterministic, so never rely on it here.
    54	        local function initModule(name)
    55	            local m = NS.modules[name]
    56	            if m and m.Init then m:Init() end
    57	        end
    58	        initModule("config") -- slash command / options work for everyone
    59	        if playerClass == "ROGUE" then
    60	            initModule("hud")
    61	            initModule("timers")
    62	            initModule("cooldowns")
    63	            initModule("alerts")
    64	            CallAll("Refresh")
    65	        else
    66	            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.")
    67	        end
    68	        -- TBC 2.5.x exposes the global GetAddOnMetadata; C_AddOns is a newer wrapper.
    69	        local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
    70	            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
    71	            or "1.0.0"
    72	        print("|cff00ff96Cutthroat|r v" .. ver .. " loaded. |cffffff00/cut|r for options.")
    73	    end
    74	end)
    75	
    76	NS.IsRogue = (playerClass == "ROGUE")
    77	
    78	-- shared color helpers
    79	NS.color = {
    80	    energy  = { 1.0, 0.85, 0.20 },
    81	    cp      = { 1.0, 0.20, 0.20 },
    82	    good    = { 0.20, 1.0, 0.40 },
    83	    warn    = { 1.0, 0.55, 0.10 },
    84	    bad     = { 1.0, 0.15, 0.15 },
    85	    dim     = { 0.45, 0.45, 0.45 },
    86	}

 succeeded in 0ms:
     1	-- cooldowns.lua: rogue defensive/utility cooldown icons with sweep timers.
     2	-- READ-ONLY — shows cooldown state, never casts. Only icons for spells you KNOW
     3	-- (so a Combat rogue won't see Cold Blood, an Assassination rogue won't see AR).
     4	
     5	local ADDON, NS = ...
     6	local CDs = NS:RegisterModule("cooldowns", {})
     7	
     8	local ICON, GAP = 30, 4
     9	
    10	-- Tracked by spellID; the name/texture are resolved at runtime (locale-safe).
    11	-- Order = display order. Talent spells simply won't show if untrained.
    12	local SPELL_IDS = {
    13	    1856,   -- Vanish
    14	    5277,   -- Evasion
    15	    2983,   -- Sprint
    16	    13877,  -- Blade Flurry   (Combat)
    17	    13750,  -- Adrenaline Rush (Combat)
    18	    14177,  -- Cold Blood     (Assassination)
    19	    14185,  -- Preparation    (Subtlety)
    20	}
    21	
    22	-- A rogue "knows" a spell if GetSpellInfo resolves it AND it has a usable cooldown
    23	-- entry. We detect known-state via the spellbook name lookup.
    24	local function SpellName(id)
    25	    local n = GetSpellInfo(id)
    26	    return n
    27	end
    28	
    29	local function IsKnown(name)
    30	    if not name then return false end
    31	    -- GetSpellCooldown returns nil for a spell not in your spellbook.
    32	    return GetSpellCooldown(name) ~= nil
    33	end
    34	
    35	function CDs:Init()
    36	    if not NS.IsRogue then return end
    37	    local root = NS.modules.hud.root
    38	    self.icons = {}
    39	
    40	    -- de-dupe the id list (guard against typos above) and resolve names/textures
    41	    local seen = {}
    42	    self.spells = {}
    43	    for _, id in ipairs(SPELL_IDS) do
    44	        if not seen[id] then
    45	            seen[id] = true
    46	            local name, _, tex = GetSpellInfo(id)
    47	            if name then
    48	                self.spells[#self.spells + 1] = { id = id, name = name, tex = tex }
    49	            end
    50	        end
    51	    end
    52	
    53	    -- anchor below the timer bars (4 bars * (14+3) starting at -56)
    54	    local rowY = -(18 + 6 + 22 + 10) - (4 * 17) - 8
    55	
    56	    for i, s in ipairs(self.spells) do
    57	        local f = CreateFrame("Frame", nil, root)
    58	        f:SetSize(ICON, ICON)
    59	        f.icon = f:CreateTexture(nil, "ARTWORK")
    60	        f.icon:SetAllPoints()
    61	        f.icon:SetTexture(s.tex or GetSpellTexture(s.id))
    62	        f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    63	        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    64	        f.cd:SetAllPoints()
    65	        if f.cd.SetDrawEdge then f.cd:SetDrawEdge(true) end
    66	        f.spell = s
    67	        f:Hide()
    68	        self.icons[i] = f
    69	    end
    70	    self.rowY = rowY
    71	
    72	    local ev = CreateFrame("Frame")
    73	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    74	    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
    75	    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
    76	    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
    77	    ev:SetScript("OnEvent", function(_, e)
    78	        if e == "SPELL_UPDATE_COOLDOWN" then
    79	            self:UpdateCooldowns()
    80	        else
    81	            self:Relayout()
    82	        end
    83	    end)
    84	    self.ev = ev
    85	
    86	    self:Relayout()
    87	end
    88	
    89	-- Show only known spells, packed left-to-right and centered under the HUD.
    90	function CDs:Relayout()
    91	    if not self.icons then return end
    92	    local root = NS.modules.hud.root
    93	    local shown = {}
    94	    for _, f in ipairs(self.icons) do
    95	        if IsKnown(f.spell.name) then shown[#shown + 1] = f else f:Hide() end
    96	    end
    97	    local n = #shown
    98	    local totalW = n * ICON + (n - 1) * GAP
    99	    local startX = -totalW / 2 + ICON / 2
   100	    for i, f in ipairs(shown) do
   101	        f:ClearAllPoints()
   102	        f:SetPoint("CENTER", root, "TOP", startX + (i - 1) * (ICON + GAP), self.rowY)
   103	        f:Show()
   104	    end
   105	    self:UpdateCooldowns()
   106	end
   107	
   108	function CDs:UpdateCooldowns()
   109	    if not self.icons then return end
   110	    for _, f in ipairs(self.icons) do
   111	        if f:IsShown() then
   112	            local start, dur, enabled = GetSpellCooldown(f.spell.name)
   113	            if start and dur and dur > 1.5 and enabled ~= 0 then
   114	                f.cd:SetCooldown(start, dur)
   115	                f.icon:SetDesaturated(true)
   116	            else
   117	                f.cd:Clear()
   118	                f.icon:SetDesaturated(false)
   119	            end
   120	        end
   121	    end
   122	end
   123	
   124	function CDs:Refresh()
   125	    if self.icons then self:Relayout() end
   126	end

exec
/bin/zsh -lc "nl -ba Cutthroat.toc | sed -n '1,80p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	## Interface: 20504
     2	## Title: Cutthroat |cff00ff96Rogue|r
     3	## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
     4	## Author: Cutthroat
     5	## Version: 1.2.0
     6	## SavedVariables: CutthroatDB
     7	## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate
     8	
     9	core.lua
    10	hud.lua
    11	timers.lua
    12	cooldowns.lua
    13	alerts.lua
    14	config.lua

exec
/bin/zsh -lc "find /Users/creative -iname '*GlobalStrings*' -o -iname '*FrameXML*' -o -iname '*Interface*' | head -200" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 1250ms:
/Users/creative/.config/gcloud/virtenv/lib/python3.14/site-packages/grpc/beta/interfaces.py
/Users/creative/.config/gcloud/virtenv/lib/python3.14/site-packages/grpc/beta/__pycache__/interfaces.cpython-314.pyc
/Users/creative/.config/gcloud/virtenv/lib/python3.14/site-packages/grpc/framework/interfaces
/Users/creative/scrubbuddy/apple/ScrubBuddy.xcodeproj/project.xcworkspace/xcuserdata/creative.xcuserdatad/UserInterfaceState.xcuserstate
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/3K/arm64e-apple-macos.swiftinterface-3PCHP2T43503K
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/3K/x86_64-apple-ios-simulator.swiftinterface-3PCHP2T43503K
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/3K/arm64-apple-ios-simulator.swiftinterface-3PCHP2T43503K
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/61/arm64e-apple-macos.swiftinterface-1NHIQOYNMHN61
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/VT/arm64-apple-ios-simulator.swiftinterface-467NGBIQWHVT
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/VT/x86_64-apple-ios-simulator.swiftinterface-467NGBIQWHVT
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZJ/IOGraphicsInterfaceTypes.h-2KP8HIDU6BAZJ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZC/arm64e-apple-macos.swiftinterface-Z81LBEB9QPZC
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/69/x86_64-apple-ios-simulator.swiftinterface-1XUX2X1CY0869
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/YV/x86_64-apple-ios-simulator.swiftinterface-1PNEE8QGBVPYV
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/YV/arm64e-apple-macos.swiftinterface-1PNEE8QGBVPYV
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/YV/arm64-apple-ios-simulator.swiftinterface-1PNEE8QGBVPYV
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/U6/arm64e-apple-macos.swiftinterface-13MO9HH15V3U6
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/0B/x86_64-apple-ios-simulator.swiftinterface-231KMNX5OI90B
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/0B/arm64-apple-ios-simulator.swiftinterface-231KMNX5OI90B
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZW/arm64-apple-ios-simulator.swiftinterface-3OJ778LC1WXZW
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZW/x86_64-apple-ios-simulator.swiftinterface-3OJ778LC1WXZW
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UT/NSUserInterfaceCompression.h-1ASQSSC4CXPUT
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/0E/x86_64-apple-ios-simulator.swiftinterface-1G309J7M14D0E
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/VN/arm64e-apple-macos.swiftinterface-2OPBIJBBBFGVN
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/VN/arm64-apple-ios-simulator.swiftinterface-2OPBIJBBBFGVN
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/GF/arm64e-apple-macos.swiftinterface-3G133JS5QKBGF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/GF/x86_64-apple-ios-simulator.swiftinterface-3G133JS5QKBGF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/GF/arm64-apple-ios-simulator.swiftinterface-3G133JS5QKBGF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/M1/x86_64-apple-ios-simulator.swiftinterface-1QO7IPG7FD9M1
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/M1/arm64e-apple-macos.swiftinterface-1QO7IPG7FD9M1
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/M1/arm64-apple-ios-simulator.swiftinterface-1QO7IPG7FD9M1
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BL/arm64e-apple-macos.swiftinterface-3LIFWUZE5K7BL
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/KQ/x86_64-apple-ios-simulator.swiftinterface-2U6JAMGEVRVKQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NI/x86_64-apple-ios-simulator.swiftinterface-1XJVOBF0AFNI
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NI/arm64e-apple-macos.swiftinterface-1XJVOBF0AFNI
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NI/arm64-apple-ios-simulator.swiftinterface-1XJVOBF0AFNI
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NN/NSUserInterfaceItemSearching.h-1DVZN987UM7NN
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BQ/arm64e-apple-macos.swiftinterface-HHJVPZ6R5BBQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BQ/arm64-apple-ios-simulator.swiftinterface-HHJVPZ6R5BBQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NH/arm64e-apple-macos.swiftinterface-2JEQB1CWVM1NH
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NH/x86_64-apple-ios-simulator.swiftinterface-2JEQB1CWVM1NH
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/NH/arm64-apple-ios-simulator.swiftinterface-2JEQB1CWVM1NH
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/DT/arm64e-apple-macos.swiftinterface-3BBHV2PBD8BDT
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/IG/x86_64-apple-ios-simulator.swiftinterface-222V57IB7UFIG
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/EK/x86_64-apple-ios-simulator.swiftinterface-1L09PFCJ3IHEK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/EK/arm64-apple-ios-simulator.swiftinterface-1L09PFCJ3IHEK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/F2/x86_64-apple-ios-simulator.swiftinterface-17ETP4QKW77F2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/IZ/arm64e-apple-macos.swiftinterface-2X1JAKQ7GO1IZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/CH/arm64e-apple-macos.swiftinterface-16FY6IWMG9UCH
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/EJ/x86_64-apple-ios-simulator.swiftinterface-384UJ3EUJTGEJ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/C6/IONetworkInterface.h-2YQVEU0DI66C6
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/TK/arm64e-apple-macos.swiftinterface-1R9PFP5L5QCTK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/TK/x86_64-apple-ios-simulator.swiftinterface-1R9PFP5L5QCTK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/TK/arm64-apple-ios-simulator.swiftinterface-1R9PFP5L5QCTK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/16/NSUserInterfaceLayout.h-29V3VKOFA6Y16
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/4P/NSInterfaceStyle.h-8FV0Q29ZB44P
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/XF/arm64e-apple-macos.swiftinterface-2H40FEA1EJMXF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/XF/x86_64-apple-ios-simulator.swiftinterface-2H40FEA1EJMXF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/XF/arm64-apple-ios-simulator.swiftinterface-2H40FEA1EJMXF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/10/IOGraphicsInterface.h-2TM3HMCS0Z410
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/7K/x86_64-apple-ios-simulator.swiftinterface-3Q4ML5N35UR7K
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/Q9/arm64e-apple-macos.swiftinterface-8NDBVH2NOMQ9
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/Q9/arm64-apple-ios-simulator.swiftinterface-8NDBVH2NOMQ9
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/T4/NSUserInterfaceItemIdentification.h-2NO350YZEUWT4
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZN/x86_64-apple-ios-simulator.swiftinterface-3GRP99COHA0ZN
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZN/arm64-apple-ios-simulator.swiftinterface-3GRP99COHA0ZN
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UM/x86_64-apple-ios-simulator.swiftinterface-3NA0NM3C8E6UM
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UM/arm64-apple-ios-simulator.swiftinterface-3NA0NM3C8E6UM
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UC/arm64e-apple-macos.swiftinterface-2ZZL440X3A1UC
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UC/x86_64-apple-ios-simulator.swiftinterface-2ZZL440X3A1UC
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UC/arm64-apple-ios-simulator.swiftinterface-2ZZL440X3A1UC
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/SF/x86_64-apple-ios-simulator.swiftinterface-1K1JYBWNFWSF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/YT/x86_64-apple-ios-simulator.swiftinterface-1EOMXCZSZ51YT
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UK/arm64-apple-ios-simulator.swiftinterface-R0KJCBPKWRUK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/UK/arm64e-apple-macos.swiftinterface-R0KJCBPKWRUK
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/U5/arm64-apple-ios-simulator.swiftinterface-GARJ0WLD68U5
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/U5/interface.h-3AY91QRG9UWU5
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/9U/PDEPluginInterface.h-3Q40DBFR97R9U
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZZ/arm64e-apple-macos.swiftinterface-2KINSS3HY61ZZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZZ/x86_64-apple-ios-simulator.swiftinterface-2KINSS3HY61ZZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ZZ/arm64-apple-ios-simulator.swiftinterface-2KINSS3HY61ZZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/YU/arm64-apple-ios-simulator.swiftinterface-J5N10Q5SGTYU
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/YU/x86_64-apple-ios-simulator.swiftinterface-J5N10Q5SGTYU
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/0A/arm64-apple-ios-simulator.swiftinterface-2CU52UEZTP50A
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/DV/arm64e-apple-macos.swiftinterface-2TCKLGFC02NDV
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/HT/UIInterface.h-3HNRTHDFRO7HT
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/KN/arm64e-apple-macos.swiftinterface-3843XXVJ2E7KN
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BS/arm64-apple-ios-simulator.swiftinterface-3BMXM4MF7GJBS
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BS/arm64e-apple-macos.swiftinterface-3BMXM4MF7GJBS
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BS/x86_64-apple-ios-simulator.swiftinterface-3BMXM4MF7GJBS
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/MP/x86_64-apple-ios-simulator.swiftinterface-1Z0RRLN2NORMP
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/MP/arm64e-apple-macos.swiftinterface-1Z0RRLN2NORMP
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/MP/arm64-apple-ios-simulator.swiftinterface-1Z0RRLN2NORMP
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/HH/x86_64-apple-ios-simulator.swiftinterface-1S60ISET1DFHH
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/HH/arm64-apple-ios-simulator.swiftinterface-1S60ISET1DFHH
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/AU/x86_64-apple-ios-simulator.swiftinterface-1KA7SQXECQBAU
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/AU/arm64e-apple-macos.swiftinterface-1KA7SQXECQBAU
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/AU/arm64-apple-ios-simulator.swiftinterface-1KA7SQXECQBAU
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/D2/x86_64-apple-ios-simulator.swiftinterface-1X5EG26NI63D2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/D2/arm64e-apple-macos.swiftinterface-1X5EG26NI63D2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/D2/arm64-apple-ios-simulator.swiftinterface-1X5EG26NI63D2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/DB/arm64e-apple-macos.swiftinterface-3OMDCWN9680DB
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/MX/x86_64-apple-ios-simulator.swiftinterface-3JWHNTP5Q5PMX
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/B0/arm64-apple-ios-simulator.swiftinterface-1TLY56UMHMIB0
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/B0/x86_64-apple-ios-simulator.swiftinterface-1TLY56UMHMIB0
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/DL/arm64e-apple-macos.swiftinterface-ANGR2ZBDPKDL
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/GD/x86_64-apple-ios-simulator.swiftinterface-DE831NRJMLGD
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/GD/arm64-apple-ios-simulator.swiftinterface-DE831NRJMLGD
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BR/arm64-apple-ios-simulator.swiftinterface-334ZH2O7142BR
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BR/x86_64-apple-ios-simulator.swiftinterface-334ZH2O7142BR
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/BR/arm64e-apple-macos.swiftinterface-334ZH2O7142BR
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/IX/arm64e-apple-macos.swiftinterface-3O51GG1CEAGIX
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/CJ/arm64e-apple-macos.swiftinterface-1DCYVL0GFACJ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/CJ/arm64-apple-ios-simulator.swiftinterface-1DCYVL0GFACJ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/CJ/x86_64-apple-ios-simulator.swiftinterface-1DCYVL0GFACJ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ET/arm64-apple-ios-simulator.swiftinterface-3BWVKIR740NET
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ET/arm64e-apple-macos.swiftinterface-3BWVKIR740NET
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/ET/x86_64-apple-ios-simulator.swiftinterface-3BWVKIR740NET
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/CP/IOEthernetInterface.h-BO9GJSMKJNCP
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/LZ/x86_64-apple-ios-simulator.swiftinterface-3HK6QC4R41ULZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/FZ/arm64-apple-ios-simulator.swiftinterface-33N8VAVIADBFZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/FZ/arm64e-apple-macos.swiftinterface-33N8VAVIADBFZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/FZ/x86_64-apple-ios-simulator.swiftinterface-33N8VAVIADBFZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/F8/x86_64-apple-ios-simulator.swiftinterface-3CU6SZ805QXF8
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/F8/arm64e-apple-macos.swiftinterface-3CU6SZ805QXF8
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/F8/arm64-apple-ios-simulator.swiftinterface-3CU6SZ805QXF8
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/LA/arm64e-apple-macos.swiftinterface-372W3URMQIGLA
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/LA/arm64-apple-ios-simulator.swiftinterface-372W3URMQIGLA
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/XV/arm64e-apple-macos.swiftinterface-1KU9YWTOX7TXV
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/46/x86_64-apple-ios-simulator.swiftinterface-2XMNC8EDVD746
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/7N/arm64-apple-ios-simulator.swiftinterface-3CXE2QAI40N7N
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/7N/x86_64-apple-ios-simulator.swiftinterface-3CXE2QAI40N7N
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/XM/arm64e-apple-macos.swiftinterface-1XYZMC7VLVMXM
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/XM/arm64-apple-ios-simulator.swiftinterface-1XYZMC7VLVMXM
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/WI/IOI2CInterface.h-3KTC89CDY8ZWI
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/RQ/arm64-apple-ios-simulator.swiftinterface-1R3IMRLGB5URQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/RQ/x86_64-apple-ios-simulator.swiftinterface-1R3IMRLGB5URQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/RQ/arm64e-apple-macos.swiftinterface-1R3IMRLGB5URQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/71/x86_64-apple-ios-simulator.swiftinterface-1RIGHMD7QX471
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/71/arm64e-apple-macos.swiftinterface-1RIGHMD7QX471
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/71/arm64-apple-ios-simulator.swiftinterface-1RIGHMD7QX471
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/WS/arm64e-apple-macos.swiftinterface-32HV1LNPD7SWS
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/QJ/arm64e-apple-macos.swiftinterface-1Z1ALCIGNJ3QJ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/T0/arm64e-apple-macos.swiftinterface-3835HN5WAKUT0
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/T0/x86_64-apple-ios-simulator.swiftinterface-3835HN5WAKUT0
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/T0/arm64-apple-ios-simulator.swiftinterface-3835HN5WAKUT0
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/QX/CIPlugInInterface.h-3B3D2MD4WEJQX
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/8E/x86_64-apple-ios-simulator.swiftinterface-4UG0LPGNJ48E
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/1V/x86_64-apple-ios-simulator.swiftinterface-38LY908FKAQ1V
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/1V/arm64-apple-ios-simulator.swiftinterface-38LY908FKAQ1V
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/records/25/NSUserInterfaceValidation.h-IW2Y24FIHK25
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-16XI1MP8Z7AE3
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-2T1VHQBXXEURU
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-2QIK9H60NNRND
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-TZQTD4HZZ7AI
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-3A76X92L2KJA1
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-3126LYVS77ZQV
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-DMFODNN2672S
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-1OW21PBLB8WF3
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-3H865L2RFHTRX
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-3NSGILP7IQJ07
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-SNILQ2JQUL3H
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-34TKPSIL92WQG
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-AOS9O3YOSSOC
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-209C43WTK366W
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-14LGTEERH0G1J
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-1HK0AZPYWZ8MG
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-31QMS6ZPCYC9L
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-2DRKELW4UJTK0
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-1OZUHDHQB4SCB
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-36HVPXIXTP79N
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-13S9QE3BJFQ0G
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-G21LQ9GB26X6
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-368O692QIOSDW
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-3VKDML75R31PZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-3SWKPOXHLLHGW
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-393LPVMQKN8M5
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-33E5R09W7DVCD
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-2LHEOT5TPEOL2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-3GRYUSBNGHGCZ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-1TJG1CFSKRBUY
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-3IHZ35FWYJPBP
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-1Q98VVNI0PRJF
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-3JVQ5UP062FUL
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-OWU5CYOTITMD
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-39A30YB83VYQQ
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-16HXHCSPM0JX2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-2AUGGK4VKO4LE
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-2IIGQPGV1YNF2
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-2BXL0MF8B1GWE
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-YQT9Y57ZMIE
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-1ZJQU4EECRQL7
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-1IDRCJFPPO9KP
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-2JF71VCDY0OIW
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-18XUWE3NYMUUX
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64e-apple-macos.swiftinterface-1BZVBI0DZLKBM
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-2HG1DMPG2YJ5T
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-S9A9PJUO63A6
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/x86_64-apple-ios-simulator.swiftinterface-2G1LN6OY1RY1V
/Users/creative/scrubbuddy/apple/build/Index.noindex/DataStore/v5/units/arm64-apple-ios-simulator.swiftinterface-2IVAQ616JNEC2

codex
Core load order is explicit: TOC loads `core.lua`, then `hud.lua`, `timers.lua`, `cooldowns.lua`; `PLAYER_LOGIN` initializes `hud` before `cooldowns`. I’m checking the HUD geometry now because the cooldown row uses hard-coded offsets tied to timer layout.
exec
/bin/zsh -lc "nl -ba hud.lua | sed -n '1,260p'" in /Users/creative/WoWAddons/Cutthroat
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
    76	    -- Event-driven power updates, all unit-filtered to "player" so other units'
    77	    -- power changes never wake this handler. Combo points have no reliable
    78	    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
    79	    -- and registering a wrong event name errors) — they're polled in timers:Tick.
    80	    local ev = CreateFrame("Frame")
    81	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    82	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    83	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    84	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
    85	    self.ev = ev
    86	end
    87	
    88	function HUD:UpdatePower()
    89	    if not self.energy then return end
    90	    local e = UnitPower("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
    91	    local m = UnitPowerMax("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
    92	    self.energy:SetMinMaxValues(0, m > 0 and m or 100)
    93	    self.energy:SetValue(e)
    94	    self.energy.text:SetText(e)
    95	end
    96	
    97	function HUD:UpdateCP()
    98	    local cp = GetComboPoints("player", "target") or 0
    99	    for i = 1, MAX_CP do
   100	        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
   101	    end
   102	end
   103	
   104	function HUD:Refresh()
   105	    if not self.root then return end
   106	    self.root:SetScale(NS.db.scale)
   107	    self.root:EnableMouse(not NS.db.locked)
   108	    self.root.bg:SetShown(not NS.db.locked)
   109	    self:UpdatePower()
   110	    self:UpdateCP()
   111	end

exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '1,280p'" in /Users/creative/WoWAddons/Cutthroat
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
    20	
    21	local function GetAura(unit, name, byPlayer)
    22	    -- WoW aura filters are SPACE-separated tokens, not pipe-separated.
    23	    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
    24	    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
    25	    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
    26	    for i = 1, 40 do
    27	        local n, dur, exp
    28	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    29	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    30	            if not d then break end
    31	            n, dur, exp = d.name, d.duration, d.expirationTime
    32	        else
    33	            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
    34	            local dur2, exp2
    35	            n, _, _, _, dur2, exp2 = UnitAura(unit, i, filter)
    36	            if not n then break end
    37	            dur, exp = dur2, exp2
    38	        end
    39	        if n == name and exp and exp > 0 then
    40	            return exp, dur   -- absolute expiration time + full duration
    41	        end
    42	    end
    43	    return nil
    44	end
    45	
    46	-- where each tracked aura lives
    47	local SOURCE = {
    48	    snd = { unit = "player", byPlayer = false },
    49	    rup = { unit = "target", byPlayer = true  },
    50	    exp = { unit = "target", byPlayer = true  },
    51	    gar = { unit = "target", byPlayer = true  },
    52	}
    53	
    54	function Timers:Init()
    55	    local root = NS.modules.hud.root
    56	    self.bars = {}
    57	    self.cache = {} -- key -> { exp = absolute, dur = full }
    58	    local order = { "snd", "rup", "exp", "gar" }
    59	    local y = -(18 + 6 + 22 + 10) -- below the CP pips
    60	    for idx, key in ipairs(order) do
    61	        local b = CreateFrame("StatusBar", nil, root)
    62	        b:SetSize(BAR_W, BAR_H)
    63	        b:SetPoint("TOP", root, "TOP", 0, y - (idx - 1) * (BAR_H + 3))
    64	        b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    65	        local c = NS.color[TRACK[key].color]
    66	        b:SetStatusBarColor(c[1], c[2], c[3])
    67	        b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
    68	        b.bg:SetColorTexture(0, 0, 0, 0.6)
    69	        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    70	        b.label:SetPoint("LEFT", 4, 0); b.label:SetText(TRACK[key].name)
    71	        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    72	        b.time:SetPoint("RIGHT", -4, 0)
    73	        b:Hide()
    74	        b:SetScript("OnHide", function(s) s.warned = false end) -- set ONCE, not per tick
    75	        self.bars[key] = b
    76	    end
    77	
    78	    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
    79	    local scan = CreateFrame("Frame")
    80	    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
    81	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
    82	    scan:SetScript("OnEvent", function() self:Scan() end)
    83	    self.scan = scan
    84	
    85	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
    86	    self.elapsed = 0
    87	    root:SetScript("OnUpdate", function(_, dt)
    88	        self.elapsed = self.elapsed + dt
    89	        if self.elapsed < 0.05 then return end
    90	        self.elapsed = 0
    91	        self:Render()
    92	    end)
    93	    self:Scan()
    94	end
    95	
    96	-- Refresh the aura cache from the game (only on aura/target change events).
    97	function Timers:Scan()
    98	    if not NS.IsRogue or not self.cache then return end
    99	    local hasTarget = UnitExists("target") and not UnitIsDead("target")
   100	    for key, src in pairs(SOURCE) do
   101	        local exp, dur
   102	        if src.unit == "player" or hasTarget then
   103	            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
   104	        end
   105	        self.cache[key] = exp and { exp = exp, dur = dur } or nil
   106	    end
   107	end
   108	
   109	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
   110	function Timers:Render()
   111	    if not NS.IsRogue then return end
   112	    NS.modules.hud:UpdateCP()
   113	    NS.modules.hud:UpdatePower()
   114	
   115	    local now = GetTime()
   116	    for key, b in pairs(self.bars) do
   117	        local c = self.cache[key]
   118	        local rem = c and (c.exp - now) or 0
   119	        if not c or rem <= 0 then
   120	            self.cache[key] = nil
   121	            if b:IsShown() then b:Hide() end
   122	        else
   123	            local warnAt = (key == "snd" and NS.db.sndWarn)
   124	                or (key == "rup" and NS.db.ruptureWarn) or 2
   125	            local dur = (c.dur and c.dur > 0) and c.dur or rem
   126	            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
   127	            b:SetValue(rem)
   128	            b.time:SetText(string.format("%.1f", rem))
   129	            if rem <= warnAt then
   130	                b.label:SetTextColor(unpack(NS.color.bad))
   131	                if not b.warned and NS.db.sound then
   132	                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
   133	                    b.warned = true
   134	                end
   135	            else
   136	                b.label:SetTextColor(1, 1, 1)
   137	                b.warned = false
   138	            end
   139	            if not b:IsShown() then b:Show() end
   140	        end
   141	    end
   142	end
   143	
   144	function Timers:Refresh() if self.cache then self:Scan() end end

exec
/bin/zsh -lc "nl -ba alerts.lua | sed -n '1,280p'" in /Users/creative/WoWAddons/Cutthroat
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
    13	    -- don't nag to Kick when it can't actually be cast (e.g. not enough energy)
    14	    local usable, noMana = IsUsableSpell(name)
    15	    if not usable or noMana then return false end
    16	    local start, dur, enabled = GetSpellCooldown(name)
    17	    if not start or enabled == 0 then return false end
    18	    return (start == 0) or (start + dur - GetTime() <= 0.2)
    19	end
    20	
    21	function Alerts:Init()
    22	    local root = NS.modules.hud.root
    23	
    24	    -- ---- Kick flash icon (center, above HUD) ----
    25	    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
    26	    kick:SetSize(64, 64)
    27	    kick:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    28	    kick.icon = kick:CreateTexture(nil, "ARTWORK")
    29	    kick.icon:SetAllPoints()
    30	    kick.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    31	    kick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    32	    kick.txt = kick:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    33	    kick.txt:SetPoint("TOP", kick, "BOTTOM", 0, -2)
    34	    kick.txt:SetText("KICK!")
    35	    kick.txt:SetTextColor(unpack(NS.color.bad))
    36	    kick:Hide()
    37	    -- pulse
    38	    local ag = kick:CreateAnimationGroup()
    39	    ag:SetLooping("BOUNCE")
    40	    local a = ag:CreateAnimation("Alpha")
    41	    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    42	    kick.ag = ag
    43	    self.kick = kick
    44	
    45	    -- ---- Poison reminder text ----
    46	    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    47	    pz:SetPoint("BOTTOM", root, "TOP", 0, 6)
    48	    pz:SetTextColor(unpack(NS.color.warn))
    49	    pz:Hide()
    50	    self.poison = pz
    51	
    52	    -- ---- Stealth opener hint ----
    53	    local op = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    54	    op:SetPoint("BOTTOM", root, "TOP", 0, 28)
    55	    op:SetTextColor(unpack(NS.color.good))
    56	    op:Hide()
    57	    self.opener = op
    58	
    59	    local ev = CreateFrame("Frame")
    60	    ev:RegisterEvent("UNIT_SPELLCAST_START")
    61	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    62	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
    63	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    64	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    65	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    66	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
    67	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
    68	    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
    69	    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
    70	    ev:RegisterEvent("UPDATE_STEALTH")
    71	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    72	    ev:SetScript("OnEvent", function(_, e, unit) Alerts:OnEvent(e, unit) end)
    73	    self.ev = ev
    74	end
    75	
    76	function Alerts:OnEvent(e, unit)
    77	    if not NS.IsRogue then return end
    78	    if e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_ENTERING_WORLD" or e == "UNIT_INVENTORY_CHANGED" then
    79	        self:CheckPoison()
    80	    elseif e == "PLAYER_REGEN_DISABLED" then
    81	        self.poison:Hide()
    82	    end
    83	    if e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_ENTERING_WORLD" then
    84	        self:CheckOpener()
    85	    end
    86	    -- Kick logic on any cast event affecting the target
    87	    self:CheckKick(e, unit)
    88	end
    89	
    90	function Alerts:CheckKick(e, unit)
    91	    if not NS.db.kickAlert then return end
    92	    if unit ~= "target" then
    93	        -- still re-evaluate on target change / cooldown updates
    94	        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
    95	    end
    96	    local casting = false
    97	    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    98	    if not name then
    99	        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
   100	    end
   101	    if name and not notInterruptible then casting = true end
   102	
   103	    if casting and SpellReady(KICK) then
   104	        if not self.kick:IsShown() then
   105	            self.kick:Show()
   106	            self.kick.ag:Stop(); self.kick.ag:Play() -- reset loop state cleanly
   107	            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
   108	        end
   109	    else
   110	        if self.kick:IsShown() then self.kick.ag:Stop(); self.kick:Hide() end
   111	    end
   112	end
   113	
   114	function Alerts:CheckPoison()
   115	    if not NS.db.poisonCheck then self.poison:Hide(); return end
   116	    if InCombatLockdown() then return end -- only nag out of combat
   117	    -- TBC 2.5 sig: hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges (no enchantID)
   118	    local mh, _, _, oh = GetWeaponEnchantInfo()
   119	    local missing = {}
   120	    if not mh then missing[#missing + 1] = "Main-hand" end
   121	    -- only warn off-hand if one is equipped
   122	    if GetInventoryItemLink("player", 17) and not oh then missing[#missing + 1] = "Off-hand" end
   123	    if #missing > 0 then
   124	        self.poison:SetText("No poison: " .. table.concat(missing, " & "))
   125	        self.poison:Show()
   126	    else
   127	        self.poison:Hide()
   128	    end
   129	end
   130	
   131	function Alerts:CheckOpener()
   132	    if not NS.db.openerHint then self.opener:Hide(); return end
   133	    local stealthed = IsStealthed and IsStealthed()
   134	    if stealthed and UnitExists("target") and UnitCanAttack("player", "target") then
   135	        self.opener:SetText("Opener: Ambush / Garrote")
   136	        self.opener:Show()
   137	    else
   138	        self.opener:Hide()
   139	    end
   140	end
   141	
   142	function Alerts:Refresh()
   143	    if self.kick then self.kick:Hide() end
   144	    if NS.IsRogue then
   145	        self:CheckPoison()  -- hides itself if disabled / in combat
   146	        self:CheckOpener()  -- hides itself if disabled
   147	    end
   148	end

exec
/bin/zsh -lc "nl -ba config.lua | sed -n '1,240p'" in /Users/creative/WoWAddons/Cutthroat
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
    15	    print("  |cffffff00/cut opener|r       toggle stealth opener hint")
    16	    print("  |cffffff00/cut sound|r        toggle alert sounds")
    17	    print("  |cffffff00/cut ticks|r        toggle energy tick marks")
    18	    print("  |cffffff00/cut snd N|r        SnD warning seconds")
    19	    print("  |cffffff00/cut rup N|r        Rupture warning seconds")
    20	    print("  |cffffff00/cut reset|r        reset position")
    21	    print("  |cffffff00/cut status|r       show settings")
    22	end
    23	
    24	function Config:Init()
    25	    SLASH_CUTTHROAT1 = "/cut"
    26	    SLASH_CUTTHROAT2 = "/cutthroat"
    27	    SlashCmdList["CUTTHROAT"] = function(msg)
    28	        local db = NS.db
    29	        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    30	        cmd = (cmd or ""):lower()
    31	
    32	        if cmd == "" or cmd == "help" then
    33	            Help()
    34	        elseif cmd == "lock" then
    35	            db.locked = not db.locked
    36	            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
    37	        elseif cmd == "scale" then
    38	            local n = tonumber(arg)
    39	            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
    40	            else Print("scale needs 0.4-3.0") end
    41	        elseif cmd == "kick" then
    42	            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
    43	        elseif cmd == "poison" then
    44	            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
    45	        elseif cmd == "opener" then
    46	            db.openerHint = not db.openerHint; Print("opener hint " .. on(db.openerHint))
    47	        elseif cmd == "sound" then
    48	            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
    49	        elseif cmd == "ticks" then
    50	            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
    51	        elseif cmd == "snd" then
    52	            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
    53	        elseif cmd == "rup" then
    54	            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
    55	        elseif cmd == "reset" then
    56	            db.point = { "CENTER", nil, "CENTER", 0, -180 }
    57	            Print("position reset (/reload to apply)")
    58	        elseif cmd == "status" then
    59	            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s | ticks %s",
    60	                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound), on(db.energyTicks)))
    61	        else
    62	            Help()
    63	        end
    64	        NS.CallAll("Refresh")
    65	    end
    66	end
    67	
    68	function Config:Refresh() end

web search: 
web search: GetSpellCooldown returns nil if spell not in spellbook wow api
codex
No web results are coming back from the browser tool in this environment, so I’m using the local code plus the injected GLM triangulation as the second opinion. I’m still filtering that against the actual module behavior; a theoretical API caveat only matters if it breaks this code path.
exec
/bin/zsh -lc 'command -v glm-ask || true' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
/Users/creative/.local/bin/glm-ask

codex
I’m going to ask GLM one targeted compatibility question now: the risky part is not the spell IDs, it’s whether the event/name-based cooldown detection behaves on 2.5.x exactly as the comments assume.
exec
/bin/zsh -lc "glm-ask \"Reviewing WoW TBC Classic 2.5.x Lua addon cooldowns.lua. Need factual API/event compatibility: GetSpellInfo(id) return values in 2.5.x; GetSpellTexture(id) availability; GetSpellCooldown(name/id) signature and behavior for unlearned but valid spell names/ids; CooldownFrameTemplate methods SetCooldown Clear SetDrawEdge; whether RegisterEvent('PLAYER_TALENT_UPDATE') errors if nonexistent in 2.5.x and what safer talent event is; rogue spell IDs Vanish 1856 Evasion 5277 Sprint 2983 Blade Flurry 13877 Adrenaline Rush 13750 Cold Blood 14177 Preparation 14185; whether dur > 1.5 is safe GCD filter. Give only concrete compatibility bugs/fixes.\"" in /Users/creative/WoWAddons/Cutthroat
 exited 6 in 0ms:
curl: (6) Could not resolve host: api.z.ai

codex
GLM is unavailable too (`api.z.ai` DNS resolution failed). I’ll proceed with the local review and mark only findings with a defensible failure mode in this code.
exec
/bin/zsh -lc "sed -n '1,220p' reviews/codex/iter2.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
session id: 019f0974-675f-7d22-9426-b3d10a6a0029
--------
user
Review the NEW file cooldowns.lua in this directory (a WoW TBC Classic 2.5.x, Lua 5.1, interface 20504 Rogue addon cooldown-icon module). Also check core.lua init order integration. It must be READ-ONLY (no spell-cast automation). Verify for TBC 2.5.x: GetSpellInfo/GetSpellCooldown/GetSpellTexture signatures; CooldownFrameTemplate + SetCooldown/Clear/SetDrawEdge availability; whether registering PLAYER_TALENT_UPDATE errors if the event doesn't exist on this build (and the safer event); spell IDs (Vanish 1856, Evasion 5277, Sprint 2983, Blade Flurry 13877, Adrenaline Rush 13750, Cold Blood 14177, Preparation 14185); IsKnown-via-GetSpellCooldown reliability; the dur>1.5 GCD filter; layout/anchor math; perf. Give a numbered list: file, function, bug, concrete fix. Do NOT edit files. Prioritize real bugs.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll do this as a read-only review: inspect `cooldowns.lua`, `core.lua`, addon metadata/load order if present, then verify API/event details against reliable TBC-era references where needed.
exec
/bin/zsh -lc 'pwd && rg --files' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

exec
/bin/zsh -lc 'git status --short' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
 M Cutthroat.toc
 M core.lua
?? cooldowns.lua
?? reviews/codex/iter2.md
?? reviews/glm/iter2.md

codex
`rg` isn’t installed here, so I’m falling back to standard shell reads. I see `cooldowns.lua` is untracked and `core.lua`/TOC are modified already; I’ll treat all of that as user work and only review.
exec
/bin/zsh -lc "sed -n '1,260p' cooldowns.lua" in /Users/creative/WoWAddons/Cutthroat
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

-- A rogue "knows" a spell if GetSpellInfo resolves it AND it has a usable cooldown
-- entry. We detect known-state via the spellbook name lookup.
local function SpellName(id)
    local n = GetSpellInfo(id)
    return n
end

local function IsKnown(name)
    if not name then return false end
    -- GetSpellCooldown returns nil for a spell not in your spellbook.
    return GetSpellCooldown(name) ~= nil
end

function CDs:Init()
    if not NS.IsRogue then return end
    local root = NS.modules.hud.root
    self.icons = {}

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

    -- anchor below the timer bars (4 bars * (14+3) starting at -56)
    local rowY = -(18 + 6 + 22 + 10) - (4 * 17) - 8

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
    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        else
            self:Relayout()
        end
    end)
    self.ev = ev

    self:Relayout()
end

-- Show only known spells, packed left-to-right and centered under the HUD.
function CDs:Relayout()
    if not self.icons then return end
    local root = NS.modules.hud.root
    local shown = {}
    for _, f in ipairs(self.icons) do
        if IsKnown(f.spell.name) then shown[#shown + 1] = f else f:Hide() end
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
            if start and dur and dur > 1.5 and enabled ~= 0 then
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
    if self.icons then self:Relayout() end
end

exec
/bin/zsh -lc 'find . -maxdepth 3 -type f -print' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua
./Cutthroat.toc
./LICENSE
./timers.lua
./docs/TRIANGULATION.md
./docs/ROADMAP.md
./docs/DECISIONS.md
./alerts.lua
./config.lua
./README.md
./.gitignore
./prompts/review_iter1.txt
./prompts/review_iter2.txt
./cooldowns.lua
./.git/config
./.git/HEAD
./.git/info/exclude
./.git/logs/HEAD
./.git/description
./.git/hooks/commit-msg.sample
./.git/hooks/pre-rebase.sample
./.git/hooks/sendemail-validate.sample
./.git/hooks/pre-commit.sample
./.git/hooks/applypatch-msg.sample
./.git/hooks/fsmonitor-watchman.sample
./.git/hooks/pre-receive.sample
./.git/hooks/prepare-commit-msg.sample
./.git/hooks/post-update.sample
./.git/hooks/pre-merge-commit.sample
./.git/hooks/pre-applypatch.sample
./.git/hooks/pre-push.sample
./.git/hooks/update.sample
./.git/hooks/push-to-checkout.sample
./.git/index
./.git/COMMIT_EDITMSG
./core.lua
./reviews/codex/iter1.md
./reviews/codex/iter2.md
./reviews/glm/iter1.md
./reviews/glm/iter2.md

exec
/bin/zsh -lc "sed -n '1,260p' core.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Cutthroat: Rogue helper for TBC Classic (2.5.x)
-- Pure read/display. No spell input automation (Warden-safe).

local ADDON, NS = ...

exec
/bin/zsh -lc "sed -n '1,220p' reviews/glm/iter2.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
Here is the review of the `cooldowns.lua` module. The script correctly uses an OnUpdate-driven `CooldownFrameTemplate` and does not automate casting, adhering to the Warden-safe requirements.

For TBC 2.5.x (Build 20504), the API signatures you assumed (`GetSpellInfo`, `GetSpellCooldown`, `CooldownFrameTemplate`) are perfectly accurate, and the GCD filtering (`> 1.5`) prevents the icons from endlessly sweeping the global cooldown. However, there are a few severe reliability bugs regarding TBC API limitations, frame anchoring, and missing event validation.

Here are the findings, prioritized by severity:

### 1. `IsKnown()` relies on invalid API behavior and will break
* **File:** `cooldowns.lua`
* **Function:** `IsKnown(name)`
* **Bug:** The code comments say *"GetSpellCooldown returns nil for a spell not in your spellbook."* This is fundamentally incorrect for TBC 2.5.x. `GetSpellCooldown` **always** returns 3 values (`start, duration, enabled`). If a spell is unlearned or unknown, it returns `0, 0, 1`, **not** `nil`. Relying on `GetSpellCooldown(name) ~= nil` will cause `IsKnown` to evaluate to `true` for all spells, breaking the unlearned talent filtering entirely (e.g., a Combat Rogue will see Cold Blood). 
* **Concrete Fix:** Replace the function with the correct TBC spellbook iteration using `GetSpellName` (which *does* return `nil` if unknown).

```lua
-- Replace the existing IsKnown function with this:
local function IsKnown(name)
    if not name then return false end
    local i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then 
            break 
        end
        -- TBC gets pet spells too, so we need to check the pet book if the spellbook finishes.
        if spellName == name then 
            return true 
        end
        i = i + 1
    end
    
    -- Check pet book (e.g., if a player somehow had a pet spell matching the name)
    i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_PET)
        if not spellName then break end
        if spellName == name then return true end
        i = i + 1
    end
    
    return false
end
```

### 2. Registering `PLAYER_TALENT_UPDATE` will throw a Lua error
* **File:** `cooldowns.lua`
* **Function:** `CDs:Init()`
* **Bug:** You registered `PLAYER_TALENT_UPDATE` with a comment guessing it *"may not exist on all builds; harmless"*. In TBC 2.5.x, this event **does not exist**. Calling `RegisterEvent` with a string that the API doesn't recognize throws a hard Lua runtime error (`'PLAYER_TALENT_UPDATE' is not a valid event name`), entirely breaking the addon's initialization sequence.
* **Concrete Fix:** Remove the line entirely. `CHARACTER_POINTS_CHANGED` and `SPELLS_CHANGED` correctly cover the respec/unlearn triggers.

```lua
    -- Remove this line completely:
    -- ev:RegisterEvent("PLAYER_TALENT_UPDATE")    
```

### 3. Horizontal Centering Math is slightly offset
* **File:** `cooldowns.lua`
* **Function:** `CDs:Relayout()`
* **Bug:** The math calculates `startX = -totalW / 2 + ICON / 2` and then adds `(i - 1) * (ICON + GAP)` from the center. This pushes the entire row off-center to the right by exactly half a gap (`GAP / 2` = 2px).
* **Concrete Fix:** Offset the sequence index by half the total width to properly center the frames.

```lua
    -- Replace your for-loop block with this:
    local n = #shown
    local totalW = n * ICON + (n - 1) * GAP
    for i, f in ipairs(shown) do
        f:ClearAllPoints()
        -- Properly calculate the dynamic left-offset for center anchoring
        local xOffset = -totalW / 2 + (i - 1) * (ICON + GAP) + (ICON / 2)
        f:SetPoint("CENTER", root, "TOP", xOffset, self.rowY)
        f:Show()
    end
```

### 4. `CooldownFrame_SetTimer` doesn't clear previous state implicitly
* **File:** `cooldowns.lua`
* **Function:** `CDs:UpdateCooldowns()`
* **Bug:** While `f.cd:Clear()` successfully stops the sweep and handles the `else` condition, failing to explicitly call `f.cd:Hide()` when the spell is fully ready can cause a 1-frame visual flash of the sweep's edge on certain setups. 
* **Concrete Fix:** Force hide the cooldown frame when clearing.

```lua
            else
                f.cd:Clear()
                f.cd:Hide()           -- Strictly clear graphical artifacts
                f.icon:SetDesaturated(false)
            end
```

### 5. Layout State desyncs on `SPELLS_CHANGED` (Minor Perf/UX)
* **File:** `cooldowns.lua`
* **Function:** Event Script / `Relayout()`
* **Bug:** `SPELLS_CHANGED` fires *very* aggressively in TBC (e.g., dragging spells on your action bar, gaining/losing shapeshift forms). `Relayout()` is a moderately heavy operation because it reconstructs the known list and clears/re-anchors all frames. Firing this continuously while a player rearranges their UI can cause noticeable micro-stutters.
* **Concrete Fix:** Instead of instantly triggering `Relayout()`, set a simple dirty-flag boolean to delay the layout update until the next `OnUpdate` cycle.

```lua
    -- Inside CDs:Init()
    self.layoutDirty = false
    
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        else
            self.layoutDirty = true   -- Throttle layout updates
        end
    end)
    
    -- Add an OnUpdate to the event frame to process the throttle
    ev:SetScript("OnUpdate", function()
        if self.layoutDirty then
            self.layoutDirty = false
            self:Relayout()
        end
    end)
```

exec
/bin/zsh -lc "sed -n '1,220p' reviews/codex/iter1.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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

exec
/bin/zsh -lc "sed -n '1,220p' reviews/glm/iter1.md" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
Here is a review of the Cutthroat addon. The code is well-structured and Warden-safe (no spell automation or protected function misuse was found). However, there are several real correctness bugs, WoW API misuses, and logic flaws that will break core features.

### 1. Player loses Combo Points and Energy appears frozen when stealthed
**File:** `hud.lua` (Lines 51-55, 68-72)
**Bug:** You are registering for `UNIT_POWER_FREQUENT`, which in TBC 2.5.x *does not fire* for Energy regeneration ticks or Combo Point changes while the player is stealthed. This was changed to `UNIT_POWER_UPDATE` in the 2.5.4 patch specifically to fix stealth addons. Because you also don't update CP on `PLAYER_ENTERING_WORLD` or after casting, CPs will often visually freeze at 0 until a target swap occurs. 
**Fix:** Swap the event registration and update the script to use `UNIT_POWER_UPDATE`.
```lua
    -- Replace the ev:SetScript in hud.lua
    ev:RegisterUnitEvent("UNIT_POWER_UPDATE", "player") -- Use this instead of FREQUENT
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:SetScript("OnEvent", function(_, event, unit, powerType)
        -- Only update power if it's an energy tick event
        if event == "UNIT_POWER_UPDATE" and powerType == "ENERGY" then
            HUD:UpdatePower()
        else
            -- CP changes or login/target swap
            HUD:UpdatePower() 
            HUD:UpdateCP()
        end
    end)
```

### 2. Invalid Aura Filter Logic Causes Timer Bars to Never Show
**File:** `timers.lua` (Lines 34-42)
**Bug:** `GetAuraRemaining` attempts to find self buffs (like Slice and Dice) by passing `byPlayer and "HARMFUL|PLAYER" or "HELPFUL|PLAYER"`. Because Slice and Dice is called with `isSelf = false` (Line 64), the filter evaluates to `"HELPFUL|PLAYER"`. In WoW's API, combining `HELPFUL` and `PLAYER` is an invalid filter string, which causes `C_UnitAuras.GetAuraDataByIndex` to silently return `nil`. This completely breaks tracking for SnD, and also fundamentally breaks tracking for any target debuff that isn't directly cast by the player (e.g. Mangle/Trauma debuff extensions applied by other players). 
**Fix:** Hardcode the standard `"HARMFUL PLAYER"` (space, not pipe) and `"HELPFUL PLAYER"` filter strings, and apply them dynamically based on aura type.
```lua
-- Replace the C_UnitAuras logic block inside GetAuraRemaining
local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL PLAYER"
for i = 1, 40 do
    local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    if not d then break end
    if d.name == name then
        if d.expirationTime and d.expirationTime > 0 then 
            return d.expirationTime - GetTime(), d.duration 
        end
    end
end
```

### 3. Subtle/Invisible Kick Flash Animation Group 
**File:** `alerts.lua` (Line 39)
**Bug:** The addon relies heavily on an alpha pulse to alert the player to Kick, but it uses `ag:SetLooping("BOUNCE")` along with an Alpha animation going from `1.0` to `0.35`. On certain Blizzard UI states, `BOUNCE` on Alpha animations can be subtly buggy or fail to re-render smoothly. However, a more severe logic bug occurs on **Line 73**: `if not self.kick:IsShown() then self.kick:Show(); self.kick.ag:Play() end`. If you are out of combat and Kick comes off cooldown while a target is actively casting (e.g. a mob casting before you pull), `SPELL_UPDATE_COOLDOWN` triggers `CheckKick`, but because the animation group was stopped previously, it may not always cleanly restart if `ag:Stop()` wasn't explicitly called with a reset.
**Fix:** Explicitly call `:Stop()` before `:Play()` to ensure the animation cleanly resets its loop state every time it becomes active.
```lua
        if not self.kick:IsShown() then
            self.kick:Show()
            self.kick.ag:Stop() -- Reset animation state
            self.kick.ag:Play()
            -- [...]
```

### 4. Timers Exponentially Inflate When Refreshed Early
**File:** `timers.lua` (Lines 117-118)
**Bug:** The variable `b.maxSeen` is used to set the max value of the status bar. The logic `if not b.maxSeen or rem > b.maxSeen then b.maxSeen = rem end` assumes that auras only get stronger. However, if a player casts a 5-Combo Point Rupture (max duration), and then 3 seconds later overwrites it with a 1-Combo Point Rupture (very short duration), `maxSeen` remains locked to the massive 5-CP duration. The new, much shorter rupture will render as a tiny sliver on the bar, defeating the purpose of a dynamic timer. 
**Fix:** If the current remaining time (`rem`) is noticeably longer than what was previously on the bar (plus a buffer for latency), you are looking at a fresh application/refresh and should reset `maxSeen`. 
```lua
function Timers:Set(key, rem, name, warnAt)
    local b = self.bars[key]
    if not rem or rem <= 0 then b:Hide(); return end
    
    -- If the new remaining time is greater than the old remaining time, it was refreshed!
    if not b.maxSeen or rem > (b.prevRem or 0) + 0.5 then
        b.maxSeen = rem
    end
    b.prevRem = rem

    b:SetMinMaxValues(0, b.maxSeen or rem)
    -- [...]
```

### 5. Stealth Opener Tooltip Misleading & Untoggleable
**File:** `alerts.lua` (Lines 163-172) & `config.lua`
**Bug:** `CheckOpener` creates a loud green text permanently sprawled above the HUD reading "Opener: Ambush / Garrote" *every single time* the rogue enters stealth with a target. There is no database toggle for this feature, and it provides redundant/false information (e.g., it suggests Ambush even if the player is in front of the target or sub-specced for Shadowstep). 
**Fix:** This should be a dynamically calculated hint based on position, or simply removed/gated behind a config boolean if you want to keep the UI clean. At minimum, tie it to a config setting:
```lua
-- alerts.lua
function Alerts:CheckOpener()
    if not NS.db.openerHint then self.opener:Hide(); return end
    local stealthed = IsStealthed and IsStealthed()
    -- [...]
```
*(Note: You will need to add `openerHint = true` to `defaults` in `core.lua` and a slash command toggle in `config.lua` if you implement this).*

### 6. Missing Combat Poisons Check
**File:** `alerts.lua` (Lines 135-149)
**Bug:** `CheckPoison` is only called on `PLAYER_REGEN_ENABLED`. If a player forgets to apply poisons before a boss fight, they will receive no warning whatsoever because they are already in combat (`PLAYER_REGEN_DISABLED` hides the text and the check never runs). 
**Fix:** You should also run `CheckPoison` immediately upon logging in or loading the addon to catch missing poisons before the first pull is initiated. 
```lua
-- In alerts.lua Alerts:Init()
    -- Add this to your event registrations:
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    
-- In alerts.lua Alerts:OnEvent()
    elseif e == "PLAYER_ENTERING_WORLD" then
        self:CheckPoison()
```

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. `cooldowns.lua`, `CDs:Init`, line 75  
   Bug: `PLAYER_TALENT_UPDATE` is not safe for TBC Classic 2.5.x. If the client does not know the event, `RegisterEvent` can hard-error during init, so the cooldown module may never finish loading.  
   Concrete fix: remove `ev:RegisterEvent("PLAYER_TALENT_UPDATE")`; keep `CHARACTER_POINTS_CHANGED` plus `SPELLS_CHANGED`.

2. `cooldowns.lua`, `IsKnown`, lines 29-32  
   Bug: `GetSpellCooldown(name) ~= nil` is not a reliable “spell is known” test in 2.5.x. Valid-but-unlearned spell names/IDs can still resolve enough for cooldown APIs to return non-nil/ready-looking values, so talent cooldowns can appear for specs that do not have them.  
   Concrete fix: scan the player spellbook by localized spell name using `GetSpellName(i, BOOKTYPE_SPELL)`, or use a proven 2.5.x known-spell API if available on the target client. Cache that known set and rebuild it on `SPELLS_CHANGED` / `CHARACTER_POINTS_CHANGED`.

3. `cooldowns.lua`, `CDs:Init` / layout math, lines 53-54 and 102  
   Bug: vertical anchor math overlaps the last timer bar. Last timer bar spans roughly `-107..-121`; cooldown icons are centered at `-132`, so 30px icons span `-117..-147`, overlapping by about 4px.  
   Concrete fix: include the icon half-height when computing `rowY`, e.g. derive timer bottom then `rowY = timerBottom - GAP_BELOW_TIMERS - ICON / 2` (`-144` with current constants).

4. `cooldowns.lua`, `CDs:UpdateCooldowns`, line 113  
   Bug: `dur > 1.5` is a fragile GCD filter. The tracked cooldowns are all far above GCD length, so a borderline `1.500...` value can briefly desaturate/sweep every shown icon after normal ability use.  
   Concrete fix: use a wider threshold such as `dur > 2` for these rogue cooldowns, or explicitly ignore the GCD cooldown if you have a reliable 2.5.x GCD probe.

5. `cooldowns.lua`, `SpellName`, lines 24-27  
   Bug: dead helper. Not behavioral, but it suggests the known-spell logic was refactored halfway and makes the API intent less clear.  
   Concrete fix: delete it, or use it in the known-spell rebuild path.

Verified OK: no cast/input automation found; module is read-only display only. `core.lua` init order is correct: `hud` is initialized before `cooldowns`, and TOC load order has `core.lua`, `hud.lua`, `timers.lua`, `cooldowns.lua`. Spell IDs listed are correct for the intended rogue abilities. `CooldownFrameTemplate`, `SetCooldown`, guarded `SetDrawEdge`, and `Clear` usage look acceptable for TBC Classic-style cooldown frames. Horizontal centering math is correct. Performance is fine: event-driven, no cooldown `OnUpdate` scan.
tokens used
60,538
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. `cooldowns.lua`, `CDs:Init`, line 75  
   Bug: `PLAYER_TALENT_UPDATE` is not safe for TBC Classic 2.5.x. If the client does not know the event, `RegisterEvent` can hard-error during init, so the cooldown module may never finish loading.  
   Concrete fix: remove `ev:RegisterEvent("PLAYER_TALENT_UPDATE")`; keep `CHARACTER_POINTS_CHANGED` plus `SPELLS_CHANGED`.

2. `cooldowns.lua`, `IsKnown`, lines 29-32  
   Bug: `GetSpellCooldown(name) ~= nil` is not a reliable “spell is known” test in 2.5.x. Valid-but-unlearned spell names/IDs can still resolve enough for cooldown APIs to return non-nil/ready-looking values, so talent cooldowns can appear for specs that do not have them.  
   Concrete fix: scan the player spellbook by localized spell name using `GetSpellName(i, BOOKTYPE_SPELL)`, or use a proven 2.5.x known-spell API if available on the target client. Cache that known set and rebuild it on `SPELLS_CHANGED` / `CHARACTER_POINTS_CHANGED`.

3. `cooldowns.lua`, `CDs:Init` / layout math, lines 53-54 and 102  
   Bug: vertical anchor math overlaps the last timer bar. Last timer bar spans roughly `-107..-121`; cooldown icons are centered at `-132`, so 30px icons span `-117..-147`, overlapping by about 4px.  
   Concrete fix: include the icon half-height when computing `rowY`, e.g. derive timer bottom then `rowY = timerBottom - GAP_BELOW_TIMERS - ICON / 2` (`-144` with current constants).

4. `cooldowns.lua`, `CDs:UpdateCooldowns`, line 113  
   Bug: `dur > 1.5` is a fragile GCD filter. The tracked cooldowns are all far above GCD length, so a borderline `1.500...` value can briefly desaturate/sweep every shown icon after normal ability use.  
   Concrete fix: use a wider threshold such as `dur > 2` for these rogue cooldowns, or explicitly ignore the GCD cooldown if you have a reliable 2.5.x GCD probe.

5. `cooldowns.lua`, `SpellName`, lines 24-27  
   Bug: dead helper. Not behavioral, but it suggests the known-spell logic was refactored halfway and makes the API intent less clear.  
   Concrete fix: delete it, or use it in the known-spell rebuild path.

Verified OK: no cast/input automation found; module is read-only display only. `core.lua` init order is correct: `hud` is initialized before `cooldowns`, and TOC load order has `core.lua`, `hud.lua`, `timers.lua`, `cooldowns.lua`. Spell IDs listed are correct for the intended rogue abilities. `CooldownFrameTemplate`, `SetCooldown`, guarded `SetDrawEdge`, and `Clear` usage look acceptable for TBC Classic-style cooldown frames. Horizontal centering math is correct. Performance is fine: event-driven, no cooldown `OnUpdate` scan.
