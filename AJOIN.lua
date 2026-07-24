--[[
    Inferno Booth Scanner
    - Only Inferno mutation
    - Only 400–800 Tokens
    - Never reuses JobId
]]

local TRADE_WORLD_PLACE_ID = 129954712878723

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
    MIN_PRICE = 400,   -- minimum tokens
    MAX_PRICE = 800,   -- maximum tokens
    VISITED_FILE = "visited_servers.txt",
}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlaceId = game.PlaceId
local JobId = game.JobId

-- ========== Visited JobIds ==========
local function loadVisited()
    local visited = {}
    local success, content = pcall(function()
        return readfile(CONFIG.VISITED_FILE)
    end)
    if success and content and content ~= "" then
        for id in string.gmatch(content, "[^\r\n]+") do
            if id and id ~= "" then
                visited[id] = true
            end
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
print("Marked current JobId as visited:", JobId)

-- ========== Helpers ==========
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

-- ========== Scan (Inferno + 400-800 Tokens only) ==========
local function scanBooths()
    local results = {}
    local TradeWorld = workspace:FindFirstChild("TradeWorld")
    if not TradeWorld then return results end
    local BoothsFolder = TradeWorld:FindFirstChild("Booths")
    if not BoothsFolder then return results end

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
                local price = tonumber(listing.listingPrice) or 0

                -- Only Inferno + price between 400 and 800
                if mutation == "Inferno" and price >= CONFIG.MIN_PRICE and price <= CONFIG.MAX_PRICE then
                    table.insert(pets, {
                        type = safe(data.PetType),
                        name = safe(petData.Name),
                        weight = getCurrentWeight(petData.BaseWeight, petData.Level),
                        level = safe(petData.Level),
                        price = price
                    })
                end
            end

            if #pets > 0 then
                table.insert(results, {
                    owner = owner,
                    pets = pets
                })
                print("Found", #pets, "Inferno pet(s) (400-800 Tokens) from", owner)
            end
        end
    end

    return results
end

-- ========== Webhook ==========
local function sendWebhook(results)
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then return end

    local desc = ""
    if #results == 0 then
        desc = "*No Inferno pets (400-800 Tokens) found*\n"
    else
        for _, booth in ipairs(results) do
            desc = desc .. "**" .. booth.owner .. "**\n"
            for _, pet in ipairs(booth.pets) do
                desc = desc .. string.format(
                    "• **%s** (%s) | %s | Lv.%s | **%s Tokens**\n",
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
        title = "🔥 Inferno Pets (400-800 Tokens)",
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

    print("✅ Webhook sent | Matching booths:", #results)
end

-- ========== Server Hop ==========
local function serverHop()
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then return end

    local triedThisSession = {}
    local maxAttempts = 40
    local originalJobId = game.JobId

    for attempt = 1, maxAttempts do
        print("Looking for NEW server... (" .. attempt .. "/" .. maxAttempts .. ")")

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
                    local sid = server.id

                    if server.playing >= CONFIG.MIN_PLAYERS
                    and server.playing <= CONFIG.MAX_PLAYERS
                    and sid ~= originalJobId
                    and not triedThisSession[sid]
                    and not visitedServers[sid] then

                        triedThisSession[sid] = true
                        print("Trying NEW server →", sid, "| Players:", server.playing)

                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(PlaceId, sid, LocalPlayer)
                        end)

                        for i = 1, 7 do
                            task.wait(1)
                            if game.JobId ~= originalJobId then
                                print("Teleport successful! New JobId:", game.JobId)
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

    print("No new servers found → forcing place rejoin")
    pcall(function()
        TeleportService:Teleport(PlaceId)
    end)
end

-- ========== Main ==========
print("Scanning for Inferno pets (400-800 Tokens)...")
local results = scanBooths()
sendWebhook(results)

print("Waiting", CONFIG.HOP_DELAY, "s before hop...")
task.wait(CONFIG.HOP_DELAY)
serverHop()
