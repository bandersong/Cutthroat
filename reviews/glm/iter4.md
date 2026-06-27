Here is the review of the `refresh-now zone` feature, ordered from critical logic bugs to UX/context checks. 

### 1. Marker math is inverted (Bug: Core Feature Broken)
*   **File:** `timers.lua`
*   **Function:** `Timers:Render()`
*   **Bug:** The marker position calculation `local mx = (warnAt / dur) * BAR_W` is mathematically incorrect for a left-to-right draining StatusBar. 
    *   As the timer elapses, `rem` approaches 0, so the visual fill shrinks toward the **left**. 
    *   The `warnAt` time represents the *end* of the timer, which visually corresponds to the **left** side of the bar. 
    *   Multiplying a fraction like `2 / 24` by `BAR_W` (200) puts the marker at **~16px from the left**. However, the bar fill is `200px` wide at that point. The marker will sit in the middle of the full bar, not at the depleting edge.
*   **Concrete Fix:** The marker should be offset by the fraction of time *remaining*. 
    ```lua
    -- Change from:
    local mx = (warnAt / dur) * BAR_W
    -- To:
    local mx = (warnAt / dur) * BAR_W
    -- Wait, no. If rem == warnAt, the fill width is exactly (warnAt / dur) * BAR_W.
    -- The math (warnAt / dur) * BAR_W is ALREADY correct if you anchored it from the RIGHT.
    ```
    *Wait, check the anchor in point #3!*

### 2. Marker anchored to LEFT instead of RIGHT (Bug: Compounds #1)
*   **File:** `timers.lua`
*   **Function:** `Timers:Render()`
*   **Bug:** `b.marker:SetPoint("LEFT", b, "LEFT", mx, 0)`. Because the bar drains from right to left, depleting durations approach the left edge (0,0). Any offset from the `LEFT` pushes the marker *into* the empty void of the bar, not the fill. 
*   **Concrete Fix:** Anchor the marker to the `RIGHT` and use a **negative** offset. Because of how WoW's StatusBar works, anchoring `RIGHT` to `RIGHT` with `-mx` places the marker exactly at the edge of the fill when `rem == warnAt`.
    ```lua
    -- Replace the mx calculation and SetPoint block with:
    local mx = (warnAt / dur) * BAR_W
    if mx > BAR_W then mx = BAR_W elseif mx < 0 then mx = 0 end
    b.marker:ClearAllPoints()
    b.marker:SetPoint("RIGHT", b, "RIGHT", -mx, 0) -- Negate the offset!
    ```

### 3. Marker causes frame leakage and edge-case stutter (Perf / Bug)
*   **File:** `timers.lua`
*   **Function:** `Timers:Init()` and `Timers:Render()`
*   **Bug:** In `Render`, you call `b.marker:ClearAllPoints()` and `SetPoint` every single frame (0.05s). This forces the WoW UI engine to recalculate UI layout coordinates continuously, which is terrible for performance. Furthermore, when the bar hides (`b:Hide()`), the marker doesn't always hide because `OnHide` on the parent doesn't cascade to manual `Show()` calls on children unless hooked.
*   **Concrete Fix:** Set the point **ONCE** during `Init()`. In `Render`, only call `SetPoint` if you are un-hiding it. Hide the marker explicitly when the bar hides.
    ```lua
    -- In Init():
    b.marker:SetPoint("RIGHT", b, "RIGHT", 0, 0) -- Default 0 offset
    
    -- In Render() replacing the marker logic:
    if NS.db.refreshZone then
        local mx = (warnAt / dur) * BAR_W
        if mx > BAR_W then mx = BAR_W elseif mx < 0 then mx = 0 end
        b.marker:SetPoint("RIGHT", b, "RIGHT", -mx, 0)
        if not b.marker:IsShown() then b.marker:Show() end
    else
        if b.marker:IsShown() then b.marker:Hide() end
    end
    
    -- In the hide block (if not c or rem <= 0):
    if b:IsShown() then 
        b:Hide() 
        b.marker:Hide() -- ensure marker vanishes with bar
    end
    ```

### 4. Redundant color execution (Perf / Correctness)
*   **File:** `timers.lua`
*   **Function:** `Timers:Render()`
*   **Bug:** `b:SetStatusBarColor(unpack(b.baseColor))` runs every frame when `rem > warnAt`. While `unpack` is fast in Lua 5.1, calling the C-side `SetStatusBarColor` every frame for no visual change is just burning CPU cycles. Your `baseColor` is correctly captured at `Init` so there is no bug in the *values*, just the execution rate.
*   **Concrete Fix:** Only apply colors on threshold state changes. 
    ```lua
    -- Inside the loop:
    if rem <= warnAt then
        if not b.inWarnZone then 
            b.label:SetTextColor(unpack(NS.color.bad))
            if NS.db.refreshZone then b:SetStatusBarColor(unpack(NS.color.good)) end
            b.inWarnZone = true
            -- play sound...
        end
    else
        if b.inWarnZone then 
            b.label:SetTextColor(1, 1, 1)
            b:SetStatusBarColor(unpack(b.baseColor))
            b.inWarnZone = false
        end
    end
    ```

### 5. Stale Marker on Target Change (Bug)
*   **File:** `timers.lua`
*   **Function:** `Timers:Scan()`
*   **Bug:** When you switch targets, `UNIT_AURA` or `PLAYER_TARGET_CHANGED` fires, triggering `Scan()`. If the new target doesn't have your Rupture, `c` becomes `nil` and the bar is hidden in `Render()`. However, `b.warned` (or the boolean state) is only reset on `OnHide`. If the user has a frame-delay where the marker is shown, or if `b:Hide()` is bypassed somehow, the marker's `mx` position from the *old* target remains stale.
*   **Concrete Fix:** Tie the marker strictly to the render loop visibility as fixed in Point #3.

### 6. UX/Context: "Refresh before expiry" vs "Refresh safely"
*   **File:** `timers.lua`
*   **Function:** Feature Architecture
*   **Bug:** Your context is 100% correct: TBC has no pandemic, early refreshes = clipped duration = wasted Combo Points/Energy. However, purely coloring the bar Green as a "refresh now" cue is slightly dangerous UX for a Rogue. 
    *   For **Slice and Dice**, you *never* want to refresh early unless absolutely necessary, as it lowers your uptime. 
    *   The standard TBC Rogue UI convention is to show the **green refresh window** when you have enough Energy/Combo Points to safely refresh *without* clipping the current tick, otherwise it stays red/yellow.
*   **Concrete Fix:** If you want to be truly optimal, the recolor should trigger based on `rem <= warnAt` **AND** `NS.modules.hud:HasFinisherCondition()` (e.g., 5 CPs for Rupture, or Energy > 25 for SnD). If they lack the resources to refresh, it shouldn't be green. If that's too complex for this iteration, the current `rem <= warnAt` is acceptable as a basic visual cue, but consider making the Green a pulsing opacity (`SetVertexColor`) so it implies *urgency* rather than *permission*.
