--!native
--!optimize 2

export type GunConfig = {
    fire: {
        rate: number,
        mode: 'auto' | 'semi-auto' | 'burst',
        spread: number,
        bullets: number?,
        bulletsPerBurst: number?,
        burstTimeout: number?,
        lastShot: number?,
    },
    caliber: string,
    ammo : {
        current : number,
        max : number,
        reloadTime: number,
        lastReload : number?,
        reloading : boolean?,
    },
}

export type Gun = {
    model : Model | Part,
    config: GunConfig,
    Character: Model,
}

local translationIndexToLoadoutTable = {
    [1] = "Primary",
    [2] = "Secondary",
    [3] = "Grenade",
    [4] = "Equipment",
}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") 
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))

local Gun = {}
if RunService:IsClient() then
    Gun = {
        states = nil,
        config = nil,
        model = nil,
        Character = nil,

    }
    local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))
    local Camera = workspace.CurrentCamera
    
    function Gun.OnShoot()
        print("Called")
    end
    
    function Gun.TriggerHold()
        if not Gun.states or not Gun.config then
            return
        end
        Gun.states.trigger = true
    end
    
    function Gun.TriggerRelease()
        if not Gun.states or not Gun.config then
            return
        end
        Gun.states.trigger = false
    end
    
    function Gun.Reload()
        if not Gun.states or not Gun.config then
            return
        end
        Gun.config.ammo.reloading = true
    end

    function Gun.OnTriggerHold()
        if Gun.config.ammo.current <= 0 then
            Gun.Reload()
            return
        end
        if not Gun.config.ammo.reloading and Gun.config.fire.lastShot >= 60/Gun.config.fire.rate then
            for i = 1, Gun.config.fire.bullets do
                Gun.OnShoot()
            end 
            Gun.config.ammo.current -= 1
            Gun.config.fire.lastShot = 0
        end
    end

    function Gun.OnReload()
        if not Gun.states or not Gun.config then
            return
        end
        if Gun.config.ammo.reloading then
            if Gun.config.ammo.lastReload >= Gun.config.ammo.reloadTime then
                Gun.config.ammo.current = Gun.config.ammo.max
                Gun.config.ammo.reloading = false
                Gun.config.ammo.lastReload = 0
            end
        end
    end

    Mouse.OnMouseButton1Click(function()
        Gun.TriggerHold()
    end)
    
    Mouse.OnMouseButton1Up(function()
        Gun.TriggerRelease()
    end)
    
    function Gun.Update(dt)
        if not Gun.states or not Gun.config then
            return
        end
        if Gun.states.trigger then
            Gun.OnTriggerHold()
            Gun.config.fire.lastShot += dt
        end
        if Gun.config.ammo.reloading then
            print("Reloading")
            Gun.OnReload()
            Gun.config.ammo.lastReload += dt
        end
    end
    
    function Gun.Equip(Player, Slot: string)
        
        Gun.Character = Player.Character or Player.CharacterAdded:Wait()
        local start = tick()
        if not Gun.Character then
            return
        end
        local RightArm = Gun.Character:FindFirstChild("Right Arm") or Gun.Character:FindFirstChild("RightHand")
        local Model = Gun.Character:FindFirstChild(Slot) or Camera:FindFirstChild(Slot)
        if not Model then
            error("GunModel is required")
        end
        packets.equipSlot.send(Slot)
        if Gun.model then
            local currentGun = Gun.model
            Gun.Unequip()
            if currentGun == Model then
                return
            end
        end
        local Config = require(Model:FindFirstChild("Config") or Model:FindFirstChild("GunConfig") or error("Config module not found"))
        Gun.config = Config
        Gun.model = Model      
        if Gun.model.Parent ~= Camera then
            Gun.model.Parent = Camera
        end
        if not Gun.model or not Gun.config then
            return
        end
        if not Gun.config.bullets then
            Gun.config.bullets = 1
        end
        if not Gun.config.bulletsPerBurst then
            Gun.config.bulletsPerBurst = 3
        end
        if not Gun.config.burstTimeout then
            Gun.config.burstTimeout = 0.1
        end
        Gun.states = {
            trigger = false,
        }
        local Handle = Gun.model:IsA("Model") and Gun.model:FindFirstChild("Handle") or Gun.model
        local Grip : Motor6D = Handle:FindFirstChild("Grip") or error("Grip must be in the Handle")
        if Grip.Part0 ~= RightArm then
            Grip.Part0 = RightArm
        end
        print(tick()-start)
        return Gun
    end

    function Gun.Unequip()
        local Torso = Gun.Character:FindFirstChild("Torso") or Gun.Character:FindFirstChild("UpperTorso")
        local Handle = Gun.model:IsA("Model") and Gun.model:FindFirstChild("Handle") or Gun.model
        local Grip : Motor6D = Handle:FindFirstChild("Grip")
        if Grip.Part0 ~= Torso then
            Grip.Part0 = Torso
        end
        Gun.model = nil
        Gun.config = nil
        Gun.states.equipped = false
        Gun.Character = nil
    end    

    RunService.Heartbeat:Connect(function(dt: number)
        Gun.Update(dt)
    end)
