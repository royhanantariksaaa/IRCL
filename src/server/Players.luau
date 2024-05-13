
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))  
local cmds : ModuleScript = script.Parent:FindFirstChild("Commands") or error("Commands module not found")
local Commands = require(cmds)


local Cameras = Create("Folder", {
    Name = `Cameras`,
    Parent = workspace
})

local Clients = {}

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
        for _, joint in ipairs(obj:GetChildren()) do
            if joint:IsA("Motor6D") then
                joints[joint.Name] = joint
            end
        end
    end
    return parts, joints, humanoid
end

local function GetInstanceFromPath(part : Instance? | string?, parent : Instance)
    for i, obj in parent:GetChildren() do
        if type(part) == "string" then
            if obj.Name == part then
                return i, obj
            end
        elseif typeof(part) == "Instance" then
            if obj == part then
                return i, obj
            end
        end
    end
    return 
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
        -- local CameraPart = Create("Part", {
        --     Size = Vector3.new(1, 1, 1),
        --     Position = Vector3.new(0, 4.5, 0),
        --     Transparency = 1,
        --     Anchored = true,
        --     CanCollide = false,
        --     CanTouch = false,
        --     CanQuery = false,
        --     Name = `{Player.Name}-CameraPart`,
        --     Parent = Cameras
        -- })    
        -- local MousePosAttachment = Create("Attachment", {
        --     Name = `MousePosAttachment`,
        --     WorldPosition = client.Mouse.WorldPosition,
        --     Parent = CameraPart
        -- })
        -- client.CameraPart = CameraPart
    end
end


local function OnCharacterSpawned(Player, Character)
    local client = Clients[Player]
    if client then
        client.Character = Character
    end
    client.BodyParts, client.BodyJoints,client.Humanoid = GetCharacterPartsWithHats(Character)
    ResetPlayerCamera(client, Player)
    client.Humanoid.Died:Connect(function()
        client.Character = nil
        client.Humanoid = nil
        client.BodyParts = nil
        client.BodyJoints = nil
    end)
end

Players.PlayerAdded:Connect(function(Player)
    local PlayerDatas = {}
    for iPlayer, iClient in Clients do
        table.insert(PlayerDatas, {
            player = iPlayer,
            cameraRotation = iClient.Camera.Rotation,
            cameraScroll = iClient.Camera.Scroll,
            mousePosition = iClient.Mouse.WorldPosition,
        })
    end
    packets.sendPlayersMouseAndCameraData.sendTo(PlayerDatas, Player)
    local client = {
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
            List = {},
        }
    }
    Clients[Player] = client
    Player.CharacterAdded:Connect(function(Character)
        OnCharacterSpawned(Player, Character)
    end)
    Player.Chatted:Connect(function(msg)
        msg = msg:lower()
        local prefix = string.sub(msg, 1, 1)
        if prefix == "!" then
            local args = string.split(msg, " ")
            local command = args[1]:sub(2)
            table.remove(args, 1)
            local _,Command,IsAdminCommand = Commands:FindCommand(Player,command)
            if Command then
                print("Found Command")
                Command(Player, args)
            end
        end
    end)
    ResetPlayerCamera(client, Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    Clients[Player] = nil
end)

RunService.Stepped:Connect(function(dt: number)
    for player, client in pairs(Clients) do
        local Humanoid = client.Humanoid
        if Humanoid then

        end
    end
    -- if #CameraCFrames == #CameraCFrames then
    --     workspace:BulkMoveTo(CameraParts, CameraCFrames, Enum.BulkMoveMode.FireCFrameChanged)
    -- else
    --     print("Mismatched MousePoses and CameraCFrames", #Cameras:GetChildren(), #CameraCFrames)
    -- end
end)

local function GetPlayerFromString(str : string)
    if not str then
        return nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        str = str:lower()
        local playerName = player.Name:lower()
        if playerName:find(str) then
            return player
        end
    end
    return nil
end

Commands:RegisterCommand("kill", true, function(Player, args)
    local target = GetPlayerFromString(args[#args])
    if target then
        local client = Clients[target]
        if client then
            local Humanoid = client.Humanoid
            if Humanoid then
                Humanoid:TakeDamage(Humanoid.Health)
            end
        end
    end
end)

Commands:RegisterCommand("Spectate", false, function(Player, args)
    local target = GetPlayerFromString(args[#args])
    if target then
        local client = Clients[Player]
        if client then
            local targetClient = Clients[target]
            if targetClient then
                packets.sendPlayerSpectating.sendTo(target, Player)
            end
        end
    end
end)

return Clients