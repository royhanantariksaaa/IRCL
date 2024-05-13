local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clnts : ModuleScript = script:FindFirstChild("Players") or error("Clients module not found")
local Clients = require(clnts)
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))

local ServerTime = 0
local ServerFrame = 0
workspace:SetAttribute("ServerTime", ServerTime)
workspace:SetAttribute("ServerFrame", ServerFrame)

local packetQueues = {}

local function queuePacket(player: Player, packet: () -> (), rate: number)
    if not rate then
        rate = 0
    end
    if not packetQueues[player] then
        packetQueues[player] = {}
    end
    table.insert(packetQueues[player], {packet = packet, rate = rate})
end

RunService.Heartbeat:Connect(function(dt: number)  
    for player, queue in pairs(packetQueues) do
        for i, data in ipairs(queue) do
            if data.rate <= 0 then
                data.packet()
                table.remove(queue, i)
            else
                data.rate -= dt
            end
        end
    end
    ServerTime += dt
    ServerFrame += 1
    workspace:SetAttribute("ServerTime", ServerTime)
    workspace:SetAttribute("ServerFrame", ServerFrame)
end)

packets.sendMousePosition.listen(function(data: Vector3, player: Player)
    local client = Clients[player]
    if client then
        client.Mouse.WorldPosition = data
        queuePacket(player, function()
            packets.sendMousePositionFromServer.sendToAll({player = player, position = data})
        end, 0.1)
    end
end)

packets.sendCameraCFrame.listen(function(data: {rotation: Vector3, scroll: number}, player: Player)
    local client = Clients[player]
    if client then
        client.Camera.Rotation = data.rotation
        client.Camera.Scroll = data.scroll
        -- print('Called', data.scroll, data.rotation)
        packets.sendCameraCFrameFromServer.sendToAll({player = player, rotation = data.rotation, scroll = data.scroll})
    end
end)

packets.sendMousePositionAndCFrame.listen(function(data: {position: Vector3, rotation: Vector3, scroll: number}, player: Player)
    local client = Clients[player]
    if client then
        client.Camera.Rotation = data.rotation
        client.Camera.Scroll = data.scroll
        packets.sendMousePositionAndCFrameFromServer.sendToAllExcept({player = player, position = data.position, rotation = data.rotation, scroll = data.scroll}, player)
    end
end)

-- packets.sendMousePositionAndCFrame.listen(function(data: { number }, player: Player)
--     local client = Clients[player]
--     -- if #data < 7 then
--     --     return
--     -- end
--     if client then
--         local rotation = Vector3.new(data[1], data[2], data[3])
--         local scroll = data[4]
--         local position = Vector3.new(data[5], data[6], data[7])
--         client.Camera.Rotation = rotation
--         client.Camera.Scroll = scroll
--         packets.sendMousePositionAndCFrameFromServer.sendToAll({player = player, position = position, rotation = rotation, scroll = scroll})
--     end
-- end)