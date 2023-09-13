if SERVER then
	util.AddNetworkString("DT/Hud.EntityDeath")

	local function SendToKillfeed(attacker, victim)
		for _, ply in pairs(player.GetHumans()) do
			net.Start("DT/Hud.EntityDeath")
			if attacker:IsPlayer() then
				net.WriteString(attacker:Nick())
				net.WriteBool(true)
			else
				net.WriteString(attacker:GetClass())
				net.WriteBool(false)
			end
			net.WriteUInt(attacker:DT_GetDisposition(ply), 3)
			if victim:IsPlayer() then
				net.WriteString(victim:Nick())
				net.WriteBool(true)
			else
				net.WriteString(victim:GetClass())
				net.WriteBool(false)
			end
			net.WriteUInt(victim:DT_GetDisposition(ply), 3)
			net.Send(ply)
		end
	end

	hook.Add("PlayerDeath", "DT/Hud.SendPlayerDeathToKillfeed", function(ply, _, attacker)
		if not IsValid(attacker) then attacker = ply end
		SendToKillfeed(attacker, ply)
	end)

	hook.Add("OnNPCKilled", "DT/Hud.SendNPCDeathToKillfeed", function(npc, attacker)
		if not IsValid(attacker) then attacker = npc end
		SendToKillfeed(attacker, npc)
	end)

else

	DT_Hud.KillfeedEnabled = DT_Core.ClientConVar("dt_hud_killfeed", "1")
	DT_Hud.KillfeedMaximum = DT_Core.ClientConVar("dt_hud_killfeed_maximum", "20")
	DT_Hud.KillfeedDuration = DT_Core.ClientConVar("dt_hud_killfeed_duration", "10")

	local KILLFEED = {}
	net.Receive("DT/Hud.EntityDeath", function()
		local duration = DT_Hud.KillfeedDuration:GetFloat()
		local entry = {
			time = CurTime(),
			duration = duration,
			attacker = {
				Name = net.ReadString(),
				IsPlayer = net.ReadBool(),
				Disposition = net.ReadUInt(3)
			},
			victim = {
				Name = net.ReadString(),
				IsPlayer = net.ReadBool(),
				Disposition = net.ReadUInt(3)
			}
		}
		table.insert(KILLFEED, entry)
		timer.Simple(duration, function()
			table.RemoveByValue(KILLFEED, entry)
		end)
	end)

	concommand.Add("dt_hud_cmd_clear_killfeed", function()
		KILLFEED = {}
	end)

	hook.Add("DrawDeathNotice", "DT/Hud.HideKillfeed", function()
		if DT_Hud.Enabled:GetBool() and DT_Hud.KillfeedEnabled:GetBool() then
			return false
		end
	end)

	hook.Add("DT/Hud.Draw", "DT/Hud.DrawKillfeed", function()
		if not DT_Hud.KillfeedEnabled:GetBool() then return end
		local ctx = DT_Hud.DrawContext()
		ctx:SetOriginWrapping(-1, 1)

		for i = 1, math.min(#KILLFEED, DT_Hud.KillfeedMaximum:GetInt()) do
			local entry = KILLFEED[i]
			local attackerColor = DT_Hud.GetDispositionColor(entry.attacker.Disposition)
			local attackerText = entry.attacker.IsPlayer and entry.attacker.Name or language.GetPhrase(entry.attacker.Name)
			local attackerLength = ctx:GetTextSize(attackerText)
			local victimColor = DT_Hud.GetDispositionColor(entry.victim.Disposition)
			local victimText = entry.victim.IsPlayer and entry.victim.Name or language.GetPhrase(entry.victim.Name)
			local victimLength = ctx:GetTextSize(victimText)
			local length = math.max(16, attackerLength + victimLength) + 6
			local middleLength = length - 2 - attackerLength - victimLength
			local offsetLength = length + 1
			local enterOffset = offsetLength - offsetLength * math.min(1, (CurTime() - entry.time) * 120 / offsetLength)
			local leaveOffset = offsetLength - offsetLength * math.min(1, (entry.duration - (CurTime() - entry.time)) * 120 / offsetLength)
			local offset = -length + math.max(enterOffset, leaveOffset)
			ctx:MoveOrigin(offset, 0)
			ctx:Hud_DrawBackground(0, 0, length, 3)
			ctx:DrawText(1, 0.85, attackerText, {color = attackerColor, outline = true})
			ctx:DrawMaterial(1 + attackerLength + middleLength / 2, 1.5, 2, DT_Hud.DeathIcon, true)
			ctx:DrawText(length - 1, 0.85, victimText, {color = victimColor, xAlign = TEXT_ALIGN_RIGHT, outline = true})
			ctx:MoveOrigin(-offset, 3.5)
		end
	end)

end