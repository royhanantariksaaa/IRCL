local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))

local Mouse
if RunService:IsClient() then
    local Inputs = require(Shared:FindFirstChild("Inputs") or error("Inputs module not found"))
    local Camera = workspace.CurrentCamera
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local GuiService = game:GetService("GuiService")
    Mouse = {
        Position = Vector2.zero,
        Hit = {
            Position = Vector3.zero
        },
        To = {
            Origin = Vector3.zero,
            Direction = Vector3.zero
        },
        Button1Hold = {
            IsHolding = false,
            Time = 0
        },
        Button2Hold = {
            IsHolding = false,
            Time = 0
        },
        RayParams = RaycastParams.new(),
        MouseButton1 = {
            
        },
        MouseButton2 = {
            
        },
        MouseMove = {
            
        }
    }

    function Mouse.SetMouseRayData()
        local Ray = Camera:ScreenPointToRay(Mouse.Position.X, Mouse.Position.Y)
        local Origin = Ray.Origin
        local Direction = Ray.Direction * 1000
        Mouse.To = {
            Origin = Origin,
            Direction = Direction
        }
    end


    function Mouse.GetMouseHit()
        Character = Player.Character or Player.CharacterAdded:Wait()
        Mouse.SetMouseRayData()
        Mouse.RayParams.FilterType = Enum.RaycastFilterType.Exclude
        Mouse.RayParams.FilterDescendantsInstances = {Character, Camera}
        local Hit = workspace:Raycast(Mouse.To.Origin, Mouse.To.Direction, Mouse.RayParams)
        if Hit then
            Mouse.Hit = Hit
            return 
        else
            Mouse.Hit = {
                Position = Mouse.To.Origin + Mouse.To.Direction
            }
        end
        return 
    end

    function Mouse.Update()
        Mouse.Position = Inputs.GetMouseLocation() - GuiService:GetGuiInset() or Vector2.new()
        Mouse.GetMouseHit()
        local ExportedMousePos = Camera.CFrame:PointToObjectSpace(Mouse.To.Origin + Mouse.To.Direction/100)
        packets.sendMousePosition.send(ExportedMousePos)
    end

    function Mouse.OnMouseButton1Click(func)
        table.insert(Mouse.MouseButton1, {func, 1, false})
    end

    function Mouse.OnMouseButton2Click(func)
        table.insert(Mouse.MouseButton2, {func, 1, false})
    end

    function Mouse.OnMouseButton1Down(func)
        table.insert(Mouse.MouseButton1, {func, 2, false})
    end

    function Mouse.OnMouseButton2Down(func)
        table.insert(Mouse.MouseButton2, {func, 2, false})
    end

    function Mouse.OnMouseButton1Up(func)
        table.insert(Mouse.MouseButton1, {func, 3})
    end

    function Mouse.OnMouseButton2Up(func)
        table.insert(Mouse.MouseButton2, {func, 3})
    end

    function Mouse.WhileMouseButton1Down(func)
        table.insert(Mouse.MouseButton1, {func, 4, false})
    end

    function Mouse.WhileMouseButton2Down(func)
        table.insert(Mouse.MouseButton2, {func, 4, false})
    end

    function Mouse.OnMouseMove(func)
        table.insert(Mouse.MouseMove, func)
    end

    Inputs.OnBegin(Enum.UserInputType.MouseButton1, function()
        Mouse.Button1Hold.IsHolding = true
    end)

    Inputs.OnChanged(Enum.UserInputType.MouseMovement, function()
        Mouse.Update()
        for i, doFunc in pairs(Mouse.MouseMove) do
            doFunc()
        end
    end)

    Inputs.OnEnd(Enum.UserInputType.MouseButton1, function()
        Mouse.Button1Hold.IsHolding = false
        for i, doFunc in pairs(Mouse.MouseButton1) do
            if doFunc[2] == 3 then
                doFunc[1]()
            end
        end
    end)


    Inputs.OnBegin(Enum.UserInputType.MouseButton2, function()
        Mouse.Button2Hold.IsHolding = true
    end)

    Inputs.OnEnd(Enum.UserInputType.MouseButton2, function()
        Mouse.Button2Hold.IsHolding = false
        for i, doFunc in pairs(Mouse.MouseButton2) do
            if doFunc[2] == 3 then
                doFunc[1]()
            end
        end
    end)

    RunService.RenderStepped:Connect(function(dt: number)
        Mouse.Update()
        for i, doFunc in Mouse.MouseButton1 do
            if Mouse.Button1Hold.IsHolding then
                if Mouse.Button1Hold.Time < dt then
                    if doFunc[2] == 1 then
                        if doFunc[3] == false then
                            doFunc[1]()
                            doFunc[3] = true
                        end
                    end
                else
                    if doFunc[2] == 2 then
                        if doFunc[3] == false then
                            doFunc[1]()
                            doFunc[3] = true
                        end
                        elseif doFunc[2] == 4 then
                            doFunc[1]()
                        end
                    end
                else
                    if doFunc[3] == true then
                        doFunc[3] = false
                    end
                end
            end
            for i, doFunc in Mouse.MouseButton2 do
                if Mouse.Button2Hold.IsHolding then
                    if Mouse.Button2Hold.Time < dt then
                    if doFunc[2] == 1 then
                        if doFunc[3] == false then
                            doFunc[1]()
                            doFunc[3] = true
                        end
                    end
                else
                    if doFunc[2] == 2 then
                        if doFunc[3] == false then
                            doFunc[1]()
                            doFunc[3] = true
                        end
                        elseif doFunc[2] == 4 then
                            doFunc[1]()
                        end
                    end
                else
                    if doFunc[3] == true then
                        doFunc[3] = false
                    end
                end
            end
            if Mouse.Button1Hold.IsHolding then
                Mouse.Button1Hold.Time += dt
            else
                Mouse.Button1Hold.Time = 0
            end
            if Mouse.Button2Hold.IsHolding then
                Mouse.Button2Hold.Time += dt
            else
                Mouse.Button2Hold.Time = 0
            end
    end)
elseif RunService:IsServer() then
    local Clients = require(Shared:FindFirstChild("Clients") or error("Clients module not found"))
    Mouse = {}
    packets.sendMousePosition.listen(function(data: Vector3, player: Player)
        local client = Clients.GetClient(player)
        local Packet = client.Packets
        if client then
            if Packet.sendMousePosition.Quota > 0 then
                Packet.sendMousePosition.Quota -= 1
                client.Mouse.WorldPosition = data
                table.insert(client.CamAndPoses, {
                    client.Camera.Rotation.X,
                    client.Camera.Rotation.Y,
                    client.Camera.Rotation.Z,
                    client.Camera.Scroll,
                    client.Mouse.WorldPosition.X,
                    client.Mouse.WorldPosition.Y,
                    client.Mouse.WorldPosition.Z
                })
            end
        end
    end)
end
return Mouse