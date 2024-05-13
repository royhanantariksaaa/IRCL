local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local ByteNet = require(Shared:FindFirstChild("ByteNet") or error("ByteNet module not found"))

return ByteNet.defineNamespace("remote", function()
    return {
        sendMousePosition = ByteNet.definePacket({
            value = ByteNet.vec3,
            reliabilityType = 'unreliable'
        }),
        sendCameraCFrame = ByteNet.definePacket({
            value = ByteNet.struct({
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            reliabilityType = 'unreliable'
        }),
        sendMousePositionAndCFrame = ByteNet.definePacket({
            value = ByteNet.struct({
                position = ByteNet.vec3,
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            -- value = ByteNet.array(ByteNet.float32),
            reliabilityType = 'unreliable'
        }),
        sendMousePositionAndCFrameFromServer = ByteNet.definePacket({
            value = ByteNet.struct({
                player = ByteNet.inst,
                position = ByteNet.vec3,
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            reliabilityType = 'unreliable'
        }),
        sendMousePositionFromServer = ByteNet.definePacket({
            value = ByteNet.struct({
                player = ByteNet.inst,
                position = ByteNet.vec3
            }),
            reliabilityType = 'unreliable'
        }),
        sendCameraCFrameFromServer = ByteNet.definePacket({
            value = ByteNet.struct({
                player = ByteNet.inst,
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            }),
            reliabilityType = 'unreliable'
        }),
        sendPlayerSpectating = ByteNet.definePacket({
            value = ByteNet.inst,
            reliabilityType = 'unreliable'
        }),
        sendPlayersMouseAndCameraData = ByteNet.definePacket({
            value = ByteNet.array(ByteNet.struct({
                player = ByteNet.inst,
                mousePosition = ByteNet.vec3,
                cameraRotation = ByteNet.vec3,
                cameraScroll = ByteNet.float32
            })),
            reliabilityType = 'unreliable'
        }),
    }
end)