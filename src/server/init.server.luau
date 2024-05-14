local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 
local Clients = require(Shared:FindFirstChild("Clients") or error("Clients module not found"))
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Cooldown = require(Shared:FindFirstChild("Cooldown") or error("Cooldown module not found"))
local Commands = require(Shared:FindFirstChild("Commands") or error("Commands module not found"))
local Gun = require(Shared:FindFirstChild("Gun") or error("Gun module not found"))

local ServerTime = 0
local ServerFrame = 0
workspace:SetAttribute("ServerTime", ServerTime)
workspace:SetAttribute("ServerFrame", ServerFrame)

local packetQueues = {}

Clients.OnPlayerJoin(function(player: Player)
    Gun.GetLoadoutConfigs(player)
end)

Clients.OnPlayerSpawn(function(player: Player)
    Gun.LoadLoadout(player)
end)

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
    for player, client in Clients.List do
        local Packets = client.Packets
        if client.Spectate then
            local Spectate = Clients.List[client.Spectate]
            if Spectate then
                packets.sendMousePositionAndCFrameFromServer.sendTo({
                    player = client.Spectate,
                    position = Spectate.Mouse.WorldPosition,
                    rotation = Spectate.Camera.Rotation,
                    scroll = Spectate.Camera.Scroll,
                }, player)
            end
        end
        for name, packet in pairs(Packets) do
            if packet.Quota < packet.QuotaPerFrame then
                if ServerTime - packet.LastSent > packet.Wait then
                    packet.LastSent = ServerTime
                    packet.Quota = packet.QuotaPerFrame
                end
            end
        end
    end
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
    Cooldown:Update(dt)
    ServerTime += dt
    ServerFrame += 1
    workspace:SetAttribute("ServerTime", ServerTime)
    workspace:SetAttribute("ServerFrame", ServerFrame)
end)

-- Commands