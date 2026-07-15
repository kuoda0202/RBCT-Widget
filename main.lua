-- RBCT helicopter dashboard for EdgeTX / TX16S MK3.
-- Author: 雷恩 / Ryan Kuo
-- Model picture order: Model Setup bitmap (/IMAGES), RBCT/modelImage/<model>.png,
-- RBCT/modelImage/<model without its first character>.png, then default.png.
local NAME = "RBCT"

-- Keep this list byte-for-byte compatible with standard telemetry. The order is
-- deliberately arranged to ensure standard telemetry setup works here.
local sensors = { "Vbat", "Curr", "Hspd", "Capa", "Bat%", "Tesc", "Tmcu", "1RSS", "2RSS", "RQly", "Thr", "Vbec", "ARM", "Gov", "Vcel", "FM" }
local id, mm = {}, {}
local heli_pic, loaded_model_key
local led_cache = { enabled = nil, color = nil }

local options = {
  { "Timer", VALUE, 1, 1, 3 }, -- TX16S MK3 model timer 1..3
  -- Match DBK_MK3Min: map one physical three-position switch to Banks 1..3.
  { "BankSwitch", SOURCE, 0 },
  { "Theme", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet" } },
  -- Same physical LED switch option used by KRC_Dashboard.
  { "DispLED", BOOL, 0 },
  { "LED Color", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet" } },
  { "Arm Source", SOURCE, 0 },
}

local C = {
  bg = lcd.RGB(7, 22, 72), blue = lcd.RGB(0, 126, 255),
  panel = lcd.RGB(15, 48, 122), panel2 = lcd.RGB(22, 61, 143),
  white = lcd.RGB(242, 247, 255), dim = lcd.RGB(147, 193, 255),
  red = lcd.RGB(255, 67, 84),    green = lcd.RGB(0, 180, 0), black = lcd.RGB(0, 0, 0),
}

-- Seven selectable rainbow-colour themes. Blue is the default.
local themes = {
  { 235,  62,  72 }, -- Red
  { 255, 135,   0 }, -- Orange
  { 255, 205,   0 }, -- Yellow
  {  40, 205,  90 }, -- Green
  {   0, 126, 255 }, -- Blue
  {  82,  82, 220 }, -- Indigo
  { 175,  70, 235 }, -- Violet
}

local function setTheme(n)
  local t = themes[math.max(1, math.min(#themes, n or 5))]
  local r, g, b = t[1], t[2], t[3]
  C.blue = lcd.RGB(r, g, b)
  C.bg = lcd.RGB(math.max(5, math.floor(r * .10)), math.max(5, math.floor(g * .10)), math.max(5, math.floor(b * .10)))
  C.panel = lcd.RGB(math.max(8, math.floor(r * .28)), math.max(8, math.floor(g * .28)), math.max(8, math.floor(b * .28)))
  C.panel2 = lcd.RGB(math.max(10, math.floor(r * .40)), math.max(10, math.floor(g * .40)), math.max(10, math.floor(b * .40)))
  C.dim = lcd.RGB(math.min(255, 95 + math.floor(r * .45)), math.min(255, 95 + math.floor(g * .45)), math.min(255, 95 + math.floor(b * .45)))
end

local function resetMinMax()
  for i = 1, #sensors do mm[i] = { cur = 0, min = nil, max = nil } end
end

local function resolveSensors()
  for i, name in ipairs(sensors) do
    if not id[i] then
      local info = getFieldInfo(name)
      if info then id[i] = info.id end
    end
  end
end

local function sensor(i)
  local v = id[i] and getValue(id[i]) or nil
  return type(v) == "number" and v or 0
end

local function stat(i, which)
  return mm[i] and mm[i][which] or 0
end

local function modelImagePath(m)
  if m.bitmap and m.bitmap ~= "" then
    local p = "/IMAGES/" .. m.bitmap
    if fstat(p) then return p end
  end
  local name = m.name or ""
  if name ~= "" then
    local p = "/WIDGETS/RBCT/modelImage/" .. name .. ".png"
    if fstat(p) then return p end
    -- Handle cases with a leading model-type marker (for example >RS5).
    p = "/WIDGETS/RBCT/modelImage/" .. string.sub(name, 2) .. ".png"
    if fstat(p) then return p end
  end
  return "/WIDGETS/RBCT/default.png"
end

local function loadModelImage()
  local m = model.getInfo() or {}
  local key = (m.name or "") .. "|" .. (m.bitmap or "")
  if key ~= loaded_model_key then
    loaded_model_key = key
    heli_pic = nil
    local p = modelImagePath(m)
    if fstat(p) then heli_pic = Bitmap.open(p) end
  end
end

local function create(zone, opts)
  local w = { zone = zone, options = opts }
  id = {}; resetMinMax(); resolveSensors()
  return w
end

local function update(w, opts) w.options = opts end

local function background(w)
  resolveSensors()
  for i = 1, #sensors do
    local v = sensor(i)
    if id[i] then
      mm[i].cur = v
      mm[i].min = mm[i].min and math.min(mm[i].min, v) or v
      mm[i].max = mm[i].max and math.max(mm[i].max, v) or v
    end
  end
end

local function volts(v)
  -- EdgeTX returns these telemetry values in volts already.
  -- Only protect against the uncommon centivolt representation; never turn
  -- a normal 11.1 V flight pack into 1.1 V.
  if v > 100 then return v / 100 end
  return v
end

local function amps(v)
  if v > 2000 then return v / 100 end
  if v > 200 then return v / 10 end
  return v
end

local function timerText(w)
  local n = (w.options.Timer or 1) - 1
  local t = model.getTimer(n)
  local s = t and t.value or 0
  local sign = s < 0 and "-" or ""
  s = math.abs(s)
  return string.format("%s%02d:%02d", sign, math.floor(s / 60), s % 60), s < 0 and C.red or C.white
end

local function bankText(w)
  local source = w.options.BankSwitch
  if source and source ~= 0 then
    local value = getValue(source)
    if type(value) == "number" then
      -- Same three-position thresholds used by DBK_MK3Min.
      local bank = 2
      if value < -300 then bank = 1
      elseif value > 300 then bank = 3 end
      return string.format("BANK %d", bank)
    end
  end

  -- DBK-compatible fallbacks make Bank usable even before a source is chosen.
  local fm_idx = getFlightMode and getFlightMode() or nil
  if type(fm_idx) == "number" then return string.format("BANK %d", math.max(1, math.min(3, fm_idx + 1))) end
  local fm = getValue("FM")
  if type(fm) == "number" then return string.format("BANK %d", math.max(1, math.min(6, math.floor(fm) + 1))) end
  return "BANK 1"
end

local function panel(x, y, w, h)
  lcd.drawFilledRectangle(x, y, w, h, C.panel)
  lcd.drawRectangle(x, y, w, h, C.blue)
end

local function refresh(w, event, touchState)
  setTheme(w.options.Theme)
  background(w); loadModelImage()
  local z = w.zone
  local x, y, sw, sh = math.floor(z.x), math.floor(z.y), math.floor(z.w), math.floor(z.h)
  -- This layout is designed for the TX16S MK3's 800 x 480 full-screen zone.
  local sx, sy = sw / 800, sh / 480
  local function X(v) return x + math.floor(v * sx) end
  local function Y(v) return y + math.floor(v * sy) end
  local function W(v) return math.floor(v * sx) end
  local function H(v) return math.floor(v * sy) end
  local function text(px, py, str, flags, color) lcd.drawText(X(px), Y(py), str, flags + color) end

  local arm_on = false
  if w.options.ArmSource and w.options.ArmSource ~= 0 then
    local arm_val = getValue(w.options.ArmSource)
    if type(arm_val) == "number" then arm_on = arm_val > 0 end
  else
    arm_on = sensor(13) > 0 -- Fallback to telemetry sensor
  end

  if LED_STRIP_LENGTH and LED_STRIP_LENGTH > 0 and setRGBLedColor and applyRGBLedColors then
    local enabled = w.options.DispLED == 1
    local color = math.max(1, math.min(#themes, w.options.LEDColor or 5))
    if led_cache.enabled ~= enabled or led_cache.color ~= color then
      led_cache.enabled, led_cache.color = enabled, color
      if enabled then
        local t = themes[color]
        for i = 0, LED_STRIP_LENGTH - 1 do
          setRGBLedColor(i, t[1], t[2], t[3])
        end
      else
        for i = 0, LED_STRIP_LENGTH - 1 do
          setRGBLedColor(i, 0, 0, 0)
        end
      end
      applyRGBLedColors()
    end
  end

  local vbat, curr, hspd, capa = volts(sensor(1)), amps(sensor(2)), sensor(3), sensor(4)
  local tesc, vbec, gov, vcel = sensor(6), volts(sensor(12)), sensor(14), volts(sensor(15))
  local timer, timerColor = timerText(w)
  local cells = vbat > 0 and math.max(1, math.floor(vbat / 4.2 + 0.85)) or 0
  local telemetry = false
  for i = 1, #sensors do if id[i] and stat(i, "cur") ~= 0 then telemetry = true break end end

  lcd.drawFilledRectangle(x, y, sw, sh, C.bg)
  lcd.drawRectangle(x, y, sw, sh, C.blue)
  -- Header: model name, selected MK3 timer, and transmitter battery/clock.
  local modelName = (model.getInfo() or {}).name or ""
  local txVoltage = getValue("tx-voltage") or getValue("TxBt") or 0
  local dt = getDateTime()
  local clock = string.format("%02d:%02d", dt.hour or 0, dt.min or 0)
  text(14, 10, modelName ~= "" and modelName or "ELECTRIC", MIDSIZE, C.white)
  text(400, 8, timer, CENTER + DBLSIZE, timerColor)
  text(600, 16, string.format("%.1fV", txVoltage), BOLD + SMLSIZE, C.white)
  text(689, 16, "/", RIGHT + BOLD + SMLSIZE, C.white)
  text(790, 16, clock, RIGHT + BOLD + SMLSIZE, C.dim)
  lcd.drawLine(X(0), Y(58), X(800), Y(58), SOLID, C.blue)

  -- Left: the model-specific helicopter image and governor status.
  -- Match the lower edge of the right-hand telemetry frame (y = 380).
  panel(X(10), Y(70), W(270), H(310))
  if heli_pic then lcd.drawBitmap(heli_pic, X(49), Y(115)) end
  text(145, 272, "0 Flights", CENTER + SMLSIZE, C.dim)
  local gov_on = gov > 0
  
  lcd.drawFilledRectangle(X(30), Y(302), W(110), H(28), C.panel2)
  text(85, 307, "GOV", CENTER + SMLSIZE, C.white)
  lcd.drawFilledRectangle(X(30), Y(330), W(110), H(42), gov_on and C.green or C.red)
  text(85, 340, gov_on and "ON" or "OFF", CENTER + MIDSIZE, C.white)

  lcd.drawFilledRectangle(X(150), Y(302), W(110), H(28), C.panel2)
  text(205, 307, "STATUS", CENTER + SMLSIZE, C.white)
  lcd.drawFilledRectangle(X(150), Y(330), W(110), H(42), arm_on and C.red or C.green)
  text(205, 340, arm_on and "ARMED" or "SAFE", CENTER + MIDSIZE, C.white)
  -- Battery summary sits below the left frame, in the bottom status area.
  text(145, 397, string.format("BATTERY  %dS  %.1fV", cells, vbat), CENTER + SMLSIZE, C.dim)
  text(145, 419, string.format("%.0f mAh used", capa), CENTER + SMLSIZE, C.dim)

  -- Right: Headspeed and ESC blocks.
  panel(X(295), Y(70), W(495), H(150))
  text(318, 84, "HEADSPEED  RPM", MIDSIZE, C.white)
  text(320, 117, string.format("%.0f", hspd), XXLSIZE, C.white)
  text(765, 114, string.format("max  %.0f", stat(3, "max")), RIGHT + SMLSIZE, C.white)
  text(765, 137, string.format("min   %.0f", stat(3, "min")), RIGHT + SMLSIZE, C.white)
  -- Reuse the Tmcu field here so
  -- this dashboard can show useful FC data.
  text(765, 160, string.format("MCU TEMP  %.0f °C", sensor(7)), RIGHT + SMLSIZE, C.white)

  panel(X(295), Y(236), W(495), H(144))
  local labels = { "AMPS", "Cell", "BEC", "ESC Temp" }
  local nums = { string.format("%.1f", curr), string.format("%.2f", vcel), string.format("%.1f", vbec), string.format("%.0f", tesc) }
  local units = { "A", "V", "V", "°C" }
  local subs = {
    string.format("max %.1fA", amps(stat(2, "max"))),
    string.format("min %.2fV", volts(stat(15, "min"))),
    string.format("min %.1fV", volts(stat(12, "min"))),
    string.format("max %.0f°C", stat(6, "max")),
  }
  local cell_color = (vcel > 0 and vcel < 3.8) and C.red or C.white
  local esc_temp_color = tesc > 60 and C.red or C.white
  for i = 1, 4 do
    local cx = 295 + (i - 1) * 124
    if i > 1 then lcd.drawLine(X(cx), Y(236), X(cx), Y(380), SOLID, C.blue) end
    text(cx + 62, 252, labels[i], CENTER + SMLSIZE, C.dim)
    
    local val_color = C.white
    if i == 2 then val_color = cell_color
    elseif i == 4 then val_color = esc_temp_color end
    
    local num, unit = nums[i], units[i]
    local split_x = cx + 62 + (string.len(num) - 3) * 12 + 20
    
    text(split_x, 284, num, RIGHT + DBLSIZE, val_color)
    text(split_x + 2, 302, unit, 0, val_color)
    
    text(cx + 62, 341, subs[i], CENTER + SMLSIZE, C.dim)
  end

  panel(X(295), Y(402), W(124), H(44))
  text(357, 415, bankText(w), CENTER, C.white)

  if not telemetry then
    lcd.drawFilledRectangle(X(434), Y(402), W(356), H(44), C.red)
    text(612, 412, "NO DATA", CENTER + MIDSIZE, C.white)
  else
    text(20, 420, string.format("BATTERY  %dS  %.1fV / %.0f mAh used", cells, vbat, capa), SMLSIZE, C.dim)
  end
end

return { name = NAME, options = options, create = create, update = update, refresh = refresh, background = background }
