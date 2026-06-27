-- Alerts: reactive reminders. ALERTS ONLY — never casts/queues a spell (Warden-safe).
--   * Kick reminder: target is casting an interruptible spell AND Kick is off CD -> flash icon.
--   * Poison check: out of combat, MH/OH missing a weapon enchant -> reminder text.
--   * Stealth opener: in stealth with a target -> show Ambush/Garrote hint.

local ADDON, NS = ...
local Alerts = NS:RegisterModule("alerts", {})

local KICK = GetSpellInfo and GetSpellInfo(1766) or "Kick" -- localized name

local function SpellReady(name)
    if not name then return false end
    -- don't nag to Kick when it can't actually be cast (e.g. not enough energy)
    local usable, noMana = IsUsableSpell(name)
    if not usable or noMana then return false end
    local start, dur, enabled = GetSpellCooldown(name)
    if not start or enabled == 0 then return false end
    return (start == 0) or (start + dur - GetTime() <= 0.2)
end

function Alerts:Init()
    local root = NS.modules.hud.root

    -- ---- Kick flash icon (center, above HUD) ----
    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
    kick:SetSize(64, 64)
    kick:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    kick.icon = kick:CreateTexture(nil, "ARTWORK")
    kick.icon:SetAllPoints()
    kick.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    kick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    kick.txt = kick:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    kick.txt:SetPoint("TOP", kick, "BOTTOM", 0, -2)
    kick.txt:SetText("KICK!")
    kick.txt:SetTextColor(unpack(NS.color.bad))
    kick:Hide()
    -- pulse
    local ag = kick:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    kick.ag = ag
    self.kick = kick

    -- ---- Poison reminder text ----
    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pz:SetPoint("BOTTOM", root, "TOP", 0, 6)
    pz:SetTextColor(unpack(NS.color.warn))
    pz:Hide()
    self.poison = pz

    -- ---- Stealth opener hint ----
    local op = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    op:SetPoint("BOTTOM", root, "TOP", 0, 28)
    op:SetTextColor(unpack(NS.color.good))
    op:Hide()
    self.opener = op

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("UNIT_SPELLCAST_START")
    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
    ev:RegisterEvent("UPDATE_STEALTH")
    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    ev:SetScript("OnEvent", function(_, e, unit) Alerts:OnEvent(e, unit) end)
    self.ev = ev
end

function Alerts:OnEvent(e, unit)
    if not NS.IsRogue then return end
    if e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_ENTERING_WORLD" or e == "UNIT_INVENTORY_CHANGED" then
        self:CheckPoison()
    elseif e == "PLAYER_REGEN_DISABLED" then
        self.poison:Hide()
    end
    if e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_ENTERING_WORLD" then
        self:CheckOpener()
    end
    -- Kick logic on any cast event affecting the target
    self:CheckKick(e, unit)
end

function Alerts:CheckKick(e, unit)
    if not NS.db.kickAlert then return end
    if unit ~= "target" then
        -- still re-evaluate on target change / cooldown updates
        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
    end
    local casting = false
    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if not name then
        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
    end
    if name and not notInterruptible then casting = true end

    if casting and SpellReady(KICK) then
        if not self.kick:IsShown() then
            self.kick:Show()
            self.kick.ag:Stop(); self.kick.ag:Play() -- reset loop state cleanly
            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
        end
    else
        if self.kick:IsShown() then self.kick.ag:Stop(); self.kick:Hide() end
    end
end

function Alerts:CheckPoison()
    if not NS.db.poisonCheck then self.poison:Hide(); return end
    if InCombatLockdown() then return end -- only nag out of combat
    -- TBC 2.5 sig: hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges (no enchantID)
    local mh, _, _, oh = GetWeaponEnchantInfo()
    local missing = {}
    if not mh then missing[#missing + 1] = "Main-hand" end
    -- only warn off-hand if one is equipped
    if GetInventoryItemLink("player", 17) and not oh then missing[#missing + 1] = "Off-hand" end
    if #missing > 0 then
        self.poison:SetText("No poison: " .. table.concat(missing, " & "))
        self.poison:Show()
    else
        self.poison:Hide()
    end
end

function Alerts:CheckOpener()
    if not NS.db.openerHint then self.opener:Hide(); return end
    local stealthed = IsStealthed and IsStealthed()
    if stealthed and UnitExists("target") and UnitCanAttack("player", "target") then
        self.opener:SetText("Opener: Ambush / Garrote")
        self.opener:Show()
    else
        self.opener:Hide()
    end
end

function Alerts:Refresh()
    if self.kick then self.kick:Hide() end
    if NS.IsRogue then
        self:CheckPoison()  -- hides itself if disabled / in combat
        self:CheckOpener()  -- hides itself if disabled
    end
end
