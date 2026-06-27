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
session id: 019f0995-313e-7f60-a98d-3314476a2889
--------
user
Review the 'combo-point overcap glow' in hud.lua of this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1) Rogue addon. self.cpGlow is a BACKGROUND texture behind the combo pip row; HUD:UpdateCP() pulses its alpha (0.15+0.30*(0.5+0.5*sin(GetTime()*5))) when GetComboPoints('player','target')>=MAX_CP(5), else hides it. UpdateCP runs every render (~0.05s via timers:Render) and on power/target events. /cut finish toggle. READ-ONLY. Verify for TBC 2.5.x: (1) is 5 the correct combo cap (any effect raising it)? (2) GetComboPoints('player','target') signature; (3) BACKGROUND vs ARTWORK draw order so glow sits behind pips, and per-render SetAlpha cost; (4) math.sin/GetTime availability; (5) flicker when cp crosses 5; (6) UpdateCP called from both events and render — any conflict; (7) UX of pulsing at cp>=5. Read hud.lua. Numbered: file/function/bug/fix. Do NOT edit. Real bugs first.
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

I’ll inspect `hud.lua` and the surrounding event/render wiring, then give this as a review only. Since you asked for real bugs first and no edits, I’ll keep it to file/function/bug/fix findings.
exec
/bin/zsh -lc 'rg -n "cpGlow|UpdateCP|GetComboPoints|MAX_CP|finish|Render|PLAYER_TARGET_CHANGED|UNIT_POWER|COMBO" hud.lua' in /Users/creative/WoWAddons/Cutthroat
 exited 127 in 0ms:
zsh:1: command not found: rg

exec
/bin/zsh -lc "sed -n '260,560p' hud.lua" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "sed -n '1,260p' hud.lua" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
 succeeded in 0ms:
-- HUD: energy bar (with ticks) + combo point pips. Anchor frame for everything.
local ADDON, NS = ...

local HUD = NS:RegisterModule("hud", {})

local WIDTH, HEIGHT = 240, 18
local CP_SIZE, CP_GAP = 22, 6
local MAX_CP = 5
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

function HUD:Init()
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
    self.energyMax = (m and m > 0) and m or 100
    self.energy:SetMinMaxValues(0, self.energyMax)
    self.energy:SetValue(e)
    self.energy.text:SetText(e)

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
    local cp = GetComboPoints("player", "target") or 0
    for i = 1, MAX_CP do
        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
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

codex
`hud.lua` has the glow exactly where described: pips are `ARTWORK`, glow is `BACKGROUND`, and `UpdateCP()` gates it on `cp >= MAX_CP` plus `NS.db.cpFinishGlow`. I’m checking the timer/slash wiring now so the event-vs-render interaction is grounded in the repo, not just the snippet.
exec
/bin/zsh -lc "nl -ba hud.lua | sed -n '1,240p'" in /Users/creative/WoWAddons/Cutthroat
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
    96	    self.cpGlow:Hide()
    97	
    98	    -- Event-driven power updates, all unit-filtered to "player" so other units'
    99	    -- power changes never wake this handler. Combo points have no reliable
   100	    -- cross-version event (UNIT_COMBO_POINTS vs UNIT_POWER_UPDATE differ by build,
   101	    -- and registering a wrong event name errors) — they're polled in timers:Tick.
   102	    local ev = CreateFrame("Frame")
   103	    ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
   104	    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
   105	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
   106	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
   107	    self.ev = ev
   108	end
   109	
   110	function HUD:UpdatePower()
   111	    if not self.energy then return end
   112	    local e = UnitPower("player", ENERGY)
   113	    local m = UnitPowerMax("player", ENERGY)
   114	    self.energyMax = (m and m > 0) and m or 100
   115	    self.energy:SetMinMaxValues(0, self.energyMax)
   116	    self.energy:SetValue(e)
   117	    self.energy.text:SetText(e)
   118	
   119	    if self.lastEnergy == nil then self.lastEnergy = e; return end
   120	    -- A regen tick lands as a sizable positive delta. Small proc gains (Combat
   121	    -- Potency etc.) are ignored with the >=10 filter so they don't yank the spark.
   122	    -- We MEASURE the real tick cadence from gap to gap (clamped) instead of assuming
   123	    -- 2.0s — GLM and Codex disagreed on whether Adrenaline Rush changes the tick
   124	    -- interval or the per-tick amount, so measuring sidesteps the unresolved question.
   125	    if e > self.lastEnergy and (e - self.lastEnergy) >= 10 then
   126	        local now = GetTime()
   127	        local gap = now - (self.lastTick or now)
   128	        if gap >= 0.8 and gap <= 2.2 then self.tickInterval = gap end
   129	        self.lastTick = now
   130	    end
   131	    self.lastEnergy = e
   132	end
   133	
   134	-- Move the regen-tick spark; called every render frame from timers:Render.
   135	function HUD:UpdateEnergyTick()
   136	    local s = self.energy and self.energy.spark
   137	    if not s then return end
   138	    -- hide when disabled or at full energy (no tick to wait for)
   139	    if not NS.db.tickSpark or (self.lastEnergy and self.lastEnergy >= self.energyMax) then
   140	        s:Hide(); return
   141	    end
   142	    local interval = self.tickInterval or 2.0
   143	    local frac = (GetTime() - (self.lastTick or 0)) / interval
   144	    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
   145	    local w = self.energy:GetWidth()
   146	    local sw = s:GetWidth() or 2
   147	    local x = frac * w
   148	    if x > w - sw then x = w - sw end  -- keep the full 2px spark inside the bar
   149	    if x < 0 then x = 0 end
   150	    s:ClearAllPoints()
   151	    s:SetPoint("TOP", self.energy, "TOPLEFT", x, 0)
   152	    s:SetPoint("BOTTOM", self.energy, "BOTTOMLEFT", x, 0)
   153	    s:Show()
   154	end
   155	
   156	function HUD:UpdateCP()
   157	    local cp = GetComboPoints("player", "target") or 0
   158	    for i = 1, MAX_CP do
   159	        self.pips[i]:SetAlpha(i <= cp and 1.0 or 0.15)
   160	    end
   161	    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
   162	    local g = self.cpGlow
   163	    if g then
   164	        if cp >= MAX_CP and NS.db.cpFinishGlow then
   165	            g:SetAlpha(0.15 + 0.30 * (0.5 + 0.5 * math.sin(GetTime() * 5)))
   166	            if not g:IsShown() then g:Show() end
   167	        elseif g:IsShown() then
   168	            g:Hide()
   169	        end
   170	    end
   171	end
   172	
   173	function HUD:Refresh()
   174	    if not self.root then return end
   175	    self.root:SetScale(NS.db.scale)
   176	    self.root:EnableMouse(not NS.db.locked)
   177	    self.root.bg:SetShown(not NS.db.locked)
   178	    self:UpdatePower()
   179	    self:UpdateCP()
   180	end

