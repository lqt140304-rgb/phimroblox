-- DramaCamera: nhận cue từ server để chuyển camera, hiện phụ đề, khung letterbox.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cue = ReplicatedStorage:WaitForChild("DramaCue")

-- UI: letterbox + phụ đề
local gui = Instance.new("ScreenGui")
gui.Name = "DramaUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function bar(anchorY)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 0.12)
	f.AnchorPoint = Vector2.new(0, anchorY)
	f.Position = UDim2.fromScale(0, anchorY)
	f.Parent = gui
end
bar(0); bar(1)

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Size = UDim2.fromScale(0.8, 0.08)
sub.AnchorPoint = Vector2.new(0.5, 1)
sub.Position = UDim2.fromScale(0.5, 0.86)
sub.Font = Enum.Font.GothamMedium
sub.TextScaled = true
sub.TextColor3 = Color3.new(1, 1, 1)
sub.TextStrokeTransparency = 0.4
sub.Text = ""
sub.Parent = gui
local c = Instance.new("UITextSizeConstraint", sub); c.MaxTextSize = 30

local currentTween
cue.OnClientEvent:Connect(function(kind, a, b, c2, d)
	if kind == "start" then
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
		if player.Character then
			for _, p in ipairs(player.Character:GetDescendants()) do
				if p:IsA("BasePart") or p:IsA("Decal") then p.LocalTransparencyModifier = 1 end
			end
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Anchored = true end
		end
		camera.CameraType = Enum.CameraType.Scriptable
		gui.Enabled = true
	elseif kind == "shot" then
		local target = CFrame.lookAt(a, b)
		if currentTween then currentTween:Cancel() end
		if c2 and c2 > 0 then
			local info = TweenInfo.new(c2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			currentTween = TweenService:Create(camera, info, { CFrame = target, FieldOfView = d })
			currentTween:Play()
		else
			camera.CFrame = target
			camera.FieldOfView = d
		end
	elseif kind == "look" then
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, a)
	elseif kind == "line" then
		sub.Text = (a ~= "" and (a .. ": ") or "") .. b
		sub.TextColor3 = a == "" and Color3.fromRGB(220, 220, 220) or Color3.new(1, 1, 1)
		sub.Font = a == "" and Enum.Font.GothamMedium or Enum.Font.GothamBold
	elseif kind == "end" then
		sub.Text = "— HẾT —"
	end
end)
