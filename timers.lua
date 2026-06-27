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
