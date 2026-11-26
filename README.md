# phimroblox

Bộ script làm phim (machinima) trong Roblox Studio.

| File | Đặt vào | Tác dụng |
|---|---|---|
| `src/server/CinematicLighting.server.lua` | ServerScriptService (Script) | Ánh sáng hoàng hôn kiểu điện ảnh (Future, Atmosphere, Bloom, DOF, SunRays...) |
| `src/server/DramaScene.server.lua` | ServerScriptService (Script) | Tự dựng con phố + ghế + đèn + 2 nhân vật R15 và diễn cảnh drama ~60s |
| `src/client/DramaCamera.client.lua` | StarterPlayer > StarterPlayerScripts (LocalScript) | Camera theo shot, letterbox, phụ đề |

## Chạy thử nhanh (không cần Rojo)
1. Mở Studio → Baseplate mới.
2. Tạo **Script** trong ServerScriptService, dán `CinematicLighting.server.lua`.
3. Tạo **Script** khác trong ServerScriptService, dán `DramaScene.server.lua`.
4. Tạo **LocalScript** trong StarterPlayer > StarterPlayerScripts, dán `DramaCamera.client.lua`.
5. Bấm **Play** (F5) → sau ~3 giây cảnh tự diễn. Ghi bằng OBS.

Mẹo: CinematicLighting có thể dán thẳng vào **Command Bar** để thấy ánh sáng ngay khi dựng cảnh.

## Dùng Rojo
`rojo serve` rồi Connect trong plugin Rojo.

## Sửa kịch bản
Trong `runScene()` của `DramaScene.server.lua`: `shot(viTriCam, nhinVao, thoiGianChuyen, fov)`, `line("Tên", "Thoại", giay)`, `walkTo(actor, viTri)`.
