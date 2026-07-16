local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ShigeSC/ActuallyWork/refs/heads/main/gui.lua"))()

-- Better title style + smaller for Android
library.theme.font = Enum.Font.GothamBold
library.theme.titlesize = 16
library.theme.fontsize = 13
library.theme.cursor = false
library.theme.topheight = 36

game:GetService("UserInputService").OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
game:GetService("UserInputService").MouseIconEnabled = true

-- Much smaller height to remove empty space
local Window = library:CreateWindow("SHOP by @boo10001", Vector2.new(380, 320), Enum.KeyCode.RightShift)

-- Force mouse
task.spawn(function()
    while true do
        game:GetService("UserInputService").OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
        game:GetService("UserInputService").MouseIconEnabled = true
        task.wait(0.1)
    end
end)

-- ==================== CONFIG SYSTEM ====================
local CONFIG_FOLDER = "BOOSCRIPT"
local HttpService = game:GetService("HttpService")

if not isfolder(CONFIG_FOLDER) then
    makefolder(CONFIG_FOLDER)
    print("[CONFIG] Created folder: BOOSCRIPT")
end

local selectedSeeds = {}
local selectedGears = {}
local selectedCrates = {}
local autoBuySelectedSeeds = false
local autoBuyAllSeeds = false
local autoBuySelectedGears = false
local autoBuyAllGears = false
local autoBuySelectedCrates = false
local autoBuyAllCrates = false
local currentConfigName = "default"

local fpsCap = 15
local cleanupEnabled = false

local seedDropdown, gearDropdown, crateDropdown
local seedSelectedToggle, seedAllToggle, gearSelectedToggle, gearAllToggle
local crateSelectedToggle, crateAllToggle

