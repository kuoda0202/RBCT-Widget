local last_warn_time = 0
local last_spoken_level = nil

local bec_volts_map = { 5.0, 5.5, 6.0, 6.4, 6.6, 7.0, 7.4, 8.0 }

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
  local t = getTime()
  -- Only check every 5 seconds (500 ticks) to avoid spamming the audio queue
  if (t - last_warn_time) < 500 then return end

  local sensor, stat, volts, is_nitro = ctx.sensor, ctx.stat, ctx.volts, ctx.is_nitro
  local getOption = ctx.getOption or function() return nil end
  local played = false

  -- Read custom alert options
  local bec_opt = getOption("BEC Warn V")
  local bec_thresh = (type(bec_opt) == "number" and bec_volts_map[bec_opt]) or 6.6

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
    local levels = { 50, 40, 30, 25, 20, 15, 10, 5, 0 }
    for i = 1, #levels do
      local level = levels[i]
      if level <= bat_low_thresh and bat_pct <= level then
        if last_spoken_level == nil or level < last_spoken_level then
          last_spoken_level = level
          -- Try playing custom voice file or speak number
          if not playVoiceFile(tostring(level) .. "%.wav") then
            if not playVoiceFile("batlow.wav") then
              playVoiceNumber(level)
            end
          end
          if playHaptic then pcall(playHaptic, 300, 200) end
          played = true
          break
        end
      end
    end

    -- Critical / Dead Battery Alarm
    if bat_pct <= bat_crit_thresh then
      if playTone then pcall(playTone, 2500, 500, 300, PLAY_NOW) end
      if playHaptic then pcall(playHaptic, 500, 300) end
      if not playVoiceFile("dead.wav") then
        playVoiceFile("rxbatlow.wav")
      end
      played = true
    end
  end

  -- 2. Rx Pack / BEC Voltage check
  local vbec = volts(sensor(12)) or 0
  if vbec > 0 and vbec < bec_thresh then
    if playTone then pcall(playTone, 2000, 500, 300, PLAY_NOW) end
    if playHaptic then pcall(playHaptic, 500, 300) end
    if not playVoiceFile("rxbatlow.wav") then
      playVoiceFile("telemwarn.wav")
    end
    played = true
  end

  -- 3. Engine/ESC Temp check
  local temp = stat(6, "cur") or 0
  local temp_thresh = is_nitro and nitro_thresh or esc_thresh
  if temp > temp_thresh then
    if playTone then pcall(playTone, 1500, 300, 300, PLAY_NOW) end
    if playHaptic then pcall(playHaptic, 300, 300) end
    playVoiceFile("telemwarn.wav")
    played = true
  end

  if played then
    last_warn_time = t
  end
end

return { update = update }

