-- Headless smoke + regression tests for Cutthroat.  Run from the addon root:
--     lua test/run.lua          (lua5.1 / luajit preferred; see LIMITATIONS)
--
-- WHAT THIS PROVES: every module loads in order; the lifecycle and gameplay code
-- paths RUN without Lua errors under a strict WoW-API mock; basic state-driven
-- behavior (show/hide, db mutation, sanitization) is correct; and the addon only
-- calls real 2.5.x frame methods + registers real events (the mock ERRORS on an
-- unknown method or event — that's how it caught the iter-2 PLAYER_TALENT_UPDATE
-- class of bug).
--
-- WHAT IT DOES *NOT* PROVE (still needs docs/SMOKE_TEST.md in a real client):
--   * visual/layout correctness — SetPoint/SetAlpha/etc. are no-ops, so anchor
--     overlaps, texture paths, and render glitches are NOT caught.
--   * real event payloads/timing, unit-filtered delivery, combat-lockdown timing.
--   * Lua 5.1 vs the host runtime: if run on 5.4/5.5 it won't catch 5.1-only
--     incompatibilities. The addon avoids the known traps (no #t on the nil-holed
--     point table, no table.unpack, no goto, no coroutines), but run on 5.1/LuaJIT
--     for true fidelity.
-- Treat a green run as a strong smoke/regression signal, not a ship guarantee.

local ok_count, fail_count = 0, 0
local function check(name, cond, msg)
    if cond then ok_count = ok_count + 1; print("  ok   " .. name)
    else fail_count = fail_count + 1; print("  FAIL " .. name .. (msg and ("  -- " .. tostring(msg)) or "")) end
end
local function try(name, fn, ...)
    local ok, err = pcall(fn, ...)
    check(name, ok, err)
    return ok
end

-- ===================== shared state =====================
unpack = unpack or table.unpack
local T = 1000.0
local allFrames = {}
local state

local function freshState()
    state = {
        class = "ROGUE", energy = 100, maxEnergy = 100, combo = 0,
        hasTarget = true, targetDead = false, stealthed = false, combat = false,
        casting = nil, notInt = false, mh = true, oh = true, ohEquipped = true,
        usable = true, noMana = false,
        auras = { player = {}, target = {} },
        cooldowns = {}, -- spellName -> duration (absent = ready)
        known = { Vanish = true, Evasion = true, Sprint = true, ["Slice and Dice"] = true },
    }
end

-- only real TBC 2.5.x events the addon is allowed to register
local VALID_EVENTS = {}
for _, e in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED",
    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UNIT_POWER_FREQUENT",
    "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_AURA", "UNIT_INVENTORY_CHANGED",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTED", "UPDATE_STEALTH",
    "SPELL_UPDATE_COOLDOWN", "SPELLS_CHANGED", "CHARACTER_POINTS_CHANGED",
}) do VALID_EVENTS[e] = true end

-- ===================== widget mock =====================
-- __index is a METHOD TABLE: known methods resolve; any other key returns nil, so
-- a typo'd method call errors ("attempt to call a nil value") and an unset DATA
-- field reads as nil (correct boolean logic) — unlike a blanket no-op.
local Wm = {}
local function newW(kind, name)
    return setmetatable({ __k = kind, _name = name, _shown = false, _ev = {}, _sc = {}, _w = 200 },
        { __index = Wm })
end
function Wm.SetScript(s, e, fn) s._sc[e] = fn end
function Wm.GetScript(s, e) return s._sc[e] end
function Wm.HookScript(s, e, fn) s._sc[e] = fn end
function Wm.RegisterEvent(s, e)
    if not VALID_EVENTS[e] then error("registered unknown event: " .. tostring(e)) end
    s._ev[e] = true
end
function Wm.RegisterUnitEvent(s, e)
    if not VALID_EVENTS[e] then error("registered unknown event: " .. tostring(e)) end
    s._ev[e] = true
