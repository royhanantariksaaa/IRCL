local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Clients : ModuleScript = script:FindFirstChild("Clients") or error("Clients module not found")
local clients = require(Clients)
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))

local ServerTime = 0

RunService.Heartbeat:Connect(function(dt: number)  
    ServerTime += dt
end)

packets.sendMousePosition.listen(function(data: Vector3, player: Player)
    local client = clients[player]
    if client then
        client.Mouse.WorldPosition = data
        if client.MousePosPart then
            client.MousePosPart.MousePosAttachment.WorldPosition = data
        end
    end
end)

packets.sendCameraCFrame.listen(function(data: {rotation: Vector3, scroll: number}, player: Player)
    local client = clients[player]
    if client then
        print(data.rotation, data.scroll)
    end
end)