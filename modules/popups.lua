-- RBCT Popups Rendering Sub-System Module
-- Author: 雷恩 / Ryan Kuo
-- Supports: RadioMaster TX16S MK3, TX16S MKII, TX15 MAX, Boxer, TX12
-- On-Demand UI: Renders only when active_popup is set, 0 CPU overhead during flight

local M = {}

local fn_T = nil

function M.init(env)
  if not env then return end
  if env.T then fn_T = env.T end
  M._initialized = true
end

local function T(w, key)
  if fn_T then return fn_T(w, key) end
  if w and w.render_ctx and w.render_ctx.T then return w.render_ctx.T(key) end
  return key
end

function M.drawPopups(w, ctx)
  local telemData = ctx.data or w.last_telem or {}
  if w.active_popup == "battery" then
    local bat_idx = w.last_bat_idx or 1
    if bat_idx < 1 or bat_idx > 6 then bat_idx = 1 end
    local f_st = (w.fleet_stats and w.fleet_stats[bat_idx]) or (w.fleet_data and w.fleet_data[bat_idx]) or { id = bat_idx, today_count = 0, lifetime_cycles = 0, status = "NONE", min_v = "-", max_t = "-", avg_dur = "-", last_mah = 0 }

    local mw, mh = 640, 412
    local mx, my = 80, 28
    ctx.panel(ctx.X(mx), ctx.Y(my), ctx.W(mw), ctx.H(mh), false, false)
    if ctx.lcd.drawRectangle then
      ctx.lcd.drawRectangle(ctx.X(mx), ctx.Y(my), ctx.W(mw), ctx.H(mh), ctx.C.blue)
    end

    -- Header Title
    local title = string.format(T(w, "bat_profile_hdr"), bat_idx)
    ctx.text(105, 42, title, ctx.f_mid, ctx.C.white)

    local is_curr_active = (bat_idx == (w.last_bat_idx or 1))
    local st_raw = f_st.status or "NONE"
    local st_name = T(w, "st_" .. string.lower(st_raw ~= "NONE" and st_raw or "unused")) or st_raw
    local st_col = (st_raw == "READY") and ctx.C.green or ((st_raw == "FLOWN") and ctx.C.red or ((st_raw == "STORAGE") and ctx.C.yellow or ctx.C.dim))

    -- Status pill on top-right
    if ctx.lcd.drawFilledRectangle then
      ctx.lcd.drawFilledRectangle(ctx.X(530), ctx.Y(36), ctx.W(170), ctx.H(34), ctx.C.panel2)
      ctx.lcd.drawRectangle(ctx.X(530), ctx.Y(36), ctx.W(170), ctx.H(34), st_col)
    end
    ctx.text(615, 43, st_name, ctx.CENTER + ctx.f_0, st_col)

    if ctx.lcd.drawLine then
      ctx.lcd.drawLine(ctx.X(100), ctx.Y(78), ctx.X(700), ctx.Y(78), SOLID, ctx.C.panel2)
    end

    -- Row 1: 4 Large Metric Cards (Clean 2-tier layout, f_0 font, perfectly centered!)
    local card_w = 140
    local cards = {
      { x = 100, lbl = T(w, "tbl_today_tot"), val = string.format("%d / %dc", f_st.today_count or 0, f_st.lifetime_cycles or 0), col = ctx.C.white },
      { x = 250, lbl = T(w, "tbl_min_v"), val = (f_st.min_v ~= "-") and (f_st.min_v .. "V") or "--V", col = (tonumber(f_st.min_v) and tonumber(f_st.min_v) < 3.5) and ctx.C.red or ctx.C.white },
      { x = 400, lbl = T(w, "tbl_max_t"), val = (f_st.max_t ~= "-") and (f_st.max_t .. "°C") or "--°C", col = (tonumber(f_st.max_t) and tonumber(f_st.max_t) > 70) and ctx.C.orange or ctx.C.white },
      { x = 550, lbl = T(w, "tbl_last_mah"), val = (f_st.last_mah and f_st.last_mah > 0) and (f_st.last_mah .. "mAh") or "--", col = ctx.C.yellow },
    }

    for i = 1, #cards do
      local c = cards[i]
      if ctx.lcd.drawFilledRectangle then
        ctx.lcd.drawFilledRectangle(ctx.X(c.x), ctx.Y(84), ctx.W(card_w), ctx.H(82), ctx.C.panel2)
        ctx.lcd.drawRectangle(ctx.X(c.x), ctx.Y(84), ctx.W(card_w), ctx.H(82), ctx.C.blue)
      end
      -- Header Label
      ctx.text(c.x + 70, 94, c.lbl, ctx.CENTER + ctx.f_sml, ctx.C.dim)
      -- Value Data (f_0 standard font, perfectly centered, never bursts)
      ctx.text(c.x + 70, 126, c.val, ctx.CENTER + ctx.f_0, c.col)
    end

    -- Section 2: Quick Status Switch Buttons (Height 52)
    ctx.text(400, 178, T(w, "bat_status_hdr"), ctx.CENTER + ctx.f_sml, ctx.C.dim)

    local btn_tags = {
      { x = 100, w = 140, tag = "READY", txt = T(w, "st_ready"), col = ctx.C.green },
      { x = 250, w = 140, tag = "FLOWN", txt = T(w, "st_flown"), col = ctx.C.red },
      { x = 400, w = 140, tag = "STORAGE", txt = T(w, "st_storage"), col = ctx.C.yellow },
      { x = 550, w = 150, tag = "NONE", txt = T(w, "st_unused"), col = ctx.C.dim }
    }

    for i = 1, #btn_tags do
      local b = btn_tags[i]
      local is_sel = (st_raw == b.tag) or (b.tag == "NONE" and (st_raw == "UNUSED" or st_raw == "NONE"))
      if ctx.lcd.drawFilledRectangle then
        ctx.lcd.drawFilledRectangle(ctx.X(b.x), ctx.Y(198), ctx.W(b.w), ctx.H(52), is_sel and b.col or ctx.C.panel2)
        ctx.lcd.drawRectangle(ctx.X(b.x), ctx.Y(198), ctx.W(b.w), ctx.H(52), is_sel and ctx.C.white or b.col)
      end
      local txt_col = is_sel and ctx.C.black or b.col
      ctx.text(b.x + math.floor(b.w / 2), 214, b.txt, ctx.CENTER + ctx.f_0, txt_col)
    end

    -- Section 3: Action Buttons (Reset Today Count / Set Active) (Height 54)
    -- Button A: Reset Today
    if ctx.lcd.drawFilledRectangle then
      ctx.lcd.drawFilledRectangle(ctx.X(100), ctx.Y(260), ctx.W(290), ctx.H(54), ctx.C.panel2)
      ctx.lcd.drawRectangle(ctx.X(100), ctx.Y(260), ctx.W(290), ctx.H(54), ctx.C.blue)
    end
    ctx.text(245, 278, T(w, "bat_rst_today"), ctx.CENTER + ctx.f_0, ctx.C.white)

    -- Button B: Set Active Battery
    if ctx.lcd.drawFilledRectangle then
      ctx.lcd.drawFilledRectangle(ctx.X(410), ctx.Y(260), ctx.W(290), ctx.H(54), ctx.C.panel2)
      ctx.lcd.drawRectangle(ctx.X(410), ctx.Y(260), ctx.W(290), ctx.H(54), is_curr_active and ctx.C.green or ctx.C.blue)
    end
    local act_str = is_curr_active and (T(w, "bat_set_active") .. " (" .. T(w, "active_bat_tag") .. ")") or T(w, "bat_set_active")
    ctx.text(555, 278, act_str, ctx.CENTER + ctx.f_0, is_curr_active and ctx.C.green or ctx.C.white)

    -- Section 4: Real-time Diagnostic Banner & Discharge Curve (Height 64, perfectly fills the bottom space)
    if ctx.lcd.drawFilledRectangle then
      ctx.lcd.drawFilledRectangle(ctx.X(100), ctx.Y(324), ctx.W(600), ctx.H(64), ctx.C.panel2)
      ctx.lcd.drawRectangle(ctx.X(100), ctx.Y(324), ctx.W(600), ctx.H(64), ctx.C.blue)
    end

    if w.chart_data and #w.chart_data > 1 then
      local dx = 580 / #w.chart_data
      local min_v, max_v = 999, 0
      for i = 1, #w.chart_data do
        local p = w.chart_data[i]
        local v = (type(p) == "table") and (p.v or p[1] or 0) or 0
        if v > 0 and v < min_v then min_v = v end
        if v > max_v then max_v = v end
      end
      if max_v > min_v then
        local range = math.max(2, max_v - min_v)
        for i = 2, #w.chart_data do
          local p1, p2 = w.chart_data[i - 1], w.chart_data[i]
          local v1 = (type(p1) == "table") and (p1.v or p1[1] or 0) or 0
          local v2 = (type(p2) == "table") and (p2.v or p2[1] or 0) or 0
          local px1 = ctx.X(110 + (i - 2) * dx)
          local py1 = ctx.Y(380 - ((v1 - min_v) / range) * 44)
          local px2 = ctx.X(110 + (i - 1) * dx)
          local py2 = ctx.Y(380 - ((v2 - min_v) / range) * 44)
          ctx.lcd.drawLine(px1, py1, px2, py2, SOLID, ctx.C.green)
        end
      end
      ctx.text(400, 330, T(w, "pop_trend"), ctx.CENTER + ctx.f_sml, ctx.C.dim)
    else
      local v_max = ctx.stat(1, "max")
      local v_min = ctx.stat(1, "min")
      local a_max = ctx.stat(2, "max")
      local sag = (v_max > 0 and v_min > 0) and (v_max - v_min) or 0
      local ir_est = (a_max >= 2 and sag > 0) and ((sag / a_max) * 1000) or 0
      local sag_str = (sag > 0) and string.format("-%.2fV", sag) or "--V"
      local ir_str = (ir_est > 0) and string.format("%.0f mohm", ir_est) or "---"
      local bat_pct = math.max(0, math.min(100, ctx.sensor(5)))

      ctx.text(250, 338, T(w, "pop_sag_lbl") .. " " .. sag_str, ctx.CENTER + ctx.f_sml, ctx.C.white)
      ctx.text(550, 338, T(w, "pop_ir_lbl") .. " " .. ir_str, ctx.CENTER + ctx.f_sml, ctx.C.yellow)
      ctx.text(400, 362, string.format(T(w, "pop_capacity"), bat_pct) .. " | " .. T(w, "pop_chart"), ctx.CENTER + ctx.f_sml, ctx.C.dim)
    end

    -- Footer Close Hint
    ctx.text(400, 402, T(w, "pop_btn_cls"), ctx.CENTER + ctx.f_sml, ctx.C.dim)

  elseif w.active_popup == "power_stats" then
    ctx.panel(ctx.X(110), ctx.Y(34), ctx.W(580), ctx.H(390), false, false)
    if ctx.lcd.drawRectangle then ctx.lcd.drawRectangle(ctx.X(110), ctx.Y(34), ctx.W(580), ctx.H(390), ctx.C.white) end
    ctx.text(400, 42, T(w, "pop_chart"), ctx.CENTER + ctx.f_0, ctx.C.white)

    ctx.text(175, 64, T(w, "pop_leg_rpm"), ctx.f_sml, ctx.C.green)
    ctx.text(265, 64, T(w, "pop_leg_volt"), ctx.f_sml, ctx.C.orange)
    ctx.text(360, 64, T(w, "pop_leg_amps"), ctx.f_sml, ctx.C.red)
    ctx.text(460, 64, T(w, "pop_leg_bec"), ctx.f_sml, ctx.C.blue)
    ctx.text(545, 64, T(w, "pop_leg_temp"), ctx.f_sml, ctx.C.yellow)

    local cx, cy, cw, ch = 175, 80, 450, 220
    if ctx.lcd.drawRectangle then
      ctx.lcd.drawRectangle(ctx.X(cx), ctx.Y(cy), ctx.W(cw), ctx.H(ch), ctx.C.dim)
      ctx.lcd.drawLine(ctx.X(cx), ctx.Y(cy + ch / 2), ctx.X(cx + cw), ctx.Y(cy + ch / 2), DOTTED, ctx.C.dim)
    end

    local data = w.chart_data
    local len = (data and type(data) == "table") and #data or 0
    local peak_rpm_raw = ctx.stat(3, "max") or 0
    local max_rpm = math.max(2000, math.ceil(peak_rpm_raw / 500) * 500)
    local max_a = math.max(50, math.ceil(ctx.amps(ctx.stat(2, "max") or 0) / 50) * 50)
    local cur_v = ctx.volts(ctx.sensor(1))
    local max_v, min_v = 55, 40
    if cur_v > 0 and cur_v <= 30 then
      if cur_v > 15 then max_v, min_v = 26, 18 else max_v, min_v = 13, 6 end
    end
    local max_t, min_t = 120, 20
    local max_b, min_b = 9.0, 5.0

    ctx.text(cx - 5, cy - 2, string.format("%.0f", max_rpm), ctx.RIGHT + ctx.f_sml, ctx.C.green)
    ctx.text(cx - 5, cy + ch - 14, "0", ctx.RIGHT + ctx.f_sml, ctx.C.green)
    ctx.text(cx + cw + 5, cy - 2, string.format("%.0fV", max_v), ctx.f_sml, ctx.C.orange)
    ctx.text(cx + cw + 5, cy + ch - 14, string.format("%.0fV", min_v), ctx.f_sml, ctx.C.orange)
    ctx.text(cx - 5, cy + ch / 2 - 7, string.format("%.0fA", max_a), ctx.RIGHT + ctx.f_sml, ctx.C.red)
    ctx.text(cx + cw + 5, cy + ch / 2 - 7, string.format("%.0f°C", max_t), ctx.f_sml, ctx.C.yellow)

    if len >= 2 then
      local max_pts = 50
      local draw_len = math.min(len, max_pts)
      local stride = (len - 1) / (draw_len - 1)
      local step = cw / (draw_len - 1)
      local base_y = cy + ch
      local px, pyr, pyv, pya, pyb, pyt
      for i = 1, draw_len do
        local d_idx = math.max(1, math.min(len, math.floor(1 + (i - 1) * stride + 0.5)))
        local p = data[d_idx] or {}
        local scr_x = ctx.X(cx + (i - 1) * step)
        local r_val = p.r or (p[1] or 0)
        local v_val = p.v or (p[2] or 0)
        local a_val = p.a or (p[3] or 0)
        local b_val = p.b or (p[4] or 0)
        local t_val = p.t or (p[5] or 0)
        local scr_yr = ctx.Y(base_y - (math.max(0, math.min(max_rpm, r_val)) / max_rpm) * ch)
        local scr_yv = ctx.Y(base_y - (math.max(0, math.min(max_v - min_v, v_val - min_v)) / math.max(1, max_v - min_v)) * ch)
        local scr_ya = ctx.Y(base_y - (math.max(0, math.min(max_a, a_val)) / max_a) * ch)
        local scr_yb = ctx.Y(base_y - (math.max(0, math.min(max_b - min_b, b_val - min_b)) / math.max(1, max_b - min_b)) * ch)
        local scr_yt = ctx.Y(base_y - (math.max(0, math.min(max_t - min_t, t_val - min_t)) / math.max(1, max_t - min_t)) * ch)
        if i > 1 then
          ctx.lcd.drawLine(px, pyr, scr_x, scr_yr, SOLID, ctx.C.green)
          ctx.lcd.drawLine(px, pyv, scr_x, scr_yv, SOLID, ctx.C.orange)
          ctx.lcd.drawLine(px, pya, scr_x, scr_ya, SOLID, ctx.C.red)
          ctx.lcd.drawLine(px, pyb, scr_x, scr_yb, SOLID, ctx.C.blue)
          ctx.lcd.drawLine(px, pyt, scr_x, scr_yt, SOLID, ctx.C.yellow)
        end
        px, pyr, pyv, pya, pyb, pyt = scr_x, scr_yr, scr_yv, scr_ya, scr_yb, scr_yt
      end
    else
      ctx.text(400, cy + ch / 2 - 8, T(w, "pop_no_crv"), ctx.CENTER + ctx.f_sml, ctx.C.dim)
    end

    local peak_rpm = ctx.stat(3, "max") or 0
    local peak_a = ctx.amps(ctx.stat(2, "max") or 0)
    local peak_t = ctx.stat(6, "max") or 0
    local min_bec_v = ctx.volts(ctx.stat(12, "min") or 0)
    local min_vbat = ctx.volts(ctx.stat(1, "min") or 0)
    local pwr_str = ""
    local max_p = (w and w.max_power and w.max_power > 0) and w.max_power or (min_vbat * peak_a)
    if max_p and max_p >= 1000 then
      pwr_str = string.format(" (%.1f kW)", max_p / 1000)
    elseif max_p and max_p >= 30 then
      pwr_str = string.format(" (%.0f W)", max_p)
    end
    ctx.text(400, 312, string.format(T(w, "pop_peak_fmt"), peak_rpm, peak_a, pwr_str, peak_t, min_vbat, min_bec_v), ctx.CENTER + ctx.f_sml, ctx.C.white)

    -- Rotor Dynamics Physics: Tip G-Force, Tip Speed (Mach), Grip Pull
    local rpm_eval = peak_rpm > 0 and peak_rpm or (ctx.sensor(3) or 0)
    if rpm_eval > 300 then
      local r_m, m_kg = 0.775, 0.19
      local cells_est = (min_vbat > 0) and math.floor(min_vbat / 3.7 + 0.5) or 12
      if cells_est <= 4 then
        r_m = 0.425; m_kg = 0.06
      elseif cells_est <= 6 then
        r_m = 0.625; m_kg = 0.12
      end
      local omega = (rpm_eval * 2 * math.pi) / 60
      local g_force = (omega * omega * r_m) / 9.80665
      local tip_kmh = (omega * r_m) * 3.6
      local mach = (omega * r_m) / 340.29
      local pull_kg = (m_kg * omega * omega * (r_m * 0.45)) / 9.80665
      ctx.text(400, 336, string.format(T(w, "pop_rotor_dyn"), g_force, tip_kmh, mach, pull_kg), ctx.CENTER + ctx.f_sml, ctx.C.cyan or ctx.C.yellow)
    else
      ctx.text(400, 336, T(w, "pop_rotor_idle"), ctx.CENTER + ctx.f_sml, ctx.C.dim)
    end

    if ctx.lcd.drawLine then ctx.lcd.drawLine(ctx.X(140), ctx.Y(360), ctx.X(660), ctx.Y(360), SOLID, ctx.C.dim) end
    ctx.text(400, 372, T(w, "pop_tap_cls"), ctx.CENTER + ctx.f_sml, ctx.C.dim)

  elseif w.active_popup == "session_stats" then
    ctx.panel(ctx.X(150), ctx.Y(60), ctx.W(500), ctx.H(370), false, false)
    if ctx.lcd.drawRectangle then ctx.lcd.drawRectangle(ctx.X(150), ctx.Y(60), ctx.W(500), ctx.H(370), ctx.C.white) end
    ctx.text(400, 75, T(w, "pop_stat_hdr"), ctx.CENTER + ctx.f_mid, ctx.C.white)

    local today_c = w.flight_count or 0
    local total_c = w.lifetime_count or 0
    ctx.text(280, 160, T(w, "pop_today"), ctx.CENTER + ctx.f_0, ctx.C.dim)
    ctx.text(280, 190, tostring(today_c), ctx.CENTER + ctx.f_dbl, ctx.C.yellow)
    ctx.text(520, 160, T(w, "pop_total"), ctx.CENTER + ctx.f_0, ctx.C.dim)
    ctx.text(520, 190, tostring(total_c), ctx.CENTER + ctx.f_dbl, ctx.C.white)

    if ctx.lcd.drawFilledRectangle then
      -- Button 1: Reset Today
      ctx.lcd.drawFilledRectangle(ctx.X(180), ctx.Y(280), ctx.W(200), ctx.H(55), ctx.C.red)
      ctx.lcd.drawRectangle(ctx.X(180), ctx.Y(280), ctx.W(200), ctx.H(55), ctx.C.white)
      -- Button 2: Reset Total
      ctx.lcd.drawFilledRectangle(ctx.X(420), ctx.Y(280), ctx.W(200), ctx.H(55), ctx.C.red)
      ctx.lcd.drawRectangle(ctx.X(420), ctx.Y(280), ctx.W(200), ctx.H(55), ctx.C.white)
    end
    ctx.text(280, 296, T(w, "pop_rst_btn"), ctx.CENTER + ctx.f_0, ctx.C.white)
    ctx.text(520, 296, T(w, "pop_rst_tot"), ctx.CENTER + ctx.f_0, ctx.C.white)
    ctx.lcd.drawLine(ctx.X(170), ctx.Y(385), ctx.X(630), ctx.Y(385), SOLID, ctx.C.dim)
    ctx.text(400, 398, T(w, "pop_btn_cls"), ctx.CENTER + ctx.f_sml, ctx.C.dim)

  elseif w.active_popup == "telemetry_info" then
    local sw = ctx.sw or 800
    local is_small = (sw < 600)
    local function infoText(en, tw, cn)
      if ctx.ui_lang == "tw" then return tw end
      if ctx.ui_lang == "cn" then return cn end
      return en
    end
    local px, py, pw, ph = 50, 20, 700, 440
    ctx.panel(ctx.X(px), ctx.Y(py), ctx.W(pw), ctx.H(ph), false, false)
    if ctx.lcd.drawRectangle then ctx.lcd.drawRectangle(ctx.X(px), ctx.Y(py), ctx.W(pw), ctx.H(ph), ctx.C.cyan or ctx.C.white) end
    
    local title_str = infoText("FLIGHT TELEMETRY INFORMATION", "飛行遙測", "飞行遥测")
    ctx.text(400, 32, title_str, ctx.CENTER + (is_small and ctx.f_0 or ctx.f_mid), ctx.C.cyan or ctx.C.white)
    if ctx.lcd.drawLine then ctx.lcd.drawLine(ctx.X(px + 20), ctx.Y(62), ctx.X(px + pw - 20), ctx.Y(62), SOLID, ctx.C.dim) end

    local c1_x = 75
    local c2_x = 310
    local c3_x = 540
    
    -- Peak statistics
    local peak_rpm = (ctx.stat and ctx.stat(3, "max")) or telemData.hspd or 0
    local peak_a   = (ctx.stat and ctx.amps and ctx.amps(ctx.stat(2, "max") or 0)) or telemData.curr or 0
    local peak_t   = (ctx.stat and ctx.stat(6, "max")) or telemData.esc_temp or 0
    local min_bec  = (ctx.stat and ctx.volts and ctx.volts(ctx.stat(12, "min") or 0)) or telemData.vbec or 0
    local min_vbat = (ctx.stat and ctx.volts and ctx.volts(ctx.stat(1, "min") or 0)) or telemData.vbat or 0
    local max_p    = (w and w.max_power and w.max_power > 0) and w.max_power or (min_vbat * peak_a)

    local header_y = 80
    local r1 = 120
    local r2 = 175
    local r3 = 230
    local r4 = 285
    local r5 = 340
    local val_off = 22

    -- Col 1: 電池與電量
    local h1 = infoText("BATTERY & PACK", "主電池與電量", "主电池与电量")
    ctx.text(c1_x, header_y, h1, (is_small and ctx.f_sml or ctx.f_0), ctx.C.yellow)
    
    local vbat_str = string.format("%.2fV (%dS)", telemData.vbat or 0, telemData.cells or 0)
    local vcel_str = string.format("%.2fV", telemData.vcel or 0)
    local vmin_str = string.format("%.2fV", min_vbat > 0 and min_vbat or (telemData.vbat or 0))
    local mah_str  = string.format("%d mAh", math.floor(telemData.mah or 0))
    local fuel_str = string.format("%d%%", math.floor(telemData.fuel_pct or 100))
    
    ctx.text(c1_x, r1, infoText("Total / Cell:", "總電壓 / 單電:", "总电压 / 单电:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c1_x, r1 + val_off, vbat_str, ctx.f_sml, ctx.C.white)
    ctx.text(c1_x, r2, infoText("Lowest Cell:", "單電最低:", "单电最低:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c1_x, r2 + val_off, vcel_str, ctx.f_sml, ctx.C.white)
    ctx.text(c1_x, r3, infoText("Min Volt Sag:", "最低壓降:", "最低压降:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c1_x, r3 + val_off, vmin_str, ctx.f_sml, ctx.C.orange or ctx.C.yellow)
    ctx.text(c1_x, r4, infoText("Consumed mAh:", "已消耗電量:", "已消耗电量:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c1_x, r4 + val_off, mah_str .. " (" .. fuel_str .. ")", ctx.f_sml, ctx.C.cyan or ctx.C.white)

    -- Col 2: 電流與功率極限
    local h2 = infoText("POWER & AMPS", "電流 / 功率", "电流 / 功率")
    ctx.text(c2_x, header_y, h2, (is_small and ctx.f_sml or ctx.f_0), ctx.C.yellow)
    
    local curr_str = string.format("%.1f A", telemData.curr or 0)
    local cmax_str = string.format("%.1f A", peak_a)
    local pwr_str  = string.format("%d W", math.floor(telemData.pwr_w or 0))
    local pmax_str = string.format("%d W", math.floor(max_p or 0))
    local rpm_max_str = string.format("%d RPM", math.floor(peak_rpm))
    
    ctx.text(c2_x, r1, infoText("Current:", "電流:", "电流:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c2_x, r1 + val_off, curr_str, ctx.f_sml, ctx.C.white)
    ctx.text(c2_x, r2, infoText("Peak Current:", "最高電流:", "最高电流:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c2_x, r2 + val_off, cmax_str, ctx.f_sml, ctx.C.red)
    ctx.text(c2_x, r3, infoText("Power Watts:", "功率 (W):", "功率 (W):"), ctx.f_sml, ctx.C.dim)
    ctx.text(c2_x, r3 + val_off, pwr_str, ctx.f_sml, ctx.C.white)
    ctx.text(c2_x, r4, infoText("Peak Watts:", "最高功率:", "最高功率:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c2_x, r4 + val_off, pmax_str, ctx.f_sml, ctx.C.red)
    ctx.text(c2_x, r5, infoText("Max Headspeed:", "最高主轉速:", "最高主转速:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c2_x, r5 + val_off, rpm_max_str, ctx.f_sml, ctx.C.cyan or ctx.C.white)

    -- Col 3: 溫度、BEC 與飛行
    local h3 = infoText("SYSTEM & TEMP", "系統與溫度", "系统与温度")
    ctx.text(c3_x, header_y, h3, (is_small and ctx.f_sml or ctx.f_0), ctx.C.yellow)
    
    local esc_t_str = string.format("%d °C", math.floor(telemData.esc_temp or 0))
    local esc_m_str = string.format("%d °C", math.floor(peak_t > 0 and peak_t or (telemData.esc_temp or 0)))
    local bec_str   = string.format("%.1fV (最低 %.1fV)", telemData.vbec or 0, min_bec > 0 and min_bec or (telemData.vbec or 0))
    local today_c   = w.flight_count or 0
    local total_c   = w.lifetime_count or 0
    local flt_str   = string.format(infoText("Today: %d / Total: %d", "本日: %d / 總計: %d", "本日: %d / 总计: %d"), today_c, total_c)
    local sig_str   = string.format("RSSI: %s | LQ: %s", tostring(telemData.rssi or "--"), tostring(telemData.link_qual or "--"))
    
    ctx.text(c3_x, r1, infoText("ESC Temp:", "電變溫度:", "电调温度:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c3_x, r1 + val_off, esc_t_str, ctx.f_sml, ctx.C.white)
    ctx.text(c3_x, r2, infoText("Peak Temp:", "最高溫度:", "最高温度:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c3_x, r2 + val_off, esc_m_str, ctx.f_sml, ctx.C.orange or ctx.C.yellow)
    ctx.text(c3_x, r3, infoText("BEC (Min):", "接收 (最低):", "接收 (最低):"), ctx.f_sml, ctx.C.dim)
    ctx.text(c3_x, r3 + val_off, bec_str, ctx.f_sml, ctx.C.white)
    ctx.text(c3_x, r4, infoText("Flight Count:", "飛行統計:", "飞行统计:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c3_x, r4 + val_off, flt_str, ctx.f_sml, ctx.C.white)
    ctx.text(c3_x, r5, infoText("Signal Quality:", "信號品質:", "信号品质:"), ctx.f_sml, ctx.C.dim)
    ctx.text(c3_x, r5 + val_off, sig_str, ctx.f_sml, ctx.C.green or ctx.C.white)

    if ctx.lcd.drawLine then ctx.lcd.drawLine(ctx.X(px + 20), ctx.Y(405), ctx.X(px + pw - 20), ctx.Y(405), SOLID, ctx.C.dim) end
    local close_hint = infoText("Tap anywhere to close", "點按任意位置關閉", "点按任意位置关闭")
    ctx.text(400, 420, close_hint, ctx.CENTER + ctx.f_sml, ctx.C.dim)
  end
end

return M
