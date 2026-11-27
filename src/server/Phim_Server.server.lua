-- Phim_Server (Script trong ServerScriptService): chỉ tạo khung nhân vật cho tập phim.
-- Toàn bộ phần diễn chạy trên máy người xem (LocalScript Phim_Player) để mượt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(ReplicatedStorage:WaitForChild("PhimKit"))
local Tap = require(ReplicatedStorage:WaitForChild("Video"))
Kit.buildRigs(Tap.CAST)
print("[Phim] Đã tạo nhân vật.")
