--[[
	HỒ SƠ 02 — NGƯỜI TRONG GƯƠNG · Phần 1, Cảnh 1 "Tiếng rửa chén"
	Dựa theo kịch bản trong repo lamvideo (episodes/hem-co-chuyen/ho-so-02-nguoi-lam-thay).

	Script này (đặt trong ServerScriptService) tự:
	  1. Dựng phòng trọ hai người + hành lang dãy trọ (mặt bằng theo DUNG-CANH.md).
	  2. Tạo dàn nhân vật có tóc, quần áo, màu da, dáng nam/nữ khác nhau.
	  3. Diễn: hồi tưởng "Tối hôm trước" (O04) → sáng nay A01–A05 → ngưỡng cửa B01 + cuộc gọi Tùng.

	Đi kèm LocalScript HoSo02_Client (StarterPlayerScripts): camera mượt, biểu cảm khuôn mặt,
	phụ đề, letterbox 2.39:1, âm thanh.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local CONFIG = {
	AutoStart = true, -- tự diễn khi bấm Play
	StartDelay = 3, -- giây chờ trước khi diễn
	PlayFlashback = true, -- có đoạn hồi tưởng "Tối hôm trước"
}

local cue = ReplicatedStorage:FindFirstChild("HoSo02Cue") or Instance.new("RemoteEvent")
cue.Name = "HoSo02Cue"
cue.Parent = ReplicatedStorage

local old = workspace:FindFirstChild("HoSo02")
if old then
	old:Destroy()
end
local ROOT = Instance.new("Folder")
ROOT.Name = "HoSo02"
ROOT.Parent = workspace
local SET = Instance.new("Folder")
SET.Name = "Set"
SET.Parent = ROOT
local ACTORS = Instance.new("Folder")
ACTORS.Name = "Actors"
ACTORS.Parent = ROOT

local ORIGIN = Vector3.new(0, 0, -300) -- đặt xa điểm spawn
local function P(x, y, z)
	return ORIGIN + Vector3.new(x, y, z)
end
local function hex(s)
	return Color3.fromHex(s)
end
local rad = math.rad

------------------------------------------------------------------------ HÀM DỰNG
local function part(props, parent)
	local p = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent or SET
	return p
end

local function box(name, size, pos, color, material, extra)
	local props = {
		Name = name,
		Size = size,
		CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos),
		Color = typeof(color) == "string" and hex(color) or color,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return part(props)
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
	return w
end

local function label(p, text, face, color, bg)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.CanvasSize = Vector2.new(400, 200)
	g.LightInfluence = 1
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.BackgroundColor3 = bg or Color3.new(1, 1, 1)
	t.TextScaled = true
	t.Font = Enum.Font.PatrickHand
	t.TextColor3 = color or Color3.new(0.1, 0.1, 0.1)
	t.Text = text
	t.Parent = g
	return g
end

------------------------------------------------------------------------ PHÒNG TRỌ
-- Mặt bằng (nhìn từ phía trước vào): trái = cửa ra hành lang; sau–trái = bếp/bồn rửa;
-- sau–giữa = tủ quần áo (+ gương đứng cạnh hông tủ); sau–phải = bàn Nam; phải = cửa sổ;
-- tiền cảnh phải = nệm đôi (gối kem của Nam gần lối đi, gối xanh của Tùng sát tường).
local WALL = "#e2dcc3"
local SKIRT = "#9c9483"

box("Floor", Vector3.new(17, 1, 19), P(0, -0.5, 0), "#d9d1bf", Enum.Material.Marble)
for i = -8, 8, 2 do -- ron gạch
	box("Grout", Vector3.new(0.05, 0.02, 19), P(i, 0.01, 0), "#b9b1a0", nil, { CanCollide = false })
end
for j = -9, 9, 2 do
	box("Grout", Vector3.new(17, 0.02, 0.05), P(0, 0.01, j), "#b9b1a0", nil, { CanCollide = false })
end
box("Ceiling", Vector3.new(17, 1, 19), P(0, 10.5, 0), "#efebe0")

-- tường sau / trước
box("WallBack", Vector3.new(17, 11, 1), P(0, 5, 9.5), WALL)
box("WallFront", Vector3.new(17, 11, 1), P(0, 5, -9.5), WALL)
-- tường trái có ô cửa (z -6..-2, cao 7.5)
box("WallLeftA", Vector3.new(1, 11, 3.5), P(-8.5, 5, -7.75), WALL)
box("WallLeftB", Vector3.new(1, 11, 11.5), P(-8.5, 5, 3.75), WALL)
box("WallLeftTop", Vector3.new(1, 3, 4), P(-8.5, 9, -4), WALL)
-- tường phải có cửa sổ (z 0..5, y 3.5..7.5)
box("WallRightA", Vector3.new(1, 11, 9.5), P(8.5, 5, -4.75), WALL)
box("WallRightB", Vector3.new(1, 11, 4.5), P(8.5, 5, 7.25), WALL)
box("WallRightLow", Vector3.new(1, 3.5, 5), P(8.5, 1.75, 2.5), WALL)
box("WallRightTop", Vector3.new(1, 3, 5), P(8.5, 9, 2.5), WALL)
box("WindowGlass", Vector3.new(0.1, 4, 5), P(8.5, 5.5, 2.5), "#cfe6ee", Enum.Material.Glass, { Transparency = 0.75 })
box("WindowBarV", Vector3.new(0.2, 4, 0.15), P(8.4, 5.5, 2.5), "#6b6b6b", Enum.Material.Metal)
for _, y in ipairs({ 4.5, 5.5, 6.5 }) do
	box("WindowBarH", Vector3.new(0.2, 0.1, 5), P(8.4, y, 2.5), "#6b6b6b", Enum.Material.Metal)
end
-- chân tường
box("SkirtBack", Vector3.new(16, 0.4, 0.1), P(0, 0.2, 8.95), SKIRT)
box("SkirtRight", Vector3.new(0.1, 0.4, 18), P(7.95, 0.2, 0), SKIRT)
-- nhà đối diện nhìn qua cửa sổ
box("NeighborWall", Vector3.new(1, 30, 30), P(22, 10, 2), "#c9b79c", Enum.Material.Concrete)

-- cửa chính (mở vào trong, áp sát góc tường trước) + then sắt
local HINGE = P(-8.5, 3.75, -6)
local door = box("Door", Vector3.new(0.3, 7.5, 4), CFrame.new(HINGE) * CFrame.Angles(0, rad(80), 0) * CFrame.new(0, 0, 2), "#7a5a3c", Enum.Material.Wood)
local doorKnob = box("DoorKnob", Vector3.new(0.3, 0.3, 0.3), door.CFrame * CFrame.new(0.25, 0, 1.6), "#c8b070", Enum.Material.Metal)
weld(door, doorKnob)
box("LatchPlate", Vector3.new(0.15, 0.5, 0.4), P(-8, 4.2, -2.2), "#4a4a4a", Enum.Material.Metal)
box("LatchBar", Vector3.new(0.12, 0.15, 1.0), P(-7.95, 4.2, -2.7), "#5a5a5a", Enum.Material.Metal, { Name = "LatchBar" })
box("DoorFrameL", Vector3.new(1.1, 7.5, 0.25), P(-8.5, 3.75, -6.1), "#5a4430", Enum.Material.Wood)
box("DoorFrameR", Vector3.new(1.1, 7.5, 0.25), P(-8.5, 3.75, -1.9), "#5a4430", Enum.Material.Wood)
box("DoorSill", Vector3.new(1.2, 0.08, 4), P(-8.5, 0.04, -4), "#6a6a6a")

-- bếp + bồn rửa (sau–trái)
box("Counter", Vector3.new(4.6, 3.4, 2.2), P(-5.7, 1.7, 8.1), "#d6d0c4", Enum.Material.Marble)
box("CounterFront", Vector3.new(4.6, 3, 0.05), P(-5.7, 1.6, 6.98), "#a99f8d", Enum.Material.Wood)
box("Sink", Vector3.new(1.9, 0.1, 1.4), P(-6.2, 3.42, 8.0), "#9aa3a8", Enum.Material.Metal)
box("Faucet", Vector3.new(0.15, 0.9, 0.15), P(-6.2, 3.85, 8.8), "#b8bec2", Enum.Material.Metal)
box("FaucetSpout", Vector3.new(0.15, 0.15, 0.6), P(-6.2, 4.25, 8.55), "#b8bec2", Enum.Material.Metal)
box("Backsplash", Vector3.new(4.6, 2.5, 0.1), P(-5.7, 4.65, 8.95), "#dfe9ea", Enum.Material.Marble)
box("Shelf", Vector3.new(3.6, 0.15, 1), P(-5.7, 7, 8.5), "#8a6d4e", Enum.Material.Wood)
box("DishRack", Vector3.new(1.3, 0.8, 1), P(-4.3, 3.8, 8.2), "#8fa6a0", Enum.Material.Metal, { Transparency = 0.3 })
local function bowl(name, pos, color)
	return part({
		Name = name,
		ClassName = "Part",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 0.75, 0.75),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, rad(90)),
		Color = hex(color or "#f2efe6"),
		Material = Enum.Material.SmoothPlastic,
	})
