BGUI = BGUI or {}
BGUI.RadialSlice = {}

function BGUI.RadialSlice.build(candidates)
  local out = {}
  for i = 1, #candidates do
    local c = candidates[i]
    if c.enabled then
      out[#out + 1] = { id = c.id, label = c.label }
      if #out >= 8 then break end
    end
  end
  return out
end
