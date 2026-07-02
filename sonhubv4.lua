-- [[ SON HUB V4 - WINDUI VERSION ]]
-- REMAKE VERSION BY USER REQUEST - ADDED AIMBOT & KIll AURA
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
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local isMobile = UserInputService.TouchEnabled
local screenSize = workspace.CurrentCamera.ViewportSize
local isSmallScreen = screenSize.X < 800 or screenSize.Y < 600 or isMobile

-- [[ CÁC BIẾN TRẠNG THÁI HỆ THỐNG ]]
local FarmEnabled = false
local ChestEnabled = false
local SelectedWeapon = nil
local ForceEquip = false
local HakiQuestEnabled = false
local CollectedRings = {}
local CurrentTarget = nil
local AntiAFKEnabled = true
local KillActive = false
local CurrentKillTarget = nil
local FarmMode = "Easy"
local AutoBringCompass = false
local AutoBringOldBook = false
local FlyEnabled = false
local FlySpeed = 200
local FlyConnection = nil
local NoclipEnabled = false
local NoclipConnection = nil
local ESPEnabled = false
local ESPFolder = nil
local ESPConnection = nil
local menuVisible = true
local AutoHakiEnabled = false
local TweenSpeed = 1.0

local AutoSkillEnabled = false
local SelectedSkills = {}
local AvailableSkills = {"Z", "X", "C", "V", "B", "N", "Y", "G", "H", "J", "K", "L", "Q", "T", "F", "U", "P", "E", "R"}

local AutoBringNormalFruit = false
local AutoBringDemonFruit = false

-- [[ BIẾN BỔ SUNG: KILL AURA & SMART AIMBOT ]]
local CustomAuraEnabled = false
local CustomAimbotEnabled = false
local AimbotMaxDistance = 400

local NormalFruitNames = {
    ["apple"]=true, ["banana"]=true, ["greenapple"]=true,
    ["melon"]=true, ["pumpkin"]=true,
    ["cantaloupe"]=true, ["prickly pear"]=true
}

local RAYLEIGH_POSITION = Vector3.new(-1009.7536010742188, 4011.46484375, 10135.1171875)
local SHOP_EMOTES_POSITION = Vector3.new(1514.7469482421875, 260.38421630859375, 2163.8037109375)

local OldBookCollected = false
local AutoChestForOldBook = false
local IsSearchingOldBook = false
local OldBookMonitoringEnabled = false

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

local FruitNames = {
    "Barrier Fruit", "Swim Fruit", "Spring Fruit", "String Fruit",
    "Spin Fruit", "Smelt Fruit", "Snow Fruit", "Slip Fruit",
    "Slow Fruit", "Quake Fruit", "Sand Fruit", "Rumble Fruit",
    "Plasma Fruit", "Phoenix Fruit", "Paw Fruit", "Order Fruit",
    "Magma Fruit", "Ope Fruit", "Luck Fruit", "Love Fruit",
    "Light Fruit", "Hot Fruit", "Gum Fruit", "Gravity Fruit",
    "Gas Fruit", "Float Fruit", "Flare Fruit", "Diamond Fruit",
    "Dark Fruit", "Clone Fruit", "Clear Fruit", "Chop Fruit",
    "Chilly Fruit", "Candy Fruit", "Bomb Fruit", "Buddha Fruit"
}

-- Bypasses Anticheat System bảo vệ nguyên bản
local _old_getgc = getgc
if _old_getgc then getgc = function(...) return {} end end

local _old_getgenv = getgenv
if _old_getgenv then
    getgenv = function(...)
        local env = _old_getgenv(...)
        local safe_env = {}
        for k, v in pairs(env) do
            if type(v) ~= "function" and type(v) ~= "table" then safe_env[k] = v end
        end
        return safe_env
    end
end

local _old_hookfunction = hookfunction
if _old_hookfunction then hookfunction = function(...) return ... end end

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
local SkillsReceiverEvent = Remotes and Remotes:FindFirstChild("SkillsReceiverEvent")
local KeyBindEvent = Remotes and Remotes:FindFirstChild("KeyBindEvent")

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
        task.wait(0.1)
    end
    return tool and tool.Parent == char
end

local function tweenToPosition(position, offset, silent)
    offset = offset or Vector3.new(0, 3, 0)
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    hrp:SetAttribute("AllowTeleport", true)
    local targetCFrame = CFrame.new(position + offset)
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = math.min(0.3 + (distance / 1000), 2.5) / TweenSpeed
    
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    local completed = false
    tween.Completed:Connect(function() completed = true; hrp:SetAttribute("AllowTeleport", false) end)
    tween:Play()
    
    local start = tick()
    while not completed and tick() - start < (duration + 0.5) do task.wait(0.05) end
    if not completed then pcall(function() hrp.CFrame = targetCFrame end) end
    return true
end

-- VÒNG LẶP KIỂM TRA VŨ KHÍ CẦM TRÊN TAY
task.spawn(function()
    while task.wait(0.5) do
        if ForceEquip and SelectedWeapon then
            local char = getCharacter()
            if char then
                local currentTool = char:FindFirstChildWhichIsA("Tool")
                if not currentTool or currentTool.Name ~= SelectedWeapon then equipWeapon(SelectedWeapon) end
            end
        end
    end
end)

