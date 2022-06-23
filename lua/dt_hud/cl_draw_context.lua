DT_HUD.Background = Color(0, 0, 10, 50)
DT_HUD.Border = Color(100, 100, 110, 25)

--- @class DT_HUD.DrawContext : DT_Lib.DrawContext
DT_HUD.DRAW_CONTEXT = setmetatable({}, {__index = DT_Lib.DRAW_CONTEXT})

--- @return DT_HUD.DrawContext
function DT_HUD.DrawContext()
  local ctx = setmetatable(DT_Lib.DrawContext(), {__index = DT_HUD.DRAW_CONTEXT})
  ctx:SetDefaultTextColor(DT_HUD.MainColor.Value)
  ctx:SetScale(DT_HUD.Scale:GetFloat())
  ctx:SetDefaultFont("DT_HUD/Default")
  return ctx
end

--- @param length number
--- @param height number
--- @param border? "left" | "right"
function DT_HUD.DRAW_CONTEXT:DrawFrame(length, height, border)
  self:CreateRectangle(0, 0, length, height)
    :Fill(DT_HUD.Background)
    :Blur(DT_HUD.Blur:GetInt())
    :Stroke(DT_HUD.Border)

  if border == "left" then
    self:CreateRectangle(-0.5, 0, 0.5, height):Fill(DT_HUD.MainColor.Value)
  elseif border == "right" then
    self:CreateRectangle(length, 0, 0.5, height):Fill(DT_HUD.MainColor.Value)
  end
end

--- @class DT_HUD.DrawBar
--- @field value number
--- @field max number
--- @field length number
--- @field height number
--- @field color Color
--- @field blur boolean?
--- @field label string?

--- @param x number
--- @param y number
--- @param options DT_HUD.DrawBar
function DT_HUD.DRAW_CONTEXT:DrawBar(x, y, options)
  local value, max = options.value, options.max
  local length, height = options.length, options.height
  local background = self:CreateRectangle(x, y, length, height)
  background:Fill(DT_HUD.Background)
  if options.blur then background:Blur(DT_HUD.Blur:GetInt()) end
  background:Stroke(DT_HUD.Border)
  local barLength = (math.min(value, max)/max)*length
  self:CreateRectangle(x, y, barLength, height):Fill(options.color)
  local shadow = self:CreateRectangle(x, y+height/2, barLength, height/2)
  for _ = 1, 2 do shadow:Fill(DT_HUD.Background) end
  if options.label then
    local value = math.Round(value)
    local max = math.Round(max)
    DT_Lib.ResetStencil()
    render.SetStencilEnable(true)
      render.SetStencilCompareFunction(STENCIL_NEVER)
      render.SetStencilFailOperation(STENCIL_INCR)
      self:CreateRectangle(x, y, barLength, height):Fill(options.color)
      render.SetStencilCompareFunction(STENCIL_EQUAL)
      render.SetStencilFailOperation(STENCIL_KEEP)
      self:DrawText(x + 0.5, y + height/2, options.label, {
        yAlign = TEXT_ALIGN_CENTER
      })
      self:DrawText(x + length - 0.5, y + height/2, value.." / "..max, {
        xAlign = TEXT_ALIGN_RIGHT,
        yAlign = TEXT_ALIGN_CENTER
      })
      render.SetStencilReferenceValue(1)
      self:DrawText(x + 0.5, y + height/2, options.label, {
        yAlign = TEXT_ALIGN_CENTER,
        outlineColor = DT_HUD.Background
      })
      self:DrawText(x + length - 0.5, y + height/2, value.." / "..max, {
        xAlign = TEXT_ALIGN_RIGHT,
        yAlign = TEXT_ALIGN_CENTER,
        outlineColor = DT_HUD.Background
      })
    render.SetStencilEnable(false)
  end
end

--- @class DT_HUD.DrawPie
--- @field value number
--- @field max number
--- @field radius number
--- @field color Color
--- @field blur boolean?

--- @param x number
--- @param y number
--- @param options DT_HUD.DrawPie
function DT_HUD.DRAW_CONTEXT:DrawPie(x, y, options)
  local radius, color = options.radius, options.color
  local value, max = options.value, options.max
  if max <= 1 then
    local poly = self:CreateDiamond(x, y, radius)
    if value <= 0 then
      poly:Fill(DT_HUD.Background)
      if options.blur then poly:Blur(DT_HUD.Blur:GetInt()) end
      poly:Stroke(DT_HUD.Border)
    else poly:Fill(color) end
  elseif max <= 3 then
    options.value = value*2
    options.max = max*2
    self:DrawPie(x, y, options)
  else
    local circle = self:CreateCircle(x, y, radius, max)
    circle:Fill(DT_HUD.Background)
    if options.blur then circle:Blur(DT_HUD.Blur:GetInt()) end
    circle:Stroke(DT_HUD.Border)
    self:CreateCirclePiece(x, y, radius, max, nil, 0, value):Fill(color)
  end
end