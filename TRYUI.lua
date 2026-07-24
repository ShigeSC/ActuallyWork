--[[
	MailBypassUI
	A standalone Lua UI library (no dependency on any other UI kit) that recreates
	the "Mail Bypass" style interface:
	  - Top bar: title, subtitle, stats pill, minimize/close
	  - Horizontal tab bar (Mail / Mail Fruits / Incoming Mails / Trade History / Settings / Tutorial)
	  - Recipient panel (Single/Multi toggle, username input, resolved user card)
	  - Add Item To Queue panel (searchable dropdown, quantity input, +Add, auto-accept toggle)
	  - Queue panel (list + Send Batch button)
	  - Bottom Discord banner

	This file only builds the UI and exposes hook points (callbacks) for your
	actual game logic — resolving a player, listing items, and sending mail —
	since those depend on your specific game's remotes/APIs.

	USAGE EXAMPLE (bottom of this file has a full example, search "EXAMPLE USAGE").
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- =========================================================
-- THEME
-- =========================================================
local Theme = {
	Bg = Color3.fromRGB(11, 13, 20),
	Panel = Color3.fromRGB(17, 20, 30),
	PanelBorder = Color3.fromRGB(35, 42, 63),
	Field = Color3.fromRGB(22, 26, 38),
	Accent = Color3.fromRGB(59, 125, 235),
	AccentDim = Color3.fromRGB(40, 70, 130),
	AccentSoft = Color3.fromRGB(30, 45, 75),
	Text = Color3.fromRGB(235, 237, 245),
	Muted = Color3.fromRGB(150, 155, 172),
	Good = Color3.fromRGB(88, 214, 141),
	Font = Enum.Font.GothamBold,
	FontBody = Enum.Font.Gotham,
}

-- =========================================================
-- UTILITIES
-- =========================================================
local function Create(className, props, parent)
	local inst = Instance.new(className)
	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function SafeTween(obj, info, props)
	local ok, tween = pcall(function()
		return TweenService:Create(obj, info, props)
	end)
	if ok and tween then
		pcall(function() tween:Play() end)
	end
end

local function MakeDraggable(dragHandle, target)
	local dragging, dragStart, startPos = false, nil, nil

	dragHandle.InputBegan:Connect(function(input)
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

	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function GetGuiParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then return hui end
	return Player:WaitForChild("PlayerGui")
end

-- =========================================================
-- LIBRARY
-- =========================================================
local MailBypassUI = {}
MailBypassUI.__index = MailBypassUI

-- Config fields (all optional unless noted):
--   Title            = "Mail Bypass"
--   Subtitle         = "by YourName v1.0"
--   Discord          = "discord.gg/yourserver"
--   Tabs             = {"Mail", "Mail Fruits", "Incoming Mails", "Trade History", "Settings", "Tutorial"}
--   ResolveRecipient = function(query) -> table|nil  { Username, UserId, Verified, AvatarId } or nil/false if not found
--   GetItems         = function() -> table  { {Name = "Apple", Stock = 26}, ... }
--   OnSendBatch      = function(queue, recipient, mode) -> boolean  (return false to keep queue / show it failed)
--   OnAutoAccept     = function(enabled) end
function MailBypassUI.new(config)
	config = config or {}

	local self = setmetatable({}, MailBypassUI)

	self.Title = config.Title or "Mail Bypass"
	self.Subtitle = config.Subtitle or "v1.0"
	self.Discord = config.Discord or "discord.gg/yourserver"
	self.TabNames = config.Tabs or { "Mail", "Mail Fruits", "Incoming Mails", "Trade History", "Settings", "Tutorial" }

	self.ResolveRecipient = config.ResolveRecipient
	self.GetItems = config.GetItems or function() return {} end
	self.OnSendBatch = config.OnSendBatch
	self.OnAutoAccept = config.OnAutoAccept

	self.Queue = {}          -- { {Name=, Qty=}, ... }
	self.SelectedItem = nil  -- currently chosen item name in the dropdown
	self.SelectedItemStock = 0
	self.Recipient = nil     -- resolved recipient table or nil
	self.Mode = "Single"     -- "Single" | "Multi"
	self.AutoAccept = false
	self.Pages = {}          -- tab name -> page Frame (for you to add your own content to other tabs)

	self:_Build()

	return self
end

function MailBypassUI:_Build()
	local Theme = Theme

	-- ============ ROOT ============
	local ScreenGui = Create("ScreenGui", {
		Name = "MailBypassUI",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	}, GetGuiParent())
	self.ScreenGui = ScreenGui

	local Main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 660, 0, 494),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, ScreenGui)
	Create("UICorner", { CornerRadius = UDim.new(0, 10) }, Main)
	Create("UIStroke", { Color = Theme.PanelBorder, Thickness = 1 }, Main)
	self.Main = Main

	-- ============ TOP BAR ============
	local TopBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, Main)
	Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 60, 235)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 60, 235)),
		}),
		Rotation = 10,
	}, TopBar)

	Create("TextLabel", {
		Text = self.Title,
		Font = Theme.Font,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 6),
		Size = UDim2.new(0, 220, 0, 18),
	}, TopBar)

	Create("TextLabel", {
		Text = self.Subtitle,
		Font = Theme.FontBody,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(220, 222, 245),
		TextTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 24),
		Size = UDim2.new(0, 220, 0, 14),
	}, TopBar)

	local StatsPill = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -78, 0.5, 0),
		Size = UDim2.new(0, 170, 0, 26),
		BackgroundColor3 = Color3.fromRGB(10, 12, 22),
		BackgroundTransparency = 0.15,
	}, TopBar)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, StatsPill)
	local StatsLabel = Create("TextLabel", {
		Name = "StatsLabel",
		Text = "0/0 today  •  0 total",
		Font = Theme.FontBody,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(230, 230, 240),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, StatsPill)
	self.StatsLabel = StatsLabel

	local CloseBtn = Create("TextButton", {
		Text = "✕",
		Font = Theme.Font,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundTransparency = 1,
	}, TopBar)

	local MinBtn = Create("TextButton", {
		Text = "—",
		Font = Theme.Font,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -38, 0.5, 0),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundTransparency = 1,
	}, TopBar)

	MakeDraggable(TopBar, Main)

	local Minimized = false
	local FullSize = Main.Size
	MinBtn.Activated:Connect(function()
		Minimized = not Minimized
		SafeTween(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			Size = Minimized and UDim2.new(0, FullSize.X.Offset, 0, 46) or FullSize
		})
	end)

	CloseBtn.Activated:Connect(function()
		ScreenGui:Destroy()
	end)

	-- ============ TAB BAR ============
	local TabBar = Create("Frame", {
		Name = "TabBar",
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, Main)

	local TabLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, TabBar)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, TabBar)

	-- ============ CONTENT AREA ============
	local Content = Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 0, 0, 80),
		Size = UDim2.new(1, 0, 1, -80 - 40), -- leave room for bottom banner
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, Main)
	self.Content = Content

	-- ============ BOTTOM BANNER ============
	local Banner = Create("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -12, 0, 32),
		BackgroundColor3 = Color3.fromRGB(70, 70, 235),
	}, Main)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Banner)
	Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 70, 235)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 110, 235)),
		}),
	}, Banner)

	Create("TextLabel", {
		Text = "🤖 Join our Server!",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
	}, Banner)

	local DiscordPill = Create("TextButton", {
		Text = self.Discord,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 160, 0, 22),
		BackgroundColor3 = Color3.fromRGB(20, 20, 40),
		BackgroundTransparency = 0.15,
	}, Banner)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, DiscordPill)

	DiscordPill.Activated:Connect(function()
		pcall(function()
			if setclipboard then setclipboard(self.Discord) end
		end)
	end)

	-- ============ BUILD TABS ============
	local TabButtons = {}
	for i, name in ipairs(self.TabNames) do
		local Btn = Create("TextButton", {
			Name = "Tab_" .. name,
			Text = name,
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 24),
			BackgroundColor3 = Theme.AccentSoft,
			BackgroundTransparency = 1,
			LayoutOrder = i,
		}, TabBar)
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }, Btn)
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}, Btn)

		local Page = Create("Frame", {
			Name = "Page_" .. name,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
		}, Content)

		self.Pages[name] = Page
		TabButtons[name] = Btn

		Btn.Activated:Connect(function()
			self:SwitchTab(name)
		end)
	end
	self._TabButtons = TabButtons

	-- Build the full "Mail" tab content if present
	if self.Pages["Mail"] then
		self:_BuildMailPage(self.Pages["Mail"])
	end

	-- Placeholder content for the other tabs (so they're not blank/broken)
	for _, name in ipairs(self.TabNames) do
		if name ~= "Mail" then
			Create("TextLabel", {
				Text = name .. " — add your content here (Library:GetPage(\"" .. name .. "\"))",
				Font = Theme.FontBody,
				TextSize = 13,
				TextColor3 = Theme.Muted,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 16, 0, 16),
				Size = UDim2.new(1, -32, 0, 40),
			}, self.Pages[name])
		end
	end

	-- Default to first tab
	self:SwitchTab(self.TabNames[1])