exec
/bin/zsh -lc "grep -RIn \"UpdateCP\\|cpFinishGlow\\|finish\\|Render\\|RegisterEvent\\|OnUpdate\" . --exclude-dir=.git" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
./hud.lua:90:    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
./hud.lua:105:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./hud.lua:106:    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./hud.lua:134:-- Move the regen-tick spark; called every render frame from timers:Render.
./hud.lua:156:function HUD:UpdateCP()
./hud.lua:161:    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
./hud.lua:164:        if cp >= MAX_CP and NS.db.cpFinishGlow then
./hud.lua:179:    self:UpdateCP()
./timers.lua:1:-- Timers: track YOUR finisher durations on the current target via combat log.
./timers.lua:30:        -- finishers: need a live attackable target AND energy AND a combo point
./timers.lua:108:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./timers.lua:112:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./timers.lua:114:    root:SetScript("OnUpdate", function(_, dt)
./timers.lua:118:        self:Render()
./timers.lua:136:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./timers.lua:137:function Timers:Render()
./timers.lua:139:    NS.modules.hud:UpdateCP()
./docs/TRIANGULATION.md:71:| 1 | `RegisterEvent("PLAYER_TALENT_UPDATE")` hard-errors — event doesn't exist in 2.5.x → breaks module load | ✅ | ✅ | ✅ **applied** | Triple-confirmed (both + my own pre-review red-team). Removed; `CHARACTER_POINTS_CHANGED` + `SPELLS_CHANGED` cover respec/learn. |
./docs/TRIANGULATION.md:93:| 5 | Perf: OnUpdate scans ~160 `UnitAura` calls / 0.1s | ⚠️ (Lua-cap warning) | ✅ | ✅ **applied** | Refactored to UNIT_AURA-driven cache; OnUpdate now only renders cached countdowns (0 scans/frame). |
./docs/ROADMAP.md:10:- [ ] **Spec detection**: read talents, adjust finisher durations (SnD/Rupture scale with talents like Improved SnD).
./docs/DECISIONS.md:13:Success criteria for the addon: loads clean on a TBC Anniversary client, zero Lua errors, no FPS regression from OnUpdate loops, and **provably no spell-input automation** (Warden-safe).
./docs/DECISIONS.md:33:**Confirmed correct by both:** 25-energy finisher cost (no TBC talent reduces it), `GetComboPoints("player","target")` signature, `>=1` gate, per-frame perf, dynamic green-on as energy ticks to 25, Expose-on-CP gating.
./docs/DECISIONS.md:59:**What:** Shipped roadmap item 2 — a thin "spark" on the energy bar that sweeps left→right over the energy regen cycle and resets on each tick, so you can time energy pooling / pre-tick finishers. New `/cut spark` toggle. Read-only.
./docs/DECISIONS.md:81:1. **Removed `PLAYER_TALENT_UPDATE` registration.** That event doesn't exist in TBC 2.5.x and `RegisterEvent` on an unknown event hard-errors — it would have broken the whole module on load. Caught by GLM, Codex, *and* my own pre-review pass. `CHARACTER_POINTS_CHANGED` + `SPELLS_CHANGED` cover respec/learning.
./docs/DECISIONS.md:108:5. **timers: event-driven aura cache.** Was scanning ~160 `UnitAura` calls every 0.1s. Now re-scans only on `UNIT_AURA`/target-change; OnUpdate just renders cached countdowns. Kills the FPS risk GLM flagged.
./alerts.lua:60:    ev:RegisterEvent("UNIT_SPELLCAST_START")
./alerts.lua:61:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./alerts.lua:62:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./alerts.lua:63:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./alerts.lua:64:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./alerts.lua:65:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./alerts.lua:66:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./alerts.lua:67:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./alerts.lua:68:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
./alerts.lua:70:    ev:RegisterEvent("UPDATE_STEALTH")
./alerts.lua:71:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./config.lua:21:    print("  |cffffff00/cut finish|r       toggle max-CP overcap glow")
./config.lua:61:        elseif cmd == "finish" then
./config.lua:62:            db.cpFinishGlow = not db.cpFinishGlow; Print("max-CP overcap glow " .. on(db.cpFinishGlow))
./config.lua:73:            Print(string.format("ticks %s | spark %s | zone %s | smart %s | finish %s",
./config.lua:74:                on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh), on(db.cpFinishGlow)))
./prompts/review_iter1.txt:1:You are reviewing a World of Warcraft TBC Classic (2.5.x, interface 20504) Rogue addon called Cutthroat. Lua 5.1 runtime, WoW API. GOAL: find correctness bugs, WoW-API misuse, performance issues (OnUpdate/CLEU loops), and ban-safety problems (it MUST NOT automate spell input). Be specific: file, line/function, the bug, the fix. Prioritize REAL bugs over style. Output a numbered list.
./prompts/review_iter1.txt:57:f:RegisterEvent("ADDON_LOADED")
./prompts/review_iter1.txt:58:f:RegisterEvent("PLAYER_LOGIN")
./prompts/review_iter1.txt:167:    -- event-driven updates (cheap; no OnUpdate polling for power)
./prompts/review_iter1.txt:171:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./prompts/review_iter1.txt:172:    ev:RegisterEvent("UNIT_POWER_UPDATE")
./prompts/review_iter1.txt:173:    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./prompts/review_iter1.txt:186:function HUD:UpdateCP()
./prompts/review_iter1.txt:199:    self:UpdateCP()
./prompts/review_iter1.txt:203:-- Timers: track YOUR finisher durations on the current target via combat log.
./prompts/review_iter1.txt:271:    root:SetScript("OnUpdate", function(_, dt)
./prompts/review_iter1.txt:376:    ev:RegisterEvent("UNIT_SPELLCAST_START")
./prompts/review_iter1.txt:377:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./prompts/review_iter1.txt:378:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./prompts/review_iter1.txt:379:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./prompts/review_iter1.txt:380:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./prompts/review_iter1.txt:381:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./prompts/review_iter1.txt:382:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./prompts/review_iter1.txt:383:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./prompts/review_iter1.txt:384:    ev:RegisterEvent("UPDATE_STEALTH")
./prompts/review_iter1.txt:385:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./prompts/review_iter3.txt:1:Review the energy regen-tick predictor just added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a thin 'spark' on the energy bar that sweeps 0->100% over the ~2s energy regen cycle and resets when energy is observed to increase, to help energy-pooling. READ-ONLY, no automation. Changed files: hud.lua (spark texture + UpdatePower gain-detection + UpdateEnergyTick), timers.lua (calls UpdateEnergyTick each render ~0.05s), config.lua (/cut spark toggle), core.lua (tickSpark default). CHECK: (1) is the 2.0s energy tick interval correct for TBC 2.5.x rogues? (2) gain-detection via positive UnitPower delta — does it falsely reset on ability-refunds/Relentless Strikes/Thistle Tea, and does that matter? (3) UnitPower/UnitPowerMax signatures + Enum.PowerType.Energy fallback to 3 in 2.5.x; (4) spark anchor math (SetPoint TOP/BOTTOM to TOPLEFT/BOTTOMLEFT with x offset) — correct & does it clip at bar ends? (5) does polling UpdatePower every 0.05s from timers:Render cause false gain-resets or perf issues? (6) behavior at energy cap / Adrenaline Rush (faster ticks); (7) any nil-safety holes (lastEnergy nil on first call). For each: file, function, bug, concrete fix. Numbered list, real bugs first.
./prompts/review_iter3.txt:98:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./prompts/review_iter3.txt:99:    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./prompts/review_iter3.txt:118:-- Move the regen-tick spark; called every render frame from timers:Render.
./prompts/review_iter3.txt:135:function HUD:UpdateCP()
./prompts/review_iter3.txt:148:    self:UpdateCP()
./prompts/review_iter3.txt:151:===== timers.lua Render =====
./prompts/review_iter3.txt:152:function Timers:Render()
./prompts/review_iter3.txt:154:    NS.modules.hud:UpdateCP()
./prompts/review_iter2.txt:76:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./prompts/review_iter2.txt:77:    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
./prompts/review_iter2.txt:78:    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
./prompts/review_iter2.txt:79:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
./prompts/review_iter2.txt:171:f:RegisterEvent("ADDON_LOADED")
./prompts/review_iter2.txt:172:f:RegisterEvent("PLAYER_LOGIN")
./prompts/review_iter2.txt:220:-- Timers: track YOUR finisher durations on the current target via combat log.
./prompts/review_iter6.txt:1:Review the 'combo-point overcap glow' just added to Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a gold texture (self.cpGlow) behind the combo-point pip row pulses (alpha via 0.15+0.30*(0.5+0.5*sin(GetTime()*5))) when GetComboPoints('player','target') >= MAX_CP (5), to warn against overcapping combo points. UpdateCP() is called every render (~0.05s from timers:Render) plus on power/target events. /cut finish toggle (cpFinishGlow default true). READ-ONLY, no automation. CHECK: (1) is MAX_CP=5 the correct combo cap for TBC rogues (any talent/effect that raises it)? (2) GetComboPoints('player','target') correctness; (3) the cpGlow texture is BACKGROUND layer anchored to pips[1]..pips[MAX_CP] with SetColorTexture(1,0.82,0,1) then alpha-animated via SetAlpha each render — does BACKGROUND render behind the ARTWORK pips correctly, and is per-render SetAlpha fine? (4) math.sin/GetTime availability in 2.5.x; (5) when cp drops below 5 the glow hides — any flicker/edge issues; (6) does calling UpdateCP both on events AND every render cause any double-show problem; (7) is pulsing at exactly cp>=5 the right UX or should it also consider whether a finisher is worth using? Real bugs first. file/function/bug/fix. Numbered.
./prompts/review_iter6.txt:93:    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
./prompts/review_iter6.txt:108:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./prompts/review_iter6.txt:109:    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./prompts/review_iter6.txt:137:-- Move the regen-tick spark; called every render frame from timers:Render.
./prompts/review_iter6.txt:159:function HUD:UpdateCP()
./prompts/review_iter6.txt:164:    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
./prompts/review_iter6.txt:167:        if cp >= MAX_CP and NS.db.cpFinishGlow then
./prompts/review_iter6.txt:182:    self:UpdateCP()
./prompts/review_iter5.txt:1:Review the 'resource-aware refresh cue' just added to Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: the green 'refresh-now' fill on SnD/Rupture/Expose/Garrote timer bars now only lights when the player can actually refresh — gated by HasRefreshResources(key): SnD needs energy>=25; Rupture/Expose need energy>=25 AND GetComboPoints('player','target')>=1; Garrote ungated. New /cut smart toggle (smartRefresh default true). READ-ONLY, no automation. CHECK: (1) are the resource thresholds correct for TBC 2.5.x rogue? SnD/Rupture/Expose all cost 25 energy? Talents (Improved SnD doesn't change cost; do any reduce finisher energy cost)? (2) GetComboPoints('player','target') correct signature/behavior in 2.5.x and is gating refresh on >=1 CP sensible (you refresh with whatever CP you have)? (3) UnitPower('player', ENERGY) where ENERGY=Enum.PowerType.Energy or 3 — correct? (4) HasRefreshResources called every render frame for in-window bars — perf? (5) does the green transition correctly turn ON when energy ticks up to 25 mid-window (dynamic)? (6) edge: target dead/none for rup/exp CP check; (7) is gating Expose on combo points right (Expose Armor is a finisher, yes)? Real bugs first. For each: file, function, bug, fix. Numbered.
./prompts/review_iter5.txt:4:-- Timers: track YOUR finisher durations on the current target via combat log.
./prompts/review_iter5.txt:106:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./prompts/review_iter5.txt:110:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./prompts/review_iter5.txt:112:    root:SetScript("OnUpdate", function(_, dt)
./prompts/review_iter5.txt:116:        self:Render()
./prompts/review_iter5.txt:134:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./prompts/review_iter5.txt:135:function Timers:Render()
./prompts/review_iter5.txt:137:    NS.modules.hud:UpdateCP()
./prompts/review_iter4.txt:4:-- Timers: track YOUR finisher durations on the current target via combat log.
./prompts/review_iter4.txt:91:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./prompts/review_iter4.txt:95:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./prompts/review_iter4.txt:97:    root:SetScript("OnUpdate", function(_, dt)
./prompts/review_iter4.txt:101:        self:Render()
./prompts/review_iter4.txt:119:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./prompts/review_iter4.txt:120:function Timers:Render()
./prompts/review_iter4.txt:122:    NS.modules.hud:UpdateCP()
./cooldowns.lua:70:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./cooldowns.lua:71:    ev:RegisterEvent("SPELLS_CHANGED")           -- learned a rank
./cooldowns.lua:72:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent point spent / respec
./cooldowns.lua:73:    -- NOTE: PLAYER_TALENT_UPDATE does NOT exist in TBC 2.5.x; RegisterEvent on an
./cooldowns.lua:83:    ev:SetScript("OnUpdate", function()
./core.lua:23:    cpFinishGlow = true,-- pulse the combo pips at max CP (don't overcap -> finish)
./core.lua:44:f:RegisterEvent("ADDON_LOADED")
./core.lua:45:f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter4.md:31:-- Timers: track YOUR finisher durations on the current target via combat log.
./reviews/codex/iter4.md:118:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter4.md:122:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter4.md:124:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter4.md:128:        self:Render()
./reviews/codex/iter4.md:146:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter4.md:147:function Timers:Render()
./reviews/codex/iter4.md:149:    NS.modules.hud:UpdateCP()
./reviews/codex/iter4.md:240:    88	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter4.md:244:    92	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter4.md:246:    94	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter4.md:250:    98	        self:Render()
./reviews/codex/iter4.md:268:   116	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter4.md:269:   117	function Timers:Render()
./reviews/codex/iter4.md:271:   119	    NS.modules.hud:UpdateCP()
./reviews/codex/iter4.md:322:/bin/zsh -lc "grep -n \"marker\\|SetStatusBarColor\\|warnAt\\|Render\\|OnHide\" timers.lua" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter4.md:331:98:        self:Render()
./reviews/codex/iter4.md:332:116:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter4.md:333:117:function Timers:Render()
./reviews/codex/iter4.md:348:1. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:140), `Timers:Render`, no bug: marker math matches this fill direction. With min/max `0,dur` and value `rem`, the fill width is `(rem / dur) * BAR_W`, so at `rem == warnAt` the fill’s right edge is at `(warnAt / dur) * BAR_W` from the left. Concrete fix: none for the math. If you want the 2px marker visually centered on the edge, anchor at `mx - 1`, but current left edge is mathematically correct.
./reviews/codex/iter4.md:350:2. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:152), `Timers:Render`, bug: if `refreshZone` is turned off while a bar is already green and still `rem <= warnAt`, the code hides the marker but does not restore `b.baseColor` because the restore only happens in the `rem > warnAt` branch. Concrete fix: in the warn branch, explicitly restore base color when `refreshZone` is false:
./reviews/codex/iter4.md:359:3. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:159), `Timers:Render`, perf issue: `SetStatusBarColor(unpack(b.baseColor))` runs every render tick for every non-warning bar, about 20 times/sec. Correct behavior, wasteful state churn. Concrete fix: track the current color state, e.g. `b.refreshColor = true/false`, and only call `SetStatusBarColor` when transitioning into or out of refresh color.
./reviews/codex/iter4.md:361:4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:140), `Timers:Render`, no real clamp bug in current code: `mx` is clamped to `[0, BAR_W]` on lines 140-141. Concrete fix: none required. Cleaner version would clamp the fraction first:
./reviews/codex/iter4.md:368:5. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:127), `Timers:Render`, no visible stale-marker bug found. `b.marker` is a child texture of `b`, so when `b:Hide()` runs, the marker is not visible. On the next active render, marker state is recalculated before `b:Show()`. Concrete fix: optional hygiene only, add `b.marker:Hide()` in the expiry branch or `OnHide`, but it is not needed to prevent a visible leftover marker.
./reviews/codex/iter4.md:370:6. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:149), `Timers:Render`, UX caveat: “green = refresh now” is mechanically correct only if `warnAt` is a small latency/GCD planning window. In TBC there is no pandemic carryover, so refreshing at 5s remaining clips 5s. Concrete fix: label/option semantics should be “refresh soon / final window,” or default thresholds should be tight, e.g. DoTs around `1.0-2.0s`, SnD depending on energy/CP planning but not a broad “now” window unless the user knowingly accepts clipping.
./reviews/codex/iter4.md:375:1. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:140), `Timers:Render`, no bug: marker math matches this fill direction. With min/max `0,dur` and value `rem`, the fill width is `(rem / dur) * BAR_W`, so at `rem == warnAt` the fill’s right edge is at `(warnAt / dur) * BAR_W` from the left. Concrete fix: none for the math. If you want the 2px marker visually centered on the edge, anchor at `mx - 1`, but current left edge is mathematically correct.
./reviews/codex/iter4.md:377:2. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:152), `Timers:Render`, bug: if `refreshZone` is turned off while a bar is already green and still `rem <= warnAt`, the code hides the marker but does not restore `b.baseColor` because the restore only happens in the `rem > warnAt` branch. Concrete fix: in the warn branch, explicitly restore base color when `refreshZone` is false:
./reviews/codex/iter4.md:386:3. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:159), `Timers:Render`, perf issue: `SetStatusBarColor(unpack(b.baseColor))` runs every render tick for every non-warning bar, about 20 times/sec. Correct behavior, wasteful state churn. Concrete fix: track the current color state, e.g. `b.refreshColor = true/false`, and only call `SetStatusBarColor` when transitioning into or out of refresh color.
./reviews/codex/iter4.md:388:4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:140), `Timers:Render`, no real clamp bug in current code: `mx` is clamped to `[0, BAR_W]` on lines 140-141. Concrete fix: none required. Cleaner version would clamp the fraction first:
./reviews/codex/iter4.md:395:5. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:127), `Timers:Render`, no visible stale-marker bug found. `b.marker` is a child texture of `b`, so when `b:Hide()` runs, the marker is not visible. On the next active render, marker state is recalculated before `b:Show()`. Concrete fix: optional hygiene only, add `b.marker:Hide()` in the expiry branch or `OnHide`, but it is not needed to prevent a visible leftover marker.
./reviews/codex/iter4.md:397:6. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:149), `Timers:Render`, UX caveat: “green = refresh now” is mechanically correct only if `warnAt` is a small latency/GCD planning window. In TBC there is no pandemic carryover, so refreshing at 5s remaining clips 5s. Concrete fix: label/option semantics should be “refresh soon / final window,” or default thresholds should be tight, e.g. DoTs around `1.0-2.0s`, SnD depending on energy/CP planning but not a broad “now” window unless the user knowingly accepts clipping.
./reviews/codex/iter5.md:14:Review the 'resource-aware refresh cue' in timers.lua of this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1) Rogue addon. The green 'refresh-now' bar fill now only lights when the player can refresh: HasRefreshResources(key) — SnD needs energy>=25; Rupture/Expose need energy>=25 AND GetComboPoints('player','target')>=1; Garrote ungated. Gated by smartRefresh (default true). READ-ONLY. Verify for TBC 2.5.x: (1) finisher energy costs — are SnD/Rupture/Expose all 25 energy? any talents that reduce finisher cost making the hardcoded 25 wrong? (2) GetComboPoints('player','target') signature/behavior, and is >=1 the right gate; (3) UnitPower('player', ENERGY) with ENERGY=Enum.PowerType.Energy or 3; (4) per-frame HasRefreshResources perf; (5) dynamic green-on when energy ticks to 25 mid-window; (6) target dead/absent edge for CP; (7) gating Expose Armor on CP (it's a finisher). Read timers.lua. Numbered list: file, function, bug, concrete fix. Do NOT edit. Real bugs first.
./reviews/codex/iter5.md:31:-- Timers: track YOUR finisher durations on the current target via combat log.
./reviews/codex/iter5.md:133:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter5.md:137:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter5.md:139:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter5.md:143:        self:Render()
./reviews/codex/iter5.md:161:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter5.md:162:function Timers:Render()
./reviews/codex/iter5.md:164:    NS.modules.hud:UpdateCP()
./reviews/codex/iter5.md:241:     1	-- Timers: track YOUR finisher durations on the current target via combat log.
./reviews/codex/iter5.md:343:   103	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter5.md:347:   107	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter5.md:349:   109	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter5.md:353:   113	        self:Render()
./reviews/codex/iter5.md:371:   131	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter5.md:372:   132	function Timers:Render()
./reviews/codex/iter5.md:374:   134	    NS.modules.hud:UpdateCP()
./reviews/codex/iter5.md:473:./prompts/review_iter3.txt:1:Review the energy regen-tick predictor just added to the Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: a thin 'spark' on the energy bar that sweeps 0->100% over the ~2s energy regen cycle and resets when energy is observed to increase, to help energy-pooling. READ-ONLY, no automation. Changed files: hud.lua (spark texture + UpdatePower gain-detection + UpdateEnergyTick), timers.lua (calls UpdateEnergyTick each render ~0.05s), config.lua (/cut spark toggle), core.lua (tickSpark default). CHECK: (1) is the 2.0s energy tick interval correct for TBC 2.5.x rogues? (2) gain-detection via positive UnitPower delta — does it falsely reset on ability-refunds/Relentless Strikes/Thistle Tea, and does that matter? (3) UnitPower/UnitPowerMax signatures + Enum.PowerType.Energy fallback to 3 in 2.5.x; (4) spark anchor math (SetPoint TOP/BOTTOM to TOPLEFT/BOTTOMLEFT with x offset) — correct & does it clip at bar ends? (5) does polling UpdatePower every 0.05s from timers:Render cause false gain-resets or perf issues? (6) behavior at energy cap / Adrenaline Rush (faster ticks); (7) any nil-safety holes (lastEnergy nil on first call). For each: file, function, bug, concrete fix. Numbered list, real bugs first.
./reviews/codex/iter5.md:483:./prompts/review_iter5.txt:1:Review the 'resource-aware refresh cue' just added to Cutthroat WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon. Feature: the green 'refresh-now' fill on SnD/Rupture/Expose/Garrote timer bars now only lights when the player can actually refresh — gated by HasRefreshResources(key): SnD needs energy>=25; Rupture/Expose need energy>=25 AND GetComboPoints('player','target')>=1; Garrote ungated. New /cut smart toggle (smartRefresh default true). READ-ONLY, no automation. CHECK: (1) are the resource thresholds correct for TBC 2.5.x rogue? SnD/Rupture/Expose all cost 25 energy? Talents (Improved SnD doesn't change cost; do any reduce finisher energy cost)? (2) GetComboPoints('player','target') correct signature/behavior in 2.5.x and is gating refresh on >=1 CP sensible (you refresh with whatever CP you have)? (3) UnitPower('player', ENERGY) where ENERGY=Enum.PowerType.Energy or 3 — correct? (4) HasRefreshResources called every render frame for in-window bars — perf? (5) does the green transition correctly turn ON when energy ticks up to 25 mid-window (dynamic)? (6) edge: target dead/none for rup/exp CP check; (7) is gating Expose on combo points right (Expose Armor is a finisher, yes)? Real bugs first. For each: file, function, bug, fix. Numbered.
./reviews/codex/iter5.md:549:    43	f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter5.md:550:    44	f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter5.md:689:4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:28), `HasRefreshResources`, no bug: SnD/Rupture/Expose Armor using `25` energy is correct. I don’t see a TBC rogue talent that reduces finisher energy cost; Improved SnD changes duration, Relentless Strikes is a refund, Ruthlessness affects combo points, not cost.
./reviews/codex/iter5.md:691:5. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:30), `HasRefreshResources`, no bug: `GetComboPoints("player", "target")` is the correct TBC-era signature, and `>= 1` is the right gate for Rupture/Expose because they are finishers and can be cast with any positive combo point count.
./reviews/codex/iter5.md:693:6. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:184), `Render`, no bug: dynamic green-on at the next energy tick works. `Render()` runs every ~0.05s, recomputes `HasRefreshResources`, and flips `b.greenState` when energy crosses 25.
./reviews/codex/iter5.md:695:7. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:184), `Render`, no perf bug: worst case is a few `UnitPower`/`GetComboPoints` calls every 0.05s for visible in-window bars. That is cheap and does not scan auras or allocate meaningful garbage. You could cache `e`/`cp` once per render, but it’s cleanup, not a needed fix.
./reviews/codex/iter5.md:697:8. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:29), `HasRefreshResources`, no bug: Expose Armor is correctly gated on combo points. It is a finisher.
./reviews/codex/iter5.md:710:4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:28), `HasRefreshResources`, no bug: SnD/Rupture/Expose Armor using `25` energy is correct. I don’t see a TBC rogue talent that reduces finisher energy cost; Improved SnD changes duration, Relentless Strikes is a refund, Ruthlessness affects combo points, not cost.
./reviews/codex/iter5.md:712:5. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:30), `HasRefreshResources`, no bug: `GetComboPoints("player", "target")` is the correct TBC-era signature, and `>= 1` is the right gate for Rupture/Expose because they are finishers and can be cast with any positive combo point count.
./reviews/codex/iter5.md:714:6. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:184), `Render`, no bug: dynamic green-on at the next energy tick works. `Render()` runs every ~0.05s, recomputes `HasRefreshResources`, and flips `b.greenState` when energy crosses 25.
./reviews/codex/iter5.md:716:7. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:184), `Render`, no perf bug: worst case is a few `UnitPower`/`GetComboPoints` calls every 0.05s for visible in-window bars. That is cheap and does not scan auras or allocate meaningful garbage. You could cache `e`/`cp` once per render, but it’s cleanup, not a needed fix.
./reviews/codex/iter5.md:718:8. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:29), `HasRefreshResources`, no bug: Expose Armor is correctly gated on combo points. It is a finisher.
./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter1.md:110:    57	    ev:RegisterEvent("UNIT_SPELLCAST_START")
./reviews/codex/iter1.md:111:    58	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./reviews/codex/iter1.md:112:    59	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./reviews/codex/iter1.md:113:    60	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./reviews/codex/iter1.md:114:    61	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./reviews/codex/iter1.md:115:    62	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter1.md:116:    63	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./reviews/codex/iter1.md:117:    64	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./reviews/codex/iter1.md:118:    65	    ev:RegisterEvent("UPDATE_STEALTH")
./reviews/codex/iter1.md:119:    66	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter1.md:303:    39	f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter1.md:304:    40	f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter1.md:413:    76	    -- event-driven updates (cheap; no OnUpdate polling for power)
./reviews/codex/iter1.md:417:    80	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter1.md:418:    81	    ev:RegisterEvent("UNIT_POWER_UPDATE")
./reviews/codex/iter1.md:419:    82	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./reviews/codex/iter1.md:432:    95	function HUD:UpdateCP()
./reviews/codex/iter1.md:445:   108	    self:UpdateCP()
./reviews/codex/iter1.md:468:     1	-- Timers: track YOUR finisher durations on the current target via combat log.
./reviews/codex/iter1.md:536:    69	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter1.md:594:/bin/zsh -lc 'grep -RInE "GetSpellCooldown|C_Spell|UnitAura|C_UnitAuras|GetWeaponEnchantInfo|GetComboPoints|UNIT_POWER|UNIT_COMBO|Register(Unit)?Event|OnUpdate|Cast|UseAction|RunScript|RunMacro" core.lua hud.lua timers.lua alerts.lua config.lua Cutthroat.toc' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter1.md:596:core.lua:39:f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter1.md:597:core.lua:40:f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter1.md:598:hud.lua:76:    -- event-driven updates (cheap; no OnUpdate polling for power)
./reviews/codex/iter1.md:601:hud.lua:80:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter1.md:602:hud.lua:81:    ev:RegisterEvent("UNIT_POWER_UPDATE")
./reviews/codex/iter1.md:609:timers.lua:69:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter1.md:611:alerts.lua:57:    ev:RegisterEvent("UNIT_SPELLCAST_START")
./reviews/codex/iter1.md:612:alerts.lua:58:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./reviews/codex/iter1.md:613:alerts.lua:59:    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./reviews/codex/iter1.md:614:alerts.lua:60:    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./reviews/codex/iter1.md:615:alerts.lua:61:    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./reviews/codex/iter1.md:616:alerts.lua:62:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter1.md:617:alerts.lua:63:    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./reviews/codex/iter1.md:618:alerts.lua:64:    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./reviews/codex/iter1.md:619:alerts.lua:65:    ev:RegisterEvent("UPDATE_STEALTH")
./reviews/codex/iter1.md:620:alerts.lua:66:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter1.md:625:/bin/zsh -lc "grep -RInE \"CastSpell|UseAction|RunScript|RunMacro|Click\\(|SpellStop|TargetUnit|InteractUnit|Pickup|PlaceAction|SetBinding|SecureActionButton|SetAttribute|C_UnitAuras|UnitAura|GetWeaponEnchantInfo|GetComboPoints|UNIT_POWER|UNIT_COMBO|GetSpellCooldown|UnitCastingInfo|UnitChannelInfo|OnUpdate|RegisterUnitEvent|C_AddOns|BackdropTemplate|PlaySound\" ." in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter1.md:628:./hud.lua:76:    -- event-driven updates (cheap; no OnUpdate polling for power)
./reviews/codex/iter1.md:631:./hud.lua:81:    ev:RegisterEvent("UNIT_POWER_UPDATE")
./reviews/codex/iter1.md:638:./timers.lua:69:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter1.md:641:./docs/DECISIONS.md:13:Success criteria for the addon: loads clean on a TBC Anniversary client, zero Lua errors, no FPS regression from OnUpdate loops, and **provably no spell-input automation** (Warden-safe).
./reviews/codex/iter1.md:650:./prompts/review_iter1.txt:1:You are reviewing a World of Warcraft TBC Classic (2.5.x, interface 20504) Rogue addon called Cutthroat. Lua 5.1 runtime, WoW API. GOAL: find correctness bugs, WoW-API misuse, performance issues (OnUpdate/CLEU loops), and ban-safety problems (it MUST NOT automate spell input). Be specific: file, line/function, the bug, the fix. Prioritize REAL bugs over style. Output a numbered list.
./reviews/codex/iter1.md:653:./prompts/review_iter1.txt:167:    -- event-driven updates (cheap; no OnUpdate polling for power)
./reviews/codex/iter1.md:656:./prompts/review_iter1.txt:172:    ev:RegisterEvent("UNIT_POWER_UPDATE")
./reviews/codex/iter1.md:663:./prompts/review_iter1.txt:271:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter1.md:671:./reviews/codex/iter1.md:14:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter1.md:679:./reviews/codex/iter1.md:413:    76	    -- event-driven updates (cheap; no OnUpdate polling for power)
./reviews/codex/iter1.md:682:./reviews/codex/iter1.md:418:    81	    ev:RegisterEvent("UNIT_POWER_UPDATE")
./reviews/codex/iter1.md:689:./reviews/codex/iter1.md:536:    69	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter1.md:713:   Fix: register `UNIT_COMBO_POINTS` and call `HUD:UpdateCP()` from it. Keep `PLAYER_TARGET_CHANGED`.
./reviews/codex/iter1.md:721:   Fix: refresh aura expiration data from `UNIT_AURA` for `player`/`target`; use `OnUpdate` only to render already-known countdowns.
./reviews/codex/iter1.md:762:   Fix: register `UNIT_COMBO_POINTS` and call `HUD:UpdateCP()` from it. Keep `PLAYER_TARGET_CHANGED`.
./reviews/codex/iter1.md:770:   Fix: refresh aura expiration data from `UNIT_AURA` for `player`/`target`; use `OnUpdate` only to render already-known countdowns.
./reviews/codex/iter6.md:14:Review the 'combo-point overcap glow' in hud.lua of this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1) Rogue addon. self.cpGlow is a BACKGROUND texture behind the combo pip row; HUD:UpdateCP() pulses its alpha (0.15+0.30*(0.5+0.5*sin(GetTime()*5))) when GetComboPoints('player','target')>=MAX_CP(5), else hides it. UpdateCP runs every render (~0.05s via timers:Render) and on power/target events. /cut finish toggle. READ-ONLY. Verify for TBC 2.5.x: (1) is 5 the correct combo cap (any effect raising it)? (2) GetComboPoints('player','target') signature; (3) BACKGROUND vs ARTWORK draw order so glow sits behind pips, and per-render SetAlpha cost; (4) math.sin/GetTime availability; (5) flicker when cp crosses 5; (6) UpdateCP called from both events and render — any conflict; (7) UX of pulsing at cp>=5. Read hud.lua. Numbered: file/function/bug/fix. Do NOT edit. Real bugs first.
./reviews/codex/iter6.md:24:/bin/zsh -lc 'rg -n "cpGlow|UpdateCP|GetComboPoints|MAX_CP|finish|Render|PLAYER_TARGET_CHANGED|UNIT_POWER|COMBO" hud.lua' in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter6.md:123:    -- "finish now" glow behind the pip row: pulses gold at max combo points so you
./reviews/codex/iter6.md:138:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter6.md:139:    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./reviews/codex/iter6.md:167:-- Move the regen-tick spark; called every render frame from timers:Render.
./reviews/codex/iter6.md:189:function HUD:UpdateCP()
./reviews/codex/iter6.md:194:    -- finish-now glow at max CP (pulsed; called every render so the sine is smooth)
./reviews/codex/iter6.md:197:        if cp >= MAX_CP and NS.db.cpFinishGlow then
./reviews/codex/iter6.md:212:    self:UpdateCP()
./reviews/codex/iter6.md:216:`hud.lua` has the glow exactly where described: pips are `ARTWORK`, glow is `BACKGROUND`, and `UpdateCP()` gates it on `cp >= MAX_CP` plus `NS.db.cpFinishGlow`. I’m checking the timer/slash wiring now so the event-vs-render interaction is grounded in the repo, not just the snippet.
./reviews/codex/iter2.md:115:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter2.md:116:    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
./reviews/codex/iter2.md:117:    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
./reviews/codex/iter2.md:118:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
./reviews/codex/iter2.md:256:f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter2.md:257:f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter2.md:374:    40	f:RegisterEvent("ADDON_LOADED")
./reviews/codex/iter2.md:375:    41	f:RegisterEvent("PLAYER_LOGIN")
./reviews/codex/iter2.md:495:    73	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter2.md:496:    74	    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
./reviews/codex/iter2.md:497:    75	    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
./reviews/codex/iter2.md:498:    76	    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
./reviews/codex/iter2.md:859:    83	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter2.md:860:    84	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./reviews/codex/iter2.md:873:    97	function HUD:UpdateCP()
./reviews/codex/iter2.md:886:   110	    self:UpdateCP()
./reviews/codex/iter2.md:892:     1	-- Timers: track YOUR finisher durations on the current target via combat log.
./reviews/codex/iter2.md:972:    81	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter2.md:976:    85	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter2.md:978:    87	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter2.md:982:    91	        self:Render()
./reviews/codex/iter2.md:1000:   109	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter2.md:1001:   110	function Timers:Render()
./reviews/codex/iter2.md:1003:   112	    NS.modules.hud:UpdateCP()
./reviews/codex/iter2.md:1099:    60	    ev:RegisterEvent("UNIT_SPELLCAST_START")
./reviews/codex/iter2.md:1100:    61	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./reviews/codex/iter2.md:1101:    62	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./reviews/codex/iter2.md:1102:    63	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./reviews/codex/iter2.md:1103:    64	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./reviews/codex/iter2.md:1104:    65	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter2.md:1105:    66	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./reviews/codex/iter2.md:1106:    67	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./reviews/codex/iter2.md:1107:    68	    ev:RegisterEvent("PLAYER_ENTERING_WORLD")  -- login/reload/zone -> check poison pre-pull
./reviews/codex/iter2.md:1109:    70	    ev:RegisterEvent("UPDATE_STEALTH")
./reviews/codex/iter2.md:1110:    71	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter2.md:1273:/bin/zsh -lc "glm-ask \"Reviewing WoW TBC Classic 2.5.x Lua addon cooldowns.lua. Need factual API/event compatibility: GetSpellInfo(id) return values in 2.5.x; GetSpellTexture(id) availability; GetSpellCooldown(name/id) signature and behavior for unlearned but valid spell names/ids; CooldownFrameTemplate methods SetCooldown Clear SetDrawEdge; whether RegisterEvent('PLAYER_TALENT_UPDATE') errors if nonexistent in 2.5.x and what safer talent event is; rogue spell IDs Vanish 1856 Evasion 5277 Sprint 2983 Blade Flurry 13877 Adrenaline Rush 13750 Cold Blood 14177 Preparation 14185; whether dur > 1.5 is safe GCD filter. Give only concrete compatibility bugs/fixes.\"" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter2.md:1396:    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter2.md:1397:    ev:RegisterEvent("SPELLS_CHANGED")          -- learned a rank
./reviews/codex/iter2.md:1398:    ev:RegisterEvent("PLAYER_TALENT_UPDATE")    -- respec (may not exist on all builds; harmless)
./reviews/codex/iter2.md:1399:    ev:RegisterEvent("CHARACTER_POINTS_CHANGED")-- talent point spent
./reviews/codex/iter2.md:1506:Here is the review of the `cooldowns.lua` module. The script correctly uses an OnUpdate-driven `CooldownFrameTemplate` and does not automate casting, adhering to the Warden-safe requirements.
./reviews/codex/iter2.md:1528:        -- TBC gets pet spells too, so we need to check the pet book if the spellbook finishes.
./reviews/codex/iter2.md:1551:* **Bug:** You registered `PLAYER_TALENT_UPDATE` with a comment guessing it *"may not exist on all builds; harmless"*. In TBC 2.5.x, this event **does not exist**. Calling `RegisterEvent` with a string that the API doesn't recognize throws a hard Lua runtime error (`'PLAYER_TALENT_UPDATE' is not a valid event name`), entirely breaking the addon's initialization sequence.
./reviews/codex/iter2.md:1556:    -- ev:RegisterEvent("PLAYER_TALENT_UPDATE")    
./reviews/codex/iter2.md:1596:* **Concrete Fix:** Instead of instantly triggering `Relayout()`, set a simple dirty-flag boolean to delay the layout update until the next `OnUpdate` cycle.
./reviews/codex/iter2.md:1610:    -- Add an OnUpdate to the event frame to process the throttle
./reviews/codex/iter2.md:1611:    ev:SetScript("OnUpdate", function()
./reviews/codex/iter2.md:1635:Review this WoW TBC Classic 2.5.x (interface 20504, Lua 5.1) Rogue addon 'Cutthroat' in the current directory. Read core.lua, hud.lua, timers.lua, alerts.lua, config.lua, Cutthroat.toc. Find: correctness bugs, WoW-API misuse (e.g. GetWeaponEnchantInfo signature, UnitAura/C_UnitAuras availability in 2.5.x, GetComboPoints, UNIT_POWER events, GetSpellCooldown), performance issues in OnUpdate loops, and any ban-safety risk (addon MUST NOT automate spell casting/input). For each finding give file, function/line, the bug, and the concrete fix. Prioritize real bugs over style. Do NOT edit files, just report a numbered list.
./reviews/codex/iter2.md:1731:    57	    ev:RegisterEvent("UNIT_SPELLCAST_START")
./reviews/codex/iter2.md:1732:    58	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
./reviews/codex/iter2.md:1733:    59	    ev:RegisterEvent("UNIT_SPELLCAST_STOP")
./reviews/codex/iter2.md:1734:    60	    ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
./reviews/codex/iter2.md:1735:    61	    ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
./reviews/codex/iter2.md:1736:    62	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter2.md:1737:    63	    ev:RegisterEvent("PLAYER_REGEN_ENABLED")   -- left combat
./reviews/codex/iter2.md:1738:    64	    ev:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entered combat
./reviews/codex/iter2.md:1739:    65	    ev:RegisterEvent("UPDATE_STEALTH")
./reviews/codex/iter2.md:1740:    66	    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
./reviews/codex/iter2.md:1855:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
./reviews/codex/iter2.md:1856:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter2.md:1864:            HUD:UpdateCP()
./reviews/codex/iter2.md:1938:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
./reviews/codex/iter2.md:1949:   Bug: `PLAYER_TALENT_UPDATE` is not safe for TBC Classic 2.5.x. If the client does not know the event, `RegisterEvent` can hard-error during init, so the cooldown module may never finish loading.  
./reviews/codex/iter2.md:1950:   Concrete fix: remove `ev:RegisterEvent("PLAYER_TALENT_UPDATE")`; keep `CHARACTER_POINTS_CHANGED` plus `SPELLS_CHANGED`.
./reviews/codex/iter2.md:1968:Verified OK: no cast/input automation found; module is read-only display only. `core.lua` init order is correct: `hud` is initialized before `cooldowns`, and TOC load order has `core.lua`, `hud.lua`, `timers.lua`, `cooldowns.lua`. Spell IDs listed are correct for the intended rogue abilities. `CooldownFrameTemplate`, `SetCooldown`, guarded `SetDrawEdge`, and `Clear` usage look acceptable for TBC Classic-style cooldown frames. Horizontal centering math is correct. Performance is fine: event-driven, no cooldown `OnUpdate` scan.
./reviews/codex/iter2.md:1974:   Bug: `PLAYER_TALENT_UPDATE` is not safe for TBC Classic 2.5.x. If the client does not know the event, `RegisterEvent` can hard-error during init, so the cooldown module may never finish loading.  
./reviews/codex/iter2.md:1975:   Concrete fix: remove `ev:RegisterEvent("PLAYER_TALENT_UPDATE")`; keep `CHARACTER_POINTS_CHANGED` plus `SPELLS_CHANGED`.
./reviews/codex/iter2.md:1993:Verified OK: no cast/input automation found; module is read-only display only. `core.lua` init order is correct: `hud` is initialized before `cooldowns`, and TOC load order has `core.lua`, `hud.lua`, `timers.lua`, `cooldowns.lua`. Spell IDs listed are correct for the intended rogue abilities. `CooldownFrameTemplate`, `SetCooldown`, guarded `SetDrawEdge`, and `Clear` usage look acceptable for TBC Classic-style cooldown frames. Horizontal centering math is correct. Performance is fine: event-driven, no cooldown `OnUpdate` scan.
./reviews/codex/iter3.md:14:Review the energy regen-tick predictor in this Cutthroat WoW TBC Classic 2.5.x (Lua 5.1, interface 20504) Rogue addon. Read hud.lua (energy.spark, HUD:UpdatePower gain-detection, HUD:UpdateEnergyTick) and how timers.lua Render calls it every ~0.05s. READ-ONLY feature, no automation. Verify for TBC 2.5.x: (1) is energy regen really a ~2.0s tick interval? (2) gain-detection via positive UnitPower delta — false resets from Relentless Strikes/Thistle Tea/refunds, does it matter? (3) UnitPower/UnitPowerMax + Enum.PowerType.Energy-or-3 fallback correctness; (4) spark SetPoint anchor math (TOP/BOTTOM pinned to TOPLEFT/BOTTOMLEFT + x offset) and end-clipping; (5) polling UpdatePower at 0.05s causing false resets/perf; (6) cap and Adrenaline Rush behavior; (7) nil-safety (lastEnergy nil first call). Numbered list: file, function, bug, concrete fix. Do NOT edit. Real bugs first.
./reviews/codex/iter3.md:26:/bin/zsh -lc "rg -n \"energy\\.spark|UpdatePower|UpdateEnergyTick|Render|UnitPower|UnitPowerMax|Enum\\.PowerType|Adrenaline|13750|lastEnergy\" hud.lua timers.lua" in /Users/creative/WoWAddons/Cutthroat
./reviews/codex/iter3.md:31:-- Timers: track YOUR finisher durations on the current target via combat log.
./reviews/codex/iter3.md:111:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter3.md:115:    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter3.md:117:    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter3.md:121:        self:Render()
./reviews/codex/iter3.md:139:-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter3.md:140:function Timers:Render()
./reviews/codex/iter3.md:142:    NS.modules.hud:UpdateCP()
./reviews/codex/iter3.md:274:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter3.md:275:    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./reviews/codex/iter3.md:294:-- Move the regen-tick spark; called every render frame from timers:Render.
./reviews/codex/iter3.md:311:function HUD:UpdateCP()
./reviews/codex/iter3.md:324:    self:UpdateCP()
./reviews/codex/iter3.md:394:    95	    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter3.md:395:    96	    ev:SetScript("OnEvent", function() HUD:UpdatePower(); HUD:UpdateCP() end)
./reviews/codex/iter3.md:414:   115	-- Move the regen-tick spark; called every render frame from timers:Render.
./reviews/codex/iter3.md:435:    81	    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/codex/iter3.md:439:    85	    -- OnUpdate only RENDERS the cached countdowns (4 bars, zero aura scans).
./reviews/codex/iter3.md:441:    87	    root:SetScript("OnUpdate", function(_, dt)
./reviews/codex/iter3.md:445:    91	        self:Render()
./reviews/codex/iter3.md:463:   109	-- Render cached countdowns + keep CP/energy fresh (cheap, runs every 0.05s).
./reviews/codex/iter3.md:464:   110	function Timers:Render()
./reviews/codex/iter3.md:466:   112	    NS.modules.hud:UpdateCP()
./reviews/codex/iter3.md:520:4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:87), `Timers:Render` plus [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:100), `HUD:UpdatePower`  
./reviews/codex/iter3.md:561:4. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:87), `Timers:Render` plus [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:100), `HUD:UpdatePower`  
./reviews/glm/iter4.md:5:*   **Function:** `Timers:Render()`
./reviews/glm/iter4.md:23:*   **Function:** `Timers:Render()`
./reviews/glm/iter4.md:36:*   **Function:** `Timers:Init()` and `Timers:Render()`
./reviews/glm/iter4.md:37:*   **Bug:** In `Render`, you call `b.marker:ClearAllPoints()` and `SetPoint` every single frame (0.05s). This forces the WoW UI engine to recalculate UI layout coordinates continuously, which is terrible for performance. Furthermore, when the bar hides (`b:Hide()`), the marker doesn't always hide because `OnHide` on the parent doesn't cascade to manual `Show()` calls on children unless hooked.
./reviews/glm/iter4.md:38:*   **Concrete Fix:** Set the point **ONCE** during `Init()`. In `Render`, only call `SetPoint` if you are un-hiding it. Hide the marker explicitly when the bar hides.
./reviews/glm/iter4.md:43:    -- In Render() replacing the marker logic:
./reviews/glm/iter4.md:62:*   **Function:** `Timers:Render()`
./reviews/glm/iter4.md:86:*   **Bug:** When you switch targets, `UNIT_AURA` or `PLAYER_TARGET_CHANGED` fires, triggering `Scan()`. If the new target doesn't have your Rupture, `c` becomes `nil` and the bar is hidden in `Render()`. However, `b.warned` (or the boolean state) is only reset on `OnHide`. If the user has a frame-delay where the marker is shown, or if `b:Hide()` is bypassed somehow, the marker's `mx` position from the *old* target remains stale.
./reviews/glm/iter5.md:44:    scan:RegisterEvent("UNIT_AURA") -- Standard for 2.5.x
./reviews/glm/iter5.md:45:    scan:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/glm/iter5.md:63:* **Function:** `Timers:Render`
./reviews/glm/iter5.md:90:1. **Thresholds/Talents:** Yes, all three cost 25 energy. Improved SnD strictly increases duration (and thus stat scaling), no standard rogue talent lowers finisher *cost*.
./reviews/glm/iter5.md:93:4. **Render Perf:** Flawless. A 50ms frame poll with condition-gated `SetStatusBarColor` calls is essentially 0.0% CPU impact. 
./reviews/glm/iter5.md:96:7. **Expose gating:** 100% correct. Expose Armor is a strictly 1-5 CP finisher.
./reviews/glm/iter1.md:10:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
./reviews/glm/iter1.md:11:    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
./reviews/glm/iter1.md:19:            HUD:UpdateCP()
./reviews/glm/iter1.md:93:    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
./reviews/glm/iter6.md:4:**file/function/bug:** `hud.lua/HUD:Init()` and `hud.lua/HUD:UpdateCP()`
./reviews/glm/iter6.md:10:**file/function/bug:** `hud.lua/HUD:Init()` and `hud.lua/HUD:UpdateCP()`
./reviews/glm/iter6.md:29:**file/function/bug:** `hud.lua/HUD:UpdateCP()`
./reviews/glm/iter6.md:34:function HUD:UpdateCP()
./reviews/glm/iter6.md:44:        if cp >= MAX_CP and NS.db.cpFinishGlow then
./reviews/glm/iter6.md:54:### 4. Event-Driven vs Render-Driven Execution
./reviews/glm/iter6.md:57:**analysis:** Calling `HUD:UpdateCP()` on power/target changes alongside rendering it on a ~0.05s timer does **not** cause a double-show problem. The `if not g:IsShown() then g:Show() end` guard efficiently prevents double-rendering, redundant frame visibility calls, or alpha stuttering. In fact, layering event calls over a render tick guarantees absolute visual responsiveness.
./reviews/glm/iter6.md:61:**file/function/bug:** `hud.lua/HUD:UpdateCP()`
./reviews/glm/iter6.md:63:**analysis:** Pulsing exactly at `cp >= 5` is an excellent, purely reactive UX choice for an overcap warning. Attempting to calculate whether a finisher is mathematically "worth using" earlier (e.g., at 4 CPs due to high Attack Power) crosses strictly into automation territory (rotation logic) which violates the addon's READ-ONLY constraints. 
./reviews/glm/iter2.md:1:Here is the review of the `cooldowns.lua` module. The script correctly uses an OnUpdate-driven `CooldownFrameTemplate` and does not automate casting, adhering to the Warden-safe requirements.
./reviews/glm/iter2.md:23:        -- TBC gets pet spells too, so we need to check the pet book if the spellbook finishes.
./reviews/glm/iter2.md:46:* **Bug:** You registered `PLAYER_TALENT_UPDATE` with a comment guessing it *"may not exist on all builds; harmless"*. In TBC 2.5.x, this event **does not exist**. Calling `RegisterEvent` with a string that the API doesn't recognize throws a hard Lua runtime error (`'PLAYER_TALENT_UPDATE' is not a valid event name`), entirely breaking the addon's initialization sequence.
./reviews/glm/iter2.md:51:    -- ev:RegisterEvent("PLAYER_TALENT_UPDATE")    
./reviews/glm/iter2.md:91:* **Concrete Fix:** Instead of instantly triggering `Relayout()`, set a simple dirty-flag boolean to delay the layout update until the next `OnUpdate` cycle.
./reviews/glm/iter2.md:105:    -- Add an OnUpdate to the event frame to process the throttle
./reviews/glm/iter2.md:106:    ev:SetScript("OnUpdate", function()
./reviews/glm/iter3.md:68:* **Answer:** No performance issues. Calling `UnitPower` and `SetValue` in a 0.05s `OnUpdate` loop is extremely cheap and highly standard for WoW addons. False resets are mitigated because `UNIT_POWER_FREQUENT` fires almost instantly anyway, so the `Render` loop isn't catching things faster than the event handler would. 

codex
The repo confirms `/cut finish` just flips `cpFinishGlow`, and render calls `UpdateCP()` on the throttled timer path. I don’t see a state race from the duplicate call sites; the only plausible issues are UX/perf nits, not correctness bugs.
exec
/bin/zsh -lc "nl -ba timers.lua | sed -n '108,150p'" in /Users/creative/WoWAddons/Cutthroat
 succeeded in 0ms:
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

exec
/bin/zsh -lc "nl -ba core.lua | sed -n '1,40p'" in /Users/creative/WoWAddons/Cutthroat
exec
/bin/zsh -lc "nl -ba config.lua | sed -n '1,90p'" in /Users/creative/WoWAddons/Cutthroat
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

codex
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

No real TBC 2.5.x correctness bugs found in the combo-point overcap glow.

1. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:8), `MAX_CP`
   Bug: none. `5` is correct for TBC Classic rogues. No TBC rogue talent/effect raises combo-point cap; later mechanics like Deeper Stratagem/modern Anticipation do not apply.
   Fix: none.

2. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:157), `HUD:UpdateCP`
   Bug: none. `GetComboPoints("player", "target")` is the correct unit-argument form for this client family.
   Fix: none.

3. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:80) and [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:92), `HUD:Init`
   Bug: none. Pips are `ARTWORK`, glow is `BACKGROUND`, same parent, so the glow draws behind the pips.
   Fix: none.

4. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:164), `HUD:UpdateCP`
   Bug: no functional issue. `SetAlpha` at ~20 Hz is cheap for one texture. If optimizing polish, cache last alpha or only update while shown, but this is not a real FPS risk.
   Fix: optional only.

5. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:165), `HUD:UpdateCP`
   Bug: none. Lua 5.1 has `math.sin`; WoW exposes `GetTime()`.
   Fix: none.

6. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:167), `HUD:UpdateCP`
   Bug: minor UX caveat, not correctness: glow hides instantly when CP drops below 5 or target disappears, so target death/change can feel abrupt.
   Fix: optional fade-out if desired; current behavior accurately reflects current CP.

7. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:137) plus [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:106), `Timers:Render` / event handler
   Bug: none. Event and render calls are idempotent; `Show()` is guarded by `IsShown()`, and the render path just keeps the sine pulse current.
   Fix: none.

UX verdict: pulsing at `cp >= 5` is right for an overcap warning. In TBC, `>= 5` is effectively `== 5`, and warning at max CP is a clean read-only cue without drifting into rotation advice.
tokens used
31,677
🧠🤝🔍🤖❓🆘🗣️➡️📝📏 Golden rules active.

