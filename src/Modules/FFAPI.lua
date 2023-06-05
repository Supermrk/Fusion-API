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
local http = syn.request or http.request

-----------------------------------------------------------------------
-- Final
-----------------------------------------------------------------------
local FFValues = Services["Storage"].Values
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
        data = http.request({
            Url = "https://www.pro-football-reference.com/boxscores/win_prob.cgi?request=1&score_differential=" .. FFValues.HomeScore.Value - FFValues.AwayScore.Value .. "&vegas_line=" .. vegasLine .. "&quarter=" .. FFValues.Quarter.Value .."&minutes=" .. minutes .. "&seconds=" .. seconds .. "&field=" .. field .. "&yds_from_goal=" .. fieldPos .."&yds_to_go=" .. yardsToGo,
        })
    else
        local vegasLine = (module.Settings.AwayRank-module.Settings.HomeRank)/4
        data = http.request({
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
            desc = "", --
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

        if (FFValues.PossessionTag.Value == FFValues.Away.Value.Name) then
            CURRENT_PLAY_INFO.pos_team = module.Settings.AwayTeam.Abbreviation
            CURRENT_PLAY_INFO.pos_win = module.Values.AwayInfo.WIN
            CURRENT_PLAY_INFO.drive = module.Settings.LastDriveID
            if (FFValues.ArrowUp.Value) then
                CURRENT_PLAY_INFO.side_of_field = module.Settings.AwayTeam.Abbreviation
                CURRENT_PLAY_INFO.yardline_100 = FFValues.YardTag.Value
            else
                CURRENT_PLAY_INFO.side_of_field = module.Settings.HomeTeam.Abbreviation
                CURRENT_PLAY_INFO.yardline_100 = FFValues.YardTag.Value+50
            end
        else
            CURRENT_PLAY_INFO.pos_team = module.Settings.HomeTeam.Abbreviation
            CURRENT_PLAY_INFO.pos_win = module.Values.HomeInfo.WIN
            CURRENT_PLAY_INFO.drive = module.Settings.LastDriveID
            if (FFValues.ArrowUp.Value) then
                CURRENT_PLAY_INFO.side_of_field = module.Settings.HomeTeam.Abbreviation
                CURRENT_PLAY_INFO.yardline_100 = FFValues.YardTag.Value
            else
                CURRENT_PLAY_INFO.side_of_field = module.Settings.AwayTeam.Abbreviation
                CURRENT_PLAY_INFO.yardline_100 = FFValues.YardTag.Value+50
            end
        end

        module.Settings.LastPlayID = module.Settings.LastPlayID+1

        local status = string.split(FFValues.StatusTag.Value, " & ")
        if (status[1] and status[2]) then
            status[1] = string.sub(status[1],1,1)
            if (tonumber(status[1])) then
                CURRENT_PLAY_INFO.down = tonumber(status[1])
            end
            if (tonumber(status[2])) then
                CURRENT_PLAY_INFO.yards_to_go = tonumber(status[2])
            else
                CURRENT_PLAY_INFO.yards_to_go = 1
            end
        end

        if (FFValues.PlayType.Value == "fieldgoal") then
            CURRENT_PLAY_INFO.kick_distance = FFValues.YardTag.Value+17

            if (FFValues.StatusTag.Value == "PAT") then
                CURRENT_PLAY_INFO.extra_point_result = module.Enums.FieldGoalResult.INCOMPLETE
            else
                CURRENT_PLAY_INFO.field_goal_result = module.Enums.FieldGoalResult.INCOMPLETE
            end
        elseif (FFValues.PlayType.Value == "kickoff") then
            CURRENT_PLAY_INFO.kickoff = true
        elseif (FFValues.PlayType.Value == "normal" and FFValues.StatusTag.Value == "PAT") then
            CURRENT_PLAY_INFO.two_point_conv_result = module.Enums.FieldGoalResult.INCOMPLETE
        end

        local awayWinPercentage = GetWinPercentage(module.Settings.AwayTeam.Abbreviation)
        module.Values.AwayInfo.WIN = awayWinPercentage
        module.Values.HomeInfo.WIN = 100-awayWinPercentage
    elseif (value == "InPlay") then
        module.Events.InPlayEvent:Fire()
        module.LastEvents.InPlayEvent = tick()
        print("[FF-API] The play is now ongoing.")

        CURRENT_PLAY_INFO.play_start_time = tick()

        if (FFValues.Carrier.Value) then
            local player = Services["Players"]:GetUserIdFromNameAsync(FFValues.Carrier.Value.Name)
            CURRENT_PLAY_INFO.qb = player
        end

        if (module.Settings.SwitchedPossession) then
            module.Settings.LastDriveID = module.Settings.LastDriveID+1
            if (FFValues.PossessionTag.Value == FFValues.Away.Value.Name) then
                module.Values.AwayInfo.DRIVE = module.Values.AwayInfo.DRIVE+1
                CURRENT_PLAY_INFO.drive = module.Settings.LastDriveID
            else
                module.Values.HomeInfo.DRIVE = module.Values.HomeInfo.DRIVE+1
                CURRENT_PLAY_INFO.drive = module.Settings.LastDriveID
            end

            module.Values.CurrentDrive.PLAYS = 0
            module.Values.CurrentDrive.TOP = 0
            module.Values.CurrentDrive.YARDS = 0
            module.Settings.SwitchedPossession = false
        end
    elseif (value == "DeadPlay") then
        module.Events.AfterPlayEvent:Fire()
        module.LastEvents.AfterPlayEvent = tick()
        print("[FF-API] The play has stopped.")

        CURRENT_PLAY_INFO.play_end_time = tick()
        wait(2.5)

        local newPossessionTeam
        if (FFValues.PossessionTag.Value == FFValues.Away.Value.Name) then
            newPossessionTeam = module.Settings.AwayTeam.Abbreviation
        else
            newPossessionTeam = module.Settings.HomeTeam.Abbreviation
        end

        if not (CURRENT_PLAY_INFO.pos_team == newPossessionTeam) then
            CURRENT_PLAY_INFO.turnover = true
            module.Settings.SwitchedPossession = true
        end
        if (CURRENT_PLAY_INFO.yards_gained > CURRENT_PLAY_INFO.yards_to_go) then
            CURRENT_PLAY_INFO.first_down = true
        end

        CURRENT_PLAY_INFO.home_timeouts_remaining_after = FFValues.HomeTos.Value
        CURRENT_PLAY_INFO.away_timeouts_remaining_after = FFValues.AwayTos.Value
        CURRENT_PLAY_INFO.home_after_score = FFValues.HomeScore.Value
        CURRENT_PLAY_INFO.away_after_score = FFValues.AwayScore.Value

        if (CURRENT_PLAY_INFO.pos_team == module.Settings.AwayTeam.Abbreviation) then
            if not (module.Values.AwayInfo.DRIVE_PLAYS[module.Settings.LastDriveID]) then
                module.Values.AwayInfo.DRIVE_PLAYS[module.Settings.LastDriveID] = {}
            end

            module.Values.AwayInfo.DRIVE_PLAYS[module.Settings.LastDriveID][module.Settings.LastPlayID] = CURRENT_PLAY_INFO
        else
            if not (module.Values.HomeInfo.DRIVE_PLAYS[module.Settings.LastDriveID]) then
                module.Values.HomeInfo.DRIVE_PLAYS[module.Settings.LastDriveID] = {}
            end

            module.Values.HomeInfo.DRIVE_PLAYS[module.Settings.LastDriveID][module.Settings.LastPlayID] = CURRENT_PLAY_INFO
        end



        if (CURRENT_PLAY_INFO.qb_pass) then
            local qb = Services["Players"]:GetNameFromUserIdAsync(CURRENT_PLAY_INFO.qb)
            local wr = Services["Players"]:GetNameFromUserIdAsync(CURRENT_PLAY_INFO.play_maker_id)
            if not (qb) then
                qb = "Unknown"
            end
            if not (wr) then
                wr = "Unknown"
            end

            local passLength = ""
            if (CURRENT_PLAY_INFO.yards_gained >= 30) then
                passLength = "deep "
            elseif (CURRENT_PLAY_INFO.yards_gained <= 10) then
                passLength = "short "
            end

            if (CURRENT_PLAY_INFO.pass_result == module.Enums.PassResult.COMPLETE) then
                CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. qb .. " pass " .. passLength .. string.lower(CURRENT_PLAY_INFO.pass_location) .. " to " .. wr .. " for " .. CURRENT_PLAY_INFO.yards_gained .. " yards."
            elseif (CURRENT_PLAY_INFO.pass_result == module.Enums.PassResult.INCOMPLETE) then
                CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. qb .. " pass incomplete " .. string.lower(CURRENT_PLAY_INFO.pass_location) .. "."
            elseif (CURRENT_PLAY_INFO.pass_result == module.Enums.PassResult.INTERCEPTION) then
                CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. qb .. " pass " .. passLength .. string.lower(CURRENT_PLAY_INFO.pass_location) .. " INTERCEPTED by " .. wr .. "."
            end
        elseif (CURRENT_PLAY_INFO.qb_run) then
            local succ,runner = pcall(function()
                return Services["Players"]:GetNameFromUserIdAsync(CURRENT_PLAY_INFO.play_maker_id)
            end)
            if not (succ) then
                runner = "Unknown"
            end

            CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. runner .. (CURRENT_PLAY_INFO.yards_gained <= 0 and " run " or " run up the ") .. string.lower(CURRENT_PLAY_INFO.run_location) .. " for " .. (CURRENT_PLAY_INFO.yards_gained <= 0 and "a loss of " or "") .. math.abs(CURRENT_PLAY_INFO.yards_gained) .. " yards."
        elseif not (CURRENT_PLAY_INFO.field_goal_result == "") then
            local succ,kicker = pcall(function()
                return Services["Players"]:GetNameFromUserIdAsync(CURRENT_PLAY_INFO.play_maker_id)
            end)
            if not (succ or kicker) then
                kicker = "Unknown"
            end

            CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. kicker .. " " .. CURRENT_PLAY_INFO.kick_distance .. " yards field goal is " .. string.upper(CURRENT_PLAY_INFO.field_goal_result) .. "."
        elseif not (CURRENT_PLAY_INFO.extra_point_result == "") then
            local succ, kicker = pcall(function()
                return Services["Players"]:GetNameFromUserIdAsync(CURRENT_PLAY_INFO.play_maker_id)
            end)
            if not (succ) then
                kicker = "Unknown"
            end

            CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. kicker .. " extra point is " .. string.upper(CURRENT_PLAY_INFO.extra_point_result) .. "."
        elseif (CURRENT_PLAY_INFO.kickoff) then
            CURRENT_PLAY_INFO.desc = "(" .. FormatClock(CURRENT_PLAY_INFO.clock) .. ") " .. CURRENT_PLAY_INFO.pos_team .. " punts returned for " .. CURRENT_PLAY_INFO.yards_gained+25 .. " yards."
        end

        if (CURRENT_PLAY_INFO.pos_team == module.Settings.AwayTeam.Abbreviation) then
            if (CURRENT_PLAY_INFO.away_after_score-CURRENT_PLAY_INFO.away_before_score == 6) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " TOUCHDOWN."
            elseif (CURRENT_PLAY_INFO.home_after_score-CURRENT_PLAY_INFO.home_before_score == 6) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " OPPOSING TOUCHDOWN."
            end
        else
            if (CURRENT_PLAY_INFO.home_after_score-CURRENT_PLAY_INFO.home_before_score == 6) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " TOUCHDOWN."
            elseif (CURRENT_PLAY_INFO.away_after_score-CURRENT_PLAY_INFO.away_before_score == 6) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " OPPOSING TOUCHDOWN."
            end
        end

        if not (CURRENT_PLAY_INFO.desc == "") then
            if (CURRENT_PLAY_INFO.touchback) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " Touchback."
            end
            if (CURRENT_PLAY_INFO.timeout) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " Timeout called by " .. CURRENT_PLAY_INFO.timeout_team .. "."
            end
            if (CURRENT_PLAY_INFO.yards_gained < CURRENT_PLAY_INFO.yards_to_go and CURRENT_PLAY_INFO.down == 4 and not CURRENT_PLAY_INFO.kickoff) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " TURNOVER on downs."
            elseif (CURRENT_PLAY_INFO.turnover) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " TURNOVER."
            end
            if (CURRENT_PLAY_INFO.fumble) then
                local otherTeam = CURRENT_PLAY_INFO.pos_team
                if (CURRENT_PLAY_INFO.turnover) then
                    if (module.Settings.AwayTeam.Abbreviation == otherTeam) then
                        otherTeam = module.Settings.HomeTeam.Abbreviation
                    else
                        otherTeam = module.Settings.AwayTeam.Abbreviation
                    end
                end

                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " FUMBLES (" .. CURRENT_PLAY_INFO.pos_team .. ")" .. " RECOVERED by " .. otherTeam .. ". Gain of " .. CURRENT_PLAY_INFO.yards_gained .. " yards."
            end
            if (CURRENT_PLAY_INFO.safety) then
                CURRENT_PLAY_INFO.desc = CURRENT_PLAY_INFO.desc .. " SAFETY."
            end
            if not (CURRENT_PLAY_INFO.two_point_conv_result == "") then
                CURRENT_PLAY_INFO.desc = "TWO-POINT CONVERSION ATTEMPT. " .. CURRENT_PLAY_INFO.desc .. " ATTEMPT " .. string.upper(CURRENT_PLAY_INFO.two_point_conv_result) .. "."
            end
        end

        module.Events.PlayFinishedEvent:Fire(CURRENT_PLAY_INFO)
        module.Values.CurrentDrive.PLAYS = module.Values.CurrentDrive.PLAYS+1
        module.Values.CurrentDrive.YARDS = module.Values.CurrentDrive.YARDS+CURRENT_PLAY_INFO.yards_gained
    end
end)

FFValues.Throwable.Changed:Connect(function(value)
    if not (value) then
        wait(0.5)
        if not (FFValues.Thrown.Value) then
            CURRENT_PLAY_INFO.qb_run = true
            if (FFValues.QB.Value) then
                local userId = GetUserIDFromName(FFValues.QB.Value.Name)
                if (userId) then
                    CURRENT_PLAY_INFO.play_maker_id = userId
                end
                if (FFValues.QB.Value.Character.PrimaryPart.Position.X > 32) then
                    CURRENT_PLAY_INFO.run_location = module.Enums.Location.LEFT
                elseif (FFValues.QB.Value.Character.PrimaryPart.Position.X < -32) then
                    CURRENT_PLAY_INFO.run_location = module.Enums.Location.RIGHT
                else
                    CURRENT_PLAY_INFO.run_location = module.Enums.Location.MIDDLE
                end
            end
        end
    end
end)

FFValues.Thrown.Changed:Connect(function(value)
    if (value) then
        module.Events.BallThrown:Fire()
        module.LastEvents.BallThrown = tick()

        CURRENT_PLAY_INFO.qb_pass = true
        CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.INCOMPLETE
    end
end)

FFValues.Carrier.Changed:Connect(function(value)
    if not (FFValues.Status.Value == "InPlay" or FFValues.Thrown.Value or value ~= nil) then
        return
    end

    if not (value) then
        return
    end
    if not (value.UserId) then
        return
    end

    local userId = value.UserId
    module.Events.BallCaught:Fire(userId)
    module.LastEvents.BallCaught = tick()

    CURRENT_PLAY_INFO.play_maker_id = userId
    if (value.Character.PrimaryPart.Position.X > 32) then
        CURRENT_PLAY_INFO.pass_location = module.Enums.Location.LEFT
    elseif (value.Character.PrimaryPart.Position.X < -32) then
        CURRENT_PLAY_INFO.pass_location = module.Enums.Location.RIGHT
    else
        CURRENT_PLAY_INFO.pass_location = module.Enums.Location.MIDDLE
    end
end)

FFValues.AwayScore.Changed:Connect(function(new)
    local reason = module.Enums.ScoreType.OTHER
    wait(0.5)
    if (tick() - module.LastEvents.Safety < 1) then
        reason = module.Enums.ScoreType.SAFETY
    elseif (tick() - module.LastEvents.Touchdown < 1) then
        reason = module.Enums.ScoreType.TOUCHDOWN
    elseif (tick() - module.LastEvents.FieldGoal < 1) then
        reason = module.Enums.ScoreType.FIELD_GOAL
    elseif (tick() - module.LastEvents.ExtraPoint < 1) then
        reason = module.Enums.ScoreType.EXTRA_POINT
    elseif (tick() - module.LastEvents.TwoPoint < 1) then
        reason = module.Enums.ScoreType.TWO_POINT
    end

    module.Events.AwayScored:Fire(new,module.Values.AwayScore, reason)

    module.OldValues.AwayScore = module.Values.AwayScore
    module.OldValues.AwayScoredReason = reason
    module.Values.AwayScore = new
end)

FFValues.HomeScore.Changed:Connect(function(new)
    local reason = module.Enums.ScoreType.OTHER
    wait(0.5)
    if (tick() - module.LastEvents.Safety < 1) then
        reason = module.Enums.ScoreType.SAFETY
    elseif (tick() - module.LastEvents.Touchdown < 1) then
        reason = module.Enums.ScoreType.TOUCHDOWN
    elseif (tick() - module.LastEvents.FieldGoal < 1) then
        reason = module.Enums.ScoreType.FIELD_GOAL
    elseif (tick() - module.LastEvents.ExtraPoint < 1) then
        reason = module.Enums.ScoreType.EXTRA_POINT
    elseif (tick() - module.LastEvents.TwoPoint < 1) then
        reason = module.Enums.ScoreType.TWO_POINT
    end

    module.Events.HomeScored:Fire(new,module.Values.HomeScore, reason)

    module.OldValues.HomeScore = module.Values.HomeScore
    module.OldValues.HomeScoredReason = reason
    module.Values.HomeScore = new
end)

FFValues.AwayTos.Changed:Connect(function(new)
    module.Events.AwayTimeoutChange:Fire(new, module.Values.AwayTimeouts)

    module.OldValues.AwayTimeouts = module.Values.AwayTimeouts
    module.Values.AwayTimeouts = new

    if (module.OldValues.AwayTimeouts - new == 1) then
        CURRENT_PLAY_INFO.timeout = true
        CURRENT_PLAY_INFO.timeout_team = module.Settings.AwayTeam.Abbreviation
    end
end)

FFValues.HomeTos.Changed:Connect(function(new)
    module.Events.HomeTimeoutChange:Fire(new, module.Values.HomeTimeouts)

    module.OldValues.HomeTimeouts = module.Values.HomeTimeouts
    module.Values.HomeTimeouts = new

    if (module.OldValues.HomeTimeouts - new == 1) then
        CURRENT_PLAY_INFO.timeout = true
        CURRENT_PLAY_INFO.timeout_team = module.Settings.HomeTeam.Abbreviation
    end
end)

FFValues.Playclock.Changed:Connect(function(new)
    module.Events.PlayClockTick:Fire(new, module.Values.PlayClock)

    module.OldValues.PlayClock = module.Values.PlayClock
    module.Values.PlayClock = new
end)

FFValues.Quarter.Changed:Connect(function(new)
    module.Events.QuarterChange:Fire(new, module.Values.Quarter)

    module.OldValues.Quarter = module.Values.Quarter
    module.Values.Quarter = new
end)

FFValues.TimerTag.Changed:Connect(function(new)
    module.Events.ClockTick:Fire(new, module.Values.Clock)

    module.OldValues.Clock = module.Values.Clock
    module.Values.Clock = new

    if (FFValues.PossessionTag.Value == FFValues.Away.Value.Name) then
        module.Values.AwayInfo.TOP = module.Values.AwayInfo.TOP+1
    else
        module.Values.HomeInfo.TOP = module.Values.HomeInfo.TOP+1
    end
    module.Values.CurrentDrive.TOP = module.Values.CurrentDrive.TOP+1
end)

FFValues.StatusTag.Changed:Connect(function(new)
    module.Events.StatusChange:Fire(new, module.Values.Status)

    module.OldValues.Status = module.Values.Status
    module.Values.Status = new
end)

FFValues.PossessionTag.Changed:Connect(function(new)
    if (new == FFValues.Away.Value.Name) then
        module.Values.Possession = false
    else
        module.Values.Possession = true
    end
end)

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
