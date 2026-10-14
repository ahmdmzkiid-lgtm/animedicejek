--[[
    ANIME DICE AFK HUB v2.3 — DELTA EXECUTOR
    
    Copas ke Delta:
    loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/ahmdmzkiid-lgtm/animedicejek@main/main.lua", true))()
]]

print("[AnimeDice] v2.3 Starting...")

-- ═══ SERVICES (safe) ═══
local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Player     = Players.LocalPlayer

print("[AnimeDice] Player: " .. tostring(Player))

-- ═══ CONFIG ═══
local CONFIG = {
    RollDelay       = 2.2,
    CollectDelay    = 10,
    SellDelay       = 5,
    RebirthDelay    = 15,
    TowerDelay      = 1,
    UpgradeDelay    = 10,
    DiceDelay       = 10,
    CodeDelay       = 2,
    ClaimDelay      = 30,
    AntiAFKDelay    = 60,
    BoostDelay      = 30,
    SpinDelay       = 3,
    LevelDelay      = 5,
    StatsDelay      = 10,
    SellBelowRarity = 3,
    KeepBestSpares  = 20,
    RebirthMultiplier = 1,
    TowerName       = nil,
    UpgradeCategories = {"Money", "Luck", "Fortune", "Roll Speed", "Unit Storage", "Sell"},
    Codes = {
        "RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4", "UPDATE5",
        "SORRY", "THANKYOU", "100KLIKES", "200KLIKES", "CODES", "FREE",
    },
    BoostNames = {"Luck", "Income", "Roll Speed"},
    SpinNames  = {"Lucky Spin", "Jackpot Spin"},
    LevelShare = 0.3,
    RebirthStatPick = "Money",
}

-- ═══ GENERATION GUARD ═══
_G.__ANIMEDICE_HUB = (_G.__ANIMEDICE_HUB or 0) + 1
local GENERATION = _G.__ANIMEDICE_HUB
if _G.__ANIMEDICE_HUB_GUI then
    pcall(function() _G.__ANIMEDICE_HUB_GUI:Destroy() end)
end
local function isAlive() return _G.__ANIMEDICE_HUB == GENERATION end

-- ═══ STATE ═══
local State = {
    AutoRoll = false, AutoSell = false, AutoCollect = true,
    AutoRebirth = false, AutoTower = false, AutoUpgrade = false,
    AutoDice = false, AutoCodes = false, AutoClaim = false,
    AutoBoost = false, AutoSpin = false, AutoLevel = false,
    AutoStats = false, AntiAFK = true,
}
local Stats = {
    Rolled = 0, Sold = 0, Collected = 0, Rebirths = 0,
    DiceBought = 0, Codes = 0, TowerRuns = 0, Upgrades = 0,
    StartTime = tick(),
}

-- ═══ UTILITY ═══
local function formatTime(s)
    return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), math.floor(s%60))
