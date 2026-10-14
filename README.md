# 🎲 Anime Dice AFK Hub

Script otomatisasi AFK untuk game **Anime Dice** di Roblox.
Kompatibel dengan **Delta Executor** dan executor lainnya.

## Fitur (14 Toggle)

| # | Fitur | Emoji | Deskripsi |
|---|-------|-------|-----------|
| 1 | Auto Roll | 🎲 | Roll dice otomatis (delay 2.2s sesuai server cooldown) |
| 2 | Auto Sell | 🗑️ | Set server-side auto sell + jual inventory |
| 3 | Auto Collect | 💰 | EquipBest: collect cash dari semua slot + equip unit terbaik |
| 4 | Auto Rebirth | 🔄 | Rebirth otomatis saat uang cukup |
| 5 | Auto Tower | 🏰 | Farm tower otomatis, auto complete floors |
| 6 | Auto Dice | 🎯 | Beli & equip dice terbaik yang terjangkau |
| 7 | Auto Upgrade | ⬆️ | Beli upgrade (Money, Luck, Fortune, dll) |
| 8 | Auto Spin | 🎰 | Gunakan Lucky Spin / Jackpot Spin otomatis |
| 9 | Auto Level | 📈 | Level up slot unit (max 30% uang) |
| 10 | Auto Claim | 🎁 | Klaim offline/daily/group/quest rewards |
| 11 | Auto Codes | 📝 | Redeem semua codes otomatis |
| 12 | Auto Boost | 🚀 | Aktifkan boost Luck/Income/Roll Speed |
| 13 | Auto Stats | ⭐ | Spend rebirth points pada stat pilihan |
| 14 | Anti-AFK | 🛡️ | Cegah kick karena idle |

## File Project

```
c:\animedice\
├── main.lua          ← Script utama (paste ke Delta)
├── scan-game.lua     ← Scan struktur game (debugging)
├── test-remote.lua   ← Test remote path (debugging)
└── README.md         ← File ini
```

## Cara Pakai

1. Buka **Roblox** → masuk game **Anime Dice**
2. Buka **Delta Executor**
3. Copy seluruh isi `main.lua`
4. Paste ke console Delta → tekan **Execute**
5. GUI muncul → toggle fitur ON/OFF
6. Tekan **Right Ctrl** untuk show/hide GUI

## Konfigurasi

Edit bagian `CONFIG` di atas `main.lua`:

```lua
-- Contoh: ubah delay roll
RollDelay = 2.2,    -- Min 2 detik (server cooldown)

-- Contoh: ubah threshold auto sell
SellBelowRarity = 3,  -- Jual Common(1) + Uncommon(2), simpan Rare(3)+

-- Contoh: ubah stat rebirth
RebirthStatPick = "Money",  -- atau "Luck"
```

## Remote Structure

Semua remote ada di `ReplicatedStorage.Network`:
- **RE** = RemoteEvent → `FireServer()`
- **RF** = RemoteFunction → `InvokeServer()`

Contoh: `Network.RollService.RF.RollDice:InvokeServer()`

## Catatan Penting

- **Roll Delay minimum 2.2 detik** — server punya hard cooldown ~2 detik
- **EquipBest** sudah termasuk collect cash + re-place unit terbaik
- **Auto Sell** menggunakan server-side auto sell (UpdateAutoSell)
- Script bisa di-re-execute tanpa restart game (generation guard)
- Remote paths bersumber dari open-source scripts yang terverifikasi
