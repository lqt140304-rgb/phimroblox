-- CinematicLighting: đặt ánh sáng "điện ảnh" cho cả map.
-- Có thể dán nguyên file này vào Command Bar trong Studio để áp dụng ngay khi đang dựng cảnh.
local Lighting = game:GetService("Lighting")

local PRESET = {
	ClockTime = 17.6,          -- hoàng hôn
	Brightness = 2.5,
	ExposureCompensation = 0.1,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	Ambient = Color3.fromRGB(40, 35, 45),
	OutdoorAmbient = Color3.fromRGB(110, 95, 110),
}

pcall(function() Lighting.Technology = Enum.Technology.Future end)
for k, v in pairs(PRESET) do Lighting[k] = v end

local function ensure(className, parent, props)
	local obj = parent:FindFirstChildOfClass(className) or Instance.new(className)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

ensure("Atmosphere", Lighting, {
	Density = 0.35, Offset = 0.2, Haze = 1.8, Glare = 0.6,
	Color = Color3.fromRGB(255, 210, 180), Decay = Color3.fromRGB(110, 80, 120),
})
ensure("BloomEffect", Lighting, { Intensity = 0.6, Size = 30, Threshold = 1.2 })
ensure("ColorCorrectionEffect", Lighting, {
	Brightness = 0.02, Contrast = 0.15, Saturation = 0.1,
	TintColor = Color3.fromRGB(255, 240, 230),
})
ensure("DepthOfFieldEffect", Lighting, {
	FarIntensity = 0.35, FocusDistance = 12, InFocusRadius = 10, NearIntensity = 0.2,
})
ensure("SunRaysEffect", Lighting, { Intensity = 0.08, Spread = 0.8 })
ensure("Clouds", workspace.Terrain, { Cover = 0.55, Density = 0.6 })

print("[CinematicLighting] Đã áp dụng preset hoàng hôn.")
