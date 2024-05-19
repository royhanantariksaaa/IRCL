local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))

local AnimationList = {
    Walking = {
        Forward = 17529679643, 
        ForwardLeft = 17531250314,
        ForwardRight = 17531262824,
        Left = 17530372376,
        Right = 17530574794,
        Backward = 17531218375,
        BackwardRight = 17531132940,
        BackwardLeft = 17531148140,
    },
    Gun = {
        Equip = 17540222174
    }
}

return AnimationList