local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local ByteNet = require(Shared:FindFirstChild("ByteNet") or error("ByteNet module not found"))

return ByteNet.defineNamespace("remote", function()
    return {
        sendMousePositionAndCFrame = ByteNet.definePacket({
            value = ByteNet.struct({
                position = ByteNet.vec3,
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 20,
            reliabilityType = 'unreliable'
        }),
        sendMousePositionAndCFrameFromServer = ByteNet.definePacket({
            value = ByteNet.struct({
                player = ByteNet.inst,
                position = ByteNet.vec3,
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 62,
            reliabilityType = 'unreliable'
        }),
        equipSlot = ByteNet.definePacket({
            value = ByteNet.string,
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 10,
            reliabilityType = 'reliable'
        }),
    }
end)