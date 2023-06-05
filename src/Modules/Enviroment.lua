--[[
This module contains all of the features focusing on enhancing the Football Fusion Enviroment.

This file contains the following features:
* Automatic Team and Kicker Jerseys
* Stadium Colors
* Field Decals (endzones, midfield)
* Automatic Touchdown Songs

Created by Supermrk (@supermrk)
]]

local Services = {
    Storage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players"),
    Tween = game:GetService("TweenService"),
    UserInput = game:GetService("UserInputService")
}

local module = {
    Settings = {
        AssetsFolder = "",
        AwayInfo = nil,
        HomeInfo = nil,
        IsDay = true
    }
}

-----------------------------------------------------------------------
-- Script API Declarations
-----------------------------------------------------------------------
local getcustomasset = getsynasset or getcustomasset

-----------------------------------------------------------------------
-- Final
-----------------------------------------------------------------------
local FFValues = Services["Storage"].Values

-----------------------------------------------------------------------
-- Static
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------
function FindNumbers(children, inner, stroke)
    for i,v in ipairs(children) do
        if (v:IsA("TextLabel")) then
            v.TextColor3 = inner
            v.TextStrokeColor3 = stroke
        elseif (#v:GetChildren() > 0) then
            FindNumbers(v:GetChildren(), inner, stroke)
        end
    end
end

function SetJersey(player, teamInfo, pos)
    pcall(function()
        if not (player.Character) then
            return
        end

        task.spawn(function()
            local uniform = player.Character:WaitForChild("Uniform")
            wait(0.5)

            if not (uniform:FindFirstChild("Helmet")) then
                return
            end

            --Setting Helmet
            uniform.Helmet.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Helmet"])
            uniform.Helmet.Mesh.TextureId = ""

            if (uniform.Helmet:FindFirstChild("RightLogo")) then
                uniform.Helmet.RightLogo.Decal.Texture = getcustomasset(module.Settings["AssetsFolder"] .. teamInfo.City .. " " .. teamInfo.Name  .. "/Logo.png", false)
                uniform.Helmet.LeftLogo.Decal.Texture = getcustomasset(module.Settings["AssetsFolder"] .. teamInfo.City .. " " .. teamInfo.Name  .. "/Logo.png", false)
            end

            --Setting Upper Uniform
            uniform.ShoulderPads.Front.Team.Text = string.upper(teamInfo["Name"])
            uniform.ShoulderPads.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Jersey"])
            uniform.Shirt.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Jersey"])
            uniform.LeftShortSleeve.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Jersey"])
            uniform.RightShortSleeve.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Jersey"])

            --Setting Pants
            uniform.LeftPants.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Pants"])
            uniform.RightPants.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Pants"])

            --Setting Stripes
            uniform.LeftGlove.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Stripe"])
            uniform.LeftShoe.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Stripe"])
            uniform.LeftSock.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Stripe"])
            uniform.RightGlove.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Stripe"])
            uniform.RightShoe.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Stripe"])
            uniform.RightSock.Color = Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["Stripe"])

            --Setting Numbers
            FindNumbers(uniform:GetChildren(), Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["NumberInner"]), Color3.fromHex(teamInfo["Colors"]["Jersey"][pos]["NumberStroke"]))
        end)
    end)
end

function SetTime(time)
    --TODO (night/day)
end

