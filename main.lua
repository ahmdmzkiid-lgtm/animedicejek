--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║          🎲 ANIME DICE AFK HUB v2.0 — DELTA EXECUTOR 🎲        ║
    ║                                                                  ║
    ║  Remote paths SUDAH DIISI dari source code open-source.          ║
    ║  Paste SELURUH script ini ke Delta Executor lalu Execute.        ║
    ║                                                                  ║
    ║  Struktur Remote: ReplicatedStorage.Network.[Service].[RE/RF]    ║
    ║  Data Controller: ReplicatedStorage.Framework.Features.Data      ║
    ╚══════════════════════════════════════════════════════════════════╝

    REMOTE MAP (verified dari open-source scripts):
    ┌─────────────────────────────────────────────────────────────────┐
    │ RollDice        = Network.RollService.RF.RollDice (InvokeServer)│
    │ EquipBest       = Network.PlotService.RE.EquipBest (FireServer) │
    │ CollectBalance  = Network.PlotService.RE.CollectBalance         │
    │ LevelUpSlot     = Network.PlotService.RE.LevelUpSlot            │
    │ InteractSlot    = Network.PlotService.RE.InteractSlot           │
    │ BuyDice         = Network.DiceShopService.RE.BuyDice            │
    │ EquipDice       = Network.DiceShopService.RE.EquipDice          │
    │ Rebirth         = Network.RebirthService.RE.Rebirth             │
    │ AddStat         = Network.RebirthService.RE.AddStat             │
    │ SellInventory   = Network.SellService.RF.SellInventory          │
    │ UpdateAutoSell  = Network.SellService.RE.UpdateAutoSell         │
    │ BuyUpgrade      = Network.RE.BuyUpgrade                         │
    │ RedeemCode      = Network.CodesService.RE.RedeemCode            │
    │ PlayTower       = Network.Towers.RF.PlayTower (InvokeServer)    │
    │ CompleteTowerFloor = Network.Towers.RF.CompleteTowerFloor       │
    │ CancelTower     = Network.Towers.RF.CancelTower                 │
    │ EquipBestTower  = Network.Towers.RE.EquipBestTowerTeam          │
    │ ClaimOffline    = Network.OfflineEarningsService.RE.Claim        │
    │ ClaimDaily      = Network.DailyRewardService.RE.Claim            │
    │ ClaimGroup      = Network.GroupRewardService.RE.Claim             │
    │ GradeRoll       = Network.GradeService.RE.Roll                   │
    │ TraitRoll       = Network.TraitService.RE.Roll                   │
    │ BoostUse        = Network.BoostService.RE.Use                    │
    │ UseSpin         = Network.SpinService.RE.Use                     │
    │ Fuse            = Network.FusingService.RE.Fuse                  │
    │ QuestClaim      = Network.QuestService.RE.Claim                  │
    │ QuestBuy        = Network.QuestService.RE.Buy                    │
    └─────────────────────────────────────────────────────────────────┘
]]

-- ╔══════════════════════════════════════════════════════════════╗
-- ║                     KONFIGURASI USER                         ║
-- ║         Edit bagian ini sesuai kebutuhan kamu                ║
-- ╚══════════════════════════════════════════════════════════════╝

