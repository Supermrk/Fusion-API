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
		SwitchedPossession = false,
		CollectWinPercentages = false,
		PlayerStatsCollectionInterval = 10
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
		CollectingStats = false,
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
		AwayScored = 0,
		HomeScored = 0,
		AwayTimeoutChange = 0,
		HomeTimeoutChange = 0,
		PlayClockTick = 0,
		QuarterChange = 0,
		ClockTick = 0,
		StatusChange = 0,
		Safety = 0,
		Touchdown = 0,
		FieldGoal = 0,
		ExtraPoint = 0,
		TwoPoint = 0,
		KickMissed = 0,
		BallThrown = 0,
		BallCaught = 0,
		PrePlayEvent = 0,
		InPlayEvent = 0,
		AfterPlayEvent = 0,
		PlayFinishedEvent = 0,
		PlayerStatsUpdated = 0,
		GameEndEvent = 0
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
	qb = 0,
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
-- Module Functions
-----------------------------------------------------------------------

-- Starts collecting player statistics.
-- Player statistics are stored in module.Values.PlayerStats.
function module:StartPlayerStatsCollection()
	if (module.Values.CollectingStats) then return end
	module.Values.CollectingStats = true

	task.spawn(function()
		while (module.Values.CollectingStats) do
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

			wait(module.Settings.PlayerStatsCollectionInterval)
		end
	end)
end

-- Stops collecting player statistics.
function module:StopPlayerStatsCollection()
	module.Values.CollectingStats = false
end

-----------------------------------------------------------------------
-- Internal Functions
-----------------------------------------------------------------------

-- Retrieves the UserID of a player given their username.
-- @param name: The username of the player.
-- @return UserID of the player if found, otherwise nil.
local function GetUserIDFromName(name : string)
	for i, v in ipairs(Services["Players"]:GetPlayers()) do
		if (v.Name == name) then
			return v.UserId
		end
	end
end

-- Formats a given time in seconds into a clock format (MM:SS).
-- @param seconds: The total number of seconds to format.
-- @return A formatted string representing the time in MM:SS format.
local function FormatClock(seconds : number)
	local minutes = (seconds - seconds % 60) / 60
	seconds = seconds - minutes * 60
	local zero = ""

	if (seconds < 10) then
		zero = "0"
	end

	return minutes .. ":" .. zero .. seconds
end

-- Calculates the win probability percentage for a given team.
-- Uses an external API to determine win probability based on the current game state.
-- 
-- @param team: The team abbreviation (e.g., "NE", "KC") for which to calculate the win percentage.
-- @return The win probability as a number (0-100), or -1 if the request fails.
local function GetWinPercentage(team : string)
	local data
	local isHome = FFValues.PossessionTag.Value == FFValues.Home.Value.Name

	-- Parse field position and distance to go
	local yardsToGo = string.split(FFValues.StatusTag.Value, " & ")
	local fieldPos = FFValues.YardTag.Value
	local field = "team"

	if (FFValues.ArrowUp.Value) then
		fieldPos = fieldPos + 50
		field = "opp"
	end

	if (yardsToGo[2] and tonumber(yardsToGo[2])) then
		yardsToGo = tonumber(yardsToGo[2])
	else
		yardsToGo = 1
	end

	-- Convert total seconds into minutes and seconds for API request
	local seconds = FFValues.TimerTag.Value
	local minutes = (seconds - seconds % 60) / 60
	seconds = seconds - minutes * 60

	-- Determine Vegas line based on team ranking
	if (isHome) then
		local vegasLine = (module.Settings.HomeRank - module.Settings.AwayRank) / 4
		data = request({
			Url = "https://www.pro-football-reference.com/boxscores/win_prob.cgi?request=1&score_differential=" 
				.. FFValues.HomeScore.Value - FFValues.AwayScore.Value 
				.. "&vegas_line=" .. vegasLine 
				.. "&quarter=" .. FFValues.Quarter.Value 
				.. "&minutes=" .. minutes 
				.. "&seconds=" .. seconds 
				.. "&field=" .. field 
				.. "&yds_from_goal=" .. fieldPos 
				.. "&yds_to_go=" .. yardsToGo,
		})
	else
		local vegasLine = (module.Settings.AwayRank - module.Settings.HomeRank) / 4
		data = request({
			Url = "https://www.pro-football-reference.com/boxscores/win_prob.cgi?request=1&score_differential=" 
				.. FFValues.AwayScore.Value - FFValues.HomeScore.Value 
				.. "&vegas_line=" .. vegasLine 
				.. "&quarter=" .. FFValues.Quarter.Value 
				.. "&minutes=" .. minutes 
				.. "&seconds=" .. seconds 
				.. "&field=" .. field 
				.. "&yds_from_goal=" .. fieldPos 
				.. "&yds_to_go=" .. yardsToGo,
		})
	end

	-- Default win percentage
	local win = module.Values.AwayInfo.WIN
	if (isHome) then
		win = module.Values.HomeInfo.WIN
	end

	-- Parse API response for win probability
	if (data) then
		local success = pcall(function()
			local split1 = string.split(data.Body, "<h3>Win Probability: ")[2]
			local split2 = string.split(split1, "%</h3>")[1]
			local split3 = string.split(split2, ".")[1]

			if (tonumber(split3)) then
				win = tonumber(split3)
			end
		end)

		-- Handle HTTP request failure
		if not (success) then
			error("Failed to invoke HTTP request GetWinPercentage() for team ", team, ".")
			return -1
		end
	end

	-- Adjust win probability based on whether the team being requested is the home team
	local requestingHomeTeam = team == module.Settings.HomeTeam.Abbreviation
	if (requestingHomeTeam) then
		if (isHome) then
			return win
		else
			return 100 - win
		end
	else
		if (isHome) then
			return 100 - win
		else
			return win
		end
	end
