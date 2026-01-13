local SERVER_URL = "http://127.0.0.1:5000/roblox_event"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local trackedDonor = nil

-- Helper to talk to Python
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

-- 1. DONATION LISTENER
local ChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if ChatEvents then
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering")
    OnMessage.OnClientEvent:Connect(function(data)
        local msg = data.Message
        -- Check for PLS DONATE system message
        if string.find(msg, "donated") and string.find(msg, "to You") then
            local donorName = string.match(msg, "^(%w+)")
            if donorName then
                trackedDonor = Players:FindFirstChild(donorName)
                print("New Donor Tracked:", donorName)
                sendToBridge({type = "donation", user = donorName})
            end
        end
    end)
end

-- 2. TEXT CHAT LISTENER
-- We use a loop to hook players because PlayerAdded doesn't catch existing ones
local function hookPlayerChat(player)
    player.Chatted:Connect(function(msg)
        if trackedDonor and player == trackedDonor then
            sendToBridge({
                type = "chat",
                user = player.Name,
                message = msg
            })
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do hookPlayerChat(player) end
Players.PlayerAdded:Connect(hookPlayerChat)


-- 3. VISUAL VOICE LISTENER
-- Checks the donor's head for the Green Microphone Bubble
task.spawn(function()
    while task.wait(0.25) do -- Scan 4 times a second
        if trackedDonor and trackedDonor.Character and trackedDonor.Character:FindFirstChild("Head") then
            local head = trackedDonor.Character.Head
            local isTalking = false
            
            -- Look for the Voice Bubble GUI
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("BillboardGui") and child.Enabled then
                    -- The voice bubble usually contains an ImageLabel (the mic icon)
                    -- We check if it's visible, which implies they are speaking
                    if child:FindFirstChildOfClass("ImageLabel") then
                        if child.Adornee == head then 
                            isTalking = true 
                        end
                    end
                end
            end
            
            if isTalking then
                sendToBridge({type = "voice_active", user = trackedDonor.Name})
                task.wait(4.5) -- Wait 4.5s (Python records for 4s) to avoid spamming requests
            end
        end
    end
end)

print("Hybrid Client Loaded: Watching Chat & Voice.")