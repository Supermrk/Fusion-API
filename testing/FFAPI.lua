--[[
This module handles collecting all of the actual game data and exposing it for use in other scripts.

This file contains the following features:
* Advanced data collection for every play
* Bindable Events for almost all possible events in the game
* Old and Current Values for almost any value exposed by the game
* A list of each team's drives, and each play in that drive
* Player Stats Collection (everything returned by the normal stats menu)

Created by Supermrk (@supermrk)
]]

local Services = {
    Storage = game:GetService("ReplicatedStorage"),
    HTTP = game:GetService("HttpService"),
    Players = game:GetService("Players")
}

-----------------------------------------------------------------------
-- Script API Declarations
-----------------------------------------------------------------------
local request = request or (syn and syn.request) or (http and http.request) or http_request

-----------------------------------------------------------------------
-- Final
-----------------------------------------------------------------------
local FFValues = Services["Storage"].Flags
local LocalPlayer = Services["Players"].LocalPlayer


-----------------------------------------------------------------------
-- Static
-----------------------------------------------------------------------
local module = {
    Settings = {
        GameID = nil,
        AwayTeam = {Abbreviation = "VOID",Name = "NONE",City = "NONE"},
        AwayRank = 0,
        HomeTeam = {Abbreviation = "VOID",Name = "NONE",City = "NONE"},
        HomeRank = 0,
        LastPlayID = 0,
        LastDriveID = 1,
        SwitchedPossession = false
    },
    Values = {
        AwayScore = FFValues.AwayScore.Value,
        AwayInfo = {
            DRIVE = 1,
            DRIVE_PLAYS = {},
            PASS = 0,
            RUSH = 0,
            TOP = 0,
            TURN = 0,
            TURN_ON_DOWNS = 0,
            WIN = 50
        },
        HomeScore = FFValues.HomeScore.Value,
        HomeInfo = {
            DRIVE = 1,
            DRIVE_PLAYS = {},
            PASS = 0,
            RUSH = 0,
            TOP = 0,
            TURN = 0,
            TURN_ON_DOWNS = 0,
            WIN = 50
        },
        CurrentDrive = {
            PLAYS = 0,
            TOP = 0,
            YARDS = 0
        },
        PlayerStats = {},
        AwayTimeouts = FFValues.AwayTos.Value,
        HomeTimeouts = FFValues.HomeTos.Value,
        PlayClock = FFValues.Playclock.Value,
        Quarter = FFValues.Quarter.Value,
        Clock = FFValues.TimerTag.Value,
        Status = FFValues.StatusTag.Value,
        Possession = true -- True == Home
    },
    OldValues = {
        AwayScore = FFValues.AwayScore.Value,
        AwayScoredReason = 5,
        HomeScore = FFValues.HomeScore.Value,
        HomeScoredReason = 5,
        AwayTimeouts = FFValues.AwayTos.Value,
        HomeTimeouts = FFValues.HomeTos.Value,
        PlayClock = FFValues.Playclock.Value,
        Quarter = FFValues.Quarter.Value,
        Clock = FFValues.TimerTag.Value,
        Status = FFValues.StatusTag.Value,
        Possession = true
    },
    Events = {
        AwayScored = Instance.new("BindableEvent"),
        HomeScored = Instance.new("BindableEvent"),
        AwayTimeoutChange = Instance.new("BindableEvent"),
        HomeTimeoutChange = Instance.new("BindableEvent"),
        PlayClockTick = Instance.new("BindableEvent"),
        QuarterChange = Instance.new("BindableEvent"),
        ClockTick = Instance.new("BindableEvent"),
        StatusChange = Instance.new("BindableEvent"),
        Safety = Instance.new("BindableEvent"),
        Touchdown = Instance.new("BindableEvent"),
        FieldGoal = Instance.new("BindableEvent"),
        ExtraPoint = Instance.new("BindableEvent"),
        TwoPoint = Instance.new("BindableEvent"),
        KickMissed = Instance.new("BindableEvent"),
        BallThrown = Instance.new("BindableEvent"),
        BallCaught = Instance.new("BindableEvent"),
        PrePlayEvent = Instance.new("BindableEvent"),
        InPlayEvent = Instance.new("BindableEvent"),
        AfterPlayEvent = Instance.new("BindableEvent"),
        PlayFinishedEvent = Instance.new("BindableEvent"),
        PlayerStatsUpdated = Instance.new("BindableEvent"),
        GameEndEvent = Instance.new("BindableEvent")
    },
    LastEvents = {
        AwayScored = tick(),
        HomeScored = tick(),
        AwayTimeoutChange = tick(),
        HomeTimeoutChange = tick(),
        PlayClockTick = tick(),
        QuarterChange = tick(),
        ClockTick = tick(),
        StatusChange = tick(),
        Safety = tick(),
        Touchdown = tick(),
        FieldGoal = tick(),
        ExtraPoint = tick(),
        TwoPoint = tick(),
        KickMissed = tick(),
        BallThrown = tick(),
        BallCaught = tick(),
        PrePlayEvent = tick(),
        InPlayEvent = tick(),
        AfterPlayEvent = tick(),
        PlayFinishedEvent = tick(),
        PlayerStatsUpdated = tick(),
        GameEndEvent = tick()
    },
    Enums = {
        ScoreType = {
            EXTRA_POINT = 0,
            TWO_POINT = 1,
            SAFETY = 2,
            FIELD_GOAL = 3,
            TOUCHDOWN = 4,
            OTHER = 5
        },
        Location = {
            LEFT = "LEFT",
            MIDDLE = "MIDDLE",
            RIGHT = "RIGHT"
        },
        PassResult = {
            COMPLETE = "complete",
            INCOMPLETE = "incomplete",
            INTERCEPTION = "interception"
        },
        FieldGoalResult = {
            COMPLETE = "good",
            INCOMPLETE = "no good"
        }
    }
}