end

-- Process the messages of on-screen text and updates API play and team states accordingly.
-- @param message The incoming message string
local function handleMessage(message)

	--- Updates yards gained and passing details if applicable.
	-- @param yards The number of yards gained
	local function updateYardsGained(yards)
		CURRENT_PLAY_INFO.yards_gained = yards or 0
		if CURRENT_PLAY_INFO.qb_pass then
			CURRENT_PLAY_INFO.pass_length = yards
			CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.COMPLETE
		end
	end

	if message:match("yard gain") then
		updateYardsGained(tonumber(message:match("(%d+) yard gain")) or 0)
	elseif message:match("Yard Touchdown!") then
		updateYardsGained(tonumber(message:match("(%d+) Yard Touchdown!")) or 0)
	elseif message:match("yard loss") then
		CURRENT_PLAY_INFO.yards_gained = -(tonumber(message:match("(%d+) yard loss")) or 0)
	elseif message == "INTERCEPTION" then
		CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.INTERCEPTION
	elseif message == "Touchback" then
		CURRENT_PLAY_INFO.touchback = true
	elseif message == "Turnover on downs" then
		task.wait(0.5)
		local possession = FFValues.PossessionTag.Value == FFValues.Away.Value.Name
		local targetInfo = possession and module.Values.AwayInfo or module.Values.HomeInfo
		targetInfo.TURN_ON_DOWNS = targetInfo.TURN_ON_DOWNS + 1
	elseif message == "Incomplete" then
		CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.INCOMPLETE
		if FFValues.Ball.Value then
			local xPos = FFValues.Ball.Value.Position.X
			CURRENT_PLAY_INFO.pass_location = xPos > 32 and module.Enums.Location.LEFT 
				or xPos < -32 and module.Enums.Location.RIGHT 
				or module.Enums.Location.MIDDLE
		end
	elseif message == "FUMBLE" then
		CURRENT_PLAY_INFO.fumble = true
	elseif message:find("have won!") then
		module.Events.GameEndEvent:Fire(module.Values.AwayScore <= module.Values.HomeScore)
		module.LastEvents.GameEndEvent = tick()
	end
end

--- Processes team-specific events and updates API states accordingly.
-- @param text The event description text
-- @param team The team associated with the event
local function handleTeamEvent(text, team)
	local isAway = team.Name == FFValues.Away.Value.Name

	if text == "T O U C H D O W N" then
		module.Events.Touchdown:Fire(not isAway)
		module.LastEvents.Touchdown = tick()
		CURRENT_PLAY_INFO.td_team = isAway and module.Settings.AwayTeam.Abbreviation or module.Settings.HomeTeam.Abbreviation
	elseif text == "S A F E T Y" then
		module.Events.Safety:Fire(not isAway)
		module.LastEvents.Safety = tick()
		CURRENT_PLAY_INFO.safety = true
	elseif text == "I T ' S   G O O D !" then
		task.wait(0.25)
		local isExtraPoint = (isAway and module.Values.AwayScore - module.OldValues.AwayScore == 1) 
			or (not isAway and module.Values.HomeScore - module.OldValues.HomeScore == 1)
		local event = isExtraPoint and module.Events.ExtraPoint or module.Events.FieldGoal
		event:Fire(not isAway)
		module.LastEvents[isExtraPoint and "ExtraPoint" or "FieldGoal"] = tick()
		if not isExtraPoint then
			CURRENT_PLAY_INFO.field_goal_result = module.Enums.FieldGoalResult.COMPLETE
		else
			CURRENT_PLAY_INFO.extra_point_result = module.Enums.FieldGoalResult.INCOMPLETE
		end
	elseif text == "2 - P T   G O O D" then
		module.Events.TwoPoint:Fire(not isAway)
		module.LastEvents.TwoPoint = tick()
		CURRENT_PLAY_INFO.two_point_conv_result = module.Enums.FieldGoalResult.COMPLETE
	elseif text == "N O   G O O D" then
		module.Events.KickMissed:Fire(not isAway)
		module.LastEvents.KickMissed = tick()
	end
