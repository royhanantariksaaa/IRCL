
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))  

local Clients = {}
local MousePoses = {}

local function GetCharacterPartsWithHats(Character)
    local parts = {}
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
    return parts, humanoid
end

local function LoadCharacterReplicationParts(client, Player)
    local MousePosPart = Create("Part", {
        Size = Vector3.new(1, 1, 1),
        Position = client.BodyParts.HumanoidRootPart.Position,
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        Name = `MousePosPart`,
        Parent = client.Character
    })    
    local MousePosAttachment = Create("Attachment", {
        Name = `MousePosAttachment`,
        WorldPosition = client.Mouse.WorldPosition,
        Parent = MousePosPart
    })
    client.MousePosPart = MousePosPart
    table.insert(MousePoses, MousePosPart)
end

local function DestroyCharacterReplicationParts(client)
    local MousePosPart = client.MousePosPart
    local index = table.find(MousePoses, MousePosPart)
    if index then
        table.remove(MousePoses, index)
    end
    if MousePosPart then
        MousePosPart:Destroy()
    end
end

local function OnCharacterSpawned(Player, Character)
    local client = Clients[Player]
    if client then
        client.Character = Character
    end
    client.BodyParts,client.Humanoid = GetCharacterPartsWithHats(Character)
    LoadCharacterReplicationParts(client, Player)
    client.Humanoid.Died:Connect(function()
        DestroyCharacterReplicationParts(client)
        client.Character = nil
        client.Humanoid = nil
        client.BodyParts = nil
    end)
end

Players.PlayerAdded:Connect(function(Player)
    local client = {
        Mouse = {
            WorldPosition = Vector3.new(),
            Button1Hold = false,
            Button2Hold = false,
            Button1Click = false,
            Button2Click = false,
        },
        Weapons = {
            List = {},
        }
    }
    Clients[Player] = client
    Player.CharacterAdded:Connect(function(Character)
        OnCharacterSpawned(Player, Character)
    end)
end)

Players.PlayerRemoving:Connect(function(Player)
	local client = Clients[Player] 
    DestroyCharacterReplicationParts(client)
    MousePoses = client.Mouse
    Clients[Player] = nil
end)

RunService.Stepped:Connect(function(dt: number)
    local RootPartCFrames = {}
    for player, client in pairs(Clients) do
        local Humanoid = client.Humanoid
        if Humanoid then
            local RootPart = client.BodyParts.HumanoidRootPart
            local MousePosPart = table.find(MousePoses, client.MousePosPart)
            if MousePosPart then
                RootPartCFrames[MousePosPart] = CFrame.new(RootPart.Position)
            end
        end
    end
    if #MousePoses == #RootPartCFrames then
        workspace:BulkMoveTo(MousePoses, RootPartCFrames, Enum.BulkMoveMode.FireCFrameChanged)
    else
        print("Mismatched MousePoses and RootPartCFrames", #MousePoses, #RootPartCFrames)
    end
end)

return Clients