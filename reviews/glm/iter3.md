Here is the review of the energy regen-tick predictor. The real bugs affecting gameplay and logic are listed first, followed by minor logic/flaws, and finally your specific questions answered.

### Real Bugs (Logic & Gameplay Impact)

**1. Hardcoded 2.0s divisor breaks the spark during Adrenaline Rush**
* **File:** `hud.lua` (`HUD:UpdateEnergyTick`)
* **Bug:** The spark sweep speed is hardcoded to `2.0` (`/ 2.0`). With the Adrenaline Rush talent, energy ticks every 1.0s. If active, the spark will take twice as long to cross the bar as it should, badly desyncing from actual regen and ruining the pooling predictor. 
* **Fix:** Calculate the tick interval dynamically using `GetPowerRegen()`. 
```lua
-- Add to top or inside function:
local regenRate = GetPowerRegen("player") or 5.0
local interval = 20.0 / regenRate
-- Replace "/ 2.0" with:
local frac = (GetTime() - (self.lastTick or 0)) / interval
```

**2. Positive Delta resets falsely on partial refunds & Thistle Tea**
* **File:** `hud.lua` (`HUD:UpdatePower`)
* **Bug:** The `e > self.lastEnergy` condition catches standard passive regen (+20), but it also catches Combat Potency procs (+3), Ruthlessness/Relentless Strikes refunds (+25), and Thistle Tea (+60). When a proc/refund happens in the middle of a regen cycle, the spark violently snaps back to 0% and has to sweep again. This introduces high-frequency visual jittery "resets" that defeat the addon's goal of smoothly tracking the cycle.
* **Fix:** Only reset the spark if the energy gain matches the standard tick intervals (multiples of 20), or disable resets during known energy injections.
```lua
-- Replace the if self.lastEnergy... block with:
if self.lastEnergy and e > self.lastEnergy then
    local diff = e - self.lastEnergy
    -- Only reset on standard 20-energy ticks
    if diff >= 20 and (diff % 20 == 0) then
        self.lastTick = GetTime()
    end
end
```

**3. Energy tick interval assumption (Question 1)**
* **Answer:** Yes, 2.0s is correct for standard TBC Rogue energy regeneration (10 energy per 1 sec, ticks every 2 sec for 20 energy). However, relying purely on 2.0s is the source of Bug #1 and #6.

**4. Loss of Anchor Reference causes Lua Error / Missing frame (Question 4)**
* **File:** `hud.lua` (`HUD:Init` setting drag hint backdrop)
* **Bug:** The backdrop texture is missing a reference: `root.bg = root:CreateTexture(...)` (the `root.bg =` is omitted in the provided code). While the addon won't hard crash from this alone, the frame is orphaned. A much more severe issue is in `OnDragStop`: `local a, _, rp, x, y = s:GetPoint()`. The 2nd return value is skipped with `_`, but it's passed to `NS.db.point` as `nil`. Later in `Init`, `p[2] and _G[p[2]]` fails because `p[2]` is nil, resetting the anchor entirely to `UIParent`.
* **Fix:** Store the global name properly, or clear the point if dragging globally.
```lua
-- Fix Init
root.bg = root:CreateTexture(nil, "BACKGROUND") -- Add assignment

-- Fix OnDragStop
root:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local a, relFrame, rp, x, y = s:GetPoint()
    local relName = relFrame and relFrame.GetName and relFrame:GetName() or nil
    NS.db.point = { a, relName, rp, x, y }
end)
```

### Minor Bugs / Cleanups

**5. Spark clipping and anchor math (Question 4)**
* **File:** `hud.lua` (`HUD:UpdateEnergyTick`)
* **Bug:** The math anchors the 2px-wide spark's exact center coordinate at `0` and `Width`. Because textures expand from their point, at 0% the left half of the 2px spark clips off the left edge of the bar, and at 100% the right half clips off the right edge.
* **Fix:** Offset the X coordinate by 1px to keep the entire spark inside the bar boundaries.
```lua
-- Replace x assignment and SetPoint with:
local x = (frac * self.energy:GetWidth()) - 1 -- offset for 2px width
s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
```

**6. No nil-safety holes (Question 7)**
* **Answer:** You actually got this perfectly right. The checks `if self.lastEnergy and e > self.lastEnergy`, `(self.lastTick or 0)`, and `(self.lastEnergy and self.lastEnergy >= self.energyMax)` cleanly prevent nil arithmetic errors on the first load and handles edge cases gracefully. No fix needed here.

**7. Performance & false resets from 0.05s polling (Question 5)**
* **Answer:** No performance issues. Calling `UnitPower` and `SetValue` in a 0.05s `OnUpdate` loop is extremely cheap and highly standard for WoW addons. False resets are mitigated because `UNIT_POWER_FREQUENT` fires almost instantly anyway, so the `Render` loop isn't catching things faster than the event handler would. 

### Answers to Edge Cases

**8. UnitPower & Enum Fallbacks (Question 3)**
* **Answer:** Your implementation `Enum and Enum.PowerType and Enum.PowerType.Energy or 3` is perfectly safe and correct for interface 20504. 

**9. Cap & Adrenaline Rush Behavior (Question 6)**
* **Answer:** At the energy cap (100), the logic `self.lastEnergy >= self.energyMax` triggers `s:Hide()`, cleanly hiding the spark. This is a great UX choice. However, during Adrenaline Rush, the sweep speed remains hardcoded to 2.0s instead of 1.0s, which breaks the predictor (see Bug #1).