-- HÀM TỰ VUNG CHIÊU / ATTACK GỐC
local attackCooldown = 0
local function attack()
    local now = tick()
    if now - attackCooldown < 0.05 then return end
    attackCooldown = now
    
    pcall(function()
        if DamageEvent then
            local tool = getTableKick()
            DamageEvent:FireServer("Click", tool, CFrame.new())
            DamageEvent:FireServer()
            DamageEvent:FireServer("Melee")
            DamageEvent:FireServer("Hit", tool)
        end
    end)
    pcall(function() if SkillsReceiverEvent then SkillsReceiverEvent:FireServer("F", "Table Kick") end end)
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 1)
        task.wait(0.01)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 1)
    end)
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(500, 300), workspace.CurrentCamera.CFrame)
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(500, 300), workspace.CurrentCamera.CFrame)
    end)
    local char = getCharacter()
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    if tool then pcall(function() tool:Activate() end) end
    if KeyBindEvent then pcall(function() KeyBindEvent:FireServer("F", true) end) end
end

-- [[ TÍNH NĂNG THÊM MỚI 1: VÒNG LẶP KILL AURA TỰ CHÉM XUNG QUANH NGOÀI AUTO FARM ]]
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
                            if distance <= 25 then
                                attack()
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- [[ TÍNH NĂNG THÊM MỚI 2: KHÓA MỤC TIÊU SMART AIMBOT ]]
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

-- VÒNG LẶP TỰ ĐỘNG CHẠY SKILL SKILLS
task.spawn(function()
    local skillIndex = 1
    while true do
        task.wait(0.15)
        if not AutoSkillEnabled then skillIndex = 1; continue end
        local skillKeys = {}
        for skill, selected in pairs(SelectedSkills) do
            if selected then table.insert(skillKeys, skill) end
        end
        if #skillKeys == 0 then continue end
        if skillIndex > #skillKeys then skillIndex = 1 end
        
        local keyCode = Enum.KeyCode[skillKeys[skillIndex]]
        if keyCode then
            pcall(function()
                VirtualInput:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.05)
                VirtualInput:SendKeyEvent(false, keyCode, false, game)
            end)
        end
        skillIndex = skillIndex + 1
    end
end)

-- TỰ ĐỘNG HAKI CHỐNG TREO MÁY NGUYÊN BẢN
task.spawn(function()
    while true do
        task.wait(2)
        if AutoHakiEnabled then
            local char = getCharacter()
            if char and not char:GetAttribute("Observation") then
                pcall(function()
                    VirtualInput:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                end)
            end
        end
    end
end)

-- TỰ ĐỘNG GOM TRÁI CÂY, SÁCH CỔ, VÀ LA BÀN
local function bringItemsLoop(toggle, conditionFunc)
    while true do
        task.wait(0.7)
        if toggle then
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then conditionFunc(hrp) end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.7)
        if AutoBringNormalFruit then
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v and v.Name and not Players:GetPlayerFromCharacter(v.Parent) then
                        local lowerName = string.lower(v.Name)
                        if NormalFruitNames[lowerName] and lowerName ~= "coconut" then
                            local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                            if part then pcall(function() part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) end) end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if AutoBringDemonFruit then
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj:IsA("Tool") and table.find(FruitNames, obj.Name) and not Players:GetPlayerFromCharacter(obj.Parent) then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if part then pcall(function() part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) end) end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if AutoBringOldBook then
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj and (string.lower(obj.Name) == "oldbook" or string.lower(obj.Name) == "old book") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if part then pcall(function() part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) end) end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if AutoBringCompass then
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj and string.find(string.lower(obj.Name), "compass") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if part then pcall(function() part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) end) end
                    end
                end
            end
        end
    end
end)

-- HÀM TÌM QUÁI ĐỂ AUTO FARM
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

local function freezeNPC(npc)
    if not npc then return end
    local root = npc:FindFirstChild("HumanoidRootPart")
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end
    if hum then pcall(function() hum.AutoRotate = false; hum.PlatformStand = true; hum.WalkSpeed = 0 end) end
end

local function unfreezeNPC(npc)
    if not npc then return end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.AutoRotate = true; hum.PlatformStand = false; hum.WalkSpeed = 16 end) end
end

-- VÒNG LẶP AUTO FARM CHÍNH CHẠY NGẦM
task.spawn(function()
    while task.wait(0.05) do
        if not FarmEnabled then
            if CurrentTarget then unfreezeNPC(CurrentTarget); CurrentTarget = nil end
            continue
        end
        local mob, hum, root = findMob()
        if mob and hum and root then
            if CurrentTarget ~= mob then
                if CurrentTarget then unfreezeNPC(CurrentTarget) end
                CurrentTarget = mob
            end
            freezeNPC(CurrentTarget)
            local char = getCharacter()
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot and root then
                pcall(function() myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 2.5) end)
            end
            attack()
            if hum.Health <= 0 then unfreezeNPC(CurrentTarget); CurrentTarget = nil end
        end
    end
