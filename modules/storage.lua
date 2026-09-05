-- RBCT Storage & Blackbox File System Module
-- Author: 雷恩 / Ryan Kuo
-- Supports: RadioMaster TX16S MK3, TX16S MKII, TX15 MAX, Boxer, TX12
-- Ultra-Light Performance Architecture: Zero SD-card IO during active flight

local M = {}

local basePath = "/WIDGETS/RBCT"
local fn_getCraftName = nil
local fn_getOption = nil
local fn_loadModule = nil

function M.init(env)
  if not env then return end
  if env.basePath then basePath = env.basePath end
  if env.getCraftName then fn_getCraftName = env.getCraftName end
  if env.getOption then fn_getOption = env.getOption end
  if env.loadModule then fn_loadModule = env.loadModule end
  M._initialized = true
end

local function sanitizeFilename(name)
  if not name or name == "" then return "default" end
  local clean = string.gsub(name, "[^%w%-_]", "_")
  return string.sub(clean, 1, 24)
end
M.sanitizeFilename = sanitizeFilename

local function getCraftName()
  if fn_getCraftName then return fn_getCraftName() end
  if model and model.getInfo then
    local info = model.getInfo()
    if info and info.name and info.name ~= "" then return info.name end
  end
  return "default"
end
M.getCraftName = getCraftName

local function getActiveBatIndex(w)
  local bat_mod = fn_loadModule and fn_loadModule("battery")
  if bat_mod and bat_mod.getBatIndex then
    local bat_src = fn_getOption and fn_getOption(w, "Bat Track")
    local val = bat_src and (bat_src ~= 0) and getValue and getValue(bat_src) or nil
    return bat_mod.getBatIndex(val)
  end
  return 0
end
M.getActiveBatIndex = getActiveBatIndex

local function getLogFilePath(w)
  local craft = getCraftName()
  return basePath .. "/log_" .. sanitizeFilename(craft) .. ".txt"
end
M.getLogFilePath = getLogFilePath

local function getLogbookFilePath(w)
  local craft = getCraftName()
  local bat_idx = getActiveBatIndex(w)
  if bat_idx and bat_idx > 0 then
    return basePath .. "/logbook_" .. sanitizeFilename(craft) .. "_bat" .. bat_idx .. ".txt"
  end
  return basePath .. "/logbook_" .. sanitizeFilename(craft) .. ".txt"
end
M.getLogbookFilePath = getLogbookFilePath

local function getFleetFilePath(w)
  local craft = getCraftName()
  return basePath .. "/fleet_" .. sanitizeFilename(craft) .. ".txt"
end
M.getFleetFilePath = getFleetFilePath

local function getChartFilePath(w)
  local craft = getCraftName()
  local bat_idx = getActiveBatIndex(w)
  if bat_idx and bat_idx > 0 then
    return basePath .. "/chart_" .. sanitizeFilename(craft) .. "_bat" .. bat_idx .. ".txt"
  end
  return basePath .. "/chart_" .. sanitizeFilename(craft) .. ".txt"
end
M.getChartFilePath = getChartFilePath

