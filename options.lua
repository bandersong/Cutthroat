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