end

function MailBypassUI:SwitchTab(name)
	for tabName, page in pairs(self.Pages) do
		local isActive = tabName == name
		page.Visible = isActive
		local Btn = self._TabButtons[tabName]
		SafeTween(Btn, TweenInfo.new(0.12), {
			BackgroundTransparency = isActive and 0 or 1,
			TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Theme.Muted,
		})
	end
end

-- =========================================================
-- MAIL PAGE (recipient + add item + queue)
-- =========================================================
function MailBypassUI:_BuildMailPage(Page)
	local Theme = Theme

	-- ---- Top row: Recipient (left) + Add Item (right) ----
	local TopRow = Create("Frame", {
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(1, -24, 0, 170),
		BackgroundTransparency = 1,
	}, Page)

	-- ===== RECIPIENT PANEL =====
	local RecipientPanel = Create("Frame", {
		Size = UDim2.new(0.5, -6, 1, 0),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, TopRow)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, RecipientPanel)
	Create("UIStroke", { Color = Theme.PanelBorder, Thickness = 1 }, RecipientPanel)

	Create("TextLabel", {
		Text = "RECIPIENT",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(0, 150, 0, 14),
	}, RecipientPanel)

	-- Single/Multi segmented toggle
	local ModePill = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.new(0, 140, 0, 20),
		BackgroundColor3 = Theme.Field,
	}, RecipientPanel)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ModePill)
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, ModePill)

	local function MakeModeButton(text, mode)
		local Btn = Create("TextButton", {
			Text = text,
			Font = Theme.Font,
			TextSize = 11,
			TextColor3 = Theme.Muted,
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = mode == self.Mode and 0 or 1,
		}, ModePill)
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Btn)
		return Btn
	end

	local SingleBtn = MakeModeButton("👤 Single", "Single")
	local MultiBtn = MakeModeButton("👥 Multi", "Multi")

	local NameBox = Create("TextBox", {
		Text = "",
		PlaceholderText = "Username",
		Font = Theme.FontBody,
		TextSize = 13,
		TextColor3 = Theme.Text,
		PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BackgroundColor3 = Theme.Field,
		Position = UDim2.new(0, 12, 0, 34),
		Size = UDim2.new(1, -24, 0, 30),
	}, RecipientPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, NameBox)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, NameBox)

	local function SetModeVisual(mode)
		self.Mode = mode
		SafeTween(SingleBtn, TweenInfo.new(0.1), { BackgroundTransparency = mode == "Single" and 0 or 1 })
		SafeTween(MultiBtn, TweenInfo.new(0.1), { BackgroundTransparency = mode == "Multi" and 0 or 1 })
		NameBox.PlaceholderText = mode == "Single" and "Username" or "Username1, Username2, ..."
	end
	SingleBtn.Activated:Connect(function() SetModeVisual("Single") end)
	MultiBtn.Activated:Connect(function() SetModeVisual("Multi") end)

	-- Resolved user card (hidden until a recipient resolves)
	local UserCard = Create("Frame", {
		Position = UDim2.new(0, 12, 0, 70),
		Size = UDim2.new(1, -24, 0, 60),
		BackgroundColor3 = Theme.Field,
		Visible = false,
	}, RecipientPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, UserCard)
	local UserCardStroke = Create("UIStroke", { Color = Theme.Good, Thickness = 1 }, UserCard)

	local Avatar = Create("ImageLabel", {
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundColor3 = Theme.Panel,
		Image = "",
	}, UserCard)
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Avatar)

	local UsernameLabel = Create("TextLabel", {
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 6),
		Size = UDim2.new(1, -64, 0, 16),
	}, UserCard)

	local UserIdLabel = Create("TextLabel", {
		Font = Theme.FontBody,
		TextSize = 11,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 22),
		Size = UDim2.new(1, -64, 0, 14),
	}, UserCard)

	local VerifiedLabel = Create("TextLabel", {
		Text = "✓ verified",
		Font = Theme.FontBody,
		TextSize = 11,
		TextColor3 = Theme.Good,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 38),
		Size = UDim2.new(1, -64, 0, 14),
	}, UserCard)

	local function TryResolve()
		local query = NameBox.Text
		if query == "" then
			self.Recipient = nil
			UserCard.Visible = false
			return
		end

		if not self.ResolveRecipient then
			return -- no resolver hooked up; leave it to you
		end

		local ok, result = pcall(self.ResolveRecipient, query)
		if ok and result then
			self.Recipient = result
			UsernameLabel.Text = "@" .. tostring(result.Username or query)
			UserIdLabel.Text = "UserID : " .. tostring(result.UserId or "?")
			VerifiedLabel.Visible = result.Verified == true
			UserCardStroke.Color = result.Verified and Theme.Good or Theme.PanelBorder
			pcall(function()
				if result.AvatarId then
					Avatar.Image = result.AvatarId
				end
			end)
			UserCard.Visible = true
		else
			self.Recipient = nil
			UserCard.Visible = false
		end
	end

	NameBox.FocusLost:Connect(TryResolve)

	-- ===== ADD ITEM TO QUEUE PANEL =====
	local AddPanel = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.5, -6, 1, 0),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, TopRow)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, AddPanel)
	Create("UIStroke", { Color = Theme.PanelBorder, Thickness = 1 }, AddPanel)

	Create("TextLabel", {
		Text = "ADD ITEM TO QUEUE",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(1, -24, 0, 14),
	}, AddPanel)

	-- Dropdown field (click to open searchable popup)
	local DropdownField = Create("TextButton", {
		Text = "",
		Position = UDim2.new(0, 12, 0, 32),
		Size = UDim2.new(1, -64, 0, 30),
		BackgroundColor3 = Theme.Field,
		AutoButtonColor = false,
	}, AddPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, DropdownField)

	local DropdownLabel = Create("TextLabel", {
		Text = "Select an item",
		Font = Theme.FontBody,
		TextSize = 13,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
	}, DropdownField)

	Create("TextLabel", {
		Text = "▾",
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Muted,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundTransparency = 1,
	}, DropdownField)

	local RefreshBtn = Create("TextButton", {
		Text = "⟳",
		Font = Theme.Font,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 32),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = Theme.Accent,
	}, AddPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, RefreshBtn)

	-- Searchable popup (built lazily, destroyed on close)
	local PopupOpen = false
	local ClosePopup -- forward decl

	local function OpenItemPopup()
		if PopupOpen then
			ClosePopup()
			return
		end
		PopupOpen = true

		local Popup = Create("Frame", {
			ZIndex = 50,
			Position = UDim2.new(0, 12, 0, 64),
			Size = UDim2.new(1, -24, 0, 180),
			BackgroundColor3 = Theme.Panel,
		}, AddPanel)
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }, Popup)
		Create("UIStroke", { Color = Theme.Accent, Thickness = 1 }, Popup)

		local SearchBox = Create("TextBox", {
			ZIndex = 51,
			PlaceholderText = "🔍 Search items...",
			Text = "",
			Font = Theme.FontBody,
			TextSize = 12,
			TextColor3 = Theme.Text,
			PlaceholderColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			BackgroundColor3 = Theme.Field,
			Position = UDim2.new(0, 6, 0, 6),
			Size = UDim2.new(1, -12, 0, 26),
		}, Popup)
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }, SearchBox)
		Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, SearchBox)

		local ListScroll = Create("ScrollingFrame", {
			ZIndex = 51,
			Position = UDim2.new(0, 6, 0, 38),
			Size = UDim2.new(1, -12, 1, -44),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 3,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, Popup)
		Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, ListScroll)

		local function Rebuild(filter)
			for _, c in ipairs(ListScroll:GetChildren()) do
				if c:IsA("Frame") then c:Destroy() end
			end

			local items = {}
			local ok, list = pcall(self.GetItems)
			if ok and type(list) == "table" then items = list end

			filter = string.lower(filter or "")
			local count = 0
			for _, item in ipairs(items) do
				local name = tostring(item.Name or "")
				if filter == "" or string.find(string.lower(name), filter, 1, true) then
					count += 1
					local Row = Create("Frame", {
						LayoutOrder = count,
						Size = UDim2.new(1, 0, 0, 26),
						BackgroundColor3 = Theme.Field,
						BackgroundTransparency = 0.3,
						ZIndex = 51,
					}, ListScroll)
					Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Row)

					Create("TextLabel", {
						Text = name,
						Font = Theme.FontBody,
						TextSize = 12,
						TextColor3 = Theme.Text,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 8, 0, 0),
						Size = UDim2.new(1, -60, 1, 0),
						ZIndex = 52,
					}, Row)

					Create("TextLabel", {
						Text = "x" .. tostring(item.Stock or 0),
						Font = Theme.FontBody,
						TextSize = 12,
						TextColor3 = Theme.Muted,
						TextXAlignment = Enum.TextXAlignment.Right,
						BackgroundTransparency = 1,
						Position = UDim2.new(1, -56, 0, 0),
						Size = UDim2.new(0, 48, 1, 0),
						ZIndex = 52,
					}, Row)

					local RowBtn = Create("TextButton", {
						Text = "",
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						ZIndex = 53,
					}, Row)

					RowBtn.Activated:Connect(function()
						self.SelectedItem = name
						self.SelectedItemStock = item.Stock or 0
						DropdownLabel.Text = name .. "  x" .. tostring(item.Stock or 0)
						DropdownLabel.TextColor3 = Theme.Text
						ClosePopup()
					end)
				end
			end

			ListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28)
		end

		SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			Rebuild(SearchBox.Text)
		end)

		Rebuild("")

		ClosePopup = function()
			PopupOpen = false
			ClosePopup = nil
			Popup:Destroy()
		end
	end

	DropdownField.Activated:Connect(OpenItemPopup)
	RefreshBtn.Activated:Connect(function()
		if PopupOpen and ClosePopup then
			-- popup rebuilds live via GetItems already; nothing else required
		end
	end)

	-- Quantity + Add
	local QtyBox = Create("TextBox", {
		Text = "100",
		Font = Theme.FontBody,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Field,
		Position = UDim2.new(0, 12, 0, 70),
		Size = UDim2.new(0, 100, 0, 30),
	}, AddPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, QtyBox)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, QtyBox)

	local AddBtn = Create("TextButton", {
		Text = "+ Add",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 118, 0, 70),
		Size = UDim2.new(1, -130, 0, 30),
		BackgroundColor3 = Theme.Accent,
	}, AddPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, AddBtn)

	local AutoAcceptCheckbox = Create("Frame", {
		Position = UDim2.new(0, 12, 0, 110),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Theme.Field,
	}, AddPanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 4) }, AutoAcceptCheckbox)
	local CheckMark = Create("TextLabel", {
		Text = "✓",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.Good,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
	}, AutoAcceptCheckbox)
	local AutoAcceptClick = Create("TextButton", {
		Text = "",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0, 12, 0, 110),
		BackgroundTransparency = 1,
	}, AddPanel)

	Create("TextLabel", {
		Text = "Auto Accept incoming mail (every 1s)",
		Font = Theme.FontBody,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 34, 0, 108),
		Size = UDim2.new(1, -40, 0, 18),
	}, AddPanel)

	AutoAcceptClick.Activated:Connect(function()
		self.AutoAccept = not self.AutoAccept
		CheckMark.Visible = self.AutoAccept
		if self.OnAutoAccept then
			pcall(self.OnAutoAccept, self.AutoAccept)
		end
	end)

	-- ---- QUEUE SECTION ----
	local QueuePanel = Create("Frame", {
		Position = UDim2.new(0, 12, 0, 188),
		Size = UDim2.new(1, -24, 1, -196),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, Page)
	Create("UICorner", { CornerRadius = UDim.new(0, 8) }, QueuePanel)
	Create("UIStroke", { Color = Theme.PanelBorder, Thickness = 1 }, QueuePanel)

	local QueueHeader = Create("TextLabel", {
		Text = "Queue  •  empty",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(0, 200, 0, 16),
	}, QueuePanel)

	local NoteBtn = Create("TextButton", {
		Text = "📝 Note",
		Font = Theme.FontBody,
		TextSize = 11,
		TextColor3 = Theme.Muted,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.new(0, 80, 0, 20),
		BackgroundColor3 = Theme.Field,
	}, QueuePanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 5) }, NoteBtn)

	local QueueList = Create("ScrollingFrame", {
		Position = UDim2.new(0, 12, 0, 36),
		Size = UDim2.new(0.55, -18, 1, -80),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		BackgroundColor3 = Theme.Field,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, QueuePanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, QueueList)
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, QueueList)
	Create("UIPadding", {
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6),
	}, QueueList)

	local EmptyLabel = Create("TextLabel", {
		Text = "Queue is empty.\nAdd an item from the right.",
		Font = Theme.FontBody,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, QueueList)

	local DescLabel = Create("TextLabel", {
		Text = "Queue is empty.\nAdd items, pick a recipient, then Send.",
		Font = Theme.FontBody,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 36),
		Size = UDim2.new(0.45, -6, 0, 60),
	}, QueuePanel)

	local SendBtn = Create("TextButton", {
		Text = "Send Batch",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0.45, -6, 0, 34),
		BackgroundColor3 = Theme.AccentDim,
		AutoButtonColor = false,
	}, QueuePanel)
	Create("UICorner", { CornerRadius = UDim.new(0, 6) }, SendBtn)

	local function RenderQueue()
		for _, c in ipairs(QueueList:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end

		local n = #self.Queue
		QueueHeader.Text = "Queue  •  " .. (n == 0 and "empty" or (n .. " item" .. (n > 1 and "s" or "")))
		EmptyLabel.Visible = n == 0
		DescLabel.Text = n == 0
			and "Queue is empty.\nAdd items, pick a recipient, then Send."
			or ("Ready to send " .. n .. " item" .. (n > 1 and "s" or "") .. ".\nPick a recipient, then Send.")

		SendBtn.BackgroundColor3 = (n > 0) and Theme.Accent or Theme.AccentDim

		for i, entry in ipairs(self.Queue) do
			local Row = Create("Frame", {
				LayoutOrder = i,
				Size = UDim2.new(1, -12, 0, 26),
				BackgroundColor3 = Theme.Panel,
			}, QueueList)
			Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Row)

			Create("TextLabel", {
				Text = entry.Name .. "  x" .. tostring(entry.Qty),
				Font = Theme.FontBody,
				TextSize = 12,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -34, 1, 0),
			}, Row)

			local RemoveBtn = Create("TextButton", {
				Text = "×",
				Font = Theme.Font,
				TextSize = 14,
				TextColor3 = Theme.Muted,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				BackgroundTransparency = 1,
			}, Row)

			RemoveBtn.Activated:Connect(function()
				table.remove(self.Queue, i)
				RenderQueue()
			end)
		end

		QueueList.CanvasSize = UDim2.new(0, 0, 0, math.max(0, n * 29))
	end
	self._RenderQueue = RenderQueue

	AddBtn.Activated:Connect(function()
		if not self.SelectedItem then
			return -- nothing selected; silently ignore (or hook a Notify callback yourself)
		end

		local qty = tonumber(QtyBox.Text) or 0
		if qty <= 0 then
			return
		end

		table.insert(self.Queue, { Name = self.SelectedItem, Qty = qty })
		RenderQueue()
	end)

	SendBtn.Activated:Connect(function()
		if #self.Queue == 0 then
			return
		end
		if not self.OnSendBatch then
			return -- hook OnSendBatch in config to actually send mail
		end

		local ok, result = pcall(self.OnSendBatch, self.Queue, self.Recipient, self.Mode)
		if ok and result ~= false then
			self.Queue = {}
			RenderQueue()
		end
	end)

	RenderQueue()
