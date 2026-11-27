--[[
	Phim_Client — LocalScript trong StarterPlayer > StarterPlayerScripts (dùng chung cho mọi tập).
	  • Camera: bám nhân vật từng khung hình (mượt), chuyển cảnh, dolly vòng cung, rung tay máy nhẹ,
	    Dutch angle, lấy nét theo chủ thể. Khung 2:1 (rộng hơn 2.39 để thấy rõ người).
	  • Khuôn mặt: mắt, mày, miệng, nốt ruồi, son môi, nước mắt; chớp mắt; mấp máy môi khi nói.
	  • Phụ đề, chữ thời gian, chữ lớn giữa màn hình, tiêu đề, fade đen, màn hình điện thoại nhắn tin.
	  • Mưa (hạt mưa bám theo camera). Âm thanh: điền ID vào bảng SOUNDS (0 = tắt).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LETTERBOX = 2.0 -- tỉ lệ khung phim (2.39 = rất hẹp, 1.78 = không có viền đen)

-- Âm thanh: dán ID từ Creator Store (Audio). 0 = tắt.
local SOUNDS = {
	notify = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, speed = 1.4 }, -- tin nhắn đến
	tap = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.12, speed = 2.2 },
	music = { id = 0, volume = 0.35, loop = true }, -- nhạc nền piano buồn
	street = { id = 0, volume = 0.3, loop = true }, -- phố sáng: xe máy, chim
	cafe = { id = 0, volume = 0.25, loop = true }, -- tiếng quán cà phê
	rain = { id = 0, volume = 0.5, loop = true }, -- mưa
	ring = { id = 0, volume = 0.4, loop = true }, -- chuông chờ điện thoại
	bell = { id = 0, volume = 0.5 }, -- chuông cửa quán
	game = { id = 0, volume = 0.2, loop = true }, -- tiếng game của Khoa
	heartbeat = { id = 0, volume = 0.5, loop = true },
}

local SPEAKER_COLOR = {
	Minh = "#9fd3ff",
	An = "#ffc2d1",
	Linh = "#c9b6ff",
	Khoa = "#ffcf8a",
	CoHoa = "#d9e8a0",
	["Linh (điện thoại)"] = "#c9b6ff",
	["Lời dẫn"] = "#e8e2d0",
}
local SPEAKER_NAME = { CoHoa = "Cô Hoa" }

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cue = ReplicatedStorage:WaitForChild("PhimCue")

------------------------------------------------------------------------ GIAO DIỆN
local gui = Instance.new("ScreenGui")
gui.Name = "PhimUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function newFrame(z)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	f.Parent = gui
	return f
end
local barTop, barBottom = newFrame(3), newFrame(3)
barBottom.AnchorPoint = Vector2.new(0, 1)

local fade = newFrame(5)
fade.Size = UDim2.fromScale(1, 1)

local function newText(z)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.new(1, 1, 1)
	t.RichText = true
	t.TextWrapped = true
	t.ZIndex = z or 4
	t.Text = ""
	t.Parent = gui
	return t
end

local sub = newText(4)
sub.AnchorPoint = Vector2.new(0.5, 1)
sub.Size = UDim2.new(0.8, 0, 0, 60)
sub.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
sub.TextSize = 26
sub.TextStrokeTransparency = 0.35
sub.TextYAlignment = Enum.TextYAlignment.Bottom

local caption = newText(4)
caption.AnchorPoint = Vector2.new(0, 0)
caption.Size = UDim2.new(0.4, 0, 0, 30)
caption.TextXAlignment = Enum.TextXAlignment.Left
caption.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Light, Enum.FontStyle.Italic)
caption.TextSize = 22
caption.TextTransparency = 1

local title = newText(6)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.47)
title.Size = UDim2.fromScale(0.8, 0.1)
title.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
title.TextScaled = true
title.TextTransparency = 1
local subtitle = newText(6)
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.57)
subtitle.Size = UDim2.fromScale(0.6, 0.04)
subtitle.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Light, Enum.FontStyle.Italic)
subtitle.TextScaled = true
subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
subtitle.TextTransparency = 1