local CONFIG = {
    -- ═══ TIMING (detik) ═══
    RollDelay       = 2.2,   -- Server cooldown ~2 detik, jangan lebih cepat
    CollectDelay    = 10,    -- EquipBest sekaligus collect + re-place terbaik
    SellDelay       = 5,     -- Check inventory tiap 5 detik
    RebirthDelay    = 15,    -- Check rebirth tiap 15 detik
    TowerDelay      = 1,     -- Delay antar floor tower
    UpgradeDelay    = 10,    -- Check upgrade tiap 10 detik
    DiceDelay       = 10,    -- Check beli dice tiap 10 detik
    CodeDelay       = 2,     -- Delay antar redeem code
    ClaimDelay      = 30,    -- Claim rewards tiap 30 detik
    AntiAFKDelay    = 60,    -- Anti-idle tiap 60 detik
    BoostDelay      = 30,    -- Check boost tiap 30 detik
    SpinDelay       = 3,     -- Delay antar spin usage
    LevelDelay      = 5,     -- Delay antar level up slot
    StatsDelay      = 10,    -- Delay antar rebirth stat add

    -- ═══ AUTO SELL FILTER ═══
    -- Rarity sort order: Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5,
    -- Mythical=6, Divine=7, Exotic=8, Celestial=9, Secret=10, Heavenly=11
    SellBelowRarity = 3,     -- Jual otomatis unit di bawah Rare (1=Common, 2=Uncommon)
    KeepBestSpares  = 20,    -- Simpan 20 unit terbaik saat inventory penuh

    -- ═══ AUTO REBIRTH ═══
    RebirthMultiplier = 1,   -- Rebirth saat uang = cost x multiplier ini

    -- ═══ AUTO TOWER ═══
    TowerName = nil,         -- nil = auto pick tower terbaik

    -- ═══ AUTO UPGRADE ═══
    UpgradeCategories = {"Money", "Luck", "Fortune", "Roll Speed", "Unit Storage", "Sell"},

    -- ═══ CODES (tambahkan code baru di sini) ═══
    Codes = {
        "RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4", "UPDATE5",
        "SORRY", "THANKYOU", "100KLIKES", "200KLIKES", "CODES", "FREE",
    },

    -- ═══ BOOST NAMES ═══
    BoostNames = {"Luck", "Income", "Roll Speed"},

    -- ═══ SPIN NAMES ═══
    SpinNames = {"Lucky Spin", "Jackpot Spin"},

    -- ═══ AUTO LEVEL SLOTS ═══
    LevelShare  = 0.3,   -- Max 30% uang dipakai untuk level up slots

    -- ═══ AUTO REBIRTH STATS ═══
    RebirthStatPick = "Money", -- Stat yang di-upgrade: "Money", "Luck", etc.

    -- ═══ GUI ═══
    ToggleKey = Enum.KeyCode.RightControl,
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║                  JANGAN EDIT DI BAWAH INI                    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")
local VIM               = game:GetService("VirtualInputManager")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

local Player    = Players.LocalPlayer
-- PENTING: jangan :Wait() tanpa batas — bisa nyangkut selamanya kalau
-- karakter belum spawn saat Execute (bikin "ga terjadi apa-apa").
local Character = Player.Character
if not Character then
    Character = Player.CharacterAdded:Wait()
end

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
-- REMOTE SETUP
-- ═══════════════════════════════════════
local Network   = RS:WaitForChild("Network", 5)
local Framework = RS:WaitForChild("Framework", 5)

if not Network then
    warn("[AnimeDice] Folder 'ReplicatedStorage.Network' tidak ditemukan!")
    warn("  Script tetap jalan & GUI muncul, tapi semua remote akan kosong.")
    warn("  Kemungkinan: nama folder beda, atau kamu Execute sebelum game load.")
end
if not Framework then
    warn("[AnimeDice] Folder 'ReplicatedStorage.Framework' tidak ditemukan!")
end

-- Helper: navigate nested path under Network
local function svc(path)
    local node = Network
    for part in string.gmatch(path, "[^%.]+") do
        node = node and node:FindFirstChild(part)
    end
    return node
end

-- All remotes (verified from open-source)
local R = {
    -- Rolling
    RollDice        = svc("RollService.RF.RollDice"),         -- RF (InvokeServer)
    SetAutoRoll     = svc("RollService.RE.SetAutoRoll"),      -- RE

    -- Plot / Income
    EquipBest       = svc("PlotService.RE.EquipBest"),        -- RE: collect + re-equip best
    CollectBalance  = svc("PlotService.RE.CollectBalance"),   -- RE: collect 1 slot
    LevelUpSlot     = svc("PlotService.RE.LevelUpSlot"),      -- RE
    InteractSlot    = svc("PlotService.RE.InteractSlot"),      -- RE

    -- Dice Shop
    BuyDice         = svc("DiceShopService.RE.BuyDice"),      -- RE
    EquipDice       = svc("DiceShopService.RE.EquipDice"),    -- RE

    -- Rebirth
    Rebirth         = svc("RebirthService.RE.Rebirth"),       -- RE
    AddStat         = svc("RebirthService.RE.AddStat"),       -- RE

    -- Sell
    SellInventory   = svc("SellService.RF.SellInventory"),    -- RF (InvokeServer)
    UpdateAutoSell  = svc("SellService.RE.UpdateAutoSell"),   -- RE

    -- Upgrades
    BuyUpgrade      = svc("RE.BuyUpgrade"),                   -- RE (langsung di Network.RE)

    -- Codes
    RedeemCode      = svc("CodesService.RE.RedeemCode") or svc("MonetizationService.RE.RedeemCode"),

    -- Tower
    PlayTower       = svc("Towers.RF.PlayTower"),             -- RF
    CompleteTowerFloor = svc("Towers.RF.CompleteTowerFloor"), -- RF
    CancelTower     = svc("Towers.RF.CancelTower"),           -- RF
    EquipBestTower  = svc("Towers.RE.EquipBestTowerTeam"),    -- RE

    -- Claims / Rewards
    ClaimOffline    = svc("OfflineEarningsService.RE.Claim"), -- RE
    ClaimDaily      = svc("DailyRewardService.RE.Claim"),     -- RE
    ClaimGroup      = svc("GroupRewardService.RE.Claim"),      -- RE

    -- Quality: Grade & Trait
    GradeRoll       = svc("GradeService.RE.Roll"),            -- RE
    TraitRoll       = svc("TraitService.RE.Roll"),             -- RE

    -- Boosts
    BoostUse        = svc("BoostService.RE.Use"),             -- RE

    -- Spins
    UseSpin         = svc("SpinService.RE.Use"),              -- RE

    -- Fuse
    Fuse            = svc("FusingService.RE.Fuse"),           -- RE
    FuseResult      = svc("FusingService.RE.Result"),         -- RE

    -- Quests
    QuestClaim      = svc("QuestService.RE.Claim"),           -- RE
    QuestBuy        = svc("QuestService.RE.Buy"),             -- RE
}

-- ═══════════════════════════════════════
-- DATA CONTROLLER (live player data)
-- ═══════════════════════════════════════
local DataController
pcall(function()
    DataController = require(Framework.Features.Data.DataController)
end)

local function getData()
    if DataController and DataController.___X then
        return DataController.___X
    end
    return nil
end

-- ═══════════════════════════════════════
-- GAME CONFIGS (optional, graceful fail)
-- ═══════════════════════════════════════
local Dice, Rebirths, PlotConfig, UnitConfig, Grades, Traits
local BuffController, TowersConfig, UpgradeConfig

pcall(function() Dice           = require(Framework.Features.Rolling.Dice) end)
pcall(function() Rebirths       = require(Framework.Features.Rebirth.Rebirths) end)
pcall(function() PlotConfig     = require(Framework.Features.Plot.PlotConfig) end)
pcall(function() UnitConfig     = require(Framework.Features.Inventory.Kinds.Unit.UnitConfig) end)
pcall(function() Grades         = require(Framework.Features.Grades.Grades) end)
pcall(function() Traits         = require(Framework.Features.Traits.Traits) end)
pcall(function() BuffController = require(Framework.Features.Buffs.BuffController) end)
pcall(function() TowersConfig   = require(Framework.Features.Towers.Towers) end)
pcall(function() UpgradeConfig  = require(Framework.Features.Upgrades.Upgrades) end)

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
-- ═══════════════════════════════════════
local function startAntiAFK()
    -- Method 1: Idle connection
    pcall(function()
        local VU = game:GetService("VirtualUser")
        Player.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end)

    -- Method 2: Periodic
    spawn(function()
        while isAlive() do
            if State.AntiAFK then
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    wait(0.1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
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
-- EquipBest = collect ALL slot balances
--           + re-place best income units
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
-- UpdateAutoSell sets server-side auto sell
-- ═══════════════════════════════════════
local function startAutoSell()
    -- Set server-side auto sell threshold
    spawn(function()
        wait(3) -- Wait for game init
        if State.AutoSell and R.UpdateAutoSell then
            fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity)
        end
    end)

    spawn(function()
        while isAlive() do
            if State.AutoSell then
                -- Update auto sell threshold
                if R.UpdateAutoSell then
                    fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity)
                end

                -- Also do manual SellInventory untuk bersihkan backpack
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
                        local info = Rebirths.Get(d.Rebirth + 1)
                        cost = info and tonumber(info.cost)
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
                    -- Cari dice terbaik yang belum dimiliki & terjangkau
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

                    -- Beli dice yang affordable
                    for _, die in ipairs(allDice) do
                        if die.price and not d.OwnedDice[die.key] and d.Money >= die.price then
                            fireRE(R.BuyDice, die.key)
                            Stats.DiceBought = Stats.DiceBought + 1
                            wait(0.5)
                        end
                    end

                    -- Equip dice terbaik yang dimiliki
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
                end
            end
            wait(CONFIG.UpgradeDelay)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO TOWER (improved)
-- ═══════════════════════════════════════
local function startAutoTower()
    spawn(function()
        while isAlive() do
            if State.AutoTower then
                -- Cancel any stuck tower first
                if R.CancelTower then
                    pcall(function()
                        invokeRF(R.CancelTower)
                    end)
                    wait(1)
                end

                -- Equip best tower team
                if R.EquipBestTower then
                    fireRE(R.EquipBestTower)
                    wait(1)
                end

                -- Play tower
                if R.PlayTower then
                    local towerResult = invokeRF(R.PlayTower, CONFIG.TowerName)

                    if towerResult then
                        Stats.TowerRuns = Stats.TowerRuns + 1

                        -- Complete floors until done
                        local maxFloors = 200  -- safety limit
                        for i = 1, maxFloors do
                            if not isAlive() or not State.AutoTower then break end

                            local floorResult = invokeRF(R.CompleteTowerFloor)
                            if not floorResult then break end
                            wait(CONFIG.TowerDelay)
                        end
                    else
                        -- Tower gagal start, mungkin masih ada run aktif
                        if R.CancelTower then
                            invokeRF(R.CancelTower)
                        end
                    end
                end
            end
            wait(5)
        end
    end)
end

-- ═══════════════════════════════════════
-- MODULE: AUTO CODES (toggle-based)
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
-- MODULE: AUTO CLAIM (offline/daily/group/quests)
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
-- MODULE: AUTO SPIN (Lucky/Jackpot)
-- Uses owned spins before each roll cycle
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
-- Level up placed units, spending max LevelShare of money
-- ═══════════════════════════════════════
local function startAutoLevel()
    spawn(function()
        while isAlive() do
            if State.AutoLevel and R.LevelUpSlot then
                local d = getData()
                if d and d.Money then
                    local budget = d.Money * CONFIG.LevelShare
                    local spent = 0

                    -- Level up each slot
                    local maxSlots = 15
                    pcall(function()
                        if PlotConfig and PlotConfig.GetMaxSlots then
                            maxSlots = PlotConfig.GetMaxSlots(d.Rebirth or 0) or 15
                        end
                    end)

                    for slot = 1, maxSlots do
                        if not isAlive() or not State.AutoLevel then break end
                        if spent >= budget then break end

                        -- Try to level up this slot
                        fireRE(R.LevelUpSlot, slot)
                        spent = spent + 1 -- Approximate, actual cost checked server-side
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
-- Spend rebirth points on chosen stat
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
    local BG     = Color3.fromRGB(18, 18, 28)
    local BG2    = Color3.fromRGB(28, 28, 42)
    local DARK   = Color3.fromRGB(12, 12, 20)
    local ACCENT = Color3.fromRGB(100, 60, 255)
    local GREEN  = Color3.fromRGB(80, 200, 120)
    local RED    = Color3.fromRGB(200, 60, 60)
    local WHITE  = Color3.fromRGB(255, 255, 255)
    local GRAY   = Color3.fromRGB(140, 140, 160)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AnimeDiceHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Player.PlayerGui
    _G.__ANIMEDICE_HUB_GUI = ScreenGui

    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 320, 0, 620)
    Main.Position = UDim2.new(0.5, -160, 0.5, -310)
    Main.BackgroundColor3 = BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local mc = Instance.new("UICorner", Main)
    mc.CornerRadius = UDim.new(0, 10)
    local ms = Instance.new("UIStroke", Main)
    ms.Color = ACCENT; ms.Thickness = 2

    -- Title
    local Title = Instance.new("Frame")
    Title.Size = UDim2.new(1, 0, 0, 45)
    Title.BackgroundColor3 = DARK
    Title.BorderSizePixel = 0
    Title.Parent = Main
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -50, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🎲 Anime Dice AFK Hub"
    TitleText.TextColor3 = WHITE
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = Title

    -- Minimize btn
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -36, 0, 8)
    MinBtn.BackgroundColor3 = RED
    MinBtn.Text = "—"
    MinBtn.TextColor3 = WHITE
    MinBtn.TextSize = 14
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = Title
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- Scroll
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -16, 1, -100)
    Scroll.Position = UDim2.new(0, 8, 0, 50)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = ACCENT
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.Parent = Main

    local Layout = Instance.new("UIListLayout", Scroll)
    Layout.Padding = UDim.new(0, 5)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Status bar
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, -16, 0, 40)
    StatusBar.Position = UDim2.new(0, 8, 1, -46)
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
    StatusText.TextSize = 11
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Text = "Loading..."
    StatusText.Parent = StatusBar

    -- Toggle factory
    local function addToggle(name, emoji, stateKey, order)
        local F = Instance.new("Frame")
        F.Size = UDim2.new(1, 0, 0, 36)
        F.BackgroundColor3 = BG2
        F.BorderSizePixel = 0
        F.LayoutOrder = order
        F.Parent = Scroll
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 7)

        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -70, 1, 0)
        L.Position = UDim2.new(0, 10, 0, 0)
        L.BackgroundTransparency = 1
        L.Text = emoji .. "  " .. name
        L.TextColor3 = WHITE
        L.TextSize = 13
        L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = F

        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, 50, 0, 24)
        B.Position = UDim2.new(1, -58, 0.5, -12)
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

            -- Auto sell: update threshold saat toggle
            if stateKey == "AutoSell" and State.AutoSell and R.UpdateAutoSell then
                fireRE(R.UpdateAutoSell, CONFIG.SellBelowRarity)
            end
        end)
    end

    addToggle("Auto Roll",     "🎲", "AutoRoll",    1)
    addToggle("Auto Sell",     "🗑️", "AutoSell",    2)
    addToggle("Auto Collect",  "💰", "AutoCollect",  3)
    addToggle("Auto Rebirth",  "🔄", "AutoRebirth",  4)
    addToggle("Auto Tower",    "🏰", "AutoTower",    5)
    addToggle("Auto Dice",     "🎯", "AutoDice",     6)
    addToggle("Auto Upgrade",  "⬆️", "AutoUpgrade",  7)
    addToggle("Auto Spin",     "🎰", "AutoSpin",     8)
    addToggle("Auto Level",    "📈", "AutoLevel",    9)
    addToggle("Auto Claim",    "🎁", "AutoClaim",   10)
    addToggle("Auto Codes",    "📝", "AutoCodes",   11)
    addToggle("Auto Boost",    "🚀", "AutoBoost",   12)
    addToggle("Auto Stats",    "⭐", "AutoStats",   13)
    addToggle("Anti-AFK",      "🛡️", "AntiAFK",     14)

    -- Minimize handler
    MinBtn.MouseButton1Click:Connect(function()
        State.GUIVisible = not State.GUIVisible
        Main.Visible = State.GUIVisible
    end)

    -- Keyboard toggle
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.ToggleKey then
            State.GUIVisible = not State.GUIVisible
            Main.Visible = State.GUIVisible
        end
    end)

    -- Status updater
    spawn(function()
        while isAlive() do
            local elapsed = tick() - Stats.StartTime
            local d = getData()
            local moneyStr = d and formatNum(d.Money) or "?"

            StatusText.Text = string.format(
                "⏱%s | 💰%s | 🎲%s | 🗑️%s | 🔄%s",
                formatTime(elapsed),
                moneyStr,
                formatNum(Stats.Rolled),
                formatNum(Stats.Sold),
                tostring(Stats.Rebirths)
            )
            wait(1)
        end
    end)

    return ScreenGui