local CURRENT_PLAY_INFO = {
    play_id = module.Settings.LastPlayID+1,
    play_start_time = 0,
    play_end_time = 0,
    game_id = module.Settings.GameID,
    home_team = module.Settings.HomeTeam.Abbreviation,
    away_team = module.Settings.AwayTeam.Abbreviation,
    pos_team = "",
    pos_win = 50,
    side_of_field = "",
    yardline_100 = 0,
    clock = FFValues.TimerTag.Value,
    quarter = FFValues.Quarter.Value,
    drive = 0,
    down = 0,
    yards_to_go = 0,
    desc = "",
    play_maker_id = 0,
    yards_gained = 0,
    kickoff = false,
    touchback = false,
    turnover = false,
    fumble = false,
    safety = false,
    qb = 3292436585,
    qb_run = false,
    qb_pass = false,
    pass_location = "",
    pass_result = "",
    run_location = "",
    field_goal_result = "",
    kick_distance = 0,
    extra_point_result = "",
    two_point_conv_result = "",
    home_timeouts_remaining_before = FFValues.HomeTos.Value,
    away_timeouts_remaining_before = FFValues.AwayTos.Value,
    home_timeouts_remaining_after = 0,
    away_timeouts_remaining_after = 0,
    timeout = false,
    timeout_team = "",
    td_team = "",
    home_before_score = FFValues.HomeScore.Value,
    away_before_score = FFValues.AwayScore.Value,
    home_after_score = 0,
    away_after_score = 0,
    first_down = false
}

-----------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------
function GetUserIDFromName(name : string)
    for i,v in ipairs(Services["Players"]:GetPlayers()) do
        if (v.Name == name) then
            return v.UserId
        end
    end
end

function FormatClock(seconds : number)
    local minutes = (seconds - seconds%60)/60
    seconds = seconds-minutes*60
    local zero = ""
    if (seconds < 10) then
        zero = "0"
    end

    return minutes .. ":" .. zero .. seconds
end