end

-- Handles the pre-play events and data collection.
local function handlePrePlay()
	module.Events.PrePlayEvent:Fire()
	module.LastEvents.PrePlayEvent = tick()
	print("[FF-API] PrePlay is starting.")

	-- Initialize play data
	CURRENT_PLAY_INFO = {
		play_id = module.Settings.LastPlayID + 1,
		game_id = module.Settings.GameID,
		home_team = module.Settings.HomeTeam.Abbreviation,
		away_team = module.Settings.AwayTeam.Abbreviation,
		clock = FFValues.TimerTag.Value,
		quarter = FFValues.Quarter.Value,
		home_timeouts_remaining_before = FFValues.HomeTos.Value,
		away_timeouts_remaining_before = FFValues.AwayTos.Value,
		home_before_score = FFValues.HomeScore.Value,
		away_before_score = FFValues.AwayScore.Value,
		play_start_time = 0,
		play_end_time = 0,
		drive = 0,
		down = 0,
		yards_to_go = 0,
		yardline_100 = 0,
		kickoff = false,
		pass_location = "",
		pass_result = "",
		run_location = "",
		field_goal_result = "",
		extra_point_result = "",
		two_point_conv_result = "",
		first_down = false
	}

	-- Determine possession and field position
	local isAwayPossession = FFValues.PossessionTag.Value == FFValues.Away.Value.Name
	local possessionTeam = isAwayPossession and module.Settings.AwayTeam or module.Settings.HomeTeam
	local winValue = isAwayPossession and module.Values.AwayInfo.WIN or module.Values.HomeInfo.WIN

	CURRENT_PLAY_INFO.pos_team = possessionTeam.Abbreviation
	CURRENT_PLAY_INFO.pos_win = winValue
	CURRENT_PLAY_INFO.drive = module.Settings.LastDriveID

	local yardAdjustment = FFValues.ArrowUp.Value and 0 or 50
	CURRENT_PLAY_INFO.side_of_field = possessionTeam.Abbreviation
	CURRENT_PLAY_INFO.yardline_100 = FFValues.YardTag.Value + yardAdjustment

	-- Parse down and yards to go
	local statusParts = string.split(FFValues.StatusTag.Value, " & ")
	if #statusParts >= 2 then
		CURRENT_PLAY_INFO.down = tonumber(statusParts[1]) or 0
		CURRENT_PLAY_INFO.yards_to_go = tonumber(statusParts[2]) or 1
	end

	-- Handle special play types
	local playType = FFValues.PlayType.Value
	if playType == "fieldgoal" then
		CURRENT_PLAY_INFO.kick_distance = FFValues.YardTag.Value + 17
		CURRENT_PLAY_INFO.field_goal_result = module.Enums.FieldGoalResult.INCOMPLETE
	elseif playType == "kickoff" then
		CURRENT_PLAY_INFO.kickoff = true
	elseif playType == "normal" and FFValues.StatusTag.Value == "PAT" then
		CURRENT_PLAY_INFO.two_point_conv_result = module.Enums.FieldGoalResult.INCOMPLETE
	end

	-- Collect win percentages if enabled
	if module.Settings.CollectWinPercentages then
		local awayWinPercentage = GetWinPercentage(module.Settings.AwayTeam.Abbreviation)
		module.Values.AwayInfo.WIN = awayWinPercentage
		module.Values.HomeInfo.WIN = 100 - awayWinPercentage
	end
end

-- Handles data collection that should occur when the play starts.
local function handleInPlay()
	module.Events.InPlayEvent:Fire()
	module.LastEvents.InPlayEvent = tick()
	print("[FF-API] The play is now ongoing.")
	CURRENT_PLAY_INFO.play_start_time = tick()

	-- Determining the QB for this play by who has the ball when it's snapped
	if FFValues.Carrier.Value then
		CURRENT_PLAY_INFO.qb = Services.Players:GetUserIdFromNameAsync(FFValues.Carrier.Value.Name)
	end

	-- Checking if a new team has the ball since last play, and updating data accordingly
	if module.Settings.SwitchedPossession then
		module.Settings.LastDriveID += 1
		local isAwayPossession = FFValues.PossessionTag.Value == FFValues.Away.Value.Name
		local teamInfo = isAwayPossession and module.Values.AwayInfo or module.Values.HomeInfo
		teamInfo.DRIVE += 1
		CURRENT_PLAY_INFO.drive = module.Settings.LastDriveID

		module.Values.CurrentDrive = { PLAYS = 0, TOP = 0, YARDS = 0 }
		module.Settings.SwitchedPossession = false
	end
