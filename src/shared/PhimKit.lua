--[[
	PhimKit — bộ công cụ làm phim (ModuleScript trong ReplicatedStorage, tên "PhimKit").

	Kiến trúc: máy chủ CHỈ tạo khung nhân vật (Kit.buildRigs). Mọi thứ còn lại — bối cảnh,
	diễn xuất, camera, khuôn mặt, phụ đề — chạy trên máy người xem (Kit.init trong LocalScript),
	nên chuyển động mượt từng khung hình, không vật lý, không ngã, không giật.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Kit = {}
local rad = math.rad
Kit.A = {}

function Kit.hex(s)
	return Color3.fromHex(s)
end
local hex = Kit.hex

-- trả về hàm toạ độ tương đối cho một bối cảnh
function Kit.origin(o)
	return function(x, y, z)
		return o + Vector3.new(x, y, z)
	end
end

------------------------------------------------------------------------ MÁY CHỦ: TẠO KHUNG NHÂN VẬT
local function cleanHead(head)
	for _, d in ipairs(head:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") or d.ClassName == "FaceControls" then
			d:Destroy()
		end
	end
	if head:IsA("MeshPart") then
		pcall(function()
			head.TextureID = ""
		end)
	end
end

-- cast = { Ten = { skin=, female=, height=, width=, userId= (tuỳ chọn: lấy nguyên avatar Roblox) }, ... }
function Kit.buildRigs(cast)
	local folder = ReplicatedStorage:FindFirstChild("PhimRigs") or Instance.new("Folder")
	folder.Name = "PhimRigs"
	folder:SetAttribute("Ready", false)
	folder:ClearAllChildren()
	folder.Parent = ReplicatedStorage
	for name, spec in pairs(cast) do
		local desc
		if spec.userId and spec.userId > 0 then
			local ok, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, spec.userId)
			if ok then
				desc = d
				for _, k in ipairs({ "IdleAnimation", "WalkAnimation", "RunAnimation", "JumpAnimation", "FallAnimation", "ClimbAnimation", "SwimAnimation" }) do
					desc[k] = 0
				end
			else
				warn("[PhimKit] Không lấy được avatar", spec.userId, d)
			end
		end
		local custom = desc == nil
		if custom then
			desc = Instance.new("HumanoidDescription")
			local skin = hex(spec.skin or "#f0cbb2")
			desc.HeadColor, desc.TorsoColor = skin, skin
			desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = skin, skin, skin, skin
		end
		-- đồ thật từ Catalog: catalog = { HairAccessory = "id,id", Shirt = id, Pants = id, HatAccessory = "id", ... }
		local hasHair, hasClothes = false, false
		for k, v in pairs(spec.catalog or {}) do
			local ok, err = pcall(function()
				desc[k] = v
			end)
			if not ok then
				warn("[PhimKit] Sai thuộc tính catalog", k, err)
			elseif v ~= 0 and v ~= "" then
				if k == "HairAccessory" then
					hasHair = true
				elseif k == "Shirt" or k == "Pants" or k == "GraphicTShirt" then
					hasClothes = true
				end
			end
		end
		local f = spec.female == true
		desc.HeightScale = spec.height or (f and 0.93 or 1)
		desc.WidthScale = spec.width or (f and 0.8 or 1)
		desc.DepthScale = spec.depth or (f and 0.85 or 1)
		desc.HeadScale = spec.headScale or 1
		desc.BodyTypeScale = spec.bodyType or (f and 0.35 or 0.15)
		desc.ProportionScale = spec.proportion or (f and 0.6 or 0.2)
		local ok, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R15)
		if not ok and spec.catalog then
			warn("[PhimKit] Đồ catalog của", name, "lỗi, dùng đồ tự dựng:", model)
			for k in pairs(spec.catalog) do
				pcall(function()
					desc[k] = typeof(desc[k]) == "number" and 0 or ""
				end)
			end
			hasHair, hasClothes = false, false
			ok, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R15)
		end
		if ok then
			model.Name = name
			local animate = model:FindFirstChild("Animate")
			if animate then
				animate:Destroy()
			end
			cleanHead(model:WaitForChild("Head"))
			model:SetAttribute("Custom", custom)
			model:SetAttribute("HasHair", hasHair)
			model:SetAttribute("HasClothes", hasClothes)
			model.Parent = folder
		else
			warn("[PhimKit] Lỗi tạo nhân vật", name, model)
		end
	end
	folder:SetAttribute("Ready", true)
end

------------------------------------------------------------------------ DỰNG KHỐI
function Kit.part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent or Kit.SET
	return p
end

function Kit.box(name, size, pos, color, material, extra)
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
	local p = Kit.part(props)
	-- chống nhấp nháy (z-fighting): mảnh phẳng mỏng (vạch kẻ, ron gạch, thảm…) nâng hẳn lên khỏi mặt nền
	-- và không đổ bóng
	if p.Size.Y <= 0.12 and not (extra and extra.NoLift) then
		p.CFrame = p.CFrame + Vector3.new(0, 0.05, 0)
		p.CastShadow = false
	end
	return p
end

function Kit.ball(name, d, pos, color, material, extra)
	local b = Kit.box(name, Vector3.new(d, d, d), pos, color, material, extra)
	b.Shape = Enum.PartType.Ball
	return b
end

-- trụ đứng (trục Y)
function Kit.cyl(name, height, d, pos, color, material, extra)
	local cf = (typeof(pos) == "CFrame" and pos or CFrame.new(pos)) * CFrame.Angles(0, 0, rad(90))
	local c = Kit.box(name, Vector3.new(height, d, d), cf, color, material, extra)
	c.Shape = Enum.PartType.Cylinder
	return c
end

function Kit.weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
	return w
end

function Kit.sign(p, text, face, opts)
	opts = opts or {}
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.CanvasSize = opts.canvas or Vector2.new(400, 200)
	g.LightInfluence = opts.glow and 0 or 1
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = opts.font or Enum.Font.PatrickHand
	t.TextColor3 = opts.color or Color3.new(0.1, 0.1, 0.1)
	t.Text = text
	t.Parent = g
	return g
end

function Kit.light(className, parent, props)
	local l = Instance.new(className)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

------------------------------------------------------------------------ MODEL CÓ SẴN (Toolbox)
-- Kéo model miễn phí từ Toolbox vào ReplicatedStorage > thư mục "PhimAssets", đặt tên theo loại
-- (Car, Tree, Bench, Lamp, Motorbike…). Có thể có nhiều bản: Car, Car2, Car3… → chọn ngẫu nhiên.
-- Nếu không có, video dùng mô hình tự dựng.
function Kit.asset(name, cf, targetLength, seed)
	local lib = ReplicatedStorage:FindFirstChild("PhimAssets")
	if not lib then
		return nil
	end
	local choices = {}
	for _, c in ipairs(lib:GetChildren()) do
		if c.Name == name or c.Name:match("^" .. name .. "%d+$") then
			table.insert(choices, c)
		end
	end
	if #choices == 0 then
		return nil
	end
	local src = choices[((seed or 1) % #choices) + 1]
	local m = src:Clone()
	if m:IsA("BasePart") then
		local wrap = Instance.new("Model")
		m.Parent = wrap
		m = wrap
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m.Parent = Kit.SET
	if targetLength then
		local ext = m:GetExtentsSize()
		local len = math.max(ext.X, ext.Z)
		if len > 0 then
			pcall(function()
				m:ScaleTo(m:GetScale() * targetLength / len)
			end)
		end
	end
	local bb, size = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bb.Position - Vector3.new(0, size.Y / 2, 0)) * m:GetPivot().Rotation
	m:PivotTo(cf)
	if not m.PrimaryPart then
		m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true)
	end
	return m
end

------------------------------------------------------------------------ ÁNH SÁNG & MÀU
local function ensure(className, parent)
	local obj = parent:FindFirstChildOfClass(className) or Instance.new(className)
	obj.Parent = parent
	return obj
end

-- Mỗi "look" = một bảng màu thống nhất: ánh trời (ColorShift), ánh nền, sương theo khoảng cách (tạo chiều sâu),
-- chỉnh màu điện ảnh (ấm ở vùng sáng, lạnh ở vùng tối) và bật/tắt đèn thật trong cảnh.
local LOOKS = {
	morning = { ClockTime = 7.6, Brightness = 2.1, Ambient = "#3a3840", Outdoor = "#8a8fa0", Top = "#ffd9a8", Bottom = "#6a7890", Exposure = -0.25, Density = 0.32, Offset = 0.3, Haze = 1.9, AtmColor = "#f4dcc0", Decay = "#9aa6c0", Glare = 0.35, Tint = "#fff0e0", Sat = 0.12, Contrast = 0.18, Rays = 0.08, Shadow = 0.65, Night = false },
	afternoon = { ClockTime = 16.4, Brightness = 2.0, Ambient = "#3c3634", Outdoor = "#8a8078", Top = "#ffc890", Bottom = "#6a7080", Exposure = -0.3, Density = 0.34, Offset = 0.3, Haze = 2.1, AtmColor = "#f0d0a8", Decay = "#8a90a8", Glare = 0.45, Tint = "#ffe8d0", Sat = 0.14, Contrast = 0.2, Rays = 0.1, Shadow = 0.65, Night = false },
	rain = { ClockTime = 17.2, Brightness = 0.9, Ambient = "#30343e", Outdoor = "#5a6272", Top = "#c8d4e8", Bottom = "#40485a", Exposure = -0.1, Density = 0.45, Offset = 0.15, Haze = 2.6, AtmColor = "#a4b0c2", Decay = "#5a6478", Glare = 0, Tint = "#dce4f4", Sat = -0.08, Contrast = 0.18, Rays = 0, Shadow = 0.6, Night = true },
	night = { ClockTime = 22.5, Brightness = 0.35, Ambient = "#1c2030", Outdoor = "#2a3048", Top = "#9aa8d8", Bottom = "#2a1e18", Exposure = 0.2, Density = 0.3, Offset = 0.2, Haze = 1.2, AtmColor = "#4a5478", Decay = "#141828", Glare = 0, Tint = "#e2e4ff", Sat = 0.05, Contrast = 0.22, Rays = 0, Shadow = 0.4, Night = true },
}

-- Đèn thật trong cảnh: tự bật khi trời tối/mưa (mode "night") hoặc luôn bật ("always").
Kit._practicals = {}
Kit._windows = {}
Kit._isNight = false
function Kit.practical(parent, className, props, mode)
	local l = Instance.new(className)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	-- giới hạn số đèn đổ bóng: quá nhiều đèn có bóng khiến Roblox bật/tắt bóng liên tục (nhấp nháy)
	Kit._shadowLights = (Kit._shadowLights or 0)
	if l.Shadows then
		Kit._shadowLights += 1
		if Kit._shadowLights > 6 then
			l.Shadows = false
		end
	end
	l.Parent = parent
	table.insert(Kit._practicals, { light = l, mode = mode or "night" })
	l.Enabled = (mode == "always") or Kit._isNight
	return l