local function layout()
	local vp = camera.ViewportSize
	local barH = math.max(0, math.floor((vp.Y - vp.X / LETTERBOX) / 2))
	barTop.Size = UDim2.new(1, 0, 0, barH)
	barBottom.Size = UDim2.new(1, 0, 0, barH)
	barBottom.Position = UDim2.new(0, 0, 1, 0)
	sub.Position = UDim2.new(0.5, 0, 1, -barH - 18)
	caption.Position = UDim2.new(0, 40, 0, barH + 18)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()

local function tween(obj, t, props)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props)
	tw:Play()
	return tw
end

------------------------------------------------------------------------ ÂM THANH
local playing = {}
local function sfx(name, on)
	local def = SOUNDS[name]
	if not def or def.id == 0 or def.id == "" then
		return
	end
	if on == false then
		local s = playing[name]
		if s then
			tween(s, 0.4, { Volume = 0 })
			task.delay(0.45, function()
				s:Destroy()
			end)
			playing[name] = nil
		end
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = typeof(def.id) == "number" and ("rbxassetid://" .. def.id) or def.id
	s.Volume = def.volume or 0.5
	s.PlaybackSpeed = def.speed or 1
	s.Looped = def.loop == true
	s.Parent = workspace
	s:Play()
	if s.Looped then
		if playing[name] then
			playing[name]:Destroy()
		end
		playing[name] = s
	else
		s.Ended:Connect(function()
			s:Destroy()
		end)
	end
end

