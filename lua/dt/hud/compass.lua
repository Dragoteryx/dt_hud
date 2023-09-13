DT_Hud.CompassRotateNorth = DT_Core.ConVar("dt_hud_compass_rotate_north", "0")
DT_Hud.CompassMaxRange = DT_Core.ConVar("dt_hud_compass_max_range", "1500")
DT_Hud.CompassTickrate = DT_Core.ConVar("dt_hud_compass_tickrate", "10")

if SERVER then
	util.AddNetworkString("DT/HUD_PlayerDeath")
	util.AddNetworkString("DT/HUD_UpdateCompass")

	hook.Add("PostPlayerDeath", "DT/HUD_PlayerDeath", function(ply)
		net.Start("DT/HUD_PlayerDeath")
		net.WriteVector(ply:GetPos())
		net.Send(ply)
	end)

	local LAST_UPDATE = 0
	hook.Add("Think", "DT/HUD_UpdateCompass", function()
		local delay = 1 / DT_Hud.CompassTickrate:GetFloat()
		if CurTime() < LAST_UPDATE + delay then return end
		LAST_UPDATE = CurTime()

		local range = DT_Hud.CompassMaxRange:GetFloat()
		for _, ply in ipairs(player.GetHumans()) do
			local viewEnt = ply:GetViewEntity()
			local me = IsValid(viewEnt) and viewEnt or ply

			local data = {}
			for ent in DT_Core.IterTargets() do
				if ent == ply or ent == me then continue end
				local dist = (ent:GetPos() - me:GetPos()):Length2D()
				if dist <= range then
					table.insert(data, {
						ent = ent,
						disp = ent:DT_GetDisposition(me),
						pos = ent:WorldSpaceCenter(),
						vel = ent:DT_GetVelocity()
					})
				end
			end

			net.Start("DT/HUD_UpdateCompass")
			net.WriteUInt(#data, 16)
			for _, entData in ipairs(data) do
				net.WriteEntity(entData.ent)
				net.WriteUInt(entData.disp, 3)
				net.WriteVector(entData.pos)
				net.WriteVector(entData.vel)
			end
			net.Send(ply)
		end
	end)

else

	DT_Hud.CompassEnabled = DT_Core.ClientConVar("dt_hud_compass", "1")
	DT_Hud.CompassLastDeath = DT_Core.ClientConVar("dt_hud_compass_last_death", "1")

	local LAST_DEATH = nil
	net.Receive("DT/HUD_PlayerDeath", function()
		LAST_DEATH = net.ReadVector()
	end)
	hook.Add("PostCleanupMap", "DT/HUD_CleanupLastDeath", function()
		LAST_DEATH = nil
	end)

	local COMPASS_DATA = {}
	net.Receive("DT/HUD_UpdateCompass", function()
		COMPASS_DATA = {}
		local n = net.ReadUInt(16)
		for _ = 1, n do
			table.insert(COMPASS_DATA, {
				ent = net.ReadEntity(),
				disp = net.ReadUInt(3),
				pos = net.ReadVector(),
				vel = net.ReadVector(),
				time = CurTime()
			})
		end

		local eyePos = EyePos()
		table.sort(COMPASS_DATA, function(entData1, entData2)
			if not IsValid(entData1.ent) then return true end
			if not IsValid(entData2.ent) then return false end
			local dist1 = eyePos:DistToSqr(entData1.ent:GetPos())
			local dist2 = eyePos:DistToSqr(entData2.ent:GetPos())
			return dist1 > dist2
		end)
	end)

	local CARDINAL_DIRECTIONS = {
		{ text = "#dt_hud.compass.north", bearing = 0 },
		{ text = "#dt_hud.compass.east", bearing = 90 },
		{ text = "#dt_hud.compass.south", bearing = 180 },
		{ text = "#dt_hud.compass.west", bearing = 270 }
	}

	hook.Add("DT/HUD_Draw", "DT/HUD_DrawCompass", function()
		if not DT_Hud.CompassEnabled:GetBool() then return end
		local ctx = DT_Hud.DrawContext()
		local centerX = ctx:GetCenter()
		ctx:SetOrigin(centerX - 22, 1)
		ctx:HUD_DrawBackground(0, 0, 44, 3)
		ctx:MoveOrigin(22, 1.5)

		local north = DT_Hud.CompassRotateNorth:GetFloat()
		local function CalculateBearing(pos)
			return -((pos - EyePos()):Angle().y + north) % 360
		end

		local myBearing = CalculateBearing(EyePos() + EyeVector())
		local function CalculateX(bearing)
			local diff = math.abs(myBearing - bearing)
			if diff <= 50 then
				if myBearing >= bearing then
					return -diff * 0.4
				else
					return diff * 0.4
				end
			elseif diff > 310 then
				if myBearing > bearing then
					return CalculateX(bearing + 360)
				else
					return CalculateX(bearing - 360)
				end
			end
		end

		for bearing = 0, 360, 22.5 do
			if bearing % 90 == 0 then continue end
			local x = CalculateX(bearing)
			if isnumber(x) then
				ctx:CreateRectangle(x - 0.05, -0.75, 0.1, 1.5)
					:Outline():Fill()
			end
		end

		for _, entData in ipairs(COMPASS_DATA) do
			if not IsValid(entData.ent) then continue end
			local pos
			if entData.ent:IsDormant() then
				local lag = CurTime() - entData.time
				pos = entData.pos + entData.vel * lag
			else pos = entData.ent:WorldSpaceCenter() end
			local bearing = CalculateBearing(pos)
			local x = CalculateX(bearing)
			if isnumber(x) then
				local tr = util.TraceLine({
					start = EyePos(),
					endpos = pos,
					mask = MASK_VISIBLE
				})

				local color = DT_Hud.GetDispositionColor(entData.disp)
				local dist = GetViewEntity():GetPos():Distance(pos)
				local size = 1 - dist / DT_Hud.CompassMaxRange:GetFloat() * 0.5

				local poly = ctx:CreateDiamond(x, 0, 0.85 * size)
				if tr.Hit then poly:Stroke(color)
				else poly:Outline():Fill(color) end
			end
		end

		if LAST_DEATH and DT_Hud.CompassLastDeath:GetBool() then
			local bearing = CalculateBearing(LAST_DEATH)
			local x = CalculateX(bearing)
			if isnumber(x) then
				ctx:DrawMaterial(x, 0, 1.6, DT_Hud.DeathIcon, true)
			end
		end

		for _, dir in ipairs(CARDINAL_DIRECTIONS) do
			local x = CalculateX(dir.bearing)
			if isnumber(x) then
				ctx:DrawText(x, 0, dir.text, {
					xAlign = TEXT_ALIGN_CENTER,
					yAlign = TEXT_ALIGN_CENTER,
					font = "DT/HUD_Large",
					outline = true
				})
			end
		end
	end)

end