end
-- cửa sổ: ban đêm một phần sáng đèn vàng ấm
function Kit.windowGlow(part, chance)
	local lit = Random.new(#Kit._windows * 7919 + 13):NextNumber() < (chance or 0.45)
	table.insert(Kit._windows, { part = part, lit = lit, color = part.Color, material = part.Material })
end
local function applyNight(on)
	Kit._isNight = on
	for _, p in ipairs(Kit._practicals) do
		if p.light.Parent then
			p.light.Enabled = p.mode == "always" or on
		end
	end
	for _, w in ipairs(Kit._windows) do
		if w.part.Parent then
			if on and w.lit then
				w.part.Material = Enum.Material.Neon
				w.part.Color = Color3.fromRGB(255, 196, 120)
				w.part.Transparency = 0.35
			else
				w.part.Material = w.material
				w.part.Color = w.color
				w.part.Transparency = 0
			end
		end
	end
end

function Kit.look(name)
	local L = LOOKS[name]
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = L.Shadow
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ClockTime = L.ClockTime
	Lighting.GeographicLatitude = 21 -- Hà Nội
	Lighting.Brightness = L.Brightness
	Lighting.Ambient = hex(L.Ambient)
	Lighting.OutdoorAmbient = hex(L.Outdoor)
	Lighting.ColorShift_Top = hex(L.Top)
	Lighting.ColorShift_Bottom = hex(L.Bottom)
	Lighting.ExposureCompensation = L.Exposure
	local atm = ensure("Atmosphere", Lighting)
	atm.Density, atm.Offset, atm.Haze, atm.Glare = L.Density, L.Offset, L.Haze, L.Glare
	atm.Color, atm.Decay = hex(L.AtmColor), hex(L.Decay)
	local cc = ensure("ColorCorrectionEffect", Lighting)
	cc.TintColor, cc.Saturation, cc.Contrast, cc.Brightness = hex(L.Tint), L.Sat, L.Contrast, 0
	local bloom = ensure("BloomEffect", Lighting)
	bloom.Intensity, bloom.Size, bloom.Threshold = L.Night and 0.8 or 0.3, L.Night and 36 or 28, L.Night and 1.2 or 1.9
	local rays = ensure("SunRaysEffect", Lighting)
	rays.Intensity, rays.Spread = L.Rays, 0.5
	applyNight(L.Night)
end

-- KHÉP KÍN BỐI CẢNH: nền cỏ địa hình thật, vòng nhà cao tầng chi tiết, toà kính, rặng cây, đồi núi xa,
-- tuỳ chọn công viên hồ (opts.lake = góc độ hướng đặt hồ).
local function tree(pos, s, rng)
	s = s or 1
	Kit.cyl("Trunk", 7 * s, 0.9 * s, pos + Vector3.new(0, 3.5 * s, 0), "#5b4636", Enum.Material.Wood, { CanCollide = false })
	local greens = { "#3f6e32", "#4f7d3d", "#5f9248", "#6aa050", "#4a7a3a" }
	for k = 0, 5 do
		local a = k * 1.05 + rng:NextNumber(0, 0.5)
		Kit.ball("Leaves", (3.6 + rng:NextNumber(0, 1.4)) * s, pos + Vector3.new(math.cos(a) * 1.7 * s, (7.5 + (k % 3) * 1.1) * s, math.sin(a) * 1.7 * s), greens[rng:NextInteger(1, #greens)], Enum.Material.Grass, { CanCollide = false })
	end
end
Kit.tree = tree

local function willow(pos, rng)
	Kit.cyl("WillowTrunk", 8, 1, pos + Vector3.new(0, 4, 0), "#4a3a2a", Enum.Material.Wood, { CanCollide = false })
	Kit.ball("WillowCrown", 7, pos + Vector3.new(0, 9, 0), "#7aa84a", Enum.Material.Grass, { CanCollide = false })
	for k = 0, 9 do
		local a = k * 0.63
		Kit.box("WillowStrand", Vector3.new(0.4, rng:NextNumber(4, 7), 1.2), CFrame.new(pos + Vector3.new(math.cos(a) * 3, 6.5, math.sin(a) * 3)) * CFrame.Angles(0, -a, 0), "#8ab85a", Enum.Material.Grass, { CanCollide = false, Transparency = 0.15 })
	end
end

local function pagoda(pos)
	Kit.box("PagodaBase", Vector3.new(10, 2, 10), pos + Vector3.new(0, 1, 0), "#8a8270", Enum.Material.Cobblestone)
	local y = 2
	for lv = 0, 2 do
		local w = 7 - lv * 1.6
		Kit.box("PagodaFloor", Vector3.new(w, 4, w), pos + Vector3.new(0, y + 2, 0), "#c8b89a", Enum.Material.Brick)
		for _, d in ipairs({ -1, 1 }) do
			Kit.box("PagodaArch", Vector3.new(w * 0.4, 2.4, 0.2), pos + Vector3.new(0, y + 1.6, d * (w / 2 + 0.05)), "#3a2a20")
		end
		Kit.box("PagodaRoof", Vector3.new(w + 2.4, 0.6, w + 2.4), pos + Vector3.new(0, y + 4.3, 0), "#7a3a2a", Enum.Material.ClayRoofTiles)
		y += 4.6
	end
	Kit.cyl("PagodaTip", 2.5, 0.5, pos + Vector3.new(0, y + 1.2, 0), "#c8a050", Enum.Material.Metal)
end

function Kit.surround(center, radius, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local T = workspace.Terrain
	-- nền cỏ địa hình (thấp hơn mặt sân 0,5 stud để không chồng lớp)
	pcall(function()
		T:FillBlock(CFrame.new(center + Vector3.new(0, -2.5, 0)), Vector3.new(radius * 3.4, 4, radius * 3.4), Enum.Material.Grass)
		pcall(function()
			T.Decoration = true
		end)
	end)
	-- đồi núi xa
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2 + rng:NextNumber(0, 0.3)
		local r = radius * rng:NextNumber(1.75, 2.1)
		local hr = rng:NextNumber(45, 75)
		pcall(function()
			T:FillBall(center + Vector3.new(math.cos(a) * r, -hr * 0.55, math.sin(a) * r), hr, i % 3 == 0 and Enum.Material.Rock or Enum.Material.Grass)
		end)
	end
	local lakeA = opts.lake
	local function nearLake(a)
		if not lakeA then
			return false
		end
		local d = math.abs((a - lakeA + math.pi) % (2 * math.pi) - math.pi)
		return d < 0.55
	end
	-- vòng nhà cao tầng chi tiết + toà kính
	local n = opts.count or 22
	local cols = opts.colors or { "#d8ccb4", "#bfc8cc", "#e0d4bc", "#b8c4b8", "#d0c0ac", "#e6dccb" }
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		if not nearLake(a) then
			local r = radius + rng:NextNumber(0, radius * 0.2)
			local glass = rng:NextNumber() < 0.3
			local h = glass and rng:NextNumber(70, 115) or rng:NextNumber(28, 60)
			local w = rng:NextNumber(16, 26)
			local p = center + Vector3.new(math.cos(a) * r, h / 2 - 0.5, math.sin(a) * r)
			local cf = CFrame.lookAt(p, Vector3.new(center.X, p.Y, center.Z))
			if glass then
				Kit.box("Tower", Vector3.new(w, h, w * 0.8), cf, "#5d7e9a", Enum.Material.Glass, { CanCollide = false, Reflectance = 0.25 })
				for y = -h / 2 + 5, h / 2 - 2, 7 do
					Kit.box("TowerBand", Vector3.new(w + 0.3, 0.8, w * 0.8 + 0.3), cf * CFrame.new(0, y, 0), "#d8dde2", Enum.Material.Concrete, { CanCollide = false })
				end
				Kit.box("TowerCrown", Vector3.new(w * 0.6, 4, w * 0.5), cf * CFrame.new(0, h / 2 + 2, 0), "#c8ced4", Enum.Material.Metal, { CanCollide = false })
			else
				local col = cols[(i % #cols) + 1]
				Kit.box("FarBuilding", Vector3.new(w, h, w * 0.8), cf, col, Enum.Material.Plaster, { CanCollide = false })
				for y = -h / 2 + 4, h / 2 - 3, 4.5 do
					local band = Kit.box("WinBand", Vector3.new(w - 2, 1.8, 0.2), cf * CFrame.new(0, y, -w * 0.4 - 0.05), "#3d5570", Enum.Material.Glass, { CanCollide = false, Reflectance = 0.2 })
					Kit.windowGlow(band, 0.5)
					Kit.box("Ledge", Vector3.new(w, 0.3, 0.8), cf * CFrame.new(0, y - 1.3, -w * 0.4 - 0.2), "#a8a090", Enum.Material.Concrete, { CanCollide = false })
				end
				Kit.box("Parapet", Vector3.new(w + 0.4, 1.2, w * 0.8 + 0.4), cf * CFrame.new(0, h / 2 + 0.6, 0), col, Enum.Material.Plaster, { CanCollide = false })
				Kit.cyl("RoofTank", 3, 2, cf * CFrame.new(w * 0.2, h / 2 + 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)), "#c8ccd0", Enum.Material.Metal, { CanCollide = false })
			end
		end
	end
	-- rặng cây giữa và sau các toà nhà
	for i = 1, (opts.trees or 34) do
		local a = rng:NextNumber(0, math.pi * 2)
		if not nearLake(a) then
			local r = radius * rng:NextNumber(0.92, 1.55)
			tree(center + Vector3.new(math.cos(a) * r, -0.5, math.sin(a) * r), rng:NextNumber(1.1, 1.8), rng)
		end
	end
	-- công viên hồ có tháp cổ, cầu cong, liễu rủ
	if lakeA then
		local lc = center + Vector3.new(math.cos(lakeA), 0, math.sin(lakeA)) * radius * 1.15
		pcall(function()
			T:FillBlock(CFrame.new(lc + Vector3.new(0, -3, 0)), Vector3.new(radius * 0.9, 5, radius * 0.9), Enum.Material.Air)
			T:FillBlock(CFrame.new(lc + Vector3.new(0, -3.4, 0)), Vector3.new(radius * 0.9, 4.4, radius * 0.9), Enum.Material.Water)
		end)
		pcall(function()
			T.WaterColor = Color3.fromRGB(60, 110, 100)
			T.WaterReflectance = 0.6
			T.WaterTransparency = 0.4
			T.WaterWaveSize = 0.08
			T.WaterWaveSpeed = 6
		end)
		Kit.box("Island", Vector3.new(14, 1.2, 14), lc + Vector3.new(0, -1, 0), "#6a8a4a", Enum.Material.Grass)
		pagoda(lc + Vector3.new(0, -0.4, 0))
		local toCenter = (center - lc).Unit
		local side = toCenter:Cross(Vector3.yAxis)
		for k = 0, 9 do
			local t = k / 9
			local pos = lc + toCenter * (8 + t * 26) + Vector3.new(0, math.sin(t * math.pi) * 3, 0)
			Kit.box("Bridge", Vector3.new(4, 0.6, 3.2), CFrame.lookAt(pos, pos + toCenter) * CFrame.Angles(math.rad(-math.cos(t * math.pi) * 20), 0, 0), "#b83a2a", Enum.Material.Wood)
		end
		for k = 0, 7 do
			local ang = k / 8 * math.pi * 2
			willow(lc + Vector3.new(math.cos(ang), 0, math.sin(ang)) * radius * 0.5 + Vector3.new(0, -0.5, 0), rng)
		end
	end
end

------------------------------------------------------------------------ TRANG PHỤC
-- Mỗi bộ: top (tee/shirt/polo/hoodie/jacket/cardigan/blouse/aodai/baba), sleeves (short/long),
-- bottom (shorts/pants/jeans/skirt/longskirt/aodaipants), màu, giày, phụ kiện.
Kit.OUTFITS = {
	-- nam
	minh_ao_so_mi = { top = "shirt", sleeves = "short", topColor = "#e9eef2", stripe = "#9fb3c8", bottom = "pants", bottomColor = "#3a4250", shoes = "#f2f2f2", acc = { "backpack", "watch" } },
	minh_ao_phong = { top = "tee", sleeves = "short", topColor = "#2f3540", bottom = "jeans", bottomColor = "#4a5d78", shoes = "#e8e8e8", acc = {} },
	minh_ao_ngu = { top = "tee", sleeves = "short", topColor = "#8b8e92", bottom = "shorts", bottomColor = "#5a5d62", shoes = "#425850", acc = {} },
	khoa_hoodie = { top = "hoodie", sleeves = "long", topColor = "#c94a3c", bottom = "shorts", bottomColor = "#26292e", shoes = "#f2f2f2", acc = { "headphones" } },
	-- nữ
	an_vay_trang = { top = "blouse", sleeves = "short", topColor = "#f6f3ec", bottom = "skirt", bottomColor = "#f6f3ec", shoes = "#d9c8b4", acc = { "earbuds", "tote" } },
	an_ao_dai = { top = "aodai", sleeves = "long", topColor = "#f7f5f0", bottom = "aodaipants", bottomColor = "#ffffff", shoes = "#e8dccb", acc = {} },
	an_cardigan = { top = "cardigan", sleeves = "long", topColor = "#f1e6d6", jacketColor = "#b7c7a5", bottom = "longskirt", bottomColor = "#6f5a4a", shoes = "#f2f2f2", acc = { "earbuds" } },
	linh_ao_bo = { top = "jacket", sleeves = "long", topColor = "#f2f2f2", jacketColor = "#5677a0", bottom = "jeans", bottomColor = "#2b2f38", shoes = "#1d1d1d", acc = { "glasses", "tote" } },
	-- trung niên
	co_hoa_ba_ba = { top = "baba", sleeves = "long", topColor = "#8a6a44", bottom = "pants", bottomColor = "#1e1f22", shoes = "#e8e4dc", acc = { "nonla", "apron" } },
	phuc_vu = { top = "polo", sleeves = "short", topColor = "#2f4a3a", bottom = "pants", bottomColor = "#222222", shoes = "#111111", acc = { "apron" } },
}

local LIMBS = {
	torso = { "UpperTorso" },
	upperArms = { "LeftUpperArm", "RightUpperArm" },
	lowerArms = { "LeftLowerArm", "RightLowerArm" },
	hands = { "LeftHand", "RightHand" },
	hips = { "LowerTorso" },
	upperLegs = { "LeftUpperLeg", "RightUpperLeg" },
	lowerLegs = { "LeftLowerLeg", "RightLowerLeg" },
	feet = { "LeftFoot", "RightFoot" },
}

local function paint(model, group, color)
	for _, n in ipairs(LIMBS[group]) do
		local p = model:FindFirstChild(n)
		if p then
			p.Color = color
		end
	end
end

-- gắn một khối phụ vào một bộ phận cơ thể (offset tính theo kích thước bộ phận)
local function attach(folder, limb, name, sizeMul, offsetMul, color, extra)
	local s = limb.Size
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(s.X * sizeMul.X, s.Y * sizeMul.Y, s.Z * sizeMul.Z)
	p.Color = typeof(color) == "string" and hex(color) or color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if extra then
		for k, v in pairs(extra) do
			if k ~= "rot" then
				p[k] = v
			end
		end
	end
	p.CFrame = limb.CFrame * CFrame.new(s.X * offsetMul.X, s.Y * offsetMul.Y, s.Z * offsetMul.Z) * (extra and extra.rot or CFrame.new())
	p.Parent = folder
	Kit.weld(limb, p)
	return p
end

local ACCESSORIES = {
	backpack = function(f, m)
		attach(f, m.UpperTorso, "Backpack", Vector3.new(0.8, 0.85, 0.5), Vector3.new(0, -0.05, 0.72), "#2d3a4a")
		attach(f, m.UpperTorso, "StrapL", Vector3.new(0.12, 0.9, 1.08), Vector3.new(-0.28, 0, 0), "#2d3a4a")
		attach(f, m.UpperTorso, "StrapR", Vector3.new(0.12, 0.9, 1.08), Vector3.new(0.28, 0, 0), "#2d3a4a")
	end,
	tote = function(f, m)
		attach(f, m.UpperTorso, "ToteStrap", Vector3.new(0.1, 1.0, 1.06), Vector3.new(0.33, -0.05, 0), "#c9b38f", { rot = CFrame.Angles(0, 0, rad(-12)) })
		attach(f, m.LowerTorso, "ToteBag", Vector3.new(0.6, 1.8, 0.7), Vector3.new(0.78, -0.1, 0), "#d8c6a2")
	end,
	watch = function(f, m)
		attach(f, m.LeftLowerArm, "Watch", Vector3.new(1.12, 0.12, 1.12), Vector3.new(0, -0.35, 0), "#1d1d1d")
	end,
	glasses = function(f, m)
		local h = m.Head
		attach(f, h, "GlassL", Vector3.new(0.24, 0.16, 0.04), Vector3.new(-0.17, 0.05, -0.52), "#1a1a1a", { Transparency = 0.35 })
		attach(f, h, "GlassR", Vector3.new(0.24, 0.16, 0.04), Vector3.new(0.17, 0.05, -0.52), "#1a1a1a", { Transparency = 0.35 })
		attach(f, h, "Bridge", Vector3.new(0.12, 0.03, 0.04), Vector3.new(0, 0.08, -0.52), "#1a1a1a")
	end,
	headphones = function(f, m)
		local h = m.Head
		attach(f, h, "Band", Vector3.new(1.15, 0.08, 0.15), Vector3.new(0, 0.55, 0), "#e6e6e6")
		attach(f, h, "CupL", Vector3.new(0.15, 0.35, 0.35), Vector3.new(-0.56, 0.05, 0), "#e6e6e6")
		attach(f, h, "CupR", Vector3.new(0.15, 0.35, 0.35), Vector3.new(0.56, 0.05, 0), "#e6e6e6")
	end,
	earbuds = function(f, m)
		attach(f, m.Head, "BudL", Vector3.new(0.08, 0.1, 0.08), Vector3.new(-0.52, 0, 0), "#ffffff")
		attach(f, m.Head, "BudR", Vector3.new(0.08, 0.1, 0.08), Vector3.new(0.52, 0, 0), "#ffffff")
	end,
	apron = function(f, m)
		attach(f, m.LowerTorso, "Apron", Vector3.new(0.95, 2.4, 0.08), Vector3.new(0, -0.6, -0.56), "#a89f91")
	end,
	nonla = function(f, m) -- nón lá: các vòng trụ nhỏ dần
		local h = m.Head
		for i = 0, 4 do
			local d = 2.6 - i * 0.55
			attach(f, h, "NonLa" .. i, Vector3.new(0.12, d / h.Size.Y, d / h.Size.Z), Vector3.new(0, 0.55 + i * 0.13, 0), "#d4b270", {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.14, d, d),
				rot = CFrame.Angles(0, 0, rad(90)),
			})
		end
	end,
}

local function clearOutfit(a)
	local f = a.model:FindFirstChild("Outfit")
	if f then
		f:Destroy()
	end
end

function Kit.dress(a, outfit)
	local o = typeof(outfit) == "string" and Kit.OUTFITS[outfit] or outfit
	assert(o, "Không có bộ đồ: " .. tostring(outfit))
	clearOutfit(a)
	local m = a.model
	local f = Instance.new("Folder")
	f.Name = "Outfit"
	f.Parent = m
	local skin = a.skin
	local top, bottom = hex(o.topColor), hex(o.bottomColor)
	local jacket = o.jacketColor and hex(o.jacketColor)
	local long = o.sleeves == "long"
	local armColor = jacket or top

	paint(m, "torso", top)
	paint(m, "upperArms", armColor)
	paint(m, "lowerArms", long and armColor or skin)
	paint(m, "hands", skin)
	paint(m, "hips", bottom)
	local bareLegs = o.bottom == "shorts" or o.bottom == "skirt"
	paint(m, "upperLegs", o.bottom == "skirt" and skin or bottom)
	paint(m, "lowerLegs", bareLegs and skin or bottom)
	paint(m, "feet", hex(o.shoes))

	local T = m.UpperTorso
	local light = top:Lerp(Color3.new(1, 1, 1), 0.3)
	local darker = top:Lerp(Color3.new(0, 0, 0), 0.25)
	if o.top == "tee" then
		attach(f, T, "Neck", Vector3.new(0.38, 0.06, 0.6), Vector3.new(0, 0.49, -0.05), darker)
	elseif o.top == "shirt" or o.top == "polo" then
		attach(f, T, "CollarL", Vector3.new(0.22, 0.12, 0.25), Vector3.new(-0.12, 0.47, -0.38), light, { rot = CFrame.Angles(0, 0, rad(20)) })
		attach(f, T, "CollarR", Vector3.new(0.22, 0.12, 0.25), Vector3.new(0.12, 0.47, -0.38), light, { rot = CFrame.Angles(0, 0, rad(-20)) })
		attach(f, T, "Placket", Vector3.new(0.06, o.top == "polo" and 0.3 or 0.95, 0.04), Vector3.new(0, o.top == "polo" and 0.3 or 0, -0.51), darker)
		if o.stripe then
			for i = -2, 2 do
				attach(f, T, "Stripe", Vector3.new(0.04, 0.96, 0.03), Vector3.new(i * 0.18, 0, -0.505), o.stripe)
			end
		end
	elseif o.top == "hoodie" then
		attach(f, T, "Hood", Vector3.new(0.7, 0.35, 0.45), Vector3.new(0, 0.55, 0.45), darker)
		attach(f, T, "Pocket", Vector3.new(0.6, 0.3, 0.05), Vector3.new(0, -0.3, -0.52), darker)
		attach(f, T, "StringL", Vector3.new(0.04, 0.3, 0.04), Vector3.new(-0.08, 0.25, -0.52), "#f2f2f2")
		attach(f, T, "StringR", Vector3.new(0.04, 0.3, 0.04), Vector3.new(0.08, 0.25, -0.52), "#f2f2f2")
	elseif o.top == "jacket" or o.top == "cardigan" then
		local c = jacket or darker
		attach(f, T, "PanelL", Vector3.new(0.36, 1.02, 1.08), Vector3.new(-0.33, 0, 0), c)
		attach(f, T, "PanelR", Vector3.new(0.36, 1.02, 1.08), Vector3.new(0.33, 0, 0), c)
		attach(f, T, "Back", Vector3.new(1.04, 1.02, 0.1), Vector3.new(0, 0, 0.5), c)
		if o.top == "jacket" then
			attach(f, T, "LapelL", Vector3.new(0.15, 0.3, 0.05), Vector3.new(-0.17, 0.33, -0.54), c:Lerp(Color3.new(0, 0, 0), 0.2), { rot = CFrame.Angles(0, 0, rad(25)) })
			attach(f, T, "LapelR", Vector3.new(0.15, 0.3, 0.05), Vector3.new(0.17, 0.33, -0.54), c:Lerp(Color3.new(0, 0, 0), 0.2), { rot = CFrame.Angles(0, 0, rad(-25)) })
		end
	elseif o.top == "blouse" then
		attach(f, T, "Ruffle", Vector3.new(0.6, 0.1, 0.62), Vector3.new(0, 0.47, -0.08), light)
		attach(f, T, "Bow", Vector3.new(0.18, 0.1, 0.05), Vector3.new(0, 0.38, -0.52), "#c98a82")
	elseif o.top == "aodai" then -- áo dài: cổ đứng + hai vạt trước/sau dài tới bắp chân
		local hips = m.LowerTorso
		attach(f, T, "StandCollar", Vector3.new(0.35, 0.12, 0.55), Vector3.new(0, 0.53, -0.05), top)
		attach(f, hips, "FlapFront", Vector3.new(0.75, 4.2, 0.06), Vector3.new(0, -1.9, -0.55), top)
		attach(f, hips, "FlapBack", Vector3.new(0.75, 4.2, 0.06), Vector3.new(0, -1.9, 0.55), top)
		attach(f, T, "Pattern", Vector3.new(0.25, 0.25, 0.03), Vector3.new(0.18, 0.15, -0.51), "#d9b8c4")
	elseif o.top == "baba" then -- áo bà ba
		attach(f, T, "Hem", Vector3.new(1.02, 0.4, 1.04), Vector3.new(0, -0.55, 0), top)
		for i = 0, 2 do
			attach(f, T, "Button", Vector3.new(0.05, 0.05, 0.03), Vector3.new(0.12, 0.3 - i * 0.3, -0.51), "#e8e0d0")
		end
	end

	if o.bottom == "skirt" or o.bottom == "longskirt" then
		local hips = m.LowerTorso
		local len = o.bottom == "skirt" and 1.9 or 4.4
		attach(f, hips, "Skirt", Vector3.new(1.3, len, 1.5), Vector3.new(0, -len / 2 + 0.1, 0), bottom)
	elseif o.bottom == "jeans" then
		for _, n in ipairs({ "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }) do
			attach(f, m[n], "Seam", Vector3.new(0.05, 1, 0.05), Vector3.new(0, 0, -0.5), bottom:Lerp(Color3.new(1, 1, 1), 0.2))
		end
	end

	-- chi tiết: đế giày, thắt lưng, cổ tay áo
	for _, n in ipairs({ "LeftFoot", "RightFoot" }) do
		attach(f, m[n], "Sole", Vector3.new(1.08, 0.28, 1.1), Vector3.new(0, -0.42, -0.02), o.sole or "#f2f2f2")
		attach(f, m[n], "Lace", Vector3.new(0.5, 0.12, 0.4), Vector3.new(0, 0.3, -0.35), hex(o.shoes):Lerp(Color3.new(1, 1, 1), 0.5))
	end
	if o.bottom == "pants" or o.bottom == "jeans" or o.bottom == "shorts" then
		attach(f, m.LowerTorso, "Belt", Vector3.new(1.05, 0.16, 1.07), Vector3.new(0, 0.38, 0), o.belt or "#2a2420")
		attach(f, m.LowerTorso, "Buckle", Vector3.new(0.18, 0.18, 0.05), Vector3.new(0, 0.38, -0.55), "#c8b070", { Material = Enum.Material.Metal })
	end
	if long then
		for _, n in ipairs({ "LeftLowerArm", "RightLowerArm" }) do
			attach(f, m[n], "Cuff", Vector3.new(1.1, 0.12, 1.1), Vector3.new(0, -0.44, 0), armColor:Lerp(Color3.new(0, 0, 0), 0.2))
		end
	else
		for _, n in ipairs({ "LeftUpperArm", "RightUpperArm" }) do
			attach(f, m[n], "SleeveHem", Vector3.new(1.1, 0.1, 1.1), Vector3.new(0, -0.3, 0), armColor:Lerp(Color3.new(0, 0, 0), 0.2))
		end
	end
	for _, accName in ipairs(o.acc or {}) do
		local build = ACCESSORIES[accName]
		if build then
			build(f, m)
		end
	end
	a.outfit = outfit
	Kit.noShadow(a)
end

------------------------------------------------------------------------ TÓC
local function hairPart(head, folder, name, size, offset, color, shape, rot)
	local p = Instance.new("Part")
	p.Name = "Hair_" .. name
	p.Size = size
	p.Shape = shape or Enum.PartType.Block
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.CFrame = head.CFrame * CFrame.new(offset) * (rot or CFrame.new())
	p.Parent = folder
	Kit.weld(head, p)
	return p
end

local HAIR = {}
HAIR.short = function(h, f, c, w, hh, d)
	hairPart(h, f, "Back", Vector3.new(w * 1.04, hh * 0.55, d * 0.25), Vector3.new(0, hh * 0.18, d * 0.43), c)
	hairPart(h, f, "Fringe", Vector3.new(w * 0.95, hh * 0.12, d * 0.14), Vector3.new(0, hh * 0.4, -d * 0.47), c)
end
HAIR.curtain = function(h, f, c, w, hh, d) -- mái chia ngôi giữa
	HAIR.short(h, f, c, w, hh, d)
	for k = -1, 1 do -- phồng đỉnh đầu
		hairPart(h, f, "Volume" .. k, Vector3.new(w * 0.4, hh * 0.22, d * 0.5), Vector3.new(w * k * 0.28, hh * 0.58, d * 0.05), c:Lerp(Color3.new(1, 1, 1), 0.04 * (k + 1)), nil, CFrame.Angles(rad(-10), 0, rad(-k * 12)))
	end
	hairPart(h, f, "BangL", Vector3.new(w * 0.42, hh * 0.2, d * 0.14), Vector3.new(-w * 0.24, hh * 0.34, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(-18)))
	hairPart(h, f, "BangR", Vector3.new(w * 0.42, hh * 0.2, d * 0.14), Vector3.new(w * 0.24, hh * 0.34, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(18)))
	hairPart(h, f, "SideL", Vector3.new(w * 0.12, hh * 0.42, d * 0.8), Vector3.new(-w * 0.5, hh * 0.18, 0.05), c)
	hairPart(h, f, "SideR", Vector3.new(w * 0.12, hh * 0.42, d * 0.8), Vector3.new(w * 0.5, hh * 0.18, 0.05), c)
end
HAIR.spiky = function(h, f, c, w, hh, d)
	hairPart(h, f, "Back", Vector3.new(w * 1.04, hh * 0.4, d * 0.25), Vector3.new(0, hh * 0.25, d * 0.44), c)
	for i = 0, 5 do
		local x = (i % 3 - 1) * 0.28
		local z = (i < 3) and -0.18 or 0.18
		hairPart(h, f, "Spike" .. i, Vector3.new(w * 0.22, hh * 0.42, d * 0.22), Vector3.new(w * x, hh * 0.66, d * z), c, nil, CFrame.Angles(rad(z * 60 - 20), 0, rad(-x * 50)))
	end
end
HAIR.long = function(h, f, c, w, hh, d) -- tóc dài thẳng ngang lưng
	for k = -2, 2 do -- lọn tóc sau lưng
		hairPart(h, f, "Strand" .. k, Vector3.new(w * 0.22, hh * 1.9, d * 0.12), Vector3.new(w * k * 0.2, -hh * 0.5, d * 0.62), c:Lerp(Color3.new(0, 0, 0), (k % 2) * 0.12), nil, CFrame.Angles(rad(6), 0, rad(k * 2)))
	end
	hairPart(h, f, "Back", Vector3.new(w * 1.1, hh * 2.1, d * 0.3), Vector3.new(0, -hh * 0.45, d * 0.45), c)
	hairPart(h, f, "SideL", Vector3.new(w * 0.14, hh * 1.3, d * 0.75), Vector3.new(-w * 0.52, -hh * 0.1, 0.05), c)
	hairPart(h, f, "SideR", Vector3.new(w * 0.14, hh * 1.3, d * 0.75), Vector3.new(w * 0.52, -hh * 0.1, 0.05), c)
	hairPart(h, f, "BangL", Vector3.new(w * 0.5, hh * 0.18, d * 0.12), Vector3.new(-w * 0.22, hh * 0.37, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(-12)))
	hairPart(h, f, "BangR", Vector3.new(w * 0.4, hh * 0.15, d * 0.12), Vector3.new(w * 0.27, hh * 0.39, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(10)))
end
HAIR.bob = function(h, f, c, w, hh, d) -- tóc bob ôm cằm (Linh)
	hairPart(h, f, "Back", Vector3.new(w * 1.1, hh * 0.95, d * 0.32), Vector3.new(0, 0, d * 0.42), c)
	hairPart(h, f, "SideL", Vector3.new(w * 0.16, hh * 0.9, d * 0.85), Vector3.new(-w * 0.52, 0, 0.05), c)
	hairPart(h, f, "SideR", Vector3.new(w * 0.16, hh * 0.9, d * 0.85), Vector3.new(w * 0.52, 0, 0.05), c)
	hairPart(h, f, "Fringe", Vector3.new(w * 0.98, hh * 0.15, d * 0.12), Vector3.new(0, hh * 0.38, -d * 0.48), c)
end
HAIR.ponytail = function(h, f, c, w, hh, d)
	HAIR.short(h, f, c, w, hh, d)
	hairPart(h, f, "Tie", Vector3.new(w * 0.25, w * 0.25, w * 0.25), Vector3.new(0, hh * 0.25, d * 0.6), c, Enum.PartType.Ball)
	hairPart(h, f, "Tail", Vector3.new(w * 0.28, hh * 1.1, d * 0.25), Vector3.new(0, -hh * 0.3, d * 0.68), c, nil, CFrame.Angles(rad(12), 0, 0))
end
HAIR.bun = function(h, f, c, w, hh, d)
	hairPart(h, f, "Back", Vector3.new(w * 1.06, hh * 0.85, d * 0.32), Vector3.new(0, hh * 0.08, d * 0.4), c)
	hairPart(h, f, "SideL", Vector3.new(w * 0.12, hh * 0.6, d * 0.8), Vector3.new(-w * 0.5, hh * 0.12, 0.08), c)
	hairPart(h, f, "SideR", Vector3.new(w * 0.12, hh * 0.6, d * 0.8), Vector3.new(w * 0.5, hh * 0.12, 0.08), c)
	hairPart(h, f, "Bun", Vector3.new(w * 0.55, w * 0.55, w * 0.55), Vector3.new(0, hh * 0.45, d * 0.6), c, Enum.PartType.Ball)
end

function Kit.hair(a, style, color)
	local old = a.model:FindFirstChild("Hair")
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Hair"
	f.Parent = a.model
	local h = a.head
	local s = h.Size
	local c = typeof(color) == "string" and hex(color) or color
	hairPart(h, f, "Cap", Vector3.new(s.X * 1.08, s.Y * 0.32, s.Z * 1.08), Vector3.new(0, s.Y * 0.42, 0.02), c)
	if HAIR[style] then
		HAIR[style](h, f, c, s.X, s.Y, s.Z)
	end
end

------------------------------------------------------------------------ NHÂN VẬT (máy người xem)
local ANIM = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	sit = "rbxassetid://2506281703",
}

function Kit.actor(name, spec)
	local rigs = ReplicatedStorage:WaitForChild("PhimRigs")
	while not rigs:GetAttribute("Ready") do
		task.wait(0.2)
	end
	local src = rigs:WaitForChild(name, 30)
	assert(src, "Thiếu khung nhân vật: " .. name)
	local model = src:Clone()
	local custom = model:GetAttribute("Custom") == true
	local head = model:WaitForChild("Head")
	cleanHead(head)
	local hum = model:FindFirstChildOfClass("Humanoid")
	pcall(function()
		hum.EvaluateStateMachine = false -- tắt vật lý của Humanoid: không ngã, không trượt
	end)
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.RequiresNeck = false
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			if custom then
				p.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true

	-- tấm mặt: mắt / mày / miệng / nốt ruồi / nước mắt (vẽ trên máy người xem)
	-- tấm giữ thông tin khuôn mặt (biểu cảm, hướng nhìn…); mặt 3D được dựng ở máy người xem
	local plate = Instance.new("Part")
	plate.Name = "FacePlate"
	plate.Transparency = 1
	plate.Size = Vector3.new(0.1, 0.1, 0.1)
	plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.Massless, plate.CastShadow = false, false, false, true, false
	plate.CFrame = head.CFrame
	plate.Parent = model
	Kit.weld(head, plate)
	plate:SetAttribute("Expression", "neutral")
	plate:SetAttribute("Talking", false)
	plate:SetAttribute("Mole", spec.mole or "")
	plate:SetAttribute("Skin", spec.skin or "#f0cbb2")
	plate:SetAttribute("BrowColor", spec.hairColor or "#1e1a18")
	plate:SetAttribute("Female", spec.female == true)
	plate:SetAttribute("Lips", spec.lips or "")
	plate:SetAttribute("Gaze", Vector2.zero)
	plate:SetAttribute("Tears", false)
	plate:SetAttribute("EyeColor", spec.eyeColor or "#3a2418")

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	model.Parent = Kit.ACTORS
	local tracks = {}
	for k, id in pairs(ANIM) do
		local an = Instance.new("Animation")
		an.AnimationId = id
		local ok, tr = pcall(function()
			return animator:LoadAnimation(an)
		end)
		if ok then
			tr.Looped = true
			tracks[k] = tr
		end
	end
	local joints = {}
	for _, mo in ipairs(model:GetDescendants()) do
		if mo:IsA("Motor6D") then
			joints[mo.Name] = { motor = mo, c0 = mo.C0 }
		end
	end
	local a = {
		name = name,
		model = model,
		hum = hum,
		root = root,
		head = head,
		face = plate,
		tracks = tracks,
		joints = joints,
		skin = hex(spec.skin or "#f0cbb2"),
		standY = hum.HipHeight + root.Size.Y / 2,
	}
	if custom then
		if not model:GetAttribute("HasHair") then
			Kit.hair(a, spec.hair, spec.hairColor)
		end
		if not model:GetAttribute("HasClothes") then
			Kit.dress(a, spec.outfit)
		end
		-- tai
		for _, sx in ipairs({ -1, 1 }) do
			local ear = Instance.new("Part")
			ear.Name = "Ear"
			ear.Size = Vector3.new(0.12, head.Size.Y * 0.28, head.Size.Z * 0.22)
			ear.Color = a.skin
			ear.Material = Enum.Material.SmoothPlastic
			ear.CanCollide, ear.CanQuery, ear.CanTouch, ear.Massless = false, false, false, true
			ear.CFrame = head.CFrame * CFrame.new(sx * head.Size.X * 0.5, -head.Size.Y * 0.02, 0)
			ear.Parent = model
			Kit.weld(head, ear)
		end
	elseif spec.outfit and spec.forceOutfit then
		Kit.dress(a, spec.outfit)
	end
	Kit.noShadow(a)
	-- vệt bóng mềm dưới chân (thay cho bóng thật vốn bị giật khi nhân vật chuyển động)
	local blob = Instance.new("Part")
	blob.Name = "BlobShadow"
	blob.Shape = Enum.PartType.Cylinder
	blob.Size = Vector3.new(0.05, 3, 3)
	blob.Color = Color3.new(0, 0, 0)
	blob.Material = Enum.Material.SmoothPlastic
	blob.Transparency = 1
	blob.Anchored = true
	blob.CanCollide, blob.CanQuery, blob.CanTouch, blob.CastShadow = false, false, false, false
	blob.Parent = Kit.SET
	a.blob = blob
	Kit.A[name] = a
	model.Parent = nil
	return a
end

-- tắt bóng thật của mọi bộ phận nhân vật (tóc, quần áo, phụ kiện)
function Kit.noShadow(a)
	for _, p in ipairs(a.model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CastShadow = false
		end
	end
end

-- cập nhật vệt bóng mỗi khung hình
local blobParams = RaycastParams.new()
blobParams.FilterType = Enum.RaycastFilterType.Exclude
blobParams.RespectCanCollide = true -- bỏ qua vạch kẻ, ron gạch mỏng (không va chạm)
function Kit._updateBlobs()
	local ignore = { Kit.ACTORS }
	for _, a in pairs(Kit.A) do
		if a.blob then
			table.insert(ignore, a.blob)
		end
	end
	blobParams.FilterDescendantsInstances = ignore
	for _, a in pairs(Kit.A) do
		local b = a.blob
		if b then
			if a.model.Parent == nil then
				b.Transparency = 1
			else
				local root = a.root.Position
				local hit = workspace:Raycast(root, Vector3.new(0, -40, 0), blobParams)
				if hit then
					local h = math.max(0, (root.Y - hit.Position.Y) - a.standY)
					local k = math.clamp(1 - h / 14, 0.25, 1)
					local d = 3.2 * (a.model:GetExtentsSize().X > 4 and 1.3 or 1) * (0.6 + 0.4 * k)
					-- chỉ đi theo mặt sàn thật, làm mượt độ cao để không nhảy giữa hai lớp
					local gy = hit.Position.Y
					if a._blobY and math.abs(gy - a._blobY) < 0.5 then
						gy = a._blobY + (gy - a._blobY) * 0.15
					end
					a._blobY = gy
					b.Size = Vector3.new(0.05, d, d)
					b.CFrame = CFrame.new(Vector3.new(root.X, gy + 0.12, root.Z)) * CFrame.Angles(0, 0, math.rad(90))
					b.Transparency = 1 - 0.35 * k
				else
					b.Transparency = 1
				end
			end
		end
	end
end

------------------------------------------------------------------------ DIỄN XUẤT (mượt, không vật lý)
function Kit.tw(obj, t, props, style, dir)
	local tween = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut), props)
	tween:Play()
	return tween
end

function Kit.anim(a, name, fade, speed)
	for k, tr in pairs(a.tracks) do
		if k ~= name and tr.IsPlaying then
			tr:Stop(fade or 0.25)
		end
	end
	local tr = a.tracks[name]
	if tr then
		if not tr.IsPlaying then
			tr:Play(fade or 0.25)
		end
		tr:AdjustSpeed(speed or 1)
	end
end

function Kit.glide(a, cf, t, style)
	if not t or t <= 0 then
		a.model:PivotTo(cf)
		return
	end
	local v = Instance.new("CFrameValue")
	v.Value = a.model:GetPivot()
	local conn = v.Changed:Connect(function(c)
		a.model:PivotTo(c)
	end)
	Kit.tw(v, t, { Value = cf }, style).Completed:Wait()
	conn:Disconnect()
	v:Destroy()
end

local function flatLook(pos, target)
	local t = Vector3.new(target.X, pos.Y, target.Z)
	if (t - pos).Magnitude < 0.01 then
		t = pos + Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(pos, t)
end

function Kit.stand(a, pos, lookAt)
	a.model.Parent = Kit.ACTORS
	Kit.anim(a, "idle")
	local p = Vector3.new(pos.X, pos.Y + a.standY, pos.Z)
	Kit.glide(a, flatLook(p, lookAt or (p + Vector3.new(0, 0, -1))), 0)
end

function Kit.sit(a, pos, seatTop, lookAt, t)
	a.model.Parent = Kit.ACTORS
	Kit.anim(a, "sit", 0.3)
	local p = Vector3.new(pos.X, seatTop + a.standY * 0.42, pos.Z)
	Kit.glide(a, flatLook(p, lookAt), t or 0)
end

function Kit.hide(a)
	a.model.Parent = nil
end

function Kit.turn(a, target, t)
	Kit.glide(a, flatLook(a.root.Position, target), t or 0.5)
end

-- đi bộ: pos là 1 điểm hoặc danh sách điểm (mặt đất). Trượt mượt + animation bước chân.
function Kit.walk(a, pos, speed)
	a.model.Parent = Kit.ACTORS
	speed = speed or 6
	local pts = typeof(pos) == "Vector3" and { pos } or pos
	-- chu kỳ bước đi tự dựng: chân bước, gối gập, tay vung ngược chân
	for _, tr in pairs(a.tracks) do
		tr:Stop(0.2)
	end
	a.busy = true
	local walking = true
	task.spawn(function()
		local phase = 0
		local J = a.joints
		local amp = math.clamp(speed / 7, 0.4, 1.3)
		while walking do
			local dt = RunService.Heartbeat:Wait()
			phase += dt * speed * 1.15
			local sn = math.sin(phase)
			local function set(name, x)
				local j = J[name]
				if j then
					j.motor.C0 = j.c0 * CFrame.Angles(rad(x), 0, 0)
				end
			end
			set("RightHip", 28 * sn * amp)
			set("LeftHip", -28 * sn * amp)
			set("RightKnee", -math.max(0, -sn) * 45 * amp)
			set("LeftKnee", -math.max(0, sn) * 45 * amp)
			if not a.posed then
				set("RightShoulder", -22 * sn * amp)
				set("LeftShoulder", 22 * sn * amp)
				set("RightElbow", 15 + 10 * math.max(0, sn) * amp)
				set("LeftElbow", 15 + 10 * math.max(0, -sn) * amp)
			end
			set("Waist", -3 * amp)
		end
		for _, n in ipairs({ "RightHip", "LeftHip", "RightKnee", "LeftKnee", "Waist" }) do
			if J[n] then
				Kit.tw(J[n].motor, 0.25, { C0 = J[n].c0 })
			end
		end
		if not a.posed then
			for _, n in ipairs({ "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow" }) do
				if J[n] then
					Kit.tw(J[n].motor, 0.25, { C0 = J[n].c0 })
				end
			end
		end
	end)
	for _, p in ipairs(pts) do
		local to = Vector3.new(p.X, p.Y + a.standY, p.Z)
		local from = a.root.Position
		local dist = (to - from).Magnitude
		if dist > 0.05 then
			local face = flatLook(from, to)
			Kit.glide(a, face, 0.2)
			Kit.glide(a, flatLook(to, to + face.LookVector), dist / speed, Enum.EasingStyle.Linear)
		end
	end
	walking = false
	a.busy = false
	Kit.anim(a, "idle", 0.3)
end

Kit.POSES = {
	rest = {},
	holdFlowers = { RightShoulder = { 35, 0, 10 }, RightElbow = { 70, 0, 0 }, LeftShoulder = { 30, 0, -5 }, LeftElbow = { 65, 0, 0 } },
	offer = { RightShoulder = { 70, 0, 5 }, LeftShoulder = { 70, 0, -5 }, RightElbow = { 15, 0, 0 }, LeftElbow = { 15, 0, 0 } },
	phoneLook = { RightShoulder = { 40, 0, 10 }, RightElbow = { 75, 0, 0 } },
	phoneEar = { RightShoulder = { 25, 0, -35 }, RightElbow = { 140, 0, 0 } },
	handsOnTable = { RightShoulder = { 45, 0, 10 }, LeftShoulder = { 45, 0, -10 }, RightElbow = { 35, 0, 0 }, LeftElbow = { 35, 0, 0 } },
	reach = { RightShoulder = { 80, 0, 0 } },
	wave = { RightShoulder = { 160, 0, 15 }, RightElbow = { 20, 0, 0 } },
	scratchHead = { RightShoulder = { 140, 0, 30 }, RightElbow = { 120, 0, 0 } },
	touchEar = { LeftShoulder = { 120, 0, 25 }, LeftElbow = { 130, 0, 0 } },
	hugSelf = { RightShoulder = { 50, 0, 40 }, LeftShoulder = { 50, 0, -40 }, RightElbow = { 100, 0, 0 }, LeftElbow = { 100, 0, 0 } },
	crossArms = { RightShoulder = { 45, 0, 30 }, LeftShoulder = { 45, 0, -30 }, RightElbow = { 95, 0, 0 }, LeftElbow = { 95, 0, 0 } },
	gameHold = { RightShoulder = { 40, 0, 15 }, LeftShoulder = { 40, 0, -15 }, RightElbow = { 75, 0, 0 }, LeftElbow = { 75, 0, 0 } },
	point = { RightShoulder = { 88, 0, 0 } },
	sellFlowers = { RightShoulder = { 60, 0, 0 }, RightElbow = { 40, 0, 0 } },
}
function Kit.pose(a, name, t, wait)
	a.posed = name ~= "rest" and Kit.POSES[name] ~= nil and next(Kit.POSES[name]) ~= nil
	local p = Kit.POSES[name] or {}
	for jointName, j in pairs(a.joints) do
		if jointName:find("Shoulder") or jointName:find("Elbow") then
			local r = p[jointName]
			local goal = r and (j.c0 * CFrame.Angles(rad(r[1]), rad(r[2]), rad(r[3]))) or j.c0
			Kit.tw(j.motor, t or 0.4, { C0 = goal })
		end
	end
	if wait ~= false then
		task.wait(t or 0.4)
	end
end

-- CỬ CHỈ: chuỗi tư thế (Neck, Waist, vai, khuỷu). Mỗi bước = { thời gian, { Khớp = {xoayX, xoayY, xoayZ, nângY} } }
-- Neck: X dương = ngửa lên, âm = cúi; Y = quay trái/phải. Waist: X âm = cúi người tới trước.
local function seqRepeat(steps, n)
	local out = {}
	for _ = 1, n do
		for _, st in ipairs(steps) do
			table.insert(out, st)
		end
	end
	return out
end
Kit.GESTURES = {
	nod = { { 0.18, { Neck = { -14, 0, 0 } } }, { 0.16, { Neck = { -2, 0, 0 } } }, { 0.16, { Neck = { -12, 0, 0 } } }, { 0.25, {} } },
	shake = { { 0.16, { Neck = { 0, 22, 0 } } }, { 0.2, { Neck = { 0, -22, 0 } } }, { 0.2, { Neck = { 0, 18, 0 } } }, { 0.2, { Neck = { 0, -12, 0 } } }, { 0.25, {} } },
	shrug = { { 0.25, { Neck = { 0, 0, 10 }, RightShoulder = { 30, 0, -35, 0.15 }, LeftShoulder = { 30, 0, 35, 0.15 }, RightElbow = { 70, 0, 0 }, LeftElbow = { 70, 0, 0 } } }, { 0.7, { Neck = { 0, 0, 10 }, RightShoulder = { 30, 0, -35, 0.15 }, LeftShoulder = { 30, 0, 35, 0.15 }, RightElbow = { 70, 0, 0 }, LeftElbow = { 70, 0, 0 } } }, { 0.35, {} } },
	think = { { 0.4, { Neck = { -8, 0, 6 }, RightShoulder = { 95, 0, 25 }, RightElbow = { 140, 0, 0 }, LeftShoulder = { 40, 0, -30 }, LeftElbow = { 90, 0, 0 } } }, { 2.0, { Neck = { -8, 0, 6 }, RightShoulder = { 95, 0, 25 }, RightElbow = { 140, 0, 0 }, LeftShoulder = { 40, 0, -30 }, LeftElbow = { 90, 0, 0 } } }, { 0.4, {} } },
	facepalm = { { 0.3, { Neck = { -20, 0, 0 }, RightShoulder = { 115, 0, 20 }, RightElbow = { 125, 0, 0 } } }, { 1.4, { Neck = { -22, 0, 0 }, RightShoulder = { 115, 0, 20 }, RightElbow = { 125, 0, 0 } } }, { 0.4, {} } },
	headHold = { { 0.35, { Neck = { -12, 0, 0 }, Waist = { -6, 0, 0 }, RightShoulder = { 140, 0, 25 }, LeftShoulder = { 140, 0, -25 }, RightElbow = { 120, 0, 0 }, LeftElbow = { 120, 0, 0 } } }, { 1.8, { Neck = { -14, 0, 0 }, Waist = { -8, 0, 0 }, RightShoulder = { 140, 0, 25 }, LeftShoulder = { 140, 0, -25 }, RightElbow = { 120, 0, 0 }, LeftElbow = { 120, 0, 0 } } }, { 0.45, {} } },
	lookAround = { { 0.5, { Neck = { 0, 35, 0 } } }, { 0.7, { Neck = { 0, 35, 0 } } }, { 0.7, { Neck = { 0, -35, 0 } } }, { 0.6, { Neck = { 0, -35, 0 } } }, { 0.5, {} } },
	lookUp = { { 0.6, { Neck = { 28, 0, 0 }, Waist = { 6, 0, 0 } } }, { 2.2, { Neck = { 30, 0, 0 }, Waist = { 6, 0, 0 } } }, { 0.6, {} } },
	surprised = { { 0.15, { Neck = { 8, 0, 0 }, Waist = { 6, 0, 0 }, RightShoulder = { 35, 0, -30 }, LeftShoulder = { 35, 0, 30 }, RightElbow = { 40, 0, 0 }, LeftElbow = { 40, 0, 0 } } }, { 1.0, { Neck = { 8, 0, 0 }, Waist = { 6, 0, 0 }, RightShoulder = { 35, 0, -30 }, LeftShoulder = { 35, 0, 30 }, RightElbow = { 40, 0, 0 }, LeftElbow = { 40, 0, 0 } } }, { 0.4, {} } },
	stretch = { { 0.6, { Waist = { 8, 0, 0 }, Neck = { 15, 0, 0 }, RightShoulder = { 170, 0, 10 }, LeftShoulder = { 170, 0, -10 } } }, { 1.0, { Waist = { 10, 0, 0 }, Neck = { 15, 0, 0 }, RightShoulder = { 175, 0, 10 }, LeftShoulder = { 175, 0, -10 } } }, { 0.6, {} } },
	cheer = { { 0.25, { RightShoulder = { 165, 0, 25 }, LeftShoulder = { 165, 0, -25 }, Neck = { 12, 0, 0 } } }, { 0.8, { RightShoulder = { 170, 0, 30 }, LeftShoulder = { 170, 0, -30 }, Neck = { 12, 0, 0 } } }, { 0.4, {} } },
	wave = seqRepeat({ { 0.22, { RightShoulder = { 160, 0, 20 }, RightElbow = { 30, 0, 0 } } }, { 0.22, { RightShoulder = { 160, 0, 20 }, RightElbow = { -10, 0, 0 } } } }, 4),
	clap = seqRepeat({ { 0.14, { RightShoulder = { 70, 0, 25 }, LeftShoulder = { 70, 0, -25 }, RightElbow = { 40, 0, 0 }, LeftElbow = { 40, 0, 0 } } }, { 0.14, { RightShoulder = { 70, 0, 5 }, LeftShoulder = { 70, 0, -5 }, RightElbow = { 40, 0, 0 }, LeftElbow = { 40, 0, 0 } } } }, 5),
	explain = seqRepeat({ { 0.45, { RightShoulder = { 45, 0, -10 }, RightElbow = { 55, 0, 0 }, Neck = { 0, 6, 0 } } }, { 0.45, { RightShoulder = { 60, 0, -25 }, RightElbow = { 30, 0, 0 }, LeftShoulder = { 35, 0, 15 }, LeftElbow = { 45, 0, 0 }, Neck = { 0, -4, 0 } } } }, 3),
	breathe = seqRepeat({ { 0.45, { Waist = { -18, 0, 0 }, Neck = { -6, 0, 0 }, RightShoulder = { 25, 0, 0, 0.12 }, LeftShoulder = { 25, 0, 0, 0.12 } } }, { 0.45, { Waist = { -14, 0, 0 }, Neck = { -2, 0, 0 }, RightShoulder = { 25, 0, 0 }, LeftShoulder = { 25, 0, 0 } } } }, 4),
	pointUp = { { 0.3, { RightShoulder = { 160, 0, 10 }, Neck = { 20, 0, 0 } } }, { 1.6, { RightShoulder = { 160, 0, 10 }, Neck = { 22, 0, 0 } } }, { 0.4, {} } },
}

function Kit.gesture(a, name, waitDone)
	local seq = Kit.GESTURES[name]
	if not seq or not a or not a.joints then
		return
	end
	local function run()
		a.busy = true
		for _, st in ipairs(seq) do
			local dur, map = st[1], st[2]
			for jn, j in pairs(a.joints) do
				if jn == "Neck" or jn == "Waist" or jn:find("Shoulder") or jn:find("Elbow") then
					local r = map[jn]
					local goal = j.c0
					if r then
						goal = j.c0 * CFrame.new(0, r[4] or 0, 0) * CFrame.Angles(rad(r[1]), rad(r[2]), rad(r[3]))
					end
					Kit.tw(j.motor, dur, { C0 = goal })
				end
			end
			task.wait(dur)
		end
		a.busy = false
	end
	if waitDone then
		run()
	else
		task.spawn(run)
	end
end

-- "SỐNG ĐỘNG": nhân vật tự chọn chỗ nhìn (người bên cạnh, máy quay, mặt đất, bầu trời), đầu quay theo mượt,
-- mắt liếc trước; thỉnh thoảng làm cử chỉ lặt vặt (gãi đầu, chống nạnh, khoanh tay, gật gù…).
Kit.GESTURES.scratch = { { 0.35, { Neck = { -6, 0, -8 }, RightShoulder = { 150, 0, 30 }, RightElbow = { 110, 0, 0 } } }, { 0.25, { Neck = { -6, 0, -8 }, RightShoulder = { 150, 0, 30 }, RightElbow = { 125, 0, 0 } } }, { 0.25, { Neck = { -6, 0, -8 }, RightShoulder = { 150, 0, 30 }, RightElbow = { 105, 0, 0 } } }, { 0.25, { Neck = { -6, 0, -8 }, RightShoulder = { 150, 0, 30 }, RightElbow = { 125, 0, 0 } } }, { 0.4, {} } }
Kit.GESTURES.hips = { { 0.4, { RightShoulder = { 10, 0, -40 }, LeftShoulder = { 10, 0, 40 }, RightElbow = { 80, 0, 0 }, LeftElbow = { 80, 0, 0 } } }, { 2.2, { RightShoulder = { 10, 0, -40 }, LeftShoulder = { 10, 0, 40 }, RightElbow = { 80, 0, 0 }, LeftElbow = { 80, 0, 0 } } }, { 0.4, {} } }
Kit.GESTURES.crossArms = { { 0.4, { RightShoulder = { 45, 0, 30 }, LeftShoulder = { 45, 0, -30 }, RightElbow = { 95, 0, 0 }, LeftElbow = { 95, 0, 0 } } }, { 2.4, { RightShoulder = { 45, 0, 30 }, LeftShoulder = { 45, 0, -30 }, RightElbow = { 95, 0, 0 }, LeftElbow = { 95, 0, 0 } } }, { 0.4, {} } }
Kit.GESTURES.shift = { { 0.6, { Waist = { 0, 8, 4 } } }, { 1.2, { Waist = { 0, 8, 4 } } }, { 0.6, { Waist = { 0, -6, -3 } } }, { 0.8, {} } }
Kit.GESTURES.smallNod = { { 0.2, { Neck = { -9, 0, 0 } } }, { 0.25, {} } }
local IDLE_GESTURES = { "scratch", "hips", "crossArms", "shift", "smallNod", "shrug", "shift", "smallNod" }

-- cảm xúc theo thẻ lời kể → biểu cảm khuôn mặt
Kit.MOOD_FACE = {
	excited = { "happy", "laugh" }, playful = { "happy", "smile" }, laughs = { "laugh" }, warm = { "smile", "happy" },
	curious = { "confused", "neutral" }, calm = { "neutral", "smile" }, serious = { "serious", "worried" },
	whispers = { "worried", "dread" }, dramatic = { "shocked", "scared" }, shouting = { "shocked", "scared" },
	sighs = { "tired", "sad" }, sad = { "sad", "hurt" },
}
function Kit.setMood(mood)
	local faces = Kit.MOOD_FACE[mood or ""]
	if not faces then
		return
	end
	local rng = Random.new()
	for _, a in pairs(Kit.A) do
		if a.model.Parent and not a.lockFace then
			Kit.expr(a, faces[rng:NextInteger(1, #faces)])
		end
	end
end

-- đặt chỗ nhìn: Vector3, hoặc nhân vật khác, hoặc "camera"; nil = tự do
function Kit.lookAt(a, target)
	a.lookTarget = target
	a.lookUntil = os.clock() + 999
end

local function targetPos(t)
	if t == "camera" then
		return workspace.CurrentCamera.CFrame.Position
	elseif typeof(t) == "Vector3" then
		return t
	elseif type(t) == "table" and t.head then
		return t.head.Position
	end
end

-- tay chân tự nhiên khi đứng: tay hơi dang, đung đưa theo nhịp thở (chỉ khi không làm cử chỉ / tư thế / đi)
function Kit._updateIdleArms(now)
	for _, a in pairs(Kit.A) do
		if a.model.Parent and not a.busy and not a.posed then
			local J = a.joints
			local ph = now * 1.6 + (a._seed or 0)
			if not a._seed then
				a._seed = math.random() * 10
			end
			local sw = math.sin(ph) * 2.5
			if J.RightShoulder then
				J.RightShoulder.motor.C0 = J.RightShoulder.c0 * CFrame.Angles(rad(3 + sw), 0, rad(-6 - math.sin(ph * 0.5) * 1.5))
			end
			if J.LeftShoulder then
				J.LeftShoulder.motor.C0 = J.LeftShoulder.c0 * CFrame.Angles(rad(3 - sw), 0, rad(6 + math.sin(ph * 0.5) * 1.5))
			end
			if J.RightElbow then
				J.RightElbow.motor.C0 = J.RightElbow.c0 * CFrame.Angles(rad(10 + sw), 0, 0)
			end
			if J.LeftElbow then
				J.LeftElbow.motor.C0 = J.LeftElbow.c0 * CFrame.Angles(rad(10 - sw), 0, 0)
			end
		end
	end
end

function Kit._updateLook(dt)
	local k = 1 - math.exp(-5 * dt)
	for _, a in pairs(Kit.A) do
		local neck = a.joints and a.joints.Neck
		if neck and a.model.Parent and not a.busy then
			local tp = targetPos(a.lookTarget)
			local yaw, pitch = 0, 0
			if tp then
				local torso = a.model:FindFirstChild("UpperTorso")
				if torso then
					local d = torso.CFrame:VectorToObjectSpace(tp - a.head.Position)
					yaw = math.clamp(math.atan2(-d.X, -d.Z), -1.0, 1.0)
					local horiz = math.sqrt(d.X * d.X + d.Z * d.Z)
					pitch = math.clamp(math.atan2(d.Y, horiz), -0.5, 0.6)
					if math.abs(math.atan2(-d.X, -d.Z)) > 2.2 then
						yaw, pitch = 0, 0 -- mục tiêu ở sau lưng: không vặn cổ
					end
				end
			end
			a._yaw = (a._yaw or 0) + (yaw - (a._yaw or 0)) * k
			a._pitch = (a._pitch or 0) + (pitch - (a._pitch or 0)) * k
			neck.motor.C0 = neck.c0 * CFrame.Angles(a._pitch, a._yaw, 0)
			-- mắt liếc trước đầu một chút
			if not a.lockGaze then
				a.face:SetAttribute("Gaze", Vector2.new(math.clamp(-(yaw - a._yaw) * 4, -1, 1), math.clamp(-(pitch - a._pitch) * 4, -1, 1)))
			end
		end
	end
end

function Kit.idleLife(on)
	Kit._idle = on
	if not on or Kit._idleRunning then
		return
	end
	Kit._idleRunning = true
	task.spawn(function()
		local rng = Random.new()
		while Kit._idle do
			local visible = {}
			for _, a in pairs(Kit.A) do
				if a.model.Parent then
					table.insert(visible, a)
				end
			end
			for _, a in ipairs(visible) do
				-- đổi chỗ nhìn mỗi vài giây
				if os.clock() > (a.lookUntil or 0) then
					local r = rng:NextNumber()
					local other
					for _ = 1, 4 do
						local c = visible[rng:NextInteger(1, #visible)]
						if c ~= a and (c.root.Position - a.root.Position).Magnitude < 30 then
							other = c
							break
						end
					end
					if other and r < 0.5 then
						a.lookTarget = other
					elseif r < 0.62 then
						a.lookTarget = "camera"
					elseif r < 0.8 then
						a.lookTarget = a.root.Position + a.root.CFrame.LookVector * 8 + Vector3.new(rng:NextNumber(-6, 6), -4, 0)
					elseif r < 0.9 then
						a.lookTarget = a.root.Position + a.root.CFrame.LookVector * 10 + Vector3.new(rng:NextNumber(-8, 8), 8, 0)
					else
						a.lookTarget = nil
					end
					a.lookUntil = os.clock() + rng:NextNumber(1.8, 4.5)
				end
				-- cử chỉ lặt vặt khi rảnh tay
				if not a.busy and not a.posed and rng:NextNumber() < 0.12 then
					Kit.gesture(a, IDLE_GESTURES[rng:NextInteger(1, #IDLE_GESTURES)])
				end
				local waist = a.joints and a.joints.Waist
				if waist and not a.busy and rng:NextNumber() < 0.25 then
					local goal = waist.c0 * CFrame.Angles(rad(rng:NextNumber(-2, 3)), rad(rng:NextNumber(-6, 6)), rad(rng:NextNumber(-3, 3)))
					Kit.tw(waist.motor, rng:NextNumber(1.4, 2.4), { C0 = goal })
				end
			end
			task.wait(1.2)
		end
		Kit._idleRunning = false
	end)
end

function Kit.resetPose(a)
	a.posed = false
	for _, j in pairs(a.joints) do
		j.motor.C0 = j.c0
	end
end

function Kit.expr(a, name)
	a.face:SetAttribute("Expression", name)
end
function Kit.gaze(a, x, y)
	a.lockGaze = (x or 0) ~= 0 or (y or 0) ~= 0
	a.face:SetAttribute("Gaze", Vector2.new(x or 0, y or 0))
end
function Kit.tears(a, on)
	a.face:SetAttribute("Tears", on)
end

function Kit.grab(a, item, handName, offset)
	local parts = item:IsA("BasePart") and { item } or item:GetDescendants()
	for _, p in ipairs(parts) do
		if p:IsA("BasePart") then
			p.Massless = true
			p.CanCollide = false
		end
	end
	local hand = a.model:FindFirstChild(handName or "RightHand")
	local root = item:IsA("Model") and item.PrimaryPart or item
	if item:IsA("Model") then
		item:PivotTo(hand.CFrame * (offset or CFrame.new()))
	else
		item.CFrame = hand.CFrame * (offset or CFrame.new(0, -0.3, -0.1))
	end
	root.Anchored = false
	local w = Kit.weld(hand, root)
	w.Name = "HeldWeld"
end
function Kit.release(item, cf)
	local root = item:IsA("Model") and item.PrimaryPart or item
	for _, w in ipairs(root:GetChildren()) do
		if w.Name == "HeldWeld" then
			w:Destroy()
		end
	end
	root.Anchored = true
	if cf then
		if item:IsA("Model") then
			item:PivotTo(cf)
		else
			item.CFrame = cf
		end
	end
end

------------------------------------------------------------------------ MÁY QUAY
-- Cỡ cảnh = chiều cao khung hình nhìn thấy (stud). Nhân vật cao ~5.3 stud.
Kit.SIZES = { ECU = 1.8, CU = 3.0, MCU = 4.3, MS = 6.2, MLS = 8.0, FS = 9.6, WS = 16 }
local LETTERBOX_VISIBLE = (16 / 9) / 2.0 -- khớp với Kit.LETTERBOX mặc định -- khung 2:1 trên màn 16:9

local function fovMM(mm)
	return math.deg(2 * math.atan(12 / mm))
end
local function distanceFor(size, mm)
	local H = Kit.SIZES[size] or size
	local half = math.atan(math.tan(math.rad(fovMM(mm)) / 2) * LETTERBOX_VISIBLE)
	return (H / 2) / math.tan(half)
end
Kit.distanceFor = distanceFor

-- điểm bám vào nhân vật
function Kit.on(a, partName, offset, localSpace)
	return { actor = a.name, part = partName or "Head", offset = offset, localSpace = localSpace }
end

Kit._shotId = 0
function Kit.cam(spec)
	Kit._shotId += 1
	Kit._lastShot = spec
	if spec.mm then
		spec.fov = fovMM(spec.mm)
		spec.mm = nil
	end
	Kit.fx("cam", spec)
end

-- Khung theo cỡ cảnh quanh 1 nhân vật.
-- opts.angle: độ quanh nhân vật (0 = chính diện, 90 = bên phải nhân vật, 180 = sau lưng)
-- opts.height: nâng/hạ máy; opts.mm: tiêu cự (mặc định 35); các khoá khác chuyển thẳng xuống camera
function Kit.frame(a, size, opts)
	opts = opts or {}
	local mm = opts.mm or 35
	local d = distanceFor(size, mm)
	local ang = rad(opts.angle or 0)
	local focusPart, focusOff
	if size == "ECU" or size == "CU" then
		focusPart, focusOff = "Head", Vector3.new(0, -0.15, 0)
	elseif size == "MCU" then
		focusPart, focusOff = "Head", Vector3.new(0, -0.7, 0)
	elseif size == "MS" then
		focusPart, focusOff = "UpperTorso", Vector3.new(0, 0.5, 0)
	else
		focusPart, focusOff = "HumanoidRootPart", Vector3.new(0, 0.6, 0)
	end
	local camOff = focusOff + Vector3.new(math.sin(ang) * d, opts.height or 0.2, -math.cos(ang) * d)
	local spec = {
		pos = Kit.on(a, focusPart, camOff, true),
		look = Kit.on(a, focusPart, focusOff + (opts.lookOffset or Vector3.zero), true),
		mm = mm,
		time = opts.time or 0,
		handheld = opts.handheld or 0,
		smooth = opts.smooth,
		dutch = opts.dutch,
		dof = opts.dof or ((size == "CU" or size == "ECU" or size == "MCU") and 0.35 or 0.15),
		focusRadius = opts.focusRadius or math.max(2, d * 0.35),
	}
	Kit.cam(spec)
	return spec
end

-- Qua vai: máy sau vai `over`, nhìn vào `onto`
function Kit.ots(over, onto, size, opts)
	opts = opts or {}
	local mm = opts.mm or 40
	local side = opts.side or 1
	local overPos, ontoPos = over.head.Position, onto.head.Position
	local dirFlat = ((ontoPos - overPos) * Vector3.new(1, 0, 1)).Unit
	local right = dirFlat:Cross(Vector3.yAxis)
	local want = distanceFor(size or "MS", mm)
	local sep = (ontoPos - overPos).Magnitude
	local back = math.max(1.6, want - sep)
	local pos = overPos - dirFlat * back + right * side * 1.5 + Vector3.new(0, 0.35, 0)
	Kit.cam({
		pos = pos,
		look = Kit.on(onto, "Head", Vector3.new(0, -0.5, 0)),
		mm = mm,
		time = 0,
		handheld = opts.handheld or 0,
		dof = 0.3,
		focusRadius = 2.5,
	})
end

-- Hai người cùng khung, máy vuông góc với đường nối hai người
function Kit.two(a, b, size, opts)
	opts = opts or {}
	local mm = opts.mm or 35
	local pa, pb = a.head.Position, b.head.Position
	local mid = (pa + pb) / 2 + Vector3.new(0, (size == "FS" or size == "WS") and -1.5 or -0.9, 0)
	local line = ((pb - pa) * Vector3.new(1, 0, 1))
	local normal = line.Unit:Cross(Vector3.yAxis) * (opts.side or 1)
	local d = math.max(distanceFor(size or "MS", mm), line.Magnitude * 1.1 + 2)
	local ang = rad(opts.angle or 0)
	local dir = CFrame.fromAxisAngle(Vector3.yAxis, ang):VectorToWorldSpace(normal)
	Kit.cam({
		pos = mid + dir * d + Vector3.new(0, opts.height or 0.4, 0),
		look = mid,
		mm = mm,
		time = opts.time or 0,
		handheld = opts.handheld or 0,
		dof = 0.12,
		focusRadius = 4,
	})
end

------------------------------------------------------------------------ KHỞI TẠO (máy người xem)
function Kit.init()
	local old = workspace:FindFirstChild("Phim")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "Phim"
	root.Parent = workspace
	local set = Instance.new("Folder")
	set.Name = "Set"
	set.Parent = root
	local actors = Instance.new("Folder")
	actors.Name = "Actors"
	actors.Parent = root
	Kit.ROOT, Kit.SET, Kit.ACTORS = root, set, actors
	Kit._client()
end

------------------------------------------------------------------------ THOẠI
function Kit.say(a, text, dur, expression)
	if expression then
		Kit.expr(a, expression)
	end
	a.face:SetAttribute("Talking", true)
	Kit.fx("line", a.name, text)
	task.delay(math.max(0.6, dur - 0.5), function()
		a.face:SetAttribute("Talking", false)
	end)
	task.wait(dur)
end

function Kit.voice(speaker, text, dur, style)
	Kit.fx("line", speaker, text, style)
	task.wait(dur)
end

function Kit.clear()
	Kit.fx("line", "", "")
end

Kit.fx = function() end

------------------------------------------------------------------------ PHẦN HIỂN THỊ: UI, ÂM THANH, MẶT, CAMERA
function Kit._client()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local StarterGui = game:GetService("StarterGui")

	local LETTERBOX = Kit.LETTERBOX or 2.0 -- tỉ lệ khung phim (2.39 = rất hẹp, 1.78 = không có viền đen)

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
	for k, v in pairs(Kit.SOUNDS or {}) do -- tập phim có thể ghi đè: Kit.SOUNDS = { music = { id = 123, volume = 0.3, loop = true } }
		SOUNDS[k] = v
	end

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
	-- viền tối quanh khung (vignette)
	for i, rot in ipairs({ 90, -90, 0, 180 }) do
		local v = newFrame(2)
		v.BackgroundColor3 = Color3.new(0, 0, 0)
		if i <= 2 then
			v.Size = UDim2.fromScale(1, 0.28)
			v.Position = UDim2.fromScale(0, i == 1 and 0 or 0.72)
		else
			v.Size = UDim2.fromScale(0.22, 1)
			v.Position = UDim2.fromScale(i == 3 and 0 or 0.78, 0)
		end
		local g = Instance.new("UIGradient")
		g.Rotation = rot
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		g.Parent = v
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

	-- KHUÔN MẶT 3D: mắt, mày, mũi, miệng là các khối nhỏ áp sát mặt cong của đầu tròn,
	-- nên nhìn nghiêng vẫn dính mặt. Toạ độ biểu cảm dùng thang 0..100 như trước.
	local function ellipsoid(color, parent)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = Vector3.new(0.1, 0.1, 0.05)
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		p.Parent = parent
		return p
	end
	local function slab(color, parent)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = Vector3.new(0.1, 0.03, 0.03)
		p.Parent = parent
		return p
	end

	local function buildFace(plate)
		if faces[plate] then
			return
		end
		local model = plate.Parent
		local head = model and model:FindFirstChild("Head")
		if not head then
			return
		end
		local old = model:FindFirstChild("Face3D")
		if old then
			old:Destroy()
		end
		local folder = Instance.new("Folder")
		folder.Name = "Face3D"
		folder.Parent = model
		local function hexOr(attr, default)
			local ok, col = pcall(Color3.fromHex, plate:GetAttribute(attr) or "")
			return ok and col or default
		end
		local dark = Color3.fromRGB(28, 24, 26)
		local skin = hexOr("Skin", Color3.fromRGB(240, 203, 178))
		local female = plate:GetAttribute("Female") == true
		local lip = hexOr("Lips", Color3.fromRGB(110, 45, 48))
		local f = { plate = plate, head = head, folder = folder, cur = table.clone(EXPR.neutral), nextBlink = os.clock() + math.random() * 3, blinkUntil = 0, seed = math.random() * 100, tearProgress = 0 }
		f.scl = { ellipsoid(Color3.fromRGB(250, 248, 244), folder), ellipsoid(Color3.fromRGB(250, 248, 244), folder) }
		f.iris = { ellipsoid(hexOr("EyeColor", Color3.fromRGB(58, 36, 24)), folder), ellipsoid(hexOr("EyeColor", Color3.fromRGB(58, 36, 24)), folder) }
		f.pupil = { ellipsoid(Color3.fromRGB(10, 8, 8), folder), ellipsoid(Color3.fromRGB(10, 8, 8), folder) }
		f.shine = { ellipsoid(Color3.new(1, 1, 1), folder), ellipsoid(Color3.new(1, 1, 1), folder) }
		f.lid = { slab(dark, folder), slab(dark, folder) }
		f.brow = { slab(hexOr("BrowColor", dark), folder), slab(hexOr("BrowColor", dark), folder) }
		f.nose = ellipsoid(skin:Lerp(Color3.fromRGB(150, 80, 60), 0.3), folder)
		f.mouth = ellipsoid(Color3.fromRGB(90, 40, 42), folder)
		f.teeth = ellipsoid(Color3.fromRGB(250, 248, 240), folder)
		f.lip = { slab(lip, folder), slab(lip, folder) }
		if (plate:GetAttribute("Lips") or "") == "" then
			f.lip[1].Transparency, f.lip[2].Transparency = 1, 1
		end
		f.corner = { slab(lip, folder), slab(lip, folder) }
		f.blush = { ellipsoid(skin:Lerp(Color3.fromRGB(235, 120, 120), 0.5), folder), ellipsoid(skin:Lerp(Color3.fromRGB(235, 120, 120), 0.5), folder) }
		for _, b in ipairs(f.blush) do
			b.Transparency = female and 0.45 or 0.75
		end
		f.tear = { slab(Color3.fromRGB(150, 205, 255), folder), slab(Color3.fromRGB(150, 205, 255), folder) }
		for _, t in ipairs(f.tear) do
			t.Material = Enum.Material.Glass
			t.Transparency = 0.25
		end
		local mole = plate:GetAttribute("Mole")
		if mole == "L" or mole == "R" then
			f.mole = ellipsoid(Color3.fromRGB(45, 30, 28), folder)
			f.moleX = mole == "L" and 71 or 29
		end
		if female then
			f.lash = { slab(dark, folder), slab(dark, folder) }
		end
		faces[plate] = f
		plate.AncestryChanged:Connect(function()
			if not plate:IsDescendantOf(workspace) then
				faces[plate] = nil
				folder:Destroy()
			end
		end)
	end

	local function updateFaces(dt, now)
		local k = 1 - math.exp(-14 * dt)
		for plate, f in pairs(faces) do
			local head = f.head
			if plate.Parent and plate.Parent.Parent ~= nil then
				local target = EXPR[plate:GetAttribute("Expression") or "neutral"] or EXPR.neutral
				local c = f.cur
				for _, key in ipairs(KEYS) do
					c[key] = c[key] + (target[key] - c[key]) * k
				end
				if now > f.nextBlink then
					f.blinkUntil = now + 0.11
					f.nextBlink = now + 2 + math.random() * 3.5
				end
				local hs = head.Size
				local F = math.min(hs.X, hs.Y) * 0.92 -- bề rộng vùng mặt (stud)
				local r = math.min(hs.X, hs.Z) * 0.5
				local hcf = head.CFrame
				-- đặt một chi tiết lên mặt cầu của đầu: (x, y) thang 0..100, kích thước (w, h) thang 0..100
				local function place(p, x, y, w, h, depth, lift, rot)
					local u = (x - 50) / 100 * F
					local v = -(y - 50) / 100 * F * 1.05
					local zz = math.sqrt(math.max(0.01, r * r - u * u * 0.85 - v * v * 0.7))
					local n = Vector3.new(u, v, -zz).Unit
					local pos = Vector3.new(u, v, 0) + Vector3.new(0, 0, -zz) + n * (lift or 0.01)
					local lcf = CFrame.lookAt(pos, pos + n) * CFrame.Angles(0, 0, math.rad(rot or 0))
					p.Size = Vector3.new(math.max(0.01, w / 100 * F), math.max(0.01, h / 100 * F), depth or 0.04)
					p.CFrame = hcf * lcf
				end
				local gz = plate:GetAttribute("Gaze") or Vector2.zero
				local eyeH = (now < f.blinkUntil) and 1.2 or c.eyeH
				local sw = c.eyeW * 1.3
				local irisD = math.min(c.eyeW, 13)
				for i, ex in ipairs({ 35, 65 }) do
					local open = eyeH > 2.5
					place(f.scl[i], ex, c.eyeY, sw, eyeH, 0.05, 0.005)
					f.scl[i].Transparency = open and 0 or 1
					local ix, iy = ex + gz.X * 2.5, c.eyeY + gz.Y * 1.5
					local ih = math.min(irisD, eyeH)
					place(f.iris[i], ix, iy, irisD, ih, 0.05, 0.02)
					place(f.pupil[i], ix, iy, irisD * 0.5, ih * 0.5, 0.05, 0.03)
					place(f.shine[i], ix + irisD * 0.18, iy - ih * 0.2, irisD * 0.28, ih * 0.28, 0.05, 0.04)
					f.iris[i].Transparency = open and 0 or 1
					f.pupil[i].Transparency = open and 0 or 1
					f.shine[i].Transparency = open and 0 or 1
					-- mí trên (nhắm mắt = một nét)
					place(f.lid[i], ex, c.eyeY - eyeH / 2, sw * 1.05, 1.8, 0.04, 0.035)
					if f.lash then
						place(f.lash[i], ex + (i == 1 and -1 or 1) * sw * 0.55, c.eyeY - eyeH / 2, sw * 0.35, 1.4, 0.03, 0.035, i == 1 and -25 or 25)
					end
					place(f.brow[i], ex, c.browY, 15, 3, 0.05, 0.02, (i == 1 and 1 or -1) * c.browAng)
					place(f.blush[i], ex + (i == 1 and -5 or 5), 61, 12, 6, 0.03, 0.005)
				end
				place(f.nose, 50, 59, 5, 6, 0.08, 0.01)
				local mh, mw = c.mouthH, c.mouthW
				if plate:GetAttribute("Talking") then
					mh = mh + 7 * math.abs(math.noise(now * 9, f.seed))
					mw = mw - 2
				end
				place(f.mouth, 50, c.mouthY, mw, mh, 0.05, 0.01)
				f.teeth.Transparency = mh > 5 and 0 or 1
				place(f.teeth, 50, c.mouthY - mh * 0.28, mw * 0.75, mh * 0.3, 0.05, 0.02)
				place(f.lip[1], 50, c.mouthY - mh / 2, mw, 1.4, 0.04, 0.02)
				place(f.lip[2], 50, c.mouthY + mh / 2, mw * 0.8, 1.6, 0.04, 0.02)
				local sm = c.smile
				for i, sx in ipairs({ -1, 1 }) do
					f.corner[i].Transparency = math.abs(sm) > 0.08 and 0 or 1
					place(f.corner[i], 50 + sx * (mw / 2 + 1.5), c.mouthY - sm * 2, 6, 2.2, 0.04, 0.02, sx * -sm * 35)
				end
				local tearsOn = plate:GetAttribute("Tears") == true
				f.tearProgress = math.clamp(f.tearProgress + (tearsOn and dt * 0.5 or -dt * 2), 0, 1)
				local tl = 14 * f.tearProgress
				for i, ex in ipairs({ 33, 67 }) do
					f.tear[i].Transparency = tl > 0.5 and 0.25 or 1
					place(f.tear[i], ex, c.eyeY + eyeH / 2 + tl / 2, 2.2, math.max(tl, 0.5), 0.03, 0.03)
				end
				if f.mole then
					place(f.mole, f.moleX, 62, 3, 3, 0.03, 0.01)
				end
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

		-- máy tự tiến rất chậm vào chủ thể (cảm giác điện ảnh)
		local drift = spec.drift or 0 -- máy đứng yên (máy trôi làm bóng nắng nhảy lớp)
		local camPos = st.pos
		if drift > 0 then
			local prog = math.clamp((now - st.t0) / 7, 0, 1)
			camPos = st.look + (st.pos - st.look) * (1 - drift * prog)
		end
		-- chống bị che: nếu có vật cản giữa chủ thể và máy, kéo máy lại gần trước vật cản
		if spec.occlude ~= false then
			local dir = camPos - st.look
			local ignore = { workspace:FindFirstChild("Phim") and workspace.Phim:FindFirstChild("Actors") }
			if player.Character then
				table.insert(ignore, player.Character)
			end
			for _ = 1, 6 do
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = ignore
				local hit = workspace:Raycast(st.look, dir, params)
				if not hit then
					break
				end
				if hit.Instance.Transparency > 0.4 or not hit.Instance.CanCollide or hit.Instance:GetAttribute("NoOcclude") then
					table.insert(ignore, hit.Instance)
				else
					camPos = hit.Position - dir.Unit * 0.5
					break
				end
			end
		end
		local cf = CFrame.lookAt(camPos, st.look)
		if spec.dutch then
			cf = cf * CFrame.Angles(0, 0, math.rad(spec.dutch))
		end
		local hh = (Kit.ALLOW_HANDHELD and spec.handheld or 0) * 1.2
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
		local dofAmt = spec.dof
		if dofAmt == nil then
			dofAmt = 0
		end
		if dofAmt > 0 then
			dof.Enabled = true
			dof.FarIntensity = dofAmt
			dof.NearIntensity = spec.near or dofAmt * 0.6
			dof.InFocusRadius = spec.focusRadius or math.max(4, (st.look - camPos).Magnitude * 0.4)
			local fd = (st.look - camPos).Magnitude
			dof.FocusDistance = dof.FocusDistance + (fd - dof.FocusDistance) * math.min(1, dt * 4)
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
		Kit._updateBlobs()
		Kit._updateLook(dt)
		Kit._updateIdleArms(now)
		if now - (Kit._lastCull or 0) > 0.5 then
			Kit._lastCull = now
			local cp = camera.CFrame.Position
			for _, pr in ipairs(Kit._practicals) do
				local l = pr.light
				if l.Parent and l.Parent:IsA("BasePart") then
					local on = (pr.mode == "always" or Kit._isNight) and (l.Parent.Position - cp).Magnitude < 140
					if l.Enabled ~= on then
						l.Enabled = on
					end
				end
			end
		end
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
	local function handle(kind, a, b, c)
		if kind == "start" then
			active = true
			gui.Enabled = true
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
				pcall(function()
					StarterGui:SetCore("TopbarEnabled", false) -- ẩn thanh nút Roblox góc trên
				end)
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
				sub.Text = string.format('<b><font color="%s">%s</font></b>', color, b)
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
	end
		Kit.fx = handle
		Kit._onShot = onShot
end

return Kit
