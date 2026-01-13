local SERVER_URL = "http://127.0.0.1:5000/roblox_event"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local trackedDonor = nil

-- HELPER: Find a player by their Display Name (Crucial for PLS DONATE)
local function FindPlayerByDisplay(displayName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.DisplayName == displayName then
            return player
        end
    end
    return nil
end

-- HELPER: Send data to Python
local function sendToBridge(payload)
    local success, _ = pcall(function()
        request({
            Url = SERVER_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- 1. DONATION LISTENER (Matches Display Name)
local ChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if ChatEvents then
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering")
    OnMessage.OnClientEvent:Connect(function(data)
        local msg = data.Message
        -- Look for standard PLS DONATE system message
        if string.find(msg, "donated") and string.find(msg, "to You") then
            -- Extract the first word (The Display Name)
            -- Note: If display names have spaces, this regex might need adjustment, 
            -- but usually PLS DONATE handles it simply.
            local potentialName = string.match(msg, "^([%w%s]+) donated")
            -- Fallback cleaner if the regex grabs extra spaces
            if potentialName then 
                potentialName = string.split(potentialName, " ")[1] 
            end

            if potentialName then
                local player = FindPlayerByDisplay(potentialName)
                if player then
                    trackedDonor = player
                    print("✅ Tracking Donor (Display Name):", potentialName)
                    sendToBridge({type = "donation", user = potentialName})
                else
                    warn("⚠️ Donation saw '"..potentialName.."' but could not find that player in server.")
                end
            end
        end
    end)
end

-- 2. TEXT CHAT LISTENER (Sends Display Name)
local function hookPlayerChat(player)
    player.Chatted:Connect(function(msg)
        -- We compare Objects to be safe, then send the Display Name
        if trackedDonor and player == trackedDonor then
            sendToBridge({
                type = "chat",
                user = player.DisplayName, -- CHANGED to DisplayName
                message = msg
            })
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do hookPlayerChat(player) end
Players.PlayerAdded:Connect(hookPlayerChat)

-- 3. VISUAL VOICE LISTENER (Sends Display Name)
task.spawn(function()
    while task.wait(0.25) do
        if trackedDonor and trackedDonor.Character and trackedDonor.Character:FindFirstChild("Head") then
            local head = trackedDonor.Character.Head
            local isTalking = false
            
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("BillboardGui") and child.Enabled then
                    if child:FindFirstChildOfClass("ImageLabel") then
                        if child.Adornee == head then 
                            isTalking = true 
                        end
                    end
                end
            end
            
            if isTalking then
                sendToBridge({
                    type = "voice_active", 
                    user = trackedDonor.DisplayName -- CHANGED to DisplayName
                })
                task.wait(4.5)
            end
        end
    end
end)

print("Hybrid Client Loaded (Display Name Mode)")