function GetWinPercentage(team : string)
    local data
    local isHome = FFValues.PossessionTag.Value == FFValues.Home.Value.Name

    local yardsToGo = string.split(FFValues.StatusTag.Value, " & ")
    local fieldPos = FFValues.YardTag.Value
    local field = "team"

    if (FFValues.ArrowUp.Value) then
        fieldPos = fieldPos+50
        field = "opp"
    end

    if (yardsToGo[2] and tonumber(yardsToGo[2])) then
        yardsToGo = tonumber(yardsToGo[2])
    else
        yardsToGo = 1
    end

    local seconds = FFValues.TimerTag.Value
    local minutes = (seconds - seconds%60)/60
    seconds = seconds - minutes*60

    if (isHome) then
        local vegasLine = (module.Settings.HomeRank-module.Settings.AwayRank)/4
        data = request({
            Url = "https://www.pro-football-reference.com/boxscores/win_prob.cgi?request=1&score_differential=" .. FFValues.HomeScore.Value - FFValues.AwayScore.Value .. "&vegas_line=" .. vegasLine .. "&quarter=" .. FFValues.Quarter.Value .."&minutes=" .. minutes .. "&seconds=" .. seconds .. "&field=" .. field .. "&yds_from_goal=" .. fieldPos .."&yds_to_go=" .. yardsToGo,
        })
    else
        local vegasLine = (module.Settings.AwayRank-module.Settings.HomeRank)/4
        data = request({
            Url = "https://www.pro-football-reference.com/boxscores/win_prob.cgi?request=1&score_differential=" .. FFValues.AwayScore.Value - FFValues.HomeScore.Value .. "&vegas_line=" .. vegasLine .. "&quarter=" .. FFValues.Quarter.Value .."&minutes=" .. minutes .. "&seconds=" .. seconds .. "&field=" .. field .. "&yds_from_goal=" .. fieldPos .."&yds_to_go=" .. yardsToGo
        })
    end

    local win = module.Values.AwayInfo.WIN
    if (isHome) then
        win = module.Values.HomeInfo.WIN
    end

    if (data) then
        pcall(function()
            local split1 = string.split(data.Body, "<h3>Win Probability: ")[2]
            local split2 = string.split(split1, "%</h3>")[1]
            local split3 = string.split(split2,".")[1]


            if (tonumber(split3)) then
                win = tonumber(split3)
            end
        end)
    end

    local requestingHomeTeam = team == module.Settings.HomeTeam.Abbreviation
    if (requestingHomeTeam) then
        if (isHome) then
            return win
        else
            return 100-win
        end
    else
        if (isHome) then
            return 100-win
        else
            return win
        end
    end
end