end
for i = 0, 3 do
	bowl("DirtyBowl", P(-6.6 + (i % 2) * 0.5, 3.55 + i * 0.12, 7.9), i % 2 == 0 and "#f2efe6" or "#d9e4ea")
end
for i = 0, 3 do
	bowl("ShelfBowl", P(-6.8 + i * 0.8, 7.25, 8.5), "#e9e4d8")
end

-- tủ quần áo (sau–giữa)
box("Wardrobe", Vector3.new(4, 8, 2.2), P(0.6, 4, 8.3), "#8b6a4a", Enum.Material.Wood)
box("WardrobeSeam", Vector3.new(0.05, 7.6, 0.05), P(0.6, 4, 7.18), "#5a4430")
box("WardrobeHandleL", Vector3.new(0.1, 0.8, 0.1), P(0.35, 4.3, 7.15), "#c8b070", Enum.Material.Metal)
box("WardrobeHandleR", Vector3.new(0.1, 0.8, 0.1), P(0.85, 4.3, 7.15), "#c8b070", Enum.Material.Metal)

-- gương đứng khung gỗ (~50×120 cm) cạnh hông tủ — đạo cụ trung tâm của cả tập
local mirrorFrame = box("MirrorFrame", Vector3.new(1.8, 4.1, 0.25), CFrame.new(P(-2.3, 2.15, 8.4)) * CFrame.Angles(rad(-6), 0, 0), "#6b4e34", Enum.Material.Wood)
local mirrorGlass = box("MirrorGlass", Vector3.new(1.5, 3.8, 0.05), mirrorFrame.CFrame * CFrame.new(0, 0, -0.14), "#7c8c92", Enum.Material.Glass, { Reflectance = 0.65, Transparency = 0 })
mirrorGlass.Name = "MirrorGlass"

-- bàn Nam (sau–phải): laptop, đèn bàn, sách
box("DeskTop", Vector3.new(5, 0.25, 2.4), P(5.2, 2.6, 7.9), "#a07c58", Enum.Material.Wood)
for _, dx in ipairs({ -2.3, 2.3 }) do
	for _, dz in ipairs({ -1.0, 1.0 }) do
		box("DeskLeg", Vector3.new(0.2, 2.5, 0.2), P(5.2 + dx, 1.25, 7.9 + dz), "#5a4430", Enum.Material.Wood)
	end
end
box("LaptopBase", Vector3.new(1.4, 0.08, 1), P(4.8, 2.77, 7.7), "#3b3f45", Enum.Material.Metal)
local screen = box("LaptopScreen", Vector3.new(1.4, 0.95, 0.06), CFrame.new(P(4.8, 3.25, 8.2)) * CFrame.Angles(rad(-12), 0, 0), "#2a2e33", Enum.Material.Metal)
box("LaptopDisplay", Vector3.new(1.25, 0.8, 0.02), screen.CFrame * CFrame.new(0, 0, -0.04), "#6fa0c8", Enum.Material.Neon, { Transparency = 0.2 })
box("LampBase", Vector3.new(0.5, 0.1, 0.5), P(6.9, 2.78, 8.4), "#2b2b2b", Enum.Material.Metal)
box("LampArm", Vector3.new(0.1, 1.4, 0.1), P(6.9, 3.5, 8.4), "#2b2b2b", Enum.Material.Metal)
local lampHead = box("LampHead", Vector3.new(0.6, 0.35, 0.6), P(6.7, 4.2, 8.2), "#ffd9a0", Enum.Material.Neon)
local lampLight = Instance.new("SpotLight")
lampLight.Face = Enum.NormalId.Bottom
lampLight.Angle = 90
lampLight.Range = 10
lampLight.Brightness = 2
lampLight.Color = Color3.fromRGB(255, 200, 140)
lampLight.Shadows = true
lampLight.Parent = lampHead
for i = 0, 2 do
	box("Book", Vector3.new(1.1, 0.18, 0.8), P(6.2, 2.82 + i * 0.18, 7.3), ({ "#8a3b3b", "#3b5a8a", "#c9b26a" })[i + 1])
end
box("Calendar", Vector3.new(1.6, 2, 0.05), P(5.2, 6.4, 8.97), "#f4f1ea")
label(SET.Calendar, "THÁNG 11", Enum.NormalId.Front)

-- ghế làm việc 4 chân gỗ — đặt trong đường đi cạnh nệm (cú va A05)
local chairRoot = box("ChairSeat", Vector3.new(1.8, 0.2, 1.8), P(0.6, 1.9, -2.3), "#8b6a4a", Enum.Material.Wood)
local chairParts = {}
for _, dx in ipairs({ -0.75, 0.75 }) do
	for _, dz in ipairs({ -0.75, 0.75 }) do
		table.insert(chairParts, box("ChairLeg", Vector3.new(0.18, 1.8, 0.18), P(0.6 + dx, 0.9, -2.3 + dz), "#5a4430", Enum.Material.Wood))
	end
end
table.insert(chairParts, box("ChairBack", Vector3.new(1.8, 1.8, 0.15), P(0.6, 2.9, -1.48), "#8b6a4a", Enum.Material.Wood))
for _, p in ipairs(chairParts) do
	p.Anchored = false
	weld(chairRoot, p)
end
-- áo xanh rêu của Nam vắt trên lưng ghế (chỉ có ở hồi tưởng tối hôm trước)
local greenShirt = box("GreenShirtOnChair", Vector3.new(1.6, 1.3, 0.35), P(0.6, 3.2, -1.48), "#5c7a70", Enum.Material.Fabric)
greenShirt.Anchored = false
weld(chairRoot, greenShirt)