------------------------------------------------------------------------ BIỂU CẢM KHUÔN MẶT
-- Toạ độ trên mặt: 0..100 (trái → phải khi nhìn chính diện, trên → dưới).
local EXPR = {
	neutral = { eyeW = 9, eyeH = 13, eyeY = 47, browY = 32, browAng = 0, mouthW = 15, mouthH = 3, mouthY = 72, smile = 0 },
	asleep = { eyeW = 11, eyeH = 1.5, eyeY = 49, browY = 35, browAng = -4, mouthW = 8, mouthH = 2.5, mouthY = 72, smile = 0 },
	sleepy = { eyeW = 11, eyeH = 3, eyeY = 48, browY = 34, browAng = -6, mouthW = 10, mouthH = 3, mouthY = 72, smile = -0.1 },
	groggy = { eyeW = 10, eyeH = 7, eyeY = 48, browY = 34, browAng = -4, mouthW = 11, mouthH = 3, mouthY = 72, smile = 0 },
	annoyed = { eyeW = 10, eyeH = 8, eyeY = 48, browY = 33, browAng = 14, mouthW = 13, mouthH = 3, mouthY = 72, smile = -0.4 },
	shocked = { eyeW = 12, eyeH = 17, eyeY = 46, browY = 24, browAng = -8, mouthW = 9, mouthH = 11, mouthY = 74, smile = 0 },
	confused = { eyeW = 10, eyeH = 13, eyeY = 47, browY = 28, browAng = -12, mouthW = 10, mouthH = 4, mouthY = 72, smile = -0.2 },
	squint = { eyeW = 10, eyeH = 2, eyeY = 48, browY = 33, browAng = 10, mouthW = 10, mouthH = 3, mouthY = 72, smile = -0.3 },
	scared = { eyeW = 12, eyeH = 16, eyeY = 46, browY = 26, browAng = -18, mouthW = 13, mouthH = 6, mouthY = 74, smile = -0.6 },
	angryScared = { eyeW = 11, eyeH = 13, eyeY = 47, browY = 29, browAng = 12, mouthW = 14, mouthH = 5, mouthY = 73, smile = -0.5 },
	pain = { eyeW = 11, eyeH = 2, eyeY = 48, browY = 31, browAng = 16, mouthW = 16, mouthH = 5, mouthY = 73, smile = -0.6 },
	calm = { eyeW = 9, eyeH = 9, eyeY = 47, browY = 32, browAng = 0, mouthW = 13, mouthH = 2.5, mouthY = 71, smile = 0.7 },
	tired = { eyeW = 10, eyeH = 7, eyeY = 48, browY = 32, browAng = -14, mouthW = 11, mouthH = 3, mouthY = 72, smile = -0.3 },
	dread = { eyeW = 11, eyeH = 14, eyeY = 47, browY = 27, browAng = -16, mouthW = 8, mouthH = 3, mouthY = 73, smile = -0.5 },
	happy = { eyeW = 9, eyeH = 10, eyeY = 47, browY = 30, browAng = -3, mouthW = 17, mouthH = 6, mouthY = 72, smile = 0.8 },
	laugh = { eyeW = 10, eyeH = 3, eyeY = 47, browY = 29, browAng = -4, mouthW = 18, mouthH = 9, mouthY = 73, smile = 0.9 },
	smile = { eyeW = 9, eyeH = 10, eyeY = 47, browY = 31, browAng = 0, mouthW = 15, mouthH = 3, mouthY = 71, smile = 0.7 },
	forcedSmile = { eyeW = 9, eyeH = 9, eyeY = 47, browY = 30, browAng = -14, mouthW = 14, mouthH = 2.5, mouthY = 71, smile = 0.4 },
	sad = { eyeW = 9, eyeH = 9, eyeY = 48, browY = 30, browAng = -16, mouthW = 11, mouthH = 2.5, mouthY = 73, smile = -0.5 },
	cry = { eyeW = 10, eyeH = 5, eyeY = 48, browY = 29, browAng = -20, mouthW = 13, mouthH = 5, mouthY = 73, smile = -0.7 },
	hurt = { eyeW = 10, eyeH = 11, eyeY = 47, browY = 28, browAng = -18, mouthW = 10, mouthH = 3, mouthY = 73, smile = -0.3 },
	worried = { eyeW = 10, eyeH = 12, eyeY = 47, browY = 28, browAng = -14, mouthW = 11, mouthH = 3, mouthY = 72, smile = -0.3 },
	serious = { eyeW = 9, eyeH = 10, eyeY = 47, browY = 32, browAng = 8, mouthW = 13, mouthH = 2.5, mouthY = 72, smile = 0 },
}
local KEYS = { "eyeW", "eyeH", "eyeY", "browY", "browAng", "mouthW", "mouthH", "mouthY", "smile" }

local faces = {}

