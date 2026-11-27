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

-- màn đen (fade) + chữ tiêu đề
local fade = Instance.new("Frame")
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.Size = UDim2.fromScale(1, 1)
fade.BorderSizePixel = 0
fade.ZIndex = 5
fade.Parent = gui
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(0.8, 0.12)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.5)
title.Font = Enum.Font.Garamond
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.TextTransparency = 1
title.ZIndex = 6
title.Parent = gui

local function tween(obj, t, props)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine), props)
	tw:Play()
	return tw
end

local function playSound(id, volume, looped)
	if not id or id == 0 then return nil end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume or 0.5
	s.Looped = looped or false
	s.Parent = workspace
	s:Play()
	return s
end

-- mưa: hạt mưa bám theo camera
local cfg = {}
local rainPart
local function startRain()
	rainPart = Instance.new("Part")
	rainPart.Anchored, rainPart.CanCollide, rainPart.CanQuery = true, false, false
	rainPart.Transparency = 1
	rainPart.Size = Vector3.new(80, 1, 80)
	rainPart.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(190, 200, 220))
	e.LightEmission = 0.3
	e.Transparency = NumberSequence.new(0.55)
	e.Size = NumberSequence.new(0.06)
	e.Squash = NumberSequence.new(4) -- kéo dài thành vệt mưa
	e.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Speed = NumberRange.new(70, 90)
	e.Lifetime = NumberRange.new(0.6, 0.8)
	e.Rate = 1500
	e.Parent = rainPart
	game:GetService("RunService").RenderStepped:Connect(function()
		rainPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 35, 0))
	end)
	-- trời âm u
	local L = game:GetService("Lighting")
	L.ClockTime = 19
	L.Brightness = 1.2
	local atm = L:FindFirstChildOfClass("Atmosphere")
	if atm then atm.Density, atm.Color = 0.45, Color3.fromRGB(150, 160, 180) end
	local cc = L:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then cc.TintColor, cc.Saturation = Color3.fromRGB(215, 225, 255), -0.15 end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then clouds.Cover, clouds.Color = 0.9, Color3.fromRGB(90, 95, 110) end
end

local function thunder()
	playSound(cfg.ThunderSoundId, 0.8)
	local cc = game:GetService("Lighting"):FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then return end
	local base = cc.Brightness
	for _ = 1, 2 do
		cc.Brightness = base + 0.6
		task.wait(0.06)
		cc.Brightness = base
		task.wait(0.1)
	end
end

local function shake(t)
	local start = os.clock()
	while os.clock() - start < t do
		local k = 0.15 * (1 - (os.clock() - start) / t)
		camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(math.random(-10, 10) * k), math.rad(math.random(-10, 10) * k), 0)
		task.wait()
	end
end

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
		cfg = a or {}
		if cfg.Rain then
			startRain()
			playSound(cfg.RainSoundId, 0.5, true)
		end
		local music = playSound(cfg.MusicId, 0, true)
		if music then tween(music, 4, { Volume = cfg.MusicVolume or 0.4 }) end
	elseif kind == "title" then
		tween(title, 1, { TextTransparency = 0 })
		title.Text = a
		task.delay(b - 1.2, function()
			tween(title, 1, { TextTransparency = 1 })
			tween(fade, 1.5, { BackgroundTransparency = 1 })
		end)
	elseif kind == "thunder" then
		task.spawn(thunder)
	elseif kind == "shake" then
		task.spawn(shake, a)
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
		sub.Text = ""
		tween(fade, 2, { BackgroundTransparency = 0 })
		title.Text = "— HẾT —"
		tween(title, 2, { TextTransparency = 0 })
		for _, snd in ipairs(workspace:GetChildren()) do
			if snd:IsA("Sound") then tween(snd, 3, { Volume = 0 }) end
		end
	end
end)
