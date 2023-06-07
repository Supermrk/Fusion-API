--[[
PLEASE NOTE: THIS SCRIPT IS FOR DEMO PURPOSES ONLY AND SHOWS HOW TO PUT THE MULTIPLE MODULES TOGETHER

This is the main script file that puts together all of the individual features.

The following is specificially programmed in here:
* Auto Highlight Clipping (and upload to Database)
* Discord Webhook Updates
* Twitch Chat Score Updates
* Updates Firebase for Realtime Statistics (using the Robase Wrapper)
* Uploads all collected game data for a AWS S3 Bucket at the end of the game
* Twitch OAuth2 Authentication
* Exporting Scorebug Values into a central CSV file

Credit to Arvoria for creating the Roblox Firebase Wrapper. Below is a link to the github repository
https://github.com/Arvoria/Roblox-Firebase

Created by Supermrk (@supermrk)
]]

local Services = {
    Players = game:GetService("Players"),
    UserInput = game:GetService("UserInputService"),
    HTTP = game:GetService("HttpService")
}

local Settings = {
    TWITCH_CLIENT_ID = "CLIENT_ID_HERE",
    TWITCH_CLIENT_SECRET = "CLIENT_SECRET_HERE",
    FIREBASE_DEFAULT_SCOPE = "FIREBASE_DEFAULT_SCOPE_HERE",
    FIREBASE_AUTH_TOKEN == "FIREBASE_AUTH_TOKEN_HERE",
    DISCORD_WEBHOOK_URL = "DISCORD_WEBHOOK_URL_HERE",
    CLIPS_DATABASE_API_URL = "CLIPS_DATABASE_API_URL_HERE",
    STATS_DATABASE_API_URL = "STATS_DATABASE_API_URL_HERE"
}

repeat wait() until game:IsLoaded()

-----------------------------------------------------------------------
-- Modules
-----------------------------------------------------------------------
--local FFAPI = require(script.FFAPI) For debugging purposes
--local Utilities = require(script.Utilities) For debugging purposes
--local Enviroment = require(script.Enviroment) For debugging purposes
local FFAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/FFAPI.lua', true))()
local Utilities = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Enviroment.lua', true))()
local Enviroment = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Utilities.lua', true))()
local Robase = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Robase.lua', true))()

-----------------------------------------------------------------------
-- Script API Declarations
-----------------------------------------------------------------------
local http = syn.request or http.request

local encrypt = syn and syn.crypt.encrypt or crypt.encrypt
local custom_encrypt = syn and syn.crypt.custom.encrypt or crypt.custom_encrypt
local custom_decrypt = syn and syn.crypt.custom.decrypt or crypt.custom_decrypt
local base64encode = syn and syn.crypt.base64.encode or crypt.base64encode
local base64decode = syn and syn.crypt.base64.decode or crypt.base64decode

local isfile = isfile
local readfile = readfile
local writefile = writefile
local setclipboard = sync and syn.write_clipboard or setclipboard

-----------------------------------------------------------------------
-- Final
-----------------------------------------------------------------------
local LocalPlayer = Services["Players"].LocalPlayer
local PlayerGUI = LocalPlayer.PlayerGui

-----------------------------------------------------------------------
-- Static
-----------------------------------------------------------------------
local Settings = {
    Config = {},
    Twitch = {
        Authorization = nil,
        ClientId = Settings.TWITCH_CLIENT_ID,
        ClientSecret = Settings.TWITCH_CLIENT_SECRET,
        UserID = "",
        LiveChannels = {}
    },
    AwayVariant = "Normal",
    HomeVariant = "Normal"
}

Robase.DefaultScope = Settings.FIREBASE_DEFAULT_SCOPE
Robase.AuthenticationToken = Settings.FIREBASE_AUTH_TOKEN
local Database = Robase:GetFirebase("")

