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
        local r = tonumber(p[1] or p.r) or 0
        local v = tonumber(p[2] or p.v) or 0
        local a = tonumber(p[3] or p.a) or 0
        local b = tonumber(p[4] or p.b) or 0
        local t = tonumber(p[5] or p.t) or 0
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

local function draw(w, ctx)
  local x, y, sw, sh, sx, sy = ctx.x, ctx.y, ctx.sw, ctx.sh, ctx.sx, ctx.sy
  local is_trn, is_transp = ctx.is_trn, ctx.is_transp
  local f_mid, f_sml = ctx.f_mid, ctx.f_sml
  local lcd, C = ctx.lcd, ctx.C

  local function X(v) return x + math.floor(v * sx) end
  local function Y(v) return y + math.floor(v * sy) end
  local function W(v) return math.floor(v * sx) end
  local function H(v) return math.floor(v * sy) end

  -- Logbook full screen mode requires solid background for high contrast readability
  lcd.drawFilledRectangle(x, y, sw, sh, C.bg)
  lcd.drawRectangle(x, y, sw, sh, C.blue)

  if w.logbook_tab == 2 then
    lcd.drawText(X(400), Y(240), "- COMING SOON !! -", CENTER + f_mid + C.white)
    return
  end

  lcd.drawText(X(400), Y(20), "FLIGHT LOGBOOK", CENTER + f_mid + C.white)

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
  local max_rpm, max_v, min_v, max_a, max_b, min_b, max_t, min_t = calculateChartScales(data)

  local base_y1 = cy1 + ch1
  local base_y2 = cy2 + ch2

  -- Top Axes Labels (Auto-Scaled & Always Visible)
  lcd.drawText(X(cx - 5), Y(cy1 - 5), string.format("%.0f", max_rpm), RIGHT + f_sml + C.green)
  lcd.drawText(X(cx - 5), Y(base_y1 - 15), "0", RIGHT + f_sml + C.green)

  lcd.drawText(X(cx + cw + 5), Y(cy1 - 5), string.format("%.0fV", max_v), f_sml + C.orange)
  lcd.drawText(X(cx + cw + 5), Y(base_y1 - 15), string.format("%.0fV", min_v), f_sml + C.orange)

  lcd.drawText(X(cx + cw + 40), Y(cy1 - 5), string.format("%.0fA", max_a), f_sml + C.red)
  lcd.drawText(X(cx + cw + 40), Y(base_y1 - 15), "0A", f_sml + C.red)

  -- Bottom Axes Labels (Auto-Scaled & Always Visible)
  lcd.drawText(X(cx - 5), Y(cy2 - 5), string.format("%.0f°", max_t), RIGHT + f_sml + C.yellow)
  lcd.drawText(X(cx - 5), Y(base_y2 - 15), string.format("%.0f°", min_t), RIGHT + f_sml + C.yellow)

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
      local pr = tonumber(p[1] or p.r) or 0
      local pv = tonumber(p[2] or p.v) or 0
      local pa = tonumber(p[3] or p.a) or 0
      local pb = tonumber(p[4] or p.b) or 0
      local pt = tonumber(p[5] or p.t) or 0
      local scr_x = X(cx + (i-1) * step)

      -- Power Chart Math (Auto-Scaled)
      local scr_yr = Y(base_y1 - (math.max(0, math.min(max_rpm, pr)) / max_rpm) * ch1)
      local scr_yv = Y(base_y1 - (math.max(0, math.min(max_v - min_v, pv - min_v)) / (max_v - min_v)) * ch1)
      local scr_ya = Y(base_y1 - (math.max(0, math.min(max_a, pa)) / max_a) * ch1)

      -- Health Chart Math (Auto-Scaled)
      local scr_yb = Y(base_y2 - (math.max(0, math.min(max_b - min_b, pb - min_b)) / (max_b - min_b)) * ch2)
      local scr_yt = Y(base_y2 - (math.max(0, math.min(max_t - min_t, pt - min_t)) / (max_t - min_t)) * ch2)

      if i > 1 then
        lcd.drawLine(px, pyr, scr_x, scr_yr, SOLID, C.green)
        lcd.drawLine(px, pyv, scr_x, scr_yv, SOLID, C.orange)
        lcd.drawLine(px, pya, scr_x, scr_ya, SOLID, C.red)

        lcd.drawLine(px, pyb, scr_x, scr_yb, SOLID, C.blue)
        lcd.drawLine(px, pyt, scr_x, scr_yt, SOLID, C.yellow)
      end
      px, pyr, pyv, pya, pyb, pyt = scr_x, scr_yr, scr_yv, scr_ya, scr_yb, scr_yt
    end
  end
end

return { draw = draw, calculateChartScales = calculateChartScales }
