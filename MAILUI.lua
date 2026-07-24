--[[
    MAIL SCRIPT GUI
    Built to match the provided mockup:
    - Red title bar: "MAIL SCRIPT BY @boo10001"
    - "-" (minimize) and "X" (close) buttons, UPPER LEFT
    - Tabs: MAIL / MAIL HISTORY
    - Left panel: SEND TO? (username input + generate-avatar button)
    - Right panel: ADD ITEM TO SEND (select item + amount + add)
    - Bottom: QUEUE list + status text + SEND button

    Paste into a LocalScript (StarterGui / StarterPlayerScripts) or run via executor.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- VERSION STAMP: check this in F9 every time you re-run the script.
-- If this line does NOT print, or prints an OLD timestamp, you are
-- NOT running this file -- your executor/game still has a stale
-- cached copy. Fully rejoin the game (or clear the executor's
-- injected scripts) before testing further visual tweaks.
print("[MailScriptGui] loaded version: v10-plain-refresh-button")

-- =========================================================
-- THEME
-- =========================================================
local Theme = {
    Bg        = Color3.fromRGB(8, 8, 8),
    Panel     = Color3.fromRGB(14, 14, 14),
    PanelLine = Color3.fromRGB(180, 20, 20),
    Red       = Color3.fromRGB(190, 22, 22),
    RedDark   = Color3.fromRGB(110, 14, 14),
    Text      = Color3.fromRGB(215, 35, 35),
    TextDim   = Color3.fromRGB(150, 40, 40),
    White     = Color3.fromRGB(235, 235, 235),
    TabBg     = Color3.fromRGB(58, 58, 62),
    InputBg   = Color3.fromRGB(128, 128, 132),
    InputText = Color3.fromRGB(20, 20, 20),
    Avatar    = Color3.fromRGB(150, 150, 154),
    Font      = Enum.Font.GothamBold,
    FontBody  = Enum.Font.SourceSansLight,
}

local function New(className, props, parent)
    local inst = Instance.new(className)
    for prop, value in pairs(props) do
        inst[prop] = value
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function GetGuiParent()
    local ok, gethui_ok = pcall(function() return gethui and gethui() end)
    if ok and gethui_ok then
        return gethui_ok
    end
    return Player:WaitForChild("PlayerGui")
end

-- Simple drag helper for the title bar
local function MakeDraggable(handle, frame)
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =========================================================
-- ROOT
-- =========================================================
local GuiParent = GetGuiParent()

-- Remove any earlier copy of this GUI so re-running the script never
-- leaves a stale instance sitting on top of (or behind) the new one.
local ExistingGui = GuiParent:FindFirstChild("MailScriptGui")
if ExistingGui then
    ExistingGui:Destroy()
end

local ScreenGui = New("ScreenGui", {
    Name = "MailScriptGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, GuiParent)

local Main = New("Frame", {
    Name = "BigFrame",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 540, 0, 400),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)

New("UICorner", { CornerRadius = UDim.new(0, 8) }, Main)
New("UIStroke", { Color = Theme.Red, Thickness = 1.5 }, Main)

-- =========================================================
-- TITLE BAR  (with - and X in the UPPER LEFT)
-- =========================================================
local TitleBar = New("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Theme.Red,
    BorderSizePixel = 0,
}, Main)

New("UICorner", { CornerRadius = UDim.new(0, 8) }, TitleBar)
-- square off the bottom corners of the title bar
New("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = Theme.Red,
    BorderSizePixel = 0,
    ZIndex = 0,
}, TitleBar)

-- "-" minimize button (right side)
local MinButton = New("TextButton", {
    Name = "MinimizeButton",
    Text = "-",
    Font = Theme.Font,
    TextSize = 20,
    TextColor3 = Theme.White,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.85,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -38, 0.5, 0),
    Size = UDim2.new(0, 24, 0, 24),
    BorderSizePixel = 0,
}, TitleBar)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, MinButton)