-- nệm đôi tiền cảnh phải (trục dài theo Z, đầu nằm ở phía +Z)
box("Mattress", Vector3.new(6, 1, 7.5), P(4.6, 0.5, -4.5), "#e8e2d4", Enum.Material.Fabric)
box("MattressSheet", Vector3.new(6.05, 0.05, 7.55), P(4.6, 1.0, -4.5), "#c9d6dc", Enum.Material.Fabric)
box("PillowNam", Vector3.new(2.2, 0.5, 1.2), P(3.2, 1.25, -1.5), "#efe3c8", Enum.Material.Fabric)
box("PillowTung", Vector3.new(2.2, 0.5, 1.2), P(6.1, 1.25, -1.5), "#7fa3c4", Enum.Material.Fabric)
local blanket = box("BlanketNam", Vector3.new(2.6, 0.35, 4.2), P(3.2, 1.75, -4.8), "#a9b98f", Enum.Material.Fabric)
local blanketTung = box("BlanketTung", Vector3.new(2.4, 0.25, 3.2), P(6.1, 1.15, -6.2), "#c79b6c", Enum.Material.Fabric)
local phone = box("Phone", Vector3.new(0.35, 0.06, 0.65), P(2.0, 1.06, -2.0), "#1d1f22", Enum.Material.Metal)
local phoneScreen = box("PhoneScreen", Vector3.new(0.3, 0.02, 0.58), phone.CFrame * CFrame.new(0, 0.04, 0), "#a8d0ff", Enum.Material.Neon, { Transparency = 0.6 })
phoneScreen.Anchored = false
weld(phone, phoneScreen)
local phoneLight = Instance.new("PointLight")
phoneLight.Range = 5
phoneLight.Brightness = 0
phoneLight.Color = Color3.fromRGB(170, 200, 255)
phoneLight.Parent = phoneScreen

-- quạt trần (client quay cánh) + đèn tuýp
box("FanRod", Vector3.new(0.2, 1, 0.2), P(0, 9.5, -1), "#ededed")
local fanHub = box("FanHub", Vector3.new(0.8, 0.4, 0.8), P(0, 8.9, -1), "#ededed", Enum.Material.Metal)
fanHub.Name = "FanHub"
for i = 0, 2 do
	local a = rad(i * 120)
	local blade = box("FanBlade", Vector3.new(3.2, 0.06, 0.6), CFrame.new(fanHub.Position) * CFrame.Angles(0, a, 0) * CFrame.new(1.8, 0, 0), "#f3f3f3")
	blade.Anchored = false
	weld(fanHub, blade)
end
local tube = box("CeilingTube", Vector3.new(4, 0.2, 0.3), P(0, 9.85, 4), "#ffffff", Enum.Material.Neon)
local tubeLight = Instance.new("SurfaceLight")
tubeLight.Face = Enum.NormalId.Bottom
tubeLight.Range = 22
tubeLight.Angle = 120
tubeLight.Brightness = 1.6
tubeLight.Color = Color3.fromRGB(225, 240, 255)
tubeLight.Shadows = true
tubeLight.Parent = tube

-- nắng sớm hắt qua cửa sổ
local sun = box("SunSource", Vector3.new(1, 1, 1), CFrame.lookAt(P(16, 10, 3), P(3, 0, -2)), "#ffffff", nil, { Transparency = 1, CanCollide = false, CastShadow = false })
local sunLight = Instance.new("SpotLight")
sunLight.Face = Enum.NormalId.Front
sunLight.Angle = 45
sunLight.Range = 32
sunLight.Brightness = 7
sunLight.Color = Color3.fromRGB(255, 226, 180)
sunLight.Shadows = true
sunLight.Parent = sun
local fill = box("WindowFill", Vector3.new(0.1, 4, 5), P(8.0, 5.5, 2.5), "#ffffff", nil, { Transparency = 1, CanCollide = false, CastShadow = false })
local fillLight = Instance.new("SurfaceLight")
fillLight.Face = Enum.NormalId.Left
fillLight.Range = 16
fillLight.Angle = 90
fillLight.Brightness = 0.8
fillLight.Color = Color3.fromRGB(210, 225, 255)
fillLight.Parent = fill

------------------------------------------------------------------------ HÀNH LANG DÃY TRỌ
box("HallFloor", Vector3.new(7, 1, 30), P(-12, -0.5, 0), "#bdb6a6", Enum.Material.Concrete)
box("HallCeiling", Vector3.new(7, 1, 30), P(-12, 10.5, 0), "#e5e0d3")
box("HallRailBase", Vector3.new(0.6, 3, 26), P(-15.2, 1.5, 2), "#cfc8b6", Enum.Material.Concrete)
box("HallRail", Vector3.new(0.3, 0.2, 26), P(-15.2, 3.6, 2), "#4b4b4b", Enum.Material.Metal)
for z = -10, 14, 2 do
	box("HallBaluster", Vector3.new(0.1, 0.6, 0.1), P(-15.2, 3.2, z), "#4b4b4b", Enum.Material.Metal)
end
box("HallPillar", Vector3.new(0.8, 11, 0.8), P(-15.2, 5, -11), "#cfc8b6", Enum.Material.Concrete)
box("HallPillar", Vector3.new(0.8, 11, 0.8), P(-15.2, 5, 15), "#cfc8b6", Enum.Material.Concrete)
box("HallEnd", Vector3.new(7, 11, 1), P(-12, 5, 15.5), WALL)
-- cửa các phòng khác
for _, z in ipairs({ 10, -13 }) do
	box("OtherDoor", Vector3.new(0.3, 7.5, 4), P(-8.9, 3.75, z), "#3f5f6f", Enum.Material.Wood)
end
box("WallLeftFar", Vector3.new(1, 11, 7), P(-8.5, 5, 12.5), WALL)
box("WallLeftNear", Vector3.new(1, 11, 5), P(-8.5, 5, -12.5), WALL)
-- cầu thang đi xuống ở đầu dãy
for i = 0, 6 do
	box("Stair", Vector3.new(4, 0.5, 1.2), P(-12.5, -0.25 - i * 0.6, -15.6 - i * 1.2), "#a9a294", Enum.Material.Concrete)
