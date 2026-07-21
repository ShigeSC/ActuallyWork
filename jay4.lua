--!strict
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ShigeSC/ActuallyWork/refs/heads/main/gui2.lua"))()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Networking = require(ReplicatedStorage.SharedModules.Networking)

-- ==================== THEME SETUP ====================
library.theme.font = Enum.Font.GothamBold
library.theme.titlesize = 16
library.theme.fontsize = 13
library.theme.cursor = false
library.theme.topheight = 36

UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
UserInputService.MouseIconEnabled = true

local Window = library:CreateWindow("SHOP by @boo10001", Vector2.new(400, 320), Enum.KeyCode.RightShift)

-- Force mouse visibility
task.spawn(function()
	while true do
		UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
		UserInputService.MouseIconEnabled = true
		task.wait(1)
	end
end)

-- ==================== CONSTANTS ====================
local CONFIG_FOLDER = "BOOSCRIPT"
local SET_FPS_CAP = setfpscap or function() end
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local SEED_LIST = {
	"Acorn", "Apple", "Bamboo", "Banana", "Blueberry", "Cactus", "Carrot", "Cherry",
	"Coconut", "Corn", "Dragon Fruit", "Dragon's Breath", "Fire Fern", "Grape",
	"Green Bean", "Hypno Bloom", "Mango", "Moon Bloom", "Mushroom", "Padding",
	"Pineapple", "Poison Apple", "Pomegranate", "Pudding", "Rocket Pop", "Star Fruit",
	"Strawberry", "Sun Bloom", "Sunflower", "Tomato", "Tulip", "Venom Spitter",
	"Venus Fly Trap"
}

local GEAR_LIST = {
	"Common Watering Can", "Common Sprinkler", "Sign", "Megaphone",
	"Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler",
	"Trowel", "Speed Mushroom", "Jump Mushroom", "Gnome",
	"Shrink Mushroom", "Supersize Mushroom", "Wheelbarrow", "Strawberry Sniper",
	"Invisibility Mushroom", "Teleporter", "Legendary Pet Teleporter",
	"Mythic Pet Teleporter", "Super Pet Teleporter", "Super Watering Can",
	"Basic Pot", "Flashbang", "Player Magnet"
}

local CRATE_LIST = {
	"Arch Crate", "Bear Trap Crate", "Bench Crate", "Boombox Crate",
	"Bridge Crate", "Conveyor Crate", "Fence Crate", "Fourth Of July Crate",
	"Ladder Crate", "Light Crate", "Owner Door Crate", "Picture Frame Crate",
	"Roleplay Crate", "Seesaw Crate", "Sign Crate", "Spring Crate",
	"Teleporter Pad Crate", "Weather Machine Crate", "Wood Wall Crate"
}

-- ==================== STATE ====================
local state = {
	selectedSeeds = {} :: {string},
	selectedGears = {} :: {string},
	selectedCrates = {} :: {string},
	autoBuySelectedSeeds = false,
	autoBuyAllSeeds = false,
	autoBuySelectedGears = false,
	autoBuyAllGears = false,
	autoBuySelectedCrates = false,
	autoBuyAllCrates = false,
	fpsCap = 15,
	cleanupEnabled = false,
	currentConfigName = "default",
	guiVisible = true,
}

-- UI References
local uiRefs: {
	seedDropdown: any?,
	gearDropdown: any?,
	crateDropdown: any?,
	seedSelectedToggle: any?,
	seedAllToggle: any?,
	gearSelectedToggle: any?,
	gearAllToggle: any?,
	crateSelectedToggle: any?,
	crateAllToggle: any?,
	configNameTextbox: any?,
	configDropdown: any?,
} = {}

-- ==================== UTILITY ====================
local function log(tag: string, message: string)
	print(string.format("[%s] %s", tag, message))
end

local function safePurchase(purchaseFn: () -> ())
	local success, err = pcall(purchaseFn)
	if not success then
		log("ERROR", tostring(err))
	end
end

