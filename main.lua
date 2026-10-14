--[[
    JAKIDICE AFK HUB v3.2 — DELTA EXECUTOR
    
    loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/ahmdmzkiid-lgtm/animedicejek@main/main.lua", true))()
]]

print("[JakiDice] v3.2 Starting...")

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Player     = Players.LocalPlayer

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
_G.__JAKIDICE_HUB = (_G.__JAKIDICE_HUB or 0) + 1
local GENERATION = _G.__JAKIDICE_HUB
if _G.__JAKIDICE_HUB_GUI then
    pcall(function() _G.__JAKIDICE_HUB_GUI:Destroy() end)
end
local function isAlive() return _G.__JAKIDICE_HUB == GENERATION end

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
    pcall(function() StarterGui:SetCore("SendNotification", {Title=title or "JakiDice", Text=text or "", Duration=dur or 3}) end)
end

-- ═══ REMOTE HELPERS (no varargs) ═══
local R = {}
local function fireRE(remote, arg1, arg2)
    if not remote then return end
    pcall(function()
        if arg2 ~= nil then
            remote:FireServer(arg1, arg2)
        elseif arg1 ~= nil then
            remote:FireServer(arg1)
        else
            remote:FireServer()
        end
    end)
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
local Dice, Rebirths, PlotConfig, UpgradeConfig

-- ══════════════════════════════════════════════════
-- GUI — TAB SYSTEM, MOBILE FRIENDLY
-- ══════════════════════════════════════════════════
local StatusText