-- "X" close button (right side, outermost)
local CloseButton = New("TextButton", {
    Name = "CloseButton",
    Text = "X",
    Font = Theme.Font,
    TextSize = 18,
    TextColor3 = Theme.White,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.85,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.new(0, 24, 0, 24),
    BorderSizePixel = 0,
}, TitleBar)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, CloseButton)

local TitleLabel = New("TextLabel", {
    Name = "TitleLabel",
    Text = "MAIL SCRIPT BY @boo10001",
    Font = Theme.Font,
    TextSize = 15,
    TextColor3 = Theme.White,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -80, 1, 0),
}, TitleBar)

MakeDraggable(TitleBar, Main)

-- Body content that gets hidden on minimize
local Body = New("Frame", {
    Name = "Body",
    Position = UDim2.new(0, 0, 0, 34),
    Size = UDim2.new(1, 0, 1, -34),
    BackgroundTransparency = 1,
}, Main)

local minimized = false
MinButton.Activated:Connect(function()
    minimized = not minimized
    Body.Visible = not minimized
    Main.Size = minimized and UDim2.new(0, 540, 0, 34) or UDim2.new(0, 540, 0, 400)
end)

CloseButton.Activated:Connect(function()
    ScreenGui.Enabled = false
end)

-- =========================================================
-- TABS: MAIL / MAIL HISTORY
-- =========================================================
local TabBar = New("Frame", {
    Name = "TabBar",
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Theme.TabBg,
    BorderSizePixel = 0,
}, Body)

local MailTabButton = New("TextButton", {
    Name = "MailTab",
    Text = "MAIL",
    Font = Theme.Font,
    TextSize = 13,
    TextColor3 = Theme.Text,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 0),
    Size = UDim2.new(0, 50, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
}, TabBar)

local HistoryTabButton = New("TextButton", {
    Name = "MailHistoryTab",
    Text = "MAIL HISTORY",
    Font = Theme.Font,
    TextSize = 13,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 70, 0, 0),
    Size = UDim2.new(0, 130, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
}, TabBar)

-- Pages (MAIL / MAIL HISTORY)
local MailPage = New("Frame", {
    Name = "MailPage",
    Position = UDim2.new(0, 12, 0, 40),
    Size = UDim2.new(1, -24, 1, -50),
    BackgroundTransparency = 1,
}, Body)

local HistoryPage = New("Frame", {
    Name = "MailHistoryPage",
    Position = UDim2.new(0, 12, 0, 40),
    Size = UDim2.new(1, -24, 1, -50),
    BackgroundTransparency = 1,
    Visible = false,
}, Body)

New("TextLabel", {
    Text = "Mail history will appear here.",
    Font = Theme.FontBody,
    TextSize = 13,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
}, HistoryPage)

local function SwitchTab(showMail)
    MailPage.Visible = showMail
    HistoryPage.Visible = not showMail
    MailTabButton.TextColor3 = showMail and Theme.Text or Theme.TextDim
    HistoryTabButton.TextColor3 = showMail and Theme.TextDim or Theme.Text
end

MailTabButton.Activated:Connect(function() SwitchTab(true) end)
HistoryTabButton.Activated:Connect(function() SwitchTab(false) end)

-- =========================================================
-- Reusable bordered panel helper
-- =========================================================
local function CreatePanel(parent, name, position, size, titleText)
    local Panel = New("Frame", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, Panel)
    New("UIStroke", { Color = Theme.PanelLine, Thickness = 1.5 }, Panel)

    New("TextLabel", {
        Text = titleText,
        Font = Theme.Font,
        TextSize = 11,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Panel)

    return Panel
end

-- =========================================================
-- LEFT PANEL — "SEND TO?"
-- =========================================================
local SendToPanel = CreatePanel(
    MailPage, "SendToFrame",
    UDim2.new(0, 0, 0, 0), UDim2.new(0, 240, 0, 100),
    "SEND TO?"
)

local RecipientBox = New("TextBox", {
    Name = "RecipientInput",
    PlaceholderText = "Username of recipient",
    Text = "",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.InputText,
    PlaceholderColor3 = Theme.InputText,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0, 26),
    Size = UDim2.new(1, -16, 0, 26),
    ClearTextOnFocus = false,
}, SendToPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, RecipientBox)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, RecipientBox)

