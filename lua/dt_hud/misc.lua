if CLIENT then

  local DrawHud = GetConVar("cl_drawhud")

  DT_HUD.Enabled = DT_Lib.ClientConVar("dt_hud", "1")
  DT_HUD.Scale = DT_Lib.ClientConVar("dt_hud_scale", "1")
  DT_HUD.Blur = DT_Lib.ClientConVar("dt_hud_blur", "3")
  DT_HUD.HideZoom = DT_Lib.ClientConVar("dt_hud_hide_zoom", "1")

  hook.Add("HUDPaint", "DT_HUD/Paint", function()
    if DrawHud:GetBool() and DT_HUD.Enabled:GetBool() then
      return hook.Run("DT_HUD/Paint")
    end
  end)

  hook.Add("HUDShouldDraw", "DT_HUD/ShouldDraw", function(name)
    if DrawHud:GetBool() and DT_HUD.Enabled:GetBool() then
      return hook.Run("DT_HUD/ShouldDraw", name)
    end
  end)

  hook.Add("DT_HUD/ShouldDraw", "DT_HUD/HideZoom", function(name)
    if name == "CHudZoom" and DT_HUD.HideZoom:GetBool() then return false end
  end)

  -- Util --

  DT_HUD.SpeedUnit = DT_Lib.ClientConVar("dt_hud_speed_unit", "hu/s")
  function DT_HUD.ConvertSpeedUnits(speed)
    local unit = DT_HUD.SpeedUnit:GetString()
    if unit == "km/h" or unit == "kph" then
      return speed*0.06858
    elseif unit == "mph" then
      return speed*0.04261362318
    elseif unit == "m/s" then
      return speed*0.01905
    elseif unit == "hu/s" then
      return speed
    end
  end

  -- Materials --

  DT_HUD.SpeedIcon = Material("dt_hud/info/speed.png")
  DT_HUD.FPSIcon = Material("dt_hud/info/fps.png")
  DT_HUD.PingIcon = Material("dt_hud/info/ping.png")

  DT_HUD.DeathIcon = Material("dt_hud/radar/death.png")
  DT_HUD.WeaponIcon = Material("dt_hud/radar/weapon.png")
  DT_HUD.CarIcon = Material("dt_hud/radar/car.png")
  DT_HUD.TankIcon = Material("dt_hud/radar/tank.png")
  DT_HUD.PlaneIcon = Material("dt_hud/radar/plane.png")
  DT_HUD.HelicopterIcon = Material("dt_hud/radar/helicopter.png")

  DT_HUD.NotifyGeneric = Material("dt_hud/notify/generic.png")
  DT_HUD.NotifyError = Material("dt_hud/notify/error.png")
  DT_HUD.NotifyUndo	= Material("dt_hud/notify/undo.png")
  DT_HUD.NotifyHint = Material("dt_hud/notify/hint.png")
  DT_HUD.NotifyCleanup = Material("dt_hud/notify/cleanup.png")

  function DT_HUD.GetVehicleIcon(veh)
    if veh.LFS then
      if veh:IsHelicopter() then return DT_HUD.HelicopterIcon
      else return DT_HUD.PlaneIcon end
    elseif veh.isWacAircraft then
      if scripted_ents.IsBasedOn(veh:GetClass(), "wac_pl_base") then
        return DT_HUD.PlaneIcon
      else return DT_HUD.HelicopterIcon end
    elseif veh.IsSimfphyscar then
      if isnumber(veh.trackspin_r) then return DT_HUD.TankIcon
      else return DT_HUD.CarIcon end
    else return DT_HUD.CarIcon end
  end

  -- Fonts --

  local function CreateFont(name, size)
    local scale = DT_HUD.Scale:GetFloat()
    surface.CreateFont(name, {
      size = (size/1080)*ScrH()*scale,
      weight = 1000
    })
  end

  local function CreateFonts()
    CreateFont("DT_HUD/Default", 15)
    CreateFont("DT_HUD/Compass", 18)
    CreateFont("DT_HUD/Humongous", 80)
  end

  CreateFonts()
  hook.Add("OnScreenSizeChanged", "DT_HUD/CreateFonts", CreateFonts)
  cvars.AddChangeCallback(DT_HUD.Scale:GetName(), CreateFonts)

  -- Colors --

  local function HUDColor(name, color)
    local red = DT_Lib.ClientConVar("dt_hud_color_"..name.."_r", tostring(color.r))
    local green = DT_Lib.ClientConVar("dt_hud_color_"..name.."_g", tostring(color.g))
    local blue = DT_Lib.ClientConVar("dt_hud_color_"..name.."_b", tostring(color.b))
    local color = Color(red:GetInt(), green:GetInt(), blue:GetInt(), color.a)
    cvars.AddChangeCallback(red:GetName(), function() color.r = red:GetInt() end)
    cvars.AddChangeCallback(green:GetName(), function() color.g = green:GetInt() end)
    cvars.AddChangeCallback(blue:GetName(), function() color.b = blue:GetInt() end)
    local color = { Red = red, Green = green, Blue = blue, Value = color }
    function color:AddToPanel(panel)
      panel:AddControl("color", {
        label = "#dt_hud.menu.client.colors."..name,
        red = red:GetName(),
        green = green:GetName(),
        blue = blue:GetName()
      })
    end
    function color:Reset()
      red:Revert()
      green:Revert()
      blue:Revert()
    end
    function color:Randomize()
      red:SetInt(math.random(0, 255))
      green:SetInt(math.random(0, 255))
      blue:SetInt(math.random(0, 255))
    end
    return color
  end

  DT_HUD.MainColor = HUDColor("main", DT_Lib.CLR_SOFT_WHITE)
  DT_HUD.FullHealthColor = HUDColor("full_health", DT_Lib.CLR_GREEN)
  DT_HUD.LowHealthColor = HUDColor("low_health", DT_Lib.CLR_RED)
  DT_HUD.ArmorColor = HUDColor("armor", DT_Lib.CLR_ORANGE)
  DT_HUD.PrimaryAmmoColor = HUDColor("primary_ammo", DT_Lib.CLR_SOFT_WHITE)
  DT_HUD.SecondaryAmmoColor = HUDColor("secondary_ammo", DT_Lib.CLR_ORANGE)
  DT_HUD.NeutralColor = HUDColor("neutral", DT_Lib.CLR_SOFT_WHITE)
  DT_HUD.AlliesColor = HUDColor("allies", DT_Lib.CLR_GREEN)
  DT_HUD.EnemiesColor = HUDColor("enemies", DT_Lib.CLR_RED)
  DT_HUD.WeaponsColor = HUDColor("weapons", DT_Lib.CLR_ORANGE)
  DT_HUD.VehiclesColor = HUDColor("vehicles", DT_Lib.CLR_ORANGE)

  function DT_HUD.GetDispositionColor(disp)
    if disp == D_HT or disp == D_FR then
      return DT_HUD.EnemiesColor.Value
    elseif disp == D_LI then
      return DT_HUD.AlliesColor.Value
    else
      return DT_HUD.NeutralColor.Value
    end
  end

  concommand.Add("dt_hud_cmd_reset_colors", function()
    DT_HUD.MainColor:Reset()
    DT_HUD.FullHealthColor:Reset()
    DT_HUD.LowHealthColor:Reset()
    DT_HUD.ArmorColor:Reset()
    DT_HUD.PrimaryAmmoColor:Reset()
    DT_HUD.SecondaryAmmoColor:Reset()
    DT_HUD.NeutralColor:Reset()
    DT_HUD.AlliesColor:Reset()
    DT_HUD.EnemiesColor:Reset()
    DT_HUD.VehiclesColor:Reset()
    DT_HUD.WeaponsColor:Reset()
  end)

  concommand.Add("dt_hud_cmd_randomize_colors", function()
    DT_HUD.MainColor:Randomize()
    DT_HUD.FullHealthColor:Randomize()
    DT_HUD.LowHealthColor:Randomize()
    DT_HUD.ArmorColor:Randomize()
    DT_HUD.PrimaryAmmoColor:Randomize()
    DT_HUD.SecondaryAmmoColor:Randomize()
    DT_HUD.NeutralColor:Randomize()
    DT_HUD.AlliesColor:Randomize()
    DT_HUD.EnemiesColor:Randomize()
    DT_HUD.VehiclesColor:Randomize()
    DT_HUD.WeaponsColor:Randomize()
  end)

end