local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared : Model = ReplicatedStorage:FindFirstChild("Shared") or error("Shared model not found")
local packets = require(Shared:FindFirstChild("packets") or error("packets module not found"))
local Create = require(Shared:FindFirstChild("Create") or error("Create module not found"))
local Edit = require(Shared:FindFirstChild("Edit") or error("Edit module not found")) 

if RunService:IsServer() then
    Players.CharacterAutoLoads = false
    local Characters = {
        List = {}
    }

    local ServerStorage = game:GetService("ServerStorage")
    local R15Parts = ServerStorage:FindFirstChild("ClassicS15") or error("R15 parts not found")
    local AppearanceLoaderFolders = Create("Folder", {
        Name = "FaceLoaders",
        Parent = ReplicatedStorage,
    })

    local CharacterTemplate = Create("Model", {
        Name = "StarterCharacter",
    })
    local HumanoidRootPart = Create("Part", {
        Name = "HumanoidRootPart",
        Size = Vector3.new(2, 2, 1),
        Transparency = 1,
        Anchored = false,
        CanCollide = true,  
        Parent = CharacterTemplate
    })
    local _Humanoid = Create("Humanoid", {
        HipHeight = 2,
        RigType = Enum.HumanoidRigType.R15,
        AutomaticScalingEnabled = true,
        RequiresNeck = false,
        Parent = CharacterTemplate
    })
    CharacterTemplate.PrimaryPart = HumanoidRootPart
    CharacterTemplate.Parent = StarterPlayer

    function GetHumanoidDescription(UserId)
        local CreatedHumanoidDescription = Create("HumanoidDescription",{
            Face = 0,
            BodyTypeScale = 0,
            DepthScale = 1,
            HeadScale = 1,
            HeightScale = 1,
            ProportionScale = 0,
            WidthScale = 1,
        })
        local _,_ = pcall(function()
            local HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(UserId)
            Edit(CreatedHumanoidDescription,{
                Face = HumanoidDescription.Face,
                Shirt = HumanoidDescription.Shirt,
                Pants = HumanoidDescription.Pants,
                HeadColor = HumanoidDescription.HeadColor,
                TorsoColor = HumanoidDescription.TorsoColor,
                RightArmColor = HumanoidDescription.RightArmColor,
                LeftArmColor = HumanoidDescription.LeftArmColor,
                RightLegColor = HumanoidDescription.RightLegColor,
                LeftLegColor = HumanoidDescription.LeftLegColor,
                HatAccessory = HumanoidDescription.HatAccessory,
                HairAccessory = HumanoidDescription.HairAccessory,
                FaceAccessory = HumanoidDescription.FaceAccessory,
                NeckAccessory = HumanoidDescription.NeckAccessory,
            })
            return HumanoidDescription
        end)
        return CreatedHumanoidDescription
    end

    function Characters.Init(Player)
        local PerPlayerLoader = R15Parts:Clone()
        PerPlayerLoader.Name = Player.Name
        PerPlayerLoader.Parent = AppearanceLoaderFolders
        local PerPlayerHumanoid = PerPlayerLoader:FindFirstChildOfClass("Humanoid")
        Characters.List[Player] = {
            Model = nil,
            HumanoidDescription = GetHumanoidDescription(Player.UserId < 0 and 19086276 or Player.UserId),
            FakeModel = PerPlayerLoader,
            RigType = Enum.HumanoidRigType.R15,
        }
        local Character = Characters.List[Player]
        task.spawn(function()
            if Character.HumanoidDescription then PerPlayerHumanoid:ApplyDescription(Character.HumanoidDescription) end
        end)
        Player.CharacterAdded:Connect(function(character: Model)  
            Characters.New(Player, character)
        end)
        Player:LoadCharacter()
        return Character
    end

    function Characters.GetCharacter(Player)
        local Character = Characters.List[Player]
        return Character
    end

    function Characters.New(Player, character)
        local Character = Characters.List[Player]
        local Humanoid = character:FindFirstChildOfClass("Humanoid")
        Humanoid.Died:Connect(function(...: any)  
            Character.HumanoidDescription = GetHumanoidDescription(Player.UserId < 0 and 19086276 or Player.UserId)
            local PerPlayerLoader = AppearanceLoaderFolders:FindFirstChild(Player.Name)
            local PerPlayerHumanoid = PerPlayerLoader:FindFirstChildOfClass("Humanoid")
            task.spawn(function()
                if Character.HumanoidDescription then PerPlayerHumanoid:ApplyDescription(Character.HumanoidDescription) end
            end)
            wait(Players.RespawnTime)
            Player:LoadCharacter()
        end)
        return character
    end

    function Characters.Destroy(Player)
        local FaceLoader = AppearanceLoaderFolders:FindFirstChild(Player.Name)
        if FaceLoader then
            FaceLoader:Destroy()
        end
    end

    return Characters
