-- RBCT Logbook & Battery Fleet Manager Module
-- Author: 雷恩 / Ryan Kuo
-- Supports: TX16S MK3 (800x480), TX16S MKII (480x272), TX15 MAX (480x320)
-- Ultra-Light Performance Architecture (Guaranteed Zero CPU-Limit)

local basePath = "/WIDGETS/RBCT"

local function loadFleetData(w, ctx)
  w.fleet_data = {}
  local modelName = ctx.modelName or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w%-_]", "_")

  for i = 1, 6 do
    local data = { id = i, cycles = 0, min_v = "-", max_t = "-", avg_dur = "-" }
    local logPath = basePath .. "/log_" .. cleanName .. "_bat" .. i .. ".txt"
    if not (fstat and fstat(logPath)) then
      logPath = basePath .. "/log_" .. cleanName .. "_BAT" .. i .. ".txt"
    end
    if not (fstat and fstat(logPath)) and i == 1 then
      logPath = basePath .. "/log_" .. cleanName .. ".txt"
    end

    local f1 = io.open(logPath, "r")
    if f1 then
      local c = io.read(f1, 100) or ""
      io.close(f1)
      local parts = {}
      for p in string.gmatch(c, "[^,]+") do table.insert(parts, p) end
      if #parts >= 3 then data.cycles = tonumber(parts[3]) or 0 end
    end

    local lbPath = basePath .. "/logbook_" .. cleanName .. "_bat" .. i .. ".txt"
    if not (fstat and fstat(lbPath)) then
      lbPath = basePath .. "/logbook_" .. cleanName .. "_BAT" .. i .. ".txt"
    end
    if not (fstat and fstat(lbPath)) and i == 1 then
      lbPath = basePath .. "/logbook_" .. cleanName .. ".txt"
    end

    local f2 = io.open(lbPath, "r")
    if f2 then
      local c2 = io.read(f2, 2048) or ""
      io.close(f2)
      local min_v = 999
      local max_t = 0
      local tot_dur_s = 0
      local flights = 0
      for line in string.gmatch(c2, "[^\r\n]+") do
        if string.len(line) > 5 then
          local parts = {}
          for p in string.gmatch(line, "[^,]+") do table.insert(parts, p) end
          if #parts >= 8 then
            local dur = parts[2]
            local m, s = string.match(dur, "(%d+):(%d+)")
            if m and s then
              tot_dur_s = tot_dur_s + tonumber(m) * 60 + tonumber(s)
              flights = flights + 1
            end
            local v = tonumber(parts[5])
            if v and v < min_v then min_v = v end
            local t = tonumber(parts[7])
            if t and t > max_t then max_t = t end
          end
        end
      end
      if flights > 0 then
        data.min_v = string.format("%.2f", min_v)
        data.max_t = string.format("%.0f", max_t)
        local avg_s = math.floor(tot_dur_s / flights)
        data.avg_dur = string.format("%02d:%02d", math.floor(avg_s / 60), avg_s % 60)
      end
    end
    table.insert(w.fleet_data, data)
  end
end

local function computeChartScales(data)
  local max_rpm = 2500
  local max_v, min_v = 55, 40
  local max_a = 150
  local max_b, min_b = 9.0, 6.0
  local max_t, min_t = 100, 20

  if data and #data >= 2 then
    local peak_rpm, peak_v, lowest_v, peak_a, peak_b, lowest_b, peak_t = 0, 0, 999, 0, 0, 999, 0

    for i = 1, #data do
      local p = data[i]
      if type(p) == "table" then
        local r = p.r or (p[1] or 0)
        local v = p.v or (p[2] or 0)
        local a = p.a or (p[3] or 0)
        local b = p.b or (p[4] or 0)
        local t = p.t or (p[5] or 0)
        if r > peak_rpm then peak_rpm = r end
        if v > peak_v then peak_v = v end
        if v > 0 and v < lowest_v then lowest_v = v end
        if a > peak_a then peak_a = a end
        if b > peak_b then peak_b = b end
        if b > 0 and b < lowest_b then lowest_b = b end
        if t > peak_t then peak_t = t end
      end
    end

    if peak_rpm > 0 then
      max_rpm = math.max(2000, math.ceil(peak_rpm / 500) * 500)
    end

    if peak_v > 30 then
      max_v, min_v = 55, 40
    elseif peak_v > 15 then
      max_v, min_v = 26, 20
    elseif peak_v > 0 then
      max_v, min_v = 13, 6
    end

    if peak_a > 0 then
      max_a = math.max(50, math.ceil(peak_a / 50) * 50)
    end

    if peak_t > 0 then
      max_t = math.max(80, math.ceil(peak_t / 20) * 20)
    end

    if peak_b > 0 and peak_b <= 6.5 then
      max_b, min_b = 6.5, 4.5
    else
      max_b, min_b = 9.0, 6.0
    end
  end

  return {
    max_rpm = max_rpm, max_v = max_v, min_v = min_v,
    max_a = max_a, max_b = max_b, min_b = min_b,
    max_t = max_t, min_t = min_t,
    str_max_rpm = string.format("%.0f", max_rpm),
    str_max_v = string.format("%.0fV", max_v),
    str_min_v = string.format("%.0fV", min_v),
    str_max_a = string.format("%.0fA", max_a),
    str_max_t = string.format("%.0f°", max_t),
    str_min_t = string.format("%.0f°", min_t),
    str_max_b = string.format("%.1fV", max_b),
    str_min_b = string.format("%.1fV", min_b)
  }