-- ==================== ANTI AFK ====================
local function setupAntiAFK()
	local function disableIdleConnections()
		pcall(function()
			for _, connection in ipairs(getconnections(player.Idled)) do
				connection:Disable()
			end
		end)
	end

	disableIdleConnections()

	task.spawn(function()
		while true do
			task.wait(25)
			disableIdleConnections()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(40)
			
			local char = player.Character
			if not char then continue end
			
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then continue end

			safePurchase(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(0.12)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
				
				hum:Move(Vector3.new(0, 0, 0.1))
				hum.Jump = true
				task.wait(0.4)
				hum.Jump = false
			end)
		end
	end)
end

setupAntiAFK()

-- ==================== CONFIG SYSTEM ====================
local ConfigManager = {
	Folder = CONFIG_FOLDER,
	CurrentConfig = nil,
}

function ConfigManager:EnsureFolder()
	if not isfolder(self.Folder) then
		makefolder(self.Folder)
	end
end

function ConfigManager:GetList(): {string}
	local list = {}
	if not isfolder(self.Folder) then return list end
	
	for _, file in ipairs(listfiles(self.Folder)) do
		local name = file:match("([^/\\]+)%.json$")
		if name then
			table.insert(list, name)
		end
	end
	return list
end

function ConfigManager:Serialize(): string
	local data = {
		version = 1,
		selectedSeeds = state.selectedSeeds,
		selectedGears = state.selectedGears,
		selectedCrates = state.selectedCrates,
		autoBuySelectedSeeds = state.autoBuySelectedSeeds,
		autoBuyAllSeeds = state.autoBuyAllSeeds,
		autoBuySelectedGears = state.autoBuySelectedGears,
		autoBuyAllGears = state.autoBuyAllGears,
		autoBuySelectedCrates = state.autoBuySelectedCrates,
		autoBuyAllCrates = state.autoBuyAllCrates,
		fpsCap = state.fpsCap,
		cleanupEnabled = state.cleanupEnabled,
	}
	return HttpService:JSONEncode(data)
end

function ConfigManager:Deserialize(json: string): boolean
	local success, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	
	if not success or typeof(data) ~= "table" then
		return false
	end

	if typeof(data.selectedSeeds) == "table" then
		state.selectedSeeds = data.selectedSeeds
	end
	if typeof(data.selectedGears) == "table" then
		state.selectedGears = data.selectedGears
	end
	if typeof(data.selectedCrates) == "table" then
		state.selectedCrates = data.selectedCrates
	end
	
	state.autoBuySelectedSeeds = data.autoBuySelectedSeeds == true
	state.autoBuyAllSeeds = data.autoBuyAllSeeds == true
	state.autoBuySelectedGears = data.autoBuySelectedGears == true
	state.autoBuyAllGears = data.autoBuyAllGears == true
	state.autoBuySelectedCrates = data.autoBuySelectedCrates == true
	state.autoBuyAllCrates = data.autoBuyAllCrates == true
	state.fpsCap = typeof(data.fpsCap) == "number" and data.fpsCap or 15
	state.cleanupEnabled = data.cleanupEnabled == true

	return true
end

function ConfigManager:Save(name: string?): boolean
	if not name or name == "" then
		log("CONFIG", "Please enter a config name")
		return false
	end

	self:EnsureFolder()
	
	local json = self:Serialize()
	local success, err = pcall(function()
		writefile(self.Folder .. "/" .. name .. ".json", json)
		writefile(self.Folder .. "/last.txt", name)
	end)
	
	if success then
		self.CurrentConfig = name
		log("CONFIG", "Saved: " .. name)
		return true
	else
		log("CONFIG", "Save failed: " .. tostring(err))
		return false
	end
end

function ConfigManager:Load(name: string?): boolean
	if not name or name == "" then
		log("CONFIG", "No config name provided")
		return false
	end

	local path = self.Folder .. "/" .. name .. ".json"
	if not isfile(path) then
		log("CONFIG", "Config not found: " .. name)
		return false
	end

	local success, content = pcall(function()
		return readfile(path)
	end)

	if not success then
		log("CONFIG", "Read failed: " .. tostring(content))
		return false
	end

	if not self:Deserialize(content) then
		log("CONFIG", "Parse failed for: " .. name)
		return false
	end

	self.CurrentConfig = name
	log("CONFIG", "Loaded: " .. name)
	return true
end

