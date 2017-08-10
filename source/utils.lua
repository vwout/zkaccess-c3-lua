-- Various conversion utilities

-- convert string to table of bytes
function str_to_arr(s, arr)
  local data = arr or {}
  for i = 1, #s do 
    data[#data + 1] = string.byte(s, i)
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

-- reverse the ordering of a sorted array (table)
function reverse_array(arr)
  local rev_arr = {}
  
  for i,v in ipairs(arr) do
    rev_arr[#arr - i + 1] = v
  end
  
  return rev_arr
end
