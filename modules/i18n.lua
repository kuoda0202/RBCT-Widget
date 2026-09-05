-- RBCT Multi-Language Translation Dictionary Module
-- Author: 雷恩 / Ryan Kuo
-- Supports: English (en), Traditional Chinese (tw), Simplified Chinese (cn)
-- 100% compliant with EdgeTX 642 TW / 618 CN fonts (AGENTS.md)

local M = {}

local fn_detectLanguage = nil
local fn_getOption = nil

function M.init(env)
  if not env then return end
  if env.detectLanguage then fn_detectLanguage = env.detectLanguage end
  if env.getOption then fn_getOption = env.getOption end
  M._initialized = true
end

local UI_TEXT = {
  today_lbl    = { en = "Today : ",  tw = "本日: ",   cn = "本日: " },
  total_lbl    = { en = "Total : ",  tw = "總計: ",   cn = "总计: " },
  rpm_lbl      = { en = "RPM",       tw = "轉速 / 分鐘", cn = "转速 / 分钟" },
  gov_lbl      = { en = "GOV",       tw = "定速",     cn = "定速" },
  status       = { en = "STATUS",   tw = "狀態",     cn = "状态" },
  armed        = { en = "ARMED",    tw = "已解鎖",   cn = "已解锁" },
  safe         = { en = "SAFE",     tw = "鎖定",     cn = "锁定" },
  rescue       = { en = "RESCUE!",  tw = "救機!",    cn = "救机!" },
  head_spd_max = { en = "Head SPD max  %.0f", tw = "主旋翼最高  %.0f", cn = "主旋翼最高  %.0f" },
  tail_spd_max = { en = "TAIL %.0f / max %.0f", tw = "尾旋翼 %.0f / 最高 %.0f", cn = "尾旋翼 %.0f / 最高 %.0f" },
  min_spd      = { en = "min   %.0f", tw = "最低   %.0f", cn = "最低   %.0f" },
  mcu_temp     = { en = "MCU TEMP  %.0f °C", tw = "飛控溫度  %.0f °C", cn = "飞控温度  %.0f °C" },
  turbine_jet  = { en = "TURBINE JET", tw = "TURBINE 模式", cn = "TURBINE 模式" },
  nitro_eng    = { en = "NITRO ENGINE", tw = "發動機模式", cn = "发动机模式" },
  ecu_bat      = { en = "ECU BAT  %.1fV", tw = "ECU 電池  %.1fV", cn = "ECU 电池  %.1fV" },
  rx_pack      = { en = "RX PACK  %.1fV", tw = "接收電池  %.1fV", cn = "接收电池  %.1fV" },
  battery_fmt  = { en = "BATTERY  %dS  %.1fV", tw = "主電池  %dS  %.1fV", cn = "主电池  %dS  %.1fV" },
  used_mah     = { en = "%.0f mAh used", tw = "已消耗 %.0f mAh", cn = "已消耗 %.0f mAh" },
  peak_pwr_w   = { en = " - max %.0fW", tw = " - 最高 %.0fW", cn = " - 最高 %.0fW" },
  peak_pwr_kw  = { en = " - max %.1fkW", tw = " - 最高 %.1fkW", cn = " - 最高 %.1fkW" },
  no_data      = { en = "NO DATA",  tw = "無遙測信號", cn = "无遥测信号" },
  
  -- Electric card columns
  col_amps     = { en = "AMPS",     tw = "電流",     cn = "电流" },
  col_cell     = { en = "Cell",     tw = "單電電壓", cn = "单节电压" },
  col_bec      = { en = "BEC",      tw = "接收電壓", cn = "接收电压" },
  col_esc_t    = { en = "ESC Temp", tw = "電變溫度", cn = "电调温度" },
  sub_max_a    = { en = "max %.1fA", tw = "最高 %.1fA", cn = "最高 %.1fA" },
  sub_min_v    = { en = "min %.2fV", tw = "最低 %.2fV", cn = "最低 %.2fV" },
  sub_min_bec  = { en = "min %.1fV", tw = "最低 %.1fV", cn = "最低 %.1fV" },
  sub_max_t    = { en = "max %.0f°C", tw = "最高 %.0f°C", cn = "最高 %.0f°C" },

  -- Nitro / Turbine modules
  engine_temp  = { en = "ENGINE TEMP", tw = "發動機溫度", cn = "发动机温度" },
  rx_pack_title= { en = "RX PACK", tw = "接收電池", cn = "接收电池" },
  sub_min_v_rx = { en = "min %.1fV", tw = "最低 %.1fV", cn = "最低 %.1fV" },
  ecu_status_hdr = { en = "ECU STATUS: ", tw = "ECU 狀態: ", cn = "ECU 状态: " },
  ecu_off        = { en = "OFF",      tw = "關閉",    cn = "关闭" },
  ecu_ready      = { en = "READY",    tw = "準備",    cn = "准备" },
  ecu_ignition   = { en = "IGNITION", tw = "點火",    cn = "点火" },
  ecu_starter    = { en = "STARTER",  tw = "啟動",    cn = "启动" },
  ecu_running    = { en = "RUNNING",  tw = "運轉",    cn = "运转" },
  ecu_cooling    = { en = "COOLING",  tw = "降溫",    cn = "降温" },
  ecu_error      = { en = "ERROR",    tw = "異常",    cn = "异常" },
  
  -- Popups
  pop_bat_hlth = { en = "BATTERY HEALTH", tw = "電池狀態", cn = "电池状态" },
  pop_capacity = { en = "CAPACITY %d%%", tw = "電量 %d%%", cn = "电量 %d%%" },
  pop_sag_lbl  = { en = "Voltage Sag:", tw = "最大壓降:", cn = "最大压降:" },
  pop_ir_lbl   = { en = "Pack IR (Est):", tw = "預測 IR:", cn = "预测 IR:" },
  pop_trend    = { en = "DISCHARGE TREND", tw = "放電曲線", cn = "放电曲线" },
  pop_insuf    = { en = "Insufficient data", tw = "無放電記錄", cn = "无放电记录" },
  pop_tap_cls  = { en = "Tap anywhere to close", tw = "點按任意位置關閉", cn = "点按任意位置关闭" },
  pop_chart    = { en = "HEADSPEED & POWER CHART", tw = "轉速與飛行曲線", cn = "转速与飞行曲线" },
  pop_no_crv   = { en = "No flight curve recorded yet", tw = "無飛行曲線記錄", cn = "无飞行曲线记录" },
  pop_leg_rpm  = { en = "RPM",      tw = "轉速",     cn = "转速" },
  pop_leg_volt = { en = "VOLT",     tw = "電壓",     cn = "电压" },
  pop_leg_amps = { en = "AMPS",     tw = "電流",     cn = "电流" },
  pop_leg_bec  = { en = "BEC",      tw = "接收",     cn = "接收" },
  pop_leg_temp = { en = "TEMP",     tw = "溫度",     cn = "温度" },
  pop_peak_fmt = { en = "PEAK: %.0f RPM | %.1f A%s | %.0f°C   MIN: %.1f V | %.1f V BEC", tw = "最高: %.0f RPM | %.1f A%s | %.0f°C   最低: %.1f V | %.1f V 接收", cn = "最高: %.0f RPM | %.1f A%s | %.0f°C   最低: %.1f V | %.1f V 接收" },
  pop_rotor_dyn= { en = "TIP: %.0f G | SPEED: %.0f km/h | PULL: %.0f kg", tw = "旋翼: %.0f G | 速度: %.0f km/h | 負載: %.0f kg", cn = "旋翼: %.0f G | 速度: %.0f km/h | 负载: %.0f kg" },
  pop_rotor_idle={ en = "ROTOR DYNAMICS: STANDBY (0 RPM)", tw = "旋翼動態: 等待中 (0 RPM)", cn = "旋翼动态: 等待中 (0 RPM)" },
  pop_stat_hdr = { en = "FLIGHT SESSION STATS", tw = "飛行統計",   cn = "飞行统计" },
  pop_today    = { en = "TODAY", tw = "本日",       cn = "本日" },
  pop_total    = { en = "LIFETIME TOTAL", tw = "總計", cn = "总计" },
  pop_rst_btn  = { en = "RESET TODAY", tw = "本日清零", cn = "本日清零" },
  pop_rst_tot  = { en = "RESET TOTAL", tw = "總計清零", cn = "总计清零" },
  pop_btn_cls  = { en = "Tap anywhere to close", tw = "點按任意位置關閉", cn = "点按任意位置关闭" },

  -- Logbook & Battery Fleet Table
  fleet_mgr    = { en = "BATTERY FLEET MANAGER", tw = "電池管理總表", cn = "电池管理总表" },
  logbook_title= { en = "FLIGHT LOGBOOK", tw = "飛行日誌", cn = "飞行日志" },
  last_chart   = { en = "LATEST FLIGHT CHART", tw = "最新一次飛行曲線圖", cn = "最新一次飞行曲线图" },
  hist_chart   = { en = "FLIGHT CHART", tw = "歷史飛行曲線圖", cn = "历史飞行曲线图" },
  no_flight_data= { en = "- NO FLIGHT DATA YET -", tw = "- 暫無飛行日誌 -", cn = "- 暂无飞行日志 -" },
  tbl_bat_num  = { en = "BAT #",    tw = "電池",     cn = "电池" },
  tbl_status   = { en = "STATUS",   tw = "狀態",     cn = "状态" },
  tbl_today_tot= { en = "TODAY/TOT",tw = "本日/總計", cn = "本日/总计" },
  tbl_last_mah = { en = "LAST MAH", tw = "消耗電量", cn = "消耗电量" },
  fleet_sum_today={ en = "Today fleet: %d Flights | Flight time: %s | Energy: %s", tw = "本日統計: %d 次飛行 | 飛行時長: %s | 總消耗電量: %s", cn = "本日统计: %d 次飞行 | 飞行时长: %s | 总消耗电量: %s" },
  st_ready     = { en = "Ready",    tw = "待飛",     cn = "待飞" },
  st_flown     = { en = "Flown",    tw = "已飛",     cn = "已飞" },
  st_storage   = { en = "Storage",  tw = "儲存",     cn = "储存" },
  st_unused    = { en = "Unused",   tw = "未用",     cn = "未用" },
  tbl_cycles   = { en = "CYCLES",   tw = "循環",     cn = "循环" },
  tbl_min_v    = { en = "MIN VOLT", tw = "最低電壓", cn = "最低电压" },
  tbl_max_t    = { en = "MAX TMP",  tw = "電變最高溫", cn = "电调最高温" },
  tbl_avg_dur  = { en = "AVG DUR",  tw = "平均時間", cn = "平均时间" },
  hdr_time     = { en = "TIME",     tw = "起飛時間", cn = "起飞时间" },
  hdr_dur      = { en = "DUR",      tw = "飛行時長", cn = "飞行时长" },
  hdr_max_rpm  = { en = "MAX RPM",  tw = "最高轉速", cn = "最高转速" },
  hdr_max_a    = { en = "MAX A",    tw = "最高電流", cn = "最高电流" },
  hdr_max_pwr  = { en = "MAX W",    tw = "最高 W",  cn = "最高 W" },
  hdr_min_v    = { en = "MIN V",    tw = "最低電壓", cn = "最低电压" },
  hdr_min_bec  = { en = "MIN BEC",  tw = "最低接收", cn = "最低接收" },
  hdr_max_tmp  = { en = "MAX TMP",  tw = "最高溫度", cn = "最高温度" },
  hdr_mah      = { en = "mAh",      tw = "已消耗量", cn = "已消耗量" },
  bat_profile_hdr = { en = "BAT %d PROFILE", tw = "BAT %d 電池狀態", cn = "BAT %d 电池状态" },
  bat_status_hdr  = { en = "QUICK STATUS TAG", tw = "點按標記狀態", cn = "点按标记状态" },
  bat_rst_today   = { en = "RESET TODAY", tw = "本日清零", cn = "本日清零" },
  bat_set_active  = { en = "SET ACTIVE BAT", tw = "設為目前電池", cn = "设为当前电池" },
  active_bat_tag  = { en = "ACTIVE", tw = "使用中", cn = "使用中" }
}

M.UI_TEXT = UI_TEXT

function M.getUiLang(w)
  local opt = fn_getOption and fn_getOption(w, "UI Lang")
  if opt == 2 or opt == "English" or opt == "英文" then return "en" end
  if fn_detectLanguage then return fn_detectLanguage() end
  return "tw"
end

function M.T(w, key)
  local item = UI_TEXT[key]
  if not item then return key end
  local l = (w and w.ui_lang) or M.getUiLang(w)
  return item[l] or item.en or item.tw or key
end

return M
