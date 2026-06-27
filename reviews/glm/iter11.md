Here are the top 3 highest-value behaviors that are still untested, highly prone to regression (based on common Rogue addon pitfalls), and fully implementable against your current mock without any visual/pixel checks.

### 1. Self-Calibrating Energy Tick Interval (`hud.lua`)
**Why it's high value:** Rogue energy addons often break when Blizzard tweaks server tick timing or when players zone. If the addon miscalibrates the predicted tick interval, the energy bar spark will wildly jump out of sync. Testing this ensures your dynamic calibration logic survives refactors.
**What to set up:** 
Zero out the state, force an energy drop to trigger the addon's internal state recording, then fire frequent update events to simulate the client predicting energy, followed by the actual server sync.
**How to assert:**
Assert that the addon's internal tick interval state recalculates to ~2.0 seconds. Then, assert that the spark's animation frame (or internal state) actually resets its loop exactly when a tick happens, rather than drifting.
```lua
-- Setup
state.energy = 40
fire("UNIT_POWER_FREQUENT", "player")
tick(0.1) 
-- Simulate server verifying the energy tick exactly 2.0s later
state.energy = 60 
T = T + 2.0 
fire("UNIT_POWER_FREQUENT", "player")

-- Assertions
check("Energy tick calibrated to ~2.0s", NS.modules.hud.tickInterval and math.abs(NS.modules.hud.tickInterval - 2.0) < 0.1)
-- (If you track an accumulator or spark animation group)
check("Energy prediction resets on sync", NS.modules.hud.sparkLoop and NS.modules.hud.sparkLoop._resetFlag == true)
```

### 2. Aura Filter Collision (HARMFUL vs HELPFUL) (`timers.lua`)
**Why it is high value:** In TBC, querying auras by index is notoriously buggy. Addons frequently regress when a mob casts a self-buff (HELPFUL) that shares a name with a Rogue debuff (e.g., "Rip" vs "Rupture", or some generic bleed). If your aura parser doesn't filter by `unitCaster` (HARMFUL-PLAYER), it will falsely show a finisher bar for an aura the Rogue didn't apply. 
**What to set up:**
Inject an aura into the target mock state with the name "Rupture", but simulate it being cast by the target itself.
**How to assert:**
Fire the aura event and ensure the timer module actively ignores it and keeps the bar hidden.
```lua
-- Setup
state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 8, caster = "target", helpful = false }
fire("UNIT_AURA", "target")
tick(0.06)

-- Assertion
check("Timer ignores target-cast HARMFUL auras matching finisher names", not NS.modules.timers.bars.rup._shown)
```

### 3. `maxSeen` Duration Scaling & Clamp (`timers.lua`)
**Why it is high value:** Rogue timers often dynamically resize the bar scale so a 5-CP Rupture (18s) visually takes up more space than a 1-CP Rupture (8s) without destroying the UI layout. If the `maxSeen` tracking variable isn't sanitized or updated correctly, the UI can permanently "max out" the scaling logic if it ever caches a bugged 9999s duration from an API hiccup.
**What to set up:**
First, feed the addon an impossible/massive duration aura (simulating an API glitch), then remove it. Next, apply a normal aura. 
**How to assert:**
Assert that `maxSeen` resets/clamps appropriately, and that the mock's `SetStatusBarColor` or `SetMinMaxValues` bounds reflect a safe scale rather than an infinite glitch.
```lua
-- Setup: Simulate a corrupt API aura duration return
state.auras.target[1] = { name = "Rupture", dur = 99999, exp = GetTime() + 99999 }
fire("UNIT_AURA", "target")
tick(0.06)
-- Aura falls off
state.auras.target[1] = nil
fire("UNIT_AURA", "target")
tick(0.06)

-- Assertion
check("maxSeen duration is safely clamped/reset on aura drop", NS.modules.timers.maxSeen ~= nil and NS.modules.timers.maxSeen < 30)
```