function ConfigManager:Delete(name: string?): boolean
	if not name or name == "" then
		return false
	end

	local path = self.Folder .. "/" .. name .. ".json"
	if not isfile(path) then
		return false
	end

	local success = pcall(function()
		delfile(path)
	end)

	if success then
		if self.CurrentConfig == name then
			self.CurrentConfig = nil
		end
		log("CONFIG", "Deleted: " .. name)
		return true
	end
	return false
end

-- ==================== UI UPDATER ====================
local function UpdateUIFromState()
	if uiRefs.seedSelectedToggle and uiRefs.seedSelectedToggle.Set then
		uiRefs.seedSelectedToggle:Set(state.autoBuySelectedSeeds)
	end
	if uiRefs.seedAllToggle and uiRefs.seedAllToggle.Set then
		uiRefs.seedAllToggle:Set(state.autoBuyAllSeeds)
	end
	if uiRefs.gearSelectedToggle and uiRefs.gearSelectedToggle.Set then
		uiRefs.gearSelectedToggle:Set(state.autoBuySelectedGears)
	end
	if uiRefs.gearAllToggle and uiRefs.gearAllToggle.Set then
		uiRefs.gearAllToggle:Set(state.autoBuyAllGears)
	end
	if uiRefs.crateSelectedToggle and uiRefs.crateSelectedToggle.Set then
		uiRefs.crateSelectedToggle:Set(state.autoBuySelectedCrates)
	end
	if uiRefs.crateAllToggle and uiRefs.crateAllToggle.Set then
		uiRefs.crateAllToggle:Set(state.autoBuyAllCrates)
	end

	pcall(function()
		if uiRefs.seedDropdown and #state.selectedSeeds > 0 then
			uiRefs.seedDropdown:Set(state.selectedSeeds)
		end
	end)
	pcall(function()
		if uiRefs.gearDropdown and #state.selectedGears > 0 then
			uiRefs.gearDropdown:Set(state.selectedGears)
		end
	end)
	pcall(function()
		if uiRefs.crateDropdown and #state.selectedCrates > 0 then
			uiRefs.crateDropdown:Set(state.selectedCrates)
		end
	end)

	if uiRefs.configNameTextbox and uiRefs.configNameTextbox.Set then
		uiRefs.configNameTextbox:Set(ConfigManager.CurrentConfig or "default")
	end
end

local function RefreshConfigDropdown()
	if not uiRefs.configDropdown then return end
	
	local configs = ConfigManager:GetList()
	
	pcall(function()
		for _, item in ipairs(configs) do
			uiRefs.configDropdown:Remove(item)
		end
	end)
	
	for _, name in ipairs(configs) do
		pcall(function()
			uiRefs.configDropdown:Add(name)
		end)
	end
end

local function ApplyLowCPU()
	SET_FPS_CAP(state.fpsCap)
	
	if not state.cleanupEnabled then return end
	
	local descendants = workspace:GetDescendants()
	local toDestroy = {}
	
	for _, v in ipairs(descendants) do
		local nameLower = v.Name:lower()
		if nameLower:find("plant") or nameLower:find("tree") or nameLower:find("flower") or
		   nameLower:find("bush") or nameLower:find("crop") or nameLower:find("grass") or
		   nameLower:find("vine") or nameLower:find("mushroom") or nameLower:find("visual") then
			table.insert(toDestroy, v)
		end
	end
	
	for _, v in ipairs(toDestroy) do
		pcall(function() v:Destroy() end)
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

	Lighting.GlobalShadows = false
	Lighting.Brightness = 2
	Lighting.ClockTime = 12
	Lighting.FogEnd = 100000
	
	log("Low CPU", string.format("Applied FPS: %d | Cleanup: %s", state.fpsCap, tostring(state.cleanupEnabled)))
end

-- ==================== MOBILE TOGGLE BUTTON SYSTEM ====================
local MobileToggle = {
	Gui = nil :: ScreenGui?,
	Button = nil :: TextButton?,
	Connections = {} :: {RBXScriptConnection},
	IsDragging = false,
	DragStart = nil :: Vector3?,
	StartPos = nil :: UDim2?,
}

function MobileToggle:Cleanup()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
	self.Button = nil
end

