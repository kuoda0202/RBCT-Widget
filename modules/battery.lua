-- RBCT Battery 6POS Detection Module
-- Author: 雷恩 / Ryan Kuo
-- Supports: TX16S MK3 hardware 6POS buttons + analog source fallback

local function convertAnalogToPos(val)
  if val == nil then return 0 end
  if type(val) == "boolean" then
    return val and 2 or 1
  end
  local v = tonumber(val) or 0
  -- If value is 1..6 integer directly (e.g. from Rotorflight PID# sensor)
  if v >= 1 and v <= 6 and math.floor(v) == v then
    return math.floor(v)
  end
  -- Normalize if value is in -1024..+1024 range
  if math.abs(v) > 120 then
    v = v / 10.24
  end
  -- 6-position thresholds in -100..+100 scale:
  -- MK3 hardware calibration (matches 1.0.701 working direction):
  -- Button 1 (LED 1) = -100% (-1024) -> BAT 1
  -- Button 2 (LED 2) = -60%  (-614)  -> BAT 2
  -- Button 3 (LED 3) = -20%  (-204)  -> BAT 3
  -- Button 4 (LED 4) = +20%  (+204)  -> BAT 4
  -- Button 5 (LED 5) = +60%  (+614)  -> BAT 5
  -- Button 6 (LED 6) = +100% (+1024) -> BAT 6
  if v < -66 then return 1
  elseif v < -33 then return 2
  elseif v < 0 then return 3
  elseif v < 33 then return 4
  elseif v < 66 then return 5
  else return 6
  end
end

local function getBatIndex(sourceVal)
  -- 1. ALWAYS scan individual hardware/logical switches first (6p1..6p6, sw1..sw6, L1..L6)
  --    This runs regardless of sourceVal, matching 1.0.701 behavior.
  if getValue then
    for i = 1, 6 do
      local names = {
        "6p" .. i, "6P" .. i, "6pos" .. i, "6POS" .. i,
        "sw" .. i, "SW" .. i, "l" .. i, "L" .. i,
        "6p_" .. i, "6P_" .. i
      }
      for j = 1, #names do
        local sv = getValue(names[j])
        if sv and ((type(sv) == "number" and sv > 500) or sv == true) then
          return i
        end
      end
    end
  end

  -- 2. Fallback to single analog 6POS / Channel / Pot source
  if not sourceVal then return 0 end

  return convertAnalogToPos(sourceVal)
end

return { getBatIndex = getBatIndex, convertAnalogToPos = convertAnalogToPos }