end
local function formatNum(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif n >= 1e9 then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(math.floor(n)) end
end
local function notify(title, text, dur)
    pcall(function() StarterGui:SetCore("SendNotification", {Title=title or "AFK Hub", Text=text or "", Duration=dur or 3}) end)
end

-- ═══ REMOTE HELPERS ═══
-- TIDAK PAKAI ... (varargs) karena Delta loadstring ga support
-- Pakai explicit arg1, arg2 saja
local R = {}

local function fireRE(remote, arg1, arg2)
    if not remote then return end
    local ok, e = pcall(function()
        if arg2 ~= nil then
            remote:FireServer(arg1, arg2)
        elseif arg1 ~= nil then
            remote:FireServer(arg1)
        else
            remote:FireServer()
        end
    end)
    if not ok then
        warn("[AnimeDice] fireRE error: " .. tostring(e))
    end
end

local function invokeRF(remote, arg1, arg2)
    if not remote then return nil end
    local ok, result = pcall(function()
        if arg2 ~= nil then
            return remote:InvokeServer(arg1, arg2)
        elseif arg1 ~= nil then
            return remote:InvokeServer(arg1)
        else
            return remote:InvokeServer()
        end
    end)
    if ok then return result end
    return nil
end

-- ═══ DATA HELPERS ═══
local DataController
local function getData()
    local ok, result = pcall(function()
        if DataController and DataController.___X then return DataController.___X end
        return nil
    end)
    if ok then return result end
    return nil
end

-- Game config refs
local Dice, Rebirths, PlotConfig, UpgradeConfig

print("[AnimeDice] Base loaded, creating GUI...")

-- ══════════════════════════════════════════════════
-- GUI — dibuat PERTAMA sebelum load remote
-- ══════════════════════════════════════════════════
local StatusText

local function createGUI()
    local BG     = Color3.fromRGB(18, 18, 28)
    local BG2    = Color3.fromRGB(28, 28, 42)
    local DARK   = Color3.fromRGB(12, 12, 20)
    local ACCENT = Color3.fromRGB(100, 60, 255)
    local GREEN  = Color3.fromRGB(80, 200, 120)
    local RED    = Color3.fromRGB(200, 60, 60)
    local WHITE  = Color3.fromRGB(255, 255, 255)
    local GRAY   = Color3.fromRGB(140, 140, 160)

    local sg = Instance.new("ScreenGui")
    sg.Name = "AnimeDiceHub"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Parent GUI (try multiple methods)
    local parented = false
    if not parented then pcall(function()
        if gethui then sg.Parent = gethui(); parented = true end
    end) end
    if not parented then pcall(function()
        sg.Parent = game:GetService("CoreGui"); parented = true
    end) end
    if not parented then pcall(function()
        sg.Parent = Player.PlayerGui; parented = true
    end) end
    if not parented then
        warn("[AnimeDice] Cannot parent GUI!")
        return nil
    end
    _G.__ANIMEDICE_HUB_GUI = sg

    -- Main frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 280, 0, 540)
    Main.Position = UDim2.new(0.5, -140, 0.5, -270)
    Main.BackgroundColor3 = BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = sg
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = ACCENT
    stroke.Thickness = 2

    -- Title bar
    local TBar = Instance.new("Frame")
    TBar.Size = UDim2.new(1, 0, 0, 40)
    TBar.BackgroundColor3 = DARK
    TBar.BorderSizePixel = 0
    TBar.Parent = Main
    Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 10)

    local TText = Instance.new("TextLabel")
    TText.Size = UDim2.new(1, -45, 1, 0)
    TText.Position = UDim2.new(0, 10, 0, 0)
    TText.BackgroundTransparency = 1
    TText.Text = "Anime Dice AFK Hub v2.3"
    TText.TextColor3 = WHITE
    TText.TextSize = 14
    TText.Font = Enum.Font.GothamBold
    TText.TextXAlignment = Enum.TextXAlignment.Left
    TText.Parent = TBar

    -- Close btn
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -33, 0, 7)
    CloseBtn.BackgroundColor3 = RED
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = WHITE
    CloseBtn.TextSize = 13
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    -- Scroll area
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -12, 1, -88)
    Scroll.Position = UDim2.new(0, 6, 0, 44)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = ACCENT
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.Parent = Main

    local Layout = Instance.new("UIListLayout", Scroll)
    Layout.Padding = UDim.new(0, 4)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Status bar
    local SBar = Instance.new("Frame")
    SBar.Size = UDim2.new(1, -12, 0, 34)
    SBar.Position = UDim2.new(0, 6, 1, -40)
    SBar.BackgroundColor3 = DARK
    SBar.BorderSizePixel = 0
    SBar.Parent = Main
    Instance.new("UICorner", SBar).CornerRadius = UDim.new(0, 6)

    StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -10, 1, 0)
    StatusText.Position = UDim2.new(0, 6, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.TextColor3 = GRAY
    StatusText.TextSize = 10
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Text = "Loading remotes..."
    StatusText.Parent = SBar

    -- Toggle factory
    local function addToggle(name, stateKey, order)
        local F = Instance.new("Frame")
        F.Size = UDim2.new(1, 0, 0, 32)
        F.BackgroundColor3 = BG2
        F.BorderSizePixel = 0
        F.LayoutOrder = order
        F.Parent = Scroll
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 7)

        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -65, 1, 0)
        L.Position = UDim2.new(0, 10, 0, 0)
        L.BackgroundTransparency = 1
        L.Text = name
        L.TextColor3 = WHITE
        L.TextSize = 12
        L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = F

        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, 46, 0, 22)
        B.Position = UDim2.new(1, -54, 0.5, -11)
        B.BackgroundColor3 = State[stateKey] and GREEN or RED
        B.Text = State[stateKey] and "ON" or "OFF"
        B.TextColor3 = WHITE
        B.TextSize = 11
        B.Font = Enum.Font.GothamBold
        B.BorderSizePixel = 0
        B.Parent = F
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 5)

        B.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            B.BackgroundColor3 = State[stateKey] and GREEN or RED
            B.Text = State[stateKey] and "ON" or "OFF"
        end)
    end

    addToggle("Auto Roll",    "AutoRoll",    1)
    addToggle("Auto Sell",    "AutoSell",    2)
    addToggle("Auto Collect", "AutoCollect", 3)
    addToggle("Auto Rebirth", "AutoRebirth", 4)
    addToggle("Auto Tower",   "AutoTower",   5)
    addToggle("Auto Dice",    "AutoDice",    6)
    addToggle("Auto Upgrade", "AutoUpgrade", 7)
    addToggle("Auto Spin",    "AutoSpin",    8)
    addToggle("Auto Level",   "AutoLevel",   9)
    addToggle("Auto Claim",   "AutoClaim",  10)
    addToggle("Auto Codes",   "AutoCodes",  11)
    addToggle("Auto Boost",   "AutoBoost",  12)
    addToggle("Auto Stats",   "AutoStats",  13)
    addToggle("Anti-AFK",     "AntiAFK",    14)

    -- Open/close button
    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 90, 0, 32)
    openBtn.Position = UDim2.new(0, 8, 0, 8)
    openBtn.BackgroundColor3 = ACCENT
    openBtn.Text = "AFK Hub"
    openBtn.TextColor3 = WHITE
    openBtn.TextSize = 12
    openBtn.Font = Enum.Font.GothamBold
    openBtn.BorderSizePixel = 0
    openBtn.Visible = false
    openBtn.Active = true
    openBtn.Draggable = true
    openBtn.Parent = sg
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)

    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        openBtn.Visible = true
    end)
    openBtn.MouseButton1Click:Connect(function()
        Main.Visible = true
        openBtn.Visible = false
    end)

    return sg