function MobileToggle:Create()
	self:Cleanup()
	
	if not Window or not Window.Frame then return end

	-- Size based on device (larger for mobile)
	local buttonSize = IS_MOBILE and 55 or 45
	
	self.Gui = Instance.new("ScreenGui")
	self.Gui.Name = "MobileToggle"
	self.Gui.ResetOnSpawn = false
	self.Gui.DisplayOrder = 9999
	self.Gui.Parent = CoreGui

	self.Button = Instance.new("TextButton")
	self.Button.Name = "ToggleButton"
	self.Button.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	-- Position at bottom right for mobile, left side for desktop
	self.Button.Position = IS_MOBILE and UDim2.new(1, -buttonSize - 10, 1, -buttonSize - 10) or UDim2.new(0, 10, 0.5, -22)
	self.Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	self.Button.Text = "S"
	self.Button.TextColor3 = Color3.new(1, 1, 1)
	self.Button.Font = Enum.Font.GothamBold
	self.Button.TextSize = IS_MOBILE and 22 or 20
	self.Button.Parent = self.Gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = self.Button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 170, 0)
	stroke.Thickness = IS_MOBILE and 3 or 2
	stroke.Parent = self.Button

	-- Add shadow for better visibility
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 2)
	shadow.Size = UDim2.new(1, 4, 1, 4)
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = -1
	shadow.Parent = self.Button

	-- Touch/Mouse handling
	table.insert(self.Connections, self.Button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = false
			self.DragStart = input.Position
			self.StartPos = self.Button.Position
		end
	end))

	table.insert(self.Connections, self.Button.InputChanged:Connect(function(input)
		if not self.DragStart then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and 
		   input.UserInputType ~= Enum.UserInputType.Touch then return end
		   
		local delta = (input.Position - self.DragStart)
		if delta.Magnitude > 5 then
			self.IsDragging = true
			self.Button.Position = UDim2.new(
				self.StartPos.X.Scale,
				self.StartPos.X.Offset + delta.X,
				self.StartPos.Y.Scale,
				self.StartPos.Y.Offset + delta.Y
			)
		end
	end))

	table.insert(self.Connections, self.Button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			
			if not self.IsDragging then
				-- Was a tap, toggle GUI
				if Window and Window.Frame then
					state.guiVisible = not state.guiVisible
					Window.Frame.Visible = state.guiVisible
					
					-- Update button text
					self.Button.Text = state.guiVisible and "S" or "•"
					self.Button.BackgroundColor3 = state.guiVisible and Color3.fromRGB(35, 35, 40) or Color3.fromRGB(0, 120, 0)
				end
			end
			
			self.IsDragging = false
			self.DragStart = nil
		end
	end))

	-- Hover effects
	table.insert(self.Connections, self.Button.MouseEnter:Connect(function()
		TweenService:Create(self.Button, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		}):Play()
	end))

	table.insert(self.Connections, self.Button.MouseLeave:Connect(function()
		local baseColor = state.guiVisible and Color3.fromRGB(35, 35, 40) or Color3.fromRGB(0, 120, 0)
		TweenService:Create(self.Button, TweenInfo.new(0.1), {
			BackgroundColor3 = baseColor
		}):Play()
	end))
end

function MobileToggle:UpdateState()
	if not self.Button then return end
	self.Button.Text = state.guiVisible and "S" or "•"
	self.Button.BackgroundColor3 = state.guiVisible and Color3.fromRGB(35, 35, 40) or Color3.fromRGB(0, 120, 0)
end

-- ==================== BUILD UI ====================

-- Seeds Tab
local SeedsTab = Window:CreateTab("Seeds")
local SeedsSector = SeedsTab:CreateSector("Seeds", "left")

uiRefs.seedDropdown = SeedsSector:AddDropdown("Select Seed", SEED_LIST, "", true, function(value)
	state.selectedSeeds = type(value) == "table" and value or {value}
end)

uiRefs.seedSelectedToggle = SeedsSector:AddToggle("Auto Buy Selected", false, function(value)
	state.autoBuySelectedSeeds = value
end)

uiRefs.seedAllToggle = SeedsSector:AddToggle("Auto Buy All Seeds", false, function(value)
	state.autoBuyAllSeeds = value
end)

