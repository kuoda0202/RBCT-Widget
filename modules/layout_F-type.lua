-- =========================================================================
-- RBCT Widget - F-type Theme & Layout Module
-- Pixel-Accurate Recreation from User Reference UI (MK3 800x480 Standard)
-- =========================================================================

local function getTrimValueFromRadio(name, stick_idx)
  -- 1. Try model.getTrim (EdgeTX standard model API)
  if model and model.getTrim then
    local fm = 0
    if model.getFlightMode then
      local ok_fm, res_fm = pcall(model.getFlightMode)
      if ok_fm and type(res_fm) == "number" then fm = res_fm end
    end
    local ok, res = pcall(model.getTrim, fm, stick_idx)
    if ok then
      if type(res) == "table" and res.value ~= nil then
        return tonumber(res.value) or 0
      elseif type(res) == "number" then
        return res
      end
    end
  end

  -- 2. Try getValue by EdgeTX source names
  if getValue then
    local s_low = string.lower(name)
    local candidate_names = {
      "trim-" .. s_low,
      "t-" .. s_low,
      name .. " Trim",
      "Trim" .. name,
      name
    }
    for i = 1, #candidate_names do
      local ok, v = pcall(getValue, candidate_names[i])
      if ok and type(v) == "number" and v ~= 0 then
        return v
      end
    end

    if getFieldInfo then
      for i = 1, #candidate_names do
        local ok_fi, info = pcall(getFieldInfo, candidate_names[i])
        if ok_fi and info and info.id then
          local ok_v, v = pcall(getValue, info.id)
          if ok_v and type(v) == "number" and v ~= 0 then
            return v
          end
        end
      end
    end
  end

  -- 3. Fallbacks
  if getTrimValue then
    local ok, v = pcall(getTrimValue, 0, stick_idx)
    if ok and type(v) == "number" then return v end
  end
  if getTrim then
    local ok, v = pcall(getTrim, stick_idx)
    if ok and type(v) == "number" then return v end
  end

  return 0
end

local function formatTrimNum(v)
  if v == nil or v == 0 then return "+0" end
  local steps = 0
  if math.abs(v) > 120 then
    steps = math.floor(v / 10.24 + 0.5)
  else
    steps = math.floor(v + 0.5)
  end
  if steps > 0 then return "+" .. steps
  elseif steps < 0 then return tostring(steps)
  else return "+0" end
end

local function normalizeTrim(v)
  if v == nil or v == 0 then return 0 end
  if math.abs(v) > 120 then
    return math.max(-100, math.min(100, (v / 1024) * 100))
  else
    return math.max(-100, math.min(100, (v / 100) * 100))
  end
end

local function drawRoundedPanel(lcd, x, y, w, h, bg_col, border_col)
  lcd.drawFilledRectangle(x + 2, y, w - 4, h, bg_col)
  lcd.drawFilledRectangle(x, y + 2, w, h - 4, bg_col)
  lcd.drawRectangle(x, y, w, h, border_col)
  lcd.drawLine(x, y + 1, x + 1, y, SOLID, border_col)
  lcd.drawLine(x + w - 1, y + 1, x + w - 2, y, SOLID, border_col)
  lcd.drawLine(x, y + h - 2, x + 1, y + h - 1, SOLID, border_col)
  lcd.drawLine(x + w - 1, y + h - 2, x + w - 2, y + h - 1, SOLID, border_col)
end

local function drawAircraftSilhouette(lcd, cx, cy, is_heli, color)
  if is_heli then
    -- Clean stylized Helicopter silhouette
    lcd.drawLine(cx - 32, cy - 12, cx + 32, cy - 12, SOLID, color)
    lcd.drawLine(cx - 30, cy - 11, cx + 30, cy - 11, SOLID, color)
    lcd.drawFilledRectangle(cx - 3, cy - 11, 6, 4, color)           -- Mast
    lcd.drawFilledRectangle(cx - 22, cy - 7, 30, 18, color)        -- Body
    lcd.drawLine(cx + 8, cy - 1, cx + 40, cy - 1, SOLID, color)    -- Boom
    lcd.drawLine(cx + 8, cy, cx + 40, cy, SOLID, color)
    lcd.drawLine(cx + 40, cy - 12, cx + 40, cy + 10, SOLID, color) -- Fin
    lcd.drawLine(cx - 24, cy + 14, cx + 16, cy + 14, SOLID, color) -- Skid
    lcd.drawLine(cx - 14, cy + 11, cx - 14, cy + 14, SOLID, color)
    lcd.drawLine(cx + 6, cy + 11, cx + 6, cy + 14, SOLID, color)
  else
    -- F-type airplane silhouette (fuselage, swept wings, tail)
    lcd.drawFilledRectangle(cx - 4, cy - 24, 8, 48, color)
    lcd.drawLine(cx - 38, cy - 3, cx + 38, cy - 3, SOLID, color)
    lcd.drawLine(cx - 38, cy - 2, cx + 38, cy - 2, SOLID, color)
    lcd.drawLine(cx - 36, cy - 1, cx + 36, cy - 1, SOLID, color)
    lcd.drawLine(cx - 18, cy + 18, cx + 18, cy + 18, SOLID, color)
    lcd.drawLine(cx - 16, cy + 19, cx + 16, cy + 19, SOLID, color)
  end
