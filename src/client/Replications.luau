local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))

local Cameras = workspace:WaitForChild("Cameras")
local Replications = {}

local function GetReplicationObject(partName : string | {string}, parent, className, props)
    local partList = {}
    if type(partName) == "table" then
        for i, name in ipairs(partName) do
            local part = parent:FindFirstChild(name)
            if part then
                table.insert(partList, part)
            else
                part = Create(className, props or {
                    Size = Vector3.new(1, 1, 1),
                    Position = Vector3.new(0, 4.5, 0),
                    Transparency = 1,
                    Anchored = true,
                    CanCollide = false,
                    CanTouch = false,
                    CanQuery = false,
                    Name = name,
                    Parent = parent
                })
                table.insert(partList, part)
            end
        end
    else
        local part = parent:FindFirstChild(partName)
        if part then
            table.insert(partList, part)
        else
            part = Create(className, props or {
                Size = Vector3.new(1, 1, 1),
                Position = Vector3.new(0, 4.5, 0),
                Transparency = 1,
                Anchored = true,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                Name = partName,
                Parent = parent
            })
            table.insert(partList, part)
        end
    end
    return partList
end

RunService.RenderStepped:Connect(function(dt: number)
    for player, obj in Replications do
        if not obj.active then
            return
        end
        local camera = obj.camera
        local mouse = obj.mouse
        local playerCharacter = player.Character
        local playerRoot = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
        if playerRoot then
            -- print(camera)
            local cameraPart = camera.Part
            if not cameraPart then
                camera.Part = GetReplicationObject("CameraPart", Cameras, "Part", {
                    Size = Vector3.new(1, 1, 1),
                    Position = playerRoot.Position + Vector3.new(0, 1.5, 0),
                    Transparency = 1,
                    Anchored = true,
                    CanCollide = false,
                    CanTouch = false,
                    CanQuery = false,
                    Name = player.Name.."-CameraPart",
                
                })[1]
                cameraPart = camera.Part
            end
            local mousePart = mouse.Part
            if not mousePart then
                mouse.Part = GetReplicationObject("MousePosAttachment", cameraPart, "Attachment",{
                    Name = "MousePosAttachment",
                    WorldPosition = mouse.WorldPosition
                })[1]
                mousePart = mouse.Part
            end
            cameraPart.CFrame = CFrame.new(playerRoot.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(camera.Rotation.Y, 0, 0) * CFrame.Angles(0, camera.Rotation.X, 0)  * CFrame.Angles(0, 0, camera.Scroll)
            mousePart.WorldPosition = mouse.WorldPosition
        else
            print("No HumanoidRootPart")
        end
    end
end)

return Replications