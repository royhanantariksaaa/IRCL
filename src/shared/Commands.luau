local RunService = game:GetService("RunService")
if RunService:IsClient() then
    return {}
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") or error("Shared module not found")
local Clients = require(Shared:FindFirstChild("Clients") or error("Clients module not found"))
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))


local Commands = {
    Admin = {

    },
    Public = {

    }
}
Commands.__index = Commands

function Commands.GetPlayerFromString(str : string)
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

function Commands.FindCommand(player, cmd)
    for i,v in Commands.Admin do
        local Command = i:lower():sub(1, #cmd)
        if Command == cmd then
            return i, v, true
        else
            print(Command, "Not the command")
        end
    end
    for i,v in Commands.Public do
        local Command = i:lower():sub(1, #cmd)
        if Command == cmd then
            return i, v, false
        else
            print("Not the command")
        end
    end
    print(Commands.Public, Commands.Admin)
    return nil
end

function Commands.RegisterCommand(name, AdminCommand, func)
    if AdminCommand then
        Commands.Admin[name] = func
    else
        Commands.Public[name] = func
    end
end

Clients.OnPlayerJoin(function(player: Player)
    player.Chatted:Connect(function(msg)
        msg = msg:lower()
        local prefix = string.sub(msg, 1, 1)
        if prefix == "!" then
            local args = string.split(msg, " ")
            local command = args[1]:sub(2)
            table.remove(args, 1)
            local _,Command,IsAdminCommand = Commands.FindCommand(player,command)
            if Command then
                print("Found Command")
                Command(player, args)
            end
        end
    end)
end)

Commands.RegisterCommand("kill", true, function(Player, args)
    local target = Commands.GetPlayerFromString(args[#args])
    if target then
        local client = Clients.List[target]
        if client then
            local Humanoid = client.Humanoid
            if Humanoid then
                Humanoid:TakeDamage(Humanoid.Health)
            end
        end
    end
end)

Commands.RegisterCommand("spectate", false, function(Player, args)
    local target = Commands.GetPlayerFromString(args[#args])
    local client = Clients.List[Player]
    if target then
        if client then
            local targetClient = Clients.List[target]
            if targetClient then
                client.Spectate = target
                print("Spectating", target.Name)
            end
        end
    else
        client.Spectate = nil
        packets.stopSendMousePositionAndCFrame.sendTo(true, Player)
    end
end)

return Commands