-- Gear Tab
local GearTab = Window:CreateTab("Gear")
local GearSector = GearTab:CreateSector("Gear", "left")

uiRefs.gearDropdown = GearSector:AddDropdown("Select Gear", GEAR_LIST, "", true, function(value)
	state.selectedGears = type(value) == "table" and value or {value}
end)

uiRefs.gearSelectedToggle = GearSector:AddToggle("Auto Buy Selected", false, function(value)
	state.autoBuySelectedGears = value
end)

uiRefs.gearAllToggle = GearSector:AddToggle("Auto Buy All Gears", false, function(value)
	state.autoBuyAllGears = value
end)

-- Crate Tab
local CrateTab = Window:CreateTab("Crates")
local CrateSector = CrateTab:CreateSector("Crates", "left")

uiRefs.crateDropdown = CrateSector:AddDropdown("Select Crate", CRATE_LIST, "", true, function(value)
	state.selectedCrates = type(value) == "table" and value or {value}
end)

uiRefs.crateSelectedToggle = CrateSector:AddToggle("Auto Buy Selected", false, function(value)
	state.autoBuySelectedCrates = value
end)

uiRefs.crateAllToggle = CrateSector:AddToggle("Auto Buy All Crates", false, function(value)
	state.autoBuyAllCrates = value
end)

-- Performance Tab
local PerfTab = Window:CreateTab("Performance")
local PerfSector = PerfTab:CreateSector("Low CPU", "left")

PerfSector:AddButton("Cleanup + 15 FPS", function()
	state.cleanupEnabled = true
	state.fpsCap = 15
	ApplyLowCPU()
end)

PerfSector:AddButton("FPS Cap 30", function()
	state.fpsCap = 30
	SET_FPS_CAP(30)
end)

PerfSector:AddButton("FPS Cap 60", function()
	state.fpsCap = 60
	SET_FPS_CAP(60)
end)

PerfSector:AddButton("Remove FPS Cap", function()
	state.fpsCap = 0
	SET_FPS_CAP(0)
end)

-- Config Tab
local ConfigTab = Window:CreateTab("Configs")
local ConfigSector = ConfigTab:CreateSector("Config Manager", "left")

uiRefs.configNameTextbox = ConfigSector:AddTextbox("Config Name", "default", function(value)
	state.currentConfigName = value
end)

local initialConfigs = ConfigManager:GetList()
local defaultConfig = initialConfigs[1] or "default"

uiRefs.configDropdown = ConfigSector:AddDropdown("Choose Config", initialConfigs, defaultConfig, false, function(selectedConfig)
	if selectedConfig and selectedConfig ~= "" then
		state.currentConfigName = selectedConfig
		
		if ConfigManager:Load(selectedConfig) then
			UpdateUIFromState()
			ApplyLowCPU()
		end
		
		if uiRefs.configNameTextbox and uiRefs.configNameTextbox.Set then
			uiRefs.configNameTextbox:Set(selectedConfig)
		end
	end
end)

ConfigSector:AddButton("Save Config", function()
	local name = state.currentConfigName
	if not name or name == "" then
		log("CONFIG", "Please enter a config name")
		return
	end
	
	if ConfigManager:Save(name) then
		task.delay(0.1, RefreshConfigDropdown)
	end
end)

ConfigSector:AddButton("Load Config", function()
	local name = state.currentConfigName
	if ConfigManager:Load(name) then
		UpdateUIFromState()
		ApplyLowCPU()
	end
end)

ConfigSector:AddButton("Delete Config", function()
	local name = state.currentConfigName
	if not name or name == "" then return end
	
	if ConfigManager:Delete(name) then
		RefreshConfigDropdown()
		if uiRefs.configNameTextbox and uiRefs.configNameTextbox.Set then
			uiRefs.configNameTextbox:Set("")
		end
	end
end)

ConfigSector:AddButton("Refresh List", function()
	RefreshConfigDropdown()
end)

-- Settings Tab with Mobile Toggle
local SettingsTab = Window:CreateTab("Settings")
local SettingsSector = SettingsTab:CreateSector("GUI Controls", "left")

