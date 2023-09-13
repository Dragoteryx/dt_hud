DT_Hud.Color = DT_Core.CreateStruct()

function DT_Hud.Color:__new(name, color)
	self.Name = name
	self.Red = DT_Core.ClientConVar("dt_hud_color_" .. name .. "_r", tostring(color.r))
	self.Green = DT_Core.ClientConVar("dt_hud_color_" .. name .. "_g", tostring(color.g))
	self.Blue = DT_Core.ClientConVar("dt_hud_color_" .. name .. "_b", tostring(color.b))
	self.Alpha = DT_Core.ClientConVar("dt_hud_color_" .. name .. "_a", tostring(color.a))
end

function DT_Hud.Color.__index:GetValue()
	return Color(
		self.Red:GetFloat(),
		self.Green:GetFloat(),
		self.Blue:GetFloat(),
		self.Alpha:GetFloat()
	)
end

function DT_Hud.Color.__index:AddToPanel(panel)
	panel:AddControl("color", {
		label = "#dt_hud.menu.client.colors." .. self.Name,
		red = self.Red:GetName(),
		green = self.Green:GetName(),
		blue = self.Blue:GetName()
	})
end

function DT_Hud.Color.__index:Randomize()
	self.Red:SetInt(math.random(0, 255))
	self.Green:SetInt(math.random(0, 255))
	self.Blue:SetInt(math.random(0, 255))
end

function DT_Hud.Color.__index:Reset()
	self.Red:Revert()
	self.Green:Revert()
	self.Blue:Revert()
	self.Alpha:Revert()
end