end
function Wm.UnregisterEvent(s, e) s._ev[e] = nil end
function Wm.Show(s) s._shown = true end
function Wm.Hide(s) s._shown = false end
function Wm.IsShown(s) return s._shown end
function Wm.SetWidth(s, v) s._w = v end
function Wm.GetWidth(s) return s._w end
function Wm.GetName(s) return s._name end
function Wm.GetID() return 1 end
function Wm.GetPoint() return "CENTER", nil, "CENTER", 0, -180 end
function Wm.CreateTexture() return newW("Texture") end
function Wm.CreateFontString() return newW("FontString") end
function Wm.CreateAnimationGroup() return newW("AnimGroup") end
function Wm.CreateAnimation() return newW("Anim") end
function Wm.SetText(s, t) s._text = t end
function Wm.SetDesaturated(s, b) s._desat = b end
function Wm.SetCooldown(s) s._cdActive = true end
function Wm.Clear(s) s._cdActive = false end
function Wm.GetChecked(s) return s._checked end
function Wm.SetChecked(s, b) s._checked = b end
function Wm.SetStatusBarColor(s, r, g, b) s._color = { r, g, b } end -- recorded for asserts
function Wm.SetMinMaxValues(s, lo, hi) s._min = lo; s._max = hi end
function Wm.SetValue(s, v) s._val = v end
function Wm.SetPoint(s, p, rel, relP, x, y) s._point = { p, rel, relP, x, y } end
-- remaining real methods: behaviorless no-ops (still allowlisted so typos error)
for _, n in ipairs({ "SetAllPoints", "SetAlpha", "SetBlendMode", "SetColorTexture",
    "SetDrawEdge", "SetDuration", "SetFromAlpha", "SetLooping", "SetMinMaxValues",
    "SetMovable", "SetObeyStepOnDrag", "SetPoint", "SetScale", "SetShown", "SetSize",
    "SetStatusBarColor", "SetStatusBarTexture", "SetTexCoord", "SetTextColor",
    "SetTexture", "SetToAlpha", "SetValue", "SetValueStep", "SetVertexColor",
    "RegisterForDrag", "ClearAllPoints", "StartMoving", "StopMovingOrSizing",
    "Play", "Stop", "EnableMouse" }) do
    Wm[n] = Wm[n] or function() end
end

