local basePath = "/WIDGETS/RBCT"

local function loadFleetData(w, ctx)
  w.fleet_data = {}
  local modelName = ctx.modelName or "UNKNOWN"
  local cleanName = string.gsub(modelName, "[^%w]", "_")
  for i = 1, 6 do
    local data = { id = i, cycles = 0, min_v = "-", max_t = "-", avg_dur = "-" }
    local logPath = basePath .. "/log_" .. cleanName .. "_BAT" .. i .. ".txt"
    local f1 = io.open(logPath, "r")
    if f1 then
      local c = io.read(f1, 100) or ""
      io.close(f1)
      local parts = {}
      for p in string.gmatch(c, "[^,]+") do table.insert(parts, p) end
      if #parts >= 3 then data.cycles = tonumber(parts[3]) or 0 end
    end
    
    local lbPath = basePath .. "/logbook_" .. cleanName .. "_BAT" .. i .. ".txt"
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
              tot_dur_s = tot_dur_s + tonumber(m)*60 + tonumber(s)
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

local function calculateChartScales(data)
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

  return max_rpm, max_v, min_v, max_a, max_b, min_b, max_t, min_t
end

local function drawLogbook(w, ctx)
  local lcd, C, f_mid, f_sml, is_trn, is_transp = ctx.lcd, ctx.C, ctx.f_mid, ctx.f_sml, ctx.is_trn, ctx.is_transp
  local x, y, sw, sh, sx, sy = ctx.x, ctx.y, ctx.sw, ctx.sh, ctx.sx, ctx.sy
  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H

  -- Logbook & Battery Manager require solid background for high contrast readability
  lcd.drawFilledRectangle(x, y, sw, sh, C.bg)
  lcd.drawRectangle(x, y, sw, sh, C.blue)
  
  if w.logbook_tab == 2 then
    if not w.fleet_data then loadFleetData(w, ctx) end
    lcd.drawText(X(400), Y(20), "BATTERY FLEET MANAGER", CENTER + f_mid + C.white)
    
    local activeBatIdx = w.last_bat_idx or 0
    
    lcd.drawLine(X(20), Y(55), X(780), Y(55), SOLID, C.panel2)
    local cols = { 100, 250, 400, 550, 700 }
    local headers = { "BAT #", "CYCLES", "MIN VOLT", "MAX TMP", "AVG DUR" }
    for i = 1, 5 do
      lcd.drawText(X(cols[i]), Y(65), headers[i], CENTER + f_sml + C.dim)
    end
    lcd.drawLine(X(20), Y(95), X(780), Y(95), SOLID, C.panel2)
    
    for i = 1, 6 do
      local data = w.fleet_data[i]
      if data then
        local py = Y(95 + (i-1)*55)
        local is_active = (i == activeBatIdx)
        
        if is_active then
          lcd.drawFilledRectangle(X(20), py, W(760), H(50), C.panel2)
        end
        
        local color = is_active and C.green or C.white
        lcd.drawText(X(cols[1]), py + H(15), "BAT " .. i, CENTER + f_mid + color)
        lcd.drawText(X(cols[2]), py + H(15), tostring(data.cycles), CENTER + f_mid + C.white)
        
        local mv_num = tonumber(data.min_v)
        local mv_col = (mv_num and mv_num < 3.5) and C.red or C.white
        lcd.drawText(X(cols[3]), py + H(15), data.min_v .. (data.min_v ~= "-" and "V" or ""), CENTER + f_mid + mv_col)
        
        lcd.drawText(X(cols[4]), py + H(15), data.max_t .. (data.max_t ~= "-" and "°" or ""), CENTER + f_mid + C.white)
        lcd.drawText(X(cols[5]), py + H(15), data.avg_dur, CENTER + f_mid + C.white)
      end
    end
  else
    lcd.drawText(X(400), Y(20), "FLIGHT LOGBOOK", CENTER + f_mid + C.white)
  
    if w.is_demo_data then
      lcd.drawFilledRectangle(X(670), Y(12), W(100), H(35), C.red)
      lcd.drawText(X(720), Y(19), "DEMO", CENTER + f_sml + C.white)
    end

    lcd.drawLine(X(20), Y(55), X(780), Y(55), SOLID, C.panel2)
    
    local cols = { 50, 140, 240, 340, 440, 540, 640, 740 }
    local headers = { "TIME", "DUR", "MAX RPM", "MAX A", "MIN V", "MIN BEC", "MAX TMP", "mAh" }
    for i = 1, 8 do
      lcd.drawText(X(cols[i]), Y(65), headers[i], CENTER + f_sml + C.dim)
    end
    lcd.drawLine(X(20), Y(95), X(780), Y(95), SOLID, C.panel2)
    
    local entries_to_draw = w.log_entries
    if (not entries_to_draw or #entries_to_draw == 0) and w.is_demo_data then
      entries_to_draw = {
        {"14:30", "04:15", "2250", "125.4", "44.20", "7.95", "82", "3100"}
      }
    end

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

    lcd.drawText(X(20), Y(230), "LAST FLIGHT CHART", f_sml + C.white)
    
    lcd.drawFilledRectangle(X(310), Y(235), W(10), H(10), C.green)
    lcd.drawText(X(330), Y(230), "RPM", f_sml + C.white)
    lcd.drawFilledRectangle(X(400), Y(235), W(10), H(10), C.orange)
    lcd.drawText(X(420), Y(230), "VOLT", f_sml + C.white)
    lcd.drawFilledRectangle(X(500), Y(235), W(10), H(10), C.red)
    lcd.drawText(X(520), Y(230), "AMPS", f_sml + C.white)
    lcd.drawFilledRectangle(X(590), Y(235), W(10), H(10), C.blue)
    lcd.drawText(X(610), Y(230), "BEC", f_sml + C.white)
    lcd.drawFilledRectangle(X(680), Y(235), W(10), H(10), C.cyan or C.yellow)
    lcd.drawText(X(700), Y(230), "TMP", f_sml + C.white)
    
    lcd.drawLine(X(20), Y(255), X(780), Y(255), SOLID, C.panel2)

    local cx, cw = 50, 660
    local cy1, ch1 = 270, 95
    local cy2, ch2 = 380, 75
    
    lcd.drawRectangle(X(cx), Y(cy1), W(cw), H(ch1), C.panel2)
    lcd.drawLine(X(cx), Y(cy1 + ch1/2), X(cx + cw), Y(cy1 + ch1/2), DOTTED, C.panel2)
    lcd.drawRectangle(X(cx), Y(cy2), W(cw), H(ch2), C.panel2)

    if not w.chart_data or #w.chart_data < 2 then
      w.is_demo_data = true
      w.chart_data = {}
      for i = 1, 40 do
        local rpm = 0
        if i > 3 and i < 37 then rpm = 2000 + math.sin(i)*100 end
        if i > 10 and i < 30 then rpm = 2200 + math.sin(i*2)*150 end
        local volt = 50 - (i/40)*6 + math.cos(i)*0.5
        if i < 3 or i > 37 then volt = 50 end
        local amp = 0
        if i > 3 and i < 37 then amp = 30 + math.abs(math.sin(i*3)*40) end
        local bec = 8.4
        if i > 3 and i < 37 then bec = 8.4 - math.abs(math.sin(i*3)*0.5) end
        local tmp = 40 + (i/40)*45
        table.insert(w.chart_data, { v = volt, a = amp, r = rpm, b = bec, t = tmp })
      end
    end

    local data = w.chart_data
    local len = data and #data or 0
    local max_rpm, max_v, min_v, max_a, max_b, min_b, max_t, min_t = calculateChartScales(data)

    local base_y1 = cy1 + ch1
    local base_y2 = cy2 + ch2

    -- Top Axes Labels (Auto-Scaled & Always Visible)
    lcd.drawText(X(cx - 5), Y(cy1 - 5), string.format("%.0f", max_rpm), RIGHT + f_sml + C.green)
    lcd.drawText(X(cx - 5), Y(base_y1 - 15), "0", RIGHT + f_sml + C.green)
    lcd.drawText(X(cx + cw + 5), Y(cy1 - 5), string.format("%.0fV", max_v), f_sml + C.orange)
    lcd.drawText(X(cx + cw + 5), Y(base_y1 - 15), string.format("%.0fV", min_v), f_sml + C.orange)
    lcd.drawText(X(795), Y(cy1 - 5), string.format("%.0fA", max_a), RIGHT + f_sml + C.red)
    lcd.drawText(X(795), Y(base_y1 - 15), "0A", RIGHT + f_sml + C.red)
    
    -- Bottom Axes Labels (Auto-Scaled & Always Visible)
    lcd.drawText(X(cx - 5), Y(cy2 - 5), string.format("%.0f°", max_t), RIGHT + f_sml + (C.cyan or C.yellow))
    lcd.drawText(X(cx - 5), Y(base_y2 - 15), string.format("%.0f°", min_t), RIGHT + f_sml + (C.cyan or C.yellow))
    lcd.drawText(X(cx + cw + 5), Y(cy2 - 5), string.format("%.1fV", max_b), f_sml + C.blue)
    lcd.drawText(X(cx + cw + 5), Y(base_y2 - 15), string.format("%.1fV", min_b), f_sml + C.blue)

    if len >= 2 then
      local max_points = 50
      local draw_len = math.min(len, max_points)
      local stride = (len - 1) / (draw_len - 1)
      local step = cw / (draw_len - 1)
      
      local px, pyr, pyv, pya, pyb, pyt
      
      for i = 1, draw_len do
        local data_idx = math.max(1, math.min(len, math.floor(1 + (i - 1) * stride + 0.5)))
        local p = data[data_idx] or {}
        local scr_x = X(cx + (i-1) * step)
        
        local r_val = p.r or (p[1] or 0)
        local v_val = p.v or (p[2] or 0)
        local a_val = p.a or (p[3] or 0)
        local b_val = p.b or (p[4] or 0)
        local t_val = p.t or (p[5] or 0)

        local scr_yr = Y(base_y1 - (math.max(0, math.min(max_rpm, r_val)) / max_rpm) * ch1)
        local scr_yv = Y(base_y1 - (math.max(0, math.min(max_v - min_v, v_val - min_v)) / (max_v - min_v)) * ch1)
        local scr_ya = Y(base_y1 - (math.max(0, math.min(max_a, a_val)) / max_a) * ch1)
        
        local scr_yb = Y(base_y2 - (math.max(0, math.min(max_b - min_b, b_val - min_b)) / (max_b - min_b)) * ch2)
        local scr_yt = Y(base_y2 - (math.max(0, math.min(max_t - min_t, t_val - min_t)) / (max_t - min_t)) * ch2)
        
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
