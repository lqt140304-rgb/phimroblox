-- DramaScene: dựng một cảnh drama ngắn (~60 giây) với 2 nhân vật R15.
-- Server lo dựng bối cảnh + điều khiển diễn viên; client (DramaCamera) lo camera + phụ đề.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cue = Instance.new("RemoteEvent")
cue.Name = "DramaCue"
cue.Parent = ReplicatedStorage

------------------------------------------------------------------ CẤU HÌNH
local CONFIG = {
	Rain = true,              -- mưa + sấm chớp
	-- Âm thanh: dán ID lấy từ Creator Store (Audio) vào đây. Để 0 = tắt.
	MusicId = 0,              -- nhạc nền buồn (piano/sad)
	RainSoundId = 0,          -- tiếng mưa loop
	ThunderSoundId = 0,       -- tiếng sấm
	MusicVolume = 0.4,
	-- Trang phục: lấy avatar từ UserId Roblox. 0 = Minh dùng avatar của bạn, Lan dùng màu mặc định.
	MinhUserId = 0,           -- 0 = lấy avatar người đang Play
	LanUserId = 0,            -- điền UserId 1 tài khoản có avatar nữ để Lan có quần áo/tóc
	Title = "MỘT LỜI CHƯA NÓI",
}

-- Animation mặc định công khai của Roblox (R15)
local ANIM = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	wave = "rbxassetid://507770239",
}

------------------------------------------------------------------ BỐI CẢNH
local set = Instance.new("Folder")
set.Name = "DramaSet"
set.Parent = workspace

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = set
	return p
end

local ORIGIN = Vector3.new(0, 0, -200) -- xa điểm spawn để không vướng
local function at(x, y, z) return ORIGIN + Vector3.new(x, y, z) end

local rng0 = Random.new(3)
-- mặt đường + vỉa hè
part({ Name = "Road", Size = Vector3.new(60, 1, 20), Position = at(0, -0.5, 8),
	Material = Enum.Material.Asphalt, Color = Color3.fromRGB(45, 45, 50) })
part({ Name = "Sidewalk", Size = Vector3.new(60, 1.4, 12), Position = at(0, -0.3, -8),
	Material = Enum.Material.Concrete, Color = Color3.fromRGB(150, 145, 140) })

if CONFIG.Rain then
	-- vũng nước phản chiếu ánh đèn
	for i = 1, 8 do
		local w = rng0:NextNumber(2, 5)
		part({ Name = "Puddle", Size = Vector3.new(w, 0.05, w * 0.6), CanCollide = false,
			Position = at(rng0:NextNumber(-25, 25), 0.03, rng0:NextNumber(2, 14)),
			Material = Enum.Material.Glass, Color = Color3.fromRGB(30, 35, 45),
			Reflectance = 0.35, Transparency = 0.2 })
	end
end

-- ghế đá
part({ Name = "BenchSeat", Size = Vector3.new(7, 0.5, 2), Position = at(0, 1.8, -10),
	Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 75, 50) })
part({ Name = "BenchBack", Size = Vector3.new(7, 2, 0.4), Position = at(0, 3, -11),
	Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 75, 50) })
for _, x in ipairs({ -3, 3 }) do
	part({ Size = Vector3.new(0.4, 1.6, 1.8), Position = at(x, 0.8, -10),
		Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 30, 30) })
end

-- cột đèn đường (đèn ấm, tạo mood)
local function lamp(x)
	part({ Size = Vector3.new(0.5, 12, 0.5), Position = at(x, 6, -13),
		Material = Enum.Material.Metal, Color = Color3.fromRGB(25, 25, 25) })
	local bulb = part({ Size = Vector3.new(1.2, 0.8, 1.2), Position = at(x, 12, -12.5),
		Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 200, 140) })
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 100; light.Range = 25; light.Brightness = 3
	light.Color = Color3.fromRGB(255, 190, 130)
	light.Shadows = true
	light.Parent = bulb
end
lamp(-12); lamp(12)

-- vài tòa nhà làm hậu cảnh
local rng = Random.new(7)
for i = -3, 3 do
	local h = rng:NextNumber(25, 55)
	local b = part({ Size = Vector3.new(14, h, 12), Position = at(i * 16, h / 2, -26),
		Material = Enum.Material.Brick,
		Color = Color3.fromHSV(rng:NextNumber(0, 0.1), 0.3, rng:NextNumber(0.35, 0.6)) })
	b.CastShadow = true
end

------------------------------------------------------------------ DIỄN VIÊN
local function makeActor(name, shirt, pants, cf, userId)
	local desc
	if userId and userId > 0 then
		local ok, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, userId)
		if ok then desc = d else warn("[Drama] Không lấy được avatar của", userId, d) end
	end
	if desc then
		-- bỏ animation riêng của avatar để dùng bộ chuẩn
		for _, k in ipairs({ "IdleAnimation", "WalkAnimation", "RunAnimation", "JumpAnimation", "FallAnimation", "ClimbAnimation", "SwimAnimation" }) do
			desc[k] = 0
		end
	else
	desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromRGB(234, 184, 146)
	desc.TorsoColor = shirt
	desc.LeftArmColor, desc.RightArmColor = desc.HeadColor, desc.HeadColor
	desc.LeftLegColor, desc.RightLegColor = pants, pants
	end
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	model.Name = name
	local anim = model:FindFirstChild("Animate")
	if anim then anim:Destroy() end -- tự điều khiển animation
	model:PivotTo(cf)
	model.Parent = set
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local tracks = {}
	for k, id in pairs(ANIM) do
		local a = Instance.new("Animation"); a.AnimationId = id
		tracks[k] = animator:LoadAnimation(a)
		tracks[k].Looped = (k ~= "wave")
	end
	tracks.idle:Play()
	return { model = model, hum = hum, tracks = tracks, root = model.PrimaryPart }
