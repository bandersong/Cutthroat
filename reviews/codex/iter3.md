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
session id: 019f097b-eae8-7580-a3fd-107a5651632c
--------
user
Review the energy regen-tick predictor in this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. Read hud.lua (energy.spark, HUD:UpdatePower gain-detection, HUD:UpdateEnergyTick) and how timers.lua Render calls it every ~0.05s. READ-ONLY feature, no automation. Verify for TBC 2.5.x: (1) is energy regen really a ~2.0s tick interval? (2) gain-detection via positive UnitPower delta — false resets from Relentless Strikes/Thistle Tea/refunds, does it matter? (3) UnitPower/UnitPowerMax + Enum.PowerType.Energy-or-3 fallback correctness; (4) spark SetPoint anchor math (TOP/BOTTOM pinned to TOPLEFT/BOTTOMLEFT + x offset) and end-clipping; (5) polling UpdatePower at 0.05s causing false resets/perf; (6) cap and Adrenaline Rush behavior; (7) nil-safety (lastEnergy nil first call). Numbered list: file, function, bug, concrete fix. Do NOT edit. Real bugs first.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll review this as code review only: read `hud.lua` and `timers.lua`, verify the exact implementation against TBC behavior, and return findings ordered by real impact. No edits.
exec
/bin/zsh -lc "sed -n '1,220p' timers.lua" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "rg -n \"energy\\.spark|UpdatePower|UpdateEnergyTick|Render|UnitPower|UnitPowerMax|Enum\\.PowerType|Adrenaline|13750|lastEnergy\" hud.lua timers.lua" in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
zsh:1: command not found: rg

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
    rnd = { name = "Rend",           isSelf = false, color = "warn" }, -- harmless if unused
}

