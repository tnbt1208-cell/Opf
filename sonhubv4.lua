-- [[ SON HUB V4 - WINDUI VERSION ]]
-- REMAKE V2: FIX SILENT KILL AURA & OVERHEAD FARM & PLAYER FLY
-- Optimized for Mobile Execution

local WindUI
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)
    if ok then
        WindUI = result
    else
        if RunService:IsStudio() or not writefile then
            WindUI = require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
        else
            WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end
    end
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- [[ CÁC BIẾN TRẠNG THÁI HỆ THỐNG ]]
local FarmEnabled = false
local ChestEnabled = false
local SelectedWeapon = nil
local ForceEquip = false
local CurrentTarget = nil
local FarmMode = "Easy"
local TweenSpeed = 1.0

-- BIẾN BAY TỰ DO (FLY PLAYER)
local FlyEnabled = false
local FlySpeed = 100
local FlyConnection = nil

-- BIẾN MỚI: SILENT KILL AURA & OVERHEAD FARM
local CustomAuraEnabled = false
local CustomAimbotEnabled = false
local AimbotMaxDistance = 400
local OverheadOffset = Vector3.new(0, 12, 0) -- Chiều cao bay trên đầu quái (Tránh quái đánh trúng)

local hardcoreMobs = {
    ["Lv2000 Crocodile"] = true, ["Lv20000 Whitebeard"] = true,
    ["Lv2000 Vokun"] = true, ["Lv40 Cave Demon [Weakened]"] = true,
    ["Lv8000 Gunner Captain"] = true, ["Bandits Leader"] = true,
    ["Bart Nospris"] = true, ["Demon Hunter"] = true,
    ["Fallen Captain"] = true, ["Rayleigh"] = true,
}

local easyMobs = {
    ["Lv1Crab"] = true, ["Lvl1 Boar"] = true, ["Lvl11 Boar"] = true, ["Lvl12 Boar"] = true,
    ["Lvl12 Thug"] = true, ["Lvl14 Bandit"] = true, ["Lvl14 Boar"] = true, ["Lvl15 Bandit"] = true,
    ["Lvl15 Boar"] = true, ["Lvl15 Thug"] = true, ["Lvl16 Boar"] = true, ["Lvl17 Thug"] = true,
    ["Lvl186 Cave Demon"] = true, ["Lvl188 Cave Demon"] = true, ["Lv198 Cave Demon"] = true,
    ["Lv20 Thief"] = true, ["Lv22 Thug"] = true, ["Lv23 Thug"] = true,
    ["Lv24 Thug"] = true, ["Lv24 Fred"] = true,
    ["Lv28 Fredde"] = true, ["Lv28 Freyd"] = true,
    ["Lv28 Friedrich"] = true, ["Lv29 Frued"] = true, ["Lv3 Crab"] = true,
    ["Lv30 Thug"] = true, ["Lv32 Fredric"] = true, ["Lv32 Thief"] = true,
    ["Lv34 Freddi"] = true, ["Lv360 Bruno"] = true,
    ["Lv4 Angry Freddy"] = true, ["Lv4 Boar"] = true, ["Lv4 Crab"] = true, ["Lv40 Thug"] = true,
    ["Lv440 Buster"] = true, ["Lv5 Crab"] = true, ["Lv500 Bucky"] = true, ["Lv9 Bandit Traitor"] = true,
}

local mediumMobs = {
    ["Lv219 Cave Demon"] = true, ["Lv2000 Vokun"] = true, ["Lv300 King Crab"] = true,
}

-- Bypasses Anticheat System bảo vệ nguyên bản
local _old_getgc = getgc
if _old_getgc then getgc = function(...) return {} end end

local function getCharacter() return Player.Character or Player.CharacterAdded:Wait() end

local function getLevelFromName(name)
    if type(name) ~= "string" then return 0 end
    local level = name:match("Lv(%d+)") or name:match("Lvl(%d+)")
    return level and tonumber(level) or 0
end

local function IsValidMobForMode(mobName)
    if type(mobName) ~= "string" then return false end
    if string.find(mobName, "Gunslinger") then return false end
    if FarmMode == "Easy" then return easyMobs[mobName] == true end
    if FarmMode == "Medium" then
        if hardcoreMobs[mobName] then return false end
        return getLevelFromName(mobName) > 200 or mediumMobs[mobName] == true
    end
    if FarmMode == "Hardcore" then return hardcoreMobs[mobName] == true end
    return false
end

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local DamageEvent = Remotes and Remotes:FindFirstChild("DamageEvent")

local function getTableKick()
    local char = getCharacter()
    if char and char:FindFirstChild("Table Kick") then return char["Table Kick"] end
    if Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild("Table Kick") then return Player.Backpack["Table Kick"] end
    return nil
end

local function getToolByName(toolName)
    if not toolName then return nil end
    if Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild(toolName) then return Player.Backpack[toolName] end
    local char = getCharacter()
    return char and char:FindFirstChild(toolName)
end

