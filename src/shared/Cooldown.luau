local RunService = game:GetService("RunService")
local Cooldown
if RunService:IsServer() then
    Cooldown = {
        PlayerList = {}
    }
    function Cooldown:Update(dt)
        for player, list in pairs(self.PlayerList) do
            for i, data in ipairs(list) do
                if data[2] <= 0 then
                    data[1]()
                    table.remove(list, i)
                else
                    data[2] -= dt
                end
            end
        end
    end
    function Cooldown:OnCooldown(player, func, secs)
        if not self.List[player] then
            self.List[player] = {}
        end
        self.List[player][func] = secs
    end
else
    Cooldown = {
        List = {}
    }
    function Cooldown:OnCooldown(func, secs)
        print("Creating Cooldown")
        self.List[func] = secs
    end
    RunService.Heartbeat:Connect(function(dt)
        for func, secs in Cooldown.List do
            if secs <= 0 then
                func()
                Cooldown.List[func] = nil
                print(secs)
            else
                Cooldown.List[func] -= dt
            end
        end
    end)
end
Cooldown.__index = Cooldown

return Cooldown