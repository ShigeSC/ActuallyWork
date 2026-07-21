-- ============================================
-- UILibrary (Complete) - Paste this at the top
-- ============================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Library = {}
Library.__index = Library

local function create(className, props)
    local inst = Instance.new(className)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    return inst
end

local function tween(inst, props, duration)
    TweenService:Create(inst, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), props):Play()
end

function Library.new(title, options)
    options = options or {}
    local self = setmetatable({}, Library)

    self.Accent = options.AccentColor or Color3.fromRGB(70, 120, 240)
    self.ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl

    local existing = playerGui:FindFirstChild("SimpleUILibrary")
    if existing then
        existing:Destroy()
    end

    self.ScreenGui = create("ScreenGui", {
        Name = "SimpleUILibrary",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui,
    })

    self.NotifyHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 260, 1, -32),
        BackgroundTransparency = 1,
        Parent = self.ScreenGui,
    })
    create("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.NotifyHolder,
    })

    self.Main = create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 480, 0, 340),
        Position = UDim2.new(0.5, -240, 0.5, -170),
        BackgroundColor3 = Color3.fromRGB(30, 30, 36),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ScreenGui,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Main })
    create("UIStroke", {
        Color = self.Accent,
        Transparency = 0.6,
        Thickness = 1,
        Parent = self.Main,
    })
    self.MainScale = create("UIScale", { Scale = 1, Parent = self.Main })

    self.TitleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(22, 22, 27),
        BorderSizePixel = 0,
        Parent = self.Main,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.TitleBar })

    create("TextLabel", {
        Text = title or "Window",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar,
    })

    local closeBtn = create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -34, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(22, 22, 27),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        AutoButtonColor = false,
        Parent = self.TitleBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = closeBtn })

    local minimizeBtn = create("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -66, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(22, 22, 27),
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        AutoButtonColor = false,
        Parent = self.TitleBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = minimizeBtn })

    for _, btn in ipairs({ closeBtn, minimizeBtn }) do
        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = Color3.fromRGB(45, 45, 54) }, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = Color3.fromRGB(22, 22, 27) }, 0.12)
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        self.ScreenGui.Enabled = false
    end)
    minimizeBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)

    self:_makeDraggable(self.TitleBar, self.Main)

    self.Bubble = create("ImageButton", {
        Name = "Bubble",
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = self.Accent,
        AutoButtonColor = false,
        Visible = false,
        Image = "",
        Parent = self.ScreenGui,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self.Bubble })
    create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1, Parent = self.Bubble })
    create("TextLabel", {
        Text = "≡",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.Bubble,
    })

    self:_makeDraggableBubble(self.Bubble)

    local UIS = game:GetService("UserInputService")
    self._visible = true
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self.ToggleKey then
            self._visible = not self._visible
            self.ScreenGui.Enabled = self._visible
        end
    end)

    self.TabBar = create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(0, 120, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(24, 24, 29),
        BorderSizePixel = 0,
        Parent = self.Main,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.TabBar })

    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabBar,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = self.TabBar,
    })

    self.Content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -120, 1, -36),
        Position = UDim2.new(0, 120, 0, 36),
        BackgroundTransparency = 1,
        Parent = self.Main,
    })

    self.Tabs = {}
    self.ActiveTab = nil

    self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)

    return self
end

function Library:_makeDraggable(handle, target)
    local dragging, dragStart, startPos
    local UIS = game:GetService("UserInputService")

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Library:_makeDraggableBubble(bubble)
    local UIS = game:GetService("UserInputService")
    local dragging = false
    local dragStart, startPos
    local moved = false

    bubble.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = bubble.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved then
                        self:Restore()
                    end
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 4 then
                moved = true
            end
            bubble.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Library:Minimize()
    self.Main.Visible = false
    self.Bubble.Visible = true
end

function Library:Restore()
    self.Bubble.Visible = false
    self.Main.Visible = true
end