elseif RunService:IsServer() then
    local Clients = require(Shared:FindFirstChild("Clients") or error("Clients module not found"))
    local WeaponFolders : Folder = ReplicatedStorage:FindFirstChild("Weapons") or error("Weapons folder not found")

    function Gun.Equip(Player, Slot: string)
        local client = Clients.GetClient(Player)
        if client.equiped then
            local currentSlot = client.equiped
            Gun.Unequip(Player)
            if currentSlot == Slot then
                return
            end
        end
        print(Player,"Equiped",Slot)
        client.equiped = Slot
    end

    function Gun.Unequip(Player)
        local client = Clients.GetClient(Player)
        client.equiped = nil
        print(Player,"Unequiped")
    end

    function Gun.OnShoot()
        print("Called")
    end

    function Gun.GetLoadoutConfigs(Player)
        local client = Clients.GetClient(Player)
        if not client then
            return
        end
        local Loadout = client.Weapons
        for i, GunData in ipairs(Loadout) do
            local Gun = type(GunData.Gun) == 'string' and  WeaponFolders:FindFirstChild(GunData.Gun) or GunData.Gun
            if Gun then
                Loadout[i].Gun = Gun
                Loadout[i].Config = require(Gun:FindFirstChild("Config") or Gun:FindFirstChild("GunConfig") or error("Config module not found"))
            end
        end
    end

    function Gun.LoadLoadout(Player)
        local client = Clients.GetClient(Player)
        if not client then
            return
        end
        local Loadout = client.Weapons
        local Torso = client.BodyParts.Torso or client.BodyParts.UpperTorso
        local Character = Torso.Parent
        for i, GunData in pairs(Loadout) do
            local GunClone = Character:FindFirstChild(GunData.Gun.Name) or GunData.Gun:Clone()
            local Handle = GunClone:IsA("Model") and (GunClone:FindFirstChild("Handle") or GunClone.PrimaryPart) or Gun
            local Grip = Create("Motor6D", {
                Part0 = Torso,
                Part1 = Handle,
                Name = "Grip",
                C0 = CFrame.new(),
                C1 = CFrame.new(),
            })
            GunClone:SetAttribute("Name", GunClone.Name)
            GunClone.Name = translationIndexToLoadoutTable[i]
            Grip.Parent = Handle
            GunClone.Parent = Character
            Loadout[i].Config = require(GunClone:FindFirstChild("Config") or GunClone:FindFirstChild("GunConfig") or error("Config module not found"))
            if not Loadout[i].Config.bullets then
                Loadout[i].Config.bullets = 1
            end
            if not Loadout[i].Config.bulletsPerBurst then
                Loadout[i].Config.bulletsPerBurst = 3
            end
            if not Loadout[i].Config.burstTimeout then
                Loadout[i].Config.burstTimeout = 0.1
            end
        end
    end

    -- Gun Related Packets

    packets.equipSlot.listen(function(data: string, player: Player)
        local client = Clients.GetClient(player)
        local Packet = client.Packets
        if client then
            if Packet.equipSlot.Quota > 0 then
                Packet.equipSlot.Quota -= 1
                Gun.Equip(player, data)
            end
        end
    end)
end

return Gun