-----------------------------------------------------------------------
-- Listeners
-----------------------------------------------------------------------
Services["Storage"].Remotes.CharacterSoundEvent.OnClientEvent:Connect(function(category, categoryType, ...)
    local args = {...}
    if (category == "GuiScript") then
        if not (categoryType == "Banner" or categoryType == "msg") then
            return
        end
    else
        return
    end

    if (categoryType == "msg") then
        local message = args[1]

        if (string.match(message, "yard gain")) then
            local split = string.split(message, " yard gain")
            if (tonumber(split[1])) then
                CURRENT_PLAY_INFO.yards_gained = tonumber(split[1])

                if (CURRENT_PLAY_INFO.qb_pass) then
                    CURRENT_PLAY_INFO.pass_length = tonumber(split[1])
                    CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.COMPLETE
                end
            end
        elseif (string.match(message, "Yard Touchdown!")) then
            local split = string.split(message, " Yard Touchdown!")
            if (tonumber(split[1])) then
                CURRENT_PLAY_INFO.yards_gained = tonumber(split[1])

                if (CURRENT_PLAY_INFO.qb_pass) then
                    CURRENT_PLAY_INFO.pass_length = tonumber(split[1])
                    CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.COMPLETE
                end
            end
        elseif (string.match(message, "yard loss")) then
            local split = string.split(message, " yard loss")
            if (tonumber(split[1])) then
                CURRENT_PLAY_INFO.yards_gained = tonumber(split[1]) * -1
            end
        elseif (message == "INTERCEPTION") then
            CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.INTERCEPTION
        elseif (message == "Touchback") then
            CURRENT_PLAY_INFO.touchback = true
        elseif (message == "Turnover on downs") then
            wait(0.5)

            if (FFValues.PossessionTag.Value == FFValues.Away.Value.Name) then
                module.Values.AwayInfo.TURN_ON_DOWNS = module.Values.AwayInfo.TURN_ON_DOWNS+1
            else
                module.Values.HomeInfo.TURN_ON_DOWNS = module.Values.HomeInfo.TURN_ON_DOWNS+1
            end
        elseif (message == "Incomplete") then
            CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.INCOMPLETE

            if (FFValues.Ball.Value) then
                if (FFValues.Ball.Value.Position.X > 32) then
                    CURRENT_PLAY_INFO.pass_location = module.Enums.Location.LEFT
                elseif (FFValues.Ball.Value.Position.X < -32) then
                    CURRENT_PLAY_INFO.pass_location = module.Enums.Location.RIGHT
                else
                    CURRENT_PLAY_INFO.pass_location = module.Enums.Location.MIDDLE
                end
            end
        elseif (message == "FUMBLE") then
            CURRENT_PLAY_INFO.fumble = true
        elseif (string.find(message,"have won!")) then
            if (module.Values.AwayScore > module.Values.HomeScore) then
                module.Events.GameEndEvent:Fire(false)
            else
                module.Events.GameEndEvent:Fire(true)
            end
            module.LastEvents.GameEndEvent = tick()
        end
        return
    end

    local team = args[2]
    local text = args[1]

    if (text == "T O U C H D O W N") then
        if (team.Name == FFValues.Away.Value.Name) then
            module.Events.Touchdown:Fire(false)
            module.LastEvents.Touchdown = tick()

            CURRENT_PLAY_INFO.td_team = module.Settings.AwayTeam.Abbreviation
        else
            module.Events.Touchdown:Fire(true)
            module.LastEvents.Touchdown = tick()

            CURRENT_PLAY_INFO.td_team = module.Settings.HomeTeam.Abbreviation
        end
    elseif (text == "S A F E T Y") then
        if (team.Name == FFValues.Away.Value.Name) then
            module.Events.Safety:Fire(false)
            module.LastEvents.Safety = tick()
        else
            module.Events.Safety:Fire(true)
            module.LastEvents.Safety = tick()
        end

        CURRENT_PLAY_INFO.safety = true
    elseif (text == "I T ' S   G O O D !") then
        local type = 1

        if (FFValues.Kicker.Value) then
            local userId = GetUserIDFromName(FFValues.Kicker.Value.Name)
            if (userId) then
                CURRENT_PLAY_INFO.play_maker_id = userId
            end
        end
        wait(0.25)
        if (team.Name == FFValues.Away.Value.Name) then
            if (module.Values.AwayScore - module.OldValues.AwayScore == 1) then
                module.Events.ExtraPoint:Fire(false)
                module.LastEvents.ExtraPoint = tick()
            else
                module.Events.FieldGoal:Fire(false)
                module.LastEvents.FieldGoal = tick()
                type = 3
            end
        else
            if (module.Values.HomeScore - module.OldValues.HomeScore == 1) then
                module.Events.ExtraPoint:Fire(true)
                module.LastEvents.ExtraPoint = tick()
            else
                module.Events.FieldGoal:Fire(true)
                module.LastEvents.FieldGoal = tick()
                type = 3
            end
        end

        if (type == 3) then
            CURRENT_PLAY_INFO.field_goal_result = module.Enums.FieldGoalResult.COMPLETE
        else
            CURRENT_PLAY_INFO.extra_point_result = module.Enums.FieldGoalResult.INCOMPLETE
        end
    elseif (text == "2 - P T   G O O D") then
        if (team.Name == FFValues.Away.Value.Name) then
            module.Events.TwoPoint:Fire(false)
            module.LastEvents.TwoPoint = tick()
        else
            module.Events.TwoPoint:Fire(true)
            module.LastEvents.TwoPoint = tick()
        end

        CURRENT_PLAY_INFO.two_point_conv_result = module.Enums.FieldGoalResult.COMPLETE
    elseif (text == "N O   G O O D") then
        if (FFValues.Kicker.Value) then
            local userId = GetUserIDFromName(FFValues.Kicker.Value.Name)
            if (userId) then
                CURRENT_PLAY_INFO.play_maker_id = userId
            end
        end

        if (team.Name == FFValues.Away.Value.Name) then
            module.Events.KickMissed:Fire(false)
            module.LastEvents.KickMissed = tick()
        else
            module.Events.KickMissed:Fire(true)
            module.LastEvents.KickMissed = tick()
        end
    end
end)

