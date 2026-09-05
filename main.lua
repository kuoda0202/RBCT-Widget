-- RBCT helicopter dashboard for EdgeTX / TX16S MK3, MKII, TX15 MAX
-- Author: 雷恩 / Ryan Kuo
-- Model picture order: Rotorflight Craft Name (/modelImage or /IMAGES),
-- EdgeTX model name (/modelImage or /IMAGES), Model Setup bitmap, then default.png.
local NAME = "RBCT"
local VERSION = "v1.0.9"

-- Keep this list byte-for-byte compatible with standard telemetry. The order is
-- deliberately arranged to ensure standard telemetry setup works here.
local sensors = { "Vbat", "Curr", "Hspd", "Capa", "Bat%", "Tesc", "Tmcu", "1RSS", "2RSS", "RQly", "Thr", "Vbec", "ARM", "Gov", "Vcel", "FM", "Tspd" }
local id, mm = {}, {}
for i = 1, #sensors do
  mm[i] = { cur = 0, min = nil, max = nil }
end
local CRAFT_SENSOR_NAMES = { "Craft", "craft", "Name", "name", "Model", "model" }
local BANK_SENSOR_NAMES = { "PID#", "PID", "Pid#", "Bank", "FM" }
local cached_craft_id = nil
local cached_bank_id = nil
local heli_pic, loaded_model_key, heli_scale, heli_draw_x, heli_draw_y
local led_cache = { enabled = nil, color = nil }

local CENTER = rawget(_G, "CENTER") or rawget(_G, "CENTERED") or _G.CENTER or _G.CENTERED or 2
local RIGHT = rawget(_G, "RIGHT") or _G.RIGHT or 16

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

  if string.find(lang_str, "tw") or string.find(lang_str, "hk") then
    return "tw"
  end
  if string.find(lang_str, "cn") or string.find(lang_str, "zh") then
    return "cn"
  end
  if string.find(lang_str, "en") or string.find(lang_str, "us") or string.find(lang_str, "gb") then
    return "en"
  end
  if fstat then
    if fstat("/SOUNDS/tw") or fstat("/SOUNDS/hk") then return "tw" end
    if fstat("/SOUNDS/cn") or fstat("/SOUNDS/zh") then return "cn" end
  end
  return "en"
end

local lang = detectLanguage()
local is_tw = (lang == "tw")
local is_cn = (lang == "cn")
local is_zh = (is_tw or is_cn)

