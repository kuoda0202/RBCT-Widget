-- RBCT helicopter dashboard for EdgeTX / TX16S MK3.
-- Author: 雷恩 / Ryan Kuo
-- Model picture order: Model Setup bitmap (/IMAGES), RBCT/modelImage/<model>.png,
-- RBCT/modelImage/<model without its first character>.png, then default.png.
local NAME = "RBCT"
local VERSION = "v 1.0.003"

-- Keep this list byte-for-byte compatible with standard telemetry. The order is
-- deliberately arranged to ensure standard telemetry setup works here.
local sensors = { "Vbat", "Curr", "Hspd", "Capa", "Bat%", "Tesc", "Tmcu", "1RSS", "2RSS", "RQly", "Thr", "Vbec", "ARM", "Gov", "Vcel", "FM" }
local id, mm = {}, {}
local heli_pic, loaded_model_key
local led_cache = { enabled = nil, color = nil }

local options = {
  { "Theme", CHOICE, 4, { "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet", "Black", "TRN", "Pink" } },
  { "Transp BG", BOOL, 0 },
  { "DispLED", BOOL, 0 },
  { "LED Color", CHOICE, 4, { "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet", "Pink", "Peach", "Rainbow" } },
  { "UserName", STRING, "Pilot" },
  { "Timer", VALUE, 1, 1, 3 }, -- TX16S MK3 model timer 1..3
  { "Arm Source", SOURCE, 0 },
  { "Arm Invert", BOOL, 0 },
  { "BankSwitch", SOURCE, 0 },
  { "Logbook Sw", SOURCE, 0 },
  { "Reset FlyCount", SOURCE, 0 },
}

local C = {
  bg = lcd.RGB(7, 22, 72), blue = lcd.RGB(0, 126, 255),
  panel = lcd.RGB(15, 48, 122), panel2 = lcd.RGB(22, 61, 143),
  white = lcd.RGB(242, 247, 255), dim = lcd.RGB(147, 193, 255),
  red = lcd.RGB(255, 67, 84),    green = lcd.RGB(0, 180, 0), black = lcd.RGB(0, 0, 0),
  orange = lcd.RGB(255, 135, 0), yellow = lcd.RGB(255, 205, 0),
}

-- Selectable colour themes. Blue is the default.
local themes = {
  { 255,   0,   0 }, -- Red
  { 255, 135,   0 }, -- Orange
  { 255, 205,   0 }, -- Yellow
  {  40, 205,  90 }, -- Green
  {   0, 126, 255 }, -- Blue
  {  82,  82, 220 }, -- Indigo
  { 175,  70, 235 }, -- Violet
  { 128, 128, 128 }, -- Black
  { 255, 255, 255 }, -- TRN
  { 255, 105, 180 }, -- Pink
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

local function getLogFilePath()
  local modelName = (model.getInfo() or {}).name or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  return "/WIDGETS/RBCT/flights_" .. cleanName .. ".txt"
end

local function loadFlightLog(w)
  local path = getLogFilePath()
  local f = io.open(path, "r")
  local dt = getDateTime()
  local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)
  
  w.lifetime_count = 0
  if f then
    local content = io.read(f, 2048) or ""
    io.close(f)
    local parts = {}
    for part in string.gmatch(content, "[^,]+") do
      table.insert(parts, part)
    end
    if #parts >= 1 then
      local log_date = parts[1]
      local today_count = tonumber(parts[2]) or 0
      local lifetime_count = tonumber(parts[3]) or today_count
      
      w.lifetime_count = lifetime_count
      if log_date == today then
        w.flight_count = today_count
      else
        w.flight_count = 0 -- new day
      end
    end
  else
    w.flight_count = 0
  end
  w.last_date = today
  w.log_loaded = true
end

local function saveFlightLog(w)
  local path = getLogFilePath()
  local f = io.open(path, "w")
  if f then
    io.write(f, w.last_date .. "," .. tostring(w.flight_count or 0) .. "," .. tostring(w.lifetime_count or 0))
    io.close(f)
  end
end

local function getLogbookPath()
  local modelName = (model.getInfo() or {}).name or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  return "/WIDGETS/RBCT/logbook_" .. cleanName .. ".txt"
end

