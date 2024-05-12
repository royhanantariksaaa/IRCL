local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 

local ByteNet = require(Shared:FindFirstChild("ByteNet") or error("ByteNet module not found"))

return ByteNet.defineNamespace("remote", function()
    return {
        sendMousePosition = ByteNet.definePacket({
            value = ByteNet.vec3
        }),
        sendCameraCFrame = ByteNet.definePacket({
            value = ByteNet.struct({
                rotation = ByteNet.vec3,
                scroll = ByteNet.float32
            })
        })
    }
end)