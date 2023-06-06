-----------------------------------------------------------------------
-- Modules
-----------------------------------------------------------------------
local FFAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/FFAPI.lua', true))()
local Utilities = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Enviroment.lua', true))()

-----------------------------------------------------------------------
-- Script API Declarations
-----------------------------------------------------------------------
local http = syn.request or http.request

-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------
local Webhook_URL = "DISCORD_WEBHOOK_URL_HERE"

local config = Utilities:GetConfig()

local awayInfo = Utilities:GetTeam(config.GameInfo.Away)
local homeInfo = Utilities:GetTeam(config.GameInfo.Home)

FFAPI.Settings.AwayTeam = awayInfo
FFAPI.Settings.HomeTeam = homeInfo

-----------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------
function ScoreNotification(teamName : String, teamScore : number)
    local WebhookBody = {
        ["username"] = "Score Updates",
        ["embeds"] = {{
            ["type"] = "rich",
            ["title"] = teamName .. " has scored!",
            ["description"] = "New Score: " .. teamScore,
            ["color"] = tonumber(0x002244), -- You can replace the "002244" with a hex code
            ["footer"] = {
                ["text"] = "Watch live at twitch.tv/rosportprogrammingnetwork"
            }
        }}
    }

    local request = http({
        ["Url"] = Webhook_URL,
        ["Method"] = "POST",
        ["Headers"] = {
            ["Content-Type"] = "application/json"
        },
        ["Body"] = game:GetService("HttpService"):JSONEncode(WebhookBody)
    })
    
    if (request.StatusCode == 200) then
        print("Webhook Successfully Sent!")
    end
end

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------
-- Away Score Change
FFAPI.Events.AwayScored.Event:Connect(function(newScore, scoreReason)
    ScoreNotification(FFAPI.Settings.AwayTeam.Name,newScore)
end)

-- Home Score Change
FFAPI.Events.HomeScored.Event:Connect(function(newScore, scoreReason)
    ScoreNotification(FFAPI.Settings.HomeTeam.Name,newScore)
end)