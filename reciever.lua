-- CONFIGURATION
local fakeUser = "jonahthejeeew" -- Your Display Name Here
local SERVER_URL = "http://127.0.0.1:5000/roblox_event"

-- 1. Create the Screen GUI
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Cleanup old GUI if it exists (so you don't get duplicates)
if CoreGui:FindFirstChild("TestDonoGUI") then
    CoreGui.TestDonoGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestDonoGUI"
screenGui.Parent = CoreGui -- Puts it in the secure GUI layer

-- 2. Create the Button
local btn = Instance.new("TextButton")
btn.Name = "SimulateDonoBtn"
btn.Parent = screenGui
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green
btn.Position = UDim2.new(0, 50, 0, 50) -- Top Left (50px down)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Text = "TEST DONATION: " .. fakeUser
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 14
btn.Font = Enum.Font.SourceSansBold

-- Make corners round (Optional aesthetic)
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = btn

-- 3. The Function
btn.MouseButton1Click:Connect(function()
    print("🔘 Button Clicked! Sending fake donation...")
    
    -- Visual Feedback (Button flashes brightness)
    btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    task.delay(0.2, function() btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0) end)

    local payload = {
        type = "donation",
        user = fakeUser
    }

    -- Send to Python
    local success, response = pcall(function()
        request({
            Url = SERVER_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success then
        print("✅ Signal Sent to Python!")
    else
        warn("❌ Failed to connect to Python Bridge (Is it running?)")
    end
end)

print("GUI Loaded! Look for the Green Button on the left.")
