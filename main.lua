-- RBCT helicopter dashboard for EdgeTX / TX16S MK3.
-- Author: 雷恩 / Ryan Kuo
-- Model picture order: Model Setup bitmap (/IMAGES), RBCT/modelImage/<model>.png,
-- RBCT/modelImage/<model without its first character>.png, then default.png.
local NAME = "RBCT"
local VERSION = "v1.0.7"

-- Keep this list byte-for-byte compatible with standard telemetry. The order is
-- deliberately arranged to ensure standard telemetry setup works here.
local sensors = { "Vbat", "Curr", "Hspd", "Capa", "Bat%", "Tesc", "Tmcu", "1RSS", "2RSS", "RQly", "Thr", "Vbec", "ARM", "Gov", "Vcel", "FM", "Tspd" }
local id, mm = {}, {}
local heli_pic, loaded_model_key
local led_cache = { enabled = nil, color = nil }

local function detectLanguage()
  local lang_str = ""
  if getGeneralSettings then
    local gs = getGeneralSettings()
    if type(gs) == "table" then
      lang_str = tostring(gs.language or gs.voice or "")
    end
  end
  if getLanguage then
    lang_str = lang_str .. " " .. tostring(getLanguage())
  end
  lang_str = string.lower(lang_str)

  if string.find(lang_str, "zh") or string.find(lang_str, "tw") or string.find(lang_str, "cn") or string.find(lang_str, "hk") then
    return true
  end
  if string.find(lang_str, "en") or string.find(lang_str, "us") or string.find(lang_str, "gb") then
    return false
  end
  if fstat and (fstat("/SOUNDS/tw") or fstat("/SOUNDS/zh") or fstat("/SOUNDS/cn")) then
    return true
  end
  return false
end

local is_zh = detectLanguage()

