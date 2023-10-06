-----------------------------------------------------------------------
-- Modules
-----------------------------------------------------------------------
local FFAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/FFAPI.lua', true))()
local Utilities = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Utilities.lua', true))()

-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------
local config = Utilities:GetConfig()

local awayInfo = Utilities:GetTeam(config.GameInfo.Away)
local homeInfo = Utilities:GetTeam(config.GameInfo.Home)

FFAPI.Settings.AwayTeam = awayInfo
FFAPI.Settings.HomeTeam = homeInfo

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------
-- Away Score Change
FFAPI.Events.AwayScored.Event:Connect(function(newScore, scoreReason)
    writefile("Away-Score.txt",newScore)
end)

-- Home Score Change
FFAPI.Events.HomeScored.Event:Connect(function(newScore, scoreReason)
    writefile("Home-Score.txt",newScore)
end)

-- PClock Change
FFAPI.Events.PlayClockTick.Event:Connect(function(newPClock, oldPClock)
    writefile("PClock.txt",":" .. newPClock)
end)

-- Quarter Change
FFAPI.Events.QuarterChange.Event:Connect(function(newQuarter, oldQuarter)
    writefile("Quarter.txt",Utilities:FormatNumber(newQuarter))
end)

-- Clock Change
FFAPI.Events.ClockTick.Event:Connect(function(newClock, oldClock)
    writefile("Clock.txt",Utilities:FormatClock(newClock))
end)

-- Status Change
FFAPI.Events.StatusChange.Event:Connect(function(newStatus, oldStatus)
    writefile("Clock.txt",newStatus)
end)