end

-- ═══════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════
local function init()
    print("═══════════════════════════════════════════")
    print("  🎲 Anime Dice AFK Hub v2.0 — Starting")
    print("═══════════════════════════════════════════")

    -- Log remote status
    local found, missing = 0, 0
    for name, remote in pairs(R) do
        if remote then
            found = found + 1
            print("  ✅ " .. name)
        else
            missing = missing + 1
            warn("  ❌ " .. name .. " (not found)")
        end
    end
    print(string.format("\n  Remotes: %d found, %d missing", found, missing))

    -- Log data controller
    if getData() then
        local d = getData()
        print("  ✅ DataController loaded")
        print("  💰 Money: " .. formatNum(d.Money or 0))
        print("  🔄 Rebirth: " .. tostring(d.Rebirth or 0))
    else
        warn("  ⚠️ DataController not available")
    end

    -- Create GUI (dibungkus pcall biar error GUI tidak menghentikan script)
    print("[AnimeDice] Membuat GUI...")
    local guiOk, guiErr = pcall(createGUI)
    if not guiOk then
        warn("[AnimeDice] Gagal buat GUI: " .. tostring(guiErr))
    else
        print("[AnimeDice] GUI berhasil dibuat. Tekan Right Ctrl untuk show/hide.")
    end
    pcall(function() notify("AFK Hub", "🎲 Anime Dice AFK Hub v2.0 loaded!", 4) end)

    -- Start modules
    startAntiAFK()
    startAutoRoll()
    startAutoCollect()
    startAutoSell()
    startAutoRebirth()
    startAutoDice()
    startAutoUpgrade()
    startAutoTower()
    startAutoCodes()
    startAutoClaim()
    startAutoBoost()
    startAutoSpin()
    startAutoLevel()
    startAutoStats()

    -- Respawn handler
    Player.CharacterAdded:Connect(function(char)
        Character = char
        wait(2)
        notify("AFK Hub", "🔄 Respawn — Script tetap aktif", 2)
    end)

    print("\n  ✅ Semua modul aktif!")
    print("  🎮 Toggle key: " .. CONFIG.ToggleKey.Name)
    print("═══════════════════════════════════════════")
end

-- RUN (dibungkus pcall biar kalau error, tetap kelihatan pesannya)
print("[AnimeDice] Script mulai dijalankan...")
local ok, err = pcall(init)
if not ok then
    warn("[AnimeDice] ERROR fatal saat init: " .. tostring(err))
    warn("[AnimeDice] Kirim pesan ini ke developer biar bisa diperbaiki.")
end
