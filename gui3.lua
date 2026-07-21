--!strict
-- Speed Hub X Style GUI Library
-- Modern dark theme with red accents, sidebar nav, accordions, and toggles

local SpeedHubX = {}
SpeedHubX.__index = SpeedHubX

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Theme Configuration
SpeedHubX.Theme = {
    Background = Color3.fromRGB(26, 26, 26),      -- Main dark background
    Sidebar = Color3.fromRGB(30, 30, 30),        -- Sidebar background
    Accent = Color3.fromRGB(255, 68, 68),          -- Red accent
    AccentDark = Color3.fromRGB(200, 50, 50),    -- Darker red
    Text = Color3.fromRGB(255, 255, 255),        -- White text
    TextDark = Color3.fromRGB(180, 180, 180),    -- Gray text
    SectionBg = Color3.fromRGB(45, 40, 40),      -- Section background
    ItemBg = Color3.fromRGB(55, 50, 50),         -- Item background
    ToggleOff = Color3.fromRGB(80, 80, 80),      -- Toggle off state
    ToggleOn = Color3.fromRGB(255, 68, 68),      -- Toggle on state
    Border = Color3.fromRGB(60, 60, 60),         -- Border color
    Font = Enum.Font.GothamBold,
    FontSize = 14,
}

-- Utility Functions
local function tween(instance: Instance, properties: {[string]: any}, duration: number?, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.2, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function createCorner(parent: Instance, radius: number?)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function createStroke(parent: Instance, color: Color3?, thickness: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or SpeedHubX.Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- Initialize GUI
function SpeedHubX:Init(title: string, version: string)
    local self = setmetatable({}, SpeedHubX)
    
    self.Title = title or "Speed Hub X"
    self.Version = version or "1.0.0"
    self.Tabs = {}
    self.ActiveTab = nil
    self.ScreenGui = nil
    self.MainFrame = nil
    self.Sidebar = nil
    self.Content = nil
    self.SearchBox = nil
    
    self:CreateBase()
    return self
end

function SpeedHubX:CreateBase()
    -- ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "SpeedHubX"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.DisplayOrder = 999
    self.ScreenGui.Parent = CoreGui
    
    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "Main"
    self.MainFrame.Size = UDim2.new(0, 700, 0, 450)
    self.MainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
    self.MainFrame.BackgroundColor3 = SpeedHubX.Theme.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Parent = self.ScreenGui
    
    createCorner(self.MainFrame, 8)
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = -1
    shadow.Parent = self.MainFrame
    
    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = SpeedHubX.Theme.Sidebar
    topBar.BorderSizePixel = 0
    topBar.Parent = self.MainFrame
    
    createCorner(topBar, 8)
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 400, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = string.format("%s | Version %s", self.Title, self.Version)
    titleLabel.TextColor3 = SpeedHubX.Theme.Accent
    titleLabel.Font = SpeedHubX.Theme.Font
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -65, 0, 5)
    minimizeBtn.BackgroundColor3 = SpeedHubX.Theme.ItemBg
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = SpeedHubX.Theme.Text
    minimizeBtn.Font = SpeedHubX.Theme.Font
    minimizeBtn.TextSize = 18
    minimizeBtn.Parent = topBar
    
    createCorner(minimizeBtn, 6)
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = SpeedHubX.Theme.Accent
    closeBtn.Text = "X"
    closeBtn.TextColor3 = SpeedHubX.Theme.Text
    closeBtn.Font = SpeedHubX.Theme.Font
    closeBtn.TextSize = 14
    closeBtn.Parent = topBar
    
    createCorner(closeBtn, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)
    
    minimizeBtn.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = false
        self:CreateToggleButton()
    end)
    
    -- Sidebar
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.Size = UDim2.new(0, 180, 1, -40)
    self.Sidebar.Position = UDim2.new(0, 0, 0, 40)
    self.Sidebar.BackgroundColor3 = SpeedHubX.Theme.Sidebar
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.Parent = self.MainFrame
    
    createCorner(self.Sidebar, 8)
    
    -- Search Box
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(1, -20, 0, 30)
    searchFrame.Position = UDim2.new(0, 10, 0, 10)
    searchFrame.BackgroundColor3 = SpeedHubX.Theme.Background
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = self.Sidebar
    
    createCorner(searchFrame, 6)
    
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "Icon"
    searchIcon.Size = UDim2.new(0, 16, 0, 16)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -8)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://3605029578"
    searchIcon.ImageColor3 = SpeedHubX.Theme.TextDark
    searchIcon.Parent = searchFrame
    
    self.SearchBox = Instance.new("TextBox")
    self.SearchBox.Name = "Search"
    self.SearchBox.Size = UDim2.new(1, -35, 1, 0)
    self.SearchBox.Position = UDim2.new(0, 30, 0, 0)
    self.SearchBox.BackgroundTransparency = 1
    self.SearchBox.Text = ""
    self.SearchBox.PlaceholderText = "Search"
    self.SearchBox.TextColor3 = SpeedHubX.Theme.Text
    self.SearchBox.PlaceholderColor3 = SpeedHubX.Theme.TextDark
    self.SearchBox.Font = SpeedHubX.Theme.Font
    self.SearchBox.TextSize = 12
    self.SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    self.SearchBox.Parent = searchFrame
    
    -- Tab Container
    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Name = "Tabs"
    self.TabContainer.Size = UDim2.new(1, -10, 1, -50)
    self.TabContainer.Position = UDim2.new(0, 5, 0, 50)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.ScrollBarThickness = 0
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabContainer.Parent = self.Sidebar
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = self.TabContainer
    
    -- Content Area
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.Size = UDim2.new(1, -190, 1, -50)
    self.Content.Position = UDim2.new(0, 185, 0, 45)
    self.Content.BackgroundTransparency = 1
    self.Content.Parent = self.MainFrame
    
    -- Dragging
    local dragging = false
    local dragStart: Vector3?
    local startPos: UDim2?
    
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Create Toggle Button (when GUI is minimized)
function SpeedHubX:CreateToggleButton()
    if self.ToggleButton then
        self.ToggleButton:Destroy()
    end
    
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "SpeedHubX_Toggle"
    toggleGui.ResetOnSpawn = false
    toggleGui.DisplayOrder = 1000
    toggleGui.Parent = CoreGui
    
    self.ToggleButton = toggleGui
    
    local button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Position = UDim2.new(0, 20, 0.5, -25)
    button.BackgroundColor3 = SpeedHubX.Theme.Accent
    button.Text = "S"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 24
    button.Parent = toggleGui
    
    createCorner(button, 25)
    
    local stroke = createStroke(button, Color3.new(1, 1, 1), 2)
    
    local shadow = Instance.new("ImageLabel")
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 2)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = -1
    shadow.Parent = button
    
    button.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = true
        toggleGui:Destroy()
        self.ToggleButton = nil
    end)
    
    -- Dragging for toggle
    local dragging = false
    local dragStart: Vector3?
    local startPos: UDim2?
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Create Tab
function SpeedHubX:CreateTab(name: string, icon: string)
    local tab = {}
    tab.Name = name
    tab.Icon = icon or "🏠"
    tab.Sections = {}
    tab.Button = nil
    tab.Content = nil
    
    -- Sidebar Button
    local button = Instance.new("TextButton")
    button.Name = name .. "Btn"
    button.Size = UDim2.new(1, -10, 0, 36)
    button.BackgroundColor3 = SpeedHubX.Theme.Sidebar
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = self.TabContainer
    
    createCorner(button, 6)
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 24, 0, 24)
    iconLabel.Position = UDim2.new(0, 10, 0.5, -12)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon or "•"
    iconLabel.TextColor3 = SpeedHubX.Theme.Text
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 16
    iconLabel.Parent = button
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -45, 1, 0)
    nameLabel.Position = UDim2.new(0, 40, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = SpeedHubX.Theme.Text
    nameLabel.Font = SpeedHubX.Theme.Font
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = button
    
    tab.Button = button
    
    -- Content Frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = name .. "Content"
    contentFrame.Size = UDim2.new(1, -10, 1, -10)
    contentFrame.Position = UDim2.new(0, 5, 0, 5)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = SpeedHubX.Theme.Accent
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.Visible = false
    contentFrame.Parent = self.Content
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = contentFrame
    
    tab.Content = contentFrame
    
    -- Click Handler
    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, {BackgroundColor3 = SpeedHubX.Theme.ItemBg})
        end
    end)
    
    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, {BackgroundColor3 = SpeedHubX.Theme.Sidebar})
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Auto-select first tab
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    return tab
end

