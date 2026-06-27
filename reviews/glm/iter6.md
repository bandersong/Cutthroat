Here is the review of the combo-point overcap glow implementation. 

### 1. Correctness of MAX_CP = 5 and GetComboPoints
**file/function/bug:** `hud.lua/HUD:Init()` and `hud.lua/HUD:UpdateCP()`
**check:** (1) & (2)
**analysis:** For Rogues in TBC Classic 2.5.x (and all expansions prior to Legion), the maximum combo point cap is strictly **5**. No talents, set bonuses, or effects can raise this limit. The API call `GetComboPoints("player", "target")` is fully correct and the standard way to retrieve combo points. The defensive `or 0` is perfect for handling returns of `nil` when the player has no target.
**fix:** No changes needed. This is entirely correct.

### 2. Layering, Alpha Animation, and Engine Capabilities
**file/function/bug:** `hud.lua/HUD:Init()` and `hud.lua/HUD:UpdateCP()`
**check:** (3) & (4)
**analysis:** 
- The `BACKGROUND` draw layer inherently renders behind `ARTWORK`, meaning the gold glow will correctly sit beneath the combo point pips without obscuring them.
- `GetTime()` and `math.sin()` are fundamental WoW UI global functions available in all versions, including 2.5.x. 
- Calling `g:SetAlpha()` continuously every render frame (~0.05s) is computationally trivial. However, because the `cpGlow` texture is set to a solid color (`SetColorTexture`), the fast-changing alpha will cause the *entire* rectangular area behind the pips to flash rapidly, which can be visually distracting. 
**fix:** Soften the glow and shift it behind the row slightly to make it less harsh without losing the warning urgency. 
```lua
-- In HUD:Init(), replace your cpGlow setup with:
    self.cpGlow = root:CreateTexture(nil, "BACKGROUND")
    self.cpGlow:SetPoint("TOPLEFT", self.pips[1], "TOPLEFT", -6, 6)
    self.cpGlow:SetPoint("BOTTOMRIGHT", self.pips[MAX_CP], "BOTTOMRIGHT", 6, -6)
    self.cpGlow:SetColorTexture(1, 0.82, 0, 1) 
    self.cpGlow:SetVertexColor(1, 0.82, 0, 1)
    self.cpGlow:SetBlendMode("ADD") -- Makes the solid texture act like a glow
    self.cpGlow:Hide()
```

### 3. Target Switching Ghosting Bug (Flicker)
**file/function/bug:** `hud.lua/HUD:UpdateCP()`
**check:** (5)
**analysis:** Because you are manually polling `GetComboPoints("player", "target")`, you must account for the player dropping their current target. When `target` evaluates to nothing, `GetComboPoints` evaluates combo points on the player's last target. If you generate 5 CPs, switch targets, and drop target (clearing your bar logically), the glow will persist on the UI until you select a new target—causing a "ghost flicker/stuck glow".
**fix:** Explicitly check if the target exists to ensure the glow hides instantly when you drop a 5 CP target.
```lua
function HUD:UpdateCP()
    -- Only fetch CP if we actually have a target
    local cp = UnitExists("target") and (GetComboPoints("player", "target") or 0) or 0
    
    for i = 1, MAX_CP do
        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
    end
    
    local g = self.cpGlow
    if g then
        if cp >= MAX_CP and NS.db.cpFinishGlow then
            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
            if not g:IsShown() then g:Show() end
        elseif g:IsShown() then
            g:Hide()
        end
    end
end
```

### 4. Event-Driven vs Render-Driven Execution
**file/function/bug:** `hud.lua/HUD:Init()` (Event Frame)
**check:** (6)
**analysis:** Calling `HUD:UpdateCP()` on power/target changes alongside rendering it on a ~0.05s timer does **not** cause a double-show problem. The `if not g:IsShown() then g:Show() end` guard efficiently prevents double-rendering, redundant frame visibility calls, or alpha stuttering. In fact, layering event calls over a render tick guarantees absolute visual responsiveness.
**fix:** No changes needed.

### 5. UX: Finisher Thresholds 
**file/function/bug:** `hud.lua/HUD:UpdateCP()`
**check:** (7)
**analysis:** Pulsing exactly at `cp >= 5` is an excellent, purely reactive UX choice for an overcap warning. Attempting to calculate whether a finisher is mathematically "worth using" earlier (e.g., at 4 CPs due to high Attack Power) crosses strictly into automation territory (rotation logic) which violates the addon's READ-ONLY constraints. 
**fix:** No changes needed. Keeping it strictly at 5 CPs preserves the addon's intent.
