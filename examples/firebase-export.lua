-----------------------------------------------------------------------
-- Modules
-----------------------------------------------------------------------
local FFAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/FFAPI.lua', true))()
local Robase = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Robase.lua', true))()
Robase.DefaultScope = "DEFAULT_SCOPE_HERE"
Robase.AuthenticationToken = "AUTH_TOKEN_HERE"

-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------
local Database = Robase:GetFirebase("DATABASE_NAME_HERE")

local config = Utilities:GetConfig()

local awayInfo = Utilities:GetTeam(config.GameInfo.Away)
local homeInfo = Utilities:GetTeam(config.GameInfo.Home)

FFAPI.Settings.AwayTeam = awayInfo
FFAPI.Settings.HomeTeam = homeInfo

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------
FFAPI.Events.ClockTick.Event:Connect(function()
    local uploadTable = {
        ["AwayScore"] = FFAPI.Values.AwayScore,
        ["HomeScore"] = FFAPI.Values.HomeScore,
        ["Clock"] = FFAPI.Values.Clock,
        ["Quarter"] = FFAPI.Values.Quarter,
        ["Status"] = FFAPI.Values.Status
    }
    
    Database:SetAsync("KEY_HERE",uploadTable,"PUT")
end)