function module:SetTeams(awayInfo, homeInfo)
    module.Settings.AwayInfo = awayInfo
    module.Settings.HomeInfo = homeInfo

    -- Setting Stadium Colors --
    print("[ENVIROMENT] Setting the Stadium's colors.")
    local Stadium = Services["Workspace"].Models.Stadium
    for i,v in ipairs(Stadium.Seats:GetChildren()) do
        v.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Normal.Main)
    end
    for i,v in ipairs(Stadium.PressSeats:GetChildren()) do
        v.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Normal.Light)
    end
    for i,v in ipairs(Stadium.Barrier.PrimaryPads:GetChildren()) do
        v.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Normal.Main)
    end
    for i,v in ipairs(Stadium.Barrier.SecondaryPads:GetChildren()) do
        v.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Normal.Light)
    end
    Services["Workspace"].Models.Uprights1.FGparts.Base.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Normal.Main)
    Services["Workspace"].Models.Uprights2.FGparts.Base.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Normal.Main)

    -- Setting Field --
    local Field = Services["Workspace"].Models.Field
    Field.Grass.Normal.Mid.SurfaceGui.ImageLabel.Image = getcustomasset(module.Settings["AssetsFolder"] .. module.Settings["HomeInfo"].City .. " " .. module.Settings["HomeInfo"].Name  .. "/Logo.png", false)
    Field.Grass.Normal.Mid.SurfaceGui.ImageLabel.ScaleType = Enum.ScaleType.Fit

    if (Field.Grass.Endzone.One:FindFirstChild("SurfaceGui")) then
        print("[ENVIROMENT] Removing default Endzone Decal #1.")
        Field.Grass.Endzone.One.SurfaceGui:Destroy()
    end
    if (Field.Grass.Endzone.Two:FindFirstChild("SurfaceGui")) then
        print("[ENVIROMENT] Removing default Endzone Decal #2.")
        Field.Grass.Endzone.Two.SurfaceGui:Destroy()
    end

    if (module.Settings.HomeInfo.Colors.Endzone) then
        print("[ENVIROMENT] Setting Endzone Color #1.")
        Field.Grass.Endzone.One.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Endzone)
    end
    if (module.Settings.AwayInfo.Colors.Endzone) then
        print("[ENVIROMENT] Setting Endzone Color #2.")
        Field.Grass.Endzone.Two.Color = Color3.fromHex(module.Settings.HomeInfo.Colors.Endzone)
    end

    local endzoneOneLogo = Field.Grass.Endzone.One:FindFirstChild("ArtDecal")
    if (endzoneOneLogo == nil) then
        endzoneOneLogo = Instance.new("Decal")
        endzoneOneLogo.Name = "ArtDecal"
        endzoneOneLogo.Parent = Field.Grass.Endzone.One
        print("[ENVIROMENT] Creating Endzone Decal #1.")
    end
    endzoneOneLogo.Texture = getcustomasset(module.Settings["AssetsFolder"] .. module.Settings["HomeInfo"].City .. " " .. module.Settings["HomeInfo"].Name  .. "/Endzone.png", false)
    endzoneOneLogo.Face = 1
    print("[ENVIROMENT] Set Endzone Decal #1.")

    local endzoneTwoLogo = Field.Grass.Endzone.Two:FindFirstChild("ArtDecal")
    if not (endzoneTwoLogo) then
        endzoneTwoLogo = Instance.new("Decal")
        endzoneTwoLogo.Name = "ArtDecal"
        endzoneTwoLogo.Parent = Field.Grass.Endzone.Two
        print("[ENVIROMENT] Creating Endzone Decal #2.")
    end
    endzoneTwoLogo.Texture = getcustomasset(module.Settings["AssetsFolder"] .. module.Settings["HomeInfo"].City .. " " .. module.Settings["HomeInfo"].Name  .. "/Endzone.png", false)
    endzoneTwoLogo.Face = 1
    print("[ENVIROMENT] Set Endzone Decal #2.")


    -- Setting Jerseys --
    for i,player in ipairs(Services["Players"]:GetPlayers()) do
        print("[ENVIROMENT] Set " .. player.Name .. "'s Jersey")
        if (player.Team.Name == FFValues.Home.Value.Name) then
            SetJersey(player,module.Settings["HomeInfo"],"Home")
        else
            SetJersey(player,module.Settings["AwayInfo"],"Away")
        end
    end
end

function module:Touchdown(isHomeTeam)
    local path = module.Settings["AssetsFolder"] .. module.Settings["HomeInfo"].City .. " " .. module.Settings["HomeInfo"].Name  .. "/Fight Song.mp3"
    if not (isHomeTeam) then
        path = module.Settings["AssetsFolder"] .. module.Settings["AwayInfo"].City .. " " .. module.Settings["AwayInfo"].Name  .. "/Fight Song.mp3"
    end

    if (isHomeTeam) then
        print("[ENVIROMENT] Playing " .. module.Settings["HomeInfo"].City .. "'s Touchdown Song.")
    else
        print("[ENVIROMENT] Playing " .. module.Settings["AwayInfo"].City .. "'s Touchdown Song.")
    end

    local sound = Instance.new("Sound")
    sound.Volume = 1.5
    sound.SoundId = getcustomasset(path,false)
    sound.Parent = Services["Workspace"]
    sound:Play()

    task.spawn(function()
        wait(30)
        if (sound.IsPlaying) then
            local tween = Services["Tween"]:Create(sound,TweenInfo.new(3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut),{Volume = 0})
            tween:Play()
            tween.Completed:Wait()
        end
        sound:Destroy()
    end)
end

function module:SetTime(isDay)
    module.Settings.IsDay = isDay
end

