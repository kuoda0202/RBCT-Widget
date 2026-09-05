local function draw(w, ctx)
  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H
  local text, lcd, C = ctx.text, ctx.lcd, ctx.C
  local f_sml, f_mid, f_dbl, f_xxl, f_0 = ctx.f_sml, ctx.f_mid, ctx.f_dbl, ctx.f_xxl, ctx.f_0
  local CENTER = ctx.CENTER or rawget(_G, "CENTER") or rawget(_G, "CENTERED") or 2
  local RIGHT = ctx.RIGHT or rawget(_G, "RIGHT") or 16
  local is_trn, is_transp = ctx.is_trn, ctx.is_transp
  local sensor, stat, volts = ctx.sensor, ctx.stat, ctx.volts
  local panel = ctx.panel

  local function textPhysical(px, py, str, flags, color)
    if (is_trn or is_transp) and color ~= C.black then
      lcd.drawText(px + 1, py + 1, str, flags + C.black)
    end
    lcd.drawText(px, py, str, flags + color)
  end

  -- Base panel
  panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)

  -- Get values
  -- Nitro Rx Pack usually monitored via Vbec or RxBt telemetry
  local vbec = tonumber(volts(sensor(12))) or 0
  local min_vbec = tonumber(volts(stat(12, "min"))) or 0

  -- Engine Temp (usually Tmcu or Tesc for FBL telemetry, we use Tmcu from sensor(7) or Tesc from sensor(6))
  local temp = tonumber(stat(6, "cur")) or 0
  local max_temp = tonumber(stat(6, "max")) or 0

  -- Divide the 495 width into two massive blocks (247px each)
  local cx1, cx2 = 295, 295 + 247

  -- Separator line
  if not is_trn then lcd.drawLine(X(cx2), Y(245), X(cx2), Y(405), SOLID, C.blue) end

  -- Common vertical layout metrics
  local title_y = Y(260)
  local sub_y = Y(362)
  local content_top = Y(276)
  local content_h = sub_y - content_top

  -- Block 1: ENGINE TEMP
  text(cx1 + 123, title_y, (ctx.T and ctx.T("engine_temp")) or "ENGINE TEMP", CENTER + f_sml, C.dim)
  local temp_color = (temp > 120) and C.red or C.white
  local temp_str = string.format("%.0f", temp)
  local temp_unit = "°C"
  local temp_font = f_xxl
  local temp_w, temp_h = lcd.sizeText(temp_str, temp_font)
  local temp_unit_w, temp_unit_h = lcd.sizeText(temp_unit, f_0)
  temp_unit_h = temp_unit_h or H(16)
  if temp_w + W(3) + temp_unit_w > W(231) or (temp_h or 0) > H(76) then
    temp_font = f_dbl
    temp_w, temp_h = lcd.sizeText(temp_str, temp_font)
    if temp_w + W(3) + temp_unit_w > W(231) or (temp_h or 0) > H(76) then
      temp_font = f_sml
      temp_w, temp_h = lcd.sizeText(temp_str, temp_font)
    end
  end
  temp_h = (temp_h and temp_h > 0) and temp_h or (temp_font == f_xxl and H(70) or H(32))
  local temp_start = X(cx1 + 123) - math.floor((temp_w + W(3) + temp_unit_w) / 2)
  local temp_y = content_top + math.floor((content_h - temp_h) / 2)
  local temp_unit_y = temp_y + temp_h - temp_unit_h - Y(2)
  textPhysical(temp_start, temp_y, temp_str, temp_font, temp_color)
  textPhysical(temp_start + temp_w + W(3), temp_unit_y, temp_unit, f_0, temp_color)
  text(cx1 + 123, sub_y, string.format((ctx.T and ctx.T("sub_max_t")) or "max %.0f°C", max_temp), CENTER + f_sml, C.dim)

  -- Block 2: RX PACK
  text(cx2 + 123, title_y, (ctx.T and ctx.T("rx_pack_title")) or "RX PACK", CENTER + f_sml, C.dim)
  local rx_color = (vbec > 0 and vbec < 6.6) and C.red or C.white
  local rx_str = string.format("%.1f", vbec)
  local rx_unit = "V"
  local rx_font = f_xxl
  local rx_w, rx_h = lcd.sizeText(rx_str, rx_font)
  local rx_unit_w, rx_unit_h = lcd.sizeText(rx_unit, f_0)
  rx_unit_h = rx_unit_h or H(16)
  if rx_w + W(3) + rx_unit_w > W(231) or (rx_h or 0) > H(76) then
    rx_font = f_dbl
    rx_w, rx_h = lcd.sizeText(rx_str, rx_font)
    if rx_w + W(3) + rx_unit_w > W(231) or (rx_h or 0) > H(76) then
      rx_font = f_sml
      rx_w, rx_h = lcd.sizeText(rx_str, rx_font)
    end
  end
  rx_h = (rx_h and rx_h > 0) and rx_h or (rx_font == f_xxl and H(70) or H(32))
  local rx_start = X(cx2 + 123) - math.floor((rx_w + W(3) + rx_unit_w) / 2)
  local rx_y = content_top + math.floor((content_h - rx_h) / 2)
  local rx_unit_y = rx_y + rx_h - rx_unit_h - Y(2)
  textPhysical(rx_start, rx_y, rx_str, rx_font, rx_color)
  textPhysical(rx_start + rx_w + W(3), rx_unit_y, rx_unit, f_0, rx_color)
  text(cx2 + 123, sub_y, string.format((ctx.T and ctx.T("sub_min_v_rx")) or "min %.1fV", min_vbec), CENTER + f_sml, C.dim)
end

return { draw = draw }
