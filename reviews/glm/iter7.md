Here is the holistic cross-module audit of the Cutthroat addon. Overall, the architecture is remarkably solid for a WoW addon, with good separation of concerns and sensible event-driven design. However, there are a few integration hazards (especially around `OnUpdate` loops and global hooks) that need addressing before ship.

### Findings & Fixes

**1. High: Duplicate `OnUpdate` loops (Redundant / Wasteful)**
*   **File:** `timers.lua` & `cooldowns.lua`
*   **Issue:** `timers.lua` sets an `OnUpdate` on the root frame to render timers (gated at 0.05s). `cooldowns.lua` creates a *brand new hidden frame* with its own `OnUpdate` to check a single dirty flag *every single frame* (uncapped). Multiple `OnUpdate` handlers firing independently is inefficient and anti-pattern in WoW UI design.
*   **Fix:** Consolidate into the existing `OnUpdate` in `timers.lua`. 
    ```lua
    -- In timers.lua OnUpdate:
    root:SetScript("OnUpdate", function(_, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed < 0.05 then return end
        self.elapsed = 0
        self:Render()
        
        -- Handle cooldowns dirty flag natively
        if NS.modules.cooldowns and NS.modules.cooldowns.layoutDirty then
            NS.modules.cooldowns.layoutDirty = false
            NS.modules.cooldowns:RebuildKnown()
            NS.modules.cooldowns:Relayout()
        end
    end)
    ```
    Then remove the `ev:SetScript("OnUpdate", ...)` completely from `cooldowns.lua`.

**2. High: Global namespace pollution (Taint / Hard error risk)**
*   **File:** `cooldowns.lua`
*   **Function:** `CDs:RebuildKnown`
*   **Issue:** `wipe` is a global function provided by WoW's UI, but relying on it without a fallback or `local wipe = wipe` at the top of the file is hazardous. If the global is ever hooked or missing, it hard-errors. 
*   **Fix:** Replace `wipe(self.known)` with a standard Lua table clear, avoiding external dependencies:
    ```lua
    local k = self.known
    for key in pairs(k) do k[key] = nil end
    ```

**3. Medium: SavedVariables Migration missing for new keys**
*   **File:** `core.lua`
*   **Function:** `ADDON_LOADED` event handler
*   **Issue:** You correctly merge defaults using `if CutthroatDB[k] == nil`. However, for table defaults (like `db.point`), if a user has an *old* save state where `point` had fewer array indices, or you add a new sub-key later, it won't deep-merge. More importantly, there is no migration logic if you ever change the schema of `point` (e.g., from `{"CENTER", "UIParent", ...}` to `{"CENTER", nil, "CENTER", ...}`). 
*   **Fix:** This is currently working perfectly for adding *new* keys, but to future-proof, add a version stamp.
    ```lua
    CutthroatDB = CutthroatDB or {}
    -- Force overwrite specific keys if versioning changes
    if not CutthroatDB.dbVersion or CutthroatDB.dbVersion < 2 then
        CutthroatDB.point = { "CENTER", nil, "CENTER", 0, -180 }
        CutthroatDB.dbVersion = 2
    end
    ```

**4. Medium: Wasted CPU cycles in `HUD:UpdatePower`**
*   **File:** `hud.lua`
*   **Function:** `HUD:UpdatePower`
*   **Issue:** This function sets `self.energy:SetMinMaxValues(0, self.energyMax)` and `self.energy.text:SetText(e)` every single time it is called. `timers.lua` calls this ~20 times a second (0.05s). Redundant FrameXML C-function calls are expensive.
*   **Fix:** Gate these calls behind a state check so they only execute when the value actually changes:
    ```lua
    if self.energyMax ~= m then
        self.energyMax = m
        self.energy:SetMinMaxValues(0, m)
    end
    if self.lastEnergy ~= e then
        self.energy:SetValue(e)
        self.energy.text:SetText(e)
    end
    ```

**5. Medium: Missing `/reload` re-init safety on Drag Frame**
*   **File:** `core.lua` & `hud.lua`
*   **Issue:** The HUD root frame is a global named frame (`"CutthroatHUD"`). If a user reloads their UI (`/reload`) during a session, `ADDON_LOADED` fires again. While `CreateFrame` gracefully returns the existing frame instead of erroring, leftover state or hooks from the previous load might persist. 
*   **Fix:** In `hud.lua`, ensure `local root = CreateFrame(...)` is safely handled by clearing existing points before applying the saved DB point:
    ```lua
    root:ClearAllPoints()
    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
    ```