function Library:Notify(title, text, duration)
    duration = duration or 3
    self._notifyCount = (self._notifyCount or 0) + 1

    local note = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(30, 30, 36),
        ClipsDescendants = true,
        LayoutOrder = self._notifyCount,
        Parent = self.NotifyHolder,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = note })
    create("UIStroke", { Color = self.Accent, Transparency = 0.5, Thickness = 1, Parent = note })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        Parent = note,
    })
    local layout = create("UIListLayout", { Padding = UDim.new(0, 2), Parent = note })

    create("TextLabel", {
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = note,
    })
    create("TextLabel", {
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = note,
    })

    note.Position = UDim2.new(0, 40, 0, 0)
    note.BackgroundTransparency = 1
    tween(note, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.2)

    task.delay(duration, function()
        if note and note.Parent then
            tween(note, { Position = UDim2.new(0, 40, 0, 0), BackgroundTransparency = 1 }, 0.2)
            task.wait(0.2)
            note:Destroy()
        end
    end)
end

function Library:AddTab(name)
    local tabButton = create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(24, 24, 29),
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextScaled = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        AutoButtonColor = false,
        Parent = self.TabBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabButton })

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Content,
    })
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page,
    })

    local tab = { Button = tabButton, Page = page }
    self.Tabs[name] = tab

    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    if not self.ActiveTab then
        self:SelectTab(name)
    end

    return self:_wrapPage(page)
end

function Library:SelectTab(name)
    for tabName, tab in pairs(self.Tabs) do
        local isActive = tabName == name
        tab.Page.Visible = isActive
        tween(tab.Button, {
            BackgroundColor3 = isActive and self.Accent or Color3.fromRGB(24, 24, 29),
            TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
        }, 0.15)
    end
    self.ActiveTab = name
end

