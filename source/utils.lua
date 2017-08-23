-- Various conversion utilities

-- convert string to table of bytes
function str_to_arr(str, arr)
  local data = arr or {}
  for i = 1, #str do
    data[#data + 1] = string.byte(str, i)
  end
  return data
end

-- convert table of bytes to string
function arr_to_str(bytes, str)
  local data = str or ""
  for _,v in ipairs(bytes) do
    data = data .. string.char(v)
  end
  return data
end