function SpeedHubX:SelectTab(tab)
    if self.ActiveTab == tab then return end
    
    -- Deselect current
    if self.ActiveTab then
        self.ActiveTab.Content.Visible = false
        tween(self.ActiveTab.Button, {BackgroundColor3 = SpeedHubX.Theme.Sidebar})
        self.ActiveTab.Button.NameLabel.TextColor3 = SpeedHubX.Theme.Text
    end
    
    -- Select new
    self.ActiveTab = tab
    tab.Content.Visible = true
    tween(tab.Button, {BackgroundColor3 = SpeedHubX.Theme.ItemBg})
    tab.Button.NameLabel.TextColor3 = SpeedHubX.Theme.Accent
    
    -- Update canvas size
    task.delay(0.1, function()
        local contentLayout = tab.Content:FindFirstChildOfClass("UIListLayout")
        if contentLayout then
            tab.Content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
        end
    end)
end

-- Create Section (Accordion)
function SpeedHubX:CreateSection(tab, title: string)
    local section = {}
    section.Title = title
    section.Expanded = false
    section.Items = {}
    
    local frame = Instance.new("Frame")
    frame.Name = title .. "Section"
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = SpeedHubX.Theme.SectionBg
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = tab.Content
    
    createCorner(frame, 6)
    
    -- Header
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = SpeedHubX.Theme.Text
    titleLabel.Font = SpeedHubX.Theme.Font
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    -- Arrow
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 30, 0, 30)
    arrow.Position = UDim2.new(1, -35, 0, 5)
    arrow.BackgroundTransparency = 1
    arrow.Text = "›"
    arrow.TextColor3 = SpeedHubX.Theme.Text
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 20
    arrow.Rotation = 90
    arrow.Parent = header
    
    -- Content Container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, -20, 0, 0)
    container.Position = UDim2.new(0, 10, 0, 40)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true
    container.Parent = frame
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Padding = UDim.new(0, 6)
    containerLayout.Parent = container
    
    section.Frame = frame
    section.Container = container
    section.Arrow = arrow
    
    -- Toggle Function
    local function toggle()
        section.Expanded = not section.Expanded
        
        if section.Expanded then
            tween(arrow, {Rotation = -90})
            local contentSize = containerLayout.AbsoluteContentSize.Y
            tween(container, {Size = UDim2.new(1, -20, 0, contentSize + 10)})
        else
            tween(arrow, {Rotation = 90})
            tween(container, {Size = UDim2.new(1, -20, 0, 0)})
        end
        
        task.delay(0.2, function()
            local contentLayout = tab.Content:FindFirstChildOfClass("UIListLayout")
            if contentLayout then
                tab.Content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
            end
        end)
    end
    
    header.MouseButton1Click:Connect(toggle)
    
    -- Auto-expand
    toggle()
    
    return section
