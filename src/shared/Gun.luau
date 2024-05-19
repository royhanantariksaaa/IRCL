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
local Players = game:GetService("Players")

local Gun = {}
if RunService:IsClient() then
    local Player = Players.LocalPlayer
    local Characters = require(Shared:FindFirstChild("Character") or error("Character module not found"))
    Gun = {
        states = nil,
        config = nil,
        model = nil,
        Character = nil,
        Animations = {}
    }
    local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))
    local Camera = workspace.CurrentCamera
    local RayFolder = Create("Folder", {
        Name = "Rays",
        Parent = Camera
    })
    local ClonedViewModel
    function Gun.DrawRay(Origin: Vector3, To: Vector3, Color: Color3)
        local RayPart = Create("Part", {
            Size = Vector3.new(0.1, 0.1, (Origin - To).Magnitude),
            Position = (Origin + To) / 2,
            Color = Color,
            Anchored = true,
            CanCollide = false,
            Transparency = 0.5,
            Parent = RayFolder,
        })
        RayPart.CFrame = CFrame.new(RayPart.Position, To)
    end

    function Gun.OnShoot()
        if not Gun.states or not Gun.config or not Gun.Character then
            return
        end
        local HumanoidRootPart = Gun.Character:FindFirstChild("HumanoidRootPart") or error("HumanoidRootPart not found")
        local Origin = HumanoidRootPart.Position + Vector3.new(0, 1, 0)
        local To = Mouse.To.Direction
        local RayParams = Mouse.RayParams
        local Hit = workspace:Raycast(Origin, To, RayParams)
        local Position = To
        if Hit then
            Position = Hit.Position
        end
        local PartOrigin = Gun.model:IsA("Model") and Gun.model.PrimaryPart or Gun.model
        Gun.DrawRay(PartOrigin.Position, Position, Color3.fromRGB(255, 0, 0))
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
        local Character = Characters.GetCharacter(Player)
        local Humanoid = Character.Humanoid
        if Humanoid then
            local IKRightArm = Humanoid:FindFirstChild("IKRightHand")
            local IKLeftArm = Humanoid:FindFirstChild("IKLeftHand")
            local IKRootTiltAttachment = Humanoid.RootPart:FindFirstChild("IKRootTiltAttachment")
            local RightArmBendPole = Character.Parts.UpperTorso:FindFirstChild("RightArmBendPole")
            local LeftArmBendPole = Character.Parts.UpperTorso:FindFirstChild("LeftArmBendPole")
            if IKRootTiltAttachment then
                if Gun.model then
                    if IKRootTiltAttachment.Position ~= Vector3.new(150,0,-150) then
                        IKRootTiltAttachment.Position = Vector3.new(150,0,-150)
                    end
                else
                    if IKRootTiltAttachment.Position ~= Vector3.new(0,0,-150) then
                        IKRootTiltAttachment.Position = Vector3.new(0,0,-150)
                    end
                end
            end
            if IKRightArm then
                if not Gun.states or not Gun.config then
                    if IKRightArm.Enabled ~= false then
                        IKRightArm.Enabled = false
                    end
                    if IKRightArm.Target ~= nil then
                        IKRightArm.Target = nil
                    end
                else
                    if IKRightArm.Enabled ~= true then
                        IKRightArm.Enabled = true
                    end
                    if IKRightArm.Target ~= Gun.model.PrimaryPart.RightHand then
                        IKRightArm.Target = Gun.model.PrimaryPart.RightHand
                    end
                    if RightArmBendPole then
                        if IKRightArm.Pole ~= RightArmBendPole then
                            IKRightArm.Pole = RightArmBendPole
                        end
                    end
                end
            end
            if IKLeftArm then
                if not Gun.states or not Gun.config then
                    if IKLeftArm.Enabled ~= false then
                        IKLeftArm.Enabled = false
                    end
                    if IKLeftArm.Target ~= nil then
                        IKLeftArm.Target = nil
                    end
                else
                    if IKLeftArm.Enabled ~= true then
                        IKLeftArm.Enabled = true
                    end
                    if IKLeftArm.Target ~= Gun.model.PrimaryPart.LeftHand then
                        IKLeftArm.Target = Gun.model.PrimaryPart.LeftHand
                    end
                    if LeftArmBendPole then
                        if IKLeftArm.Pole ~= LeftArmBendPole then
                            IKLeftArm.Pole = LeftArmBendPole
                            print("Setting ArmPole")
                        end
                    end
                end
            end
        end
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
    local ViewModelGun
    function Gun.Equip(Player, Slot: string)
        Gun.Character = Gun.Character or Player.Character or Player.CharacterAdded:Wait()
        if not Gun.Character then
            return
        end
        local Humanoid = Gun.Character:FindFirstChild("Humanoid") or error("Humanoid not found")
        local Character = Characters.GetCharacter(Player)
        if Character then
            -- Character.FollowMouse = true

            Character.LoadedAnimations["GunEquip"]:Play()
        end
        -- Gun.Animations.GunEquip:Play()
        local Head = Gun.Character:FindFirstChild("Head") or error("Head not found")
        local Torso = Gun.Character:FindFirstChild("HumanoidRootPart") 
        local Model = Gun.Character:FindFirstChild(Slot) or Camera:FindFirstChild(Slot) or error("Model not found")
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
        if not Gun.model or not Gun.config then
            return
        end
        -- ViewModelGun = Gun.model:Clone()
        -- ViewModelGun.Parent = ClonedViewModel
        -- local ViewModelRightArm = ClonedViewModel:FindFirstChild("Right Arm") or ClonedViewModel:FindFirstChild("RightHand")
        -- local ViewModelHandle = ViewModelGun:IsA("Model") and ViewModelGun:FindFirstChild("Handle") or ViewModelGun
        -- local ViewModelGrip : Motor6D = ViewModelHandle:FindFirstChild("Grip") or error("Grip must be in the Handle")
        -- if ViewModelGrip.Part0 ~= ViewModelRightArm then
        --     print(ViewModelRightArm)
        --     ViewModelGrip.Part0 = ViewModelRightArm
        --     ViewModelGrip.C0 = CFrame.new()
        -- end
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
        if Grip.Part0 ~= Head then
            Grip.Part0 = Head
            Grip.C0 = CFrame.new(.25,-1,0)
        end
        local IKRootTiltAttachment = Humanoid:FindFirstChild("IKRootTiltAttachment")
        if IKRootTiltAttachment then
            IKRootTiltAttachment.CFrame = CFrame.new(150,0,-150)
        end
        return Gun
    end
    
    function Gun.Unequip(Player)
        local Character = Characters.GetCharacter(Player)
        if Character then
            -- Character.FollowMouse = false
            Character.LoadedAnimations["GunEquip"]:Stop()
            if ViewModelGun then ViewModelGun:Destroy() end
        end
        local Torso = Gun.Character:FindFirstChild("Torso") or Gun.Character:FindFirstChild("UpperTorso")
        local Handle = Gun.model:IsA("Model") and Gun.model:FindFirstChild("Handle") or Gun.model
        local Grip : Motor6D = Handle:FindFirstChild("Grip")
        if Grip.Part0 ~= Torso then
            Grip.Part0 = Torso
            Grip.C0 = CFrame.new(0,0,.5)*CFrame.Angles(1.5,0,0)*CFrame.Angles(0,0,1.5)
        end
        Gun.model = nil
        Gun.config = nil
        Gun.states.equipped = false
    end    

    RunService.RenderStepped:Connect(function(dt: number)
        -- if not ClonedViewModel then ClonedViewModel = Camera:FindFirstChild("ViewModel") end
        -- if Gun.config and (Camera.Focus.Position - Camera.CFrame.Position).Magnitude <= 0.56 then
        --     if ClonedViewModel.Parent ~= workspace.CurrentCamera then
        --         ClonedViewModel.Parent = workspace.CurrentCamera
        --     end
        -- else
        --     if ClonedViewModel.Parent == workspace.CurrentCamera then
        --         ClonedViewModel.Parent = nil
        --     end
        -- end
    end)

    RunService.Heartbeat:Connect(function(dt: number)
        Gun.Update(dt)
    end)

    RunService.Stepped:Connect(function(dt)
        
    end)

    Characters.OnDied(function(Character)
        Gun.Unequip(Character.Parent)
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

    function Gun.LoadLoadout(Player,Character)
        local client = Clients.GetClient(Player)
        if not client then
            return
        end
        local Loadout = client.Weapons
        local Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
        for i, GunData in pairs(Loadout) do
            local GunClone = Character:FindFirstChild(GunData.Gun.Name) or GunData.Gun:Clone()
            local Handle = GunClone:IsA("Model") and (GunClone:FindFirstChild("Handle") or GunClone.PrimaryPart) or Gun
            local Grip = Create("Motor6D", {
                Part0 = Torso,
                Part1 = Handle,
                Name = "Grip",
                C0 = CFrame.new(0,0,.5)*CFrame.Angles(1.5,0,0)*CFrame.Angles(0,0,1.5),
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