local function buildFace(plate)
	if faces[plate] then
		return
	end
	local oldFace = plate:FindFirstChild("Face")
	if oldFace then
		oldFace:Destroy()
	end
	local g = Instance.new("SurfaceGui")
	g.Name = "Face"
	g.Face = Enum.NormalId.Front
	g.Adornee = plate
	g.CanvasSize = Vector2.new(200, 200)
	g.LightInfluence = 0.6
	g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	g.Parent = plate

	local function el(color, z, radius)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.ZIndex = z or 1
		f.Parent = g
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radius or 1, 0)
		c.Parent = f
		return f
	end
	local function hexOr(attr, default)
		local v = plate:GetAttribute(attr)
		local ok, col = pcall(Color3.fromHex, v or "")
		return ok and col or default
	end
	local dark = Color3.fromRGB(28, 24, 26)
	local browColor = hexOr("BrowColor", dark)
	local skin = hexOr("Skin", Color3.fromRGB(240, 203, 178))
	local female = plate:GetAttribute("Female") == true

	local f = { plate = plate, cur = table.clone(EXPR.neutral), nextBlink = os.clock() + math.random() * 3, blinkUntil = 0, seed = math.random() * 100 }
	f.eyeL, f.eyeR = el(dark, 2), el(dark, 2)
	for _, eye in ipairs({ f.eyeL, f.eyeR }) do
		local hl = el(Color3.new(1, 1, 1), 3)
		hl.Size = UDim2.fromScale(0.32, 0.25)
		hl.Position = UDim2.fromScale(0.68, 0.3)
		hl.Parent = eye
	end
	f.browL, f.browR = el(browColor, 2, 0.5), el(browColor, 2, 0.5)
	f.mouth = el(Color3.fromRGB(90, 40, 42), 2, 1)
	f.cornerL, f.cornerR = el(Color3.fromRGB(90, 40, 42), 2, 1), el(Color3.fromRGB(90, 40, 42), 2, 1)
	-- nốt ruồi: Nam bên trái mặt, Người Kia bên phải (đối xứng gương)
	local moleSide = plate:GetAttribute("Mole")
	if moleSide == "L" or moleSide == "R" then
		local m = el(Color3.fromRGB(45, 30, 28), 2)
		m.Size = UDim2.fromScale(0.035, 0.035)
		m.Position = UDim2.fromScale(moleSide == "L" and 0.71 or 0.29, 0.62)
	end
	-- má hồng nhẹ
	for _, x in ipairs({ 0.27, 0.73 }) do
		local b = el(skin:Lerp(Color3.fromRGB(235, 120, 120), 0.5), 1)
		b.BackgroundTransparency = female and 0.45 or 0.8
		b.Size = UDim2.fromScale(0.13, 0.07)
		b.Position = UDim2.fromScale(x, 0.6)
	end
	local lips = plate:GetAttribute("Lips")
	if lips and lips ~= "" then
		local ok, col = pcall(Color3.fromHex, lips)
		if ok then
			f.mouth.BackgroundColor3 = col
			f.cornerL.BackgroundColor3, f.cornerR.BackgroundColor3 = col, col
		end
	end
	f.tearL, f.tearR = el(Color3.fromRGB(150, 205, 255), 3, 0.5), el(Color3.fromRGB(150, 205, 255), 3, 0.5)
	f.tearL.BackgroundTransparency, f.tearR.BackgroundTransparency = 0.25, 0.25
	f.tearProgress = 0
	if female then -- mi mắt
		f.lashL, f.lashR = el(dark, 2, 0.5), el(dark, 2, 0.5)
	end
	faces[plate] = f
	plate.AncestryChanged:Connect(function()
		if not plate:IsDescendantOf(game) then
			faces[plate] = nil
		end
	end)
end

local function S(x, y)
	return UDim2.fromScale(x / 100, y / 100)
end

