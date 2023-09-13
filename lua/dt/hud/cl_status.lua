DT_Hud.StatusEnabled = DT_Core.ClientConVar("dt_hud_status", "1")
DT_Hud.StatusStatistics = DT_Core.ClientConVar("dt_hud_status_statistics", "1")
DT_Hud.StatusStatisticsSpeed = DT_Core.ClientConVar("dt_hud_status_statistics_speed", "1")
DT_Hud.StatusStatisticsFramerate = DT_Core.ClientConVar("dt_hud_status_statistics_framerate", "1")
DT_Hud.StatusStatisticsLatency = DT_Core.ClientConVar("dt_hud_status_statistics_latency", "1")

local HEALTH = nil
local ARMOR = nil
hook.Add("Think", "DT/Hud.HealthArmorLerp", function()
	local ply = LocalPlayer()
	if ply:Alive() then
		HEALTH = HEALTH and Lerp(0.05, HEALTH, ply:Health()) or ply:Health()
		ARMOR = ARMOR and Lerp(0.05, ARMOR, ply:Armor()) or ply:Armor()
	else
		HEALTH = HEALTH and Lerp(0.05, HEALTH, 0) or 0
		ARMOR = ARMOR and Lerp(0.05, ARMOR, 0) or 0
	end
end)

local FPS = -1
local PING = -1
local LAST_INFO_REFRESH = 0
hook.Add("Think", "DT/Hud.RefreshFPSPing", function()
	if CurTime() < LAST_INFO_REFRESH + 1 then return end
	PING = math.Round(LocalPlayer():Ping())
	FPS = math.Round(1 / FrameTime())
	LAST_INFO_REFRESH = CurTime()
end)

hook.Add("DT/Hud.ShouldDraw", "DT/Hud.HideStatus", function(name)
	if not DT_Hud.StatusEnabled:GetBool() then return end
	if name == "CHudHealth" or name == "CHudBattery" then
		return false
	end
end)

hook.Add("DT/Hud.Draw", "DT/Hud.DrawStatus", function()
	if not DT_Hud.StatusEnabled:GetBool() then
		DT_Hud.DrawLeftNotifications(-16)
	else
		local ply = LocalPlayer()
		local ctx = DT_Hud.DrawContext()
		ctx:SetOriginWrapping(1, -4)

		-- armor --

		local armor = ARMOR or ply:Armor()
		local maxArmor = ply:GetMaxArmor()
		ctx:Hud_DrawBackground(0, 0, 22, 3)
		ctx:DrawMaterial(1.5, 1.5, 2, DT_Hud.ShieldIcon, true)
		ctx:Hud_DrawBar(3, 0.5, {
			length = 18.5, height = 2,
			value = armor, max = maxArmor,
			color = DT_Hud.ArmorColor:GetValue(),
			outline = true
		})
		ctx:MoveOrigin(0, -3.5)

		-- health --

		local health = HEALTH or ply:Health()
		local maxHealth = ply:GetMaxHealth()
		ctx:Hud_DrawBackground(0, 0, 22, 3)
		ctx:DrawMaterial(1.5, 1.5, 2, DT_Hud.HealthIcon, true)
		ctx:Hud_DrawBar(3, 0.5, {
			length = 18.5, height = 2,
			value = health, max = maxHealth,
			color = DT_Hud.HealthColor:GetValue(),
			outline = true
		})
		ctx:MoveOrigin(0, -3.5)

		if DT_Hud.StatusStatistics:GetBool() then
			local displayed = 0

			-- speed --

			if DT_Hud.StatusStatisticsSpeed:GetBool() then
				displayed = displayed + 1

				local veh = ply:DT_GetVehicle()
				local icon = DT_Hud.SpeedIcon
				local speed = ply:GetVelocity():Length()
				if IsValid(veh) then
					icon = DT_Hud.GetVehicleIcon(veh)
					speed = veh:GetVelocity():Length()
				end

				local text = "???????"
				local syst = DT_Hud.MeasuringSystem:GetString()
				if syst == "metric" then
					local template = language.GetPhrase("dt_hud.speed.metric")
					text = string.Replace(template, "$SPEED", math.Round(speed * 0.06858))
				elseif syst == "imperial" then
					local template = language.GetPhrase("dt_hud.speed.imperial")
					text = string.Replace(template, "$SPEED", math.Round(speed * 0.04261362318))
				elseif syst == "hammer" then
					local template = language.GetPhrase("dt_hud.speed.hammer")
					text = string.Replace(template, "$SPEED", math.Round(speed))
				end

				ctx:Hud_DrawBackground(0, 0, 9, 3)
				ctx:DrawMaterial(1.5, 1.5, 2, icon, true)
				ctx:DrawText(8.5, 1.5, text, {xAlign = TEXT_ALIGN_RIGHT, yAlign = TEXT_ALIGN_CENTER, outline = true})
				ctx:MoveOrigin(9.5, 0)
			end

			-- framerate --

			if DT_Hud.StatusStatisticsFramerate:GetBool() then
				displayed = displayed + 1

				ctx:Hud_DrawBackground(0, 0, 6, 3)
				ctx:DrawMaterial(1.5, 1.5, 2, DT_Hud.FPSIcon, true)
				ctx:DrawText(5.5, 1.5, FPS, {xAlign = TEXT_ALIGN_RIGHT, yAlign = TEXT_ALIGN_CENTER, outline = true})
				ctx:MoveOrigin(6.5, 0)
			end

			-- latency --

			if DT_Hud.StatusStatisticsLatency:GetBool() then
				displayed = displayed + 1

				ctx:Hud_DrawBackground(0, 0, 6, 3)
				ctx:DrawMaterial(1.5, 1.6, 2.1, DT_Hud.PingIcon, true)
				ctx:DrawText(5.5, 1.5, PING, {xAlign = TEXT_ALIGN_RIGHT, yAlign = TEXT_ALIGN_CENTER, outline = true})
			end

			if displayed > 0 then
				ctx:MoveOrigin(0, -3.5)
			end
		end

		local _, y = ctx:GetOrigin()
		DT_Hud.DrawLeftNotifications(y - 0.5)
	end
end)