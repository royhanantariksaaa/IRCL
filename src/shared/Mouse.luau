local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))

local Camera = workspace.CurrentCamera

local Mouse = {
    Position = Vector2.zero,
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
Mouse.__index = Mouse

function Mouse:SetMouseRayData()
    local Ray = Camera:ScreenPointToRay(self.Position.X, self.Position.Y)
    local Origin = Ray.Origin
    local Direction = Ray.Direction * 1000
    self.To = {
        Origin = Origin,
        Direction = Direction
    }
end


function Mouse:GetMouseHit()
    Character = Player.Character or Player.CharacterAdded:Wait()
    self:SetMouseRayData()
    self.RayParams.FilterType = Enum.RaycastFilterType.Exclude
    self.RayParams.FilterDescendantsInstances = {Character, Camera}
    local Hit = workspace:Raycast(self.To.Origin, self.To.Direction, self.RayParams)
    if Hit then
        self.Hit = {
            Position = Hit.Position,
        }
        return 
    else
        self.Hit = nil
    end
    return 
end

function Mouse:Update()
    self.Position = UserInputService:GetMouseLocation() or Vector2.new()
    self:GetMouseHit()
end

function Mouse:OnMouseButton1Click(func)
    table.insert(self.MouseButton1, {func, 1, false})
end

function Mouse:OnMouseButton2Click(func)
    table.insert(self.MouseButton2, {func, 1, false})
end

function Mouse:OnMouseButton1Down(func)
    table.insert(self.MouseButton1, {func, 2, false})
end

function Mouse:OnMouseButton2Down(func)
    table.insert(self.MouseButton2, {func, 2, false})
end

function Mouse:OnMouseButton1Up(func)
    table.insert(self.MouseButton1, {func, 3})
end

function Mouse:OnMouseButton2Up(func)
    table.insert(self.MouseButton2, {func, 3})
end

function Mouse:OnMouseMove(func)
    table.insert(self.MouseMove, func)
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Mouse.Button1Hold.IsHolding = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        Mouse.Button2Hold.IsHolding = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        Mouse:Update()
        for i, doFunc in pairs(Mouse.MouseMove) do
            doFunc()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Mouse.Button1Hold.IsHolding = false
        for i, doFunc in pairs(Mouse.MouseButton1) do
            if doFunc[2] == 3 then
                doFunc[1]()
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        Mouse.Button2Hold.IsHolding = false
        for i, doFunc in pairs(Mouse.MouseButton2) do
            if doFunc[2] == 3 then
                doFunc[1]()
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt: number)
    Mouse:Update()
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

return Mouse