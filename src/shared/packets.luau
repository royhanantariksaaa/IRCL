local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local ByteNet = require(Shared:FindFirstChild("ByteNet") or error("ByteNet module not found"))

return ByteNet.defineNamespace("remote", function()
    return {
        sendMousePosition = ByteNet.definePacket({
            value = ByteNet.vec3,
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 32,
            reliabilityType = 'reliable'
        }),
        sendCameraCFrame = ByteNet.definePacket({
            value = ByteNet.struct({
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 32,
            reliabilityType = 'reliable'
        }),
        sendMousePositionAndCFrameFromServer = ByteNet.definePacket({
            value = ByteNet.struct({
                player = ByteNet.inst,
                positions = ByteNet.array(ByteNet.array(ByteNet.float32))
            }),
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 16,
            reliabilityType = 'reliable'
        }),
        -- sendMousePositionAndCFrameFromServer = ByteNet.definePacket({
        --     value = ByteNet.struct({
        --         player = ByteNet.inst,
        --         positions = ByteNet.array(ByteNet.vec3),
        --         rotations = ByteNet.array(ByteNet.vec3),
        --         scrolls = ByteNet.array(ByteNet.float32)
        --     }),
        --     Quota = 1,
        --     QuotaPerFrame = 1,
        --     Rate = 32,
        --     reliabilityType = 'unreliable'
        -- }),
        
        stopSendMousePositionAndCFrame = ByteNet.definePacket({
            value = ByteNet.bool,
            Quota = 1,
            QuotaPerFrame = 1,
            Rate = 62,
            reliabilityType = 'reliable'
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