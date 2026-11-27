--[[
	PhimKit — bộ công cụ làm phim dùng chung (ModuleScript, đặt trong ReplicatedStorage, tên "PhimKit").
	Gồm: dựng khối, nhân vật (tóc, trang phục thay được, mặt), diễn xuất (đi, ngồi, nằm, tư thế tay,
	biểu cảm), máy quay (khung hình theo cỡ cảnh: CU/MCU/MS/FS/WS), thoại, hiệu ứng.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Kit = {}
local rad = math.rad
Kit.A = {}

function Kit.hex(s)
	return Color3.fromHex(s)
end
local hex = Kit.hex

------------------------------------------------------------------------ KHỞI TẠO
function Kit.init()
	local cue = ReplicatedStorage:FindFirstChild("PhimCue") or Instance.new("RemoteEvent")
	cue.Name = "PhimCue"
	cue.Parent = ReplicatedStorage
	Kit.cue = cue
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
end

-- trả về hàm toạ độ tương đối cho một bối cảnh
function Kit.origin(o)
	return function(x, y, z)
		return o + Vector3.new(x, y, z)
	end
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
	return Kit.part(props)
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

------------------------------------------------------------------------ ÁNH SÁNG
local function ensure(className, parent)
	local obj = parent:FindFirstChildOfClass(className) or Instance.new(className)
	obj.Parent = parent
	return obj
end

local LOOKS = {
	morning = { ClockTime = 7.5, Brightness = 2.6, Ambient = "#4a4a50", Outdoor = "#a0a0aa", Exposure = 0.1, Density = 0.3, Haze = 1.4, AtmColor = "#f0e4d4", Tint = "#fff4e6", Sat = 0.05, Contrast = 0.1 },
	afternoon = { ClockTime = 15.5, Brightness = 2.2, Ambient = "#4a4640", Outdoor = "#9a948a", Exposure = 0, Density = 0.32, Haze = 1.6, AtmColor = "#e8d8c0", Tint = "#ffeedd", Sat = 0.05, Contrast = 0.12 },
	rain = { ClockTime = 16.5, Brightness = 0.9, Ambient = "#3a3e48", Outdoor = "#707888", Exposure = 0.15, Density = 0.45, Haze = 2.2, AtmColor = "#a8b4c4", Tint = "#dde6ff", Sat = -0.15, Contrast = 0.15 },
	night = { ClockTime = 22.5, Brightness = 0.3, Ambient = "#20222c", Outdoor = "#262a3a", Exposure = 0.25, Density = 0.3, Haze = 0.6, AtmColor = "#46506e", Tint = "#dde2ff", Sat = -0.1, Contrast = 0.14 },
}
function Kit.look(name)
	local L = LOOKS[name]
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.ClockTime = L.ClockTime
	Lighting.Brightness = L.Brightness
	Lighting.Ambient = hex(L.Ambient)
	Lighting.OutdoorAmbient = hex(L.Outdoor)
	Lighting.ExposureCompensation = L.Exposure
	local atm = ensure("Atmosphere", Lighting)
	atm.Density, atm.Haze, atm.Color = L.Density, L.Haze, hex(L.AtmColor)
	local cc = ensure("ColorCorrectionEffect", Lighting)
	cc.TintColor, cc.Saturation, cc.Contrast = hex(L.Tint), L.Sat, L.Contrast
	local bloom = ensure("BloomEffect", Lighting)
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.6, 24, 1.3
	Kit.fx("look", name)
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

	for _, accName in ipairs(o.acc or {}) do
		local build = ACCESSORIES[accName]
		if build then
			build(f, m)
		end
	end
	a.outfit = outfit
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
	hairPart(h, f, "Fringe", Vector3.new(w * 0.95, hh * 0.16, d * 0.14), Vector3.new(0, hh * 0.36, -d * 0.47), c)
end
HAIR.curtain = function(h, f, c, w, hh, d) -- mái chia ngôi giữa (Minh)
	HAIR.short(h, f, c, w, hh, d)
	hairPart(h, f, "BangL", Vector3.new(w * 0.42, hh * 0.32, d * 0.14), Vector3.new(-w * 0.24, hh * 0.24, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(-18)))
	hairPart(h, f, "BangR", Vector3.new(w * 0.42, hh * 0.32, d * 0.14), Vector3.new(w * 0.24, hh * 0.24, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(18)))
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
HAIR.long = function(h, f, c, w, hh, d) -- tóc dài thẳng ngang lưng (An)
	hairPart(h, f, "Back", Vector3.new(w * 1.1, hh * 2.1, d * 0.3), Vector3.new(0, -hh * 0.45, d * 0.45), c)
	hairPart(h, f, "SideL", Vector3.new(w * 0.14, hh * 1.3, d * 0.75), Vector3.new(-w * 0.52, -hh * 0.1, 0.05), c)
	hairPart(h, f, "SideR", Vector3.new(w * 0.14, hh * 1.3, d * 0.75), Vector3.new(w * 0.52, -hh * 0.1, 0.05), c)
	hairPart(h, f, "BangL", Vector3.new(w * 0.5, hh * 0.3, d * 0.12), Vector3.new(-w * 0.22, hh * 0.3, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(-12)))
	hairPart(h, f, "BangR", Vector3.new(w * 0.4, hh * 0.22, d * 0.12), Vector3.new(w * 0.27, hh * 0.34, -d * 0.48), c, nil, CFrame.Angles(0, 0, rad(10)))
end
HAIR.bob = function(h, f, c, w, hh, d) -- tóc bob ôm cằm (Linh)
	hairPart(h, f, "Back", Vector3.new(w * 1.1, hh * 0.95, d * 0.32), Vector3.new(0, 0, d * 0.42), c)
	hairPart(h, f, "SideL", Vector3.new(w * 0.16, hh * 0.9, d * 0.85), Vector3.new(-w * 0.52, 0, 0.05), c)
	hairPart(h, f, "SideR", Vector3.new(w * 0.16, hh * 0.9, d * 0.85), Vector3.new(w * 0.52, 0, 0.05), c)
	hairPart(h, f, "Fringe", Vector3.new(w * 0.98, hh * 0.22, d * 0.12), Vector3.new(0, hh * 0.32, -d * 0.48), c)
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

------------------------------------------------------------------------ NHÂN VẬT
local ANIM = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	sit = "rbxassetid://2506281703",
}

function Kit.actor(name, spec)
	local desc = Instance.new("HumanoidDescription")
	local skin = hex(spec.skin)
	desc.HeadColor, desc.TorsoColor = skin, skin
	desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = skin, skin, skin, skin
	if spec.female then
		desc.HeightScale, desc.WidthScale, desc.DepthScale, desc.HeadScale = 0.93 * (spec.height or 1), 0.82, 0.88, 0.97
		desc.BodyTypeScale, desc.ProportionScale = 0.3, 0.5
	else
		desc.HeightScale = spec.height or 1
		desc.WidthScale = spec.build or 1
	end
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	model.Name = name
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local head = model:WaitForChild("Head")
	local decal = head:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Material = Enum.Material.SmoothPlastic
		end
	end

	-- tấm mặt (client vẽ mắt/mày/miệng/nốt ruồi lên đây)
	local plate = Instance.new("Part")
	plate.Name = "FacePlate"
	plate.Transparency = 1
	plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.Massless = false, false, false, true
	local fs = math.min(head.Size.X, head.Size.Y)
	plate.Size = Vector3.new(fs * 0.95, fs * 0.95, 0.05)
	plate.CFrame = head.CFrame * CFrame.new(0, -head.Size.Y * 0.04, -head.Size.Z / 2 - 0.02)
	plate.Parent = model
	Kit.weld(head, plate)
	plate:SetAttribute("Expression", "neutral")
	plate:SetAttribute("Talking", false)
	plate:SetAttribute("Mole", spec.mole or "")
	plate:SetAttribute("Skin", spec.skin)
	plate:SetAttribute("BrowColor", spec.hairColor)
	plate:SetAttribute("Female", spec.female == true)
	plate:SetAttribute("Lips", spec.lips or "")
	plate:SetAttribute("Gaze", Vector2.zero)
	plate:SetAttribute("Tears", false)

	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
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
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
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
		skin = skin,
		standY = hum.HipHeight + root.Size.Y / 2,
	}
	Kit.hair(a, spec.hair, spec.hairColor)
	Kit.dress(a, spec.outfit)
	Kit.A[name] = a
	model.Parent = nil
	return a