end

local function drawBitmapImg(lcd, px, py, bmp, scale_pct)
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
-- RadioMaster Logo (Hardware DMA2D Bitmap with Text Fallback)
-- =========================================================================
local rm_logo_img = nil
local rm_logo_sml_img = nil
local rm_logo_tried = false

local function getRmLogo(is_sml)
  if not rm_logo_tried then
    rm_logo_tried = true
    if Bitmap and Bitmap.open then
      pcall(function()
        rm_logo_img = Bitmap.open("/WIDGETS/RBCT/Pic/rm_logo.png") or Bitmap.open("WIDGETS/RBCT/Pic/rm_logo.png")
        rm_logo_sml_img = Bitmap.open("/WIDGETS/RBCT/Pic/rm_logo_sml.png") or Bitmap.open("WIDGETS/RBCT/Pic/rm_logo_sml.png")
      end)
    end
  end
  return is_sml and (rm_logo_sml_img or rm_logo_img) or (rm_logo_img or rm_logo_sml_img)
end

local function drawRmLogo(lcd, lx, ly, color, is_sml, f_mid)
  local bmp = getRmLogo(is_sml)
  if bmp then
    drawBitmapImg(lcd, lx, ly, bmp, 100)
  else
    lcd.drawText(lx, ly, "RADIOMASTER", f_mid + color)
  end
end