end

local minh, lan
local function spawnActors(player)
minh = makeActor("Minh", Color3.fromRGB(40, 60, 110), Color3.fromRGB(30, 30, 35),
	CFrame.new(at(-1.5, 3, -8)) * CFrame.Angles(0, math.rad(180), 0),
	CONFIG.MinhUserId > 0 and CONFIG.MinhUserId or player.UserId)
lan = makeActor("Lan", Color3.fromRGB(150, 40, 60), Color3.fromRGB(50, 40, 40),
	CFrame.new(at(28, 3, -6)) * CFrame.Angles(0, math.rad(90), 0), CONFIG.LanUserId)
end

local function walkTo(actor, pos)
	actor.tracks.walk:Play(0.2)
	actor.hum.WalkSpeed = 8
	actor.hum:MoveTo(pos)
	actor.hum.MoveToFinished:Wait()
	actor.tracks.walk:Stop(0.3)
end

local function face(actor, targetPos)
	local p = actor.root.Position
	actor.model:PivotTo(CFrame.lookAt(p, Vector3.new(targetPos.X, p.Y, targetPos.Z)))
end

------------------------------------------------------------------ KỊCH BẢN
-- shot(tên, camPos, lookAt, thời_gian_chuyển, fov)
local function shot(camPos, lookAt, tweenTime, fov)
	cue:FireAllClients("shot", camPos, lookAt, tweenTime or 0, fov or 50)
end
local function line(speaker, text, dur)
	cue:FireAllClients("line", speaker, text)
	task.wait(dur or 3)
end

local function head(actor) return actor.model.Head.Position end

local function runScene()
	cue:FireAllClients("start", CONFIG)
	cue:FireAllClients("title", CONFIG.Title, 4)
	task.wait(4.5)

	-- SHOT 1: toàn cảnh, máy chạy chậm vào
	shot(at(0, 18, 40), at(0, 3, -10), 0, 40)
	task.wait(0.1)
	shot(at(0, 8, 18), at(0, 3, -10), 5, 45)
	line("", "Tối hôm đó, Minh đợi ở chỗ cũ...", 5)

	-- SHOT 2: cận Minh nhìn đồng hồ
	shot(head(minh) + Vector3.new(3, 0.5, 6), head(minh), 0, 35)
	line("Minh", "Lại trễ nữa rồi...", 3)

	-- SHOT 3: Lan bước tới (máy theo)
	shot(at(18, 5, 12), lan.root.Position, 0, 50)
	task.spawn(function()
		for _ = 1, 40 do
			cue:FireAllClients("look", lan.root.Position)
			task.wait(0.15)
		end
	end)
	walkTo(lan, at(2.5, 3, -6))
	face(lan, minh.root.Position)
	lan.tracks.wave:Play(0.2)

	-- Minh đứng dậy, quay sang Lan
	face(minh, lan.root.Position)

	-- SHOT 4/5: shot - reverse shot qua vai
	local function overShoulder(from, to, fov)
		local dir = (head(to) - head(from)).Unit
		local right = dir:Cross(Vector3.yAxis).Unit
		shot(head(from) - dir * 3 + right * 1.6 + Vector3.new(0, 0.4, 0), head(to), 0, fov or 40)
	end

	overShoulder(minh, lan)
	line("Lan", "Xin lỗi... em có chuyện muốn nói.", 3)
	overShoulder(lan, minh)
	line("Minh", "Lại là chuyện đó à?", 2.5)
	overShoulder(minh, lan, 32)
	line("Lan", "Tháng sau em đi rồi. Sang nước ngoài.", 3.5)

	-- SHOT 6: cận mặt Minh, zoom chậm (dramatic)
	shot(head(minh) + (head(lan) - head(minh)).Unit * 5, head(minh), 0, 35)
	shot(head(minh) + (head(lan) - head(minh)).Unit * 5, head(minh), 3, 18)
	if CONFIG.Rain then cue:FireAllClients("thunder") end
	line("Minh", "...", 2)
	line("Minh", "Sao bây giờ em mới nói?", 3)

	overShoulder(minh, lan, 30)
	line("Lan", "Vì em sợ... anh sẽ giữ em lại.", 3.5)

	-- SHOT 7: góc rộng hai người, im lặng
	shot(at(-10, 4, 6), (minh.root.Position + lan.root.Position) / 2, 0, 50)
	task.wait(2)
	line("Lan", "Em xin lỗi.", 2.5)

	-- Lan bỏ đi
	shot(at(0, 6, 14), minh.root.Position, 0, 45)
	task.spawn(walkTo, lan, at(-30, 3, -6))
	task.wait(1.5)
	cue:FireAllClients("shake", 0.6)
	line("Minh", "Lan...!", 2)

	-- SHOT 8: cảnh kết, máy kéo lên cao, Minh đứng một mình dưới đèn
	shot(at(0, 30, 30), minh.root.Position, 6, 55)
	line("", "Có những lời, nói ra rồi... không thể rút lại.", 5)

	cue:FireAllClients("end")
end

local running = false
local function onPlayer(player)
	if running then return end
	running = true
	if not player.Character then player.CharacterAdded:Wait() end
	spawnActors(player)
	task.wait(3)
	runScene()
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
