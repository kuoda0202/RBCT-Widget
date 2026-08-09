local function getBatIndex(sourceVal)
  -- 1. Scan individual hardware/logical switches (6p1..6p6, 6pos1..6pos6, sw1..sw6, L1..L6)
  if getValue then
    for i = 1, 6 do
      local names = {
        "6p" .. i, "6P" .. i, "6pos" .. i, "6POS" .. i,
        "sw" .. i, "SW" .. i, "l" .. i, "L" .. i
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
  if type(sourceVal) == "boolean" then
    return sourceVal and 2 or 1
  end
  
  local v = tonumber(sourceVal) or 0
  
  -- If value is 1..6 integer directly
  if v >= 1 and v <= 6 and math.floor(v) == v then
    return math.floor(v)
  end

  -- Normalize if value is in -1024..+1024 range
  if math.abs(v) > 120 then
    v = v / 10.24
  end
  
  -- 6-position thresholds in -100..+100 scale:
  if v < -66 then return 1
  elseif v < -33 then return 2
  elseif v < 0 then return 3
  elseif v < 33 then return 4
  elseif v < 66 then return 5
  else return 6
  end
end

return { getBatIndex = getBatIndex }