local function updateFaces(dt, now)
	local k = 1 - math.exp(-14 * dt)
	for plate, f in pairs(faces) do
		local target = EXPR[plate:GetAttribute("Expression") or "neutral"] or EXPR.neutral
		local c = f.cur
		for _, key in ipairs(KEYS) do
			c[key] = c[key] + (target[key] - c[key]) * k
		end
		if now > f.nextBlink then
			f.blinkUntil = now + 0.11
			f.nextBlink = now + 2 + math.random() * 3.5
		end
		local gz = plate:GetAttribute("Gaze") or Vector2.zero
		local eyeH = (now < f.blinkUntil) and 1.2 or c.eyeH
		local ex, ey = gz.X * 3, c.eyeY + gz.Y * 2
		f.eyeL.Size, f.eyeR.Size = S(c.eyeW, eyeH), S(c.eyeW, eyeH)
		f.eyeL.Position, f.eyeR.Position = S(35 + ex, ey), S(65 + ex, ey)
		if f.lashL then
			f.lashL.Size, f.lashR.Size = S(c.eyeW * 0.6, 2), S(c.eyeW * 0.6, 2)
			f.lashL.Position = S(35 + ex - c.eyeW * 0.4, ey - eyeH / 2)
			f.lashR.Position = S(65 + ex + c.eyeW * 0.4, ey - eyeH / 2)
			f.lashL.Rotation, f.lashR.Rotation = -25, 25
		end
		f.browL.Size, f.browR.Size = S(14, 3), S(14, 3)
		f.browL.Position, f.browR.Position = S(35, c.browY), S(65, c.browY)
		f.browL.Rotation, f.browR.Rotation = c.browAng, -c.browAng

		local mh, mw = c.mouthH, c.mouthW
		if plate:GetAttribute("Talking") then
			mh = mh + 7 * math.abs(math.noise(now * 9, f.seed))
			mw = mw - 2
		end
		local tearsOn = plate:GetAttribute("Tears") == true
		f.tearProgress = math.clamp(f.tearProgress + (tearsOn and dt * 0.5 or -dt * 2), 0, 1)
		local tl = 14 * f.tearProgress
		f.tearL.Visible, f.tearR.Visible = tl > 0.5, tl > 0.5
		f.tearL.Size, f.tearR.Size = S(2.4, tl), S(2.4, tl)
		f.tearL.Position = S(33 + ex, ey + eyeH / 2 + tl / 2)
		f.tearR.Position = S(67 + ex, ey + eyeH / 2 + tl / 2)
		f.mouth.Size = S(mw, mh)
		f.mouth.Position = S(50, c.mouthY)
		local sm = c.smile
		local show = math.abs(sm) > 0.08
		f.cornerL.Visible, f.cornerR.Visible = show, show
		if show then
			f.cornerL.Size, f.cornerR.Size = S(6, 2.6), S(6, 2.6)
			f.cornerL.Position = S(50 - mw / 2 - 1.5, c.mouthY - sm * 2)
			f.cornerR.Position = S(50 + mw / 2 + 1.5, c.mouthY - sm * 2)
			f.cornerL.Rotation, f.cornerR.Rotation = sm * 35, -sm * 35
		end
	end
end

local function watchActors()
	local root = workspace:WaitForChild("Phim")
	local function check(d)
		if d.Name == "FacePlate" and d:IsA("BasePart") then
			buildFace(d)
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		check(d)
	end
	root.DescendantAdded:Connect(check)
end
task.spawn(watchActors)

------------------------------------------------------------------------ CHỮ LỚN GIỮA MÀN HÌNH
local big = newText(6)
big.AnchorPoint = Vector2.new(0.5, 0.5)
big.Position = UDim2.fromScale(0.5, 0.5)
big.Size = UDim2.fromScale(0.7, 0.2)
big.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
big.TextScaled = true
big.TextTransparency = 1
local bigSize = Instance.new("UITextSizeConstraint")
bigSize.MaxTextSize = 40
bigSize.Parent = big

------------------------------------------------------------------------ MÀN HÌNH ĐIỆN THOẠI
local phoneUI = Instance.new("Frame")
phoneUI.Name = "Phone"
phoneUI.AnchorPoint = Vector2.new(1, 0.5)
phoneUI.Position = UDim2.new(1, -40, 0.5, 0)
phoneUI.Size = UDim2.fromOffset(270, 470)
phoneUI.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
phoneUI.Visible = false
phoneUI.ZIndex = 7
phoneUI.Parent = gui
Instance.new("UICorner", phoneUI).CornerRadius = UDim.new(0, 28)
local screenF = Instance.new("Frame")
screenF.Position = UDim2.fromOffset(10, 10)
screenF.Size = UDim2.new(1, -20, 1, -20)
screenF.BackgroundColor3 = Color3.fromRGB(238, 240, 245)
screenF.ZIndex = 7
screenF.ClipsDescendants = true
screenF.Parent = phoneUI
Instance.new("UICorner", screenF).CornerRadius = UDim.new(0, 20)
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = Color3.fromRGB(0, 104, 255)
header.TextColor3 = Color3.new(1, 1, 1)
header.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
header.TextSize = 18
header.ZIndex = 8
header.Parent = screenF
local list = Instance.new("Frame")
list.Position = UDim2.fromOffset(0, 60)
list.Size = UDim2.new(1, 0, 1, -90)
list.BackgroundTransparency = 1
list.ZIndex = 8
list.Parent = screenF
local layoutList = Instance.new("UIListLayout")
layoutList.Padding = UDim.new(0, 8)
layoutList.VerticalAlignment = Enum.VerticalAlignment.Bottom
layoutList.SortOrder = Enum.SortOrder.LayoutOrder
layoutList.Parent = list
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
pad.Parent = list
local statusL = Instance.new("TextLabel")
statusL.AnchorPoint = Vector2.new(1, 1)
statusL.Position = UDim2.new(1, -12, 1, -8)
statusL.Size = UDim2.new(1, -24, 0, 20)
statusL.BackgroundTransparency = 1
statusL.TextXAlignment = Enum.TextXAlignment.Right
statusL.TextColor3 = Color3.fromRGB(120, 120, 130)
statusL.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
statusL.TextSize = 13
statusL.ZIndex = 8
statusL.Parent = screenF
local msgCount = 0

