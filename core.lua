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