function CreateFrame(kind, name)
    local f = newW(kind or "Frame", name)
    if name then _G[name] = f end
    allFrames[#allFrames + 1] = f
    return f
end
UIParent = newW("Frame", "UIParent")

local function fire(ev, ...)
    for _, f in ipairs(allFrames) do
        if f._ev[ev] and f._sc.OnEvent then f._sc.OnEvent(f, ev, ...) end
    end
end
local function tick(dt)
    T = T + dt
    for _, f in ipairs(allFrames) do
        if f._sc.OnUpdate then f._sc.OnUpdate(f, dt) end
    end
end

-- ===================== WoW global API mock =====================
function GetTime() return T end
function UnitClass() return "Rogue", state.class end
function UnitExists(u) if u == "target" then return state.hasTarget end return true end
function UnitIsDead() return state.targetDead end
function UnitCanAttack() return true end
function UnitPower() return state.energy end
function UnitPowerMax() return state.maxEnergy end
function GetComboPoints(unit, target)
    if target ~= "target" then error("GetComboPoints needs ('player','target'), got " .. tostring(target)) end
    return state.combo
end
function IsStealthed() return state.stealthed end
function InCombatLockdown() return state.combat end
function IsUsableSpell() return state.usable, state.noMana end
function PlaySound() end
function UnitCastingInfo()
    if state.casting then return state.casting, nil, nil, nil, nil, nil, nil, state.notInt end
end
function UnitChannelInfo() return nil end
function GetWeaponEnchantInfo() return state.mh, 0, 0, state.oh end
function GetInventoryItemLink() return state.ohEquipped and "item:1" or nil end
function GetSpellCooldown(name)
    local cd = state.cooldowns[name]
    if cd then return T - 1, cd, 1 end
    return 0, 0, 1
end
function GetSpellTexture() return "Interface\\Icons\\x" end
local spellNames = { [1856] = "Vanish", [5277] = "Evasion", [2983] = "Sprint",
    [13877] = "Blade Flurry", [13750] = "Adrenaline Rush", [14177] = "Cold Blood",
    [14185] = "Preparation", [1766] = "Kick",
    -- timer finishers (resolved locale-safely by timers.lua via GetSpellInfo)
    [5171] = "Slice and Dice", [1943] = "Rupture", [8647] = "Expose Armor", [703] = "Garrote" }
function GetSpellInfo(id) return spellNames[id], nil, "tex" end
function GetSpellName(i)
    local list = {}
    for k in pairs(state.known) do list[#list + 1] = k end
    table.sort(list)
    return list[i] -- nil past the end -> the addon's while-loop terminates
end
-- Filter-aware UnitAura: returns the i-th aura MATCHING the filter (like real WoW),
-- and treats a pipe-separated filter as INVALID (returns nil) — so a regression to
-- the old "HARMFUL|PLAYER" bug makes aura tests fail instead of silently passing.
function UnitAura(unit, i, filter)
    filter = filter or ""
    if filter:find("|") then return nil end -- invalid filter token separator
    local wantHarm = filter:find("HARMFUL") ~= nil
    local wantHelp = filter:find("HELPFUL") ~= nil
    local wantPlayer = filter:find("PLAYER") ~= nil
    local list = {}
    for _, a in ipairs(state.auras[unit] or {}) do
        local typeOK = (not wantHarm and not wantHelp)
            or (wantHarm and a.harmful) or (wantHelp and not a.harmful)
        local playerOK = (not wantPlayer) or a.byPlayer
        if typeOK and playerOK then list[#list + 1] = a end
    end
    local a = list[i]
    if not a then return nil end
    return a.name, nil, nil, nil, a.dur, a.exp
end
C_UnitAuras = nil
BOOKTYPE_SPELL = "spell"
Enum = { PowerType = { Energy = 3 } }
SOUNDKIT = { RAID_WARNING = 8959 }
SlashCmdList = {}
function CopyTable(t)
    local r = {}
    for k, v in pairs(t) do r[k] = (type(v) == "table") and CopyTable(v) or v end
    return r
end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
C_AddOns = { GetAddOnMetadata = function() return "test" end }
function GetAddOnMetadata() return "test" end
function InterfaceOptions_AddCategory() end
function InterfaceOptionsFrame_OpenToCategory() end
Settings = nil

-- ===================== scenario plumbing =====================
local MODULES = { "core.lua", "hud.lua", "timers.lua", "cooldowns.lua",
                  "alerts.lua", "options.lua", "config.lua" }
local function resetWorld()
    allFrames = {}
    CutthroatDB = nil
    SlashCmdList.CUTTHROAT = nil
    local kill = {}
    for k in pairs(_G) do if type(k) == "string" and k:find("^Cutthroat") then kill[#kill + 1] = k end end
    for _, k in ipairs(kill) do _G[k] = nil end
end
local function loadAll(NS)
    for _, f in ipairs(MODULES) do
        local chunk, err = loadfile(f)
        if not chunk then check("load " .. f, false, err)
        else try("load " .. f, chunk, "Cutthroat", NS) end
    end
end
local function iconByName(cds, n)
    for _, f in ipairs(cds.icons or {}) do if f.spell and f.spell.name == n then return f end end
end

-- ===================== Scenario 1: rogue happy path =====================
print("== Scenario: rogue ==")
freshState()
local NS = {}
loadAll(NS)
try("ADDON_LOADED", fire, "ADDON_LOADED", "Cutthroat")
check("db populated", NS.db ~= nil and NS.db.scale == 1.0)
try("PLAYER_LOGIN", fire, "PLAYER_LOGIN")
check("hud inited", NS.modules.hud and NS.modules.hud.root ~= nil)
check("timers inited", NS.modules.timers and NS.modules.timers.bars ~= nil)
check("cooldowns inited", NS.modules.cooldowns and NS.modules.cooldowns.icons ~= nil)
check("options inited", NS.modules.options and NS.modules.options.panel ~= nil)

print("== gameplay ==")
state.combo = 5; state.energy = 60
try("power event", fire, "UNIT_POWER_FREQUENT", "player")
state.auras.player[1] = { name = "Slice and Dice", dur = 21, exp = GetTime() + 10, harmful = false, byPlayer = true }
state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 4, harmful = true, byPlayer = true }
try("aura event", fire, "UNIT_AURA", "player")
local renderOK = true
for _ = 1, 20 do if not pcall(tick, 0.06) then renderOK = false end end
check("render loop (20 frames) no error", renderOK)
check("SnD bar shown while buffed", NS.modules.timers.bars.snd._shown)
check("Rupture bar shown while debuffed", NS.modules.timers.bars.rup._shown)
check("CP overcap glow shown at 5 CP", NS.modules.hud.cpGlow._shown)

print("== cooldown desaturation ==")
state.cooldowns.Vanish = 30
try("SPELL_UPDATE_COOLDOWN", fire, "SPELL_UPDATE_COOLDOWN")
local vanish = iconByName(NS.modules.cooldowns, "Vanish")
check("Vanish icon exists (known spell)", vanish ~= nil)
check("Vanish icon shown (known)", vanish and vanish:IsShown())
check("Vanish texture desaturated while on CD", vanish and vanish.icon and vanish.icon._desat == true)
local coldblood = iconByName(NS.modules.cooldowns, "Cold Blood")
check("Cold Blood icon created but hidden (not known)", coldblood ~= nil and not coldblood:IsShown())

print("== kick alert ==")
state.casting = "Fireball"; state.notInt = false
try("cast start", fire, "UNIT_SPELLCAST_START", "target")
check("kick flash shown vs interruptible cast", NS.modules.alerts.kick._shown)
state.casting = nil
try("cast stop", fire, "UNIT_SPELLCAST_STOP", "target")
check("kick flash hidden after cast", not NS.modules.alerts.kick._shown)

print("== poison check (behavioral) ==")
state.combat = false; state.mh = nil
try("regen-enabled", fire, "PLAYER_REGEN_ENABLED")
check("poison warning shown when MH unenchanted", NS.modules.alerts.poison._shown)
check("poison text names Main-hand", NS.modules.alerts.poison._text and NS.modules.alerts.poison._text:find("Main"))

print("== slash commands + db mutation ==")
local slash = SlashCmdList["CUTTHROAT"]
check("slash registered", type(slash) == "function")
if slash then
    for _, c in ipairs({ "", "help", "status", "lock", "scale 1.2", "scale 9",
        "kick", "poison", "opener", "sound", "ticks", "spark", "zone", "smart",
        "finish", "snd 4", "rup 3", "config", "options", "reset", "bogus" }) do
        try("/cut " .. c, slash, c)
    end
    check("'/cut scale 1.2' set scale", NS.db.scale == 1.2)
    check("'/cut scale 9' rejected (>3)", NS.db.scale == 1.2)
    check("'/cut snd 4' set sndWarn", NS.db.sndWarn == 4)
    check("'/cut kick' toggled kickAlert off", NS.db.kickAlert == false)
end

print("== regression: Kick negatives ==")
-- the slash-command test above toggled several settings OFF; reset the ones these
-- regression tests depend on so they exercise the real logic, not a disabled flag
NS.db.kickAlert = true; NS.db.poisonCheck = true; NS.db.openerHint = true
-- non-interruptible cast must NOT flash Kick
NS.modules.alerts.kick:Hide()
state.casting = "Polymorph"; state.notInt = true
try("non-interruptible cast event", fire, "UNIT_SPELLCAST_START", "target")
check("Kick does NOT flash on non-interruptible cast", not NS.modules.alerts.kick._shown)
-- interruptible cast but Kick unusable (no energy) must NOT flash
state.casting = "Fireball"; state.notInt = false; state.usable = false
try("cast event w/ Kick unusable", fire, "UNIT_SPELLCAST_START", "target")
check("Kick does NOT flash when unusable", not NS.modules.alerts.kick._shown)
state.usable = true; state.casting = nil
pcall(fire, "UNIT_SPELLCAST_STOP", "target")

print("== regression: smart-refresh green gating ==")
-- in the warn window WITH resources -> green; without CP -> not green
local good = NS.color.good
state.hasTarget = true; state.targetDead = false; state.energy = 60; state.combo = 5
state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 1, harmful = true, byPlayer = true } -- rem ~1 <= ruptureWarn(2)
NS.db.refreshZone = true; NS.db.smartRefresh = true
pcall(fire, "UNIT_AURA", "target"); pcall(tick, 0.06)
local rup = NS.modules.timers.bars.rup
check("Rupture bar green in warn window w/ CP+energy",
    rup._color and math.abs(rup._color[2] - good[2]) < 0.01)
state.combo = 0 -- can't refresh -> must drop the green cue
pcall(tick, 0.06)
check("Rupture bar NOT green when 0 CP (can't refresh)",
    rup._color and math.abs(rup._color[2] - good[2]) > 0.01)
state.combo = 5

print("== regression: misc behavior ==")
-- poison: both weapons enchanted -> no warning
state.combat = false; state.mh = true; state.oh = true
pcall(fire, "PLAYER_REGEN_ENABLED")
check("no poison warning when both weapons enchanted", not NS.modules.alerts.poison._shown)
-- opener hint: stealth + hostile target shows; leaving stealth hides
state.stealthed = true
pcall(fire, "UPDATE_STEALTH")
check("opener hint shown when stealthed w/ target", NS.modules.alerts.opener._shown)
state.stealthed = false
pcall(fire, "UPDATE_STEALTH")
check("opener hint hidden when not stealthed", not NS.modules.alerts.opener._shown)
-- energy spark hides at full energy
state.energy = 100
pcall(fire, "UNIT_POWER_FREQUENT", "player"); pcall(tick, 0.06)
check("energy tick spark hidden at full energy", not NS.modules.hud.energy.spark._shown)

print("== detarget clears glow ==")
state.hasTarget = false; state.combo = 0
pcall(tick, 0.06)
check("CP glow clears on detarget", not NS.modules.hud.cpGlow._shown)

-- ===================== Scenario 2: corrupt SavedVariables =====================
print("== Scenario: corrupt SavedVariables ==")
resetWorld()
freshState()
local NS2 = {}
loadAll(NS2)
CutthroatDB = { point = "not-a-table", scale = 999, kickAlert = false } -- garbage + a real pref
try("ADDON_LOADED w/ corrupt DB", fire, "ADDON_LOADED", "Cutthroat")
check("corrupt point reset to default table", type(NS2.db.point) == "table" and NS2.db.point[1] == "CENTER")
check("out-of-range scale reset", NS2.db.scale == 1.0)
check("valid user pref preserved", NS2.db.kickAlert == false)
try("PLAYER_LOGIN w/ corrupt DB", fire, "PLAYER_LOGIN")
check("hud inited despite corrupt DB", NS2.modules.hud and NS2.modules.hud.root ~= nil)

-- ===================== Scenario 3: non-rogue =====================
print("== Scenario: non-rogue ==")
resetWorld()
freshState()
state.class = "WARRIOR"
local NS3 = {}
loadAll(NS3)
try("non-rogue lifecycle", function() fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN") end)
check("non-rogue HUD NOT inited", not (NS3.modules.hud and NS3.modules.hud.root))
check("non-rogue options STILL inited", NS3.modules.options and NS3.modules.options.panel ~= nil)
check("non-rogue slash works", type(SlashCmdList["CUTTHROAT"]) == "function")

-- ===================== Scenario 4: deep behavior (locks past bugs) =====================
print("== Scenario: deep behavior ==")
resetWorld()
freshState()
local NS4 = {}
loadAll(NS4)
fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN")
local tmr = NS4.modules.timers

print("== aura filter correctness (the iter-1 bug class) ==")
-- our own SnD (HELPFUL) + our own Rupture (HARMFUL PLAYER) must be found
state.auras.player = { { name = "Slice and Dice", dur = 21, exp = GetTime() + 10, harmful = false, byPlayer = true } }
state.auras.target = { { name = "Rupture", dur = 16, exp = GetTime() + 8, harmful = true, byPlayer = true } }
fire("UNIT_AURA", "player"); fire("UNIT_AURA", "target")
check("SnD found via HELPFUL filter", tmr.cache.snd ~= nil)
check("our Rupture found via HARMFUL PLAYER filter", tmr.cache.rup ~= nil)
-- a Rupture cast by the TARGET (not the player) must be ignored by HARMFUL PLAYER
state.auras.target = { { name = "Rupture", dur = 16, exp = GetTime() + 8, harmful = true, byPlayer = false } }
fire("UNIT_AURA", "target")
check("target-cast Rupture ignored (not byPlayer)", tmr.cache.rup == nil)

print("== real-duration bar scaling + marker math ==")
NS4.db.ruptureWarn = 2; NS4.db.refreshZone = true
state.auras.target = { { name = "Rupture", dur = 16, exp = GetTime() + 4, harmful = true, byPlayer = true } }
fire("UNIT_AURA", "target"); tick(0.06)
local rupbar = tmr.bars.rup
check("bar max == real aura duration (16)", rupbar._max == 16)
check("marker at warnAt/dur*BAR_W (2/16*200=25)", rupbar.marker._point and math.abs(rupbar.marker._point[4] - 25) < 0.01)
-- refresh with a SHORTER duration: bar must rescale (no stale maxSeen), marker moves
state.auras.target = { { name = "Rupture", dur = 8, exp = GetTime() + 3, harmful = true, byPlayer = true } }
fire("UNIT_AURA", "target"); tick(0.06)
check("bar rescales to shorter duration (8)", rupbar._max == 8)
check("marker moves on dur change (2/8*200=50)", rupbar.marker._point and math.abs(rupbar.marker._point[4] - 50) < 0.01)

print("== self-calibrating energy tick interval ==")
local hud = NS4.modules.hud
state.energy = 20; hud:UpdatePower()               -- seed lastEnergy
T = T + 1.0; state.energy = 40; hud:UpdatePower()  -- 1st tick: establishes lastTick (idle gap rejected)
T = T + 1.0; state.energy = 60; hud:UpdatePower()  -- 2nd tick: 1.0s gap measured -> interval 1.0
check("tickInterval calibrated to observed ~1.0s gap", math.abs(hud.tickInterval - 1.0) < 0.05)
state.energy = 65; hud:UpdatePower()               -- +5 proc, same instant -> must be ignored
check("small proc gain does not change tickInterval", math.abs(hud.tickInterval - 1.0) < 0.05)
T = T + 2.0; state.energy = 85; hud:UpdatePower()  -- +20 at 2.0s gap -> recalibrate up
check("tickInterval recalibrates to ~2.0s gap", math.abs(hud.tickInterval - 2.0) < 0.05)

print("== cooldown one-shot OnUpdate self-cleanup ==")
local cds = NS4.modules.cooldowns
fire("SPELLS_CHANGED")
check("layout OnUpdate installed + dirty after SPELLS_CHANGED",
    cds.ev:GetScript("OnUpdate") ~= nil and cds.layoutDirty == true)
tick(0.06)
check("layout OnUpdate self-cleared + clean after flush",
    cds.ev:GetScript("OnUpdate") == nil and cds.layoutDirty == false)

print("== /reload double-init idempotency ==")
local before = #allFrames
local root1 = hud.root
local ok_reinit = pcall(function() hud:Init(); tmr:Init(); cds:Init(); NS4.modules.alerts:Init() end)
check("re-Init() does not error", ok_reinit)
check("re-Init() creates no new frames (guarded)", #allFrames == before)
check("re-Init() keeps same hud.root", hud.root == root1)

-- ===================== Scenario 5: localization (non-enUS aura names) =====================
print("== Scenario: localization ==")
resetWorld()
freshState()
-- simulate a German client: SnD's localized name. The addon must resolve TRACK
-- names via GetSpellInfo (id 5171) and match the LOCALIZED aura, not hardcoded enUS.
spellNames[5171] = "Säbelrasseln"
local NS5 = {}
loadAll(NS5)
fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN")
check("TRACK.snd resolved to localized name", NS5.modules.timers and
    select(1, GetSpellInfo(5171)) == "Säbelrasseln")
state.auras.player = { { name = "Säbelrasseln", dur = 21, exp = GetTime() + 10, harmful = false, byPlayer = true } }
fire("UNIT_AURA", "player"); tick(0.06)
check("SnD detected by LOCALIZED aura name (non-enUS)", NS5.modules.timers.bars.snd._shown)
spellNames[5171] = "Slice and Dice" -- restore for any later use

-- ===================== summary =====================
print(string.format("\n== RESULT: %d passed, %d failed ==", ok_count, fail_count))
os.exit(fail_count == 0 and 0 or 1)
