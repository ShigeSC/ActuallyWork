--[[
    UILibrary.lua
    A lightweight Roblox GUI library with:
      - Tabbed window
      - Buttons
      - Toggles (on/off switches)
      - Sliders

    USAGE:
    Put this as a LocalScript in StarterPlayerScripts (or require it as a
    ModuleScript — see note at the bottom). Running it as-is will build a
    demo window so you can see everything working immediately.
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

function Library.new(title)
	local self = setmetatable({}, Library)

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

	self.Main = create("Frame", {
		Name = "Main",
		Size = UDim2.new(0, 480, 0, 340),
		Position = UDim2.new(0.5, -240, 0.5, -170),
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		BorderSizePixel = 0,
		Parent = self.ScreenGui,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Main })

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
		BackgroundColor3 = Color3.fromRGB(70, 120, 240),
		AutoButtonColor = false,
		Visible = false,
		Image = "",
		Parent = self.ScreenGui,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self.Bubble })
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
	self.Bubble.Size = UDim2.new(0, 0, 0, 0)
	tween(self.Bubble, { Size = UDim2.new(0, 50, 0, 50) }, 0.2)
end

function Library:Restore()
	self.Bubble.Visible = false
	self.Main.Visible = true
	self.Main.Size = UDim2.new(0, 0, 0, 0)
	tween(self.Main, { Size = UDim2.new(0, 480, 0, 340) }, 0.2)
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
			BackgroundColor3 = isActive and Color3.fromRGB(70, 120, 240) or Color3.fromRGB(24, 24, 29),
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
			tween(btn, { BackgroundColor3 = Color3.fromRGB(70, 120, 240) }, 0.08)
			task.wait(0.08)
			tween(btn, { BackgroundColor3 = Color3.fromRGB(45, 45, 54) }, 0.15)
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
			BackgroundColor3 = state and Color3.fromRGB(70, 200, 120) or Color3.fromRGB(70, 70, 80),
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
			tween(switchBG, { BackgroundColor3 = state and Color3.fromRGB(70, 200, 120) or Color3.fromRGB(70, 70, 80) }, 0.15)
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
			BackgroundColor3 = Color3.fromRGB(70, 120, 240),
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

	return api
end

-- ============================================================
-- Demo (runs automatically if this script is executed directly
-- as a LocalScript). Delete this section if you only want the
-- library and plan to require() it from elsewhere.
-- ============================================================

local window = Library.new("Demo Window")

local mainTab = window:AddTab("Main")
mainTab:AddButton("Print Hello", function()
	print("Hello from the UI library!")
end)
mainTab:AddToggle("Enable Feature", false, function(state)
	print("Feature enabled:", state)
end)
mainTab:AddSlider("Walk Speed", 16, 100, 16, function(value)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = value
	end
end)

local settingsTab = window:AddTab("Settings")
settingsTab:AddToggle("Show FPS Counter", true, function(state)
	print("FPS counter:", state)
end)
settingsTab:AddSlider("Field of View", 70, 120, 90, function(value)
	workspace.CurrentCamera.FieldOfView = value
end)

return Library
