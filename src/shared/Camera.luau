--!native
--!optimize 2
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))

local Camera = {}
if RunService:IsClient() then
    local Player = Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local Cam = workspace.CurrentCamera
    local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))

    -- local ViewModel = Shared:FindFirstChild("ViewModel") or error("ViewModel not found")
    -- local ClonedViewModel = ViewModel:Clone()
    -- local CameraPart = Create("Part", {
    --     Size = Vector3.new(0.1, 0.1, 0.1),
    --     Anchored = true,
    --     CanQuery = false,
    --     CanCollide = false,
    --     CanTouch = false,
    --     Transparency = 1,
    --     Parent = ClonedViewModel
    -- })
    -- local ViewModelRightShoulder = Create("Motor6D",{
    --     Part0 = CameraPart,
    --     Part1 = ClonedViewModel.RightUpperArm,
    --     Parent = CameraPart,
    --     C0 = CFrame.new(1.5, 0, -1) * CFrame.Angles(1.5, 0, 0),
    --     C1 = CFrame.new(0, 0, 0)
    -- })
    -- local ViewModelLeftShoulder = Create("Motor6D",{
    --     Part0 = CameraPart,
    --     Part1 = ClonedViewModel.LeftUpperArm,
    --     Parent = CameraPart,
    --     C0 = CFrame.new(-1.5, 0, -1) * CFrame.Angles(1.5, 0, 0),
    --     C1 = CFrame.new(0, 0, 0)
    -- })
    -- ClonedViewModel.Parent = workspace.CurrentCamera

    Camera = {
        spectate = {
            who = nil,
            HumanoidRootPart = nil,
            currentCameraCFrame = CFrame.new(),
            lastCameraCFrame = CFrame.new(),
            currentMousePos = Vector3.new(),
            lastMousePos = Vector3.new(),
            currentScroll = 0,
            currentIndex = 1,
            currentTick = 0,
            lastUpdate = 0
        },
        SpectatorData = {
        }
    }
    
    local ScreenGui = Create("ScreenGui", {
        Parent = PlayerGui
    })
    local SpectatorMouseFrame = Create("Frame", {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 10, 0, 10),
        Parent = ScreenGui
    })

    function Camera.Get()
        return Cam
    end

    function Camera.GetScroll()
        return (Cam.Focus.Position - Cam.CFrame.Position).Magnitude
    end

    function Camera.GetCameraRotationAndScroll()
        local Y,X,Z = Cam.CFrame:ToEulerAnglesYXZ()
        local scroll = Camera.GetScroll()
        local rotation = Vector3.new(X,Y,Z)
        return rotation, scroll
    end

    function Camera.SendCameraCFrame()
        local rotation, scroll = Camera.GetCameraRotationAndScroll()
        packets.sendCameraCFrame.send({rotation = rotation, scroll = scroll})
    end

    local CameraElapsedTime = 0.016

    RunService.RenderStepped:Connect(function(dt)
        CameraElapsedTime = os.clock()
        if Camera.spectate and Camera.spectate.who then
            Cam.CameraType = Enum.CameraType.Scriptable
            local playerReplication = Camera.SpectatorData
            local Spectate = Camera.spectate
            local playerRoot = Spectate.HumanoidRootPart 
            if not playerRoot then
                Spectate.HumanoidRootPart = Camera.spectate.who.Character:FindFirstChild("HumanoidRootPart")
                playerRoot = Spectate.HumanoidRootPart
            end
            local v = playerReplication[Spectate.currentIndex]
            if v then
                local et = math.clamp((CameraElapsedTime - Spectate.lastUpdate)/(1/16),0.016,1)
                Spectate.currentCameraCFrame = Spectate.lastCameraCFrame:Lerp(CFrame.Angles(0,v.rotation.X,0) * CFrame.Angles(v.rotation.Y,0,0), et)    
                Spectate.currentMousePos = Spectate.lastMousePos:Lerp(v.position, et)
            end
            Cam.CFrame = CFrame.new(playerRoot.Position + Vector3.new(0, 1.5, 0)) * Camera.spectate.currentCameraCFrame * CFrame.new(0,0,Camera.spectate.currentScroll)
            local ConvertedMouseWorldPos = Cam.CFrame:PointToWorldSpace(Spectate.currentMousePos)
            local screenPos = Cam:WorldToScreenPoint(ConvertedMouseWorldPos)
            SpectatorMouseFrame.Position = UDim2.new(0, screenPos.X - SpectatorMouseFrame.Size.X.Offset/2, 0, screenPos.Y - SpectatorMouseFrame.Size.Y.Offset/2)
            --Animate Camera based on playerReplication
            if CameraElapsedTime - Spectate.lastUpdate > 1/16 then
                if Spectate.currentIndex < #playerReplication then
                    Spectate.currentIndex += 1
                else
                    Spectate.currentIndex = 1
                end
                Spectate.lastCameraCFrame = Spectate.currentCameraCFrame
                Spectate.lastMousePos = Spectate.currentMousePos
                Spectate.currentCameraCFrame = CFrame.Angles(0,playerReplication[Spectate.currentIndex].rotation.X,0) * CFrame.Angles(playerReplication[Spectate.currentIndex].rotation.Y,0,0)
                Spectate.currentMousePos = playerReplication[Spectate.currentIndex].position
                Spectate.currentScroll = playerReplication[Spectate.currentIndex].scroll
                -- if CameraElapsedTime - Spectate.lastUpdate > 1.2 then
                --     Camera.spectate.who = nil
                --     Camera.spectate = nil
                --     Camera.SendCameraCFrame()
                -- end
                Spectate.lastUpdate = CameraElapsedTime
            end
            Spectate.currentTick = CameraElapsedTime
        else
            Cam.CameraType = Enum.CameraType.Custom
            Camera.SendCameraCFrame()
        end   
        -- CameraPart.CFrame = Cam.CFrame

        CameraElapsedTime = os.clock()
    end)

    packets.sendMousePositionAndCFrameFromServer.listen(function(data: {player: Player, positions: {}})
        local playerReplication = Camera.SpectatorData
        local positions = {}
        for i,v in data.positions do
            local position = Vector3.new(v[5], v[6], v[7])
            local rotation = Vector3.new(v[1], v[2], v[3])
            local scroll = v[4]
            table.insert(positions, {position = position, rotation = rotation, scroll = scroll})
        end
        local playerRoot = data.player.Character and data.player.Character:FindFirstChild("HumanoidRootPart")
        -- CFrame.new(playerRoot.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0,rotation.X,0) * CFrame.Angles(rotation.Y,0,0) * CFrame.new(0,0,scroll)
        --         local ConvertedMouseWorldPos = Cam.CFrame:PointToWorldSpace(mouse)
        local NumberOfSpectatorData
        if Camera.SpectatorData then
            NumberOfSpectatorData = #Camera.SpectatorData
        end
        Camera.SpectatorData = positions
        if NumberOfSpectatorData>0 or Camera.spectate and os.clock() - Camera.spectate.lastUpdate < 1.2 then
            return
        end
        Camera.spectate = {
            who = data.player,
            HumanoidRootPart = playerRoot,
            currentCameraCFrame = CFrame.Angles(0,positions[1].rotation.X,0) * CFrame.Angles(positions[1].rotation.Y,0,0) ,
            lastCameraCFrame = CFrame.Angles(0,positions[1].rotation.X,0) * CFrame.Angles(positions[1].rotation.Y,0,0) ,
            currentMousePos = positions[1].position,
            lastMousePos = positions[1].position,
            currentScroll = positions[1].scroll,
            currentIndex = 1,
            currentTick = CameraElapsedTime,
            lastUpdate = CameraElapsedTime
        }
    end)
    
    packets.stopSendMousePositionAndCFrame.listen(function(data: boolean)
        Camera.spectating = nil
        local playerReplication = Camera.SpectatorData
        playerReplication.mouse.WorldPosition = Vector3.new()
        playerReplication.camera.Rotation = Vector3.new()
        playerReplication.camera.Scroll = 0
    end)
elseif RunService:IsServer() then
    local Clients = require(Shared:FindFirstChild("Clients") or error("Clients module not found"))
    packets.sendCameraCFrame.listen(function(data: {rotation: Vector3, scroll: number}, player: Player)
        local client = Clients.GetClient(player)
        local Packet = client.Packets
        if client then
            if Packet.sendMousePositionAndCFrameFromServer.Quota > 0 then
                Packet.sendMousePositionAndCFrameFromServer.Quota -= 1
                client.Camera.Rotation = data.rotation
                client.Camera.Scroll = data.scroll
                table.insert(client.CamAndPoses, {
                    client.Camera.Rotation.X,
                    client.Camera.Rotation.Y,
                    client.Camera.Rotation.Z,
                    client.Camera.Scroll,
                    client.Mouse.WorldPosition.X,
                    client.Mouse.WorldPosition.Y,
                    client.Mouse.WorldPosition.Z
                })
            end
        end
    end)
    Clients.OnPlayerDie(function(player: Player)
        local client = Clients.GetClient(player)
        client.Spectate = nil
        packets.stopSendMousePositionAndCFrame.sendTo(true, player)
    end)
end

return Camera 