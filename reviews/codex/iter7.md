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
session id: 019f099c-e39c-7792-9925-5d2b308aaed9
--------
user
HOLISTIC CROSS-MODULE AUDIT of this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. Read ALL files: core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc. Prior reviews each saw only one file; this is the first whole-addon review. Focus on INTEGRATION issues per-file reviews miss: (a) module init order + cross-module deps (timers/cooldowns/alerts anchor to NS.modules.hud.root; core inits hud first, rogue-only); (b) event-frame proliferation/leaks/duplicate registrations across modules; (c) multiple OnUpdate loops — timers:Render @0.05s calls hud UpdateCP/UpdatePower/UpdateEnergyTick, cooldowns has its own per-frame OnUpdate checking a dirty flag — redundant/wasteful?; (d) SavedVariables defaults merge + migration when keys added across versions; (e) taint/secure-frame (verify none); (f) /reload re-init safety; (g) NS.db/NS.IsRogue gating consistency; (h) dead code, unused locals, leaked globals (missing local); (i) shared-state hazards. Then give a SHIP-READINESS verdict + a concise IN-CLIENT SMOKE-TEST CHECKLIST for a human. Numbered: file, function, issue, concrete fix. Do NOT edit files. Real issues first.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll audit this read-only: first enumerate the addon files and then read each target module fully before forming integration findings. I’ll avoid edits and ground the review in exact file/function references.
exec
/bin/zsh -lc "pwd && rg --files -g 'core.lua' -g 'hud.lua' -g 'timers.lua' -g 'cooldowns.lua' -g 'alerts.lua' -g 'config.lua' -g 'Cutthroat.toc'" in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
/Users/creative/WoWAddons/Cutthroat
zsh:1: command not found: rg

exec
/bin/zsh -lc 'git status --short' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
?? reviews/codex/iter7.md
?? reviews/glm/iter7.md

codex
`rg` is not installed here, so I’m falling back to standard shell reads. The worktree has untracked review notes only; I’ll ignore them since this is a no-edit audit.
exec
/bin/zsh -lc "find . -maxdepth 2 \\( -name core.lua -o -name hud.lua -o -name timers.lua -o -name cooldowns.lua -o -name alerts.lua -o -name config.lua -o -name Cutthroat.toc \\) -print" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua
./Cutthroat.toc
./timers.lua
./alerts.lua
./config.lua
./cooldowns.lua
./core.lua

exec
/bin/zsh -lc 'wc -l core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
      90 core.lua
     182 hud.lua
     201 timers.lua
     147 cooldowns.lua
     148 alerts.lua
      82 config.lua
      14 Cutthroat.toc
     864 total

