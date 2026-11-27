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

--[[ ĐỒ THẬT TỪ CATALOG ROBLOX (đẹp nhất):
	Mở roblox.com/catalog, chọn món đồ, lấy số ID trong đường dẫn (roblox.com/catalog/<ID>/...),
	rồi thêm vào nhân vật, ví dụ:
		catalog = { HairAccessory = "1234567", Shirt = 2345678, Pants = 3456789, HatAccessory = "", FaceAccessory = "" }
	Nhiều món cùng loại: "id1,id2". Có tóc catalog thì bỏ tóc tự dựng; có áo/quần catalog thì bỏ đồ tự dựng.
	Hoặc lấy nguyên avatar của một tài khoản: userId = 123456.
]]
local CAST = {
	Ban = { catalog = { HairAccessory = "7259123616", Shirt = 398633584, Pants = 382538503 },  skin = "#efc8a8", hair = "curtain", hairColor = "#1e1a18", height = 1.02, outfit = { top = "hoodie", sleeves = "long", topColor = "#3b6ea5", bottom = "jeans", bottomColor = "#2f3a4a", shoes = "#f2f2f2", acc = { "backpack" } } },
	Linh = { catalog = { HairAccessory = "2956239660", Shirt = 398635081, Pants = 144076512 },  skin = "#f4d5c0", hair = "bob", hairColor = "#3a241a", female = true, lips = "#c06a6a", height = 0.93, outfit = "linh_ao_bo" },
	Tuan = { catalog = { HairAccessory = "5644883846" },  skin = "#c98e68", hair = "spiky", hairColor = "#161412", height = 1.12, width = 1.1, outfit = { top = "tee", sleeves = "short", topColor = "#c8322f", bottom = "shorts", bottomColor = "#1d1d22", shoes = "#f2f2f2", acc = { "watch" } } },
	CoBanMi = { skin = "#d8a280", hair = "bun", hairColor = "#2a2626", female = true, height = 0.88, width = 0.98, proportion = 0.2, outfit = { top = "baba", sleeves = "long", topColor = "#6f8a6a", bottom = "pants", bottomColor = "#1e1f22", shoes = "#e8e4dc", acc = { "apron" } } },
	KhachA = { catalog = { HairAccessory = "376526888" },  skin = "#f0cfb8", hair = "ponytail", hairColor = "#4a2e22", female = true, lips = "#c07070", height = 0.95, outfit = "an_cardigan" },
	KhachB = { catalog = { HairAccessory = "63690008" },  skin = "#dcae8a", hair = "short", hairColor = "#1e1a18", height = 1.0, width = 1.08, outfit = "minh_ao_phong" },
	KhachC = { skin = "#f2d2bc", hair = "short", hairColor = "#2a1d18", height = 0.72, width = 0.85, headScale = 1.1, outfit = { top = "tee", sleeves = "short", topColor = "#e8c547", bottom = "shorts", bottomColor = "#3b5a8a", shoes = "#d64545", acc = {} } },
	KhachD = { skin = "#c8926e", hair = "short", hairColor = "#bdbdbd", height = 0.95, width = 1.05, outfit = { top = "shirt", sleeves = "long", topColor = "#d8d2c0", bottom = "pants", bottomColor = "#4a4a44", shoes = "#2a2a2a", acc = { "glasses" } } },
}
Video.CAST = CAST

function Video.build(Kit)
	Video._buildOnly = true
	local ctx = Video.run(Kit)
	Video._buildOnly = false
	return ctx
