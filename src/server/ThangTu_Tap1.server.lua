--[[
	THÁNG TƯ NÓI DỐI — Tập 1: Cá tháng Tư
	Script đặt trong ServerScriptService. Cần ModuleScript "PhimKit" trong ReplicatedStorage
	và LocalScript "Phim_Client" trong StarterPlayer > StarterPlayerScripts.
	Kịch bản: docs/THANG-TU-NOI-DOI.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Kit = require(ReplicatedStorage:WaitForChild("PhimKit"))
Kit.init()

local box, ball, cyl, weld, sign, light = Kit.box, Kit.ball, Kit.cyl, Kit.weld, Kit.sign, Kit.light
local rad = math.rad
local fx, say, voice, clear = Kit.fx, Kit.say, Kit.voice, Kit.clear

local CONFIG = {
	AutoStart = true,
	StartDelay = 3,
}

------------------------------------------------------------------------ ĐẠO CỤ
local function modelOf(name, parts, primary)
	local m = Instance.new("Model")
	m.Name = name
	for _, p in ipairs(parts) do
		p.Parent = m
		if p ~= primary then
			p.Anchored = false
			p.CanCollide = false
			weld(primary, p)
		end
	end
	m.PrimaryPart = primary
	m.Parent = Kit.SET
	return m
end

-- bó hoa loa kèn trắng gói giấy kraft
local function makeBouquet(cf)
	local wrap = box("Wrap", Vector3.new(0.75, 1.5, 0.75), cf, "#c8a77a", Enum.Material.Fabric, { CanCollide = false })
	local parts = { wrap }
	for i = 0, 5 do
		local ang = rad(i * 60)
		local r = i == 0 and 0 or 0.3
		local off = Vector3.new(math.cos(ang) * r, 1.05 + (i % 2) * 0.18, math.sin(ang) * r)
		table.insert(parts, box("Stem", Vector3.new(0.07, 0.7, 0.07), cf * CFrame.new(off - Vector3.new(0, 0.35, 0)), "#5f8a4a", nil, { CanCollide = false }))
		local bloom = box("Lily", Vector3.new(0.34, 0.5, 0.34), cf * CFrame.new(off + Vector3.new(0, 0.15, 0)) * CFrame.Angles(rad(15), ang, 0), "#fbfaf2", nil, { CanCollide = false })
		table.insert(parts, bloom)
		table.insert(parts, box("Petal", Vector3.new(0.5, 0.06, 0.5), bloom.CFrame * CFrame.new(0, 0.25, 0), "#ffffff", nil, { CanCollide = false }))
		table.insert(parts, box("Stamen", Vector3.new(0.06, 0.12, 0.06), bloom.CFrame * CFrame.new(0, 0.3, 0), "#e8c547", Enum.Material.Neon, { CanCollide = false }))
	end
	table.insert(parts, box("Ribbon", Vector3.new(0.8, 0.12, 0.8), cf * CFrame.new(0, 0.2, 0), "#c94a5a", nil, { CanCollide = false }))
	return modelOf("Bouquet", parts, wrap)
end

local function makeGift(cf)
	local b = box("Gift", Vector3.new(0.6, 0.45, 0.6), cf, "#b8323f", nil, { CanCollide = false })
	return modelOf("GiftBox", {
		b,
		box("RibbonA", Vector3.new(0.62, 0.47, 0.1), cf, "#f2d27a", nil, { CanCollide = false }),
		box("RibbonB", Vector3.new(0.1, 0.47, 0.62), cf, "#f2d27a", nil, { CanCollide = false }),
	}, b)
end

local function makePhone(cf, color)
	return box("Phone", Vector3.new(0.32, 0.6, 0.05), cf, color or "#1d1f22", Enum.Material.Metal, { CanCollide = false })
end

------------------------------------------------------------------------ BỐI CẢNH 1: PHỐ HOA (sáng)
local S = Kit.origin(Vector3.new(0, 0, -600))

box("Road", Vector3.new(90, 1, 14), S(0, -0.5, 0), "#3e3f44", Enum.Material.Asphalt)
for x = -42, 42, 6 do
	box("Lane", Vector3.new(3, 0.02, 0.25), S(x, 0.01, 0), "#e8e4d6", nil, { CanCollide = false })
end
box("SidewalkN", Vector3.new(90, 0.4, 7), S(0, 0.2, 10.5), "#b9a98f", Enum.Material.Brick)
box("SidewalkS", Vector3.new(90, 0.4, 7), S(0, 0.2, -10.5), "#b9a98f", Enum.Material.Brick)
box("CurbN", Vector3.new(90, 0.45, 0.3), S(0, 0.22, 7.1), "#8e8a82", Enum.Material.Concrete)
box("CurbS", Vector3.new(90, 0.45, 0.3), S(0, 0.22, -7.1), "#8e8a82", Enum.Material.Concrete)

-- dãy nhà ống phố cổ hai bên
local FACADE = { "#e3c06a", "#d98f6a", "#cfd6b0", "#e6d7b8", "#b9cdd6", "#e0a8a0", "#d8c27a", "#c9b8d9", "#e8e0cc", "#a8c4a0" }
local SHOPS = { "TẠP HOÁ", "PHỞ GIA TRUYỀN", "HIỆU SÁCH", "ĐỒNG HỒ", "TIỆM MAY", "BÁNH MÌ", "VÀNG BẠC", "THUỐC BẮC", "KÍNH MẮT", "CƠM BÌNH DÂN" }
local function shophouse(i, x, side)
	local h = 18 + ((i * 7) % 9)
	local z = side * 17.5
	local face = -side -- hướng mặt tiền
	local c = FACADE[(i % #FACADE) + 1]
	box("House", Vector3.new(8.6, h, 8), S(x, h / 2, z), c, Enum.Material.Plaster)
	-- tầng trệt: cửa cuốn / cửa hàng
	box("ShopOpening", Vector3.new(6.4, 6, 0.2), S(x, 3.4, z + face * 4.05), "#2e2a26", Enum.Material.SmoothPlastic)
	local board = box("ShopSign", Vector3.new(7.2, 1.4, 0.3), S(x, 7.4, z + face * 4.2), i % 2 == 0 and "#b3262e" or "#1f4e79")
	sign(board, SHOPS[(i % #SHOPS) + 1], side < 0 and Enum.NormalId.Back or Enum.NormalId.Front, { color = Color3.fromRGB(255, 236, 170), font = Enum.Font.GothamBold })
	-- các tầng trên: cửa sổ chớp + ban công
	for floor = 1, math.floor((h - 9) / 5) do
		local y = 8.5 + floor * 4.8
		box("Window", Vector3.new(3, 3, 0.2), S(x, y, z + face * 4.05), "#4d6b5a", Enum.Material.Wood)
		box("Balcony", Vector3.new(7, 0.3, 1.6), S(x, y - 1.7, z + face * 4.8), "#d8d2c4", Enum.Material.Concrete)
		box("Rail", Vector3.new(7, 1.2, 0.1), S(x, y - 1.0, z + face * 5.55), "#2b2b2b", Enum.Material.Metal, { Transparency = 0.2 })
		if (i + floor) % 2 == 0 then
			ball("Plant", 1.1, S(x + 2.6, y - 1.0, z + face * 5.0), "#4f7d3d", Enum.Material.Grass)
		end
	end
	box("Roof", Vector3.new(9, 0.6, 8.5), S(x, h + 0.3, z), "#8a5a44", Enum.Material.Slate)
end
for i = 0, 9 do
	shophouse(i, -40 + i * 9, 1)
	shophouse(i + 3, -40 + i * 9, -1)
end

-- cây hoa sưa trắng trên vỉa hè
local function sua(x, z)
	cyl("Trunk", 9, 0.9, S(x, 4.5, z), "#5b4636", Enum.Material.Wood)
	cyl("Branch", 4, 0.4, CFrame.new(S(x + 1, 8.5, z)) * CFrame.Angles(0, 0, rad(-35)), "#5b4636", Enum.Material.Wood)
	for k = 0, 9 do
		local a = rad(k * 37)
		ball("Blossom", 3.2 - (k % 3) * 0.5, S(x + math.cos(a) * 2.4, 10 + (k % 4) * 0.8, z + math.sin(a) * 2.4), k % 3 == 0 and "#e9efe4" or "#fbfbf6", Enum.Material.Grass)
	end
end
for _, x in ipairs({ -30, -12, 9, 27 }) do
	sua(x, 12.2)
end

-- cột điện + dây điện chằng chịt
for _, x in ipairs({ -36, -6, 24 }) do
	box("Pole", Vector3.new(0.6, 16, 0.6), S(x, 8, 13.4), "#8d8d88", Enum.Material.Concrete)
	for k = 0, 4 do
		local wire = box("Wire", Vector3.new(30, 0.06, 0.06), S(x + 15, 14.5 - k * 0.5, 13.4 - k * 0.3), "#111111", nil, { CanCollide = false })
		wire.CFrame = wire.CFrame * CFrame.Angles(0, 0, rad((k % 2 == 0) and 1 or -1))
	end
end

-- xe máy đỗ vỉa hè
local function moto(x, z, col)
	box("MotoBody", Vector3.new(3.2, 1.2, 0.8), S(x, 1.6, z), col, Enum.Material.Metal)
	box("MotoSeat", Vector3.new(1.6, 0.3, 0.8), S(x - 0.3, 2.35, z), "#1d1d1d")
	cyl("WheelF", 0.4, 1.4, CFrame.new(S(x + 1.4, 1.1, z)) * CFrame.Angles(rad(90), 0, 0), "#1a1a1a")
	cyl("WheelB", 0.4, 1.4, CFrame.new(S(x - 1.4, 1.1, z)) * CFrame.Angles(rad(90), 0, 0), "#1a1a1a")
	box("Handle", Vector3.new(0.2, 1.2, 1.4), S(x + 1.4, 2.8, z), "#2b2b2b", Enum.Material.Metal)
end
moto(-20, -9.5, "#b3262e")
moto(-16, -9.6, "#2a4d8f")
moto(15, 9.2, "#e6e6e6")
moto(19, 9.3, "#2f2f2f")

-- xe đạp chở hoa loa kèn của cô Hoa
local BIKE = S(0, 0.4, 8.6)
local function bike(base)
	local cf = CFrame.new(base)
	cyl("BikeWheelF", 0.15, 2.2, cf * CFrame.new(1.7, 1.1, 0) * CFrame.Angles(rad(90), 0, 0), "#202020")
	cyl("BikeWheelB", 0.15, 2.2, cf * CFrame.new(-1.7, 1.1, 0) * CFrame.Angles(rad(90), 0, 0), "#202020")
	box("BikeFrame", Vector3.new(3.4, 0.15, 0.15), cf * CFrame.new(0, 1.9, 0), "#2f5d50", Enum.Material.Metal)
	box("BikeDown", Vector3.new(0.15, 1.6, 0.15), cf * CFrame.new(0.4, 1.4, 0) * CFrame.Angles(0, 0, rad(25)), "#2f5d50", Enum.Material.Metal)
	box("BikeSeat", Vector3.new(0.8, 0.2, 0.4), cf * CFrame.new(-0.6, 2.7, 0), "#3a2a20")
	box("BikeBar", Vector3.new(0.15, 0.15, 1.4), cf * CFrame.new(1.6, 2.9, 0), "#2f5d50", Enum.Material.Metal)
	box("BikeRack", Vector3.new(1.6, 0.15, 1.2), cf * CFrame.new(-1.6, 2.2, 0), "#5a4a3a", Enum.Material.Wood)
	for _, side in ipairs({ -1, 1 }) do -- hai giỏ hoa hai bên
		box("Basket", Vector3.new(1.4, 1.1, 0.8), cf * CFrame.new(-1.6, 1.8, side * 1.0), "#b08a5a", Enum.Material.Fabric)
		for k = 0, 11 do
			local bx = -2.2 + (k % 4) * 0.4
			local bz = side * (0.75 + math.floor(k / 4) * 0.25)
			box("Stem", Vector3.new(0.06, 1.4, 0.06), cf * CFrame.new(bx, 2.9, bz), "#5f8a4a")
			box("Lily", Vector3.new(0.3, 0.45, 0.3), cf * CFrame.new(bx, 3.75 + (k % 3) * 0.15, bz) * CFrame.Angles(rad(15), rad(k * 40), 0), "#fbfaf2")
		end
	end
end
bike(BIKE)
local flowerSign = box("FlowerSign", Vector3.new(1.6, 0.7, 0.05), CFrame.new(BIKE + Vector3.new(-1.6, 1.0, -1.45)), "#fff7d6")
sign(flowerSign, "Loa kèn 50k", Enum.NormalId.Front)

------------------------------------------------------------------------ BỐI CẢNH 2: QUÁN CÀ PHÊ CŨ (chiều)
local C = Kit.origin(Vector3.new(250, 0, -600))
box("CafeFloor", Vector3.new(30, 1, 24), C(0, -0.5, 0), "#8a6446", Enum.Material.WoodPlanks)
box("CafeCeiling", Vector3.new(30, 1, 24), C(0, 12.5, 0), "#3a2e26", Enum.Material.Wood)
box("CafeBack", Vector3.new(30, 13, 1), C(0, 6, 12.5), "#a5563c", Enum.Material.Brick)
box("CafeLeft", Vector3.new(1, 13, 24), C(-15.5, 6, 0), "#e8dcc4", Enum.Material.Plaster)
box("CafeRight", Vector3.new(1, 13, 24), C(15.5, 6, 0), "#e8dcc4", Enum.Material.Plaster)
-- mặt tiền kính nhìn ra phố (cửa ra vào x 10..14)
box("FrontBase", Vector3.new(24, 1.5, 0.8), C(-3, 0.75, -12), "#3a2e26", Enum.Material.Wood)
box("FrontGlass", Vector3.new(24, 8, 0.15), C(-3, 5.5, -12), "#cfe6ee", Enum.Material.Glass, { Transparency = 0.8 })
for x = -15, 9, 4 do
	box("Mullion", Vector3.new(0.3, 9.5, 0.4), C(x, 4.75, -12), "#2a221c", Enum.Material.Wood)
end
box("FrontTop", Vector3.new(30, 3, 0.8), C(0, 11, -12), "#3a2e26", Enum.Material.Wood)
box("DoorPost", Vector3.new(0.4, 9.5, 0.4), C(14.5, 4.75, -12), "#2a221c", Enum.Material.Wood)
box("CafeDoor", Vector3.new(0.2, 8.5, 3.8), CFrame.new(C(10.1, 4.25, -13.9)) * CFrame.Angles(0, rad(0), 0), "#cfe6ee", Enum.Material.Glass, { Transparency = 0.6 })
local cafeSign = box("CafeSign", Vector3.new(9, 1.6, 0.3), C(-4, 11, -12.6), "#2a221c", Enum.Material.Wood)
sign(cafeSign, "Cà Phê Cũ", Enum.NormalId.Front, { color = Color3.fromRGB(255, 214, 150), font = Enum.Font.Fondamento, glow = true })

-- vỉa hè + phố trước quán (cho cảnh mưa nhìn từ ngoài vào)
box("CafeSidewalk", Vector3.new(60, 0.4, 9), C(0, 0.2, -16.5), "#9e9484", Enum.Material.Brick)
box("CafeRoad", Vector3.new(60, 1, 14), C(0, -0.5, -28), "#3e3f44", Enum.Material.Asphalt)
box("Awning", Vector3.new(26, 0.3, 4), CFrame.new(C(-3, 9.6, -14)) * CFrame.Angles(rad(-12), 0, 0), "#2f5d50", Enum.Material.Fabric)
for i = 0, 4 do
	box("Opposite", Vector3.new(11, 20, 6), C(-24 + i * 12, 10, -40), FACADE[i + 1], Enum.Material.Plaster)
end

-- nội thất
local function cafeTable(x, z)
	cyl("TableTop", 0.15, 3.4, C(x, 3, z), "#6b4a32", Enum.Material.Wood)
	cyl("TableLeg", 3, 0.3, C(x, 1.5, z), "#2a2a2a", Enum.Material.Metal)
end
local function cafeChair(x, z, faceX)
	box("Seat", Vector3.new(1.7, 0.2, 1.7), C(x, 1.8, z), "#4e3626", Enum.Material.Wood)
	box("ChairBack", Vector3.new(0.2, 1.9, 1.7), C(x - faceX * 0.8, 2.85, z), "#4e3626", Enum.Material.Wood)
	for _, dx in ipairs({ -0.7, 0.7 }) do
		for _, dz in ipairs({ -0.7, 0.7 }) do
			box("Leg", Vector3.new(0.15, 1.7, 0.15), C(x + dx, 0.85, z + dz), "#2a2a2a", Enum.Material.Metal)
		end
	end
end
-- bàn cạnh cửa sổ của Minh & An
local T = C(-6, 0, -8.5)
cafeTable(-6, -8.5)
cafeChair(-8.8, -8.5, 1)
cafeChair(-3.2, -8.5, -1)
cafeTable(5, 1)
cafeChair(2.2, 1, 1)
cafeTable(-6, 4)
-- quầy pha chế
box("Counter", Vector3.new(12, 3.6, 2.4), C(3, 1.8, 9), "#5a3e2a", Enum.Material.Wood)
box("CounterTop", Vector3.new(12.3, 0.2, 2.7), C(3, 3.7, 9), "#d8d2c4", Enum.Material.Marble)
box("Espresso", Vector3.new(2, 1.6, 1.3), C(0, 4.6, 9.4), "#b8bec2", Enum.Material.Metal)
local menu = box("Menu", Vector3.new(6, 3, 0.1), C(3, 8, 11.9), "#1f2421", Enum.Material.Slate)
sign(menu, "Cà phê muối 35k\nBạc xỉu 30k\nTrà đào 35k", Enum.NormalId.Front, { color = Color3.fromRGB(240, 240, 230), font = Enum.Font.PatrickHand })
for i = 0, 3 do
	box("Shelf", Vector3.new(4, 0.2, 1.2), C(-11, 3 + i * 2.2, 11.6), "#6b4a32", Enum.Material.Wood)
	for k = 0, 4 do
		box("Book", Vector3.new(0.35, 1.3, 0.9), C(-12.6 + k * 0.6 + (i % 2) * 0.2, 3.75 + i * 2.2, 11.6), ({ "#8a3b3b", "#3b5a8a", "#c9b26a", "#4e7a5a", "#e8e0cc" })[k + 1])
	end
end
box("Guitar", Vector3.new(1.4, 3.6, 0.3), CFrame.new(C(-15, 6.5, -2)) * CFrame.Angles(0, rad(90), rad(8)), "#b07a45", Enum.Material.Wood)
for _, p in ipairs({ C(13.5, 0, 10), C(-14, 0, -10.5) }) do
	box("Pot", Vector3.new(1.4, 1.6, 1.4), p + Vector3.new(0, 0.8, 0), "#c46a4a", Enum.Material.Concrete)
	ball("Leaves", 2.8, p + Vector3.new(0, 3, 0), "#3f6e3a", Enum.Material.Grass)
end
-- đèn thả ấm
for _, p in ipairs({ C(-6, 9.5, -8.5), C(5, 9.5, 1), C(-6, 9.5, 4), C(3, 9.5, 8) }) do
	box("Cord", Vector3.new(0.05, 2.6, 0.05), p + Vector3.new(0, 1.7, 0), "#111111")
	local bulb = ball("Pendant", 0.7, p, "#ffd59a", Enum.Material.Neon)
	light("PointLight", bulb, { Range = 14, Brightness = 1.4, Color = Color3.fromRGB(255, 196, 130), Shadows = true })
end

------------------------------------------------------------------------ BỐI CẢNH 3: PHÒNG TRỌ MINH (đêm mưa)
local R = Kit.origin(Vector3.new(500, 0, -600))
box("RoomFloor", Vector3.new(18, 1, 18), R(0, -0.5, 0), "#cfc6b4", Enum.Material.Marble)
box("RoomCeil", Vector3.new(18, 1, 18), R(0, 10.5, 0), "#e8e4da")
box("RoomLeft", Vector3.new(1, 11, 18), R(-9, 5, 0), "#c8d3c9", Enum.Material.Plaster)
box("RoomRight", Vector3.new(1, 11, 18), R(9, 5, 0), "#c8d3c9", Enum.Material.Plaster)
box("RoomFront", Vector3.new(18, 11, 1), R(0, 5, -9), "#c8d3c9", Enum.Material.Plaster)
box("RoomBackL", Vector3.new(6, 11, 1), R(-6, 5, 9), "#c8d3c9", Enum.Material.Plaster)
box("RoomBackR", Vector3.new(6, 11, 1), R(6, 5, 9), "#c8d3c9", Enum.Material.Plaster)
box("RoomBackLow", Vector3.new(6, 3, 1), R(0, 1.5, 9), "#c8d3c9", Enum.Material.Plaster)
box("RoomBackTop", Vector3.new(6, 2.5, 1), R(0, 9.25, 9), "#c8d3c9", Enum.Material.Plaster)
box("RoomGlass", Vector3.new(6, 5.5, 0.1), R(0, 5.75, 9), "#5d6f8a", Enum.Material.Glass, { Transparency = 0.6 })
box("RoomBar", Vector3.new(0.15, 5.5, 0.2), R(0, 5.75, 8.9), "#3a3a3a", Enum.Material.Metal)
-- thành phố về đêm ngoài cửa sổ
box("NightCity", Vector3.new(80, 50, 1), R(0, 10, 40), "#141a2a", Enum.Material.SmoothPlastic)
for i = 0, 40 do
	local x = -30 + (i * 13) % 60
	local y = 2 + (i * 7) % 24
	box("LitWindow", Vector3.new(1.2, 1.6, 0.2), R(x, y, 39.4), i % 3 == 0 and "#ffd28a" or "#9fc4ff", Enum.Material.Neon, { Transparency = 0.2 })
end
-- giường Minh
box("BedFrame", Vector3.new(5.5, 1.2, 9), R(-6, 0.6, 3.5), "#6b4a32", Enum.Material.Wood)
box("BedMattress", Vector3.new(5.3, 0.6, 8.8), R(-6, 1.5, 3.5), "#e8e2d4", Enum.Material.Fabric)
box("BedBlanket", Vector3.new(5.4, 0.3, 4.5), R(-6, 1.9, 2), "#7d93b0", Enum.Material.Fabric)
box("BedPillow", Vector3.new(3, 0.6, 1.4), R(-6, 2.1, 7.2), "#f2ede2", Enum.Material.Fabric)
-- bàn + ghế Khoa
box("Desk", Vector3.new(2.6, 0.25, 6), R(7.4, 3, 3), "#a07c58", Enum.Material.Wood)
box("DeskLegs", Vector3.new(2.4, 2.9, 0.2), R(7.4, 1.45, 0.2), "#5a4430", Enum.Material.Wood)
box("DeskLegs", Vector3.new(2.4, 2.9, 0.2), R(7.4, 1.45, 5.8), "#5a4430", Enum.Material.Wood)
box("Monitor", Vector3.new(0.2, 2, 3.2), R(8.3, 4.4, 3), "#1d1f22", Enum.Material.Metal)
local monitorGlow = box("MonitorScreen", Vector3.new(0.05, 1.8, 3), R(8.18, 4.4, 3), "#5a8fd8", Enum.Material.Neon, { Transparency = 0.15 })
light("SurfaceLight", monitorGlow, { Face = Enum.NormalId.Left, Range = 12, Brightness = 1.2, Color = Color3.fromRGB(120, 170, 255) })
box("GameChair", Vector3.new(1.8, 0.3, 1.8), R(5.2, 1.8, 3), "#c94a3c")
box("GameChairBack", Vector3.new(0.3, 3, 1.8), R(4.3, 3.3, 3), "#c94a3c")
box("GameChairBase", Vector3.new(0.3, 1.6, 0.3), R(5.2, 0.8, 3), "#222222", Enum.Material.Metal)
-- đèn dây ấm + poster
for i = 0, 11 do
	local b = ball("FairyLight", 0.25, R(-8.3, 8.6 - math.abs(math.sin(i * 0.6)) * 0.5, -6 + i * 1.2), "#ffcf87", Enum.Material.Neon)
	if i % 4 == 0 then
		light("PointLight", b, { Range = 6, Brightness = 0.7, Color = Color3.fromRGB(255, 190, 120) })
	end
end
local poster = box("Poster", Vector3.new(0.1, 3.2, 2.4), R(-8.45, 5.5, -2), "#2a3a5a")
sign(poster, "ARCHITECTURE\n2026", Enum.NormalId.Right, { color = Color3.fromRGB(240, 220, 180), font = Enum.Font.GothamBold })
local roomLamp = box("CeilingLamp", Vector3.new(2, 0.2, 2), R(0, 9.9, 0), "#ffffff", Enum.Material.Neon, { Transparency = 0.3 })
local roomLight = light("PointLight", roomLamp, { Range = 16, Brightness = 0.35, Color = Color3.fromRGB(210, 220, 255), Shadows = true })
local fanHub = box("FanHub", Vector3.new(0.8, 0.4, 0.8), R(0, 9.2, -3), "#ededed", Enum.Material.Metal)
for i = 0, 2 do
	local blade = box("FanBlade", Vector3.new(3, 0.06, 0.6), CFrame.new(fanHub.Position) * CFrame.Angles(0, rad(i * 120), 0) * CFrame.new(1.7, 0, 0), "#f3f3f3")
	blade.Anchored = false
	weld(fanHub, blade)
end

------------------------------------------------------------------------ DÀN DIỄN VIÊN
-- Thêm/đổi bộ đồ: xem Kit.OUTFITS trong PhimKit, hoặc truyền bảng mới vào Kit.dress(...)
Kit.POSES.flowersPhone = { LeftShoulder = { 30, 0, -5 }, LeftElbow = { 70, 0, 0 }, RightShoulder = { 40, 0, 10 }, RightElbow = { 75, 0, 0 } }
Kit.POSES.flowersLeft = { LeftShoulder = { 30, 0, -5 }, LeftElbow = { 70, 0, 0 } }
Kit.POSES.paperRead = { RightShoulder = { 45, 0, 15 }, LeftShoulder = { 45, 0, -15 }, RightElbow = { 70, 0, 0 }, LeftElbow = { 70, 0, 0 } }

local Minh = Kit.actor("Minh", { skin = "#efc8a8", hair = "curtain", hairColor = "#1e1a18", mole = "", outfit = "minh_ao_so_mi" })
local An = Kit.actor("An", { skin = "#f6d8c6", hair = "long", hairColor = "#2a1d18", female = true, lips = "#c76a6a", outfit = "an_vay_trang" })
local Khoa = Kit.actor("Khoa", { skin = "#d6a07c", hair = "spiky", hairColor = "#1a1714", build = 1.08, outfit = "khoa_hoodie" })
local CoHoa = Kit.actor("CoHoa", { skin = "#c8926e", hair = "bun", hairColor = "#2a2626", female = true, height = 0.95, outfit = "co_hoa_ba_ba" })
local PhucVu = Kit.actor("PhucVu", { skin = "#e8bf9f", hair = "ponytail", hairColor = "#3a2a20", female = true, lips = "#b86a6a", outfit = "phuc_vu" })
local Khach = Kit.actor("Khach", { skin = "#dcae8a", hair = "short", hairColor = "#2a2420", outfit = { top = "jacket", sleeves = "long", topColor = "#e9e4d8", jacketColor = "#3d4a3a", bottom = "pants", bottomColor = "#2b2b2b", shoes = "#5a3e2a", acc = { "glasses" } } })
local ALL = { Minh, An, Khoa, CoHoa, PhucVu, Khach }

local function onlyCast(list)
	local keep = {}
	for _, a in ipairs(list) do
		keep[a] = true
	end
	for _, a in ipairs(ALL) do
		if not keep[a] then
			Kit.hide(a)
		end
		Kit.resetPose(a)
		a.face:SetAttribute("Talking", false)
		Kit.tears(a, false)
		Kit.gaze(a, 0, 0)
	end
end

local bouquet = makeBouquet(CFrame.new(BIKE + Vector3.new(-1.6, 3.2, -0.6)))
local gift = makeGift(CFrame.new(S(-30, 1, 30)))
local minhPhone = makePhone(CFrame.new(S(-30, 1, 32)))
local anPhone = makePhone(CFrame.new(S(-30, 1, 34)), "#e8d6d0")
local paper = box("Paper", Vector3.new(0.9, 1.2, 0.03), CFrame.new(S(-30, 1, 36)), "#fbfbf8", nil, { CanCollide = false })
sign(paper, "KẾT QUẢ\nĐO THÍNH LỰC", Enum.NormalId.Front, { color = Color3.fromRGB(40, 40, 60) })

------------------------------------------------------------------------ CÁC CẢNH
local SEAT_AN, SEAT_MINH = C(-8.8, 0, -8.5), C(-3.2, 0, -8.5)
local TABLE = C(-6, 0, -8.5)

local function setupCafe(withMinh)
	Kit.look("afternoon")
	onlyCast({ An, PhucVu, Khach, withMinh and Minh or nil })
	Kit.sit(An, SEAT_AN, 1.8, TABLE)
	Kit.pose(An, "handsOnTable", 0.01, false)
	Kit.expr(An, "sad")
	Kit.stand(PhucVu, C(3, 0, 7.6), C(3, 0, 0))
	Kit.sit(Khach, C(2.2, 0, 1), 1.8, C(5, 0, 1))
	Kit.expr(Khach, "neutral")
	Kit.pose(Khach, "phoneLook", 0.01, false)
	if withMinh then
		Kit.sit(Minh, SEAT_MINH, 1.8, TABLE)
		Kit.release(bouquet, CFrame.new(C(-5.2, 3.9, -9.3)) * CFrame.Angles(0, 0, rad(80)))
		Kit.release(gift, CFrame.new(C(-5.4, 3.3, -7.6)))
		Kit.pose(Minh, "handsOnTable", 0.01, false)
	end
end

-- 00:00 — HOOK: vào thẳng lời chia tay
local function hook()
	setupCafe(true)
	Kit.expr(Minh, "smile")
	fx("start")
	fx("fade", 1, 0)
	Kit.frame(An, "CU", { angle = 25, mm = 50, handheld = 0.1 })
	fx("fade", 0, 0.3)
	fx("sfx", "cafe", true)
	task.wait(0.4)
	say(An, "Mình chia tay đi.", 1.9, "hurt")
	Kit.frame(Minh, "MS", { angle = -20, mm = 40 })
	Kit.expr(Minh, "shocked")
	task.wait(0.6)
	say(Minh, "Hôm nay mùng 1 tháng 4 đó nha.", 2.3, "laugh")
	Kit.frame(An, "CU", { angle = 15, mm = 55, dof = 0.5 })
	Kit.tears(An, true)
	say(An, "Em nói thật.", 1.8, "sad")
	clear()
	fx("fade", 1, 0.12)
	task.wait(0.6)
	fx("big", "Ngày 1 tháng 4.\nNgày người ta nói thật… mà không ai tin.", 3.4)
	task.wait(4.2)
	fx("title", "THÁNG TƯ NÓI DỐI", "Tập 1 · Cá tháng Tư")
	task.wait(4.6)
	fx("sfx", "cafe", false)
end

-- 00:20 — PHỐ HOA: 3 tiếng trước
local function street()
	Kit.look("morning")
	onlyCast({ Minh, CoHoa })
	Kit.dress(Minh, "minh_ao_so_mi")
	Kit.release(bouquet, CFrame.new(BIKE + Vector3.new(-1.6, 3.2, -0.6)))
	Kit.stand(CoHoa, BIKE + Vector3.new(1.5, 0, 2.2), BIKE + Vector3.new(-6, 0, 0))
	Kit.expr(CoHoa, "smile")
	Kit.stand(Minh, S(-22, 0.4, 9), S(0, 0.4, 9))
	Kit.expr(Minh, "happy")

	fx("sfx", "street", true)
	Kit.cam({ pos = S(-34, 18, -6), look = S(-6, 6, 10), mm = 22, time = 0 })
	fx("fade", 0, 1.2)
	fx("caption", "Sáng 1/4 · 3 tiếng trước")
	task.wait(0.2)
	Kit.cam({ pos = S(-26, 6.5, -1), look = S(-12, 4, 9), mm = 28, time = 5 })
	task.wait(2)
	-- Minh đi dọc vỉa hè dưới hàng hoa sưa, máy đi theo
	Kit.frame(Minh, "FS", { angle = 70, mm = 30, smooth = 3, handheld = 0.1 })
	Kit.walk(Minh, S(-4.5, 0.4, 7.9), 7)
	Kit.turn(Minh, CoHoa.root.Position, 0.4)

	Kit.two(Minh, CoHoa, "MLS", { side = -1, mm = 35, angle = -15 })
	say(CoHoa, "Mua cho người yêu hả con? Loa kèn chỉ có tháng Tư thôi đấy.", 3.2, "smile")
	Kit.frame(Minh, "MCU", { angle = 30, mm = 40 })
	say(Minh, "Dạ. Hôm nay kỷ niệm hai năm tụi con.", 2.6, "happy")
	Kit.frame(CoHoa, "MS", { angle = -25, mm = 40 })
	Kit.pose(CoHoa, "sellFlowers", 0.4)
	Kit.grab(CoHoa, bouquet, "RightHand", CFrame.new(0, 0.3, -0.2))
	say(CoHoa, "Bó đẹp nhất cho con đấy.", 2, "smile")
	-- trao hoa
	Kit.two(Minh, CoHoa, "MS", { side = -1, mm = 35 })
	Kit.pose(Minh, "offer", 0.4)
	Kit.release(bouquet)
	Kit.grab(Minh, bouquet, "LeftHand", CFrame.new(0, 0.3, -0.2))
	Kit.pose(CoHoa, "rest", 0.3, false)
	Kit.pose(Minh, "flowersPhone", 0.4)
	minhPhone.CFrame = Minh.model.RightHand.CFrame
	Kit.grab(Minh, minhPhone, "RightHand", CFrame.new(0, -0.25, -0.25) * CFrame.Angles(rad(-70), 0, 0))

	-- nhắn tin cho An
	Kit.frame(Minh, "MCU", { angle = 20, mm = 45, dof = 0.4 })
	Kit.gaze(Minh, 0, 0.8)
	fx("phone", { title = "An 🌷", msgs = {}, status = "" })
	task.wait(0.6)
	fx("phoneAdd", true, "Cà phê cũ nha. Có bất ngờ 🎁")
	task.wait(1.2)
	fx("phoneStatus", "An đang nhập…")
	task.wait(1.6)
	fx("phoneAdd", false, "Em cũng có chuyện muốn nói.")
	Kit.expr(Minh, "worried")
	task.wait(1.2)
	Kit.expr(Minh, "smile")
	task.wait(1)
	fx("phoneHide")
	Kit.gaze(Minh, 0, 0)
	fx("sfx", "street", false)
	fx("fade", 1, 0.6)
	task.wait(0.7)
end

-- 01:00 — QUÁN CÀ PHÊ, trước khi Minh tới
local function cafeBefore()
	setupCafe(false)
	Kit.expr(An, "sad")
	fx("sfx", "cafe", true)
	Kit.cam({ pos = C(-1, 6.5, -2), look = C(-8.5, 3, -9), mm = 32, time = 0, handheld = 0.08 })
	fx("caption", "Chiều cùng ngày")
	fx("fade", 0, 0.8)
	task.wait(1.5)
	-- An nhìn tờ giấy rồi gập lại cất đi
	Kit.pose(An, "paperRead", 0.5)
	Kit.grab(An, paper, "RightHand", CFrame.new(0.2, -0.2, -0.4) * CFrame.Angles(rad(-60), 0, 0))
	Kit.frame(An, "MCU", { angle = 35, mm = 45, dof = 0.4 })
	Kit.gaze(An, 0, 0.9)
	task.wait(2.2)
	Kit.cam({ pos = Kit.on(An, "RightHand", Vector3.new(0.8, 1.2, -1.8), true), look = Kit.on(An, "RightHand"), mm = 60, time = 0, dof = 0.6, focusRadius = 1 })
	task.wait(1.8)
	Kit.release(paper, CFrame.new(S(-30, 1, 36)))
	Kit.pose(An, "handsOnTable", 0.4)
	Kit.gaze(An, 0, 0)

	-- Linh gọi tới
	fx("sfx", "notify")
	anPhone.CFrame = An.model.RightHand.CFrame
	Kit.grab(An, anPhone, "RightHand", CFrame.new(0, -0.2, -0.15))
	Kit.pose(An, "phoneEar", 0.5)
	Kit.frame(An, "MCU", { angle = -30, mm = 45, dof = 0.35 })
	voice("Linh (điện thoại)", "Mày định nói thật với nó không?", 2.8, "phone")
	say(An, "Không.", 1.4, "sad")
	clear()
	task.wait(0.8)
	-- đẩy máy chậm vào mặt An
	Kit.frame(An, "MCU", { angle = 0, mm = 45, dof = 0.4 })
	task.wait(0.05)
	Kit.frame(An, "CU", { angle = 0, mm = 60, time = 3, dof = 0.55 })
	say(An, "Tao sẽ nói dối.", 2.4, "serious")
	clear()
	task.wait(0.8)
	Kit.pose(An, "handsOnTable", 0.4)
	Kit.release(anPhone, CFrame.new(C(-7, 3.1, -9.2)) * CFrame.Angles(rad(90), 0, 0))
	-- tập cười trước tấm kính cửa sổ
	Kit.turn(An, C(-9, 0, -14), 0.5)
	Kit.cam({ pos = C(-8.6, 4.6, -14), look = Kit.on(An, "Head"), mm = 50, time = 0, dof = 0.3 })
	Kit.expr(An, "forcedSmile")
	task.wait(1.4)
	Kit.expr(An, "sad")
	task.wait(1)
	Kit.expr(An, "smile")
	task.wait(1.2)
	Kit.turn(An, TABLE, 0.4)
end

-- 01:30 — MINH TỚI, lời chia tay nhìn từ góc rộng
local function cafeBreakup()
	-- Minh bước vào từ cửa
	Kit.stand(Minh, C(12, 0, -15), C(12, 0, 0))
	Kit.pose(Minh, "holdFlowers", 0.01, false)
	Kit.release(bouquet)
	Kit.grab(Minh, bouquet, "LeftHand", CFrame.new(0, 0.3, -0.2))
	Kit.release(gift)
	Kit.grab(Minh, gift, "RightHand", CFrame.new(0, -0.3, -0.2))
	Kit.expr(Minh, "happy")
	fx("sfx", "bell")
	Kit.cam({ pos = C(-10, 6, -3), look = Kit.on(Minh, "Head"), mm = 30, time = 0, smooth = 3 })
	Kit.walk(Minh, C(12, 0, -6), 7)
	Kit.walk(Minh, C(-3.2, 0, -5.8), 7)
	Kit.sit(Minh, SEAT_MINH, 1.8, TABLE, 0.6)
	Kit.pose(Minh, "handsOnTable", 0.3)
	Kit.release(bouquet, CFrame.new(C(-5.2, 3.9, -9.3)) * CFrame.Angles(0, 0, rad(80)))
	Kit.release(gift, CFrame.new(C(-5.4, 3.3, -7.6)))

	-- hai người cùng khung — lặp lại lời chia tay
	Kit.two(An, Minh, "MS", { side = 1, mm = 35, height = 0.8 })
	Kit.expr(An, "hurt")
	task.wait(0.8)
	say(An, "Mình chia tay đi.", 2, "hurt")
	say(Minh, "Hôm nay mùng 1 tháng 4 đó nha.", 2.2, "laugh")
	Kit.ots(Minh, An, "MCU", { side = 1, mm = 45 })
	say(An, "Em nói thật.", 1.8, "sad")
	Kit.ots(An, Minh, "MCU", { side = -1, mm = 45 })
	say(Minh, "Diễn sâu ghê. Năm nay em thắng rồi đó.", 2.8, "laugh")

	-- An đứng dậy, đẩy bó hoa về phía Minh
	Kit.two(An, Minh, "MLS", { side = 1, mm = 32, height = 1 })
	Kit.stand(An, C(-8.6, 0, -6.4), TABLE)
	Kit.pose(An, "offer", 0.4)
	Kit.cam({ pos = C(-6, 5.2, -5.2), look = C(-5.2, 3.6, -9.3), mm = 40, time = 0, dof = 0.4, focusRadius = 1.5 })
	Kit.tw(bouquet.PrimaryPart, 0.6, { CFrame = CFrame.new(C(-4.3, 3.9, -8.9)) * CFrame.Angles(0, 0, rad(80)) })
	task.wait(0.6)
	Kit.frame(An, "CU", { angle = 30, mm = 55, dof = 0.5 })
	Kit.tears(An, true)
	say(An, "Anh giữ đi. Em không mang theo được.", 3, "cry")
	clear()
	Kit.pose(An, "rest", 0.3)

	-- An bước ra cửa
	Kit.frame(Minh, "MS", { angle = 40, mm = 35 })
	Kit.expr(Minh, "laugh")
	task.spawn(function()
		Kit.walk(An, C(-8.6, 0, -5.8), 6)
		Kit.walk(An, C(12, 0, -5.8), 6)
		Kit.walk(An, C(12, 0, -15), 6)
	end)
	task.wait(1.5)
	say(Minh, "Ê! Còn quà mà!", 1.8, "laugh")
	clear()
	task.wait(2.5)
	fx("sfx", "bell")
	fx("sfx", "cafe", false)

	-- ngoài trời đổ mưa: An đi qua cửa kính, Minh vẫn ngồi cười bên trong
	Kit.look("rain")
	fx("rain", true)
	fx("sfx", "rain", true)
	fx("sfx", "music", true)
	Kit.cam({ pos = C(-2, 4.6, -22), look = C(-6, 3.5, -9), mm = 35, time = 0, handheld = 0.08, dof = 0.15 })
	Kit.walk(An, C(-24, 0.4, -16.5), 6)
	-- quay vào trong, giữ khung: ghế trống, bó hoa, nụ cười tắt dần
	fx("rain", false)
	Kit.hide(An)
	Kit.frame(Minh, "MS", { angle = -35, mm = 40, handheld = 0.05 })
	Kit.expr(Minh, "smile")
	Kit.gaze(Minh, -1, 0)
	task.wait(1.4)
	Kit.expr(Minh, "forcedSmile")
	task.wait(1.2)
	Kit.cam({ pos = C(-4.6, 5.2, -5.8), look = C(-8.8, 2.8, -8.5), mm = 35, time = 0 })
	task.wait(1.6)
	Kit.frame(Minh, "CU", { angle = -15, mm = 55, dof = 0.5 })
	Kit.gaze(Minh, 0, 0.6)
	Kit.expr(Minh, "sad")
	task.wait(2.2)
	fx("fade", 1, 1)
	task.wait(1.2)
end

-- 02:30 — PHÒNG TRỌ, đêm mưa
local function roomNight()
	Kit.look("night")
	onlyCast({ Minh, Khoa })
	Kit.dress(Minh, "minh_ao_ngu")
	Kit.sit(Khoa, R(5.2, 0, 3), 1.95, R(9, 0, 3))
	Kit.pose(Khoa, "gameHold", 0.01, false)
	Kit.expr(Khoa, "happy")
	Kit.sit(Minh, R(-3.6, 0, 2.5), 1.8, R(4, 0, 2.5))
	Kit.pose(Minh, "phoneLook", 0.01, false)
	minhPhone.Anchored = true
	Kit.grab(Minh, minhPhone, "RightHand", CFrame.new(0, -0.25, -0.25) * CFrame.Angles(rad(-70), 0, 0))
	Kit.expr(Minh, "sad")
	Kit.gaze(Minh, 0, 0.8)
	fx("sfx", "rain", true)
	fx("sfx", "game", true)
	Kit.cam({ pos = R(-6, 7.5, -7.5), look = R(1, 2.5, 3), mm = 24, time = 0 })
	fx("caption", "22:47")
	fx("fade", 0, 1)
	task.wait(2)

	Kit.frame(Khoa, "MS", { angle = -60, mm = 35 })
	say(Khoa, "Sao? Đi cá tháng Tư về bị cá thật à?", 2.8, "laugh")
	Kit.turn(Khoa, Minh.root.Position, 0.5)
	clear()
	Kit.frame(Minh, "MS", { angle = 20, mm = 40 })
	task.wait(1.5)
	Kit.frame(Khoa, "MCU", { angle = 0, mm = 40 })
	Kit.expr(Khoa, "worried")
	fx("sfx", "game", false)
	task.wait(1.5)

	-- tin nhắn: Đã xem, không trả lời
	Kit.frame(Minh, "MCU", { angle = 25, mm = 45, dof = 0.4 })
	fx("phone", {
		title = "An 🌷",
		msgs = {
			{ me = true, text = "Cà phê cũ nha. Có bất ngờ 🎁" },
			{ me = false, text = "Em cũng có chuyện muốn nói." },
		},
		status = "",
	})
	task.wait(0.8)
	fx("phoneAdd", true, "Đùa đủ rồi nha 😅")
	task.wait(1.5)
	fx("phoneStatus", "Đã xem 22:48")
	Kit.expr(Minh, "worried")
	task.wait(2.5)
	fx("phoneHide")
	-- gọi điện: chuông đổ rồi im
	Kit.pose(Minh, "phoneEar", 0.4)
	Kit.frame(Minh, "CU", { angle = -20, mm = 50, dof = 0.5 })
	fx("sfx", "ring", true)
	task.wait(4)
	fx("sfx", "ring", false)
	task.wait(1.2)
	Kit.pose(Minh, "phoneLook", 0.4)

	-- tin nhắn từ Linh
	fx("phone", { title = "Linh (bạn An)", msgs = {}, status = "" })
	task.wait(0.4)
	fx("phoneAdd", false, "Mày không biết thật à?")
	fx("sfx", "heartbeat", true)
	Kit.frame(Minh, "MCU", { angle = 0, mm = 45, dof = 0.5 })
	task.wait(0.05)
	Kit.frame(Minh, "CU", { angle = 0, mm = 65, time = 3.5, dof = 0.6 })
	Kit.expr(Minh, "dread")
	task.wait(3.6)
	fx("phoneHide")
	fx("sfx", "heartbeat", false)
	fx("fade", 1, 0.2)
	task.wait(0.6)
	fx("big", "Tập 2 — Người biết sự thật", 3)
	task.wait(3.8)
	fx("end")
end

local function runEpisode()
	hook()
	street()
	cafeBefore()
	cafeBreakup()
	roomNight()
end

------------------------------------------------------------------------ CHẠY
for _, a in ipairs(ALL) do
	Kit.hide(a)
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
	local ok, err = pcall(runEpisode)
	if not ok then
		warn("[ThangTu] Lỗi khi diễn: ", err)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
print("[ThangTu] Đã dựng phố hoa, quán cà phê, phòng trọ. Tập 1 sẽ tự chạy khi bấm Play.")