local function equipWeapon(toolName)
    if not toolName or not ForceEquip then return false end
    local tool = getToolByName(toolName)
    local char = getCharacter()
    if tool and char and tool.Parent ~= char then
        pcall(function() tool.Parent = char end)
    end
    return tool and tool.Parent == char
end

-- [[ SILENT ATTACK: GỬI SÁT THƯƠNG NGẦM (KHÔNG CẦN VUNG TAY) ]]
local function silentAttack(targetMob)
    if not targetMob or not DamageEvent then return end
    local tool = getTableKick() or (SelectedWeapon and getToolByName(SelectedWeapon))
    
    pcall(function()
        -- Gửi gói tin sát thương trực tiếp lên quái, hệ thống vẫn ghi nhận là BẠN đánh
        DamageEvent:FireServer("Click", tool, targetMob.HumanoidRootPart.CFrame)
        DamageEvent:FireServer("Melee", targetMob)
        DamageEvent:FireServer("Hit", tool, targetMob)
    end)
end

-- [[ FIX 1: SILENT KILL AURA - QUÁI LẠI GẦN TỰ MẤT MÁU NGẦM ]]
task.spawn(function()
    while true do
        if CustomAuraEnabled then
            pcall(function()
                local char = getCharacter()
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                local aliveFolder = workspace:FindFirstChild("Alive")
                if myRoot and aliveFolder then
                    for _, npc in pairs(aliveFolder:GetChildren()) do
                        if npc:IsA("Model") and npc ~= char and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                            local distance = (myRoot.Position - npc.HumanoidRootPart.Position).Magnitude
                            -- Phạm vi quái đi vào vùng 25-30 Studs xung quanh bạn sẽ tự động nhận sát thương ngầm
                            if distance <= 30 then
                                silentAttack(npc)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.1) -- Tốc độ gây sát thương aura
    end
end)

