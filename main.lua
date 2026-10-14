--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║          🎲 ANIME DICE AFK HUB v2.1 — DELTA EXECUTOR 🎲        ║
    ║                                                                  ║
    ║  Copas link ini ke Delta Executor:                               ║
    ║  loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/          ║
    ║    ahmdmzkiid-lgtm/animedicejek@main/main.lua", true))()        ║
    ║                                                                  ║
    ║  Struktur Remote: ReplicatedStorage.Network.[Service].[RE/RF]    ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  STAGE 0: BASIC PRINT TEST — kalau ini ga keluar, Delta    ║
-- ║  belum inject. Kalau keluar, lanjut.                        ║
-- ╚══════════════════════════════════════════════════════════════╝
print("==============================================")
print("  [AnimeDice] v2.1 STARTING...")
print("==============================================")

-- ╔══════════════════════════════════════════════════════════════╗
-- ║                     KONFIGURASI USER                         ║
-- ║         Edit bagian ini sesuai kebutuhan kamu                ║
-- ╚══════════════════════════════════════════════════════════════╝

local CONFIG = {
    -- ═══ TIMING (detik) ═══
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

    -- ═══ AUTO SELL FILTER ═══
    SellBelowRarity = 3,
    KeepBestSpares  = 20,

    -- ═══ AUTO REBIRTH ═══
    RebirthMultiplier = 1,

    -- ═══ AUTO TOWER ═══
    TowerName = nil,

    -- ═══ AUTO UPGRADE ═══
    UpgradeCategories = {"Money", "Luck", "Fortune", "Roll Speed", "Unit Storage", "Sell"},

    -- ═══ CODES ═══
    Codes = {
        "RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4", "UPDATE5",
        "SORRY", "THANKYOU", "100KLIKES", "200KLIKES", "CODES", "FREE",
    },

    -- ═══ BOOST / SPIN ═══
    BoostNames = {"Luck", "Income", "Roll Speed"},
    SpinNames  = {"Lucky Spin", "Jackpot Spin"},

    -- ═══ AUTO LEVEL SLOTS ═══
    LevelShare  = 0.3,

    -- ═══ AUTO REBIRTH STATS ═══
    RebirthStatPick = "Money",
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║                  JANGAN EDIT DI BAWAH INI                    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- SAFE SERVICE GETTER
-- Beberapa service (VirtualInputManager, VirtualUser)
-- ga ada di semua executor. Harus pcall.
-- ═══════════════════════════════════════
local function safeGetService(name)
    local ok, svc = pcall(function()
        return game:GetService(name)
    end)
    if ok and svc then
        return svc
    end
    warn("[AnimeDice] Service '" .. name .. "' tidak tersedia di executor ini")
    return nil
end

print("[AnimeDice] Loading services...")

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Services yang MUNGKIN ga ada di mobile executor
local UIS = safeGetService("UserInputService")
local VIM = safeGetService("VirtualInputManager")
local VU  = safeGetService("VirtualUser")

print("[AnimeDice] Services loaded OK")

-- ═══════════════════════════════════════
-- PLAYER & CHARACTER (safe, no infinite wait)
-- ═══════════════════════════════════════
local Player = Players.LocalPlayer
if not Player then
    warn("[AnimeDice] LocalPlayer nil! Aborting.")
    return
end
print("[AnimeDice] Player: " .. Player.Name)

local Character = Player.Character
if not Character then
    print("[AnimeDice] Waiting for character (max 10s)...")
    local startWait = tick()
    local charConn
    local charReady = false

    charConn = Player.CharacterAdded:Connect(function(c)
        Character = c
        charReady = true
    end)

    while not charReady and (tick() - startWait) < 10 do
        wait(0.5)
    end

    if charConn then charConn:Disconnect() end

    if not Character then
        Character = Player.Character
    end

    if not Character then
        warn("[AnimeDice] Character tidak muncul dalam 10 detik. Lanjut tanpa character.")
    end
end
print("[AnimeDice] Character: " .. tostring(Character and Character.Name or "none"))

-- ═══════════════════════════════════════
-- GENERATION GUARD (safe re-execute)
-- ═══════════════════════════════════════
_G.__ANIMEDICE_HUB = (_G.__ANIMEDICE_HUB or 0) + 1
local GENERATION = _G.__ANIMEDICE_HUB
if _G.__ANIMEDICE_HUB_GUI then
    pcall(function() _G.__ANIMEDICE_HUB_GUI:Destroy() end)
end

local function isAlive()
    return _G.__ANIMEDICE_HUB == GENERATION
end

-- ═══════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════
local State = {
    AutoRoll      = false,
    AutoSell      = false,
    AutoCollect   = true,
    AutoRebirth   = false,
    AutoTower     = false,
    AutoUpgrade   = false,
    AutoDice      = false,
    AutoCodes     = false,
    AutoClaim     = false,
    AutoBoost     = false,
    AutoSpin      = false,
    AutoLevel     = false,
    AutoStats     = false,
    AntiAFK       = true,
    Running       = true,
    GUIVisible    = true,
}

local Stats = {
    Rolled    = 0,
    Sold      = 0,
    Collected = 0,
    Rebirths  = 0,
    DiceBought = 0,
    Codes     = 0,
    TowerRuns = 0,
    Upgrades  = 0,
    StartTime = tick(),
}

-- ═══════════════════════════════════════
-- REMOTE SETUP (full pcall protection)
-- ═══════════════════════════════════════
print("[AnimeDice] Looking for Network folder...")
local Network, Framework

local netOk, netErr = pcall(function()
    Network = RS:WaitForChild("Network", 10)
end)
if not netOk then
    warn("[AnimeDice] Error waiting for Network: " .. tostring(netErr))
end

local fwOk, fwErr = pcall(function()
    Framework = RS:WaitForChild("Framework", 10)
end)
if not fwOk then
    warn("[AnimeDice] Error waiting for Framework: " .. tostring(fwErr))
end

if Network then
    print("[AnimeDice] ✅ Network folder found!")
else
    warn("[AnimeDice] ❌ Network folder NOT found!")
    warn("[AnimeDice] GUI will still appear, but remotes won't work.")
    warn("[AnimeDice] Make sure you Execute AFTER the game fully loads.")
end

if Framework then
    print("[AnimeDice] ✅ Framework folder found!")
else
    warn("[AnimeDice] ❌ Framework folder NOT found!")
end

-- Helper: navigate nested path under Network
local function svc(path)
    if not Network then return nil end
    local ok, result = pcall(function()
        local node = Network
        for part in string.gmatch(path, "[^%.]+") do
            if not node then return nil end
            node = node:FindFirstChild(part)
        end
        return node
    end)
    return ok and result or nil
end

-- All remotes
print("[AnimeDice] Loading remotes...")
local R = {}

local remoteOk, remoteErr = pcall(function()
    R = {
        -- Rolling
        RollDice        = svc("RollService.RF.RollDice"),
        SetAutoRoll     = svc("RollService.RE.SetAutoRoll"),

        -- Plot / Income
        EquipBest       = svc("PlotService.RE.EquipBest"),
        CollectBalance  = svc("PlotService.RE.CollectBalance"),
        LevelUpSlot     = svc("PlotService.RE.LevelUpSlot"),
        InteractSlot    = svc("PlotService.RE.InteractSlot"),

        -- Dice Shop
        BuyDice         = svc("DiceShopService.RE.BuyDice"),
        EquipDice       = svc("DiceShopService.RE.EquipDice"),

        -- Rebirth
        Rebirth         = svc("RebirthService.RE.Rebirth"),
        AddStat         = svc("RebirthService.RE.AddStat"),

        -- Sell
        SellInventory   = svc("SellService.RF.SellInventory"),
        UpdateAutoSell  = svc("SellService.RE.UpdateAutoSell"),

        -- Upgrades
        BuyUpgrade      = svc("RE.BuyUpgrade"),

        -- Codes
        RedeemCode      = svc("CodesService.RE.RedeemCode") or svc("MonetizationService.RE.RedeemCode"),

        -- Tower
        PlayTower       = svc("Towers.RF.PlayTower"),
        CompleteTowerFloor = svc("Towers.RF.CompleteTowerFloor"),
        CancelTower     = svc("Towers.RF.CancelTower"),
        EquipBestTower  = svc("Towers.RE.EquipBestTowerTeam"),

        -- Claims / Rewards
        ClaimOffline    = svc("OfflineEarningsService.RE.Claim"),
        ClaimDaily      = svc("DailyRewardService.RE.Claim"),
        ClaimGroup      = svc("GroupRewardService.RE.Claim"),

        -- Quality: Grade & Trait
        GradeRoll       = svc("GradeService.RE.Roll"),
        TraitRoll       = svc("TraitService.RE.Roll"),

        -- Boosts
        BoostUse        = svc("BoostService.RE.Use"),

        -- Spins
        UseSpin         = svc("SpinService.RE.Use"),

        -- Fuse
        Fuse            = svc("FusingService.RE.Fuse"),
        FuseResult      = svc("FusingService.RE.Result"),

        -- Quests
        QuestClaim      = svc("QuestService.RE.Claim"),
        QuestBuy        = svc("QuestService.RE.Buy"),
    }
end)

if not remoteOk then
    warn("[AnimeDice] Error loading remotes: " .. tostring(remoteErr))
    R = {}
end

print("[AnimeDice] Remotes loaded OK")

-- ═══════════════════════════════════════
-- DATA CONTROLLER (live player data)
-- ═══════════════════════════════════════
local DataController
pcall(function()
    if Framework then
        DataController = require(Framework.Features.Data.DataController)
    end
end)

local function getData()
    local ok, result = pcall(function()
        if DataController and DataController.___X then
            return DataController.___X
        end
        return nil
    end)
    return ok and result or nil
end

-- ═══════════════════════════════════════
-- GAME CONFIGS (optional, graceful fail)
-- ═══════════════════════════════════════
local Dice, Rebirths, PlotConfig, UnitConfig, Grades, Traits
local BuffController, TowersConfig, UpgradeConfig

if Framework then
    pcall(function() Dice           = require(Framework.Features.Rolling.Dice) end)
    pcall(function() Rebirths       = require(Framework.Features.Rebirth.Rebirths) end)
    pcall(function() PlotConfig     = require(Framework.Features.Plot.PlotConfig) end)
    pcall(function() UnitConfig     = require(Framework.Features.Inventory.Kinds.Unit.UnitConfig) end)
    pcall(function() Grades         = require(Framework.Features.Grades.Grades) end)
    pcall(function() Traits         = require(Framework.Features.Traits.Traits) end)
    pcall(function() BuffController = require(Framework.Features.Buffs.BuffController) end)
    pcall(function() TowersConfig   = require(Framework.Features.Towers.Towers) end)
    pcall(function() UpgradeConfig  = require(Framework.Features.Upgrades.Upgrades) end)
end

print("[AnimeDice] Game configs loaded OK")

-- ═══════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "AFK Hub",
            Text = text or "",
            Duration = duration or 3,
        })
    end)
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function formatNum(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif n >= 1e9 then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(math.floor(n)) end
end

local function fireRE(remote, ...)
    if not remote then return end
    pcall(function() remote:FireServer(...) end)
end

local function invokeRF(remote, ...)
    if not remote then return nil end
    local ok, result = pcall(function() return remote:InvokeServer(...) end)
    return ok and result or nil
end

-- ═══════════════════════════════════════
-- MODULE: ANTI-AFK
-- Pakai VirtualUser + Idled connection
-- VirtualInputManager di-skip kalau ga ada
-- ═══════════════════════════════════════
local function startAntiAFK()
    -- Method 1: Idle connection (paling aman)
    pcall(function()
        if VU then
            Player.Idled:Connect(function()
                pcall(function()
                    VU:CaptureController()
                    VU:ClickButton2(Vector2.new())
                end)
            end)
            print("[AnimeDice] Anti-AFK: VirtualUser OK")
        end
    end)

    -- Method 2: Periodic key press (HANYA kalau VIM tersedia)
    spawn(function()
        while isAlive() do
            if State.AntiAFK then
                if VIM then
                    pcall(function()
                        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        wait(0.1)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end
            end
            wait(CONFIG.AntiAFKDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO ROLL
-- ═══════════════════════════════════════
local function startAutoRoll()
    spawn(function()
        while isAlive() do
            if State.AutoRoll and R.RollDice then
                local result = invokeRF(R.RollDice)
                if result then
                    Stats.Rolled = Stats.Rolled + 1
                end
            end
            wait(CONFIG.RollDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO COLLECT (EquipBest)
-- ═══════════════════════════════════════
local function startAutoCollect()
    spawn(function()
        while isAlive() do
            if State.AutoCollect and R.EquipBest then
                fireRE(R.EquipBest)
                Stats.Collected = Stats.Collected + 1
            end
            wait(CONFIG.CollectDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO SELL
-- ═══════════════════════════════════════
local function startAutoSell()
    spawn(function()
        wait(3)
        if State.AutoSell and R.UpdateAutoSell then
            fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity)
        end
    end)

    spawn(function()
        while isAlive() do
            if State.AutoSell then
                if R.UpdateAutoSell then
                    fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity)
                end
                if R.SellInventory then
                    local result = invokeRF(R.SellInventory)
                    if result then
                        Stats.Sold = Stats.Sold + 1
                    end
                end
            end
            wait(CONFIG.SellDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO REBIRTH
-- ═══════════════════════════════════════
local function startAutoRebirth()
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
                        notify("AFK Hub", "🔄 Rebirth #" .. (d.Rebirth + 1) .. "!", 3)
                        wait(2)
                    end
                end
            end
            wait(CONFIG.RebirthDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO DICE (buy + equip best)
-- ═══════════════════════════════════════
local function startAutoDice()
    spawn(function()
        while isAlive() do
            if State.AutoDice and R.BuyDice and R.EquipDice and Dice then
                local d = getData()
                if d then
                    local allDice = {}
                    pcall(function()
                        local raw = Dice.GetAll()
                        for key, def in pairs(raw) do
                            table.insert(allDice, {
                                key = key,
                                luck = tonumber(def.luck) or 0,
                                price = tonumber(def.price),
                            })
                        end
                        table.sort(allDice, function(a, b) return a.luck < b.luck end)
                    end)

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
            end
            wait(CONFIG.DiceDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO UPGRADE
-- ═══════════════════════════════════════
local function startAutoUpgrade()
    spawn(function()
        while isAlive() do
            if State.AutoUpgrade and R.BuyUpgrade and UpgradeConfig then
                local d = getData()
                if d then
                    pcall(function()
                        for _, cat in ipairs(CONFIG.UpgradeCategories) do
                            for name, def in pairs(UpgradeConfig) do
                                if name:find(cat) and def.price and not d.Upgrades[name] then
                                    if d.Money >= tonumber(def.price) then
                                        fireRE(R.BuyUpgrade, name)
                                        Stats.Upgrades = Stats.Upgrades + 1
                                        wait(0.3)
                                    end
                                end
                            end
                        end
                    end)
                end
            end
            wait(CONFIG.UpgradeDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO TOWER
-- ═══════════════════════════════════════
local function startAutoTower()
    spawn(function()
        while isAlive() do
            if State.AutoTower then
                if R.CancelTower then
                    pcall(function() invokeRF(R.CancelTower) end)
                    wait(1)
                end

                if R.EquipBestTower then
                    fireRE(R.EquipBestTower)
                    wait(1)
                end

                if R.PlayTower then
                    local towerResult = invokeRF(R.PlayTower, CONFIG.TowerName)

                    if towerResult then
                        Stats.TowerRuns = Stats.TowerRuns + 1
                        local maxFloors = 200
                        for i = 1, maxFloors do
                            if not isAlive() or not State.AutoTower then break end
                            local floorResult = invokeRF(R.CompleteTowerFloor)
                            if not floorResult then break end
                            wait(CONFIG.TowerDelay)
                        end
                    else
                        if R.CancelTower then
                            pcall(function() invokeRF(R.CancelTower) end)
                        end
                    end
                end
            end
            wait(5)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO CODES
-- ═══════════════════════════════════════
local codesRedeemed = {}

local function startAutoCodes()
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
end

-- ═══════════════════════════════════════
-- MODULE: AUTO CLAIM
-- ═══════════════════════════════════════
local function startAutoClaim()
    spawn(function()
        while isAlive() do
            if State.AutoClaim then
                if R.ClaimOffline then fireRE(R.ClaimOffline) end
                wait(0.3)
                if R.ClaimDaily  then fireRE(R.ClaimDaily)  end
                wait(0.3)
                if R.ClaimGroup  then fireRE(R.ClaimGroup)  end
                wait(0.3)
                if R.QuestClaim  then fireRE(R.QuestClaim)  end
            end
            wait(CONFIG.ClaimDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO BOOST
-- ═══════════════════════════════════════
local function startAutoBoost()
    spawn(function()
        while isAlive() do
            if State.AutoBoost and R.BoostUse then
                for _, boostName in ipairs(CONFIG.BoostNames) do
                    fireRE(R.BoostUse, boostName)
                    wait(0.3)
                end
            end
            wait(CONFIG.BoostDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO SPIN
-- ═══════════════════════════════════════
local function startAutoSpin()
    spawn(function()
        while isAlive() do
            if State.AutoSpin and R.UseSpin then
                for _, spinName in ipairs(CONFIG.SpinNames) do
                    fireRE(R.UseSpin, spinName)
                    wait(0.5)
                end
            end
            wait(CONFIG.SpinDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO LEVEL SLOT
-- ═══════════════════════════════════════
local function startAutoLevel()
    spawn(function()
        while isAlive() do
            if State.AutoLevel and R.LevelUpSlot then
                local d = getData()
                if d and d.Money then
                    local budget = d.Money * CONFIG.LevelShare
                    local spent = 0

                    local maxSlots = 15
                    pcall(function()
                        if PlotConfig and PlotConfig.GetMaxSlots then
                            maxSlots = PlotConfig.GetMaxSlots(d.Rebirth or 0) or 15
                        end
                    end)

                    for slot = 1, maxSlots do
                        if not isAlive() or not State.AutoLevel then break end
                        if spent >= budget then break end
                        fireRE(R.LevelUpSlot, slot)
                        spent = spent + 1
                        wait(0.2)
                    end
                end
            end
            wait(CONFIG.LevelDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO REBIRTH STATS
-- ═══════════════════════════════════════
local function startAutoStats()
    spawn(function()
        while isAlive() do
            if State.AutoStats and R.AddStat then
                fireRE(R.AddStat, CONFIG.RebirthStatPick)
            end
            wait(CONFIG.StatsDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════
local function createGUI()
    print("[AnimeDice] Creating GUI...")

    local BG     = Color3.fromRGB(18, 18, 28)
    local BG2    = Color3.fromRGB(28, 28, 42)
    local DARK   = Color3.fromRGB(12, 12, 20)
    local ACCENT = Color3.fromRGB(100, 60, 255)
    local GREEN  = Color3.fromRGB(80, 200, 120)
    local RED    = Color3.fromRGB(200, 60, 60)
    local WHITE  = Color3.fromRGB(255, 255, 255)
    local GRAY   = Color3.fromRGB(140, 140, 160)

    -- Try syn.protect_gui or gethui for executor compatibility
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AnimeDiceHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Delta / executor safe parenting
    local guiParented = false

    -- Method 1: gethui() (most executors support this)
    if not guiParented then
        pcall(function()
            if gethui then
                ScreenGui.Parent = gethui()
                guiParented = true
                print("[AnimeDice] GUI parented via gethui()")
            end
        end)
    end

    -- Method 2: syn.protect_gui (Synapse-style)
    if not guiParented then
        pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(ScreenGui)
                ScreenGui.Parent = Player.PlayerGui
                guiParented = true
                print("[AnimeDice] GUI parented via syn.protect_gui")
            end
        end)
    end

    -- Method 3: CoreGui
    if not guiParented then
        pcall(function()
            ScreenGui.Parent = game:GetService("CoreGui")
            guiParented = true
            print("[AnimeDice] GUI parented to CoreGui")
        end)
    end

    -- Method 4: PlayerGui (fallback)
    if not guiParented then
        pcall(function()
            ScreenGui.Parent = Player.PlayerGui
            guiParented = true
            print("[AnimeDice] GUI parented to PlayerGui")
        end)
    end

    if not guiParented then
        warn("[AnimeDice] GAGAL parent GUI! Tidak bisa menampilkan UI.")
        return nil
    end

    _G.__ANIMEDICE_HUB_GUI = ScreenGui

    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 300, 0, 580)
    Main.Position = UDim2.new(0.5, -150, 0.5, -290)
    Main.BackgroundColor3 = BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local mc = Instance.new("UICorner", Main)
    mc.CornerRadius = UDim.new(0, 10)
    local ms = Instance.new("UIStroke", Main)
    ms.Color = ACCENT
    ms.Thickness = 2

    -- Title
    local Title = Instance.new("Frame")
    Title.Size = UDim2.new(1, 0, 0, 42)
    Title.BackgroundColor3 = DARK
    Title.BorderSizePixel = 0
    Title.Parent = Main
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -50, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "Anime Dice AFK Hub"
    TitleText.TextColor3 = WHITE
    TitleText.TextSize = 15
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = Title

    -- Close/Minimize btn
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -36, 0, 7)
    MinBtn.BackgroundColor3 = RED
    MinBtn.Text = "X"
    MinBtn.TextColor3 = WHITE
    MinBtn.TextSize = 14
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = Title
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- Scroll
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -16, 1, -96)
    Scroll.Position = UDim2.new(0, 8, 0, 48)
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
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, -16, 0, 36)
    StatusBar.Position = UDim2.new(0, 8, 1, -42)
    StatusBar.BackgroundColor3 = DARK
    StatusBar.BorderSizePixel = 0
    StatusBar.Parent = Main
    Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 6)

    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "Status"
    StatusText.Size = UDim2.new(1, -10, 1, 0)
    StatusText.Position = UDim2.new(0, 8, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.TextColor3 = GRAY
    StatusText.TextSize = 10
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Text = "Loading..."
    StatusText.Parent = StatusBar

    -- Toggle factory
    local function addToggle(name, stateKey, order)
        local F = Instance.new("Frame")
        F.Size = UDim2.new(1, 0, 0, 34)
        F.BackgroundColor3 = BG2
        F.BorderSizePixel = 0
        F.LayoutOrder = order
        F.Parent = Scroll
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 7)

        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -70, 1, 0)
        L.Position = UDim2.new(0, 10, 0, 0)
        L.BackgroundTransparency = 1
        L.Text = name
        L.TextColor3 = WHITE
        L.TextSize = 13
        L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = F

        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, 50, 0, 22)
        B.Position = UDim2.new(1, -58, 0.5, -11)
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

            if stateKey == "AutoSell" and State.AutoSell and R.UpdateAutoSell then
                fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity)
            end
        end)
    end

    addToggle("Auto Roll",     "AutoRoll",    1)
    addToggle("Auto Sell",     "AutoSell",    2)
    addToggle("Auto Collect",  "AutoCollect",  3)
    addToggle("Auto Rebirth",  "AutoRebirth",  4)
    addToggle("Auto Tower",    "AutoTower",    5)
    addToggle("Auto Dice",     "AutoDice",     6)
    addToggle("Auto Upgrade",  "AutoUpgrade",  7)
    addToggle("Auto Spin",     "AutoSpin",     8)
    addToggle("Auto Level",    "AutoLevel",    9)
    addToggle("Auto Claim",    "AutoClaim",   10)
    addToggle("Auto Codes",    "AutoCodes",   11)
    addToggle("Auto Boost",    "AutoBoost",   12)
    addToggle("Auto Stats",    "AutoStats",   13)
    addToggle("Anti-AFK",      "AntiAFK",     14)

    -- Minimize handler — hide content, show small button
    local minimized = false
    local openBtn

    -- Small "open" button when minimized
    openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 100, 0, 36)
    openBtn.Position = UDim2.new(0, 10, 0, 10)
    openBtn.BackgroundColor3 = ACCENT
    openBtn.Text = "AFK Hub"
    openBtn.TextColor3 = WHITE
    openBtn.TextSize = 13
    openBtn.Font = Enum.Font.GothamBold
    openBtn.BorderSizePixel = 0
    openBtn.Visible = false
    openBtn.Active = true
    openBtn.Draggable = true
    openBtn.Parent = ScreenGui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)

    MinBtn.MouseButton1Click:Connect(function()
        minimized = true
        Main.Visible = false
        openBtn.Visible = true
    end)

    openBtn.MouseButton1Click:Connect(function()
        minimized = false
        Main.Visible = true
        openBtn.Visible = false
    end)

    -- Status updater
    spawn(function()
        while isAlive() do
            pcall(function()
                local elapsed = tick() - Stats.StartTime
                local d = getData()
                local moneyStr = d and formatNum(d.Money) or "?"

                StatusText.Text = string.format(
                    "T:%s | $%s | Roll:%s | Sell:%s | RB:%s",
                    formatTime(elapsed),
                    moneyStr,
                    formatNum(Stats.Rolled),
                    formatNum(Stats.Sold),
                    tostring(Stats.Rebirths)
                )
            end)
            wait(1)
        end
    end)

    print("[AnimeDice] GUI created successfully!")
    return ScreenGui
end

-- ═══════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════
local function init()
    print("==============================================")
    print("  Anime Dice AFK Hub v2.1 — Initializing")
    print("==============================================")

    -- Log remote status
    local found, missing = 0, 0
    for name, remote in pairs(R) do
        if remote then
            found = found + 1
        else
            missing = missing + 1
            warn("  [Remote Missing] " .. name)
        end
    end
    print("  Remotes: " .. found .. " found, " .. missing .. " missing")

    -- Log data controller
    local d = getData()
    if d then
        print("  DataController: OK")
        print("  Money: " .. formatNum(d.Money or 0))
        print("  Rebirth: " .. tostring(d.Rebirth or 0))
    else
        warn("  DataController: not available (some features may not work)")
    end

    -- Create GUI
    local guiOk, guiErr = pcall(createGUI)
    if not guiOk then
        warn("[AnimeDice] GUI Error: " .. tostring(guiErr))
        warn("[AnimeDice] Script will continue without GUI")
    end

    pcall(function()
        notify("AFK Hub", "Anime Dice AFK Hub v2.1 loaded!", 4)
    end)

    -- Start ALL modules
    print("[AnimeDice] Starting modules...")
    pcall(startAntiAFK)
    pcall(startAutoRoll)
    pcall(startAutoCollect)
    pcall(startAutoSell)
    pcall(startAutoRebirth)
    pcall(startAutoDice)
    pcall(startAutoUpgrade)
    pcall(startAutoTower)
    pcall(startAutoCodes)
    pcall(startAutoClaim)
    pcall(startAutoBoost)
    pcall(startAutoSpin)
    pcall(startAutoLevel)
    pcall(startAutoStats)

    -- Respawn handler
    Player.CharacterAdded:Connect(function(char)
        Character = char
        wait(2)
        notify("AFK Hub", "Respawn — Script tetap aktif", 2)
    end)

    print("==============================================")
    print("  ALL MODULES STARTED!")
    print("  GUI should be visible on screen.")
    print("  If no GUI, check console for errors above.")
    print("==============================================")
end

-- ═══════════════════════════════════════
-- RUN
-- ═══════════════════════════════════════
local ok, err = pcall(init)
if not ok then
    warn("[AnimeDice] FATAL ERROR: " .. tostring(err))
    warn("[AnimeDice] Send this error to the developer.")
end