function Library:_wrapPage(page)
    local api = {}
    local library = self

    function api:AddButton(text, callback)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(45, 45, 54),
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            AutoButtonColor = false,
            Parent = page,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = Color3.fromRGB(58, 58, 70) }, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = Color3.fromRGB(45, 45, 54) }, 0.12)
        end)
        btn.MouseButton1Click:Connect(function()
            tween(btn, { BackgroundColor3 = Color3.fromRGB(60, 60, 72) }, 0.06)
            task.delay(0.06, function()
                tween(btn, { BackgroundColor3 = Color3.fromRGB(45, 45, 54) }, 0.1)
            end)
            if callback then callback() end
        end)

        return btn
    end

    function api:AddToggle(text, default, callback)
        local state = default or false

        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(45, 45, 54),
            Parent = page,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = holder })

        create("TextLabel", {
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(230, 230, 230),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })

        local switchBG = create("Frame", {
            Size = UDim2.new(0, 40, 0, 20),
            Position = UDim2.new(1, -50, 0.5, -10),
            BackgroundColor3 = state and library.Accent or Color3.fromRGB(70, 70, 80),
            Parent = holder,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchBG })

        local knob = create("Frame", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = switchBG,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

        local clickCatcher = create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = holder,
        })

        local function set(newState)
            state = newState
            tween(switchBG, { BackgroundColor3 = state and library.Accent or Color3.fromRGB(70, 70, 80) }, 0.15)
            tween(knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
            if callback then callback(state) end
        end

        clickCatcher.MouseButton1Click:Connect(function()
            set(not state)
        end)

        return {
            Set = set,
            Get = function() return state end,
        }
    end

    function api:AddSlider(text, min, max, default, callback)
        min = min or 0
        max = max or 100
        local value = math.clamp(default or min, min, max)

        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = Color3.fromRGB(45, 45, 54),
            Parent = page,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = holder })

        local label = create("TextLabel", {
            Text = text .. ": " .. tostring(value),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(230, 230, 230),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 20),
            Position = UDim2.new(0, 12, 0, 2),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })

        local track = create("Frame", {
            Size = UDim2.new(1, -24, 0, 6),
            Position = UDim2.new(0, 12, 1, -16),
            BackgroundColor3 = Color3.fromRGB(70, 70, 80),
            Parent = holder,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

        local function ratioFor(v)
            return (v - min) / (max - min)
        end

        local fill = create("Frame", {
            Size = UDim2.new(ratioFor(value), 0, 1, 0),
            BackgroundColor3 = library.Accent,
            Parent = track,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

        local knob = create("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(ratioFor(value), 0, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 2,
            Parent = track,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

        local UIS = game:GetService("UserInputService")
        local dragging = false

        local function updateFromX(xPos)
            local relative = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + relative * (max - min) + 0.5)
            fill.Size = UDim2.new(relative, 0, 1, 0)
            knob.Position = UDim2.new(relative, 0, 0.5, 0)
            label.Text = text .. ": " .. tostring(value)
            if callback then callback(value) end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromX(input.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromX(input.Position.X)
            end
        end)

        return {
            Set = function(v)
                value = math.clamp(v, min, max)
                local r = ratioFor(value)
                fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, 0, 0.5, 0)
                label.Text = text .. ": " .. tostring(value)
            end,
            Get = function() return value end,
        }
    end

    function api:AddLabel(text)
        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = page,
        })
        create("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = library.Accent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, -8),
            Position = UDim2.new(0, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = Color3.fromRGB(55, 55, 65),
            BorderSizePixel = 0,
            Parent = holder,
        })
        return holder
    end

    function api:AddTextbox(text, placeholder, callback)
        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(45, 45, 54),
            Parent = page,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = holder })

        create("TextLabel", {
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = 1,
            Size = UDim2.new(0.4, -8, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })

        local box = create("TextBox", {
            Size = UDim2.new(0.6, -12, 0, 24),
            Position = UDim2.new(0.4, 0, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(30, 30, 36),
            Text = "",
            PlaceholderText = placeholder or "",
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            PlaceholderColor3 = Color3.fromRGB(130, 130, 140),
            ClearTextOnFocus = false,
            Parent = holder,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = box })
        create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })

        box.FocusLost:Connect(function(enterPressed)
            if callback then callback(box.Text, enterPressed) end
        end)

        return {
            Set = function(v) box.Text = v end,
            Get = function() return box.Text end,
        }
    end

    function api:AddDropdown(text, options, default, callback)
    options = options or {}
    local selected = default or options[1]
    local open = false

    local holder = create("Frame", {
        Name = text .. "Holder",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Color3.fromRGB(45, 45, 54),
        ClipsDescendants = false,
        ZIndex = 5,
        Parent = page,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = holder })

    create("TextLabel", {
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, -8, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = holder,
    })

    local selectorBtn = create("TextButton", {
        Size = UDim2.new(0.6, -12, 0, 24),
        Position = UDim2.new(0.4, 0, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(30, 30, 36),
        Text = tostring(selected) .. "  ▾",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = holder,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = selectorBtn })

    local maxVisible = 5
    local itemHeight = 26
    local listHeight = math.min(#options, maxVisible) * itemHeight
    
    local list = create("ScrollingFrame", {
        Size = UDim2.new(0.6, -12, 0, listHeight),
        Position = UDim2.new(0.4, 0, 1, 2),
        BackgroundColor3 = Color3.fromRGB(30, 30, 36),
        Visible = false,
        ZIndex = 10,
        Parent = holder,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, #options * itemHeight),
        BorderSizePixel = 0,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = list })
    
    local listLayout = create("UIListLayout", { 
        SortOrder = Enum.SortOrder.LayoutOrder, 
        Parent = list 
    })

    local optionButtons = {}

    local function close()
        open = false
        list.Visible = false
    end

    local function select(opt)
        selected = opt
        selectorBtn.Text = tostring(opt) .. "  ▾"
        close()
        if callback then callback(opt) end
    end

    local function buildOptions(newOptions)
        -- Clear old options
        for _, btn in pairs(optionButtons) do
            btn:Destroy()
        end
        optionButtons = {}
        
        -- Update canvas size
        list.CanvasSize = UDim2.new(0, 0, 0, #newOptions * itemHeight)
        list.Size = UDim2.new(0.6, -12, 0, math.min(#newOptions, maxVisible) * itemHeight)
        
        -- Create new option buttons
        for i, opt in ipairs(newOptions) do
            local optBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, itemHeight),
                BackgroundColor3 = Color3.fromRGB(30, 30, 36),
                Text = tostring(opt),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(230, 230, 230),
                AutoButtonColor = false,
                ZIndex = 10,
                Parent = list,
            })
            optBtn.MouseEnter:Connect(function()
                tween(optBtn, { BackgroundColor3 = Color3.fromRGB(45, 45, 54) }, 0.1)
            end)
            optBtn.MouseLeave:Connect(function()
                tween(optBtn, { BackgroundColor3 = Color3.fromRGB(30, 30, 36) }, 0.1)
            end)
            optBtn.MouseButton1Click:Connect(function()
                select(opt)
            end)
            table.insert(optionButtons, optBtn)
        end
    end

    -- Build initial options
    buildOptions(options)

    selectorBtn.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
    end)

    return {
        Set = select,
        Get = function() return selected end,
        Holder = holder,
        Refresh = function(newOptions)
    options = newOptions
    -- Reset selection if current selection not in new list
    local found = false
    for _, opt in ipairs(newOptions) do
        if opt == selected then found = true break end
    end
    if not found and #newOptions > 0 then
        selected = newOptions[1] -- or nil to show nothing
        selectorBtn.Text = tostring(selected) .. "  ▾"
    end
    buildOptions(newOptions)
end,
    }
end

    function api:AddMultiDropdown(text, options, defaultSelected, callback)
        options = options or {}
        local selected = {}
        for _, opt in ipairs(defaultSelected or {}) do
            selected[opt] = true
        end
        local open = false

        local function selectedList()
            local list = {}
            for _, opt in ipairs(options) do
                if selected[opt] then table.insert(list, opt) end
            end
            return list
        end

        local function summaryText()
            local list = selectedList()
            if #list == 0 then return "Select...  ▾" end
            if #list <= 2 then return table.concat(list, ", ") .. "  ▾" end
            return #list .. " selected  ▾"
        end

        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(45, 45, 54),
            ClipsDescendants = false,
            ZIndex = 5,
            Parent = page,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = holder })

        create("TextLabel", {
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = 1,
            Size = UDim2.new(0.4, -8, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = holder,
        })

        local selectorBtn = create("TextButton", {
            Size = UDim2.new(0.6, -12, 0, 24),
            Position = UDim2.new(0.4, 0, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(30, 30, 36),
            Text = summaryText(),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            AutoButtonColor = false,
            ZIndex = 5,
            Parent = holder,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = selectorBtn })
        create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = selectorBtn })

        local listHeight = math.min(#options, 5) * 26
        local panel = create("Frame", {
            Size = UDim2.new(0.6, -12, 0, 30 + listHeight + 6),
            Position = UDim2.new(0.4, 0, 1, 2),
            BackgroundColor3 = Color3.fromRGB(30, 30, 36),
            Visible = false,
            ZIndex = 10,
            Parent = holder,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = panel })
        create("UIPadding", {
            PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            Parent = panel,
        })

        local searchBox = create("TextBox", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = Color3.fromRGB(45, 45, 54),
            Text = "",
            PlaceholderText = "Search...",
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            PlaceholderColor3 = Color3.fromRGB(130, 130, 140),
            ClearTextOnFocus = false,
            ZIndex = 11,
            Parent = panel,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = searchBox })
        create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = searchBox })

        local scroll = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, listHeight),
            Position = UDim2.new(0, 0, 0, 28),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 11,
            Parent = panel,
        })
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

        local rows = {}

        local function refreshRow(opt)
            local row = rows[opt]
            row.Check.BackgroundColor3 = selected[opt] and library.Accent or Color3.fromRGB(45, 45, 54)
            row.Check.Text = selected[opt] and "✓" or ""
        end

        for _, opt in ipairs(options) do
            local row = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = Color3.fromRGB(30, 30, 36),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 11,
                Parent = scroll,
            })

            local check = create("TextLabel", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 4, 0.5, -8),
                BackgroundColor3 = selected[opt] and library.Accent or Color3.fromRGB(45, 45, 54),
                Text = selected[opt] and "✓" or "",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 11,
                Parent = row,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = check })

            create("TextLabel", {
                Text = tostring(opt),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(230, 230, 230),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 26, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = row,
            })

            row.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = Color3.fromRGB(40, 40, 48) }, 0.1)
            end)
            row.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = Color3.fromRGB(30, 30, 36) }, 0.1)
            end)
            row.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt] or nil
                refreshRow(opt)
                selectorBtn.Text = summaryText()
                if callback then callback(selectedList()) end
            end)

            rows[opt] = { Row = row, Check = check }
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = searchBox.Text:lower()
            for _, opt in ipairs(options) do
                local row = rows[opt].Row
                row.Visible = query == "" or tostring(opt):lower():find(query, 1, true) ~= nil
            end
        end)

        selectorBtn.MouseButton1Click:Connect(function()
            open = not open
            panel.Visible = open
            if open then
                searchBox.Text = ""
                for _, opt in ipairs(options) do
                    rows[opt].Row.Visible = true
                end
            end
        end)

        return {
            Set = function(list)
                selected = {}
                for _, opt in ipairs(list) do selected[opt] = true end
                for _, opt in ipairs(options) do refreshRow(opt) end
                selectorBtn.Text = summaryText()
            end,
            Get = selectedList,
        }
    end

    return api