-- SMART AIMBOT (LOCK CAM)
RunService.RenderStepped:Connect(function()
    if CustomAimbotEnabled then
        pcall(function()
            local char = getCharacter()
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            local aliveFolder = workspace:FindFirstChild("Alive")
            if myRoot and aliveFolder then
                local closestPart = nil
                local shortestDistance = AimbotMaxDistance
                
                for _, npc in pairs(aliveFolder:GetChildren()) do
                    if npc:IsA("Model") and npc ~= char and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                        local distance = (myRoot.Position - npc.HumanoidRootPart.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPart = npc.HumanoidRootPart
                        end
                    end
                end
                
                if closestPart then
                    local cam = workspace.CurrentCamera
                    cam.CFrame = CFrame.new(cam.CFrame.Position, closestPart.Position)
                end
            end
        end)
    end
end)

-- HÀM TÌM QUÁI FARM
local function findMob()
    local aliveFolder = workspace:FindFirstChild("Alive")
    if not aliveFolder then return nil, nil, nil end
    local bestMob, bestHum, bestRoot = nil, nil, nil
    local lowestLevel = math.huge
    local bestDistance = math.huge
    local myChar = getCharacter()
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    
    for _, npc in ipairs(aliveFolder:GetChildren()) do
        if npc:IsA("Model") and not Players:GetPlayerFromCharacter(npc) and IsValidMobForMode(npc.Name) then
            local level = getLevelFromName(npc.Name)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
            if hum and root and hum.Health > 0 then
                local dist = (myRoot.Position - root.Position).Magnitude
                if level < lowestLevel or (level == lowestLevel and dist < bestDistance) then
                    lowestLevel = level
                    bestDistance = dist
                    bestMob, bestHum, bestRoot = npc, hum, root
                end
            end
        end
    end
    return bestMob, bestHum, bestRoot
end

-- [[ FIX 2: AUTO FARM BAY TRÊN ĐẦU QUÁI (OVERHEAD) CHỐNG BỊ ĐÁNH TRÚNG ]]
task.spawn(function()
    while task.wait(0.02) do
        if not FarmEnabled then
            if CurrentTarget then pcall(function() CurrentTarget.Humanoid.WalkSpeed = 16 end); CurrentTarget = nil end
            continue
        end
        
        local mob, hum, root = findMob()
        if mob and hum and root then
            CurrentTarget = mob
            local char = getCharacter()
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot and root then
                -- Đóng băng quái tại chỗ không cho di chuyển bậy
                pcall(function() 
                    root.AssemblyLinearVelocity = Vector3.zero 
                    hum.WalkSpeed = 0
                end)
                
                -- Nhân vật sẽ liên tục được giữ ở vị trí CỐ ĐỊNH trên đỉnh đầu quái 12 block (Overhead)
                myRoot.CFrame = root.CFrame * CFrame.new(0, OverheadOffset.Y, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                
                -- Thực hiện đấm ngầm liên tục
                silentAttack(mob)
            end
            if hum.Health <= 0 then CurrentTarget = nil end
        end
    end
end)

-- [[ FIX 3: TÍNH NĂNG BAY CHO PLAYER (FLY FUNCTION) ]]
local function HandlePlayerFly()
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    if FlyEnabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "SonHub_FlyVelocity"
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Parent = hrp
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "SonHub_FlyGyro"
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
        
        FlyConnection = RunService.RenderStepped:Connect(function()
            if not FlyEnabled or not hrp.Parent then 
                bodyVelocity:Destroy()
                bodyGyro:Destroy()
                FlyConnection:Disconnect()
                return 
            end
            
            local camCFrame = workspace.CurrentCamera.CFrame
            local moveDirection = Vector3.new(0,0,0)
            
            -- Đọc hướng di chuyển ảo trên Mobile / Keyboard
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camCFrame.RightVector end
            
            -- Hỗ trợ Touch Joystick trên mobile
            if hum.MoveDirection.Magnitude > 0 then
                moveDirection = hum.MoveDirection
            end
            
            bodyVelocity.Velocity = moveDirection * FlySpeed
            bodyGyro.CFrame = camCFrame
        end)
    else
        local oldV = hrp:FindFirstChild("SonHub_FlyVelocity")
        local oldG = hrp:FindFirstChild("SonHub_FlyGyro")
        if oldV then oldV:Destroy() end
        if oldG then oldG:Destroy() end
    end
end

-- VÒNG LẶP AUTO RƯƠNG
task.spawn(function()
    while task.wait(0.2) do
        if ChestEnabled then
            for _, v in ipairs(workspace:GetDescendants()) do
                if not ChestEnabled then break end
                if v and v.Name == "TreasureChest" and v:IsA("Model") then
                    local pos = v:FindFirstChild("Pos1", true) or v:FindFirstChild("PrimaryPart")
                    local char = getCharacter()
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if pos and hrp then
                        pcall(function() hrp.CFrame = pos.CFrame + Vector3.new(0, 3, 0) end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end)

local function getAvailableWeapons()
    local weapons = {"None"}
    if Player:FindFirstChild("Backpack") then
        for _, v in pairs(Player.Backpack:GetChildren()) do if v:IsA("Tool") then table.insert(weapons, v.Name) end end
    end
    return weapons
end

-- [[ KHỞI TẠO INTERFACE WINDUI GỐC ]]
local Window = WindUI:CreateWindow({
    Title = "SON HUB V4 REMAKE",
    Author = "by SonDepTrai",
    Icon = "solar:star-bold",
    Folder = "SON_HUB",
    Theme = "Dark",
    NewElements = true,
    OpenButton = {
        Title = "Open SON HUB",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#FF6B35"), Color3.fromHex("#FFD700")),
    },
})

Window:Tag({ Title = "v4 Remake V2", Color = Color3.fromHex("#FF6B35") })

local FarmTab = Window:Tab({ Title = "Farm System", Icon = "solar:leaf-bold" })
local TeleportTab = Window:Tab({ Title = "Movement & Player", Icon = "solar:planet-bold" })

local FarmSection = FarmTab:Section({ Title = "Overhead Autofarm", Opened = true })

local weaponDropdown
FarmSection:Button({
    Title = "Refresh Weapons List",
    Icon = "refresh-ccw",
    Callback = function()
        local wp = getAvailableWeapons()
        if weaponDropdown then weaponDropdown:Refresh(wp) end
    end
})

weaponDropdown = FarmSection:Dropdown({
    Title = "Select Your Weapon",
    Values = getAvailableWeapons(),
    Value = "None",
    Callback = function(v)
        if v == "None" then SelectedWeapon = nil; ForceEquip = false else SelectedWeapon = v; ForceEquip = true; equipWeapon(v) end
    end
})

FarmSection:Toggle({
    Title = "Auto Farm Mobs (Overhead)",
    Value = false,
    Callback = function(v) FarmEnabled = v end
})

FarmSection:Dropdown({
    Title = "Select Farm Tier",
    Values = {"Easy", "Medium", "Hardcore"},
    Value = "Easy",
    Callback = function(v) FarmMode = v end
})

FarmSection:Divider()
FarmSection:Toggle({
    Title = "🔥 Silent Kill Aura (Quái Tự Mất Máu)",
    Value = false,
    Callback = function(v) CustomAuraEnabled = v end
})

FarmSection:Toggle({
    Title = "🎯 Smart Aimbot (Lock Cam)",
    Value = false,
    Callback = function(v) CustomAimbotEnabled = v end
})

-- Tab Dịch chuyển & Tính năng cho Người chơi
local MovementSection = TeleportTab:Section({ Title = "Player Flight Mode", Opened = true })

MovementSection:Toggle({
    Title = "✈️ Kích Hoạt Tính Năng Fly Player",
    Value = false,
    Callback = function(v) 
        FlyEnabled = v 
        HandlePlayerFly()
    end
})

MovementSection:Slider({
    Title = "Tốc Độ Bay (Fly Speed)",
    Min = 50,
    Max = 300,
    Value = 100,
    Callback = function(v) FlySpeed = v end
})

WindUI:Notify({ Title = "OP Remake V2", Content = "Đã fix hoàn tất Kill Aura và Farm Trên Đầu Quái!", Duration = 4 })