local function createGUI()
    local BG       = Color3.fromRGB(15, 15, 25)
    local BG2      = Color3.fromRGB(25, 25, 40)
    local DARK     = Color3.fromRGB(10, 10, 18)
    local ACCENT   = Color3.fromRGB(130, 70, 255)
    local ACCENT2  = Color3.fromRGB(90, 50, 200)
    local GREEN    = Color3.fromRGB(50, 205, 100)
    local RED      = Color3.fromRGB(220, 55, 55)
    local WHITE    = Color3.fromRGB(255, 255, 255)
    local GRAY     = Color3.fromRGB(160, 160, 180)
    local DIMWHITE = Color3.fromRGB(220, 220, 235)
    local TABBG    = Color3.fromRGB(20, 18, 32)
    local TABACT   = Color3.fromRGB(130, 70, 255)
    local TABINACT = Color3.fromRGB(35, 32, 55)

    local sg = Instance.new("ScreenGui")
    sg.Name = "JakiDiceHub"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
    if not parented then return nil end
    _G.__JAKIDICE_HUB_GUI = sg

    -- ═══ MAIN FRAME ═══
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 340, 0, 400)
    Main.Position = UDim2.new(0.5, -170, 0.5, -200)
    Main.BackgroundColor3 = BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = sg
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = ACCENT
    stroke.Thickness = 2
    stroke.Transparency = 0.3

    -- ═══ HEADER ═══
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = DARK
    Header.BorderSizePixel = 0
    Header.Parent = Main
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)
    local hGrad = Instance.new("UIGradient", Header)
    hGrad.Color = ColorSequence.new(DARK, Color3.fromRGB(20, 15, 35))
    hGrad.Rotation = 90

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -55, 0, 24)
    TitleLabel.Position = UDim2.new(0, 14, 0, 5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "JakiDice Hub"
    TitleLabel.TextColor3 = WHITE
    TitleLabel.TextSize = 18
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -55, 0, 16)
    SubLabel.Position = UDim2.new(0, 14, 0, 30)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = "Anime Dice AFK Automation"
    SubLabel.TextColor3 = GRAY
    SubLabel.TextSize = 10
    SubLabel.Font = Enum.Font.GothamMedium
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -42, 0, 9)
    CloseBtn.BackgroundColor3 = RED
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = WHITE
    CloseBtn.TextSize = 15
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Header
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

    -- ═══ TAB BAR ═══
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -16, 0, 34)
    TabBar.Position = UDim2.new(0, 8, 0, 54)
    TabBar.BackgroundColor3 = TABBG
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

    local TabLayout = Instance.new("UIListLayout", TabBar)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 3)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local tabPad = Instance.new("UIPadding", TabBar)
    tabPad.PaddingLeft = UDim.new(0, 3)
    tabPad.PaddingTop = UDim.new(0, 3)

    -- ═══ CONTENT PAGES (satu per tab) ═══
    local pages = {}
    local tabButtons = {}

    local function createPage()
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, -16, 1, -140)
        page.Position = UDim2.new(0, 8, 0, 92)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = ACCENT
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = Main

        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        return page
    end

    -- Bikin 4 halaman
    local pageMain  = createPage()
    local pageFarm  = createPage()
    local pageExtra = createPage()
    local pageMisc  = createPage()

    pages = {pageMain, pageFarm, pageExtra, pageMisc}
    local tabNames = {"Main", "Farm", "Extra", "Misc"}
    local activeTab = 1

    local function switchTab(idx)
        activeTab = idx
        for i, p in ipairs(pages) do
            p.Visible = (i == idx)
        end
        for i, btn in ipairs(tabButtons) do
            if i == idx then
                btn.BackgroundColor3 = TABACT
                btn.TextColor3 = WHITE
            else
                btn.BackgroundColor3 = TABINACT
                btn.TextColor3 = GRAY
            end
        end
    end

    -- Bikin tab buttons
    for i, name in ipairs(tabNames) do
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(0, 78, 0, 28)
        tb.BackgroundColor3 = (i == 1) and TABACT or TABINACT
        tb.Text = name
        tb.TextColor3 = (i == 1) and WHITE or GRAY
        tb.TextSize = 12
        tb.Font = Enum.Font.GothamBold
        tb.BorderSizePixel = 0
        tb.LayoutOrder = i
        tb.Parent = TabBar
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)

        local tabIdx = i
        tb.MouseButton1Click:Connect(function()
            switchTab(tabIdx)
        end)

        table.insert(tabButtons, tb)
    end

    -- Show first tab
    pageMain.Visible = true

    -- ═══ STATUS BAR ═══
    local SBar = Instance.new("Frame")
    SBar.Size = UDim2.new(1, -16, 0, 38)
    SBar.Position = UDim2.new(0, 8, 1, -44)
    SBar.BackgroundColor3 = DARK
    SBar.BorderSizePixel = 0
    SBar.Parent = Main
    Instance.new("UICorner", SBar).CornerRadius = UDim.new(0, 8)

    StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -14, 1, 0)
    StatusText.Position = UDim2.new(0, 7, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.TextColor3 = GRAY
    StatusText.TextSize = 11
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Text = "Loading..."
    StatusText.Parent = SBar

    -- ═══ TOGGLE FACTORY ═══
    local function addToggle(page, displayName, stateKey, order)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 40)
        Row.BackgroundColor3 = BG2
        Row.BorderSizePixel = 0
        Row.LayoutOrder = order
        Row.Parent = page
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 9)

        local AccentBar = Instance.new("Frame")
        AccentBar.Size = UDim2.new(0, 4, 0, 26)
        AccentBar.Position = UDim2.new(0, 0, 0.5, -13)
        AccentBar.BackgroundColor3 = State[stateKey] and GREEN or ACCENT2
        AccentBar.BorderSizePixel = 0
        AccentBar.Parent = Row
        Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(0, 2)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -85, 1, 0)
        Label.Position = UDim2.new(0, 16, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = displayName
        Label.TextColor3 = DIMWHITE
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamSemibold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Row

        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 58, 0, 26)
        Btn.Position = UDim2.new(1, -68, 0.5, -13)
        Btn.BackgroundColor3 = State[stateKey] and GREEN or RED
        Btn.Text = State[stateKey] and "ON" or "OFF"
        Btn.TextColor3 = WHITE
        Btn.TextSize = 13
        Btn.Font = Enum.Font.GothamBold
        Btn.BorderSizePixel = 0
        Btn.Parent = Row
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 7)

        Btn.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            Btn.BackgroundColor3 = State[stateKey] and GREEN or RED
            Btn.Text = State[stateKey] and "ON" or "OFF"
            AccentBar.BackgroundColor3 = State[stateKey] and GREEN or ACCENT2
        end)
    end

    -- Tab 1: Main (core gameplay)
    addToggle(pageMain, "Auto Roll",     "AutoRoll",    1)
    addToggle(pageMain, "Auto Collect",  "AutoCollect", 2)
    addToggle(pageMain, "Auto Sell",     "AutoSell",    3)
    addToggle(pageMain, "Auto Rebirth",  "AutoRebirth", 4)

    -- Tab 2: Farm (grinding)
    addToggle(pageFarm, "Auto Tower",    "AutoTower",   1)
    addToggle(pageFarm, "Auto Dice",     "AutoDice",    2)
    addToggle(pageFarm, "Auto Upgrade",  "AutoUpgrade", 3)
    addToggle(pageFarm, "Auto Level",    "AutoLevel",   4)

    -- Tab 3: Extra (bonus stuff)
    addToggle(pageExtra, "Auto Spin",    "AutoSpin",    1)
    addToggle(pageExtra, "Auto Boost",   "AutoBoost",   2)
    addToggle(pageExtra, "Auto Claim",   "AutoClaim",   3)
    addToggle(pageExtra, "Auto Codes",   "AutoCodes",   4)

    -- Tab 4: Misc
    addToggle(pageMisc, "Auto Stats",    "AutoStats",   1)
    addToggle(pageMisc, "Anti-AFK",      "AntiAFK",     2)

    -- ═══ FLOATING ICON (saat close) ═══
    local iconBtn = Instance.new("TextButton")
    iconBtn.Size = UDim2.new(0, 48, 0, 48)
    iconBtn.Position = UDim2.new(0, 10, 0.5, -24)
    iconBtn.BackgroundColor3 = ACCENT
    iconBtn.Text = "JD"
    iconBtn.TextColor3 = WHITE
    iconBtn.TextSize = 18
    iconBtn.Font = Enum.Font.GothamBlack
    iconBtn.BorderSizePixel = 0
    iconBtn.Visible = false
    iconBtn.Active = true
    iconBtn.Draggable = true
    iconBtn.Parent = sg
    Instance.new("UICorner", iconBtn).CornerRadius = UDim.new(1, 0)

    local iconStroke = Instance.new("UIStroke", iconBtn)
    iconStroke.Color = WHITE
    iconStroke.Thickness = 2
    iconStroke.Transparency = 0.3

    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        iconBtn.Visible = true
    end)
    iconBtn.MouseButton1Click:Connect(function()
        Main.Visible = true
        iconBtn.Visible = false
    end)

    return sg
