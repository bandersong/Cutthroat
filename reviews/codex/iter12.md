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
session id: 019f09d3-cfe5-7810-9c49-fa3af4ddc7e8
--------
user
FINAL SHIP-READINESS / CONVERGENCE AUDIT of this Cutthroat WoW TBC Classic 2.5.x Rogue addon. Feature-complete (energy/CP HUD, SnD/Rupture/Expose/Garrote timers + refresh markers, cooldown row, Kick reminder, poison check, opener hint, CP-overcap glow, options GUI), ban-safe (read-only, no spell automation), 115 headless regression tests passing on real Lua 5.1 via CI, fully documented, 11 prior triangulated rounds already fixed the known bugs. Read all .lua files + test/run.lua. BE SKEPTICAL — do NOT manufacture issues to seem useful. Binary question: any REAL remaining (a) correctness bug, (b) ban-safety/Warden risk, or (c) genuinely ESSENTIAL missing capability for a basic TBC rogue helper? If yes: concrete file+fix. If nothing real remains: explicitly say 'NO REAL ISSUES — SHIP IT (pending in-client visual test)'. Nice-to-haves/gold-plating do NOT count. One clear verdict at top. Do NOT edit files.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll audit this read-only: enumerate the Lua surface, read every `.lua` plus `test/run.lua`, then report only material ship blockers if they exist.
exec
/bin/zsh -lc "rg --files -g '*.lua'" in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
zsh:1: command not found: rg

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
./prompts/converge_iter12.txt
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
./reviews/codex/iter12.md
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
./reviews/glm/iter12.md
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
/bin/zsh -lc 'pwd && ls' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
/Users/creative/WoWAddons/Cutthroat
CHANGELOG.md
Cutthroat.toc
LICENSE
README.md
alerts.lua
config.lua
cooldowns.lua
core.lua
docs
hud.lua
options.lua
prompts
reviews
test
timers.lua