-----------------------------------------------------------------------
-- Listeners
-----------------------------------------------------------------------
FFAPI.Events.PlayFinishedEvent.Event:Connect(function(playData)
    if (playData.desc == "") then
        return
    end

    if (Settings.Config.Settings.AutoTwitchClipping == "true" and Settings.Twitch.Authorization) then --Automatically clip highlights and upload them to a database
        if (Utilities:GetChannelID(Settings.Config.Settings.Channel)) then
            if (playData.yards_gained >= 35 or playData.turnover or playData.safety or playData.td_team ~= "" or playData.field_goal_result ~= "" or playData.extra_point_result ~= "" or playData.two_point_conv_result ~= "") then
                pcall(function()
                    local response = http({
                        Url = "https://api.twitch.tv/helix/clips?broadcaster_id=" .. Utilities:GetChannelID(Settings.Config.Settings.Channel) .. "&has_delay=true",
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["Authorization"] = "Bearer " .. Settings.Twitch.Authorization,
                            ["Client-Id"] = Settings.Twitch.ClientId
                        }
                    })

                    if (response.StatusCode == 202) then
                        local data = Services["HTTP"]:JSONDecode(response.Body)
                        if (#data.data > 0 and data.data[1].id) then
                            response = http({
                                Url = Settings.CLIPS_DATABASE_API_URL,
                                Method = "PUT",
                                Headers = {
                                    ["Content-Type"] = "application/json"
                                },
                                Body = Services["HTTP"]:JSONEncode({
                                    ["clipid"] = data.data[1].id,
                                    ["gameid"] = Settings.Config.GameInfo.Away .. "-" .. Settings.Config.GameInfo.Home .. "-" .. Settings.Config.GameInfo.Series .. "-" .. Settings.Config.GameInfo.Season,
                                    ["league"] = Settings.Config.GameInfo.League,
                                    ["desc"] = playData.desc,
                                    ["playlength"] = math.round((playData.play_end_time - playData.play_start_time)/0.1)*0.1,
                                    ["time"] = math.round(playData.play_start_time)
                                })
                            })

                            if (response.StatusCode == 200) then
                                print("[MAIN] Successfully clipped highlight.")
                            end
                        end
                    end
                end)
            end
        end
    end

    if (Settings.Config.Settings.SendToWebhook == "true") then --Sending Play-by-Play data to the Webhook
        pcall(function()
            local WebhookBody = {
                username = FFAPI.Settings.AwayTeam.Name .. " vs " .. FFAPI.Settings.HomeTeam.Name .. " Updates",
                ["avatar_url"] = "https://i.imgur.com/eaqjOs1.png",
                embeds = {{
                    type = "rich",
                    title = FFAPI.Settings.AwayTeam.Name .. " vs " .. FFAPI.Settings.HomeTeam.Name,
                    description = "> **Clock:** " .. Utilities:FormatNumber(playData.quarter) .. ", " .. Utilities:FormatClock(playData.clock) .. "\n> **Down:** " .. Utilities:FormatNumber(playData.down) .. " & " .. (playData.yards_to_go or "") .. "\n> **Play Description:** " .. playData.desc,
                    color = tonumber(0x002244),
                    fields = {
                        {
                            name = FFAPI.Settings.AwayTeam.Name .. " Stats:",
                            value = "**Score:** " .. FFAPI.Values.AwayScore .. "\n**Passing Yards:** " .. FFAPI.Values.AwayInfo.PASS .. "\n**Rushing Yards:** " .. FFAPI.Values.AwayInfo.RUSH .. "\n**Time Of Possession:** " .. Utilities:FormatClock(FFAPI.Values.AwayInfo.TOP),
                            inline = true
                        },
                        {
                            name = FFAPI.Settings.HomeTeam.Name .. " Stats:",
                            value = "**Score:** " .. FFAPI.Values.HomeScore .. "\n**Passing Yards:** " .. FFAPI.Values.HomeInfo.PASS .. "\n**Rushing Yards:** " .. FFAPI.Values.HomeInfo.RUSH .. "\n**Time Of Possession:** " .. Utilities:FormatClock(FFAPI.Values.HomeInfo.TOP),
                            inline = true
                        }
                    },
                    author = {
                        name = "@" .. Settings.Config.Settings.Channel,
                        url = "https://www.twitch.tv/" .. Settings.Config.Settings.Channel,
                        icon_url = "https://i.imgur.com/eaqjOs1.png"
                    },
                    footer = {
                        text = "Watch live on Twitch.tv/" .. Settings.Config.Settings.Channel
                    }
                }}
            }
            local request = http({
                Url = Settings.DISCORD_WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = Services["HTTP"]:JSONEncode(WebhookBody)
            })

            if (request.StatusCode == 200) then
                print("[MAIN] Successfully sent Discord Webhook Update.")
            end
        end)
    end

    if (Settings.Config.Settings.AutoTwitchUpdates == "true") then --Sending Score Updates to the other RSPN Chats
        if (Settings.Twitch.Authorization) then
            local playType = nil
            if not (playData.td_team == "") then
                playType = "TOUCHDOWN"
            elseif (playData.turnover) then
                playType = "TURNOVER"
            elseif (playData.safety) then
                playType = "SAFETY"
            elseif (playData.field_goal_result == FFAPI.Enums.FieldGoalResult.COMPLETE) then
                playType = "FIELD GOAL"
            end

            if (playType) then
                local RequestBody = {
                    message = "@" .. Settings.Config.Settings.Channel .. " Update: " .. FFAPI.Settings.AwayTeam.Name .. " " .. FFAPI.Values.AwayScore .. " vs " .. FFAPI.Settings.HomeTeam.Name .. " " .. FFAPI.Values.HomeScore .. " ►►►" .. playType .. " " .. string.upper(playData.pos_team) .. "◄◄◄",
                    color = "blue"
                }
                RequestBody = Services["HTTP"]:JSONEncode(RequestBody)
                for i,v in ipairs(Settings.Twitch.LiveChannels) do
                    pcall(function()
                        http({
                            Url = "https://api.twitch.tv/helix/chat/announcements?broadcaster_id=" .. v .. "&moderator_id=" .. Utilities:GetRSPNChannels()["RoSportProgrammingNetwork"],
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Authorization"] = "Bearer " .. Settings.Twitch.Authorization,
                                ["Client-Id"] = Settings.Twitch.ClientId
                            },
                            Body = RequestBody
                        })
                        print("[MAIN] Successfully sent Auto Twitch Update to " .. v .. ".")
                    end)
                end
            end
        end
    end
