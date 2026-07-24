--[[
    Auto Inferno Booth Scanner + Server Hop
]]

-- Prevent multiple instances
if getgenv().InfernoScannerRunning then
    return
end
getgenv().InfernoScannerRunning = true

local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1530248772091908206/01aXIqyblwZOAo-goz0oRkL95Ip_9LJhOi15Xg1J1Nn_85k7I-7ozg4PhWM_CoksxNRF",
    HOP_DELAY = 8,
    MIN_PLAYERS = 10,
}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for game to load
repeat task.wait() until game:IsLoaded()
task.wait(2)

local Controllers = game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TradeBoothControllers")
local ListingController = require(Controllers:WaitForChild("TradeBoothListingController"))
local PetMutationRegistry = require(game.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
local EnumToName = PetMutationRegistry.EnumToPetMutation or {}

local PlaceId = game.PlaceId
local JobId = game.JobId

local function getMutationName(code)
    if not code or code == "" then return "None" end
    return EnumToName[tostring(code)] or tostring(code)
end

local function safe(v)
    return tostring(v or "?")
end

local function getCurrentWeight(baseWeight, level)
    if not baseWeight or not level then return "?" end
    return string.format("%.2fkg", baseWeight * (1 + level * 0.1))
end

local function getJoinLink()
    return string.format(
        "https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s",
        PlaceId, JobId
    )
end

local function scanBooths()
    local results = {}
    local TradeWorld = workspace:FindFirstChild("TradeWorld")
    if not TradeWorld then return results end
    local BoothsFolder = TradeWorld:FindFirstChild("Booths")
    if not BoothsFolder then return results end

    for _, booth in ipairs(BoothsFolder:GetChildren()) do
        local uuid = booth.Name

        pcall(function()
            if ListingController.SetBooth then
                ListingController:SetBooth(uuid)
            end
            ListingController.BoothUUID = uuid
            if ListingController.RefreshDisplay then
                ListingController:RefreshDisplay()
            end
        end)

        task.wait(0.3)

        local ok, inventory = pcall(function()
            return ListingController:GetInventory()
        end)

        if ok and typeof(inventory) == "table" and #inventory > 0 then
            local owner = safe(inventory[1] and inventory[1].listingOwner)
            local pets = {}

            for _, listing in ipairs(inventory) do
                local data = listing.data or {}
                local petData = data.PetData or {}
                local mutation = getMutationName(petData.MutationType)

                if mutation == "Inferno" then
                    table.insert(pets, {
                        type = safe(data.PetType),
                        name = safe(petData.Name),
                        weight = getCurrentWeight(petData.BaseWeight, petData.Level),
                        level = safe(petData.Level),
                        price = safe(listing.listingPrice)
                    })
                end
            end

            if #pets > 0 then
                table.insert(results, {
                    owner = owner,
                    pets = pets
                })
            end
        end
    end

    return results
end

local function buildDescription(results)
    local desc = ""

    if #results == 0 then
        desc = "*No Inferno pets found*\n"
    else
        for _, booth in ipairs(results) do
            desc = desc .. "**" .. booth.owner .. "**\n"
            for _, pet in ipairs(booth.pets) do
                desc = desc .. string.format(
                    "• **%s** (%s) | %s | Lv.%s | %s Tokens\n",
                    pet.type, pet.name, pet.weight, pet.level, pet.price
                )
            end
            desc = desc .. "\n"
        end
    end

    if #desc > 3500 then
        desc = string.sub(desc, 1, 3500) .. "\n...(truncated)"
    end

    desc = desc .. "─────────────────\n"
    desc = desc .. string.format("🌐 Players: %d/%d\n", #Players:GetPlayers(), Players.MaxPlayers)
    desc = desc .. "🔗 Join: " .. getJoinLink()

    return desc
end

local function sendWebhook(results)
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then
        warn("No request function")
        return
    end

    local embed = {
        title = "🔥 Inferno Pets Found",
        description = buildDescription(results),
        color = 16729088,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "Auto Scanner • Trade World" }
    }

    local payload = {
        username = "Inferno Scanner",
        embeds = {embed}
    }

    pcall(function()
        requestFunc({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)

    print("✅ Webhook sent | Booths with Inferno:", #results)
end

local function serverHop()
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then return end

    local response = requestFunc({
        Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100",
        Method = "GET"
    })

    if not response or not response.Body then
        warn("Failed to get servers")
        return
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not success or not data or not data.data then return end

    for _, server in ipairs(data.data) do
        if server.playing >= CONFIG.MIN_PLAYERS and server.playing < server.maxPlayers and server.id ~= JobId then
            print("Hopping →", server.id, "| Players:", server.playing)
            TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            return
        end
    end

    warn("No good server found")
end

-- Queue script for next server
local thisScript = debug.getinfo(1, "S").source
if queue_on_teleport then
    -- Re-queue the whole logic
    queue_on_teleport([[
        getgenv().InfernoScannerRunning = false
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/yourrepo/main/inferno.lua"))()
    ]])
end

-- ========== MAIN ==========
print("=== Auto Inferno Scanner Started ===")

print("Scanning booths...")
local results = scanBooths()
sendWebhook(results)

print("Waiting", CONFIG.HOP_DELAY, "s before hop...")
task.wait(CONFIG.HOP_DELAY)

serverHop()