end

local function drawLogbook(w, ctx)
  local lcd, C, f_mid, f_sml = ctx.lcd, ctx.C, ctx.f_mid, ctx.f_sml
  local x, y, sw, sh = ctx.x, ctx.y, ctx.sw, ctx.sh
  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H
  local CENTER = ctx.CENTER or rawget(_G, "CENTER") or rawget(_G, "CENTERED") or 2
  local RIGHT = ctx.RIGHT or rawget(_G, "RIGHT") or 16
  local T = ctx.T or function(k) return k end

  -- Solid backdrop
  lcd.drawFilledRectangle(x, y, sw, sh, C.bg)
  lcd.drawRectangle(x, y, sw, sh, C.blue)

  -- =========================================================================
  -- TAB 2: BATTERY FLEET MANAGER
  -- =========================================================================
  if w.logbook_tab == 2 then
    if not w.fleet_data then loadFleetData(w, ctx) end
    lcd.drawText(X(400), Y(16), T("fleet_mgr"), CENTER + f_mid + C.white)

    local activeBatIdx = w.last_bat_idx or 0

    lcd.drawLine(X(20), Y(50), X(780), Y(50), SOLID, C.panel2)
    local cols = { 100, 250, 400, 550, 700 }
    lcd.drawText(X(cols[1]), Y(58), T("tbl_bat_num"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[2]), Y(58), T("tbl_cycles"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[3]), Y(58), T("tbl_min_v"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[4]), Y(58), T("tbl_max_t"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[5]), Y(58), T("tbl_avg_dur"), CENTER + f_sml + C.dim)
    lcd.drawLine(X(20), Y(86), X(780), Y(86), SOLID, C.panel2)

    local fleet = w.fleet_data or {}
    for i = 1, math.min(6, #fleet) do
      local data = fleet[i]
      if data then
        local py = Y(90 + (i - 1) * 55)
        local is_active = (i == activeBatIdx)

        if is_active then
          lcd.drawFilledRectangle(X(20), py, W(760), H(50), C.panel2)
          lcd.drawRectangle(X(20), py, W(760), H(50), C.blue)
        elseif i % 2 == 1 then
          lcd.drawFilledRectangle(X(20), py, W(760), H(50), C.panel)
        end

        local color = is_active and C.green or C.white
        lcd.drawText(X(cols[1]), py + H(14), "BAT " .. i, CENTER + f_mid + color)
        lcd.drawText(X(cols[2]), py + H(14), tostring(data.cycles), CENTER + f_mid + C.white)

        local mv_num = tonumber(data.min_v)
        local mv_col = (mv_num and mv_num < 3.5) and C.red or C.white
        lcd.drawText(X(cols[3]), py + H(14), data.min_v .. (data.min_v ~= "-" and "V" or ""), CENTER + f_mid + mv_col)
        lcd.drawText(X(cols[4]), py + H(14), data.max_t .. (data.max_t ~= "-" and "°C" or ""), CENTER + f_mid + C.white)
        lcd.drawText(X(cols[5]), py + H(14), data.avg_dur, CENTER + f_mid + C.white)
      end
    end

  -- =========================================================================
  -- TAB 1: FLIGHT LOGBOOK & COMPACT PERFORMANCE CHART
  -- =========================================================================
  else
    lcd.drawText(X(400), Y(16), T("logbook_title"), CENTER + f_mid + C.white)

    if w.is_demo_data then
      lcd.drawFilledRectangle(X(670), Y(10), W(100), H(32), C.red)
      lcd.drawText(X(720), Y(16), "DEMO", CENTER + f_sml + C.white)
    end

    lcd.drawLine(X(20), Y(50), X(780), Y(50), SOLID, C.panel2)

    local cols = { 55, 135, 215, 295, 380, 465, 550, 635, 725 }
    lcd.drawText(X(cols[1]), Y(58), T("hdr_time"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[2]), Y(58), T("hdr_dur"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[3]), Y(58), T("hdr_max_rpm"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[4]), Y(58), T("hdr_max_a"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[5]), Y(58), T("hdr_max_pwr"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[6]), Y(58), T("hdr_min_v"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[7]), Y(58), T("hdr_min_bec"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[8]), Y(58), T("hdr_max_tmp"), CENTER + f_sml + C.dim)
    lcd.drawText(X(cols[9]), Y(58), T("hdr_mah"), CENTER + f_sml + C.dim)
    lcd.drawLine(X(20), Y(86), X(780), Y(86), SOLID, C.panel2)

    local entries_to_draw = w.log_entries
    if (not entries_to_draw or #entries_to_draw == 0) and w.is_demo_data then
      entries_to_draw = {
        { "14:30", "04:15", "2250", "125.4", "44.20", "7.95", "82", "3100", "3250" }
      }
    end

    local max_rows = (sh < 300) and 2 or 4
    local count = math.min(max_rows, #(entries_to_draw or {}))
    for i = 1, count do
      local py = Y(92 + (i - 1) * 32)

      if i % 2 == 1 then
        lcd.drawFilledRectangle(X(20), Y(88 + (i - 1) * 32), W(760), H(30), C.panel)
      end

      local parts = entries_to_draw[i]
      if type(parts) == "table" and #parts >= 8 then
        local amp_str = parts[4]
        local a_num = tonumber(parts[4])
        if a_num then amp_str = string.format("%.1f", a_num) end

        local pwr_val = parts[9] and tonumber(parts[9]) or 0
        local pwr_str = "---"
        if pwr_val >= 1000 then
          pwr_str = string.format("%.1fkW", pwr_val / 1000)
        elseif pwr_val >= 30 then
          pwr_str = string.format("%.0fW", pwr_val)
        end

        lcd.drawText(X(cols[1]), py, parts[1], CENTER + f_sml + C.white)
        lcd.drawText(X(cols[2]), py, parts[2], CENTER + f_sml + C.white)
        lcd.drawText(X(cols[3]), py, parts[3], CENTER + f_sml + C.white)
        lcd.drawText(X(cols[4]), py, amp_str, CENTER + f_sml + C.white)
        lcd.drawText(X(cols[5]), py, pwr_str, CENTER + f_sml + C.white)
        lcd.drawText(X(cols[6]), py, parts[5], CENTER + f_sml + C.white)
        lcd.drawText(X(cols[7]), py, parts[6], CENTER + f_sml + C.white)
        lcd.drawText(X(cols[8]), py, parts[7] .. "°", CENTER + f_sml + C.white)
        lcd.drawText(X(cols[9]), py, parts[8], CENTER + f_sml + C.white)
      end
    end

    if not entries_to_draw or #entries_to_draw == 0 then
      lcd.drawText(X(400), Y(110), T("no_flight_data"), CENTER + f_sml + C.dim)
    end

    -- Chart Title & Legends
    lcd.drawText(X(20), Y(230), T("last_chart"), f_sml + C.white)

    lcd.drawFilledRectangle(X(290), Y(235), W(10), H(10), C.green)
    lcd.drawText(X(308), Y(230), T("pop_leg_rpm"), f_sml + C.white)
    lcd.drawFilledRectangle(X(380), Y(235), W(10), H(10), C.orange)
    lcd.drawText(X(398), Y(230), T("pop_leg_volt"), f_sml + C.white)
    lcd.drawFilledRectangle(X(470), Y(235), W(10), H(10), C.red)
    lcd.drawText(X(488), Y(230), T("pop_leg_amps"), f_sml + C.white)
    lcd.drawFilledRectangle(X(560), Y(235), W(10), H(10), C.blue)
    lcd.drawText(X(578), Y(230), T("pop_leg_bec"), f_sml + C.white)
    lcd.drawFilledRectangle(X(650), Y(235), W(10), H(10), C.cyan or C.yellow)
    lcd.drawText(X(668), Y(230), T("pop_leg_temp"), f_sml + C.white)

    lcd.drawLine(X(20), Y(255), X(780), Y(255), SOLID, C.panel2)

    local cx, cw = 50, 660
    local cy1, ch1 = 270, 95
    local cy2, ch2 = 380, 75

    lcd.drawRectangle(X(cx), Y(cy1), W(cw), H(ch1), C.panel2)
    lcd.drawLine(X(cx), Y(cy1 + math.floor(ch1 / 2)), X(cx + cw), Y(cy1 + math.floor(ch1 / 2)), SOLID, C.panel)
    lcd.drawRectangle(X(cx), Y(cy2), W(cw), H(ch2), C.panel2)

    -- Generate demo points if no real flight chart recorded
    if not w.chart_data or #w.chart_data < 2 then
      w.is_demo_data = true
      w.chart_data = {}
      for i = 1, 24 do
        local rpm = (i > 2 and i < 22) and 2200 or 0
        local volt = (i < 2 or i > 22) and 50.0 or (50.0 - (i / 24) * 6.0)
        local amp = (i > 2 and i < 22) and 45.0 or 0
        local bec = 8.4
        local tmp = 40 + (i / 24) * 35
        w.chart_data[i] = { v = volt, a = amp, r = rpm, b = bec, t = tmp }
      end
      w._scales_cache = nil
    end

    local data = w.chart_data
    local len = data and #data or 0

    -- Compute scales only when data array changes
    if not w._scales_cache or w._scales_data_len ~= len then
      w._scales_cache = computeChartScales(data)
      w._scales_data_len = len
    end
    local sc = w._scales_cache

    local base_y1 = cy1 + ch1
    local base_y2 = cy2 + ch2

    -- Pre-calculated scale markers
    lcd.drawText(X(cx - 5), Y(cy1 - 5), sc.str_max_rpm, RIGHT + f_sml + C.green)
    lcd.drawText(X(cx - 5), Y(base_y1 - 15), "0", RIGHT + f_sml + C.green)
    lcd.drawText(X(cx + cw + 5), Y(cy1 - 5), sc.str_max_v, f_sml + C.orange)
    lcd.drawText(X(cx + cw + 5), Y(base_y1 - 15), sc.str_min_v, f_sml + C.orange)
    lcd.drawText(X(795), Y(cy1 - 5), sc.str_max_a, RIGHT + f_sml + C.red)
    lcd.drawText(X(795), Y(base_y1 - 15), "0A", RIGHT + f_sml + C.red)

    lcd.drawText(X(cx - 5), Y(cy2 - 5), sc.str_max_t, RIGHT + f_sml + (C.cyan or C.yellow))
    lcd.drawText(X(cx - 5), Y(base_y2 - 15), sc.str_min_t, RIGHT + f_sml + (C.cyan or C.yellow))
    lcd.drawText(X(cx + cw + 5), Y(cy2 - 5), sc.str_max_b, f_sml + C.blue)
    lcd.drawText(X(cx + cw + 5), Y(base_y2 - 15), sc.str_min_b, f_sml + C.blue)

    -- Ultra-Lightweight 20-Point Single-Stroke Renderer (Total line calls <= 95)
    if len >= 2 then
      local max_points = (sh < 300) and 16 or 22
      local draw_len = math.min(len, max_points)
      local stride = (len - 1) / (draw_len - 1)
      local step = cw / (draw_len - 1)
      local px, pyr, pyv, pya, pyb, pyt

      local max_rpm, max_v, min_v = sc.max_rpm, sc.max_v, sc.min_v
      local max_a, max_b, min_b = sc.max_a, sc.max_b, sc.min_b
      local max_t, min_t = sc.max_t, sc.min_t

      local span_v = math.max(1, max_v - min_v)
      local span_b = math.max(0.1, max_b - min_b)
      local span_t = math.max(1, max_t - min_t)

      for i = 1, draw_len do
        local data_idx = math.max(1, math.min(len, math.floor(1 + (i - 1) * stride + 0.5)))
        local scr_x = X(cx + (i - 1) * step)

        local p = data[data_idx]
        local r_val = p and (p.r or p[1]) or 0
        local v_val = p and (p.v or p[2]) or 0
        local a_val = p and (p.a or p[3]) or 0
        local b_val = p and (p.b or p[4]) or 0
        local t_val = p and (p.t or p[5]) or 0

        local scr_yr = Y(base_y1 - (math.max(0, math.min(max_rpm, r_val)) / max_rpm) * ch1)
        local scr_yv = Y(base_y1 - (math.max(0, math.min(span_v, v_val - min_v)) / span_v) * ch1)
        local scr_ya = Y(base_y1 - (math.max(0, math.min(max_a, a_val)) / max_a) * ch1)
        local scr_yb = Y(base_y2 - (math.max(0, math.min(span_b, b_val - min_b)) / span_b) * ch2)
        local scr_yt = Y(base_y2 - (math.max(0, math.min(span_t, t_val - min_t)) / span_t) * ch2)

        if i > 1 then
          lcd.drawLine(px, pyr, scr_x, scr_yr, SOLID, C.green)
          lcd.drawLine(px, pyv, scr_x, scr_yv, SOLID, C.orange)
          lcd.drawLine(px, pya, scr_x, scr_ya, SOLID, C.red)
          lcd.drawLine(px, pyb, scr_x, scr_yb, SOLID, C.blue)
          lcd.drawLine(px, pyt, scr_x, scr_yt, SOLID, C.cyan or C.yellow)
        end
        px, pyr, pyv, pya, pyb, pyt = scr_x, scr_yr, scr_yv, scr_ya, scr_yb, scr_yt
      end
    end
  end
end

return { drawLogbook = drawLogbook }