end)

FFAPI.Events.ClockTick.Event:Connect(function()
    if (Settings.Config.Settings.UploadToRealtimeAPI == "true") then --Uploading Game Information to Firebase
        pcall(function()
            local uploadTable = {
                ["awayInfo"] = {
                    ["abbreviation"] = FFAPI.Settings.AwayTeam.Abbreviation,
                    ["city"] = FFAPI.Settings.AwayTeam.City,
                    ["color"] = FFAPI.Settings.AwayTeam.Colors.Normal.Main,
                    ["name"] = FFAPI.Settings.AwayTeam.Name
                },
                ["awayScore"] = FFAPI.Values.AwayScore,
                ["awayStats"] = {},
                ["awayTeamStats"] = {
                    ["pass"] = FFAPI.Values.AwayInfo.PASS,
                    ["rush"] = FFAPI.Values.AwayInfo.RUSH,
                    ["top"] = FFAPI.Values.AwayInfo.TOP,
                    ["turn"] = FFAPI.Values.AwayInfo.TURN+FFAPI.Values.AwayInfo.TURN_ON_DOWNS,
                    ["win"] = FFAPI.Values.AwayInfo.WIN
                },
                ["clock"] = FFAPI.Values.Clock,
                ["homeInfo"] = {
                    ["abbreviation"] = FFAPI.Settings.HomeTeam.Abbreviation,
                    ["city"] = FFAPI.Settings.HomeTeam.City,
                    ["color"] = FFAPI.Settings.HomeTeam.Colors.Normal.Main,
                    ["name"] = FFAPI.Settings.HomeTeam.Name
                },
                ["homeScore"] = FFAPI.Values.HomeScore,
                ["homeStats"] = {},
                ["homeTeamStats"] = {
                    ["pass"] = FFAPI.Values.HomeInfo.PASS,
                    ["rush"] = FFAPI.Values.HomeInfo.RUSH,
                    ["top"] = FFAPI.Values.HomeInfo.TOP,
                    ["turn"] = FFAPI.Values.HomeInfo.TURN+FFAPI.Values.HomeInfo.TURN_ON_DOWNS,
                    ["win"] = FFAPI.Values.HomeInfo.WIN
                },
                ["playerData"] = {},
                ["quarter"] = FFAPI.Values.Quarter
            }

            Database:SetAsync(Settings.Config.Settings.Channel,uploadTable,"PUT")
        end)
    end
end)