end

-- ============================================
-- YOUR SCRIPT STARTS HERE
-- ============================================

-- Initialize Window
local Window = Library.new("SHOP by @boo10001", {
    AccentColor = Color3.fromRGB(0, 170, 0),
    ToggleKey = Enum.KeyCode.N,
})

-- Force mouse icon
game:GetService("UserInputService").OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
game:GetService("UserInputService").MouseIconEnabled = true

task.spawn(function()
    while true do
        game:GetService("UserInputService").OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
        game:GetService("UserInputService").MouseIconEnabled = true
        task.wait(0.1)
    end
end)

-- ==================== ANTI AFK ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer

print("✅ [Anti-AFK] Script started")

local function disableIdleConnections()
    local count = 0
    pcall(function()
        for _, connection in ipairs(getconnections(player.Idled)) do
            connection:Disable()
            count += 1
        end
    end)
    if count > 0 then
        print("✅ [Anti-AFK] Disabled " .. count .. " idle connections")
    end
end

disableIdleConnections()

RunService.Heartbeat:Connect(function()
    if tick() % 25 < 1 then
        disableIdleConnections()
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.12)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                hum:Move(Vector3.new(0, 0, 0.1))
                hum.Jump = true
                task.wait(0.4)
                hum.Jump = false
            end
        end)
        print("✅ [Anti-AFK] Sent input (Space + Jump)")
        task.wait(40)
    end