**6. Low: Dead code & Unused variables**
*   **File:** `timers.lua`
*   **Issue:** 
    1. `rnd` (Rend) is listed in the `TRACK` table, but is completely ignored by `SOURCE` and `Init`. This is dead code.
    2. `local e, m = UnitPower...` in `hud.lua` (inside `HasRefreshResources` logic gate) calls `UnitPower` continuously, but `HUD:UpdatePower` already calculates and stores `self.lastEnergy`.
*   **Fix:** Remove `rnd` from `TRACK`. In `timers.lua`, change `local e = UnitPower("player", ENERGY)` to read from the HUD module if possible, or leave as-is (it's low impact, but architecturally redundant).

**7. Low: Addon communication/messaging consistency**
*   **File:** `timers.lua`, `cooldowns.lua`, `alerts.lua`
*   **Issue:** `SPELL_UPDATE_COOLDOWN` is registered by both `cooldowns.lua` and `alerts.lua`. Both run full iterations over spell cooldowns independently. 
*   **Fix:** Architecturally fine since they do different things (desaturation vs. kick logic), but could be merged into a single internal event bus if performance ever becomes an issue. Not a blocker for ship.

---

### Ship-Readiness Verdict

**READY FOR ALPHA / BETA RELEASE.**
The addon is functionally complete, structurally sound, and Warden-safe (verified pure read-only with zero secure frame templates used for spell interactions). Fixing the duplicate `OnUpdate` loops (Finding #1) and the `wipe` global dependency (Finding #2) are mandatory before pushing to a live environment. The other findings are standard polish/OOM-prevention optimizations.

---

### In-Client Smoke-Test Checklist

Since WoW addons cannot be fully integration-tested in a CI pipeline without a headless client, a human **MUST** verify the following in-game on the TBC Classic 2.5.x client:

**[ ] 1. Clean Login & Gating**
- [ ] Login on a Non-Rogue class. Verify the `/cut` command prints a help menu, but verify **zero** frames are created on the screen.
- [ ] Login on a Rogue. Verify the HUD draws (Energy bar, 5 empty combo pips).

**[ ] 2. Core Rendering & State Machine**
- [ ] Use abilities to generate Energy depletes and Combat Points (1 through 5). Verify the pips light up sequentially.
- [ ] At 5 Combo Points, verify the **Gold Overcap Glow** pulses smoothly (sine wave).
- [ ] Verify the Energy tick spark (the sweeping white line) moves smoothly and resets precisely when a regen tick occurs (usually every 2 seconds).

**[ ] 3. Aura Tracking (timers.lua)**
- [ ] Cast Slice and Dice. Verify the green bar appears and counts down accurately.
- [ ] Wait until it hits the `sndWarn` threshold (Default 3s). Verify the bar flashes/turns red and a sound plays.
- [ ] Cast Rupture on a target dummy. Verify the red bar appears. Drop target—verify the bar disappears or cleans up properly.

**[ ] 4. Cooldowns Module**
- [ ] Verify spec-specific cooldowns (Adrenaline Rush, Cold Blood) **only** appear if you are actively specced into them.
- [ ] Cast Vanish or Evasion. Verify the Cooldown radial sweep begins on the icon and the icon desaturates (turns dark/gray).
- [ ] Switch specs (reset talents). Verify the icons update dynamically without requiring a `/reload`.

**[ ] 5. Alerts**
- [ ] Have a target dummy cast a spell. Verify the **KICK!** flash appears and pulses.
- [ ] Take off your weapons/poisons out of combat. Verify the poison warning appears. Enter combat—verify it hides immediately.
- [ ] Go into Stealth and target an enemy dummy. Verify the "Opener: Ambush / Garrote" text appears.

**[ ] 6. Settings & SavedVariables Persistence**
- [ ] Run `/cut lock`. Verify the drag background appears/disappears.
- [ ] Drag the HUD to a new location. Type `/reload`. Verify the HUD stays exactly where you left it.
- [ ] Run `/cut reset`. Verify it returns to the bottom center default.
- [ ] Run `/cut scale 1.5` and `/cut scale 0.5`. Verify scaling is applied immediately without distortion.
