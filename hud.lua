-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
local ADDON, NS = ...

local HUD = NS:RegisterModule("hud", {})

local WIDTH, HEIGHT = 240, 18
local CP_SIZE, CP_GAP = 22, 6
local MAX_CP = 5
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

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
    self.energyMax = (m and m > 0) and m or 100
    self.energy:SetMinMaxValues(0, self.energyMax)
    self.energy:SetValue(e)
    self.energy.text:SetText(e)

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