function M.loadFleetData(w)
  w.fleet_stats = {}
  local dt = (getDateTime and getDateTime()) or { year = 2000, mon = 1, day = 1 }
  local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)

  for i = 1, 6 do
    w.fleet_stats[i] = {
      id = i,
      last_date = today,
      today_count = 0,
      lifetime_cycles = 0,
      status = "NONE",
      min_v = "-",
      max_t = "-",
      avg_dur = "-",
      tot_dur_s = 0,
      tot_flights = 0,
      last_mah = 0
    }
  end

  local path = getFleetFilePath(w)
  if fstat and fstat(path) then
    local f = io.open(path, "r")
    if f then
      local content = io.read(f, 2048) or ""
      io.close(f)
      for line in string.gmatch(content, "[^\r\n]+") do
        local parts = {}
        for p in string.gmatch(line, "([^,]+)") do table.insert(parts, p) end
        local idx = tonumber(parts[1])
        if idx and idx >= 1 and idx <= 6 then
          local entry = w.fleet_stats[idx]
          entry.last_date = parts[2] or today
          entry.today_count = tonumber(parts[3]) or 0
          entry.lifetime_cycles = tonumber(parts[4]) or 0
          entry.status = parts[5] or "NONE"
          entry.min_v = parts[6] or "-"
          entry.max_t = parts[7] or "-"
          entry.avg_dur = parts[8] or "-"
          entry.tot_dur_s = tonumber(parts[9]) or 0
          entry.tot_flights = tonumber(parts[10]) or entry.lifetime_cycles or 0
          entry.last_mah = tonumber(parts[11]) or 0

          if entry.last_date ~= today then
            entry.today_count = 0
            entry.last_date = today
            if entry.status == "FLOWN" then
              entry.status = "NONE"
            end
          end
        end
      end
    end
  else
    local craft = getCraftName()
    local cleanName = sanitizeFilename(craft)
    for i = 1, 6 do
      local lbPath = basePath .. "/logbook_" .. cleanName .. "_bat" .. i .. ".txt"
      if not (fstat and fstat(lbPath)) and i == 1 then
        lbPath = basePath .. "/logbook_" .. cleanName .. ".txt"
      end
      if fstat and fstat(lbPath) then
        local f2 = io.open(lbPath, "r")
        if f2 then
          local c2 = io.read(f2, 2048) or ""
          io.close(f2)
          local min_v, max_t, tot_dur_s, flights, last_mah = 999, 0, 0, 0, 0
          for l in string.gmatch(c2, "[^\r\n]+") do
            local p = {}
            for item in string.gmatch(l, "([^,]+)") do table.insert(p, item) end
            if #p >= 8 then
              flights = flights + 1
              local dur = p[2]
              local m, s = string.match(dur, "(%d+):(%d+)")
              if m and s then
                tot_dur_s = tot_dur_s + tonumber(m) * 60 + tonumber(s)
              end
              local v = tonumber(p[5])
              if v and v < min_v then min_v = v end
              local t = tonumber(p[7])
              if t and t > max_t then max_t = t end
              local mah = tonumber(p[8])
              if mah and mah > 0 and last_mah == 0 then last_mah = mah end
            end
          end
          if flights > 0 then
            local entry = w.fleet_stats[i]
            entry.lifetime_cycles = flights
            entry.tot_flights = flights
            entry.tot_dur_s = tot_dur_s
            entry.last_mah = last_mah
            if min_v < 900 then entry.min_v = string.format("%.2f", min_v) end
            if max_t > 0 then entry.max_t = string.format("%.0f", max_t) end
            local avg_s = math.floor(tot_dur_s / flights)
            entry.avg_dur = string.format("%02d:%02d", math.floor(avg_s / 60), avg_s % 60)
          end
        end
      end
    end
  end
end

function M.saveFleetData(w)
  if not w.fleet_stats then return end
  local path = getFleetFilePath(w)
  local f = io.open(path, "w")
  if f then
    for i = 1, 6 do
      local s = w.fleet_stats[i] or {}
      io.write(f, string.format("%d,%s,%d,%d,%s,%s,%s,%s,%d,%d,%d\n",
        i,
        s.last_date or "2000-01-01",
        s.today_count or 0,
        s.lifetime_cycles or 0,
        s.status or "NONE",
        tostring(s.min_v or "-"),
        tostring(s.max_t or "-"),
        tostring(s.avg_dur or "-"),
        s.tot_dur_s or 0,
        s.tot_flights or 0,
        s.last_mah or 0
      ))
    end
    io.close(f)
  end
end

function M.updateBatteryStatusOnVoltage(w, bat_idx, vcel, vbat)
  if not w.fleet_stats or not bat_idx or bat_idx < 1 or bat_idx > 6 then return end
  local st = w.fleet_stats[bat_idx]
  if not st then return end
  if vcel and vcel >= 4.10 then
    if st.status ~= "READY" then
      st.status = "READY"
    end
  elseif vcel and vcel >= 3.80 and vcel <= 3.90 and (st.today_count or 0) == 0 and st.status == "NONE" then
    st.status = "STORAGE"
  end
end

function M.loadFlightLog(w)
  w.flight_count = 0
  w.lifetime_count = 0
  local path = getLogFilePath(w)
  if not (fstat and fstat(path)) then return end

  local f = io.open(path, "r")
  if f then
    local content = io.read(f, 256) or ""
    io.close(f)
    if content ~= "" then
      local d, c, l = string.match(content, "([%d%-]+),(%d+),(%d+)")
      if d and c and l then
        w.last_date = d
        w.flight_count = tonumber(c) or 0
        w.lifetime_count = tonumber(l) or 0
      end
    end
  end
end

function M.saveFlightLog(w)
  local path = getLogFilePath(w)
  local dt = (getDateTime and getDateTime()) or { year = 2000, mon = 1, day = 1 }
  local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)
  local f = io.open(path, "w")
  if f then
    io.write(f, string.format("%s,%d,%d\n", today, w.flight_count or 0, w.lifetime_count or 0))
    io.close(f)
  end
end