local options_tw = {
  { "UI 主題", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Black", "TRN", "Pink", "LCD", "F-type" } },
  { "背景 (BG)", BOOL, 0 },
  { "搖桿燈開關", BOOL, 0 },
  { "搖桿燈顏色", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Pink", "Rainbow" } },
  { "機型選擇", CHOICE, 1, { "電機 (Electric)", "油機 (Nitro)", "Turbine (Jet)" } },
  { "解鎖開關", SOURCE, 0 },
  { "解鎖圖示反向", BOOL, 0 },
  { "日誌開關", SOURCE, 0 },
  { "BANK 開關", SOURCE, 0 },
  { "光感主題開關", SOURCE, 0 },
  { "語音警示", BOOL, 0 },
  { "BEC 電壓警示", CHOICE, 5, { "5.0V", "5.5V", "6.0V", "6.4V", "6.6V", "7.0V", "7.4V", "8.0V" } },
  { "電變高溫警示", VALUE, 60, 40, 110 },
  { "油機高溫警示", VALUE, 120, 80, 160 },
  { "電量語音", BOOL, 0 },
  { "低電警報", VALUE, 30, 15, 50 },
  { "使用者名稱", STRING, "Pilot" },
  { "計時器選擇", VALUE, 1, 1, 3 },
  { "本日飛行清零", SOURCE, 0 },
  { "電池日誌", SOURCE, 0 },
  { "電池重置", SOURCE, 0 },
  { "UI 語言", CHOICE, 1, { "自動 (Auto)", "英文 (English)" } },
}

local options_cn = {
  { "UI 主题", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Black", "TRN", "Pink", "LCD", "F-type" } },
  { "背景 (BG)", BOOL, 0 },
  { "摇杆灯开关", BOOL, 0 },
  { "摇杆灯颜色", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Pink", "Rainbow" } },
  { "机型选择", CHOICE, 1, { "电机 (Electric)", "油机 (Nitro)", "Turbine (Jet)" } },
  { "解锁开关", SOURCE, 0 },
  { "解锁图标反向", BOOL, 0 },
  { "日志开关", SOURCE, 0 },
  { "BANK 开关", SOURCE, 0 },
  { "光感主题开关", SOURCE, 0 },
  { "语音警示", BOOL, 0 },
  { "BEC 电压警示", CHOICE, 5, { "5.0V", "5.5V", "6.0V", "6.4V", "6.6V", "7.0V", "7.4V", "8.0V" } },
  { "电调高温警示", VALUE, 60, 40, 110 },
  { "油机高温警示", VALUE, 120, 80, 160 },
  { "电量语音", BOOL, 0 },
  { "低电警报", VALUE, 30, 15, 50 },
  { "使用者名称", STRING, "Pilot" },
  { "计时器选择", VALUE, 1, 1, 3 },
  { "本日飞行清零", SOURCE, 0 },
  { "电池日志", SOURCE, 0 },
  { "电池重置", SOURCE, 0 },
  { "UI 语言", CHOICE, 1, { "自动 (Auto)", "英文 (English)" } },
}

local options_en = {
  { "Theme", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Black", "TRN", "Pink", "LCD", "F-type" } },
  { "Transp BG", BOOL, 0 },
  { "DispLED", BOOL, 0 },
  { "LED Color", CHOICE, 5, { "Red", "Orange", "Yellow", "Green", "Blue", "Cyan", "Violet", "Pink", "Rainbow" } },
  { "Heli Type", CHOICE, 1, { "Electric", "Nitro", "Turbine" } },
  { "Arm Source", SOURCE, 0 },
  { "Arm Icon Invert", BOOL, 0 },
  { "Logbook Sw", SOURCE, 0 },
  { "Bank Src", SOURCE, 0 },
  { "Light Theme Sw", SOURCE, 0 },
  { "Voice Alm", BOOL, 0 },
  { "BEC Volt Warn", CHOICE, 5, { "5.0V", "5.5V", "6.0V", "6.4V", "6.6V", "7.0V", "7.4V", "8.0V" } },
  { "ESC Temp Warn", VALUE, 60, 40, 110 },
  { "Nitro Temp Warn", VALUE, 120, 80, 160 },
  { "Bat% Voice", BOOL, 0 },
  { "Bat Low %", VALUE, 30, 15, 50 },
  { "UserName", STRING, "Pilot" },
  { "Timer", VALUE, 1, 1, 3 },
  { "Reset Flight Cnt", SOURCE, 0 },
  { "Bat Track", SOURCE, 0 },
  { "Rst BatLog", SOURCE, 0 },
  { "UI Lang", CHOICE, 1, { "Auto", "English" } },
}

local options = is_tw and options_tw or (is_cn and options_cn or options_en)

local option_aliases = {
  ["Theme"] = { "Theme", "UI 主題", "UI 主题", "UI主題", "UI主题", "面板主題", "面板主题" },
  ["Transp BG"] = { "Transp BG", "背景 (BG)", "背景(BG)", "無底色", "无底色", "BG 背景", "TranspBG" },
  ["DispLED"] = { "DispLED", "搖桿燈開關", "摇杆灯开关", "光圈開關", "光圈开关", "LED燈開關", "LED灯开关", "Disp LED" },
  ["LED Color"] = { "LED Color", "搖桿燈顏色", "摇杆灯颜色", "光圈顏色", "光圈颜色", "LED顏色", "LED颜色", "LEDColor" },
  ["UserName"] = { "UserName", "使用者名稱", "使用者名称", "使用者", "用户名", "用戶名", "User Name" },
  ["Timer"] = { "Timer", "計時器選擇", "计时器选择", "計時器", "计时器" },
  ["Arm Source"] = { "Arm Source", "解鎖開關", "解锁开关", "ArmSource" },
  ["Arm Invert"] = { "Arm Invert", "解鎖圖示反向", "解锁图标反向", "反向解鎖", "反向解锁", "ArmInvert", "Arm Icon Invert", "Invert Arm Icon" },
  ["Arm Icon Invert"] = { "Arm Icon Invert", "Arm Invert", "解鎖圖示反向", "解锁图标反向", "反向解鎖", "反向解锁", "ArmInvert", "Invert Arm Icon" },
  ["BankSwitch"] = { "BankSwitch", "Bank Src", "BANK 開關", "BANK 开关", "BANK開關", "BANK开关", "BANK 開關 (---為Auto)", "BANK 开关 (---为Auto)", "Bank Src (---=Auto)" },
  ["Bank Src"] = { "Bank Src", "BankSwitch", "BANK 開關", "BANK 开关", "BANK開關", "BANK开关", "BANK 開關 (---為Auto)", "BANK 开关 (---为Auto)", "Bank Src (---=Auto)" },
  ["Logbook Sw"] = { "Logbook Sw", "日誌開關", "日志开关", "LogbookSw" },
  ["Reset FlyCount"] = { "Reset FlyCount", "Reset Flight Cnt", "本日飛行清零", "本日飞行清零", "Rst FlyCnt", "飛行清零", "飞行清零", "清零" },
  ["Reset Flight Cnt"] = { "Reset Flight Cnt", "Reset FlyCount", "本日飛行清零", "本日飞行清零", "Rst FlyCnt", "飛行清零", "飞行清零", "清零" },
  ["Rst FlyCnt"] = { "Rst FlyCnt", "Reset Flight Cnt", "本日飛行清零", "本日飞行清零", "Reset FlyCount", "飛行清零", "飞行清零", "清零" },
  ["Heli Type"] = { "Heli Type", "機型選擇", "机型选择", "飛行模式", "飞行模式", "油電選擇", "油电选择", "HeliType" },
  ["Bat Track"] = { "Bat Track", "電池日誌", "电池日志", "電池編號", "电池编号", "電池記錄", "电池记录" },
  ["Reset Bat Log"] = { "Reset Bat Log", "Rst BatLog", "電池重置", "电池重置", "重置電池", "重置电池", "電池清零", "电池清零", "清空電池", "清空电池" },
  ["Rst BatLog"] = { "Rst BatLog", "Reset Bat Log", "電池重置", "电池重置", "重置電池", "重置电池", "電池清零", "电池清零", "清空電池", "清空电池" },
  ["Light Sens"] = { "Light Sens", "光感主題開關", "光感主题开关", "光感主題", "光感主题", "光感切換", "光感切换", "光感應LCD主題", "光感应LCD主题", "光感開關", "光感开关", "Auto LCD", "LightSens", "Light Theme Sw", "Light Sens Sw" },
  ["Light Theme Sw"] = { "Light Theme Sw", "Light Sens", "光感主題開關", "光感主题开关", "光感主題", "光感主题", "光感切換", "光感切换", "光感應LCD主題", "光感应LCD主题", "光感開關", "光感开关", "Auto LCD", "LightSens", "Light Sens Sw" },
  ["Voice Alarm"] = { "Voice Alarm", "Voice Alm", "語音警示", "语音警示", "語音警告", "语音警告", "VoiceAlarm", "語音", "语音" },
  ["Voice Alm"] = { "Voice Alm", "Voice Alarm", "語音警示", "语音警示", "語音警告", "语音警告", "VoiceAlarm", "語音", "语音" },
  ["BEC Warn V"] = { "BEC Warn V", "BEC 電壓警示", "BEC 电压警示", "BEC 警示", "BEC 門檻", "BEC 门槛", "BEC 警示門檻", "BEC 警示门槛", "BEC低壓門檻", "BEC低压门槛", "BEC Voltage Warn", "BEC Volt Warn" },
  ["BEC Volt Warn"] = { "BEC Volt Warn", "BEC Warn V", "BEC 電壓警示", "BEC 电压警示", "BEC 警示", "BEC 門檻", "BEC 门槛", "BEC 警示門檻", "BEC 警示门槛", "BEC低壓門檻", "BEC低压门槛", "BEC Voltage Warn" },
  ["ESC Temp Warn"] = { "ESC Temp Warn", "ESC T Warn", "電變高溫警示", "电调高温警示", "電變高溫", "电调高温", "電變高溫門檻", "电调高温门槛", "ESC TempWarn" },
  ["ESC T Warn"] = { "ESC T Warn", "ESC Temp Warn", "電變高溫警示", "电调高温警示", "電變高溫", "电调高温", "電變高溫門檻", "电调高温门槛", "ESC TempWarn" },
  ["Nitro Temp Warn"] = { "Nitro Temp Warn", "Nit T Warn", "油機高溫警示", "油机高温警示", "油機高溫", "油机高温", "油機高溫門檻", "油机高温门槛", "Nitro TempWarn" },
  ["Nit T Warn"] = { "Nit T Warn", "Nitro Temp Warn", "油機高溫警示", "油机高温警示", "油機高溫", "油机高温", "油機高溫門檻", "油机高温门槛", "Nitro TempWarn" },
  ["Bat% Voice"] = { "Bat% Voice", "電量語音", "电量语音", "Bat Voice", "電量語音播報", "电量语音播报" },
  ["Bat Low %"] = { "Bat Low %", "低電警報", "低电警报", "低電警示", "低电警示", "低電門檻", "低电门槛", "低電量警示", "低电量警示", "低電量警告", "低电量警告", "低電量門檻", "低电量门槛", "Bat Low" },
  ["Bat Crit %"] = { "Bat Crit %", "沒電警報", "没电警报", "沒電警示", "没电警示", "沒電門檻", "没电门槛", "臨界沒電門檻", "临界没电门槛", "Bat Crit" },
  ["UI Lang"] = { "UI Lang", "UI 語言", "UI 语言", "UI語言", "UI语言", "介面語言", "界面语言", "語言設定", "语言设置" },
}

local option_index_map = {
  ["Theme"] = 1, ["Transp BG"] = 2, ["DispLED"] = 3, ["LED Color"] = 4,
  ["Heli Type"] = 5, ["Arm Source"] = 6, ["Arm Invert"] = 7, ["Logbook Sw"] = 8,
  ["Bank Src"] = 9, ["Light Sens"] = 10, ["Voice Alarm"] = 11, ["BEC Warn V"] = 12,
  ["ESC Temp Warn"] = 13, ["Nitro Temp Warn"] = 14, ["Bat% Voice"] = 15,
  ["Bat Low %"] = 16, ["UserName"] = 17, ["Timer"] = 18, ["Reset FlyCount"] = 19,
  ["Bat Track"] = 20, ["Reset Bat Log"] = 21, ["UI Lang"] = 22
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
  local num_idx = option_index_map[key]
  if num_idx and w.options[num_idx] ~= nil then
    return w.options[num_idx]
  end
  return nil
end

-- =========================================================================
-- Module Loader & Dynamic Cache Engine
-- =========================================================================
local basePath = "/WIDGETS/RBCT"
local w_last_mod_err = ""

-- Module cache for preloaded modules
local modules = {}
local failed_modules = {}

local function loadModule(name)
  if modules[name] then return modules[name] end
  if failed_modules[name] then return nil end

  local paths = {
    basePath .. "/modules/" .. name .. ".lua",
    "/WIDGETS/RBCT/modules/" .. name .. ".lua",
    "WIDGETS/RBCT/modules/" .. name .. ".lua",
    basePath .. "/modules/" .. name
  }
  local f, err = nil, ""
  for i = 1, #paths do
    if loadScript then
      f, err = loadScript(paths[i])
      if f then break end
    end
  end
  if f then
    local ok, mod = pcall(f)
    if ok and mod then
      modules[name] = mod
      return mod
    else
      w_last_mod_err = "EXEC ERR: " .. tostring(mod)
      failed_modules[name] = true
    end
  else
    w_last_mod_err = "LOAD ERR: " .. tostring(err or "nil")
    failed_modules[name] = true
  end
  return nil
end

-- =========================================================================
-- UI Multi-Language Translation Bridge (modules/i18n.lua)
-- =========================================================================
local i18n_mod = nil
local function getI18n()
  if not i18n_mod then
    i18n_mod = loadModule("i18n")
    if i18n_mod and not i18n_mod._initialized then
      i18n_mod.init({
        detectLanguage = detectLanguage,
        getOption = getOption
      })
    end
  end
  return i18n_mod
end

local function getUiLang(w)
  local m = getI18n()
  if m and m.getUiLang then return m.getUiLang(w) end
  local opt = getOption(w, "UI Lang")
  if opt == 2 or opt == "English" or opt == "英文" then return "en" end
  return detectLanguage()
end

local function T(w, key)
  local m = getI18n()
  if m and m.T then return m.T(w, key) end
  return key
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

local theme_names_map = {
  ["red"] = 1, ["紅"] = 1,
  ["orange"] = 2, ["橙"] = 2,
  ["yellow"] = 3, ["黃"] = 3,
  ["green"] = 4, ["綠"] = 4,
  ["blue"] = 5, ["藍"] = 5,
  ["cyan"] = 6, ["水藍"] = 6,
  ["violet"] = 7,
  ["black"] = 8,
  ["trn"] = 9,
  ["pink"] = 10,
  ["lcd"] = 11,
  ["f-type"] = 12, ["ftype"] = 12,
  ["japan"] = 12 -- backward compatibility with previously saved text values
}

local function parseThemeIndex(val)
  if val == nil then return 5 end

  if type(val) == "string" then
    local s = string.lower(val)
    for k, idx in pairs(theme_names_map) do
      if string.find(s, k) then return idx end
    end
    local n = tonumber(val)
    if n then val = n end
  end

  if type(val) == "number" then
    local n = math.floor(val)
    if n >= 1 and n <= 12 then
      return n
    elseif n == 0 then
      return 1
    end
  end
  return 5
end

local function applyDynamicTheme(w, arm_on)
  local theme_opt = getOption(w, "Theme")
  local t_val = parseThemeIndex(theme_opt)
  local light_sens_src = getOption(w, "Light Sens")
  local is_light_sens_active = false
  if light_sens_src and light_sens_src ~= 0 then
    local s_val = getValue(light_sens_src)
    w._last_s_val = s_val
    if type(s_val) == "boolean" then
      is_light_sens_active = s_val
      w._light_active = s_val
    elseif type(s_val) == "number" then
      -- 支援 EdgeTX 所有開關模式與類比光感：
      -- 1. 開關輸出 0 / 1 / 2 (UP / MID / DOWN)
      -- 2. 開關輸出 -1024 / 0 / +1024
      -- 3. 類比光感應器 0 ~ 1024 (或 0 ~ 100%)
      local cur_state = w._light_active or false
      if s_val == 1 or s_val == 2 then
        cur_state = true
      elseif s_val > 10 then
        cur_state = true
      elseif s_val <= 4 then
        cur_state = false
      end
      w._light_active = cur_state
      is_light_sens_active = cur_state
    end
  else
    w._light_active = false
  end

  if is_light_sens_active then
    t_val = 11 -- Force LCD theme under strong ambient light or assigned switch
  end

  w.active_theme_idx = t_val

  if t_val == 1 then -- 1: Red (Ruby Crimson)
    C.bg = lcd.RGB(28, 6, 8)
    C.blue = lcd.RGB(255, 45, 65)
    C.panel = lcd.RGB(48, 12, 16)
    C.panel2 = lcd.RGB(68, 18, 24)
    C.white = lcd.RGB(255, 245, 245)
    C.dim = lcd.RGB(255, 140, 150)
  elseif t_val == 2 then -- 2: Orange
    C.bg = lcd.RGB(30, 16, 5)
    C.blue = lcd.RGB(255, 135, 0)
    C.panel = lcd.RGB(55, 30, 10)
    C.panel2 = lcd.RGB(75, 40, 15)
    C.white = lcd.RGB(255, 250, 245)
    C.dim = lcd.RGB(255, 180, 120)
  elseif t_val == 3 then -- 3: Yellow
    C.bg = lcd.RGB(28, 24, 5)
    C.blue = lcd.RGB(255, 205, 0)
    C.panel = lcd.RGB(52, 44, 10)
    C.panel2 = lcd.RGB(70, 60, 15)
    C.white = lcd.RGB(255, 255, 240)
    C.dim = lcd.RGB(255, 230, 140)
  elseif t_val == 4 then -- 4: Green (Emerald)
    C.bg = lcd.RGB(6, 26, 12)
    C.blue = lcd.RGB(40, 205, 90)
    C.panel = lcd.RGB(12, 50, 24)
    C.panel2 = lcd.RGB(18, 70, 34)
    C.white = lcd.RGB(240, 255, 245)
    C.dim = lcd.RGB(140, 240, 170)
  elseif t_val == 5 then -- 5: Blue (Default Cobalt)
    C.bg = lcd.RGB(7, 22, 72)
    C.blue = lcd.RGB(0, 126, 255)
    C.panel = lcd.RGB(15, 48, 122)
    C.panel2 = lcd.RGB(22, 61, 143)
    C.white = lcd.RGB(242, 247, 255)
    C.dim = lcd.RGB(147, 193, 255)
  elseif t_val == 6 then -- 6: Cyan (Water Blue)
    C.bg = lcd.RGB(5, 25, 32)
    C.blue = lcd.RGB(0, 220, 255)
    C.panel = lcd.RGB(10, 52, 65)
    C.panel2 = lcd.RGB(15, 72, 90)
    C.white = lcd.RGB(240, 255, 255)
    C.dim = lcd.RGB(130, 235, 255)
  elseif t_val == 7 then -- 7: Violet (Purple)
    C.bg = lcd.RGB(24, 8, 32)
    C.blue = lcd.RGB(175, 70, 235)
    C.panel = lcd.RGB(48, 18, 65)
    C.panel2 = lcd.RGB(68, 26, 90)
    C.white = lcd.RGB(255, 245, 255)
    C.dim = lcd.RGB(220, 160, 255)
  elseif t_val == 8 then -- 8: Black (Stealth OLED)
    C.bg = lcd.RGB(0, 0, 0)
    C.blue = lcd.RGB(80, 80, 80)
    C.panel = lcd.RGB(20, 20, 20)
    C.panel2 = lcd.RGB(35, 35, 35)
    C.white = lcd.RGB(240, 240, 240)
    C.dim = lcd.RGB(140, 140, 140)
  elseif t_val == 9 then -- 9: TRN (Transparent White Wireframe)
    C.bg = lcd.RGB(0, 0, 0)
    C.blue = lcd.RGB(255, 255, 255)
    C.panel = lcd.RGB(0, 0, 0)
    C.panel2 = lcd.RGB(0, 0, 0)
    C.white = lcd.RGB(255, 255, 255)
    C.dim = lcd.RGB(200, 200, 200)
  elseif t_val == 10 then -- 10: Pink (Magenta)
    C.bg = lcd.RGB(32, 10, 20)
    C.blue = lcd.RGB(255, 105, 180)
    C.panel = lcd.RGB(65, 20, 42)
    C.panel2 = lcd.RGB(90, 28, 58)
    C.white = lcd.RGB(255, 245, 250)
    C.dim = lcd.RGB(255, 175, 215)
  elseif t_val == 11 then -- 11: LCD (High-Contrast Daylight)
    C.bg = lcd.RGB(210, 218, 205)
    C.blue = lcd.RGB(20, 25, 20)
    C.panel = lcd.RGB(190, 200, 185)
    C.panel2 = lcd.RGB(175, 185, 170)
    C.white = lcd.RGB(10, 15, 10)
    C.dim = lcd.RGB(50, 60, 50)
  elseif t_val == 12 then -- 12: F-type (Slate Navy)
    C.bg = lcd.RGB(35, 45, 58)
    C.blue = lcd.RGB(50, 185, 245)
    C.panel = lcd.RGB(48, 62, 78)
    C.panel2 = lcd.RGB(72, 98, 128)
    C.white = lcd.RGB(235, 245, 255)
    C.dim = lcd.RGB(145, 170, 195)
  else
    C.bg = lcd.RGB(7, 22, 72)
    C.blue = lcd.RGB(0, 126, 255)
    C.panel = lcd.RGB(15, 48, 122)
    C.panel2 = lcd.RGB(22, 61, 143)
    C.white = lcd.RGB(242, 247, 255)
    C.dim = lcd.RGB(147, 193, 255)
  end

  C.red = lcd.RGB(255, 60, 60)
  C.green = lcd.RGB(0, 230, 80)
  C.black = lcd.RGB(0, 0, 0)
  C.orange = lcd.RGB(255, 135, 0)
  C.yellow = lcd.RGB(255, 205, 0)
  C.cyan = lcd.RGB(0, 220, 255)

  return t_val
end

local led_colors = {
  { 255,   0,   0 }, -- 1: Red
  { 255, 128,   0 }, -- 2: Orange
  { 255, 255,   0 }, -- 3: Yellow
  {   0, 255,   0 }, -- 4: Green
  {   0,   0, 255 }, -- 5: Blue
  {   0, 255, 255 }, -- 6: Cyan
  { 128,   0, 255 }, -- 7: Violet
  { 255,   0, 128 }, -- 8: Pink
}

local function parseLedColorIndex(val)
  if type(val) == "number" then
    local n = math.floor(val)
    if n >= 1 and n <= 9 then return n end
    return 5
  elseif type(val) == "string" then
    local s = string.lower(val)
    if string.find(s, "red") or string.find(s, "紅") then return 1
    elseif string.find(s, "orange") or string.find(s, "橙") then return 2
    elseif string.find(s, "yellow") or string.find(s, "黃") then return 3
    elseif string.find(s, "green") or string.find(s, "綠") then return 4
    elseif string.find(s, "blue") or string.find(s, "藍") then return 5
    elseif string.find(s, "cyan") or string.find(s, "水藍") then return 6
    elseif string.find(s, "violet") then return 7
    elseif string.find(s, "pink") then return 8
    elseif string.find(s, "rainbow") then return 9
    end
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
  else r, g, b = c, 0, x end
  return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

local function parseHeliType(val)
  if type(val) == "number" then
    local n = math.floor(val)
    if n >= 1 and n <= 3 then return n end
    return 1
  elseif type(val) == "string" then
    local s = string.lower(val)
    if string.find(s, "nitro") or string.find(s, "油") then return 2
    elseif string.find(s, "turbine") or string.find(s, "jet") then return 3
    else return 1 end
  end
  return 1
end

local function getCraftName()
  local craft = ""
  if cached_craft_id and getValue then
    local v = getValue(cached_craft_id)
    if type(v) == "string" and string.len(v) > 0 and v ~= "---" then
      return v
    end
  end

  if getFieldInfo then
    for i = 1, #CRAFT_SENSOR_NAMES do
      local info = getFieldInfo(CRAFT_SENSOR_NAMES[i])
      if info and info.id then
        local v = getValue(info.id)
        if type(v) == "string" and string.len(v) > 0 and v ~= "---" then
          cached_craft_id = info.id
          craft = v
          break
        end
      end
    end
  end

  if craft == "" then
    if _G.rf2 and type(_G.rf2.craftName) == "string" and _G.rf2.craftName ~= "" then
      craft = _G.rf2.craftName
    elseif _G.RF2 and type(_G.RF2.craftName) == "string" and _G.RF2.craftName ~= "" then
      craft = _G.RF2.craftName
    elseif _G.rf2bg and type(_G.rf2bg.craftName) == "string" and _G.rf2bg.craftName ~= "" then
      craft = _G.rf2bg.craftName
    elseif _G.MSP and type(_G.MSP.craftName) == "string" and _G.MSP.craftName ~= "" then
      craft = _G.MSP.craftName
    elseif _G.msp and type(_G.msp.craftName) == "string" and _G.msp.craftName ~= "" then
      craft = _G.msp.craftName
    elseif _G.DBK and type(_G.DBK.craftName) == "string" and _G.DBK.craftName ~= "" then
      craft = _G.DBK.craftName
    end
  end

  if craft == "" and model and model.getInfo then
    local info = model.getInfo()
    if info and info.name and info.name ~= "" then
      craft = info.name
    end
  end

  return craft
end

local function resolveModelImagePath()
  local craft = getCraftName()
  local candidates = {}
  if craft ~= "" then
    table.insert(candidates, "/modelImage/" .. craft .. ".png")
    table.insert(candidates, "/IMAGES/" .. craft .. ".png")
  end
  if model and model.getInfo then
    local info = model.getInfo()
    if info and info.name and info.name ~= "" then
      table.insert(candidates, "/modelImage/" .. info.name .. ".png")
      table.insert(candidates, "/IMAGES/" .. info.name .. ".png")
    end
    if info and info.bitmap and info.bitmap ~= "" then
      table.insert(candidates, info.bitmap)
      table.insert(candidates, "/IMAGES/" .. info.bitmap)
    end
  end
  table.insert(candidates, basePath .. "/Pic/default.png")
  table.insert(candidates, basePath .. "/default.png")

  for i = 1, #candidates do
    local p = candidates[i]
    if fstat and fstat(p) then return p end
  end
  return nil
end

local function loadModelImage(sx, sy, viewport_w, viewport_h, logical_max_w, logical_max_h)
  sx = (sx and sx > 0) and sx or 1
  sy = (sy and sy > 0) and sy or 1
  logical_max_w = logical_max_w or 240
  logical_max_h = logical_max_h or 140
  local craft = getCraftName()
  local info = (model and model.getInfo) and model.getInfo() or nil
  local model_name = info and info.name or ""
  local bitmap_name = info and info.bitmap or ""
  local key = craft .. "|" .. model_name .. "|" .. bitmap_name .. "|" ..
    tostring(viewport_w or 800) .. "x" .. tostring(viewport_h or 480) .. "|" ..
    tostring(logical_max_w) .. "x" .. tostring(logical_max_h)

  if loaded_model_key == key and heli_pic ~= nil then return end

  heli_pic = nil
  loaded_model_key = key
  heli_scale = 100
  heli_draw_x = 25
  heli_draw_y = 74

  local target_path = resolveModelImagePath()
  local bitmap_open_api = nil
  if Bitmap and Bitmap.open then bitmap_open_api = Bitmap
  elseif bitmap and bitmap.open then bitmap_open_api = bitmap end
  if target_path and bitmap_open_api then
    local ok, img = pcall(bitmap_open_api.open, target_path)
    if ok and img then
      heli_pic = img
      local bitmap_size_api = nil
      if Bitmap and Bitmap.getSize then bitmap_size_api = Bitmap
      elseif bitmap and bitmap.getSize then bitmap_size_api = bitmap end
      if bitmap_size_api then
        local w, h = bitmap_size_api.getSize(img)
        if w and h and w > 0 and h > 0 then
          -- Bitmap pixels are not transformed by the dashboard's X/Y helpers.
          -- Convert the logical 800x480 image bounds to physical pixels first,
          -- which keeps TX15-class 480x320 screens inside the same model card.
          local max_w = math.max(1, math.floor(logical_max_w * sx))
          local max_h = math.max(1, math.floor(logical_max_h * sy))
          local scale_w = (max_w / w) * 100
          local scale_h = (max_h / h) * 100
          heli_scale = math.min(100, math.floor(math.min(scale_w, scale_h)))
          local final_w = math.floor(w * (heli_scale / 100))
          local final_h = math.floor(h * (heli_scale / 100))
          -- Resize once at load time for faster repeated drawing and exact
          -- physical dimensions on every supported RadioMaster display.
          local bitmap_api = nil
          if Bitmap and Bitmap.resize then
            bitmap_api = Bitmap
          elseif bitmap and bitmap.resize then
            bitmap_api = bitmap
          end
          if heli_scale < 100 and bitmap_api and bitmap_api.resize then
            local resized_ok, resized = pcall(bitmap_api.resize, img, final_w, final_h)
            if resized_ok and resized then
              heli_pic = resized
              heli_scale = 100
            end
          end
          local final_logical_w = final_w / sx
          local final_logical_h = final_h / sy
          heli_draw_x = 10 + math.floor((270 - final_logical_w) / 2)
          heli_draw_y = 70 + math.floor((145 - final_logical_h) / 2)
        end
      end
    end
  end
end

local function getStorage()
  local sm = loadModule("storage")
  if sm and not sm._initialized then
    sm.init({
      basePath = basePath,
      getCraftName = getCraftName,
      getOption = getOption,
      loadModule = loadModule
    })
  end
  return sm
end

local function sanitizeFilename(name)
  local sm = getStorage()
  if sm and sm.sanitizeFilename then return sm.sanitizeFilename(name) end
  if not name or name == "" then return "default" end
  local clean = string.gsub(name, "[^%w%-_]", "_")
  return string.sub(clean, 1, 24)
end

local function getActiveBatIndex(w)
  local sm = getStorage()
  if sm and sm.getActiveBatIndex then return sm.getActiveBatIndex(w) end
  return 0
end

local function getLogFilePath(w)
  local sm = getStorage()
  if sm and sm.getLogFilePath then return sm.getLogFilePath(w) end
  return basePath .. "/log_" .. sanitizeFilename(getCraftName()) .. ".txt"
end

local function getLogbookFilePath(w)
  local sm = getStorage()
  if sm and sm.getLogbookFilePath then return sm.getLogbookFilePath(w) end
  return basePath .. "/logbook_" .. sanitizeFilename(getCraftName()) .. ".txt"
end

local function getFleetFilePath(w)
  local sm = getStorage()
  if sm and sm.getFleetFilePath then return sm.getFleetFilePath(w) end
  return basePath .. "/fleet_" .. sanitizeFilename(getCraftName()) .. ".txt"
end

local function getChartFilePath(w)
  local sm = getStorage()
  if sm and sm.getChartFilePath then return sm.getChartFilePath(w) end
  return basePath .. "/chart_" .. sanitizeFilename(getCraftName()) .. ".txt"
end

local function loadFleetData(w)
  local sm = getStorage()
  if sm and sm.loadFleetData then sm.loadFleetData(w) end
end

local function saveFleetData(w)
  local sm = getStorage()
  if sm and sm.saveFleetData then sm.saveFleetData(w) end
end

local function updateBatteryStatusOnVoltage(w, bat_idx, vcel, vbat)
  local sm = getStorage()
  if sm and sm.updateBatteryStatusOnVoltage then sm.updateBatteryStatusOnVoltage(w, bat_idx, vcel, vbat) end
end

local function loadFlightLog(w)
  local sm = getStorage()
  if sm and sm.loadFlightLog then sm.loadFlightLog(w) end
end

local function saveFlightLog(w)
  local sm = getStorage()
  if sm and sm.saveFlightLog then sm.saveFlightLog(w) end
end

local function loadLogbook(w)
  local sm = getStorage()
  if sm and sm.loadLogbook then sm.loadLogbook(w) end
end

local function saveLogbook(w)
  local sm = getStorage()
  if sm and sm.saveLogbook then sm.saveLogbook(w) end
end

local function loadChartData(w, target_idx)
  local sm = getStorage()
  if sm and sm.loadChartData then sm.loadChartData(w, target_idx) end
end

local function saveChartData(w)
  local sm = getStorage()
  if sm and sm.saveChartData then sm.saveChartData(w) end
end

local function resetActiveBatLog(w)
  local sm = getStorage()
  if sm and sm.resetActiveBatLog then sm.resetActiveBatLog(w) end
end

local function sensor(i)
  if not id[i] then return 0 end
  local v = getValue(id[i])
  if type(v) == "table" then
    return tonumber(v.value) or 0
  end
  return tonumber(v) or 0
end

local function stat(i, k)
  if not mm[i] then return 0 end
  return mm[i][k] or mm[i].cur or 0
end

local function resetMinMax()
  for i = 1, #sensors do
    mm[i] = { cur = 0, min = nil, max = nil }
  end
end

local function updateSensors()
  for i = 1, #sensors do
    if not id[i] then
      local sensor_aliases = {
        [1] = { "Vbat", "Cels", "RxBt", "A1", "A2", "Volt", "VFAS", "BAT", "BatV" },
        [2] = { "Curr", "Curr+", "Current", "Amps", "A" },
        [3] = { "Hspd", "HSpd", "HSPD", "RPM", "Rpm", "ERPM", "Head" },
        [4] = { "Capa", "Capacity", "Cap", "Mah", "mAh", "Used", "Fuel" },
        [5] = { "Bat%", "Bat", "Batt", "Fuel", "Pct" },
        [6] = { "Tesc", "EscT", "Tmp1", "Temp", "TMP1", "ESC", "EscTemp", "TEM1" },
        [7] = { "Tmcu", "McuT", "Tmp2", "TMP2", "FC", "FcTemp", "TEM2" },
        [8] = { "1RSS", "RSSI", "1Rsi", "RSS1", "Rsi1" },
        [9] = { "2RSS", "2Rsi", "RSS2", "Rsi2" },
        [10]= { "RQly", "RQly+", "QLY", "Qly", "RSNR", "SNR", "TQly" },
        [11]= { "Thr", "Throt", "Throttle", "THR", "Thrp" },
        [12]= { "Vbec", "BecV", "BEC", "Bec", "BECV", "RxBt", "5V", "A2" },
        [13]= { "ARM", "Arm", "Armed", "Armd", "ST-ARM" },
        [14]= { "Gov", "GOV", "Governor", "GovState" },
        [15]= { "Vcel", "CelV", "Cell", "Cmin", "MinCell", "VCell" },
        [16]= { "FM", "FlightMode", "Mode", "MODE" },
        [17]= { "Tspd", "TSpd", "TSPD", "TRPM", "TailRPM", "Tail" },
      }
      local names = sensor_aliases[i] or { sensors[i] }
      for j = 1, #names do
        local field = getFieldInfo(names[j])
        if field then id[i] = field.id; break end
      end
    end
  end

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
      if not mm[i] then
        mm[i] = { cur = 0, min = nil, max = nil }
      end
      mm[i].cur = v
      if v ~= 0 then
        mm[i].min = mm[i].min and math.min(mm[i].min, v) or v
      end
      mm[i].max = mm[i].max and math.max(mm[i].max, v) or v
    end
  end
end

local function volts(v)
  if v > 100 then return v / 100 end
  return v
end

local function amps(v)
  if v > 2000 then return v / 100 end
  return v
end

local function timerText(w)
  local timer_opt = tonumber(getOption(w, "Timer")) or 1
  local n = math.max(0, math.min(2, math.floor(timer_opt) - 1))
  local t = (model and model.getTimer) and model.getTimer(n) or nil
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
      local bank = 2
      if value < -300 then bank = 1
      elseif value > 300 then bank = 3 end
      return string.format("BANK %d", bank)
    end
  end

  local fm = nil
  if cached_bank_id and getValue then
    local v = getValue(cached_bank_id)
    if (type(v) == "number" and v >= 0) or (type(v) == "string" and tonumber(v) ~= nil) then
      fm = v
    end
  end

  if fm == nil and getFieldInfo then
    for i = 1, #BANK_SENSOR_NAMES do
      local name = BANK_SENSOR_NAMES[i]
      local info = getFieldInfo(name)
      if info and info.id then
        local v = getValue(info.id)
        if (type(v) == "number" and v >= 0) or (type(v) == "string" and tonumber(v) ~= nil) then
          cached_bank_id = info.id
          fm = v
          break
        end
      end
      local v = getValue(name)
      if (type(v) == "number" and v >= 0) or (type(v) == "string" and tonumber(v) ~= nil) then
        fm = v
        break
      end
    end
  end

  local val = tonumber(fm)
  if val ~= nil then
    local b = math.floor(val)
    if b == 0 then b = 1 end
    return string.format("BANK %d", math.max(1, math.min(6, b)))
  end

  if _G.rf2 and _G.rf2.profile then
    local b = tonumber(_G.rf2.profile)
    if b and b > 0 then return string.format("BANK %d", b) end
  end

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

local function drawHeliBitmap(px, py, bmp, scale_pct)
  if not bmp then return end
  if lcd.drawBitmap then
    -- Official EdgeTX order is bitmap, x, y, scale.
    local ok = pcall(lcd.drawBitmap, bmp, px, py, scale_pct or 100)
    if not ok then
      pcall(lcd.drawBitmap, px, py, bmp, scale_pct or 100)
    end
  elseif lcd.drawImage then
    pcall(lcd.drawImage, px, py, bmp)
  end
end

-- =========================================================================
-- High-Performance Dashboard Renderer (TX16S MK3 / MKII / TX15 MAX)
-- =========================================================================
local function drawDashboard(w, data, ctx)
  local theme_opt = getOption(w, "Theme")
  local t_val = w.active_theme_idx or parseThemeIndex(theme_opt)
  if t_val == 12 then
    local ftype_mod = loadModule("layout_F-type")
    if ftype_mod and ftype_mod.draw then
      local ok, err = pcall(ftype_mod.draw, w, data, ctx)
      if ok then return end
      lcd.drawFilledRectangle(ctx.x, ctx.y, ctx.sw, ctx.sh, ctx.C.bg)
      lcd.drawText(ctx.X(400), ctx.Y(80), "F-TYPE RENDER CRASH", ctx.CENTER + ctx.f_mid + ctx.C.red)
      lcd.drawText(ctx.X(400), ctx.Y(140), tostring(err), ctx.CENTER + ctx.f_sml + ctx.C.white)
      return
    else
      lcd.drawFilledRectangle(ctx.x, ctx.y, ctx.sw, ctx.sh, ctx.C.bg)
      lcd.drawText(ctx.X(400), ctx.Y(80), "F-TYPE MODULE LOAD FAILED", ctx.CENTER + ctx.f_mid + ctx.C.red)
      lcd.drawText(ctx.X(400), ctx.Y(140), tostring(w_last_mod_err), ctx.CENTER + ctx.f_sml + ctx.C.white)
      return
    end
  end

  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H
  local x, y, sw, sh = ctx.x, ctx.y, ctx.sw, ctx.sh
  local f_xxl, f_dbl, f_mid, f_sml, f_0 = ctx.f_xxl, ctx.f_dbl, ctx.f_mid, ctx.f_sml, ctx.f_0
  local is_trn, is_transp = ctx.is_trn, ctx.is_transp
  local now_t = getTime()

  local function text(px, py, str, flags, color)
    if (is_trn or is_transp) and color ~= C.black then
      lcd.drawText(X(px) + 1, Y(py) + 1, str, flags + C.black)
    end
    lcd.drawText(X(px), Y(py), str, flags + color)
  end

  -- Draw text whose position is already expressed in physical screen pixels.
  -- This is required when positioning separate mixed-size strings using the
  -- physical widths returned by lcd.sizeText().
  local function textPhysical(px, py, str, flags, color)
    if (is_trn or is_transp) and color ~= C.black then
      lcd.drawText(px + 1, py + 1, str, flags + C.black)
    end
    lcd.drawText(px, py, str, flags + color)
  end

  -- 1. Full Screen Background & Outer Border
  if not is_transp and not is_trn then
    drawBgRect(x, y, sw, sh, C.bg, false)
  end
  if not is_trn then
    lcd.drawRectangle(x, y, sw, sh, C.blue)
  end

  -- 2. Header Bar (Model Name, Timer, TX Volt, Clock, Header Line)
  local is_banner = (w.bat_prompt_timer > 0) and (now_t - w.bat_prompt_timer < 1000) and (not data.arm_on)
  if is_banner then
    local BANNER_DUR = 1000
    local elapsed = now_t - w.bat_prompt_timer
    local batStr = (w.last_bat_idx > 0) and ("BAT " .. w.last_bat_idx) or (is_tw and "預設電池" or (is_cn and "默认电池" or "Default BAT"))
    if w.last_bat_idx > 0 and w.fleet_stats and w.fleet_stats[w.last_bat_idx] then
      local st = w.fleet_stats[w.last_bat_idx]
      batStr = string.format("BAT %d (%d/%dc)", w.last_bat_idx, st.today_count or 0, st.lifetime_cycles or 0)
    end
    local promptTxt = is_tw and ("電池已連線: 將記錄於 " .. batStr .. " (不是請按開關 1~6 切換)") or (is_cn and ("电池已连接: 将记录于 " .. batStr .. " (不是请按开关 1~6 切换)") or ("BATTERY CONNECTED: Logging to " .. batStr .. " (Switch 1~6)"))
    if sw < 600 then
      local batShort = (w.last_bat_idx > 0) and ("BAT " .. w.last_bat_idx) or (is_tw and "預設電池" or (is_cn and "默认电池" or "DEFAULT BAT"))
      promptTxt = is_tw and ("電池連線: " .. batShort) or (is_cn and ("电池连接: " .. batShort) or ("BAT CONNECTED: " .. batShort))
    end
    local p_w = math.floor(W(636) * (1 - (elapsed / BANNER_DUR)))
    lcd.drawFilledRectangle(X(80), Y(6), W(640), H(38), C.yellow)
    lcd.drawRectangle(X(80), Y(6), W(640), H(38), C.black, 2)
    if p_w > 0 then lcd.drawFilledRectangle(X(82), Y(40), p_w, H(4), C.red) end
    lcd.drawText(X(400), Y(14), promptTxt, CENTER + f_sml + C.black)
  else
    local m_name = data.modelName ~= "" and data.modelName or "MODEL01"
    text(14, 12, m_name, f_mid, C.white)
    text(400, 6, data.timer, CENTER + f_dbl, data.timerColor)

    -- Transmitter Battery Gauge (Enlarged Capsule with Center Voltage)
    local tx_v = data.txVoltage or 0
    local tx_min, tx_max = 6.0, 8.4
    if tx_v > 0 and tx_v < 5.0 then tx_min, tx_max = 3.0, 4.2 end
    local tx_pct = math.max(0, math.min(100, math.floor(((tx_v - tx_min) / math.max(0.1, tx_max - tx_min)) * 100)))

    local tx_col = C.green
    if tx_pct <= 20 then tx_col = C.red
    elseif tx_pct <= 45 then tx_col = C.orange end

    local bx, by, bw, bh = 640, 13, 72, 27
    local tw, th = 4, 12

    if not is_trn and not is_transp then
      drawBgRect(X(bx), Y(by), W(bw), H(bh), C.panel2 or C.panel, is_transp)
    end
    lcd.drawRectangle(X(bx), Y(by), W(bw), H(bh), is_trn and C.white or C.blue)
    lcd.drawFilledRectangle(X(bx + bw), Y(by + (bh - th) / 2), W(tw), H(th), is_trn and C.white or C.blue)

    local inner_max_w = bw - 6
    local fill_w = math.max(tx_pct > 0 and 2 or 0, math.min(inner_max_w, math.floor((tx_pct / 100) * inner_max_w)))
    if fill_w > 0 then
      lcd.drawFilledRectangle(X(bx + 3), Y(by + 3), W(fill_w), H(bh - 6), tx_col)
    end

    -- Center Voltage Text inside Battery (Adaptive font ensures zero overflow on all radios)
    local tx_str = string.format("%.1fV", tx_v)
    local mid_bx = bx + math.floor(bw / 2)
    local bat_font = (sw < 600) and (f_0 ~= nil and f_0 or 0) or f_sml
    local ty_offset = (sw < 600) and 2 or 5
    lcd.drawText(X(mid_bx) + 1, Y(by + ty_offset) + 1, tx_str, CENTER + bat_font + C.black)
    lcd.drawText(X(mid_bx), Y(by + ty_offset), tx_str, CENTER + bat_font + C.white)

    -- Top-Right Stacked Date (Upper) & Time (Lower) - Mutual Vertical Axis Centering
    local dt_font = (sw < 600) and (f_0 ~= nil and f_0 or 0) or f_sml
    text(760, 9, data.dateStr, CENTER + dt_font, C.dim)
    text(760, 27, data.timeStr, CENTER + dt_font, C.white)
  end
  if not is_trn then
    lcd.drawLine(x, Y(58), x + sw, Y(58), SOLID, C.blue)
  end

  -- 3. Left Panel (Heli Picture, Flights, GOV, ARM/STATUS, Battery %)
  panel(X(10), Y(70), W(270), H(400), is_trn, is_transp)

  -- All supported RadioMaster color radios render model bitmaps.  The image is
  -- pre-sized when Bitmap.resize is available, otherwise drawBitmap uses its
  -- documented percentage scale argument.
  if heli_pic then
    drawHeliBitmap(X(heli_draw_x or 25), Y(heli_draw_y or 74), heli_pic, heli_scale)
  end

  local cur_lang = (w and w.ui_lang) or getUiLang(w)
  local is_cjk = (cur_lang == "tw" or cur_lang == "cn")
  local cjk_sml = is_cjk and 1 or 0
  local cjk_mid = is_cjk and 2 or 0

  -- Flights counter
  text(80, 218 + cjk_sml, T(w, "today_lbl") .. (w.flight_count or 0), CENTER + f_sml, C.white)
  text(205, 218 + cjk_sml, T(w, "total_lbl") .. (w.lifetime_count or 0), CENTER + f_sml, C.dim)

  -- GOV & STATUS Title Boxes (Upper Enclosed Header Cards)
  if not is_trn then
    drawBgRect(X(20), Y(250), W(120), H(26), C.panel2, is_transp)
    lcd.drawRectangle(X(20), Y(250), W(120), H(26), C.blue)
    drawBgRect(X(150), Y(250), W(120), H(26), C.panel2, is_transp)
    lcd.drawRectangle(X(150), Y(250), W(120), H(26), C.blue)
  end
  text(80, 252 + cjk_sml, T(w, "gov_lbl"), CENTER + f_sml, C.white)
  text(210, 252 + cjk_sml, T(w, "status"), CENTER + f_sml, C.white)

  -- GOV State Card (Standalone Floating Colored Badge)
  lcd.drawFilledRectangle(X(20), Y(282), W(120), H(38), data.gov_on and C.green or C.red)
  local gov_txt = data.gov_on and "ON" or "OFF"
  lcd.drawText(X(80) + 1, Y(282 + cjk_mid) + 1, gov_txt, CENTER + f_mid + C.black)
  lcd.drawText(X(80), Y(282 + cjk_mid), gov_txt, CENTER + f_mid + C.white)

  -- STATUS State Card (Standalone Floating Colored Badge)
  if data.rescue_active then
    local flash_on = (math.floor(now_t / 20) % 2) == 0
    lcd.drawFilledRectangle(X(150), Y(282), W(120), H(38), flash_on and C.red or C.black)
    local r_txt = T(w, "rescue")
    if flash_on then
      lcd.drawText(X(210) + 1, Y(282 + cjk_mid) + 1, r_txt, CENTER + f_mid + C.black)
      lcd.drawText(X(210), Y(282 + cjk_mid), r_txt, CENTER + f_mid + C.white)
    else
      lcd.drawText(X(210), Y(282 + cjk_mid), r_txt, CENTER + f_mid + C.red)
    end
  else
    lcd.drawFilledRectangle(X(150), Y(282), W(120), H(38), data.arm_on and C.red or C.green)
    local arm_txt = data.arm_on and T(w, "armed") or T(w, "safe")
    lcd.drawText(X(210) + 1, Y(282 + cjk_mid) + 1, arm_txt, CENTER + f_mid + C.black)
    lcd.drawText(X(210), Y(282 + cjk_mid), arm_txt, CENTER + f_mid + C.white)
  end

  -- Battery % Progress Bar
  if not is_trn then
    drawBgRect(X(20), Y(330), W(250), H(44), C.panel2, is_transp)
  end
  local pct_color = C.red
  if data.bat_pct > 30 then pct_color = C.green
  elseif data.bat_pct > 15 then pct_color = C.orange end

  local bar_w = math.max(0, math.min(250, math.floor((data.bat_pct / 100) * 250)))
  if bar_w > 0 then
    lcd.drawFilledRectangle(X(20), Y(330), W(bar_w), H(44), pct_color)
  end
  lcd.drawRectangle(X(20), Y(330), W(250), H(44), is_trn and C.black or C.blue)
  text(145, 332, string.format("%d %%", data.bat_pct), CENTER + f_mid, C.white)

  -- Battery Summaries
  if data.is_turbine_mode then
    text(145, 390, T(w, "turbine_jet"), CENTER + f_sml, C.dim)
    text(145, 412, string.format(T(w, "ecu_bat"), data.vbec), CENTER + f_sml, C.dim)
  elseif data.is_nitro_mode then
    text(145, 390, T(w, "nitro_eng"), CENTER + f_sml, C.dim)
    text(145, 412, string.format(T(w, "rx_pack"), data.vbec), CENTER + f_sml, C.dim)
  else
    text(145, 390, string.format(T(w, "battery_fmt"), data.cells, data.vbat), CENTER + f_sml, C.dim)
    local capa_text = string.format(T(w, "used_mah"), data.capa)
    if data.power and data.power >= 10 then
      if data.power >= 1000 then
        capa_text = capa_text .. string.format(" - %.1fkW", data.power / 1000)
      else
        capa_text = capa_text .. string.format(" - %.0fW", data.power)
      end
    elseif data.max_power and data.max_power >= 30 then
      if data.max_power >= 1000 then
        capa_text = capa_text .. string.format(T(w, "peak_pwr_kw"), data.max_power / 1000)
      else
        capa_text = capa_text .. string.format(T(w, "peak_pwr_w"), data.max_power)
      end
    end
    text(145, 412, capa_text, CENTER + f_sml, C.dim)
  end
  local bat_info_str = VERSION
  if w.last_bat_idx and w.last_bat_idx > 0 then
    if w.fleet_stats and w.fleet_stats[w.last_bat_idx] then
      local st = w.fleet_stats[w.last_bat_idx]
      bat_info_str = string.format("%s | BAT %d (%d/%dc)", VERSION, w.last_bat_idx, st.today_count or 0, st.lifetime_cycles or 0)
    else
      bat_info_str = VERSION .. " | BAT " .. w.last_bat_idx
    end
  end
  if w._last_s_val ~= nil then
    local l_str = tostring(w._last_s_val)
    if type(w._last_s_val) == "boolean" then l_str = w._last_s_val and "ON" or "OFF" end
    bat_info_str = bat_info_str .. string.format(" | LGT: %s", l_str)
  end
  text(145, 434, bat_info_str, CENTER + f_sml, C.dim)

  -- 4. Right Top Panel (RPM Card)
  panel(X(295), Y(70), W(495), H(160), is_trn, is_transp)
  text(318, 85, T(w, "rpm_lbl"), f_0, C.white)
  text(320, 122, string.format("%.0f", data.hspd), f_xxl, C.white)
  text(770, 124, string.format(T(w, "head_spd_max"), stat(3, "max")), RIGHT + f_sml, C.white)
  if not data.is_nitro_mode and not data.is_turbine_mode and (id[17] or data.tspd > 0 or data.max_tspd > 0) then
    text(770, 147, string.format(T(w, "tail_spd_max"), data.tspd, data.max_tspd), RIGHT + f_sml, C.white)
  else
    text(770, 147, string.format(T(w, "min_spd"), stat(3, "min")), RIGHT + f_sml, C.white)
  end
  text(770, 175, string.format(T(w, "mcu_temp"), sensor(7)), RIGHT + f_sml, C.white)

  -- 5. Right Bottom Panel (Electric / Nitro / Turbine)
  if data.is_turbine_mode then
    local turbine = loadModule("turbine")
    if turbine and turbine.draw then turbine.draw(w, ctx) end
  elseif data.is_nitro_mode then
    local nitro = loadModule("nitro")
    if nitro and nitro.draw then nitro.draw(w, ctx) end
  else
    panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)
    local colTitles = { T(w, "col_amps"), T(w, "col_cell"), T(w, "col_bec"), T(w, "col_esc_t") }
    local cell_color = (data.vcel > 0 and data.vcel < 3.5) and C.red or C.white
    local esc_temp_color = data.tesc > 60 and C.red or C.white

    local nums = {
      string.format("%.1f", data.curr),
      string.format("%.2f", data.vcel),
      string.format("%.1f", data.vbec),
      string.format("%.0f", data.tesc)
    }
    local units = { "A", "V", "V", "°C" }
    local colors = { C.white, cell_color, C.white, esc_temp_color }
    local subs = {
      string.format(T(w, "sub_max_a"), amps(stat(2, "max"))),
      string.format(T(w, "sub_min_v"), volts(stat(15, "min"))),
      string.format(T(w, "sub_min_bec"), volts(stat(12, "min"))),
      string.format(T(w, "sub_max_t"), stat(6, "max"))
    }

    for i = 1, 4 do
      local cx = 295 + (i - 1) * 124
      local mid_x = cx + 62
      if i > 1 and not is_trn then
        lcd.drawLine(X(cx), Y(245), X(cx), Y(405), SOLID, C.blue)
      end
      text(mid_x, 265, colTitles[i], CENTER + f_sml, C.dim)

      local val_color = colors[i]
      local num_str = nums[i]
      local unit_str = units[i]

      -- Large-number/small-unit typography: numbers prominent in f_dbl, units in f_0
      local num_w = 0
      local unit_w = 0
      if lcd.sizeText then
        num_w = select(1, lcd.sizeText(num_str, f_dbl))
        unit_w = select(1, lcd.sizeText(unit_str, f_0))
      else
        num_w = string.len(num_str) * (sw < 600 and 10 or 17)
        unit_w = string.len(unit_str) * (sw < 600 and 7 or 10)
      end
      local gap = (sw < 600) and 2 or 3
      local start_px = X(mid_x) - math.floor((num_w + gap + unit_w) / 2)
      textPhysical(start_px, Y(301), num_str, f_dbl, val_color)
      textPhysical(start_px + num_w + gap, Y(319), unit_str, f_0, val_color)
      text(mid_x, 362, subs[i], CENTER + f_sml, C.dim)
    end
  end

  -- 6. Bottom Status Bar (BANK, NO DATA / UserName)
  panel(X(295), Y(420), W(124), H(50), is_trn, is_transp)
  text(357, 436, bankText(w), CENTER + f_0, C.white)

  if not data.telemetry then
    lcd.drawFilledRectangle(X(434), Y(420), W(356), H(50), C.red)
    lcd.drawText(X(612), Y(429), T(w, "no_data"), CENTER + f_mid + C.white)
  else
    panel(X(434), Y(420), W(356), H(50), is_trn, is_transp)
    local user_name = getOption(w, "UserName") or ""
    if user_name ~= "" then
      text(612, 429, user_name, CENTER + f_mid, C.white)
    end
  end
end

-- =========================================================================
-- Core Telemetry, Voice & Safety Service Engine
-- =========================================================================
local function serviceTelemetry(w)
  updateSensors()

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
    arm_on = sensor(13) > 0
  end

  if arm_on then w.has_armed = true end

  local cur_vbat = sensor(1)
  local cur_bat_idx = getActiveBatIndex(w)
  local cur_vbec = volts(sensor(12))

  local heli_mode = parseHeliType(getOption(w, "Heli Type"))
  local is_nitro = (heli_mode == 2)
  local is_turbine = (heli_mode == 3)
  local is_electric = (heli_mode == 1)

  -- Power loss alert logic
  if w.has_armed and is_electric and cur_vbat < 5 and cur_vbec > 4 then
    if not w.power_lost_triggered then
      w.power_lost_triggered = true
      if playFile then
        if not pcall(playFile, "pwr_backup.wav") then
          if not pcall(playFile, "mainlost.wav") then
            pcall(playFile, "/SOUNDS/en/mainlost.wav")
          end
        end
      end
    end
    if w.power_lost_triggered and not w.power_lost_muted then
      local now = getTime()
      if now - w.last_alarm_time > 300 then
        if playTone then playTone(2000, 300, 300, 0) end
        if playHaptic then playHaptic(200, 300) end
        w.last_alarm_time = now
      end
    end
  else
    if cur_vbat > 10 then
      w.power_lost_triggered = false
      w.power_lost_muted = false
    end
  end

  -- Battery prompt & active battery change listener
  if w.last_vbat < 5 and cur_vbat >= 5 then
    w.bat_prompt_timer = getTime()
    if playTone then pcall(playTone, 1800, 120, 80, 0) end
  end
  if cur_bat_idx ~= w.last_bat_idx and w.last_bat_idx ~= -1 then
    w.bat_prompt_timer = getTime()
    if playTone then pcall(playTone, 2200, 100, 50, 0) end
    w.log_loaded = false
    w.fleet_data = nil
  end

  local cur_vcel = volts(sensor(15))
  if cur_vcel <= 0 and cur_vbat > 0 then
    local cell_cnt = math.max(1, math.floor(cur_vbat / 4.2 + 0.5))
    cur_vcel = cur_vbat / cell_cnt
  end
  if cur_bat_idx >= 1 and cur_bat_idx <= 6 and not arm_on and cur_vbat >= 5.0 then
    updateBatteryStatusOnVoltage(w, cur_bat_idx, cur_vcel, cur_vbat)
  end

  w.last_vbat = cur_vbat
  w.last_bat_idx = cur_bat_idx

  -- Logbook switch listener (Edge-triggered so manual touch opening is NOT instantly overridden!)
  local logSw = getOption(w, "Logbook Sw")
  if logSw and logSw ~= 0 then
    local l_val = getValue(logSw)
    if w.last_log_sw == nil then
      w.last_log_sw = l_val
      if type(l_val) == "number" then
        if l_val >= 50 or l_val == 2 then
          w.show_logbook = true
          w.logbook_tab = 2
        elseif (l_val > -50 and l_val < 50) or l_val == 1 then
          w.show_logbook = true
          w.logbook_tab = 1
        end
      elseif type(l_val) == "boolean" and l_val then
        w.show_logbook = true
        w.logbook_tab = 1
      end
    elseif w.last_log_sw ~= l_val then
      w.last_log_sw = l_val
      if type(l_val) == "boolean" then
        w.show_logbook = l_val
        w.logbook_tab = 1
      elseif type(l_val) == "number" then
        if l_val >= 50 or l_val == 2 then
          w.show_logbook = true
          w.logbook_tab = 2
        elseif (l_val > -50 and l_val < 50) or l_val == 1 then
          w.show_logbook = true
          w.logbook_tab = 1
        else
          w.show_logbook = false
        end
      end
    end
  end

  -- Telemetry connectivity & smart composite in-flight detection
  local is_online = (cur_vbat >= 5.0) or (cur_vbec >= 3.5)
  local valid_arm = arm_on and is_online

  local cur_thr = sensor(11) or 0
  local cur_rpm = sensor(3) or 0
  local cur_amp = amps(sensor(2) or 0)
  local is_power_active = (cur_thr > 0) or (cur_rpm > 300) or (cur_amp > 1.5)

  if valid_arm and is_power_active then
    w.has_flown_this_arm = true
  end
  local is_flying = valid_arm and (is_power_active or (w.has_flown_this_arm == true))

  -- Dynamic craft name change detection (active on bench & ground standby; noise-locked only during active flight)
  if not is_flying then
    local currentCraftName = getCraftName()
    if w.last_craft_name ~= currentCraftName then
      w.last_craft_name = currentCraftName
      w.log_loaded = false
    end
  end

  if not w.log_loaded then
    loadFlightLog(w)
    loadLogbook(w)
    loadChartData(w)
    loadFleetData(w)
    w.log_loaded = true
  end

  local dt = getDateTime()
  local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)
  if w.log_loaded and w.last_date ~= today then
    w.flight_count = 0
    w.last_date = today
    -- Only write to SD card on new day if historical lifetime flights exist; do not create empty files on first boot
    if (w.lifetime_count or 0) > 0 then
      saveFlightLog(w)
    end
  end

  -- Flight log counting & Chart data ring buffer
  if w.log_loaded then
    -- High-frequency dedicated Voice Alarm polling (every 200ms)
    local voice_opt = getOption(w, "Voice Alarm")
    if voice_opt == 1 or voice_opt == true then
      local now_t = getTime()
      if (now_t - (w.last_voice_poll or 0)) >= 20 then
        w.last_voice_poll = now_t
        local voice_mod = loadModule("voice")
        if voice_mod and voice_mod.update then
          local v_ctx = {
            sensor = sensor, stat = stat, volts = volts, amps = amps,
            is_nitro = is_nitro,
            getOption = function(k) return getOption(w, k) end
          }
          pcall(voice_mod.update, w, v_ctx)
        end
      end
    end

    if valid_arm then
      if not w.last_arm_state then
        w.arm_start_time = getTime()
        local cur_dt = getDateTime()
        w.takeoff_clock_str = string.format("%02d:%02d", cur_dt.hour or 0, cur_dt.min or 0)
        w.flight_counted_this_arm = false
        w.chart_reset_this_arm = false
        w.last_sample_time = w.arm_start_time
      elseif not w.flight_counted_this_arm and w.arm_start_time then
        local elapsed = getTime() - w.arm_start_time
        local max_rpm = stat(3, "max") or 0
        local max_amp = amps(stat(2, "max") or 0)
        -- Valid flight criteria: 15s armed duration OR (rotor spinning > 400 RPM / load > 2A)
        if (elapsed >= 1500) or ((max_rpm > 400 or max_amp > 2.0) and elapsed >= 500) then
          w.flight_count = (w.flight_count or 0) + 1
          w.lifetime_count = (w.lifetime_count or 0) + 1
          w.flight_counted_this_arm = true
          w.needs_flight_log_save = true
          -- Strictly NO SD write mid-air! Deferred to DISARM below.
        end
      end

      -- Chart data sampling (buffered in RAM only)
      if not w.chart_reset_this_arm then
        w.chart_data = {}
        w.chart_reset_this_arm = true
      end
      if w.chart_data then
        local now_t = getTime()
        if (now_t - (w.last_sample_time or 0)) >= 300 then
          w.last_sample_time = now_t
          local vbat_s = volts(sensor(1))
          local curr_s = amps(sensor(2))
          local rpm_s = sensor(3)
          local bec_s = volts(sensor(12))
          local tmp_s = sensor(6)

          table.insert(w.chart_data, { v = vbat_s, a = curr_s, r = rpm_s, b = bec_s, t = tmp_s })
          if #w.chart_data > 200 then
            table.remove(w.chart_data, 1)
          end
        end
      end
    else
      -- Landed & DISARMED: Safe point to perform SD card file I/O operations
      if w.flight_counted_this_arm and w.arm_start_time then
        local dur_s = math.floor((getTime() - w.arm_start_time) / 100)
        if dur_s >= 8 then
          local dur_str = string.format("%02d:%02d", math.floor(dur_s / 60), dur_s % 60)
          local time_str = w.takeoff_clock_str or string.format("%02d:%02d", dt.hour or 0, dt.min or 0)
          local rpm_str = string.format("%.0f", stat(3, "max") or 0)
          local amps_str = string.format("%.1f", amps(stat(2, "max") or 0))
          local cell_str = string.format("%.2f", volts(stat(15, "min") or 0))
          local bec_str = string.format("%.2f", volts(stat(12, "min") or 0))
          local tmp_str = string.format("%.0f", stat(6, "max") or 0)
          local capa_str = string.format("%.0f", stat(4, "cur") or stat(4, "max") or 0)
          local pwr_str = string.format("%.0f", w.max_power or 0)
          local parts = { time_str, dur_str, rpm_str, amps_str, cell_str, bec_str, tmp_str, capa_str, pwr_str }
          table.insert(w.log_entries, 1, parts)
          if #w.log_entries > 10 then table.remove(w.log_entries) end
          saveLogbook(w)

          -- Update battery fleet stats
          local cur_bat = getActiveBatIndex(w) or 1
          if cur_bat >= 1 and cur_bat <= 6 and w.fleet_stats then
            local st = w.fleet_stats[cur_bat]
            if st then
              st.today_count = (st.today_count or 0) + 1
              st.lifetime_cycles = (st.lifetime_cycles or 0) + 1
              st.status = "FLOWN"
              st.last_mah = tonumber(capa_str) or 0
              local min_v_num = tonumber(cell_str) or 0
              if min_v_num > 0 and (st.min_v == "-" or min_v_num < (tonumber(st.min_v) or 999)) then
                st.min_v = string.format("%.2f", min_v_num)
              end
              local max_t_num = tonumber(tmp_str) or 0
              if max_t_num > 0 and (st.max_t == "-" or max_t_num > (tonumber(st.max_t) or 0)) then
                st.max_t = string.format("%.0f", max_t_num)
              end
              st.tot_dur_s = (st.tot_dur_s or 0) + dur_s
              st.tot_flights = (st.tot_flights or 0) + 1
              local avg_s = math.floor(st.tot_dur_s / math.max(1, st.tot_flights))
              st.avg_dur = string.format("%02d:%02d", math.floor(avg_s / 60), avg_s % 60)
              saveFleetData(w)
            end
          end
        end
        if w.needs_flight_log_save then
          saveFlightLog(w)
          w.needs_flight_log_save = false
        end
      end
      if w.chart_reset_this_arm and w.chart_data and #w.chart_data >= 2 then
        saveChartData(w)
      end
      w.arm_start_time = nil
      w.flight_counted_this_arm = false
      w.chart_reset_this_arm = false
      w.has_flown_this_arm = false
    end
    w.last_arm_state = valid_arm
  end

  -- Switch Reset Listeners
  local reset_on = false
  local r_opt = getOption(w, "Reset FlyCount")
  if r_opt and r_opt ~= 0 then
    local r_val = getValue(r_opt)
    if type(r_val) == "boolean" then reset_on = r_val
    elseif type(r_val) == "number" then reset_on = r_val > 0 end
  end

  local bat_reset_on = false
  local bat_reset_src = getOption(w, "Reset Bat Log")
  if bat_reset_src and bat_reset_src ~= 0 then
    local br_val = getValue(bat_reset_src)
    if type(br_val) == "boolean" then bat_reset_on = br_val
    elseif type(br_val) == "number" then bat_reset_on = br_val > 0 end
  end

  -- Switch Reset Listeners (Bench & ground standby 100% active; protected only during active in-flight power)
  if w.log_loaded then
    if bat_reset_on and not w.last_bat_reset_state then
      if not is_flying then
        resetActiveBatLog(w)
      end
    elseif reset_on and not w.last_reset_state then
      if w.show_logbook and w.logbook_tab == 2 then
        if not is_flying then
          resetActiveBatLog(w)
        end
      else
        w.flight_count = 0
        if not is_flying then
          saveFlightLog(w)
        else
          w.needs_flight_log_save = true
        end
      end
    end
  end
  w.last_reset_state = reset_on
  w.last_bat_reset_state = bat_reset_on

  -- LED Strip Controller
  if LED_STRIP_LENGTH and LED_STRIP_LENGTH > 0 and setRGBLedColor and applyRGBLedColors then
    local led_val = getOption(w, "DispLED")
    local enabled = (led_val == 1 or led_val == true or led_val == "1")
    local color_opt = getOption(w, "LED Color")
    local color_idx = parseLedColorIndex(color_opt)
    local is_rainbow = (color_idx == 9) or (color_opt == "Rainbow")

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

  -- Calculate all snapshot telemetry fields for UI
  local vbat, curr, hspd, capa = volts(sensor(1)), amps(sensor(2)), sensor(3), sensor(4)
  local tesc, vbec, gov, vcel = sensor(6), volts(sensor(12)), sensor(14), volts(sensor(15))
  local fm_raw = id[16] and getValue(id[16]) or ""
  local rescue_active = false
  if type(fm_raw) == "string" then
    local s = string.lower(fm_raw)
    if string.find(s, "rescue") or string.find(s, "bail") then
      rescue_active = true
    end
  end

  local timer, timerColor = timerText(w)
  local cells = 0
  if vbat > 0 and vcel and vcel > 1.0 then
    cells = math.floor((vbat / vcel) + 0.5)
  elseif vbat > 0 then
    local max_vbat = stat(1, "max")
    local ref_v = (max_vbat and max_vbat > 0) and max_vbat or vbat
    cells = math.max(1, math.floor(ref_v / 3.85 + 0.5))
  end

  local telemetry = false
  for i = 1, #sensors do
    if id[i] and stat(i, "cur") ~= 0 then telemetry = true break end
  end

  local modelName = getCraftName()
  local txVoltage = getValue("tx-voltage") or getValue("TxBt") or 0
  local dateStr = string.format("%02d-%02d", dt.mon or 1, dt.day or 1)
  local timeStr = string.format("%02d:%02d", dt.hour or 0, dt.min or 0)
  local bat_pct = sensor(5)

  local cur_power = vbat * curr
  if valid_arm and cur_power > 0 then
    w.max_power = math.max(w.max_power or 0, cur_power)
  elseif not valid_arm and is_power_active and (cur_power > (w.max_power or 0)) then
    w.max_power = cur_power
  end
  if cur_vbat < 5.0 then
    w.max_power = 0
  end

  local td = w.telem_data or {}
  td.arm_on = arm_on
  td.modelName = modelName
  td.txVoltage = txVoltage
  td.dateStr = dateStr
  td.timeStr = timeStr
  td.clock = timeStr
  td.timer = timer
  td.timerColor = timerColor
  td.gov_on = (gov > 0)
  td.rescue_active = rescue_active
  td.bat_pct = bat_pct
  td.is_turbine_mode = is_turbine
  td.is_nitro_mode = is_nitro
  td.is_electric = is_electric
  td.vbat = vbat
  td.vbec = vbec
  td.vcel = vcel
  td.capa = capa
  td.cells = cells
  td.curr = curr
  td.power = cur_power
  td.max_power = w.max_power or 0
  td.hspd = hspd
  td.tesc = tesc
  td.tspd = sensor(17)
  td.max_tspd = stat(17, "max")
  td.bank_str = bankText(w)
  td.telemetry = telemetry
  td.rssi = sensor(8)
  td.link_qual = sensor(10)
  w.telem_data = td
  return td
end

-- =========================================================================
-- Popups Sub-view Rendering (Battery Health & Headspeed / Power Chart)
-- =========================================================================
local function drawPopups(w, ctx)
  local pop_mod = loadModule("popups")
  if pop_mod and not pop_mod._initialized then
    pop_mod.init({ T = T })
  end
  if pop_mod and pop_mod.drawPopups then
    return pop_mod.drawPopups(w, ctx)
  end
end

-- =========================================================================
-- EdgeTX Widget Standard Callbacks: create, update, refresh, background
-- =========================================================================
local function create(zone, opts)
  resetMinMax()
  local w = {
    zone = zone, options = opts, active_popup = nil,
    bat_prompt_timer = -10000, last_vbat = -1, last_bat_idx = -1,
    has_armed = false, power_lost_triggered = false, power_lost_muted = false,
    last_alarm_time = 0, last_heartbeat = 0, needs_rebuild = true,
    telem_data = {},
    render_ctx = {}
  }
  -- Preload modules at widget startup so no SD card compilation happens in refresh()
  loadModule("storage")
  loadModule("popups")
  loadModule("i18n")
  loadModule("battery")
  loadModule("logbook")
  loadModule("voice")
  loadModule("nitro")
  loadModule("turbine")
  loadModule("layout_F-type")
  return w
end

local function update(w, opts)
  w.options = opts
  w.needs_rebuild = true
end

local function background(w)
  if not w then return end
  serviceTelemetry(w)
end

local function refresh(w, event, touchState)
  if not w then return end

  -- 1. Run core telemetry, voice alarms, power-loss monitor, and logbook updates
  local telemData = serviceTelemetry(w)

  applyDynamicTheme(w, telemData.arm_on)
  telemData.light_val = w._last_s_val
  telemData.light_active = (w.active_theme_idx == 11)

  local z = w.zone or { x = 0, y = 0, w = 480, h = 272 }
  local x, y, sw, sh = math.floor(z.x or 0), math.floor(z.y or 0), math.floor(z.w or 480), math.floor(z.h or 272)
  local sx, sy = sw / 800, sh / 480
  local function X(v) return x + math.floor(v * sx) end
  local function Y(v) return y + math.floor(v * sy) end
  local function W(v) return math.floor(v * sx) end
  local function H(v) return math.floor(v * sy) end

  w.ui_lang = getUiLang(w)
  local theme_opt = getOption(w, "Theme")
  local t_val = w.active_theme_idx or parseThemeIndex(theme_opt)
  local is_trn = (t_val == 9)
  local is_transp = (getOption(w, "Transp BG") == 1 or getOption(w, "Transp BG") == true)
  if t_val == 11 or t_val == 12 then is_transp = false; is_trn = false end

  local f_xxl, f_dbl, f_mid, f_sml, f_0 = XXLSIZE, DBLSIZE, MIDSIZE, SMLSIZE, 0
  if sw < 600 then
    f_xxl, f_dbl, f_mid, f_sml, f_0 = DBLSIZE, MIDSIZE, 0, SMLSIZE, SMLSIZE
  end

  -- 2. Touch event handling
  local is_tap = false
  local tx, ty = 0, 0
  if type(touchState) == "table" and touchState.x and touchState.x > 0 and touchState.y and touchState.y > 0 then
    local cur_x = touchState.x
    local cur_y = touchState.y
    local is_break = (EVT_TOUCH_BREAK ~= nil and event == EVT_TOUCH_BREAK) or (event == 99) or (touchState.state == 2)
    if is_break then
      w.finger_touching = false
    else
      if not w.finger_touching then
        w.finger_touching = true
        w.touch_seq = (w.touch_seq or 0) + 1
        tx, ty = cur_x, cur_y
        is_tap = true
      end
    end
  else
    w.finger_touching = false
  end

  if event == EVT_VIRTUAL_ENTER then
    w.show_logbook = not w.show_logbook
    if w.show_logbook then w.logbook_tab = 1 end
  elseif event == EVT_VIRTUAL_EXIT then
    if w.power_lost_triggered and not w.power_lost_muted then
      w.power_lost_muted = true
    elseif w.active_popup then
      w.active_popup = nil
    elseif w.show_logbook then
      w.show_logbook = false
    elseif lcd.exitFullScreen then
      lcd.exitFullScreen()
      return true
    end
  elseif is_tap then
    local now_t = getTime()
    local is_banner = (now_t - w.bat_prompt_timer < 1000) and (not telemData.arm_on)
    if is_banner and tx >= X(100) and tx <= X(700) and ty <= Y(65) then
      w.bat_prompt_timer = 0
      w.active_popup = "battery"
      w.popup_open_t = now_t
    elseif w.active_popup then
      local popup_age = now_t - (w.popup_open_t or 0)
      if popup_age > 35 then
        if w.active_popup == "battery" then
          local bat_idx = w.last_bat_idx or 1
          local st = w.fleet_stats and w.fleet_stats[bat_idx]
          -- 1. Status selector buttons (Y: 194 to 254)
          if ty >= Y(194) and ty <= Y(254) then
            if st then
              if tx >= X(100) and tx <= X(242) then
                st.status = "READY"
                saveFleetData(w)
                if playTone then playTone(1800, 80, 50, 0) end
              elseif tx >= X(248) and tx <= X(392) then
                st.status = "FLOWN"
                saveFleetData(w)
                if playTone then playTone(1600, 80, 50, 0) end
              elseif tx >= X(398) and tx <= X(542) then
                st.status = "STORAGE"
                saveFleetData(w)
                if playTone then playTone(1400, 80, 50, 0) end
              elseif tx >= X(548) and tx <= X(705) then
                st.status = "NONE"
                saveFleetData(w)
                if playTone then playTone(1200, 80, 50, 0) end
              end
            end
          -- 2. Action Button A: Reset Today Count (Y: 256 to 318, X: 100 to 392)
          elseif ty >= Y(256) and ty <= Y(318) and tx >= X(100) and tx <= X(392) then
            if st then
              st.today_count = 0
              saveFleetData(w)
              if playTone then playTone(2000, 120, 50, 0) end
            end
          -- 3. Action Button B: Set Active Battery (Y: 256 to 318, X: 408 to 705)
          elseif ty >= Y(256) and ty <= Y(318) and tx >= X(408) and tx <= X(705) then
            w.manual_bat_idx = bat_idx
            w.last_bat_idx = bat_idx
            saveFleetData(w)
            if playTone then playTone(2200, 100, 50, 0) end
          -- 4. Click anywhere else to close
          else
            w.active_popup = nil
          end
        elseif w.active_popup == "session_stats" then
          if tx >= X(180) and tx <= X(380) and ty >= Y(280) and ty <= Y(345) then
            w.flight_count = 0
            saveFlightLog(w)
            if playTone then playTone(1500, 100, 100, 0) end
          elseif tx >= X(420) and tx <= X(620) and ty >= Y(280) and ty <= Y(345) then
            w.lifetime_count = 0
            saveFlightLog(w)
            if playTone then playTone(1800, 150, 100, 0) end
          end
          w.active_popup = nil
        else
          -- telemetry_info or power_stats: tap anywhere to close
          w.active_popup = nil
        end
      end
    elseif not w.show_logbook then
      local theme_opt = getOption(w, "Theme")
      local t_val = w.active_theme_idx or parseThemeIndex(theme_opt)
      local handled = false
      if t_val == 12 then
        local ftype_mod = loadModule("layout_F-type")
        if ftype_mod and ftype_mod.handleTouch then
          local ok, res = pcall(ftype_mod.handleTouch, w, tx, ty, { X = X, Y = Y, W = W, H = H, sw = sw, sh = sh, x = x, y = y })
          if ok and res then handled = true end
        end
        -- F-type layout has independent calibrated touch boundaries; do not fall through to legacy theme areas
        handled = true
      end
      if not handled then
        if tx <= X(295) and ty <= Y(315) then
          w.active_popup = "session_stats"
          w.popup_open_seq = w.touch_seq
        elseif tx <= X(295) and ty > Y(315) and ty <= Y(410) then
          w.active_popup = "battery"
          w.popup_open_seq = w.touch_seq
        elseif tx <= X(295) and ty > Y(410) then
          -- Direct touch on Battery area cycles active battery 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 1
          w.manual_bat_idx = ((w.last_bat_idx or 1) % 6) + 1
          w.last_bat_idx = w.manual_bat_idx
          w.bat_prompt_timer = now_t
          w.log_loaded = false
          w.fleet_data = nil
          if playTone then pcall(playTone, 2200, 100, 50, 0) end
        elseif tx > X(295) and ty <= Y(240) then
          w.active_popup = "power_stats"
          w.popup_open_seq = w.touch_seq
        elseif tx > X(295) and ty > Y(240) and ty <= Y(410) then
          w.active_popup = "power_stats"
          w.popup_open_seq = w.touch_seq
        end
      end
    else
      -- In Logbook screen
      if w.logbook_tab == 2 and ty >= Y(85) and ty <= Y(420) then
        -- Direct touch on Battery Fleet Manager table row opens battery health popup for that battery (1 to 6)!
        local row = math.floor((ty - Y(85)) / math.max(1, H(55))) + 1
        if row >= 1 and row <= 6 then
          w.manual_bat_idx = row
          w.last_bat_idx = row
          w.active_popup = "battery"
          w.popup_open_seq = w.touch_seq
          if playTone then pcall(playTone, 2200, 100, 50, 0) end
        end
      elseif w.logbook_tab == 1 and ty >= Y(85) and ty < Y(225) then
        -- Direct touch on Logbook table row selects that flight (1 to 5) and displays its chart!
        local max_rows = (sh < 300) and 3 or 5
        local row_step = (max_rows == 5) and 27 or 30
        local clicked_row = math.floor((ty - Y(88)) / math.max(1, H(row_step))) + 1
        local max_avail = math.min(max_rows, #(w.log_entries or {}))
        if clicked_row >= 1 and clicked_row <= max_avail then
          w.selected_chart_idx = clicked_row
          loadChartData(w, clicked_row)
          if playTone then pcall(playTone, 2000, 50, 50, 0) end
        end
      elseif ty < Y(85) then
        -- Tap top title toggles Tab 1 (Logbook) vs Tab 2 (Fleet Manager)
        w.logbook_tab = (w.logbook_tab == 1) and 2 or 1
        w.fleet_data = nil
        if playTone then pcall(playTone, 1500, 80, 50, 0) end
      end
    end
  end

  -- F-type uses a wider but shorter model card than the standard dashboard.
  -- Include those bounds in the load-time resize so every radio draws at 1:1.
  local model_max_w, model_max_h = 240, 140
  if t_val == 12 then model_max_w, model_max_h = 256, 106 end
  loadModelImage(sx, sy, sw, sh, model_max_w, model_max_h)

  -- 3. Context Table for Rendering
  local is_modal_active = (w.show_logbook or w.active_popup ~= nil)

  local function text(px, py, str, flags, color)
    if (is_trn or is_transp) and color ~= C.black then
      lcd.drawText(X(px) + 2, Y(py) + 2, str, flags + C.black)
    end
    lcd.drawText(X(px), Y(py), str, flags + color)
  end

  local ctx = w.render_ctx or {}
  ctx.x = x; ctx.y = y; ctx.sw = sw; ctx.sh = sh; ctx.sx = sx; ctx.sy = sy
  ctx.X = X; ctx.Y = Y; ctx.W = W; ctx.H = H; ctx.text = text
  ctx.is_trn = is_trn; ctx.is_transp = is_transp
  ctx.f_xxl = f_xxl; ctx.f_dbl = f_dbl; ctx.f_mid = f_mid; ctx.f_sml = f_sml; ctx.f_0 = f_0
  ctx.lcd = lcd; ctx.C = C; ctx.sensor = sensor; ctx.stat = stat
  ctx.amps = amps; ctx.volts = volts; ctx.panel = panel
  ctx.getOption = ctx.getOption or function(k) return getOption(w, k) end
  ctx.RIGHT = RIGHT; ctx.CENTER = CENTER; ctx.modelName = telemData.modelName
  ctx.ui_lang = w.ui_lang
  ctx.T = ctx.T or function(k) return T(w, k) end
  ctx.fleet_stats = w.fleet_stats
  ctx.heli_pic = heli_pic
  ctx.heli_scale = heli_scale
  ctx.drawHeliBitmap = drawHeliBitmap
  ctx.data = telemData
  w.last_telem = telemData
  w.render_ctx = ctx

  -- 4. Draw Dashboard (when not full-screen Logbook)
  if not w.show_logbook then
    local ok_dash, err_dash = pcall(drawDashboard, w, telemData, ctx)
    if not ok_dash then
      -- Fail-Safe Emergency HUD (Zero crash, keeps pilot informed of vital signs)
      lcd.drawFilledRectangle(ctx.x, ctx.y, ctx.sw, ctx.sh, ctx.C.bg)
      lcd.drawRectangle(ctx.x, ctx.y, ctx.sw, ctx.sh, ctx.C.red)
      lcd.drawText(ctx.X(400), ctx.Y(80), "RBCT EMERGENCY HUD", ctx.CENTER + ctx.f_mid + ctx.C.red)
      lcd.drawText(ctx.X(400), ctx.Y(160), string.format("VBAT: %.1fV (%dS)", telemData.vbat or 0, telemData.cells or 0), ctx.CENTER + ctx.f_dbl + ctx.C.white)
      lcd.drawText(ctx.X(400), ctx.Y(240), string.format("RPM: %.0f | %s", telemData.hspd or 0, telemData.arm_on and "ARMED" or "SAFE"), ctx.CENTER + ctx.f_mid + (telemData.arm_on and ctx.C.red or ctx.C.green))
      lcd.drawText(ctx.X(400), ctx.Y(320), "TIMER: " .. tostring(telemData.timer or "00:00"), ctx.CENTER + ctx.f_mid + ctx.C.yellow)
      lcd.drawText(ctx.X(400), ctx.Y(400), tostring(err_dash), ctx.CENTER + ctx.f_sml + ctx.C.dim)
    end
  end

  -- 5. Render Logbook if active
  if w.show_logbook then
    local log_mod = loadModule("logbook")
    if log_mod and log_mod.drawLogbook then
      local ok, err = pcall(log_mod.drawLogbook, w, ctx)
      if not ok then
        lcd.drawFilledRectangle(x, y, sw, sh, C.red)
        lcd.drawText(x + 10, y + 10, "LOGBOOK CRASH:", 0)
        lcd.drawText(x + 10, y + 40, tostring(err), 0)
      end
    else
      lcd.drawFilledRectangle(x, y, sw, sh, C.red)
      lcd.drawText(x + 10, y + 10, "LOGBOOK MODULE LOAD FAILED", 0)
      lcd.drawText(x + 10, y + 40, tostring(w_last_mod_err), 0)
    end
  end

  -- 6. Popups Modal Overlay
  if w.active_popup then
    local ok_pop, err_pop = pcall(drawPopups, w, ctx)
    if not ok_pop then
      -- If drawPopups fails, draw fallback error box without crashing widget
      lcd.drawFilledRectangle(ctx.X(150), ctx.Y(60), ctx.W(500), ctx.H(370), ctx.C.panel2)
      lcd.drawText(ctx.X(400), ctx.Y(100), "POPUP RENDER ERROR", ctx.CENTER + ctx.f_mid + ctx.C.red)
      lcd.drawText(ctx.X(400), ctx.Y(150), tostring(err_pop), ctx.CENTER + ctx.f_sml + ctx.C.white)
      lcd.drawText(ctx.X(400), ctx.Y(380), "Tap to close", ctx.CENTER + ctx.f_sml + ctx.C.dim)
    end
  end
end

return {
  name = NAME,
  options = options,
  create = create,
  update = update,
  refresh = refresh,
  background = background
}