local function getConfigList()
    local list = {}
    for _, file in pairs(listfiles(CONFIG_FOLDER)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(list, name)
        end
    end
    return list
end

local function saveConfig(name)
    if not name or name == "" then
        print("[CONFIG] Please type a name first!")
        return
    end

    local data = {
        selectedSeeds = selectedSeeds,
        selectedGears = selectedGears,
        selectedCrates = selectedCrates,
        autoBuySelectedSeeds = autoBuySelectedSeeds,
        autoBuyAllSeeds = autoBuyAllSeeds,
        autoBuySelectedGears = autoBuySelectedGears,
        autoBuyAllGears = autoBuyAllGears,
        autoBuySelectedCrates = autoBuySelectedCrates,
        autoBuyAllCrates = autoBuyAllCrates,
        fpsCap = fpsCap,
        cleanupEnabled = cleanupEnabled
    }

    writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    writefile(CONFIG_FOLDER .. "/last.txt", name)
    print("[CONFIG] Saved → BOOSCRIPT/" .. name .. ".json")
end

local function applyConfigToUI()
    if seedDropdown and seedDropdown.Set then pcall(function() seedDropdown:Set(selectedSeeds) end) end
    if gearDropdown and gearDropdown.Set then pcall(function() gearDropdown:Set(selectedGears) end) end
    if crateDropdown and crateDropdown.Set then pcall(function() crateDropdown:Set(selectedCrates) end) end

    if seedSelectedToggle and seedSelectedToggle.Set then pcall(function() seedSelectedToggle:Set(autoBuySelectedSeeds) end) end
    if seedAllToggle and seedAllToggle.Set then pcall(function() seedAllToggle:Set(autoBuyAllSeeds) end) end
    if gearSelectedToggle and gearSelectedToggle.Set then pcall(function() gearSelectedToggle:Set(autoBuySelectedGears) end) end
    if gearAllToggle and gearAllToggle.Set then pcall(function() gearAllToggle:Set(autoBuyAllGears) end) end
    if crateSelectedToggle and crateSelectedToggle.Set then pcall(function() crateSelectedToggle:Set(autoBuySelectedCrates) end) end
    if crateAllToggle and crateAllToggle.Set then pcall(function() crateAllToggle:Set(autoBuyAllCrates) end) end
end

local function applyLowCPU()
    if cleanupEnabled then
        local workspace = game:GetService("Workspace")
        local lighting = game:GetService("Lighting")

        for _, v in ipairs(workspace:GetDescendants()) do
            local nameLower = v.Name:lower()
            if nameLower:find("plant") or nameLower:find("tree") or nameLower:find("flower") or
               nameLower:find("bush") or nameLower:find("crop") or nameLower:find("grass") or
               nameLower:find("vine") or nameLower:find("mushroom") or nameLower:find("visual") then
                pcall(function() v:Destroy() end)
            end
        end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Color = Color3.fromRGB(180, 180, 200)
                v.Reflectance = 0
                v.Transparency = 0.1
            elseif v:IsA("Texture") or v:IsA("Decal") or v:IsA("ParticleEmitter") or v:IsA("Trail") then
                pcall(function() v:Destroy() end)
            end
        end

        lighting.GlobalShadows = false
        lighting.Brightness = 2
        lighting.ClockTime = 12
        lighting.FogEnd = 100000
    end

    local setfpscap = setfpscap or function() end
    setfpscap(fpsCap)
    print("[Low CPU] Applied FPS Cap:", fpsCap, " | Cleanup:", cleanupEnabled)
end

local function loadConfig(name)
    if not name or name == "" then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then
        print("[CONFIG] Not found: " .. name)
        return false
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if success and data then
        selectedSeeds = data.selectedSeeds or {}
        selectedGears = data.selectedGears or {}
        selectedCrates = data.selectedCrates or {}
        autoBuySelectedSeeds = data.autoBuySelectedSeeds or false
        autoBuyAllSeeds = data.autoBuyAllSeeds or false
        autoBuySelectedGears = data.autoBuySelectedGears or false
        autoBuyAllGears = data.autoBuyAllGears or false
        autoBuySelectedCrates = data.autoBuySelectedCrates or false
        autoBuyAllCrates = data.autoBuyAllCrates or false
        fpsCap = data.fpsCap or 15
        cleanupEnabled = data.cleanupEnabled or false
        currentConfigName = name

        applyConfigToUI()
        applyLowCPU()

        print("[CONFIG] Loaded and applied: " .. name)
        return true
    end
    return false
end

if isfile(CONFIG_FOLDER .. "/last.txt") then
    loadConfig(readfile(CONFIG_FOLDER .. "/last.txt"))
end

-- ==================== SEEDS TAB ====================
local SeedsTab = Window:CreateTab("Seeds")
local SeedsSector = SeedsTab:CreateSector("Seeds", "left")

seedDropdown = SeedsSector:AddDropdown("Select Seed", {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo", "Corn"
}, "", true, function(Value)
    selectedSeeds = type(Value) == "table" and Value or {Value}
end)

seedSelectedToggle = SeedsSector:AddToggle("Auto Buy Selected", autoBuySelectedSeeds, function(Value)
    autoBuySelectedSeeds = Value
end)

seedAllToggle = SeedsSector:AddToggle("Auto Buy All Seeds", autoBuyAllSeeds, function(Value)
    autoBuyAllSeeds = Value
end)

-- ==================== GEAR TAB ====================
local GearTab = Window:CreateTab("Gear")
local GearSector = GearTab:CreateSector("Gear", "left")

gearDropdown = GearSector:AddDropdown("Select Gear", {
    "Common Watering Can", "Common Sprinkler", "Sign", "Megaphone",
    "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler",
    "Trowel", "Speed Mushroom", "Jump Mushroom", "Gnome",
    "Shrink Mushroom", "Supersize Mushroom", "Wheelbarrow", "Strawberry Sniper",
    "Invisibility Mushroom", "Teleporter", "Legendary Pet Teleporter",
    "Mythic Pet Teleporter", "Super Pet Teleporter", "Super Watering Can",
    "Basic Pot", "Flashbang", "Player Magnet"
}, "", true, function(Value)
    selectedGears = type(Value) == "table" and Value or {Value}
end)

gearSelectedToggle = GearSector:AddToggle("Auto Buy Selected", autoBuySelectedGears, function(Value)
    autoBuySelectedGears = Value
end)

gearAllToggle = GearSector:AddToggle("Auto Buy All Gears", autoBuyAllGears, function(Value)
    autoBuyAllGears = Value
end)

-- ==================== CRATE TAB ====================
local CrateTab = Window:CreateTab("Crate")
local CrateSector = CrateTab:CreateSector("Crates", "left")

crateDropdown = CrateSector:AddDropdown("Select Crate", {
    "Arch Crate", "Bear Trap Crate", "Bench Crate", "Boombox Crate",
    "Bridge Crate", "Conveyor Crate", "Fence Crate", "Fourth Of July Crate",
    "Ladder Crate", "Light Crate", "Owner Door Crate", "Picture Frame Crate",
    "Roleplay Crate", "Seesaw Crate", "Sign Crate", "Spring Crate",
    "Teleporter Pad Crate", "Weather Machine Crate", "Wood Wall Crate"
}, "", true, function(Value)
    selectedCrates = type(Value) == "table" and Value or {Value}
end)

crateSelectedToggle = CrateSector:AddToggle("Auto Buy Selected", autoBuySelectedCrates, function(Value)
    autoBuySelectedCrates = Value
end)

crateAllToggle = CrateSector:AddToggle("Auto Buy All Crates", autoBuyAllCrates, function(Value)
    autoBuyAllCrates = Value
end)

-- ==================== LOW CPU TAB ====================
local CleanupTab = Window:CreateTab("Low CPU")
local CleanupSector = CleanupTab:CreateSector("Performance", "left")

CleanupSector:AddButton("Cleanup + 15 FPS", function()
    cleanupEnabled = true
    fpsCap = 15
    applyLowCPU()
    print("Cleanup + Smooth + 15 FPS activated")
end)

CleanupSector:AddButton("FPS Cap 30", function()
    fpsCap = 30
    local setfpscap = setfpscap or function() end
    setfpscap(30)
    print("FPS capped at 30")
end)

CleanupSector:AddButton("FPS Cap 60", function()
    fpsCap = 60
    local setfpscap = setfpscap or function() end
    setfpscap(60)
    print("FPS capped at 60")
end)

CleanupSector:AddButton("Remove FPS Cap", function()
    fpsCap = 0
    local setfpscap = setfpscap or function() end
    setfpscap(0)
    print("FPS cap removed")
end)

-- ==================== CONFIGS TAB ====================
local ConfigTab = Window:CreateTab("Configs")
local ConfigSector = ConfigTab:CreateSector("Config Manager", "left")

ConfigSector:AddTextbox("Config Name", currentConfigName, function(Value)
    currentConfigName = Value
end)

local configDropdown = ConfigSector:AddDropdown("Choose Config", getConfigList(), currentConfigName, false, function(Value)
    if Value and Value ~= "" then
        loadConfig(Value)
        writefile(CONFIG_FOLDER .. "/last.txt", Value)
    end
end)

ConfigSector:AddButton("Save Config", function()
    saveConfig(currentConfigName)
    for _, name in pairs(getConfigList()) do
        pcall(function() configDropdown:Add(name) end)
    end
end)

ConfigSector:AddButton("Load Config", function()
    loadConfig(currentConfigName)
end)

ConfigSector:AddButton("Delete Config", function()
    if currentConfigName and currentConfigName ~= "" then
        local path = CONFIG_FOLDER .. "/" .. currentConfigName .. ".json"
        if isfile(path) then
            delfile(path)
            print("[CONFIG] Deleted: " .. currentConfigName)
        end
    end
end)

-- ==================== CONTROLS ====================
local ControlSector = SeedsTab:CreateSector("Controls", "right")

ControlSector:AddButton("X Destroy", function()
    if getgenv().uilib then getgenv().uilib:Destroy() end
    if Window and Window.Main then Window.Main:Destroy() end
    if restoreCircle then restoreCircle:Destroy() end
    print("GUI destroyed")
end)

-- ==================== MOVABLE CIRCLE (FIXED) ====================
local restoreCircle = nil
local dragging = false
local dragStart, startPos
local clickTime = 0

local function createRestoreCircle()
    if restoreCircle then restoreCircle:Destroy() end

    restoreCircle = Instance.new("ScreenGui")
    restoreCircle.Name = "RestoreCircle"
    restoreCircle.ResetOnSpawn = false
    restoreCircle.Parent = game:GetService("CoreGui")

    local circle = Instance.new("TextButton")
    circle.Size = UDim2.new(0, 50, 0, 50)
    circle.Position = UDim2.new(0, 15, 0.5, -25)
    circle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    circle.Text = "S"
    circle.TextColor3 = Color3.new(1,1,1)
    circle.Font = Enum.Font.GothamBold
    circle.TextSize = 18
    circle.Parent = restoreCircle

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 170, 0)
    stroke.Thickness = 2
    stroke.Parent = circle

    circle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = circle.Position
            clickTime = tick()
        end
    end)

    circle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false

            if tick() - clickTime < 0.2 then
                if Window and Window.Frame then
                    Window.Frame.Visible = true
                end
                if restoreCircle then
                    restoreCircle:Destroy()
                    restoreCircle = nil
                end
            end
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                circle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

