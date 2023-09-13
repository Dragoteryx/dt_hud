function DT_Hud.DrawContext(width, height)
	local ctx = DT_Core.DrawContext(width, height)
	ctx:SetDefaultColor(DT_Hud.MainColor:GetValue())
	ctx:SetDefaultOutlineColor(Color(0, 0, 0, 75))
	ctx:SetScale(DT_Hud.Scale:GetFloat())
	ctx:SetDefaultFont("DT/HUD_Default")
	return ctx
end

function DT_Core.DrawContext.__index:HUD_DrawBackground(x, y, length, height)
	self:CreateRectangle(x, y, length, height)
		:Blur(DT_Hud.BlurQuality:GetInt())
		:Fill(DT_Hud.BackgroundColor:GetValue())
end

function DT_Core.DrawContext.__index:HUD_DrawBar(x, y, options)
	local value, max = options.value, options.max
	local length, height = options.length, options.height

	local background = self:CreateRectangle(x, y, length, height)
	if options.blur then background:Blur(DT_Hud.BlurQuality:GetInt()) end
	background:Fill(DT_Hud.BackgroundColor:GetValue(), nil)

	local barLength = math.min(value, max) / max * length
	local bar = self:CreateRectangle(x, y, barLength, height)
	if options.outline then bar:Outline() end
	bar:Fill(options.color)

	if math.Round(value) > 0 then
		self:DrawText(x + 0.5, y + height / 2, math.Round(value), {
			xAlign = TEXT_ALIGN_LEFT,
			yAlign = TEXT_ALIGN_CENTER,
			outline = true
		})
	end
end