end
box("StairWall", Vector3.new(1, 14, 10), P(-9.9, 2, -19), WALL)
-- góc đồ cho tặng của dãy trọ: "Ai cần cứ lấy"
box("GiveawayBox", Vector3.new(2, 1.4, 1.6), P(-10.2, 0.7, 13.6), "#b48a5a", Enum.Material.Cardboard)
local sign = box("GiveawaySign", Vector3.new(2, 1, 0.05), P(-10.2, 2.4, 14.95), "#fff7d6")
label(sign, "Ai cần cứ lấy", Enum.NormalId.Front)
box("ShoeRack", Vector3.new(0.8, 1.2, 2.4), P(-9.4, 0.6, -7.6), "#6b6f72", Enum.Material.Metal)
box("Slippers", Vector3.new(0.6, 0.15, 0.9), P(-9.4, 1.27, -7.9), "#425850")
box("Slippers", Vector3.new(0.6, 0.15, 0.9), P(-9.4, 1.27, -7.1), "#d4673f")
-- bóng đèn hành lang
for _, z in ipairs({ -8, 6 }) do
	local bulb = part({ Name = "HallBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = CFrame.new(P(-12, 9.6, z)), Color = hex("#ffe2b0"), Material = Enum.Material.Neon })
	local l = Instance.new("PointLight")
	l.Range = 14
	l.Brightness = 1.2
	l.Color = Color3.fromRGB(255, 214, 160)
	l.Shadows = true
	l.Parent = bulb
end
-- cây, dây phơi bên ngoài lan can cho có sức sống
box("Outside", Vector3.new(1, 40, 60), P(-40, 5, 0), "#bcc9c4", Enum.Material.Concrete)
for i = 0, 4 do
	box("Laundry", Vector3.new(0.1, 1.4, 1.1), P(-16.5, 7.5, -6 + i * 2.2), ({ "#d64545", "#e8e8e8", "#4a78b8", "#e8c547", "#7aa87a" })[i + 1], Enum.Material.Fabric)
end
box("LaundryLine", Vector3.new(0.05, 0.05, 14), P(-16.5, 8.2, -1.6), "#333333")

------------------------------------------------------------------------ ÁNH SÁNG THEO GIỜ
local function ensure(className, parent, name)
	local obj = parent:FindFirstChild(name or className) or Instance.new(className)
	obj.Name = name or className
	obj.Parent = parent
	return obj
end
pcall(function()
	Lighting.Technology = Enum.Technology.Future
end)
local atm = ensure("Atmosphere", Lighting)
local bloom = ensure("BloomEffect", Lighting)
local cc = ensure("ColorCorrectionEffect", Lighting)
bloom.Intensity, bloom.Size, bloom.Threshold = 0.5, 24, 1.4

local function setTime(mode)
	if mode == "night" then
		Lighting.ClockTime = 22.5
		Lighting.Brightness = 0.3
		Lighting.Ambient = Color3.fromRGB(28, 30, 40)
		Lighting.OutdoorAmbient = Color3.fromRGB(30, 34, 48)
		Lighting.ExposureCompensation = 0.2
		atm.Density, atm.Haze, atm.Color = 0.25, 0.5, Color3.fromRGB(70, 80, 110)
		cc.TintColor, cc.Saturation, cc.Contrast = Color3.fromRGB(215, 222, 255), -0.1, 0.12
		sunLight.Enabled, fillLight.Enabled = false, false
		tubeLight.Enabled, lampLight.Enabled = true, true
		tube.Material, lampHead.Material = Enum.Material.Neon, Enum.Material.Neon
		phoneLight.Brightness = 1.2
	else -- sáng sớm
		Lighting.ClockTime = 7.2
		Lighting.Brightness = 2.2
		Lighting.Ambient = Color3.fromRGB(70, 68, 66)
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
		Lighting.ExposureCompensation = 0.15
		atm.Density, atm.Haze, atm.Color = 0.3, 1.2, Color3.fromRGB(235, 225, 210)
		cc.TintColor, cc.Saturation, cc.Contrast = Color3.fromRGB(255, 246, 235), 0.02, 0.1
		sunLight.Enabled, fillLight.Enabled = true, true
		tubeLight.Enabled, lampLight.Enabled = false, false
		tube.Material, lampHead.Material = Enum.Material.SmoothPlastic, Enum.Material.SmoothPlastic
		phoneLight.Brightness = 0
	end
end

------------------------------------------------------------------------ NHÂN VẬT
-- Theo THIET-KE-NHAN-VAT.md: phân biệt bằng tóc, quần áo, màu da và dáng người.
local CAST = {
	Nam = { skin = "#f0cbb2", shirt = "#8b8e92", pants = "#707370", feet = "#425850", hair = "messy", hairColor = "#1b1b1f", mole = "L", shorts = true },
	NguoiKia = { skin = "#f0cbb2", shirt = "#5c7a70", pants = "#707370", feet = "#425850", hair = "messy", hairColor = "#1b1b1f", mole = "R", shorts = true },
	Tung = { skin = "#d9a484", shirt = "#d4673f", pants = "#2c3138", feet = "#f2f2f2", hair = "spiky", hairColor = "#241f1c", shorts = true, build = 1.05 },
	HangXom = { skin = "#e5bca2", shirt = "#7c6a58", pants = "#56595e", feet = "#8a7a6a", hair = "bun", hairColor = "#222024", longSleeve = true, female = true },
	ChuTro = { skin = "#eec2a8", shirt = "#7a405a", pants = "#3c3e44", feet = "#2a2a2a", hair = "bunclip", hairColor = "#2a2220", female = true, bag = true },
}

local ANIM = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	sit = "rbxassetid://2506281703",
}

local function hairPart(head, name, size, offset, color, shape, rot)
	local p = Instance.new("Part")
	p.Name = "Hair_" .. name
	p.Size = size
	p.Shape = shape or Enum.PartType.Block
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.CFrame = head.CFrame * CFrame.new(offset) * (rot or CFrame.new())
	p.Parent = head.Parent
	weld(head, p)
	return p
end

local function buildHair(head, style, color)
	local s = head.Size
	local w, h, d = s.X, s.Y, s.Z
	-- mũ tóc phủ đỉnh đầu (chung cho mọi kiểu)
	hairPart(head, "Cap", Vector3.new(w * 1.08, h * 0.32, d * 1.08), Vector3.new(0, h * 0.42, 0.02), color)
	if style == "messy" then -- tóc khối anime rối bù, phủ trán và gáy (Nam / Người Kia)
		hairPart(head, "Back", Vector3.new(w * 1.06, h * 0.75, d * 0.3), Vector3.new(0, h * 0.12, d * 0.42), color)
		hairPart(head, "SideL", Vector3.new(w * 0.14, h * 0.5, d * 0.9), Vector3.new(-w * 0.5, h * 0.18, 0.05), color)
		hairPart(head, "SideR", Vector3.new(w * 0.14, h * 0.5, d * 0.9), Vector3.new(w * 0.5, h * 0.18, 0.05), color)
		for i, x in ipairs({ -0.3, -0.05, 0.22 }) do -- mái lởm chởm che trán
			hairPart(head, "Fringe" .. i, Vector3.new(w * 0.3, h * 0.34, d * 0.14), Vector3.new(w * x, h * 0.24, -d * 0.47), color, nil, CFrame.Angles(rad(-8), 0, rad(({ 14, -6, 18 })[i])))
		end
		for i = 1, 3 do -- chỏm rối
			hairPart(head, "Tuft" .. i, Vector3.new(w * 0.22, h * 0.2, d * 0.22), Vector3.new(w * (-0.25 + i * 0.15), h * 0.6, d * (0.1 - i * 0.08)), color, nil, CFrame.Angles(rad(20 * i), rad(30 * i), rad(-15 * i)))
		end
	elseif style == "spiky" then -- tóc vuốt dựng nhọn thể thao (Tùng)
		hairPart(head, "Back", Vector3.new(w * 1.04, h * 0.4, d * 0.25), Vector3.new(0, h * 0.25, d * 0.44), color)
		for i = 0, 5 do
			local x = (i % 3 - 1) * 0.28
			local z = (i < 3) and -0.18 or 0.18
			hairPart(head, "Spike" .. i, Vector3.new(w * 0.22, h * 0.42, d * 0.22), Vector3.new(w * x, h * 0.66, d * z), color, nil, CFrame.Angles(rad(z * 60 - 20), 0, rad(-x * 50)))
		end
	elseif style == "bun" or style == "bunclip" then -- tóc búi cao sau gáy (hàng xóm / cô chủ trọ)
		hairPart(head, "Back", Vector3.new(w * 1.06, h * 0.85, d * 0.32), Vector3.new(0, h * 0.08, d * 0.4), color)
		hairPart(head, "SideL", Vector3.new(w * 0.12, h * 0.6, d * 0.8), Vector3.new(-w * 0.5, h * 0.12, 0.08), color)
		hairPart(head, "SideR", Vector3.new(w * 0.12, h * 0.6, d * 0.8), Vector3.new(w * 0.5, h * 0.12, 0.08), color)
		hairPart(head, "Part", Vector3.new(w * 0.9, h * 0.12, d * 0.12), Vector3.new(0, h * 0.42, -d * 0.48), color)
		local bun = hairPart(head, "Bun", Vector3.new(w * 0.55, w * 0.55, w * 0.55), Vector3.new(0, h * 0.5, d * 0.6), color, Enum.PartType.Ball)
		if style == "bunclip" then -- kẹp càng cua hổ phách
			hairPart(head, "Clip", Vector3.new(w * 0.5, h * 0.12, d * 0.12), Vector3.new(0, h * 0.5, d * 0.88), hex("#964818"))
		end
		return bun
	end
end

local function makeActor(name, spec)
	local desc = Instance.new("HumanoidDescription")
	local skin, shirt, pants = hex(spec.skin), hex(spec.shirt), hex(spec.pants)
	desc.HeadColor, desc.TorsoColor = skin, shirt
	desc.LeftArmColor, desc.RightArmColor = shirt, shirt
	desc.LeftLegColor, desc.RightLegColor = pants, pants
	if spec.female then
		desc.HeightScale, desc.WidthScale, desc.DepthScale, desc.HeadScale = 0.94, 0.85, 0.9, 0.98
		desc.BodyTypeScale, desc.ProportionScale = 0.3, 0.4
	else
		desc.HeightScale = spec.build or 1
		desc.WidthScale = spec.build or 1
	end
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	model.Name = name
	local anim = model:FindFirstChild("Animate")
	if anim then
		anim:Destroy()
	end
	local head = model:WaitForChild("Head")
	local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
	if face then
		face:Destroy()
	end

	-- tô màu từng phần: áo cộc tay / dài tay, quần lửng / quần dài, dép
	local function paint(names, color)
		for _, n in ipairs(names) do
			local p = model:FindFirstChild(n)
			if p then
				p.Color = color
			end
		end
	end
	paint({ "UpperTorso", "LeftUpperArm", "RightUpperArm" }, shirt)
	paint({ "LowerTorso", "LeftUpperLeg", "RightUpperLeg" }, pants)
	paint({ "LeftHand", "RightHand" }, skin)
	paint({ "LeftLowerArm", "RightLowerArm" }, spec.longSleeve and shirt or skin)
	paint({ "LeftLowerLeg", "RightLowerLeg" }, spec.shorts and skin or pants)
	paint({ "LeftFoot", "RightFoot" }, hex(spec.feet))
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Material = Enum.Material.SmoothPlastic
		end
	end
	-- viền cổ áo cho đỡ trơn
	local collar = hairPart(model.UpperTorso, "Collar", Vector3.new(model.UpperTorso.Size.X * 0.45, 0.08, 0.3), Vector3.new(0, model.UpperTorso.Size.Y * 0.47, -model.UpperTorso.Size.Z * 0.35), shirt:Lerp(Color3.new(1, 1, 1), 0.35))
	collar.Name = "Collar"
	if spec.bag then -- túi bao tử đeo chéo + chùm chìa khóa
		hairPart(model.LowerTorso, "Bag", Vector3.new(0.7, 0.45, 0.25), Vector3.new(0.35, 0.1, -0.5), hex("#1a191b"))
		hairPart(model.LowerTorso, "Keys", Vector3.new(0.15, 0.25, 0.08), Vector3.new(0.6, -0.15, -0.6), hex("#d4af37"))
	end

	buildHair(head, spec.hair, hex(spec.hairColor))

	-- tấm mặt: client vẽ mắt / mày / miệng / nốt ruồi lên đây và đổi biểu cảm
	local plate = Instance.new("Part")
	plate.Name = "FacePlate"
	plate.Transparency = 1
	plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.Massless = false, false, false, true
	local fs = math.min(head.Size.X, head.Size.Y)
	plate.Size = Vector3.new(fs * 0.95, fs * 0.95, 0.05)
	plate.CFrame = head.CFrame * CFrame.new(0, -head.Size.Y * 0.04, -head.Size.Z / 2 - 0.02)
	plate.Parent = model
	weld(head, plate)
	plate:SetAttribute("Expression", "neutral")
	plate:SetAttribute("Talking", false)
	plate:SetAttribute("Mole", spec.mole or "")
	plate:SetAttribute("Skin", spec.skin)
	plate:SetAttribute("BrowColor", spec.hairColor)
	plate:SetAttribute("Female", spec.female == true)
	plate:SetAttribute("Gaze", Vector2.zero)

	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.NameDisplayDistance = 0
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	model.Parent = ACTORS

	local tracks = {}
	for k, id in pairs(ANIM) do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, tr = pcall(function()
			return animator:LoadAnimation(a)
		end)
		if ok then
			tr.Looped = true
			tracks[k] = tr
		end
	end
	if tracks.idle then
		tracks.idle:Play()
	end

	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	local joints = {}
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") then
			joints[m.Name] = { motor = m, c0 = m.C0 }
		end
	end
	return {
		name = name,
		model = model,
		hum = hum,
		root = root,
		head = head,
		face = plate,
		tracks = tracks,
		joints = joints,
		standY = hum.HipHeight + root.Size.Y / 2,
	}
end

local A = {}
for name, spec in pairs(CAST) do
	A[name] = makeActor(name, spec)
end

------------------------------------------------------------------------ ĐIỀU KHIỂN DIỄN XUẤT
local function tw(obj, t, props, style)
	local tween = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props)
	tween:Play()
	return tween
