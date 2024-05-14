
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))

if RunService:IsClient() then
    return {}
end

local Clients = {
    List = {},
    PlayerJoins = {},
    PlayerLeaves = {},
    PlayerSpawns = {},
    PlayerDies = {},
}

function Clients.InitClient(Player)
    local Packets = {}
    for name,packet in packets do
        Packets[name] = {
            Quota = packet.quota or 1,
            QuotaPerFrame = packet.quotaPerFrame or 1,
            LastSent = 0,
            Wait = 1 / (packet.Rate or 1),
        }
    end
    local client = {
        Packets = Packets,
        Mouse = {
            WorldPosition = Vector3.new(),
            Button1Hold = false,
            Button2Hold = false,
            Button1Click = false,
            Button2Click = false,
        },
        Camera = {
            Rotation = Vector3.new(),
            Scroll = 0,
        },
        Weapons = {
            {Gun = "G4"},
            {Gun = "G4"}
        }
    }
    Clients.List[Player] = client
    return client
end

function Clients.GetClients()
    return Clients.List
end

function Clients.GetClient(Player)
    return Clients.List[Player] or Clients.InitClient(Player)
end

function Clients.OnPlayerJoin(callback)
    table.insert(Clients.PlayerJoins, callback)
end

function Clients.OnPlayerLeave(callback)
    table.insert(Clients.PlayerLeaves, callback)
end

function Clients.OnPlayerSpawn(callback)
    table.insert(Clients.PlayerSpawns, callback)
end

function Clients.OnPlayerDie(callback)
    table.insert(Clients.PlayerDies, callback)
end

local function GetCharacterPartsWithHats(Character)
    local parts = {}
    local joints = {}
    local humanoid : Humanoid? = nil
    for _, obj in ipairs(Character:GetChildren()) do
        if obj:IsA("BasePart") then
            parts[obj.Name] = obj
        elseif obj:IsA("Accessory") then
            for _, part in ipairs(obj:GetChildren()) do
                if part:IsA("BasePart") then
                    parts[part.Name] = part
                end
            end
        elseif obj:IsA("Humanoid") then
            humanoid = obj
        end
    end
    return parts, joints, humanoid
end

local function ResetPlayerCamera(client, Player)
    if client.CameraPart then
        local ClientCamera = client.Camera
        ClientCamera.Rotation = Vector3.new()
        ClientCamera.Scroll = 0
    else
        local ClientCamera = client.Camera
        ClientCamera.Rotation = Vector3.new()
        ClientCamera.Scroll = 0
    end
end

local function processOnPlayerJoined(Player)
    for _, callback in ipairs(Clients.PlayerJoins) do
        callback(Player)
    end
end

local function processOnPlayerLeave(Player)
    for _, callback in ipairs(Clients.PlayerLeaves) do
        callback(Player)
    end
end

local function processOnPlayerSpawned(Player, Character)
    for _, callback in ipairs(Clients.PlayerSpawns) do
        callback(Player, Character)
    end
end

local function processOnPlayerDied(Player)
    for _, callback in ipairs(Clients.PlayerDies) do
        callback(Player)
    end
end

local function OnCharacterSpawned(Player, Character)
    local client = Clients.List[Player]
    client.BodyParts, client.BodyJoints,client.Humanoid = GetCharacterPartsWithHats(Character)
    print(Clients.List[Player])
    ResetPlayerCamera(client, Player)
    processOnPlayerSpawned(Player, Character)
    client.Humanoid.Died:Connect(function()
        processOnPlayerDied(Player)
        client.Humanoid = nil
        client.BodyParts = nil
        client.BodyJoints = nil
    end)

end

Players.PlayerAdded:Connect(function(Player)
    local client = Clients.InitClient(Player)
    processOnPlayerJoined(Player)
    Player.CharacterAdded:Connect(function(Character)
        OnCharacterSpawned(Player, Character)
    end)
    ResetPlayerCamera(client, Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    processOnPlayerLeave(Player)
    Clients.List[Player] = nil
end)

RunService.Stepped:Connect(function(dt: number)
    for player, client in pairs(Clients.List) do
        local Humanoid = client.Humanoid
        if Humanoid then

        end
    end
end)

return Clients