function M.loadLogbook(w)
  w.log_entries = {}
  local path = getLogbookFilePath(w)
  if not (fstat and fstat(path)) then return end
  local f = io.open(path, "r")
  if f then
    local content = io.read(f, 4096) or ""
    io.close(f)
    for line in string.gmatch(content, "[^\r\n]+") do
      local parts = {}
      for item in string.gmatch(line, "([^,]+)") do
        table.insert(parts, item)
      end
      if #parts >= 8 then
        table.insert(w.log_entries, parts)
      end
      if #w.log_entries >= 10 then break end
    end
  end
end

function M.saveLogbook(w)
  if not w.log_entries then return end
  local path = getLogbookFilePath(w)
  local f = io.open(path, "w")
  if f then
    for i = 1, math.min(10, #w.log_entries) do
      local row = table.concat(w.log_entries[i], ",")
      io.write(f, row .. "\n")
    end
    io.close(f)
  end
end

function M.loadChartData(w, target_idx)
  w.chart_data = {}
  w.selected_chart_idx = target_idx or w.selected_chart_idx or 1
  local sel = w.selected_chart_idx
  local path = getChartFilePath(w)
  if not (fstat and fstat(path)) then return end
  local f = io.open(path, "r")
  if not f then return end

  local content = io.read(f, 32768) or ""
  io.close(f)
  if content == "" then return end

  local blocks = {}
  if string.find(content, "#FLIGHT") then
    for block in string.gmatch(content, "#FLIGHT[^\r\n]*[\r\n]+([^#]+)") do
      table.insert(blocks, block)
    end
  else
    table.insert(blocks, content)
  end

  local block_to_load = blocks[sel]
  if block_to_load then
    for line in string.gmatch(block_to_load, "[^\r\n]+") do
      local v, a, r, b, t = string.match(line, "([%d%.]+),([%d%.]+),([%d%.]+),([%d%.]+),([%d%.]+)")
      if v and a and r and b and t then
        table.insert(w.chart_data, {
          v = tonumber(v) or 0,
          a = tonumber(a) or 0,
          r = tonumber(r) or 0,
          b = tonumber(b) or 0,
          t = tonumber(t) or 0
        })
      end
      if #w.chart_data >= 200 then break end
    end
  end
  w._scales_cache = nil
end

function M.saveChartData(w)
  if not w.chart_data or #w.chart_data < 2 then return end
  local path = getChartFilePath(w)

  local existing_blocks = {}
  local f_read = io.open(path, "r")
  if f_read then
    local content = io.read(f_read, 32768) or ""
    io.close(f_read)
    if content ~= "" then
      if string.find(content, "#FLIGHT") then
        for b in string.gmatch(content, "#FLIGHT[^\r\n]*[\r\n]+([^#]+)") do
          table.insert(existing_blocks, b)
          if #existing_blocks >= 4 then break end
        end
      else
        table.insert(existing_blocks, content)
      end
    end
  end

  local f = io.open(path, "w")
  if f then
    io.write(f, "#FLIGHT\n")
    for i = 1, #w.chart_data do
      local p = w.chart_data[i]
      io.write(f, string.format("%.2f,%.1f,%.0f,%.2f,%.0f\n", p.v or 0, p.a or 0, p.r or 0, p.b or 0, p.t or 0))
    end

    for i = 1, math.min(4, #existing_blocks) do
      local b = existing_blocks[i]
      if b and string.len(b) > 10 then
        io.write(f, "#FLIGHT\n" .. b)
        if string.sub(b, -1) ~= "\n" then io.write(f, "\n") end
      end
    end
    io.close(f)
  end
  w.selected_chart_idx = 1
end

function M.resetActiveBatLog(w)
  local l_path = getLogbookFilePath(w)
  local c_path = getChartFilePath(w)
  w.log_entries = {}
  w.chart_data = {}
  local f1 = io.open(l_path, "w"); if f1 then io.close(f1) end
  local f2 = io.open(c_path, "w"); if f2 then io.close(f2) end
  local bat_idx = getActiveBatIndex(w)
  if w.fleet_stats and bat_idx and w.fleet_stats[bat_idx] then
    local dt = (getDateTime and getDateTime()) or { year = 2000, mon = 1, day = 1 }
    local today = string.format("%04d-%02d-%02d", dt.year or 2000, dt.mon or 1, dt.day or 1)
    w.fleet_stats[bat_idx] = {
      id = bat_idx, last_date = today, today_count = 0, lifetime_cycles = 0,
      status = "NONE", min_v = "-", max_t = "-", avg_dur = "-", tot_dur_s = 0, tot_flights = 0, last_mah = 0
    }
    M.saveFleetData(w)
  end
  if playTone then playTone(1200, 150, 150, 0) end
end

return M