end

-- CREATE GUI NOW
local guiOk, guiErr = pcall(createGUI)
if guiOk then
    print("[AnimeDice] GUI created!")
    notify("AFK Hub", "GUI loaded! Sedang load remotes...", 3)
else
    warn("[AnimeDice] GUI error: " .. tostring(guiErr))
end

-- ══════════════════════════════════════════════════
-- LOAD REMOTES (setelah GUI muncul, di background)
-- ══════════════════════════════════════════════════
print("[AnimeDice] Loading remotes...")

spawn(function()
    wait(2)

    -- Find Network folder
    local Network = nil
    pcall(function()
        Network = RS:FindFirstChild("Network")
        if not Network then
            Network = RS:WaitForChild("Network", 10)
        end
    end)

    if Network then
        print("[AnimeDice] Network folder found!")
    else
        warn("[AnimeDice] Network folder NOT found!")
        if StatusText then
            StatusText.Text = "Network not found"
        end
    end

    -- Helper to find remote
    local function svc(path)
        if not Network then return nil end
        local ok2, result = pcall(function()
            local node = Network
            for part in string.gmatch(path, "[^%.]+") do
                if not node then return nil end
                node = node:FindFirstChild(part)
            end
            return node
        end)
        if ok2 then return result end
        return nil
    end

    -- Load all remotes
    pcall(function()
        R.RollDice        = svc("RollService.RF.RollDice")
        R.SetAutoRoll     = svc("RollService.RE.SetAutoRoll")
        R.EquipBest       = svc("PlotService.RE.EquipBest")
        R.CollectBalance  = svc("PlotService.RE.CollectBalance")
        R.LevelUpSlot     = svc("PlotService.RE.LevelUpSlot")
        R.InteractSlot    = svc("PlotService.RE.InteractSlot")
        R.BuyDice         = svc("DiceShopService.RE.BuyDice")
        R.EquipDice       = svc("DiceShopService.RE.EquipDice")
        R.Rebirth         = svc("RebirthService.RE.Rebirth")
        R.AddStat         = svc("RebirthService.RE.AddStat")
        R.SellInventory   = svc("SellService.RF.SellInventory")
        R.UpdateAutoSell  = svc("SellService.RE.UpdateAutoSell")
        R.BuyUpgrade      = svc("RE.BuyUpgrade")
        R.RedeemCode      = svc("CodesService.RE.RedeemCode") or svc("MonetizationService.RE.RedeemCode")
        R.PlayTower       = svc("Towers.RF.PlayTower")
        R.CompleteTowerFloor = svc("Towers.RF.CompleteTowerFloor")
        R.CancelTower     = svc("Towers.RF.CancelTower")
        R.EquipBestTower  = svc("Towers.RE.EquipBestTowerTeam")
        R.ClaimOffline    = svc("OfflineEarningsService.RE.Claim")
        R.ClaimDaily      = svc("DailyRewardService.RE.Claim")
        R.ClaimGroup      = svc("GroupRewardService.RE.Claim")
        R.GradeRoll       = svc("GradeService.RE.Roll")
        R.TraitRoll       = svc("TraitService.RE.Roll")
        R.BoostUse        = svc("BoostService.RE.Use")
        R.UseSpin         = svc("SpinService.RE.Use")
        R.Fuse            = svc("FusingService.RE.Fuse")
        R.QuestClaim      = svc("QuestService.RE.Claim")
        R.QuestBuy        = svc("QuestService.RE.Buy")
    end)

    -- Count remotes
    local found, missing = 0, 0
    for name, remote in pairs(R) do
        if remote then found = found + 1
        else missing = missing + 1 end
    end
    print("[AnimeDice] Remotes: " .. found .. " found, " .. missing .. " missing")

    -- Load Framework + DataController
    local Framework = nil
    pcall(function()
        Framework = RS:FindFirstChild("Framework")
        if not Framework then
            Framework = RS:WaitForChild("Framework", 5)
        end
    end)

    if Framework then
        print("[AnimeDice] Framework found!")
        pcall(function() DataController = require(Framework.Features.Data.DataController) end)
        pcall(function() Dice         = require(Framework.Features.Rolling.Dice) end)
        pcall(function() Rebirths     = require(Framework.Features.Rebirth.Rebirths) end)
        pcall(function() PlotConfig   = require(Framework.Features.Plot.PlotConfig) end)
        pcall(function() UpgradeConfig = require(Framework.Features.Upgrades.Upgrades) end)
        print("[AnimeDice] Game configs loaded")
    else
        warn("[AnimeDice] Framework not found")
    end

    if StatusText then
        StatusText.Text = "Ready! " .. found .. " remotes"
    end
    notify("AFK Hub", found .. " remotes loaded!", 4)

    -- ══════════════════════════════════════════════════
    -- START ALL MODULES
    -- ══════════════════════════════════════════════════
    print("[AnimeDice] Starting modules...")

    -- Anti-AFK
    spawn(function()
        local VU2 = nil
        pcall(function() VU2 = game:GetService("VirtualUser") end)
        if VU2 then
            pcall(function()
                Player.Idled:Connect(function()
                    pcall(function()
                        VU2:CaptureController()
                        VU2:ClickButton2(Vector2.new())
                    end)
                end)
            end)
        end

        local VIM2 = nil
        pcall(function() VIM2 = game:GetService("VirtualInputManager") end)

        while isAlive() do
            if State.AntiAFK and VIM2 then
                pcall(function()
                    VIM2:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    wait(0.1)
                    VIM2:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
            end
            wait(CONFIG.AntiAFKDelay)
        end
    end)

    -- Auto Roll
    spawn(function()
        while isAlive() do
            if State.AutoRoll and R.RollDice then
                local result = invokeRF(R.RollDice)
                if result then Stats.Rolled = Stats.Rolled + 1 end
            end
            wait(CONFIG.RollDelay)
        end
    end)

    -- Auto Collect
    spawn(function()
        while isAlive() do
            if State.AutoCollect and R.EquipBest then
                fireRE(R.EquipBest)
                Stats.Collected = Stats.Collected + 1
            end
            wait(CONFIG.CollectDelay)
        end
    end)

    -- Auto Sell
    spawn(function()
        while isAlive() do
            if State.AutoSell then
                if R.UpdateAutoSell then fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity) end
                if R.SellInventory then
                    local result = invokeRF(R.SellInventory)
                    if result then Stats.Sold = Stats.Sold + 1 end
                end
            end
            wait(CONFIG.SellDelay)
        end
    end)

    -- Auto Rebirth
    spawn(function()
        while isAlive() do
            if State.AutoRebirth and R.Rebirth then
                local d = getData()
                if d then
                    local cost = nil
                    pcall(function()
                        if Rebirths then
                            local info = Rebirths.Get(d.Rebirth + 1)
                            cost = info and tonumber(info.cost)
                        end
                    end)
                    if cost and d.Money >= cost * CONFIG.RebirthMultiplier then
                        fireRE(R.Rebirth)
                        Stats.Rebirths = Stats.Rebirths + 1
                        wait(2)
                    end
                end
            end
            wait(CONFIG.RebirthDelay)
        end
    end)

    -- Auto Dice
    spawn(function()
        while isAlive() do
            if State.AutoDice and R.BuyDice and R.EquipDice and Dice then
                pcall(function()
                    local d = getData()
                    if d then
                        local allDice = {}
                        local raw = Dice.GetAll()
                        for key, def in pairs(raw) do
                            table.insert(allDice, {key=key, luck=tonumber(def.luck) or 0, price=tonumber(def.price)})
                        end
                        table.sort(allDice, function(a,b) return a.luck < b.luck end)
                        for _, die in ipairs(allDice) do
                            if die.price and not d.OwnedDice[die.key] and d.Money >= die.price then
                                fireRE(R.BuyDice, die.key)
                                Stats.DiceBought = Stats.DiceBought + 1
                                wait(0.5)
                            end
                        end
                        local bestKey, bestLuck = nil, 0
                        for _, die in ipairs(allDice) do
                            if d.OwnedDice[die.key] and die.luck > bestLuck then
                                bestKey, bestLuck = die.key, die.luck
                            end
                        end
                        if bestKey and bestKey ~= d.Dice then
                            fireRE(R.EquipDice, bestKey)
                        end
                    end
                end)
            end
            wait(CONFIG.DiceDelay)
        end
    end)

    -- Auto Upgrade
    spawn(function()
        while isAlive() do
            if State.AutoUpgrade and R.BuyUpgrade and UpgradeConfig then
                pcall(function()
                    local d = getData()
                    if d then
                        for _, cat in ipairs(CONFIG.UpgradeCategories) do
                            for uname, def in pairs(UpgradeConfig) do
                                if uname:find(cat) and def.price and not d.Upgrades[uname] then
                                    if d.Money >= tonumber(def.price) then
                                        fireRE(R.BuyUpgrade, uname)
                                        Stats.Upgrades = Stats.Upgrades + 1
                                        wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            wait(CONFIG.UpgradeDelay)
        end
    end)

    -- Auto Tower
    spawn(function()
        while isAlive() do
            if State.AutoTower and R.PlayTower then
                pcall(function()
                    if R.CancelTower then invokeRF(R.CancelTower) end
                    wait(1)
                    if R.EquipBestTower then fireRE(R.EquipBestTower) end
                    wait(1)
                    local tr = invokeRF(R.PlayTower, CONFIG.TowerName)
                    if tr then
                        Stats.TowerRuns = Stats.TowerRuns + 1
                        for i = 1, 200 do
                            if not isAlive() or not State.AutoTower then break end
                            local fr = invokeRF(R.CompleteTowerFloor)
                            if not fr then break end
                            wait(CONFIG.TowerDelay)
                        end
                    end
                end)
            end
            wait(5)
        end
    end)

    -- Auto Codes
    local codesRedeemed = {}
    spawn(function()
        while isAlive() do
            if State.AutoCodes and R.RedeemCode then
                for _, code in ipairs(CONFIG.Codes) do
                    if not isAlive() or not State.AutoCodes then break end
                    if not codesRedeemed[code] then
                        fireRE(R.RedeemCode, code)
                        codesRedeemed[code] = true
                        Stats.Codes = Stats.Codes + 1
                        wait(CONFIG.CodeDelay)
                    end
                end
            end
            wait(30)
        end
    end)

    -- Auto Claim
    spawn(function()
        while isAlive() do
            if State.AutoClaim then
                if R.ClaimOffline then fireRE(R.ClaimOffline) end
                wait(0.3)
                if R.ClaimDaily then fireRE(R.ClaimDaily) end
                wait(0.3)
                if R.ClaimGroup then fireRE(R.ClaimGroup) end
                wait(0.3)
                if R.QuestClaim then fireRE(R.QuestClaim) end
            end
            wait(CONFIG.ClaimDelay)
        end
    end)

    -- Auto Boost
    spawn(function()
        while isAlive() do
            if State.AutoBoost and R.BoostUse then
                for _, bn in ipairs(CONFIG.BoostNames) do
                    fireRE(R.BoostUse, bn)
                    wait(0.3)
                end
            end
            wait(CONFIG.BoostDelay)
        end
    end)

    -- Auto Spin
    spawn(function()
        while isAlive() do
            if State.AutoSpin and R.UseSpin then
                for _, sn in ipairs(CONFIG.SpinNames) do
                    fireRE(R.UseSpin, sn)
                    wait(0.5)
                end
            end
            wait(CONFIG.SpinDelay)
        end
    end)

    -- Auto Level
    spawn(function()
        while isAlive() do
            if State.AutoLevel and R.LevelUpSlot then
                pcall(function()
                    local d = getData()
                    if d and d.Money then
                        local maxSlots = 15
                        pcall(function()
                            if PlotConfig and PlotConfig.GetMaxSlots then
                                maxSlots = PlotConfig.GetMaxSlots(d.Rebirth or 0) or 15
                            end
                        end)
                        for slot = 1, maxSlots do
                            if not isAlive() or not State.AutoLevel then break end
                            fireRE(R.LevelUpSlot, slot)
                            wait(0.2)
                        end
                    end
                end)
            end
            wait(CONFIG.LevelDelay)
        end
    end)

    -- Auto Stats
    spawn(function()
        while isAlive() do
            if State.AutoStats and R.AddStat then
                fireRE(R.AddStat, CONFIG.RebirthStatPick)
            end
            wait(CONFIG.StatsDelay)
        end
    end)

    -- Status updater
    spawn(function()
        while isAlive() do
            pcall(function()
                if StatusText then
                    local elapsed = tick() - Stats.StartTime
                    local d = getData()
                    local money = d and formatNum(d.Money) or "?"
                    StatusText.Text = string.format("T:%s $%s R:%s S:%s RB:%s",
                        formatTime(elapsed), money,
                        formatNum(Stats.Rolled), formatNum(Stats.Sold),
                        tostring(Stats.Rebirths))
                end
            end)
            wait(1)
        end
    end)

    -- Respawn handler
    Player.CharacterAdded:Connect(function()
        wait(2)
        notify("AFK Hub", "Respawn - Script tetap aktif", 2)
    end)

    print("[AnimeDice] ALL MODULES STARTED!")
end)
