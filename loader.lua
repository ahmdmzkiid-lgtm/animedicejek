--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║        🎲 ANIME DICE AFK HUB — LOADER (jsDelivr CDN) 🎲         ║
    ║                                                                  ║
    ║  File ini cuma SATU baris inti. Paste seluruh file ini ke        ║
    ║  Delta Executor → Execute. Dia otomatis download main.lua        ║
    ║  dari GitHub lewat jsDelivr, lalu menjalankannya.                ║
    ║                                                                  ║
    ║  Keuntungan: kamu cukup update main.lua di GitHub, user TIDAK    ║
    ║  perlu copas ulang — cukup Execute loader ini lagi.              ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════
--  KONFIGURASI — GANTI 3 BAGIAN INI SESUAI REPO GITHUB KAMU
-- ═══════════════════════════════════════════════════════════════════
local GITHUB_USER  = "ahmdmzkiid-lgtm"   -- GitHub username
local GITHUB_REPO  = "animedicejek"      -- nama repo
local BRANCH       = "main"              -- biasanya "main" atau "master"
local FILE_PATH    = "main.lua"          -- path main.lua di dalam repo

-- Format URL jsDelivr:
--   https://cdn.jsdelivr.net/gh/<user>/<repo>@<branch>/<path>
local SCRIPT_URL = string.format(
    "https://cdn.jsdelivr.net/gh/%s/%s@%s/%s",
    GITHUB_USER, GITHUB_REPO, BRANCH, FILE_PATH
)

-- ═══════════════════════════════════════════════════════════════════
--  LOADER — jangan perlu diubah
-- ═══════════════════════════════════════════════════════════════════
local ok, source = pcall(function()
    -- parameter `true` = aktifkan bypass anti-bot (penting untuk jsDelivr/GitHub)
    return game:HttpGet(SCRIPT_URL, true)
end)

if not ok or type(source) ~= "string" or #source < 10 then
    warn("[AnimeDice Loader] Gagal download script!")
    warn("  URL   : " .. SCRIPT_URL)
    warn("  Error : " .. tostring(source))
    warn("  Cek: username/repo/branch benar? Repo publik? Nama file benar?")
    return
end

-- Deteksi kalau yang ke-download ternyata HTML (berarti URL salah / bukan raw)
if source:sub(1, 1) == "<" or source:find("<!DOCTYPE") or source:find("<html") then
    warn("[AnimeDice Loader] Yang ke-download HTML, bukan Lua. URL kemungkinan salah.")
    warn("  URL: " .. SCRIPT_URL)
    return
end

-- Jalankan script hasil download
local fn, loadErr = loadstring(source)
if not fn then
    warn("[AnimeDice Loader] Script ter-download tapi gagal di-compile:")
    warn("  " .. tostring(loadErr))
    return
end

local runOk, runErr = pcall(fn)

if not runOk then
    warn("[AnimeDice Loader] Script error saat dijalankan:")
    warn("  " .. tostring(runErr))
    return
end

print("[AnimeDice Loader] ✅ Script berhasil di-load dari jsDelivr.")