-----------------------------------------------------------------------
-- PrePlay / InPlay / DeadPlay Listener (modified for <font> tags)
-----------------------------------------------------------------------
FFValues.Status.Changed:Connect(function(value)
    if (value == "PrePlay") then
        module.Events.PrePlayEvent:Fire()
        module.LastEvents.PrePlayEvent = tick()
        print("[FF-API] PrePlay is starting.")

        CURRENT_PLAY_INFO = {
            play_id = module.Settings.LastPlayID+1,
            play_start_time = 0,
            play_end_time = 0,
            game_id = module.Settings.GameID,
            home_team = module.Settings.HomeTeam.Abbreviation,
            away_team = module.Settings.AwayTeam.Abbreviation,
            pos_team = "",
            pos_win = 50,
            side_of_field = "",
            yardline_100 = 0,
            clock = FFValues.TimerTag.Value,
            quarter = FFValues.Quarter.Value,
            drive = 0,
            down = 0,
            yards_to_go = 0,
            desc = "",
            play_maker_id = 0,
            yards_gained = 0,
            kickoff = false,
            touchback = false,
            turnover = false,
            fumble = false,
            safety = false,
            qb = 3292436585,
            qb_run = false,
            qb_pass = false,
            pass_location = "",
            pass_result = "",
            run_location = "",
            field_goal_result = "",
            kick_distance = 0,
            extra_point_result = "",
            two_point_conv_result = "",
            home_timeouts_remaining_before = FFValues.HomeTos.Value,
            away_timeouts_remaining_before = FFValues.AwayTos.Value,
            home_timeouts_remaining_after = 0,
            away_timeouts_remaining_after = 0,
            timeout = false,
            timeout_team = "",
            td_team = "",
            home_before_score = FFValues.HomeScore.Value,
            away_before_score = FFValues.AwayScore.Value,
            home_after_score = 0,
            away_after_score = 0,
            first_down = false
        }

        local status = string.split(FFValues.StatusTag.Value, " & ")
        if (status[1] and status[2]) then
            -- Extract text inside <font> tags for the first part
            local function extractFontText(input)
                local startPos, endPos = string.find(input, "<font.->")
                if startPos and endPos then
                    local closeTag = string.find(input, "</font>")
                    if closeTag then
                        return string.sub(input, endPos+1, closeTag-1)
                    end
                end
                return nil
            end

            local fontText = extractFontText(status[1])
            if fontText and tonumber(fontText) then
                CURRENT_PLAY_INFO.down = tonumber(fontText)
            else
                CURRENT_PLAY_INFO.down = tonumber(status[1]) or 0
            end

            if tonumber(status[2]) then
                CURRENT_PLAY_INFO.yards_to_go = tonumber(status[2])
            else
                CURRENT_PLAY_INFO.yards_to_go = 1
            end
        end
    end
end)

-----------------------------------------------------------------------
-- Return Module
-----------------------------------------------------------------------
return module
