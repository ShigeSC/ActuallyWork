--!strict
local library = {
    flags = {},
    items = {},
    theme = {
        fontsize = 15,
        titlesize = 18,
        font = Enum.Font.Code,
        background = "rbxassetid://5553946656",
        tilesize = 90,
        cursor = false,
        cursorimg = "https://t0.rbxcdn.com/42f66da98c40252ee151326a82aab51f",
        backgroundcolor = Color3.fromRGB(20, 20, 20),
        tabstextcolor = Color3.fromRGB(240, 240, 240),
        bordercolor = Color3.fromRGB(60, 60, 60),
        accentcolor = Color3.fromRGB(28, 56, 139),
        accentcolor2 = Color3.fromRGB(16, 31, 78),
        outlinecolor = Color3.fromRGB(60, 60, 60),
        outlinecolor2 = Color3.fromRGB(0, 0, 0),
        sectorcolor = Color3.fromRGB(30, 30, 30),
        toptextcolor = Color3.fromRGB(255, 255, 255),
        topheight = 48,
        topcolor = Color3.fromRGB(30, 30, 30),
        topcolor2 = Color3.fromRGB(30, 30, 30),
        buttoncolor = Color3.fromRGB(49, 49, 49),
        buttoncolor2 = Color3.fromRGB(39, 39, 39),
        itemscolor = Color3.fromRGB(200, 200, 200),
        itemscolor2 = Color3.fromRGB(210, 210, 210)
    }
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Types
type Connection = RBXScriptConnection
type Theme = typeof(library.theme)

type Watermark = {
    Visible: boolean,
    text: string,
    main: ScreenGui,
    mainbar: Frame,
    UpdateTheme: (Theme) -> (),
    Remove: () -> ()
}

type Window = {
    name: string,
    size: UDim2,
    hidebutton: Enum.KeyCode,
    theme: Theme,
    Main: ScreenGui,
    Frame: TextButton,
    Tabs: {Tab},
    OpenedColorPickers: {[TextButton]: boolean},
    UpdateTheme: (Theme) -> (),
    CreateTab: (string) -> Tab
}

type Tab = {
    name: string,
    TabButton: TextButton,
    Left: ScrollingFrame,
    Right: ScrollingFrame,
    SectorsLeft: {Sector},
    SectorsRight: {Sector},
    SelectTab: () -> (),
    CreateSector: (string, string) -> Sector,
    CreateConfigSystem: (string?) -> ConfigSystem
}

type Sector = {
    name: string,
    side: string,
    Main: Frame,
    Items: Frame,
    FixSize: () -> (),
    AddButton: (string, () -> ()) -> Button,
    AddToggle: (string, boolean, (boolean) -> (), string?) -> Toggle,
    AddSlider: (string, number?, number?, number?, number?, (number) -> (), string?) -> Slider,
    AddDropdown: (string, {string}, string?, boolean, ((string | {string})) -> (), string?) -> Dropdown,
    AddTextbox: (string, string?, (string) -> (), string?) -> Textbox,
    AddLabel: (string) -> Label,
    AddColorpicker: (string, Color3?, (Color3) -> (), string?) -> Colorpicker,
    AddKeybind: (string, Enum.KeyCode?, (Enum.KeyCode) -> (), () -> (), string?) -> Keybind,
    AddSeperator: (string) -> Seperator
}

-- Utility Functions
local function protectGui(gui: ScreenGui)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif gethui then
        gui.Parent = gethui()
    else
        gui.Parent = CoreGui
    end
end

local function createOutline(parent: GuiObject, thickness: number, color: Color3, zIndex: number?): Frame
    local outline = Instance.new("Frame")
    outline.Name = "Outline_" .. thickness
    outline.ZIndex = zIndex or 4
    outline.Size = UDim2.fromOffset(parent.Size.X.Offset + thickness * 2, parent.Size.Y.Offset + thickness * 2)
    outline.BorderSizePixel = 0
    outline.BackgroundColor3 = color
    outline.Position = UDim2.fromOffset(-thickness, -thickness)
    outline.Parent = parent
    
    parent:GetPropertyChangedSignal("Size"):Connect(function()
        outline.Size = UDim2.fromOffset(parent.Size.X.Offset + thickness * 2, parent.Size.Y.Offset + thickness * 2)
    end)
    
    return outline
end

local function createGradient(parent: GuiObject, rotation: number, colorSeq: ColorSequence): UIGradient
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation
    gradient.Color = colorSeq
    gradient.Parent = parent
    return gradient
end

local function tween(instance: Instance, properties: {[string]: any}, duration: number?)
    TweenService:Create(instance, TweenInfo.new(duration or 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), properties):Play()
end

local connections: {Connection} = {}

local function trackConnection(conn: Connection)
    table.insert(connections, conn)
    return conn
end

-- Watermark
function library:CreateWatermark(name: string, position: Vector2?): Watermark
    local gamename = MarketplaceService:GetProductInfo(game.PlaceId).Name
    local watermark: Watermark = {
        Visible = true,
        text = " " .. name:gsub("{game}", gamename):gsub("{fps}", "0 FPS") .. " "
    }

    watermark.main = Instance.new("ScreenGui")
    watermark.main.Name = "Watermark"
    protectGui(watermark.main)

    if getgenv().watermark then
        getgenv().watermark:Destroy()
    end
    getgenv().watermark = watermark.main

    UserInputService.MouseIconEnabled = true
    UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None

    watermark.mainbar = Instance.new("Frame")
    watermark.mainbar.Name = "Main"
    watermark.mainbar.BorderColor3 = Color3.fromRGB(80, 80, 80)
    watermark.mainbar.Visible = watermark.Visible
    watermark.mainbar.BorderSizePixel = 0
    watermark.mainbar.ZIndex = 5
    watermark.mainbar.Position = UDim2.fromOffset(position and position.X or 10, position and position.Y or 10)
    watermark.mainbar.Size = UDim2.fromOffset(0, 25)
    watermark.mainbar.Parent = watermark.main

    createGradient(watermark.mainbar, 90, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
    }))

    createOutline(watermark.mainbar, 1, library.theme.outlinecolor, 4)
    createOutline(watermark.mainbar, 2, library.theme.outlinecolor2, 3)

    local topbar = Instance.new("Frame")
    topbar.Name = "TopBar"
    topbar.ZIndex = 6
    topbar.BackgroundColor3 = library.theme.accentcolor
    topbar.BorderSizePixel = 0
    topbar.Visible = watermark.Visible
    topbar.Size = UDim2.fromOffset(0, 1)
    topbar.Parent = watermark.mainbar

    local label = Instance.new("TextLabel")
    label.Name = "FPSLabel"
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.fromOffset(238, 25)
    label.Font = library.theme.font
    label.ZIndex = 6
    label.Text = watermark.text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 15
    label.TextStrokeTransparency = 0
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = watermark.mainbar

    local function updateSize()
        local textBounds = TextService:GetTextSize(label.Text, 15, library.theme.font, Vector2.new(9999, 9999))
        watermark.mainbar.Size = UDim2.fromOffset(textBounds.X + 10, 25)
        topbar.Size = UDim2.fromOffset(textBounds.X + 10, 1)
        label.Size = UDim2.fromOffset(textBounds.X + 10, 25)
    end

    updateSize()

    -- FPS Counter
    local startTime, counter = os.clock(), 0
    trackConnection(RunService.Heartbeat:Connect(function()
        if not name:find("{fps}") then return end
        
        counter += 1
        local currentTime = os.clock()
        if currentTime - startTime >= 1 then
            local fps = math.floor(counter / (currentTime - startTime))
            counter = 0
            startTime = currentTime
            
            label.Text = " " .. name:gsub("{game}", gamename):gsub("{fps}", fps .. " FPS") .. " "
            updateSize()
        end
    end))

    -- Hover effects
    watermark.mainbar.MouseEnter:Connect(function()
        tween(watermark.mainbar, {BackgroundTransparency = 1}, 0.1)
        tween(topbar, {BackgroundTransparency = 1}, 0.1)
        tween(label, {TextTransparency = 1}, 0.1)
    end)

    watermark.mainbar.MouseLeave:Connect(function()
        tween(watermark.mainbar, {BackgroundTransparency = 0}, 0.1)
        tween(topbar, {BackgroundTransparency = 0}, 0.1)
        tween(label, {TextTransparency = 0}, 0.1)
    end)

    function watermark:UpdateTheme(theme: Theme)
        topbar.BackgroundColor3 = theme.accentcolor
    end

    function watermark:Remove()
        watermark.main:Destroy()
    end

    return watermark