-- Circular avatar placeholder (plain grey circle, as in the mockup)
local AvatarCircle = New("ImageLabel", {
    Name = "ImageOfUser",
    Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
    ImageColor3 = Theme.White,
    ImageTransparency = 0.4,
    BackgroundColor3 = Theme.Avatar,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0, 58),
    Size = UDim2.new(0, 34, 0, 34),
}, SendToPanel)
New("UICorner", { CornerRadius = UDim.new(1, 0) }, AvatarCircle)

local GenerateButton = New("TextButton", {
    Name = "GenerateUserButton",
    Text = "GENERATE USERHERE WITH @",
    Font = Theme.Font,
    TextSize = 10,
    TextColor3 = Theme.Text,
    TextWrapped = true,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 50, 0, 58),
    Size = UDim2.new(1, -58, 0, 34),
    TextXAlignment = Enum.TextXAlignment.Left,
}, SendToPanel)

-- =========================================================
-- RIGHT PANEL — "ADD ITEM TO SEND"
-- =========================================================
local AddItemPanel = CreatePanel(
    MailPage, "AddItemFrame",
    UDim2.new(0, 250, 0, 0), UDim2.new(1, -250, 0, 100),
    "ADD ITEM TO SEND"
)

-- "Select item" dropdown-style button + small swatch box
local SelectItemButton = New("TextButton", {
    Name = "SelectItemButton",
    Text = "Select item",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.InputText,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0, 26),
    Size = UDim2.new(1, -56, 0, 26),
}, AddItemPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, SelectItemButton)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, SelectItemButton)

local RefreshItemButton = New("TextButton", {
    Name = "RefreshItemButton",
    Text = "🔄",
    Font = Theme.Font,
    TextSize = 16,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.RedDark,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -40, 0, 26),
    Size = UDim2.new(0, 32, 0, 26),
}, AddItemPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, RefreshItemButton)
New("UIStroke", { Color = Theme.Red, Thickness = 1 }, RefreshItemButton)

local AmountBox = New("TextBox", {
    Name = "AmountInput",
    PlaceholderText = "Amount",
    Text = "",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.InputText,
    PlaceholderColor3 = Theme.InputText,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0, 60),
    Size = UDim2.new(1, -96, 0, 26),
    ClearTextOnFocus = false,
}, AddItemPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, AmountBox)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, AmountBox)

local AddButton = New("TextButton", {
    Name = "AddButton",
    Text = "ADD",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.RedDark,
    BackgroundColor3 = Theme.Red,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -80, 0, 60),
    Size = UDim2.new(0, 72, 0, 26),
}, AddItemPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, AddButton)

-- =========================================================
-- BOTTOM — QUEUE + STATUS + SEND
-- =========================================================
local BottomPanel = New("Frame", {
    Name = "BottomFrame",
    Position = UDim2.new(0, 0, 0, 110),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, MailPage)
New("UICorner", { CornerRadius = UDim.new(0, 8) }, BottomPanel)
New("UIStroke", { Color = Theme.PanelLine, Thickness = 1.5 }, BottomPanel)

New("TextLabel", {
    Text = "QUEUE",
    Font = Theme.Font,
    TextSize = 11,
    TextColor3 = Theme.Text,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 8),
    Size = UDim2.new(0, 100, 0, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
}, BottomPanel)

local QueueList = New("ScrollingFrame", {
    Name = "QueueList",
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0, 26),
    Size = UDim2.new(0.62, -14, 1, -36),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Red,
}, BottomPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, QueueList)
New("UIStroke", { Color = Theme.PanelLine, Thickness = 1 }, QueueList)
New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, QueueList)