codex
`rg` is not installed here, so I’m using `find` and direct file reads. The Lua surface is small: `alerts.lua`, `config.lua`, `cooldowns.lua`, `core.lua`, `hud.lua`, `options.lua`, `timers.lua`, and `test/run.lua`.
exec
/bin/zsh -lc 'nl -ba alerts.lua' in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc 'nl -ba cooldowns.lua' in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc 'nl -ba options.lua' in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc 'nl -ba test/run.lua' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	-- Headless smoke + regression tests for Cutthroat.  Run from the addon root:
     2	--     lua test/run.lua          (lua5.1 / luajit preferred; see LIMITATIONS)
     3	--
     4	-- WHAT THIS PROVES: every module loads in order; the lifecycle and gameplay code
     5	-- paths RUN without Lua errors under a strict WoW-API mock; basic state-driven
     6	-- behavior (show/hide, db mutation, sanitization) is correct; and the addon only
     7	-- calls real 2.5.x frame methods + registers real events (the mock ERRORS on an
     8	-- unknown method or event — that's how it caught the iter-2 PLAYER_TALENT_UPDATE
     9	-- class of bug).
    10	--
    11	-- WHAT IT DOES *NOT* PROVE (still needs docs/SMOKE_TEST.md in a real client):
    12	--   * visual/layout correctness — SetPoint/SetAlpha/etc. are no-ops, so anchor
    13	--     overlaps, texture paths, and render glitches are NOT caught.
    14	--   * real event payloads/timing, unit-filtered delivery, combat-lockdown timing.
    15	--   * Lua 5.1 vs the host runtime: if run on 5.4/5.5 it won't catch 5.1-only
    16	--     incompatibilities. The addon avoids the known traps (no #t on the nil-holed
    17	--     point table, no table.unpack, no goto, no coroutines), but run on 5.1/LuaJIT
    18	--     for true fidelity.
    19	-- Treat a green run as a strong smoke/regression signal, not a ship guarantee.
    20	
    21	local ok_count, fail_count = 0, 0
    22	local function check(name, cond, msg)
    23	    if cond then ok_count = ok_count + 1; print("  ok   " .. name)
    24	    else fail_count = fail_count + 1; print("  FAIL " .. name .. (msg and ("  -- " .. tostring(msg)) or "")) end
    25	end
    26	local function try(name, fn, ...)
    27	    local ok, err = pcall(fn, ...)
    28	    check(name, ok, err)
    29	    return ok
    30	end
    31	
    32	-- ===================== shared state =====================
    33	unpack = unpack or table.unpack
    34	local T = 1000.0
    35	local allFrames = {}
    36	local state
    37	
    38	local function freshState()
    39	    state = {
    40	        class = "ROGUE", energy = 100, maxEnergy = 100, combo = 0,
    41	        hasTarget = true, targetDead = false, stealthed = false, combat = false,
    42	        casting = nil, notInt = false, mh = true, oh = true, ohEquipped = true,
    43	        usable = true, noMana = false,
    44	        auras = { player = {}, target = {} },
    45	        cooldowns = {}, -- spellName -> duration (absent = ready)
    46	        known = { Vanish = true, Evasion = true, Sprint = true, ["Slice and Dice"] = true },
    47	    }
    48	end
    49	
    50	-- only real TBC 2.5.x events the addon is allowed to register
    51	local VALID_EVENTS = {}
    52	for _, e in ipairs({
    53	    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED",
    54	    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UNIT_POWER_FREQUENT",
    55	    "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_AURA", "UNIT_INVENTORY_CHANGED",
    56	    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_START",
    57	    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTED", "UPDATE_STEALTH",
    58	    "SPELL_UPDATE_COOLDOWN", "SPELLS_CHANGED", "CHARACTER_POINTS_CHANGED",
    59	}) do VALID_EVENTS[e] = true end
    60	
    61	-- ===================== widget mock =====================
    62	-- __index is a METHOD TABLE: known methods resolve; any other key returns nil, so
    63	-- a typo'd method call errors ("attempt to call a nil value") and an unset DATA
    64	-- field reads as nil (correct boolean logic) — unlike a blanket no-op.
    65	local Wm = {}
    66	local function newW(kind, name)
    67	    return setmetatable({ __k = kind, _name = name, _shown = false, _ev = {}, _sc = {}, _w = 200 },
    68	        { __index = Wm })
    69	end
    70	function Wm.SetScript(s, e, fn) s._sc[e] = fn end
    71	function Wm.GetScript(s, e) return s._sc[e] end
    72	function Wm.HookScript(s, e, fn) s._sc[e] = fn end
    73	function Wm.RegisterEvent(s, e)
    74	    if not VALID_EVENTS[e] then error("registered unknown event: " .. tostring(e)) end
    75	    s._ev[e] = true
    76	end
    77	function Wm.RegisterUnitEvent(s, e)
    78	    if not VALID_EVENTS[e] then error("registered unknown event: " .. tostring(e)) end
    79	    s._ev[e] = true
    80	end
    81	function Wm.UnregisterEvent(s, e) s._ev[e] = nil end
    82	function Wm.Show(s) s._shown = true end
    83	function Wm.Hide(s) s._shown = false end
    84	function Wm.IsShown(s) return s._shown end
    85	function Wm.SetWidth(s, v) s._w = v end
    86	function Wm.GetWidth(s) return s._w end
    87	function Wm.GetName(s) return s._name end
    88	function Wm.GetID() return 1 end
    89	function Wm.GetPoint() return "CENTER", nil, "CENTER", 0, -180 end
    90	function Wm.CreateTexture() return newW("Texture") end
    91	function Wm.CreateFontString() return newW("FontString") end
    92	function Wm.CreateAnimationGroup() return newW("AnimGroup") end
    93	function Wm.CreateAnimation() return newW("Anim") end
    94	function Wm.SetText(s, t) s._text = t end
    95	function Wm.SetDesaturated(s, b) s._desat = b end
    96	function Wm.SetCooldown(s) s._cdActive = true end
    97	function Wm.Clear(s) s._cdActive = false end
    98	function Wm.GetChecked(s) return s._checked end
    99	function Wm.SetChecked(s, b) s._checked = b end
   100	function Wm.SetStatusBarColor(s, r, g, b) s._color = { r, g, b } end -- recorded for asserts
   101	function Wm.SetMinMaxValues(s, lo, hi) s._min = lo; s._max = hi end
   102	function Wm.SetValue(s, v) s._val = v end
   103	function Wm.SetPoint(s, p, rel, relP, x, y) s._point = { p, rel, relP, x, y } end
   104	-- remaining real methods: behaviorless no-ops (still allowlisted so typos error)
   105	for _, n in ipairs({ "SetAllPoints", "SetAlpha", "SetBlendMode", "SetColorTexture",
   106	    "SetDrawEdge", "SetDuration", "SetFromAlpha", "SetLooping", "SetMinMaxValues",
   107	    "SetMovable", "SetObeyStepOnDrag", "SetPoint", "SetScale", "SetShown", "SetSize",
   108	    "SetStatusBarColor", "SetStatusBarTexture", "SetTexCoord", "SetTextColor",
   109	    "SetTexture", "SetToAlpha", "SetValue", "SetValueStep", "SetVertexColor",
   110	    "RegisterForDrag", "ClearAllPoints", "StartMoving", "StopMovingOrSizing",
   111	    "Play", "Stop", "EnableMouse" }) do
   112	    Wm[n] = Wm[n] or function() end
   113	end
   114	
   115	function CreateFrame(kind, name)
   116	    local f = newW(kind or "Frame", name)
   117	    if name then _G[name] = f end
   118	    allFrames[#allFrames + 1] = f
   119	    return f
   120	end
   121	UIParent = newW("Frame", "UIParent")
   122	
   123	local function fire(ev, ...)
   124	    for _, f in ipairs(allFrames) do
   125	        if f._ev[ev] and f._sc.OnEvent then f._sc.OnEvent(f, ev, ...) end
   126	    end
   127	end
   128	local function tick(dt)
   129	    T = T + dt
   130	    for _, f in ipairs(allFrames) do
   131	        if f._sc.OnUpdate then f._sc.OnUpdate(f, dt) end
   132	    end
   133	end
   134	
   135	-- ===================== WoW global API mock =====================
   136	function GetTime() return T end
   137	function UnitClass() return "Rogue", state.class end
   138	function UnitExists(u) if u == "target" then return state.hasTarget end return true end
   139	function UnitIsDead() return state.targetDead end
   140	function UnitCanAttack() return true end
   141	function UnitPower() return state.energy end
   142	function UnitPowerMax() return state.maxEnergy end
   143	function GetComboPoints(unit, target)
   144	    if target ~= "target" then error("GetComboPoints needs ('player','target'), got " .. tostring(target)) end
   145	    return state.combo
   146	end
   147	function IsStealthed() return state.stealthed end
   148	function InCombatLockdown() return state.combat end
   149	function IsUsableSpell() return state.usable, state.noMana end
   150	function PlaySound() end
   151	function UnitCastingInfo()
   152	    if state.casting then return state.casting, nil, nil, nil, nil, nil, nil, state.notInt end
   153	end
   154	function UnitChannelInfo() return nil end
   155	function GetWeaponEnchantInfo() return state.mh, 0, 0, state.oh end
   156	function GetInventoryItemLink() return state.ohEquipped and "item:1" or nil end
   157	function GetSpellCooldown(name)
   158	    local cd = state.cooldowns[name]
   159	    if cd then return T - 1, cd, 1 end
   160	    return 0, 0, 1
   161	end
   162	function GetSpellTexture() return "Interface\\Icons\\x" end
   163	local spellNames = { [1856] = "Vanish", [5277] = "Evasion", [2983] = "Sprint",
   164	    [13877] = "Blade Flurry", [13750] = "Adrenaline Rush", [14177] = "Cold Blood",
   165	    [14185] = "Preparation", [1766] = "Kick" }
   166	function GetSpellInfo(id) return spellNames[id], nil, "tex" end
   167	function GetSpellName(i)
   168	    local list = {}
   169	    for k in pairs(state.known) do list[#list + 1] = k end
   170	    table.sort(list)
   171	    return list[i] -- nil past the end -> the addon's while-loop terminates
   172	end
   173	-- Filter-aware UnitAura: returns the i-th aura MATCHING the filter (like real WoW),
   174	-- and treats a pipe-separated filter as INVALID (returns nil) — so a regression to
   175	-- the old "HARMFUL|PLAYER" bug makes aura tests fail instead of silently passing.
   176	function UnitAura(unit, i, filter)
   177	    filter = filter or ""
   178	    if filter:find("|") then return nil end -- invalid filter token separator
   179	    local wantHarm = filter:find("HARMFUL") ~= nil
   180	    local wantHelp = filter:find("HELPFUL") ~= nil
   181	    local wantPlayer = filter:find("PLAYER") ~= nil
   182	    local list = {}
   183	    for _, a in ipairs(state.auras[unit] or {}) do
   184	        local typeOK = (not wantHarm and not wantHelp)
   185	            or (wantHarm and a.harmful) or (wantHelp and not a.harmful)
   186	        local playerOK = (not wantPlayer) or a.byPlayer
   187	        if typeOK and playerOK then list[#list + 1] = a end
   188	    end
   189	    local a = list[i]
   190	    if not a then return nil end
   191	    return a.name, nil, nil, nil, a.dur, a.exp
   192	end
   193	C_UnitAuras = nil
   194	BOOKTYPE_SPELL = "spell"
   195	Enum = { PowerType = { Energy = 3 } }
   196	SOUNDKIT = { RAID_WARNING = 8959 }
   197	SlashCmdList = {}
   198	function CopyTable(t)
   199	    local r = {}
   200	    for k, v in pairs(t) do r[k] = (type(v) == "table") and CopyTable(v) or v end
   201	    return r
   202	end
   203	function wipe(t) for k in pairs(t) do t[k] = nil end return t end
   204	C_AddOns = { GetAddOnMetadata = function() return "test" end }
   205	function GetAddOnMetadata() return "test" end
   206	function InterfaceOptions_AddCategory() end
   207	function InterfaceOptionsFrame_OpenToCategory() end
   208	Settings = nil
   209	
   210	-- ===================== scenario plumbing =====================
   211	local MODULES = { "core.lua", "hud.lua", "timers.lua", "cooldowns.lua",
   212	                  "alerts.lua", "options.lua", "config.lua" }
   213	local function resetWorld()
   214	    allFrames = {}
   215	    CutthroatDB = nil
   216	    SlashCmdList.CUTTHROAT = nil
   217	    local kill = {}
   218	    for k in pairs(_G) do if type(k) == "string" and k:find("^Cutthroat") then kill[#kill + 1] = k end end
   219	    for _, k in ipairs(kill) do _G[k] = nil end
   220	end
   221	local function loadAll(NS)
   222	    for _, f in ipairs(MODULES) do
   223	        local chunk, err = loadfile(f)
   224	        if not chunk then check("load " .. f, false, err)
   225	        else try("load " .. f, chunk, "Cutthroat", NS) end
   226	    end
   227	end
   228	local function iconByName(cds, n)
   229	    for _, f in ipairs(cds.icons or {}) do if f.spell and f.spell.name == n then return f end end
   230	end
   231	
   232	-- ===================== Scenario 1: rogue happy path =====================
   233	print("== Scenario: rogue ==")
   234	freshState()
   235	local NS = {}
   236	loadAll(NS)
   237	try("ADDON_LOADED", fire, "ADDON_LOADED", "Cutthroat")
   238	check("db populated", NS.db ~= nil and NS.db.scale == 1.0)
   239	try("PLAYER_LOGIN", fire, "PLAYER_LOGIN")
   240	check("hud inited", NS.modules.hud and NS.modules.hud.root ~= nil)
   241	check("timers inited", NS.modules.timers and NS.modules.timers.bars ~= nil)
   242	check("cooldowns inited", NS.modules.cooldowns and NS.modules.cooldowns.icons ~= nil)
   243	check("options inited", NS.modules.options and NS.modules.options.panel ~= nil)
   244	
   245	print("== gameplay ==")
   246	state.combo = 5; state.energy = 60
   247	try("power event", fire, "UNIT_POWER_FREQUENT", "player")
   248	state.auras.player[1] = { name = "Slice and Dice", dur = 21, exp = GetTime() + 10, harmful = false, byPlayer = true }
   249	state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 4, harmful = true, byPlayer = true }
   250	try("aura event", fire, "UNIT_AURA", "player")
   251	local renderOK = true
   252	for _ = 1, 20 do if not pcall(tick, 0.06) then renderOK = false end end
   253	check("render loop (20 frames) no error", renderOK)
   254	check("SnD bar shown while buffed", NS.modules.timers.bars.snd._shown)
   255	check("Rupture bar shown while debuffed", NS.modules.timers.bars.rup._shown)
   256	check("CP overcap glow shown at 5 CP", NS.modules.hud.cpGlow._shown)
   257	
   258	print("== cooldown desaturation ==")
   259	state.cooldowns.Vanish = 30
   260	try("SPELL_UPDATE_COOLDOWN", fire, "SPELL_UPDATE_COOLDOWN")
   261	local vanish = iconByName(NS.modules.cooldowns, "Vanish")
   262	check("Vanish icon exists (known spell)", vanish ~= nil)
   263	check("Vanish icon shown (known)", vanish and vanish:IsShown())
   264	check("Vanish texture desaturated while on CD", vanish and vanish.icon and vanish.icon._desat == true)
   265	local coldblood = iconByName(NS.modules.cooldowns, "Cold Blood")
   266	check("Cold Blood icon created but hidden (not known)", coldblood ~= nil and not coldblood:IsShown())
   267	
   268	print("== kick alert ==")
   269	state.casting = "Fireball"; state.notInt = false
   270	try("cast start", fire, "UNIT_SPELLCAST_START", "target")
   271	check("kick flash shown vs interruptible cast", NS.modules.alerts.kick._shown)
   272	state.casting = nil
   273	try("cast stop", fire, "UNIT_SPELLCAST_STOP", "target")
   274	check("kick flash hidden after cast", not NS.modules.alerts.kick._shown)
   275	
   276	print("== poison check (behavioral) ==")
   277	state.combat = false; state.mh = nil
   278	try("regen-enabled", fire, "PLAYER_REGEN_ENABLED")
   279	check("poison warning shown when MH unenchanted", NS.modules.alerts.poison._shown)
   280	check("poison text names Main-hand", NS.modules.alerts.poison._text and NS.modules.alerts.poison._text:find("Main"))
   281	
   282	print("== slash commands + db mutation ==")
   283	local slash = SlashCmdList["CUTTHROAT"]
   284	check("slash registered", type(slash) == "function")
   285	if slash then
   286	    for _, c in ipairs({ "", "help", "status", "lock", "scale 1.2", "scale 9",
   287	        "kick", "poison", "opener", "sound", "ticks", "spark", "zone", "smart",
   288	        "finish", "snd 4", "rup 3", "config", "options", "reset", "bogus" }) do
   289	        try("/cut " .. c, slash, c)
   290	    end
   291	    check("'/cut scale 1.2' set scale", NS.db.scale == 1.2)
   292	    check("'/cut scale 9' rejected (>3)", NS.db.scale == 1.2)
   293	    check("'/cut snd 4' set sndWarn", NS.db.sndWarn == 4)
   294	    check("'/cut kick' toggled kickAlert off", NS.db.kickAlert == false)
   295	end
   296	
   297	print("== regression: Kick negatives ==")
   298	-- the slash-command test above toggled several settings OFF; reset the ones these
   299	-- regression tests depend on so they exercise the real logic, not a disabled flag
   300	NS.db.kickAlert = true; NS.db.poisonCheck = true; NS.db.openerHint = true
   301	-- non-interruptible cast must NOT flash Kick
   302	NS.modules.alerts.kick:Hide()
   303	state.casting = "Polymorph"; state.notInt = true
   304	try("non-interruptible cast event", fire, "UNIT_SPELLCAST_START", "target")
   305	check("Kick does NOT flash on non-interruptible cast", not NS.modules.alerts.kick._shown)
   306	-- interruptible cast but Kick unusable (no energy) must NOT flash
   307	state.casting = "Fireball"; state.notInt = false; state.usable = false
   308	try("cast event w/ Kick unusable", fire, "UNIT_SPELLCAST_START", "target")
   309	check("Kick does NOT flash when unusable", not NS.modules.alerts.kick._shown)
   310	state.usable = true; state.casting = nil
   311	pcall(fire, "UNIT_SPELLCAST_STOP", "target")
   312	
   313	print("== regression: smart-refresh green gating ==")
   314	-- in the warn window WITH resources -> green; without CP -> not green
   315	local good = NS.color.good
   316	state.hasTarget = true; state.targetDead = false; state.energy = 60; state.combo = 5
   317	state.auras.target[1] = { name = "Rupture", dur = 16, exp = GetTime() + 1, harmful = true, byPlayer = true } -- rem ~1 <= ruptureWarn(2)
   318	NS.db.refreshZone = true; NS.db.smartRefresh = true
   319	pcall(fire, "UNIT_AURA", "target"); pcall(tick, 0.06)
   320	local rup = NS.modules.timers.bars.rup
   321	check("Rupture bar green in warn window w/ CP+energy",
   322	    rup._color and math.abs(rup._color[2] - good[2]) < 0.01)
   323	state.combo = 0 -- can't refresh -> must drop the green cue
   324	pcall(tick, 0.06)
   325	check("Rupture bar NOT green when 0 CP (can't refresh)",
   326	    rup._color and math.abs(rup._color[2] - good[2]) > 0.01)
   327	state.combo = 5
   328	
   329	print("== regression: misc behavior ==")
   330	-- poison: both weapons enchanted -> no warning
   331	state.combat = false; state.mh = true; state.oh = true
   332	pcall(fire, "PLAYER_REGEN_ENABLED")
   333	check("no poison warning when both weapons enchanted", not NS.modules.alerts.poison._shown)
   334	-- opener hint: stealth + hostile target shows; leaving stealth hides
   335	state.stealthed = true
   336	pcall(fire, "UPDATE_STEALTH")
   337	check("opener hint shown when stealthed w/ target", NS.modules.alerts.opener._shown)
   338	state.stealthed = false
   339	pcall(fire, "UPDATE_STEALTH")
   340	check("opener hint hidden when not stealthed", not NS.modules.alerts.opener._shown)
   341	-- energy spark hides at full energy
   342	state.energy = 100
   343	pcall(fire, "UNIT_POWER_FREQUENT", "player"); pcall(tick, 0.06)
   344	check("energy tick spark hidden at full energy", not NS.modules.hud.energy.spark._shown)
   345	
   346	print("== detarget clears glow ==")
   347	state.hasTarget = false; state.combo = 0
   348	pcall(tick, 0.06)
   349	check("CP glow clears on detarget", not NS.modules.hud.cpGlow._shown)
   350	
   351	-- ===================== Scenario 2: corrupt SavedVariables =====================
   352	print("== Scenario: corrupt SavedVariables ==")
   353	resetWorld()
   354	freshState()
   355	local NS2 = {}
   356	loadAll(NS2)
   357	CutthroatDB = { point = "not-a-table", scale = 999, kickAlert = false } -- garbage + a real pref
   358	try("ADDON_LOADED w/ corrupt DB", fire, "ADDON_LOADED", "Cutthroat")
   359	check("corrupt point reset to default table", type(NS2.db.point) == "table" and NS2.db.point[1] == "CENTER")
   360	check("out-of-range scale reset", NS2.db.scale == 1.0)
   361	check("valid user pref preserved", NS2.db.kickAlert == false)
   362	try("PLAYER_LOGIN w/ corrupt DB", fire, "PLAYER_LOGIN")
   363	check("hud inited despite corrupt DB", NS2.modules.hud and NS2.modules.hud.root ~= nil)
   364	
   365	-- ===================== Scenario 3: non-rogue =====================
   366	print("== Scenario: non-rogue ==")
   367	resetWorld()
   368	freshState()
   369	state.class = "WARRIOR"
   370	local NS3 = {}
   371	loadAll(NS3)
   372	try("non-rogue lifecycle", function() fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN") end)
   373	check("non-rogue HUD NOT inited", not (NS3.modules.hud and NS3.modules.hud.root))
   374	check("non-rogue options STILL inited", NS3.modules.options and NS3.modules.options.panel ~= nil)
   375	check("non-rogue slash works", type(SlashCmdList["CUTTHROAT"]) == "function")
   376	
   377	-- ===================== Scenario 4: deep behavior (locks past bugs) =====================
   378	print("== Scenario: deep behavior ==")
   379	resetWorld()
   380	freshState()
   381	local NS4 = {}
   382	loadAll(NS4)
   383	fire("ADDON_LOADED", "Cutthroat"); fire("PLAYER_LOGIN")
   384	local tmr = NS4.modules.timers
   385	
   386	print("== aura filter correctness (the iter-1 bug class) ==")
   387	-- our own SnD (HELPFUL) + our own Rupture (HARMFUL PLAYER) must be found
   388	state.auras.player = { { name = "Slice and Dice", dur = 21, exp = GetTime() + 10, harmful = false, byPlayer = true } }
   389	state.auras.target = { { name = "Rupture", dur = 16, exp = GetTime() + 8, harmful = true, byPlayer = true } }
   390	fire("UNIT_AURA", "player"); fire("UNIT_AURA", "target")
   391	check("SnD found via HELPFUL filter", tmr.cache.snd ~= nil)
   392	check("our Rupture found via HARMFUL PLAYER filter", tmr.cache.rup ~= nil)
   393	-- a Rupture cast by the TARGET (not the player) must be ignored by HARMFUL PLAYER
   394	state.auras.target = { { name = "Rupture", dur = 16, exp = GetTime() + 8, harmful = true, byPlayer = false } }
   395	fire("UNIT_AURA", "target")
   396	check("target-cast Rupture ignored (not byPlayer)", tmr.cache.rup == nil)
   397	
   398	print("== real-duration bar scaling + marker math ==")
   399	NS4.db.ruptureWarn = 2; NS4.db.refreshZone = true
   400	state.auras.target = { { name = "Rupture", dur = 16, exp = GetTime() + 4, harmful = true, byPlayer = true } }
   401	fire("UNIT_AURA", "target"); tick(0.06)
   402	local rupbar = tmr.bars.rup
   403	check("bar max == real aura duration (16)", rupbar._max == 16)
   404	check("marker at warnAt/dur*BAR_W (2/16*200=25)", rupbar.marker._point and math.abs(rupbar.marker._point[4] - 25) < 0.01)
   405	-- refresh with a SHORTER duration: bar must rescale (no stale maxSeen), marker moves
   406	state.auras.target = { { name = "Rupture", dur = 8, exp = GetTime() + 3, harmful = true, byPlayer = true } }
   407	fire("UNIT_AURA", "target"); tick(0.06)
   408	check("bar rescales to shorter duration (8)", rupbar._max == 8)
   409	check("marker moves on dur change (2/8*200=50)", rupbar.marker._point and math.abs(rupbar.marker._point[4] - 50) < 0.01)
   410	
   411	print("== self-calibrating energy tick interval ==")
   412	local hud = NS4.modules.hud
   413	state.energy = 20; hud:UpdatePower()               -- seed lastEnergy
   414	T = T + 1.0; state.energy = 40; hud:UpdatePower()  -- 1st tick: establishes lastTick (idle gap rejected)
   415	T = T + 1.0; state.energy = 60; hud:UpdatePower()  -- 2nd tick: 1.0s gap measured -> interval 1.0
   416	check("tickInterval calibrated to observed ~1.0s gap", math.abs(hud.tickInterval - 1.0) < 0.05)
   417	state.energy = 65; hud:UpdatePower()               -- +5 proc, same instant -> must be ignored
   418	check("small proc gain does not change tickInterval", math.abs(hud.tickInterval - 1.0) < 0.05)
   419	T = T + 2.0; state.energy = 85; hud:UpdatePower()  -- +20 at 2.0s gap -> recalibrate up
   420	check("tickInterval recalibrates to ~2.0s gap", math.abs(hud.tickInterval - 2.0) < 0.05)
   421	
   422	print("== cooldown one-shot OnUpdate self-cleanup ==")
   423	local cds = NS4.modules.cooldowns
   424	fire("SPELLS_CHANGED")
   425	check("layout OnUpdate installed + dirty after SPELLS_CHANGED",
   426	    cds.ev:GetScript("OnUpdate") ~= nil and cds.layoutDirty == true)
   427	tick(0.06)
   428	check("layout OnUpdate self-cleared + clean after flush",
   429	    cds.ev:GetScript("OnUpdate") == nil and cds.layoutDirty == false)
   430	
   431	print("== /reload double-init idempotency ==")
   432	local before = #allFrames
   433	local root1 = hud.root
   434	local ok_reinit = pcall(function() hud:Init(); tmr:Init(); cds:Init(); NS4.modules.alerts:Init() end)
   435	check("re-Init() does not error", ok_reinit)
   436	check("re-Init() creates no new frames (guarded)", #allFrames == before)
   437	check("re-Init() keeps same hud.root", hud.root == root1)
   438	
   439	-- ===================== summary =====================
   440	print(string.format("\n== RESULT: %d passed, %d failed ==", ok_count, fail_count))
   441	os.exit(fail_count == 0 and 0 or 1)

exec
/bin/zsh -lc 'nl -ba core.lua' in /Users/creative/WoWAddons/Cutthroat
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

exec
/bin/zsh -lc 'nl -ba hud.lua' in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc 'nl -ba timers.lua' in /Users/creative/WoWAddons/Cutthroat
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
/bin/zsh -lc 'nl -ba config.lua' in /Users/creative/WoWAddons/Cutthroat
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
I’ve read the implementation once through. I’m doing a second pass now for the three ship blockers only: API/runtime correctness, protected-action/automation risk, and whether a basic TBC rogue helper is missing something essential.
exec
/bin/zsh -lc "find . -name '*.lua' -print | xargs grep -nE 'GetSpellInfo|GetSpellName|UnitAura|C_UnitAuras|GetComboPoints|GetWeaponEnchantInfo|RegisterEvent|RegisterUnitEvent|OnUpdate|InCombatLockdown'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua:105:    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
./hud.lua:106:    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
./hud.lua:107:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./hud.lua:167:    local cp = UnitExists("target") and (GetComboPoints("player", "target") or 0) or 0
./test/run.lua:73:function Wm.RegisterEvent(s, e)
./test/run.lua:77:function Wm.RegisterUnitEvent(s, e)
./test/run.lua:131:        if f._sc.OnUpdate then f._sc.OnUpdate(f, dt) end
./test/run.lua:143:function GetComboPoints(unit, target)
./test/run.lua:144:    if target ~= "target" then error("GetComboPoints needs ('player','target'), got " .. tostring(target)) end
./test/run.lua:148:function InCombatLockdown() return state.combat end
./test/run.lua:155:function GetWeaponEnchantInfo() return state.mh, 0, 0, state.oh end
./test/run.lua:166:function GetSpellInfo(id) return spellNames[id], nil, "tex" end
./test/run.lua:167:function GetSpellName(i)
./test/run.lua:173:-- Filter-aware UnitAura: returns the i-th aura MATCHING the filter (like real WoW),
./test/run.lua:176:function UnitAura(unit, i, filter)
./test/run.lua:193:C_UnitAuras = nil
./test/run.lua:422:print("== cooldown one-shot OnUpdate self-cleanup ==")
./test/run.lua:425:check("layout OnUpdate installed + dirty after SPELLS_CHANGED",
./test/run.lua:426:    cds.ev:GetScript("OnUpdate") ~= nil and cds.layoutDirty == true)
./test/run.lua:428:check("layout OnUpdate self-cleared + clean after flush",
./test/run.lua:429:    cds.ev:GetScript("OnUpdate") == nil and cds.layoutDirty == false)
./timers.lua:34:        return e >= 25 and (GetComboPoints("player", "target") or 0) >= 1
./timers.lua:46:        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
./timers.lua:47:            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
./timers.lua:51:            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
./timers.lua:53:            local a = { UnitAura(unit, i, filter) }
./timers.lua:105:    -- Re-scan auras only when they CHANGE (event-driven). No per-frame UnitAura loops.
./timers.lua:107:    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
./timers.lua:108:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./timers.lua:112:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./timers.lua:113:    -- Use a PRIVATE frame, not hud.root, so a future module setting an OnUpdate on
./timers.lua:117:    self.renderFrame:SetScript("OnUpdate", function(_, dt)
./alerts.lua:9:local KICK = GetSpellInfo and GetSpellInfo(1766) or "Kick" -- localized name
./alerts.lua:61:    ev:RegisterEvent("UNIT_SPELLCAST_START")
./alerts.lua:62:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./alerts.lua:63:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./alerts.lua:64:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./alerts.lua:65:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./alerts.lua:66:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./alerts.lua:67:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./alerts.lua:68:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./alerts.lua:69:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
./alerts.lua:70:    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
./alerts.lua:71:    ev:RegisterEvent("UPDATE_STEALTH")
./alerts.lua:72:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./alerts.lua:117:    if InCombatLockdown() then return end -- only nag out of combat
./alerts.lua:119:    local mh, _, _, oh = GetWeaponEnchantInfo()
./cooldowns.lua:41:            local name, _, tex = GetSpellInfo(id)
./cooldowns.lua:71:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./cooldowns.lua:72:    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
./cooldowns.lua:73:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
./cooldowns.lua:74:    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
./cooldowns.lua:77:    -- OnUpdate that removes itself after running — no permanent per-frame loop.
./cooldowns.lua:79:        ev:SetScript("OnUpdate", nil)
./cooldowns.lua:89:            ev:SetScript("OnUpdate", flushLayout) -- fires once next frame, then clears
./cooldowns.lua:104:        local n = GetSpellName(i, BOOK)
./core.lua:44:f:RegisterEvent("ADDON_LOADED")
./core.lua:45:f:RegisterEvent("PLAYER_LOGIN")

exec
/bin/zsh -lc "find . -name '*.lua' -print | xargs grep -nE 'CastSpell|UseAction|RunMacro|Click|SetBinding|TargetUnit|Interact|Pickup|SpellStop|C_Timer|hooksecurefunc|SetAttribute|RegisterStateDriver|SecureAction|DoEmote|SendChatMessage|RunScript|loadstring'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./options.lua:42:        cb:SetScript("OnClick", function(b)

exec
/bin/zsh -lc 'nl -ba Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	## Interface: 20504
     2	## Title: Cutthroat |cff00ff96Rogue|r
     3	## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
     4	## Author: Cutthroat
     5	## Version: 1.7.0
     6	## SavedVariables: CutthroatDB
     7	## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate
     8	
     9	core.lua
    10	hud.lua
    11	timers.lua
    12	cooldowns.lua
    13	alerts.lua
    14	options.lua
    15	config.lua

exec
/bin/zsh -lc 'lua -v && lua test/run.lua' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
Lua 5.5.0  Copyright (C) 1994-2025 Lua.org, PUC-Rio
== Scenario: rogue ==
  ok   load core.lua
  ok   load hud.lua
  ok   load timers.lua
  ok   load cooldowns.lua
  ok   load alerts.lua
  ok   load options.lua
  ok   load config.lua
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
== cooldown desaturation ==
  ok   SPELL_UPDATE_COOLDOWN
  ok   Vanish icon exists (known spell)
  ok   Vanish icon shown (known)
  ok   Vanish texture desaturated while on CD
  ok   Cold Blood icon created but hidden (not known)
== kick alert ==
  ok   cast start
  ok   kick flash shown vs interruptible cast
  ok   cast stop
  ok   kick flash hidden after cast
== poison check (behavioral) ==
  ok   regen-enabled
  ok   poison warning shown when MH unenchanted
  ok   poison text names Main-hand
== slash commands + db mutation ==
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
  ok   '/cut scale 1.2' set scale
  ok   '/cut scale 9' rejected (>3)
  ok   '/cut snd 4' set sndWarn
  ok   '/cut kick' toggled kickAlert off
== regression: Kick negatives ==
  ok   non-interruptible cast event
  ok   Kick does NOT flash on non-interruptible cast
  ok   cast event w/ Kick unusable
  ok   Kick does NOT flash when unusable
== regression: smart-refresh green gating ==
  ok   Rupture bar green in warn window w/ CP+energy
  ok   Rupture bar NOT green when 0 CP (can't refresh)
== regression: misc behavior ==
  ok   no poison warning when both weapons enchanted
  ok   opener hint shown when stealthed w/ target
  ok   opener hint hidden when not stealthed
  ok   energy tick spark hidden at full energy
== detarget clears glow ==
  ok   CP glow clears on detarget
== Scenario: corrupt SavedVariables ==
  ok   load core.lua
  ok   load hud.lua
  ok   load timers.lua
  ok   load cooldowns.lua
  ok   load alerts.lua
  ok   load options.lua
  ok   load config.lua
  ok   ADDON_LOADED w/ corrupt DB
  ok   corrupt point reset to default table
  ok   out-of-range scale reset
  ok   valid user pref preserved
|cff00ff96Cutthroat|r vtest loaded. |cffffff00/cut|r for options.
  ok   PLAYER_LOGIN w/ corrupt DB
  ok   hud inited despite corrupt DB
== Scenario: non-rogue ==
  ok   load core.lua
  ok   load hud.lua
  ok   load timers.lua
  ok   load cooldowns.lua
  ok   load alerts.lua
  ok   load options.lua
  ok   load config.lua
|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.
|cff00ff96Cutthroat|r vtest loaded. |cffffff00/cut|r for options.
  ok   non-rogue lifecycle
  ok   non-rogue HUD NOT inited
  ok   non-rogue options STILL inited
  ok   non-rogue slash works
== Scenario: deep behavior ==
  ok   load core.lua
  ok   load hud.lua
  ok   load timers.lua
  ok   load cooldowns.lua
  ok   load alerts.lua
  ok   load options.lua
  ok   load config.lua
|cff00ff96Cutthroat|r vtest loaded. |cffffff00/cut|r for options.
== aura filter correctness (the iter-1 bug class) ==
  ok   SnD found via HELPFUL filter
  ok   our Rupture found via HARMFUL PLAYER filter
  ok   target-cast Rupture ignored (not byPlayer)
== real-duration bar scaling + marker math ==
  ok   bar max == real aura duration (16)
  ok   marker at warnAt/dur*BAR_W (2/16*200=25)
  ok   bar rescales to shorter duration (8)
  ok   marker moves on dur change (2/8*200=50)
== self-calibrating energy tick interval ==
  ok   tickInterval calibrated to observed ~1.0s gap
  ok   small proc gain does not change tickInterval
  ok   tickInterval recalibrates to ~2.0s gap
== cooldown one-shot OnUpdate self-cleanup ==
  ok   layout OnUpdate installed + dirty after SPELLS_CHANGED
  ok   layout OnUpdate self-cleared + clean after flush
== /reload double-init idempotency ==
  ok   re-Init() does not error
  ok   re-Init() creates no new frames (guarded)
  ok   re-Init() keeps same hud.root

== RESULT: 115 passed, 0 failed ==

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

**VERDICT: ONE REAL CORRECTNESS ISSUE — fix before public ship unless this addon is explicitly enUS-only.**

[timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:10) hard-codes English aura names:

`Slice and Dice`, `Rupture`, `Expose Armor`, `Garrote`

Then [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:57) compares those strings directly against `UnitAura`/`C_UnitAuras` aura names. On non-enUS clients, aura names are localized, so the core timer feature will fail to detect SnD/Rupture/Expose/Garrote.

Concrete fix: define timer spells by spell ID, resolve localized names with `GetSpellInfo` before scanning, and compare against those localized names. Minimal shape:

```lua
snd = { spellID = 5171, fallback = "Slice and Dice", isSelf = true, color = "good" }
rup = { spellID = 1943, fallback = "Rupture", isSelf = false, color = "bad" }
exp = { spellID = 8647, fallback = "Expose Armor", isSelf = false, color = "warn" }
gar = { spellID = 703, fallback = "Garrote", isSelf = false, color = "bad" }
```

Then set `track.name = GetSpellInfo(track.spellID) or track.fallback` before `GetAura` comparisons. Update `test/run.lua` with localized mock names so this cannot regress.

Ban-safety/Warden review: clean. I found no spell automation or protected-action calls; only frame/UI APIs, spell info/cooldown reads, aura reads, inventory enchant reads, slash/options state changes, and sounds.

I ran the headless suite here too: `115 passed, 0 failed`, but under local `Lua 5.5.0`, not Lua 5.1. Your CI’s real Lua 5.1 run remains the stronger signal.
tokens used
44,192
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

**VERDICT: ONE REAL CORRECTNESS ISSUE — fix before public ship unless this addon is explicitly enUS-only.**

[timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:10) hard-codes English aura names:

`Slice and Dice`, `Rupture`, `Expose Armor`, `Garrote`

Then [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:57) compares those strings directly against `UnitAura`/`C_UnitAuras` aura names. On non-enUS clients, aura names are localized, so the core timer feature will fail to detect SnD/Rupture/Expose/Garrote.

Concrete fix: define timer spells by spell ID, resolve localized names with `GetSpellInfo` before scanning, and compare against those localized names. Minimal shape:

```lua
snd = { spellID = 5171, fallback = "Slice and Dice", isSelf = true, color = "good" }
rup = { spellID = 1943, fallback = "Rupture", isSelf = false, color = "bad" }
exp = { spellID = 8647, fallback = "Expose Armor", isSelf = false, color = "warn" }
gar = { spellID = 703, fallback = "Garrote", isSelf = false, color = "bad" }
```

Then set `track.name = GetSpellInfo(track.spellID) or track.fallback` before `GetAura` comparisons. Update `test/run.lua` with localized mock names so this cannot regress.

Ban-safety/Warden review: clean. I found no spell automation or protected-action calls; only frame/UI APIs, spell info/cooldown reads, aura reads, inventory enchant reads, slash/options state changes, and sounds.

I ran the headless suite here too: `115 passed, 0 failed`, but under local `Lua 5.5.0`, not Lua 5.1. Your CI’s real Lua 5.1 run remains the stronger signal.
