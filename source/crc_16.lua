-- Ported CRC-16 from libcrc.org
-- (https://github.com/lammertb/libcrc/blob/master/src/crc16.c)

local CRC_POLY_16 = 0xA001
local CRC_START_16 = 0x0000


local M = {_TYPE='module', _NAME='crc_16', _VERSION='0.1'}


--[[
 Requires the first module listed that exists, else raises like `require`.
 If a non-string is encountered, it is returned.
 Second return value is module name loaded (or '').
 
 Credits: https://pastebin.com/XsP9NcVA
 --]]
local function requireany(...)
  local errs = {}
  for _,name in ipairs{...} do
    if type(name) ~= 'string' then return name, '' end
    local ok, mod = pcall(require, name)
    if ok then return mod, name end
    errs[#errs+1] = mod
  end
  error(table.concat(errs, '\n'), 2)
end

-- Try to use whatever bit-manipulation library that is available
local bit, name_ = requireany('bit', 'nixio.bit', 'bit32', 'bit.numberlua')


function M.crc_16_byte(byte, crc)

  local function calc_divisor(byte)
    local poly = 0
       
    for i = 0, 7 do
        if bit.band(bit.bxor(poly, byte), 0x0001) == 1 then
            poly = bit.bxor(bit.rshift(poly, 1), CRC_POLY_16)
        else
            poly = bit.rshift(poly, 1)
        end
        
        byte = bit.rshift(byte, 1)
    end
    
    return poly --bit.band(poly, 0xFFFF)     -- Truncate to 16bit
  end
  
  local crc = bit.band(crc, 0xFFFF)   -- Truncate to 16bit
  local msb = bit.rshift(crc, 8)      -- Take msb from 16bit crc
  local crc_div = calc_divisor(bit.bxor(crc, byte))
  
  crc = bit.bxor(msb, crc_div)
  
  return crc --bit.band(crc, 0xFFFF)
end
local M_crc_16_byte = M.crc_16_byte


function M.crc_16_string(str, crc)
  crc = crc or CRC_START_16
  
  for i = 1, #str do 
    crc = M_crc_16_byte(string.byte(str, i), crc)
  end

  return crc
end
local M_crc_16_string = M.crc_16_string


function M.crc_16_byte_array(byte_array, crc)
  crc = crc or CRC_START_16
  
  for _,byte in ipairs(byte_array) do
    if type(byte) == 'string' then
      crc = M_crc_16_string(byte, crc)
    else
      crc = M_crc_16_byte(byte, crc)
    end
  end
  
  return crc
end
local M_crc_16_byte_array = M.crc_16_byte_array


function M.crc_16(data, crc)
  if type(data) == 'string' then
    return M_crc_16_string(data, crc)
  elseif type(data) == 'table' then
    return M_crc_16_byte_array(data, crc)
  else
    return M_crc_16_byte(data, crc)
  end
end

-- Return the CRC LSB
function M.lsb(crc)
  return bit.band(crc, 0x00FF)
end

-- Return the CRC MSB
function M.msb(crc)
  return bit.rshift(crc, 8)
end


return M