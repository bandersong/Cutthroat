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
session id: 019f09bc-c449-7052-819e-df3c0c5c388e
--------
user
Adversarially review the headless test harness test/run.lua for this Cutthroat WoW TBC Classic 2.5.x Lua addon. It stubs the WoW API, loads all modules, fires events, reports 52 passed/0 failed. KEY QUESTION: real confidence or FALSE confidence? Specifically: (1) what in-client bugs would this still MISS (don't over-claim 'tested')? (2) trivial/tautological assertions that test the mock not the addon? (3) Lua 5.1 (WoW) vs the test runtime differences that make green-here != works-in-WoW (# on tables with nil holes, table.unpack vs unpack, integer/float, goto, string.* , pairs order)? (4) does the no-op __index metatable (returns noop for any unknown method) MASK bugs by swallowing calls? (5) is event/OnUpdate dispatch faithful? (6) what makes a passing run misleading? Read test/run.lua and the addon files. Give concrete improvements. Numbered, most important first. Do NOT edit.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll treat this as a review, not an edit. I’m going to read the harness and addon modules first, then I’ll rank the false-confidence risks against actual code paths rather than generic WoW-test advice.
exec
/bin/zsh -lc 'pwd && rg --files' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

exec
/bin/zsh -lc 'git status --short' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
?? reviews/codex/iter10.md
?? reviews/glm/iter10.md
?? test/

codex
`rg` isn’t installed here, so I’m falling back to `find`/`sed`. The worktree already has untracked review/test files; I’ll only read, not touch them.
exec
/bin/zsh -lc 'find . -maxdepth 4 -type f | sort' in /Users/creative/WoWAddons/Cutthroat
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
./.git/objects/00/e52029c35f5c1d1e29ebd2c78ab760228cb1ec
./.git/objects/01/cd97421a9363ae3e8c2627177f88b1115bae70
./.git/objects/03/291f1f6bd81de56f27d1083c28aeefb19f7824
./.git/objects/04/2c23097dd44c7afe44d71436fc0b855ee71116
./.git/objects/04/570359d6d68a4f4f47da3155eaacacd7ea694e
./.git/objects/0a/d5393e8d813606951bb098563db8697e9fc190
./.git/objects/0b/13fb2ab995ae8c1511f196be008a6d6a1e78c8
./.git/objects/0b/a18a3b1b75b983360b4982be8b37dea8bf4471
./.git/objects/0d/58faaaacfc4872e22e2d5f4c12b74e5dd2e861
./.git/objects/0f/172fa1c105fb1e32641dcb1d2ce47705414c13
./.git/objects/12/2ae31a30af8634a58f7f96cf201cf4f2fc234a
./.git/objects/12/4fe40fac24f9e2d5e1ca4e2259c1236cbf31cc
./.git/objects/13/db69404c835708c42ff445a3b25479e70d4269
./.git/objects/16/70ca2410b417f00691eb43718f1c0c6a009274
./.git/objects/19/c800135e085edb11602fdcb78b168692d88ebd
./.git/objects/1a/25b59d8b0e7ab0e7f1f2eeb3c854f106e78146
./.git/objects/1a/eb01b72c31c1ac03bdd0110220b88f6ae36270
./.git/objects/1b/ee7e5e7c2dff275a5983757676af9c4c2651a0
./.git/objects/1c/0f47651854d7ab7696e51b2395a9f3c33866f2
./.git/objects/22/5bef7c52710f85c00b2f72e5e75f17b81ccfe5
./.git/objects/22/6e9d830bed7434e78aa9ae6062061cc995adc5
./.git/objects/23/4e835e3fc000c12189efba7332d3ce17181ef0
./.git/objects/23/62ac216d85699908087b09ea1888ed13b54637
./.git/objects/23/d69a7d407e4a47e7689fb1c5ec342df2f2c0d6
./.git/objects/25/687e392c34c385462bf291cbbfd24553b1df81
./.git/objects/26/d3d6bea3321bf010fe3b4cd2f127f26d59f4e9
./.git/objects/27/3656632af9fa5ea0ddfe993c55cd09b1ae8cd6
./.git/objects/27/49554a30ad68f3bc7ef3a3db99b07785304489
./.git/objects/28/9d7ca347783930c7ee6db653e86d7183bb6f14
./.git/objects/29/79ff10840526870ad29b2478739a7d825c101d
./.git/objects/2b/3af80149dd87a263e9159964ac9eac4061948c
./.git/objects/2b/76b9598986f3f92acee2fa63468d08d89e85dd
./.git/objects/2e/c55b5aa96f0fee982d4270a24675260a57eb35
./.git/objects/32/ad4657ba7101df3b718070bd9ea03dc9146657
./.git/objects/33/f950a5453f6dc4927c0ade6d43abdcbd32fac4
./.git/objects/35/dae43dff21ba420558548e2c6f2e580a057e6d
./.git/objects/3a/1cec5903a84942c7d9fa98aec033c35f7f40d1
./.git/objects/3e/032cebd0d348624a72a40c087926ece3f03b88
./.git/objects/3e/bc2a792791e38ee5b56dacc87278919311c8ca
./.git/objects/41/3361134552ad0c38facc9a88fa10326ca43e45
./.git/objects/41/3478d76a05852cbe3d8ad8379e8360152d68f6
./.git/objects/42/b68e5c9d0c82dbd95962d0263812088cf6c5dd
./.git/objects/43/660e9381834512ed0d4ed224e8829effcf512d
./.git/objects/46/fd227ad45b20e088f3b7190b4f47c3fbbead95
./.git/objects/49/f2cc012d7c68b3d8666a8daf7f0f43abcea6bb
./.git/objects/4b/0c6f513982b2245d47d3aa43a0da232ced4e00
./.git/objects/4c/ac8c7b2d6b353f35aad1ff6ce8f78d5c1b9398
./.git/objects/4e/22b144885cb6b057f2bca600cfc4763a1c17ae
./.git/objects/4e/4d92782ffc5ff87d36eb0a6963e5f748015e07
./.git/objects/50/2ca46ff31e6ef7dc41786e5e944f17f0935d49
./.git/objects/51/a2b254c6b9e3003196baad6b7f907edc449fdb
./.git/objects/52/2cc5d65aa646e90dca367901d71068468afaf9
./.git/objects/53/e7fae2ce70466906e3f2a610dcb7745980ebe8
./.git/objects/54/08f630bb062193fe5a7bd91f85c2ccaefe2e4a
./.git/objects/55/6950d87eb98b8e5d93509619f1da562d8f7727
./.git/objects/56/2d7b9667956c5b223499de4da234c5584f2f9d
./.git/objects/56/90358ceedfa9a00baed87d4f475dac9d98f661
./.git/objects/59/6d672510ac964b509e32ff0d815c2f78d1324e
./.git/objects/5a/23a538407791d0cc5fc1982e0c0bf792174362
./.git/objects/64/18e7459beaa0da2099ccedfc9ea9260e5ae658
./.git/objects/65/6973289706653939d4fdb8ea32331c721d4fc0
./.git/objects/69/903f4acd7fb30e6e5123a47fe3192a95b87934
./.git/objects/6e/0f20633c463e9c7521eb1d420949ab12fc10d0
./.git/objects/6f/5524e84aad09c83b89391303432f7a4d38dbba
./.git/objects/73/1e2a600b4900bef87075178085dad6cca9838e
./.git/objects/73/e33f584393805aaf5e68ae6b3cdc70a740ee93
./.git/objects/75/f7bb862b16371cd1ab01762c12e0cb3c7a2081
./.git/objects/78/1a67e93ac7a0e873318b518697e644ca9c5405
./.git/objects/7b/1e507ad946b843ab8e430c36b148e978a1b54a
./.git/objects/7b/fdc29d3d5fdc0025b5ea7967c1b3e62f78e325
./.git/objects/7f/ca6de07c0f57122c89683810a2cd1e22bd4908
./.git/objects/81/ddb5b1e522dd23e4799bbb2febc148b93a56a0
./.git/objects/85/158823cb678f5a361fc0dab0f1a7387bcf63be
./.git/objects/85/9df278ca46a6431f3182786ce6cdb7eff3c044
./.git/objects/87/0e2f41bb220ae46eead2a14abb49e590516658
./.git/objects/87/b8b264d6c9773e67a5cb8da003694367231080
./.git/objects/88/d9ea6f848dbce2b21b4bfb87c7b3f0096e37f9
./.git/objects/8d/d54d65bd48efe1dbd913077b54bf1a79fab4ea
./.git/objects/93/5a672677cb6edce55b435c2174ee072fa6c806
./.git/objects/94/0b0ac8f17176a429a35cf37bef321003d7606f
./.git/objects/94/c16586f0db1741335caf2df2023bb89bd88d2f
./.git/objects/95/49b836e53057e4dcb104502dd91bb1d9ea758b
./.git/objects/95/e62305531e07bf934e4094cf8ebbd9a7120aa7
./.git/objects/99/110cd6a63504201dc30096dcad3149b2b1a71e
./.git/objects/99/20cb89e0257c9e118f6909f1515a44ffc8eb05
./.git/objects/99/ccaa7302df30dd89ed10ba1bbab2095ce7ad02
./.git/objects/9a/21e059b302880fda760f82f8f2a8fab1d25dc9
./.git/objects/9a/25791bf2f3822ef1930183b0e79b9da04bc402
./.git/objects/9b/971c1aadff075886249ea92e5bebd15476c705
./.git/objects/9c/7405339045833974435ab139c4950e7442cec6
./.git/objects/9f/44e0837f673378141af8090f7dab9cbe357dc2
./.git/objects/9f/8ab60d45a20eab591fd7a7c81b024705808254
./.git/objects/a2/0b9dbbd5a7eafbca80877e92cf8da0cea98e5d
./.git/objects/a4/7555cde84a4c8fd3f96623090afa7c9d74bc0e
./.git/objects/a7/14497318830cbbd34b36c95a8f401026ced431
./.git/objects/a7/5601e8338037780a378ed51b7be65805043706
./.git/objects/a9/f605b1384be7877302b54e697ef14d77e76a50
./.git/objects/ab/9552a65f051bb5fb18a8cc08315aacad464b05
./.git/objects/ac/1ffe9ef6a6e83d485a0e9aeaf3ec21639d7a0e
./.git/objects/ac/2dbba47a718bc4cc5dc63f152a924bfc796a01
./.git/objects/af/633fb4d4b9904cd8a5eb0ee302012fcf75a01d
./.git/objects/b1/cfa4add3dca79caf49d64570ed7b3439e2366b
./.git/objects/b3/110e1b65da279812003fa827debfbe360c0ef1
./.git/objects/b5/5b54906548b772c39799426650dd2b08944a32
./.git/objects/b8/8eeb16a3615eb834deffd71585918ba2111acc
./.git/objects/b8/fff708a6f3a43db539f3d3c2c0efaba0ae2e57
./.git/objects/b9/7bc36f7c49959360bb4564c27962d13dd49aaf
./.git/objects/bb/ac0b34ef85f0fc296fb9045961c27335fab38d
./.git/objects/bc/ba845473bde67e2a6d4937259113171c765307
./.git/objects/be/d5709a318dd954718c970e0791e740e12555e2
./.git/objects/c7/3272696dd1ed0198c9e91364fccf57224936e3
./.git/objects/c7/6ea42cf5cb60799dbce00d7c383a99d00eec82
./.git/objects/ce/0ee450e8328c4490540e6c527dc51c60cd8db9
./.git/objects/ce/aacbb4801944ffe37cec8a927d8905aab898c8
./.git/objects/ce/fbce51abc741f8f398bdebcb0c047ba0612672
./.git/objects/d8/dadcf6e4c2a90630fdfc50bfa5d18f0c99a321
./.git/objects/da/ee571c38a0bce6c4e8adb2767c8375a3e340ba
./.git/objects/dc/6447e7455fd0a4ca3cdd58ce11a3a26b050d72
./.git/objects/dc/a9ac3dcc3b4be72b1fb7e6f94480cf905857c7
./.git/objects/dd/bd7d33ff5a0b3a0fba61ebfc618266faf8b240
./.git/objects/de/c686d5c0cf2f35dab3e04fbb36b2713ff9843c
./.git/objects/e0/6c43f7cbaa11baee2e36cba6fe686865840297
./.git/objects/e0/8daba5a859882a03f932e38ab1ac36dc6da2a7
./.git/objects/e1/1b453ded5f24fd21bf171c94576c598a2d5b01
./.git/objects/e1/8762c66b7947e28fd8ef9fa766416ebf73a04d
./.git/objects/e2/57ec028e187f6b80ad1eb737f3aeaefbcd8d58
./.git/objects/e4/685a9e1669945ebbf63489185c3b07cf852e0e
./.git/objects/e4/b4ec842c70737b6ca6a25695bfca25af58cd15
./.git/objects/e6/2ba76a55a85c7d26156b363431c857e53c77b9
./.git/objects/e7/65f01e756ad43f65153a90435f0079ef33d171
./.git/objects/e8/23f64d5d789b5e04b723877243a2166f665c6f
./.git/objects/e8/a43992b1d0866687274f679969ddac90f49aa0
./.git/objects/e9/a49ab679a74e0479254cf0b35f1b1f4883c60f
./.git/objects/f6/1188752862c3fb55443700f4f80364a7670c20
./.git/objects/f6/edfad854512aeb151e28c0c0d7ac3a97488f6d
./.git/objects/f8/d5bd70a53ddbae22d8dcfec4a311ad0a97f7a0
./.git/objects/f9/abfc7f372ff7448bed2f3f416b8d2347765f50
./.git/objects/f9/be16b58f7e7305eb748d1a57834b013ffce1da
./.git/objects/fa/179301f1627d97ed352e76645ab2c7a8600d0c
./.git/objects/ff/6b1d8c9cbf91bd36356e6e460452e0c35ada2b
./.git/objects/ff/6e6d400e75814283bcef2ba261d8a67459be02
./.git/refs/heads/master
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
./reviews/codex/iter1.md
./reviews/codex/iter10.md
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
/bin/zsh -lc "sed -n '1,260p' test/run.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Headless test harness for Cutthroat. Run from the addon root:  lua test/run.lua
-- Stubs the WoW 2.5.x API, loads every module, fires the real lifecycle + gameplay
-- events, and asserts no Lua errors + basic behavior. This is EXECUTION ground
-- truth — it catches runtime bugs that `luac -p` (syntax only) and code review miss.
--
-- NOTE: runs on stock Lua 5.1+/5.4/5.5. The addon avoids 5.1-only constructs, so
-- this is a faithful enough runtime to shake out nil-indexing, bad API calls, and
-- logic errors. It is NOT a substitute for the in-client smoke test (rendering,
-- real event timing) — see docs/SMOKE_TEST.md.

local ok_count, fail_count = 0, 0
local function check(name, cond, msg)
    if cond then
        ok_count = ok_count + 1
        print("  ok   " .. name)
    else
        fail_count = fail_count + 1
        print("  FAIL " .. name .. (msg and ("  -- " .. tostring(msg)) or ""))
    end
end
-- pcall a fn and surface the actual error message on failure (not just a boolean)
local function try(name, fn, ...)
    local ok, err = pcall(fn, ...)
    check(name, ok, err)
    return ok
end

-- ===================== mock WoW API =====================
unpack = unpack or table.unpack
local allFrames = {}
local T = 1000.0
local state = {
    class = "ROGUE", energy = 100, maxEnergy = 100, combo = 0,
    hasTarget = true, targetDead = false, stealthed = false, combat = false,
    casting = nil, notInt = false, mh = true, oh = true,
    auras = { player = {}, target = {} },
    known = { ["Vanish"] = true, ["Evasion"] = true, ["Sprint"] = true,
              ["Slice and Dice"] = true },
}

local function noop() return nil end
local function newW(kind, name)
    local w = { __k = kind, _name = name, _shown = false, _ev = {}, _sc = {}, _w = 200 }
    setmetatable(w, { __index = function() return noop end })
    function w:SetScript(e, fn) self._sc[e] = fn end
    function w:GetScript(e) return self._sc[e] end
    function w:HookScript(e, fn) self._sc[e] = fn end
    function w:RegisterEvent(e) self._ev[e] = true end
    function w:RegisterUnitEvent(e) self._ev[e] = true end
    function w:UnregisterEvent(e) self._ev[e] = nil end
    function w:Show() self._shown = true end
    function w:Hide() self._shown = false end
    function w:IsShown() return self._shown end
    function w:SetWidth(v) self._w = v end
    function w:GetWidth() return self._w end
    function w:GetName() return self._name end
    function w:GetPoint() return "CENTER", nil, "CENTER", 0, -180 end
    function w:CreateTexture() return newW("Texture") end
    function w:CreateFontString() return newW("FontString") end
    function w:CreateAnimationGroup()
        local ag = newW("AG")
        function ag:CreateAnimation() return newW("Anim") end
        return ag
    end
    return w
end

function CreateFrame(kind, name, parent, tmpl)
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

function GetTime() return T end
function UnitClass() return "Rogue", state.class end
function UnitExists(u) if u == "target" then return state.hasTarget end return true end
function UnitIsDead() return state.targetDead end
function UnitCanAttack() return true end
function UnitPower() return state.energy end
function UnitPowerMax() return state.maxEnergy end
function GetComboPoints() return state.combo end
function IsStealthed() return state.stealthed end
function InCombatLockdown() return state.combat end
function IsUsableSpell() return true, false end
function PlaySound() end
function UnitCastingInfo()
    if state.casting then return state.casting, nil, nil, nil, nil, nil, nil, state.notInt end
end
function UnitChannelInfo() return nil end
function GetWeaponEnchantInfo() return state.mh, 0, 0, state.oh end
function GetInventoryItemLink(unit, slot) return state.ohEquipped and "item:1" or nil end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellTexture() return "Interface\\Icons\\x" end
local spellNames = { [1856] = "Vanish", [5277] = "Evasion", [2983] = "Sprint",
    [13877] = "Blade Flurry", [13750] = "Adrenaline Rush", [14177] = "Cold Blood",
    [14185] = "Preparation", [1766] = "Kick" }
function GetSpellInfo(id) return spellNames[id], nil, "tex" end
function GetSpellName(i)
    local list = {}
    for k in pairs(state.known) do list[#list + 1] = k end
    table.sort(list)
    return list[i]
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

-- ===================== load addon =====================
local NS = {}
local function loadAddon(file)
    local chunk, err = loadfile(file)
    if not chunk then check("load " .. file, false, err); return end
    local ok, e = pcall(chunk, "Cutthroat", NS)
    check("load " .. file, ok, e)
end
print("== load modules ==")
for _, f in ipairs({ "core.lua", "hud.lua", "timers.lua", "cooldowns.lua",
                     "alerts.lua", "options.lua", "config.lua" }) do
    loadAddon(f)
end

-- ===================== lifecycle =====================
print("== lifecycle (rogue) ==")
check("ADDON_LOADED", (pcall(fire, "ADDON_LOADED", "Cutthroat")))
check("db populated", NS.db ~= nil and NS.db.scale == 1.0)
check("PLAYER_LOGIN", (pcall(fire, "PLAYER_LOGIN")))
check("hud inited", NS.modules.hud and NS.modules.hud.root ~= nil)
check("timers inited", NS.modules.timers and NS.modules.timers.bars ~= nil)
check("cooldowns inited", NS.modules.cooldowns and NS.modules.cooldowns.icons ~= nil)
check("options inited", NS.modules.options and NS.modules.options.panel ~= nil)

-- ===================== gameplay =====================
print("== gameplay ==")
state.combo = 5; state.energy = 60
check("power event", (pcall(fire, "UNIT_POWER_FREQUENT", "player")))
state.auras.player[1] = { name = "Slice and Dice", dur = 21, exp = GetTime() + 10 }
state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 4 }
check("aura event", (pcall(fire, "UNIT_AURA", "player")))
local renderOK = true
for _ = 1, 20 do if not pcall(tick, 0.06) then renderOK = false end end
check("render loop (20 frames) no error", renderOK)
check("SnD bar shown while buffed", NS.modules.timers.bars.snd._shown)
check("Rupture bar shown while debuffed", NS.modules.timers.bars.rup._shown)
check("CP overcap glow shown at 5 CP", NS.modules.hud.cpGlow._shown)

print("== kick alert ==")
state.casting = "Fireball"; state.notInt = false
check("cast start event", (pcall(fire, "UNIT_SPELLCAST_START", "target")))
check("kick flash shown vs interruptible cast", NS.modules.alerts.kick._shown)
state.casting = nil
check("cast stop event", (pcall(fire, "UNIT_SPELLCAST_STOP", "target")))

print("== poison check ==")
state.combat = false; state.mh = nil
check("regen-enabled event", (pcall(fire, "PLAYER_REGEN_ENABLED")))
check("poison warning shown when MH unenchanted", NS.modules.alerts.poison._shown)

print("== slash commands ==")
local slash = SlashCmdList["CUTTHROAT"]
check("slash registered", type(slash) == "function")
if slash then
    for _, c in ipairs({ "", "help", "status", "lock", "scale 1.2", "scale 9",
        "kick", "poison", "opener", "sound", "ticks", "spark", "zone", "smart",
        "finish", "snd 4", "rup 3", "config", "options", "reset", "bogus" }) do
        check("/cut " .. c, (pcall(slash, c)))
    end
end

print("== detarget clears glow ==")
state.hasTarget = false; state.combo = 0
pcall(tick, 0.06)
check("CP glow clears on detarget", not NS.modules.hud.cpGlow._shown)

print("== non-rogue load ==")
state.class = "WARRIOR"
local NS2 = {}
local function loadInto(file)
    local chunk = loadfile(file)
    if chunk then return pcall(chunk, "Cutthroat", NS2) end
    return false
end
local warOK = true
for _, f in ipairs({ "core.lua", "hud.lua", "timers.lua", "cooldowns.lua",
                     "alerts.lua", "options.lua", "config.lua" }) do
    if not loadInto(f) then warOK = false end
end
check("non-rogue modules load", warOK)
check("non-rogue ADDON_LOADED+LOGIN", (pcall(function()
    fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN")
end)))
check("non-rogue HUD NOT inited", not (NS2.modules.hud and NS2.modules.hud.root))
check("non-rogue options STILL inited", NS2.modules.options and NS2.modules.options.panel ~= nil)

-- ===================== summary =====================
print(string.format("\n== RESULT: %d passed, %d failed ==", ok_count, fail_count))
os.exit(fail_count == 0 and 0 or 1)

exec
/bin/zsh -lc "sed -n '261,620p' test/run.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
codex
The harness is already showing the central smell: many checks are “no pcall error” and the widget mock returns a no-op for unknown methods. I’m reading the addon code now to tie that to specific missed failures.
exec
/bin/zsh -lc "sed -n '1,260p' core.lua" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "sed -n '1,320p' hud.lua" in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc "sed -n '1,340p' timers.lua" in /Users/creative/WoWAddons/Cutthroat
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
            local dur2, exp2
            n, _, _, _, dur2, exp2 = UnitAura(unit, i, filter)
            if not n then break end
            dur, exp = dur2, exp2
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
/bin/zsh -lc "sed -n '1,320p' cooldowns.lua" in /Users/creative/WoWAddons/Cutthroat
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

exec
/bin/zsh -lc "sed -n '1,360p' alerts.lua" in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc "sed -n '1,420p' options.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- options.lua: graphical settings panel in Interface > AddOns, so you don't have
-- to memorize the /cut slash toggles. Read-only over the addon's SavedVariables.
local ADDON, NS = ...
local Options = NS:RegisterModule("options", {})

-- boolean settings -> checkbox label (order = top-to-bottom in the panel)
local TOGGLES = {
    { "locked",       "Lock HUD position" },
    { "kickAlert",    "Kick interrupt reminder" },
    { "poisonCheck",  "Poison missing warning" },
    { "openerHint",   "Stealth opener hint" },
    { "sound",        "Alert sounds" },
    { "energyTicks",  "Energy 20-mark lines (reload to apply)" },
    { "tickSpark",    "Energy regen-tick spark" },
    { "refreshZone",  "Refresh-now marker on bars" },
    { "smartRefresh", "Green only when CP/energy ready" },
    { "cpFinishGlow", "Max-CP overcap glow" },
}

function Options:Init()
    if self.panel then return end   -- idempotent
    if not NS.db then return end    -- SavedVariables must be loaded first
    local panel = CreateFrame("Frame", "CutthroatOptions", UIParent)
    panel.name = "Cutthroat"
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Cutthroat |cff00ff96Rogue|r")
    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetText("Ban-safe HUD + alerts. Changes apply instantly.")

    self.checks = {}
    local y = -64
    for _, t in ipairs(TOGGLES) do
        local key, label = t[1], t[2]
        local cb = CreateFrame("CheckButton", "CutthroatOpt_" .. key, panel, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, y)
        local txt = _G[cb:GetName() .. "Text"]
        if txt then txt:SetText(label) end
        cb:SetScript("OnClick", function(b)
            NS.db[key] = b:GetChecked() and true or false
            NS.CallAll("Refresh")
        end)
        self.checks[key] = cb
        y = y - 28
    end

    -- scale slider (uses the legacy OptionsSliderTemplate, present in 2.5.x)
    local s = CreateFrame("Slider", "CutthroatOptScale", panel, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, y - 20)
    s:SetMinMaxValues(0.4, 3.0)
    s:SetValueStep(0.05)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:SetWidth(220)
    local sn = s:GetName()
    if _G[sn .. "Low"] then _G[sn .. "Low"]:SetText("0.4") end
    if _G[sn .. "High"] then _G[sn .. "High"]:SetText("3.0") end
    if _G[sn .. "Text"] then _G[sn .. "Text"]:SetText("Scale") end -- title before first drag
    s:SetScript("OnValueChanged", function(sl, v)
        v = math.floor(v * 20 + 0.5) / 20 -- snap to 0.05
        if _G[sl:GetName() .. "Text"] then
            _G[sl:GetName() .. "Text"]:SetText(string.format("Scale: %.2f", v))
        end
        if NS.db.scale ~= v then
            NS.db.scale = v
            -- apply live + cheap (only the HUD scales) instead of a full CallAll per drag step
            local hud = NS.modules.hud
            if hud and hud.root then hud.root:SetScale(v) end
        end
    end)
    self.scale = s

    -- legacy Interface Options "refresh" hook fires when the panel is shown
    panel.refresh = function() self:Load() end

    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(cat)
        self.category = cat
    end
    self:Load()
end

-- mirror the saved values into the widgets
function Options:Load()
    if not self.checks or not NS.db then return end
    for key, cb in pairs(self.checks) do
        cb:SetChecked(NS.db[key] and true or false)
    end
    if self.scale then self.scale:SetValue(NS.db.scale or 1.0) end
end

function Options:Refresh() self:Load() end

-- open the panel (called by /cut config)
function Options:Open()
    if not self.panel then return end
    if InterfaceOptionsFrame_OpenToCategory then
        -- Blizzard bug: first call sometimes lands on the wrong page; call twice
        InterfaceOptionsFrame_OpenToCategory(self.panel)
        InterfaceOptionsFrame_OpenToCategory(self.panel)
    elseif Settings and Settings.OpenToCategory and self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end

exec
/bin/zsh -lc "sed -n '1,420p' config.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
-- Config: /cut slash command. Minimal, no external libs.
local ADDON, NS = ...
local Config = NS:RegisterModule("config", {})

local function on(v) return v and "|cff20ff40on|r" or "|cffff4040off|r" end

local function Print(msg) print("|cff00ff96Cutthroat|r: " .. msg) end

local function Help()
    Print("commands:")
    print("  |cffffff00/cut lock|r        toggle move/lock HUD")
    print("  |cffffff00/cut scale N|r      set scale (e.g. 0.9)")
    print("  |cffffff00/cut kick|r         toggle Kick reminder")
    print("  |cffffff00/cut poison|r       toggle poison check")
    print("  |cffffff00/cut opener|r       toggle stealth opener hint")
    print("  |cffffff00/cut sound|r        toggle alert sounds")
    print("  |cffffff00/cut ticks|r        toggle energy 20-mark lines")
    print("  |cffffff00/cut spark|r        toggle energy regen-tick spark")
    print("  |cffffff00/cut zone|r         toggle refresh-now marker on bars")
    print("  |cffffff00/cut smart|r        green only when CP/energy ready")
    print("  |cffffff00/cut finish|r       toggle max-CP overcap glow")
    print("  |cffffff00/cut snd N|r        SnD warning seconds")
    print("  |cffffff00/cut rup N|r        Rupture warning seconds")
    print("  |cffffff00/cut config|r       open the options panel")
    print("  |cffffff00/cut reset|r        reset position")
    print("  |cffffff00/cut status|r       show settings")
end

function Config:Init()
    SLASH_CUTTHROAT1 = "/cut"
    SLASH_CUTTHROAT2 = "/cutthroat"
    SlashCmdList["CUTTHROAT"] = function(msg)
        local db = NS.db
        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()

        if cmd == "" or cmd == "help" then
            Help()
        elseif cmd == "lock" then
            db.locked = not db.locked
            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
        elseif cmd == "scale" then
            local n = tonumber(arg)
            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
            else Print("scale needs 0.4-3.0") end
        elseif cmd == "kick" then
            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
        elseif cmd == "poison" then
            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
        elseif cmd == "opener" then
            db.openerHint = not db.openerHint; Print("opener hint " .. on(db.openerHint))
        elseif cmd == "sound" then
            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
        elseif cmd == "ticks" then
            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
        elseif cmd == "spark" then
            db.tickSpark = not db.tickSpark; Print("regen-tick spark " .. on(db.tickSpark))
        elseif cmd == "zone" then
            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
        elseif cmd == "smart" then
            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
        elseif cmd == "finish" then
            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
        elseif cmd == "snd" then
            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
        elseif cmd == "rup" then
            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
        elseif cmd == "config" or cmd == "options" then
            if NS.modules.options and NS.modules.options.Open then
                NS.modules.options:Open()
            end
        elseif cmd == "reset" then
            db.point = { "CENTER", nil, "CENTER", 0, -180 }
            Print("position reset (/reload to apply)")
        elseif cmd == "status" then
            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s",
                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound)))
            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
        else
            Help()
        end
        NS.CallAll("Refresh")
    end