end)

print("✅ [Anti-AFK] Fully loaded and protecting you")
-- =======================================================================

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
local SeedsTab = Window:AddTab("🌱 Seeds")

SeedsTab:AddLabel("🌱 Auto Plant")

seedDropdown = SeedsTab:AddMultiDropdown("Seed Type", {
    "Acorn", "Apple", "Bamboo", "Banana", "Blueberry", "Cactus", "Carrot", "Cherry",
    "Coconut", "Corn", "Dragon Fruit", "Dragon's Breath", "Fire Fern", "Grape",
    "Green Bean", "Hypno Bloom", "Mango", "Moon Bloom", "Mushroom", "Padding",
    "Pineapple", "Poison Apple", "Pomegranate", "Pudding", "Rocket Pop", "Star Fruit",
    "Strawberry", "Sun Bloom", "Sunflower", "Tomato", "Tulip", "Venom Spitter",
    "Venus Fly Trap"
}, selectedSeeds, function(choices)
    selectedSeeds = choices
    Window:Notify("Seeds Selected", table.concat(choices, ", "), 2.5)
end)

seedSelectedToggle = SeedsTab:AddToggle("Auto Buy Selected", autoBuySelectedSeeds, function(state)
    autoBuySelectedSeeds = state
end)

seedAllToggle = SeedsTab:AddToggle("Auto Buy All Seeds", autoBuyAllSeeds, function(state)
    autoBuyAllSeeds = state
end)