end

local function playAnim(a, name, fade)
	for k, tr in pairs(a.tracks) do
		if k ~= name and tr.IsPlaying then
			tr:Stop(fade or 0.25)
		end
	end
	local tr = a.tracks[name]
	if tr and not tr.IsPlaying then
		tr:Play(fade or 0.25)
	end
end

local function stopAnims(a)
	for _, tr in pairs(a.tracks) do
		tr:Stop(0.2)
	end
end

-- di chuyển mượt (gốc anchored, nội suy trên server) – dùng cho tư thế nằm/ngồi/xoay người
local function glide(a, cf, t)
	a.root.Anchored = true
	if not t or t <= 0 then
		a.model:PivotTo(cf)
		return
	end
	local v = Instance.new("CFrameValue")
	v.Value = a.model:GetPivot()
	local conn = v.Changed:Connect(function(c)
		a.model:PivotTo(c)
	end)
	tw(v, t, { Value = cf }).Completed:Wait()
	conn:Disconnect()
	v:Destroy()
end

local function standCF(a, x, z, lookAt)
	local pos = P(x, a.standY, z)
	local target = lookAt and Vector3.new(lookAt.X, pos.Y, lookAt.Z) or pos + Vector3.new(0, 0, -1)
	if (target - pos).Magnitude < 0.01 then
		target = pos + Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(pos, target)
end

local function place(a, x, z, lookAt)
	a.model.Parent = ACTORS
	stopAnims(a)
	playAnim(a, "idle")
	glide(a, standCF(a, x, z, lookAt), 0)
end

local function hide(a)
	a.model.Parent = nil
end

local function turnTo(a, target, t)
	local pos = a.root.Position
	glide(a, CFrame.lookAt(pos, Vector3.new(target.X, pos.Y, target.Z)), t or 0.6)
end

-- đi bộ thật bằng Humanoid (vật lý server-owned → client nội suy mượt)
local function walkTo(a, x, z, speed)
	local goal = P(x, a.standY, z)
	a.root.Anchored = false
	pcall(function()
		a.root:SetNetworkOwner(nil)
	end)
	a.hum.WalkSpeed = speed or 7
	playAnim(a, "walk", 0.2)
	a.hum:MoveTo(goal)
	local done = false
	local conn = a.hum.MoveToFinished:Connect(function()
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < 12 do
		task.wait()
	end
	conn:Disconnect()
	playAnim(a, "idle", 0.3)
	a.root.Anchored = true
end

-- tư thế tay bằng cách xoay khớp Motor6D (cộng thêm lên animation đang chạy)
local POSES = {
	rest = {},
	wash = { RightShoulder = { 55, 0, 0 }, LeftShoulder = { 55, 0, 0 }, RightElbow = { 45, 0, 0 }, LeftElbow = { 45, 0, 0 } },
	holdBowl = { RightShoulder = { 45, 0, -10 }, RightElbow = { 55, 0, 0 } },
	handsOpen = { RightShoulder = { 70, 0, -15 }, LeftShoulder = { 70, 0, 15 }, RightElbow = { 20, 0, 0 }, LeftElbow = { 20, 0, 0 } },
	phoneLook = { RightShoulder = { 40, 0, 10 }, RightElbow = { 75, 0, 0 } },
	phoneEar = { RightShoulder = { 25, 0, -35 }, RightElbow = { 140, 0, 0 } },
	reach = { RightShoulder = { 80, 0, 0 } },
	rubEyes = { RightShoulder = { 115, 0, 15 }, RightElbow = { 120, 0, 0 } },
	touchFace = { RightShoulder = { 95, 0, 20 }, RightElbow = { 115, 0, 0 } },
	point = { RightShoulder = { 88, 0, 0 } },
	crossArms = { RightShoulder = { 45, 0, 30 }, LeftShoulder = { 45, 0, -30 }, RightElbow = { 95, 0, 0 }, LeftElbow = { 95, 0, 0 } },
}
local function pose(a, name, t)
	local p = POSES[name] or {}
	for jointName, j in pairs(a.joints) do
		if jointName:find("Shoulder") or jointName:find("Elbow") then
			local r = p[jointName]
			local goal = r and (j.c0 * CFrame.Angles(rad(r[1]), rad(r[2]), rad(r[3]))) or j.c0
			tw(j.motor, t or 0.4, { C0 = goal })
		end
	end
	task.wait(t or 0.4)
end

-- nằm ngửa trên nệm, đầu về phía gối (+Z)
local function lieDown(a, x, z)
	stopAnims(a)
	glide(a, CFrame.new(P(x, 1.55, z)) * CFrame.Angles(rad(90), 0, 0), 0)
end

local function sitAt(a, x, z, lookAt, t)
	playAnim(a, "sit", 0.3)
	local pos = P(x, 2.25, z)
	glide(a, CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z)), t or 0)
