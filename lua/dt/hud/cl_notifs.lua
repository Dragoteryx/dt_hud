DT_Hud.Notifications = DT_Core.ClientConVar("dt_hud_notifications", "1")

local LEFT_NOTIFICATIONS = {}
function DT_Hud.AddLeftNotification(text, icon, duration)
	local notif = {
		text = text,
		icon = icon,
		duration = duration,
		time = CurTime(),
		progress = false
	}

	table.insert(LEFT_NOTIFICATIONS, notif)
	timer.Simple(duration, function()
		table.RemoveByValue(LEFT_NOTIFICATIONS, notif)
	end)
end

local RIGHT_NOTIFICATIONS = {}
function DT_Hud.AddRightNotification(text, icon, duration)
	local notif = {
		text = text,
		icon = icon,
		duration = duration,
		time = CurTime()
	}

	table.insert(RIGHT_NOTIFICATIONS, notif)
	timer.Simple(duration, function()
		table.RemoveByValue(RIGHT_NOTIFICATIONS, notif)
	end)
end

local notification_AddLegacy = notification.AddLegacy
function notification.AddLegacy(text, type, duration)
	if DT_Hud.Enabled:GetBool() and DT_Hud.Notifications:GetBool() then
		local icon
		if type == NOTIFY_ERROR then icon = DT_Hud.NotifyError
		elseif type == NOTIFY_UNDO then icon = DT_Hud.NotifyUndo
		elseif type == NOTIFY_HINT then icon = DT_Hud.NotifyHint
		elseif type == NOTIFY_CLEANUP then icon = DT_Hud.NotifyCleanup
		else icon = DT_Hud.NotifyGeneric end
		DT_Hud.AddLeftNotification(text, icon, duration)
	else
		return notification_AddLegacy(text, type, duration)
	end
end

local notification_AddProgress = notification.AddProgress
function notification.AddProgress(id, text, ratio)
	if DT_Hud.Enabled:GetBool() and DT_Hud.Notifications:GetBool() then
		for _, notif in ipairs(RIGHT_NOTIFICATIONS) do
			if notif.progress and notif.id == id then
				notif.text = text
				notif.ratio = ratio
				return
			end
		end
		table.insert(RIGHT_NOTIFICATIONS, {
			id = id,
			text = text,
			ratio = ratio,
			time = CurTime(),
			progress = true
		})
	else
		return notification_AddProgress(id, text, ratio)
	end
end

local notification_Kill = notification.Kill
function notification.Kill(id)
	if DT_Hud.Enabled:GetBool() and DT_Hud.Notifications:GetBool() then
		for _, notif in ipairs(LEFT_NOTIFICATIONS) do
			if notif.progress and notif.id == id and not notif.removed then
				notif.removed = CurTime()
				return
			end
		end
	else
		return notification_Kill(id)
	end
end

hook.Add("HUDAmmoPickedUp", "DT/Hud.AmmoPickedUp", function(ammo, amount)
	if not DT_Hud.Enabled:GetBool() or not DT_Hud.Notifications:GetBool() then return end
	local template = language.GetPhrase("dt_hud.pickup.ammo")
	local name = language.GetPhrase("#" .. ammo .. "_ammo")
	if string.StartWith(name, "#") then name = ammo end
	local phrase = string.Replace(template, "$NAME", name)
	phrase = string.Replace(phrase, "$AMOUNT", amount)
	DT_Hud.AddRightNotification(phrase, DT_Hud.AmmoIcon, 5)
	return false
end)

hook.Add("HUDItemPickedUp", "DT/Hud.ItemPickedUp", function(item)
	if not DT_Hud.Enabled:GetBool() or not DT_Hud.Notifications:GetBool() then return end
	local template = language.GetPhrase("dt_hud.pickup.item")
	local name = language.GetPhrase(item)
	local phrase = string.Replace(template, "$NAME", name)
	DT_Hud.AddLeftNotification(phrase, DT_Hud.PickUpIcon, 5)
	return false
end)

hook.Add("HUDWeaponPickedUp", "DT/Hud.WeaponPickedUp", function(weap)
	if not DT_Hud.Enabled:GetBool() or not DT_Hud.Notifications:GetBool() then return end
	local template = language.GetPhrase("dt_hud.pickup.weapon")
	local name = weap:DT_GetNiceName()
	local phrase = string.Replace(template, "$NAME", name)
	DT_Hud.AddRightNotification(phrase, DT_Hud.WeaponIcon, 5)
	return false
end)

function DT_Hud.DrawLeftNotifications(y)
	if not DT_Hud.Notifications:GetBool() then return end
	local ctx = DT_Hud.DrawContext()
	ctx:SetOriginWrapping(1, y)

	for _, notif in ipairs(LEFT_NOTIFICATIONS) do
		if notif.progress then
			-- todo
		else
			local length = math.max(17.5, ctx:GetTextSize(notif.text)) + 4.5
			local offsetLength = length + 1
			local enterOffset = offsetLength - offsetLength * math.min(1, (CurTime() - notif.time) * 120 / offsetLength)
			local leaveOffset = offsetLength - offsetLength * math.min(1, (notif.duration - (CurTime() - notif.time)) * 120 / offsetLength)
			local offset = -math.max(enterOffset, leaveOffset)
			ctx:MoveOrigin(offset, 0)
			ctx:Hud_DrawBackground(0, 0, length, 3)
			ctx:DrawMaterial(1.5, 1.5, 2, notif.icon, true)
			ctx:DrawText(3.5, 1.5, notif.text, {yAlign = TEXT_ALIGN_CENTER, outline = true})
			ctx:MoveOrigin(-offset, -3.5)
		end
	end
end

function DT_Hud.DrawRightNotifications(y)
	if not DT_Hud.Notifications:GetBool() then return end
	local ctx = DT_Hud.DrawContext()
	ctx:SetOriginWrapping(-1, y)

	for _, notif in ipairs(RIGHT_NOTIFICATIONS) do
		local length = math.max(17.5, ctx:GetTextSize(notif.text)) + 4.5
		local offsetLength = length + 1
		local enterOffset = offsetLength - offsetLength * math.min(1, (CurTime() - notif.time) * 120 / offsetLength)
		local leaveOffset = offsetLength - offsetLength * math.min(1, (notif.duration - (CurTime() - notif.time)) * 120 / offsetLength)
		local offset = -length + math.max(enterOffset, leaveOffset)
		ctx:MoveOrigin(offset, 0)
		ctx:Hud_DrawBackground(0, 0, length, 3)
		ctx:DrawMaterial(1.5, 1.5, 2, notif.icon, true)
		ctx:DrawText(3.5, 1.5, notif.text, {yAlign = TEXT_ALIGN_CENTER, outline = true})
		ctx:MoveOrigin(-offset, -3.5)
	end
end