local options = {
  { "Theme", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Black", "TRN", "Pink", "LCD" } },
  { "Transp BG", BOOL, 0 },
  { "DispLED", BOOL, 0 },
  { "LED Color", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Pink", "Rainbow" } },
  { "Heli Type", CHOICE, 2, { "Nitro", "Electric" } },
  { "Arm Source", SOURCE, 0 },
  { "Arm Invert", BOOL, 0 },
  { "Logbook Sw", SOURCE, 0 },
  { "Bank Src", SOURCE, 0 },
  { "Light Sens", SOURCE, 0 },
  { "Voice Alm", BOOL, 0 },
  { "BEC Warn V", CHOICE, 5, { "5.0V", "5.5V", "6.0V", "6.4V", "6.6V", "7.0V", "7.4V", "8.0V" } },
  { "ESC T Warn", VALUE, 60, 40, 110 },
  { "Nit T Warn", VALUE, 120, 80, 160 },
  { "Bat% Voice", BOOL, 0 },
  { "Bat Low %", VALUE, 30, 15, 50 },
  { "UserName", STRING, "Pilot" },
  { "Timer", VALUE, 1, 1, 3 },
  { "Rst FlyCnt", SOURCE, 0 },
  { "Bat Track", SOURCE, 0 },
  { "Rst BatLog", SOURCE, 0 },
}

local option_aliases = {
  ["Theme"] = { "Theme", "UI 主題", "UI主題", "面板主題" },
  ["Transp BG"] = { "Transp BG", "背景 (BG)", "背景(BG)", "無底色", "BG 背景", "透明背景", "TranspBG" },
  ["DispLED"] = { "DispLED", "搖桿燈開關", "光圈開關", "LED燈開關", "Disp LED" },
  ["LED Color"] = { "LED Color", "搖桿燈顏色", "光圈顏色", "LED顏色", "LEDColor" },
  ["UserName"] = { "UserName", "使用者名稱", "使用者", "User Name" },
  ["Timer"] = { "Timer", "計時器選擇", "計時器" },
  ["Arm Source"] = { "Arm Source", "解鎖開關", "ArmSource" },
  ["Arm Invert"] = { "Arm Invert", "反向解鎖", "ArmInvert" },
  ["BankSwitch"] = { "BankSwitch", "Bank Src", "BANK開關", "BANK 開關", "BANK開關 (---為Auto)", "BANK開關 (---為自動)", "Bank Src (---=Auto)" },
  ["Bank Src"] = { "Bank Src", "BankSwitch", "BANK開關", "BANK 開關", "BANK開關 (---為Auto)", "BANK開關 (---為自動)", "Bank Src (---=Auto)" },
  ["Logbook Sw"] = { "Logbook Sw", "日誌開關", "LogbookSw" },
  ["Reset FlyCount"] = { "Reset FlyCount", "重置計數", "次數重置", "架次重置", "次數歸零", "次數清零" },
  ["Heli Type"] = { "Heli Type", "機型選擇", "動力模式", "動力選項", "油電選擇", "HeliType" },
  ["Bat Track"] = { "Bat Track", "電池日誌", "電池號碼", "電池紀錄", "電池追蹤" },
  ["Reset Bat Log"] = { "Reset Bat Log", "重置電池", "電池歸零", "電池重置", "清空電池" },
  ["Light Sens"] = { "Light Sens", "光感應LCD主題", "光感開關", "光感切換", "Auto LCD", "LightSens" },
  ["Voice Alarm"] = { "Voice Alarm", "語音警示", "語音警告", "VoiceAlarm", "語音" },
  ["BEC Warn V"] = { "BEC Warn V", "BEC 警示", "BEC 門檻", "BEC 警示門檻", "BEC低壓門檻", "BEC Voltage Warn" },
  ["ESC Temp Warn"] = { "ESC Temp Warn", "電變高溫警示", "電變高溫門檻", "電變高溫", "ESC TempWarn" },
  ["Nitro Temp Warn"] = { "Nitro Temp Warn", "油機高溫警示", "油機高溫門檻", "油機高溫", "Nitro TempWarn" },
  ["Bat% Voice"] = { "Bat% Voice", "電量語音報警", "電量語音", "Bat Voice" },
  ["Bat Low %"] = { "Bat Low %", "低電量警示", "低電量門檻", "低電門檻", "Bat Low" },
  ["Bat Crit %"] = { "Bat Crit %", "沒電警示", "沒電門檻", "臨界沒電門檻", "Bat Crit" },
}

local function getOption(w, key)
  if not w or not w.options then return nil end
  local val = w.options[key]
  if val ~= nil then return val end
  local aliases = option_aliases[key]
  if aliases then
    for i = 1, #aliases do
      local a_val = w.options[aliases[i]]
      if a_val ~= nil then return a_val end
    end
  end
  return nil
end

local basePath = "/WIDGETS/RBCT_Beta"

local w_last_mod_err = ""

-- Module cache for lazy loading
local modules = {}
local function loadModule(name)
  if not modules[name] then
    local paths = {
      basePath .. "/modules/" .. name .. ".lua",
      basePath .. "/modules/" .. name,
      "/WIDGETS/RBCT_Beta/modules/" .. name .. ".lua",
      "WIDGETS/RBCT_Beta/modules/" .. name .. ".lua"
    }
    local f, err = nil, ""
    for i = 1, #paths do
      f, err = loadScript(paths[i])
      if f then break end
    end
    if f then
      local ok, mod = pcall(f)
      if ok then
        modules[name] = mod
      else
        w_last_mod_err = "EXEC ERR: " .. tostring(mod)
      end
    else
      w_last_mod_err = "LOAD ERR: " .. tostring(err or "nil")
    end
  end
  return modules[name]
end

local C = {
  bg = lcd.RGB(7, 22, 72), blue = lcd.RGB(0, 126, 255),
  panel = lcd.RGB(15, 48, 122), panel2 = lcd.RGB(22, 61, 143),
  white = lcd.RGB(242, 247, 255), dim = lcd.RGB(147, 193, 255),
  red = lcd.RGB(255, 67, 84),    green = lcd.RGB(0, 180, 0), black = lcd.RGB(0, 0, 0),
  orange = lcd.RGB(255, 135, 0), yellow = lcd.RGB(255, 205, 0), cyan = lcd.RGB(0, 220, 255),
}

-- Selectable colour themes. Blue is the default.
local themes = {
  { 255,   0,   0 }, -- 1: Red
  { 255, 135,   0 }, -- 2: Orange
  { 255, 205,   0 }, -- 3: Yellow
  {  40, 205,  90 }, -- 4: Green
  {   0, 126, 255 }, -- 5: Blue
  {   0, 220, 255 }, -- 6: Cyan (水藍)
  { 175,  70, 235 }, -- 7: Violet
  { 128, 128, 128 }, -- 8: Black
  { 255, 255, 255 }, -- 9: TRN
  { 255, 105, 180 }, -- 10: Pink
}

local function parseThemeIndex(val)
  if type(val) == "number" then
    local n = math.floor(val)
    if n >= 1 and n <= 11 then return n end
    return 5
  elseif type(val) == "string" then
    local s = string.lower(val)
    if string.find(s, "red") or string.find(s, "紅") then return 1
    elseif string.find(s, "orange") or string.find(s, "橘") or string.find(s, "橙") then return 2
    elseif string.find(s, "yellow") or string.find(s, "黃") then return 3
    elseif string.find(s, "green") or string.find(s, "綠") then return 4
    elseif string.find(s, "cyan") or string.find(s, "水藍") or string.find(s, "水") or string.find(s, "深藍") or string.find(s, "靛") then return 6
    elseif string.find(s, "blue") or string.find(s, "藍") then return 5
    elseif string.find(s, "violet") or string.find(s, "紫") then return 7
    elseif string.find(s, "black") or string.find(s, "黑") then return 8
    elseif string.find(s, "trn") or string.find(s, "透") then return 9
    elseif string.find(s, "pink") or string.find(s, "粉") or string.find(s, "桃") then return 10
    elseif string.find(s, "lcd") or string.find(s, "晶") or string.find(s, "高反差") then return 11
    end
    local n = tonumber(val)
    if n then return parseThemeIndex(n) end
  end
  return 5
end

local led_colors = {
  { 255,   0,   0 }, -- 1: Red
  { 255, 135,   0 }, -- 2: Orange
  { 255, 205,   0 }, -- 3: Yellow
  {  40, 205,  90 }, -- 4: Green
  {   0, 126, 255 }, -- 5: Blue
  {   0, 220, 255 }, -- 6: Cyan (水藍)
  { 175,  70, 235 }, -- 7: Violet
  { 255, 105, 180 }, -- 8: Pink
}

local function parseLedColorIndex(val)
  if type(val) == "number" then
    local n = math.floor(val)
    if n >= 1 and n <= 9 then return n end
    if n == 0 then return 1 end
    return 5
  elseif type(val) == "string" then
    local s = string.lower(val)
    if string.find(s, "red") or string.find(s, "紅") then return 1
    elseif string.find(s, "orange") or string.find(s, "橘") or string.find(s, "橙") then return 2
    elseif string.find(s, "yellow") or string.find(s, "黃") then return 3
    elseif string.find(s, "green") or string.find(s, "綠") then return 4
    elseif string.find(s, "cyan") or string.find(s, "水藍") or string.find(s, "水") or string.find(s, "深藍") or string.find(s, "靛") then return 6
    elseif string.find(s, "blue") or string.find(s, "藍") then return 5
    elseif string.find(s, "violet") or string.find(s, "紫") then return 7
    elseif string.find(s, "pink") or string.find(s, "粉") or string.find(s, "桃") then return 8
    elseif string.find(s, "rainbow") or string.find(s, "彩虹") or string.find(s, "七彩") then return 9
    end
    local n = tonumber(val)
    if n then return parseLedColorIndex(n) end
  end
  return 5
end

local function hsvToRgb(h, s, v)
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  local r, g, b = 0, 0, 0
  if h < 60 then r, g, b = c, x, 0
  elseif h < 120 then r, g, b = x, c, 0
  elseif h < 180 then r, g, b = 0, c, x
  elseif h < 240 then r, g, b = 0, x, c
  elseif h < 300 then r, g, b = x, 0, c
  else r, g, b = c, 0, x
  end
  return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

local function setTheme(n)
  local idx = parseThemeIndex(n)
  if idx == 11 then
    -- Special High-Contrast LCD Aesthetic Theme
    C.blue = lcd.RGB(15, 25, 20)       -- Graphite text / lines
    C.bg = lcd.RGB(212, 224, 206)      -- Pale green-gray LCD background
    C.panel = lcd.RGB(194, 208, 186)   -- LCD panel tile
    C.panel2 = lcd.RGB(180, 196, 172)  -- Secondary LCD tile
    C.dim = lcd.RGB(75, 90, 75)        -- Dim label
    C.white = lcd.RGB(15, 25, 20)      -- Dark text
    C.black = lcd.RGB(212, 224, 206)   -- Inverse background
  else
    local t = themes[math.max(1, math.min(#themes, idx))]
    local r, g, b = t[1], t[2], t[3]
    C.blue = lcd.RGB(r, g, b)
    C.bg = lcd.RGB(math.max(5, math.floor(r * .10)), math.max(5, math.floor(g * .10)), math.max(5, math.floor(b * .10)))
    C.panel = lcd.RGB(math.max(8, math.floor(r * .28)), math.max(8, math.floor(g * .28)), math.max(8, math.floor(b * .28)))
    C.panel2 = lcd.RGB(math.max(10, math.floor(r * .40)), math.max(10, math.floor(g * .40)), math.max(10, math.floor(b * .40)))
    C.dim = lcd.RGB(math.min(255, 95 + math.floor(r * .45)), math.min(255, 95 + math.floor(g * .45)), math.min(255, 95 + math.floor(b * .45)))
    C.white = lcd.RGB(242, 247, 255)
    C.black = lcd.RGB(0, 0, 0)
  end
  C.theme = themes[idx] or themes[5]
end

local function applyDynamicTheme(w, arm_on)
  local base_theme = getOption(w, "Theme")
  local light_src = getOption(w, "Light Sens")
  local light_val = 0

  local is_light_active = false
  if light_src and light_src ~= 0 then
    local v = getValue(light_src)
    if type(v) == "table" then v = v.value end
    
    if type(v) == "boolean" then
      is_light_active = v
    elseif type(v) == "number" then
      is_light_active = (v > 0)
    end
  end
  local now = getTime()

  -- Initialize current theme if nil
  if not w.current_dynamic_theme then
    w.current_dynamic_theme = base_theme
  end

  if is_light_active then
    w.light_inactive_since = nil
    if not w.light_active_since then
      w.light_active_since = now
    elseif (now - w.light_active_since) >= 20 then -- 0.2s hysteresis
      w.current_dynamic_theme = 13 -- LCD theme
    end
  else
    w.light_active_since = nil
    if not w.light_inactive_since then
      w.light_inactive_since = now
    elseif (now - w.light_inactive_since) >= 20 then -- 0.2s hysteresis
      w.current_dynamic_theme = base_theme
    end
  end
  
  -- If light sensor is not active and no hysteresis is running, always ensure we track base_theme
  -- This allows dynamic menu updates to work instantly when light sensor is off
  if not is_light_active and not w.light_inactive_since then
      w.current_dynamic_theme = base_theme
  end

  setTheme(w.current_dynamic_theme)
end

local function resetMinMax()
  for i = 1, #sensors do mm[i] = { cur = 0, min = nil, max = nil } end
end

local sensor_aliases = {
  ["Tspd"] = { "Tspd", "TSpd", "TSPD", "TRPM" },
  ["Hspd"] = { "Hspd", "HSpd", "HSPD", "RPM" },
  ["Tesc"] = { "Tesc", "EscT", "Tmp1", "Temp", "TMP1" },
  ["Tmcu"] = { "Tmcu", "McuT", "Tmp2", "MCU" },
  ["Vbec"] = { "Vbec", "BecV", "RxBt", "BEC" },
  ["Vcel"] = { "Vcel", "CelV", "Cels" },
  ["FM"]   = { "FM", "PID#", "PID", "Pid#", "Bank" },
}

local function resolveSensors()
  for i, name in ipairs(sensors) do
    if not id[i] then
      local info = getFieldInfo(name)
      if info then
        id[i] = info.id
      else
        local aliases = sensor_aliases[name]
        if aliases then
          for a = 1, #aliases do
            local a_info = getFieldInfo(aliases[a])
            if a_info then
              id[i] = a_info.id
              break
            end
          end
        end
      end
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
  local name = m.name or ""
  if name ~= "" then
    local p = basePath .. "/modelImage/" .. name .. ".png"
    if fstat(p) then return p end
    -- Handle cases with a leading model-type marker (for example >RS5).
    p = basePath .. "/modelImage/" .. string.sub(name, 2) .. ".png"
    if fstat(p) then return p end
  end
  if m.bitmap and m.bitmap ~= "" then
    local p = m.bitmap
    if string.sub(p, 1, 1) ~= "/" then
      p = "/IMAGES/" .. p
    end
    if fstat(p) then return p end
  end
  return basePath .. "/default.png"
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

local function getActiveBatIndex(w)
  local bat_mod = loadModule("battery")
  if bat_mod then
    local bat_src = getOption(w, "Bat Track")
    local val = bat_src and (bat_src ~= 0) and getValue(bat_src) or nil
    return bat_mod.getBatIndex(val)
  end
  return 0
end

local function resetActiveBatLog(w)
  local batIdx = getActiveBatIndex(w)
  local modelName = (model.getInfo() or {}).name or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  local dt = getDateTime()
  local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)

  local logPath, lbPath, chPath
  if batIdx > 0 then
    logPath = basePath .. "/log_" .. cleanName .. "_BAT" .. batIdx .. ".txt"
    lbPath = basePath .. "/logbook_" .. cleanName .. "_BAT" .. batIdx .. ".txt"
    chPath = basePath .. "/chart_" .. cleanName .. "_BAT" .. batIdx .. ".txt"
  else
    logPath = basePath .. "/log_" .. cleanName .. ".txt"
    lbPath = basePath .. "/logbook_" .. cleanName .. ".txt"
    chPath = basePath .. "/chart_" .. cleanName .. ".txt"
  end

  local f1 = io.open(logPath, "w")
  if f1 then
    io.write(f1, today .. ",0,0")
    io.close(f1)
  end

  local f2 = io.open(lbPath, "w")
  if f2 then
    io.write(f2, "")
    io.close(f2)
  end

  local f3 = io.open(chPath, "w")
  if f3 then
    io.write(f3, "")
    io.close(f3)
  end

  w.flight_count = 0
  w.lifetime_count = 0
  w.log_entries = {}
  w.chart_data = {}
  w.fleet_data = nil
  w.log_loaded = false
end

local function getLogFilePath(w)
  local modelName = (model.getInfo() or {}).name or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  local batIdx = getActiveBatIndex(w)
  if batIdx > 0 then
    return basePath .. "/log_" .. cleanName .. "_BAT" .. batIdx .. ".txt"
  end
  return basePath .. "/log_" .. cleanName .. ".txt"
end

local function loadFlightLog(w)
  local path = getLogFilePath(w)
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
  local path = getLogFilePath(w)
  local f = io.open(path, "w")
  if f then
    io.write(f, w.last_date .. "," .. tostring(w.flight_count or 0) .. "," .. tostring(w.lifetime_count or 0))
    io.close(f)
  end
end

local function getLogbookPath(w)
  local modelName = (model.getInfo() or {}).name or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  local batIdx = getActiveBatIndex(w)
  if batIdx > 0 then
    return basePath .. "/logbook_" .. cleanName .. "_BAT" .. batIdx .. ".txt"
  end
  return basePath .. "/logbook_" .. cleanName .. ".txt"
end

local function getChartPath(w)
  local modelName = (model.getInfo() or {}).name or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  local batIdx = getActiveBatIndex(w)
  if batIdx > 0 then
    return basePath .. "/chart_" .. cleanName .. "_BAT" .. batIdx .. ".txt"
  end
  return basePath .. "/chart_" .. cleanName .. ".txt"
end

local function loadChartData(w)
  w.chart_data = {}
  local path = getChartPath(w)
  local f = io.open(path, "r")
  if f then
    local content = io.read(f, 6144) or ""
    io.close(f)
    for line in string.gmatch(content, "[^\r\n]+") do
      if string.len(line) > 5 then
        local parts = {}
        for p in string.gmatch(line, "[^,]+") do
          table.insert(parts, tonumber(p) or 0)
        end
        if #parts >= 5 then
          table.insert(w.chart_data, { r = parts[1], v = parts[2], a = parts[3], b = parts[4], t = parts[5] })
        end
      end
    end
  end
end

local function saveChartData(w)
  if not w.chart_data or #w.chart_data < 2 then return end
  local path = getChartPath(w)
  local f = io.open(path, "w")
  if f then
    for i = 1, #w.chart_data do
      local p = w.chart_data[i]
      if type(p) == "table" then
        local r = p.r or (p[1] or 0)
        local v = p.v or (p[2] or 0)
        local a = p.a or (p[3] or 0)
        local b = p.b or (p[4] or 0)
        local t = p.t or (p[5] or 0)
        io.write(f, string.format("%.0f,%.2f,%.1f,%.2f,%.0f\n", r, v, a, b, t))
      end
    end
    io.close(f)
  end
end

local function loadLogbook(w)
  w.log_entries = {}
  local path = getLogbookPath(w)
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
  if not w.chart_data or #w.chart_data == 0 then
    loadChartData(w)
  end
end

local function saveLogbook(w)
  local path = getLogbookPath(w)
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
  local timer_opt = tonumber(getOption(w, "Timer")) or 1
  local n = math.max(0, math.min(2, math.floor(timer_opt) - 1))
  local t = model.getTimer(n)
  local s = t and t.value or 0
  local sign = s < 0 and "-" or ""
  s = math.abs(s)
  return string.format("%s%02d:%02d", sign, math.floor(s / 60), s % 60), s < 0 and C.red or C.white
end

local function bankText(w)
  local source = getOption(w, "Bank Src") or getOption(w, "BankSwitch")
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

  -- Fallback logic when NO physical switch source is designated (Auto mode):
  -- Prioritize Rotorflight PID Profile sensor ("PID#", "PID", "Pid#", "Bank") over "FM" (Flight Mode)
  local bank_sensors = { "PID#", "PID", "Pid#", "Bank", "FM" }
  local fm = nil
  for i = 1, #bank_sensors do
    local name = bank_sensors[i]
    if getFieldInfo then
      local info = getFieldInfo(name)
      if info then
        fm = getValue(info.id)
        if type(fm) == "number" and fm > 0 then break end
      end
    end
    fm = getValue(name)
    if type(fm) == "number" and fm > 0 then break end
  end

  if type(fm) == "number" and fm > 0 then
    local b = math.floor(fm)
    if b == 0 then b = 1 end
    return string.format("BANK %d", math.max(1, math.min(6, b)))
  end

  -- Unpowered / No telemetry signal & no physical switch designated
  return "BANK --"
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

local function refresh(w, event, touchState)
  local arm_on = false
  local arm_src = getOption(w, "Arm Source")
  if arm_src and arm_src ~= 0 then
    local arm_val = getValue(arm_src)
    if type(arm_val) == "boolean" then 
      arm_on = arm_val
    elseif type(arm_val) == "number" then 
      arm_on = arm_val > 0 
    end
    local arm_inv = getOption(w, "Arm Invert")
    if arm_inv == 1 or arm_inv == true then
      arm_on = not arm_on
    end
  else
    arm_on = sensor(13) > 0 -- Fallback to telemetry sensor
  end

  applyDynamicTheme(w, arm_on)
  background(w); loadModelImage()
  local z = w.zone
  local x, y, sw, sh = math.floor(z.x), math.floor(z.y), math.floor(z.w), math.floor(z.h)
  -- This layout is designed for the TX16S MK3's 800 x 480 full-screen zone.
  local sx, sy = sw / 800, sh / 480
  local function X(v) return x + math.floor(v * sx) end
  local function Y(v) return y + math.floor(v * sy) end
  local function W(v) return math.floor(v * sx) end
  local function H(v) return math.floor(v * sy) end
  local theme_opt = getOption(w, "Theme")
  local t_val = parseThemeIndex(theme_opt)
  local is_trn = (t_val == 9)
  local transp_opt = getOption(w, "Transp BG")
  local is_transp = (transp_opt == 1 or transp_opt == true)
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
    if t_type == 1 then
      w.is_touching = true
    elseif t_type == 2 or t_type == 3 then
      if w.is_touching then
        is_tap = true
        w.is_touching = false
      end
    else
      w.is_touching = false
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

  local logSw = getOption(w, "Logbook Sw")
  if logSw and logSw ~= 0 then
    local l_val = getValue(logSw)
    if type(l_val) == "boolean" then
      w.show_logbook = l_val
      w.logbook_tab = 1
    elseif type(l_val) == "number" then
      -- 3-position switch: DOWN (>= 50) -> Tab 2, MID (-50 < v < 50) -> Tab 1, UP (<= -50) -> Close
      if l_val >= 50 or l_val == 2 then
        w.show_logbook = true
        w.logbook_tab = 2 -- Tab 2: Battery Fleet Manager
      elseif (l_val > -50 and l_val < 50) or l_val == 1 then
        w.show_logbook = true
        w.logbook_tab = 1 -- Tab 1: Logbook Line Chart
      else
        w.show_logbook = false -- UP (SC-up / Off)
      end
    end
  end

  local arm_on = false
  local armSrc = getOption(w, "Arm Source")
  if armSrc and armSrc ~= 0 then
    local arm_val = getValue(armSrc)
    if type(arm_val) == "boolean" then 
      arm_on = arm_val
    elseif type(arm_val) == "number" then 
      arm_on = arm_val > 0 
    end
    local armInv = getOption(w, "Arm Invert")
    if armInv == 1 or armInv == true then
      arm_on = not arm_on
    end
  else
    arm_on = sensor(13) > 0 -- Fallback to telemetry sensor
  end

  if not w.log_loaded then
    loadFlightLog(w)
    loadLogbook(w)
    loadChartData(w)
    w.log_loaded = true
  end

  -- Detect Battery Track switch change
  local currentBatIdx = getActiveBatIndex(w)
  if w.last_bat_idx ~= currentBatIdx then
    w.last_bat_idx = currentBatIdx
    w.log_loaded = false -- Force reload next frame
  end

  -- Handle dynamic themes（暫時完全禁用，避免衝突）
  -- local theme_mod = loadModule("theme")
  -- if theme_mod then
  --   local ctx = { C=C, lcd=lcd }
  --   theme_mod.update(w, ctx)
  --   if w.force_solid_bg then
  --     is_transp = false
  --     is_trn = false
  --   end
  -- end
  
  -- 如果是 HiVis 或 F-35 主題，強制設置 solid bg
  local curTheme = getOption(w, "Theme")
  if curTheme == 11 or curTheme == 12 then
    is_transp = false
    is_trn = false
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
        w.chart_reset_this_arm = false
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

      -- Check spool-up trigger: RPM > 500 or Current > 1.5A
      local cur_rpm = stat(3, "cur") or 0
      local cur_curr = amps(sensor(2)) or 0
      if (cur_rpm > 500 or cur_curr > 1.5) and not w.chart_reset_this_arm then
        w.chart_data = {} -- Clear old chart once motor actually spools up
        w.is_demo_data = false
        w.chart_reset_this_arm = true
      end
      
      -- Sample chart data every 3 seconds (300 ticks) once spool-up has started
      if w.chart_reset_this_arm then
        if (getTime() - (w.last_sample_time or 0)) >= 300 then
          w.last_sample_time = getTime()
          if not w.chart_data then w.chart_data = {} end
          
          local rpm = stat(3, "cur") or 0
          local vbat = volts(sensor(1)) or 0
          local curr = amps(sensor(2)) or 0
          local bec = volts(sensor(12)) or 0
          local tmp = stat(6, "cur") or 0
          
          -- Voice Assistant integration
          local voice_opt = getOption(w, "Voice Alarm")
          if voice_opt == 1 or voice_opt == true then
            local voice_mod = loadModule("voice")
            if voice_mod then
              local ctx = {
                sensor = sensor,
                stat = stat,
                volts = volts,
                amps = amps,
                is_nitro = (getOption(w, "Heli Type") == 1),
                getOption = function(k) return getOption(w, k) end
              }
              voice_mod.update(w, ctx)
            end
          end
          
          table.insert(w.chart_data, { v = vbat, a = curr, r = rpm, b = bec, t = tmp })
          -- Ring Buffer (FIFO): keep only the last 200 points (approx 10 mins)
          if #w.chart_data > 200 then
             table.remove(w.chart_data, 1)
          end
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
      if w.chart_reset_this_arm and w.chart_data and #w.chart_data >= 2 then
        saveChartData(w)
      end
      w.arm_start_time = nil
      w.flight_counted_this_arm = false
      w.chart_reset_this_arm = false
    end
    w.last_arm_state = arm_on
  end

  local reset_on = false
  local r_opt = getOption(w, "Reset FlyCount")
  if r_opt and r_opt ~= 0 then
    local r_val = getValue(r_opt)
    if type(r_val) == "boolean" then
      reset_on = r_val
    elseif type(r_val) == "number" then
      reset_on = r_val > 0
    end
  end

  local bat_reset_on = false
  local bat_reset_src = getOption(w, "Reset Bat Log")
  if bat_reset_src and bat_reset_src ~= 0 then
    local br_val = getValue(bat_reset_src)
    if type(br_val) == "boolean" then
      bat_reset_on = br_val
    elseif type(br_val) == "number" then
      bat_reset_on = br_val > 0
    end
  end

  if w.log_loaded then
    if bat_reset_on and not w.last_bat_reset_state then
      resetActiveBatLog(w)
    elseif reset_on and not w.last_reset_state then
      if w.show_logbook and w.logbook_tab == 2 then
        resetActiveBatLog(w)
      else
        w.flight_count = 0
        saveFlightLog(w)
      end
    end
    w.last_reset_state = reset_on
    w.last_bat_reset_state = bat_reset_on
  end

  if LED_STRIP_LENGTH and LED_STRIP_LENGTH > 0 and setRGBLedColor and applyRGBLedColors then
    local led_val = getOption(w, "DispLED")
    local enabled = (led_val == 1 or led_val == true or led_val == "1")
    local color_opt = getOption(w, "LED Color")
    local color_idx = parseLedColorIndex(color_opt)
    local is_rainbow = (color_idx == 9) or (color_opt == "Rainbow") or (color_opt == "彩虹")

    if enabled and is_rainbow then
      local t_ticks = getTime()
      if led_cache.enabled ~= enabled or led_cache.color ~= 99 or led_cache.ticks ~= t_ticks then
        led_cache.enabled, led_cache.color, led_cache.ticks = enabled, 99, t_ticks
        for i = 0, LED_STRIP_LENGTH - 1 do
          local hue = math.floor((i * 45 + t_ticks * 4) % 360)
          local r, g, b = hsvToRgb(hue, 1.0, 1.0)
          setRGBLedColor(i, r, g, b)
        end
        applyRGBLedColors()
      end
    else
      local color = math.max(1, math.min(#led_colors, color_idx))
      if led_cache.enabled ~= enabled or led_cache.color ~= color then
        led_cache.enabled, led_cache.color = enabled, color
        if enabled then
          local t = led_colors[color]
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
    local lctx = {
      x=x, y=y, sw=sw, sh=sh, sx=sx, sy=sy,
      X=X, Y=Y, W=W, H=H,
      is_trn=is_trn, is_transp=is_transp,
      f_mid=f_mid, f_sml=f_sml,
      lcd=lcd, C=C,
      modelName=(model.getInfo() or {}).name or "UNKNOWN"
    }
    local log_mod = loadModule("logbook")
    if log_mod and log_mod.drawLogbook then
      local ok, err = pcall(log_mod.drawLogbook, w, lctx)
      if not ok then
        lcd.drawFilledRectangle(x, y, sw, sh, C.red)
        lcd.drawText(x + 10, y + 10, "LOGBOOK CRASH:", 0)
        lcd.drawText(x + 10, y + 40, tostring(err), 0)
      end
    else
      lcd.drawFilledRectangle(x, y, sw, sh, C.red)
      lcd.drawText(x + 10, y + 10, "LOGBOOK MODULE LOAD FAILED", 0)
      lcd.drawText(x + 10, y + 40, tostring(w_last_mod_err), 0)
      lcd.drawText(x + 10, y + 70, "Base: " .. tostring(basePath), 0)
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
  if heli_pic then lcd.drawBitmap(heli_pic, X(25), Y(74), math.floor(sx * 125)) end
  text(80, 220, "Today: " .. (w.flight_count or 0), CENTER + f_sml, C.white)
  text(210, 220, "Total: " .. (w.lifetime_count or 0), CENTER + f_sml, C.dim)
  local gov_on = gov > 0
  
  if not is_trn then drawBgRect(X(20), Y(240), W(120), H(28), C.panel2, is_transp) end
  text(80, 245, "GOV", CENTER + f_sml, C.white)
  lcd.drawFilledRectangle(X(20), Y(268), W(120), H(42), gov_on and C.green or C.red)
  lcd.drawText(X(80), Y(274), gov_on and "ON" or "OFF", CENTER + f_mid + C.white)

  if not is_trn then drawBgRect(X(150), Y(240), W(120), H(28), C.panel2, is_transp) end
  text(210, 245, "STATUS", CENTER + f_sml, C.white)
  lcd.drawFilledRectangle(X(150), Y(268), W(120), H(42), arm_on and C.red or C.green)
  lcd.drawText(X(210), Y(274), arm_on and "ARMED" or "SAFE", CENTER + f_mid + C.white)

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
  local heli_type = getOption(w, "Heli Type")
  local is_nitro_mode = (heli_type == 1 or heli_type == 0 or heli_type == "Nitro" or heli_type == "燃油機 (Nitro)" or (type(heli_type) == "string" and string.find(string.lower(heli_type), "nitro") ~= nil))
  local is_turbine_mode = (heli_type == 3 or heli_type == "Turbine" or (type(heli_type) == "string" and string.find(string.lower(heli_type), "turbine") ~= nil))

  if is_turbine_mode then
    text(145, 390, "TURBINE JET", CENTER + f_sml, C.dim)
    text(145, 412, string.format("ECU BAT  %.1fV", vbec), CENTER + f_sml, C.dim)
  elseif is_nitro_mode then
    text(145, 390, "NITRO ENGINE", CENTER + f_sml, C.dim)
    text(145, 412, string.format("RX PACK  %.1fV", vbec), CENTER + f_sml, C.dim)
  else
    text(145, 390, string.format("BATTERY  %dS  %.1fV", cells, vbat), CENTER + f_sml, C.dim)
    text(145, 412, string.format("%.0f mAh used", capa), CENTER + f_sml, C.dim)
  end
  local bat_info_str = (w.last_bat_idx and w.last_bat_idx > 0) and (VERSION .. " | BAT " .. w.last_bat_idx) or VERSION
  text(145, 434, bat_info_str, CENTER + f_sml, C.dim)

  -- Right: Headspeed and ESC blocks.
  panel(X(295), Y(70), W(495), H(160), is_trn, is_transp)
  local tspd = sensor(17)
  local max_tspd = stat(17, "max")
  if not is_nitro_mode and not is_turbine_mode and (id[17] or tspd > 0 or max_tspd > 0) then
    text(318, 89, "HEAD / TAIL RPM", f_mid, C.white)
    text(320, 127, string.format("%.0f", hspd), f_xxl, C.white)
    text(765, 124, string.format("max  %.0f", stat(3, "max")), RIGHT + f_sml, C.white)
    text(765, 147, string.format("TAIL %.0f / MAX %.0f", tspd, max_tspd), RIGHT + f_sml, C.white)
  else
    text(318, 89, "HEADSPEED  RPM", f_mid, C.white)
    text(320, 127, string.format("%.0f", hspd), f_xxl, C.white)
    text(765, 124, string.format("max  %.0f", stat(3, "max")), RIGHT + f_sml, C.white)
    text(765, 147, string.format("min   %.0f", stat(3, "min")), RIGHT + f_sml, C.white)
  end
  -- Reuse the Tmcu field here so
  -- this dashboard can show useful FC data.
  text(765, 175, string.format("MCU TEMP  %.0f °C", sensor(7)), RIGHT + f_sml, C.white)

  -- Bottom Right Panel: Electric vs Nitro vs Turbine Mode
  if is_turbine_mode then
    -- Turbine Mode (Dynamic Module Loading)
    local turbine = loadModule("turbine")
    if turbine and turbine.draw then
      local ctx = { X=X, Y=Y, W=W, H=H, text=text, lcd=lcd, C=C, f_sml=f_sml, f_mid=f_mid, f_dbl=f_dbl, f_xxl=f_xxl, f_0=f_0, is_trn=is_trn, is_transp=is_transp, sensor=sensor, stat=stat, amps=amps, volts=volts, panel=panel, getOption=getOption, RIGHT=RIGHT, CENTER=CENTER }
      turbine.draw(w, ctx)
    else
      -- Fallback if module is missing
      panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)
      text(540, 310, "TURBINE MODULE MISSING", CENTER + f_mid, C.red)
    end
  elseif is_nitro_mode then
    -- Nitro Mode (Dynamic Module Loading)
    local nitro = loadModule("nitro")
    if nitro and nitro.draw then
      local ctx = { X=X, Y=Y, W=W, H=H, text=text, lcd=lcd, C=C, f_sml=f_sml, f_mid=f_mid, f_dbl=f_dbl, f_xxl=f_xxl, f_0=f_0, is_trn=is_trn, is_transp=is_transp, sensor=sensor, stat=stat, amps=amps, volts=volts, panel=panel, RIGHT=RIGHT, CENTER=CENTER }
      nitro.draw(w, ctx)
    else
      -- Fallback if module is missing
      panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)
      text(540, 310, "NITRO MODULE MISSING", CENTER + f_mid, C.red)
    end
  else
    -- Standard Electric Mode
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
  end

  panel(X(295), Y(420), W(124), H(50), is_trn, is_transp)
  text(357, 436, bankText(w), CENTER + f_0, C.white)

  if not telemetry then
    lcd.drawFilledRectangle(X(434), Y(420), W(356), H(50), C.red)
    lcd.drawText(X(612), Y(429), "NO DATA", CENTER + f_mid + C.white)
  else
    local user_name = getOption(w, "UserName") or ""
    if user_name ~= "" then
      text(612, 429, user_name, CENTER + f_mid, C.white)
    end
  end
end

local function background(w)
end

return { name = NAME, options = options, create = create, update = update, refresh = refresh, background = background }
