DT_HUD.Notifications = DT_Lib.ClientConVar("dt_hud_notifications", "1")

--- @class DT_HUD.LegacyNotification
--- @field progress false
--- @field text string
--- @field type integer
--- @field duration number
--- @field time number

--- @class DT_HUD.ProgressNotification
--- @field progress true
--- @field text string
--- @field time number
--- @field id any
--- @field ratio number?
--- @field removed number?

--- @alias DT_HUD.Notification DT_HUD.LegacyNotification|DT_HUD.ProgressNotification

--- @type DT_HUD.Notification[]
local NOTIFICATIONS = {}

DT_HUD.__notification_AddLegacy = DT_HUD.__notification_AddLegacy or notification.AddLegacy
function notification.AddLegacy(text, type, duration)
  if DT_HUD.Enabled:GetBool() and DT_HUD.Notifications:GetBool() then
    local notif = {
      text = text, type = type,
      duration = duration,
      time = CurTime(),
      progress = false
    }
    table.insert(NOTIFICATIONS, notif)
    timer.Simple(duration, function()
      table.RemoveByValue(NOTIFICATIONS, notif)
    end)
  else
    return DT_HUD.__notification_AddLegacy(text, type, duration)
  end
end

DT_HUD.__notification_AddProgress = DT_HUD.__notification_AddProgress or notification.AddProgress
function notification.AddProgress(id, text, ratio)
  if DT_HUD.Enabled:GetBool() and DT_HUD.Notifications:GetBool() then
    for _, notif in ipairs(NOTIFICATIONS) do
      if notif.progress and notif.id == id then
        notif.text = text
        notif.ratio = ratio
        return
      end
    end
    table.insert(NOTIFICATIONS, {
      id = id, text = text, ratio = ratio,
      time = CurTime(), progress = true
    })
  else
    return DT_HUD.__notification_AddProgress(id, text, ratio)
  end
end

DT_HUD.__notification_Kill = DT_HUD.__notification_Kill or notification.Kill
function notification.Kill(id)
  if DT_HUD.Enabled:GetBool() and DT_HUD.Notifications:GetBool() then
    for _, notif in ipairs(NOTIFICATIONS) do
      if notif.progress and notif.id == id and not notif.removed then
        notif.removed = CurTime()
        return
      end
    end
  else
    return DT_HUD.__notification_Kill(id, text, ratio)
  end
end

function DT_HUD.GetNotifyIcon(type)
  if type == NOTIFY_ERROR then return DT_HUD.NotifyError
  elseif type == NOTIFY_UNDO then return DT_HUD.NotifyUndo
  elseif type == NOTIFY_HINT then return DT_HUD.NotifyHint
  elseif type == NOTIFY_CLEANUP then return DT_HUD.NotifyCleanup
  else return DT_HUD.NotifyGeneric end
end

hook.Add("DT_HUD/Paint", "DT_HUD/PaintNotifications", function()
  if not DT_HUD.Notifications:GetBool() then return end

  local y = -16
  if DT_HUD.StatusEnabled:GetBool() then
    y = -12
    if DT_HUD.StatusMiscEnabled:GetBool() then y = y - 4 end
    if DT_HUD.StatusEffectsEnabled:GetBool() then y = y - 4 end
  end

  local ctx = DT_HUD.DrawContext()
  ctx:SetOrigin(1.5, y)

  --- @type DT_HUD.Notification[]
  local toRemove = {}
  for _, notif in ipairs(NOTIFICATIONS) do
    local length = math.max(17.25, ctx:GetTextSize(notif.text)) + 4.75
    local offsetLength = length + 2
    local enterOffset = offsetLength - offsetLength * math.min(1, (CurTime() - notif.time) * (120/offsetLength))

    --- @type number
    local leaveOffset
    if not notif.progress then
      leaveOffset = offsetLength - offsetLength * math.min(1, (notif.duration - (CurTime() - notif.time)) * (120/offsetLength))
    elseif notif.removed then
      leaveOffset = offsetLength * math.min(1, (CurTime() - notif.removed) * (120/offsetLength))
      if leaveOffset == offsetLength then table.insert(toRemove, notif) end
    else leaveOffset = 0 end

    local offset = math.max(enterOffset, leaveOffset)
    ctx:AddOffset(-offset, 0)
    ctx:DrawFrame(length, 3, "left")

    if notif.progress then
      local outerRadius = 1
      local innerRadius = 0.75
      local lines = 50
      local ring = ctx:CreateRing(1.75, 1.5, 0, innerRadius, lines)
      local ratio = 1 - (notif.ratio and math.Clamp(notif.ratio, 0, 1) or ((CurTime() - notif.time) % 2) / 2)
      ring.OuterCircle = ctx:CreateCirclePiece(1.75, 1.5, outerRadius, lines, nil, math.Round(lines * ratio), lines)
      ring:Fill(DT_HUD.MainColor.Value)
    else
      ctx:CreateSquare(1.75, 1.5, 2)
        :Fill(DT_HUD.MainColor.Value, DT_HUD.GetNotifyIcon(notif.type))
    end

    ctx:DrawText(3.75, 0.75, notif.text)
    ctx:AddOffset(offset, -4)
  end

  for _, notif in ipairs(toRemove) do
    table.RemoveByValue(NOTIFICATIONS, notif)
  end
end)