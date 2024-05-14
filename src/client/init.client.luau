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

local ClientTime = 0

local ScreenGui = Create("ScreenGui", {
    Parent = Player.PlayerGui
})
local SpectatorMouseFrame = Create("Frame", {
    BackgroundTransparency = 0,
    Size = UDim2.new(0, 10, 0, 10),
    Parent = ScreenGui
})

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


RunService.RenderStepped:Connect(function(dt: number)      
    ClientTime += dt
end)

local function UpdateSpectatorMouseFrame(WorldPosition : Vector3)
    local screenPos = Camera:WorldToScreenPoint(WorldPosition)
    SpectatorMouseFrame.Position = UDim2.new(0, screenPos.X - SpectatorMouseFrame.Size.X.Offset/2, 0, screenPos.Y - SpectatorMouseFrame.Size.Y.Offset/2)
end