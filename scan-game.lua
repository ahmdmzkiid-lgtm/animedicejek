--[[
    ╔═══════════════════════════════════════════════════╗
    ║     EXPLORER TOOL — Scan struktur game            ║
    ║     Jalankan di Delta untuk lihat isi game         ║
    ╚═══════════════════════════════════════════════════╝
    
    Script ini membantu kamu menemukan:
    - Lokasi folder Remotes
    - Lokasi inventory player
    - Struktur ReplicatedStorage
]]

local Player = game:GetService("Players").LocalPlayer

local function scanFolder(parent, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 3
    if depth > maxDepth then return end
    
    local indent = string.rep("  ", depth)
    
    for _, child in pairs(parent:GetChildren()) do
        local info = indent .. "├─ " .. child.Name .. " [" .. child.ClassName .. "]"
        
        -- Highlight remotes
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            info = info .. " ⚡ REMOTE"
        end
        
        -- Highlight folders with remotes
        local hasRemotes = false
        pcall(function()
            for _, gc in pairs(child:GetChildren()) do
                if gc:IsA("RemoteEvent") or gc:IsA("RemoteFunction") then
                    hasRemotes = true
                end
            end
        end)
        if hasRemotes then
            info = info .. " 📡 HAS REMOTES"
        end
        
        print(info)
        
        pcall(function()
            scanFolder(child, depth + 1, maxDepth)
        end)
    end
end

-- ═══ SCAN REPLICATED STORAGE ═══
print("\n╔═══════════════════════════════════════╗")
print("║   📦 REPLICATED STORAGE              ║")
print("╚═══════════════════════════════════════╝")
scanFolder(game:GetService("ReplicatedStorage"), 0, 3)

-- ═══ SCAN PLAYER DATA ═══
print("\n╔═══════════════════════════════════════╗")
print("║   👤 PLAYER DATA                     ║")
print("╚═══════════════════════════════════════╝")
scanFolder(Player, 0, 3)

-- ═══ SCAN WORKSPACE (shallow) ═══
print("\n╔═══════════════════════════════════════╗")
print("║   🌍 WORKSPACE (top-level only)      ║")
print("╚═══════════════════════════════════════╝")
scanFolder(game:GetService("Workspace"), 0, 1)

-- ═══ RINGKASAN REMOTE ═══
print("\n╔═══════════════════════════════════════╗")
print("║   ⚡ SEMUA REMOTE YANG DITEMUKAN      ║")
print("╚═══════════════════════════════════════╝")

local remoteCount = 0
local function findAllRemotes(parent, path)
    pcall(function()
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                remoteCount = remoteCount + 1
                print(string.format("  %d. [%s] %s", remoteCount, child.ClassName, path .. "." .. child.Name))
            end
            findAllRemotes(child, path .. "." .. child.Name)
        end
    end)
end

findAllRemotes(game:GetService("ReplicatedStorage"), "ReplicatedStorage")

print("\n  Total remotes: " .. remoteCount)
print("═══════════════════════════════════════")