FFAPI.Events.GameEndEvent.Event:Connect(function(homeWin)
    if (Settings.Config.Settings.UploadStatsToDatabase == "true") then --Uploading stats the the Database
        local gameInfo = {
            AwayScore = FFAPI.Values.AwayScore,
            AwayInfo = FFAPI.Values.AwayInfo,
            HomeScore = FFAPI.Values.HomeScore,
            HomeInfo = FFAPI.Values.HomeInfo,
            PlayerStats = FFAPI.Values.PlayerStats
        }

        if (FFAPI.Values.AwayInfo.TOP > 300 and FFAPI.Values.HomeInfo.TOP > 300) then
            local succ = pcall(function()
                local request = http({
                    Url = Settings.STATS_DATABASE_API_URL .. string.upper(Settings.Config.GameInfo.Away) .. "-" .. string.upper(Settings.Config.GameInfo.Home) .. "-" .. string.upper(Settings.Config.GameInfo.Series) .. "-" .. string.upper(Settings.Config.GameInfo.Season) .. ".json",
                    Method = "PUT",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = Services["HTTP"]:JSONEncode(gameInfo)
                })
                if (request.StatusCode == 200) then
                    print("[MAIN] Successfully saved game data.")
                else
                    print("[MAIN] Failed to sae game data.")
                end
            end)
            if not (succ) then
                print("[MAIN] Failed to sae game data.")
            end
        end
    end
end)

FFAPI.Events.Touchdown.Event:Connect(function(isHomeTeam)
    Enviroment:Touchdown(isHomeTeam)
end)

LocalPlayer.CharacterAdded:Connect(function()
    PlayerGUI:WaitForChild("MainGui").Scoreboard.Visible = false
    PlayerGUI:WaitForChild("MainGui").LeftMenu.Visible = false
end)

Services["UserInput"].InputBegan:Connect(function(input)
    local key = input.KeyCode

    if (key == Enum.KeyCode.F3) then
        print("[MAIN] Successfully toggled the Away color variant.")
        if (Settings.AwayVariant == "Normal") then
            Settings.AwayVariant = "Alternate"
        else
            Settings.AwayVariant = "Normal"
        end
    end

    if (key == Enum.KeyCode.F4) then
        print("[MAIN] Successfully toggled the Home color variant.")
        if (Settings.HomeVariant == "Normal") then
            Settings.HomeVariant = "Alternate"
        else
            Settings.HomeVariant = "Normal"
        end
    end

    if (key == Enum.KeyCode.F5) then
        local awayInfo = FFAPI.Settings.AwayTeam
        local homeInfo = FFAPI.Settings.HomeTeam

        FFAPI.Settings.AwayTeam = homeInfo
        FFAPI.Settings.HomeTeam = awayInfo
        Enviroment:SetTeams(homeInfo,awayInfo)
        print("[MAIN] Successfully switched the teams.")
    end
end)
-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------
Settings.Config = Utilities:GetConfig()
print(game:GetService("HttpService"):JSONEncode(Settings.Config))
local AwayInfo = Utilities:GetTeam(Settings.Config.GameInfo.Away)
local HomeInfo = Utilities:GetTeam(Settings.Config.GameInfo.Home)
if (AwayInfo == nil or HomeInfo == nil) then
    LocalPlayer:Kick("Incorrect Team Names.")
    return
end

FFAPI.Settings.AwayTeam = AwayInfo
FFAPI.Settings.HomeTeam = HomeInfo
print("[MAIN] Successfully got the team info.")

if not (Utilities:GetChannelID(Settings.Config.Settings.Channel)) then
    LocalPlayer:Kick("Incorrect Channel in Config.")
    return
end