else
    local Player = Players.LocalPlayer
    local Mouse = require(Shared:FindFirstChild("Mouse") or error("Mouse module not found"))
    
    local R6Parts = {
        {
            Part = {
                Name = "Torso",
                Size = Vector3.new(2, 2, 1),
            },
            Joint = {
                Name = "RootJoint",
                Part0 = "HumanoidRootPart",
                Part1 = "Torso",
                C0 = CFrame.new(0, 0, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0),
                C1 = CFrame.new(0, 0, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0),
            },
        },
        {
            Part = {
                Name = "Head",
                Size = Vector3.new(2, 1, 1),
            },
            Joint = {
                Name = "Neck",
                Part0 = "Torso",
                Part1 = "Head",
                C0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0),
                C1 = CFrame.new(0, -0.5, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0),
            },
        },
        {
            Part = {
                Name = "Left Arm",
                Size = Vector3.new(1, 2, 1),
            },
            Joint = {
                Name = "Left Shoulder",
                Part0 = "Torso",
                Part1 = "Left Arm",
                C0 = CFrame.new(-1, 0.5, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0),
                C1 = CFrame.new(0.5, 0.5, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0),
            },
        },
        {
            Part = {
                Name = "Right Arm",
                Size = Vector3.new(1, 2, 1),
            },
            Joint = {
                Name = "Right Shoulder",
                Part0 = "Torso",
                Part1 = "Right Arm",
                C0 = CFrame.new( 1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0),
                C1 = CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0),
            },
        },
        {
            Part = {
                Name = "Left Leg",
                Size = Vector3.new(1, 2, 1),
            },
            Joint = {
                Name = "Left Hip",
                Part0 = "Torso",
                Part1 = "Left Leg",
                C0 = CFrame.new(-1, -1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0),
                C1 = CFrame.new(-0.5, 1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0),
            },
        },
        {
            Part = {
                Name = "Right Leg",
                Size = Vector3.new(1, 2, 1),
            },
            Joint = {
                Name = "Right Hip",
                Part0 = "Torso",
                Part1 = "Right Leg",
                C0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0),
                C1 = CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0),
            },
        },
    }

    local OnDied = {}
    local LocalCharacter = {}
    local Characters = {
        List = {},
    }
    local AppearanceLoaderFolders = ReplicatedStorage:FindFirstChild("FaceLoaders") or error("FaceLoaders not found")
    local AnimationFolder = Shared:FindFirstChild("AnimationFolder") or error("Animations not found")

    function Characters.OnDied(func)
        table.insert(OnDied, func)
    end

    function Characters.processOnPlayerDied(player)
        for _, func in pairs(OnDied) do
            func(player)
        end
    end

    function Characters.New(player)
        player = player or Player
        local Character 
        if player == Player then
            LocalCharacter = {
                Model = player.Character or player.CharacterAdded:Wait() or error("Character not found"),
                Humanoid = player.Character.Humanoid or error("Humanoid not found"),
                FakeModel = nil,
                Parts = {},
                Joints = {},
                LoadedAnimations = {},
                FollowMouse = true,
                RigType = player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15",
            }
            Character = LocalCharacter
        else
            Characters.List[player] = {
                Model = player.Character or player.CharacterAdded:Wait() or error("Character not found"),
                Humanoid = player.Character.Humanoid or error("Humanoid not found"),
                FakeModel = nil,
                Parts = {},
                Joints = {
                    Neck = nil,
                    Waist = nil,
                    LeftShoulder = nil,
                    RightShoulder = nil,
                    LeftHip = nil,
                    RightHip = nil,
                    LeftKnee = nil,
                    RightKnee = nil,
                    LeftElbow = nil,
                    RightElbow = nil,
                    LeftAnkle = nil,
                    RightAnkle = nil,
                    LeftWrist = nil,
                    RightWrist = nil,
                },
                RigType = player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15",
            }
            Character = Characters.List[player]
        end
        if Character.RigType == "R6"  then
            for Name, Info in pairs(R6Parts) do
                local NewPart = Create("Part", Info.Part)
                if Character.RigType == "R6" and Info.Part.Name == "Head" then
                    local SpecialMesh = Create("SpecialMesh", {
                        Name = "Mesh",
                        Scale = Vector3.new(1.25, 1.25, 1.25),
                        Parent = NewPart,
                    })
                end
                local Part0 = Character[Info.Joint.Part0] or error(`Part0 not found, {Info.Joint.Part0}, {Character[Info.Joint.Part0]}`)
                local _JointData = Info.Joint
                _JointData.Part0 = Part0
                _JointData.Part1 = NewPart
                _JointData.Parent = NewPart 
                local Joint = Create("Motor6D", _JointData)
                NewPart.Parent = Character.Model
                Character[NewPart.Name] = NewPart
            end
        elseif Character.RigType == "R15" then
            local CharacterLoader = AppearanceLoaderFolders:FindFirstChild(player.Name)
            if not CharacterLoader then return end
            local FakeHead = CharacterLoader.Head
            local Cloned = CharacterLoader:Clone()
            local RootPart = Character.Humanoid.RootPart
            Cloned.LowerTorso.Root.Part0 = RootPart
            Character.Humanoid.HipHeight = Cloned.Humanoid.HipHeight
            Cloned.HumanoidRootPart:Destroy()
            Cloned.Humanoid:Destroy()
            for i,v in Cloned:GetChildren() do
                local Joint = v:FindFirstChildOfClass("Motor6D")
                if Joint then
                    Character.Joints[Joint.Name] = Joint
                end
                v.Parent = Character.Model
                Character.Parts[v.Name] = v
            end
            local IKNeckLookAt = Character.Humanoid.RootPart:FindFirstChild("IKLookAt") or Create("Attachment", {
                    Name = "IKLookAt",
                    Parent = Character.Humanoid.RootPart,
                })
            IKNeckLookAt.WorldPosition = Mouse.Hit.Position
            local IKNeck = Character.Humanoid:FindFirstChild("IKNeck") or Create("IKControl", {
                    Name = "IKNeck",
                    Type = Enum.IKControlType.LookAt,
                    Priority = 1,
                    SmoothTime = 0.12,
                    ChainRoot = Character.Parts.UpperTorso,
                    EndEffector = Character.Parts.Head,
                    Target = IKNeckLookAt,
                    Parent = Character.Humanoid,
                })
            IKNeck.Target = IKNeckLookAt
            local IKRootTilt = Character.Humanoid:FindFirstChild("IKRootTilt") 
            if not IKRootTilt then
                local IKRootTiltAttachment = Create("Attachment", {
                    Name = "IKRootTiltAttachment",
                    CFrame = CFrame.new(0,0,-150),
                    Parent = RootPart
                })
                local IKRootTilt = Create("IKControl", {
                    Name = "IKRootTilt",
                    Type = Enum.IKControlType.LookAt,
                    Priority = 0,
                    SmoothTime = 0.12,
                    ChainRoot = RootPart,
                    EndEffector = Character.Parts.LowerTorso,
                    Target = IKRootTiltAttachment,
                    Parent = Character.Humanoid
                })
            end
            local RightArmBendPole = RootPart:FindFirstChild("RightArmBendPole") or Create("Attachment", {
                Name = "RightArmBendPole",
                Position = Vector3.new(2,0,0),
                Parent = Character.Parts.UpperTorso,
            })
            local LeftArmBendPole = RootPart:FindFirstChild("LeftArmBendPole") or Create("Attachment", {
                Name = "LeftArmBendPole",
                Position = Vector3.new(-2,0,0),
                Parent = Character.Parts.UpperTorso,
            })
            local IKRightHand = Character.Humanoid:FindFirstChild("IKRightHand") or Create("IKControl", {
                Name = "IKRightHand",
                Type = Enum.IKControlType.Transform,
                Priority = 2,
                Weight = 1,
                SmoothTime = 0,
                ChainRoot = Character.Parts.RightUpperArm,
                EndEffector = Character.Parts.RightHand,
                Parent = Character.Humanoid,
            })
            local IKLeftHand = Character.Humanoid:FindFirstChild("IKLeftHand") or Create("IKControl", {
                Name = "IKLeftHand",
                Type = Enum.IKControlType.Transform,
                Priority = 2,
                Weight = 1,
                SmoothTime = 0,
                ChainRoot = Character.Parts.LeftUpperArm,
                EndEffector = Character.Parts.LeftHand,
                Parent = Character.Humanoid,
            })
            CharacterLoader.ChildAdded:Connect(function(child: Instance)  
                local clonedChild = child:Clone()
                clonedChild.Parent = Character.Model
                if clonedChild:IsA("Accessory") then
                    local clonedAccessoryWeld = clonedChild.Handle.AccessoryWeld
                    clonedAccessoryWeld.Part1 = Character.Parts.Head
                end
            end)
            FakeHead.ChildAdded:Connect(function(child)
                if child.Name == "face" then
                    local Head = Character.Parts.Head
                    if Head and Head.face then 
                        Head.face.Texture = child.Texture
                    end
                end
            end)
        end
        Character.Humanoid.Died:Connect(function()
            Characters.processOnPlayerDied(player)
        end)
        for _, Animation in pairs(AnimationFolder:GetChildren()) do
            for _, Track in pairs(Animation:GetChildren()) do
                if Track:IsA("Animation") then
                    Character.LoadedAnimations[Track.Name] = Character.Humanoid:LoadAnimation(Track)
                end
            end
        end
        print(Character)
        return Character
    end

    function Characters.GetCharacter(Player)
        local Character = Characters.List[Player] or LocalCharacter
        return Character
    end

    local function CharacterJoined(player, msg)
        if msg ~= "" then print(msg) end
        Characters.New(player)
    end

    for _, player in Players:GetPlayers() do
        CharacterJoined(player, "")
        player.CharacterAdded:Connect(function(character)
            CharacterJoined(player, "")
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        CharacterJoined(player, "")
        player.CharacterAdded:Connect(function()
            CharacterJoined(player, "")
        end)
    end)

    RunService.RenderStepped:Connect(function(dt)  
        if LocalCharacter.Model then
            local Humanoid = LocalCharacter.Humanoid
            if not Humanoid then return end
            if LocalCharacter.FollowMouse then
                if Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
                    if Humanoid.AutoRotate then
                        Humanoid.AutoRotate = false
                    end
                else
                    if not Humanoid.AutoRotate then
                        Humanoid.AutoRotate = true
                    end
                end
                if not Humanoid.AutoRotate then
                    local AlignOrientation = Humanoid.RootPart:FindFirstChild("AlignOrientation")
                    if not AlignOrientation then
                        local Attachment0 = Create("Attachment", {
                            Parent = Humanoid.RootPart,
                        })
                        AlignOrientation = Create("AlignOrientation", {
                            RigidityEnabled = true,
                            Attachment0 = Attachment0,
                            Mode = Enum.OrientationAlignmentMode.OneAttachment,
                            Parent = Humanoid.RootPart,
                        })
                    end
                    local LookVector = (Mouse.Hit.Position - Humanoid.RootPart.Position).Unit
                    AlignOrientation.CFrame = CFrame.new(Humanoid.RootPart.Position, Humanoid.RootPart.Position + LookVector*Vector3.new(1,0,1))
                    if LocalCharacter.Joints.Neck then
                        local Neck = LocalCharacter.Joints.Neck
                    end
                    local IKLookAt = Humanoid.RootPart:FindFirstChild("IKLookAt")
                    if IKLookAt then
                        IKLookAt.WorldPosition = Mouse.Hit.Position
                    end
                else
                    local AlignOrientation = Humanoid.RootPart:FindFirstChild("AlignOrientation")
                    if AlignOrientation then
                        AlignOrientation:Destroy()
                    end
                end
            else
                if not Humanoid.AutoRotate then
                    Humanoid.AutoRotate = true
                end
                local AlignOrientation = Humanoid.RootPart:FindFirstChild("AlignOrientation")
                if AlignOrientation then
                    AlignOrientation:Destroy()
                end
            end
        end
    end)

    RunService.Stepped:Connect(function(a0: number, a1: number)  
        if LocalCharacter.FollowMouse then
            local RightWrist = LocalCharacter.Joints.RightWrist
            local LeftWrist = LocalCharacter.Joints.LeftWrist
            if RightWrist then
                RightWrist.Transform = CFrame.new()
            end
            if LeftWrist then
                LeftWrist.Transform = CFrame.new()
            end
        end
    end)

    return Characters
end