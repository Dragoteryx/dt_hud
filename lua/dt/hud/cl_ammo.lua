DT_Hud.AmmoEnabled = DT_Core.ClientConVar("dt_hud_ammo", "1")

local function DrawAmmoIcon(ctx, color)
	ctx:Hud_DrawBackground(0, 0, 3, 3)
	ctx:DrawMaterial(1.5, 1.5, 2, DT_Hud.AmmoIcon, {
		outline = true,
		color = color
	})
end

local function DrawAmmoClip(ctx, color, values)
	DrawAmmoIcon(ctx, color)
	ctx:Hud_DrawBackground(3.5, 0, 13, 3)
	ctx:DrawText(6.75, 1.5, values.clip, {
		font = "DT/Hud.Large",
		xAlign = TEXT_ALIGN_CENTER,
		yAlign = TEXT_ALIGN_CENTER,
		outline = true,
		color = color
	})
	ctx:DrawText(10, 1.5, "/", {
		xAlign = TEXT_ALIGN_CENTER,
		yAlign = TEXT_ALIGN_CENTER,
		font = "DT/Hud.Large",
		outline = true,
		color = color
	})
	ctx:DrawText(13.25, 1.5, values.clipSize, {
		xAlign = TEXT_ALIGN_CENTER,
		yAlign = TEXT_ALIGN_CENTER,
		font = "DT/Hud.Large",
		outline = true,
		color = color
	})

	ctx:Hud_DrawBackground(17, 0, 5, 3)
	ctx:DrawText(19.5, 1.5, values.ammoCount, {
		xAlign = TEXT_ALIGN_CENTER,
		yAlign = TEXT_ALIGN_CENTER,
		font = "DT/Hud.Large",
		outline = true,
		color = color
	})

	ctx:MoveOrigin(0, -3.5)
	return true
end

local function DrawAmmoCount(ctx, color, count)
	DrawAmmoIcon(ctx, color)
	ctx:Hud_DrawBackground(3.5, 0, 18.5, 3)
	ctx:DrawText(12.75, 1.5, count, {
		xAlign = TEXT_ALIGN_CENTER,
		yAlign = TEXT_ALIGN_CENTER,
		font = "DT/Hud.Large",
		outline = true,
		color = color
	})
	ctx:MoveOrigin(0, -3.5)
	return true
end

local function DrawInfiniteAmmo(ctx, color)
	DrawAmmoIcon(ctx, color)
	ctx:Hud_DrawBackground(3.5, 0, 18.5, 3)
	ctx:DrawText(12.75, 1.3, "∞", {
		xAlign = TEXT_ALIGN_CENTER,
		yAlign = TEXT_ALIGN_CENTER,
		font = "DT/Hud.Huge",
		outline = true,
		color = color
	})
	ctx:MoveOrigin(0, -3.5)
	return true
end

local function DrawAmmo(ctx, color, options)
	if options.ammoType == -1 then
		return DrawInfiniteAmmo(ctx, color)
	elseif options.clipSize == -1 then
		return DrawAmmoCount(ctx, color, options.ammoCount)
	else
		return DrawAmmoClip(ctx, color, options)
	end
end

hook.Add("DT/Hud.ShouldDraw", "DT/Hud.HideAmmo", function(name)
	if not DT_Hud.AmmoEnabled:GetBool() then return end
	if name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
		return false
	end
end)

hook.Add("DT/Hud.Draw", "DT/Hud.DrawAmmo", function()
	if not DT_Hud.AmmoEnabled:GetBool() then
		DT_Hud.DrawRightNotifications(-16)
	else
		local ply = LocalPlayer()
		if ply:InVehicle() then return end
		local weap = ply:GetActiveWeapon()
		if not IsValid(weap) then return end
		local ctx = DT_Hud.DrawContext()
		ctx:SetOriginWrapping(-23, -4)
		local displayed = 0

		-- secondary ammo --

		do
			local clip = weap:Clip2()
			local clipSize = weap:GetMaxClip2()
			local ammoType = weap:GetSecondaryAmmoType()
			local ammoCount = ply:GetAmmoCount(ammoType)
			if DrawAmmo(ctx, DT_Hud.SecondaryAmmoColor:GetValue(), {
				clip = clip, clipSize = clipSize,
				ammoCount = ammoCount,
				ammoType = ammoType
			}) then
				displayed = displayed + 1
			end
		end

		-- primary ammo --

		do
			local clip = weap:Clip1()
			local clipSize = weap:GetMaxClip1()
			local ammoType = weap:GetPrimaryAmmoType()
			local ammoCount = ply:GetAmmoCount(ammoType)
			if DrawAmmo(ctx, DT_Hud.PrimaryAmmoColor:GetValue(), {
				clip = clip, clipSize = clipSize,
				ammoCount = ammoCount,
				ammoType = ammoType
			}) then
				displayed = displayed + 1
			end
		end

		-- weapon name --

		if displayed == 0 then
			DT_Hud.DrawRightNotifications(-4)
		else
			ctx:Hud_DrawBackground(0, 0, 22, 3)
			ctx:DrawText(1, 1.5, weap:DT_GetNiceName(), {
				yAlign = TEXT_ALIGN_CENTER,
				maxLength = 20,
				outline = true,
			})

			local _, y = ctx:GetOrigin()
			DT_Hud.DrawRightNotifications(y - 4)
		end
	end
end)