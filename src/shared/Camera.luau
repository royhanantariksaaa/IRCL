--!native
--!optimize 2

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))

local Camera = {}
if RunService:IsClient() then
    Camera = {
        spectating = nil,
        SpectatorData = {
            camera = {
                Rotation = Vector3.new(),
                Scroll = 0,
            },
            mouse = {
                WorldPosition = Vector3.new(),
            }
        }
    }
    Cam = workspace.CurrentCamera
    
    function Camera.Get()
        return Cam
    end

    function Camera.GetCameraRotationAndScroll(self)
        local Y,X,Z = Cam.CFrame:ToEulerAnglesYXZ()
        local scroll = (Cam.CFrame.Position - Cam.Focus.Position).Magnitude
        local rotation = Vector3.new(X,Y,Z)
        return rotation, scroll
    end

    function Camera.SendCameraCFrame(self)
        local rotation, scroll = Camera.GetCameraRotationAndScroll()
        local realMouseWorldPos = Mouse.To.Origin + Mouse.To.Direction
        realMouseWorldPos = Cam.CFrame:ToObjectSpace(CFrame.new(realMouseWorldPos)).Position
        packets.sendMousePositionAndCFrame.send({position = realMouseWorldPos, rotation = rotation, scroll = scroll})
    end

    packets.sendMousePositionAndCFrameFromServer.listen(function(data: {player: Player, position: Vector3, rotation: Vector3, scroll: number})
        local player = data.player
        local playerReplication = Camera.SpectatorData
        playerReplication.mouse.WorldPosition = data.position
        playerReplication.camera.Rotation = data.rotation
        playerReplication.camera.Scroll = data.scroll
        Camera.spectating = player
    end)

    RunService.RenderStepped:Connect(function()
        if Camera.spectating ~= nil then
            local playerReplication = Camera.SpectatorData
            local camera = playerReplication.camera
            local mouse = playerReplication.mouse
            local playerRoot = Camera.spectating.Character:FindFirstChild("HumanoidRootPart")
            if not playerRoot then
                return
            end
            Cam.CameraType = Enum.CameraType.Scriptable
            Cam.CFrame = CFrame.new(playerRoot.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0,camera.Rotation.X,0) * CFrame.Angles(camera.Rotation.Y,0,0) * CFrame.new(0,0,camera.Scroll)
            local ConvertedMouseWorldPos = Cam.CFrame:PointToWorldSpace(mouse.WorldPosition)
        else
            Cam.CameraType = Enum.CameraType.Custom
            Camera.SendCameraCFrame()
        end   
    end)
else
    local Clients = require(Shared:FindFirstChild("Clients") or error("Clients module not found"))
    packets.sendMousePositionAndCFrame.listen(function(data: {position: Vector3, rotation: Vector3, scroll: number}, player: Player)
        local client = Clients.GetClient(player)
        local Packet = client.Packets
        if client then
            if Packet.sendMousePositionAndCFrameFromServer.Quota > 0 then
                Packet.sendMousePositionAndCFrameFromServer.Quota -= 1
                client.Camera.Rotation = data.rotation
                client.Camera.Scroll = data.scroll
                client.Mouse.WorldPosition = data.position
            end
        end
    end)
end

return Camera 