end

-- Handles data collection after a play has concluded.
local function handleDeadPlay()
	module.Events.AfterPlayEvent:Fire()
	module.Events.PlayFinishedEvent:Fire(CURRENT_PLAY_INFO)
	module.LastEvents.AfterPlayEvent = tick()
	print("[FF-API] The play has stopped.")

	CURRENT_PLAY_INFO.play_end_time = tick()
	wait(2.5)

	local newPossessionTeam = (FFValues.PossessionTag.Value == FFValues.Away.Value.Name) and 
		module.Settings.AwayTeam.Abbreviation or module.Settings.HomeTeam.Abbreviation

	if CURRENT_PLAY_INFO.pos_team ~= newPossessionTeam then
		CURRENT_PLAY_INFO.turnover = true
		module.Settings.SwitchedPossession = true
	end

	if CURRENT_PLAY_INFO.yards_gained or 0 > CURRENT_PLAY_INFO.yards_to_go or 0 then
		CURRENT_PLAY_INFO.first_down = true
	end

	-- Update timeout and scoring information
	CURRENT_PLAY_INFO.home_timeouts_remaining_after = FFValues.HomeTos.Value
	CURRENT_PLAY_INFO.away_timeouts_remaining_after = FFValues.AwayTos.Value
	CURRENT_PLAY_INFO.home_after_score = FFValues.HomeScore.Value
	CURRENT_PLAY_INFO.away_after_score = FFValues.AwayScore.Value

	-- Store play data
	local teamDriveInfo = (CURRENT_PLAY_INFO.pos_team == module.Settings.AwayTeam.Abbreviation) and 
		module.Values.AwayInfo.DRIVE_PLAYS or module.Values.HomeInfo.DRIVE_PLAYS

	teamDriveInfo[module.Settings.LastDriveID] = teamDriveInfo[module.Settings.LastDriveID] or {}
	teamDriveInfo[module.Settings.LastDriveID][module.Settings.LastPlayID] = CURRENT_PLAY_INFO
end

-----------------------------------------------------------------------
-- Listeners
-----------------------------------------------------------------------

-- Listens for various GUI related FF events to parse data from.
Services["Storage"].Remotes.CharacterSoundEvent.OnClientEvent:Connect(function(category, categoryType, ...)
	if category ~= "GuiScript" or not (categoryType == "Banner" or categoryType == "msg") then
		return
	end

	local args = {...}
	if categoryType == "msg" then
		handleMessage(args[1])
	else
		handleTeamEvent(args[1], args[2])
	end
end)

-- Listens for various play related status changes and collects necessary data.
FFValues.Status.Changed:Connect(function(value)
	if value == "PrePlay" then
		handlePrePlay()
	elseif value == "InPlay" then
		handleInPlay()
	elseif value == "DeadPlay" then
		handleDeadPlay()
	end
end)

-- Listens for when the ball is no longer throwable and checks if it a QB run
FFValues.Throwable.Changed:Connect(function(value)
	if not (value) then
		wait(0.25)
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

-- Listens for when the ball is thrown and triggers events and updates data accordingly
FFValues.Thrown.Changed:Connect(function(value)
	if (value) then
		module.Events.BallThrown:Fire()
		module.LastEvents.BallThrown = tick()

		CURRENT_PLAY_INFO.qb_pass = true
		CURRENT_PLAY_INFO.pass_result = module.Enums.PassResult.INCOMPLETE
	end
end)

FFValues.Carrier.Changed:Connect(function(value) -- TODO add check for handoff
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

FFValues.AwayScore.Changed:Connect(function(newScore)
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

	module.Events.AwayScored:Fire(newScore, module.Values.AwayScore, reason)

	module.OldValues.AwayScore = module.Values.AwayScore
	module.OldValues.AwayScoredReason = reason
	module.Values.AwayScore = newScore
end)

FFValues.HomeScore.Changed:Connect(function(newScore)
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

	module.Events.HomeScored:Fire(newScore, module.Values.HomeScore, reason)

	module.OldValues.HomeScore = module.Values.HomeScore
	module.OldValues.HomeScoredReason = reason
	module.Values.HomeScore = newScore
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

return module
