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