end)

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

local function GetPlayerList()
    local list = {"None"}
    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= Player then table.insert(list, plr.Name) end end
    return list
end

-- [[ TOẠ ĐỘ KHU VỰC CHỨC NĂNG VÀ ĐẢO ]]
local Islands = {
    ["Sam"] = Vector3.new(-1282.53, 218.00, -1347.59), ["Fisher"] = Vector3.new(-1689.73, 216.00, -320.37),
    ["Sector G9"] = Vector3.new(-2681.07, 216.00, -943.29), ["Marine Ford"] = Vector3.new(-3310.71, 300.75, -3286.47),
    ["Purple Island"] = Vector3.new(-5273.88, 519.50, -7845.15), ["Water Tower"] = Vector3.new(-233.99, 226.00, -1026.76),
    ["Wind Mills"] = Vector3.new(65.12, 224.00, -35.69), ["One House"] = Vector3.new(720.87, 241.00, 1214.81),
    ["Restaurant"] = Vector3.new(1954.35, 218.00, 610.74), ["King Crab"] = Vector3.new(1215.75, 243.00, -268.88),
    ["Cave Island"] = Vector3.new(2052.59, 491.00, -656.71), ["Big Tree"] = Vector3.new(2051.62, 288.00, -1871.25),
    ["Krizma Island"] = Vector3.new(-1072.04, 361.00, 1677.36), ["Gun Island"] = Vector3.new(-1846.41, 222.00, 3402.44),
    ["Ancient Island"] = Vector3.new(-2721.82, 252.69, 1153.06), ["C Island"] = Vector3.new(2953.90, 217.00, 1394.13),
}

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

Window:Tag({ Title = "v4 Remake", Color = Color3.fromHex("#FF6B35") })

local FarmTab = Window:Tab({ Title = "Farm System", Icon = "solar:leaf-bold" })
local ConfigFarmTab = Window:Tab({ Title = "Config", Icon = "solar:cpu-bold" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "solar:planet-bold" })

local FarmSection = FarmTab:Section({ Title = "Main Autofarm", Opened = true })

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
    Title = "Auto Farm Mobs",
    Value = false,
    Callback = function(v) FarmEnabled = v end
})

FarmSection:Dropdown({
    Title = "Select Farm Tier",
    Values = {"Easy", "Medium", "Hardcore"},
    Value = "Easy",
    Callback = function(v) FarmMode = v end
})

-- [[ BỔ SUNG GIAO DIỆN NÚT BẤM CHO TÍNH NĂNG MỚI NẰM NGAY TRÊN TAB FARM ]]
FarmSection:Divider()
FarmSection:Toggle({
    Title = "🔥 Kích Hoạt Kill Aura (25 Studs)",
    Value = false,
    Callback = function(v) CustomAuraEnabled = v end
})

FarmSection:Toggle({
    Title = "🎯 Kích Hoạt Smart Aimbot (Lock Cam)",
    Value = false,
    Callback = function(v) CustomAimbotEnabled = v end
})

FarmSection:Toggle({
    Title = "Auto Collect Chests",
    Value = false,
    Callback = function(v) ChestEnabled = v end
})

-- Tab Thiết Lập Auto Skill
local SkillSection = ConfigFarmTab:Section({ Title = "Auto Attack Skills", Opened = true })
SkillSection:Toggle({ Title = "Toggle Auto Skills", Value = false, Callback = function(v) AutoSkillEnabled = v end })

for _, skill in ipairs(AvailableSkills) do
    SkillSection:Toggle({
        Title = "Skill Bind [" .. skill .. "]",
        Value = false,
        Callback = function(v) SelectedSkills[skill] = v end
    })
end

-- Tab Dịch Chuyển Đảo
local IslandSection = TeleportTab:Section({ Title = "World Teleport", Opened = true })
local IslandNames = {} for n in pairs(Islands) do table.insert(IslandNames, n) end

IslandSection:Dropdown({
    Title = "Choose Target Island",
    Values = IslandNames,
    Value = "None",
    Callback = function(v)
        if v ~= "None" and Islands[v] then tweenToPosition(Islands[v], nil, true) end
    end
})

-- Khởi tạo nút Toggle Menu trên Mobile chống kẹt màn hình
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "SON_Toggle_Remake"
toggleGui.Parent = Player:WaitForChild("PlayerGui")
toggleGui.ResetOnSpawn = false

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, isMobile and 50 or 65, 0, isMobile and 50 or 65)
toggleBtn.Position = UDim2.new(0, 15, 0, isMobile and 60 or 90)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Image = "rbxassetid://86946036155828"
toggleBtn.Parent = toggleGui

toggleBtn.MouseButton1Click:Connect(function()
    menuVisible = not menuVisible
    if menuVisible then Window:Open() else Window:Close() end
end)

WindUI:Notify({ Title = "OP Final Remake", Content = "Bản Remake Khóa Mục Tiêu Đã Sẵn Sàng!", Duration = 4 })
