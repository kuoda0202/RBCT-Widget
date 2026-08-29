local function draw(w, ctx)
  local X, Y, W, H = ctx.X, ctx.Y, ctx.W, ctx.H
  local text, lcd, C = ctx.text, ctx.lcd, ctx.C
  local f_sml, f_mid, f_dbl, f_xxl, f_0 = ctx.f_sml, ctx.f_mid, ctx.f_dbl, ctx.f_xxl, ctx.f_0
  local RIGHT = ctx.RIGHT or 0
  local CENTER = ctx.CENTER or 0
  local is_trn, is_transp = ctx.is_trn, ctx.is_transp
  local sensor, stat = ctx.sensor, ctx.stat
  local panel = ctx.panel

  -- Base panel
  panel(X(295), Y(245), W(495), H(160), is_trn, is_transp)

  -- Mocked values for Turbine telemetry mapping
  local egt = tonumber(stat(6, "cur")) or 0         -- EGT (Tmp1)
  local core_rpm = tonumber(stat(3, "cur")) or 0    -- Core RPM
  local fuel = tonumber(sensor(5)) or 0             -- Fuel % (Bat%)
  local pump = tonumber(sensor(12)) or 0            -- Pump Voltage (Vbec)
  local ecu_code = tonumber(sensor(16)) or 0        -- ECU State (FM)

  -- ECU State Mapping
  local ecu_key = "ecu_off"
  local ecu_color = C.dim
  if ecu_code == 0 then ecu_key = "ecu_ready"; ecu_color = C.white
  elseif ecu_code == 1 then ecu_key = "ecu_ignition"; ecu_color = C.orange
  elseif ecu_code == 2 then ecu_key = "ecu_starter"; ecu_color = C.blue
  elseif ecu_code == 3 then ecu_key = "ecu_running"; ecu_color = C.green
  elseif ecu_code == 4 then ecu_key = "ecu_cooling"; ecu_color = C.cyan
  end

  local fallback_texts = {
    ecu_off = "OFF", ecu_ready = "READY", ecu_ignition = "IGNITION",
    ecu_starter = "STARTER", ecu_running = "RUNNING", ecu_cooling = "COOLING", ecu_error = "ERROR"
  }
  local ecu_hdr = (ctx.T and ctx.T("ecu_status_hdr")) or "ECU STATUS: "
  local ecu_text = (ctx.T and ctx.T(ecu_key)) or fallback_texts[ecu_key] or "OFF"

  -- Top Status: Centered ECU State
  if not is_trn then lcd.drawFilledRectangle(X(295), Y(245), W(495), H(32), C.panel2) end
  text(542, 248, ecu_hdr .. ecu_text, CENTER + f_0, ecu_color)
  if not is_trn then lcd.drawLine(X(295), Y(277), X(790), Y(277), SOLID, C.blue) end

  -- Reusable Horizontal Bar Function for EICAS Glass Cockpit Aesthetic
  local function drawBar(y, label, val_str, pct, color)
    text(310, y, label, f_0, C.white)
    
    local bar_w = 270
    local bar_x = 375
    local outline_color = is_trn and C.black or C.blue
    
    -- Draw bar track
    if not is_trn then 
      lcd.drawFilledRectangle(X(bar_x), Y(y), W(bar_w), H(18), C.bg)
    end
    lcd.drawRectangle(X(bar_x), Y(y), W(bar_w), H(18), outline_color)
    
    -- Draw fill percentage
    local fill_w = math.max(0, math.min(bar_w - 4, math.floor(pct * (bar_w - 4))))
    if fill_w > 0 then
      lcd.drawFilledRectangle(X(bar_x + 2), Y(y + 2), W(fill_w), H(14), color)
    end
    
    -- Value string on the right
    text(775, y, val_str, RIGHT + f_0, color)
  end

  -- Blink for warnings
  local blink = math.floor(getTime() / 50) % 2 == 0
  
  -- EGT Bar (Scale: 0 - 1000 C)
  local egt_pct = math.max(0, math.min(1, egt / 1000))
  local egt_col = (egt > 800) and (blink and C.red or C.white) or C.orange
  drawBar(285, "EGT", string.format("%.0f C", egt), egt_pct, egt_col)

  -- CORE RPM Bar (Scale: 0 - 200,000 RPM)
  local rpm_pct = math.max(0, math.min(1, core_rpm / 200000))
  local rpm_col = C.white
  drawBar(315, "RPM", string.format("%d", core_rpm), rpm_pct, rpm_col)

  -- FUEL Bar (Scale: 0 - 100 %)
  local fuel_pct = math.max(0, math.min(1, fuel / 100))
  local fuel_col = (fuel < 20) and (blink and C.red or C.white) or (fuel < 40 and C.orange or C.green)
  drawBar(345, "FUEL", string.format("%d %%", fuel), fuel_pct, fuel_col)
  
  -- PUMP Bar (Scale: 0 - 10.0 V)
  local pump_pct = math.max(0, math.min(1, pump / 10))
  local pump_col = (pump < 4.0 and pump > 0) and C.red or C.white
  drawBar(375, "PUMP", string.format("%.1f V", pump), pump_pct, pump_col)
  
end

return { draw = draw }
