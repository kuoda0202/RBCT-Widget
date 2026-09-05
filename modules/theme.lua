local function update(w, ctx)
  local lightSens = (w.options and (w.options["Light Sens"] or w.options["光感開關"] or w.options[9]))
  
  -- 如果没有 Light Sens，或者主题已经是 HiVis/F-35，就不做任何事情
  if not lightSens or lightSens == 0 then
    return
  end
  
  local val = getValue(lightSens) or 0
  local C, lcd = ctx.C, ctx.lcd
  
  -- 初始化 widget 状态
  if w._theme_state == nil then
    w._theme_state = {
      is_hivis = false,
      backup = {}
    }
  end
  local state = w._theme_state
  
  local should_be_hivis = state.is_hivis
  if type(val) == "number" then
    if val == 1 or val == 2 or val > 10 then
      should_be_hivis = true
    elseif val <= 4 then
      should_be_hivis = false
    end
  elseif type(val) == "boolean" then
    should_be_hivis = val
  end
  
  if should_be_hivis and not state.is_hivis then
    -- 备份颜色
    for k, v in pairs(C) do state.backup[k] = v end
    -- 切换到 HiVis
    C.bg = lcd.RGB(245, 245, 245)
    C.panel = lcd.RGB(220, 220, 220)
    C.panel2 = lcd.RGB(200, 200, 200)
    C.white = lcd.RGB(10, 10, 10)
    C.dim = lcd.RGB(80, 80, 80)
    C.blue = lcd.RGB(0, 0, 0)
    C.green = lcd.RGB(0, 150, 0)
    state.is_hivis = true
    w.force_solid_bg = true
  elseif not should_be_hivis and state.is_hivis then
    -- 恢复备份
    for k, v in pairs(state.backup) do C[k] = v end
    state.is_hivis = false
    w.force_solid_bg = false
  end
end

return { update = update }