-- Hide/Show buttons that work with the toggle system
SettingsSector:AddButton("Hide GUI", function()
	if Window and Window.Frame then
		state.guiVisible = false
		Window.Frame.Visible = false
		MobileToggle:Create()
		MobileToggle:UpdateState()
	end
end)

SettingsSector:AddButton("Show GUI", function()
	if Window and Window.Frame then
		state.guiVisible = true
		Window.Frame.Visible = true
		MobileToggle:UpdateState()
	end
end)

SettingsSector:AddButton("Destroy GUI", function()
	if getgenv().uilib then
		getgenv().uilib:Destroy()
	end
	MobileToggle:Cleanup()
end)

SettingsSector:AddLabel(IS_MOBILE and "Tap circle to toggle GUI" or "Press N to toggle GUI")

-- Keyboard toggle (desktop only)
if not IS_MOBILE then
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.N then
			if Window and Window.Frame then
				state.guiVisible = not state.guiVisible
				Window.Frame.Visible = state.guiVisible
				
				if not state.guiVisible then
					MobileToggle:Create()
				else
					MobileToggle:Cleanup()
				end
			end
		end
	end)
end

-- Always create toggle button on mobile at start
if IS_MOBILE then
	-- Start with button visible since user might want to hide immediately
	MobileToggle:Create()
end

-- ==================== MUTE SYSTEM ====================
task.spawn(function()
	while true do
		local anyAutoBuy = state.autoBuySelectedSeeds or state.autoBuyAllSeeds or 
						   state.autoBuySelectedGears or state.autoBuyAllGears or 
						   state.autoBuySelectedCrates or state.autoBuyAllCrates

		if anyAutoBuy then
			SoundService.Volume = 0
			for _, s in ipairs(SoundService:GetDescendants()) do
				if s:IsA("Sound") then
					s.Volume = 0
					s.Playing = false
				end
			end
		else
			SoundService.Volume = 1
		end
		task.wait(0.5)
	end
end)

-- ==================== AUTO BUY LOOP ====================
task.spawn(function()
	while true do
		if state.autoBuySelectedSeeds and #state.selectedSeeds > 0 then
			for _, seed in ipairs(state.selectedSeeds) do
				safePurchase(function()
					Networking.SeedShop.PurchaseSeed:Fire(seed)
				end)
			end
		end

		if state.autoBuyAllSeeds then
			for _, seed in ipairs(SEED_LIST) do
				safePurchase(function()
					Networking.SeedShop.PurchaseSeed:Fire(seed)
				end)
			end
		end

		if state.autoBuySelectedGears and #state.selectedGears > 0 then
			for _, gear in ipairs(state.selectedGears) do
				safePurchase(function()
					Networking.GearShop.PurchaseGear:Fire(gear)
				end)
			end
		end

		if state.autoBuyAllGears then
			for _, gear in ipairs(GEAR_LIST) do
				safePurchase(function()
					Networking.GearShop.PurchaseGear:Fire(gear)
				end)
			end
		end

		if state.autoBuySelectedCrates and #state.selectedCrates > 0 then
			for _, crate in ipairs(state.selectedCrates) do
				safePurchase(function()
					Networking.CrateShop.PurchaseCrate:Fire(crate)
				end)
			end
		end

		if state.autoBuyAllCrates then
			for _, crate in ipairs(CRATE_LIST) do
				safePurchase(function()
					Networking.CrateShop.PurchaseCrate:Fire(crate)
				end)
			end
		end

		task.wait(0.3)
	end
end)

-- ==================== AUTO-LOAD ====================
ConfigManager:EnsureFolder()

task.delay(1, function()
	if isfile(CONFIG_FOLDER .. "/last.txt") then
		local lastConfig = readfile(CONFIG_FOLDER .. "/last.txt")
		if lastConfig and lastConfig ~= "" then
			if ConfigManager:Load(lastConfig) then
				UpdateUIFromState()
				ApplyLowCPU()
				pcall(function()
					if uiRefs.configDropdown and uiRefs.configDropdown.Set then
						uiRefs.configDropdown:Set(lastConfig)
					end
				end)
			end
		end
	end
end)

log("LOADER", "SHOP loaded" .. (IS_MOBILE and " (Mobile Mode)" or " (Desktop Mode)"))