local function loadLogbook(w)
  w.log_entries = {}
  local path = getLogbookPath()
  local f = io.open(path, "r")
  if f then
    local content = io.read(f, 2048) or ""
    io.close(f)
    for line in string.gmatch(content, "[^\r\n]+") do
      if string.len(line) > 5 then
        local parts = {}
        for p in string.gmatch(line, "[^,]+") do table.insert(parts, p) end
        table.insert(w.log_entries, parts)
        if #w.log_entries >= 10 then break end
      end
    end
  end
end

local function saveLogbook(w)
  local path = getLogbookPath()
  local f = io.open(path, "w")
  if f then
    for i=1, #w.log_entries do
      local p = w.log_entries[i]
      if type(p) == "table" and #p >= 8 then
        io.write(f, p[1]..","..p[2]..","..p[3]..","..p[4]..","..p[5]..","..p[6]..","..p[7]..","..p[8].."\n")
      elseif type(p) == "table" and #p >= 6 then
        io.write(f, p[1]..","..p[2]..","..p[3]..","..p[4]..","..p[5]..","..p[6].."\n")
      end
    end
    io.close(f)
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

  -- 自動偵測更換電池或重置遙測
  local cur_vbat = sensor(1)
  if cur_vbat == 0 and mm[1] and mm[1].max and mm[1].max > 0 then
    resetMinMax()
  end

  local cur_capa = sensor(4)
  if cur_capa < 10 and mm[4] and mm[4].max and mm[4].max > 50 then
    resetMinMax()
  end

  for i = 1, #sensors do
    local v = sensor(i)
    if id[i] then
      mm[i].cur = v
      if v ~= 0 then
        mm[i].min = mm[i].min and math.min(mm[i].min, v) or v
      end
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
  -- 移除 v > 200 的限制，避免 700 級直昇機大電流時顯示錯誤縮水 10 倍
  if v > 2000 then return v / 100 end
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

local function drawBgRect(x, y, w, h, color, is_transp)
  if is_transp then
    for i = 0, h - 1, 2 do
      lcd.drawLine(x, y + i, x + w - 1, y + i, SOLID, C.blue)
    end
  else
    lcd.drawFilledRectangle(x, y, w, h, color)
  end
end

local function panel(x, y, w, h, is_trn, is_transp)
  if is_trn then return end
  drawBgRect(x, y, w, h, C.panel, is_transp)
  lcd.drawRectangle(x, y, w, h, C.blue)
end