end

function Config:Refresh() end

exec
/bin/zsh -lc "sed -n '1,220p' Cutthroat.toc" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
## Interface: 20504
## Title: Cutthroat |cff00ff96Rogue|r
## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
## Author: Cutthroat
## Version: 1.7.0
## SavedVariables: CutthroatDB
## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate

core.lua
hud.lua
timers.lua
cooldowns.lua
alerts.lua
options.lua
config.lua

codex
I’ve got the main shape. Next I’m checking exact line numbers and the local Lua version/runtime so the review can distinguish “real addon issue risk” from “harness artifact.”
exec
/bin/zsh -lc 'lua -v' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
Lua 5.5.0  Copyright (C) 1994-2025 Lua.org, PUC-Rio

exec
/bin/zsh -lc "nl -ba test/run.lua | sed -n '1,240p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Headless test harness for Cutthroat. Run from the addon root:  lua test/run.lua
     2	-- Stubs the WoW 2.5.x API, loads every module, fires the real lifecycle + gameplay
     3	-- events, and asserts no Lua errors + basic behavior. This is EXECUTION ground
     4	-- truth — it catches runtime bugs that `luac -p` (syntax only) and code review miss.
     5	--
     6	-- NOTE: runs on stock Lua 5.1+/5.4/5.5. The addon avoids 5.1-only constructs, so
     7	-- this is a faithful enough runtime to shake out nil-indexing, bad API calls, and
     8	-- logic errors. It is NOT a substitute for the in-client smoke test (rendering,
     9	-- real event timing) — see docs/SMOKE_TEST.md.
    10	
    11	local ok_count, fail_count = 0, 0
    12	local function check(name, cond, msg)
    13	    if cond then
    14	        ok_count = ok_count + 1
    15	        print("  ok   " .. name)
    16	    else
    17	        fail_count = fail_count + 1
    18	        print("  FAIL " .. name .. (msg and ("  -- " .. tostring(msg)) or ""))
    19	    end
    20	end
    21	-- pcall a fn and surface the actual error message on failure (not just a boolean)
    22	local function try(name, fn, ...)
    23	    local ok, err = pcall(fn, ...)
    24	    check(name, ok, err)
    25	    return ok
    26	end
    27	
    28	-- ===================== mock WoW API =====================
    29	unpack = unpack or table.unpack
    30	local allFrames = {}
    31	local T = 1000.0
    32	local state = {
    33	    class = "ROGUE", energy = 100, maxEnergy = 100, combo = 0,
    34	    hasTarget = true, targetDead = false, stealthed = false, combat = false,
    35	    casting = nil, notInt = false, mh = true, oh = true,
    36	    auras = { player = {}, target = {} },
    37	    known = { ["Vanish"] = true, ["Evasion"] = true, ["Sprint"] = true,
    38	              ["Slice and Dice"] = true },
    39	}
    40	
    41	local function noop() return nil end
    42	local function newW(kind, name)
    43	    local w = { __k = kind, _name = name, _shown = false, _ev = {}, _sc = {}, _w = 200 }
    44	    setmetatable(w, { __index = function() return noop end })
    45	    function w:SetScript(e, fn) self._sc[e] = fn end
    46	    function w:GetScript(e) return self._sc[e] end
    47	    function w:HookScript(e, fn) self._sc[e] = fn end
    48	    function w:RegisterEvent(e) self._ev[e] = true end
    49	    function w:RegisterUnitEvent(e) self._ev[e] = true end
    50	    function w:UnregisterEvent(e) self._ev[e] = nil end
    51	    function w:Show() self._shown = true end
    52	    function w:Hide() self._shown = false end
    53	    function w:IsShown() return self._shown end
    54	    function w:SetWidth(v) self._w = v end
    55	    function w:GetWidth() return self._w end
    56	    function w:GetName() return self._name end
    57	    function w:GetPoint() return "CENTER", nil, "CENTER", 0, -180 end
    58	    function w:CreateTexture() return newW("Texture") end
    59	    function w:CreateFontString() return newW("FontString") end
    60	    function w:CreateAnimationGroup()
    61	        local ag = newW("AG")
    62	        function ag:CreateAnimation() return newW("Anim") end
    63	        return ag
    64	    end
    65	    return w
    66	end
    67	
    68	function CreateFrame(kind, name, parent, tmpl)
    69	    local f = newW(kind or "Frame", name)
    70	    if name then _G[name] = f end
    71	    allFrames[#allFrames + 1] = f
    72	    return f
    73	end
    74	UIParent = newW("Frame", "UIParent")
    75	
    76	local function fire(ev, ...)
    77	    for _, f in ipairs(allFrames) do
    78	        if f._ev[ev] and f._sc.OnEvent then f._sc.OnEvent(f, ev, ...) end
    79	    end
    80	end
    81	local function tick(dt)
    82	    T = T + dt
    83	    for _, f in ipairs(allFrames) do
    84	        if f._sc.OnUpdate then f._sc.OnUpdate(f, dt) end
    85	    end
    86	end
    87	
    88	function GetTime() return T end
    89	function UnitClass() return "Rogue", state.class end
    90	function UnitExists(u) if u == "target" then return state.hasTarget end return true end
    91	function UnitIsDead() return state.targetDead end
    92	function UnitCanAttack() return true end
    93	function UnitPower() return state.energy end
    94	function UnitPowerMax() return state.maxEnergy end
    95	function GetComboPoints() return state.combo end
    96	function IsStealthed() return state.stealthed end
    97	function InCombatLockdown() return state.combat end
    98	function IsUsableSpell() return true, false end
    99	function PlaySound() end
   100	function UnitCastingInfo()
   101	    if state.casting then return state.casting, nil, nil, nil, nil, nil, nil, state.notInt end
   102	end
   103	function UnitChannelInfo() return nil end
   104	function GetWeaponEnchantInfo() return state.mh, 0, 0, state.oh end
   105	function GetInventoryItemLink(unit, slot) return state.ohEquipped and "item:1" or nil end
   106	function GetSpellCooldown() return 0, 0, 1 end
   107	function GetSpellTexture() return "Interface\\Icons\\x" end
   108	local spellNames = { [1856] = "Vanish", [5277] = "Evasion", [2983] = "Sprint",
   109	    [13877] = "Blade Flurry", [13750] = "Adrenaline Rush", [14177] = "Cold Blood",
   110	    [14185] = "Preparation", [1766] = "Kick" }
   111	function GetSpellInfo(id) return spellNames[id], nil, "tex" end
   112	function GetSpellName(i)
   113	    local list = {}
   114	    for k in pairs(state.known) do list[#list + 1] = k end
   115	    table.sort(list)
   116	    return list[i]
   117	end
   118	function UnitAura(unit, i)
   119	    local a = state.auras[unit] and state.auras[unit][i]
   120	    if not a then return nil end
   121	    return a.name, nil, nil, nil, a.dur, a.exp
   122	end
   123	C_UnitAuras = nil
   124	BOOKTYPE_SPELL = "spell"
   125	Enum = { PowerType = { Energy = 3 } }
   126	SOUNDKIT = { RAID_WARNING = 8959 }
   127	SlashCmdList = {}
   128	function CopyTable(t)
   129	    local r = {}
   130	    for k, v in pairs(t) do r[k] = (type(v) == "table") and CopyTable(v) or v end
   131	    return r
   132	end
   133	function wipe(t) for k in pairs(t) do t[k] = nil end return t end
   134	C_AddOns = { GetAddOnMetadata = function() return "test" end }
   135	function GetAddOnMetadata() return "test" end
   136	function InterfaceOptions_AddCategory() end
   137	function InterfaceOptionsFrame_OpenToCategory() end
   138	Settings = nil
   139	
   140	-- ===================== load addon =====================
   141	local NS = {}
   142	local function loadAddon(file)
   143	    local chunk, err = loadfile(file)
   144	    if not chunk then check("load " .. file, false, err); return end
   145	    local ok, e = pcall(chunk, "Cutthroat", NS)
   146	    check("load " .. file, ok, e)
   147	end
   148	print("== load modules ==")
   149	for _, f in ipairs({ "core.lua", "hud.lua", "timers.lua", "cooldowns.lua",
   150	                     "alerts.lua", "options.lua", "config.lua" }) do
   151	    loadAddon(f)
   152	end
   153	
   154	-- ===================== lifecycle =====================
   155	print("== lifecycle (rogue) ==")
   156	check("ADDON_LOADED", (pcall(fire, "ADDON_LOADED", "Cutthroat")))
   157	check("db populated", NS.db ~= nil and NS.db.scale == 1.0)
   158	check("PLAYER_LOGIN", (pcall(fire, "PLAYER_LOGIN")))
   159	check("hud inited", NS.modules.hud and NS.modules.hud.root ~= nil)
   160	check("timers inited", NS.modules.timers and NS.modules.timers.bars ~= nil)
   161	check("cooldowns inited", NS.modules.cooldowns and NS.modules.cooldowns.icons ~= nil)
   162	check("options inited", NS.modules.options and NS.modules.options.panel ~= nil)
   163	
   164	-- ===================== gameplay =====================
   165	print("== gameplay ==")
   166	state.combo = 5; state.energy = 60
   167	check("power event", (pcall(fire, "UNIT_POWER_FREQUENT", "player")))
   168	state.auras.player[1] = { name = "Slice and Dice", dur = 21, exp = GetTime() + 10 }
   169	state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 4 }
   170	check("aura event", (pcall(fire, "UNIT_AURA", "player")))
   171	local renderOK = true
   172	for _ = 1, 20 do if not pcall(tick, 0.06) then renderOK = false end end
   173	check("render loop (20 frames) no error", renderOK)
   174	check("SnD bar shown while buffed", NS.modules.timers.bars.snd._shown)
   175	check("Rupture bar shown while debuffed", NS.modules.timers.bars.rup._shown)
   176	check("CP overcap glow shown at 5 CP", NS.modules.hud.cpGlow._shown)
   177	
   178	print("== kick alert ==")
   179	state.casting = "Fireball"; state.notInt = false
   180	check("cast start event", (pcall(fire, "UNIT_SPELLCAST_START", "target")))
   181	check("kick flash shown vs interruptible cast", NS.modules.alerts.kick._shown)
   182	state.casting = nil
   183	check("cast stop event", (pcall(fire, "UNIT_SPELLCAST_STOP", "target")))
   184	
   185	print("== poison check ==")
   186	state.combat = false; state.mh = nil
   187	check("regen-enabled event", (pcall(fire, "PLAYER_REGEN_ENABLED")))
   188	check("poison warning shown when MH unenchanted", NS.modules.alerts.poison._shown)
   189	
   190	print("== slash commands ==")
   191	local slash = SlashCmdList["CUTTHROAT"]
   192	check("slash registered", type(slash) == "function")
   193	if slash then
   194	    for _, c in ipairs({ "", "help", "status", "lock", "scale 1.2", "scale 9",
   195	        "kick", "poison", "opener", "sound", "ticks", "spark", "zone", "smart",
   196	        "finish", "snd 4", "rup 3", "config", "options", "reset", "bogus" }) do
   197	        check("/cut " .. c, (pcall(slash, c)))
   198	    end
   199	end
   200	
   201	print("== detarget clears glow ==")
   202	state.hasTarget = false; state.combo = 0
   203	pcall(tick, 0.06)
   204	check("CP glow clears on detarget", not NS.modules.hud.cpGlow._shown)
   205	
   206	print("== non-rogue load ==")
   207	state.class = "WARRIOR"
   208	local NS2 = {}
   209	local function loadInto(file)
   210	    local chunk = loadfile(file)
   211	    if chunk then return pcall(chunk, "Cutthroat", NS2) end
   212	    return false
   213	end
   214	local warOK = true
   215	for _, f in ipairs({ "core.lua", "hud.lua", "timers.lua", "cooldowns.lua",
   216	                     "alerts.lua", "options.lua", "config.lua" }) do
   217	    if not loadInto(f) then warOK = false end
   218	end
   219	check("non-rogue modules load", warOK)
   220	check("non-rogue ADDON_LOADED+LOGIN", (pcall(function()
   221	    fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN")
   222	end)))
   223	check("non-rogue HUD NOT inited", not (NS2.modules.hud and NS2.modules.hud.root))
   224	check("non-rogue options STILL inited", NS2.modules.options and NS2.modules.options.panel ~= nil)
   225	
   226	-- ===================== summary =====================
   227	print(string.format("\n== RESULT: %d passed, %d failed ==", ok_count, fail_count))
   228	os.exit(fail_count == 0 and 0 or 1)

exec
/bin/zsh -lc "nl -ba core.lua | sed -n '1,150p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba hud.lua | sed -n '1,230p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Cutthroat: Rogue helper for TBC Classic (2.5.x)
     2	-- Pure read/display. No spell input automation (Warden-safe).
     3	
     4	local ADDON, NS = ...
     5	NS.name = "Cutthroat"
     6	NS.modules = {}
     7	
     8	-- ---- Saved variable defaults ----
     9	local defaults = {
    10	    locked = false,
    11	    scale = 1.0,
    12	    point = { "CENTER", nil, "CENTER", 0, -180 },
    13	    sndWarn = 3,        -- seconds left on Slice and Dice before warning
    14	    ruptureWarn = 2,    -- seconds left on Rupture before warning
    15	    kickAlert = true,   -- flash when target casts an interruptible spell + Kick ready
    16	    poisonCheck = true, -- warn when a weapon is missing poison out of combat
    17	    openerHint = true,  -- show "Ambush / Garrote" hint when stealthed w/ target
    18	    sound = true,
    19	    energyTicks = true, -- show 20-energy tick marks
    20	    tickSpark = true,   -- moving spark = progress to next ~2s energy regen tick
    21	    refreshZone = true, -- mark the "refresh now" window near expiry on SnD/DoT bars
    22	    smartRefresh = true,-- only turn the bar green when you have CP/energy to refresh
    23	    cpFinishGlow = true,-- pulse the combo pips at max CP (don't overcap -> finish)
    24	}
    25	
    26	-- ---- Class gate ----
    27	local _, playerClass = UnitClass("player")
    28	
    29	-- ---- Module registration ----
    30	function NS:RegisterModule(name, mod)
    31	    self.modules[name] = mod
    32	    return mod
    33	end
    34	
    35	local function CallAll(method, ...)
    36	    for _, mod in pairs(NS.modules) do
    37	        if mod[method] then mod[method](mod, ...) end
    38	    end
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
    92	
    93	NS.IsRogue = (playerClass == "ROGUE")
    94	
    95	-- shared color helpers
    96	NS.color = {
    97	    energy  = { 1.0, 0.85, 0.20 },
    98	    cp      = { 1.0, 0.20, 0.20 },
    99	    good    = { 0.20, 1.0, 0.40 },
   100	    warn    = { 1.0, 0.55, 0.10 },
   101	    bad     = { 1.0, 0.15, 0.15 },
   102	    dim     = { 0.45, 0.45, 0.45 },
   103	}

 succeeded in 0ms:
     1	-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
     2	local ADDON, NS = ...
     3	
     4	local HUD = NS:RegisterModule("hud", {})
     5	
     6	local WIDTH, HEIGHT = 240, 18
     7	local CP_SIZE, CP_GAP = 22, 6
     8	local MAX_CP = 5
     9	local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
    10	
    11	function HUD:Init()
    12	    if self.root then return end -- idempotent: never double-init frames
    13	    local db = NS.db
    14	
    15	    -- root anchor (movable)
    16	    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
    17	    root:SetSize(WIDTH, HEIGHT + CP_SIZE + 8)
    18	    root:SetScale(db.scale)
    19	    local p = db.point
    20	    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
    21	    root:SetMovable(true)
    22	    root:EnableMouse(not db.locked)
    23	    root:RegisterForDrag("LeftButton")
    24	    root:SetScript("OnDragStart", function(s) if not NS.db.locked then s:StartMoving() end end)
    25	    root:SetScript("OnDragStop", function(s)
    26	        s:StopMovingOrSizing()
    27	        local a, _, rp, x, y = s:GetPoint()
    28	        NS.db.point = { a, nil, rp, x, y }
    29	    end)
    30	    self.root = root
    31	
    32	    -- drag hint backdrop (only when unlocked)
    33	    root.bg = root:CreateTexture(nil, "BACKGROUND")
    34	    root.bg:SetAllPoints()
    35	    root.bg:SetColorTexture(0, 0, 0, 0.25)
    36	
    37	    -- ---- Energy bar ----
    38	    local energy = CreateFrame("StatusBar", nil, root)
    39	    energy:SetSize(WIDTH, HEIGHT)
    40	    energy:SetPoint("TOP", root, "TOP", 0, 0)
    41	    energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    42	    energy:SetStatusBarColor(unpack(NS.color.energy))
    43	    energy:SetMinMaxValues(0, 100)
    44	    energy.bg = energy:CreateTexture(nil, "BACKGROUND")
    45	    energy.bg:SetAllPoints()
    46	    energy.bg:SetColorTexture(0.12, 0.10, 0.0, 0.85)
    47	    energy.text = energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    48	    energy.text:SetPoint("CENTER")
    49	    self.energy = energy
    50	
    51	    -- 20-energy tick marks
    52	    energy.ticks = {}
    53	    if db.energyTicks then
    54	        for i = 1, 4 do
    55	            local t = energy:CreateTexture(nil, "OVERLAY")
    56	            t:SetColorTexture(0, 0, 0, 0.6)
    57	            t:SetSize(1, HEIGHT)
    58	            t:SetPoint("LEFT", energy, "LEFT", WIDTH * (i * 20 / 100), 0)
    59	            energy.ticks[i] = t
    60	        end
    61	    end
    62	
    63	    -- energy regen-tick spark: a thin marker sweeping the bar 0->100% over the
    64	    -- ~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
    65	    energy.spark = energy:CreateTexture(nil, "OVERLAY")
    66	    energy.spark:SetColorTexture(1, 1, 1, 0.85)
    67	    energy.spark:SetWidth(2)
    68	    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
    69	    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
    70	    energy.spark:Hide()
    71	    self.lastEnergy = nil
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
   166	    -- guard on a live target so the glow can't linger after detarget
   167	    local cp = UnitExists("target") and (GetComboPoints("player", "target") or 0) or 0
   168	    -- polled ~20x/s; only re-alpha the pips when the CP count actually changes
   169	    if cp ~= self.shownCP then
   170	        self.shownCP = cp
   171	        for i = 1, MAX_CP do
   172	            self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
   173	        end
   174	    end
   175	    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
   176	    local g = self.cpGlow
   177	    if g then
   178	        if cp >= MAX_CP and NS.db.cpFinishGlow then
   179	            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
   180	            if not g:IsShown() then g:Show() end
   181	        elseif g:IsShown() then
   182	            g:Hide()
   183	        end
   184	    end
   185	end
   186	
   187	function HUD:Refresh()
   188	    if not self.root then return end
   189	    self.root:SetScale(NS.db.scale)
   190	    self.root:EnableMouse(not NS.db.locked)
   191	    self.root.bg:SetShown(not NS.db.locked)
   192	    self:UpdatePower()
   193	    self:UpdateCP()
   194	end

exec
/bin/zsh -lc "nl -ba cooldowns.lua | sed -n '1,220p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- cooldowns.lua: rogue defensive/utility cooldown icons with sweep timers.
     2	-- READ-ONLY — shows cooldown state, never casts. Only icons for spells you KNOW
     3	-- (so a Combat rogue won't see Cold Blood, an Assassination rogue won't see AR).
     4	
     5	local ADDON, NS = ...
     6	local CDs = NS:RegisterModule("cooldowns", {})
     7	
     8	local ICON, GAP = 30, 4
     9	
    10	-- Tracked by spellID; the name/texture are resolved at runtime (locale-safe).
    11	-- Order = display order. Talent spells simply won't show if untrained.
    12	local SPELL_IDS = {
    13	    1856,   -- Vanish
    14	    5277,   -- Evasion
    15	    2983,   -- Sprint
    16	    13877,  -- Blade Flurry   (Combat)
    17	    13750,  -- Adrenaline Rush (Combat)
    18	    14177,  -- Cold Blood     (Assassination)
    19	    14185,  -- Preparation    (Subtlety)
    20	}
    21	
    22	-- Known-state is determined by scanning the player spellbook by localized name.
    23	-- (GetSpellCooldown(name) does NOT reliably return nil for unlearned spells in
    24	-- 2.5.x, so it can't gate the talent-spell icons — verified by GLM + Codex.)
    25	local BOOK = BOOKTYPE_SPELL or "spell"
    26	
    27	function CDs:Init()
    28	    if not NS.IsRogue then return end
    29	    if self.icons then return end -- idempotent: never double-init
    30	    local root = NS.modules.hud.root
    31	    self.icons = {}
    32	    self.known = {}
    33	    self.layoutDirty = false
    34	
    35	    -- de-dupe the id list (guard against typos above) and resolve names/textures
    36	    local seen = {}
    37	    self.spells = {}
    38	    for _, id in ipairs(SPELL_IDS) do
    39	        if not seen[id] then
    40	            seen[id] = true
    41	            local name, _, tex = GetSpellInfo(id)
    42	            if name then
    43	                self.spells[#self.spells + 1] = { id = id, name = name, tex = tex }
    44	            end
    45	        end
    46	    end
    47	
    48	    -- anchor below the timer bars. Bar 1 top = -56; 4 bars at 14h/3gap → last bar
    49	    -- bottom = -121. Icons are CENTER-anchored, so drop a full ICON/2 + gap below
    50	    -- that to avoid clipping the bottom bar (caught by Codex: was overlapping ~4px).
    51	    local timerBottom = -(18 + 6 + 22 + 10) - (3 * 17) - 14  -- -121
    52	    local rowY = timerBottom - 8 - ICON / 2                   -- -144
    53	
    54	    for i, s in ipairs(self.spells) do
    55	        local f = CreateFrame("Frame", nil, root)
    56	        f:SetSize(ICON, ICON)
    57	        f.icon = f:CreateTexture(nil, "ARTWORK")
    58	        f.icon:SetAllPoints()
    59	        f.icon:SetTexture(s.tex or GetSpellTexture(s.id))
    60	        f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    61	        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    62	        f.cd:SetAllPoints()
    63	        if f.cd.SetDrawEdge then f.cd:SetDrawEdge(true) end
    64	        f.spell = s
    65	        f:Hide()
    66	        self.icons[i] = f
    67	    end
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
   106	        self.known[n] = true
   107	        i = i + 1
   108	    end
   109	end
   110	
   111	-- Show only known spells, packed left-to-right and centered under the HUD.
   112	function CDs:Relayout()
   113	    if not self.icons then return end
   114	    local root = NS.modules.hud.root
   115	    local shown = {}
   116	    for _, f in ipairs(self.icons) do
   117	        if self.known[f.spell.name] then shown[#shown + 1] = f else f:Hide() end
   118	    end
   119	    local n = #shown
   120	    local totalW = n * ICON + (n - 1) * GAP
   121	    local startX = -totalW / 2 + ICON / 2
   122	    for i, f in ipairs(shown) do
   123	        f:ClearAllPoints()
   124	        f:SetPoint("CENTER", root, "TOP", startX + (i - 1) * (ICON + GAP), self.rowY)
   125	        f:Show()
   126	    end
   127	    self:UpdateCooldowns()
   128	end
   129	
   130	function CDs:UpdateCooldowns()
   131	    if not self.icons then return end
   132	    for _, f in ipairs(self.icons) do
   133	        if f:IsShown() then
   134	            local start, dur, enabled = GetSpellCooldown(f.spell.name)
   135	            -- dur > 2 ignores the ~1s GCD sweep; all tracked CDs are far above it
   136	            if start and dur and dur > 2 and enabled ~= 0 then
   137	                f.cd:SetCooldown(start, dur)
   138	                f.icon:SetDesaturated(true)
   139	            else
   140	                f.cd:Clear()
   141	                f.icon:SetDesaturated(false)
   142	            end
   143	        end
   144	    end
   145	end
   146	
   147	function CDs:Refresh()
   148	    if self.icons then self:RebuildKnown(); self:Relayout() end
   149	end

exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '1,260p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Timers: track YOUR finisher durations on the current target via combat log.
     2	-- Slice and Dice (self buff) + Rupture / Expose Armor / Garrote (target debuffs).
     3	-- Uses CLEU for application/refresh so it works pre-2.5 aura APIs reliably.
     4	
     5	local ADDON, NS = ...
     6	local Timers = NS:RegisterModule("timers", {})
     7	
     8	-- spellID -> { label, base, perCP (optional) }  durations are *max* (5cp) approximations;
     9	-- we read the real remaining time from auras when possible, CLEU is the fallback.
    10	local TRACK = {
    11	    -- Slice and Dice ranks share name; track by name (self buff)
    12	    snd = { name = "Slice and Dice", isSelf = true,  color = "good" },
    13	    rup = { name = "Rupture",        isSelf = false, color = "bad"  },
    14	    exp = { name = "Expose Armor",   isSelf = false, color = "warn" },
    15	    gar = { name = "Garrote",        isSelf = false, color = "bad"  },
    16	}
    17	
    18	local BAR_W, BAR_H = 200, 14
    19	local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
    20	
    21	-- Can the player actually refresh this aura right now? Used to gate the green
    22	-- "refresh-now" cue so it never implies an action you lack resources for.
    23	-- Finisher cost is 25 energy; SnD needs only energy, Rupture/Expose also need CP.
    24	local function HasRefreshResources(key)
    25	    local e = UnitPower("player", ENERGY)
    26	    if key == "snd" then
    27	        return e >= 25 -- self-buff, only needs energy
    28	    elseif key == "rup" or key == "exp" then
    29	        -- finishers: need a live attackable target AND energy AND a combo point
    30	        if not UnitExists("target") or UnitIsDead("target")
    31	            or not UnitCanAttack("player", "target") then
    32	            return false
    33	        end
    34	        return e >= 25 and (GetComboPoints("player", "target") or 0) >= 1
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
    52	            local dur2, exp2
    53	            n, _, _, _, dur2, exp2 = UnitAura(unit, i, filter)
    54	            if not n then break end
    55	            dur, exp = dur2, exp2
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
   181	            -- fill-green gated separately so /cut zone toggles live and restores base.
   182	            local want = rem <= warnAt
   183	            if want ~= b.inZone then
   184	                b.inZone = want
   185	                b.label:SetTextColor(want and NS.color.bad[1] or 1,
   186	                                     want and NS.color.bad[2] or 1,
   187	                                     want and NS.color.bad[3] or 1)
   188	                if want and NS.db.sound then
   189	                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
   190	                end
   191	            end
   192	            local green = want and NS.db.refreshZone
   193	            if green and NS.db.smartRefresh then green = HasRefreshResources(key) end
   194	            if green ~= b.greenState then
   195	                b.greenState = green
   196	                b:SetStatusBarColor(unpack(green and NS.color.good or b.baseColor))
   197	            end
   198	
   199	            if not b:IsShown() then b:Show() end
   200	        end
   201	    end
   202	end
   203	
   204	function Timers:Refresh() if self.cache then self:Scan() end end

exec
/bin/zsh -lc "nl -ba alerts.lua | sed -n '1,240p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Alerts: reactive reminders. ALERTS ONLY — never casts/queues a spell (Warden-safe).
     2	--   * Kick reminder: target is casting an interruptible spell AND Kick is off CD -> flash icon.
     3	--   * Poison check: out of combat, MH/OH missing a weapon enchant -> reminder text.
     4	--   * Stealth opener: in stealth with a target -> show Ambush/Garrote hint.
     5	
     6	local ADDON, NS = ...
     7	local Alerts = NS:RegisterModule("alerts", {})
     8	
     9	local KICK = GetSpellInfo and GetSpellInfo(1766) or "Kick" -- localized name
    10	
    11	local function SpellReady(name)
    12	    if not name then return false end
    13	    -- don't nag to Kick when it can't actually be cast (e.g. not enough energy)
    14	    local usable, noMana = IsUsableSpell(name)
    15	    if not usable or noMana then return false end
    16	    local start, dur, enabled = GetSpellCooldown(name)
    17	    if not start or enabled == 0 then return false end
    18	    return (start == 0) or (start + dur - GetTime() <= 0.2)
    19	end
    20	
    21	function Alerts:Init()
    22	    if self.ev then return end -- idempotent: never double-init frames/events
    23	    local root = NS.modules.hud.root
    24	
    25	    -- ---- Kick flash icon (center, above HUD) ----
    26	    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
    27	    kick:SetSize(64, 64)
    28	    kick:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    29	    kick.icon = kick:CreateTexture(nil, "ARTWORK")
    30	    kick.icon:SetAllPoints()
    31	    kick.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    32	    kick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    33	    kick.txt = kick:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    34	    kick.txt:SetPoint("TOP", kick, "BOTTOM", 0, -2)
    35	    kick.txt:SetText("KICK!")
    36	    kick.txt:SetTextColor(unpack(NS.color.bad))
    37	    kick:Hide()
    38	    -- pulse
    39	    local ag = kick:CreateAnimationGroup()
    40	    ag:SetLooping("BOUNCE")
    41	    local a = ag:CreateAnimation("Alpha")
    42	    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    43	    kick.ag = ag
    44	    self.kick = kick
    45	
    46	    -- ---- Poison reminder text ----
    47	    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    48	    pz:SetPoint("BOTTOM", root, "TOP", 0, 6)
    49	    pz:SetTextColor(unpack(NS.color.warn))
    50	    pz:Hide()
    51	    self.poison = pz
    52	
    53	    -- ---- Stealth opener hint ----
    54	    local op = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    55	    op:SetPoint("BOTTOM", root, "TOP", 0, 28)
    56	    op:SetTextColor(unpack(NS.color.good))
    57	    op:Hide()
    58	    self.opener = op
    59	
    60	    local ev = CreateFrame("Frame")
    61	    ev:RegisterEvent("UNIT_SPELLCAST_START")
    62	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    63	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
    64	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    65	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    66	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    67	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
    68	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
    69	    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
    70	    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
    71	    ev:RegisterEvent("UPDATE_STEALTH")
    72	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    73	    ev:SetScript("OnEvent", function(_, e, unit) Alerts:OnEvent(e, unit) end)
    74	    self.ev = ev
    75	end
    76	
    77	function Alerts:OnEvent(e, unit)
    78	    if not NS.IsRogue then return end
    79	    if e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_ENTERING_WORLD" or e == "UNIT_INVENTORY_CHANGED" then
    80	        self:CheckPoison()
    81	    elseif e == "PLAYER_REGEN_DISABLED" then
    82	        self.poison:Hide()
    83	    end
    84	    if e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_ENTERING_WORLD" then
    85	        self:CheckOpener()
    86	    end
    87	    -- Kick logic on any cast event affecting the target
    88	    self:CheckKick(e, unit)
    89	end
    90	
    91	function Alerts:CheckKick(e, unit)
    92	    if not NS.db.kickAlert then return end
    93	    if unit ~= "target" then
    94	        -- still re-evaluate on target change / cooldown updates
    95	        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
    96	    end
    97	    local casting = false
    98	    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    99	    if not name then
   100	        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
   101	    end
   102	    if name and not notInterruptible then casting = true end
   103	
   104	    if casting and SpellReady(KICK) then
   105	        if not self.kick:IsShown() then
   106	            self.kick:Show()
   107	            self.kick.ag:Stop(); self.kick.ag:Play() -- reset loop state cleanly
   108	            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
   109	        end
   110	    else
   111	        if self.kick:IsShown() then self.kick.ag:Stop(); self.kick:Hide() end
   112	    end
   113	end
   114	
   115	function Alerts:CheckPoison()
   116	    if not NS.db.poisonCheck then self.poison:Hide(); return end
   117	    if InCombatLockdown() then return end -- only nag out of combat
   118	    -- TBC 2.5 sig: hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges (no enchantID)
   119	    local mh, _, _, oh = GetWeaponEnchantInfo()
   120	    local missing = {}
   121	    if not mh then missing[#missing + 1] = "Main-hand" end
   122	    -- only warn off-hand if one is equipped
   123	    if GetInventoryItemLink("player", 17) and not oh then missing[#missing + 1] = "Off-hand" end
   124	    if #missing > 0 then
   125	        self.poison:SetText("No poison: " .. table.concat(missing, " & "))
   126	        self.poison:Show()
   127	    else
   128	        self.poison:Hide()
   129	    end
   130	end
   131	
   132	function Alerts:CheckOpener()
   133	    if not NS.db.openerHint then self.opener:Hide(); return end
   134	    local stealthed = IsStealthed and IsStealthed()
   135	    if stealthed and UnitExists("target") and UnitCanAttack("player", "target") then
   136	        self.opener:SetText("Opener: Ambush / Garrote")
   137	        self.opener:Show()
   138	    else
   139	        self.opener:Hide()
   140	    end
   141	end
   142	
   143	function Alerts:Refresh()
   144	    if self.kick then self.kick:Hide() end
   145	    if NS.IsRogue then
   146	        self:CheckPoison()  -- hides itself if disabled / in combat
   147	        self:CheckOpener()  -- hides itself if disabled
   148	    end
   149	end

exec
/bin/zsh -lc "nl -ba options.lua | sed -n '1,190p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- options.lua: graphical settings panel in Interface > AddOns, so you don't have
     2	-- to memorize the /cut slash toggles. Read-only over the addon's SavedVariables.
     3	local ADDON, NS = ...
     4	local Options = NS:RegisterModule("options", {})
     5	
     6	-- boolean settings -> checkbox label (order = top-to-bottom in the panel)
     7	local TOGGLES = {
     8	    { "locked",       "Lock HUD position" },
     9	    { "kickAlert",    "Kick interrupt reminder" },
    10	    { "poisonCheck",  "Poison missing warning" },
    11	    { "openerHint",   "Stealth opener hint" },
    12	    { "sound",        "Alert sounds" },
    13	    { "energyTicks",  "Energy 20-mark lines (reload to apply)" },
    14	    { "tickSpark",    "Energy regen-tick spark" },
    15	    { "refreshZone",  "Refresh-now marker on bars" },
    16	    { "smartRefresh", "Green only when CP/energy ready" },
    17	    { "cpFinishGlow", "Max-CP overcap glow" },
    18	}
    19	
    20	function Options:Init()
    21	    if self.panel then return end   -- idempotent
    22	    if not NS.db then return end    -- SavedVariables must be loaded first
    23	    local panel = CreateFrame("Frame", "CutthroatOptions", UIParent)
    24	    panel.name = "Cutthroat"
    25	    self.panel = panel
    26	
    27	    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    28	    title:SetPoint("TOPLEFT", 16, -16)
    29	    title:SetText("Cutthroat |cff00ff96Rogue|r")
    30	    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    31	    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    32	    sub:SetText("Ban-safe HUD + alerts. Changes apply instantly.")
    33	
    34	    self.checks = {}
    35	    local y = -64
    36	    for _, t in ipairs(TOGGLES) do
    37	        local key, label = t[1], t[2]
    38	        local cb = CreateFrame("CheckButton", "CutthroatOpt_" .. key, panel, "UICheckButtonTemplate")
    39	        cb:SetPoint("TOPLEFT", 16, y)
    40	        local txt = _G[cb:GetName() .. "Text"]
    41	        if txt then txt:SetText(label) end
    42	        cb:SetScript("OnClick", function(b)
    43	            NS.db[key] = b:GetChecked() and true or false
    44	            NS.CallAll("Refresh")
    45	        end)
    46	        self.checks[key] = cb
    47	        y = y - 28
    48	    end
    49	
    50	    -- scale slider (uses the legacy OptionsSliderTemplate, present in 2.5.x)
    51	    local s = CreateFrame("Slider", "CutthroatOptScale", panel, "OptionsSliderTemplate")
    52	    s:SetPoint("TOPLEFT", 20, y - 20)
    53	    s:SetMinMaxValues(0.4, 3.0)
    54	    s:SetValueStep(0.05)
    55	    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    56	    s:SetWidth(220)
    57	    local sn = s:GetName()
    58	    if _G[sn .. "Low"] then _G[sn .. "Low"]:SetText("0.4") end
    59	    if _G[sn .. "High"] then _G[sn .. "High"]:SetText("3.0") end
    60	    if _G[sn .. "Text"] then _G[sn .. "Text"]:SetText("Scale") end -- title before first drag
    61	    s:SetScript("OnValueChanged", function(sl, v)
    62	        v = math.floor(v * 20 + 0.5) / 20 -- snap to 0.05
    63	        if _G[sl:GetName() .. "Text"] then
    64	            _G[sl:GetName() .. "Text"]:SetText(string.format("Scale: %.2f", v))
    65	        end
    66	        if NS.db.scale ~= v then
    67	            NS.db.scale = v
    68	            -- apply live + cheap (only the HUD scales) instead of a full CallAll per drag step
    69	            local hud = NS.modules.hud
    70	            if hud and hud.root then hud.root:SetScale(v) end
    71	        end
    72	    end)
    73	    self.scale = s
    74	
    75	    -- legacy Interface Options "refresh" hook fires when the panel is shown
    76	    panel.refresh = function() self:Load() end
    77	
    78	    -- register: legacy API for 2.5.x; Settings.* is a retail-10.0+ fallback only
    79	    if InterfaceOptions_AddCategory then
    80	        InterfaceOptions_AddCategory(panel)
    81	    elseif Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    82	        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    83	        Settings.RegisterAddOnCategory(cat)
    84	        self.category = cat
    85	    end
    86	    self:Load()
    87	end
    88	
    89	-- mirror the saved values into the widgets
    90	function Options:Load()
    91	    if not self.checks or not NS.db then return end
    92	    for key, cb in pairs(self.checks) do
    93	        cb:SetChecked(NS.db[key] and true or false)
    94	    end
    95	    if self.scale then self.scale:SetValue(NS.db.scale or 1.0) end
    96	end
    97	
    98	function Options:Refresh() self:Load() end
    99	
   100	-- open the panel (called by /cut config)
   101	function Options:Open()
   102	    if not self.panel then return end
   103	    if InterfaceOptionsFrame_OpenToCategory then
   104	        -- Blizzard bug: first call sometimes lands on the wrong page; call twice
   105	        InterfaceOptionsFrame_OpenToCategory(self.panel)
   106	        InterfaceOptionsFrame_OpenToCategory(self.panel)
   107	    elseif Settings and Settings.OpenToCategory and self.category then
   108	        Settings.OpenToCategory(self.category:GetID())
   109	    end
   110	end

exec
/bin/zsh -lc "nl -ba config.lua | sed -n '1,180p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Config: /cut slash command. Minimal, no external libs.
     2	local ADDON, NS = ...
     3	local Config = NS:RegisterModule("config", {})
     4	
     5	local function on(v) return v and "|cff20ff40on|r" or "|cffff4040off|r" end
     6	
     7	local function Print(msg) print("|cff00ff96Cutthroat|r: " .. msg) end
     8	
     9	local function Help()
    10	    Print("commands:")
    11	    print("  |cffffff00/cut lock|r        toggle move/lock HUD")
    12	    print("  |cffffff00/cut scale N|r      set scale (e.g. 0.9)")
    13	    print("  |cffffff00/cut kick|r         toggle Kick reminder")
    14	    print("  |cffffff00/cut poison|r       toggle poison check")
    15	    print("  |cffffff00/cut opener|r       toggle stealth opener hint")
    16	    print("  |cffffff00/cut sound|r        toggle alert sounds")
    17	    print("  |cffffff00/cut ticks|r        toggle energy 20-mark lines")
    18	    print("  |cffffff00/cut spark|r        toggle energy regen-tick spark")
    19	    print("  |cffffff00/cut zone|r         toggle refresh-now marker on bars")
    20	    print("  |cffffff00/cut smart|r        green only when CP/energy ready")
    21	    print("  |cffffff00/cut finish|r       toggle max-CP overcap glow")
    22	    print("  |cffffff00/cut snd N|r        SnD warning seconds")
    23	    print("  |cffffff00/cut rup N|r        Rupture warning seconds")
    24	    print("  |cffffff00/cut config|r       open the options panel")
    25	    print("  |cffffff00/cut reset|r        reset position")
    26	    print("  |cffffff00/cut status|r       show settings")
    27	end
    28	
    29	function Config:Init()
    30	    SLASH_CUTTHROAT1 = "/cut"
    31	    SLASH_CUTTHROAT2 = "/cutthroat"
    32	    SlashCmdList["CUTTHROAT"] = function(msg)
    33	        local db = NS.db
    34	        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    35	        cmd = (cmd or ""):lower()
    36	
    37	        if cmd == "" or cmd == "help" then
    38	            Help()
    39	        elseif cmd == "lock" then
    40	            db.locked = not db.locked
    41	            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
    42	        elseif cmd == "scale" then
    43	            local n = tonumber(arg)
    44	            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
    45	            else Print("scale needs 0.4-3.0") end
    46	        elseif cmd == "kick" then
    47	            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
    48	        elseif cmd == "poison" then
    49	            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
    50	        elseif cmd == "opener" then
    51	            db.openerHint = not db.openerHint; Print("opener hint " .. on(db.openerHint))
    52	        elseif cmd == "sound" then
    53	            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
    54	        elseif cmd == "ticks" then
    55	            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
    56	        elseif cmd == "spark" then
    57	            db.tickSpark = not db.tickSpark; Print("regen-tick spark " .. on(db.tickSpark))
    58	        elseif cmd == "zone" then
    59	            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
    60	        elseif cmd == "smart" then
    61	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
    62	        elseif cmd == "finish" then
    63	            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
    64	        elseif cmd == "snd" then
    65	            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
    66	        elseif cmd == "rup" then
    67	            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
    68	        elseif cmd == "config" or cmd == "options" then
    69	            if NS.modules.options and NS.modules.options.Open then
    70	                NS.modules.options:Open()
    71	            end
    72	        elseif cmd == "reset" then
    73	            db.point = { "CENTER", nil, "CENTER", 0, -180 }
    74	            Print("position reset (/reload to apply)")
    75	        elseif cmd == "status" then
    76	            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s",
    77	                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound)))
    78	            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
    79	                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
    80	        else
    81	            Help()
    82	        end
    83	        NS.CallAll("Refresh")
    84	    end
    85	end
    86	
    87	function Config:Refresh() end

codex
One important concrete mismatch: this machine is running `Lua 5.5.0`, while WoW TBC Classic addon Lua is 5.1-derived. That makes the harness useful as a smoke runner, but its header claim of “faithful enough” is too strong.
exec
/bin/zsh -lc 'lua test/run.lua' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
== load modules ==
  ok   load core.lua
  ok   load hud.lua
  ok   load timers.lua
  ok   load cooldowns.lua
  ok   load alerts.lua
  ok   load options.lua
  ok   load config.lua
== lifecycle (rogue) ==
  ok   ADDON_LOADED
  ok   db populated
|cff00ff96Cutthroat|r vtest loaded. |cffffff00/cut|r for options.
  ok   PLAYER_LOGIN
  ok   hud inited
  ok   timers inited
  ok   cooldowns inited
  ok   options inited
== gameplay ==
  ok   power event
  ok   aura event
  ok   render loop (20 frames) no error
  ok   SnD bar shown while buffed
  ok   Rupture bar shown while debuffed
  ok   CP overcap glow shown at 5 CP
== kick alert ==
  ok   cast start event
  ok   kick flash shown vs interruptible cast
  ok   cast stop event
== poison check ==
  ok   regen-enabled event
  ok   poison warning shown when MH unenchanted
== slash commands ==
  ok   slash registered
|cff00ff96Cutthroat|r: commands:
  |cffffff00/cut lock|r        toggle move/lock HUD
  |cffffff00/cut scale N|r      set scale (e.g. 0.9)
  |cffffff00/cut kick|r         toggle Kick reminder
  |cffffff00/cut poison|r       toggle poison check
  |cffffff00/cut opener|r       toggle stealth opener hint
  |cffffff00/cut sound|r        toggle alert sounds
  |cffffff00/cut ticks|r        toggle energy 20-mark lines
  |cffffff00/cut spark|r        toggle energy regen-tick spark
  |cffffff00/cut zone|r         toggle refresh-now marker on bars
  |cffffff00/cut smart|r        green only when CP/energy ready
  |cffffff00/cut finish|r       toggle max-CP overcap glow
  |cffffff00/cut snd N|r        SnD warning seconds
  |cffffff00/cut rup N|r        Rupture warning seconds
  |cffffff00/cut config|r       open the options panel
  |cffffff00/cut reset|r        reset position
  |cffffff00/cut status|r       show settings
  ok   /cut 
|cff00ff96Cutthroat|r: commands:
  |cffffff00/cut lock|r        toggle move/lock HUD
  |cffffff00/cut scale N|r      set scale (e.g. 0.9)
  |cffffff00/cut kick|r         toggle Kick reminder
  |cffffff00/cut poison|r       toggle poison check
  |cffffff00/cut opener|r       toggle stealth opener hint
  |cffffff00/cut sound|r        toggle alert sounds
  |cffffff00/cut ticks|r        toggle energy 20-mark lines
  |cffffff00/cut spark|r        toggle energy regen-tick spark
  |cffffff00/cut zone|r         toggle refresh-now marker on bars
  |cffffff00/cut smart|r        green only when CP/energy ready
  |cffffff00/cut finish|r       toggle max-CP overcap glow
  |cffffff00/cut snd N|r        SnD warning seconds
  |cffffff00/cut rup N|r        Rupture warning seconds
  |cffffff00/cut config|r       open the options panel
  |cffffff00/cut reset|r        reset position
  |cffffff00/cut status|r       show settings
  ok   /cut help
|cff00ff96Cutthroat|r: locked false | scale 1.00 | kick |cff20ff40on|r | poison |cff20ff40on|r | opener |cff20ff40on|r | sound |cff20ff40on|r
|cff00ff96Cutthroat|r: ticks |cff20ff40on|r | spark |cff20ff40on|r | zone |cff20ff40on|r | smart |cff20ff40on|r | finish |cff20ff40on|r
  ok   /cut status
|cff00ff96Cutthroat|r: HUD locked
  ok   /cut lock
|cff00ff96Cutthroat|r: scale 1.2
  ok   /cut scale 1.2
|cff00ff96Cutthroat|r: scale needs 0.4-3.0
  ok   /cut scale 9
|cff00ff96Cutthroat|r: Kick reminder |cffff4040off|r
  ok   /cut kick
|cff00ff96Cutthroat|r: poison check |cffff4040off|r
  ok   /cut poison
|cff00ff96Cutthroat|r: opener hint |cffff4040off|r
  ok   /cut opener
|cff00ff96Cutthroat|r: alert sound |cffff4040off|r
  ok   /cut sound
|cff00ff96Cutthroat|r: energy ticks |cffff4040off|r (/reload to apply)
  ok   /cut ticks
|cff00ff96Cutthroat|r: regen-tick spark |cffff4040off|r
  ok   /cut spark
|cff00ff96Cutthroat|r: refresh marker |cffff4040off|r
  ok   /cut zone
|cff00ff96Cutthroat|r: smart refresh (CP/energy-gated) |cffff4040off|r
  ok   /cut smart
|cff00ff96Cutthroat|r: max-CP overcap glow |cffff4040off|r
  ok   /cut finish
|cff00ff96Cutthroat|r: SnD warn at 4s
  ok   /cut snd 4
|cff00ff96Cutthroat|r: Rupture warn at 3s
  ok   /cut rup 3
  ok   /cut config
  ok   /cut options
|cff00ff96Cutthroat|r: position reset (/reload to apply)
  ok   /cut reset
|cff00ff96Cutthroat|r: commands:
  |cffffff00/cut lock|r        toggle move/lock HUD
  |cffffff00/cut scale N|r      set scale (e.g. 0.9)
  |cffffff00/cut kick|r         toggle Kick reminder
  |cffffff00/cut poison|r       toggle poison check
  |cffffff00/cut opener|r       toggle stealth opener hint
  |cffffff00/cut sound|r        toggle alert sounds
  |cffffff00/cut ticks|r        toggle energy 20-mark lines
  |cffffff00/cut spark|r        toggle energy regen-tick spark
  |cffffff00/cut zone|r         toggle refresh-now marker on bars
  |cffffff00/cut smart|r        green only when CP/energy ready
  |cffffff00/cut finish|r       toggle max-CP overcap glow
  |cffffff00/cut snd N|r        SnD warning seconds
  |cffffff00/cut rup N|r        Rupture warning seconds
  |cffffff00/cut config|r       open the options panel
  |cffffff00/cut reset|r        reset position
  |cffffff00/cut status|r       show settings
  ok   /cut bogus
== detarget clears glow ==
  ok   CP glow clears on detarget
== non-rogue load ==
  ok   non-rogue modules load
|cff00ff96Cutthroat|r vtest loaded. |cffffff00/cut|r for options.
|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.
|cff00ff96Cutthroat|r vtest loaded. |cffffff00/cut|r for options.
  ok   non-rogue ADDON_LOADED+LOGIN
  ok   non-rogue HUD NOT inited
  ok   non-rogue options STILL inited

== RESULT: 52 passed, 0 failed ==

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. **False confidence.** `52 passed` mostly means “modules loaded under a permissive mock.” It is not strong evidence the addon works in TBC. The biggest issue is [test/run.lua:44](/Users/creative/WoWAddons/Cutthroat/test/run.lua:44): every unknown widget method returns `noop`, so misspelled or unavailable frame APIs silently pass.

2. **The no-op frame mock masks real UI bugs.** Calls like `SetSize`, `SetPoint`, `SetScale`, `SetStatusBarColor`, `SetText`, `SetShown`, `SetCooldown`, animation methods, etc. are mostly swallowed unless explicitly modeled. A typo like `SetStatuzBarColor` would pass. Improvement: make `__index` throw `unknown method <kind>:<name>` by default, then whitelist only real 2.5.x methods used by this addon.

3. **Many assertions are tautological/no-error checks.** Examples: module loads [test/run.lua:145](/Users/creative/WoWAddons/Cutthroat/test/run.lua:145), event pcalls [test/run.lua:156](/Users/creative/WoWAddons/Cutthroat/test/run.lua:156), slash command pcalls [test/run.lua:197](/Users/creative/WoWAddons/Cutthroat/test/run.lua:197). These test that the mock did not explode. Stronger checks would assert `db` mutations after each slash command, actual bar values/text, cooldown desaturation, poison text content, opener visibility, disabled settings hiding things, and negative cases.

4. **Runtime mismatch is material.** This run used `Lua 5.5.0`; WoW TBC is Lua 5.1-derived. Green here does not catch 5.1-incompatible syntax/features: `goto`, `table.unpack`, newer standard library behavior, and some numeric/string edge cases. The shim at [test/run.lua:29](/Users/creative/WoWAddons/Cutthroat/test/run.lua:29) gives `unpack`, but it does not prevent addon code from using `table.unpack`, which would fail in WoW.

5. **`#` on holed tables remains a known trap.** The addon correctly avoids `#point` for `{ "CENTER", nil, ... }` in [core.lua:54](/Users/creative/WoWAddons/Cutthroat/core.lua:54), but the harness should add a regression test with corrupted `CutthroatDB.point` before `ADDON_LOADED`. Also test all saved-variable migrations from existing partial/corrupt DBs, not only empty DB.

6. **Event dispatch is not faithful.** `RegisterUnitEvent` ignores unit filters [test/run.lua:49](/Users/creative/WoWAddons/Cutthroat/test/run.lua:49), and `fire` broadcasts synchronously to every frame [test/run.lua:76](/Users/creative/WoWAddons/Cutthroat/test/run.lua:76). Real WoW has unit-filtered delivery, addon load ordering, reentrant events, combat lockdown timing, and frame script ordering concerns.

7. **OnUpdate is too idealized.** `tick` calls all `OnUpdate`s synchronously in creation order [test/run.lua:81](/Users/creative/WoWAddons/Cutthroat/test/run.lua:81). It does not test irregular `dt`, long frame stalls, one-shot `OnUpdate` cleanup in cooldowns [cooldowns.lua:78](/Users/creative/WoWAddons/Cutthroat/cooldowns.lua:78), or scripts created/destroyed during dispatch.

8. **The aura/cooldown mocks are oversimplified.** `UnitAura` ignores filter args [test/run.lua:118](/Users/creative/WoWAddons/Cutthroat/test/run.lua:118), so `"HARMFUL PLAYER"` behavior in [timers.lua:43](/Users/creative/WoWAddons/Cutthroat/timers.lua:43) is not really tested. `GetSpellCooldown` always returns ready [test/run.lua:106](/Users/creative/WoWAddons/Cutthroat/test/run.lua:106), so cooldown hiding/desaturation logic in [cooldowns.lua:130](/Users/creative/WoWAddons/Cutthroat/cooldowns.lua:130) is barely covered.

9. **State contamination makes passing misleading.** The non-rogue phase reuses `allFrames`, globals, and `CutthroatDB`; firing events hits both first-run rogue frames and second-run non-rogue frames. That is visible in duplicate load prints. Improvement: isolate each scenario in a fresh Lua process or reset all globals/frame registries between scenarios.

10. **Concrete next upgrades:** run under Lua 5.1; replace permissive `__index`; implement stateful widget methods; validate event names against a TBC allowlist; honor `RegisterUnitEvent` units; split tests into fresh-process scenarios; add negative tests for wrong unit events, cooldown active/unlearned spells, corrupt saved vars, disabled toggles, no target/dead target, non-interruptible casts, offhand equipped/missing poison, and options checkbox/slider callbacks. Then label the harness honestly: “headless smoke/regression tests,” not “execution ground truth.”
tokens used
65,471
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

1. **False confidence.** `52 passed` mostly means “modules loaded under a permissive mock.” It is not strong evidence the addon works in TBC. The biggest issue is [test/run.lua:44](/Users/creative/WoWAddons/Cutthroat/test/run.lua:44): every unknown widget method returns `noop`, so misspelled or unavailable frame APIs silently pass.

2. **The no-op frame mock masks real UI bugs.** Calls like `SetSize`, `SetPoint`, `SetScale`, `SetStatusBarColor`, `SetText`, `SetShown`, `SetCooldown`, animation methods, etc. are mostly swallowed unless explicitly modeled. A typo like `SetStatuzBarColor` would pass. Improvement: make `__index` throw `unknown method <kind>:<name>` by default, then whitelist only real 2.5.x methods used by this addon.

3. **Many assertions are tautological/no-error checks.** Examples: module loads [test/run.lua:145](/Users/creative/WoWAddons/Cutthroat/test/run.lua:145), event pcalls [test/run.lua:156](/Users/creative/WoWAddons/Cutthroat/test/run.lua:156), slash command pcalls [test/run.lua:197](/Users/creative/WoWAddons/Cutthroat/test/run.lua:197). These test that the mock did not explode. Stronger checks would assert `db` mutations after each slash command, actual bar values/text, cooldown desaturation, poison text content, opener visibility, disabled settings hiding things, and negative cases.

4. **Runtime mismatch is material.** This run used `Lua 5.5.0`; WoW TBC is Lua 5.1-derived. Green here does not catch 5.1-incompatible syntax/features: `goto`, `table.unpack`, newer standard library behavior, and some numeric/string edge cases. The shim at [test/run.lua:29](/Users/creative/WoWAddons/Cutthroat/test/run.lua:29) gives `unpack`, but it does not prevent addon code from using `table.unpack`, which would fail in WoW.

5. **`#` on holed tables remains a known trap.** The addon correctly avoids `#point` for `{ "CENTER", nil, ... }` in [core.lua:54](/Users/creative/WoWAddons/Cutthroat/core.lua:54), but the harness should add a regression test with corrupted `CutthroatDB.point` before `ADDON_LOADED`. Also test all saved-variable migrations from existing partial/corrupt DBs, not only empty DB.

6. **Event dispatch is not faithful.** `RegisterUnitEvent` ignores unit filters [test/run.lua:49](/Users/creative/WoWAddons/Cutthroat/test/run.lua:49), and `fire` broadcasts synchronously to every frame [test/run.lua:76](/Users/creative/WoWAddons/Cutthroat/test/run.lua:76). Real WoW has unit-filtered delivery, addon load ordering, reentrant events, combat lockdown timing, and frame script ordering concerns.

7. **OnUpdate is too idealized.** `tick` calls all `OnUpdate`s synchronously in creation order [test/run.lua:81](/Users/creative/WoWAddons/Cutthroat/test/run.lua:81). It does not test irregular `dt`, long frame stalls, one-shot `OnUpdate` cleanup in cooldowns [cooldowns.lua:78](/Users/creative/WoWAddons/Cutthroat/cooldowns.lua:78), or scripts created/destroyed during dispatch.

8. **The aura/cooldown mocks are oversimplified.** `UnitAura` ignores filter args [test/run.lua:118](/Users/creative/WoWAddons/Cutthroat/test/run.lua:118), so `"HARMFUL PLAYER"` behavior in [timers.lua:43](/Users/creative/WoWAddons/Cutthroat/timers.lua:43) is not really tested. `GetSpellCooldown` always returns ready [test/run.lua:106](/Users/creative/WoWAddons/Cutthroat/test/run.lua:106), so cooldown hiding/desaturation logic in [cooldowns.lua:130](/Users/creative/WoWAddons/Cutthroat/cooldowns.lua:130) is barely covered.

9. **State contamination makes passing misleading.** The non-rogue phase reuses `allFrames`, globals, and `CutthroatDB`; firing events hits both first-run rogue frames and second-run non-rogue frames. That is visible in duplicate load prints. Improvement: isolate each scenario in a fresh Lua process or reset all globals/frame registries between scenarios.

10. **Concrete next upgrades:** run under Lua 5.1; replace permissive `__index`; implement stateful widget methods; validate event names against a TBC allowlist; honor `RegisterUnitEvent` units; split tests into fresh-process scenarios; add negative tests for wrong unit events, cooldown active/unlearned spells, corrupt saved vars, disabled toggles, no target/dead target, non-interruptible casts, offhand equipped/missing poison, and options checkbox/slider callbacks. Then label the harness honestly: “headless smoke/regression tests,” not “execution ground truth.”