New("TextLabel", {
    Name = "QueuePlaceholder",
    Text = "THE QUEUE SHOULD BE HERE",
    Font = Theme.Font,
    TextSize = 11,
    TextColor3 = Theme.InputText,
    TextXAlignment = Enum.TextXAlignment.Center,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
}, QueueList)

local StatusLabel = New("TextLabel", {
    Name = "StatusLabel",
    Text = "PUT THE STATUS HERE",
    Font = Theme.Font,
    TextSize = 11,
    TextColor3 = Theme.Text,
    BackgroundTransparency = 1,
    Position = UDim2.new(0.62, 6, 0, 26),
    Size = UDim2.new(0.38, -14, 0, 30),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true,
}, BottomPanel)

local SendButton = New("TextButton", {
    Name = "SendButton",
    Text = "SEND",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.RedDark,
    BackgroundColor3 = Theme.Red,
    BorderSizePixel = 0,
    Position = UDim2.new(0.62, 6, 1, -40),
    Size = UDim2.new(0.38, -14, 0, 28),
}, BottomPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, SendButton)

-- =========================================================
-- Wire up basic behavior (queue add / send stubs)
-- Replace the TODOs with your actual mail-sending remote calls.
-- =========================================================
local queueItems = {} -- { {item = "Name", amount = 5}, ... }
local selectedItem = nil

local function RefreshQueueDisplay()
    for _, child in ipairs(QueueList:GetChildren()) do
        if child.Name ~= "QueuePlaceholder" and child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    QueueList.QueuePlaceholder.Visible = (#queueItems == 0)

    for i, entry in ipairs(queueItems) do
        New("TextLabel", {
            Text = entry.item .. " x" .. tostring(entry.amount),
            Font = Theme.FontBody,
            TextSize = 12,
            TextColor3 = Theme.White,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i,
        }, QueueList)
    end
end

local itemOptions = {} -- populate this with your real item names, e.g. from a RemoteFunction

local function RefreshItemOptions()
    -- TODO: replace this with your real item source, e.g.:
    -- itemOptions = game.ReplicatedStorage.MailRemotes.GetItems:InvokeServer()
    StatusLabel.Text = "Refreshed item list (" .. #itemOptions .. " items)."
end

SelectItemButton.Activated:Connect(function()
    -- TODO: open your item-select dropdown/menu here, then set selectedItem
    StatusLabel.Text = "Select an item to add."
end)

RefreshItemButton.Activated:Connect(function()
    RefreshItemOptions()
end)

AddButton.Activated:Connect(function()
    local amount = tonumber(AmountBox.Text)
    if not selectedItem then
        StatusLabel.Text = "Pick an item first!"
        return
    end
    if not amount or amount <= 0 then
        StatusLabel.Text = "Enter a valid amount!"
        return
    end

    table.insert(queueItems, { item = selectedItem, amount = amount })
    RefreshQueueDisplay()
    AmountBox.Text = ""
    StatusLabel.Text = "Added " .. selectedItem .. " x" .. amount .. " to queue."
end)

GenerateButton.Activated:Connect(function()
    -- TODO: hook this up to whatever "generate username with @" lookup you use
    local typed = RecipientBox.Text:gsub("^@", "")
    if typed == "" then
        StatusLabel.Text = "Type a username first."
        return
    end
    StatusLabel.Text = "Looking up @" .. typed .. "..."
end)

SendButton.Activated:Connect(function()
    if RecipientBox.Text == "" then
        StatusLabel.Text = "Enter a recipient username!"
        return
    end
    if #queueItems == 0 then
        StatusLabel.Text = "Queue is empty — add an item first!"
        return
    end

    -- TODO: fire your actual send RemoteEvent here, e.g.:
    -- game.ReplicatedStorage.MailRemotes.SendMail:FireServer(RecipientBox.Text, queueItems)

    StatusLabel.Text = "Sent to " .. RecipientBox.Text .. "!"
    queueItems = {}
    RefreshQueueDisplay()
end)

RefreshQueueDisplay()
SwitchTab(true)
