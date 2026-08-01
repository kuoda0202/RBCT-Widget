local function draw(w, ctx)
  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H
  local text, lcd, C = ctx.text, ctx.lcd, ctx.C
  local f_sml, f_mid, f_dbl, f_xxl, f_0 = ctx.f_sml, ctx.f_mid, ctx.f_dbl, ctx.f_xxl, ctx.f_0
  local is_trn, is_transp = ctx.is_trn, ctx.is_transp
  local sensor, stat, volts = ctx.sensor, ctx.stat, ctx.volts
  local panel = ctx.panel

  -- Base panel
  panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)

  -- Get values
  local rx_v = volts(sensor(12)) or 0
  local min_rx_v = volts(stat(12, "min")) or 0
  local eng_temp = stat(6, "cur") or 0
  local max_eng_temp = stat(6, "max") or 0

  -- Divide the 495 width into two massive blocks (247px each)
  local cx1, cx2 = 295, 295 + 247

  -- Separator line
  if not is_trn then lcd.drawLine(X(cx2), Y(245), X(cx2), Y(405), SOLID, C.blue) end

  -- Block 1: ENGINE TEMP
  text(cx1 + 123, 260, "ENGINE TEMP", CENTER + f_sml, C.dim)
  local temp_color = (eng_temp > 120) and C.red or C.white
  local temp_str = string.format("%.0f", eng_temp)
  local len1 = string.len(temp_str)
  local split_x1 = cx1 + (len1 <= 2 and 165 or (len1 == 3 and 182 or 198))
  text(split_x1, 280, temp_str, RIGHT + f_xxl, temp_color)
  text(split_x1 + 3, 308, "°C", f_0, temp_color)
  text(cx1 + 123, 362, string.format("max %.0f°C", max_eng_temp), CENTER + f_sml, C.dim)

  -- Block 2: RX PACK
  text(cx2 + 123, 260, "RX PACK", CENTER + f_sml, C.dim)
  local rx_color = (rx_v > 0 and rx_v < 6.6) and C.red or C.white
  local rx_str = string.format("%.1f", rx_v)
  local len2 = string.len(rx_str)
  local split_x2 = cx2 + (len2 <= 2 and 162 or (len2 == 3 and 175 or 192))
  text(split_x2, 280, rx_str, RIGHT + f_xxl, rx_color)
  text(split_x2 + 3, 308, "V", f_0, rx_color)
  text(cx2 + 123, 362, string.format("min %.1fV", min_rx_v), CENTER + f_sml, C.dim)
end

return { draw = draw }