pcall(function()
    local split = string.split(Settings.Config.Settings.AssetsFilePath,"\\")
    split = split[#split-1]
    Enviroment.Settings.AssetsFolder = split .. "/"
end)
Enviroment:SetTeams(AwayInfo,HomeInfo)

PlayerGUI.MainGui.Scoreboard.Visible = false
PlayerGUI.MainGui.LeftMenu.Visible = false

-- Twitch Authentication ----------------------------------------------
if (Settings.Config.Settings.AutoTwitchUpdates == "true" or Settings.Config.Settings.AutoTwitchClipping == "true") then
    pcall(function()
        if (isfile("credentials.data")) then -- Checking if there's an auth code already saved
            local success, response = pcall(function()
                local credentials = readfile("credentials.data")
                credentials = custom_decrypt(credentials,"JuS618gxF7wVOrD8g7MQOgoQO2REiFq6UcLTzWS2nHc=","RSPN","CBC")
                credentials = base64decode(credentials)
                credentials = Services["HTTP"]:JSONDecode(credentials)

                if (credentials.access_token and credentials.refresh_token) then
                    local response = http({
                        Url = "https://id.twitch.tv/oauth2/validate",
                        Method = "GET",
                        Headers = {
                            Authorization = "OAuth " .. credentials.access_token
                        }
                    })

                    if (response.StatusCode == 200) then
                        Settings.Twitch.Authorization = credentials.access_token
                        print("[MAIN] Twitch authentication complete.")
                    else -- If it's expired, we use the refresh token to generate a new one
                        local response2 = http({
                            Url = "https://id.twitch.tv/oauth2/token",
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/x-www-form-urlencoded"
                            },
                            Body = "client_id=" .. Settings.Twitch.ClientId .. "&client_secret=" .. Settings.Twitch.ClientSecret .. "&grant_type=refresh_token&refresh_token=" .. credentials.refresh_token
                        })

                        if (response2.StatusCode == 200) then
                            response2 = Services["HTTP"]:JSONDecode(response2.Body)

                            if (response2["access_token"] and response2["refresh_token"]) then
                                Settings.Twitch.Authorization = response2["access_token"]

                                local json = {
                                    access_token = response2["access_token"],
                                    refresh_token = response2["refresh_token"]
                                }
                                json = Services["HTTP"]:JSONEncode(json)
                                writefile("credentials.data",custom_encrypt(base64encode(json),"JuS618gxF7wVOrD8g7MQOgoQO2REiFq6UcLTzWS2nHc=","RSPN","CBC"))
                                print("[MAIN] Twitch authentication complete.")
                            end
                        end
                    end
                end
            end)
        end
        -- If we didn't get a code, we either use the provded AuthCode in the config, or set the users clipboard to the link
        if (Settings.Config.Settings.TwitchAuthCode and string.len(Settings.Config.Settings.TwitchAuthCode) > 10 and Settings.Twitch.Authorization == nil) then
            local response = http({
                Url = "https://id.twitch.tv/oauth2/token?client_id=" .. Settings.Twitch.ClientId .. "&client_secret=" .. Settings.Twitch.ClientSecret .. "&code=" .. Settings.Config.Settings.TwitchAuthCode .. "&grant_type=authorization_code&redirect_uri=http://localhost:3000",
                Method = "POST"
            })

            if (response.StatusCode == 200) then
                response = Services["HTTP"]:JSONDecode(response.Body)

                if (response["access_token"] and response["refresh_token"]) then
                    Settings.Twitch.Authorization = response["access_token"]

                    local json = {
                        access_token = response["access_token"],
                        refresh_token = response["refresh_token"]
                    }
                    json = Services["HTTP"]:JSONEncode(json)
                    writefile("credentials.data",encrypt(base64encode(json),"JuS618gxF7wVOrD8g7MQOgoQO2REiFq6UcLTzWS2nHc=","RSPN","CBC"))
                    print("[MAIN] Twitch authentication complete.")

                    return
                end
            end
        end
        if not (Settings.Twitch.Authorization) then
            setclipboard("https://id.twitch.tv/oauth2/authorize?response_type=code&client_id=" .. Settings.Twitch.ClientId .."&redirect_uri=http://localhost:3000&scope=clips%3Aedit+moderator%3Amanage%3Aannouncements")
            print("[MAIN] Twitch authentication failed. Please check the URL in your clipboard.")
        end
    end)
end

if (Settings.Twitch.Authorization) then
    -- Twitch Updates Setup -------------------------------------------
    if (Settings.Config.Settings.AutoTwitchUpdates == "true") then
        pcall(function()
            local channelsList = Utilities:GetRSPNChannels()
            local channels = ""
            for i,v in pairs(channelsList) do
                if (channels == "") then
                    channels = "user_login=" .. i
                else
                    channels = channels .. "&user_login=" .. i
                end
            end

            local response = http({
                Url = "https://api.twitch.tv/helix/streams?" .. channels .. "&type=live",
                Headers = {
                    Authorization = "Bearer " .. Settings.Twitch.Authorization,
                    ["Client-Id"] = Settings.Twitch.ClientId
                }
            })

            if (response.StatusCode == 200) then
                local data = Services["HTTP"]:JSONDecode(response.Body)
                if (data.data) then
                    data = data.data

                    for i,v in ipairs(data) do
                        if (v.id) then
                            table.insert(Settings.Twitch.LiveChannels,v.id)
                            print("[MAIN] Found " .. v.id .. " live.")
                        end
                    end
                end
                print("[MAIN] Set live Twitch channels.")
            end
        end)
    end
