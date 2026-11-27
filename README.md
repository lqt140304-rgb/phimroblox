# phimroblox

Làm phim (machinima) trong Roblox Studio bằng script Luau.

## Dự án hiện tại: WHAT IF — Nếu trọng lực giảm một nửa trong 7 ngày?
Kịch bản lời kể + kiểm chứng: [docs/WHAT-IF-TRONG-LUC.md](docs/WHAT-IF-TRONG-LUC.md)

| File | Đặt vào | Loại | Tên (bắt buộc đúng) |
|---|---|---|---|
| `src/shared/PhimKit.lua` | ReplicatedStorage | **ModuleScript** | `PhimKit` |
| `src/shared/Video.lua` | ReplicatedStorage | **ModuleScript** | `Video` |
| `src/server/Phim_Server.server.lua` | ServerScriptService | **Script** | tuỳ ý |
| `src/client/Phim_Player.client.lua` | StarterPlayer › StarterPlayerScripts | **LocalScript** | tuỳ ý |

Muốn làm video khác: viết module mới cùng cấu trúc (`CAST` + `run(Kit)`), đặt tên `Video`.

### Có gì
- **Hook 3 giây đầu:** mở thẳng vào câu "Mình chia tay đi" → chữ lớn → tên phim → lùi về 3 tiếng trước.
- **3 bối cảnh:** phố cũ Hà Nội (nhà ống, biển hiệu, hoa sưa, dây điện, xe đạp chở hoa loa kèn), quán "Cà Phê Cũ" (mặt kính, đèn thả, quầy, kệ sách, vỉa hè mưa), phòng trọ đêm (đèn dây, màn hình game, thành phố ngoài cửa sổ).
- **6 diễn viên:** Minh, An, Khoa, cô Hoa, chị phục vụ, khách quán. Có 2 dáng nam/nữ và các màu da khác nhau.
- **Trang phục thay được giữa cảnh:** `Kit.dress(nhânVật, "tên_bộ")`. Có sẵn 10 bộ: sơ mi kẻ, áo phông, đồ ngủ, hoodie, váy trắng, áo dài, cardigan + chân váy dài, áo khoác bò, áo bà ba, đồng phục quán. Phụ kiện: balo, túi tote, đồng hồ, kính, tai nghe, tai nghe nhét tai, tạp dề, nón lá. Muốn thêm bộ mới thì thêm vào `Kit.OUTFITS`.
- **Kiểu tóc:** curtain (mái chia ngôi), short, spiky, long, bob, ponytail, bun.
- **Biểu cảm:** 25 biểu cảm (sad, cry, hurt, laugh, forcedSmile, worried, dread…), nước mắt chảy, son môi, chớp mắt, mấp máy môi khi nói.
- **Camera rộng hơn:** khung 2:1 (thay cho 2.39), camera tính khoảng cách theo cỡ cảnh `Kit.frame(nv, "CU"|"MCU"|"MS"|"MLS"|"FS"|"WS")` nên luôn thấy rõ người; có thêm khung qua vai `Kit.ots` và hai người cùng khung `Kit.two`.
- **Điện thoại nhắn tin trên màn hình**, chữ "Đã xem", mưa, phụ đề có màu theo nhân vật.

### Tuỳ chỉnh
- Âm thanh: bảng `SOUNDS` đầu file client (dán ID Audio, 0 = tắt).
- Khung phim: `LETTERBOX` đầu file client (1.78 = không có viền đen).

## Lưu trữ
- `examples/ho-so-02/`: dự án "Hồ sơ 02" (đã dừng).
- `examples/drama-pho/`: cảnh thử đầu tiên.
- `tools/CinematicLighting.lua`: preset ánh sáng hoàng hôn cho Command Bar.