local BAR_W, BAR_H = 200, 14

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
        b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
        b.bg:SetColorTexture(0, 0, 0, 0.6)
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.label:SetPoint("LEFT", 4, 0); b.label:SetText(TRACK[key].name)
        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.time:SetPoint("RIGHT", -4, 0)
        b:Hide()
        b:SetScript("OnHide", function(s) s.warned = false end) -- set ONCE, not per tick
        self.bars[key] = b
    end

    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
    local scan = CreateFrame("Frame")
    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
    scan:SetScript("OnEvent", function() self:Scan() end)
    self.scan = scan

    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
    self.elapsed = 0
    root:SetScript("OnUpdate", function(_, dt)
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
            if b:IsShown() then b:Hide() end
        else
            local warnAt = (key == "snd" and NS.db.sndWarn)
                or (key == "rup" and NS.db.ruptureWarn) or 2
            local dur = (c.dur and c.dur > 0) and c.dur or rem
            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
            b:SetValue(rem)
            b.time:SetText(string.format("%.1f", rem))
            if rem <= warnAt then
                b.label:SetTextColor(unpack(NS.color.bad))
                if not b.warned and NS.db.sound then
                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
                    b.warned = true
                end
            else
                b.label:SetTextColor(1, 1, 1)
                b.warned = false
            end
            if not b:IsShown() then b:Show() end
        end
    end
end

function Timers:Refresh() if self.cache then self:Scan() end end

exec
/bin/zsh -lc "sed -n '1,260p' hud.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
local ADDON, NS = ...

local HUD = NS:RegisterModule("hud", {})

local WIDTH, HEIGHT = 240, 18
local CP_SIZE, CP_GAP = 22, 6
local MAX_CP = 5

function HUD:Init()
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
    local e = UnitPower("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
    local m = UnitPowerMax("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
    self.energyMax = m > 0 and m or 100
    self.energy:SetMinMaxValues(0, self.energyMax)
    self.energy:SetValue(e)
    self.energy.text:SetText(e)
    -- a positive delta means a regen tick (or energy gain) just landed -> reset spark
    if self.lastEnergy and e > self.lastEnergy then
        self.lastTick = GetTime()
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
    local frac = (GetTime() - (self.lastTick or 0)) / 2.0
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
    local x = frac * self.energy:GetWidth()
    s:ClearAllPoints()
    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
    s:Show()
end

function HUD:UpdateCP()
    local cp = GetComboPoints("player", "target") or 0
    for i = 1, MAX_CP do
        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
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

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ve got the relevant code. `rg` is unavailable in this environment, so I’m using direct file reads and line numbering now to pin the findings precisely.
exec
/bin/zsh -lc "nl -ba hud.lua | sed -n '35,130p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
    61	    -- energy regen-tick spark: a thin marker sweeping the bar 0->100% over the
    62	    -- ~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
    63	    energy.spark = energy:CreateTexture(nil, "OVERLAY")
    64	    energy.spark:SetColorTexture(1, 1, 1, 0.85)
    65	    energy.spark:SetWidth(2)
    66	    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
    67	    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
    68	    energy.spark:Hide()
    69	    self.lastEnergy = nil
    70	    self.energyMax = 100
    71	    self.lastTick = 0
    72	
    73	    -- ---- Combo point pips ----
    74	    self.pips = {}
    75	    local totalW = MAX_CP * CP_SIZE + (MAX_CP - 1) * CP_GAP
    76	    local startX = (WIDTH - totalW) / 2
    77	    for i = 1, MAX_CP do
    78	        local pip = root:CreateTexture(nil, "ARTWORK")
    79	        pip:SetSize(CP_SIZE, CP_SIZE)
    80	        pip:SetPoint("TOPLEFT", root, "TOPLEFT", startX + (i - 1) * (CP_SIZE + CP_GAP), -(HEIGHT + 6))
    81	        pip:SetTexture("Interface\\ComboFrame\\ComboPoint")
    82	        pip:SetTexCoord(0, 0.375, 0, 1) -- the lit gem
    83	        pip:SetVertexColor(unpack(NS.color.cp))
    84	        pip:SetAlpha(0.15)
    85	        self.pips[i] = pip
    86	    end
    87	
    88	    -- Event-driven power updates, all unit-filtered to "player" so other units'
    89	    -- power changes never wake this handler. Combo points have no reliable
    90	    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
    91	    -- and registering a wrong event name errors) — they're polled in timers:Tick.
    92	    local ev = CreateFrame("Frame")
    93	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    94	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    95	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    96	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
    97	    self.ev = ev
    98	end
    99	
   100	function HUD:UpdatePower()
   101	    if not self.energy then return end
   102	    local e = UnitPower("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
   103	    local m = UnitPowerMax("player", Enum and Enum.PowerType and Enum.PowerType.Energy or 3)
   104	    self.energyMax = m > 0 and m or 100
   105	    self.energy:SetMinMaxValues(0, self.energyMax)
   106	    self.energy:SetValue(e)
   107	    self.energy.text:SetText(e)
   108	    -- a positive delta means a regen tick (or energy gain) just landed -> reset spark
   109	    if self.lastEnergy and e > self.lastEnergy then
   110	        self.lastTick = GetTime()
   111	    end
   112	    self.lastEnergy = e
   113	end
   114	
   115	-- Move the regen-tick spark; called every render frame from timers:Render.
   116	function HUD:UpdateEnergyTick()
   117	    local s = self.energy and self.energy.spark
   118	    if not s then return end
   119	    -- hide when disabled or at full energy (no tick to wait for)
   120	    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
   121	        s:Hide(); return
   122	    end
   123	    local frac = (GetTime() - (self.lastTick or 0)) / 2.0
   124	    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
   125	    local x = frac * self.energy:GetWidth()
   126	    s:ClearAllPoints()
   127	    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
   128	    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
   129	    s:Show()
   130	end

exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '80,145p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
   114	    NS.modules.hud:UpdateEnergyTick()
   115	
   116	    local now = GetTime()
   117	    for key, b in pairs(self.bars) do
   118	        local c = self.cache[key]
   119	        local rem = c and (c.exp - now) or 0
   120	        if not c or rem <= 0 then
   121	            self.cache[key] = nil
   122	            if b:IsShown() then b:Hide() end
   123	        else
   124	            local warnAt = (key == "snd" and NS.db.sndWarn)
   125	                or (key == "rup" and NS.db.ruptureWarn) or 2
   126	            local dur = (c.dur and c.dur > 0) and c.dur or rem
   127	            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
   128	            b:SetValue(rem)
   129	            b.time:SetText(string.format("%.1f", rem))
   130	            if rem <= warnAt then
   131	                b.label:SetTextColor(unpack(NS.color.bad))
   132	                if not b.warned and NS.db.sound then
   133	                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
   134	                    b.warned = true
   135	                end
   136	            else
   137	                b.label:SetTextColor(1, 1, 1)
   138	                b.warned = false
   139	            end
   140	            if not b:IsShown() then b:Show() end
   141	        end
   142	    end
   143	end
   144	
   145	function Timers:Refresh() if self.cache then self:Scan() end end

web search: 
web search: WoW TBC Classic rogue energy regenerates every 2 seconds 20 energy
web search: 
web search: site:warcraft.wiki.gg Energy WoW energy regenerates every two seconds rogue
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:108), `HUD:UpdatePower`  
   **Bug:** Any positive energy delta resets `lastTick`. That will false-sync on Relentless Strikes, Thistle Tea, Combat Potency, refunds, and other instant energy gains. It matters: the spark can be pushed off the real 2.0s server tick and then confidently show the wrong next tick.  
   **Concrete fix:** Track `delta = e - self.lastEnergy`; only resync on plausible regen ticks, e.g. `delta >= 10` or `>= 20` depending tolerance, and gate by time since last accepted tick: accept only when `now - lastTick >= ~1.7` or when no valid tick exists. Ignore small positive deltas.

2. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:123), `HUD:UpdateEnergyTick`  
   **Bug:** The 2.0s interval is correct for TBC energy regen: baseline rogue energy is discrete, roughly 20 energy per 2.0s tick. The predictor’s interval is right, but its phase source is weak because `lastTick` comes from any positive delta.  
   **Concrete fix:** Keep `/ 2.0`, but only update `lastTick` from filtered tick-like gains in `UpdatePower`.

3. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:125), `HUD:UpdateEnergyTick`  
   **Bug:** Spark end-clips at the right edge. `x = frac * width` can become exactly `width`, while the spark itself is 2px wide. With `TOP`/`BOTTOM` anchored to `TOPLEFT`/`BOTTOMLEFT`, the texture center/anchor behavior can place part of it outside the bar at `frac == 1`.  
   **Concrete fix:** Clamp with spark width: `x = min(frac * barWidth, barWidth - s:GetWidth())`, or anchor the spark by `CENTER` and clamp to half-width boundaries.