local function hideGUI()
    if Window and Window.Frame then
        Window.Frame.Visible = false
        createRestoreCircle()
    end
end

local function showGUI()
    if Window and Window.Frame then
        Window.Frame.Visible = true
    end
    if restoreCircle then
        restoreCircle:Destroy()
        restoreCircle = nil
    end
end

ControlSector:AddButton("- Hide", function()
    hideGUI()
end)

ControlSector:AddButton("Show", function()
    showGUI()
end)

-- Press N to hide/unhide
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.N then
        if Window and Window.Frame then
            if Window.Frame.Visible then
                hideGUI()
            else
                showGUI()
            end
        end
    end
end)

-- ==================== AUTO BUY LOOP ====================
task.spawn(function()
    while true do
        if autoBuySelectedSeeds and #selectedSeeds > 0 then
            for _, seed in ipairs(selectedSeeds) do
                pcall(function()
                    local Networking = require(game.ReplicatedStorage.SharedModules.Networking)
                    Networking.SeedShop.PurchaseSeed:Fire(seed)
                end)
            end
        end

        if autoBuyAllSeeds then
            local allSeeds = {"Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo", "Corn"}
            for _, seed in ipairs(allSeeds) do
                pcall(function()
                    local Networking = require(game.ReplicatedStorage.SharedModules.Networking)
                    Networking.SeedShop.PurchaseSeed:Fire(seed)
                end)
            end
        end

        if autoBuySelectedGears and #selectedGears > 0 then
            for _, gear in ipairs(selectedGears) do
                pcall(function()
                    local Networking = require(game.ReplicatedStorage.SharedModules.Networking)
                    Networking.GearShop.PurchaseGear:Fire(gear)
                end)
            end
        end

        if autoBuyAllGears then
            local allGears = {
                "Common Watering Can", "Common Sprinkler", "Sign", "Megaphone",
                "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler",
                "Trowel", "Speed Mushroom", "Jump Mushroom", "Gnome",
                "Shrink Mushroom", "Supersize Mushroom", "Wheelbarrow", "Strawberry Sniper",
                "Invisibility Mushroom", "Teleporter", "Legendary Pet Teleporter",
                "Mythic Pet Teleporter", "Super Pet Teleporter", "Super Watering Can",
                "Basic Pot", "Flashbang", "Player Magnet"
            }
            for _, gear in ipairs(allGears) do
                pcall(function()
                    local Networking = require(game.ReplicatedStorage.SharedModules.Networking)
                    Networking.GearShop.PurchaseGear:Fire(gear)
                end)
            end
        end

        if autoBuySelectedCrates and #selectedCrates > 0 then
            for _, crate in ipairs(selectedCrates) do
                pcall(function()
                    local Networking = require(game.ReplicatedStorage.SharedModules.Networking)
                    Networking.CrateShop.PurchaseCrate:Fire(crate)
                end)
            end
        end

        if autoBuyAllCrates then
            local allCrates = {
                "Arch Crate", "Bear Trap Crate", "Bench Crate", "Boombox Crate",
                "Bridge Crate", "Conveyor Crate", "Fence Crate", "Fourth Of July Crate",
                "Ladder Crate", "Light Crate", "Owner Door Crate", "Picture Frame Crate",
                "Roleplay Crate", "Seesaw Crate", "Sign Crate", "Spring Crate",
                "Teleporter Pad Crate", "Weather Machine Crate", "Wood Wall Crate"
            }
            for _, crate in ipairs(allCrates) do
                pcall(function()
                    local Networking = require(game.ReplicatedStorage.SharedModules.Networking)
                    Networking.CrateShop.PurchaseCrate:Fire(crate)
                end)
            end
        end

        task.wait(0.3)
    end
end)

print("SHOP by @boo10001 - Height reduced to remove empty space")