end

local function expr(a, name)
	a.face:SetAttribute("Expression", name)
end
local function gaze(a, x, y)
	a.face:SetAttribute("Gaze", Vector2.new(x or 0, y or 0))
end

local function grab(a, item, handName, offset)
	item.Anchored = false
	item.Massless = true
	item.CanCollide = false
	local hand = a.model:FindFirstChild(handName or "RightHand")
	item.CFrame = hand.CFrame * (offset or CFrame.new(0, -0.3, -0.1))
	local w = weld(hand, item)
	w.Name = "HeldWeld"
	return w
end
local function release(item, cf)
	for _, w in ipairs(item:GetChildren()) do
		if w.Name == "HeldWeld" then
			w:Destroy()
		end
	end
	item.Anchored = true
	if cf then
		item.CFrame = cf
	end
end

------------------------------------------------------------------------ CAMERA / THOẠI / ÂM (gửi xuống client)
local function fovMM(mm) -- tiêu cự (mm, full-frame) → FOV dọc của Roblox
	return math.deg(2 * math.atan(12 / mm))
end
local function at(a, partName, offset, localSpace)
	return { actor = a.name, part = partName or "Head", offset = offset, localSpace = localSpace }
end
local function cam(spec)
	if spec.mm then
		spec.fov = fovMM(spec.mm)
		spec.mm = nil
	end
	cue:FireAllClients("cam", spec)
end
local function fx(kind, ...)
	cue:FireAllClients(kind, ...)
end

local function say(a, text, dur, expression)
	if expression then
		expr(a, expression)
	end
	a.face:SetAttribute("Talking", true)
	fx("line", a.name, text)
	task.delay(math.max(0.6, dur - 0.5), function()
		a.face:SetAttribute("Talking", false)
	end)
	task.wait(dur)
end
local function voice(speaker, text, dur, style)
	fx("line", speaker, text, style)
	task.wait(dur)
end
local function clearLine()
	fx("line", "", "")
end

------------------------------------------------------------------------ ĐẠO CỤ CẦM TAY
local heldBowl = bowl("HeldBowl", P(-5.5, 3.6, 7.4), "#f2efe6")
local drip = Instance.new("ParticleEmitter")
drip.Texture = "rbxasset://textures/particles/sparkles_main.dds"
drip.Color = ColorSequence.new(Color3.fromRGB(200, 225, 255))
drip.Size = NumberSequence.new(0.05)
drip.Transparency = NumberSequence.new(0.3)
drip.Speed = NumberRange.new(0)
drip.Acceleration = Vector3.new(0, -30, 0)
drip.Lifetime = NumberRange.new(0.5)
drip.Rate = 6
drip.Enabled = false
drip.Parent = A.NguoiKia.model.RightHand
local drip2 = drip:Clone()
drip2.Parent = A.NguoiKia.model.LeftHand

------------------------------------------------------------------------ KỊCH BẢN
local KITCHEN = P(-5.6, 0, 6.2)
local DOOR = P(-7.4, 0, -4)

local function resetStage()
	for _, a in pairs(A) do
		hide(a)
		for _, j in pairs(a.joints) do
			j.motor.C0 = j.c0
		end
		a.face:SetAttribute("Talking", false)
		expr(a, "neutral")
		gaze(a, 0, 0)
	end
	chairRoot.CFrame = CFrame.new(P(0.6, 1.9, -2.3))
	release(phone, CFrame.new(P(2.0, 1.06, -2.0)))
	release(heldBowl, CFrame.new(P(-6.0, 3.55, 7.6)) * CFrame.Angles(0, 0, rad(90)))
	drip.Enabled, drip2.Enabled = false, false
	blanket.CFrame = CFrame.new(P(3.2, 1.75, -4.8))
end

local function flashback()
	-- O04 — Tối hôm trước
	resetStage()
	setTime("night")
	greenShirt.Transparency = 0
	A.Nam.model.Parent = ACTORS
	sitAt(A.Nam, 3.0, -4.2, P(-2, 0, -4.2))
	grab(A.Nam, phone, "RightHand", CFrame.new(0, -0.25, -0.2) * CFrame.Angles(rad(-60), 0, 0))
	task.spawn(pose, A.Nam, "phoneLook", 0.1)
	expr(A.Nam, "neutral")
	gaze(A.Nam, 0, 0.8)
	place(A.Tung, -1.5, -0.5, P(3, 0, -4))

	cam({ pos = P(-6.8, 7, -8.6), look = P(0.5, 2.5, 1), mm = 30, time = 0, handheld = 0.15 })
	fx("caption", "Tối hôm trước")
	fx("fade", 0, 2)
	fx("sfx", "game", true)
	task.wait(2.5)

	-- Tùng chỉ đống chén ở bồn, Nam vẫn nhìn điện thoại
	cam({ pos = at(A.Tung, "Head", Vector3.new(2.5, 0.2, -5.5), true), look = at(A.Tung, "Head"), mm = 45, time = 0, handheld = 0.2 })
	turnTo(A.Tung, KITCHEN, 0.5)
	expr(A.Tung, "annoyed")
	pose(A.Tung, "point", 0.4)
	task.wait(1)
	turnTo(A.Tung, A.Nam.root.Position, 0.5)

	cam({ pos = at(A.Nam, "Head", Vector3.new(-0.6, 0.3, -3.5), true), look = at(A.Nam, "Head"), mm = 55, time = 0, handheld = 0.15 })
	say(A.Nam, "Tí tao rửa. Mày ngủ đi.", 2.6, "neutral")
	clearLine()

	pose(A.Tung, "rest", 0.3)
	expr(A.Tung, "tired")
	cam({ pos = P(-6.8, 7, -8.6), look = P(2.5, 2, -3), mm = 32, time = 0, handheld = 0.1 })
	task.wait(0.6)
	walkTo(A.Tung, -1.2, -5.5, 6)
	walkTo(A.Tung, 1.0, -6.6, 6)
	lieDown(A.Tung, 6.1, -3.4)
	blanketTung.CFrame = CFrame.new(P(6.1, 1.85, -4.6))
	expr(A.Tung, "sleepy")
	task.wait(0.5)

	voice("Lời dẫn", "Còn đống chén tối đó, cậu vẫn để lại cho sáng mai.", 3.8, "narration")
	clearLine()
	-- O05 — báo thức nối vào hiện tại
	fx("sfx", "game", false)
	fx("fade", 1, 1.2)
	task.wait(1.6)