end

------------------------------------------------------------------------ DIỄN XUẤT
function Kit.tw(obj, t, props, style)
	local tween = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props)
	tween:Play()
	return tween
end

function Kit.anim(a, name, fade)
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

function Kit.glide(a, cf, t)
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
	Kit.tw(v, t, { Value = cf }).Completed:Wait()
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

-- đặt diễn viên đứng tại pos (Vector3 mặt đất), nhìn về lookAt
function Kit.stand(a, pos, lookAt)
	a.model.Parent = Kit.ACTORS
	Kit.anim(a, "idle")
	local p = Vector3.new(pos.X, pos.Y + a.standY, pos.Z)
	Kit.glide(a, flatLook(p, lookAt or (p + Vector3.new(0, 0, -1))), 0)
end

-- ngồi ghế: seatTop = độ cao mặt ghế
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
	local pos = a.root.Position
	Kit.glide(a, flatLook(pos, target), t or 0.6)
end

function Kit.walk(a, pos, speed)
	a.model.Parent = Kit.ACTORS
	local goal = Vector3.new(pos.X, pos.Y + a.standY, pos.Z)
	a.root.Anchored = false
	pcall(function()
		a.root:SetNetworkOwner(nil)
	end)
	a.hum.WalkSpeed = speed or 7
	Kit.anim(a, "walk", 0.2)
	a.hum:MoveTo(goal)
	local done = false
	local conn = a.hum.MoveToFinished:Connect(function()
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < 15 do
		task.wait()
	end
	conn:Disconnect()
	Kit.anim(a, "idle", 0.3)
	a.root.Anchored = true
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

function Kit.resetPose(a)
	for _, j in pairs(a.joints) do
		j.motor.C0 = j.c0
	end
end

function Kit.expr(a, name)
	a.face:SetAttribute("Expression", name)
end
function Kit.gaze(a, x, y)
	a.face:SetAttribute("Gaze", Vector2.new(x or 0, y or 0))
end
function Kit.tears(a, on)
	a.face:SetAttribute("Tears", on)
end

function Kit.grab(a, item, handName, offset)
	if item:IsA("BasePart") then
		item.Anchored = false
		item.Massless = true
		item.CanCollide = false
	else
		for _, p in ipairs(item:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Massless = true
				p.CanCollide = false
			end
		end
	end
	local hand = a.model:FindFirstChild(handName or "RightHand")
	local root = item
	if item:IsA("Model") then
		root = item.PrimaryPart
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
Kit.SIZES = { ECU = 1.3, CU = 2.4, MCU = 3.4, MS = 5.0, MLS = 6.6, FS = 8.0, WS = 14 }
local LETTERBOX_VISIBLE = (16 / 9) / 2.0 -- khung 2:1 trên màn 16:9

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

function Kit.cam(spec)
	if spec.mm then
		spec.fov = fovMM(spec.mm)
		spec.mm = nil
	end
	Kit.cue:FireAllClients("cam", spec)
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
		handheld = opts.handheld or 0.12,
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
		handheld = opts.handheld or 0.1,
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
		handheld = opts.handheld or 0.08,
		dof = 0.12,
		focusRadius = 4,
	})
end

------------------------------------------------------------------------ THOẠI / HIỆU ỨNG
function Kit.fx(kind, ...)
	if Kit.cue then
		Kit.cue:FireAllClients(kind, ...)
	end
end

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

return Kit