No real TBC 2.5.x correctness bugs found in the combo-point overcap glow.

1. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:8), `MAX_CP`
   Bug: none. `5` is correct for TBC Classic rogues. No TBC rogue talent/effect raises combo-point cap; later mechanics like Deeper Stratagem/modern Anticipation do not apply.
   Fix: none.

2. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:157), `HUD:UpdateCP`
   Bug: none. `GetComboPoints("player", "target")` is the correct unit-argument form for this client family.
   Fix: none.

3. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:80) and [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:92), `HUD:Init`
   Bug: none. Pips are `ARTWORK`, glow is `BACKGROUND`, same parent, so the glow draws behind the pips.
   Fix: none.

4. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:164), `HUD:UpdateCP`
   Bug: no functional issue. `SetAlpha` at ~20 Hz is cheap for one texture. If optimizing polish, cache last alpha or only update while shown, but this is not a real FPS risk.
   Fix: optional only.

5. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:165), `HUD:UpdateCP`
   Bug: none. Lua 5.1 has `math.sin`; WoW exposes `GetTime()`.
   Fix: none.

6. [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:167), `HUD:UpdateCP`
   Bug: minor UX caveat, not correctness: glow hides instantly when CP drops below 5 or target disappears, so target death/change can feel abrupt.
   Fix: optional fade-out if desired; current behavior accurately reflects current CP.

7. [timers.lua](/Users/creative/WoWAddons/Cutthroat/timers.lua:137) plus [hud.lua](/Users/creative/WoWAddons/Cutthroat/hud.lua:106), `Timers:Render` / event handler
   Bug: none. Event and render calls are idempotent; `Show()` is guarded by `IsShown()`, and the render path just keeps the sine pulse current.
   Fix: none.

UX verdict: pulsing at `cp >= 5` is right for an overcap warning. In TBC, `>= 5` is effectively `== 5`, and warning at max CP is a clean read-only cue without drifting into rotation advice.
