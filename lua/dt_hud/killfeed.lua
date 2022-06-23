if SERVER then
  util.AddNetworkString("DT_HUD/EntityDeath")

  local function SendToKillfeed(attacker, victim)
    for _, ply in pairs(player.GetHumans()) do
      net.Start("DT_HUD/EntityDeath")
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

  hook.Add("PlayerDeath", "DT_HUD/SendPlayerDeathToKillfeed", function(ply, _, attacker)
    SendToKillfeed(attacker, ply)
  end)

  hook.Add("OnNPCKilled", "DT_HUD/SendNPCDeathToKillfeed", function(npc, attacker)
    SendToKillfeed(attacker, npc)
  end)

else

  DT_HUD.KillfeedEnabled = DT_Lib.ClientConVar("dt_hud_killfeed", "1")
  DT_HUD.KillfeedMaximum = DT_Lib.ClientConVar("dt_hud_killfeed_maximum", "10")
  DT_HUD.KillfeedDuration = DT_Lib.ClientConVar("dt_hud_killfeed_duration", "10")

  local KILLFEED = {}
  net.Receive("DT_HUD/EntityDeath", function()
    local duration = DT_HUD.KillfeedDuration:GetFloat()
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

  hook.Add("DrawDeathNotice", "DT_HUD/HideKillfeed", function()
    if DT_HUD.Enabled:GetBool() and DT_HUD.KillfeedEnabled:GetBool() then
      return false
    end
  end)

  hook.Add("DT_HUD/Paint", "DT_HUD/Killfeed", function()
    if not DT_HUD.KillfeedEnabled:GetBool() then return end

    local ctx = DT_HUD.DrawContext()
    if DT_HUD.RadarAllowed:GetBool() and DT_HUD.RadarEnabled:GetBool() then
      ctx:SetOrigin(-23.5, 3 + 30*DT_HUD.RadarScale:GetFloat())
    else ctx:SetOrigin(-23.5, 1) end

    for i = 1, math.min(#KILLFEED, DT_HUD.KillfeedMaximum:GetInt()) do
      local entry = KILLFEED[i]
      local enterOffset = 24 - 24 * math.min(1, (CurTime() - entry.time) * 5)
      local leaveOffset = 24 - 24 * math.min(1, (entry.duration - (CurTime() - entry.time)) * 5)
      local offset = math.max(enterOffset, leaveOffset)
      ctx:AddOffset(offset, 0)
      ctx:DrawFrame(22, 3, "right")
      ctx:CreateSquare(11, 1.5, 2):Fill(DT_HUD.MainColor.Value, DT_HUD.DeathIcon)
      local attackerColor = DT_HUD.GetDispositionColor(entry.attacker.Disposition)
      local attackerText = entry.attacker.IsPlayer and entry.attacker.Name or language.GetPhrase(entry.attacker.Name)
      ctx:DrawText(1, 0.85, attackerText, {color = attackerColor, maxLength = 8.5})
      local victimColor = DT_HUD.GetDispositionColor(entry.victim.Disposition)
      local victimText = entry.victim.IsPlayer and entry.victim.Name or language.GetPhrase(entry.victim.Name)
      ctx:DrawText(21, 0.85, victimText, {color = victimColor, maxLength = 8.5, xAlign = TEXT_ALIGN_RIGHT})
      ctx:AddOffset(-offset, 4)
    end
  end)

end