end

-- CREATE GUI
local guiOk, guiErr = pcall(createGUI)
if guiOk then
    print("[JakiDice] GUI created!")
    notify("JakiDice", "GUI loaded! Loading remotes...", 3)
else
    warn("[JakiDice] GUI error: " .. tostring(guiErr))
end

-- ══════════════════════════════════════════════════
-- LOAD REMOTES (background)
-- ══════════════════════════════════════════════════
spawn(function()
    wait(2)

    local Network = nil
    pcall(function()
        Network = RS:FindFirstChild("Network")
        if not Network then Network = RS:WaitForChild("Network", 10) end
    end)

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

    pcall(function()
        R.RollDice           = svc("RollService.RF.RollDice")
        R.SetAutoRoll        = svc("RollService.RE.SetAutoRoll")
        R.EquipBest          = svc("PlotService.RE.EquipBest")
        R.CollectBalance     = svc("PlotService.RE.CollectBalance")
        R.LevelUpSlot        = svc("PlotService.RE.LevelUpSlot")
        R.InteractSlot       = svc("PlotService.RE.InteractSlot")
        R.BuyDice            = svc("DiceShopService.RE.BuyDice")
        R.EquipDice          = svc("DiceShopService.RE.EquipDice")
        R.Rebirth            = svc("RebirthService.RE.Rebirth")
        R.AddStat            = svc("RebirthService.RE.AddStat")
        R.SellInventory      = svc("SellService.RF.SellInventory")
        R.UpdateAutoSell     = svc("SellService.RE.UpdateAutoSell")
        R.BuyUpgrade         = svc("RE.BuyUpgrade")
        R.RedeemCode         = svc("CodesService.RE.RedeemCode") or svc("MonetizationService.RE.RedeemCode")
        R.PlayTower          = svc("Towers.RF.PlayTower")
        R.CompleteTowerFloor = svc("Towers.RF.CompleteTowerFloor")
        R.CancelTower        = svc("Towers.RF.CancelTower")
        R.EquipBestTower     = svc("Towers.RE.EquipBestTowerTeam")
        R.ClaimOffline       = svc("OfflineEarningsService.RE.Claim")
        R.ClaimDaily         = svc("DailyRewardService.RE.Claim")
        R.ClaimGroup         = svc("GroupRewardService.RE.Claim")
        R.GradeRoll          = svc("GradeService.RE.Roll")
        R.TraitRoll          = svc("TraitService.RE.Roll")
        R.BoostUse           = svc("BoostService.RE.Use")
        R.UseSpin            = svc("SpinService.RE.Use")
        R.Fuse               = svc("FusingService.RE.Fuse")
        R.QuestClaim         = svc("QuestService.RE.Claim")
        R.QuestBuy           = svc("QuestService.RE.Buy")
    end)

    local found, missing = 0, 0
    for k, v in pairs(R) do
        if v then found = found + 1 else missing = missing + 1 end
    end

    local Framework = nil
    pcall(function()
        Framework = RS:FindFirstChild("Framework")
        if not Framework then Framework = RS:WaitForChild("Framework", 5) end
    end)
    if Framework then
        pcall(function() DataController = require(Framework.Features.Data.DataController) end)
        pcall(function() Dice           = require(Framework.Features.Rolling.Dice) end)
        pcall(function() Rebirths       = require(Framework.Features.Rebirth.Rebirths) end)
        pcall(function() PlotConfig     = require(Framework.Features.Plot.PlotConfig) end)
        pcall(function() UpgradeConfig  = require(Framework.Features.Upgrades.Upgrades) end)
    end

    if StatusText then StatusText.Text = found .. " remotes ready" end
    notify("JakiDice", found .. " remotes loaded!", 3)

    -- ═══ MODULES ═══

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

    spawn(function()
        while isAlive() do
            if State.AutoRoll and R.RollDice then
                local result = invokeRF(R.RollDice)
                if result then Stats.Rolled = Stats.Rolled + 1 end
            end
            wait(CONFIG.RollDelay)
        end
    end)

    spawn(function()
        while isAlive() do
            if State.AutoCollect and R.EquipBest then
                fireRE(R.EquipBest)
                Stats.Collected = Stats.Collected + 1
            end
            wait(CONFIG.CollectDelay)
        end
    end)

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
                    StatusText.Text = string.format("%s | $%s | R:%s | S:%s",
                        formatTime(elapsed), money,
                        formatNum(Stats.Rolled), formatNum(Stats.Sold))
                end
            end)
            wait(1)
        end
    end)

    Player.CharacterAdded:Connect(function()
        wait(2)
        notify("JakiDice", "Respawn - Script tetap aktif", 2)
    end)

    print("[JakiDice] ALL MODULES STARTED!")
end)