end

-- Create Toggle Switch
function SpeedHubX:CreateToggle(section, text: string, default: boolean, callback: (boolean) -> ())
    local toggle = {}
    toggle.Value = default or false
    
    local frame = Instance.new("Frame")
    frame.Name = text .. "Toggle"
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = SpeedHubX.Theme.ItemBg
    frame.BorderSizePixel = 0
    frame.Parent = section.Container
    
    createCorner(frame, 6)
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = SpeedHubX.Theme.Text
    label.Font = SpeedHubX.Theme.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    -- Toggle Background
    local toggleBg = Instance.new("TextButton")
    toggleBg.Name = "ToggleBg"
    toggleBg.Size = UDim2.new(0, 44, 0, 24)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -12)
    toggleBg.BackgroundColor3 = toggle.Value and SpeedHubX.Theme.ToggleOn or SpeedHubX.Theme.ToggleOff
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = frame
    
    createCorner(toggleBg, 12)
    
    -- Toggle Circle
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = toggle.Value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBg
    
    createCorner(circle, 9)
    
    local function updateToggle()
        toggle.Value = not toggle.Value
        
        local targetColor = toggle.Value and SpeedHubX.Theme.ToggleOn or SpeedHubX.Theme.ToggleOff
        local targetPos = toggle.Value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        
        tween(toggleBg, {BackgroundColor3 = targetColor})
        tween(circle, {Position = targetPos})
        
        if callback then
            callback(toggle.Value)
        end
    end
    
    toggleBg.MouseButton1Click:Connect(updateToggle)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateToggle()
        end
    end)
    
    function toggle:Set(value: boolean)
        if toggle.Value ~= value then
            updateToggle()
        end
    end
    
    return toggle
end

