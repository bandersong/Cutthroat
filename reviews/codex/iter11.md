Reading additional input from stdin...
OpenAI Codex v0.142.2
--------
workdir: /Users/creative/WoWAddons/Cutthroat
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 019f09c9-31a8-75c2-8216-2e470bccdff3
--------
user
Test-gap mining for the headless harness test/run.lua of this Cutthroat WoW TBC Classic 2.5.x Rogue addon (93 checks, behavioral+negative tests already cover Kick non-interruptible/unusable gating, smart-refresh CP/energy gating, poison clear, opener visibility, spark-at-cap, cooldown desaturation, corrupt SavedVariables). Read test/run.lua and the addon. Name the TOP 2-3 highest-value behaviors STILL untested that realistically COULD regress and ARE implementable against this mock (no rendering). Be concrete: setup, assertion, module. Prioritize past-bug areas: aura filter (HELPFUL vs HARMFUL PLAYER), self-calibrating energy tick interval, real-duration bar scaling (maxSeen removal), refresh marker position math, one-shot cooldown OnUpdate self-cleanup, /reload double-init idempotency guards. Numbered, most valuable first. Do NOT edit.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll read the harness and addon code, then map gaps against what the mock can actually observe. No edits.
exec
/bin/zsh -lc 'pwd && rg --files' in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc 'rg -n "Aura|UnitAura|HELPFUL|HARMFUL|PLAYER|energy|tick|maxSeen|refresh|marker|OnUpdate|ADDON_LOADED|reload|Initialize|init|RegisterEvent|SavedVariables|cooldown" .' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

 exited 127 in 0ms:
zsh:1: command not found: rg

exec
/bin/zsh -lc "sed -n '1,260p' test/run.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
    [14185] = "Preparation", [1766] = "Kick" }
function GetSpellInfo(id) return spellNames[id], nil, "tex" end
function GetSpellName(i)
    local list = {}
    for k in pairs(state.known) do list[#list + 1] = k end
    table.sort(list)
    return list[i] -- nil past the end -> the addon's while-loop terminates
end
function UnitAura(unit, i)
    local a = state.auras[unit] and state.auras[unit][i]
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
state.auras.player[1] = { name = "Slice and Dice", dur = 21, exp = GetTime() + 10 }
state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 4 }
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

codex
`rg` isn’t installed here, so I’m falling back to `find`/`grep`. I’ve got the first half of the harness; next I’m checking the remaining scenarios and the specific addon modules around the candidate gaps.
exec
/bin/zsh -lc "sed -n '261,620p' test/run.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 1 } -- rem ~1 <= ruptureWarn(2)
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

-- ===================== summary =====================
print(string.format("\n== RESULT: %d passed, %d failed ==", ok_count, fail_count))
os.exit(fail_count == 0 and 0 or 1)

exec
/bin/zsh -lc 'find . -maxdepth 3 -type f | sort' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./.git/COMMIT_EDITMSG
./.git/HEAD
./.git/config
./.git/description
./.git/hooks/applypatch-msg.sample
./.git/hooks/commit-msg.sample
./.git/hooks/fsmonitor-watchman.sample
./.git/hooks/post-update.sample
./.git/hooks/pre-applypatch.sample
./.git/hooks/pre-commit.sample
./.git/hooks/pre-merge-commit.sample
./.git/hooks/pre-push.sample
./.git/hooks/pre-rebase.sample
./.git/hooks/pre-receive.sample
./.git/hooks/prepare-commit-msg.sample
./.git/hooks/push-to-checkout.sample
./.git/hooks/sendemail-validate.sample
./.git/hooks/update.sample
./.git/index
./.git/info/exclude
./.git/logs/HEAD
./.github/workflows/ci.yml
./.gitignore
./CHANGELOG.md
./Cutthroat.toc
./LICENSE
./README.md
./alerts.lua
./config.lua
./cooldowns.lua
./core.lua
./docs/DECISIONS.md
./docs/ROADMAP.md
./docs/SMOKE_TEST.md
./docs/TRIANGULATION.md
./hud.lua
./options.lua
./prompts/audit_iter7.txt
./prompts/docs_iter9.txt
./prompts/harness_iter10.txt
./prompts/review_iter1.txt
./prompts/review_iter2.txt
./prompts/review_iter3.txt
./prompts/review_iter4.txt
./prompts/review_iter5.txt
./prompts/review_iter6.txt
./prompts/review_iter8.txt
./prompts/testgap_iter11.txt
./reviews/codex/iter1.md
./reviews/codex/iter10.md
./reviews/codex/iter11.md
./reviews/codex/iter2.md
./reviews/codex/iter3.md
./reviews/codex/iter4.md
./reviews/codex/iter5.md
./reviews/codex/iter6.md
./reviews/codex/iter7.md
./reviews/codex/iter8.md
./reviews/codex/iter9.md
./reviews/glm/iter1.md
./reviews/glm/iter10.md
./reviews/glm/iter11.md
./reviews/glm/iter2.md
./reviews/glm/iter3.md
./reviews/glm/iter4.md
./reviews/glm/iter5.md
./reviews/glm/iter6.md
./reviews/glm/iter7.md
./reviews/glm/iter8.md
./reviews/glm/iter9.md
./test/run.lua
./timers.lua

