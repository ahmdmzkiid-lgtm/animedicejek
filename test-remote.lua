--[[
    ╔══════════════════════════════════════════════════╗
    ║     QUICK TEST — Jalankan ini DULU di Delta      ║
    ║     untuk test apakah remote path benar           ║
    ╚══════════════════════════════════════════════════╝
    
    CARA PAKAI:
    1. Isi REMOTE_PATH dan REMOTE_NAME di bawah
    2. Isi TEST_ARGS dengan argumen dari SimpleSpy
    3. Execute di Delta
    4. Lihat output di console (F9 di PC)
]]

-- ═══ ISI INI ═══
local REMOTE_PATH = "ReplicatedStorage.Remotes"   -- Ganti sesuai SimpleSpy
local REMOTE_NAME = "GameRemote"                   -- Ganti sesuai SimpleSpy
local REMOTE_TYPE = "Event"                        -- "Event" atau "Function"
local TEST_ARGS   = {"Roll", 1}                    -- Ganti sesuai SimpleSpy

-- ═══ JANGAN EDIT DI BAWAH ═══
print("\n🔍 Testing remote connection...\n")

-- Step 1: Cek path
local parts = string.split(REMOTE_PATH, ".")
local current = game:GetService(parts[1])
print("✅ Service: " .. parts[1])

for i = 2, #parts do
    local child = current:FindFirstChild(parts[i])
    if child then
        current = child
        print("✅ Found: " .. parts[i])
    else
        warn("❌ NOT FOUND: " .. parts[i] .. " in " .. current:GetFullName())
        print("\n📂 Available children:")
        for _, c in pairs(current:GetChildren()) do
            print("   - " .. c.Name .. " (" .. c.ClassName .. ")")
        end
        return
    end
end

-- Step 2: Cek remote
local remote = current:FindFirstChild(REMOTE_NAME)
if remote then
    print("✅ Remote found: " .. REMOTE_NAME .. " (" .. remote.ClassName .. ")")
else
    warn("❌ Remote NOT FOUND: " .. REMOTE_NAME)
    print("\n📂 Available remotes:")
    for _, c in pairs(current:GetChildren()) do
        print("   - " .. c.Name .. " (" .. c.ClassName .. ")")
    end
    return
end

-- Step 3: Fire test
print("\n🚀 Firing remote with args: " .. tostring(#TEST_ARGS) .. " arguments")
for i, v in ipairs(TEST_ARGS) do
    print("   arg[" .. i .. "] = " .. tostring(v) .. " (" .. typeof(v) .. ")")
end

local success, result = pcall(function()
    if REMOTE_TYPE == "Event" then
        remote:FireServer(unpack(TEST_ARGS))
        return "fired (no return value for events)"
    else
        return remote:InvokeServer(unpack(TEST_ARGS))
    end
end)

if success then
    print("\n✅ SUCCESS! Result: " .. tostring(result))
else
    warn("\n❌ ERROR: " .. tostring(result))
end

print("\n═══════════════════════════════════════")
print("Test selesai! Kalau semua ✅, config sudah benar.")
print("═══════════════════════════════════════")
