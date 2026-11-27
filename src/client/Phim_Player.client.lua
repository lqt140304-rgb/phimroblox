-- Phim_Player (LocalScript trong StarterPlayer > StarterPlayerScripts): dựng bối cảnh và diễn tập phim.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(ReplicatedStorage:WaitForChild("PhimKit"))
local Tap = require(ReplicatedStorage:FindFirstChild("VideoDai") or ReplicatedStorage:WaitForChild("Video"))

local player = Players.LocalPlayer
if not player.Character then
	player.CharacterAdded:Wait()
end
task.wait(2)
Kit.init()
local ok, err = pcall(Tap.run, Kit)
if not ok then
	warn("[Phim] Lỗi khi diễn: ", err)
end
