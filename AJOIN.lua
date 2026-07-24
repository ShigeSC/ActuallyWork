--[[
    Inferno Booth Scanner
    Only runs in Trade World
]]

local TRADE_WORLD_PLACE_ID = 129954712878723

-- Silent exit if not Trade World
if game.PlaceId ~= TRADE_WORLD_PLACE_ID then
    return
end

print("=== Inferno Scanner Starting ===")
print("Correct Trade World detected")
print("Waiting 15 seconds for game to fully load...")

task.wait(15)

print("Loading modules...")

local Modules = game.ReplicatedStorage:WaitForChild("Modules", 20)
if not Modules then
    warn("Modules not found")
    return
end

local TradeBoothControllers = Modules:WaitForChild("TradeBoothControllers", 10)
if not TradeBoothControllers then
    warn("TradeBoothControllers not found")
    return
end

local ListingController = require(TradeBoothControllers:WaitForChild("TradeBoothListingController"))
local PetMutationRegistry = require(game.ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetRegistry"):WaitForChild("PetMutationRegistry"))
local EnumToName = PetMutationRegistry.EnumToPetMutation or {}

print("Modules loaded successfully")

local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1530267036423295046/3vRLs5xaF2TX9QE28nzFYAY3uZgC_28Z3dcmxFdtUJEKfwvneAieghk5jIWp_c2VI0R0",
    HOP_DELAY = 8,
    MIN_PLAYERS = 15,
    MAX_PLAYERS = 25,
    VISITED_FILE = "visited_servers.txt",
}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlaceId = game.PlaceId
local JobId = game.JobId

-- Visited servers
local function loadVisited()
    local visited = {}
    local success, content = pcall(function()
        return readfile(CONFIG.VISITED_FILE)
    end)
    if success and content then
        for id in string.gmatch(content, "[^\n]+") do
            visited[id] = true
        end
    end
    return visited
end

local function saveVisited(visited)
    local lines = {}
    for id in pairs(visited) do
        table.insert(lines, id)
    end
    pcall(function()
        writefile(CONFIG.VISITED_FILE, table.concat(lines, "\n"))
    end)
end

local visitedServers = loadVisited()
visitedServers[JobId] = true
saveVisited(visitedServers)
print("Current server marked as visited")

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
    if not TradeWorld then
        print("TradeWorld not found")
        return results
    end

    local BoothsFolder = TradeWorld:FindFirstChild("Booths")
    if not BoothsFolder then
        print("Booths not found")
        return results
    end

    local booths = BoothsFolder:GetChildren()
    print("Scanning", #booths, "booths...")

    for _, booth in ipairs(booths) do
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
                print("Found", #pets, "Inferno pet(s) from", owner)
            end
        end
    end

    return results
end

local function sendWebhook(results)
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then return end

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

    local embed = {
        title = "🔥 Inferno Pets Found",
        description = desc,
        color = 16729088,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "Auto Scanner • Trade World" }
    }

    pcall(function()
        requestFunc({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "Inferno Scanner",
                embeds = {embed}
            })
        })
    end)

    print("✅ Webhook sent | Inferno booths:", #results)
end

local function serverHop()
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then return end

    local tried = {}
    local maxAttempts = 30
    local originalJobId = game.JobId

    for attempt = 1, maxAttempts do
        print("Looking for server... (" .. attempt .. "/" .. maxAttempts .. ")")

        local response = requestFunc({
            Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100",
            Method = "GET"
        })

        if response and response.Body then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if ok and data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing >= CONFIG.MIN_PLAYERS
                    and server.playing <= CONFIG.MAX_PLAYERS
                    and server.id ~= originalJobId
                    and not tried[server.id]
                    and not visitedServers[server.id] then

                        tried[server.id] = true
                        print("Trying →", server.id, "| Players:", server.playing)

                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                        end)

                        for i = 1, 6 do
                            task.wait(1)
                            if game.JobId ~= originalJobId then
                                print("Teleport successful!")
                                return
                            end
                        end

                        print("Teleport failed, trying next...")
                    end
                end
            end
        end

        task.wait(1.5)
    end

    print("No good server found → forcing place rejoin")
    pcall(function()
        TeleportService:Teleport(PlaceId)
    end)
end

-- Main
print("Scanning booths...")
local results = scanBooths()
sendWebhook(results)

print("Waiting", CONFIG.HOP_DELAY, "s before hop...")
task.wait(CONFIG.HOP_DELAY)
serverHop()
