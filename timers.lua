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
