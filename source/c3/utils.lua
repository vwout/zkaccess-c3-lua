-- Various conversion utilities
local utils = {}

-- Returns HEX (string) representation of num
function utils.num2hex(num)
  local hexstr = '0123456789abcdef'
  local s = ''

  while num > 0 do
    local mod = math.fmod(num, 16)
    s = string.sub(hexstr, mod+1, mod+1) .. s
    num = math.floor(num / 16)
  end

  if #s == 0 then s = '0' end
  if #s == 1 then s = '0' .. s end
  return s
end

-- Returns the number stored in the byte array in Big-Endian encoding
function utils.bytes_to_num(byte_array)
  local num = 0;

  for _,byte in ipairs(byte_array) do
    num = (num * 256) + byte
  end

  return num
end

-- Converts a C3 time byte array in Big-Endian encoding to a lua time struct
-- In the C3 protocol, the time is stored in seconds as a byte array
-- Decoding formula is as follows:
--   second = t % 60;
--   t /= 60;
--   minute = t % 60;
--   t /= 60;
--   hour = t % 24;
--   t /= 24;
--   day = t % 31 + 1;
--   t /= 31;
--   month = t % 12 + 1;
--   t /= 12;
--   year = t + 2000

function utils.byte_array_to_time(byte_array)
  local seconds_since_2000 = utils.bytes_to_num(byte_array)

  local time_t = {}
  time_t.sec = math.fmod(seconds_since_2000, 60)
  seconds_since_2000 = math.floor(seconds_since_2000 / 60)
  time_t.min = math.fmod(seconds_since_2000, 60)
  seconds_since_2000 = math.floor(seconds_since_2000 / 60)
  time_t.hour = math.fmod(seconds_since_2000, 24)
  seconds_since_2000 = math.floor(seconds_since_2000 / 24)
  time_t.day = math.fmod(seconds_since_2000, 31) + 1
  seconds_since_2000 = math.floor(seconds_since_2000 / 31)
  time_t.month = math.fmod(seconds_since_2000, 12) + 1
  seconds_since_2000 = math.floor(seconds_since_2000 / 12)
  time_t.year = seconds_since_2000 + 2000

  return os.time(time_t)
end

-- convert string to table of bytes
function utils.str_to_arr(str, arr)
  local data = arr or {}
  if str then
    for i = 1, #str do
      data[#data + 1] = string.byte(str, i)
    end
  end
  return data
end

-- convert table of bytes to string
function utils.arr_to_str(bytes, str)
  local data = str or ""
  if bytes then
    for _,v in ipairs(bytes) do
      data = data .. string.char(v)
    end
  end
  return data
end

return utils
