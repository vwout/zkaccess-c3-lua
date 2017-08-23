-- Various conversion utilities
local utils = {}

-- convert string to table of bytes
function utils.str_to_arr(str, arr)
  local data = arr or {}
  for i = 1, #str do
    data[#data + 1] = string.byte(str, i)
  end
  return data
end

-- convert table of bytes to string
function utils.arr_to_str(bytes, str)
  local data = str or ""
  for _,v in ipairs(bytes) do
    data = data .. string.char(v)
  end
  return data
end

return utils