codex
All requested files are small enough to read completely. I’m pulling numbered listings now so the final review can cite concrete locations rather than broad module names.
exec
/bin/zsh -lc 'nl -ba hud.lua' in /Users/creative/WoWAddons/Cutthroat
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
    54	        NS.db = CutthroatDB
    55	    elseif event == "PLAYER_LOGIN" then
    56	        -- Explicit init order: hud first (timers/alerts anchor to hud.root),
    57	        -- config last. pairs() order is nondeterministic, so never rely on it here.
    58	        local function initModule(name)
    59	            local m = NS.modules[name]
    60	            if m and m.Init then m:Init() end
    61	        end
    62	        initModule("config") -- slash command / options work for everyone
    63	        if playerClass == "ROGUE" then
    64	            initModule("hud")
    65	            initModule("timers")
    66	            initModule("cooldowns")
    67	            initModule("alerts")
    68	            CallAll("Refresh")
    69	        else
    70	            print("|cff00ff96Cutthroat|r: not a rogue — HUD disabled. |cffffff00/cut|r still works.")
    71	        end
    72	        -- TBC 2.5.x exposes the global GetAddOnMetadata; C_AddOns is a newer wrapper.
    73	        local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
    74	            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
    75	            or "1.0.0"
    76	        print("|cff00ff96Cutthroat|r v" .. ver .. " loaded. |cffffff00/cut|r for options.")
    77	    end
    78	end)
    79	
    80	NS.IsRogue = (playerClass == "ROGUE")
    81	
    82	-- shared color helpers
    83	NS.color = {
    84	    energy  = { 1.0, 0.85, 0.20 },
    85	    cp      = { 1.0, 0.20, 0.20 },
    86	    good    = { 0.20, 1.0, 0.40 },
    87	    warn    = { 1.0, 0.55, 0.10 },
    88	    bad     = { 1.0, 0.15, 0.15 },
    89	    dim     = { 0.45, 0.45, 0.45 },
    90	}

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
    12	    local db = NS.db
    13	
    14	    -- root anchor (movable)
    15	    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
    16	    root:SetSize(WIDTH, HEIGHT + CP_SIZE + 8)
    17	    root:SetScale(db.scale)
    18	    local p = db.point
    19	    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
    20	    root:SetMovable(true)
    21	    root:EnableMouse(not db.locked)
    22	    root:RegisterForDrag("LeftButton")
    23	    root:SetScript("OnDragStart", function(s) if not NS.db.locked then s:StartMoving() end end)
    24	    root:SetScript("OnDragStop", function(s)
    25	        s:StopMovingOrSizing()
    26	        local a, _, rp, x, y = s:GetPoint()
    27	        NS.db.point = { a, nil, rp, x, y }
    28	    end)
    29	    self.root = root
    30	
    31	    -- drag hint backdrop (only when unlocked)
    32	    root.bg = root:CreateTexture(nil, "BACKGROUND")
    33	    root.bg:SetAllPoints()
    34	    root.bg:SetColorTexture(0, 0, 0, 0.25)
    35	
    36	    -- ---- Energy bar ----
    37	    local energy = CreateFrame("StatusBar", nil, root)
    38	    energy:SetSize(WIDTH, HEIGHT)
    39	    energy:SetPoint("TOP", root, "TOP", 0, 0)
    40	    energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    41	    energy:SetStatusBarColor(unpack(NS.color.energy))
    42	    energy:SetMinMaxValues(0, 100)
    43	    energy.bg = energy:CreateTexture(nil, "BACKGROUND")
    44	    energy.bg:SetAllPoints()
    45	    energy.bg:SetColorTexture(0.12, 0.10, 0.0, 0.85)
    46	    energy.text = energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    47	    energy.text:SetPoint("CENTER")
    48	    self.energy = energy
    49	
    50	    -- 20-energy tick marks
    51	    energy.ticks = {}
    52	    if db.energyTicks then
    53	        for i = 1, 4 do
    54	            local t = energy:CreateTexture(nil, "OVERLAY")
    55	            t:SetColorTexture(0, 0, 0, 0.6)
    56	            t:SetSize(1, HEIGHT)
    57	            t:SetPoint("LEFT", energy, "LEFT", WIDTH * (i * 20 / 100), 0)
    58	            energy.ticks[i] = t
    59	        end
    60	    end
    61	
    62	    -- energy regen-tick spark: a thin marker sweeping the bar 0->100% over the
    63	    -- ~2s regen cycle, reset whenever energy is observed to gain. Helps pooling.
    64	    energy.spark = energy:CreateTexture(nil, "OVERLAY")
    65	    energy.spark:SetColorTexture(1, 1, 1, 0.85)
    66	    energy.spark:SetWidth(2)
    67	    energy.spark:SetPoint("TOP", energy, "TOPLEFT", 0, 0)
    68	    energy.spark:SetPoint("BOTTOM", energy, "BOTTOMLEFT", 0, 0)
    69	    energy.spark:Hide()
    70	    self.lastEnergy = nil
    71	    self.energyMax = 100
    72	    self.lastTick = 0
    73	    self.tickInterval = 2.0 -- self-calibrated from observed tick gaps
    74	
    75	    -- ---- Combo point pips ----
    76	    self.pips = {}
    77	    local totalW = MAX_CP * CP_SIZE + (MAX_CP - 1) * CP_GAP
    78	    local startX = (WIDTH - totalW) / 2
    79	    for i = 1, MAX_CP do
    80	        local pip = root:CreateTexture(nil, "ARTWORK")
    81	        pip:SetSize(CP_SIZE, CP_SIZE)
    82	        pip:SetPoint("TOPLEFT", root, "TOPLEFT", startX + (i - 1) * (CP_SIZE + CP_GAP), -(HEIGHT + 6))
    83	        pip:SetTexture("Interface\\ComboFrame\\ComboPoint")
    84	        pip:SetTexCoord(0, 0.375, 0, 1) -- the lit gem
    85	        pip:SetVertexColor(unpack(NS.color.cp))
    86	        pip:SetAlpha(0.15)
    87	        self.pips[i] = pip
    88	    end
    89	
    90	    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
    91	    -- spend them instead of overcapping (building past 5 CP is wasted generation).
    92	    self.cpGlow = root:CreateTexture(nil, "BACKGROUND")
    93	    self.cpGlow:SetPoint("TOPLEFT", self.pips[1], "TOPLEFT", -3, 3)
    94	    self.cpGlow:SetPoint("BOTTOMRIGHT", self.pips[MAX_CP], "BOTTOMRIGHT", 3, -3)
    95	    self.cpGlow:SetColorTexture(1, 0.82, 0, 1)
    96	    self.cpGlow:SetBlendMode("ADD") -- additive => soft glow, not a harsh solid box
    97	    self.cpGlow:Hide()
    98	
    99	    -- Event-driven power updates, all unit-filtered to "player" so other units'
   100	    -- power changes never wake this handler. Combo points have no reliable
   101	    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
   102	    -- and registering a wrong event name errors) — they're polled in timers:Tick.
   103	    local ev = CreateFrame("Frame")
   104	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
   105	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
   106	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
   107	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
   108	    self.ev = ev
   109	end
   110	
   111	function HUD:UpdatePower()
   112	    if not self.energy then return end
   113	    local e = UnitPower("player", ENERGY)
   114	    local m = UnitPowerMax("player", ENERGY)
   115	    self.energyMax = (m and m > 0) and m or 100
   116	    self.energy:SetMinMaxValues(0, self.energyMax)
   117	    self.energy:SetValue(e)
   118	    self.energy.text:SetText(e)
   119	
   120	    if self.lastEnergy == nil then self.lastEnergy = e; return end
   121	    -- A regen tick lands as a sizable positive delta. Small proc gains (Combat
   122	    -- Potency etc.) are ignored with the >=10 filter so they don't yank the spark.
   123	    -- We MEASURE the real tick cadence from gap to gap (clamped) instead of assuming
   124	    -- 2.0s — GLM and Codex disagreed on whether Adrenaline Rush changes the tick
   125	    -- interval or the per-tick amount, so measuring sidesteps the unresolved question.
   126	    if e > self.lastEnergy and (e - self.lastEnergy) >= 10 then
   127	        local now = GetTime()
   128	        local gap = now - (self.lastTick or now)
   129	        if gap >= 0.8 and gap <= 2.2 then self.tickInterval = gap end
   130	        self.lastTick = now
   131	    end
   132	    self.lastEnergy = e
   133	end
   134	
   135	-- Move the regen-tick spark; called every render frame from timers:Render.
   136	function HUD:UpdateEnergyTick()
   137	    local s = self.energy and self.energy.spark
   138	    if not s then return end
   139	    -- hide when disabled or at full energy (no tick to wait for)
   140	    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
   141	        s:Hide(); return
   142	    end
   143	    local interval = self.tickInterval or 2.0
   144	    local frac = (GetTime() - (self.lastTick or 0)) / interval
   145	    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
   146	    local w = self.energy:GetWidth()
   147	    local sw = s:GetWidth() or 2
   148	    local x = frac * w
   149	    if x > w - sw then x = w - sw end  -- keep the full 2px spark inside the bar
   150	    if x < 0 then x = 0 end
   151	    s:ClearAllPoints()
   152	    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
   153	    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
   154	    s:Show()
   155	end
   156	
   157	function HUD:UpdateCP()
   158	    -- guard on a live target so the glow can't linger after detarget
   159	    local cp = UnitExists("target") and (GetComboPoints("player", "target") or 0) or 0
   160	    for i = 1, MAX_CP do
   161	        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
   162	    end
   163	    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
   164	    local g = self.cpGlow
   165	    if g then
   166	        if cp >= MAX_CP and NS.db.cpFinishGlow then
   167	            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
   168	            if not g:IsShown() then g:Show() end
   169	        elseif g:IsShown() then
   170	            g:Hide()
   171	        end
   172	    end
   173	end
   174	
   175	function HUD:Refresh()
   176	    if not self.root then return end
   177	    self.root:SetScale(NS.db.scale)
   178	    self.root:EnableMouse(not NS.db.locked)
   179	    self.root.bg:SetShown(not NS.db.locked)
   180	    self:UpdatePower()
   181	    self:UpdateCP()
   182	end

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
    29	    local root = NS.modules.hud.root
    30	    self.icons = {}
    31	    self.known = {}
    32	    self.layoutDirty = false
    33	
    34	    -- de-dupe the id list (guard against typos above) and resolve names/textures
    35	    local seen = {}
    36	    self.spells = {}
    37	    for _, id in ipairs(SPELL_IDS) do
    38	        if not seen[id] then
    39	            seen[id] = true
    40	            local name, _, tex = GetSpellInfo(id)
    41	            if name then
    42	                self.spells[#self.spells + 1] = { id = id, name = name, tex = tex }
    43	            end
    44	        end
    45	    end
    46	
    47	    -- anchor below the timer bars. Bar 1 top = -56; 4 bars at 14h/3gap → last bar
    48	    -- bottom = -121. Icons are CENTER-anchored, so drop a full ICON/2 + gap below
    49	    -- that to avoid clipping the bottom bar (caught by Codex: was overlapping ~4px).
    50	    local timerBottom = -(18 + 6 + 22 + 10) - (3 * 17) - 14  -- -121
    51	    local rowY = timerBottom - 8 - ICON / 2                   -- -144
    52	
    53	    for i, s in ipairs(self.spells) do
    54	        local f = CreateFrame("Frame", nil, root)
    55	        f:SetSize(ICON, ICON)
    56	        f.icon = f:CreateTexture(nil, "ARTWORK")
    57	        f.icon:SetAllPoints()
    58	        f.icon:SetTexture(s.tex or GetSpellTexture(s.id))
    59	        f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    60	        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    61	        f.cd:SetAllPoints()
    62	        if f.cd.SetDrawEdge then f.cd:SetDrawEdge(true) end
    63	        f.spell = s
    64	        f:Hide()
    65	        self.icons[i] = f
    66	    end
    67	    self.rowY = rowY
    68	
    69	    local ev = CreateFrame("Frame")
    70	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    71	    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
    72	    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
    73	    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
    74	    -- unknown event hard-errors and would break load. The two above cover respec.
    75	    ev:SetScript("OnEvent", function(_, e)
    76	        if e == "SPELL_UPDATE_COOLDOWN" then
    77	            self:UpdateCooldowns()
    78	        else
    79	            self.layoutDirty = true -- SPELLS_CHANGED fires aggressively; coalesce
    80	        end
    81	    end)
    82	    -- coalesce bursty layout-affecting events into one rebuild per frame
    83	    ev:SetScript("OnUpdate", function()
    84	        if self.layoutDirty then
    85	            self.layoutDirty = false
    86	            self:RebuildKnown()
    87	            self:Relayout()
    88	        end
    89	    end)
    90	    self.ev = ev
    91	
    92	    self:RebuildKnown()
    93	    self:Relayout()
    94	end
    95	
    96	-- Cache the set of spells the player actually knows (by localized name).
    97	function CDs:RebuildKnown()
    98	    if not self.known then return end
    99	    wipe(self.known)
   100	    local i = 1
   101	    while true do
   102	        local n = GetSpellName(i, BOOK)
   103	        if not n then break end
   104	        self.known[n] = true
   105	        i = i + 1
   106	    end
   107	end
   108	
   109	-- Show only known spells, packed left-to-right and centered under the HUD.
   110	function CDs:Relayout()
   111	    if not self.icons then return end
   112	    local root = NS.modules.hud.root
   113	    local shown = {}
   114	    for _, f in ipairs(self.icons) do
   115	        if self.known[f.spell.name] then shown[#shown + 1] = f else f:Hide() end
   116	    end
   117	    local n = #shown
   118	    local totalW = n * ICON + (n - 1) * GAP
   119	    local startX = -totalW / 2 + ICON / 2
   120	    for i, f in ipairs(shown) do
   121	        f:ClearAllPoints()
   122	        f:SetPoint("CENTER", root, "TOP", startX + (i - 1) * (ICON + GAP), self.rowY)
   123	        f:Show()
   124	    end
   125	    self:UpdateCooldowns()
   126	end
   127	
   128	function CDs:UpdateCooldowns()
   129	    if not self.icons then return end
   130	    for _, f in ipairs(self.icons) do
   131	        if f:IsShown() then
   132	            local start, dur, enabled = GetSpellCooldown(f.spell.name)
   133	            -- dur > 2 ignores the ~1s GCD sweep; all tracked CDs are far above it
   134	            if start and dur and dur > 2 and enabled ~= 0 then
   135	                f.cd:SetCooldown(start, dur)
   136	                f.icon:SetDesaturated(true)
   137	            else
   138	                f.cd:Clear()
   139	                f.icon:SetDesaturated(false)
   140	            end
   141	        end
   142	    end
   143	end
   144	
   145	function CDs:Refresh()
   146	    if self.icons then self:RebuildKnown(); self:Relayout() end
   147	end

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
    24	    print("  |cffffff00/cut reset|r        reset position")
    25	    print("  |cffffff00/cut status|r       show settings")
    26	end
    27	
    28	function Config:Init()
    29	    SLASH_CUTTHROAT1 = "/cut"
    30	    SLASH_CUTTHROAT2 = "/cutthroat"
    31	    SlashCmdList["CUTTHROAT"] = function(msg)
    32	        local db = NS.db
    33	        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    34	        cmd = (cmd or ""):lower()
    35	
    36	        if cmd == "" or cmd == "help" then
    37	            Help()
    38	        elseif cmd == "lock" then
    39	            db.locked = not db.locked
    40	            Print("HUD " .. (db.locked and "locked" or "unlocked — drag the box"))
    41	        elseif cmd == "scale" then
    42	            local n = tonumber(arg)
    43	            if n and n >= 0.4 and n <= 3 then db.scale = n; Print("scale " .. n)
    44	            else Print("scale needs 0.4-3.0") end
    45	        elseif cmd == "kick" then
    46	            db.kickAlert = not db.kickAlert; Print("Kick reminder " .. on(db.kickAlert))
    47	        elseif cmd == "poison" then
    48	            db.poisonCheck = not db.poisonCheck; Print("poison check " .. on(db.poisonCheck))
    49	        elseif cmd == "opener" then
    50	            db.openerHint = not db.openerHint; Print("opener hint " .. on(db.openerHint))
    51	        elseif cmd == "sound" then
    52	            db.sound = not db.sound; Print("alert sound " .. on(db.sound))
    53	        elseif cmd == "ticks" then
    54	            db.energyTicks = not db.energyTicks; Print("energy ticks " .. on(db.energyTicks) .. " (/reload to apply)")
    55	        elseif cmd == "spark" then
    56	            db.tickSpark = not db.tickSpark; Print("regen-tick spark " .. on(db.tickSpark))
    57	        elseif cmd == "zone" then
    58	            db.refreshZone = not db.refreshZone; Print("refresh marker " .. on(db.refreshZone))
    59	        elseif cmd == "smart" then
    60	            db.smartRefresh = not db.smartRefresh; Print("smart refresh (CP/energy-gated) " .. on(db.smartRefresh))
    61	        elseif cmd == "finish" then
    62	            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
    63	        elseif cmd == "snd" then
    64	            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
    65	        elseif cmd == "rup" then
    66	            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
    67	        elseif cmd == "reset" then
    68	            db.point = { "CENTER", nil, "CENTER", 0, -180 }
    69	            Print("position reset (/reload to apply)")
    70	        elseif cmd == "status" then
    71	            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s",
    72	                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound)))
    73	            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
    74	                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
    75	        else
    76	            Help()
    77	        end
    78	        NS.CallAll("Refresh")
    79	    end
    80	end
    81	
    82	function Config:Refresh() end

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
    16	    rnd = { name = "Rend",           isSelf = false, color = "warn" }, -- harmless if unused
    17	}
    18	
    19	local BAR_W, BAR_H = 200, 14
    20	local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
    21	
    22	-- Can the player actually refresh this aura right now? Used to gate the green
    23	-- "refresh-now" cue so it never implies an action you lack resources for.
    24	-- Finisher cost is 25 energy; SnD needs only energy, Rupture/Expose also need CP.
    25	local function HasRefreshResources(key)
    26	    local e = UnitPower("player", ENERGY)
    27	    if key == "snd" then
    28	        return e >= 25 -- self-buff, only needs energy
    29	    elseif key == "rup" or key == "exp" then
    30	        -- finishers: need a live attackable target AND energy AND a combo point
    31	        if not UnitExists("target") or UnitIsDead("target")
    32	            or not UnitCanAttack("player", "target") then
    33	            return false
    34	        end
    35	        return e >= 25 and (GetComboPoints("player", "target") or 0) >= 1
    36	    end
    37	    return false -- Garrote: stealth-only, can't refresh in combat -> never cue green
    38	end
    39	
    40	local function GetAura(unit, name, byPlayer)
    41	    -- WoW aura filters are SPACE-separated tokens, not pipe-separated.
    42	    -- byPlayer=true  -> our debuff on the target ("HARMFUL PLAYER")
    43	    -- byPlayer=false -> our self buff like Slice and Dice ("HELPFUL")
    44	    local filter = byPlayer and "HARMFUL PLAYER" or "HELPFUL"
    45	    for i = 1, 40 do
    46	        local n, dur, exp
    47	        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    48	            local d = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    49	            if not d then break end
    50	            n, dur, exp = d.name, d.duration, d.expirationTime
    51	        else
    52	            -- UnitAura: name(1) icon count debuffType duration(5) expirationTime(6) ...
    53	            local dur2, exp2
    54	            n, _, _, _, dur2, exp2 = UnitAura(unit, i, filter)
    55	            if not n then break end
    56	            dur, exp = dur2, exp2
    57	        end
    58	        if n == name and exp and exp > 0 then
    59	            return exp, dur   -- absolute expiration time + full duration
    60	        end
    61	    end
    62	    return nil
    63	end
    64	
    65	-- where each tracked aura lives
    66	local SOURCE = {
    67	    snd = { unit = "player", byPlayer = false },
    68	    rup = { unit = "target", byPlayer = true  },
    69	    exp = { unit = "target", byPlayer = true  },
    70	    gar = { unit = "target", byPlayer = true  },
    71	}
    72	
    73	function Timers:Init()
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
   113	    self.elapsed = 0
   114	    root:SetScript("OnUpdate", function(_, dt)
   115	        self.elapsed = self.elapsed + dt
   116	        if self.elapsed < 0.05 then return end
   117	        self.elapsed = 0
   118	        self:Render()
   119	    end)
   120	    self:Scan()
   121	end
   122	
   123	-- Refresh the aura cache from the game (only on aura/target change events).
   124	function Timers:Scan()
   125	    if not NS.IsRogue or not self.cache then return end
   126	    local hasTarget = UnitExists("target") and not UnitIsDead("target")
   127	    for key, src in pairs(SOURCE) do
   128	        local exp, dur
   129	        if src.unit == "player" or hasTarget then
   130	            exp, dur = GetAura(src.unit, TRACK[key].name, src.byPlayer)
   131	        end
   132	        self.cache[key] = exp and { exp = exp, dur = dur } or nil
   133	    end
   134	end
   135	
   136	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
   137	function Timers:Render()
   138	    if not NS.IsRogue then return end
   139	    NS.modules.hud:UpdateCP()
   140	    NS.modules.hud:UpdatePower()
   141	    NS.modules.hud:UpdateEnergyTick()
   142	
   143	    local now = GetTime()
   144	    for key, b in pairs(self.bars) do
   145	        local c = self.cache[key]
   146	        local rem = c and (c.exp - now) or 0
   147	        if not c or rem <= 0 then
   148	            self.cache[key] = nil
   149	            if b:IsShown() then
   150	                b:Hide(); b.marker:Hide()
   151	                b.inZone = nil; b.greenState = nil; b.markerDur = nil
   152	            end
   153	        else
   154	            local warnAt = (key == "snd" and NS.db.sndWarn)
   155	                or (key == "rup" and NS.db.ruptureWarn) or 2
   156	            local dur = (c.dur and c.dur > 0) and c.dur or rem
   157	            b:SetMinMaxValues(0, dur)  -- real aura duration, bar never lies on refresh
   158	            b:SetValue(rem)
   159	            b.time:SetText(string.format("%.1f", rem))
   160	
   161	            -- refresh-now marker: the fill's right edge crosses it at rem==warnAt.
   162	            -- Reposition only when the duration changes (per new cast), not per frame.
   163	            if NS.db.refreshZone then
   164	                if b.markerDur ~= dur then
   165	                    b.markerDur = dur
   166	                    local frac = warnAt / dur
   167	                    if frac > 1 then frac = 1 elseif frac < 0 then frac = 0 end
   168	                    b.marker:ClearAllPoints()
   169	                    b.marker:SetPoint("CENTER", b, "LEFT", frac * BAR_W, 0) -- centered on edge
   170	                end
   171	                if not b.marker:IsShown() then b.marker:Show() end
   172	            elseif b.marker:IsShown() then
   173	                b.marker:Hide()
   174	            end
   175	
   176	            -- color state machine: only call Set*Color on a transition (avoids ~20
   177	            -- redundant C calls/sec/bar). label flash + entry sound gated by inZone;
   178	            -- fill-green gated separately so /cut zone toggles live and restores base.
   179	            local want = rem <= warnAt
   180	            if want ~= b.inZone then
   181	                b.inZone = want
   182	                b.label:SetTextColor(want and NS.color.bad[1] or 1,
   183	                                     want and NS.color.bad[2] or 1,
   184	                                     want and NS.color.bad[3] or 1)
   185	                if want and NS.db.sound then
   186	                    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
   187	                end
   188	            end
   189	            local green = want and NS.db.refreshZone
   190	            if green and NS.db.smartRefresh then green = HasRefreshResources(key) end
   191	            if green ~= b.greenState then
   192	                b.greenState = green
   193	                b:SetStatusBarColor(unpack(green and NS.color.good or b.baseColor))
   194	            end
   195	
   196	            if not b:IsShown() then b:Show() end
   197	        end
   198	    end
   199	end
   200	
   201	function Timers:Refresh() if self.cache then self:Scan() end end

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
    22	    local root = NS.modules.hud.root
    23	
    24	    -- ---- Kick flash icon (center, above HUD) ----
    25	    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
    26	    kick:SetSize(64, 64)
    27	    kick:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    28	    kick.icon = kick:CreateTexture(nil, "ARTWORK")
    29	    kick.icon:SetAllPoints()
    30	    kick.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    31	    kick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    32	    kick.txt = kick:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    33	    kick.txt:SetPoint("TOP", kick, "BOTTOM", 0, -2)
    34	    kick.txt:SetText("KICK!")
    35	    kick.txt:SetTextColor(unpack(NS.color.bad))
    36	    kick:Hide()
    37	    -- pulse
    38	    local ag = kick:CreateAnimationGroup()
    39	    ag:SetLooping("BOUNCE")
    40	    local a = ag:CreateAnimation("Alpha")
    41	    a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.35)
    42	    kick.ag = ag
    43	    self.kick = kick
    44	
    45	    -- ---- Poison reminder text ----
    46	    local pz = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    47	    pz:SetPoint("BOTTOM", root, "TOP", 0, 6)
    48	    pz:SetTextColor(unpack(NS.color.warn))
    49	    pz:Hide()
    50	    self.poison = pz
    51	
    52	    -- ---- Stealth opener hint ----
    53	    local op = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    54	    op:SetPoint("BOTTOM", root, "TOP", 0, 28)
    55	    op:SetTextColor(unpack(NS.color.good))
    56	    op:Hide()
    57	    self.opener = op
    58	
    59	    local ev = CreateFrame("Frame")
    60	    ev:RegisterEvent("UNIT_SPELLCAST_START")
    61	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    62	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
    63	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    64	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    65	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    66	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
    67	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
    68	    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
    69	    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
    70	    ev:RegisterEvent("UPDATE_STEALTH")
    71	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    72	    ev:SetScript("OnEvent", function(_, e, unit) Alerts:OnEvent(e, unit) end)
    73	    self.ev = ev
    74	end
    75	
    76	function Alerts:OnEvent(e, unit)
    77	    if not NS.IsRogue then return end
    78	    if e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_ENTERING_WORLD" or e == "UNIT_INVENTORY_CHANGED" then
    79	        self:CheckPoison()
    80	    elseif e == "PLAYER_REGEN_DISABLED" then
    81	        self.poison:Hide()
    82	    end
    83	    if e == "UPDATE_STEALTH" or e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_ENTERING_WORLD" then
    84	        self:CheckOpener()
    85	    end
    86	    -- Kick logic on any cast event affecting the target
    87	    self:CheckKick(e, unit)
    88	end
    89	
    90	function Alerts:CheckKick(e, unit)
    91	    if not NS.db.kickAlert then return end
    92	    if unit ~= "target" then
    93	        -- still re-evaluate on target change / cooldown updates
    94	        if e ~= "PLAYER_TARGET_CHANGED" and e ~= "SPELL_UPDATE_COOLDOWN" then return end
    95	    end
    96	    local casting = false
    97	    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    98	    if not name then
    99	        name, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
   100	    end
   101	    if name and not notInterruptible then casting = true end
   102	
   103	    if casting and SpellReady(KICK) then
   104	        if not self.kick:IsShown() then
   105	            self.kick:Show()
   106	            self.kick.ag:Stop(); self.kick.ag:Play() -- reset loop state cleanly
   107	            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
   108	        end
   109	    else
   110	        if self.kick:IsShown() then self.kick.ag:Stop(); self.kick:Hide() end
   111	    end
   112	end
   113	
   114	function Alerts:CheckPoison()
   115	    if not NS.db.poisonCheck then self.poison:Hide(); return end
   116	    if InCombatLockdown() then return end -- only nag out of combat
   117	    -- TBC 2.5 sig: hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges (no enchantID)
   118	    local mh, _, _, oh = GetWeaponEnchantInfo()
   119	    local missing = {}
   120	    if not mh then missing[#missing + 1] = "Main-hand" end
   121	    -- only warn off-hand if one is equipped
   122	    if GetInventoryItemLink("player", 17) and not oh then missing[#missing + 1] = "Off-hand" end
   123	    if #missing > 0 then
   124	        self.poison:SetText("No poison: " .. table.concat(missing, " & "))
   125	        self.poison:Show()
   126	    else
   127	        self.poison:Hide()
   128	    end
   129	end
   130	
   131	function Alerts:CheckOpener()
   132	    if not NS.db.openerHint then self.opener:Hide(); return end
   133	    local stealthed = IsStealthed and IsStealthed()
   134	    if stealthed and UnitExists("target") and UnitCanAttack("player", "target") then
   135	        self.opener:SetText("Opener: Ambush / Garrote")
   136	        self.opener:Show()
   137	    else
   138	        self.opener:Hide()
   139	    end
   140	end
   141	
   142	function Alerts:Refresh()
   143	    if self.kick then self.kick:Hide() end
   144	    if NS.IsRogue then
   145	        self:CheckPoison()  -- hides itself if disabled / in combat
   146	        self:CheckOpener()  -- hides itself if disabled
   147	    end
   148	end

exec
/bin/zsh -lc 'nl -ba Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
     1	## Interface: 20504
     2	## Title: Cutthroat |cff00ff96Rogue|r
     3	## Notes: Rogue HUD + combat alerts for TBC Classic. Energy, combo points, SnD/Rupture timers, Kick reminder, poison check. Alerts only — no automation.
     4	## Author: Cutthroat
     5	## Version: 1.6.0
     6	## SavedVariables: CutthroatDB
     7	## IconTexture: Interface\Icons\Ability_Rogue_Eviscerate
     8	
     9	core.lua
    10	hud.lua
    11	timers.lua
    12	cooldowns.lua
    13	alerts.lua
    14	config.lua

codex
The first integration pass shows the load path is mostly deliberate: TOC loads `core.lua` before modules, modules register at file load, and `PLAYER_LOGIN` initializes rogue modules after SavedVariables are assigned. I’m checking the remaining cross-module edges now: slash refresh behavior, duplicate events, and stale UI state after config toggles.
exec
/bin/zsh -lc "grep -RIn \"RegisterEvent\\|RegisterUnitEvent\\|SetScript(\\\"OnUpdate\\|function [A-Za-z_]\\|"'^[A-Za-z_][A-Za-z0-9_]* =" core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
core.lua:30:function NS:RegisterModule(name, mod)
core.lua:35:local function CallAll(method, ...)
core.lua:44:f:RegisterEvent("ADDON_LOADED")
core.lua:45:f:RegisterEvent("PLAYER_LOGIN")
core.lua:58:        local function initModule(name)
hud.lua:11:function HUD:Init()
hud.lua:104:    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
hud.lua:105:    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
hud.lua:106:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
hud.lua:111:function HUD:UpdatePower()
hud.lua:136:function HUD:UpdateEnergyTick()
hud.lua:157:function HUD:UpdateCP()
hud.lua:175:function HUD:Refresh()
timers.lua:25:local function HasRefreshResources(key)
timers.lua:40:local function GetAura(unit, name, byPlayer)
timers.lua:73:function Timers:Init()
timers.lua:107:    scan:RegisterUnitEvent("UNIT_AURA", "player", "target")
timers.lua:108:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
timers.lua:114:    root:SetScript("OnUpdate", function(_, dt)
timers.lua:124:function Timers:Scan()
timers.lua:137:function Timers:Render()
timers.lua:201:function Timers:Refresh() if self.cache then self:Scan() end end
cooldowns.lua:27:function CDs:Init()
cooldowns.lua:70:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldowns.lua:71:    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
cooldowns.lua:72:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
cooldowns.lua:73:    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
cooldowns.lua:83:    ev:SetScript("OnUpdate", function()
cooldowns.lua:97:function CDs:RebuildKnown()
cooldowns.lua:110:function CDs:Relayout()
cooldowns.lua:128:function CDs:UpdateCooldowns()
cooldowns.lua:145:function CDs:Refresh()
alerts.lua:11:local function SpellReady(name)
alerts.lua:21:function Alerts:Init()
alerts.lua:60:    ev:RegisterEvent("UNIT_SPELLCAST_START")
alerts.lua:61:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
alerts.lua:62:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
alerts.lua:63:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
alerts.lua:64:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
alerts.lua:65:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
alerts.lua:66:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
alerts.lua:67:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
alerts.lua:68:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
alerts.lua:69:    ev:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon/poison swap
alerts.lua:70:    ev:RegisterEvent("UPDATE_STEALTH")
alerts.lua:71:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
alerts.lua:76:function Alerts:OnEvent(e, unit)
alerts.lua:90:function Alerts:CheckKick(e, unit)
alerts.lua:114:function Alerts:CheckPoison()
alerts.lua:131:function Alerts:CheckOpener()
alerts.lua:142:function Alerts:Refresh()
config.lua:5:local function on(v) return v and "|cff20ff40on|r" or "|cffff4040off|r" end
config.lua:7:local function Print(msg) print("|cff00ff96Cutthroat|r: " .. msg) end
config.lua:9:local function Help()
config.lua:28:function Config:Init()
config.lua:82:function Config:Refresh() end

exec
/bin/zsh -lc "grep -RIn \"NS\\.db\\|NS\\.modules\\|NS\\.IsRogue\\|CreateFrame\\|SlashCmdList\\|_G\\[\" core.lua hud.lua timers.lua cooldowns.lua alerts.lua config.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
core.lua:6:NS.modules = {}
core.lua:36:    for _, mod in pairs(NS.modules) do
core.lua:43:local f = CreateFrame("Frame", "CutthroatRoot", UIParent)
core.lua:54:        NS.db = CutthroatDB
core.lua:59:            local m = NS.modules[name]
core.lua:80:NS.IsRogue = (playerClass == "ROGUE")
hud.lua:12:    local db = NS.db
hud.lua:15:    local root = CreateFrame("Frame", "CutthroatHUD", UIParent, "BackdropTemplate")
hud.lua:19:    root:SetPoint(p[1], p[2] and _G[p[2]] or UIParent, p[3], p[4], p[5])
hud.lua:23:    root:SetScript("OnDragStart", function(s) if not NS.db.locked then s:StartMoving() end end)
hud.lua:27:        NS.db.point = { a, nil, rp, x, y }
hud.lua:37:    local energy = CreateFrame("StatusBar", nil, root)
hud.lua:103:    local ev = CreateFrame("Frame")
hud.lua:140:    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
hud.lua:166:        if cp >= MAX_CP and NS.db.cpFinishGlow then
hud.lua:177:    self.root:SetScale(NS.db.scale)
hud.lua:178:    self.root:EnableMouse(not NS.db.locked)
hud.lua:179:    self.root.bg:SetShown(not NS.db.locked)
timers.lua:74:    local root = NS.modules.hud.root
timers.lua:80:        local b = CreateFrame("StatusBar", nil, root)
timers.lua:106:    local scan = CreateFrame("Frame")
timers.lua:125:    if not NS.IsRogue or not self.cache then return end
timers.lua:138:    if not NS.IsRogue then return end
timers.lua:139:    NS.modules.hud:UpdateCP()
timers.lua:140:    NS.modules.hud:UpdatePower()
timers.lua:141:    NS.modules.hud:UpdateEnergyTick()
timers.lua:154:            local warnAt = (key == "snd" and NS.db.sndWarn)
timers.lua:155:                or (key == "rup" and NS.db.ruptureWarn) or 2
timers.lua:163:            if NS.db.refreshZone then
timers.lua:185:                if want and NS.db.sound then
timers.lua:189:            local green = want and NS.db.refreshZone
timers.lua:190:            if green and NS.db.smartRefresh then green = HasRefreshResources(key) end
cooldowns.lua:28:    if not NS.IsRogue then return end
cooldowns.lua:29:    local root = NS.modules.hud.root
cooldowns.lua:54:        local f = CreateFrame("Frame", nil, root)
cooldowns.lua:60:        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
cooldowns.lua:69:    local ev = CreateFrame("Frame")
cooldowns.lua:112:    local root = NS.modules.hud.root
alerts.lua:22:    local root = NS.modules.hud.root
alerts.lua:25:    local kick = CreateFrame("Frame", "CutthroatKick", UIParent)
alerts.lua:59:    local ev = CreateFrame("Frame")
alerts.lua:77:    if not NS.IsRogue then return end
alerts.lua:91:    if not NS.db.kickAlert then return end
alerts.lua:107:            if NS.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master") end
alerts.lua:115:    if not NS.db.poisonCheck then self.poison:Hide(); return end
alerts.lua:132:    if not NS.db.openerHint then self.opener:Hide(); return end
alerts.lua:144:    if NS.IsRogue then
config.lua:31:    SlashCmdList["CUTTHROAT"] = function(msg)
config.lua:32:        local db = NS.db

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

**Verdict: CONDITIONALLY SHIP-READY**

No blocker found for normal rogue login, `/reload`, or non-rogue login. Init order is basically sound: TOC loads `core.lua` first, modules register before `PLAYER_LOGIN`, `NS.db` is assigned on `ADDON_LOADED`, and rogue-only modules initialize after HUD exists.

I would ship after fixing the low-cost OnUpdate/event cleanup items below. Nothing here looks like taint/security trouble.

**Findings**

1. `cooldowns.lua`, `CDs:Init`, lines 82-89: permanent per-frame `OnUpdate` runs forever just to check `layoutDirty`.
Concrete fix: set `OnUpdate` only when `SPELLS_CHANGED` / `CHARACTER_POINTS_CHANGED` marks dirty, then clear it after rebuild:
`ev:SetScript("OnUpdate", nil)` after `RebuildKnown()` / `Relayout()`.

2. `timers.lua`, `Timers:Init`, lines 112-119: timer render loop is installed directly on `NS.modules.hud.root`.
This works today, but it creates a shared-state hazard: any future module setting `root:SetScript("OnUpdate", ...)` will silently replace timers/HUD animation updates.
Concrete fix: create a private render frame parented to root, e.g. `self.renderFrame = CreateFrame("Frame", nil, root)`, and put the timer `OnUpdate` there.

3. `hud.lua` + `timers.lua`, `HUD:Init` / `Timers:Render`, lines `hud.lua:103-108` and `timers.lua:136-141`: power and combo points are both event-updated and polled every 0.05s.
This is not a correctness bug, but it is redundant. The 0.05s loop is needed for CP glow/tick spark animation, not necessarily for full `UpdatePower()` and `UpdateCP()` every tick.
Concrete fix: split HUD methods into cheap animation render vs state refresh. Let events call `UpdatePower()` / `UpdateCP()`, and let the render loop call only `UpdateEnergyTick()` plus CP glow animation if needed.

4. `alerts.lua` + `cooldowns.lua`, event registration, lines `alerts.lua:71` and `cooldowns.lua:70`: both register `SPELL_UPDATE_COOLDOWN`.
This is acceptable at current scale, but it duplicates event wakeups for related cooldown state.
Concrete fix: either leave as-is because behavior is simple, or centralize cooldown-change fanout through core if more modules start listening to the same event.

5. `core.lua`, SavedVariables merge, lines 48-54: defaults merge is shallow.
Current defaults are mostly flat, so new top-level keys are fine. The weak spot is nested/default-table migration, especially `point`.
Concrete fix: add recursive default merge plus validation for `scale` and `point` before HUD uses them. Preserve user values, inject missing nested keys, and reset malformed `point` to `{ "CENTER", nil, "CENTER", 0, -180 }`.

6. `core.lua`, comments vs actual init order, lines 56-62: comment says “hud first” and “config last”, but code initializes `config` first.
Runtime is okay because config needs no HUD and slash commands should work for everyone.
Concrete fix: update the comment to say config initializes first, rogue visual modules initialize after HUD.

7. `timers.lua`, `TRACK`, lines 10-17: `rnd = Rend` is dead config.
It is not in `SOURCE` or render order, so it never displays.
Concrete fix: remove it unless intentionally reserved for testing.

8. `core.lua`, `NS:RegisterModule`, line 30: method is global on `NS`, which is intended. No accidental leaked locals found in the requested files.
Expected globals: `CutthroatDB`, `SLASH_CUTTHROAT1`, `SLASH_CUTTHROAT2`, `SlashCmdList`.

9. Secure/taint review: no protected action buttons, no secure templates, no macro/spell execution, no combat attribute mutation.
The addon is display-only. `InCombatLockdown()` is only used for poison nag suppression. Taint risk looks low.

10. `/reload` safety: normal `/reload` is safe because Lua state resets and frames/events are recreated once.
Manual double-calling module `Init()` would duplicate frames/events, but WoW’s normal load path does not do that.
Concrete fix if you want hardening: add `if self.root then return end`, `if self.ev then return end`, etc. to module `Init()` methods.

**In-Client Smoke Test Checklist**

1. Rogue login on TBC Classic 2.5.x: no Lua errors, HUD appears, `/cut status` works.
2. `/reload`: no duplicate HUD/icons/alerts, saved position and scale persist.
3. Non-rogue login: no Lua errors, HUD disabled, `/cut` still works.
4. Drag unlocked HUD, `/reload`: position persists.
5. Toggle `/cut lock`, `/cut scale 0.9`, `/cut sound`, `/cut spark`, `/cut finish`: visible behavior updates without errors.
6. Build combo points and change target: pips update and max-CP glow clears on detarget.
7. Spend/apply Slice and Dice, Rupture, Expose Armor, Garrote: bars appear, expire, and refresh markers behave.
8. Use rogue cooldowns: known cooldown icons only, cooldown sweep/desaturation updates.
9. Target an interruptible cast with Kick ready/on cooldown: Kick alert appears only when actionable.
10. Remove poisons out of combat, equip offhand/no offhand, enter combat: poison warning behaves correctly.
11. Stealth with hostile target: opener hint appears; unstealth or clear target hides it.
12. Use `/eventtrace` or BugSack during combat: confirm no Lua errors and no surprising duplicate event storms.
tokens used
40,387
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

**Verdict: CONDITIONALLY SHIP-READY**

No blocker found for normal rogue login, `/reload`, or non-rogue login. Init order is basically sound: TOC loads `core.lua` first, modules register before `PLAYER_LOGIN`, `NS.db` is assigned on `ADDON_LOADED`, and rogue-only modules initialize after HUD exists.

I would ship after fixing the low-cost OnUpdate/event cleanup items below. Nothing here looks like taint/security trouble.

**Findings**

1. `cooldowns.lua`, `CDs:Init`, lines 82-89: permanent per-frame `OnUpdate` runs forever just to check `layoutDirty`.
Concrete fix: set `OnUpdate` only when `SPELLS_CHANGED` / `CHARACTER_POINTS_CHANGED` marks dirty, then clear it after rebuild:
`ev:SetScript("OnUpdate", nil)` after `RebuildKnown()` / `Relayout()`.

2. `timers.lua`, `Timers:Init`, lines 112-119: timer render loop is installed directly on `NS.modules.hud.root`.
This works today, but it creates a shared-state hazard: any future module setting `root:SetScript("OnUpdate", ...)` will silently replace timers/HUD animation updates.
Concrete fix: create a private render frame parented to root, e.g. `self.renderFrame = CreateFrame("Frame", nil, root)`, and put the timer `OnUpdate` there.

3. `hud.lua` + `timers.lua`, `HUD:Init` / `Timers:Render`, lines `hud.lua:103-108` and `timers.lua:136-141`: power and combo points are both event-updated and polled every 0.05s.
This is not a correctness bug, but it is redundant. The 0.05s loop is needed for CP glow/tick spark animation, not necessarily for full `UpdatePower()` and `UpdateCP()` every tick.
Concrete fix: split HUD methods into cheap animation render vs state refresh. Let events call `UpdatePower()` / `UpdateCP()`, and let the render loop call only `UpdateEnergyTick()` plus CP glow animation if needed.

4. `alerts.lua` + `cooldowns.lua`, event registration, lines `alerts.lua:71` and `cooldowns.lua:70`: both register `SPELL_UPDATE_COOLDOWN`.
This is acceptable at current scale, but it duplicates event wakeups for related cooldown state.
Concrete fix: either leave as-is because behavior is simple, or centralize cooldown-change fanout through core if more modules start listening to the same event.

5. `core.lua`, SavedVariables merge, lines 48-54: defaults merge is shallow.
Current defaults are mostly flat, so new top-level keys are fine. The weak spot is nested/default-table migration, especially `point`.
Concrete fix: add recursive default merge plus validation for `scale` and `point` before HUD uses them. Preserve user values, inject missing nested keys, and reset malformed `point` to `{ "CENTER", nil, "CENTER", 0, -180 }`.

6. `core.lua`, comments vs actual init order, lines 56-62: comment says “hud first” and “config last”, but code initializes `config` first.
Runtime is okay because config needs no HUD and slash commands should work for everyone.
Concrete fix: update the comment to say config initializes first, rogue visual modules initialize after HUD.

7. `timers.lua`, `TRACK`, lines 10-17: `rnd = Rend` is dead config.
It is not in `SOURCE` or render order, so it never displays.
Concrete fix: remove it unless intentionally reserved for testing.

8. `core.lua`, `NS:RegisterModule`, line 30: method is global on `NS`, which is intended. No accidental leaked locals found in the requested files.
Expected globals: `CutthroatDB`, `SLASH_CUTTHROAT1`, `SLASH_CUTTHROAT2`, `SlashCmdList`.

9. Secure/taint review: no protected action buttons, no secure templates, no macro/spell execution, no combat attribute mutation.
The addon is display-only. `InCombatLockdown()` is only used for poison nag suppression. Taint risk looks low.

10. `/reload` safety: normal `/reload` is safe because Lua state resets and frames/events are recreated once.
Manual double-calling module `Init()` would duplicate frames/events, but WoW’s normal load path does not do that.
Concrete fix if you want hardening: add `if self.root then return end`, `if self.ev then return end`, etc. to module `Init()` methods.

**In-Client Smoke Test Checklist**

1. Rogue login on TBC Classic 2.5.x: no Lua errors, HUD appears, `/cut status` works.
2. `/reload`: no duplicate HUD/icons/alerts, saved position and scale persist.
3. Non-rogue login: no Lua errors, HUD disabled, `/cut` still works.
4. Drag unlocked HUD, `/reload`: position persists.
5. Toggle `/cut lock`, `/cut scale 0.9`, `/cut sound`, `/cut spark`, `/cut finish`: visible behavior updates without errors.
6. Build combo points and change target: pips update and max-CP glow clears on detarget.
7. Spend/apply Slice and Dice, Rupture, Expose Armor, Garrote: bars appear, expire, and refresh markers behave.
8. Use rogue cooldowns: known cooldown icons only, cooldown sweep/desaturation updates.
9. Target an interruptible cast with Kick ready/on cooldown: Kick alert appears only when actionable.
10. Remove poisons out of combat, equip offhand/no offhand, enter combat: poison warning behaves correctly.
11. Stealth with hostile target: opener hint appears; unstealth or clear target hides it.
12. Use `/eventtrace` or BugSack during combat: confirm no Lua errors and no surprising duplicate event storms.
