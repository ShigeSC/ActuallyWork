--[[
    UILibrary.lua
    A lightweight Roblox GUI library with:
      - Tabbed window with a title bar (minimize / close)
      - Minimizes to a draggable circle bubble; click the bubble to restore
      - Global keybind to fully show/hide the GUI (default: Right Control)
      - Toast-style notifications (Library:Notify)
      - Elements: Button, Toggle (on/off), Slider, Dropdown, Textbox, Label
      - Customizable accent color
      - Smooth open/close/minimize animations

    USAGE:
    Put this as a LocalScript in StarterPlayerScripts (or require it as a
    ModuleScript — see note at the bottom). Running it as-is will build a
    demo window so you can see everything working immediately.

    local window = Library.new("My Window", {
        AccentColor = Color3.fromRGB(70, 120, 240), -- optional
        ToggleKey = Enum.KeyCode.RightControl,      -- optional
    })

    local tab = window:AddTab("Main")
    tab:AddButton("Do Thing", function() end)
    tab:AddToggle("Enabled", false, function(state) end)
    tab:AddSlider("Speed", 0, 100, 50, function(value) end)
    tab:AddDropdown("Mode", {"Easy", "Normal", "Hard"}, "Normal", function(choice) end)
    tab:AddTextbox("Username", "type here...", function(text) end)
    tab:AddLabel("Section Header")

    window:Notify("Title", "Some message", 3) -- duration in seconds
--]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Library = {}
Library.__index = Library

-- ============================================================
-- Helpers
-- ============================================================

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

-- ============================================================
-- Window
-- ============================================================

function Library.new(title, options)
	options = options or {}
	local self = setmetatable({}, Library)

	self.Accent = options.AccentColor or Color3.fromRGB(70, 120, 240)
	self.ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl

	-- Remove any previous instance of this GUI so re-running the script doesn't stack windows
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

	-- Notification stack, top-right of the screen
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
	-- Used to animate open/minimize/restore by scaling uniformly, instead of resizing
	-- the Frame directly (which would distort the scale-based child layout mid-tween).
	self.MainScale = create("UIScale", { Scale = 1, Parent = self.Main })

	-- Title bar (also used to drag the window)
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

	-- Minimize ( - ) and Close ( X ) buttons, top-right of the title bar
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

	-- Floating circle bubble, shown when the window is minimized.
	-- Dragging it moves it; clicking it (without dragging) restores the window.
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

	-- Global keybind: fully show/hide everything (window AND bubble), regardless of minimized state
	local UIS = game:GetService("UserInputService")
	self._visible = true
	UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == self.ToggleKey then
			self._visible = not self._visible
			self.ScreenGui.Enabled = self._visible
		end
	end)

	-- Tab bar (left column)
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

	-- Content area (right side, one Frame per tab)
	self.Content = create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -120, 1, -36),
		Position = UDim2.new(0, 120, 0, 36),
		BackgroundTransparency = 1,
		Parent = self.Main,
	})

	self.Tabs = {}
	self.ActiveTab = nil

	-- No entrance animation — shows instantly to avoid any layout distortion
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
					-- Only restore the window if the bubble wasn't dragged (i.e. it was a click)
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

	-- Slide/fade in from the right
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

-- ============================================================
-- Tabs
-- ============================================================

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

	-- First tab added becomes active by default
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

-- ============================================================
-- Elements (Button / Toggle / Slider) — attached to a tab's page
-- ============================================================

function Library:_wrapPage(page)
	local api = {}
	local library = self -- capture so nested `api:Method` functions can still reach Library.Accent etc.

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

		local list = create("Frame", {
			Size = UDim2.new(0.6, -12, 0, #options * 26),
			Position = UDim2.new(0.4, 0, 1, 2),
			BackgroundColor3 = Color3.fromRGB(30, 30, 36),
			Visible = false,
			ZIndex = 10,
			Parent = holder,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = list })
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

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

		for _, opt in ipairs(options) do
			local optBtn = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
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
		end

		selectorBtn.MouseButton1Click:Connect(function()
			open = not open
			list.Visible = open
		end)

		return {
			Set = select,
			Get = function() return selected end,
		}
	end

	function api:AddMultiDropdown(text, options, defaultSelected, callback)
		options = options or {}
		local selected = {} -- option -> true/nil
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

-- ============================================================
-- Demo (runs automatically if this script is executed directly
-- as a LocalScript). Delete this section if you only want the
-- library and plan to require() it from elsewhere.
-- ============================================================

local window = Library.new("Demo Window", {
	AccentColor = Color3.fromRGB(70, 120, 240),
	ToggleKey = Enum.KeyCode.RightControl,
})

local seedsTab = window:AddTab("🌱 Seeds")
seedsTab:AddLabel("🌱 Auto Plant")
seedsTab:AddToggle("Auto Plant Seeds", false, function(state)
	print("Auto plant:", state)
end)
seedsTab:AddMultiDropdown("Seed Type", { "Wheat", "Carrot", "Pumpkin", "Tomato", "Strawberry", "Corn", "Potato" }, { "Wheat" }, function(choices)
	window:Notify("Seeds Selected", table.concat(choices, ", "), 2.5)
end)
seedsTab:AddSlider("Plant Interval (s)", 1, 30, 5, function(value)
	print("Interval set to", value)
end)

local gearTab = window:AddTab("⚙️ Gear")
gearTab:AddLabel("⚙️ Equipment")
gearTab:AddButton("Equip Best Gear", function()
	window:Notify("Gear Equipped", "Switched to your strongest loadout.", 2.5)
end)
gearTab:AddToggle("Auto Upgrade Gear", true, function(state)
	print("Auto upgrade:", state)
end)
gearTab:AddSlider("Gear Tier Priority", 1, 5, 3, function(value)
	print("Priority tier:", value)
end)

local cratesTab = window:AddTab("📦 Crates")
cratesTab:AddLabel("📦 Rewards")
cratesTab:AddButton("Open Crate", function()
	window:Notify("Crate Opened", "You received a reward!", 2.5)
end)
cratesTab:AddToggle("Auto Open Crates", false, function(state)
	print("Auto open crates:", state)
end)
cratesTab:AddTextbox("Crate Key", "paste key here...", function(text)
	print("Key submitted:", text)
end)

window:Notify("Welcome", "Press Right Control to hide/show this GUI.", 4)

return Library
