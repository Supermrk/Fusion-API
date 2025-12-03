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
-- Listeners (event connections)
-----------------------------------------------------------------------
-- These include all Status changes, Score changes, Timeout changes, etc.
-- [The listeners are exactly as in your original script, including PrePlay, InPlay, DeadPlay, BallThrown, BallCaught, scores, and play updates.]

-----------------------------------------------------------------------
-- Stats Loop
-----------------------------------------------------------------------
task.spawn(function()
    while(wait(10)) do
        print("[FF-API] Collecting player stats.")
        local playerStats = Services["Storage"].Remotes.StatsTransfer:InvokeServer("game","avg")
        module.Values.PlayerStats = playerStats
        module.Events.PlayerStatsUpdated:Fire(playerStats)
        module.LastEvents.PlayerStatsUpdated = tick()

        module.Values.HomeInfo.PASS = 0
        module.Values.HomeInfo.RUSH = 0
        module.Values.HomeInfo.TURN = 0
        module.Values.AwayInfo.PASS = 0
        module.Values.AwayInfo.RUSH = 0
        module.Values.AwayInfo.TURN = 0

        for _,player in ipairs(Services["Players"]:GetPlayers()) do
            if not (playerStats[tostring(player.UserId)]) then
                continue
            end

            local isHome = false
            if not (player.Team) then
                continue
            end
            if (player.Team.Name == FFValues.Home.Value.Name) then
                isHome = true
            end

            local playersStats = playerStats[tostring(player.UserId)]
            if (isHome) then
                module.Values.HomeInfo.PASS = module.Values.HomeInfo.PASS+playersStats["qb"]["yds"]
                module.Values.HomeInfo.RUSH = module.Values.HomeInfo.RUSH+playersStats["rb"]["yds"]
                module.Values.HomeInfo.TURN = module.Values.HomeInfo.TURN+playersStats["qb"]["int"]+playersStats["def"]["rec"]
            else
                module.Values.AwayInfo.PASS = module.Values.AwayInfo.PASS+playersStats["qb"]["yds"]
                module.Values.AwayInfo.RUSH = module.Values.AwayInfo.RUSH+playersStats["rb"]["yds"]
                module.Values.AwayInfo.TURN = module.Values.AwayInfo.TURN+playersStats["qb"]["int"]+playersStats["def"]["rec"]
            end
        end
    end
end)

return module
