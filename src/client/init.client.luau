local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))

local ClientTime = 0

local Effects = {}

Mouse:OnMouseButton1Click(function()
    local effect = Create("Part", {
        Size = Vector3.new(1, 1, 1),
        Position = Mouse.Hit.Position,
        Anchored = true,
        CanCollide = false,
        Parent = workspace
    })
    table.insert(Effects, effect)
end)

Mouse:OnMouseMove(function()
    packets.sendMousePosition.send(Mouse.Hit.Position)
end)

local Camera = workspace.CurrentCamera

local function GetCameraRotationAndScroll()
    local X,Y,Z = Camera.CFrame:ToEulerAnglesXYZ()
    local scroll = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
    local rotation = Vector3.new(X,Y,Z)
    return rotation, scroll
end

local function sendCameraCFrame()
    local rotation, scroll = GetCameraRotationAndScroll()
    packets.sendCameraCFrame.send({rotation = rotation, scroll = scroll})
end

RunService.RenderStepped:Connect(function(dt: number)  
    ClientTime += dt
    sendCameraCFrame()
end)

RunService.Heartbeat:Connect(function(dt: number)  
    for i, effect in Effects do
        
    end
end)