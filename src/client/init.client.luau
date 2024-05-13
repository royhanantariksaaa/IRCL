local rplctns = script:FindFirstChild("Replications") or error("Replications module not found")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))

local ClientTime = 0

local Effects = {}
local Replications = require(rplctns)

local function GetPlayerReplicationData(player)
    local replication = Replications[player]
    if not replication then
        replication = {
            active = false,
            camera = {
                Part = nil,
                Rotation = Vector3.new(),
                Scroll = 0,
            },
            mouse = {
                Part = nil,
                WorldPosition = Vector3.new(),
            }
        }
        Replications[player] = replication
    end
    return replication
end

local states = {
    spectating = nil
}

local ScreenGui = Create("ScreenGui", {
    Parent = Player.PlayerGui
})
local SpectatorMouseFrame = Create("Frame", {
    BackgroundTransparency = 0,
    Size = UDim2.new(0, 10, 0, 10),
    Parent = ScreenGui
})

Mouse:OnMouseButton1Click(function()
    local effect = Create("Part", {
        Size = Vector3.new(1, 1, 1),
        Position = Mouse.Hit.Position,
        Anchored = true,
        CanCollide = false,
        Parent = workspace
    })
    table.insert(Effects, effect)
end)

Mouse:OnMouseMove(function()
    -- packets.sendMousePosition.send(realMouseWorldPos)
end)

local Camera = workspace.CurrentCamera

local function GetCameraRotationAndScroll()
    local Y,X,Z = Camera.CFrame:ToEulerAnglesYXZ()
    local scroll = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
    local rotation = Vector3.new(X,Y,Z)
    return rotation, scroll
end

local function UpdateSpectatorMouseFrame(WorldPosition : Vector3)
    local screenPos = Camera:WorldToScreenPoint(WorldPosition)
    SpectatorMouseFrame.Position = UDim2.new(0, screenPos.X - SpectatorMouseFrame.Size.X.Offset/2, 0, screenPos.Y - SpectatorMouseFrame.Size.Y.Offset/2)
end

local function sendCameraCFrame()
    local rotation, scroll = GetCameraRotationAndScroll()
    local mouseHitRayData = Mouse.To
    local realMouseWorldPos = mouseHitRayData.Origin + mouseHitRayData.Direction
    -- local datasToSend = {rotation.X, rotation.Y, rotation.Z, scroll, realMouseWorldPos.X, realMouseWorldPos.Y, realMouseWorldPos.Z}
    -- packets.sendMousePositionAndCFrame.send(datasToSend)
    -- packets.sendArrayTest.send({1,2,3,4,5,6,7,8,9,10})
    packets.sendMousePositionAndCFrame.send({position = realMouseWorldPos, rotation = rotation, scroll = scroll})
end

RunService.RenderStepped:Connect(function(dt: number)  
    ClientTime += dt
    if states.spectating ~= nil then
        local playerReplication = GetPlayerReplicationData(states.spectating)
        local camera = playerReplication.camera
        local mouse = playerReplication.mouse
        local playerRoot = states.spectating.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then
            return
        end
        -- print(camera.Rotation.X, camera.Rotation.Y, camera.Scroll)
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.new(playerRoot.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0,camera.Rotation.X,0) * CFrame.Angles(camera.Rotation.Y,0,0) * CFrame.new(0,0,camera.Scroll)
        if camera.Part then
            camera.Part.CFrame = Camera.CFrame
            if mouse.Part then
                mouse.Part.WorldPosition = playerReplication.mouse.WorldPosition
            end
        end
        UpdateSpectatorMouseFrame(playerReplication.mouse.WorldPosition)
    else
        Camera.CameraType = Enum.CameraType.Custom
        sendCameraCFrame()
    end   
end)

RunService.Heartbeat:Connect(function(dt: number)  
    for i, effect in Effects do
        
    end
end)

packets.sendMousePositionFromServer.listen(function(data: {player: Player, position: Vector3})
    local player = data.player
    local playerReplication = GetPlayerReplicationData(player)
    playerReplication.mouse.WorldPosition = data.position
end)

packets.sendCameraCFrameFromServer.listen(function(data: {player: Player, rotation: Vector3, scroll: number})
    local player = data.player
    local playerReplication = GetPlayerReplicationData(player)
    playerReplication.camera.Rotation = data.rotation
    playerReplication.camera.Scroll = data.scroll
    -- print("Received camera data from server")
end)

packets.sendPlayerSpectating.listen(function(data : Player)
    local player = data
    local playerReplication = GetPlayerReplicationData(player)
    playerReplication.active = true
    states.spectating = data
    -- print("Spectating player: "..player.Name)
end)

packets.sendPlayersMouseAndCameraData.listen(function(data: {player: Player, mousePosition: Vector3, cameraRotation: Vector3, cameraScroll: number})
    for i, playerData in data do
        local player = playerData.player
        local playerReplication = GetPlayerReplicationData(player)
        playerReplication.mouse.WorldPosition = playerData.mousePosition
        playerReplication.camera.Rotation = playerData.cameraRotation
        playerReplication.camera.Scroll = playerData.cameraScroll
    end
end)    