SeedsTab:AddSlider("Plant Interval (s)", 1, 30, 5, function(value)
    print("Interval set to", value)
end)

-- ==================== GEAR TAB ====================
local GearTab = Window:AddTab("⚙️ Gear")

GearTab:AddLabel("⚙️ Equipment")

gearDropdown = GearTab:AddMultiDropdown("Select Gear", {
    "Common Watering Can", "Common Sprinkler", "Sign", "Megaphone",
    "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler",
    "Trowel", "Speed Mushroom", "Jump Mushroom", "Gnome",
    "Shrink Mushroom", "Supersize Mushroom", "Wheelbarrow", "Strawberry Sniper",
    "Invisibility Mushroom", "Teleporter", "Legendary Pet Teleporter",
    "Mythic Pet Teleporter", "Super Pet Teleporter", "Super Watering Can",
    "Basic Pot", "Flashbang", "Player Magnet"
}, selectedGears, function(choices)
    selectedGears = choices
end)

gearSelectedToggle = GearTab:AddToggle("Auto Buy Selected", autoBuySelectedGears, function(state)
    autoBuySelectedGears = state
end)

gearAllToggle = GearTab:AddToggle("Auto Buy All Gears", autoBuyAllGears, function(state)
    autoBuyAllGears = state
end)

GearTab:AddSlider("Gear Tier Priority", 1, 5, 3, function(value)
    print("Priority tier:", value)
end)

-- ==================== CRATE TAB ====================
local CrateTab = Window:AddTab("📦 Crates")

CrateTab:AddLabel("📦 Rewards")

crateDropdown = CrateTab:AddMultiDropdown("Select Crate", {
    "Arch Crate", "Bear Trap Crate", "Bench Crate", "Boombox Crate",
    "Bridge Crate", "Conveyor Crate", "Fence Crate", "Fourth Of July Crate",
    "Ladder Crate", "Light Crate", "Owner Door Crate", "Picture Frame Crate",
    "Roleplay Crate", "Seesaw Crate", "Sign Crate", "Spring Crate",
    "Teleporter Pad Crate", "Weather Machine Crate", "Wood Wall Crate"
}, selectedCrates, function(choices)
    selectedCrates = choices
end)

crateSelectedToggle = CrateTab:AddToggle("Auto Buy Selected", autoBuySelectedCrates, function(state)
    autoBuySelectedCrates = state
end)

crateAllToggle = CrateTab:AddToggle("Auto Buy All Crates", autoBuyAllCrates, function(state)
    autoBuyAllCrates = state
end)

CrateTab:AddTextbox("Crate Key", "paste key here...", function(text)
    print("Key submitted:", text)
end)

-- ==================== LOW CPU TAB ====================
local CleanupTab = Window:AddTab("Low CPU")

CleanupTab:AddLabel("Performance")

CleanupTab:AddButton("Cleanup + 15 FPS", function()
    cleanupEnabled = true
    fpsCap = 15
    applyLowCPU()
    Window:Notify("Performance", "Cleanup + 15 FPS activated", 3)
end)

CleanupTab:AddButton("FPS Cap 30", function()
    fpsCap = 30
    local setfpscap = setfpscap or function() end
    setfpscap(30)
    Window:Notify("FPS", "Capped at 30", 2)
end)

CleanupTab:AddButton("FPS Cap 60", function()
    fpsCap = 60
    local setfpscap = setfpscap or function() end
    setfpscap(60)
    Window:Notify("FPS", "Capped at 60", 2)
end)

CleanupTab:AddButton("Remove FPS Cap", function()
    fpsCap = 0
    local setfpscap = setfpscap or function() end
    setfpscap(0)
    Window:Notify("FPS", "Cap removed", 2)
end)

