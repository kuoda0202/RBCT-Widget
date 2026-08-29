local last_warn_time = 0
local last_spoken_level = nil

local vbec_abnormal_start = 0
local temp_abnormal_start = 0
local bat_crit_abnormal_start = 0

local bec_volts_map = { 5.0, 5.5, 6.0, 6.4, 6.6, 7.0, 7.4, 8.0 }

local STATIC_BAT_LEVELS = { 50, 40, 30, 25, 20, 15, 10, 5, 0 }

local function getEscalation(start_time, t)
  if start_time == 0 then return 0, 9999 end
  local dur = (t - start_time) / 100
  if dur > 15 then return 3, 50
  elseif dur > 5 then return 2, 150
  else return 1, 300 end
end

local function playVoiceFile(file_name)
  if playFile then
    return pcall(playFile, file_name)
  end
  return false
end

local function playVoiceNumber(val, unit)
  if playNumber then
    local u = unit or (rawget(_G, "UNIT_PERCENT") or 0)
    return pcall(playNumber, val, u, 0)
  end
  return false
end

local function update(w, ctx)
  if not ctx then return end
  local t = getTime()
  local sensor, stat, volts, is_nitro = ctx.sensor, ctx.stat, ctx.volts, ctx.is_nitro
  local getOption = ctx.getOption or function() return nil end
  local played = false

  -- Read custom alert options
  local bec_opt = getOption("BEC Warn V")
  local bec_thresh = 6.6
  if type(bec_opt) == "number" then
    bec_thresh = bec_volts_map[bec_opt] or bec_volts_map[bec_opt + 1] or 6.6
  end

  local esc_thresh = tonumber(getOption("ESC Temp Warn")) or 60
  local nitro_thresh = tonumber(getOption("Nitro Temp Warn")) or 120

  local bat_voice_opt = getOption("Bat% Voice")
  local bat_voice_enabled = (bat_voice_opt == 1 or bat_voice_opt == true)
  local bat_low_thresh = tonumber(getOption("Bat Low %")) or 30
  local bat_crit_thresh = tonumber(getOption("Bat Crit %")) or 10

  -- 1. Battery Percentage Voice Alerts (StacyDashV4 features)
  local bat_pct = stat(5, "cur") or 0
  if bat_pct > 90 then
    -- Reset spoken level tracker on fresh pack
    last_spoken_level = nil
  end

  if bat_voice_enabled and bat_pct > 0 and bat_pct <= 100 then
    for i = 1, #STATIC_BAT_LEVELS do
      local level = STATIC_BAT_LEVELS[i]
      if level <= bat_low_thresh and bat_pct <= level then
        if last_spoken_level == nil or level < last_spoken_level then
          last_spoken_level = level
          -- Try playing custom voice file or speak number
          if not playVoiceFile(tostring(level) .. "%.wav") then
            if not playVoiceFile("batlow.wav") then
              if not playVoiceFile("lowbat.wav") then
                playVoiceNumber(level)
              end
            end
          end
          if playHaptic then pcall(playHaptic, 300, 200) end
          played = true
          break
        end
      end
    end

    -- Critical / Dead Battery Alarm (Escalating)
    if bat_pct <= bat_crit_thresh then
      if bat_crit_abnormal_start == 0 then bat_crit_abnormal_start = t end
      local stage, interval = getEscalation(bat_crit_abnormal_start, t)
      if (t - last_warn_time) >= interval then
        if stage == 3 then
          if playTone then pcall(playTone, 2500, 100, 100, PLAY_NOW) end
          if playHaptic then pcall(playHaptic, 100, 100) end
        elseif stage == 2 then
          if playTone then pcall(playTone, 2500, 300, 300, PLAY_NOW) end
          if not playVoiceFile("batcrt.wav") then
            if not playVoiceFile("dead.wav") then
              if not playVoiceFile("batlow.wav") then
                playVoiceFile("lowbat.wav")
              end
            end
          end
        else
          if playTone then pcall(playTone, 2000, 500, 300, PLAY_NOW) end
        end
        played = true
      end
    else
      bat_crit_abnormal_start = 0
    end
  else
    bat_crit_abnormal_start = 0
  end

  -- 2. Rx Pack / BEC Voltage check (Escalating)
  local vbec = volts(sensor(12)) or 0
  if vbec > 0 and vbec < bec_thresh then
    if vbec_abnormal_start == 0 then vbec_abnormal_start = t end
    local stage, interval = getEscalation(vbec_abnormal_start, t)
    if not played and (t - last_warn_time) >= interval then
      if stage == 3 then
        if playTone then pcall(playTone, 2500, 100, 100, PLAY_NOW) end
        if playHaptic then pcall(playHaptic, 100, 100) end
      elseif stage == 2 then
        if playTone then pcall(playTone, 2000, 300, 300, PLAY_NOW) end
        if not playVoiceFile("bec_crit.wav") then
          if not playVoiceFile("bec_low.wav") then
            if not playVoiceFile("rxbatlow.wav") then
              if not playVoiceFile("becovl.wav") then
                playVoiceFile("telemwarn.wav")
              end
            end
          end
        end
      else
        if playTone then pcall(playTone, 1500, 500, 300, PLAY_NOW) end
      end
      played = true
    end
  else
    vbec_abnormal_start = 0
  end

  -- 3. Engine/ESC Temp check (Escalating)
  local temp = stat(6, "cur") or 0
  local temp_thresh = is_nitro and nitro_thresh or esc_thresh
  if temp > temp_thresh then
    if temp_abnormal_start == 0 then temp_abnormal_start = t end
    local stage, interval = getEscalation(temp_abnormal_start, t)
    if not played and (t - last_warn_time) >= interval then
      if stage == 3 then
        if playTone then pcall(playTone, 2000, 100, 100, PLAY_NOW) end
        if playHaptic then pcall(playHaptic, 100, 100) end
      elseif stage == 2 then
        if playTone then pcall(playTone, 1500, 300, 300, PLAY_NOW) end
        if not playVoiceFile("esct_crit.wav") then
          if not playVoiceFile("esct_warn.wav") then
            if not playVoiceFile("telemwarn.wav") then
              if not playVoiceFile("htemp.wav") then
                playVoiceFile("overht.wav")
              end
            end
          end
        end
      else
        if playTone then pcall(playTone, 1500, 500, 300, PLAY_NOW) end
      end
      played = true
    end
  else
    temp_abnormal_start = 0
  end

  if played then
    last_warn_time = t
  end
end

return { update = update }