exec
/bin/zsh -lc 'grep -RInE "Aura|UnitAura|HELPFUL|HARMFUL|PLAYER|energy|tick|maxSeen|refresh|marker|OnUpdate|ADDON_LOADED|reload|Initialize|init|RegisterEvent|SavedVariables|cooldown" .' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 114ms:
~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
./reviews/codex/iter3.md:362:    63	    energy.spark = energy:CreateTexture(nil, "OVERLAY")
./reviews/codex/iter3.md:363:    64	    energy.spark:SetColorTexture(1, 1, 1, 0.85)
./reviews/codex/iter3.md:364:    65	    energy.spark:SetWidth(2)
./reviews/codex/iter3.md:365:    66	    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
./reviews/codex/iter3.md:366:    67	    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
./reviews/codex/iter3.md:367:    68	    energy.spark:Hide()
./reviews/codex/iter3.md:369:    70	    self.energyMax = 100
./reviews/codex/iter3.md:394:    95	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter3.md:400:   101	    if not self.energy then return end
./reviews/codex/iter3.md:403:   104	    self.energyMax = m > 0 and m or 100
./reviews/codex/iter3.md:404:   105	    self.energy:SetMinMaxValues(0, self.energyMax)
./reviews/codex/iter3.md:405:   106	    self.energy:SetValue(e)
./reviews/codex/iter3.md:406:   107	    self.energy.text:SetText(e)
./reviews/codex/iter3.md:407:   108	    -- a positive delta means a regen tick (or energy gain) just landed -> reset spark
./reviews/codex/iter3.md:414:   115	-- Move the regen-tick spark; called every render frame from timers:Render.
./reviews/codex/iter3.md:416:   117	    local s = self.energy and self.energy.spark
./reviews/codex/iter3.md:418:   119	    -- hide when disabled or at full energy (no tick to wait for)
./reviews/codex/iter3.md:419:   120	    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
./reviews/codex/iter3.md:424:   125	    local x = frac * self.energy:GetWidth()
./reviews/codex/iter3.md:426:   127	    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
./reviews/codex/iter3.md:427:   128	    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
./reviews/codex/iter3.md:435:    81	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter3.md:439:    85	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter3.md:441:    87	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter3.md:457:   103	            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
./reviews/codex/iter3.md:463:   109	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter3.md:481:   127	            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
./reviews/codex/iter3.md:502:web search: WoW TBC Classic rogue energy regenerates every 2 seconds 20 energy
./reviews/codex/iter3.md:504:web search: site:warcraft.wiki.gg Energy WoW energy regenerates every two seconds rogue
./reviews/codex/iter3.md:509:   **Bug:** Any positive energy delta resets `lastTick`. That will false-sync on Relentless Strikes, Thistle Tea, Combat Potency, refunds, and other instant energy gains. It matters: the spark can be pushed off the real 2.0s server tick and then confidently show the wrong next tick.  
./reviews/codex/iter3.md:510:   **Concrete fix:** Track `delta = e - self.lastEnergy`; only resync on plausible regen ticks, e.g. `delta >= 10` or `>= 20` depending tolerance, and gate by time since last accepted tick: accept only when `now - lastTick >= ~1.7` or when no valid tick exists. Ignore small positive deltas.
./reviews/codex/iter3.md:513:   **Bug:** The 2.0s interval is correct for TBC energy regen: baseline rogue energy is discrete, roughly 20 energy per 2.0s tick. The predictor’s interval is right, but its phase source is weak because `lastTick` comes from any positive delta.  
./reviews/codex/iter3.md:514:   **Concrete fix:** Keep `/ 2.0`, but only update `lastTick` from filtered tick-like gains in `UpdatePower`.
./reviews/codex/iter3.md:529:   **Bug:** `UnitPowerMax` zero/nil is mostly handled by falling back to `100`, so no divide-by-zero exists because spark progress uses time, not `energyMax`. Minor risk: if `UnitPowerMax` returned nil, `m > 0` would error. In WoW this normally returns a number.  
./reviews/codex/iter3.md:530:   **Concrete fix:** Harden anyway: `self.energyMax = (m and m > 0) and m or 100`.
./reviews/codex/iter3.md:533:   **Bug:** At energy cap, spark hides. That is reasonable. Adrenaline Rush doubles energy regen rate, but it should not change the 2.0s tick phase; it changes energy gained per tick. Current code does not assume 20 energy per accepted tick, so AR itself is not a separate spark bug unless future filtering only accepts exactly 20.  
./reviews/codex/iter3.md:534:   **Concrete fix:** If adding delta filtering, accept larger tick gains during AR, e.g. `delta >= 10`/`>= 20`, not `delta == 20`. No need to alter the spark sweep interval for AR.
./reviews/codex/iter3.md:538:   **Concrete fix:** None required. Optional clarity: explicitly initialize and return on first sample so future edits do not break it:
./reviews/codex/iter3.md:550:   **Bug:** Any positive energy delta resets `lastTick`. That will false-sync on Relentless Strikes, Thistle Tea, Combat Potency, refunds, and other instant energy gains. It matters: the spark can be pushed off the real 2.0s server tick and then confidently show the wrong next tick.  
./reviews/codex/iter3.md:551:   **Concrete fix:** Track `delta = e - self.lastEnergy`; only resync on plausible regen ticks, e.g. `delta >= 10` or `>= 20` depending tolerance, and gate by time since last accepted tick: accept only when `now - lastTick >= ~1.7` or when no valid tick exists. Ignore small positive deltas.
./reviews/codex/iter3.md:554:   **Bug:** The 2.0s interval is correct for TBC energy regen: baseline rogue energy is discrete, roughly 20 energy per 2.0s tick. The predictor’s interval is right, but its phase source is weak because `lastTick` comes from any positive delta.  
./reviews/codex/iter3.md:555:   **Concrete fix:** Keep `/ 2.0`, but only update `lastTick` from filtered tick-like gains in `UpdatePower`.
./reviews/codex/iter3.md:570:   **Bug:** `UnitPowerMax` zero/nil is mostly handled by falling back to `100`, so no divide-by-zero exists because spark progress uses time, not `energyMax`. Minor risk: if `UnitPowerMax` returned nil, `m > 0` would error. In WoW this normally returns a number.  
./reviews/codex/iter3.md:571:   **Concrete fix:** Harden anyway: `self.energyMax = (m and m > 0) and m or 100`.
./reviews/codex/iter3.md:574:   **Bug:** At energy cap, spark hides. That is reasonable. Adrenaline Rush doubles energy regen rate, but it should not change the 2.0s tick phase; it changes energy gained per tick. Current code does not assume 20 energy per accepted tick, so AR itself is not a separate spark bug unless future filtering only accepts exactly 20.  
./reviews/codex/iter3.md:575:   **Concrete fix:** If adding delta filtering, accept larger tick gains during AR, e.g. `delta >= 10`/`>= 20`, not `delta == 20`. No need to alter the spark sweep interval for AR.
./reviews/codex/iter3.md:579:   **Concrete fix:** None required. Optional clarity: explicitly initialize and return on first sample so future edits do not break it:
./reviews/codex/iter7.md:14:HOLISTIC CROSS-MODULE AUDIT of this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. Read ALL files: core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc. Prior reviews each saw only one file; this is the first whole-addon review. Focus on INTEGRATION issues per-file reviews miss: (a) module init order + cross-module deps (timers/cooldowns/alerts anchor to NS.modules.hud.root; core inits hud first, rogue-only); (b) event-frame proliferation/leaks/duplicate registrations across modules; (c) multiple OnUpdate loops — timers:Render @0.05s calls hud UpdateCP/UpdatePower/UpdateEnergyTick, cooldowns has its own per-frame OnUpdate checking a dirty flag — redundant/wasteful?; (d) SavedVariables defaults merge + migration when keys added across versions; (e) taint/secure-frame (verify none); (f) /reload re-init safety; (g) NS.db/NS.IsRogue gating consistency; (h) dead code, unused locals, leaked globals (missing local); (i) shared-state hazards. Then give a SHIP-READINESS verdict + a concise IN-CLIENT SMOKE-TEST CHECKLIST for a human. Numbered: file, function, issue, concrete fix. Do NOT edit files. Real issues first.
./reviews/codex/iter7.md:24:/bin/zsh -lc "pwd && rg --files -g 'core.lua' -g 'hud.lua' -g 'timers.lua' -g 'cooldowns.lua' -g 'alerts.lua' -g 'config.lua' -g 'Cutthroat.toc'" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:38:/bin/zsh -lc "find . -maxdepth 2 \\( -name core.lua -o -name hud.lua -o -name timers.lua -o -name cooldowns.lua -o -name alerts.lua -o -name config.lua -o -name Cutthroat.toc \\) -print" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:45:./cooldowns.lua
./reviews/codex/iter7.md:49:/bin/zsh -lc 'wc -l core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:54:     147 cooldowns.lua
./reviews/codex/iter7.md:85:    19	    energyTicks = true, -- show 20-energy tick marks
./reviews/codex/iter7.md:86:    20	    tickSpark = true,   -- moving spark = progress to next ~2s energy regen tick
./reviews/codex/iter7.md:87:    21	    refreshZone = true, -- mark the "refresh now" window near expiry on SnD/DoT bars
./reviews/codex/iter7.md:88:    22	    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
./reviews/codex/iter7.md:110:    44	f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter7.md:111:    45	f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter7.md:113:    47	    if event == "ADDON_LOADED" and arg1 == ADDON then
./reviews/codex/iter7.md:121:    55	    elseif event == "PLAYER_LOGIN" then
./reviews/codex/iter7.md:122:    56	        -- Explicit init order: hud first (timers/alerts anchor to hud.root),
./reviews/codex/iter7.md:124:    58	        local function initModule(name)
./reviews/codex/iter7.md:128:    62	        initModule("config") -- slash command / options work for everyone
./reviews/codex/iter7.md:130:    64	            initModule("hud")
./reviews/codex/iter7.md:131:    65	            initModule("timers")
./reviews/codex/iter7.md:132:    66	            initModule("cooldowns")
./reviews/codex/iter7.md:133:    67	            initModule("alerts")
./reviews/codex/iter7.md:150:    84	    energy  = { 1.0, 0.85, 0.20 },
./reviews/codex/iter7.md:159:     1	-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
./reviews/codex/iter7.md:195:    37	    local energy = CreateFrame("StatusBar", nil, root)
./reviews/codex/iter7.md:196:    38	    energy:SetSize(WIDTH, HEIGHT)
./reviews/codex/iter7.md:197:    39	    energy:SetPoint("TOP", root, "TOP", 0, 0)
./reviews/codex/iter7.md:198:    40	    energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
./reviews/codex/iter7.md:199:    41	    energy:SetStatusBarColor(unpack(NS.color.energy))
./reviews/codex/iter7.md:200:    42	    energy:SetMinMaxValues(0, 100)
./reviews/codex/iter7.md:201:    43	    energy.bg = energy:CreateTexture(nil, "BACKGROUND")
./reviews/codex/iter7.md:202:    44	    energy.bg:SetAllPoints()
./reviews/codex/iter7.md:203:    45	    energy.bg:SetColorTexture(0.12, 0.10, 0.0, 0.85)
./reviews/codex/iter7.md:204:    46	    energy.text = energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
./reviews/codex/iter7.md:205:    47	    energy.text:SetPoint("CENTER")
./reviews/codex/iter7.md:206:    48	    self.energy = energy
./reviews/codex/iter7.md:208:    50	    -- 20-energy tick marks
./reviews/codex/iter7.md:209:    51	    energy.ticks = {}
./reviews/codex/iter7.md:210:    52	    if db.energyTicks then
./reviews/codex/iter7.md:212:    54	            local t = energy:CreateTexture(nil, "OVERLAY")
./reviews/codex/iter7.md:215:    57	            t:SetPoint("LEFT", energy, "LEFT", WIDTH * (i * 20 / 100), 0)
./reviews/codex/iter7.md:216:    58	            energy.ticks[i] = t
./reviews/codex/iter7.md:220:    62	    -- energy regen-tick spark: a thin marker sweeping the bar 0->100% over the
./reviews/codex/iter7.md:221:    63	    -- ~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
./reviews/codex/iter7.md:222:    64	    energy.spark = energy:CreateTexture(nil, "OVERLAY")
./reviews/codex/iter7.md:223:    65	    energy.spark:SetColorTexture(1, 1, 1, 0.85)
./reviews/codex/iter7.md:224:    66	    energy.spark:SetWidth(2)
./reviews/codex/iter7.md:225:    67	    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
./reviews/codex/iter7.md:226:    68	    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
./reviews/codex/iter7.md:227:    69	    energy.spark:Hide()
./reviews/codex/iter7.md:229:    71	    self.energyMax = 100
./reviews/codex/iter7.md:231:    73	    self.tickInterval = 2.0 -- self-calibrated from observed tick gaps
./reviews/codex/iter7.md:264:   106	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter7.md:270:   112	    if not self.energy then return end
./reviews/codex/iter7.md:273:   115	    self.energyMax = (m and m > 0) and m or 100
./reviews/codex/iter7.md:274:   116	    self.energy:SetMinMaxValues(0, self.energyMax)
./reviews/codex/iter7.md:275:   117	    self.energy:SetValue(e)
./reviews/codex/iter7.md:276:   118	    self.energy.text:SetText(e)
./reviews/codex/iter7.md:279:   121	    -- A regen tick lands as a sizable positive delta. Small proc gains (Combat
./reviews/codex/iter7.md:281:   123	    -- We MEASURE the real tick cadence from gap to gap (clamped) instead of assuming
./reviews/codex/iter7.md:282:   124	    -- 2.0s — GLM and Codex disagreed on whether Adrenaline Rush changes the tick
./reviews/codex/iter7.md:283:   125	    -- interval or the per-tick amount, so measuring sidesteps the unresolved question.
./reviews/codex/iter7.md:287:   129	        if gap >= 0.8 and gap <= 2.2 then self.tickInterval = gap end
./reviews/codex/iter7.md:293:   135	-- Move the regen-tick spark; called every render frame from timers:Render.
./reviews/codex/iter7.md:295:   137	    local s = self.energy and self.energy.spark
./reviews/codex/iter7.md:297:   139	    -- hide when disabled or at full energy (no tick to wait for)
./reviews/codex/iter7.md:298:   140	    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
./reviews/codex/iter7.md:301:   143	    local interval = self.tickInterval or 2.0
./reviews/codex/iter7.md:304:   146	    local w = self.energy:GetWidth()
./reviews/codex/iter7.md:310:   152	    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
./reviews/codex/iter7.md:311:   153	    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
./reviews/codex/iter7.md:343:/bin/zsh -lc 'nl -ba cooldowns.lua' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:345:     1	-- cooldowns.lua: rogue defensive/utility cooldown icons with sweep timers.
./reviews/codex/iter7.md:346:     2	-- READ-ONLY — shows cooldown state, never casts. Only icons for spells you KNOW
./reviews/codex/iter7.md:350:     6	local CDs = NS:RegisterModule("cooldowns", {})
./reviews/codex/iter7.md:414:    70	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter7.md:415:    71	    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
./reviews/codex/iter7.md:416:    72	    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
./reviews/codex/iter7.md:417:    73	    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
./reviews/codex/iter7.md:427:    83	    ev:SetScript("OnUpdate", function()
./reviews/codex/iter7.md:512:    17	    print("  |cffffff00/cut ticks|r        toggle energy 20-mark lines")
./reviews/codex/iter7.md:513:    18	    print("  |cffffff00/cut spark|r        toggle energy regen-tick spark")
./reviews/codex/iter7.md:514:    19	    print("  |cffffff00/cut zone|r         toggle refresh-now marker on bars")
./reviews/codex/iter7.md:515:    20	    print("  |cffffff00/cut smart|r        green only when CP/energy ready")
./reviews/codex/iter7.md:548:    53	        elseif cmd == "ticks" then
./reviews/codex/iter7.md:549:    54	            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
./reviews/codex/iter7.md:551:    56	            db.tickSpark = not db.tickSpark; Print("regen-tick spark " .. on(db.tickSpark))
./reviews/codex/iter7.md:553:    58	            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
./reviews/codex/iter7.md:555:    60	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
./reviews/codex/iter7.md:564:    69	            Print("position reset (/reload to apply)")
./reviews/codex/iter7.md:568:    73	            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
./reviews/codex/iter7.md:569:    74	                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
./reviews/codex/iter7.md:584:     3	-- Uses CLEU for application/refresh so it works pre-2.5 aura APIs reliably.
./reviews/codex/iter7.md:603:    22	-- Can the player actually refresh this aura right now? Used to gate the green
./reviews/codex/iter7.md:604:    23	-- "refresh-now" cue so it never implies an action you lack resources for.
./reviews/codex/iter7.md:605:    24	-- Finisher cost is 25 energy; SnD needs only energy, Rupture/Expose also need CP.
./reviews/codex/iter7.md:609:    28	        return e >= 25 -- self-buff, only needs energy
./reviews/codex/iter7.md:611:    30	        -- finishers: need a live attackable target AND energy AND a combo point
./reviews/codex/iter7.md:618:    37	    return false -- Garrote: stealth-only, can't refresh in combat -> never cue green
./reviews/codex/iter7.md:621:    40	local function GetAura(unit, name, byPlayer)
./reviews/codex/iter7.md:623:    42	    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
./reviews/codex/iter7.md:624:    43	    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
./reviews/codex/iter7.md:625:    44	    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
./reviews/codex/iter7.md:628:    47	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
./reviews/codex/iter7.md:629:    48	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
./reviews/codex/iter7.md:633:    52	            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
./reviews/codex/iter7.md:635:    54	            n, _, _, _, dur2, exp2 = UnitAura(unit, i, filter)
./reviews/codex/iter7.md:670:    89	        -- "refresh now" marker: when the fill shrinks past this line you're in the
./reviews/codex/iter7.md:671:    90	        -- window to refresh without significant clipping (TBC has no pandemic).
./reviews/codex/iter7.md:672:    91	        b.marker = b:CreateTexture(nil, "OVERLAY")
./reviews/codex/iter7.md:673:    92	        b.marker:SetColorTexture(1, 1, 1, 0.9)
./reviews/codex/iter7.md:674:    93	        b.marker:SetSize(2, BAR_H)
./reviews/codex/iter7.md:675:    94	        b.marker:Hide()
./reviews/codex/iter7.md:681:   100	        -- reset transient render state on hide (set ONCE, not per tick)
./reviews/codex/iter7.md:682:   101	        b:SetScript("OnHide", function(s) s.inZone = nil; s.greenState = nil; s.markerDur = nil end)
./reviews/codex/iter7.md:686:   105	    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
./reviews/codex/iter7.md:689:   108	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter7.md:693:   112	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter7.md:695:   114	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter7.md:711:   130	            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
./reviews/codex/iter7.md:717:   136	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter7.md:731:   150	                b:Hide(); b.marker:Hide()
./reviews/codex/iter7.md:732:   151	                b.inZone = nil; b.greenState = nil; b.markerDur = nil
./reviews/codex/iter7.md:738:   157	            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
./reviews/codex/iter7.md:742:   161	            -- refresh-now marker: the fill's right edge crosses it at rem==warnAt.
./reviews/codex/iter7.md:744:   163	            if NS.db.refreshZone then
./reviews/codex/iter7.md:745:   164	                if b.markerDur ~= dur then
./reviews/codex/iter7.md:746:   165	                    b.markerDur = dur
./reviews/codex/iter7.md:749:   168	                    b.marker:ClearAllPoints()
./reviews/codex/iter7.md:750:   169	                    b.marker:SetPoint("CENTER", b, "LEFT", frac * BAR_W, 0) -- centered on edge
./reviews/codex/iter7.md:752:   171	                if not b.marker:IsShown() then b.marker:Show() end
./reviews/codex/iter7.md:753:   172	            elseif b.marker:IsShown() then
./reviews/codex/iter7.md:754:   173	                b.marker:Hide()
./reviews/codex/iter7.md:770:   189	            local green = want and NS.db.refreshZone
./reviews/codex/iter7.md:799:    13	    -- don't nag to Kick when it can't actually be cast (e.g. not enough energy)
./reviews/codex/iter7.md:846:    60	    ev:RegisterEvent("UNIT_SPELLCAST_START")
./reviews/codex/iter7.md:847:    61	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./reviews/codex/iter7.md:848:    62	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./reviews/codex/iter7.md:849:    63	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./reviews/codex/iter7.md:850:    64	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./reviews/codex/iter7.md:851:    65	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter7.md:852:    66	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./reviews/codex/iter7.md:853:    67	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./reviews/codex/iter7.md:854:    68	    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
./reviews/codex/iter7.md:856:    70	    ev:RegisterEvent("UPDATE_STEALTH")
./reviews/codex/iter7.md:857:    71	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter7.md:864:    78	    if e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_ENTERING_WORLD" or e == "UNIT_INVENTORY_CHANGED" then
./reviews/codex/iter7.md:866:    80	    elseif e == "PLAYER_REGEN_DISABLED" then
./reviews/codex/iter7.md:869:    83	    if e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_ENTERING_WORLD" then
./reviews/codex/iter7.md:879:    93	        -- still re-evaluate on target change / cooldown updates
./reviews/codex/iter7.md:880:    94	        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
./reviews/codex/iter7.md:944:     6	## SavedVariables: CutthroatDB
./reviews/codex/iter7.md:950:    12	cooldowns.lua
./reviews/codex/iter7.md:955:The first integration pass shows the load path is mostly deliberate: TOC loads `core.lua` before modules, modules register at file load, and `PLAYER_LOGIN` initializes rogue modules after SavedVariables are assigned. I’m checking the remaining cross-module edges now: slash refresh behavior, duplicate events, and stale UI state after config toggles.
./reviews/codex/iter7.md:957:/bin/zsh -lc "grep -RIn \"RegisterEvent\\|RegisterUnitEvent\\|SetScript(\\\"OnUpdate\\|function [A-Za-z_]\\|"'^[A-Za-z_][A-Za-z0-9_]* =" core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:961:core.lua:44:f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter7.md:962:core.lua:45:f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter7.md:963:core.lua:58:        local function initModule(name)
./reviews/codex/iter7.md:967:hud.lua:106:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter7.md:973:timers.lua:40:local function GetAura(unit, name, byPlayer)
./reviews/codex/iter7.md:976:timers.lua:108:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter7.md:977:timers.lua:114:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter7.md:981:cooldowns.lua:27:function CDs:Init()
./reviews/codex/iter7.md:982:cooldowns.lua:70:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter7.md:983:cooldowns.lua:71:    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
./reviews/codex/iter7.md:984:cooldowns.lua:72:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
./reviews/codex/iter7.md:985:cooldowns.lua:73:    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
./reviews/codex/iter7.md:986:cooldowns.lua:83:    ev:SetScript("OnUpdate", function()
./reviews/codex/iter7.md:987:cooldowns.lua:97:function CDs:RebuildKnown()
./reviews/codex/iter7.md:988:cooldowns.lua:110:function CDs:Relayout()
./reviews/codex/iter7.md:989:cooldowns.lua:128:function CDs:UpdateCooldowns()
./reviews/codex/iter7.md:990:cooldowns.lua:145:function CDs:Refresh()
./reviews/codex/iter7.md:993:alerts.lua:60:    ev:RegisterEvent("UNIT_SPELLCAST_START")
./reviews/codex/iter7.md:994:alerts.lua:61:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./reviews/codex/iter7.md:995:alerts.lua:62:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./reviews/codex/iter7.md:996:alerts.lua:63:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./reviews/codex/iter7.md:997:alerts.lua:64:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./reviews/codex/iter7.md:998:alerts.lua:65:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter7.md:999:alerts.lua:66:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./reviews/codex/iter7.md:1000:alerts.lua:67:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./reviews/codex/iter7.md:1001:alerts.lua:68:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
./reviews/codex/iter7.md:1003:alerts.lua:70:    ev:RegisterEvent("UPDATE_STEALTH")
./reviews/codex/iter7.md:1004:alerts.lua:71:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter7.md:1017:/bin/zsh -lc "grep -RIn \"NS\\.db\\|NS\\.modules\\|NS\\.IsRogue\\|CreateFrame\\|SlashCmdList\\|_G\\[\" core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter7.md:1030:hud.lua:37:    local energy = CreateFrame("StatusBar", nil, root)
./reviews/codex/iter7.md:1032:hud.lua:140:    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
./reviews/codex/iter7.md:1047:timers.lua:163:            if NS.db.refreshZone then
./reviews/codex/iter7.md:1049:timers.lua:189:            local green = want and NS.db.refreshZone
./reviews/codex/iter7.md:1051:cooldowns.lua:28:    if not NS.IsRogue then return end
./reviews/codex/iter7.md:1052:cooldowns.lua:29:    local root = NS.modules.hud.root
./reviews/codex/iter7.md:1053:cooldowns.lua:54:        local f = CreateFrame("Frame", nil, root)
./reviews/codex/iter7.md:1054:cooldowns.lua:60:        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
./reviews/codex/iter7.md:1055:cooldowns.lua:69:    local ev = CreateFrame("Frame")
./reviews/codex/iter7.md:1056:cooldowns.lua:112:    local root = NS.modules.hud.root
./reviews/codex/iter7.md:1074:No blocker found for normal rogue login, `/reload`, or non-rogue login. Init order is basically sound: TOC loads `core.lua` first, modules register before `PLAYER_LOGIN`, `NS.db` is assigned on `ADDON_LOADED`, and rogue-only modules initialize after HUD exists.
./reviews/codex/iter7.md:1076:I would ship after fixing the low-cost OnUpdate/event cleanup items below. Nothing here looks like taint/security trouble.
./reviews/codex/iter7.md:1080:1. `cooldowns.lua`, `CDs:Init`, lines 82-89: permanent per-frame `OnUpdate` runs forever just to check `layoutDirty`.
./reviews/codex/iter7.md:1081:Concrete fix: set `OnUpdate` only when `SPELLS_CHANGED` / `CHARACTER_POINTS_CHANGED` marks dirty, then clear it after rebuild:
./reviews/codex/iter7.md:1082:`ev:SetScript("OnUpdate", nil)` after `RebuildKnown()` / `Relayout()`.
./reviews/codex/iter7.md:1085:This works today, but it creates a shared-state hazard: any future module setting `root:SetScript("OnUpdate", ...)` will silently replace timers/HUD animation updates.
./reviews/codex/iter7.md:1086:Concrete fix: create a private render frame parented to root, e.g. `self.renderFrame = CreateFrame("Frame", nil, root)`, and put the timer `OnUpdate` there.
./reviews/codex/iter7.md:1089:This is not a correctness bug, but it is redundant. The 0.05s loop is needed for CP glow/tick spark animation, not necessarily for full `UpdatePower()` and `UpdateCP()` every tick.
./reviews/codex/iter7.md:1090:Concrete fix: split HUD methods into cheap animation render vs state refresh. Let events call `UpdatePower()` / `UpdateCP()`, and let the render loop call only `UpdateEnergyTick()` plus CP glow animation if needed.
./reviews/codex/iter7.md:1092:4. `alerts.lua` + `cooldowns.lua`, event registration, lines `alerts.lua:71` and `cooldowns.lua:70`: both register `SPELL_UPDATE_COOLDOWN`.
./reviews/codex/iter7.md:1093:This is acceptable at current scale, but it duplicates event wakeups for related cooldown state.
./reviews/codex/iter7.md:1094:Concrete fix: either leave as-is because behavior is simple, or centralize cooldown-change fanout through core if more modules start listening to the same event.
./reviews/codex/iter7.md:1096:5. `core.lua`, SavedVariables merge, lines 48-54: defaults merge is shallow.
./reviews/codex/iter7.md:1100:6. `core.lua`, comments vs actual init order, lines 56-62: comment says “hud first” and “config last”, but code initializes `config` first.
./reviews/codex/iter7.md:1102:Concrete fix: update the comment to say config initializes first, rogue visual modules initialize after HUD.
./reviews/codex/iter7.md:1114:10. `/reload` safety: normal `/reload` is safe because Lua state resets and frames/events are recreated once.
./reviews/codex/iter7.md:1121:2. `/reload`: no duplicate HUD/icons/alerts, saved position and scale persist.
./reviews/codex/iter7.md:1123:4. Drag unlocked HUD, `/reload`: position persists.
./reviews/codex/iter7.md:1126:7. Spend/apply Slice and Dice, Rupture, Expose Armor, Garrote: bars appear, expire, and refresh markers behave.
./reviews/codex/iter7.md:1127:8. Use rogue cooldowns: known cooldown icons only, cooldown sweep/desaturation updates.
./reviews/codex/iter7.md:1128:9. Target an interruptible cast with Kick ready/on cooldown: Kick alert appears only when actionable.
./reviews/codex/iter7.md:1138:No blocker found for normal rogue login, `/reload`, or non-rogue login. Init order is basically sound: TOC loads `core.lua` first, modules register before `PLAYER_LOGIN`, `NS.db` is assigned on `ADDON_LOADED`, and rogue-only modules initialize after HUD exists.
./reviews/codex/iter7.md:1140:I would ship after fixing the low-cost OnUpdate/event cleanup items below. Nothing here looks like taint/security trouble.
./reviews/codex/iter7.md:1144:1. `cooldowns.lua`, `CDs:Init`, lines 82-89: permanent per-frame `OnUpdate` runs forever just to check `layoutDirty`.
./reviews/codex/iter7.md:1145:Concrete fix: set `OnUpdate` only when `SPELLS_CHANGED` / `CHARACTER_POINTS_CHANGED` marks dirty, then clear it after rebuild:
./reviews/codex/iter7.md:1146:`ev:SetScript("OnUpdate", nil)` after `RebuildKnown()` / `Relayout()`.
./reviews/codex/iter7.md:1149:This works today, but it creates a shared-state hazard: any future module setting `root:SetScript("OnUpdate", ...)` will silently replace timers/HUD animation updates.
./reviews/codex/iter7.md:1150:Concrete fix: create a private render frame parented to root, e.g. `self.renderFrame = CreateFrame("Frame", nil, root)`, and put the timer `OnUpdate` there.
./reviews/codex/iter7.md:1153:This is not a correctness bug, but it is redundant. The 0.05s loop is needed for CP glow/tick spark animation, not necessarily for full `UpdatePower()` and `UpdateCP()` every tick.
./reviews/codex/iter7.md:1154:Concrete fix: split HUD methods into cheap animation render vs state refresh. Let events call `UpdatePower()` / `UpdateCP()`, and let the render loop call only `UpdateEnergyTick()` plus CP glow animation if needed.
./reviews/codex/iter7.md:1156:4. `alerts.lua` + `cooldowns.lua`, event registration, lines `alerts.lua:71` and `cooldowns.lua:70`: both register `SPELL_UPDATE_COOLDOWN`.
./reviews/codex/iter7.md:1157:This is acceptable at current scale, but it duplicates event wakeups for related cooldown state.
./reviews/codex/iter7.md:1158:Concrete fix: either leave as-is because behavior is simple, or centralize cooldown-change fanout through core if more modules start listening to the same event.
./reviews/codex/iter7.md:1160:5. `core.lua`, SavedVariables merge, lines 48-54: defaults merge is shallow.
./reviews/codex/iter7.md:1164:6. `core.lua`, comments vs actual init order, lines 56-62: comment says “hud first” and “config last”, but code initializes `config` first.
./reviews/codex/iter7.md:1166:Concrete fix: update the comment to say config initializes first, rogue visual modules initialize after HUD.
./reviews/codex/iter7.md:1178:10. `/reload` safety: normal `/reload` is safe because Lua state resets and frames/events are recreated once.
./reviews/codex/iter7.md:1185:2. `/reload`: no duplicate HUD/icons/alerts, saved position and scale persist.
./reviews/codex/iter7.md:1187:4. Drag unlocked HUD, `/reload`: position persists.
./reviews/codex/iter7.md:1190:7. Spend/apply Slice and Dice, Rupture, Expose Armor, Garrote: bars appear, expire, and refresh markers behave.
./reviews/codex/iter7.md:1191:8. Use rogue cooldowns: known cooldown icons only, cooldown sweep/desaturation updates.
./reviews/codex/iter7.md:1192:9. Target an interruptible cast with Kick ready/on cooldown: Kick alert appears only when actionable.
./reviews/glm/iter11.md:4:**Why it's high value:** Rogue energy addons often break when Blizzard tweaks server tick timing or when players zone. If the addon miscalibrates the predicted tick interval, the energy bar spark will wildly jump out of sync. Testing this ensures your dynamic calibration logic survives refactors.
./reviews/glm/iter11.md:6:Zero out the state, force an energy drop to trigger the addon's internal state recording, then fire frequent update events to simulate the client predicting energy, followed by the actual server sync.
./reviews/glm/iter11.md:8:Assert that the addon's internal tick interval state recalculates to ~2.0 seconds. Then, assert that the spark's animation frame (or internal state) actually resets its loop exactly when a tick happens, rather than drifting.
./reviews/glm/iter11.md:11:state.energy = 40
./reviews/glm/iter11.md:13:tick(0.1) 
./reviews/glm/iter11.md:14:-- Simulate server verifying the energy tick exactly 2.0s later
./reviews/glm/iter11.md:15:state.energy = 60 
./reviews/glm/iter11.md:20:check("Energy tick calibrated to ~2.0s", NS.modules.hud.tickInterval and math.abs(NS.modules.hud.tickInterval - 2.0) < 0.1)
./reviews/glm/iter11.md:25:### 2. Aura Filter Collision (HARMFUL vs HELPFUL) (`timers.lua`)
./reviews/glm/iter11.md:26:**Why it is high value:** In TBC, querying auras by index is notoriously buggy. Addons frequently regress when a mob casts a self-buff (HELPFUL) that shares a name with a Rogue debuff (e.g., "Rip" vs "Rupture", or some generic bleed). If your aura parser doesn't filter by `unitCaster` (HARMFUL-PLAYER), it will falsely show a finisher bar for an aura the Rogue didn't apply. 
./reviews/glm/iter11.md:35:tick(0.06)
./reviews/glm/iter11.md:38:check("Timer ignores target-cast HARMFUL auras matching finisher names", not NS.modules.timers.bars.rup._shown)
./reviews/glm/iter11.md:41:### 3. `maxSeen` Duration Scaling & Clamp (`timers.lua`)
./reviews/glm/iter11.md:42:**Why it is high value:** Rogue timers often dynamically resize the bar scale so a 5-CP Rupture (18s) visually takes up more space than a 1-CP Rupture (8s) without destroying the UI layout. If the `maxSeen` tracking variable isn't sanitized or updated correctly, the UI can permanently "max out" the scaling logic if it ever caches a bugged 9999s duration from an API hiccup.
./reviews/glm/iter11.md:46:Assert that `maxSeen` resets/clamps appropriately, and that the mock's `SetStatusBarColor` or `SetMinMaxValues` bounds reflect a safe scale rather than an infinite glitch.
./reviews/glm/iter11.md:51:tick(0.06)
./reviews/glm/iter11.md:52:-- Aura falls off
./reviews/glm/iter11.md:55:tick(0.06)
./reviews/glm/iter11.md:58:check("maxSeen duration is safely clamped/reset on aura drop", NS.modules.timers.maxSeen ~= nil and NS.modules.timers.maxSeen < 30)
./reviews/glm/iter4.md:1:Here is the review of the `refresh-now zone` feature, ordered from critical logic bugs to UX/context checks. 
./reviews/glm/iter4.md:6:*   **Bug:** The marker position calculation `local mx = (warnAt / dur) * BAR_W` is mathematically incorrect for a left-to-right draining StatusBar. 
./reviews/glm/iter4.md:9:    *   Multiplying a fraction like `2 / 24` by `BAR_W` (200) puts the marker at **~16px from the left**. However, the bar fill is `200px` wide at that point. The marker will sit in the middle of the full bar, not at the depleting edge.
./reviews/glm/iter4.md:10:*   **Concrete Fix:** The marker should be offset by the fraction of time *remaining*. 
./reviews/glm/iter4.md:24:*   **Bug:** `b.marker:SetPoint("LEFT", b, "LEFT", mx, 0)`. Because the bar drains from right to left, depleting durations approach the left edge (0,0). Any offset from the `LEFT` pushes the marker *into* the empty void of the bar, not the fill. 
./reviews/glm/iter4.md:25:*   **Concrete Fix:** Anchor the marker to the `RIGHT` and use a **negative** offset. Because of how WoW's StatusBar works, anchoring `RIGHT` to `RIGHT` with `-mx` places the marker exactly at the edge of the fill when `rem == warnAt`.
./reviews/glm/iter4.md:30:    b.marker:ClearAllPoints()
./reviews/glm/iter4.md:31:    b.marker:SetPoint("RIGHT", b, "RIGHT", -mx, 0) -- Negate the offset!
./reviews/glm/iter4.md:37:*   **Bug:** In `Render`, you call `b.marker:ClearAllPoints()` and `SetPoint` every single frame (0.05s). This forces the WoW UI engine to recalculate UI layout coordinates continuously, which is terrible for performance. Furthermore, when the bar hides (`b:Hide()`), the marker doesn't always hide because `OnHide` on the parent doesn't cascade to manual `Show()` calls on children unless hooked.
./reviews/glm/iter4.md:38:*   **Concrete Fix:** Set the point **ONCE** during `Init()`. In `Render`, only call `SetPoint` if you are un-hiding it. Hide the marker explicitly when the bar hides.
./reviews/glm/iter4.md:41:    b.marker:SetPoint("RIGHT", b, "RIGHT", 0, 0) -- Default 0 offset
./reviews/glm/iter4.md:43:    -- In Render() replacing the marker logic:
./reviews/glm/iter4.md:44:    if NS.db.refreshZone then
./reviews/glm/iter4.md:47:        b.marker:SetPoint("RIGHT", b, "RIGHT", -mx, 0)
./reviews/glm/iter4.md:48:        if not b.marker:IsShown() then b.marker:Show() end
./reviews/glm/iter4.md:50:        if b.marker:IsShown() then b.marker:Hide() end
./reviews/glm/iter4.md:56:        b.marker:Hide() -- ensure marker vanishes with bar
./reviews/glm/iter4.md:70:            if NS.db.refreshZone then b:SetStatusBarColor(unpack(NS.color.good)) end
./reviews/glm/iter4.md:86:*   **Bug:** When you switch targets, `UNIT_AURA` or `PLAYER_TARGET_CHANGED` fires, triggering `Scan()`. If the new target doesn't have your Rupture, `c` becomes `nil` and the bar is hidden in `Render()`. However, `b.warned` (or the boolean state) is only reset on `OnHide`. If the user has a frame-delay where the marker is shown, or if `b:Hide()` is bypassed somehow, the marker's `mx` position from the *old* target remains stale.
./reviews/glm/iter4.md:87:*   **Concrete Fix:** Tie the marker strictly to the render loop visibility as fixed in Point #3.
./reviews/glm/iter4.md:92:*   **Bug:** Your context is 100% correct: TBC has no pandemic, early refreshes = clipped duration = wasted Combo Points/Energy. However, purely coloring the bar Green as a "refresh now" cue is slightly dangerous UX for a Rogue. 
./reviews/glm/iter4.md:93:    *   For **Slice and Dice**, you *never* want to refresh early unless absolutely necessary, as it lowers your uptime. 
./reviews/glm/iter4.md:94:    *   The standard TBC Rogue UI convention is to show the **green refresh window** when you have enough Energy/Combo Points to safely refresh *without* clipping the current tick, otherwise it stays red/yellow.
./reviews/glm/iter4.md:95:*   **Concrete Fix:** If you want to be truly optimal, the recolor should trigger based on `rem <= warnAt` **AND** `NS.modules.hud:HasFinisherCondition()` (e.g., 5 CPs for Rupture, or Energy > 25 for SnD). If they lack the resources to refresh, it shouldn't be green. If that's too complex for this iteration, the current `rem <= warnAt` is acceptable as a basic visual cue, but consider making the Green a pulsing opacity (`SetVertexColor`) so it implies *urgency* rather than *permission*.
./reviews/glm/iter5.md:1:Here is the review of the resource-aware refresh cue. The feature is functionally brilliant—your event-driven aura caching nicely avoids per-frame overhead, and the state-machine approach to UI updates is highly optimized. However, there is a critical spec failure regarding Rogue resource generation in TBC that breaks the dynamic nature of this feature, along with a minor spec deviation in the `UNIT_AURA` API usage.
./reviews/glm/iter5.md:7:* **Function:** `HasRefreshResources` (and upvalue definition)
./reviews/glm/iter5.md:8:* **Bug:** TBC Rogue energy ticks **20** every 2 seconds, meaning energy values rarely land exactly on 25. Without GCD/latency prediction, the green cue will only flash exactly when the client receives an energy tick putting the player at $\ge$ 25. If the player triggers a GCD action at 20 energy, the cue won't light up when it mathematically *should* (predicting the next tick). Furthermore, the comment for `b.marker:ClearAllPoints()` incorrectly states TBC has no pandemic; refreshing Rupture/Garrote mid-duration **pandemics** the remaining time into the new base duration in TBC. 
./reviews/glm/iter5.md:9:* **Fix:** Implement a simple pseudo-energy ticker to dynamically predict pooling through GCDs, and correct the pandemic comment.
./reviews/glm/iter5.md:19:        -- Predict energy gain if currently in a global cooldown
./reviews/glm/iter5.md:21:            local ticks = math.floor((GetTime() - lastEnergyTick) / ENERGY_TICK_RATE) + 1
./reviews/glm/iter5.md:22:            e = math.min(e + ticks * 20, 100)
./reviews/glm/iter5.md:33:-- Fix the marker comment in Timers:Init():
./reviews/glm/iter5.md:34:-- "refresh now" marker: ... (TBC refreshes pandemic the remaining duration)
./reviews/glm/iter5.md:40:* **Bug:** `RegisterUnitEvent` is a Retail API addition. In interface 20504 (BCC), `RegisterUnitEvent` evaluates to nil. This silently fails, meaning `self:Scan()` is never called on aura changes (only on `PLAYER_TARGET_CHANGED`), breaking tracker updates whenever you refresh a debuff on a current target.
./reviews/glm/iter5.md:44:    scan:RegisterEvent("UNIT_AURA") -- Standard for 2.5.x
./reviews/glm/iter5.md:45:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/glm/iter5.md:54:* **Function:** Upvalue definitions
./reviews/glm/iter5.md:61:### 4. `b.marker` visualization incorrect on bar refreshes
./reviews/glm/iter5.md:64:* **Bug:** The `b.markerDur` state is only reset in `OnHide`. Because `b.inZone` explicitly resets to `nil` inside the render loop when an aura expires, it bypasses `OnHide`. The marker position state persists, calculating a bad ratio against a newly applied aura's duration.
./reviews/glm/iter5.md:65:* **Fix:** Synchronize the marker reset with the expiration reset block.
./reviews/glm/iter5.md:70:                b:Hide(); b.marker:Hide()
./reviews/glm/iter5.md:71:                b.inZone = nil; b.greenState = nil; b.markerDur = nil -- Ensure it resets here too
./reviews/glm/iter5.md:78:* **Bug:** If the target dies while inside the refresh window, `GetComboPoints("player", "target")` returns `0` which correctly kills the cue. However, if the player swaps to a dead target (or a friendly NPC) to refresh a debuff, a lack of targeting safety can pass `nil` to boolean checks and cause hiccups depending on your HUD's state. 
./reviews/glm/iter5.md:90:1. **Thresholds/Talents:** Yes, all three cost 25 energy. Improved SnD strictly increases duration (and thus stat scaling), no standard rogue talent lowers finisher *cost*.
./reviews/glm/iter5.md:94:5. **Dynamic tick up:** Will physically toggle, but only when crossing the hard 25 energy threshold. See Bug #1 for GCD prediction. 
./reviews/glm/iter1.md:5:**Bug:** You are registering for `UNIT_POWER_FREQUENT`, which in TBC 2.5.x *does not fire* for Energy regeneration ticks or Combo Point changes while the player is stealthed. This was changed to `UNIT_POWER_UPDATE` in the 2.5.4 patch specifically to fix stealth addons. Because you also don't update CP on `PLAYER_ENTERING_WORLD` or after casting, CPs will often visually freeze at 0 until a target swap occurs. 
./reviews/glm/iter1.md:10:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
./reviews/glm/iter1.md:11:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/glm/iter1.md:13:        -- Only update power if it's an energy tick event
./reviews/glm/iter1.md:24:### 2. Invalid Aura Filter Logic Causes Timer Bars to Never Show
./reviews/glm/iter1.md:26:**Bug:** `GetAuraRemaining` attempts to find self buffs (like Slice and Dice) by passing `byPlayer and "HARMFUL|PLAYER" or "HELPFUL|PLAYER"`. Because Slice and Dice is called with `isSelf = false` (Line 64), the filter evaluates to `"HELPFUL|PLAYER"`. In WoW's API, combining `HELPFUL` and `PLAYER` is an invalid filter string, which causes `C_UnitAuras.GetAuraDataByIndex` to silently return `nil`. This completely breaks tracking for SnD, and also fundamentally breaks tracking for any target debuff that isn't directly cast by the player (e.g. Mangle/Trauma debuff extensions applied by other players). 
./reviews/glm/iter1.md:27:**Fix:** Hardcode the standard `"HARMFUL PLAYER"` (space, not pipe) and `"HELPFUL PLAYER"` filter strings, and apply them dynamically based on aura type.
./reviews/glm/iter1.md:29:-- Replace the C_UnitAuras logic block inside GetAuraRemaining
./reviews/glm/iter1.md:30:local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL PLAYER"
./reviews/glm/iter1.md:32:    local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
./reviews/glm/iter1.md:44:**Bug:** The addon relies heavily on an alpha pulse to alert the player to Kick, but it uses `ag:SetLooping("BOUNCE")` along with an Alpha animation going from `1.0` to `0.35`. On certain Blizzard UI states, `BOUNCE` on Alpha animations can be subtly buggy or fail to re-render smoothly. However, a more severe logic bug occurs on **Line 73**: `if not self.kick:IsShown() then self.kick:Show(); self.kick.ag:Play() end`. If you are out of combat and Kick comes off cooldown while a target is actively casting (e.g. a mob casting before you pull), `SPELL_UPDATE_COOLDOWN` triggers `CheckKick`, but because the animation group was stopped previously, it may not always cleanly restart if `ag:Stop()` wasn't explicitly called with a reset.
./reviews/glm/iter1.md:56:**Bug:** The variable `b.maxSeen` is used to set the max value of the status bar. The logic `if not b.maxSeen or rem > b.maxSeen then b.maxSeen = rem end` assumes that auras only get stronger. However, if a player casts a 5-Combo Point Rupture (max duration), and then 3 seconds later overwrites it with a 1-Combo Point Rupture (very short duration), `maxSeen` remains locked to the massive 5-CP duration. The new, much shorter rupture will render as a tiny sliver on the bar, defeating the purpose of a dynamic timer. 
./reviews/glm/iter1.md:57:**Fix:** If the current remaining time (`rem`) is noticeably longer than what was previously on the bar (plus a buffer for latency), you are looking at a fresh application/refresh and should reset `maxSeen`. 
./reviews/glm/iter1.md:63:    -- If the new remaining time is greater than the old remaining time, it was refreshed!
./reviews/glm/iter1.md:64:    if not b.maxSeen or rem > (b.prevRem or 0) + 0.5 then
./reviews/glm/iter1.md:65:        b.maxSeen = rem
./reviews/glm/iter1.md:69:    b:SetMinMaxValues(0, b.maxSeen or rem)
./reviews/glm/iter1.md:88:**Bug:** `CheckPoison` is only called on `PLAYER_REGEN_ENABLED`. If a player forgets to apply poisons before a boss fight, they will receive no warning whatsoever because they are already in combat (`PLAYER_REGEN_DISABLED` hides the text and the check never runs). 
./reviews/glm/iter1.md:89:**Fix:** You should also run `CheckPoison` immediately upon logging in or loading the addon to catch missing poisons before the first pull is initiated. 
./reviews/glm/iter1.md:93:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
./reviews/glm/iter1.md:96:    elseif e == "PLAYER_ENTERING_WORLD" then
./reviews/glm/iter10.md:51:*   **Event Registration Limits:** You mock `f:RegisterEvent(e)` but never check if an addon tries to register an event *that does not exist* in the WoW API (e.g., `PLAYER_TARGET_CHANGED` is real, but `PLAYER_TARGET_MOVED` is not). 
./reviews/glm/iter10.md:52:*   **OnUpdate throttling:** Your `tick` assumes all frames have `OnUpdate`. If an addon creates 100 frames and puts heavy logic in `OnUpdate` without throttling it via `GetTime()`, the test passes instantly. In WoW, this drops the user's FPS to 1.
./reviews/glm/iter10.md:53:**The Fix:** Create an allowlist of valid WoW 2.5.x events. Make `RegisterEvent` fail the test if an invalid event is passed. 
./reviews/glm/iter10.md:60:If `UNIT_POWER_FREQUENT` throws a Lua error internally, `pcall` traps it, returns `false`, and the test prints a fail. But if the event handler does `if energy > 100 then ThrowError() end`, it might not trigger in this specific test state.
./reviews/glm/iter10.md:62:**The Fix:** You need *behavioral assertions* against expected states, not just `pcall` wrappers. Assert specific values (e.g., `check("Energy correctly capped", NS.db.energy == 100)`).
./reviews/glm/iter10.md:67:*   **Zone changes:** Going from a Raid into an Arena resets cooldowns and unregisters events. Does the addon handle `PLAYER_ENTERING_WORLD` properly?
./reviews/glm/iter8.md:16:Your UI correctly sets `_G[sn.."High"]` to `"3.0"` on init. However, inside the `OnValueChanged` script, `sl:GetName().."Text"` sets the **title** of the slider (which overwrites the default empty string). So your slider label dynamically changes to "Scale: 1.50", but your hardcoded `0.4` / `3.0` are disconnected from `s:SetMinMaxValues()`. If you later change the limits, the UI lies.
./reviews/glm/iter8.md:17:**fix:** Set the slider title once during initialization, then update only the title text on value change. 
./reviews/glm/iter8.md:32:**3. file: `options.lua` / `core.lua` | function: `Options:Init` | bug: `NS.db` can be nil, causing a UI freeze/taint if options load before SavedVariables.**
./reviews/glm/iter8.md:33:Your `core.lua` initializes `NS.db` on `ADDON_LOADED`. However, if `ADDON_LOADED` fires, triggers sanitization, and then errors out (or if an external addon manager forces your options frame to load prematurely), `NS.db` is nil. `Options:Init()` immediately calls `NS.db[key]`, which will throw a Lua error and brick the interface panel.
./reviews/glm/iter8.md:65:**(6) `panel.name` + `panel.refresh` Hook**
./reviews/glm/iter8.md:66:This is the exact, correct hook methodology for the legacy Interface Options system. In 2.5.x, `InterfaceOptionsFrame:OnShow()` iterates over visible panels and calls `panel.refresh()` if it exists. Your logic is flawless.
./reviews/glm/iter8.md:69:**None.** Creating frames and registering them with `InterfaceOptions_AddCategory` is globally safe and lightweight. Because the UI widgets just read/write to `NS.db` (which is safely populated for all classes in `core.lua`), it acts exactly like a standard SavedVariables editor.
./reviews/glm/iter8.md:72:**No problem.** Looking at your `core.lua`, `NS.CallAll("Refresh")` is only invoked manually by the player *after* `PLAYER_LOGIN`. If the player is not a Rogue, the `if playerClass == "ROGUE" then` block skips initializing your visual modules (hud, timers, cooldowns, alerts). 
./reviews/glm/iter8.md:73:If a non-rogue toggles a checkbox, `NS.CallAll("Refresh")` will fire, but because `NS.modules["hud"]` etc. are empty/uninitialized, `CallAll` will simply iterate over an empty loop (or call the harmless `options.lua` module's own `Refresh` function) and safely do nothing.
./reviews/glm/iter6.md:57:**analysis:** Calling `HUD:UpdateCP()` on power/target changes alongside rendering it on a ~0.05s timer does **not** cause a double-show problem. The `if not g:IsShown() then g:Show() end` guard efficiently prevents double-rendering, redundant frame visibility calls, or alpha stuttering. In fact, layering event calls over a render tick guarantees absolute visual responsiveness.
./reviews/glm/iter2.md:1:Here is the review of the `cooldowns.lua` module. The script correctly uses an OnUpdate-driven `CooldownFrameTemplate` and does not automate casting, adhering to the Warden-safe requirements.
./reviews/glm/iter2.md:3:For TBC 2.5.x (Build 20504), the API signatures you assumed (`GetSpellInfo`, `GetSpellCooldown`, `CooldownFrameTemplate`) are perfectly accurate, and the GCD filtering (`> 1.5`) prevents the icons from endlessly sweeping the global cooldown. However, there are a few severe reliability bugs regarding TBC API limitations, frame anchoring, and missing event validation.
./reviews/glm/iter2.md:8:* **File:** `cooldowns.lua`
./reviews/glm/iter2.md:43:### 2. Registering `PLAYER_TALENT_UPDATE` will throw a Lua error
./reviews/glm/iter2.md:44:* **File:** `cooldowns.lua`
./reviews/glm/iter2.md:46:* **Bug:** You registered `PLAYER_TALENT_UPDATE` with a comment guessing it *"may not exist on all builds; harmless"*. In TBC 2.5.x, this event **does not exist**. Calling `RegisterEvent` with a string that the API doesn't recognize throws a hard Lua runtime error (`'PLAYER_TALENT_UPDATE' is not a valid event name`), entirely breaking the addon's initialization sequence.
./reviews/glm/iter2.md:51:    -- ev:RegisterEvent("PLAYER_TALENT_UPDATE")    
./reviews/glm/iter2.md:55:* **File:** `cooldowns.lua`
./reviews/glm/iter2.md:74:* **File:** `cooldowns.lua`
./reviews/glm/iter2.md:77:* **Concrete Fix:** Force hide the cooldown frame when clearing.
./reviews/glm/iter2.md:88:* **File:** `cooldowns.lua`
./reviews/glm/iter2.md:91:* **Concrete Fix:** Instead of instantly triggering `Relayout()`, set a simple dirty-flag boolean to delay the layout update until the next `OnUpdate` cycle.
./reviews/glm/iter2.md:105:    -- Add an OnUpdate to the event frame to process the throttle
./reviews/glm/iter2.md:106:    ev:SetScript("OnUpdate", function()
./reviews/glm/iter3.md:1:Here is the review of the energy regen-tick predictor. The real bugs affecting gameplay and logic are listed first, followed by minor logic/flaws, and finally your specific questions answered.
./reviews/glm/iter3.md:7:* **Bug:** The spark sweep speed is hardcoded to `2.0` (`/ 2.0`). With the Adrenaline Rush talent, energy ticks every 1.0s. If active, the spark will take twice as long to cross the bar as it should, badly desyncing from actual regen and ruining the pooling predictor. 
./reviews/glm/iter3.md:8:* **Fix:** Calculate the tick interval dynamically using `GetPowerRegen()`. 
./reviews/glm/iter3.md:20:* **Fix:** Only reset the spark if the energy gain matches the standard tick intervals (multiples of 20), or disable resets during known energy injections.
./reviews/glm/iter3.md:25:    -- Only reset on standard 20-energy ticks
./reviews/glm/iter3.md:32:**3. Energy tick interval assumption (Question 1)**
./reviews/glm/iter3.md:33:* **Answer:** Yes, 2.0s is correct for standard TBC Rogue energy regeneration (10 energy per 1 sec, ticks every 2 sec for 20 energy). However, relying purely on 2.0s is the source of Bug #1 and #6.
./reviews/glm/iter3.md:60:local x = (frac * self.energy:GetWidth()) - 1 -- offset for 2px width
./reviews/glm/iter3.md:61:s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
./reviews/glm/iter3.md:65:* **Answer:** You actually got this perfectly right. The checks `if self.lastEnergy and e > self.lastEnergy`, `(self.lastTick or 0)`, and `(self.lastEnergy and self.lastEnergy >= self.energyMax)` cleanly prevent nil arithmetic errors on the first load and handles edge cases gracefully. No fix needed here.
./reviews/glm/iter3.md:68:* **Answer:** No performance issues. Calling `UnitPower` and `SetValue` in a 0.05s `OnUpdate` loop is extremely cheap and highly standard for WoW addons. False resets are mitigated because `UNIT_POWER_FREQUENT` fires almost instantly anyway, so the `Render` loop isn't catching things faster than the event handler would. 
./reviews/glm/iter3.md:76:* **Answer:** At the energy cap (100), the logic `self.lastEnergy >= self.energyMax` triggers `s:Hide()`, cleanly hiding the spark. This is a great UX choice. However, during Adrenaline Rush, the sweep speed remains hardcoded to 2.0s instead of 1.0s, which breaks the predictor (see Bug #1).
./reviews/glm/iter7.md:1:Here is the holistic cross-module audit of the Cutthroat addon. Overall, the architecture is remarkably solid for a WoW addon, with good separation of concerns and sensible event-driven design. However, there are a few integration hazards (especially around `OnUpdate` loops and global hooks) that need addressing before ship.
./reviews/glm/iter7.md:5:**1. High: Duplicate `OnUpdate` loops (Redundant / Wasteful)**
./reviews/glm/iter7.md:6:*   **File:** `timers.lua` & `cooldowns.lua`
./reviews/glm/iter7.md:7:*   **Issue:** `timers.lua` sets an `OnUpdate` on the root frame to render timers (gated at 0.05s). `cooldowns.lua` creates a *brand new hidden frame* with its own `OnUpdate` to check a single dirty flag *every single frame* (uncapped). Multiple `OnUpdate` handlers firing independently is inefficient and anti-pattern in WoW UI design.
./reviews/glm/iter7.md:8:*   **Fix:** Consolidate into the existing `OnUpdate` in `timers.lua`. 
./reviews/glm/iter7.md:10:    -- In timers.lua OnUpdate:
./reviews/glm/iter7.md:11:    root:SetScript("OnUpdate", function(_, dt)
./reviews/glm/iter7.md:17:        -- Handle cooldowns dirty flag natively
./reviews/glm/iter7.md:18:        if NS.modules.cooldowns and NS.modules.cooldowns.layoutDirty then
./reviews/glm/iter7.md:19:            NS.modules.cooldowns.layoutDirty = false
./reviews/glm/iter7.md:20:            NS.modules.cooldowns:RebuildKnown()
./reviews/glm/iter7.md:21:            NS.modules.cooldowns:Relayout()
./reviews/glm/iter7.md:25:    Then remove the `ev:SetScript("OnUpdate", ...)` completely from `cooldowns.lua`.
./reviews/glm/iter7.md:28:*   **File:** `cooldowns.lua`
./reviews/glm/iter7.md:37:**3. Medium: SavedVariables Migration missing for new keys**
./reviews/glm/iter7.md:39:*   **Function:** `ADDON_LOADED` event handler
./reviews/glm/iter7.md:54:*   **Issue:** This function sets `self.energy:SetMinMaxValues(0, self.energyMax)` and `self.energy.text:SetText(e)` every single time it is called. `timers.lua` calls this ~20 times a second (0.05s). Redundant FrameXML C-function calls are expensive.
./reviews/glm/iter7.md:57:    if self.energyMax ~= m then
./reviews/glm/iter7.md:58:        self.energyMax = m
./reviews/glm/iter7.md:59:        self.energy:SetMinMaxValues(0, m)
./reviews/glm/iter7.md:62:        self.energy:SetValue(e)
./reviews/glm/iter7.md:63:        self.energy.text:SetText(e)
./reviews/glm/iter7.md:67:**5. Medium: Missing `/reload` re-init safety on Drag Frame**
./reviews/glm/iter7.md:69:*   **Issue:** The HUD root frame is a global named frame (`"CutthroatHUD"`). If a user reloads their UI (`/reload`) during a session, `ADDON_LOADED` fires again. While `CreateFrame` gracefully returns the existing frame instead of erroring, leftover state or hooks from the previous load might persist. 
./reviews/glm/iter7.md:84:*   **File:** `timers.lua`, `cooldowns.lua`, `alerts.lua`
./reviews/glm/iter7.md:85:*   **Issue:** `SPELL_UPDATE_COOLDOWN` is registered by both `cooldowns.lua` and `alerts.lua`. Both run full iterations over spell cooldowns independently. 
./reviews/glm/iter7.md:93:The addon is functionally complete, structurally sound, and Warden-safe (verified pure read-only with zero secure frame templates used for spell interactions). Fixing the duplicate `OnUpdate` loops (Finding #1) and the `wipe` global dependency (Finding #2) are mandatory before pushing to a live environment. The other findings are standard polish/OOM-prevention optimizations.
./reviews/glm/iter7.md:108:- [ ] Verify the Energy tick spark (the sweeping white line) moves smoothly and resets precisely when a regen tick occurs (usually every 2 seconds).
./reviews/glm/iter7.md:110:**[ ] 3. Aura Tracking (timers.lua)**
./reviews/glm/iter7.md:116:- [ ] Verify spec-specific cooldowns (Adrenaline Rush, Cold Blood) **only** appear if you are actively specced into them.
./reviews/glm/iter7.md:118:- [ ] Switch specs (reset talents). Verify the icons update dynamically without requiring a `/reload`.
./reviews/glm/iter7.md:125:**[ ] 6. Settings & SavedVariables Persistence**
./reviews/glm/iter7.md:127:- [ ] Drag the HUD to a new location. Type `/reload`. Verify the HUD stays exactly where you left it.

codex
The harness currently proves lifecycle, broad render loop safety, basic timer visibility, resource-gated green state, cooldown desaturation, and DB sanitization. I’m now reading the implementation details for the past-bug areas so the gaps are concrete and not duplicates of existing checks.
exec
/bin/zsh -lc "sed -n '1,240p' hud.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
local ADDON, NS = ...

local HUD = NS:RegisterModule("hud", {})

local WIDTH, HEIGHT = 240, 18
local CP_SIZE, CP_GAP = 22, 6
local MAX_CP = 5
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

function HUD:Init()
    if self.root then return end -- idempotent: never double-init frames
    local db = NS.db

    -- root anchor (movable)
    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
    root:SetSize(WIDTH, HEIGHT + CP_SIZE + 8)
    root:SetScale(db.scale)
    local p = db.point
    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
    root:SetMovable(true)
    root:EnableMouse(not db.locked)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", function(s) if not NS.db.locked then s:StartMoving() end end)
    root:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        local a, _, rp, x, y = s:GetPoint()
        NS.db.point = { a, nil, rp, x, y }
    end)
    self.root = root

    -- drag hint backdrop (only when unlocked)
    root.bg = root:CreateTexture(nil, "BACKGROUND")
    root.bg:SetAllPoints()
    root.bg:SetColorTexture(0, 0, 0, 0.25)

    -- ---- Energy bar ----
    local energy = CreateFrame("StatusBar", nil, root)
    energy:SetSize(WIDTH, HEIGHT)
    energy:SetPoint("TOP", root, "TOP", 0, 0)
    energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    energy:SetStatusBarColor(unpack(NS.color.energy))
    energy:SetMinMaxValues(0, 100)
    energy.bg = energy:CreateTexture(nil, "BACKGROUND")
    energy.bg:SetAllPoints()
    energy.bg:SetColorTexture(0.12, 0.10, 0.0, 0.85)
    energy.text = energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    energy.text:SetPoint("CENTER")
    self.energy = energy

    -- 20-energy tick marks
    energy.ticks = {}
    if db.energyTicks then
        for i = 1, 4 do
            local t = energy:CreateTexture(nil, "OVERLAY")
            t:SetColorTexture(0, 0, 0, 0.6)
            t:SetSize(1, HEIGHT)
            t:SetPoint("LEFT", energy, "LEFT", WIDTH * (i * 20 / 100), 0)
            energy.ticks[i] = t
        end
    end

    -- energy regen-tick spark: a thin marker sweeping the bar 0->100% over the
    -- ~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
    energy.spark = energy:CreateTexture(nil, "OVERLAY")
    energy.spark:SetColorTexture(1, 1, 1, 0.85)
    energy.spark:SetWidth(2)
    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
    energy.spark:Hide()
    self.lastEnergy = nil
    self.energyMax = 100
    self.lastTick = 0
    self.tickInterval = 2.0 -- self-calibrated from observed tick gaps

    -- ---- Combo point pips ----
    self.pips = {}
    local totalW = MAX_CP * CP_SIZE + (MAX_CP - 1) * CP_GAP
    local startX = (WIDTH - totalW) / 2
    for i = 1, MAX_CP do
        local pip = root:CreateTexture(nil, "ARTWORK")
        pip:SetSize(CP_SIZE, CP_SIZE)
        pip:SetPoint("TOPLEFT", root, "TOPLEFT", startX + (i - 1) * (CP_SIZE + CP_GAP), -(HEIGHT + 6))
        pip:SetTexture("Interface\\ComboFrame\\ComboPoint")
        pip:SetTexCoord(0, 0.375, 0, 1) -- the lit gem
        pip:SetVertexColor(unpack(NS.color.cp))
        pip:SetAlpha(0.15)
        self.pips[i] = pip
    end

    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
    -- spend them instead of overcapping (building past 5 CP is wasted generation).
    self.cpGlow = root:CreateTexture(nil, "BACKGROUND")
    self.cpGlow:SetPoint("TOPLEFT", self.pips[1], "TOPLEFT", -3, 3)
    self.cpGlow:SetPoint("BOTTOMRIGHT", self.pips[MAX_CP], "BOTTOMRIGHT", 3, -3)
    self.cpGlow:SetColorTexture(1, 0.82, 0, 1)
    self.cpGlow:SetBlendMode("ADD") -- additive => soft glow, not a harsh solid box
    self.cpGlow:Hide()

    -- Event-driven power updates, all unit-filtered to "player" so other units'
    -- power changes never wake this handler. Combo points have no reliable
    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
    -- and registering a wrong event name errors) — they're polled in timers:Tick.
    local ev = CreateFrame("Frame")
    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
    self.ev = ev
end

function HUD:UpdatePower()
    if not self.energy then return end
    local e = UnitPower("player", ENERGY)
    local m = UnitPowerMax("player", ENERGY)
    m = (m and m > 0) and m or 100
    -- This is polled ~20x/s; only make the C-side bar calls when values change.
    if m ~= self.energyMax then
        self.energyMax = m
        self.energy:SetMinMaxValues(0, m)
    end
    if e ~= self.shownEnergy then
        self.shownEnergy = e
        self.energy:SetValue(e)
        self.energy.text:SetText(e)
    end

    if self.lastEnergy == nil then self.lastEnergy = e; return end
    -- A regen tick lands as a sizable positive delta. Small proc gains (Combat
    -- Potency etc.) are ignored with the >=10 filter so they don't yank the spark.
    -- We MEASURE the real tick cadence from gap to gap (clamped) instead of assuming
    -- 2.0s — GLM and Codex disagreed on whether Adrenaline Rush changes the tick
    -- interval or the per-tick amount, so measuring sidesteps the unresolved question.
    if e > self.lastEnergy and (e - self.lastEnergy) >= 10 then
        local now = GetTime()
        local gap = now - (self.lastTick or now)
        if gap >= 0.8 and gap <= 2.2 then self.tickInterval = gap end
        self.lastTick = now
    end
    self.lastEnergy = e
end

-- Move the regen-tick spark; called every render frame from timers:Render.
function HUD:UpdateEnergyTick()
    local s = self.energy and self.energy.spark
    if not s then return end
    -- hide when disabled or at full energy (no tick to wait for)
    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
        s:Hide(); return
    end
    local interval = self.tickInterval or 2.0
    local frac = (GetTime() - (self.lastTick or 0)) / interval
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
    local w = self.energy:GetWidth()
    local sw = s:GetWidth() or 2
    local x = frac * w
    if x > w - sw then x = w - sw end  -- keep the full 2px spark inside the bar
    if x < 0 then x = 0 end
    s:ClearAllPoints()
    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
    s:Show()
end

function HUD:UpdateCP()
    -- guard on a live target so the glow can't linger after detarget
    local cp = UnitExists("target") and (GetComboPoints("player", "target") or 0) or 0
    -- polled ~20x/s; only re-alpha the pips when the CP count actually changes
    if cp ~= self.shownCP then
        self.shownCP = cp
        for i = 1, MAX_CP do
            self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
        end
    end
    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
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

function HUD:Refresh()
    if not self.root then return end
    self.root:SetScale(NS.db.scale)
    self.root:EnableMouse(not NS.db.locked)
    self.root.bg:SetShown(not NS.db.locked)
    self:UpdatePower()
    self:UpdateCP()
end

exec
/bin/zsh -lc "sed -n '1,260p' cooldowns.lua" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "sed -n '1,260p' timers.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
    if self.icons then return end -- idempotent: never double-init
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
    -- SPELLS_CHANGED fires aggressively, so coalesce layout rebuilds with a ONE-SHOT
    -- OnUpdate that removes itself after running — no permanent per-frame loop.
    local function flushLayout()
        ev:SetScript("OnUpdate", nil)
        self.layoutDirty = false
        self:RebuildKnown()
        self:Relayout()
    end
    ev:SetScript("OnEvent", function(_, e)
        if e == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateCooldowns()
        elseif not self.layoutDirty then
            self.layoutDirty = true
            ev:SetScript("OnUpdate", flushLayout) -- fires once next frame, then clears
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

 succeeded in 0ms:
-- Timers: track YOUR finisher durations on the current target via combat log.
-- Slice and Dice (self buff) + Rupture / Expose Armor / Garrote (target debuffs).
-- Uses CLEU for application/refresh so it works pre-2.5 aura APIs reliably.

local ADDON, NS = ...
local Timers = NS:RegisterModule("timers", {})

-- spellID -> { label, base, perCP (optional) }  durations are *max* (5cp) approximations;
-- we read the real remaining time from auras when possible, CLEU is the fallback.
local TRACK = {
    -- Slice and Dice ranks share name; track by name (self buff)
    snd = { name = "Slice and Dice", isSelf = true,  color = "good" },
    rup = { name = "Rupture",        isSelf = false, color = "bad"  },
    exp = { name = "Expose Armor",   isSelf = false, color = "warn" },
    gar = { name = "Garrote",        isSelf = false, color = "bad"  },
}

local BAR_W, BAR_H = 200, 14
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

-- Can the player actually refresh this aura right now? Used to gate the green
-- "refresh-now" cue so it never implies an action you lack resources for.
-- Finisher cost is 25 energy; SnD needs only energy, Rupture/Expose also need CP.
local function HasRefreshResources(key)
    local e = UnitPower("player", ENERGY)
    if key == "snd" then
        return e >= 25 -- self-buff, only needs energy
    elseif key == "rup" or key == "exp" then
        -- finishers: need a live attackable target AND energy AND a combo point
        if not UnitExists("target") or UnitIsDead("target")
            or not UnitCanAttack("player", "target") then
            return false
        end
        return e >= 25 and (GetComboPoints("player", "target") or 0) >= 1
    end
    return false -- Garrote: stealth-only, can't refresh in combat -> never cue green
end

local function GetAura(unit, name, byPlayer)
    -- WoW aura filters are SPACE-separated tokens, not pipe-separated.
    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
    for i = 1, 40 do
        local n, dur, exp
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if not d then break end
            n, dur, exp = d.name, d.duration, d.expirationTime
        else
            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
            -- pack the returns (no bare `_` throwaways, which leak a global on 5.1)
            local a = { UnitAura(unit, i, filter) }
            n, dur, exp = a[1], a[5], a[6]
            if not n then break end
        end
        if n == name and exp and exp > 0 then
            return exp, dur   -- absolute expiration time + full duration
        end
    end
    return nil
end

-- where each tracked aura lives
local SOURCE = {
    snd = { unit = "player", byPlayer = false },
    rup = { unit = "target", byPlayer = true  },
    exp = { unit = "target", byPlayer = true  },
    gar = { unit = "target", byPlayer = true  },
}

function Timers:Init()
    if self.bars then return end -- idempotent: never double-init frames/scripts
    local root = NS.modules.hud.root
    self.bars = {}
    self.cache = {} -- key -> { exp = absolute, dur = full }
    local order = { "snd", "rup", "exp", "gar" }
    local y = -(18 + 6 + 22 + 10) -- below the CP pips
    for idx, key in ipairs(order) do
        local b = CreateFrame("StatusBar", nil, root)
        b:SetSize(BAR_W, BAR_H)
        b:SetPoint("TOP", root, "TOP", 0, y - (idx - 1) * (BAR_H + 3))
        b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local c = NS.color[TRACK[key].color]
        b:SetStatusBarColor(c[1], c[2], c[3])
        b.baseColor = c
        b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
        b.bg:SetColorTexture(0, 0, 0, 0.6)
        -- "refresh now" marker: when the fill shrinks past this line you're in the
        -- window to refresh without significant clipping (TBC has no pandemic).
        b.marker = b:CreateTexture(nil, "OVERLAY")
        b.marker:SetColorTexture(1, 1, 1, 0.9)
        b.marker:SetSize(2, BAR_H)
        b.marker:Hide()
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.label:SetPoint("LEFT", 4, 0); b.label:SetText(TRACK[key].name)
        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.time:SetPoint("RIGHT", -4, 0)
        b:Hide()
        -- reset transient render state on hide (set ONCE, not per tick)
        b:SetScript("OnHide", function(s) s.inZone = nil; s.greenState = nil; s.markerDur = nil end)
        self.bars[key] = b
    end

    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
    local scan = CreateFrame("Frame")
    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
    scan:SetScript("OnEvent", function() self:Scan() end)
    self.scan = scan

    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
    -- Use a PRIVATE frame, not hud.root, so a future module setting an OnUpdate on
    -- root can't silently clobber the render loop (shared-state hazard).
    self.elapsed = 0
    self.renderFrame = CreateFrame("Frame", nil, root)
    self.renderFrame:SetScript("OnUpdate", function(_, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed < 0.05 then return end
        self.elapsed = 0
        self:Render()
    end)
    self:Scan()
end

-- Refresh the aura cache from the game (only on aura/target change events).
function Timers:Scan()
    if not NS.IsRogue or not self.cache then return end
    local hasTarget = UnitExists("target") and not UnitIsDead("target")
    for key, src in pairs(SOURCE) do
        local exp, dur
        if src.unit == "player" or hasTarget then
            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
        end
        self.cache[key] = exp and { exp = exp, dur = dur } or nil
    end
end

-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
function Timers:Render()
    if not NS.IsRogue then return end
    NS.modules.hud:UpdateCP()
    NS.modules.hud:UpdatePower()
    NS.modules.hud:UpdateEnergyTick()

    local now = GetTime()
    for key, b in pairs(self.bars) do
        local c = self.cache[key]
        local rem = c and (c.exp - now) or 0
        if not c or rem <= 0 then
            self.cache[key] = nil
            if b:IsShown() then
                b:Hide(); b.marker:Hide()
                b.inZone = nil; b.greenState = nil; b.markerDur = nil
            end
        else
            local warnAt = (key == "snd" and NS.db.sndWarn)
                or (key == "rup" and NS.db.ruptureWarn) or 2
            local dur = (c.dur and c.dur > 0) and c.dur or rem
            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
            b:SetValue(rem)
            b.time:SetText(string.format("%.1f", rem))

            -- refresh-now marker: the fill's right edge crosses it at rem==warnAt.
            -- Reposition only when the duration changes (per new cast), not per frame.
            if NS.db.refreshZone then
                if b.markerDur ~= dur then
                    b.markerDur = dur
                    local frac = warnAt / dur
                    if frac > 1 then frac = 1 elseif frac < 0 then frac = 0 end
                    b.marker:ClearAllPoints()
                    b.marker:SetPoint("CENTER", b, "LEFT", frac * BAR_W, 0) -- centered on edge
                end
                if not b.marker:IsShown() then b.marker:Show() end
            elseif b.marker:IsShown() then
                b.marker:Hide()
            end

            -- color state machine: only call Set*Color on a transition (avoids ~20
            -- redundant C calls/sec/bar). label flash + entry sound gated by inZone;
            -- fill-green gated separately so /cut zone toggles live and restores base.
            local want = rem <= warnAt
            if want ~= b.inZone then
                b.inZone = want
                b.label:SetTextColor(want and NS.color.bad[1] or 1,
                                     want and NS.color.bad[2] or 1,
                                     want and NS.color.bad[3] or 1)
                if want and NS.db.sound then
                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
                end
            end
            local green = want and NS.db.refreshZone
            if green and NS.db.smartRefresh then green = HasRefreshResources(key) end
            if green ~= b.greenState then
                b.greenState = green
                b:SetStatusBarColor(unpack(green and NS.color.good or b.baseColor))
            end

            if not b:IsShown() then b:Show() end
        end
    end
end

function Timers:Refresh() if self.cache then self:Scan() end end

exec
/bin/zsh -lc "sed -n '1,260p' core.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Cutthroat: Rogue helper for TBC Classic (2.5.x)
-- Pure read/display. No spell input automation (Warden-safe).

local ADDON, NS = ...
NS.name = "Cutthroat"
NS.modules = {}

-- ---- Saved variable defaults ----
local defaults = {
    locked = false,
    scale = 1.0,
    point = { "CENTER", nil, "CENTER", 0, -180 },
    sndWarn = 3,        -- seconds left on Slice and Dice before warning
    ruptureWarn = 2,    -- seconds left on Rupture before warning
    kickAlert = true,   -- flash when target casts an interruptible spell + Kick ready
    poisonCheck = true, -- warn when a weapon is missing poison out of combat
    openerHint = true,  -- show "Ambush / Garrote" hint when stealthed w/ target
    sound = true,
    energyTicks = true, -- show 20-energy tick marks
    tickSpark = true,   -- moving spark = progress to next ~2s energy regen tick
    refreshZone = true, -- mark the "refresh now" window near expiry on SnD/DoT bars
    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
    cpFinishGlow = true,-- pulse the combo pips at max CP (don't overcap -> finish)
}

-- ---- Class gate ----
local _, playerClass = UnitClass("player")

-- ---- Module registration ----
function NS:RegisterModule(name, mod)
    self.modules[name] = mod
    return mod
end

local function CallAll(method, ...)
    for _, mod in pairs(NS.modules) do
        if mod[method] then mod[method](mod, ...) end
    end
end
NS.CallAll = CallAll

-- ---- Event hub ----
local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CutthroatDB = CutthroatDB or {}
        for k, v in pairs(defaults) do
            if CutthroatDB[k] == nil then
                CutthroatDB[k] = (type(v) == "table") and CopyTable(v) or v
            end
        end
        -- Sanitize the values the HUD trusts, in case the save is corrupted. NOTE:
        -- point[2] is intentionally nil (relativeTo=UIParent), so validate fields by
        -- index — never use #point (a nil hole makes the length operator unreliable).
        local p = CutthroatDB.point
        if type(p) ~= "table" or type(p[1]) ~= "string" or type(p[3]) ~= "string"
            or type(p[4]) ~= "number" or type(p[5]) ~= "number" then
            CutthroatDB.point = CopyTable(defaults.point)
        end
        if type(CutthroatDB.scale) ~= "number" or CutthroatDB.scale < 0.4 or CutthroatDB.scale > 3 then
            CutthroatDB.scale = defaults.scale
        end
        NS.db = CutthroatDB
    elseif event == "PLAYER_LOGIN" then
        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
        -- works for everyone, then the rogue-only visual modules — hud BEFORE
        -- timers/cooldowns/alerts, which all anchor to hud.root.
        local function initModule(name)
            local m = NS.modules[name]
            if m and m.Init then m:Init() end
        end
        initModule("config")  -- slash commands work for everyone
        initModule("options") -- graphical settings panel works for everyone
        if playerClass == "ROGUE" then
            initModule("hud")
            initModule("timers")
            initModule("cooldowns")
            initModule("alerts")
            CallAll("Refresh")
        else
            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.")
        end
        -- TBC 2.5.x exposes the global GetAddOnMetadata; C_AddOns is a newer wrapper.
        local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
            or "1.0.0"
        print("|cff00ff96Cutthroat|r v" .. ver .. " loaded. |cffffff00/cut|r for options.")
    end
end)

NS.IsRogue = (playerClass == "ROGUE")

-- shared color helpers
NS.color = {
    energy  = { 1.0, 0.85, 0.20 },
    cp      = { 1.0, 0.20, 0.20 },
    good    = { 0.20, 1.0, 0.40 },
    warn    = { 1.0, 0.55, 0.10 },
    bad     = { 1.0, 0.15, 0.15 },
    dim     = { 0.45, 0.45, 0.45 },
}

exec
/bin/zsh -lc "sed -n '1,240p' alerts.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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
    if self.ev then return end -- idempotent: never double-init frames/events
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

exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '35,180p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba cooldowns.lua | sed -n '68,105p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
    68	    self.rowY = rowY
    69	
    70	    local ev = CreateFrame("Frame")
    71	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    72	    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
    73	    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
    74	    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
    75	    -- unknown event hard-errors and would break load. The two above cover respec.
    76	    -- SPELLS_CHANGED fires aggressively, so coalesce layout rebuilds with a ONE-SHOT
    77	    -- OnUpdate that removes itself after running — no permanent per-frame loop.
    78	    local function flushLayout()
    79	        ev:SetScript("OnUpdate", nil)
    80	        self.layoutDirty = false
    81	        self:RebuildKnown()
    82	        self:Relayout()
    83	    end
    84	    ev:SetScript("OnEvent", function(_, e)
    85	        if e == "SPELL_UPDATE_COOLDOWN" then
    86	            self:UpdateCooldowns()
    87	        elseif not self.layoutDirty then
    88	            self.layoutDirty = true
    89	            ev:SetScript("OnUpdate", flushLayout) -- fires once next frame, then clears
    90	        end
    91	    end)
    92	    self.ev = ev
    93	
    94	    self:RebuildKnown()
    95	    self:Relayout()
    96	end
    97	
    98	-- Cache the set of spells the player actually knows (by localized name).
    99	function CDs:RebuildKnown()
   100	    if not self.known then return end
   101	    wipe(self.known)
   102	    local i = 1
   103	    while true do
   104	        local n = GetSpellName(i, BOOK)
   105	        if not n then break end

 succeeded in 0ms:
    35	    end
    36	    return false -- Garrote: stealth-only, can't refresh in combat -> never cue green
    37	end
    38	
    39	local function GetAura(unit, name, byPlayer)
    40	    -- WoW aura filters are SPACE-separated tokens, not pipe-separated.
    41	    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
    42	    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
    43	    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
    44	    for i = 1, 40 do
    45	        local n, dur, exp
    46	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    47	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    48	            if not d then break end
    49	            n, dur, exp = d.name, d.duration, d.expirationTime
    50	        else
    51	            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
    52	            -- pack the returns (no bare `_` throwaways, which leak a global on 5.1)
    53	            local a = { UnitAura(unit, i, filter) }
    54	            n, dur, exp = a[1], a[5], a[6]
    55	            if not n then break end
    56	        end
    57	        if n == name and exp and exp > 0 then
    58	            return exp, dur   -- absolute expiration time + full duration
    59	        end
    60	    end
    61	    return nil
    62	end
    63	
    64	-- where each tracked aura lives
    65	local SOURCE = {
    66	    snd = { unit = "player", byPlayer = false },
    67	    rup = { unit = "target", byPlayer = true  },
    68	    exp = { unit = "target", byPlayer = true  },
    69	    gar = { unit = "target", byPlayer = true  },
    70	}
    71	
    72	function Timers:Init()
    73	    if self.bars then return end -- idempotent: never double-init frames/scripts
    74	    local root = NS.modules.hud.root
    75	    self.bars = {}
    76	    self.cache = {} -- key -> { exp = absolute, dur = full }
    77	    local order = { "snd", "rup", "exp", "gar" }
    78	    local y = -(18 + 6 + 22 + 10) -- below the CP pips
    79	    for idx, key in ipairs(order) do
    80	        local b = CreateFrame("StatusBar", nil, root)
    81	        b:SetSize(BAR_W, BAR_H)
    82	        b:SetPoint("TOP", root, "TOP", 0, y - (idx - 1) * (BAR_H + 3))
    83	        b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    84	        local c = NS.color[TRACK[key].color]
    85	        b:SetStatusBarColor(c[1], c[2], c[3])
    86	        b.baseColor = c
    87	        b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
    88	        b.bg:SetColorTexture(0, 0, 0, 0.6)
    89	        -- "refresh now" marker: when the fill shrinks past this line you're in the
    90	        -- window to refresh without significant clipping (TBC has no pandemic).
    91	        b.marker = b:CreateTexture(nil, "OVERLAY")
    92	        b.marker:SetColorTexture(1, 1, 1, 0.9)
    93	        b.marker:SetSize(2, BAR_H)
    94	        b.marker:Hide()
    95	        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    96	        b.label:SetPoint("LEFT", 4, 0); b.label:SetText(TRACK[key].name)
    97	        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    98	        b.time:SetPoint("RIGHT", -4, 0)
    99	        b:Hide()
   100	        -- reset transient render state on hide (set ONCE, not per tick)
   101	        b:SetScript("OnHide", function(s) s.inZone = nil; s.greenState = nil; s.markerDur = nil end)
   102	        self.bars[key] = b
   103	    end
   104	
   105	    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
   106	    local scan = CreateFrame("Frame")
   107	    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
   108	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
   109	    scan:SetScript("OnEvent", function() self:Scan() end)
   110	    self.scan = scan
   111	
   112	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
   113	    -- Use a PRIVATE frame, not hud.root, so a future module setting an OnUpdate on
   114	    -- root can't silently clobber the render loop (shared-state hazard).
   115	    self.elapsed = 0
   116	    self.renderFrame = CreateFrame("Frame", nil, root)
   117	    self.renderFrame:SetScript("OnUpdate", function(_, dt)
   118	        self.elapsed = self.elapsed + dt
   119	        if self.elapsed < 0.05 then return end
   120	        self.elapsed = 0
   121	        self:Render()
   122	    end)
   123	    self:Scan()
   124	end
   125	
   126	-- Refresh the aura cache from the game (only on aura/target change events).
   127	function Timers:Scan()
   128	    if not NS.IsRogue or not self.cache then return end
   129	    local hasTarget = UnitExists("target") and not UnitIsDead("target")
   130	    for key, src in pairs(SOURCE) do
   131	        local exp, dur
   132	        if src.unit == "player" or hasTarget then
   133	            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
   134	        end
   135	        self.cache[key] = exp and { exp = exp, dur = dur } or nil
   136	    end
   137	end
   138	
   139	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
   140	function Timers:Render()
   141	    if not NS.IsRogue then return end
   142	    NS.modules.hud:UpdateCP()
   143	    NS.modules.hud:UpdatePower()
   144	    NS.modules.hud:UpdateEnergyTick()
   145	
   146	    local now = GetTime()
   147	    for key, b in pairs(self.bars) do
   148	        local c = self.cache[key]
   149	        local rem = c and (c.exp - now) or 0
   150	        if not c or rem <= 0 then
   151	            self.cache[key] = nil
   152	            if b:IsShown() then
   153	                b:Hide(); b.marker:Hide()
   154	                b.inZone = nil; b.greenState = nil; b.markerDur = nil
   155	            end
   156	        else
   157	            local warnAt = (key == "snd" and NS.db.sndWarn)
   158	                or (key == "rup" and NS.db.ruptureWarn) or 2
   159	            local dur = (c.dur and c.dur > 0) and c.dur or rem
   160	            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
   161	            b:SetValue(rem)
   162	            b.time:SetText(string.format("%.1f", rem))
   163	
   164	            -- refresh-now marker: the fill's right edge crosses it at rem==warnAt.
   165	            -- Reposition only when the duration changes (per new cast), not per frame.
   166	            if NS.db.refreshZone then
   167	                if b.markerDur ~= dur then
   168	                    b.markerDur = dur
   169	                    local frac = warnAt / dur
   170	                    if frac > 1 then frac = 1 elseif frac < 0 then frac = 0 end
   171	                    b.marker:ClearAllPoints()
   172	                    b.marker:SetPoint("CENTER", b, "LEFT", frac * BAR_W, 0) -- centered on edge
   173	                end
   174	                if not b.marker:IsShown() then b.marker:Show() end
   175	            elseif b.marker:IsShown() then
   176	                b.marker:Hide()
   177	            end
   178	
   179	            -- color state machine: only call Set*Color on a transition (avoids ~20
   180	            -- redundant C calls/sec/bar). label flash + entry sound gated by inZone;

exec
/bin/zsh -lc "nl -ba hud.lua | sed -n '72,165p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
    72	    self.energyMax = 100
    73	    self.lastTick = 0
    74	    self.tickInterval = 2.0 -- self-calibrated from observed tick gaps
    75	
    76	    -- ---- Combo point pips ----
    77	    self.pips = {}
    78	    local totalW = MAX_CP * CP_SIZE + (MAX_CP - 1) * CP_GAP
    79	    local startX = (WIDTH - totalW) / 2
    80	    for i = 1, MAX_CP do
    81	        local pip = root:CreateTexture(nil, "ARTWORK")
    82	        pip:SetSize(CP_SIZE, CP_SIZE)
    83	        pip:SetPoint("TOPLEFT", root, "TOPLEFT", startX + (i - 1) * (CP_SIZE + CP_GAP), -(HEIGHT + 6))
    84	        pip:SetTexture("Interface\\ComboFrame\\ComboPoint")
    85	        pip:SetTexCoord(0, 0.375, 0, 1) -- the lit gem
    86	        pip:SetVertexColor(unpack(NS.color.cp))
    87	        pip:SetAlpha(0.15)
    88	        self.pips[i] = pip
    89	    end
    90	
    91	    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
    92	    -- spend them instead of overcapping (building past 5 CP is wasted generation).
    93	    self.cpGlow = root:CreateTexture(nil, "BACKGROUND")
    94	    self.cpGlow:SetPoint("TOPLEFT", self.pips[1], "TOPLEFT", -3, 3)
    95	    self.cpGlow:SetPoint("BOTTOMRIGHT", self.pips[MAX_CP], "BOTTOMRIGHT", 3, -3)
    96	    self.cpGlow:SetColorTexture(1, 0.82, 0, 1)
    97	    self.cpGlow:SetBlendMode("ADD") -- additive => soft glow, not a harsh solid box
    98	    self.cpGlow:Hide()
    99	
   100	    -- Event-driven power updates, all unit-filtered to "player" so other units'
   101	    -- power changes never wake this handler. Combo points have no reliable
   102	    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
   103	    -- and registering a wrong event name errors) — they're polled in timers:Tick.
   104	    local ev = CreateFrame("Frame")
   105	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
   106	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
   107	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
   108	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
   109	    self.ev = ev
   110	end
   111	
   112	function HUD:UpdatePower()
   113	    if not self.energy then return end
   114	    local e = UnitPower("player", ENERGY)
   115	    local m = UnitPowerMax("player", ENERGY)
   116	    m = (m and m > 0) and m or 100
   117	    -- This is polled ~20x/s; only make the C-side bar calls when values change.
   118	    if m ~= self.energyMax then
   119	        self.energyMax = m
   120	        self.energy:SetMinMaxValues(0, m)
   121	    end
   122	    if e ~= self.shownEnergy then
   123	        self.shownEnergy = e
   124	        self.energy:SetValue(e)
   125	        self.energy.text:SetText(e)
   126	    end
   127	
   128	    if self.lastEnergy == nil then self.lastEnergy = e; return end
   129	    -- A regen tick lands as a sizable positive delta. Small proc gains (Combat
   130	    -- Potency etc.) are ignored with the >=10 filter so they don't yank the spark.
   131	    -- We MEASURE the real tick cadence from gap to gap (clamped) instead of assuming
   132	    -- 2.0s — GLM and Codex disagreed on whether Adrenaline Rush changes the tick
   133	    -- interval or the per-tick amount, so measuring sidesteps the unresolved question.
   134	    if e > self.lastEnergy and (e - self.lastEnergy) >= 10 then
   135	        local now = GetTime()
   136	        local gap = now - (self.lastTick or now)
   137	        if gap >= 0.8 and gap <= 2.2 then self.tickInterval = gap end
   138	        self.lastTick = now
   139	    end
   140	    self.lastEnergy = e
   141	end
   142	
   143	-- Move the regen-tick spark; called every render frame from timers:Render.
   144	function HUD:UpdateEnergyTick()
   145	    local s = self.energy and self.energy.spark
   146	    if not s then return end
   147	    -- hide when disabled or at full energy (no tick to wait for)
   148	    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
   149	        s:Hide(); return
   150	    end
   151	    local interval = self.tickInterval or 2.0
   152	    local frac = (GetTime() - (self.lastTick or 0)) / interval
   153	    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
   154	    local w = self.energy:GetWidth()
   155	    local sw = s:GetWidth() or 2
   156	    local x = frac * w
   157	    if x > w - sw then x = w - sw end  -- keep the full 2px spark inside the bar
   158	    if x < 0 then x = 0 end
   159	    s:ClearAllPoints()
   160	    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
   161	    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
   162	    s:Show()
   163	end
   164	
   165	function HUD:UpdateCP()

exec
/bin/zsh -lc "nl -ba core.lua | sed -n '39,91p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
    39	end
    40	NS.CallAll = CallAll
    41	
    42	-- ---- Event hub ----
    43	local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
    44	f:RegisterEvent("ADDON_LOADED")
    45	f:RegisterEvent("PLAYER_LOGIN")
    46	f:SetScript("OnEvent", function(self, event, arg1)
    47	    if event == "ADDON_LOADED" and arg1 == ADDON then
    48	        CutthroatDB = CutthroatDB or {}
    49	        for k, v in pairs(defaults) do
    50	            if CutthroatDB[k] == nil then
    51	                CutthroatDB[k] = (type(v) == "table") and CopyTable(v) or v
    52	            end
    53	        end
    54	        -- Sanitize the values the HUD trusts, in case the save is corrupted. NOTE:
    55	        -- point[2] is intentionally nil (relativeTo=UIParent), so validate fields by
    56	        -- index — never use #point (a nil hole makes the length operator unreliable).
    57	        local p = CutthroatDB.point
    58	        if type(p) ~= "table" or type(p[1]) ~= "string" or type(p[3]) ~= "string"
    59	            or type(p[4]) ~= "number" or type(p[5]) ~= "number" then
    60	            CutthroatDB.point = CopyTable(defaults.point)
    61	        end
    62	        if type(CutthroatDB.scale) ~= "number" or CutthroatDB.scale < 0.4 or CutthroatDB.scale > 3 then
    63	            CutthroatDB.scale = defaults.scale
    64	        end
    65	        NS.db = CutthroatDB
    66	    elseif event == "PLAYER_LOGIN" then
    67	        -- Deterministic init order (pairs() is unordered): config FIRST so /cut
    68	        -- works for everyone, then the rogue-only visual modules — hud BEFORE
    69	        -- timers/cooldowns/alerts, which all anchor to hud.root.
    70	        local function initModule(name)
    71	            local m = NS.modules[name]
    72	            if m and m.Init then m:Init() end
    73	        end
    74	        initModule("config")  -- slash commands work for everyone
    75	        initModule("options") -- graphical settings panel works for everyone
    76	        if playerClass == "ROGUE" then
    77	            initModule("hud")
    78	            initModule("timers")
    79	            initModule("cooldowns")
    80	            initModule("alerts")
    81	            CallAll("Refresh")
    82	        else
    83	            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.")
    84	        end
    85	        -- TBC 2.5.x exposes the global GetAddOnMetadata; C_AddOns is a newer wrapper.
    86	        local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
    87	            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
    88	            or "1.0.0"
    89	        print("|cff00ff96Cutthroat|r v" .. ver .. " loaded. |cffffff00/cut|r for options.")
    90	    end
    91	end)

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. **Aura filter correctness**
   Module: [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:39)

   Setup: make the `UnitAura(unit, i, filter)` mock filter-aware and record/branch on `filter`. Put `Slice and Dice` only behind `HELPFUL`; put `Rupture` only behind `HARMFUL PLAYER`; optionally make `HARMFUL|PLAYER` or `HELPFUL PLAYER` return nil.

   Assertion: `Timers:Scan()` populates `cache.snd` only via `HELPFUL`, and `cache.rup` only via `HARMFUL PLAYER`. A wrong pipe-separated filter or wrong helpful/harmful choice should fail.

   Why top: current tests show bars, but the mock ignores the filter argument, so the exact past bug class can regress while tests stay green.

2. **Real-duration scaling + refresh marker math**
   Module: [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:159)

   Setup: enhance `Wm.SetMinMaxValues`, `Wm.SetValue`, and `Wm.SetPoint` to record args. Seed `NS.modules.timers.cache.rup = { exp = GetTime() + 4, dur = 16 }`, render once, then replace with `{ exp = GetTime() + 3, dur = 8 }` and render again. Keep `NS.db.ruptureWarn = 2`, `refreshZone = true`.

   Assertion: bar max becomes `16`, then `8`, proving no stale `maxSeen` behavior. Marker point should be `CENTER`, bar, `LEFT`, `2 / 8 * 200 = 50`, `0` after the second render. Also assert marker moves when `dur` changes.

   Why top: this catches two silent visual lies: old long-duration scaling surviving a shorter refresh, and inverted/off-by-side marker math. Both are implementable headlessly by recording frame method arguments.

3. **Self-calibrating energy tick interval**
   Module: [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:128)

   Setup: start below cap, call `HUD:UpdatePower()` at energy `20`, advance `T` manually, then simulate regen-sized gains: `40` at `T+1.0` or `T+1.1`, then `60` at another matching interval. Also include a small gain like `+5` between ticks.

   Assertion: `HUD.tickInterval` updates to the observed valid gap, ignores the `+5` proc-style gain, and `HUD.lastTick` lands on the real regen-sized gain time. Optionally record spark `SetPoint` x after half an interval to prove it uses the calibrated interval.

   Why top: the existing spark test only proves “hide at cap.” It does not prove the core calibration behavior, so a refactor could silently go back to fixed/wrong timing.

Near miss: the cooldown one-shot `OnUpdate` cleanup in [cooldowns.lua](/Users/creative/WoWAddons/Cutthroat/cooldowns.lua:78) is very easy to test: fire `SPELLS_CHANGED`, assert `CDs.ev:GetScript("OnUpdate")` exists and `layoutDirty == true`, tick once, assert script is nil and `layoutDirty == false`. I’d add it after the three above.
tokens used
71,780
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. **Aura filter correctness**
   Module: [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:39)

   Setup: make the `UnitAura(unit, i, filter)` mock filter-aware and record/branch on `filter`. Put `Slice and Dice` only behind `HELPFUL`; put `Rupture` only behind `HARMFUL PLAYER`; optionally make `HARMFUL|PLAYER` or `HELPFUL PLAYER` return nil.

   Assertion: `Timers:Scan()` populates `cache.snd` only via `HELPFUL`, and `cache.rup` only via `HARMFUL PLAYER`. A wrong pipe-separated filter or wrong helpful/harmful choice should fail.

   Why top: current tests show bars, but the mock ignores the filter argument, so the exact past bug class can regress while tests stay green.

2. **Real-duration scaling + refresh marker math**
   Module: [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:159)

   Setup: enhance `Wm.SetMinMaxValues`, `Wm.SetValue`, and `Wm.SetPoint` to record args. Seed `NS.modules.timers.cache.rup = { exp = GetTime() + 4, dur = 16 }`, render once, then replace with `{ exp = GetTime() + 3, dur = 8 }` and render again. Keep `NS.db.ruptureWarn = 2`, `refreshZone = true`.

   Assertion: bar max becomes `16`, then `8`, proving no stale `maxSeen` behavior. Marker point should be `CENTER`, bar, `LEFT`, `2 / 8 * 200 = 50`, `0` after the second render. Also assert marker moves when `dur` changes.

   Why top: this catches two silent visual lies: old long-duration scaling surviving a shorter refresh, and inverted/off-by-side marker math. Both are implementable headlessly by recording frame method arguments.

3. **Self-calibrating energy tick interval**
   Module: [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:128)

   Setup: start below cap, call `HUD:UpdatePower()` at energy `20`, advance `T` manually, then simulate regen-sized gains: `40` at `T+1.0` or `T+1.1`, then `60` at another matching interval. Also include a small gain like `+5` between ticks.

   Assertion: `HUD.tickInterval` updates to the observed valid gap, ignores the `+5` proc-style gain, and `HUD.lastTick` lands on the real regen-sized gain time. Optionally record spark `SetPoint` x after half an interval to prove it uses the calibrated interval.

   Why top: the existing spark test only proves “hide at cap.” It does not prove the core calibration behavior, so a refactor could silently go back to fixed/wrong timing.

Near miss: the cooldown one-shot `OnUpdate` cleanup in [cooldowns.lua](/Users/creative/WoWAddons/Cutthroat/cooldowns.lua:78) is very easy to test: fire `SPELLS_CHANGED`, assert `CDs.ev:GetScript("OnUpdate")` exists and `layoutDirty == true`, tick once, assert script is nil and `layoutDirty == false`. I’d add it after the three above.
