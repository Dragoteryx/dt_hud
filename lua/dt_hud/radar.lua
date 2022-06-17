DT_HUD.RadarAllowed = DT_Lib.ConVar("dt_hud_radar_allowed", "1")
DT_HUD.RadarTickrate = DT_Lib.ConVar("dt_hud_radar_tickrate", "10")
DT_HUD.RadarRange = DT_Lib.ConVar("dt_hud_radar_range", "1500")
DT_HUD.RadarSweep = DT_Lib.ConVar("dt_hud_radar_sweep", "1")
DT_HUD.RadarFadeOut = DT_Lib.ConVar("dt_hud_radar_fadeout", "1")
DT_HUD.CompassRotate = DT_Lib.ConVar("dt_hud_compass_rotate", "0")

--- @param ent Entity @The entity to test
--- @return boolean isVehicle @Whether this entity is a vehicle
local function IsVehicle(ent)
  if ent:GetClass() == "prop_vehicle_prisoner_pod" then return false end
  return ent:IsVehicle() or ent.LFS or ent.isWacAircraft
end

--- Returns the current sweep value.
--- This sould be synchronized between the server
--- and the client as long as [CurTime](https://wiki.facepunch.com/gmod/Global.CurTime) is synchronized.
--- @return number sweep @The current sweep value.
function DT_HUD.GetSweep()
  local sweep = DT_HUD.RadarSweep:GetFloat()
  if sweep < 0 then return -1 end
  return CurTime() % (sweep + 1)
end

if SERVER then
  util.AddNetworkString("DT_HUD/RadarData")
  util.AddNetworkString("DT_HUD/PlayerDeath")

  hook.Add("PostPlayerDeath", "DT_HUD/PlayerDeath", function(ply)
    net.Start("DT_HUD/PlayerDeath")
    net.WriteVector(ply:GetPos())
    net.Send(ply)
  end)

  local function ShowOnRadar(ent)
    return ent:DT_IsTarget() or IsVehicle(ent)
      or (ent:IsWeapon() and not IsValid(ent:GetOwner()))
  end

  local LAST_UPDATE = 0
  local LAST_SWEEP = -1
  local SENT_ENTITIES = {}
  hook.Add("Think", "DT_HUD/RadarData", function()
    if not DT_HUD.RadarAllowed:GetBool() then return end
    local delay = 1 / DT_HUD.RadarTickrate:GetFloat()
    if CurTime() < LAST_UPDATE + delay then return end
    LAST_UPDATE = CurTime()
    local sweep = DT_HUD.GetSweep()
    if sweep < LAST_SWEEP then SENT_ENTITIES = {} end
    LAST_SWEEP = sweep
    local range = DT_HUD.RadarRange:GetFloat()
    local sweepDist = (sweep/0.9)*range
    local entities = {}
    for _, ent in ipairs(ents.GetAll()) do
      if IsValid(ent) and ShowOnRadar(ent) then
        table.insert(entities, ent)
      end
    end
    for _, ply in ipairs(player.GetHumans()) do
      local myPos = ply:GetPos()
      local data = {}
      for _, ent in ipairs(entities) do
        if ent == ply then continue end
        local entPos = ent:GetPos()
        local dist = (myPos-entPos):Length2D()
        if dist > range then continue end
        if sweep ~= -1 then
          if SENT_ENTITIES[ent] then continue end
          if dist > sweepDist then continue end
          SENT_ENTITIES[ent] = true
        end
        local entData = {}
        entData.Entity = ent
        entData.InPVS = ply:TestPVS(ent)
        entData.Pos = ent:WorldSpaceCenter()
        entData.Vel = ent:DT_GetVelocity()
        entData.Disp = ent:DT_GetDisposition(ply)
        table.insert(data, entData)
      end
      net.Start("DT_HUD/RadarData")
      net.WriteUInt(#data, 32)
      for _, entData in ipairs(data) do
        net.WriteEntity(entData.Entity)
        net.WriteBool(entData.InPVS)
        net.WriteVector(entData.Pos)
        net.WriteVector(entData.Vel)
        net.WriteUInt(entData.Disp, 3)
      end
      net.Send(ply)
    end
  end)

else

  DT_HUD.RadarEnabled = DT_Lib.ConVar("dt_hud_radar", "1")
  DT_HUD.RadarScale = DT_Lib.ConVar("dt_hud_radar_scale", "1")
  DT_HUD.RadarIcons = DT_Lib.ConVar("dt_hud_radar_icons", "1")
  DT_HUD.RadarLastDeath = DT_Lib.ConVar("dt_hud_radar_last_death", "1")
  DT_HUD.CompassEnabled = DT_Lib.ConVar("dt_hud_compass", "1")
  DT_HUD.CompassNorthOnly = DT_Lib.ConVar("dt_hud_compass_north_only", "0")

  local LAST_DEATH = nil
  net.Receive("DT_HUD/PlayerDeath", function()
    LAST_DEATH = net.ReadVector()
  end)
  hook.Add("PostCleanupMap", "DT_HUD/CleanupLastDeath", function()
    LAST_DEATH = nil
  end)

  local RADAR_DATA = {}
  net.Receive("DT_HUD/RadarData", function()
    local entities = net.ReadUInt(32)
    for _ = 1, entities do
      local ent = net.ReadEntity()
      RADAR_DATA[ent:EntIndex()] = {
        Entity = ent,
        InPVS = net.ReadBool(),
        Pos = net.ReadVector(),
        Vel = net.ReadVector(),
        Disp = net.ReadUInt(3),
        LastUpdate = CurTime()
      }
    end
  end)

  local function IsVehicleEmpty(veh)
    if veh.LFS then
      local seats = veh:GetPassengerSeats()
      for _, seat in pairs(seats) do
        if not IsValid(seat) then continue end
        local passenger = seat:GetPassenger(0)
        if IsValid(passenger) then return false end
      end
      return true
    elseif veh.isWacAircraft then
      local switcher = veh:GetSwitcher()
      if not IsValid(switcher) then return true end
      for _, seat in ipairs(switcher.seats) do
        if not IsValid(seat) then continue end
        local passenger = seat:GetPassenger(0)
        if IsValid(passenger) then return false end
      end
      return true
    else return not IsValid(veh:GetDriver()) end
  end

  hook.Add("DT_HUD/Paint", "DT_HUD/Radar", function()
    if not DT_HUD.RadarAllowed:GetBool() then return end
    if not DT_HUD.RadarEnabled:GetBool() then return end
    local ply = LocalPlayer()
    local radius = 15*DT_HUD.RadarScale:GetFloat()
    local range = DT_HUD.RadarRange:GetFloat()
    local myPos, myAng = ply:GetPos(), EyeAngles()
    local sweep = DT_HUD.GetSweep()

    --- @param pos Vector
    --- @return number
    local function CalcAngle(pos)
      return math.AngleDifference((pos - myPos):Angle().y, myAng.y)
    end

    --- @param pos Vector
    --- @param important boolean
    --- @return number?, number?
    local function ToRadarCoords(pos, important)
      local dist = (myPos-pos):Length2D()
      if dist > range and not important then return end
      local coords = Vector(radius*math.min(1, dist/range)*0.9, 0)
      coords:Rotate(Angle(0, -CalcAngle(pos) - 90, 0))
      return coords.x, coords.y
    end

    local ctx = DT_HUD.DrawContext()
    ctx:SetOrigin(-radius - 1, radius + 1)

    -- draw radar

    local outerRing = ctx:CreateCircle(0, 0, radius, 80)
    local middleRing = ctx:CreateCircle(0, 0, radius/3*2, 80)
    local innerRing = ctx:CreateCircle(0, 0, radius/3, 80)
    local cone = ctx:CreateCirclePiece(0, 0, radius, 80, nil, 50, 70)

    outerRing:Fill(DT_HUD.Background)
    outerRing:Blur(DT_HUD.Blur:GetInt())
    cone:Fill(DT_HUD.Border)
    cone:Blur(DT_HUD.Blur:GetInt())
    outerRing:Stroke(DT_HUD.Border)
    middleRing:Stroke(DT_HUD.Border)
    innerRing:Stroke(DT_HUD.Border)

    if sweep >= 0 and sweep <= 1 then
      local sweepRing = ctx:CreateCircle(0, 0, radius*sweep, 80)
      sweepRing:Stroke(DT_HUD.Border)
    end

    -- draw ents (todo: rewrite this mess)
    for _, data in pairs(RADAR_DATA) do
      local ent = data.Entity
      if not IsValid(ent) then continue end
      local time = CurTime() - data.LastUpdate
      local fade = time / DT_HUD.RadarFadeOut:GetFloat()
      if fade > 1 and sweep ~= -1 then continue end
      local usePVS = sweep == -1 and data.InPVS
      local entPos = usePVS and ent:GetPos()
        or data.Pos + data.Vel * time
      local x, y = ToRadarCoords(entPos, false)
      if not x or not y then continue end
      local ang = CalcAngle(entPos)
      local tr = util.TraceLine({
        start = EyePos(),
        endpos = entPos,
        mask = MASK_VISIBLE
      })
      local visible = not tr.Hit and math.abs(ang) < 45
      local function DrawOnRadar(color)
        local height = entPos.z - myPos.z
        local icon
        if height > 100 then icon = ctx:CreateTriangle(x, y, 0.6, -90)
        elseif height < -100 then icon = ctx:CreateTriangle(x, y, 0.6, 90)
        else icon = ctx:CreateDiamond(x, y, 0.6) end
        if visible then icon:Fill(color)
        else icon:Stroke(color) end
      end
      if ent:IsWeapon() then
        if IsValid(ent:GetOwner()) then continue end
        local color = DT_HUD.WeaponColor.Value
        if sweep ~= -1 then color.a = (1 - fade)*255 end
        if DT_HUD.RadarIcons:GetBool() then
          local icon = DT_HUD.WeaponIcon
          ctx:CreateSquare(x, y, 1.25):Fill(color, icon)
        else DrawOnRadar(color) end
        color.a = 255
      elseif IsVehicle(ent) then
        if not IsVehicleEmpty(ent) then continue end
        local color = DT_HUD.VehicleColor.Value
        if sweep ~= -1 then color.a = (1 - fade)*255 end
        if DT_HUD.RadarIcons:GetBool() then
          local icon = DT_HUD.GetVehicleIcon(ent)
          ctx:CreateSquare(x, y, 1.5):Fill(color, icon)
        else DrawOnRadar(color) end
        color.a = 255
      else
        local color = DT_HUD.GetDispositionColor(data.Disp)
        if sweep ~= -1 then color.a = (1 - fade)*255 end
        DrawOnRadar(color)
        color.a = 255
      end
    end

    -- draw last death
    if LAST_DEATH and DT_HUD.RadarLastDeath:GetBool() then
      local x, y = ToRadarCoords(LAST_DEATH, true)
      local icon = ctx:CreateSquare(x - 0.75, y - 0.75, 1.5)
      icon:Fill(DT_HUD.MainColor.Value, DT_HUD.DeathIcon)
    end

    -- draw compass
    if DT_HUD.CompassEnabled:GetBool() then
      local dir = Vector(999999999, 0)
      local ang = DT_HUD.CompassRotate:GetFloat()
      dir:Rotate(Angle(0, -ang, 0))
      for i = 1, 4 do
        if i > 1 and DT_HUD.CompassNorthOnly:GetBool() then break end
        local x, y = ToRadarCoords(dir, true)
        dir:Rotate(Angle(0, -90, 0))
        ctx:DrawText(x, y, "#dt_hud.compass."..i, {
          font = "DT_HUD/Compass",
          xAlign = TEXT_ALIGN_CENTER,
          yAlign = TEXT_ALIGN_CENTER
        })
      end
    end

    -- draw center
    ctx:CreateDiamond(0, 0, 0.6)
      :Fill(DT_HUD.MainColor.Value)
  end)

end