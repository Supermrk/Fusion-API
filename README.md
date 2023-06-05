<h1 align="center">FF2-API</h4>
<h4 align="center">A script that takes in and processes data from the Roblox game <a href="https://www.roblox.com/games/8204899140/Football-Fusion-2">Football Fusion</a> for use in streaming.</h4>
<div align="center">
	<a href="https://github.com/Supermrk/FF2-API"><img src="https://shields.io/github/all-contributors/Supermrk/FF2-API/main" alt="Contributors" /></a>
	<a href="https://github.com/Supermrk/FF2-API"><img src="https://img.shields.io/github/stars/Supermrk/FF2-API" alt="Stars" /></a>
	<a href="https://www.twitch.tv/rosportprogrammingnetwork"><img src="https://img.shields.io/twitch/status/rosportprogrammingnetwork" alt="RSPN Twitch" /></a>
	<a href="https://discord.com/invite/rspn"><img src="https://shields.io/discord/1019419802399416350?label=Discord&color=blue" alt="RSPN Discord" /></a>
</div>
<p align="center">Created by Supermrk</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#usage">Usage</a> •
  <a href="#using-the-api">Using the API</a> •
  <a href="#credits">Credits</a> •
  <a href="#license">License</a>
</p>

---

## Features
* Custom Player, Replay, and Kicker Jerseys
* Custom Field and Stadium Decals
* Advanced Data Collection (Win %, TOP, Play-by-Play Stats, Drive Stats, Player Stats)
* Discord Webhook Updates
* Twitch Chat Score Updates
* Firebase Realtime Updates Integration
* Automatic Twitch Highlight Clipping (uploaded to DynamoDB)
* Automatic Game Stats uploaded to an AWS S3 Bucket at the end of the game
* Automatic Touchdown Songs
* Easily Integratable API for your own Open-Source Projects

---

## About
This collection of scripts were initially created for [RSPN](https://www.twitch.tv/rosportprogrammingnetwork), a Roblox Sports Streaming Network. However, because of the introduction of Roblox's Byfron Anticheat, it was only ever used once.

At the time of this being written, no injector has yet to bypass the Anticheat, thus making it reasonable for me to make this code public. These scripts **arent in the most usable state**, but below I will vaguely explain how to use them. 

If you're interested in how I wrote certain parts of the script, or have another question, feel free to DM me on Discord **@Supermrk**. I will not help you use these scripts, however. This Github will continue to be public and if you're interested in adding updates, feel free to commit changes and I will merge those that seem fit.

---

## Requirements
- A Roblox Script Injector - The only confirmed working injectors are either Synapse X or one that follows the [Unified Naming Convention](https://scriptunc.org/).

---

## Usage
To use this script, just run the `ScorebugScript.lua` file under the `src` folder. The first time you run the script, it will kick you from the game and make a `config.json` file under the Workspace folder of your injector. **You are required** to fill out the `Home Team` and `Away Team` inputs with a College Team's Name (database is in the `Utilities.lua` folder), the others are completely optional.

If you're wanting to use any of the Twitch specific features, then the second time you run the script a URL will be copied to your clipboard so you can complete the OAuth2 process. Also, make sure to change the Twitch Channels table under the `Utilities.lua` folder.

---

## Using the API
If you're not interested in using the pre-made central script and want to create your own, using the modules as APIs is simple.

### Initialising the APIs:
**Required:** You must initialise any modules you wish to use.
 ```lua
-- You may replace the URL with a raw version of your script
local FFAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FF2-API/main/src/Modules/FFAPI.lua', true))()
local Utilities = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FF2-API/main/src/Modules/Enviroment.lua', true))()
local Enviroment = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FF2-API/main/src/Modules/Utilities.lua', true))()
 ```
 
 ---
 
 ### 1. Setting Teams:
 **Required:** This is required before any of the scripts can work.
 
 **1. If you're using the built in config:**
  ```lua
  local config = Utilities:GetConfig()
  ```
 **2. Getting the Team's Info:**
  ```lua
  -- Using the Config
  local awayInfo = Utilities:GetTeam(config.GameInfo.Away)
  local homeInfo = Utilities:GetTeam(config.GameInfo.Home)
  
  -- Using a String
  local awayInfo = Utilities:GetTeam("Minnesota")
  local homeInfo = Utilities:GetTeam("Michigan State")
  ```
  **3. Setting the Teams in the Modules:**
  ```lua
  FFAPI.Settings.AwayTeam = awayInfo
  FFAPI.Settings.HomeTeam = homeInfo
  
  Enviroment:SetTeams(awayInfo,homeInfo)
  ```
  
  ---
  
  ### 2. Accessing Values from the FF-API
  Most of the values are stored under the module table returned after loading/requiring any of the APIs. Here's a few examples of fetching data:
  ```lua
  print("Away Score", FFAPI.Values.AwayScore)
  print("Away Win Percentage", FFAPI.Values.AwayInfo.WIN)
  print("Away Time of Possession", FFAPI.Values.AwayInfo.TOP)
  print("Current Drive Plays", FFAPI.Values.CurrentDrive.PLAYS)
  ```
  For a full list, take a look at the `FFAPI.lua` module.
  
  ---
  
  ### 3. Listening for Events
  There are plenty of events included in the FFAPI. Here's an example of connecting to the `HomeScored` Event:
  ```lua
  FFAPI.Events.HomeScored.Event:Connect(function(newScore, scoreReason)
	  print("The home team has scored!", newScore, scoreReason)
  end)
  ```
  For a full list of events, take a look at the `FFAPI.lua` module under `module.Events`.
  
  ### 4. Swapping Teams
  It's useful to have a keybind to automatically swap teams in case the team you selected as the Home Team is actually the Away Team (it happens all of the time). Here's an example of how you can do that:
  ```lua
  game:GetService("UserInputService").InputBegan:Connect(function(input)
	local keyCode = input.KeyCode
	
	if (keyCode == Enum.KeyCode.F5) then -- You can change the keycode
		local awayInfo = FFAPI.Settings.AwayTeam
		local homeInfo = FFAPI.Settings.HomeTeam
		
		FFAPI.Settings.AwayTeam = homeInfo
		FFAPI.Settings.HomeTeam = awayInfo
		
		Enviroment:SetTeams(homeInfo,awayInfo)
	end
end)
```

---

## Credits
* Supermrk - Lead Developer.
* Hayden - Helped with creating the College Teams database and testing.
* Alfredo - Helped with testing.
* Vol - For giving us permission to use these scripts, as well as giving us tons of Primetime and Playoff games.
* XSTNS & Bayton - For creating Football Fusion and for giving us permission to use scripts for the purpose of streaming.
* Arvoria - For creating the Firebase Roblox Wrapper, Robase.

---

## License
[GNU GPL-3.0](https://raw.githubusercontent.com/Supermrk/FF2-API/main/LICENSE)