end

local function scene1()
	-- ======================= SÁNG HIỆN TẠI =======================
	resetStage()
	setTime("morning")
	greenShirt.Transparency = 1 -- áo xanh đã không còn trên ghế
	blanketTung.CFrame = CFrame.new(P(6.1, 1.15, -6.2))
	A.Nam.model.Parent = ACTORS
	lieDown(A.Nam, 3.2, -3.5)
	expr(A.Nam, "asleep")
	A.NguoiKia.model.Parent = ACTORS
	place(A.NguoiKia, -5.6, 6.3, P(-5.6, 0, 10)) -- quay lưng lại phòng, mặt vào bồn
	pose(A.NguoiKia, "wash", 0.1)
	grab(A.NguoiKia, heldBowl, "RightHand", CFrame.new(0, -0.35, -0.1) * CFrame.Angles(0, 0, rad(90)))

	-- A01 — qua vai từ bồn rửa: lưng Người Kia mờ tiền cảnh, Nam ngủ nét hậu cảnh
	cam({ pos = P(-6.6, 5.0, 8.4), look = at(A.Nam, "Head"), mm = 35, time = 0, handheld = 0.25, dof = 0.5, near = 0.7 })
	fx("caption", "Sáng hôm sau")
	fx("fade", 0, 1.5)
	fx("sfx", "alarm", true)
	fx("sfx", "fan", true)
	task.wait(3.5)

	-- A02 — sát mặt gối: thò tay tắt báo thức, kéo chăn
	cam({ pos = P(1.5, 1.9, -1.0), look = at(A.Nam, "Head"), mm = 65, time = 0, handheld = 0.1, dof = 0.6, focusRadius = 1.5 })
	expr(A.Nam, "sleepy")
	task.wait(0.8)
	pose(A.Nam, "reach", 0.5)
	fx("sfx", "alarm", false)
	pose(A.Nam, "rest", 0.4)
	expr(A.Nam, "asleep")
	tw(blanket, 0.6, { CFrame = CFrame.new(P(3.2, 1.9, -4.2)) })
	task.wait(1)

	-- tiếng nước, tiếng chén va nhau
	fx("sfx", "water", true)
	fx("sfx", "dishes", true)
	task.wait(1.6)
	say(A.Nam, "Tùng, nhẹ tay chút coi. Tao đang ngủ.", 3, "sleepy")
	clearLine()
	-- tiếng nước ngừng. Không ai đáp.
	fx("sfx", "water", false)
	fx("sfx", "dishes", false)
	pose(A.NguoiKia, "holdBowl", 0.3)
	task.wait(1.6)
	expr(A.Nam, "groggy")
	gaze(A.Nam, -0.6, 0)
	task.wait(1)

	-- A02B — trung rộng chéo 45° từ chân giường: lật chăn, ngồi dậy, xỏ dép
	cam({ pos = P(-1.2, 4.6, -8.4), look = at(A.Nam, "HumanoidRootPart"), mm = 40, time = 0, handheld = 0.2, smooth = 4 })
	tw(blanket, 0.7, { CFrame = CFrame.new(P(5.0, 1.3, -4.8)) })
	task.wait(0.4)
	playAnim(A.Nam, "sit", 0.4)
	glide(A.Nam, CFrame.new(P(3.2, 2.25, -3.9)), 1.4) -- chống tay ngồi dậy
	task.wait(0.4)
	sitAt(A.Nam, 1.9, -4.4, P(-3, 0, -4.4), 1.0) -- dịch ra mép nệm, buông chân xuống
	task.wait(0.5)
	turnTo(A.Nam, KITCHEN, 0.5)
	A.Nam.root.Anchored = true
	gaze(A.Nam, 0, 0)

	-- A03 — dolly arc sau vai Nam (Nam tưởng là Tùng)
	local namHead = A.Nam.head.Position
	local dir = (A.NguoiKia.head.Position - namHead) * Vector3.new(1, 0, 1)
	dir = dir.Unit
	local behind = math.deg(math.atan2(-dir.Z, -dir.X))
	cam({
		arc = { center = at(A.Nam, "Head"), radius = 3.2, height = 0.6, a0 = behind + 28, a1 = behind - 4 },
		look = at(A.NguoiKia, "Head"),
		mm = 50,
		time = 4,
		handheld = 0.1,
		dof = 0.35,
	})
	say(A.Nam, "Ê, áo đó của tao…", 1.6, "annoyed")
	-- người ấy quay lại
	task.spawn(turnTo, A.NguoiKia, A.Nam.root.Position, 1.3)
	expr(A.NguoiKia, "calm")
	task.wait(1.3)
	clearLine()

	-- A04B — cận phản ứng Nam TRƯỚC khi xác nhận mặt người kia
	cam({ pos = at(A.Nam, "Head", Vector3.new(0.4, 0.15, -2.6), true), look = at(A.Nam, "Head"), mm = 65, time = 0, handheld = 0.18, dof = 0.6, focusRadius = 1.2 })
	expr(A.Nam, "shocked")
	task.wait(1.4)
	-- A04 — cú cắt ngược trục: Người Kia quay hẳn mặt, nốt ruồi bên phải, cười nhẹ (Dutch 5°)
	cam({ pos = at(A.NguoiKia, "Head", Vector3.new(-0.3, 0.1, -2.8), true), look = at(A.NguoiKia, "Head"), mm = 65, time = 0, handheld = 0.12, dutch = 5, dof = 0.6, focusRadius = 1.2 })
	task.wait(2)
	-- Nam nhìn ra cửa như chờ Tùng bước vào cười — giữ 2 giây, chỉ còn tiếng quạt
	cam({ pos = at(A.Nam, "Head", Vector3.new(0.4, 0.15, -2.6), true), look = at(A.Nam, "Head"), mm = 65, time = 0, handheld = 0.15, dof = 0.6, focusRadius = 1.2 })
	gaze(A.Nam, -1, 0)
	expr(A.Nam, "confused")
	task.wait(2)
	gaze(A.Nam, 0, 0)
	-- dụi mắt. Nhìn lại. Sờ lên mặt mình.
	pose(A.Nam, "rubEyes", 0.4)
	expr(A.Nam, "squint")
	task.wait(0.6)
	pose(A.Nam, "rest", 0.3)
	expr(A.Nam, "shocked")
	task.wait(0.6)
	pose(A.Nam, "touchFace", 0.5)
	task.wait(0.8)
	pose(A.Nam, "rest", 0.4)

	-- hai người trong khung (trung cảnh qua vai Nam)
	cam({ pos = at(A.Nam, "Head", Vector3.new(1.6, 0.6, 3.4), true), look = at(A.NguoiKia, "Head"), mm = 45, time = 0, handheld = 0.15, dof = 0.3 })
	say(A.Nam, "Tùng thuê mày hù tao hả?", 2.4, "confused")
	clearLine()
	task.wait(0.3)
	say(A.NguoiKia, "Không. Tao thấy chén chưa rửa nên làm luôn.", 3.4, "calm")
	clearLine()

	-- đúng giọng Nam — cận Nam hụt hơi
	cam({ pos = at(A.Nam, "Head", Vector3.new(0.3, 0.1, -2.2), true), look = at(A.Nam, "Head"), mm = 75, time = 0, handheld = 0.2, dof = 0.7, focusRadius = 1 })
	expr(A.Nam, "scared")
	fx("sfx", "heartbeat", true)
	task.wait(1)

	-- A05 — góc sàn 15 cm cạnh chân ghế: chụp máy, bật dậy, va ghế "CỘP"
	cam({ pos = P(-1.4, 0.45, -5.6), look = P(1.0, 1.2, -2.8), mm = 30, time = 0, handheld = 0.3 })
	pose(A.Nam, "reach", 0.25)
	grab(A.Nam, phone, "RightHand", CFrame.new(0, -0.25, -0.2) * CFrame.Angles(rad(-60), 0, 0))
	pose(A.Nam, "rest", 0.15)
	playAnim(A.Nam, "idle", 0.15)
	glide(A.Nam, standCF(A.Nam, 1.4, -3.6, A.NguoiKia.root.Position), 0.35)
	task.wait(0.1)
	fx("sfx", "thud")
	fx("shake", 0.35, 1.2)
	tw(chairRoot, 0.15, { CFrame = CFrame.new(P(0.0, 1.9, -2.0)) * CFrame.Angles(0, rad(-14), 0) }, Enum.EasingStyle.Quad)
	expr(A.Nam, "pain")
	task.wait(0.4)
	expr(A.Nam, "scared")
	-- người ấy nhích ra khỏi bồn rửa
	task.spawn(walkTo, A.NguoiKia, -4.6, 4.8, 4)
	task.wait(0.5)

	cam({ pos = at(A.Nam, "Head", Vector3.new(-0.8, 0.2, -3.6), true), look = at(A.Nam, "Head"), mm = 45, time = 0, handheld = 0.5, smooth = 8 })
	say(A.Nam, "Đứng đó! Đừng tới gần tao!", 2.2, "scared")
	clearLine()

	-- người kia dừng, hạ chén xuống mặt đỡ, đưa hai bàn tay trống ra trước người
	cam({ pos = at(A.NguoiKia, "Head", Vector3.new(0.5, 0.4, -5), true), look = at(A.NguoiKia, "UpperTorso"), mm = 45, time = 0, handheld = 0.15 })
	turnTo(A.NguoiKia, KITCHEN + Vector3.new(0, 0, 4), 0.4)
	pose(A.NguoiKia, "holdBowl", 0.3)
	release(heldBowl, CFrame.new(P(-4.4, 3.55, 7.6)) * CFrame.Angles(0, 0, rad(90)))
	task.wait(0.6)
	turnTo(A.NguoiKia, A.Nam.root.Position, 0.4)
	pose(A.NguoiKia, "handsOpen", 0.5)
	drip.Enabled, drip2.Enabled = true, true
	task.wait(1)
	fx("sfx", "heartbeat", false)

	-- ======================= B01 — CỐ THỦ NGƯỠNG CỬA =======================
	-- Nam men theo lối cạnh giường ra cửa; máy đi theo mượt (camera bám nhân vật)
	cam({ pos = P(-12.8, 5.2, -8.6), look = at(A.Nam, "Head"), mm = 32, time = 0, smooth = 3.5, handheld = 0.15, dof = 0.2 })
	pose(A.Nam, "phoneLook", 0.3)
	walkTo(A.Nam, -0.8, -4.6, 5)
	walkTo(A.Nam, DOOR.X, DOOR.Z, 5)
	turnTo(A.Nam, A.NguoiKia.root.Position, 0.4)

	-- hàng xóm đi ngang hành lang phía sau, cô chủ trọ đứng đầu cầu thang
	place(A.ChuTro, -12.6, -13.2, P(-12, 0, 0))
	pose(A.ChuTro, "crossArms", 0.1)
	place(A.HangXom, -12.2, 12, P(-12, 0, -20))

	-- shot/ngược shot ở ngưỡng cửa
	local function onNam(mm)
		cam({ pos = at(A.Nam, "Head", Vector3.new(0.9, 0.2, -3.2), true), look = at(A.Nam, "Head"), mm = mm or 55, time = 0, handheld = 0.18, dof = 0.5, focusRadius = 1.5 })
	end
	local function onKia(mm)
		cam({ pos = at(A.Nam, "Head", Vector3.new(-1.1, 0.4, 2.4), true), look = at(A.NguoiKia, "Head"), mm = mm or 50, time = 0, handheld = 0.12, dof = 0.45, focusRadius = 2 })
	end
	onNam()
	say(A.Nam, "Mày là ai?", 1.8, "scared")
	onKia()
	say(A.NguoiKia, "Tao tên Nam.", 1.8, "calm")
	onNam(65)
	say(A.Nam, "Đừng có giỡn. Sao mày vào đây?", 2.6, "angryScared")
	onKia(60)
	say(A.NguoiKia, "Cửa mở.", 1.6, "calm")
	clearLine()
	-- liếc chốt cửa (insert), rồi lập tức nhìn lại
	gaze(A.Nam, 1, 0)
	cam({ pos = P(-6.6, 4.6, -3.6), look = P(-8, 4.2, -2.5), mm = 75, time = 0, dof = 0.6, focusRadius = 0.8 })
	task.wait(1.1)
	gaze(A.Nam, 0, 0)

	-- gọi Tùng: ngón cái trượt hai lần trên màn hình
	cam({ pos = P(-3.2, 5.0, -7.8), look = at(A.Nam, "Head"), mm = 40, time = 0, handheld = 0.15, smooth = 5, dof = 0.25 })
	task.spawn(walkTo, A.HangXom, -12.2, -9, 4)
	pose(A.Nam, "phoneLook", 0.3)
	fx("sfx", "tap")
	task.wait(0.4)
	fx("sfx", "tap")
	task.wait(0.4)
	pose(A.Nam, "phoneEar", 0.4)
	fx("sfx", "ring", true)
	task.wait(2.2)
	fx("sfx", "ring", false)
	voice("Tùng (điện thoại)", "Gì vậy? Tao đang học.", 2.2, "phone")
	onNam(70)
	say(A.Nam, "Mày… mày đang trên trường thật hả?", 3, "scared")
	clearLine()

	-- người trong phòng vẫn đứng chờ. Nước từ bàn tay nhỏ xuống nền.
	cam({ pos = at(A.NguoiKia, "HumanoidRootPart", Vector3.new(0.9, 0.3, -2.6), true), look = at(A.NguoiKia, "RightHand"), mm = 85, time = 0, dof = 0.7, focusRadius = 0.6 })
	fx("sfx", "drip", true)
	task.wait(2.4)
	-- Nam siết điện thoại — đẩy máy chậm vào mặt
	cam({ pos = at(A.Nam, "Head", Vector3.new(0.5, 0.15, -4.2), true), look = at(A.Nam, "Head"), mm = 50, time = 0, handheld = 0.1, dof = 0.6, focusRadius = 1.2 })
	task.wait(0.05)
	cam({ pos = at(A.Nam, "Head", Vector3.new(0.3, 0.1, -2.0), true), look = at(A.Nam, "Head"), mm = 75, time = 4.5, handheld = 0.1, dof = 0.7, focusRadius = 1 })
	expr(A.Nam, "dread")
	task.wait(4.5)
	fx("sfx", "drip", false)
	fx("fade", 1, 2)
	task.wait(2.2)
	fx("title", "Còn tiếp…", "")
	task.wait(3)
	fx("end")
end

local function runAll()
	fx("start")
	fx("fade", 1, 0)
	fx("title", "HỒ SƠ 02 — NGƯỜI TRONG GƯƠNG", "The Crack in Reality")
	task.wait(4.5)
	if CONFIG.PlayFlashback then
		flashback()
	end
	scene1()
end

-- ẩn diễn viên đến khi diễn
for _, a in pairs(A) do
	hide(a)
end

local running = false
local function onPlayer(player)
	if running or not CONFIG.AutoStart then
		return
	end
	running = true
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(CONFIG.StartDelay)
	local ok, err = pcall(runAll)
	if not ok then
		warn("[HoSo02] Lỗi khi diễn: ", err)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
print("[HoSo02] Đã dựng phòng trọ + hành lang. Cảnh sẽ tự diễn khi bấm Play.")
