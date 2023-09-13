local DRAW_HUD = GetConVar("cl_drawhud")

DT_Hud.Enabled = DT_Core.ClientConVar("dt_hud", "1")
DT_Hud.Scale = DT_Core.ClientConVar("dt_hud_scale", "1")
DT_Hud.BlurQuality = DT_Core.ClientConVar("dt_hud_blur_quality", "3")
DT_Hud.HideZoom = DT_Core.ClientConVar("dt_hud_hide_zoom", "1")
DT_Hud.HidePoison = DT_Core.ClientConVar("dt_hud_hide_poison", "1")
DT_Hud.HideCrosshair = DT_Core.ClientConVar("dt_hud_hide_crosshair", "0")
DT_Hud.MeasuringSystem = DT_Core.ClientConVar("dt_hud_measuring_system", "hammer")

-- Draw hooks --

hook.Add("HUDShouldDraw", "DT/HUD_ShouldDraw", function(name)
	if not DRAW_HUD:GetBool() or not DT_Hud.Enabled:GetBool() then return end
	if name == "CHudZoom" and DT_Hud.HideZoom:GetBool() then return false end
	if name == "CHudPoisonDamageIndicator" and DT_Hud.HidePoison:GetBool() then return false end
	if name == "CHudCrosshair" and DT_Hud.HideCrosshair:GetBool() then return false end
	return hook.Run("DT/HUD_ShouldDraw", name)
end)

hook.Add("HUDPaint", "DT/HUD_Paint", function()
	if not DRAW_HUD:GetBool() or not DT_Hud.Enabled:GetBool() then return end
	return hook.Run("DT/HUD_Draw")
end)

-- Materials --a

DT_Hud.HealthIcon = Material("dt/hud/status/health.png")
DT_Hud.ShieldIcon = Material("dt/hud/status/shield.png")
DT_Hud.SpeedIcon = Material("dt/hud/status/speed.png")
DT_Hud.FPSIcon = Material("dt/hud/status/fps.png")
DT_Hud.PingIcon = Material("dt/hud/status/ping.png")
DT_Hud.PickUpIcon = Material("dt/hud/status/pickup.png")

DT_Hud.WeaponIcon = Material("dt/hud/ammo/weapon.png")
DT_Hud.AmmoIcon = Material("dt/hud/ammo/ammo.png")

DT_Hud.CarIcon = Material("dt/hud/vehicles/car.png")
DT_Hud.TankIcon = Material("dt/hud/vehicles/tank.png")
DT_Hud.PlaneIcon = Material("dt/hud/vehicles/plane.png")
DT_Hud.HelicopterIcon = Material("dt/hud/vehicles/helicopter.png")

DT_Hud.DeathIcon = Material("dt/hud/death.png")
DT_Hud.NotifyGeneric = Material("dt/hud/notifs/generic.png")
DT_Hud.NotifyError = Material("dt/hud/notifs/error.png")
DT_Hud.NotifyUndo	= Material("dt/hud/notifs/undo.png")
DT_Hud.NotifyHint = Material("dt/hud/notifs/hint.png")
DT_Hud.NotifyCleanup = Material("dt/hud/notifs/cleanup.png")

function DT_Hud.GetVehicleIcon(veh)
	if veh.LFS then
		if veh:IsHelicopter() then return DT_Hud.HelicopterIcon
		else return DT_Hud.PlaneIcon end
	elseif veh.isWacAircraft then
		if scripted_ents.IsBasedOn(veh:GetClass(), "wac_pl_base") then
			return DT_Hud.PlaneIcon
		else return DT_Hud.HelicopterIcon end
	elseif veh.IsSimfphyscar then
		if isnumber(veh.trackspin_r) then return DT_Hud.TankIcon
		else return DT_Hud.CarIcon end
	else return DT_Hud.CarIcon end
end

-- Colors --

DT_Hud.MainColor = DT_Hud.Color("main", Color(204, 204, 221))
DT_Hud.BackgroundColor = DT_Hud.Color("background", Color(100, 100, 120, 25))
DT_Hud.HealthColor = DT_Hud.Color("health", Color(107, 164, 61))
DT_Hud.ArmorColor = DT_Hud.Color("armor", Color(172, 98, 61))
DT_Hud.PrimaryAmmoColor = DT_Hud.Color("primary_ammo", Color(204, 204, 221))
DT_Hud.SecondaryAmmoColor = DT_Hud.Color("secondary_ammo", Color(172, 98, 61))
DT_Hud.NeutralColor = DT_Hud.Color("neutral", Color(204, 204, 221))
DT_Hud.AlliesColor = DT_Hud.Color("allies", Color(107, 164, 61))
DT_Hud.EnemiesColor = DT_Hud.Color("enemies", Color(187, 69, 69))

function DT_Hud.GetDispositionColor(disp)
	if disp == D_HT or disp == D_FR then
		return DT_Hud.EnemiesColor:GetValue()
	elseif disp == D_LI then
		return DT_Hud.AlliesColor:GetValue()
	else
		return DT_Hud.NeutralColor:GetValue()
	end
end

concommand.Add("dt_hud_cmd_reset_colors", function()
	DT_Hud.MainColor:Reset()
	DT_Hud.BackgroundColor:Reset()
	DT_Hud.HealthColor:Reset()
	DT_Hud.ArmorColor:Reset()
	DT_Hud.PrimaryAmmoColor:Reset()
	DT_Hud.SecondaryAmmoColor:Reset()
	DT_Hud.NeutralColor:Reset()
	DT_Hud.AlliesColor:Reset()
	DT_Hud.EnemiesColor:Reset()
end)

concommand.Add("dt_hud_cmd_randomize_colors", function()
	DT_Hud.MainColor:Randomize()
	DT_Hud.BackgroundColor:Randomize()
	DT_Hud.HealthColor:Randomize()
	DT_Hud.ArmorColor:Randomize()
	DT_Hud.PrimaryAmmoColor:Randomize()
	DT_Hud.SecondaryAmmoColor:Randomize()
	DT_Hud.NeutralColor:Randomize()
	DT_Hud.AlliesColor:Randomize()
	DT_Hud.EnemiesColor:Randomize()
end)

-- Fonts --

local function CreateFont(name, size)
	local scale = DT_Hud.Scale:GetFloat()
	surface.CreateFont(name, {
		size = size / 1080 * ScrH() * scale,
		weight = 1000
	})
end

local function CreateFonts()
	CreateFont("DT/HUD_Default", 15)
	CreateFont("DT/HUD_Large", 20)
	CreateFont("DT/HUD_Huge", 30)
end

CreateFonts()
hook.Add("OnScreenSizeChanged", "DT/HUD_CreateFonts", CreateFonts)
cvars.AddChangeCallback(DT_Hud.Scale:GetName(), CreateFonts)