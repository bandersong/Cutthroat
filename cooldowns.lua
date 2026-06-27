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
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        else
            self.layoutDirty = true -- SPELLS_CHANGED fires aggressively; coalesce
        end
    end)
    -- coalesce bursty layout-affecting events into one rebuild per frame
    ev:SetScript("OnUpdate", function()
        if self.layoutDirty then
            self.layoutDirty = false
            self:RebuildKnown()
            self:Relayout()
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