-- ==================== CONFIGS TAB ====================
local ConfigTab = Window:AddTab("Configs")

ConfigTab:AddLabel("Config Manager")

local configNameTextbox = ConfigTab:AddTextbox("Config Name", currentConfigName, function(text)
    currentConfigName = text
end)

local configOptions = getConfigList()
local selectedConfigName = currentConfigName

-- This line should already exist - make sure it uses configDropdownObj:
configDropdownObj = ConfigTab:AddDropdown("Choose Config", configOptions, currentConfigName, function(choice)
    selectedConfigName = choice
    if choice and choice ~= "" then
        loadConfig(choice)
        writefile(CONFIG_FOLDER .. "/last.txt", choice)
    end
end)

ConfigTab:AddButton("Save Config", function()
    saveConfig(currentConfigName)
    Window:Notify("Config Saved", "Config saved as: " .. currentConfigName, 3)
end)

ConfigTab:AddButton("Load Config", function()
    if selectedConfigName and selectedConfigName ~= "" then
        loadConfig(selectedConfigName)
    else
        loadConfig(currentConfigName)
    end
end)

ConfigTab:AddButton("Delete Config", function()
    local nameToDelete = selectedConfigName or currentConfigName
    if nameToDelete and nameToDelete ~= "" then
        local path = CONFIG_FOLDER .. "/" .. nameToDelete .. ".json"
        if isfile(path) then
            delfile(path)
            Window:Notify("Config Deleted", "Deleted: " .. nameToDelete, 2)
        end
    end
end)

ConfigTab:AddButton("Refresh Config List", function()
    local newList = getConfigList()
    
    -- Just refresh the existing dropdown, don't destroy it
    if configDropdownObj and configDropdownObj.Refresh then
        configDropdownObj.Refresh(newList)
    end
    
    Window:Notify("Config List", "Refreshed! Found " .. #newList .. " config(s).", 2)
end)

-- ==================== CONTROLS (in Seeds Tab) ====================
SeedsTab:AddLabel("Controls")

SeedsTab:AddButton("X Destroy", function()
    Window.ScreenGui:Destroy()
    print("GUI destroyed")
end)

SeedsTab:AddButton("- Hide", function()
    Window:Minimize()
end)

SeedsTab:AddButton("Show", function()
    Window:Restore()
end)

-- ==================== STRONG MUTE ====================
task.spawn(function()
    while true do
        local anyAutoBuy = autoBuySelectedSeeds or autoBuyAllSeeds or 
                           autoBuySelectedGears or autoBuyAllGears or 
                           autoBuySelectedCrates or autoBuyAllCrates

        if anyAutoBuy then
            pcall(function()
                SoundService.Volume = 0
                for _, s in pairs(SoundService:GetDescendants()) do
                    if s:IsA("Sound") then
                        s.Volume = 0
                        s.Playing = false
                    end
                end
                for _, s in pairs(workspace:GetDescendants()) do
                    if s:IsA("Sound") then
                        s.Volume = 0
                        s.Playing = false
                    end
                end
            end)
        else
            pcall(function()
                SoundService.Volume = 1
            end)
        end
        task.wait(0.1)
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
            local allSeeds = {
                "Acorn", "Apple", "Bamboo", "Banana", "Blueberry", "Cactus", "Carrot", "Cherry",
                "Coconut", "Corn", "Dragon Fruit", "Dragon's Breath", "Fire Fern", "Grape",
                "Green Bean", "Hypno Bloom", "Mango", "Moon Bloom", "Mushroom", "Padding",
                "Pineapple", "Poison Apple", "Pomegranate", "Pudding", "Rocket Pop", "Star Fruit",
                "Strawberry", "Sun Bloom", "Sunflower", "Tomato", "Tulip", "Venom Spitter",
                "Venus Fly Trap"
            }
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

Window:Notify("Welcome", "Press N to hide/show this GUI. Use - button to minimize.", 4)
print("SHOP by @boo10001 loaded with UILibrary")