local function drawLogbook(w, x, y, sw, sh, sx, sy, is_trn, is_transp, f_mid, f_sml)
  local function X(v) return x + math.floor(v * sx) end
  local function Y(v) return y + math.floor(v * sy) end
  local function W(v) return math.floor(v * sx) end
  local function H(v) return math.floor(v * sy) end
  
  if not is_transp and not is_trn then
    lcd.drawFilledRectangle(x, y, sw, sh, C.bg)
  end
  if not is_trn then
    lcd.drawRectangle(x, y, sw, sh, C.blue)
  end
  
  if w.logbook_tab == 2 then
    lcd.drawText(X(400), Y(240), "- COMING SOON !! -", CENTER + f_mid + C.white)
    return
  end

  lcd.drawText(X(400), Y(20), "FLIGHT LOGBOOK", CENTER + f_mid + C.white)
  
  -- Demo UI removed

  lcd.drawLine(X(20), Y(55), X(780), Y(55), SOLID, C.panel2)
  
  local cols = { 50, 140, 240, 340, 440, 540, 640, 740 }
  local headers = { "TIME", "DUR", "MAX RPM", "MAX A", "MIN V", "MIN BEC", "MAX TMP", "mAh" }
  for i = 1, 8 do
    lcd.drawText(X(cols[i]), Y(65), headers[i], CENTER + f_sml + C.dim)
  end
  lcd.drawLine(X(20), Y(95), X(780), Y(95), SOLID, C.panel2)
  
  local entries_to_draw = w.log_entries

  -- Draw only up to 4 entries in split-screen mode
  for i = 1, math.min(4, #(entries_to_draw or {})) do
    local py = Y(95 + (i-1)*32)
    local parts = entries_to_draw[i]
    if type(parts) == "table" and #parts >= 8 then
      lcd.drawText(X(cols[1]), py, parts[1], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[2]), py, parts[2], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[3]), py, parts[3], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[4]), py, parts[4], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[5]), py, parts[5], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[6]), py, parts[6], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[7]), py, parts[7].."°", CENTER + f_sml + C.white)
      lcd.drawText(X(cols[8]), py, parts[8], CENTER + f_sml + C.white)
    elseif type(parts) == "table" and #parts >= 6 then
      lcd.drawText(X(cols[1]), py, parts[1], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[2]), py, parts[2], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[3]), py, parts[3], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[4]), py, parts[4], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[5]), py, parts[5], CENTER + f_sml + C.white)
      lcd.drawText(X(cols[6]), py, "-", CENTER + f_sml + C.white)
      lcd.drawText(X(cols[7]), py, "-", CENTER + f_sml + C.white)
      lcd.drawText(X(cols[8]), py, parts[6], CENTER + f_sml + C.white)
    end
  end

  if not entries_to_draw or #entries_to_draw == 0 then
    lcd.drawText(X(400), Y(120), "- NO FLIGHT DATA YET -", CENTER + f_sml + C.dim)
  end

  -- ==========================================
  -- Chart Area (Bottom Half)
  -- ==========================================
  lcd.drawText(X(20), Y(230), "LAST FLIGHT CHART", f_sml + C.white)
  
  -- Color Legend
  lcd.drawFilledRectangle(X(310), Y(235), W(10), H(10), C.green)
  lcd.drawText(X(330), Y(230), "RPM", f_sml + C.white)
  
  lcd.drawFilledRectangle(X(400), Y(235), W(10), H(10), C.orange)
  lcd.drawText(X(420), Y(230), "VOLT", f_sml + C.white)
  
  lcd.drawFilledRectangle(X(500), Y(235), W(10), H(10), C.red)
  lcd.drawText(X(520), Y(230), "AMPS", f_sml + C.white)
  
  lcd.drawFilledRectangle(X(590), Y(235), W(10), H(10), C.blue)
  lcd.drawText(X(610), Y(230), "BEC", f_sml + C.white)
  
  lcd.drawFilledRectangle(X(680), Y(235), W(10), H(10), C.yellow)
  lcd.drawText(X(700), Y(230), "TMP", f_sml + C.white)
  
  lcd.drawLine(X(20), Y(255), X(780), Y(255), SOLID, C.panel2)

  local cx, cw = 50, 660
  local cy1, ch1 = 270, 95
  local cy2, ch2 = 380, 75
  
  -- Top Grid (Power)
  lcd.drawRectangle(X(cx), Y(cy1), W(cw), H(ch1), C.panel2)
  lcd.drawLine(X(cx), Y(cy1 + ch1/2), X(cx + cw), Y(cy1 + ch1/2), DOTTED, C.panel2)
  
  -- Bottom Grid (Health)
  lcd.drawRectangle(X(cx), Y(cy2), W(cw), H(ch2), C.panel2)

  if not w.chart_data then
    w.chart_data = {}
  end

  local data = w.chart_data
  local len = #data
  if len >= 2 then
    local max_rpm = 2500
    local max_v, min_v = 55, 40
    local max_a = 150
    local max_b, min_b = 9, 6
    local max_t, min_t = 100, 20
    
    local max_points = 50
    local draw_len = math.min(len, max_points)
    local stride = (len - 1) / (draw_len - 1)
    local step = cw / (draw_len - 1)
    
    local base_y1 = cy1 + ch1
    local base_y2 = cy2 + ch2
    local px, pyr, pyv, pya, pyb, pyt
    
    for i = 1, draw_len do
      local data_idx = math.floor(1 + (i - 1) * stride + 0.5)
      local p = data[data_idx]
      local scr_x = X(cx + (i-1) * step)
      
      -- Power Chart Math
      local scr_yr = Y(base_y1 - (math.max(0, math.min(max_rpm, p[1])) / max_rpm) * ch1)
      local scr_yv = Y(base_y1 - (math.max(0, math.min(max_v - min_v, p[2] - min_v)) / (max_v - min_v)) * ch1)
      local scr_ya = Y(base_y1 - (math.max(0, math.min(max_a, p[3])) / max_a) * ch1)
      
      -- Health Chart Math
      local scr_yb = Y(base_y2 - (math.max(0, math.min(max_b - min_b, p[4] - min_b)) / (max_b - min_b)) * ch2)
      local scr_yt = Y(base_y2 - (math.max(0, math.min(max_t - min_t, p[5] - min_t)) / (max_t - min_t)) * ch2)
      
      if i > 1 then
        lcd.drawLine(px, pyr, scr_x, scr_yr, SOLID, C.green)
        lcd.drawLine(px, pyv, scr_x, scr_yv, SOLID, C.orange)
        lcd.drawLine(px, pya, scr_x, scr_ya, SOLID, C.red)
        
        lcd.drawLine(px, pyb, scr_x, scr_yb, SOLID, C.blue)
        lcd.drawLine(px, pyt, scr_x, scr_yt, SOLID, C.yellow)
      end
      px, pyr, pyv, pya, pyb, pyt = scr_x, scr_yr, scr_yv, scr_ya, scr_yb, scr_yt
    end
    
    -- Top Axes Labels
    lcd.drawText(X(cx - 5), Y(cy1 - 5), "2500", RIGHT + f_sml + C.green)
    lcd.drawText(X(cx - 5), Y(base_y1 - 15), "0", RIGHT + f_sml + C.green)
    
    lcd.drawText(X(cx + cw + 5), Y(cy1 - 5), "55V", f_sml + C.orange)
    lcd.drawText(X(cx + cw + 5), Y(base_y1 - 15), "40V", f_sml + C.orange)
    
    lcd.drawText(X(cx + cw + 40), Y(cy1 - 5), "150A", f_sml + C.red)
    lcd.drawText(X(cx + cw + 40), Y(base_y1 - 15), "0A", f_sml + C.red)
    
    -- Bottom Axes Labels
    lcd.drawText(X(cx - 5), Y(cy2 - 5), "100°", RIGHT + f_sml + C.yellow)
    lcd.drawText(X(cx - 5), Y(base_y2 - 15), "20°", RIGHT + f_sml + C.yellow)
    
    lcd.drawText(X(cx + cw + 5), Y(cy2 - 5), "9.0V", f_sml + C.blue)
    lcd.drawText(X(cx + cw + 5), Y(base_y2 - 15), "6.0V", f_sml + C.blue)
  end
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
  local is_trn = (w.options.Theme == 9)
  local is_transp = (w.options["Transp BG"] == 1 or w.options["Transp BG"] == true)
  local function text(px, py, str, flags, color)
    if (is_trn or is_transp) and color ~= C.black then
      lcd.drawText(X(px) + 2, Y(py) + 2, str, flags + C.black)
    end
    lcd.drawText(X(px), Y(py), str, flags + color)
  end
  local f_xxl, f_dbl, f_mid, f_sml, f_0 = XXLSIZE, DBLSIZE, MIDSIZE, SMLSIZE, 0
  if sw < 600 then
    f_xxl, f_dbl, f_mid, f_sml, f_0 = DBLSIZE, MIDSIZE, 0, SMLSIZE, SMLSIZE
  end

  local is_tap = false
  local tx, ty = 0, 0
  if type(touchState) == "table" and type(touchState.x) == "number" and type(touchState.y) == "number" then
    tx, ty = touchState.x, touchState.y
    local t_type = touchState.type
    -- Hardcode EdgeTX touch types (1=FIRST, 2=BREAK, 3=TAP) to bypass missing global constants
    if t_type == 1 or t_type == 2 or t_type == 3 then
      is_tap = true
    end
  end

  if event == EVT_VIRTUAL_ENTER then
    w.show_logbook = not w.show_logbook
    if w.show_logbook then w.logbook_tab = 1 end
    return true
  elseif event == EVT_VIRTUAL_EXIT then
    if w.show_logbook then
      w.show_logbook = false
      return true
    elseif lcd.exitFullScreen then
      lcd.exitFullScreen()
      return true
    end
  elseif is_tap then
    if not w.show_logbook then
      -- Ultra-loose touch zone: covers BANK, LOG, and NO DATA (the whole bottom right panel area)
      if tx >= X(300) and ty >= Y(380) then
        w.show_logbook = true
        w.logbook_tab = 1
        return true
      end
    else
      w.show_logbook = false
      return true
    end
  end

  if w.options["Logbook Sw"] and w.options["Logbook Sw"] ~= 0 then
    local l_val = getValue(w.options["Logbook Sw"])
    if w.last_logbook_sw_val ~= l_val then
      w.last_logbook_sw_val = l_val
      if type(l_val) == "boolean" then
        w.show_logbook = l_val
        w.logbook_tab = 1
      elseif type(l_val) == "number" then
        -- 1024 (down), 100 (percent down), 2 (index down)
        if l_val >= 90 or l_val == 2 then
          w.show_logbook = true
          w.logbook_tab = 2
        -- 0 (mid)
        elseif (l_val > -50 and l_val < 90) or l_val == 1 then
          w.show_logbook = true
          w.logbook_tab = 1
        else
          w.show_logbook = false
        end
      end
    end
  end

  local arm_on = false
  if w.options["Arm Source"] and w.options["Arm Source"] ~= 0 then
    local arm_val = getValue(w.options["Arm Source"])
    if type(arm_val) == "boolean" then 
      arm_on = arm_val
    elseif type(arm_val) == "number" then 
      arm_on = arm_val > 0 
    end
    if w.options["Arm Invert"] == 1 or w.options["Arm Invert"] == true then
      arm_on = not arm_on
    end
  else
    arm_on = sensor(13) > 0 -- Fallback to telemetry sensor
  end

  if not w.log_loaded then
    loadFlightLog(w)
    loadLogbook(w)
  end

  local dt = getDateTime()
  local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)
  if w.log_loaded and w.last_date ~= today then
    w.flight_count = 0
    w.last_date = today
    saveFlightLog(w)
  end

  if w.log_loaded then
    if arm_on then
      if not w.last_arm_state then
        w.arm_start_time = getTime()
        w.flight_counted_this_arm = false
        w.chart_data = {} -- Reset chart on new flight
        w.last_sample_time = w.arm_start_time
      elseif not w.flight_counted_this_arm and w.arm_start_time then
        if (getTime() - w.arm_start_time) >= 600 then
          local chk_rpm = stat(3, "max") or 0
          local chk_curr = amps(stat(2, "max")) or 0
          if chk_rpm > 800 or chk_curr > 2 then
            w.flight_count = (w.flight_count or 0) + 1
            w.lifetime_count = (w.lifetime_count or 0) + 1
            w.flight_counted_this_arm = true
            saveFlightLog(w)
          end
        end
      end
      
      -- Sample chart data every 3 seconds (300 ticks)
      if (getTime() - (w.last_sample_time or 0)) >= 300 then
        w.last_sample_time = getTime()
        if not w.chart_data then w.chart_data = {} end
        
        local rpm = stat(3, "cur") or 0
        local vbat = volts(sensor(1)) or 0
        local curr = amps(sensor(2)) or 0
        local bec = volts(sensor(12)) or 0
        local tmp = stat(6, "cur") or 0
        
        table.insert(w.chart_data, {rpm, vbat, curr, bec, tmp})
        -- Ring Buffer (FIFO): keep only the last 200 points (approx 10 mins)
        if #w.chart_data > 200 then
           table.remove(w.chart_data, 1)
        end
      end
    else
      if w.flight_counted_this_arm and w.arm_start_time then
        local dur_s = math.floor((getTime() - w.arm_start_time) / 100)
        local dur_str = string.format("%02d:%02d", math.floor(dur_s / 60), dur_s % 60)
        local time_str = string.format("%02d:%02d", dt.hour or 0, dt.min or 0)
        local rpm_str = string.format("%.0f", stat(3, "max") or 0)
        local amps_str = string.format("%.1f", amps(stat(2, "max") or 0))
        local cell_str = string.format("%.2f", volts(stat(15, "min") or 0))
        local bec_str = string.format("%.2f", volts(stat(12, "min") or 0))
        local tmp_str = string.format("%.0f", stat(6, "max") or 0)
        local capa_str = string.format("%.0f", stat(4, "cur") or stat(4, "max") or 0)
        local parts = {time_str, dur_str, rpm_str, amps_str, cell_str, bec_str, tmp_str, capa_str}
        table.insert(w.log_entries, 1, parts)
        if #w.log_entries > 10 then table.remove(w.log_entries) end
        saveLogbook(w)
      end
      w.arm_start_time = nil
      w.flight_counted_this_arm = false
    end
    w.last_arm_state = arm_on
  end

  local reset_on = false
  if w.options["Reset FlyCount"] and w.options["Reset FlyCount"] ~= 0 then
    local r_val = getValue(w.options["Reset FlyCount"])
    if type(r_val) == "boolean" then
      reset_on = r_val
    elseif type(r_val) == "number" then
      reset_on = r_val > 0
    end
  end

  if w.log_loaded then
    if reset_on and not w.last_reset_state then
      w.flight_count = 0
      saveFlightLog(w)
    end
    w.last_reset_state = reset_on
  end

  if LED_STRIP_LENGTH and LED_STRIP_LENGTH > 0 and setRGBLedColor and applyRGBLedColors then
    local enabled = w.options.DispLED == 1
    local color_opt = w.options["LED Color"]
    local color_idx = type(color_opt) == "number" and color_opt or 4
    local is_rainbow = (color_idx == 9) or (color_idx == 10)

    if enabled and is_rainbow then
      local offset = math.floor(getTime() / 15)
      if led_cache.enabled ~= enabled or led_cache.color ~= 99 or led_cache.offset ~= offset then
        led_cache.enabled, led_cache.color, led_cache.offset = enabled, 99, offset
        for i = 0, LED_STRIP_LENGTH - 1 do
          local t = themes[((i + offset) % 9) + 1]
          setRGBLedColor(i, t[1], t[2], t[3])
        end
        applyRGBLedColors()
      end
    else
      -- Solid color logic (preserving original mapping behavior)
      local color = math.max(1, math.min(9, color_idx))
      -- If 0-based index was passed, we ideally want +1. But we keep it safe:
      if color_idx == 0 then color = 1 elseif color_idx > 0 and color_idx < 9 then color = color_idx + 1 end
      
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
  end

  local vbat, curr, hspd, capa = volts(sensor(1)), amps(sensor(2)), sensor(3), sensor(4)
  local tesc, vbec, gov, vcel = sensor(6), volts(sensor(12)), sensor(14), volts(sensor(15))
  local timer, timerColor = timerText(w)
  -- 使用最高紀錄的電池電壓 (剛接上時的靜止電壓) 來計算 S 數，避免飛行中因壓降導致 S 數亂跳
  local max_vbat = stat(1, "max")
  local cells = max_vbat > 0 and math.max(1, math.floor(max_vbat / 4.2 + 0.85)) or 0
  local telemetry = false
  for i = 1, #sensors do if id[i] and stat(i, "cur") ~= 0 then telemetry = true break end end

  if w.show_logbook then
    local ok, err = pcall(drawLogbook, w, x, y, sw, sh, sx, sy, is_trn, is_transp, f_mid, f_sml)
    if not ok then
      lcd.drawFilledRectangle(x, y, sw, sh, C.red)
      lcd.drawText(x + 10, y + 10, "LOGBOOK CRASH:", 0)
      lcd.drawText(x + 10, y + 40, tostring(err), 0)
    end
    return
  end

  if not is_transp and not is_trn then
    lcd.drawFilledRectangle(x, y, sw, sh, C.bg)
  end
  if not is_trn then
    lcd.drawRectangle(x, y, sw, sh, C.blue)
  end
  -- Header: model name, selected MK3 timer, and transmitter battery/clock.
  local modelName = (model.getInfo() or {}).name or ""
  local txVoltage = getValue("tx-voltage") or getValue("TxBt") or 0
  local dt = getDateTime()
  local clock = string.format("%02d:%02d", dt.hour or 0, dt.min or 0)
  text(14, 10, modelName ~= "" and modelName or "ELECTRIC", f_mid, C.white)
  text(400, 8, timer, CENTER + f_dbl, timerColor)
  text(600, 16, string.format("%.1fV", txVoltage), BOLD + f_sml, C.white)
  text(790, 16, clock, RIGHT + BOLD + f_sml, C.dim)
  if not is_trn then lcd.drawLine(X(0), Y(58), X(800), Y(58), SOLID, C.blue) end

  -- Left: the model-specific helicopter image and governor status.
  -- Match the lower edge of the bottom right-hand frames (y = 470).
  panel(X(10), Y(70), W(270), H(400), is_trn, is_transp)
  if heli_pic then lcd.drawBitmap(heli_pic, X(49), Y(80), math.floor(sx * 100)) end
  text(80, 210, "Today: " .. (w.flight_count or 0), CENTER + f_sml, C.white)
  text(210, 210, "Total: " .. (w.lifetime_count or 0), CENTER + f_sml, C.dim)
  local gov_on = gov > 0
  
  if not is_trn then drawBgRect(X(20), Y(235), W(120), H(28), C.panel2, is_transp) end
  text(80, 240, "GOV", CENTER + f_sml, C.white)
  lcd.drawFilledRectangle(X(20), Y(263), W(120), H(42), gov_on and C.green or C.red)
  lcd.drawText(X(80), Y(269), gov_on and "ON" or "OFF", CENTER + f_mid + C.white)

  if not is_trn then drawBgRect(X(150), Y(235), W(120), H(28), C.panel2, is_transp) end
  text(210, 240, "STATUS", CENTER + f_sml, C.white)
  lcd.drawFilledRectangle(X(150), Y(263), W(120), H(42), arm_on and C.red or C.green)
  lcd.drawText(X(210), Y(269), arm_on and "ARMED" or "SAFE", CENTER + f_mid + C.white)

  -- Battery Percentage Bar
  local bat_pct = sensor(5)
  local pct_color = C.red
  if bat_pct > 30 then pct_color = C.green
  elseif bat_pct > 15 then pct_color = C.orange
  end
  
  if not is_trn then drawBgRect(X(20), Y(320), W(250), H(50), C.panel2, is_transp) end
  local bar_w = math.max(0, math.min(250, math.floor((bat_pct / 100) * 250)))
  if bar_w > 0 then
    lcd.drawFilledRectangle(X(20), Y(320), W(bar_w), H(50), pct_color)
  end
  lcd.drawRectangle(X(20), Y(320), W(250), H(50), is_trn and C.black or C.blue)
  text(145, 329, string.format("%d %%", bat_pct), CENTER + f_mid, C.white)
  -- Battery summary sits below the left frame, in the bottom status area.
  text(145, 390, string.format("BATTERY  %dS  %.1fV", cells, vbat), CENTER + f_sml, C.dim)
  text(145, 412, string.format("%.0f mAh used", capa), CENTER + f_sml, C.dim)
  text(145, 434, VERSION, CENTER + f_sml, C.dim)

  -- Right: Headspeed and ESC blocks.
  panel(X(295), Y(70), W(495), H(160), is_trn, is_transp)
  text(318, 89, "HEADSPEED  RPM", f_mid, C.white)
  text(320, 127, string.format("%.0f", hspd), f_xxl, C.white)
  text(765, 124, string.format("max  %.0f", stat(3, "max")), RIGHT + f_sml, C.white)
  text(765, 147, string.format("min   %.0f", stat(3, "min")), RIGHT + f_sml, C.white)
  -- Reuse the Tmcu field here so
  -- this dashboard can show useful FC data.
  text(765, 175, string.format("MCU TEMP  %.0f °C", sensor(7)), RIGHT + f_sml, C.white)

  panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)
  local labels = { "AMPS", "Cell", "BEC", "ESC Temp" }
  local nums = { string.format("%.1f", curr), string.format("%.2f", vcel), string.format("%.1f", vbec), string.format("%.0f", tesc) }
  local units = { "A", "V", "V", "°C" }
  local subs = {
    string.format("max %.1fA", amps(stat(2, "max"))),
    string.format("min %.2fV", volts(stat(15, "min"))),
    string.format("min %.1fV", volts(stat(12, "min"))),
    string.format("max %.0f°C", stat(6, "max")),
  }
  -- 將單芯警告電壓從 3.8V 調降至合理的 3.5V，避免起飛後一直閃紅字
  local cell_color = (vcel > 0 and vcel < 3.5) and C.red or C.white
  local esc_temp_color = tesc > 60 and C.red or C.white
  for i = 1, 4 do
    local cx = 295 + (i - 1) * 124
    if i > 1 and not is_trn then lcd.drawLine(X(cx), Y(245), X(cx), Y(405), SOLID, C.blue) end
    text(cx + 62, 265, labels[i], CENTER + f_sml, C.dim)
    
    local val_color = C.white
    if i == 2 then val_color = cell_color
    elseif i == 4 then val_color = esc_temp_color end
    
    local num, unit = nums[i], units[i]
    local split_x = cx + 62 + (string.len(num) - 3) * 12 + 20
    
    text(split_x, 301, num, RIGHT + f_dbl, val_color)
    text(split_x + 2, 319, unit, f_0, val_color)
    
    text(cx + 62, 362, subs[i], CENTER + f_sml, C.dim)
  end

  panel(X(295), Y(420), W(124), H(50), is_trn, is_transp)
  text(357, 436, bankText(w), CENTER + f_0, C.white)

  if not telemetry then
    lcd.drawFilledRectangle(X(434), Y(420), W(356), H(50), C.red)
    lcd.drawText(X(612), Y(429), "NO DATA", CENTER + f_mid + C.white)
  else
    local user_name = w.options.UserName or ""
    if user_name ~= "" then
      text(612, 429, user_name, CENTER + f_mid, C.white)
    end
  end
end

return { name = NAME, options = options, create = create, update = update, refresh = refresh, background = background }
