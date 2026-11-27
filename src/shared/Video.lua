--[[
	WHAT IF — Nếu trọng lực giảm một nửa trong 7 ngày?  (ModuleScript trong ReplicatedStorage, tên "Video")
	Kịch bản + kiểm chứng: docs/WHAT-IF-TRONG-LUC.md

	Lời kể hiện thành phụ đề. Khi có file giọng đọc, ghép trong CapCut theo đúng thời điểm của từng đoạn
	(hoặc upload audio lên Roblox rồi điền ID vào NARRATION_ID để phát luôn trong phim).
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Video = {}

local NARRATION_ID = 0 -- ID audio giọng đọc toàn bộ video (0 = chỉ hiện phụ đề)
local MUSIC_ID = 0 -- nhạc nền kiểu khoa học/hồi hộp

local CAST = {
	Ban = { skin = "#efc8a8", hair = "curtain", hairColor = "#1e1a18", height = 1.02, outfit = { top = "hoodie", sleeves = "long", topColor = "#3b6ea5", bottom = "jeans", bottomColor = "#2f3a4a", shoes = "#f2f2f2", acc = { "backpack" } } },
	Linh = { skin = "#f4d5c0", hair = "bob", hairColor = "#3a241a", female = true, lips = "#c06a6a", height = 0.93, outfit = "linh_ao_bo" },
	Tuan = { skin = "#c98e68", hair = "spiky", hairColor = "#161412", height = 1.12, width = 1.1, outfit = { top = "tee", sleeves = "short", topColor = "#c8322f", bottom = "shorts", bottomColor = "#1d1d22", shoes = "#f2f2f2", acc = { "watch" } } },
	CoBanMi = { skin = "#d8a280", hair = "bun", hairColor = "#2a2626", female = true, height = 0.88, width = 0.98, proportion = 0.2, outfit = { top = "baba", sleeves = "long", topColor = "#6f8a6a", bottom = "pants", bottomColor = "#1e1f22", shoes = "#e8e4dc", acc = { "apron" } } },
	KhachA = { skin = "#f0cfb8", hair = "ponytail", hairColor = "#4a2e22", female = true, lips = "#c07070", height = 0.95, outfit = "an_cardigan" },
	KhachB = { skin = "#dcae8a", hair = "short", hairColor = "#1e1a18", height = 1.0, width = 1.08, outfit = "minh_ao_phong" },
	KhachC = { skin = "#f2d2bc", hair = "short", hairColor = "#2a1d18", height = 0.72, width = 0.85, headScale = 1.1, outfit = { top = "tee", sleeves = "short", topColor = "#e8c547", bottom = "shorts", bottomColor = "#3b5a8a", shoes = "#d64545", acc = {} } },
	KhachD = { skin = "#c8926e", hair = "short", hairColor = "#bdbdbd", height = 0.95, width = 1.05, outfit = { top = "shirt", sleeves = "long", topColor = "#d8d2c0", bottom = "pants", bottomColor = "#4a4a44", shoes = "#2a2a2a", acc = { "glasses" } } },
}
Video.CAST = CAST

function Video.run(Kit)
	local box, ball, cyl, weld, sign, light = Kit.box, Kit.ball, Kit.cyl, Kit.weld, Kit.sign, Kit.light
	local rad = math.rad
	local fx = Kit.fx
	local P = Kit.origin(Vector3.new(0, 0, -900))
	local NORMAL_G = 196.2
	local oldGravity = workspace.Gravity

	local function playId(id, volume)
		if id and id ~= 0 then
			local snd = Instance.new("Sound")
			snd.SoundId = "rbxassetid://" .. tostring(id)
			snd.Volume = volume
			snd.Parent = workspace
			snd:Play()
			return snd
		end
	end
	Kit.POSES.cheer = { RightShoulder = { 165, 0, 20 }, LeftShoulder = { 165, 0, -20 }, RightElbow = { 10, 0, 0 }, LeftElbow = { 10, 0, 0 } }
	Kit.POSES.reachUp = { RightShoulder = { 175, 0, 5 } }
	Kit.POSES.kneesTired = { RightShoulder = { 30, 0, 0 }, LeftShoulder = { 30, 0, 0 }, RightElbow = { 10, 0, 0 }, LeftElbow = { 10, 0, 0 } }
	Kit.POSES.flail = { RightShoulder = { 120, 0, 60 }, LeftShoulder = { 120, 0, -60 }, RightElbow = { 30, 0, 0 }, LeftElbow = { 30, 0, 0 } }
	Kit.POSES.stir = { RightShoulder = { 55, 0, 10 }, RightElbow = { 60, 0, 0 } }

	------------------------------------------------------------------ BỐI CẢNH: QUẢNG TRƯỜNG THÀNH PHỐ
	Kit.surround(P(0, 0, 0), 150, { seed = 5 })
	box("Plaza", Vector3.new(130, 1, 90), P(0, -0.5, 12), "#d8d0c0", Enum.Material.Slate)
	for x = -60, 60, 6 do
		box("Tile", Vector3.new(0.08, 0.02, 90), P(x, 0.01, 12), "#b8b0a0", nil, { CanCollide = false })
	end
	box("Road", Vector3.new(200, 1, 18), P(0, -0.5, -42), "#3c3d42", Enum.Material.Asphalt)
	box("SidewalkRoad", Vector3.new(200, 0.3, 6), P(0, 0.15, -30.5), "#b9a98f", Enum.Material.Brick)
	for x = -96, 96, 8 do
		box("Lane", Vector3.new(4, 0.02, 0.3), P(x, 0.01, -42), "#f2efe0", nil, { CanCollide = false })
	end
	for i = 0, 6 do
		box("Zebra", Vector3.new(1.2, 0.02, 14), P(-10 + i * 2.2, 0.01, -42), "#f2efe0", nil, { CanCollide = false })
	end
	box("FarSidewalk", Vector3.new(200, 0.3, 8), P(0, 0.15, -55), "#b9a98f", Enum.Material.Brick)

	-- nhà cao tầng bao quanh quảng trường
	local COLORS = { "#e3c06a", "#cfd6b0", "#b9cdd6", "#e0a8a0", "#e6d7b8", "#c9b8d9", "#a8c4a0", "#d98f6a" }
	for i = 0, 9 do
		local h = 30 + (i * 13) % 30
		local b = box("Building", Vector3.new(12, h, 14), P(-58 + i * 13, h / 2, 64), COLORS[(i % #COLORS) + 1], Enum.Material.Concrete)
		for fl = 1, math.floor(h / 6) - 1 do
			for k = -1, 1 do
				box("Win", Vector3.new(2.4, 2.8, 0.2), b.CFrame * CFrame.new(k * 3.6, -h / 2 + fl * 6, -7.05), "#5d7590", Enum.Material.Glass, { Transparency = 0.2 })
			end
		end
	end
	for i = 0, 8 do
		local h = 20 + (i * 7) % 18
		box("Shop", Vector3.new(9, h, 10), P(-56 + i * 14, h / 2, -66), COLORS[((i + 3) % #COLORS) + 1], Enum.Material.Plaster)
		local s = box("ShopSign", Vector3.new(7, 1.4, 0.3), P(-56 + i * 14, 6, -60.8), i % 2 == 0 and "#b3262e" or "#1f4e79")
		sign(s, ({ "TẠP HOÁ", "TRÀ SỮA", "PHỞ", "BÁNH MÌ", "ĐIỆN THOẠI", "CƠM", "NHÀ THUỐC", "SÁCH", "CAFE" })[i + 1], Enum.NormalId.Back, { color = Color3.fromRGB(255, 236, 170), font = Enum.Font.GothamBold })
	end
	for _, x in ipairs({ -68, 68 }) do
		box("SideBlock", Vector3.new(12, 36, 90), P(x, 18, 12), "#bfb3a0", Enum.Material.Concrete)
	end

	-- cây xanh + đèn đường + ghế
	local function tree(x, z, s)
		s = s or 1
		cyl("Trunk", 7 * s, 0.9 * s, P(x, 3.5 * s, z), "#5b4636", Enum.Material.Wood)
		for k = 0, 5 do
			local a = rad(k * 60)
			ball("Leaves", 4.2 * s, P(x + math.cos(a) * 1.6 * s, 8 * s + (k % 2) * 1.2, z + math.sin(a) * 1.6 * s), k % 2 == 0 and "#4f7d3d" or "#5f9248", Enum.Material.Grass)
		end
	end
	for _, p in ipairs({ { -50, 40 }, { -40, 48 }, { 48, 44 }, { 55, 30 }, { -54, -20 }, { 54, -18 }, { 20, 46 }, { -14, 50 } }) do
		tree(p[1], p[2], 1 + (p[1] % 3) * 0.1)
	end
	box("Grass", Vector3.new(30, 0.2, 18), P(42, 0.1, 38), "#6a9a4a", Enum.Material.Grass)
	box("Grass", Vector3.new(30, 0.2, 18), P(-44, 0.1, 40), "#6a9a4a", Enum.Material.Grass)
	for _, x in ipairs({ -40, -14, 14, 40 }) do
		box("LampPole", Vector3.new(0.4, 12, 0.4), P(x, 6, -27), "#2b2b2b", Enum.Material.Metal)
		ball("LampHead", 1, P(x, 12.2, -27), "#fff2d0", Enum.Material.Neon)
	end
	for _, x in ipairs({ -18, 18 }) do
		box("Bench", Vector3.new(6, 0.4, 1.6), P(x, 1.6, 26), "#8b6a4a", Enum.Material.Wood)
		box("BenchBack", Vector3.new(6, 1.6, 0.3), P(x, 2.6, 26.8), "#8b6a4a", Enum.Material.Wood)
		box("BenchLeg", Vector3.new(5.6, 1.4, 1.2), P(x, 0.7, 26), "#3a3a3a", Enum.Material.Metal)
	end

	-- đài phun nước giữa quảng trường
	local F = P(0, 0, 14)
	cyl("Basin", 1.4, 16, F + Vector3.new(0, 0.7, 0), "#c9c2b4", Enum.Material.Marble)
	cyl("Water", 0.2, 15, F + Vector3.new(0, 1.35, 0), "#5aa6c8", Enum.Material.Glass, { Transparency = 0.25 })
	cyl("Column", 3, 1.6, F + Vector3.new(0, 2.5, 0), "#d8d2c4", Enum.Material.Marble)
	local nozzle = cyl("Nozzle", 0.4, 0.8, F + Vector3.new(0, 4.2, 0), "#9aa3a8", Enum.Material.Metal)
	local jet = Instance.new("ParticleEmitter")
	jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	jet.Color = ColorSequence.new(Color3.fromRGB(190, 225, 255))
	jet.LightEmission = 0.2
	jet.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.15) })
	jet.Transparency = NumberSequence.new(0.35)
	jet.Speed = NumberRange.new(26, 30)
	jet.SpreadAngle = Vector2.new(12, 12)
	jet.Acceleration = Vector3.new(0, -NORMAL_G * 0.45, 0)
	jet.Lifetime = NumberRange.new(1.2, 1.4)
	jet.Rate = 220
	jet.EmissionDirection = Enum.NormalId.Top
	jet.Parent = nozzle

	-- sân bóng rổ
	local H = P(-32, 0, 22)
	box("Court", Vector3.new(22, 0.1, 18), H + Vector3.new(0, 0.05, -4), "#b86a4a", Enum.Material.Concrete)
	box("CourtLine", Vector3.new(22, 0.02, 0.25), H + Vector3.new(0, 0.11, -4), "#f2efe0")
	box("HoopPole", Vector3.new(0.5, 12, 0.5), H + Vector3.new(0, 6, 3.5), "#2b2b2b", Enum.Material.Metal)
	box("Backboard", Vector3.new(6, 3.6, 0.2), H + Vector3.new(0, 12, 2.9), "#f2f2f2", nil, { Transparency = 0.1 })
	local rim = cyl("Rim", 0.15, 2.2, H + Vector3.new(0, 10.8, 1.6), "#e2652b", Enum.Material.Metal)
	box("Net", Vector3.new(1.8, 1.4, 1.8), H + Vector3.new(0, 10, 1.6), "#ffffff", Enum.Material.Fabric, { Transparency = 0.6, CanCollide = false })

	-- cầu vượt + cầu thang
	local O = P(36, 0, -24)
	for i = 0, 13 do
		box("Step", Vector3.new(1, 0.55 * (i + 1), 4), O + Vector3.new(i * 1, 0.275 * (i + 1), 0), "#a9a294", Enum.Material.Concrete)
	end
	box("Overpass", Vector3.new(10, 0.8, 30), O + Vector3.new(18, 7.3, -8), "#a9a294", Enum.Material.Concrete)
	box("OverpassRail", Vector3.new(10, 1.6, 0.2), O + Vector3.new(18, 8.5, 6.8), "#2f5d50", Enum.Material.Metal)
	box("Pillar", Vector3.new(1.2, 7, 1.2), O + Vector3.new(18, 3.5, 2), "#a9a294", Enum.Material.Concrete)

	-- xe mì vỉa hè
	local M = P(14, 0, -28.5)
	box("Cart", Vector3.new(5, 3.2, 2.6), M + Vector3.new(0, 1.6, 0), "#d9d3c4", Enum.Material.Metal)
	local cartSign = box("CartSign", Vector3.new(4.6, 1, 0.1), M + Vector3.new(0, 2.2, -1.36), "#b3262e")
	sign(cartSign, "MÌ TÔM TRỨNG", Enum.NormalId.Front, { color = Color3.fromRGB(255, 236, 170), font = Enum.Font.GothamBold })
	local pot = cyl("Pot", 1.4, 2, M + Vector3.new(1, 3.9, 0), "#b8bec2", Enum.Material.Metal)
	cyl("PotWater", 0.1, 1.8, M + Vector3.new(1, 4.55, 0), "#d8c890", Enum.Material.Glass, { Transparency = 0.2 })
	box("Noodles", Vector3.new(1.2, 0.15, 1.2), M + Vector3.new(1, 4.62, 0), "#e8d08a", Enum.Material.Fabric)
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
	steam.Speed = NumberRange.new(2, 3)
	steam.Lifetime = NumberRange.new(1.5, 2.2)
	steam.Rate = 14
	steam.Parent = pot
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	bubbles.Size = NumberSequence.new(0.12)
	bubbles.Speed = NumberRange.new(1, 2)
	bubbles.Lifetime = NumberRange.new(0.2, 0.4)
	bubbles.Rate = 40
	bubbles.Parent = pot
	box("Umbrella", Vector3.new(7, 0.3, 7), M + Vector3.new(0, 8, 0), "#2f6ab0", Enum.Material.Fabric)
	box("UmbrellaPole", Vector3.new(0.2, 8, 0.2), M + Vector3.new(-2.2, 4, 0.9), "#dddddd", Enum.Material.Metal)
	box("Stool", Vector3.new(1.2, 1.2, 1.2), M + Vector3.new(-3.4, 0.6, -1.5), "#d64545")
	local thermo = Instance.new("BillboardGui")
	thermo.Size = UDim2.fromOffset(140, 60)
	thermo.StudsOffset = Vector3.new(0, 2.6, 0)
	thermo.AlwaysOnTop = true
	thermo.Enabled = false
	thermo.Parent = pot
	local thermoText = Instance.new("TextLabel")
	thermoText.Size = UDim2.fromScale(1, 1)
	thermoText.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	thermoText.TextColor3 = Color3.new(1, 1, 1)
	thermoText.Font = Enum.Font.GothamBlack
	thermoText.TextScaled = true
	thermoText.Text = "81°C"
	thermoText.Parent = thermo
	Instance.new("UICorner", thermoText).CornerRadius = UDim.new(0, 12)

	-- ô tô
	local function car(name, cf, color)
		local body = box(name, Vector3.new(9, 2, 4.2), cf * CFrame.new(0, 1.8, 0), color, Enum.Material.SmoothPlastic)
		local parts = {
			box("Cabin", Vector3.new(5, 1.8, 3.9), cf * CFrame.new(-0.5, 3.7, 0), color),
			box("Glass", Vector3.new(4.6, 1.5, 4.0), cf * CFrame.new(-0.5, 3.75, 0), "#2a3440", Enum.Material.Glass, { Transparency = 0.2 }),
			box("LightF", Vector3.new(0.1, 0.4, 0.8), cf * CFrame.new(4.52, 2.1, 1.4), "#fff2c0", Enum.Material.Neon),
			box("LightF2", Vector3.new(0.1, 0.4, 0.8), cf * CFrame.new(4.52, 2.1, -1.4), "#fff2c0", Enum.Material.Neon),
			box("LightB", Vector3.new(0.1, 0.4, 0.8), cf * CFrame.new(-4.52, 2.1, 1.4), "#c41e1e", Enum.Material.Neon),
			box("LightB2", Vector3.new(0.1, 0.4, 0.8), cf * CFrame.new(-4.52, 2.1, -1.4), "#c41e1e", Enum.Material.Neon),
		}
		for _, wx in ipairs({ -3, 3 }) do
			for _, wz in ipairs({ -2.1, 2.1 }) do
				local w = box("Wheel", Vector3.new(0.8, 2, 2), cf * CFrame.new(wx, 1, wz) * CFrame.Angles(0, rad(90), 0), "#1a1a1a")
				w.Shape = Enum.PartType.Cylinder
				table.insert(parts, w)
			end
		end
		local m = Instance.new("Model")
		m.Name = name
		body.Parent = m
		for _, p in ipairs(parts) do
			p.Parent = m
			p.Anchored = false
			p.CanCollide = false
			weld(body, p)
		end
		m.PrimaryPart = body
		m.Parent = Kit.SET
		return m
	end
	local function label(model, text, color)
		local g = Instance.new("BillboardGui")
		g.Size = UDim2.fromOffset(220, 44)
		g.StudsOffset = Vector3.new(0, 5, 0)
		g.AlwaysOnTop = true
		g.Parent = model.PrimaryPart
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundColor3 = color
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.Text = text
		t.Parent = g
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, 10)
		return g
	end
	local function moveModel(m, cf, t, style, dir)
		local v = Instance.new("CFrameValue")
		v.Value = m:GetPivot()
		local conn = v.Changed:Connect(function(c)
			m:PivotTo(c)
		end)
		local tw = Kit.tw(v, t, { Value = cf }, style or Enum.EasingStyle.Linear, dir)
		tw.Completed:Connect(function()
			conn:Disconnect()
			v:Destroy()
		end)
		return tw
	end
	local carA = car("CarA", CFrame.new(P(-70, 0, -38)), "#e6e6e6")
	local carB = car("CarB", CFrame.new(P(-70, 0, -46)), "#c8322f")
	car("Parked", CFrame.new(P(-6, 0, -30.5)) * CFrame.Angles(0, 0, 0), "#2a4d8f")

	------------------------------------------------------------------ DIỄN VIÊN
	local A = {}
	for name, spec in pairs(CAST) do
		A[name] = Kit.actor(name, spec)
	end
	local Ban, Linh, Tuan, CoBanMi = A.Ban, A.Linh, A.Tuan, A.CoBanMi
	local crowd = { A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Tuan }

	-- nhảy theo đường parabol (mượt từng khung hình)
	local function jump(a, height, dur, forward, poseName)
		local start = a.model:GetPivot()
		local fwd = start.LookVector * (forward or 0)
		Kit.pose(a, poseName or "cheer", 0.15, false)
		local t0 = os.clock()
		while true do
			local t = (os.clock() - t0) / dur
			if t >= 1 then
				break
			end
			a.model:PivotTo(start + Vector3.new(0, 4 * height * t * (1 - t), 0) + fwd * t)
			RunService.Heartbeat:Wait()
		end
		a.model:PivotTo(start + fwd)
		Kit.pose(a, "rest", 0.2, false)
	end

	local function setGravity(scale)
		workspace.Gravity = NORMAL_G * scale
		jet.Acceleration = Vector3.new(0, -NORMAL_G * 0.45 * scale, 0)
	end

	-- lời kể: hiện phụ đề + chạy hành động song song, chờ đúng thời lượng đoạn
	local function beat(text, dur, action)
		fx("line", "Lời dẫn", text, "narration")
		if action then
			task.spawn(action)
		end
		task.wait(dur)
	end

	local function placeCrowd()
		Kit.stand(A.KhachA, P(-8, 0, 0), P(0, 0, 14))
		Kit.stand(A.KhachB, P(10, 0, 2), P(0, 0, 14))
		Kit.stand(A.KhachC, P(-4, 0, -4), P(0, 0, 14))
		Kit.stand(A.KhachD, P(16, 0, 24), P(0, 0, 14))
		Kit.stand(Linh, P(4, 0, -2), P(0, 0, 14))
		Kit.stand(Tuan, P(-32, 0, 14), P(-32, 0, 30))
		Kit.stand(CoBanMi, P(14, 0, -26), P(14, 0, -40))
		Kit.pose(CoBanMi, "stir", 0.1, false)
		for _, a in ipairs(crowd) do
			Kit.expr(a, "happy")
		end
	end

	------------------------------------------------------------------ VIDEO
	Kit.look("morning")
	setGravity(0.5)
	placeCrowd()
	Kit.stand(Ban, P(-6, 0, -25.5), P(-6, 0, -40))
	Kit.expr(Ban, "happy")
	fx("start")
	fx("fade", 1, 0)
	playId(NARRATION_ID, 1)
	local music = playId(MUSIC_ID, 0.25)

	-- 0 · HOOK: bật nhảy vọt qua nóc ô tô
	Kit.cam({ pos = P(9, 2, -31), look = P(-6, 6, -30), mm = 22, time = 0, handheld = 0.15, occlude = false })
	fx("fade", 0, 0.2)
	beat("Nếu sáng mai bạn thức dậy… và trọng lực chỉ còn MỘT NỬA thì sao?", 4.2, function()
		task.wait(0.3)
		jump(Ban, 9, 1.6, 10, "cheer")
		Kit.expr(Ban, "laugh")
	end)
	fx("big", "-50% TRỌNG LỰC", 2.5)
	-- 1
	Kit.cam({ pos = P(-40, 30, -50), look = P(0, 2, 10), mm = 24, time = 0 })
	task.wait(0.05)
	Kit.cam({ pos = P(-28, 18, -40), look = P(0, 2, 10), mm = 24, time = 4.5 })
	beat("Nghe thì vui. Nhưng đến ngày thứ bảy, bạn sẽ ước nó chưa từng xảy ra.", 4.6, function()
		for i, a in ipairs(crowd) do
			task.delay(i * 0.35, function()
				jump(a, 6, 1.4, 0)
			end)
		end
	end)
	fx("line", "", "")
	fx("title", "NẾU TRỌNG LỰC GIẢM MỘT NỬA", "7 ngày · What if?")
	task.wait(2.4)

	-- 2 · NGÀY 1: nhảy cao gấp đôi
	fx("caption", "NGÀY 1 · Trọng lực 50%")
	Kit.stand(Ban, P(-6, 0, 4), P(-6, 0, -10))
	Kit.stand(Linh, P(-2, 0, 4), P(-2, 0, -10))
	Kit.cam({ pos = P(-4, 4, -10), look = P(-4, 4.5, 4), mm = 28, time = 0 })
	beat("Ngày 1. Bạn nhảy cao gấp đôi, và lơ lửng trên không lâu gấp đôi.", 4.6, function()
		task.wait(0.4)
		task.spawn(jump, Linh, 4, 1.3, 0)
		jump(Ban, 4, 1.3, 0)
		Kit.expr(Ban, "laugh")
		Kit.expr(Linh, "laugh")
		task.spawn(jump, Ban, 4, 1.3, 0)
		jump(Linh, 4, 1.3, 0)
	end)
	-- 3 · chạm vành rổ
	Kit.frame(Tuan, "FS", { angle = -30, mm = 28, height = 2 })
	beat("Một cú bật nhảy bình thường đưa bạn lên gần một mét. Chạm tới vành rổ dễ như đùa.", 5, function()
		Kit.walk(Tuan, P(-32, 0, 21), 10)
		jump(Tuan, 3.6, 1.5, 0, "reachUp")
		Kit.expr(Tuan, "laugh")
	end)
	fx("big", "≈ 1 mét", 1.5)
	-- 4 · bóng bay xa gấp đôi (vật lý thật)
	local soccer = ball("Football", 1.1, P(-14, 0.6, -6), "#f2f2f2", Enum.Material.SmoothPlastic)
	soccer.Anchored = false
	Kit.stand(Ban, P(-16, 0, -6), P(10, 0, -6))
	Kit.cam({ pos = P(-6, 6, -24), look = P(4, 4, -4), mm = 24, time = 0, smooth = 3 })
	beat("Một cú sút nhẹ, quả bóng bay xa gấp đôi.", 3.6, function()
		task.wait(0.3)
		Kit.pose(Ban, "reach", 0.15)
		soccer.AssemblyLinearVelocity = Vector3.new(34, 30, 0)
		Kit.cam({ pos = P(-6, 6, -24), look = { actor = "Ban", part = "Head" }, mm = 24, time = 0 })
		local t0 = os.clock()
		while os.clock() - t0 < 2.8 do
			Kit.fx("cam", { pos = P(-6, 6, -24), look = soccer.Position, fov = 40, time = 0, smooth = 6, drift = 0 })
			task.wait(0.1)
		end
	end)
	fx("big", "Bay xa ×2", 1.5)

	-- 5–6 · NGÀY 2: quãng phanh gấp đôi
	fx("caption", "NGÀY 2")
	local labelA = label(carA, "Trọng lực bình thường", Color3.fromRGB(40, 120, 200))
	local labelB = label(carB, "Trọng lực 50%", Color3.fromRGB(200, 50, 50))
	Kit.cam({ pos = P(-40, 10, -20), look = P(-20, 2, -42), mm = 28, time = 0 })
	beat("Ngày 2. Nhưng ngoài đường thì không vui như vậy.", 3.2, function()
		moveModel(carA, CFrame.new(P(-30, 0, -38)), 3)
		moveModel(carB, CFrame.new(P(-30, 0, -46)), 3)
	end)
	Kit.cam({ pos = P(-10, 14, -20), look = P(0, 1, -42), mm = 26, time = 0 })
	beat("Xe ép xuống mặt đường nhẹ hơn, bánh bám kém hơn. Phanh gấp, xe trượt dài gấp đôi.", 5.6, function()
		task.wait(0.6)
		moveModel(carA, CFrame.new(P(-14, 0, -38)), 1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		moveModel(carB, CFrame.new(P(2, 0, -46)), 2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(2.9)
		fx("big", "Quãng phanh ×2", 1.6)
	end)
	labelA:Destroy()
	labelB:Destroy()

	-- 7 · NGÀY 3: mưa chậm, đài phun cao gấp đôi
	fx("caption", "NGÀY 3")
	Kit.look("rain")
	fx("rain", true)
	fx("sfx", "rain", true)
	Kit.cam({ pos = P(0, 5, -10), look = P(0, 9, 14), mm = 24, time = 0 })
	task.wait(0.05)
	Kit.cam({ pos = P(0, 3, -4), look = P(0, 14, 14), mm = 24, time = 5 })
	beat("Ngày 3. Mưa rơi chậm hơn khoảng ba mươi phần trăm. Đài phun nước bắn cao gấp đôi.", 5.2)
	fx("rain", false)
	fx("sfx", "rain", false)

	-- 8 · cú twist
	Kit.look("afternoon")
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		Kit.tw(cc, 2, { TintColor = Color3.fromRGB(255, 190, 180), Saturation = -0.2 })
	end
	fx("sfx", "heartbeat", true)
	Kit.frame(Ban, "MCU", { angle = 15, mm = 40 })
	Kit.stand(Ban, P(36, 0, -22), P(50, 0, -22))
	Kit.expr(Ban, "worried")
	beat("Nhưng có một thứ đã thay đổi ngay từ giây đầu tiên… mà bạn không hề nhận ra.", 5)
	-- 9 · áp suất
	Kit.cam({ pos = P(30, 4, -36), look = P(36, 20, -22), mm = 20, time = 0 })
	task.wait(0.05)
	Kit.cam({ pos = P(20, 30, -50), look = P(36, 40, -10), mm = 20, time = 6 })
	beat("Không khí cũng nhẹ đi một nửa. Áp suất ở mặt đất chỉ còn như trên đỉnh núi cao năm nghìn rưỡi mét.", 6.6, function()
		task.wait(1.5)
		fx("big", "ÁP SUẤT 50%\n≈ đỉnh núi 5.500 m", 3.5)
	end)
	-- 10 · leo cầu thang thở dốc
	Kit.frame(Ban, "FS", { angle = -60, mm = 28, smooth = 4 })
	beat("Leo vài bậc cầu thang là thở dốc. Nhiều người đau đầu, buồn nôn, như bị say độ cao.", 5.6, function()
		local steps = {}
		for i = 0, 8 do
			table.insert(steps, P(36.5 + i, 0.55 * (i + 1), -24))
		end
		Kit.walk(Ban, steps, 3)
		Kit.expr(Ban, "tired")
		Kit.pose(Ban, "kneesTired", 0.4)
		Kit.frame(Ban, "MCU", { angle = 20, mm = 40 })
	end)
	-- 11 · mì tôm
	thermo.Enabled = true
	Kit.cam({ pos = P(10, 7.5, -34), look = P(15, 4.4, -28.5), mm = 35, time = 0, dof = 0.4, focusRadius = 2 })
	beat("Nước sôi ở khoảng tám mươi độ. Mì tôm… khó mà chín.", 4.8, function()
		Kit.expr(CoBanMi, "confused")
	end)
	thermo.Enabled = false
	fx("sfx", "heartbeat", false)
	if cc then
		Kit.tw(cc, 1, { TintColor = Color3.fromRGB(255, 236, 220), Saturation = 0.1 })
	end

	-- 12 · NGÀY 7: trọng lực trở lại
	fx("caption", "NGÀY 7")
	Kit.look("morning")
	placeCrowd()
	Kit.stand(Ban, P(0, 0, -8), P(0, 0, -20))
	local everyone = { Ban, A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Tuan }
	local footballs = {}
	for i = 1, 6 do
		local b = ball("Ball", 1.1, P(-20 + i * 6, 6 + (i % 3) * 2, 2), i % 2 == 0 and "#e2652b" or "#f2f2f2")
		table.insert(footballs, b)
	end
	-- mọi người đang lơ lửng trên không
	for i, a in ipairs(everyone) do
		local cf = a.model:GetPivot()
		Kit.glide(a, cf + Vector3.new(0, 5 + (i % 3) * 1.5, 0), 0)
		Kit.pose(a, "cheer", 0.01, false)
	end
	Kit.cam({ pos = P(0, 6, -26), look = P(0, 8, 4), mm = 22, time = 0, handheld = 0.1 })
	beat("Ngày 7. Và rồi, đúng lúc mọi người đang ở trên không…", 3.4, function()
		for i, a in ipairs(everyone) do
			task.spawn(function()
				local base = a.model:GetPivot()
				local t0 = os.clock()
				while os.clock() - t0 < 3.2 do
					a.model:PivotTo(base + Vector3.new(0, math.sin((os.clock() - t0) * 2 + i) * 0.4, 0))
					RunService.Heartbeat:Wait()
				end
			end)
		end
	end)
	beat("…trọng lực trở lại.", 2, function()
		setGravity(1)
		for _, b in ipairs(footballs) do
			b.Anchored = false
		end
		for _, a in ipairs(everyone) do
			Kit.pose(a, "flail", 0.1, false)
			Kit.expr(a, "shocked")
			task.spawn(function()
				local cf = a.model:GetPivot()
				local ground = Vector3.new(cf.Position.X, P(0, 0, 0).Y + a.standY, cf.Position.Z)
				Kit.glide(a, CFrame.new(ground) * cf.Rotation, 0.35, Enum.EasingStyle.Quad)
				Kit.pose(a, "rest", 0.2, false)
				Kit.expr(a, "pain")
			end)
		end
		task.wait(0.35)
		fx("shake", 0.5, 2)
	end)
	-- 13 · câu hỏi cuối
	Kit.cam({ pos = P(-14, 9, -24), look = P(0, 2, 2), mm = 24, time = 0 })
	task.wait(0.05)
	Kit.cam({ pos = P(-24, 20, -40), look = P(0, 2, 2), mm = 24, time = 5 })
	beat("Nếu được sống một ngày trọng lực giảm một nửa, bạn sẽ làm gì? Bình luận cho mình biết nhé.", 5.4, function()
		task.wait(1.5)
		for _, a in ipairs(everyone) do
			Kit.expr(a, "confused")
		end
		fx("big", "👇 BÌNH LUẬN NGAY", 3)
	end)
	fx("line", "", "")
	if music then
		Kit.tw(music, 1, { Volume = 0 })
	end
	fx("fade", 1, 1)
	task.wait(1.2)
	workspace.Gravity = oldGravity
	fx("end")
end

return Video