-----------------------------------------------------------------------
-- Listeners
-----------------------------------------------------------------------
FFValues.Away.Changed:Connect(function(team)
    if (team and team:IsA("Team")) then
        team.PlayerAdded:Connect(function(player)
            if (module.Settings["AwayInfo"]) then
                print("[ENVIROMENT] Set " .. player.Name .. "'s Jersey")
                SetJersey(player,module.Settings["AwayInfo"],"Away")
            end
        end)
    end
end)
FFValues.Home.Changed:Connect(function(team)
    if (team and team:IsA("Team")) then
        team.PlayerAdded:Connect(function(player)
            if (module.Settings["HomeInfo"]) then
                print("[ENVIROMENT] Set " .. player.Name .. "'s Jersey")
                SetJersey(player,module.Settings["HomeInfo"],"Home")
            end
        end)
    end
end)

Services["Players"].PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        print("[ENVIROMENT] Set " .. player.Name .. "'s Jersey")
        if (player.Team.Name == FFValues.Home.Value.Name) then
            SetJersey(player,module.Settings["HomeInfo"],"Home")
        else
            SetJersey(player,module.Settings["AwayInfo"],"Away")
        end
    end)
end)

Services["UserInput"].InputBegan:Connect(function(input)
    if not (input.KeyCode == Enum.KeyCode.F6) then
        return
    end

    if (Services["Workspace"]:FindFirstChild("TargetLine")) then
        print("[ENVIROMENT] Disabled the Field Goal Target Line.")
        Services["Workspace"]:FindFirstChild("TargetLine"):Destroy()
        return
    end

    local targetLine = Instance.new("Part")
    targetLine.Size = Vector3.new(160, 2.4, 1)
    targetLine.Transparency = 1
    targetLine.CanCollide = false
    targetLine.Anchored = true
    targetLine.CanTouch = false
    targetLine.Name = "TargetLine"

    local texture = Instance.new("Texture")
    texture.Texture = "rbxassetid://13183925348"
    texture.StudsPerTileU = 20
    texture.StudsPerTileV = 2.4
    texture.Parent = targetLine

    if (Services["Workspace"].LineDown.Position.Z > Services["Workspace"].LineTogo.Position.Z) then
        targetLine.Position = Vector3.new(0, 2.5, -37.00)
        targetLine.Orientation = Vector3.new(90,180,0)
    else
        targetLine.Position = Vector3.new(0, 2.5, 37.00)
        targetLine.Orientation = Vector3.new(90,0,0)
    end

    targetLine.Parent = Services["Workspace"]
    print("[ENVIROMENT] Enabled the Field Goal Target Line.")
end)

Services["Workspace"].DescendantAdded:Connect(function(model)
    if (model:IsA("Model")) then
        if (model.Name == "Kicker" or model.Name == "Punter") then
            if (model:WaitForChild("Humanoid")) then
                if (FFValues.PossessionTag.Value == FFValues.Home.Value.Name) then
                    if (model.Name == "Kicker") then
                        SetJersey({Character = model},module.Settings["AwayInfo"],"Away")
                    else
                        SetJersey({Character = model},module.Settings["HomeInfo"],"Away")
                    end
                else
                    if (model.Name == "Kicker") then
                        SetJersey({Character = model},module.Settings["HomeInfo"],"Home")
                    else
                        SetJersey({Character = model},module.Settings["AwayInfo"],"Home")
                    end
                end
                print("[ENVIROMENT] Set " .. model.Name .. "'s Jersey")
                return
            end
        end

        if (FFValues.StatusTag.Value == "REPLAY") then
            local player
            for i,v in ipairs(Services["Players"]:GetPlayers()) do
                if (v.Name == model.Name) then
                    player = v
                end
            end

            if (player) then
                print("[ENVIROMENT] Set " .. player.Name .. "'s Replay Jersey")
                if (player.Team.Name == FFValues.Home.Value.Name) then
                    SetJersey({Character = model},module.Settings["HomeInfo"],"Home")
                else
                    SetJersey({Character = model},module.Settings["AwayInfo"],"Away")
                end
            end
        end
    end
end)
-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------

for i,player in ipairs(Services["Players"]:GetPlayers()) do
    player.CharacterAdded:Connect(function(character)
        print("[ENVIROMENT] Set " .. player.Name .. "'s Jersey")
        if (player.Team.Name == FFValues.Home.Value.Name) then
            SetJersey(player,module.Settings["HomeInfo"],"Home")
        else
            SetJersey(player,module.Settings["AwayInfo"],"Away")
        end
    end)
end


return module