end

-- Window
function library:CreateWindow(name: string, size: Vector2?, hidebutton: Enum.KeyCode?): Window
    local window: Window = {
        name = name or "",
        size = UDim2.fromOffset(size and size.X or 492, size and size.Y or 598),
        hidebutton = hidebutton or Enum.KeyCode.RightShift,
        theme = library.theme,
        Tabs = {},
        OpenedColorPickers = {}
    }

    local updateevent = Instance.new("BindableEvent")
    
    function window:UpdateTheme(theme: Theme)
        updateevent:Fire(theme or library.theme)
        window.theme = theme or library.theme
    end

    window.Main = Instance.new("ScreenGui")
    window.Main.Name = name
    window.Main.DisplayOrder = 15
    protectGui(window.Main)

    if getgenv().uilib then
        getgenv().uilib:Destroy()
    end
    getgenv().uilib = window.Main

    -- Dragging
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            window.Frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end))

    local function dragStartFn(input: InputObject)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and 
           input.UserInputType ~= Enum.UserInputType.Touch then return end
        
        dragging = true
        dragStart = input.Position
        startPos = window.Frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end

    local function dragEndFn(input: InputObject)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and 
           input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragInput = input
    end

    window.Frame = Instance.new("TextButton")
    window.Frame.Name = "main"
    window.Frame.Position = UDim2.fromScale(0.5, 0.5)
    window.Frame.BorderSizePixel = 0
    window.Frame.Size = window.size
    window.Frame.AutoButtonColor = false
    window.Frame.Text = ""
    window.Frame.BackgroundColor3 = window.theme.backgroundcolor
    window.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Frame.Parent = window.Main

    trackConnection(updateevent.Event:Connect(function(theme)
        window.Frame.BackgroundColor3 = theme.backgroundcolor
    end))

    trackConnection(UserInputService.InputBegan:Connect(function(key)
        if key.KeyCode == window.hidebutton then
            window.Frame.Visible = not window.Frame.Visible
        end
    end))

    -- Outlines
    createOutline(window.Frame, 1, window.theme.outlinecolor2, 1)
    createOutline(window.Frame, 2, window.theme.outlinecolor, 0)
    createOutline(window.Frame, 3, window.theme.outlinecolor2, -1)

    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "top"
    topBar.Size = UDim2.fromOffset(window.size.X.Offset, window.theme.topheight)
    topBar.BorderSizePixel = 0
    topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topBar.InputBegan:Connect(dragStartFn)
    topBar.InputChanged:Connect(dragEndFn)
    topBar.Parent = window.Frame

    createGradient(topBar, 90, ColorSequence.new({
        ColorSequenceKeypoint.new(0, window.theme.topcolor),
        ColorSequenceKeypoint.new(1, window.theme.topcolor2)
    }))

    trackConnection(updateevent.Event:Connect(function(theme)
        topBar.Size = UDim2.fromOffset(window.size.X.Offset, theme.topheight)
    end))

    local nameLabel = Instance.new("TextLabel")
    nameLabel.TextColor3 = window.theme.toptextcolor
    nameLabel.Text = window.name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = window.theme.font
    nameLabel.Name = "title"
    nameLabel.Position = UDim2.fromOffset(4, -2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.fromOffset(190, topBar.AbsoluteSize.Y / 2 - 2)
    nameLabel.TextSize = window.theme.titlesize
    nameLabel.Parent = topBar

    local line2 = Instance.new("Frame")
    line2.Name = "line"
    line2.Position = UDim2.fromOffset(0, topBar.AbsoluteSize.Y / 2.1)
    line2.Size = UDim2.fromOffset(window.size.X.Offset, 1)
    line2.BorderSizePixel = 0
    line2.BackgroundColor3 = window.theme.accentcolor
    line2.Parent = topBar

    local tabList = Instance.new("Frame")
    tabList.Name = "tablist"
    tabList.BackgroundTransparency = 1
    tabList.Position = UDim2.fromOffset(0, topBar.AbsoluteSize.Y / 2 + 1)
    tabList.Size = UDim2.fromOffset(window.size.X.Offset, topBar.AbsoluteSize.Y / 2)
    tabList.BorderSizePixel = 0
    tabList.Parent = topBar
    tabList.InputBegan:Connect(dragStartFn)
    tabList.InputChanged:Connect(dragEndFn)

    local blackLine = Instance.new("Frame")
    blackLine.Name = "blackline"
    blackLine.Size = UDim2.fromOffset(window.size.X.Offset, 1)
    blackLine.BorderSizePixel = 0
    blackLine.ZIndex = 9
    blackLine.BackgroundColor3 = window.theme.outlinecolor2
    blackLine.Position = UDim2.fromOffset(0, topBar.AbsoluteSize.Y)
    blackLine.Parent = window.Frame

    local backgroundImage = Instance.new("ImageLabel")
    backgroundImage.Name = "background"
    backgroundImage.BorderSizePixel = 0
    backgroundImage.ScaleType = Enum.ScaleType.Tile
    backgroundImage.Position = blackLine.Position + UDim2.fromOffset(0, 1)
    backgroundImage.Size = UDim2.fromOffset(window.size.X.Offset, window.size.Y.Offset - topBar.AbsoluteSize.Y - 1)
    backgroundImage.Image = window.theme.background or ""
    backgroundImage.ImageTransparency = backgroundImage.Image ~= "" and 0 or 1
    backgroundImage.ImageColor3 = Color3.new()
    backgroundImage.BackgroundColor3 = window.theme.backgroundcolor
    backgroundImage.TileSize = UDim2.fromOffset(window.theme.tilesize, window.theme.tilesize)
    backgroundImage.Parent = window.Frame

    local line = Instance.new("Frame")
    line.Name = "line"
    line.Position = UDim2.fromOffset(0, 0)
    line.Size = UDim2.fromOffset(60, 1)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = window.theme.accentcolor
    line.Parent = window.Frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = tabList

    -- Tab Creation
    function window:CreateTab(tabName: string): Tab
        local tab: Tab = {
            name = tabName or "",
            SectorsLeft = {},
            SectorsRight = {}
        }

        local textSize = TextService:GetTextSize(tab.name, window.theme.fontsize, window.theme.font, Vector2.new(200, 300))

        tab.TabButton = Instance.new("TextButton")
        tab.TabButton.TextColor3 = window.theme.tabstextcolor
        tab.TabButton.Text = tab.name
        tab.TabButton.AutoButtonColor = false
        tab.TabButton.Font = window.theme.font
        tab.TabButton.TextYAlignment = Enum.TextYAlignment.Center
        tab.TabButton.BackgroundTransparency = 1
        tab.TabButton.BorderSizePixel = 0
        tab.TabButton.Size = UDim2.fromOffset(textSize.X + 15, tabList.AbsoluteSize.Y - 1)
        tab.TabButton.Name = tab.name
        tab.TabButton.TextSize = window.theme.fontsize
        tab.TabButton.Parent = tabList

        trackConnection(updateevent.Event:Connect(function(theme)
            local size = TextService:GetTextSize(tab.name, theme.fontsize, theme.font, Vector2.new(200, 300))
            tab.TabButton.TextColor3 = tab.TabButton.Name == "SelectedTab" and theme.accentcolor or theme.tabstextcolor
            tab.TabButton.Font = theme.font
            tab.TabButton.Size = UDim2.fromOffset(size.X + 15, tabList.AbsoluteSize.Y - 1)
            tab.TabButton.TextSize = theme.fontsize
        end))

        -- Scrolling Frames
        local function createSide(name: string, position: UDim2): ScrollingFrame
            local side = Instance.new("ScrollingFrame")
            side.Name = name
            side.BorderSizePixel = 0
            side.Size = UDim2.fromOffset(window.size.X.Offset / 2, window.size.Y.Offset - (topBar.AbsoluteSize.Y + 1))
            side.BackgroundTransparency = 1
            side.Visible = false
            side.ScrollBarThickness = 0
            side.ScrollingDirection = Enum.ScrollingDirection.Y
            side.Position = position
            side.Parent = window.Frame

            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 12)
            layout.Parent = side

            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 12)
            padding.PaddingLeft = UDim.new(0, 12)
            padding.PaddingRight = UDim.new(0, name == "leftside" and 12 or 6)
            padding.Parent = side

            return side
        end

        tab.Left = createSide("leftside", blackLine.Position + UDim2.fromOffset(0, 1))
        tab.Right = createSide("rightside", tab.Left.Position + UDim2.fromOffset(tab.Left.AbsoluteSize.X, 0))

        local selecting = false
        function tab:SelectTab()
            if selecting then return end
            selecting = true

            for _, v in ipairs(window.Tabs) do
                if v ~= tab then
                    v.TabButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                    v.TabButton.Name = "Tab"
                    v.Left.Visible = false
                    v.Right.Visible = false
                end
            end

            tab.TabButton.TextColor3 = window.theme.accentcolor
            tab.TabButton.Name = "SelectedTab"
            tab.Right.Visible = true
            tab.Left.Visible = true
            
            local targetSize = UDim2.fromOffset(tab.TabButton.AbsoluteSize.X, 1)
            local targetPos = UDim2.new(0, tab.TabButton.AbsolutePosition.X - window.Frame.AbsolutePosition.X, 0, 0) + 
                             (blackLine.Position - UDim2.fromOffset(0, 1))
            
            line:TweenSizeAndPosition(targetSize, targetPos, Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.15)

            task.wait(0.2)
            selecting = false
        end

        if #window.Tabs == 0 then
            tab:SelectTab()
        end

        tab.TabButton.MouseButton1Down:Connect(tab.SelectTab)

        -- Sector Creation
        function tab:CreateSector(sectorName: string, side: string): Sector
            local sector: Sector = {
                name = sectorName or "",
                side = side:lower() or "left"
            }

            sector.Main = Instance.new("Frame")
            sector.Main.Name = sector.name:gsub(" ", "") .. "Sector"
            sector.Main.BorderSizePixel = 0
            sector.Main.ZIndex = 4
            sector.Main.Size = UDim2.fromOffset(window.size.X.Offset / 2 - 17, 20)
            sector.Main.BackgroundColor3 = window.theme.sectorcolor
            sector.Main.Parent = sector.side == "left" and tab.Left or tab.Right

            trackConnection(updateevent.Event:Connect(function(theme)
                sector.Main.BackgroundColor3 = theme.sectorcolor
            end))

            -- Top accent line
            local topLine = Instance.new("Frame")
            topLine.Name = "line"
            topLine.ZIndex = 4
            topLine.Size = UDim2.fromOffset(sector.Main.Size.X.Offset + 4, 1)
            topLine.BorderSizePixel = 0
            topLine.Position = UDim2.fromOffset(-2, -2)
            topLine.BackgroundColor3 = window.theme.accentcolor
            topLine.Parent = sector.Main

            trackConnection(updateevent.Event:Connect(function(theme)
                topLine.BackgroundColor3 = theme.accentcolor
            end))

            -- Outlines
            for i = 1, 3 do
                local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                local color = i == 2 and window.theme.outlinecolor or window.theme.outlinecolor2
                createOutline(sector.Main, thickness, color, 4 - i)
            end

            -- Label
            local labelSize = TextService:GetTextSize(sector.name, 15, window.theme.font, Vector2.new(2000, 2000))
            local label = Instance.new("TextLabel")
            label.AnchorPoint = Vector2.new(0, 0.5)
            label.Position = UDim2.fromOffset(12, -1)
            label.Size = UDim2.fromOffset(math.clamp(labelSize.X + 13, 0, sector.Main.Size.X.Offset), labelSize.Y)
            label.BackgroundTransparency = 1
            label.BorderSizePixel = 0
            label.ZIndex = 6
            label.Text = sector.name
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 1
            label.Font = window.theme.font
            label.TextSize = 15
            label.Parent = sector.Main

            local labelBack = Instance.new("Frame")
            labelBack.Name = "labelframe"
            labelBack.ZIndex = 5
            labelBack.Size = UDim2.fromOffset(label.Size.X.Offset, 10)
            labelBack.BorderSizePixel = 0
            labelBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            labelBack.Position = UDim2.fromOffset(label.Position.X.Offset, -1)
            labelBack.Parent = sector.Main

            sector.Items = Instance.new("Frame")
            sector.Items.Name = "items"
            sector.Items.ZIndex = 2
            sector.Items.Size = UDim2.fromOffset(170, 140)
            sector.Items.AutomaticSize = Enum.AutomaticSize.Y
            sector.Items.BorderSizePixel = 0
            sector.Items.BackgroundTransparency = 1
            sector.Items.Parent = sector.Main

            local itemsLayout = Instance.new("UIListLayout")
            itemsLayout.FillDirection = Enum.FillDirection.Vertical
            itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            itemsLayout.Padding = UDim.new(0, 12)
            itemsLayout.Parent = sector.Items

            local itemsPadding = Instance.new("UIPadding")
            itemsPadding.PaddingTop = UDim.new(0, 15)
            itemsPadding.PaddingLeft = UDim.new(0, 6)
            itemsPadding.PaddingRight = UDim.new(0, 6)
            itemsPadding.Parent = sector.Items

            table.insert(sector.side == "left" and tab.SectorsLeft or tab.SectorsRight, sector)

            function sector:FixSize()
                sector.Main.Size = UDim2.fromOffset(window.size.X.Offset / 2 - 17, itemsLayout.AbsoluteContentSize.Y + 22)
                
                local function getTotalHeight(sectors: {Sector}): number
                    local height = 0
                    for _, v in ipairs(sectors) do
                        height += v.Main.AbsoluteSize.Y
                    end
                    return height
                end

                local leftHeight = getTotalHeight(tab.SectorsLeft) + ((#tab.SectorsLeft - 1) * 12) + 20
                local rightHeight = getTotalHeight(tab.SectorsRight) + ((#tab.SectorsRight - 1) * 12) + 20

                tab.Left.CanvasSize = UDim2.fromOffset(tab.Left.AbsoluteSize.X, leftHeight)
                tab.Right.CanvasSize = UDim2.fromOffset(tab.Right.AbsoluteSize.X, rightHeight)
            end

            -- Component: Button
            function sector:AddButton(text: string, callback: () -> ())
                local button = {
                    text = text or "",
                    callback = callback or function() end
                }

                button.Main = Instance.new("TextButton")
                button.Main.BorderSizePixel = 0
                button.Main.Text = ""
                button.Main.AutoButtonColor = false
                button.Main.Name = "button"
                button.Main.ZIndex = 5
                button.Main.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 14)
                button.Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                button.Main.Parent = sector.Items

                createGradient(button.Main, 90, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, library.theme.buttoncolor),
                    ColorSequenceKeypoint.new(1, library.theme.buttoncolor2)
                }))

                for i = 1, 3 do
                    local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                    local color = i == 2 and library.theme.outlinecolor or library.theme.outlinecolor2
                    local outline = createOutline(button.Main, thickness, color, 4)
                    if i == 2 then
                        button.hoverOutline = outline
                    end
                end

                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.BackgroundTransparency = 1
                label.Position = UDim2.new(0, -1, 0, 0)
                label.ZIndex = 5
                label.Size = button.Main.Size
                label.Font = library.theme.font
                label.Text = button.text
                label.TextColor3 = library.theme.itemscolor2
                label.TextSize = 15
                label.TextStrokeTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.Parent = button.Main

                button.Main.MouseButton1Down:Connect(button.callback)

                button.Main.MouseEnter:Connect(function()
                    if button.hoverOutline then
                        button.hoverOutline.BackgroundColor3 = library.theme.accentcolor
                    end
                end)

                button.Main.MouseLeave:Connect(function()
                    if button.hoverOutline then
                        button.hoverOutline.BackgroundColor3 = library.theme.outlinecolor2
                    end
                end)

                sector:FixSize()
                return button
            end

            -- Component: Label
            function sector:AddLabel(text: string)
                local label = {
                    Main = Instance.new("TextLabel")
                }

                label.Main.Name = "Label"
                label.Main.BackgroundTransparency = 1
                label.Main.Position = UDim2.new(0, -1, 0, 0)
                label.Main.ZIndex = 4
                label.Main.AutomaticSize = Enum.AutomaticSize.XY
                label.Main.Font = library.theme.font
                label.Main.Text = text
                label.Main.TextColor3 = library.theme.itemscolor
                label.Main.TextSize = 15
                label.Main.TextStrokeTransparency = 1
                label.Main.TextXAlignment = Enum.TextXAlignment.Left
                label.Main.Parent = sector.Items

                function label:Set(value: string)
                    label.Main.Text = value
                end

                sector:FixSize()
                return label
            end

            -- Component: Toggle
            function sector:AddToggle(text: string, default: boolean, callback: (boolean) -> (), flag: string?)
                local toggle = {
                    text = text or "",
                    default = default or false,
                    callback = callback or function() end,
                    flag = flag or text or "",
                    value = default or false
                }

                toggle.Main = Instance.new("TextButton")
                toggle.Main.Name = "toggle"
                toggle.Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                toggle.Main.BorderColor3 = library.theme.outlinecolor
                toggle.Main.BorderSizePixel = 0
                toggle.Main.Size = UDim2.fromOffset(8, 8)
                toggle.Main.AutoButtonColor = false
                toggle.Main.ZIndex = 5
                toggle.Main.Text = ""
                toggle.Main.Parent = sector.Items

                for i = 1, 3 do
                    local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                    local color = i == 2 and library.theme.outlinecolor or library.theme.outlinecolor2
                    local outline = createOutline(toggle.Main, thickness, color, 4)
                    if i == 2 then
                        toggle.hoverOutline = outline
                    end
                end

                createGradient(toggle.Main, 292.5, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45))
                }))

                local label = Instance.new("TextButton")
                label.Name = "Label"
                label.AutoButtonColor = false
                label.BackgroundTransparency = 1
                label.Position = UDim2.fromOffset(toggle.Main.AbsoluteSize.X + 10, -2)
                label.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 71, 12)
                label.Font = library.theme.font
                label.ZIndex = 5
                label.Text = toggle.text
                label.TextColor3 = library.theme.itemscolor
                label.TextSize = 15
                label.TextStrokeTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = toggle.Main

                toggle.CheckedFrame = Instance.new("Frame")
                toggle.CheckedFrame.ZIndex = 5
                toggle.CheckedFrame.BorderSizePixel = 0
                toggle.CheckedFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                toggle.CheckedFrame.Size = toggle.Main.Size
                toggle.CheckedFrame.Visible = toggle.value
                toggle.CheckedFrame.Parent = toggle.Main

                createGradient(toggle.CheckedFrame, 292.5, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, library.theme.accentcolor2),
                    ColorSequenceKeypoint.new(1, library.theme.accentcolor)
                }))

                if toggle.flag and toggle.flag ~= "" then
                    library.flags[toggle.flag] = toggle.default
                end

                function toggle:Set(value: boolean)
                    toggle.value = value
                    toggle.CheckedFrame.Visible = value
                    label.TextColor3 = value and library.theme.itemscolor2 or library.theme.itemscolor
                    
                    if toggle.flag and toggle.flag ~= "" then
                        library.flags[toggle.flag] = toggle.value
                    end
                    
                    pcall(toggle.callback, value)
                end

                function toggle:Get(): boolean
                    return toggle.value
                end

                toggle:Set(toggle.default)

                local function onClick()
                    toggle:Set(not toggle.value)
                end

                toggle.Main.MouseButton1Down:Connect(onClick)
                label.MouseButton1Down:Connect(onClick)

                local function onEnter()
                    if toggle.hoverOutline then
                        toggle.hoverOutline.BackgroundColor3 = library.theme.accentcolor
                    end
                end

                local function onLeave()
                    if toggle.hoverOutline then
                        toggle.hoverOutline.BackgroundColor3 = library.theme.outlinecolor2
                    end
                end

                label.MouseEnter:Connect(onEnter)
                label.MouseLeave:Connect(onLeave)
                toggle.Main.MouseEnter:Connect(onEnter)
                toggle.Main.MouseLeave:Connect(onLeave)

                sector:FixSize()
                table.insert(library.items, toggle)
                return toggle
            end

            -- Component: Slider
            function sector:AddSlider(text: string, min: number?, default: number?, max: number?, decimals: number?, callback: (number) -> (), flag: string?)
                local slider = {
                    text = text or "",
                    callback = callback or function() end,
                    min = min or 0,
                    max = max or 100,
                    decimals = decimals or 1,
                    default = default or min or 0,
                    flag = flag or text or "",
                    value = default or min or 0
                }

                local dragging = false

                slider.MainBack = Instance.new("Frame")
                slider.MainBack.Name = "MainBack"
                slider.MainBack.ZIndex = 7
                slider.MainBack.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 25)
                slider.MainBack.BorderSizePixel = 0
                slider.MainBack.BackgroundTransparency = 1
                slider.MainBack.Parent = sector.Items

                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 6)
                label.Font = library.theme.font
                label.Text = slider.text .. ":"
                label.TextColor3 = library.theme.itemscolor
                label.Position = UDim2.fromOffset(0, 0)
                label.TextSize = 15
                label.ZIndex = 4
                label.TextStrokeTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = slider.MainBack

                local labelSize = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(200, 300))
                
                slider.InputLabel = Instance.new("TextBox")
                slider.InputLabel.BackgroundTransparency = 1
                slider.InputLabel.ClearTextOnFocus = false
                slider.InputLabel.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - labelSize.X - 15, 12)
                slider.InputLabel.Font = library.theme.font
                slider.InputLabel.Text = tostring(slider.default)
                slider.InputLabel.TextColor3 = library.theme.itemscolor
                slider.InputLabel.Position = UDim2.fromOffset(labelSize.X + 3, -3)
                slider.InputLabel.TextSize = 15
                slider.InputLabel.ZIndex = 4
                slider.InputLabel.TextStrokeTransparency = 1
                slider.InputLabel.TextXAlignment = Enum.TextXAlignment.Left
                slider.InputLabel.Parent = slider.MainBack

                slider.Main = Instance.new("TextButton")
                slider.Main.Name = "slider"
                slider.Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                slider.Main.Position = UDim2.fromOffset(0, 15)
                slider.Main.BorderSizePixel = 0
                slider.Main.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 12)
                slider.Main.AutoButtonColor = false
                slider.Main.Text = ""
                slider.Main.ZIndex = 5
                slider.Main.Parent = slider.MainBack

                for i = 1, 3 do
                    local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                    local color = i == 2 and library.theme.outlinecolor or library.theme.outlinecolor2
                    local outline = createOutline(slider.Main, thickness, color, 4)
                    if i == 2 then
                        slider.hoverOutline = outline
                    end
                end

                createGradient(slider.Main, 90, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(49, 49, 49)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(41, 41, 41))
                }))

                slider.SlideBar = Instance.new("Frame")
                slider.SlideBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                slider.SlideBar.ZIndex = 5
                slider.SlideBar.BorderSizePixel = 0
                slider.SlideBar.Size = UDim2.fromOffset(0, slider.Main.Size.Y.Offset)
                slider.SlideBar.Parent = slider.Main

                createGradient(slider.SlideBar, 90, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, library.theme.accentcolor),
                    ColorSequenceKeypoint.new(1, library.theme.accentcolor2)
                }))

                if slider.flag and slider.flag ~= "" then
                    library.flags[slider.flag] = slider.default
                end

                function slider:Get(): number
                    return slider.value
                end

                function slider:Set(value: number)
                    slider.value = math.clamp(math.round(value * slider.decimals) / slider.decimals, slider.min, slider.max)
                    local percent = 1 - ((slider.max - slider.value) / (slider.max - slider.min))
                    
                    if slider.flag and slider.flag ~= "" then
                        library.flags[slider.flag] = slider.value
                    end
                    
                    slider.SlideBar:TweenSize(
                        UDim2.fromOffset(percent * slider.Main.AbsoluteSize.X, slider.Main.AbsoluteSize.Y),
                        Enum.EasingDirection.In,
                        Enum.EasingStyle.Sine,
                        0.05
                    )
                    
                    slider.InputLabel.Text = tostring(slider.value)
                    pcall(slider.callback, slider.value)
                end

                slider:Set(slider.default)

                slider.InputLabel.FocusLost:Connect(function()
                    local num = tonumber(slider.InputLabel.Text)
                    if num then
                        slider:Set(num)
                    else
                        slider.InputLabel.Text = tostring(slider.value)
                    end
                end)

                local function refresh()
                    local mousePos = camera:WorldToViewportPoint(mouse.Hit.Position)
                    local percent = math.clamp(mousePos.X - slider.SlideBar.AbsolutePosition.X, 0, slider.Main.AbsoluteSize.X) / slider.Main.AbsoluteSize.X
                    local value = math.floor((slider.min + (slider.max - slider.min) * percent) * slider.decimals) / slider.decimals
                    slider:Set(math.clamp(value, slider.min, slider.max))
                end

                local function inputBegan(input: InputObject)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        refresh()
                    end
                end

                local function inputEnded(input: InputObject)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end

                slider.SlideBar.InputBegan:Connect(inputBegan)
                slider.SlideBar.InputEnded:Connect(inputEnded)
                slider.Main.InputBegan:Connect(inputBegan)
                slider.Main.InputEnded:Connect(inputEnded)

                trackConnection(UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        refresh()
                    end
                end))

                slider.Main.MouseEnter:Connect(function()
                    if slider.hoverOutline then
                        slider.hoverOutline.BackgroundColor3 = library.theme.accentcolor
                    end
                end)

                slider.Main.MouseLeave:Connect(function()
                    if slider.hoverOutline then
                        slider.hoverOutline.BackgroundColor3 = library.theme.outlinecolor2
                    end
                end)

                sector:FixSize()
                table.insert(library.items, slider)
                return slider
            end

            -- Component: Dropdown
            function sector:AddDropdown(text: string, items: {string}, default: string?, multichoice: boolean?, callback: ((string | {string})) -> (), flag: string?)
                local dropdown = {
                    text = text or "",
                    defaultitems = items or {},
                    default = default,
                    callback = callback or function() end,
                    multichoice = multichoice or false,
                    values = {},
                    flag = flag or text or "",
                    items = {}
                }

                dropdown.MainBack = Instance.new("Frame")
                dropdown.MainBack.Name = "backlabel"
                dropdown.MainBack.ZIndex = 7
                dropdown.MainBack.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 34)
                dropdown.MainBack.BorderSizePixel = 0
                dropdown.MainBack.BackgroundTransparency = 1
                dropdown.MainBack.Parent = sector.Items

                local label = Instance.new("TextLabel")
                label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                label.BackgroundTransparency = 1
                label.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 10)
                label.Position = UDim2.fromOffset(0, 0)
                label.Font = library.theme.font
                label.Text = dropdown.text
                label.ZIndex = 4
                label.TextColor3 = library.theme.itemscolor
                label.TextSize = 15
                label.TextStrokeTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = dropdown.MainBack

                dropdown.Main = Instance.new("TextButton")
                dropdown.Main.Name = "dropdown"
                dropdown.Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                dropdown.Main.BorderSizePixel = 0
                dropdown.Main.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 16)
                dropdown.Main.Position = UDim2.fromOffset(0, 17)
                dropdown.Main.ZIndex = 5
                dropdown.Main.AutoButtonColor = false
                dropdown.Main.Font = library.theme.font
                dropdown.Main.Text = ""
                dropdown.Main.TextColor3 = Color3.fromRGB(255, 255, 255)
                dropdown.Main.TextSize = 15
                dropdown.Main.TextXAlignment = Enum.TextXAlignment.Left
                dropdown.Main.Parent = dropdown.MainBack

                createGradient(dropdown.Main, 90, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(49, 49, 49)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 39, 39))
                }))

                local selectedLabel = Instance.new("TextLabel")
                selectedLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                selectedLabel.BackgroundTransparency = 1
                selectedLabel.Position = UDim2.fromOffset(5, 2)
                selectedLabel.Size = UDim2.fromOffset(130, 13)
                selectedLabel.Font = library.theme.font
                selectedLabel.Text = dropdown.text
                selectedLabel.ZIndex = 5
                selectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                selectedLabel.TextSize = 15
                selectedLabel.TextStrokeTransparency = 1
                selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
                selectedLabel.Parent = dropdown.Main

                local nav = Instance.new("ImageButton")
                nav.Name = "navigation"
                nav.BackgroundTransparency = 1
                nav.LayoutOrder = 10
                nav.Position = UDim2.fromOffset(sector.Main.Size.X.Offset - 26, 5)
                nav.Rotation = 90
                nav.ZIndex = 5
                nav.Size = UDim2.fromOffset(8, 8)
                nav.Image = "rbxassetid://4918373417"
                nav.ImageColor3 = Color3.fromRGB(210, 210, 210)
                nav.Parent = dropdown.Main

                for i = 1, 3 do
                    local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                    local color = i == 2 and library.theme.outlinecolor or library.theme.outlinecolor2
                    local outline = createOutline(dropdown.Main, thickness, color, 4)
                    if i == 2 then
                        dropdown.hoverOutline = outline
                    end
                end

                local itemsFrame = Instance.new("ScrollingFrame")
                itemsFrame.Name = "itemsframe"
                itemsFrame.BorderSizePixel = 0
                itemsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                itemsFrame.Position = UDim2.fromOffset(0, dropdown.Main.Size.Y.Offset + 8)
                itemsFrame.ScrollBarThickness = 2
                itemsFrame.ZIndex = 8
                itemsFrame.ScrollingDirection = Enum.ScrollingDirection.Y
                itemsFrame.Visible = false
                itemsFrame.CanvasSize = UDim2.fromOffset(dropdown.Main.AbsoluteSize.X, 0)
                itemsFrame.Parent = dropdown.Main

                local listLayout = Instance.new("UIListLayout")
                listLayout.FillDirection = Enum.FillDirection.Vertical
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Parent = itemsFrame

                local listPadding = Instance.new("UIPadding")
                listPadding.PaddingTop = UDim.new(0, 2)
                listPadding.PaddingBottom = UDim.new(0, 2)
                listPadding.PaddingLeft = UDim.new(0, 2)
                listPadding.PaddingRight = UDim.new(0, 2)
                listPadding.Parent = itemsFrame

                local outlineFrames = {}
                for i = 1, 3 do
                    local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                    local color = i == 2 and library.theme.outlinecolor or library.theme.outlinecolor2
                    local frame = Instance.new("Frame")
                    frame.Name = "outline"
                    frame.ZIndex = 7
                    frame.BorderSizePixel = 0
                    frame.BackgroundColor3 = color
                    frame.Visible = false
                    frame.Parent = dropdown.Main
                    outlineFrames[i] = frame
                end

                local ignoreBack = Instance.new("TextButton")
                ignoreBack.BackgroundTransparency = 1
                ignoreBack.BorderSizePixel = 0
                ignoreBack.Position = UDim2.fromOffset(0, dropdown.Main.Size.Y.Offset + 8)
                ignoreBack.Size = UDim2.new(0, 0, 0, 0)
                ignoreBack.ZIndex = 7
                ignoreBack.Text = ""
                ignoreBack.Visible = false
                ignoreBack.AutoButtonColor = false
                ignoreBack.Parent = dropdown.Main

                if dropdown.flag and dropdown.flag ~= "" then
                    library.flags[dropdown.flag] = dropdown.multichoice and {dropdown.default or dropdown.defaultitems[1] or ""} or (dropdown.default or dropdown.defaultitems[1] or "")
                end

                function dropdown:isSelected(item: string): boolean
                    for _, v in ipairs(dropdown.values) do
                        if v == item then
                            return true
                        end
                    end
                    return false
                end

                function dropdown:updateText(text: string)
                    if #text >= 27 then
                        text = text:sub(1, 25) .. ".."
                    end
                    selectedLabel.Text = text
                end

                function dropdown:Set(value: string | {string})
                    if typeof(value) == "table" then
                        dropdown.values = value
                        dropdown:updateText(table.concat(value, ", "))
                        pcall(dropdown.callback, value)
                    else
                        dropdown:updateText(value)
                        dropdown.values = {value}
                        pcall(dropdown.callback, value)
                    end

                    if dropdown.flag and dropdown.flag ~= "" then
                        library.flags[dropdown.flag] = dropdown.multichoice and dropdown.values or dropdown.values[1]
                    end
                end

                function dropdown:Get(): string | {string}
                    return dropdown.multichoice and dropdown.values or dropdown.values[1]
                end

                function dropdown:Add(v: string)
                    local item = Instance.new("TextButton")
                    item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    item.TextColor3 = Color3.fromRGB(255, 255, 255)
                    item.BorderSizePixel = 0
                    item.Position = UDim2.fromOffset(0, 0)
                    item.Size = UDim2.fromOffset(dropdown.Main.Size.X.Offset - 4, 20)
                    item.ZIndex = 9
                    item.Text = v
                    item.Name = v
                    item.AutoButtonColor = false
                    item.Font = library.theme.font
                    item.TextSize = 15
                    item.TextXAlignment = Enum.TextXAlignment.Left
                    item.TextStrokeTransparency = 1
                    item.Parent = itemsFrame

                    item.MouseButton1Down:Connect(function()
                        if dropdown.multichoice then
                            if dropdown:isSelected(v) then
                                for i2, v2 in ipairs(dropdown.values) do
                                    if v2 == v then
                                        table.remove(dropdown.values, i2)
                                    end
                                end
                                dropdown:Set(dropdown.values)
                            else
                                table.insert(dropdown.values, v)
                                dropdown:Set(dropdown.values)
                            end
                            return
                        else
                            nav.Rotation = 90
                            itemsFrame.Visible = false
                            itemsFrame.Active = false
                            for _, frame in ipairs(outlineFrames) do
                                frame.Visible = false
                            end
                            ignoreBack.Visible = false
                            ignoreBack.Active = false
                        end

                        dropdown:Set(v)
                    end)

                    -- Use property change instead of RenderStepped
                    local function updateItem()
                        if dropdown.multichoice and dropdown:isSelected(v) or dropdown.values[1] == v then
                            item.BackgroundColor3 = Color3.fromRGB(64, 64, 64)
                            item.TextColor3 = library.theme.accentcolor
                            item.Text = " " .. v
                        else
                            item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            item.TextColor3 = Color3.fromRGB(255, 255, 255)
                            item.Text = v
                        end
                    end

                    -- Update when values change
                    local oldSet = dropdown.Set
                    dropdown.Set = function(self, value)
                        oldSet(self, value)
                        updateItem()
                    end

                    table.insert(dropdown.items, v)
                    
                    local contentHeight = #dropdown.items * 20
                    itemsFrame.Size = UDim2.fromOffset(dropdown.Main.Size.X.Offset, math.clamp(contentHeight, 20, 156) + 4)
                    itemsFrame.CanvasSize = UDim2.fromOffset(itemsFrame.AbsoluteSize.X, contentHeight + 4)

                    for i, frame in ipairs(outlineFrames) do
                        local offset = i == 1 and 2 or (i == 2 and 4 or 6)
                        frame.Size = itemsFrame.Size + UDim2.fromOffset(offset, offset)
                        frame.Position = itemsFrame.Position + UDim2.fromOffset(-offset/2, -offset/2)
                    end
                    ignoreBack.Size = itemsFrame.Size
                end

                function dropdown:Remove(value: string)
                    local item = itemsFrame:FindFirstChild(value)
                    if item then
                        for i, v in ipairs(dropdown.items) do
                            if v == value then
                                table.remove(dropdown.items, i)
                            end
                        end

                        local contentHeight = #dropdown.items * 20
                        itemsFrame.Size = UDim2.fromOffset(dropdown.Main.Size.X.Offset, math.clamp(contentHeight, 20, 156) + 4)
                        itemsFrame.CanvasSize = UDim2.fromOffset(itemsFrame.AbsoluteSize.X, contentHeight + 4)

                        for i, frame in ipairs(outlineFrames) do
                            local offset = i == 1 and 2 or (i == 2 and 4 or 6)
                            frame.Size = itemsFrame.Size + UDim2.fromOffset(offset, offset)
                        end
                        ignoreBack.Size = itemsFrame.Size

                        item:Destroy()
                    end
                end

                for _, v in ipairs(dropdown.defaultitems) do
                    dropdown:Add(v)
                end

                if dropdown.default then
                    dropdown:Set(dropdown.default)
                end

                local function toggleDropdown()
                    local isOpen = nav.Rotation == 90
                    
                    if isOpen then
                        nav.Rotation = -90
                        if #dropdown.items > 0 then
                            itemsFrame.ScrollingEnabled = true
                            sector.Main.Parent.ScrollingEnabled = false
                            itemsFrame.Visible = true
                            itemsFrame.Active = true
                            ignoreBack.Visible = true
                            ignoreBack.Active = true
                            for _, frame in ipairs(outlineFrames) do
                                frame.Visible = true
                            end
                        end
                    else
                        nav.Rotation = 90
                        itemsFrame.ScrollingEnabled = false
                        sector.Main.Parent.ScrollingEnabled = true
                        itemsFrame.Visible = false
                        itemsFrame.Active = false
                        ignoreBack.Visible = false
                        ignoreBack.Active = false
                        for _, frame in ipairs(outlineFrames) do
                            frame.Visible = false
                        end
                    end
                end

                dropdown.Main.MouseButton1Down:Connect(toggleDropdown)
                nav.MouseButton1Down:Connect(toggleDropdown)

                dropdown.Main.MouseEnter:Connect(function()
                    if dropdown.hoverOutline then
                        dropdown.hoverOutline.BackgroundColor3 = library.theme.accentcolor
                    end
                end)

                dropdown.Main.MouseLeave:Connect(function()
                    if dropdown.hoverOutline then
                        dropdown.hoverOutline.BackgroundColor3 = library.theme.outlinecolor2
                    end
                end)

                sector:FixSize()
                table.insert(library.items, dropdown)
                return dropdown
            end

            -- Component: Textbox
            function sector:AddTextbox(text: string, default: string?, callback: (string) -> (), flag: string?)
                local textbox = {
                    text = text or "",
                    callback = callback or function() end,
                    default = default,
                    value = "",
                    flag = flag or text or ""
                }

                local holder = Instance.new("Frame")
                holder.Name = "holder"
                holder.ZIndex = 5
                holder.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 14)
                holder.BorderSizePixel = 0
                holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                holder.Parent = sector.Items

                createGradient(holder, 90, ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(49, 49, 49)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 39, 39))
                }))

                textbox.Main = Instance.new("TextBox")
                textbox.Main.PlaceholderText = text
                textbox.Main.PlaceholderColor3 = Color3.fromRGB(190, 190, 190)
                textbox.Main.Text = ""
                textbox.Main.BackgroundTransparency = 1
                textbox.Main.Font = library.theme.font
                textbox.Main.Name = "textbox"
                textbox.Main.MultiLine = false
                textbox.Main.ClearTextOnFocus = false
                textbox.Main.ZIndex = 5
                textbox.Main.TextScaled = true
                textbox.Main.Size = holder.Size
                textbox.Main.TextSize = 15
                textbox.Main.TextColor3 = Color3.fromRGB(255, 255, 255)
                textbox.Main.BorderSizePixel = 0
                textbox.Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                textbox.Main.TextXAlignment = Enum.TextXAlignment.Left
                textbox.Main.Parent = holder

                for i = 1, 3 do
                    local thickness = i == 1 and 1 or (i == 2 and 2 or 3)
                    local color = i == 2 and library.theme.outlinecolor or library.theme.outlinecolor2
                    local outline = createOutline(textbox.Main, thickness, color, 4)
                    if i == 2 then
                        textbox.hoverOutline = outline
                    end
                end

                if textbox.flag and textbox.flag ~= "" then
                    library.flags[textbox.flag] = textbox.default or ""
                end

                function textbox:Set(text: string)
                    textbox.value = text
                    textbox.Main.Text = text
                    if textbox.flag and textbox.flag ~= "" then
                        library.flags[textbox.flag] = text
                    end
                    pcall(textbox.callback, text)
                end

                function textbox:Get(): string
                    return textbox.value
                end

                if textbox.default then
                    textbox:Set(textbox.default)
                end

                textbox.Main.FocusLost:Connect(function()
                    textbox:Set(textbox.Main.Text)
                end)

                textbox.Main.MouseEnter:Connect(function()
                    if textbox.hoverOutline then
                        textbox.hoverOutline.BackgroundColor3 = library.theme.accentcolor
                    end
                end)

                textbox.Main.MouseLeave:Connect(function()
                    if textbox.hoverOutline then
                        textbox.hoverOutline.BackgroundColor3 = library.theme.outlinecolor2
                    end
                end)

                sector:FixSize()
                table.insert(library.items, textbox)
                return textbox
            end

            -- Component: Keybind
            function sector:AddKeybind(text: string, default: Enum.KeyCode?, newkeycallback: (Enum.KeyCode) -> (), callback: () -> (), flag: string?)
                local keybind = {
                    text = text or "",
                    default = default or "None",
                    callback = callback or function() end,
                    newkeycallback = newkeycallback or function() end,
                    flag = flag or text or "",
                    value = default or "None"
                }

                local main = Instance.new("TextLabel")
                main.BackgroundTransparency = 1
                main.Size = UDim2.fromOffset(156, 10)
                main.ZIndex = 4
                main.Font = library.theme.font
                main.Text = keybind.text
                main.TextColor3 = library.theme.itemscolor
                main.TextSize = 15
                main.TextStrokeTransparency = 1
                main.TextXAlignment = Enum.TextXAlignment.Left
                main.Parent = sector.Items

                local bind = Instance.new("TextButton")
                bind.Name = "keybind"
                bind.BackgroundTransparency = 1
                bind.BorderColor3 = library.theme.outlinecolor
                bind.ZIndex = 5
                bind.BorderSizePixel = 0
                bind.Position = UDim2.fromOffset(sector.Main.Size.X.Offset - 10, 0)
                bind.Font = library.theme.font
                bind.TextColor3 = Color3.fromRGB(136, 136, 136)
                bind.TextSize = 15
                bind.TextXAlignment = Enum.TextXAlignment.Right
                bind.Parent = main

                local shorterKeycodes = {
                    ["LeftShift"] = "LSHIFT",
                    ["RightShift"] = "RSHIFT",
                    ["LeftControl"] = "LCTRL",
                    ["RightControl"] = "RCTRL",
                    ["LeftAlt"] = "LALT",
                    ["RightAlt"] = "RALT"
                }

                if keybind.flag and keybind.flag ~= "" then
                    library.flags[keybind.flag] = keybind.default
                end

                function keybind:Set(value: Enum.KeyCode | string)
                    if value == "None" then
                        keybind.value = value
                        bind.Text = "[None]"
                    else
                        keybind.value = value
                        local name = shorterKeycodes[value.Name] or value.Name
                        bind.Text = "[" .. name .. "]"
                    end

                    local size = TextService:GetTextSize(bind.Text, bind.TextSize, bind.Font, Vector2.new(2000, 2000))
                    bind.Size = UDim2.fromOffset(size.X, size.Y)
                    bind.Position = UDim2.fromOffset(sector.Main.Size.X.Offset - 10 - bind.AbsoluteSize.X, 0)

                    if keybind.flag and keybind.flag ~= "" then
                        library.flags[keybind.flag] = keybind.value
                    end
                    pcall(keybind.newkeycallback, keybind.value)
                end

                keybind:Set(keybind.default or "None")

                function keybind:Get(): Enum.KeyCode | string
                    return keybind.value
                end

                bind.MouseButton1Down:Connect(function()
                    bind.Text = "[...]"
                    bind.TextColor3 = library.theme.accentcolor
                end)

                trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end

                    if bind.Text == "[...]" then
                        bind.TextColor3 = Color3.fromRGB(136, 136, 136)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            keybind:Set(input.KeyCode)
                        else
                            keybind:Set("None")
                        end
                    else
                        if keybind.value ~= "None" and input.KeyCode == keybind.value then
                            pcall(keybind.callback)
                        end
                    end
                end))

                sector:FixSize()
                table.insert(library.items, keybind)
                return keybind
            end

            -- Component: Seperator
            function sector:AddSeperator(text: string)
                local seperator = {
                    text = text or ""
                }

                local main = Instance.new("Frame")
                main.Name = "Main"
                main.ZIndex = 5
                main.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 12, 10)
                main.BorderSizePixel = 0
                main.BackgroundTransparency = 1
                main.Parent = sector.Items

                local line = Instance.new("Frame")
                line.Name = "Line"
                line.ZIndex = 7
                line.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                line.BorderSizePixel = 0
                line.Size = UDim2.fromOffset(sector.Main.Size.X.Offset - 26, 1)
                line.Position = UDim2.fromOffset(7, 5)
                line.Parent = main

                local outline = Instance.new("Frame")
                outline.Name = "Outline"
                outline.ZIndex = 6
                outline.BorderSizePixel = 0
                outline.BackgroundColor3 = library.theme.outlinecolor2
                outline.Position = UDim2.fromOffset(-1, -1)
                outline.Size = line.Size + UDim2.fromOffset(2, 2)
                outline.Parent = line

                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.BackgroundTransparency = 1
                label.Size = main.Size
                label.Font = library.theme.font
                label.ZIndex = 8
                label.Text = seperator.text
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextSize = library.theme.fontsize
                label.TextStrokeTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.Parent = main

                local textSize = TextService:GetTextSize(seperator.text, library.theme.fontsize, library.theme.font, Vector2.new(2000, 2000))
                local textStart = main.AbsoluteSize.X / 2 - (textSize.X / 2)

                local labelBack = Instance.new("Frame")
                labelBack.Name = "LabelBack"
                labelBack.ZIndex = 7
                labelBack.Size = UDim2.fromOffset(textSize.X + 12, 10)
                labelBack.BorderSizePixel = 0
                labelBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                labelBack.Position = UDim2.new(0, textStart - 6, 0, 0)
                labelBack.Parent = main

                sector:FixSize()
                return seperator
            end

            return sector
        end

        -- Config System
        function tab:CreateConfigSystem(side: string?)
            local configSystem = {
                configFolder = window.name .. "/" .. tostring(game.PlaceId)
            }

            if not isfolder(configSystem.configFolder) then
                makefolder(configSystem.configFolder)
            end

            configSystem.sector = tab:CreateSector("Configs", side or "left")

            local configName = configSystem.sector:AddTextbox("Config Name", "", function() end, "")
            
            local files = {}
            for _, v in ipairs(listfiles(configSystem.configFolder)) do
                if v:find(".txt") then
                    table.insert(files, v:gsub(configSystem.configFolder .. "\\", ""):gsub(".txt", ""))
                end
            end

            local configDropdown = configSystem.sector:AddDropdown("Configs", files, files[1], false, function() end, "")

            configSystem.sector:AddButton("Create", function()
                for _, v in ipairs(listfiles(configSystem.configFolder)) do
                    configDropdown:Remove(v:gsub(configSystem.configFolder .. "\\", ""):gsub(".txt", ""))
                end

                local name = configName:Get()
                if name and name ~= "" then
                    local config = {}

                    for i, v in pairs(library.flags) do
                        if v ~= nil and v ~= "" then
                            if typeof(v) == "Color3" then
                                config[i] = {v.R, v.G, v.B}
                            elseif tostring(v):find("Enum.KeyCode") then
                                config[i] = v.Name
                            elseif typeof(v) == "table" then
                                config[i] = {v}
                            else
                                config[i] = v
                            end
                        end
                    end

                    writefile(configSystem.configFolder .. "/" .. name .. ".txt", HttpService:JSONEncode(config))

                    for _, v in ipairs(listfiles(configSystem.configFolder)) do
                        if v:find(".txt") then
                            configDropdown:Add(v:gsub(configSystem.configFolder .. "\\", ""):gsub(".txt", ""))
                        end
                    end
                end
            end)

            configSystem.sector:AddButton("Save", function()
                local config = {}
                local name = configDropdown:Get()
                if name and name ~= "" then
                    for i, v in pairs(library.flags) do
                        if v ~= nil and v ~= "" then
                            if typeof(v) == "Color3" then
                                config[i] = {v.R, v.G, v.B}
                            elseif tostring(v):find("Enum.KeyCode") then
                                config[i] = "Enum.KeyCode." .. v.Name
                            elseif typeof(v) == "table" then
                                config[i] = {v}
                            else
                                config[i] = v
                            end
                        end
                    end

                    writefile(configSystem.configFolder .. "/" .. name .. ".txt", HttpService:JSONEncode(config))
                end
            end)

            configSystem.sector:AddButton("Load", function()
                local success, content = pcall(readfile, configSystem.configFolder .. "/" .. configDropdown:Get() .. ".txt")
                if success then
                    local readConfig = HttpService:JSONDecode(content)
                    local newConfig = {}

                    for i, v in pairs(readConfig) do
                        if typeof(v) == "table" then
                            if typeof(v[1]) == "number" then
                                newConfig[i] = Color3.new(v[1], v[2], v[3])
                            elseif typeof(v[1]) == "table" then
                                newConfig[i] = v[1]
                            end
                        elseif tostring(v):find("Enum.KeyCode.") then
                            newConfig[i] = Enum.KeyCode[tostring(v):gsub("Enum.KeyCode.", "")]
                        else
                            newConfig[i] = v
                        end
                    end

                    library.flags = newConfig

                    for i, v in pairs(library.flags) do
                        for _, item in ipairs(library.items) do
                            if i ~= nil and i ~= "" and i ~= "Configs_Name" and i ~= "Configs" and item.flag ~= nil then
                                if item.flag == i then
                                    pcall(function()
                                        item:Set(v)
                                    end)
                                end
                            end
                        end
                    end
                end
            end)

            configSystem.sector:AddButton("Delete", function()
                for _, v in ipairs(listfiles(configSystem.configFolder)) do
                    configDropdown:Remove(v:gsub(configSystem.configFolder .. "\\", ""):gsub(".txt", ""))
                end

                local name = configDropdown:Get()
                if not name or name == "" then return end
                if not isfile(configSystem.configFolder .. "/" .. name .. ".txt") then return end

                delfile(configSystem.configFolder .. "/" .. name .. ".txt")

                for _, v in ipairs(listfiles(configSystem.configFolder)) do
                    if v:find(".txt") then
                        configDropdown:Add(v:gsub(configSystem.configFolder .. "\\", ""):gsub(".txt", ""))
                    end
                end
            end)

            return configSystem
        end

        table.insert(window.Tabs, tab)
        return tab
    end

    return window
end

return library