local function draw(w, data, ctx)
  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H
  local x, y, sw, sh = ctx.x, ctx.y, ctx.sw, ctx.sh
  local lcd, CENTER, RIGHT = ctx.lcd, ctx.CENTER, ctx.RIGHT
  
  -- Giant Timers font on 800x480 (XXLSIZE) / Double on 480x272
  local f_timer = (sw >= 600) and (ctx.f_xxl or XXLSIZE or (ctx.f_dbl or DBLSIZE)) or (ctx.f_dbl or DBLSIZE)
  -- refresh() already selects suitable fonts for each radio resolution.
  -- Do not replace SMLSIZE with the default font on 480 px radios.
  local f_dbl = ctx.f_dbl or DBLSIZE or 0
  local f_mid = ctx.f_mid or MIDSIZE or 0
  local f_sml = ctx.f_sml or SMLSIZE or 0
  local f_tiny = TINSIZE or f_sml
  local f_0 = ctx.f_0 or 0
  -- 1. Exact Reference Palette
  local C_BG         = lcd.RGB(42, 54, 70)    -- Dark slate navy background
  local C_PANEL      = lcd.RGB(48, 62, 78)    -- Button fill
  local C_BORDER     = lcd.RGB(68, 92, 118)   -- Button border
  local C_BOX_BORDER = lcd.RGB(55, 95, 140)   -- Model card thin blue outline
  local C_CYAN       = lcd.RGB(45, 175, 240)  -- Aircraft icon & text cyan
  local C_SCALE_BG   = lcd.RGB(95, 148, 185)  -- Trim ruler light cyan-blue background
  local C_SCALE_TICK = lcd.RGB(25, 42, 60)    -- Trim ruler dark tick marks
  local C_SLIDER     = lcd.RGB(15, 25, 38)    -- Trim slider dark block
  local C_TEXT       = lcd.RGB(230, 240, 250) -- Crisp white text
  local C_DIM        = lcd.RGB(150, 172, 195) -- Dim silver-grey
  local C_GREEN      = lcd.RGB(40, 205, 80)
  local C_YELLOW     = lcd.RGB(240, 190, 40)
  local C_RED        = lcd.RGB(255, 65, 65)

  -- Full Screen Solid Background
  lcd.drawFilledRectangle(x, y, sw, sh, C_BG)

  -- =========================================================================
  -- 2. Top Header Bar: Telemetry T + Cellular RSSI Signal Bars + RSSI/LQ Data
  -- =========================================================================
  -- (A) Top Left: Telemetry T + Cellular RSSI Signal Bars + RSSI/LQ (Replacing duplicate BEC/Ext voltage)
  local rssi_val = data.rssi or 0
  local lq_val = data.link_qual or 0
  local rssi_str = (rssi_val ~= 0) and string.format("%ddB", rssi_val) or "---"
  local lq_str = (lq_val > 0) and string.format("%d%%", lq_val) or "---"
  lcd.drawText(X(18), Y(16), "T", f_mid + C_CYAN)

  -- Cellular 4-Bar Signal Indicator (📶)
  local bars_lit = 0
  local sig_col = C_GREEN
  if data.telemetry or (rssi_val ~= 0) or (lq_val > 0) then
    local lq = (lq_val > 0) and lq_val or 100
    if lq >= 85 or (rssi_val >= -75 and rssi_val ~= 0) then
      bars_lit = 4
      sig_col = C_GREEN
    elseif lq >= 60 or rssi_val >= -90 then
      bars_lit = 3
      sig_col = C_GREEN
    elseif lq >= 35 or rssi_val >= -105 then
      bars_lit = 2
      sig_col = C_YELLOW
    else
      bars_lit = 1
      sig_col = C_RED
    end
  end

  local sig_x = X(42)
  local sig_base_y = Y(38)
  local bar_w = W(4)
  local bar_sp = 2
  local max_h = H(18)
  for b = 1, 4 do
    local bh = math.max(3, math.floor(max_h * (b / 4)))
    local bx = sig_x + (b - 1) * (bar_w + bar_sp)
    local by = sig_base_y - bh
    local b_col = (b <= bars_lit) and sig_col or C_BORDER
    lcd.drawFilledRectangle(bx, by, bar_w, bh, b_col)
  end

  -- Compact RSSI & Link Quality (LQ) indicators (SML font, no duplicate BEC/voltage)
  lcd.drawText(X(70), Y(18), "RSSI", f_sml + C_DIM)
  lcd.drawText(X(120), Y(18), rssi_str, f_sml + C_TEXT)
  lcd.drawText(X(70), Y(42), "LQ", f_sml + C_DIM)
  lcd.drawText(X(120), Y(42), lq_str, f_sml + C_TEXT)

  -- (A2) Version & Active Battery Watermark (Positioned in slot X(195~305), Y(16~60))
  local ver_str = "RBCT v1.0.9"
  local bat_idx = (w and w.last_bat_idx) or 1
  if bat_idx < 1 or bat_idx > 6 then bat_idx = 1 end
  local bat_tag = "BAT " .. tostring(bat_idx)
  if w and w.fleet_stats and w.fleet_stats[bat_idx] then
    local st = w.fleet_stats[bat_idx]
    bat_tag = string.format("BAT %d (%d/%dc)", bat_idx, st.today_count or 0, st.lifetime_cycles or 0)
  end
  lcd.drawText(X(248), Y(16), ver_str, CENTER + f_sml + C_DIM)

  local l_val = data.light_val or (w and w._last_s_val)
  if l_val ~= nil then
    local l_col = (data.light_active) and C_CYAN or C_DIM
    local l_str = tostring(l_val)
    if type(l_val) == "boolean" then l_str = l_val and "ON" or "OFF" end
    local l_txt = "LGT: " .. l_str
    lcd.drawText(X(180), Y(46), l_txt, f_sml + l_col)
    lcd.drawText(X(248), Y(46), bat_tag, f_sml + C_DIM)
  else
    lcd.drawText(X(248), Y(46), bat_tag, CENTER + f_sml + C_DIM)
  end

  -- (B) Top Center: MODEL 01 (Bold) & RadioMaster Logo & BANK 1
  local m_name = (data.modelName and data.modelName ~= "") and data.modelName or "MODEL 01"
  lcd.drawText(X(400), Y(2), m_name, CENTER + f_mid + C_TEXT)

  local cond_str = "BANK 1"
  if data.bank_str and data.bank_str ~= "" then
    cond_str = data.bank_str
  elseif _G.rf2 and _G.rf2.profile then
    cond_str = "PROFILE " .. tostring(_G.rf2.profile)
  end
  lcd.drawText(X(535), Y(22), cond_str, f_mid + C_TEXT)

  -- RadioMaster Official Logo (Hardware Bitmap with Text Fallback)
  local is_sml_radio = (sw < 600)
  local logo_w = is_sml_radio and 96 or 160
  local lx = X(400) - math.floor(logo_w / 2)
  local ly = is_sml_radio and Y(24) or Y(41)
  drawRmLogo(lcd, lx, ly, C_TEXT, is_sml_radio, f_mid)

  -- (C) Top Right: TX Battery Level (Large Segmented Green Grid) & Voltage
  local tx_v = data.txVoltage or 0
  local tx_min, tx_max = 6.0, 8.4
  if tx_v > 0 and tx_v < 5.0 then tx_min, tx_max = 3.0, 4.2 end
  local tx_pct = math.max(0, math.min(100, math.floor(((tx_v - tx_min) / math.max(0.1, tx_max - tx_min)) * 100)))
  
  local num_segs = 5
  local active_segs = math.max(0, math.min(num_segs, math.ceil((tx_pct / 100) * num_segs)))

  -- 3-Tier Dynamic Color (Green: 4~5 bars, Yellow: 2~3 bars, Red: 0~1 bar)
  local bat_col = C_GREEN
  if active_segs <= 1 or tx_pct <= 20 then
    bat_col = C_RED
  elseif active_segs <= 3 or tx_pct <= 55 then
    bat_col = C_YELLOW
  else
    bat_col = C_GREEN
  end

  local bx, by, bw, bh = 684, 12, 84, 30
  -- Nipple on right (Positive terminal)
  lcd.drawFilledRectangle(X(bx + bw), Y(by + 8), W(4), H(14), bat_col)
  -- Outer border
  lcd.drawRectangle(X(bx), Y(by), W(bw), H(bh), bat_col)
  -- 5 Segmented vertical bars inside
  local seg_w = math.floor((bw - 6 - (num_segs - 1) * 3) / num_segs)
  for s = 0, num_segs - 1 do
    local sx_pos = bx + 3 + s * (seg_w + 3)
    if s < active_segs then
      lcd.drawFilledRectangle(X(sx_pos), Y(by + 3), W(seg_w), H(bh - 6), bat_col)
    else
      lcd.drawRectangle(X(sx_pos), Y(by + 3), W(seg_w), H(bh - 6), C_BORDER)
    end
  end
  local tx_str = string.format("%.1fV", tx_v)
  lcd.drawText(X(bx + bw / 2), Y(by + bh + 4), tx_str, CENTER + f_mid + C_TEXT)

  -- =========================================================================
  -- 3. Giant Dual Displays: Left = Main Rotor RPM, Right = Flight Timer
  -- =========================================================================
  local rpm_val = (data.hspd and data.hspd > 50) and math.floor(data.hspd + 0.5) or 0
  local tail_rpm_val = (data.tspd and data.tspd > 50) and math.floor(data.tspd + 0.5) or 0
  local has_tail_rpm = tail_rpm_val > 0 or ((data.max_tspd or 0) > 0)
  local rpm_str = (rpm_val > 0) and string.format("%d", rpm_val) or "0"
  if has_tail_rpm then
    rpm_str = string.format("%05d /%05d", math.min(99999, rpm_val), math.min(99999, tail_rpm_val))
  end

  local timer_str = data.timer or "00:00.0"
  if string.find(timer_str, "%.") == nil and #timer_str == 5 then
    timer_str = timer_str .. ".0"
  end

  -- Left: main RPM, or "main / tail" when a tail RPM source is active.
  -- Select the largest font that keeps the complete string inside the same
  -- 275 px horizontal bounds as the telemetry cards below it.
  local rpm_font = f_timer
  local rpm_text_w = lcd.sizeText and select(1, lcd.sizeText(rpm_str, rpm_font)) or (#rpm_str * W(30))
  if has_tail_rpm then
    local rpm_max_w = W(275)
    if rpm_text_w > rpm_max_w then
      local rpm_fonts = { f_dbl, f_mid, f_sml, f_tiny }
      for i = 1, #rpm_fonts do
        local candidate = rpm_fonts[i]
        local candidate_w = lcd.sizeText and select(1, lcd.sizeText(rpm_str, candidate)) or (#rpm_str * W(12))
        rpm_font, rpm_text_w = candidate, candidate_w
        if candidate_w <= rpm_max_w then break end
      end
    end
  end
  local rpm_cx = X(256)
  if has_tail_rpm then
    local rpm_left, rpm_right = X(24), X(299)
    local half_w = math.floor(rpm_text_w / 2)
    rpm_cx = math.max(rpm_left + half_w, math.min(rpm_cx, rpm_right - half_w))
  end
  if has_tail_rpm then
    lcd.drawText(rpm_cx, Y(92), rpm_str, CENTER + rpm_font + C_TEXT)
  else
    -- Anchor the final digit to the left-column frame.
    lcd.drawText(X(299), Y(92), rpm_str, RIGHT + rpm_font + C_TEXT)
  end

  -- Right: Flight Timer. Anchor the final digit to the right-column frame.
  lcd.drawText(X(776), Y(92), timer_str, RIGHT + f_timer + C_TEXT)

  -- =========================================================================
  -- 4. Left Column: F-type telemetry/function stack from the MK3 reference
  -- =========================================================================
  local btn_x, btn_w = 24, 275
  local T = ctx.T or function(key) return key end
  local function statValue(index, mode, fallback)
    if ctx.stat then
      local ok, value = pcall(ctx.stat, index, mode)
      if ok and type(value) == "number" then return value end
    end
    return fallback or 0
  end
  local function asVolts(value)
    return (ctx.volts and ctx.volts(value)) or value
  end
  local function asAmps(value)
    return (ctx.amps and ctx.amps(value)) or value
  end

  -- Row 1: peak headspeed and controller temperature summary.
  local summary_y, summary_h = 188, 52
  drawRoundedPanel(lcd, X(btn_x), Y(summary_y), W(btn_w), H(summary_h), C_PANEL, C_BORDER)
  local max_hspd = statValue(3, "max", data.hspd)
  local mcu_temp = statValue(7, "cur", 0)
  lcd.drawText(X(btn_x + btn_w - 10), Y(summary_y + 10),
    string.format(T("head_spd_max"), max_hspd), RIGHT + f_tiny + C_TEXT)
  lcd.drawText(X(btn_x + btn_w - 10), Y(summary_y + 30),
    string.format(T("mcu_temp"), mcu_temp), RIGHT + f_tiny + C_TEXT)

  -- Row 2: Today / Total flight counters.
  local count_y, count_h = 248, 39
  drawRoundedPanel(lcd, X(btn_x), Y(count_y), W(btn_w), H(count_h), C_PANEL, C_BORDER)
  local today_c = (w and w.flight_count) or (data and data.flights_today) or 0
  local total_c = (w and w.lifetime_count) or (data and data.flights_total) or 0
  lcd.drawText(X(btn_x + 110), Y(count_y + 9), T("today_lbl") .. today_c, RIGHT + f_sml + C_TEXT)
  lcd.drawText(X(177), Y(count_y + 9), T("total_lbl") .. total_c, f_sml + C_TEXT)

  -- Row 3: four live electric telemetry cells.  Use the F-type palette instead
  -- of the pasted artwork's black background so this block belongs to the theme.
  local telem_y, telem_h = 295, 79
  local cell_w = math.floor(btn_w / 4)
  lcd.drawFilledRectangle(X(btn_x), Y(telem_y), W(btn_w), H(telem_h), C_PANEL)
  lcd.drawRectangle(X(btn_x), Y(telem_y), W(btn_w), H(telem_h), C_BORDER)
  for i = 1, 3 do
    lcd.drawLine(X(btn_x + i * cell_w), Y(telem_y), X(btn_x + i * cell_w), Y(telem_y + telem_h - 1), SOLID, C_BORDER)
  end
  -- These cells are only ~68 px wide.  Use dedicated compact labels instead
  -- of the full dashboard translations, which collide even at SMLSIZE.
  local ui_lang = ctx.ui_lang or "en"
  local titles
  if ui_lang == "tw" then
    titles = { "電流", "單電", "接收", "電變" }
  elseif ui_lang == "cn" then
    titles = { "电流", "单电", "接收", "电调" }
  else
    titles = { "AMPS", "Cell", "BEC", "ESC T" }
  end
  local values = {
    string.format("%.1f", data.curr or 0),
    string.format("%.2f", data.vcel or 0),
    string.format("%.1f", data.vbec or 0),
    string.format("%.0f", data.tesc or 0)
  }
  local units = { "A", "V", "V", "°C" }
  -- The bottom line intentionally contains values only.  At 68 px per cell,
  -- adding max/min text causes glyphs to cross the vertical dividers.
  local subs = {
    string.format("%.1fA", asAmps(statValue(2, "max", data.curr))),
    string.format("%.2fV", asVolts(statValue(15, "min", data.vcel))),
    string.format("%.1fV", asVolts(statValue(12, "min", data.vbec))),
    string.format("%.0f°C", statValue(6, "max", data.tesc))
  }
  for i = 1, 4 do
    local cx = btn_x + (i - 1) * cell_w + cell_w / 2
    local value_col = C_TEXT
    if i == 2 and (data.vcel or 0) > 0 and data.vcel < 3.5 then value_col = C_RED end
    if i == 4 and (data.tesc or 0) >= 60 then value_col = C_RED end
    lcd.drawText(X(cx), Y(telem_y + 6), titles[i], CENTER + f_tiny + C_DIM)

    -- Keep the numeric reading prominent but render its unit at SMLSIZE.
    -- Width-based placement keeps the mixed-font pair centered as values grow.
    local num_font = f_sml
    local num_w, num_h
    if lcd.sizeText then
      num_w, num_h = lcd.sizeText(values[i], num_font)
    else
      num_w, num_h = #values[i] * W(6), H(18)
    end
    local unit_w = lcd.sizeText and select(1, lcd.sizeText(units[i], f_tiny)) or (#units[i] * W(5))
    local value_gap = W(2)
    local available_w = math.max(1, W(cell_w) - W(6))
    if num_w + value_gap + unit_w > available_w or num_h > H(28) then
      num_font = f_tiny
      if lcd.sizeText then
        num_w = select(1, lcd.sizeText(values[i], num_font))
      else
        num_w = #values[i] * W(5)
      end
    end
    local value_x = X(cx) - math.floor((num_w + value_gap + unit_w) / 2)
    lcd.drawText(value_x, Y(telem_y + 30), values[i], num_font + value_col)
    lcd.drawText(value_x + num_w + value_gap, Y(telem_y + 35), units[i], f_tiny + value_col)
    lcd.drawText(X(cx), Y(telem_y + 58), subs[i], CENTER + f_tiny + C_DIM)
  end

  -- Row 4: information popup entry.
  local info_y, info_h = 382, 35
  drawRoundedPanel(lcd, X(btn_x), Y(info_y), W(btn_w), H(info_h), C_PANEL, C_BORDER)
  lcd.drawText(X(btn_x + btn_w / 2), Y(info_y + 7), "Information", CENTER + f_sml + C_TEXT)

  -- =========================================================================
  -- 5. Center Column: 4-Way Trims (T1~T4) - Shifted down by 20px
  -- =========================================================================
  local t_ail = getTrimValueFromRadio("Ail", 0)
  local t_ele = getTrimValueFromRadio("Ele", 1)
  local t_thr = getTrimValueFromRadio("Thr", 2)
  local t_rud = getTrimValueFromRadio("Rud", 3)

  local norm_ele = normalizeTrim(t_ele)
  local norm_thr = normalizeTrim(t_thr)
  local norm_ail = normalizeTrim(t_ail)
  local norm_rud = normalizeTrim(t_rud)

  -- (A) Upper Vertical Trims (Elevator T3 on left & Throttle T2 on right)
  local vt1_y, vt1_h = 206, 95
  local t3_x, t2_x = 358, 418
  local vt_w = 24

  -- Upper scale backgrounds (Light cyan-blue ruler)
  lcd.drawFilledRectangle(X(t3_x), Y(vt1_y), W(vt_w), H(vt1_h), C_SCALE_BG)
  lcd.drawFilledRectangle(X(t2_x), Y(vt1_y), W(vt_w), H(vt1_h), C_SCALE_BG)

  -- Upper scale tick marks
  for i = 0, 8 do
    local tk_y = Y(vt1_y + 6 + i * (vt1_h - 12) / 8)
    lcd.drawLine(X(t3_x + 1), tk_y, X(t3_x + vt_w - 2), tk_y, SOLID, C_SCALE_TICK)
    lcd.drawLine(X(t2_x + 1), tk_y, X(t2_x + vt_w - 2), tk_y, SOLID, C_SCALE_TICK)
  end

  local p_t3_y = Y(vt1_y + vt1_h / 2 - (norm_ele / 100) * (vt1_h / 2 - 6))
  local p_t2_y = Y(vt1_y + vt1_h / 2 - (norm_thr / 100) * (vt1_h / 2 - 6))
  lcd.drawFilledRectangle(X(t3_x), p_t3_y - 4, W(vt_w), H(8), C_SLIDER)
  lcd.drawFilledRectangle(X(t2_x), p_t2_y - 4, W(vt_w), H(8), C_SLIDER)

  -- Numbers for Upper Trims
  lcd.drawText(X(t3_x - 14), Y(vt1_y + 35), formatTrimNum(t_ele), RIGHT + f_sml + C_TEXT)
  lcd.drawText(X(t2_x + vt_w + 14), Y(vt1_y + 35), formatTrimNum(t_thr), f_sml + C_TEXT)

  -- (B) Lower Vertical Trims (Elevator & Throttle lower reference)
  local vt2_y, vt2_h = 316, 95
  lcd.drawFilledRectangle(X(t3_x), Y(vt2_y), W(vt_w), H(vt2_h), C_SCALE_BG)
  lcd.drawFilledRectangle(X(t2_x), Y(vt2_y), W(vt_w), H(vt2_h), C_SCALE_BG)
  for i = 0, 8 do
    local tk_y = Y(vt2_y + 6 + i * (vt2_h - 12) / 8)
    lcd.drawLine(X(t3_x + 1), tk_y, X(t3_x + vt_w - 2), tk_y, SOLID, C_SCALE_TICK)
    lcd.drawLine(X(t2_x + 1), tk_y, X(t2_x + vt_w - 2), tk_y, SOLID, C_SCALE_TICK)
  end
  local p_t3b_y = Y(vt2_y + vt2_h / 2 - (norm_ele / 100) * (vt2_h / 2 - 6))
  local p_t2b_y = Y(vt2_y + vt2_h / 2 - (norm_thr / 100) * (vt2_h / 2 - 6))
  lcd.drawFilledRectangle(X(t3_x), p_t3b_y - 4, W(vt_w), H(8), C_SLIDER)
  lcd.drawFilledRectangle(X(t2_x), p_t2b_y - 4, W(vt_w), H(8), C_SLIDER)

  lcd.drawText(X(t3_x - 14), Y(vt2_y + 35), formatTrimNum(t_ele), RIGHT + f_sml + C_TEXT)
  lcd.drawText(X(t2_x + vt_w + 14), Y(vt2_y + 35), formatTrimNum(t_thr), f_sml + C_TEXT)

  -- (C) Bottom Horizontal Trims: T1 & T4 (Horizontally aligned with Left/Right numbers)
  local ht_w, ht_h = 115, 16
  local t1_x, t4_x = 265, 420
  local ht_y = 444

  lcd.drawFilledRectangle(X(t1_x), Y(ht_y), W(ht_w), H(ht_h), C_SCALE_BG)
  lcd.drawFilledRectangle(X(t4_x), Y(ht_y), W(ht_w), H(ht_h), C_SCALE_BG)
  for i = 0, 8 do
    local tk1_x = X(t1_x + 6 + i * (ht_w - 12) / 8)
    local tk4_x = X(t4_x + 6 + i * (ht_w - 12) / 8)
    lcd.drawLine(tk1_x, Y(ht_y + 2), tk1_x, Y(ht_y + ht_h - 3), SOLID, C_SCALE_TICK)
    lcd.drawLine(tk4_x, Y(ht_y + 2), tk4_x, Y(ht_y + ht_h - 3), SOLID, C_SCALE_TICK)
  end

  local p_t1_x = X(t1_x + ht_w / 2 + (norm_ail / 100) * (ht_w / 2 - 8))
  local p_t4_x = X(t4_x + ht_w / 2 + (norm_rud / 100) * (ht_w / 2 - 8))
  lcd.drawFilledRectangle(p_t1_x - 4, Y(ht_y), W(8), H(ht_h), C_SLIDER)
  lcd.drawFilledRectangle(p_t4_x - 4, Y(ht_y), W(8), H(ht_h), C_SLIDER)

  lcd.drawText(X(t1_x + ht_w / 2), Y(ht_y - 20), formatTrimNum(t_ail), CENTER + f_sml + C_TEXT)
  lcd.drawText(X(t4_x + ht_w / 2), Y(ht_y - 20), formatTrimNum(t_rud), CENTER + f_sml + C_TEXT)

  -- =========================================================================
  -- 6. Right Column: Wide Model Picture Card (W: 275px matching Left Column) & Status Badges
  -- =========================================================================
  local rc_x, rc_w = 501, 275
  local m_card_y, m_card_h = 194, 118

  -- Model Picture Card (Thin Outline Box)
  lcd.drawFilledRectangle(X(rc_x), Y(m_card_y), W(rc_w), H(m_card_h), C_PANEL)
  lcd.drawRectangle(X(rc_x), Y(m_card_y), W(rc_w), H(m_card_h), C_BOX_BORDER)
  
  -- Render the actual model thumbnail at the card's physical pixel bounds.
  local has_drawn_model_img = false
  if ctx.heli_pic then
    local img = ctx.heli_pic
    local img_w, img_h = W(250), H(100)
    local scale_pct = 100
    local bitmap_size_api = nil
    if Bitmap and Bitmap.getSize then bitmap_size_api = Bitmap
    elseif bitmap and bitmap.getSize then bitmap_size_api = bitmap end
    if bitmap_size_api then
      local bw, bh = bitmap_size_api.getSize(img)
      if bw and bh and bw > 0 and bh > 0 then
        local max_w = W(256)
        local max_h = H(106)
        local sw_pct = (max_w / bw) * 100
        local sh_pct = (max_h / bh) * 100
        scale_pct = math.min(100, math.floor(math.min(sw_pct, sh_pct)))
        img_w = math.floor(bw * (scale_pct / 100))
        img_h = math.floor(bh * (scale_pct / 100))
      end
    end
    local draw_ix = X(rc_x + rc_w / 2) - math.floor(img_w / 2)
    local draw_iy = Y(m_card_y + 6) + math.floor((H(106) - img_h) / 2)
    if drawBitmapImg then
      drawBitmapImg(lcd, draw_ix, draw_iy, img, scale_pct)
      has_drawn_model_img = true
    end
  end

  if not has_drawn_model_img then
    local is_heli = not data.is_turbine_mode
    drawAircraftSilhouette(lcd, X(rc_x + rc_w / 2), Y(m_card_y + 59), is_heli, C_CYAN)
  end

  -- =========================================================================
  -- Dual Badges (GOV & STATUS) and Battery % Card matching Image 2
  -- =========================================================================
  local badge_y = 320
  local hdr_h = 22
  local body_h = 40
  local card_w = math.floor((rc_w - 9) / 2) -- 133px each
  local g_x = rc_x
  local s_x = rc_x + card_w + 9

  -- (1) Left Badge: GOV (Header + Colored Status Block)
  lcd.drawFilledRectangle(X(g_x), Y(badge_y), W(card_w), H(hdr_h), C_PANEL)
  lcd.drawRectangle(X(g_x), Y(badge_y), W(card_w), H(hdr_h), C_BORDER)
  lcd.drawText(X(g_x + card_w / 2), Y(badge_y + 2), "GOV", CENTER + f_sml + C_TEXT)

  local gov_col = data.gov_on and C_GREEN or C_RED
  local gov_txt = data.gov_on and "ON" or "OFF"
  lcd.drawFilledRectangle(X(g_x), Y(badge_y + hdr_h), W(card_w), H(body_h), gov_col)
  lcd.drawRectangle(X(g_x), Y(badge_y + hdr_h), W(card_w), H(body_h), C_BORDER)
  -- 3D Text with Drop Shadow (Shifted up to visual center)
  lcd.drawText(X(g_x + card_w / 2) + 1, Y(badge_y + hdr_h + 1) + 1, gov_txt, CENTER + f_mid + C_SLIDER)
  lcd.drawText(X(g_x + card_w / 2), Y(badge_y + hdr_h + 1), gov_txt, CENTER + f_mid + C_TEXT)

  -- (2) Right Badge: STATUS (Header + Colored Status Block)
  lcd.drawFilledRectangle(X(s_x), Y(badge_y), W(card_w), H(hdr_h), C_PANEL)
  lcd.drawRectangle(X(s_x), Y(badge_y), W(card_w), H(hdr_h), C_BORDER)
  lcd.drawText(X(s_x + card_w / 2), Y(badge_y + 2), "STATUS", CENTER + f_sml + C_TEXT)

  local stat_col = C_GREEN
  local stat_txt = "SAFE"
  if data.rescue_active then
    local flash_on = (math.floor(getTime() / 20) % 2) == 0
    stat_col = flash_on and C_RED or C_SLIDER
    stat_txt = "RESCUE!"
  elseif data.arm_on then
    stat_col = C_RED
    stat_txt = "ARMED"
  else
    stat_col = C_GREEN
    stat_txt = "SAFE"
  end

  lcd.drawFilledRectangle(X(s_x), Y(badge_y + hdr_h), W(card_w), H(body_h), stat_col)
  lcd.drawRectangle(X(s_x), Y(badge_y + hdr_h), W(card_w), H(body_h), C_BORDER)
  -- 3D Text with Drop Shadow (Shifted up to visual center)
  lcd.drawText(X(s_x + card_w / 2) + 1, Y(badge_y + hdr_h + 1) + 1, stat_txt, CENTER + f_mid + C_SLIDER)
  lcd.drawText(X(s_x + card_w / 2), Y(badge_y + hdr_h + 1), stat_txt, CENTER + f_mid + C_TEXT)

  -- (3) Bottom Battery % Box. Its bottom aligns with the left Information box.
  local bat_box_y = 388
  local bat_box_h = 29
  lcd.drawFilledRectangle(X(rc_x), Y(bat_box_y), W(rc_w), H(bat_box_h), C_PANEL)
  lcd.drawRectangle(X(rc_x), Y(bat_box_y), W(rc_w), H(bat_box_h), C_BOX_BORDER)

  local pct_val = math.max(0, math.min(100, math.floor(data.bat_pct or 0)))
  local pct_str = string.format("%d %%", pct_val)
  lcd.drawText(X(rc_x + rc_w / 2), Y(bat_box_y + 4), pct_str, CENTER + f_sml + C_TEXT)

  -- =========================================================================
  -- 7. Bottom Status Bar: Left = Radio Powered-on Uptime (已開機時間), Right = Date & Time
  -- =========================================================================
  local bot_y = 444
  local total_sec = math.floor(getTime() / 100)
  local hrs = math.floor(total_sec / 3600)
  local mins = math.floor((total_sec % 3600) / 60)
  local secs = total_sec % 60
  local uptime_str = string.format("%02d:%02d:%02d", hrs, mins, secs)
  lcd.drawText(X(24), Y(bot_y), uptime_str, f_0 + C_TEXT)

  local dt = getDateTime()
  local date_full = string.format("'%02d/%02d/%02d %d:%02d", (dt.year or 2026) % 100, dt.mon or 1, dt.day or 1, dt.hour or 0, dt.min or 0)
  lcd.drawText(X(776), Y(bot_y), date_full, RIGHT + f_0 + C_TEXT)
end

local function handleTouch(w, tx, ty, ctx)
  local X, Y = ctx.X, ctx.Y
  local now_t = getTime()

  -- Peak summary -> headspeed/power chart.
  if tx >= X(24) and tx <= X(300) and ty >= Y(188) and ty <= Y(240) then
    w.active_popup = "power_stats"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 2200, 80, 50, 0) end
    return true
  end

  -- Flight counters -> session statistics/reset.
  if tx >= X(24) and tx <= X(300) and ty >= Y(248) and ty <= Y(287) then
    w.active_popup = "session_stats"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 1500, 80, 50, 0) end
    return true
  end

  -- Four-cell telemetry card -> battery health.
  if tx >= X(24) and tx <= X(300) and ty >= Y(295) and ty <= Y(374) then
    w.active_popup = "battery"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 2000, 80, 50, 0) end
    return true
  end

  -- Information -> comprehensive telemetry popup.
  if tx >= X(24) and tx <= X(300) and ty >= Y(382) and ty <= Y(417) then
    w.active_popup = "telemetry_info"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 1600, 80, 50, 0) end
    return true
  end

  -- Right Model Card stack -> Opens Headspeed & Power Chart
  if tx >= X(501) and tx <= X(776) and ty >= Y(194) and ty <= Y(417) then
    w.active_popup = "power_stats"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 2200, 80, 50, 0) end
    return true
  end

  -- Top Right Battery Area (X: 680..780, Y: 10..76) -> Opens Battery Health Popup
  if tx >= X(680) and tx <= X(780) and ty >= Y(10) and ty <= Y(76) then
    w.active_popup = "battery"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 2000, 80, 50, 0) end
    return true
  end

  -- Top Watermark Area (X: 190..305, Y: 10..65) -> Cycles Active Battery 1~6
  if tx >= X(190) and tx <= X(305) and ty >= Y(10) and ty <= Y(65) then
    w.manual_bat_idx = ((w.last_bat_idx or 1) % 6) + 1
    w.last_bat_idx = w.manual_bat_idx
    w.bat_prompt_timer = now_t
    w.log_loaded = false
    w.fleet_data = nil
    if playTone then pcall(playTone, 2200, 100, 50, 0) end
    return true
  end

  -- Bottom Left Uptime (X: 20..200, Y: 430..475) -> Opens Session Stats (Flight Counts / Reset)
  if tx >= X(20) and tx <= X(200) and ty >= Y(430) and ty <= Y(475) then
    w.active_popup = "session_stats"
    w.popup_open_t = now_t
    if playTone then pcall(playTone, 1500, 80, 50, 0) end
    return true
  end

  return false
end

return {
  draw = draw,
  handleTouch = handleTouch
}
