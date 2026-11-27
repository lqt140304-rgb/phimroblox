# phimroblox

Làm phim (machinima) trong Roblox Studio bằng script Luau.

## Cảnh hiện tại: Hồ sơ 02 — Người trong gương (Phần 1, Cảnh 1)
Dựng theo kịch bản trong repo `lamvideo` (`episodes/hem-co-chuyen/ho-so-02-nguoi-lam-thay`).

| File | Đặt vào | Loại |
|---|---|---|
| `src/server/HoSo02_Scene.server.lua` | ServerScriptService | **Script** |
| `src/client/HoSo02_Client.client.lua` | StarterPlayer › StarterPlayerScripts | **LocalScript** |

Bấm **Play (F5)** → ~3 giây sau phim tự chạy (~3 phút).

**Nội dung:** tiêu đề → hồi tưởng "Tối hôm trước" (Nam hứa "Tí tao rửa", Tùng đi ngủ) → sáng hôm sau: báo thức, tiếng rửa chén, Nam tưởng là Tùng → Người Kia quay lại, cùng một khuôn mặt → va ghế, lùi ra ngưỡng cửa → hỏi đáp "Cửa mở." → gọi cho Tùng.

**Thế giới:** phòng trọ theo mặt bằng trong DUNG-CANH.md (cửa trái, bếp sau–trái, tủ + gương đứng, bàn sau–phải, cửa sổ phải, nệm đôi gối kem/gối xanh, ghế 4 chân, quạt trần quay), hành lang dãy trọ có lan can, dây phơi, cầu thang, góc đồ "Ai cần cứ lấy". Ánh sáng đêm (đèn tuýp, đèn bàn, màn hình điện thoại) và sáng sớm (nắng xiên qua cửa sổ).

**Nhân vật:** Nam (áo ngủ xám), Người Kia (áo xanh rêu của Nam, nốt ruồi đối xứng), Tùng (tóc dựng, áo cam, da ngăm), hàng xóm nữ (tóc búi, cardigan), cô chủ trọ (kẹp càng cua, túi bao tử, chùm chìa khóa). Nam/nữ khác dáng người, tóc dựng bằng khối.

**Biểu cảm:** mắt, mày, miệng vẽ trên mặt, tự chớp mắt, mấp máy môi khi nói. Có: neutral, asleep, sleepy, groggy, annoyed, shocked, confused, squint, scared, angryScared, pain, calm, tired, dread, happy.

**Camera:** client tính camera từng khung hình và bám theo nhân vật (hết giật), dolly vòng cung, rung tay máy, Dutch angle, lấy nét theo chủ thể, ống kính theo mm, letterbox 2.39:1.

## Tùy chỉnh
- Âm thanh: bảng `SOUNDS` đầu file client (dán ID Audio từ Creator Store; 0 = tắt).
- Bỏ hồi tưởng: `CONFIG.PlayFlashback = false` trong file server.
- Sửa cảnh: hàm `flashback()` / `scene1()`; các lệnh `cam{...}`, `say(...)`, `expr(...)`, `pose(...)`, `walkTo(...)`.

## Khác
- `examples/drama-pho/`: cảnh drama đường phố thử nghiệm đầu tiên (không dùng cùng lúc với Hồ sơ 02).
- `tools/CinematicLighting.lua`: dán vào Command Bar để có ánh sáng hoàng hôn điện ảnh.
- Rojo: `rojo serve` với `default.project.json`.