-- Create Dropdown
function SpeedHubX:CreateDropdown(section, text: string, items: {string}, multiSelect: boolean, callback: (any) -> ())
    local dropdown = {}
    dropdown.Items = items or {}
    dropdown.Selected = multiSelect and {} or ""
    dropdown.MultiSelect = multiSelect or false
    dropdown.Open = false
    
    local frame = Instance.new("Frame")
    frame.Name = text .. "Dropdown"
    frame.Size = UDim2.new(1, 0, 0, 70)
    frame.BackgroundColor3 = SpeedHubX.Theme.ItemBg
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = section.Container
    
    createCorner(frame, 6)
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = SpeedHubX.Theme.TextDark
    label.Font = SpeedHubX.Theme.Font
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    -- Selected Text / Button
    local selectedBtn = Instance.new("TextButton")
    selectedBtn.Name = "Selected"
    selectedBtn.Size = UDim2.new(1, -20, 0, 28)
    selectedBtn.Position = UDim2.new(0, 10, 0, 32)
    selectedBtn.BackgroundColor3 = SpeedHubX.Theme.Background
    selectedBtn.Text = multiSelect and "Select..." or (items[1] or "None")
    selectedBtn.TextColor3 = SpeedHubX.Theme.Text
    selectedBtn.Font = SpeedHubX.Theme.Font
    selectedBtn.TextSize = 12
    selectedBtn.Parent = frame
    
    createCorner(selectedBtn, 4)
    
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = SpeedHubX.Theme.TextDark
    arrow.Font = SpeedHubX.Theme.Font
    arrow.TextSize = 10
    arrow.Parent = selectedBtn
    
    -- Dropdown List
    local listFrame = Instance.new("Frame")
    listFrame.Name = "List"
    listFrame.Size = UDim2.new(1, -20, 0, 0)
    listFrame.Position = UDim2.new(0, 10, 0, 65)
    listFrame.BackgroundColor3 = SpeedHubX.Theme.Background
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.Parent = frame
    
    createCorner(listFrame, 4)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listFrame
    
    local function updateList()
        -- Clear existing
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, item in ipairs(dropdown.Items) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = SpeedHubX.Theme.Background
            btn.Text = "  " .. item
            btn.TextColor3 = SpeedHubX.Theme.Text
            btn.Font = SpeedHubX.Theme.Font
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = listFrame
            
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = SpeedHubX.Theme.ItemBg
            end)
            
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = SpeedHubX.Theme.Background
            end)
            
            btn.MouseButton1Click:Connect(function()
                if dropdown.MultiSelect then
                    if table.find(dropdown.Selected, item) then
                        table.remove(dropdown.Selected, table.find(dropdown.Selected, item))
                    else
                        table.insert(dropdown.Selected, item)
                    end
                    selectedBtn.Text = #dropdown.Selected > 0 and table.concat(dropdown.Selected, ", ") or "Select..."
                else
                    dropdown.Selected = item
                    selectedBtn.Text = item
                    dropdown.Open = false
                    listFrame.Visible = false
                    arrow.Text = "▼"
                    frame.Size = UDim2.new(1, 0, 0, 70)
                end
                
                if callback then
                    callback(dropdown.MultiSelect and dropdown.Selected or dropdown.Selected)
                end
            end)
        end
        
        task.wait()
        listFrame.Size = UDim2.new(1, -20, 0, listLayout.AbsoluteContentSize.Y)
    end
    
    selectedBtn.MouseButton1Click:Connect(function()
        dropdown.Open = not dropdown.Open
        listFrame.Visible = dropdown.Open
        arrow.Text = dropdown.Open and "▲" or "▼"
        
        if dropdown.Open then
            updateList()
            frame.Size = UDim2.new(1, 0, 0, 75 + math.min(#dropdown.Items * 28, 150))
        else
            frame.Size = UDim2.new(1, 0, 0, 70)
        end
    end)
    
    function dropdown:Set(value)
        if dropdown.MultiSelect then
            dropdown.Selected = typeof(value) == "table" and value or {value}
            selectedBtn.Text = #dropdown.Selected > 0 and table.concat(dropdown.Selected, ", ") or "Select..."
        else
            dropdown.Selected = value
            selectedBtn.Text = value
        end
    end
    
    return dropdown
end

-- Create Button
function SpeedHubX:CreateButton(section, text: string, callback: () -> ())
    local btn = Instance.new("TextButton")
    btn.Name = text .. "Btn"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = SpeedHubX.Theme.Accent
    btn.Text = text
    btn.TextColor3 = SpeedHubX.Theme.Text
    btn.Font = SpeedHubX.Theme.Font
    btn.TextSize = 13
    btn.Parent = section.Container
    
    createCorner(btn, 6)
    
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = SpeedHubX.Theme.AccentDark})
    end)
    
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = SpeedHubX.Theme.Accent})
    end)
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return btn
end

-- Create Label
function SpeedHubX:CreateLabel(section, text: string)
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = SpeedHubX.Theme.TextDark
    label.Font = SpeedHubX.Theme.Font
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section.Container
    
    return label
end

return SpeedHubX
