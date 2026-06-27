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
    print("  |cffffff00/cut snd N|r        SnD warning seconds")
    print("  |cffffff00/cut rup N|r        Rupture warning seconds")
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
        elseif cmd == "snd" then
            local n = tonumber(arg); if n then db.sndWarn = n; Print("SnD warn at " .. n .. "s") end
        elseif cmd == "rup" then
            local n = tonumber(arg); if n then db.ruptureWarn = n; Print("Rupture warn at " .. n .. "s") end
        elseif cmd == "reset" then
            db.point = { "CENTER", nil, "CENTER", 0, -180 }
            Print("position reset (/reload to apply)")
        elseif cmd == "status" then
            Print(string.format("locked %s | scale %.2f | kick %s | poison %s | opener %s | sound %s | ticks %s | spark %s | zone %s | smart %s",
                tostring(db.locked), db.scale, on(db.kickAlert), on(db.poisonCheck), on(db.openerHint), on(db.sound), on(db.energyTicks), on(db.tickSpark), on(db.refreshZone), on(db.smartRefresh)))
        else
            Help()
        end
        NS.CallAll("Refresh")
    end
end

function Config:Refresh() end