local function phoneMsg(fromMe, text)
	msgCount += 1
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = msgCount
	row.ZIndex = 8
	row.Parent = list
	local b = Instance.new("TextLabel")
	b.AnchorPoint = Vector2.new(fromMe and 1 or 0, 0)
	b.Position = UDim2.fromScale(fromMe and 1 or 0, 0)
	b.Size = UDim2.new(0, 0, 0, 0)
	b.AutomaticSize = Enum.AutomaticSize.XY
	b.BackgroundColor3 = fromMe and Color3.fromRGB(0, 132, 255) or Color3.new(1, 1, 1)
	b.TextColor3 = fromMe and Color3.new(1, 1, 1) or Color3.fromRGB(20, 20, 24)
	b.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	b.TextSize = 15
	b.TextWrapped = true
	b.Text = text
	b.ZIndex = 9
	b.Parent = row
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(180, 400)
	c.Parent = b
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	local pp = Instance.new("UIPadding")
	pp.PaddingLeft, pp.PaddingRight, pp.PaddingTop, pp.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 7), UDim.new(0, 7)
	pp.Parent = b
end

------------------------------------------------------------------------ MƯA
local rainPart, rainConn
local function setRain(on)
	if on and not rainPart then
		rainPart = Instance.new("Part")
		rainPart.Anchored, rainPart.CanCollide, rainPart.CanQuery = true, false, false
		rainPart.Transparency = 1
		rainPart.Size = Vector3.new(70, 1, 70)
		rainPart.Parent = workspace
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(190, 205, 225))
		e.LightEmission = 0.2
		e.Transparency = NumberSequence.new(0.6)
		e.Size = NumberSequence.new(0.05)
		e.Squash = NumberSequence.new(5)
		e.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
		e.EmissionDirection = Enum.NormalId.Bottom
		e.Speed = NumberRange.new(80, 95)
		e.Lifetime = NumberRange.new(0.5, 0.7)
		e.Rate = 1800
		e.Parent = rainPart
		rainConn = RunService.RenderStepped:Connect(function()
			rainPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 30, 0))
		end)
	elseif not on and rainPart then
		rainConn:Disconnect()
		rainPart:Destroy()
		rainPart = nil
	end
end

------------------------------------------------------------------------ CAMERA
local dof = Instance.new("DepthOfFieldEffect")
dof.Enabled = false
dof.Parent = camera

local shot = nil -- spec hiện tại
local st = { pos = nil, look = nil, fov = 50, t0 = 0, fromPos = nil, fromLook = nil, fromFov = 50, snap = true }
local shake = { amp = 0, t0 = 0, dur = 0 }
local active = false

local function actorPart(p)
	local root = workspace:FindFirstChild("Phim")
	local actors = root and root:FindFirstChild("Actors")
	local m = actors and actors:FindFirstChild(p.actor)
	if not m then
		return nil, nil
	end
	return m:FindFirstChild(p.part or "Head"), m:FindFirstChild("HumanoidRootPart")
end

