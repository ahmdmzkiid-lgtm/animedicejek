print("[TEST] Step 1: Starting...")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
print("[TEST] Step 2: Player = " .. tostring(Player))

-- Bikin GUI super simple
local ok, err = pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "TestGUI"
    sg.ResetOnSpawn = false

    -- Coba parent ke CoreGui dulu
    local parented = false
    pcall(function()
        sg.Parent = game:GetService("CoreGui")
        parented = true
    end)
    if not parented then
        sg.Parent = Player.PlayerGui
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 150)
    frame.Position = UDim2.new(0.5, -125, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "ANIME DICE TEST GUI"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 60)
    info.Position = UDim2.new(0, 10, 0, 45)
    info.BackgroundTransparency = 1
    info.Text = "GUI BERHASIL MUNCUL!\nPlayer: " .. Player.Name
    info.TextColor3 = Color3.fromRGB(80, 200, 120)
    info.TextSize = 14
    info.Font = Enum.Font.GothamMedium
    info.TextWrapped = true
    info.Parent = frame

    print("[TEST] Step 3: GUI created!")
end)

if not ok then
    warn("[TEST] GUI ERROR: " .. tostring(err))
end

print("[TEST] DONE!")
game:GetService("StarterGui"):SetCore("SendNotification", {Title="Test", Text="Script selesai! Cek layar.", Duration=10})