4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:87), `Timers:Render` plus [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:100), `HUD:UpdatePower`  
   **Bug:** Polling every ~0.05s is not itself a performance problem here; `UnitPower`/`UnitPowerMax` and one texture update are cheap. The real issue is behavioral: high-frequency polling makes the addon very likely to observe every proc/tea/refund as a positive delta and false-reset immediately.  
   **Concrete fix:** Leave polling if desired, but make resync filtering robust. Optionally stop calling `UpdatePower` from render and rely on `UNIT_POWER_FREQUENT`, with render only moving the spark.

5. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:102), `HUD:UpdatePower`  
   **Bug:** `Enum.PowerType.Energy or 3` fallback is fine for TBC 2.5.x. `UnitPower`/`UnitPowerMax` are the correct APIs. No real bug here.  
   **Concrete fix:** Optional cleanup only: define `local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3` once near the top for clarity.

6. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:104), `HUD:UpdatePower`  
   **Bug:** `UnitPowerMax` zero/nil is mostly handled by falling back to `100`, so no divide-by-zero exists because spark progress uses time, not `energyMax`. Minor risk: if `UnitPowerMax` returned nil, `m > 0` would error. In WoW this normally returns a number.  
   **Concrete fix:** Harden anyway: `self.energyMax = (m and m > 0) and m or 100`.

7. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:120), `HUD:UpdateEnergyTick`  
   **Bug:** At energy cap, spark hides. That is reasonable. Adrenaline Rush doubles energy regen rate, but it should not change the 2.0s tick phase; it changes energy gained per tick. Current code does not assume 20 energy per accepted tick, so AR itself is not a separate spark bug unless future filtering only accepts exactly 20.  
   **Concrete fix:** If adding delta filtering, accept larger tick gains during AR, e.g. `delta >= 10`/`>= 20`, not `delta == 20`. No need to alter the spark sweep interval for AR.

8. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:109), `HUD:UpdatePower`  
   **Bug:** First-call nil safety is okay. `if self.lastEnergy and e > self.lastEnergy then` prevents the first observed value from resetting `lastTick`.  
   **Concrete fix:** None required. Optional clarity: explicitly initialize and return on first sample so future edits do not break it:
   ```lua
   if self.lastEnergy == nil then
       self.lastEnergy = e
       return
   end
   ```
tokens used
20,327
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:108), `HUD:UpdatePower`  
   **Bug:** Any positive energy delta resets `lastTick`. That will false-sync on Relentless Strikes, Thistle Tea, Combat Potency, refunds, and other instant energy gains. It matters: the spark can be pushed off the real 2.0s server tick and then confidently show the wrong next tick.  
   **Concrete fix:** Track `delta = e - self.lastEnergy`; only resync on plausible regen ticks, e.g. `delta >= 10` or `>= 20` depending tolerance, and gate by time since last accepted tick: accept only when `now - lastTick >= ~1.7` or when no valid tick exists. Ignore small positive deltas.

2. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:123), `HUD:UpdateEnergyTick`  
   **Bug:** The 2.0s interval is correct for TBC energy regen: baseline rogue energy is discrete, roughly 20 energy per 2.0s tick. The predictor’s interval is right, but its phase source is weak because `lastTick` comes from any positive delta.  
   **Concrete fix:** Keep `/ 2.0`, but only update `lastTick` from filtered tick-like gains in `UpdatePower`.

3. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:125), `HUD:UpdateEnergyTick`  
   **Bug:** Spark end-clips at the right edge. `x = frac * width` can become exactly `width`, while the spark itself is 2px wide. With `TOP`/`BOTTOM` anchored to `TOPLEFT`/`BOTTOMLEFT`, the texture center/anchor behavior can place part of it outside the bar at `frac == 1`.  
   **Concrete fix:** Clamp with spark width: `x = min(frac * barWidth, barWidth - s:GetWidth())`, or anchor the spark by `CENTER` and clamp to half-width boundaries.

4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:87), `Timers:Render` plus [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:100), `HUD:UpdatePower`  
   **Bug:** Polling every ~0.05s is not itself a performance problem here; `UnitPower`/`UnitPowerMax` and one texture update are cheap. The real issue is behavioral: high-frequency polling makes the addon very likely to observe every proc/tea/refund as a positive delta and false-reset immediately.  
   **Concrete fix:** Leave polling if desired, but make resync filtering robust. Optionally stop calling `UpdatePower` from render and rely on `UNIT_POWER_FREQUENT`, with render only moving the spark.

5. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:102), `HUD:UpdatePower`  
   **Bug:** `Enum.PowerType.Energy or 3` fallback is fine for TBC 2.5.x. `UnitPower`/`UnitPowerMax` are the correct APIs. No real bug here.  
   **Concrete fix:** Optional cleanup only: define `local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3` once near the top for clarity.

6. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:104), `HUD:UpdatePower`  
   **Bug:** `UnitPowerMax` zero/nil is mostly handled by falling back to `100`, so no divide-by-zero exists because spark progress uses time, not `energyMax`. Minor risk: if `UnitPowerMax` returned nil, `m > 0` would error. In WoW this normally returns a number.  
   **Concrete fix:** Harden anyway: `self.energyMax = (m and m > 0) and m or 100`.

7. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:120), `HUD:UpdateEnergyTick`  
   **Bug:** At energy cap, spark hides. That is reasonable. Adrenaline Rush doubles energy regen rate, but it should not change the 2.0s tick phase; it changes energy gained per tick. Current code does not assume 20 energy per accepted tick, so AR itself is not a separate spark bug unless future filtering only accepts exactly 20.  
   **Concrete fix:** If adding delta filtering, accept larger tick gains during AR, e.g. `delta >= 10`/`>= 20`, not `delta == 20`. No need to alter the spark sweep interval for AR.

8. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:109), `HUD:UpdatePower`  
   **Bug:** First-call nil safety is okay. `if self.lastEnergy and e > self.lastEnergy then` prevents the first observed value from resetting `lastTick`.  
   **Concrete fix:** None required. Optional clarity: explicitly initialize and return on first sample so future edits do not break it:
   ```lua
   if self.lastEnergy == nil then
       self.lastEnergy = e
       return
   end
   ```