local function resolve(p)
	if p == nil then
		return nil
	end
	if typeof(p) == "Vector3" then
		return p
	end
	local part, rootPart = actorPart(p)
	if not part then
		return nil
	end
	local off = p.offset or Vector3.zero
	if p.localSpace then
		-- dùng hướng của thân (HumanoidRootPart) để máy không lắc theo nhịp thở của đầu
		local rot = (rootPart or part).CFrame.Rotation
		return part.Position + rot:VectorToWorldSpace(off)
	end
	return part.Position + off
end

local function ease(a)
	return 0.5 - math.cos(math.pi * math.clamp(a, 0, 1)) / 2
end

local function onShot(spec)
	st.fromPos, st.fromLook, st.fromFov = st.pos, st.look, camera.FieldOfView
	st.t0 = os.clock()
	st.snap = (spec.time or 0) <= 0 or st.pos == nil
	shot = spec
end

local function updateCamera(dt, now)
	if not shot then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local spec = shot
	local dur = spec.time or 0
	local alpha = dur > 0 and ease((now - st.t0) / dur) or 1

	local look = resolve(spec.look) or st.look or Vector3.zero
	local pos
	if spec.arc then
		local c = resolve(spec.arc.center) or look
		local ang = math.rad(spec.arc.a0 + (spec.arc.a1 - spec.arc.a0) * alpha)
		pos = c + Vector3.new(math.cos(ang) * spec.arc.radius, spec.arc.height or 0, math.sin(ang) * spec.arc.radius)
	else
		pos = resolve(spec.pos) or st.pos or (look + Vector3.new(0, 2, 8))
		if not st.snap and dur > 0 and st.fromPos then
			pos = st.fromPos:Lerp(pos, alpha)
			look = st.fromLook:Lerp(look, alpha)
		end
	end
	local fov = spec.fov or 50
	if dur > 0 and not spec.arc then
		fov = st.fromFov + (fov - st.fromFov) * alpha
	end

	-- làm mượt: cắt cảnh thì nhảy ngay, còn lại lọc bỏ rung giật của chuyển động nhân vật
	if st.snap or not st.pos then
		st.pos, st.look = pos, look
		st.snap = false
	else
		local kPos = 1 - math.exp(-(spec.smooth or 20) * dt)
		local kLook = 1 - math.exp(-(spec.smooth and spec.smooth * 1.6 or 25) * dt)
		st.pos = st.pos:Lerp(pos, kPos)
		st.look = st.look:Lerp(look, kLook)
	end

	local cf = CFrame.lookAt(st.pos, st.look)
	if spec.dutch then
		cf = cf * CFrame.Angles(0, 0, math.rad(spec.dutch))
	end
	local hh = (spec.handheld or 0) * 1.2
	if hh > 0 then
		cf = cf
			* CFrame.Angles(
				math.rad(math.noise(now * 0.55, 1.3) * hh),
				math.rad(math.noise(now * 0.45, 7.1) * hh),
				math.rad(math.noise(now * 0.3, 3.7) * hh * 0.5)
			)
	end
	if shake.amp > 0 then
		local k = 1 - (now - shake.t0) / shake.dur
		if k <= 0 then
			shake.amp = 0
		else
			local a = shake.amp * k * k
			cf = cf * CFrame.Angles(math.rad((math.random() - 0.5) * a * 4), math.rad((math.random() - 0.5) * a * 4), 0)
		end
	end
	camera.CFrame = cf
	camera.FieldOfView = fov

	-- lấy nét theo chủ thể
	if spec.dof and spec.dof > 0 then
		dof.Enabled = true
		dof.FarIntensity = spec.dof
		dof.NearIntensity = spec.near or spec.dof * 0.6
		dof.InFocusRadius = spec.focusRadius or 3
		dof.FocusDistance = (st.look - st.pos).Magnitude
	else
		dof.Enabled = false
	end
end

------------------------------------------------------------------------ CHARACTER NGƯỜI CHƠI
local function hideMe()
	local char = player.Character
	if not char then
		return
	end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("Decal") then
			p.LocalTransparencyModifier = 1
		end
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = true
	end
