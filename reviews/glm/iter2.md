Here is the review of the `cooldowns.lua` module. The script correctly uses an OnUpdate-driven `CooldownFrameTemplate` and does not automate casting, adhering to the Warden-safe requirements.

For TBC 2.5.x (Build 20504), the API signatures you assumed (`GetSpellInfo`, `GetSpellCooldown`, `CooldownFrameTemplate`) are perfectly accurate, and the GCD filtering (`> 1.5`) prevents the icons from endlessly sweeping the global cooldown. However, there are a few severe reliability bugs regarding TBC API limitations, frame anchoring, and missing event validation.

Here are the findings, prioritized by severity:

### 1. `IsKnown()` relies on invalid API behavior and will break
* **File:** `cooldowns.lua`
* **Function:** `IsKnown(name)`
* **Bug:** The code comments say *"GetSpellCooldown returns nil for a spell not in your spellbook."* This is fundamentally incorrect for TBC 2.5.x. `GetSpellCooldown` **always** returns 3 values (`start, duration, enabled`). If a spell is unlearned or unknown, it returns `0, 0, 1`, **not** `nil`. Relying on `GetSpellCooldown(name) ~= nil` will cause `IsKnown` to evaluate to `true` for all spells, breaking the unlearned talent filtering entirely (e.g., a Combat Rogue will see Cold Blood). 
* **Concrete Fix:** Replace the function with the correct TBC spellbook iteration using `GetSpellName` (which *does* return `nil` if unknown).

```lua
-- Replace the existing IsKnown function with this:
local function IsKnown(name)
    if not name then return false end
    local i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then 
            break 
        end
        -- TBC gets pet spells too, so we need to check the pet book if the spellbook finishes.
        if spellName == name then 
            return true 
        end
        i = i + 1
    end
    
    -- Check pet book (e.g., if a player somehow had a pet spell matching the name)
    i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_PET)
        if not spellName then break end
        if spellName == name then return true end
        i = i + 1
    end
    
    return false
end
```

### 2. Registering `PLAYER_TALENT_UPDATE` will throw a Lua error
* **File:** `cooldowns.lua`
* **Function:** `CDs:Init()`
* **Bug:** You registered `PLAYER_TALENT_UPDATE` with a comment guessing it *"may not exist on all builds; harmless"*. In TBC 2.5.x, this event **does not exist**. Calling `RegisterEvent` with a string that the API doesn't recognize throws a hard Lua runtime error (`'PLAYER_TALENT_UPDATE' is not a valid event name`), entirely breaking the addon's initialization sequence.
* **Concrete Fix:** Remove the line entirely. `CHARACTER_POINTS_CHANGED` and `SPELLS_CHANGED` correctly cover the respec/unlearn triggers.

```lua
    -- Remove this line completely:
    -- ev:RegisterEvent("PLAYER_TALENT_UPDATE")    
```

### 3. Horizontal Centering Math is slightly offset
* **File:** `cooldowns.lua`
* **Function:** `CDs:Relayout()`
* **Bug:** The math calculates `startX = -totalW / 2 + ICON / 2` and then adds `(i - 1) * (ICON + GAP)` from the center. This pushes the entire row off-center to the right by exactly half a gap (`GAP / 2` = 2px).
* **Concrete Fix:** Offset the sequence index by half the total width to properly center the frames.

```lua
    -- Replace your for-loop block with this:
    local n = #shown
    local totalW = n * ICON + (n - 1) * GAP
    for i, f in ipairs(shown) do
        f:ClearAllPoints()
        -- Properly calculate the dynamic left-offset for center anchoring
        local xOffset = -totalW / 2 + (i - 1) * (ICON + GAP) + (ICON / 2)
        f:SetPoint("CENTER", root, "TOP", xOffset, self.rowY)
        f:Show()
    end
```

### 4. `CooldownFrame_SetTimer` doesn't clear previous state implicitly
* **File:** `cooldowns.lua`
* **Function:** `CDs:UpdateCooldowns()`
* **Bug:** While `f.cd:Clear()` successfully stops the sweep and handles the `else` condition, failing to explicitly call `f.cd:Hide()` when the spell is fully ready can cause a 1-frame visual flash of the sweep's edge on certain setups. 
* **Concrete Fix:** Force hide the cooldown frame when clearing.

```lua
            else
                f.cd:Clear()
                f.cd:Hide()           -- Strictly clear graphical artifacts
                f.icon:SetDesaturated(false)
            end
```

### 5. Layout State desyncs on `SPELLS_CHANGED` (Minor Perf/UX)
* **File:** `cooldowns.lua`
* **Function:** Event Script / `Relayout()`
* **Bug:** `SPELLS_CHANGED` fires *very* aggressively in TBC (e.g., dragging spells on your action bar, gaining/losing shapeshift forms). `Relayout()` is a moderately heavy operation because it reconstructs the known list and clears/re-anchors all frames. Firing this continuously while a player rearranges their UI can cause noticeable micro-stutters.
* **Concrete Fix:** Instead of instantly triggering `Relayout()`, set a simple dirty-flag boolean to delay the layout update until the next `OnUpdate` cycle.

```lua
    -- Inside CDs:Init()
    self.layoutDirty = false
    
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        else
            self.layoutDirty = true   -- Throttle layout updates
        end
    end)
    
    -- Add an OnUpdate to the event frame to process the throttle
    ev:SetScript("OnUpdate", function()
        if self.layoutDirty then
            self.layoutDirty = false
            self:Relayout()
        end
    end)
```