end

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
	Kit.surround(P(0, 0, 0), 150, { seed = 5, lake = 0 })
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

	-- công cụ dựng chi tiết
	local function wedge(name, size, cf, color, material)
		local w = Instance.new("WedgePart")
		w.Name = name
		w.Anchored = true
		w.Size = size
		w.CFrame = cf
		w.Color = Kit.hex(color)
		w.Material = material or Enum.Material.SmoothPlastic
		w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		w.Parent = Kit.SET
		return w
	end
	local rng = Random.new(42)
	local COLORS = { "#e3c06a", "#cfd6b0", "#b9cdd6", "#e0a8a0", "#e6d7b8", "#c9b8d9", "#a8c4a0", "#d98f6a", "#f0e0c0", "#bcd4c4" }
	local SHOPNAMES = { "TẠP HOÁ", "TRÀ SỮA", "PHỞ BÒ", "BÁNH MÌ", "ĐIỆN THOẠI", "CƠM TẤM", "NHÀ THUỐC", "HIỆU SÁCH", "CAFE", "BÚN CHẢ", "SỬA XE", "KÍNH MẮT", "TIỆM BÁNH", "SPA", "VĂN PHÒNG PHẨM" }
	local AWNING = { { "#c8322f", "#f2f2f2" }, { "#2f6ab0", "#f2f2f2" }, { "#2f7a4a", "#f2e6c8" }, { "#e2a32b", "#7a3a1a" } }

	-- nhà ống kiểu Việt Nam: cửa hàng tầng trệt, mái hiên sọc, biển hiệu, ban công, điều hoà, bồn nước inox
	local function vnHouse(i, x, z, faceDir)
		local w = 8 + rng:NextInteger(0, 3)
		local floors = rng:NextInteger(3, 6)
		local h = 8.5 + floors * 4.8 + 1
		local d = 12
		local col = COLORS[(i % #COLORS) + 1]
		box("House", Vector3.new(w, h, d), P(x, h / 2, z), col, Enum.Material.Plaster)
		local fz = z + faceDir * (d / 2)
		local function F(dx, y, dz)
			return P(x + dx, y, fz + faceDir * dz)
		end
		local face = faceDir < 0 and Enum.NormalId.Front or Enum.NormalId.Back
		-- tầng trệt
		box("ShopFront", Vector3.new(w - 1.2, 6.2, 0.2), F(0, 3.1, 0.05), "#2b2622")
		local shopLight = box("ShopLight", Vector3.new(w - 2, 0.15, 0.15), F(0, 6, 0.3), "#fff0c8", Enum.Material.Neon)
		Kit.practical(shopLight, "PointLight", { Range = 12, Brightness = 1.4, Color = Color3.fromRGB(255, 200, 140) })
		box("Shutter", Vector3.new(w - 1.3, 2, 0.15), F(0, 5.2, 0.2), "#9aa0a4", Enum.Material.DiamondPlate)
		for k = 0, 2 do
			box("Goods", Vector3.new(1.4, 1.2 + k * 0.4, 1.2), F(-w / 2 + 1.6 + k * 1.8, 0.6 + k * 0.2, 1.2), ({ "#d64545", "#e8c547", "#4a78b8" })[k + 1], Enum.Material.Cardboard)
		end
		local aw = AWNING[(i % #AWNING) + 1]
		for k = 0, math.floor(w / 1.2) - 1 do
			box("Awning", Vector3.new(1.2, 0.15, 3), CFrame.new(F(-w / 2 + 0.6 + k * 1.2, 7.1, 1.4)) * CFrame.Angles(rad(faceDir * -14), 0, 0), k % 2 == 0 and aw[1] or aw[2], Enum.Material.Fabric)
		end
		local board = box("Sign", Vector3.new(w - 0.8, 1.6, 0.3), F(0, 8.6, 0.3), i % 2 == 0 and "#b3262e" or "#1f4e79")
		sign(board, SHOPNAMES[(i % #SHOPNAMES) + 1], face, { color = Color3.fromRGB(255, 236, 170), font = Enum.Font.GothamBlack, glow = true })
		-- các tầng trên
		for fl = 1, floors do
			local y = 9 + fl * 4.8
			box("WinFrame", Vector3.new(w * 0.55, 3.2, 0.25), F(0, y, 0.05), "#f2efe6")
			Kit.windowGlow(box("WinGlass", Vector3.new(w * 0.55 - 0.5, 2.7, 0.1), F(0, y, 0.2), "#3d5570", Enum.Material.Glass, { Reflectance = 0.15 }))
			box("ShutterL", Vector3.new(0.9, 3.2, 0.15), F(-w * 0.275 - 0.5, y, 0.15), "#4d7a5a", Enum.Material.Wood)
			box("ShutterR", Vector3.new(0.9, 3.2, 0.15), F(w * 0.275 + 0.5, y, 0.15), "#4d7a5a", Enum.Material.Wood)
			box("Balcony", Vector3.new(w - 0.6, 0.3, 1.8), F(0, y - 1.9, 0.9), "#d8d2c4", Enum.Material.Concrete)
			box("Rail", Vector3.new(w - 0.6, 1.2, 0.12), F(0, y - 1.2, 1.75), "#2b2b2b", Enum.Material.Metal, { Transparency = 0.15 })
			box("AC", Vector3.new(1.6, 1.1, 0.8), F(w / 2 - 1.1, y + 0.9, 0.5), "#e8e8e8", Enum.Material.Metal)
			cyl("ACFan", 0.05, 0.8, CFrame.new(F(w / 2 - 1.1, y + 0.9, 0.92)) * CFrame.Angles(rad(90), 0, 0), "#555555")
			if rng:NextNumber() < 0.6 then
				ball("Plant", 1, F(-w / 2 + 1, y - 1.3, 1.2), "#4f7d3d", Enum.Material.Grass)
				box("PlantPot", Vector3.new(0.8, 0.6, 0.8), F(-w / 2 + 1, y - 1.75, 1.2), "#c46a4a", Enum.Material.Concrete)
			end
			if rng:NextNumber() < 0.35 then
				for k = 0, 2 do
					box("Laundry", Vector3.new(0.9, 1.1, 0.05), F(-1 + k * 1.1, y - 0.2, 1.6), ({ "#e8e8e8", "#d64545", "#4a78b8", "#e8c547" })[rng:NextInteger(1, 4)], Enum.Material.Fabric)
				end
			end
		end
		-- mái: bồn nước inox nằm ngang + ăng ten
		box("Parapet", Vector3.new(w, 1, d), P(x, h + 0.5, z), col, Enum.Material.Plaster)
		local tank = cyl("WaterTank", 3, 1.6, CFrame.new(P(x - 1, h + 2, z)) * CFrame.Angles(0, 0, rad(90)), "#c8ccd0", Enum.Material.Metal)
		tank.CFrame = CFrame.new(P(x - 1, h + 1.9, z)) * CFrame.Angles(0, rad(90), 0)
		box("TankStand", Vector3.new(2, 0.9, 1.2), P(x - 1, h + 1.1, z), "#555555", Enum.Material.Metal)
		box("Antenna", Vector3.new(0.1, 3, 0.1), P(x + w / 2 - 1, h + 2.5, z), "#333333", Enum.Material.Metal)
	end
	for i = 0, 13 do
		vnHouse(i, -62 + i * 9.6, 64, -1)
	end
	for i = 0, 13 do
		vnHouse(i + 5, -62 + i * 9.6, -66, 1)
	end
	for _, x in ipairs({ -70, 70 }) do
		box("SideBlock", Vector3.new(12, 36, 110), P(x, 18, 0), "#bfb3a0", Enum.Material.Concrete)
		for fl = 1, 5 do
			for k = -4, 4 do
				Kit.windowGlow(box("SideWin", Vector3.new(0.2, 2.6, 3), P(x - math.sign(x) * 6.05, fl * 6, k * 11), "#3d5570", Enum.Material.Glass, { Reflectance = 0.15 }))
			end
		end
	end

	-- cây xanh nhiều tầng lá + bồn cây
	local function tree(x, z, s)
		s = s or 1
		local base = CFrame.new(P(x, 0, z))
		local asset = Kit.asset("Tree", base * CFrame.Angles(0, rng:NextNumber(0, 6), 0), nil, math.floor(x + z))
		if asset then
			return
		end
		cyl("Planter", 0.8, 3.4 * s, P(x, 0.4, z), "#a9a294", Enum.Material.Concrete)
		cyl("Soil", 0.1, 3 * s, P(x, 0.82, z), "#4a3a2a", Enum.Material.Ground)
		cyl("Trunk", 8 * s, 0.9 * s, P(x, 4 * s, z), "#5b4636", Enum.Material.Wood)
		for k = 0, 2 do
			cyl("Branch", 3 * s, 0.35 * s, CFrame.new(P(x, 7 * s, z)) * CFrame.Angles(0, rad(k * 120), rad(40)) * CFrame.new(0, 1.2 * s, 0), "#5b4636", Enum.Material.Wood)
		end
		local greens = { "#3f6e32", "#4f7d3d", "#5f9248", "#6aa050" }
		for k = 0, 11 do
			local a = rad(k * 47 + x)
			local r = (k < 6 and 2.2 or 1.2) * s
			ball("Leaves", (3.2 + (k % 3) * 0.7) * s, P(x + math.cos(a) * r, (8.5 + (k % 4) * 0.9 + (k >= 6 and 1.8 or 0)) * s, z + math.sin(a) * r), greens[(k % #greens) + 1], Enum.Material.Grass)
		end
	end
	for _, p in ipairs({ { -50, 40 }, { -40, 48 }, { 48, 44 }, { 55, 30 }, { -54, -20 }, { 54, -18 }, { 20, 46 }, { -14, 50 }, { -58, 10 }, { 58, 8 }, { -26, -24 }, { 26, -24 }, { 0, 48 } }) do
		tree(p[1], p[2], 0.95 + (math.abs(p[1]) % 3) * 0.08)
	end
	-- thảm cỏ + bồn hoa + hàng rào cây bụi
	local function lawn(cx, cz, sx, sz)
		box("Grass", Vector3.new(sx, 0.3, sz), P(cx, 0.15, cz), "#5f8f42", Enum.Material.Grass)
		box("Curb", Vector3.new(sx + 0.6, 0.5, 0.3), P(cx, 0.25, cz - sz / 2), "#a9a294", Enum.Material.Concrete)
		box("Curb", Vector3.new(sx + 0.6, 0.5, 0.3), P(cx, 0.25, cz + sz / 2), "#a9a294", Enum.Material.Concrete)
		for k = 0, math.floor(sx / 2.2) do
			ball("Hedge", 1.8, P(cx - sx / 2 + 0.9 + k * 2.2, 0.9, cz + sz / 2 - 0.9), "#3f6e32", Enum.Material.Grass)
		end
		for k = 1, 14 do
			ball("Flower", 0.45, P(cx + rng:NextNumber(-sx / 2 + 1, sx / 2 - 1), 0.45, cz + rng:NextNumber(-sz / 2 + 1, sz / 2 - 2.5)), ({ "#e84a5f", "#f7d046", "#ffffff", "#c86fd8", "#ff8c42" })[rng:NextInteger(1, 5)], Enum.Material.SmoothPlastic)
		end
	end
	lawn(42, 38, 30, 18)
	lawn(-44, 40, 26, 16)
	lawn(30, 10, 14, 10)

	-- đèn đường, ghế, thùng rác, cột chắn, ki-ốt, nhà chờ xe buýt, đèn giao thông
	for _, x in ipairs({ -48, -24, 0, 24, 48 }) do
		if not Kit.asset("Lamp", CFrame.new(P(x, 0.3, -28.5)), nil, x) then
			box("LampPole", Vector3.new(0.4, 12, 0.4), P(x, 6, -28.5), "#2b2b2b", Enum.Material.Metal)
			box("LampArm", Vector3.new(0.25, 0.25, 2.4), P(x, 11.9, -29.6), "#2b2b2b", Enum.Material.Metal)
			local head = box("LampHead", Vector3.new(0.8, 0.3, 1.4), P(x, 11.7, -30.6), "#fff2d0", Enum.Material.Neon)
			Kit.practical(head, "SpotLight", { Face = Enum.NormalId.Bottom, Angle = 100, Range = 24, Brightness = 2.2, Color = Color3.fromRGB(255, 205, 150), Shadows = false })
		end
		cyl("Bin", 1.6, 1.1, P(x + 3, 0.8, -28.5), "#2f7a4a", Enum.Material.Metal)
		for k = -1, 1 do
			cyl("Bollard", 1.2, 0.4, P(x + 6 + k * 1.5, 0.6, -33.2), "#3a3a3a", Enum.Material.Metal)
		end
	end
	for _, p in ipairs({ { -18, 26 }, { 18, 26 }, { -40, 30 }, { 40, 24 } }) do
		if not Kit.asset("Bench", CFrame.new(P(p[1], 0, p[2])), nil, p[1]) then
			box("Bench", Vector3.new(6, 0.4, 1.6), P(p[1], 1.6, p[2]), "#8b6a4a", Enum.Material.WoodPlanks)
			box("BenchBack", Vector3.new(6, 1.6, 0.3), P(p[1], 2.6, p[2] + 0.8), "#8b6a4a", Enum.Material.WoodPlanks)
			box("BenchLeg", Vector3.new(0.3, 1.4, 1.4), P(p[1] - 2.6, 0.7, p[2]), "#2b2b2b", Enum.Material.Metal)
			box("BenchLeg", Vector3.new(0.3, 1.4, 1.4), P(p[1] + 2.6, 0.7, p[2]), "#2b2b2b", Enum.Material.Metal)
		end
	end
	-- ki-ốt báo + nhà chờ xe buýt
	box("Kiosk", Vector3.new(5, 6, 4), P(-36, 3, -22), "#2f6ab0", Enum.Material.Metal)
	box("KioskRoof", Vector3.new(6, 0.4, 5), P(-36, 6.2, -22), "#f2f2f2", Enum.Material.Metal)
	box("KioskWindow", Vector3.new(4, 2.6, 0.2), P(-36, 3.6, -24.05), "#cfe6ee", Enum.Material.Glass, { Transparency = 0.4 })
	box("BusRoof", Vector3.new(10, 0.3, 3.6), P(48, 7.6, -30), "#2b2b2b", Enum.Material.Metal)
	box("BusBack", Vector3.new(10, 6.5, 0.15), P(48, 4, -28.4), "#cfe6ee", Enum.Material.Glass, { Transparency = 0.5 })
	box("BusPostL", Vector3.new(0.3, 7.6, 0.3), P(43.2, 3.8, -28.5), "#2b2b2b", Enum.Material.Metal)
	box("BusPostR", Vector3.new(0.3, 7.6, 0.3), P(52.8, 3.8, -28.5), "#2b2b2b", Enum.Material.Metal)
	box("BusBench", Vector3.new(8, 0.4, 1.2), P(48, 1.6, -29.2), "#8b6a4a", Enum.Material.WoodPlanks)
	local busAd = box("BusAd", Vector3.new(3.5, 5, 0.1), P(52.5, 4, -30), "#ffffff", Enum.Material.SmoothPlastic)
	busAd.CFrame = CFrame.new(P(52.6, 4, -30)) * CFrame.Angles(0, rad(90), 0)
	sign(busAd, "TRỌNG LỰC\n-50%\nBẠN ĐÃ SẴN SÀNG?", Enum.NormalId.Front, { color = Color3.fromRGB(200, 40, 40), font = Enum.Font.GothamBlack })
	-- đèn giao thông ở vạch sang đường
	for _, p in ipairs({ { -12, -32.5, 1 }, { 4, -51.5, -1 } }) do
		local base = P(p[1], 0, p[2])
		box("SignalPole", Vector3.new(0.4, 9, 0.4), base + Vector3.new(0, 4.5, 0), "#2b2b2b", Enum.Material.Metal)
		box("SignalBox", Vector3.new(1, 3, 0.9), base + Vector3.new(0, 8.4, 0), "#1d1d1d", Enum.Material.Metal)
		ball("Red", 0.6, base + Vector3.new(0, 9.4, -0.45 * p[3]), "#ff3b30", Enum.Material.Neon)
		ball("Yellow", 0.6, base + Vector3.new(0, 8.4, -0.45 * p[3]), "#4a3a10", Enum.Material.SmoothPlastic)
		ball("Green", 0.6, base + Vector3.new(0, 7.4, -0.45 * p[3]), "#103a10", Enum.Material.SmoothPlastic)
	end
	-- dây điện chằng chịt kiểu phố Việt
	for _, x in ipairs({ -56, -28, 28, 56 }) do
		box("Pole", Vector3.new(0.6, 16, 0.6), P(x, 8, -58.5), "#8d8d88", Enum.Material.Concrete)
		for k = 0, 5 do
			local wire = box("Wire", Vector3.new(28.2, 0.06, 0.06), P(x + 14, 14.6 - k * 0.45, -58.5 + k * 0.15), "#111111", nil, { CanCollide = false })
			wire.CFrame = wire.CFrame * CFrame.Angles(0, 0, rad((k % 2 == 0) and 1.2 or -1.2))
		end
	end
	-- xe máy đỗ dọc vỉa hè
	local function motorbike(x, z, col, yaw)
		local cf = CFrame.new(P(x, 0, z)) * CFrame.Angles(0, rad(yaw or 0), 0)
		if Kit.asset("Motorbike", cf, 4.5, math.floor(x)) then
			return
		end
		box("MotoBody", Vector3.new(3, 1.1, 0.7), cf * CFrame.new(0, 1.5, 0), col, Enum.Material.Metal)
		box("MotoSeat", Vector3.new(1.6, 0.35, 0.75), cf * CFrame.new(-0.3, 2.2, 0), "#1d1d1d", Enum.Material.Leather)
		box("MotoFront", Vector3.new(0.6, 1.6, 0.8), cf * CFrame.new(1.4, 2, 0) * CFrame.Angles(0, 0, rad(-15)), col, Enum.Material.Metal)
		box("MotoBar", Vector3.new(0.15, 0.15, 1.6), cf * CFrame.new(1.6, 2.9, 0), "#2b2b2b", Enum.Material.Metal)
		ball("MotoLight", 0.4, cf * CFrame.new(1.8, 2.6, 0), "#fff2c0", Enum.Material.Neon)
		for _, wx in ipairs({ -1.3, 1.5 }) do
			local wh = box("MotoWheel", Vector3.new(0.35, 1.3, 1.3), cf * CFrame.new(wx, 0.65, 0) * CFrame.Angles(0, rad(90), 0), "#1a1a1a")
			wh.Shape = Enum.PartType.Cylinder
		end
	end
	local MOTO = { "#c8322f", "#2a4d8f", "#e6e6e6", "#2f2f2f", "#e2a32b", "#2f7a4a" }
	for k = 0, 9 do
		motorbike(-56 + k * 5.2 + (k > 4 and 40 or 0), -59.5, MOTO[(k % #MOTO) + 1], 90)
	end
	for k = 0, 5 do
		motorbike(-60 + k * 2.4, -31.5, MOTO[((k + 2) % #MOTO) + 1], 90)
	end
	-- mây
	pcall(function()
		local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover, clouds.Density = 0.55, 0.6
		clouds.Parent = workspace.Terrain
	end)

	-- đài phun nước giữa quảng trường
	local F = P(0, 0, 14)
	cyl("Basin", 1.4, 16, F + Vector3.new(0, 0.7, 0), "#c9c2b4", Enum.Material.Marble)
	cyl("Water", 0.2, 15, F + Vector3.new(0, 1.35, 0), "#3f8fb8", Enum.Material.Glass, { Transparency = 0.15, Reflectance = 0.35 })
	cyl("BasinRim", 0.3, 16.6, F + Vector3.new(0, 1.5, 0), "#e6e0d2", Enum.Material.Marble)
	cyl("BasinInner", 0.35, 14.8, F + Vector3.new(0, 1.5, 0), "#3f8fb8", Enum.Material.Glass, { Transparency = 0.15, Reflectance = 0.35 })
	cyl("Tier", 0.5, 5, F + Vector3.new(0, 3.2, 0), "#d8d2c4", Enum.Material.Marble)
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

	-- ô tô: dùng model "Car" trong PhimAssets nếu có, không thì tự dựng (mui, kính lái nghiêng, gương, biển số, mâm xe)
	local function car(name, cf, color)
		local asset = Kit.asset("Car", cf, 10, #name)
		if asset then
			asset.Name = name
			return asset
		end
		local body = box(name, Vector3.new(9.6, 1.6, 4.3), cf * CFrame.new(0, 1.7, 0), color, Enum.Material.SmoothPlastic)
		local parts = {
			box("Skirt", Vector3.new(9.4, 0.5, 4.2), cf * CFrame.new(0, 0.85, 0), "#2a2a2a"),
			box("Roof", Vector3.new(3.4, 0.25, 3.9), cf * CFrame.new(-0.6, 4.05, 0), color),
			box("SideGlass", Vector3.new(3.4, 1.4, 4.0), cf * CFrame.new(-0.6, 3.2, 0), "#1f2a36", Enum.Material.Glass, { Reflectance = 0.25 }),
			wedge("Windshield", Vector3.new(4.0, 1.5, 1.5), cf * CFrame.new(1.85, 3.25, 0) * CFrame.Angles(0, rad(-90), 0), "#1f2a36", Enum.Material.Glass),
			wedge("RearGlass", Vector3.new(4.0, 1.5, 1.2), cf * CFrame.new(-2.9, 3.25, 0) * CFrame.Angles(0, rad(90), 0), "#1f2a36", Enum.Material.Glass),
			box("BumperF", Vector3.new(0.4, 0.6, 4.4), cf * CFrame.new(4.85, 1.2, 0), "#2a2a2a"),
			box("BumperB", Vector3.new(0.4, 0.6, 4.4), cf * CFrame.new(-4.85, 1.2, 0), "#2a2a2a"),
			box("Plate", Vector3.new(0.1, 0.45, 1.4), cf * CFrame.new(5.07, 1.2, 0), "#f2f2f2"),
			box("LightF", Vector3.new(0.12, 0.35, 0.9), cf * CFrame.new(4.82, 2.1, 1.5), "#fff6d8", Enum.Material.Neon),
			box("LightF2", Vector3.new(0.12, 0.35, 0.9), cf * CFrame.new(4.82, 2.1, -1.5), "#fff6d8", Enum.Material.Neon),
			box("LightB", Vector3.new(0.12, 0.35, 0.9), cf * CFrame.new(-4.82, 2.1, 1.5), "#d4141e", Enum.Material.Neon),
			box("LightB2", Vector3.new(0.12, 0.35, 0.9), cf * CFrame.new(-4.82, 2.1, -1.5), "#d4141e", Enum.Material.Neon),
			box("MirrorL", Vector3.new(0.4, 0.3, 0.5), cf * CFrame.new(1.4, 2.9, 2.35), color),
			box("MirrorR", Vector3.new(0.4, 0.3, 0.5), cf * CFrame.new(1.4, 2.9, -2.35), color),
			box("Handle", Vector3.new(0.5, 0.1, 0.05), cf * CFrame.new(-0.4, 2.3, 2.17), "#c0c0c0", Enum.Material.Metal),
		}
		for _, wx in ipairs({ -3.1, 3.1 }) do
			for _, wz in ipairs({ -2.05, 2.05 }) do
				local w = box("Tire", Vector3.new(0.9, 2.1, 2.1), cf * CFrame.new(wx, 1.05, wz) * CFrame.Angles(0, rad(90), 0), "#161616")
				w.Shape = Enum.PartType.Cylinder
				table.insert(parts, w)
				local rimPart = box("Hub", Vector3.new(0.95, 1.2, 1.2), w.CFrame, "#c8ccd0", Enum.Material.Metal)
				rimPart.Shape = Enum.PartType.Cylinder
				table.insert(parts, rimPart)
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
	car("Parked", CFrame.new(P(-6, 0, -30.5)), "#2a4d8f")
	car("Parked2", CFrame.new(P(22, 0, -54)) * CFrame.Angles(0, rad(180), 0), "#e2a32b")
	car("Parked3", CFrame.new(P(-40, 0, -54)) * CFrame.Angles(0, rad(180), 0), "#3a3a3a")

	------------------------------------------------------------------ DIỄN VIÊN
	local A = {}
	for name, spec in pairs(Video.CAST_OVERRIDE or CAST) do
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

	-- dùng lại cho bản dài (VideoDai): trả về bộ công cụ, không diễn bản Short
	if Video._buildOnly then
		return {
			P = P, A = A, Ban = Ban, Linh = Linh, Tuan = Tuan, CoBanMi = CoBanMi, crowd = crowd,
			jump = jump, setGravity = setGravity, beat = beat, placeCrowd = placeCrowd,
			car = car, label = label, moveModel = moveModel, carA = carA, carB = carB,
			thermo = thermo, jet = jet, playId = playId, wedge = wedge, oldGravity = oldGravity,
			motorbike = motorbike, tree = tree,
		}
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
	beat("Nếu sáng mai bạn thức dậy… và trọng lực chỉ còn MỘT NỬA thì sao?", 4.74, function()
		task.wait(0.3)
		jump(Ban, 9, 1.6, 10, "cheer")
		Kit.expr(Ban, "laugh")
	end)
	fx("big", "-50% TRỌNG LỰC", 2.5)
	-- 1
	Kit.cam({ pos = P(-40, 30, -50), look = P(0, 2, 10), mm = 24, time = 0 })
	task.wait(0.05)
	Kit.cam({ pos = P(-28, 18, -40), look = P(0, 2, 10), mm = 24, time = 4.5 })
	beat("Nghe thì vui. Nhưng đến ngày thứ bảy, bạn sẽ ước nó chưa từng xảy ra.", 4.66, function()
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
	beat("Ngày 1. Bạn nhảy cao gấp đôi, và lơ lửng trên không lâu gấp đôi.", 4.58, function()
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
	beat("Một cú bật nhảy bình thường đưa bạn lên gần một mét. Chạm tới vành rổ dễ như đùa.", 5.45, function()
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
	beat("Một cú sút nhẹ, quả bóng bay xa gấp đôi.", 2.81, function()
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
	beat("Ngày 2. Nhưng ngoài đường thì không vui như vậy.", 3.62, function()
		moveModel(carA, CFrame.new(P(-30, 0, -38)), 3)
		moveModel(carB, CFrame.new(P(-30, 0, -46)), 3)
	end)
	Kit.cam({ pos = P(-10, 14, -20), look = P(0, 1, -42), mm = 26, time = 0 })
	beat("Xe ép xuống mặt đường nhẹ hơn, bánh bám kém hơn. Phanh gấp, xe trượt dài gấp đôi.", 6.02, function()
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
	beat("Ngày 3. Mưa rơi chậm hơn khoảng ba mươi phần trăm. Đài phun nước bắn cao gấp đôi.", 6.49)
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
	beat("Nhưng có một thứ đã thay đổi ngay từ giây đầu tiên… mà bạn không hề nhận ra.", 4.35)
	-- 9 · áp suất
	Kit.cam({ pos = P(30, 4, -36), look = P(36, 20, -22), mm = 20, time = 0 })
	task.wait(0.05)
	Kit.cam({ pos = P(20, 30, -50), look = P(36, 40, -10), mm = 20, time = 6 })
	beat("Không khí cũng nhẹ đi một nửa. Áp suất ở mặt đất chỉ còn như trên đỉnh núi cao năm nghìn rưỡi mét.", 6.02, function()
		task.wait(1.5)
		fx("big", "ÁP SUẤT 50%\n≈ đỉnh núi 5.500 m", 3.5)
	end)
	-- 10 · leo cầu thang thở dốc
	Kit.frame(Ban, "FS", { angle = -60, mm = 28, smooth = 4 })
	beat("Leo vài bậc cầu thang là thở dốc. Nhiều người đau đầu, buồn nôn, như bị say độ cao.", 6.99, function()
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
	beat("Nước sôi ở khoảng tám mươi độ. Mì tôm… khó mà chín.", 4.01, function()
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
	beat("Ngày 7. Và rồi, đúng lúc mọi người đang ở trên không…", 4.82, function()
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
	beat("…trọng lực trở lại.", 1.37, function()
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
	beat("Nếu được sống một ngày trọng lực giảm một nửa, bạn sẽ làm gì? Bình luận cho mình biết nhé.", 6.18, function()
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