end

------------------------------------------------------------------------ VÒNG LẶP
local fanAngle = 0
RunService:BindToRenderStep("Phim", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local now = os.clock()
	updateFaces(dt, now)
	if active then
		updateCamera(dt, now)
		hideMe()
	end
	local root = workspace:FindFirstChild("Phim")
	local hub = root and root:FindFirstChild("Set") and root.Set:FindFirstChild("FanHub")
	if hub then
		fanAngle = (fanAngle + dt * 7) % (math.pi * 2)
		hub.CFrame = CFrame.new(hub.Position) * CFrame.Angles(0, fanAngle, 0)
	end
end)

------------------------------------------------------------------------ NHẬN CUE TỪ SERVER
cue.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "start" then
		active = true
		gui.Enabled = true
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
	elseif kind == "cam" then
		onShot(a)
	elseif kind == "fade" then
		-- a = 1 → tối đen, 0 → sáng; b = thời gian
		if (b or 0) <= 0 then
			fade.BackgroundTransparency = 1 - a
		else
			tween(fade, b, { BackgroundTransparency = 1 - a })
		end
	elseif kind == "title" then
		title.Text, subtitle.Text = a or "", b or ""
		tween(title, 1, { TextTransparency = 0 })
		tween(subtitle, 1.4, { TextTransparency = 0.2 })
		task.delay(3, function()
			tween(title, 1, { TextTransparency = 1 })
			tween(subtitle, 1, { TextTransparency = 1 })
		end)
	elseif kind == "caption" then
		caption.Text = a
		tween(caption, 0.8, { TextTransparency = 0.1 })
		task.delay(3.2, function()
			tween(caption, 1, { TextTransparency = 1 })
		end)
	elseif kind == "line" then
		if not a or a == "" then
			sub.Text = ""
			return
		end
		local color = SPEAKER_COLOR[a] or "#ffffff"
		local name = SPEAKER_NAME[a] or a
		if c == "narration" then
			sub.Text = string.format('<i><font color="%s">%s</font></i>', color, b)
		elseif c == "phone" then
			sub.Text = string.format('<font color="%s"><b>%s:</b></font> <i>%s</i>', color, name, b)
		else
			sub.Text = string.format('<font color="%s"><b>%s:</b></font> %s', color, name, b)
		end
	elseif kind == "sfx" then
		sfx(a, b)
	elseif kind == "shake" then
		shake.amp, shake.dur, shake.t0 = b or 1, a or 0.3, os.clock()
	elseif kind == "big" then
		big.Text = a or ""
		tween(big, 0.8, { TextTransparency = 0 })
		task.delay(b or 3, function()
			tween(big, 0.8, { TextTransparency = 1 })
		end)
	elseif kind == "phone" then
		-- a = { title=, msgs={ {me=true,text=}... }, status= }
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("Frame") then
				ch:Destroy()
			end
		end
		header.Text = a.title or ""
		statusL.Text = a.status or ""
		for _, m in ipairs(a.msgs or {}) do
			phoneMsg(m.me == true, m.text)
		end
		phoneUI.Visible = true
	elseif kind == "phoneAdd" then
		phoneMsg(a == true, b)
		statusL.Text = ""
		sfx(a and "tap" or "notify")
	elseif kind == "phoneStatus" then
		statusL.Text = a or ""
	elseif kind == "phoneHide" then
		phoneUI.Visible = false
	elseif kind == "rain" then
		setRain(a)
	elseif kind == "end" then
		for name in pairs(playing) do
			sfx(name, false)
		end
		setRain(false)
		phoneUI.Visible = false
		task.wait(1)
		active = false
		shot = nil
		dof.Enabled = false
		tween(fade, 1.5, { BackgroundTransparency = 1 })
		task.wait(1.6)
		gui.Enabled = false
		camera.CameraType = Enum.CameraType.Custom
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
end)