end

-- =========================================================
-- PUBLIC API
-- =========================================================
function MailBypassUI:SetStats(today, cap, total)
	if self.StatsLabel then
		self.StatsLabel.Text = tostring(today) .. "/" .. tostring(cap) .. " today  •  " .. tostring(total) .. " total"
	end
end

function MailBypassUI:GetPage(tabName)
	return self.Pages[tabName]
end

function MailBypassUI:GetQueue()
	return self.Queue
end

function MailBypassUI:ClearQueue()
	self.Queue = {}
	if self._RenderQueue then self._RenderQueue() end
end

function MailBypassUI:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return MailBypassUI

--[[
	EXAMPLE USAGE (put this in a separate script that requires this module):

	local MailBypassUI = require(path.to.this.module)

	local UI = MailBypassUI.new({
		Title = "Mail Bypass",
		Subtitle = "by Hiyori_ v4.3",
		Discord = "discord.gg/lentiques",
		Tabs = {"Mail", "Mail Fruits", "Incoming Mails", "Trade History", "Settings", "Tutorial"},

		-- You provide the real lookup (Players:GetUserIdFromNameAsync, a friends
		-- cache, a remote to the server, etc.)
		ResolveRecipient = function(query)
			local ok, userId = pcall(function()
				return game:GetService("Players"):GetUserIdFromNameAsync(query)
			end)
			if not ok or not userId then return nil end

			local thumbOk, thumb = pcall(function()
				return game:GetService("Players"):GetUserThumbnailAsync(
					userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
				)
			end)

			return {
				Username = query,
				UserId = userId,
				Verified = true,
				AvatarId = thumbOk and thumb or nil,
			}
		end,

		-- You provide the real inventory list from your game state
		GetItems = function()
			return {
				{ Name = "Apple", Stock = 26 },
				{ Name = "Bench Crate", Stock = 13 },
				{ Name = "Blueberry", Stock = 73 },
				{ Name = "Bridge Crate", Stock = 1 },
				{ Name = "Carrot", Stock = 401 },
				{ Name = "Cherry", Stock = 1 },
			}
		end,

		-- You provide the real sending logic (fire a RemoteEvent, etc.)
		OnSendBatch = function(queue, recipient, mode)
			if not recipient then
				warn("No recipient resolved")
				return false
			end
			for _, entry in ipairs(queue) do
				print("Sending", entry.Qty, entry.Name, "to", recipient.Username)
				-- game:GetService("ReplicatedStorage").SendMailRemote:FireServer(recipient.UserId, entry.Name, entry.Qty)
			end
			return true
		end,

		OnAutoAccept = function(enabled)
			print("Auto-accept:", enabled)
		end,
	})

	UI:SetStats(1, 50, 9)
]]