end


-----------------------------------------------------------------------
-- Loop
-----------------------------------------------------------------------
while (wait(0.5)) do
    local csv = "Rows,Name,City,Abbreviation,Logos,Score,ScoreDifference,Possession,Timeouts,MainColor,LighterColor,PassingYards,RushingYards,Turnovers,TimeOfPossession,DrivePlays,DriveYards,DriveTOP,Timers,Game\n"
    csv = csv .. "Away," .. -- Setting the Away Values
    FFAPI.Settings.AwayTeam.Name .. "," .. 
    FFAPI.Settings.AwayTeam.City .. "," .. 
    FFAPI.Settings.AwayTeam.Abbreviation .. "," ..
    Settings.Config.Settings.AssetsFilePath .. FFAPI.Settings.AwayTeam.City .. " " .. FFAPI.Settings.AwayTeam.Name .. "\\Animation\\0001.png," ..
    FFAPI.Values.AwayScore .. "," ..
    FFAPI.Values.AwayScore - FFAPI.OldValues.AwayScore .. "," ..
    tostring(not FFAPI.Values.Possession) .. "," ..
    FFAPI.Values.AwayTimeouts .. "," ..
    FFAPI.Settings.AwayTeam.Colors[Settings.AwayVariant].Main .. "," ..
    FFAPI.Settings.AwayTeam.Colors[Settings.AwayVariant].Light .. "," ..
    FFAPI.Values.AwayInfo.PASS .. "," ..
    FFAPI.Values.AwayInfo.RUSH .. "," ..
    FFAPI.Values.AwayInfo.TURN+FFAPI.Values.AwayInfo.TURN_ON_DOWNS .. "," ..
    Utilities:FormatClock(FFAPI.Values.AwayInfo.TOP) .. "," ..
    FFAPI.Values.CurrentDrive.PLAYS .. "," ..
    FFAPI.Values.CurrentDrive.YARDS .. "," ..
    Utilities:FormatClock(FFAPI.Values.CurrentDrive.TOP) .. "," ..
    Utilities:FormatNumber(FFAPI.Values.Quarter) .. " " .. Utilities:FormatClock(FFAPI.Values.Clock) .. "," ..
    FFAPI.Values.Status .. "\n"
    csv = csv .. "Home," .. -- Setting the Home Values
    FFAPI.Settings.HomeTeam.Name .. "," .. 
    FFAPI.Settings.HomeTeam.City .. "," .. 
    FFAPI.Settings.HomeTeam.Abbreviation .. "," ..
    Settings.Config.Settings.AssetsFilePath .. FFAPI.Settings.HomeTeam.City .. " " .. FFAPI.Settings.HomeTeam.Name .. "\\Animation\\0001.png," ..
    FFAPI.Values.HomeScore .. "," ..
    FFAPI.Values.HomeScore - FFAPI.OldValues.HomeScore .. "," ..
    tostring(FFAPI.Values.Possession) .. "," ..
    FFAPI.Values.HomeTimeouts .. "," ..
    FFAPI.Settings.HomeTeam.Colors[Settings.HomeVariant].Main .. "," ..
    FFAPI.Settings.HomeTeam.Colors[Settings.HomeVariant].Light .. "," ..
    FFAPI.Values.HomeInfo.PASS .. "," ..
    FFAPI.Values.HomeInfo.RUSH .. "," ..
    FFAPI.Values.HomeInfo.TURN+FFAPI.Values.HomeInfo.TURN_ON_DOWNS .. "," ..
    Utilities:FormatClock(FFAPI.Values.HomeInfo.TOP) .. "," ..
    FFAPI.Values.CurrentDrive.PLAYS .. "," ..
    FFAPI.Values.CurrentDrive.YARDS .. "," ..
    Utilities:FormatClock(FFAPI.Values.CurrentDrive.TOP) .. "," ..
    FFAPI.Values.PlayClock .. "," ..
    Utilities:FormatNumber(FFAPI.Values.Quarter) .. "\n"

    writefile("LFG-Values.csv",csv)
end
