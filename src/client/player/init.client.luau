local rplctns = script:FindFirstChild("Replications") or error("Replications module not found")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 
local WeaponFolders : Folder = ReplicatedStorage:FindFirstChild("Weapons") or error("Weapons folder not found")

local Input = require(Shared:FindFirstChild("Inputs") or error("Inputs module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))
local Gun = require(Shared:FindFirstChild("Gun") or error("Gun module not found"))
local Camera = require(Shared:FindFirstChild("Camera") or error("Camera module not found"))
local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))
local Characters = require(Shared:FindFirstChild("Character") or error("Character module not found"))

local ClientTime = 0

Input.OnKeyDown(Enum.KeyCode.One, function()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    if not Character then return end
    Gun.Equip(Player, "Primary")
end)

Input.OnKeyDown(Enum.KeyCode.Two, function()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    if not Character then return end
    Gun.Equip(Player, "Secondary")
end)

Input.OnKeyDown(Enum.KeyCode.Three, function()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    if not Character then return end
end)

Input.OnKeyDown(Enum.KeyCode.R, function()
    Gun.Reload()
end)

Mouse.OnMouseMove(function()
    local Character = Characters.GetCharacter(Player)
    if not Character then return end
    -- Character.FollowMouse = true
end)

RunService.RenderStepped:Connect(function(dt: number)      
    ClientTime += dt
end)