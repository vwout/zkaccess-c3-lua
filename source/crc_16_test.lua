require "lunit"
require "utils"
local CRC = require 'crc_16'

module("crc_16_test", lunit.testcase, package.seeall)

function test_crc_basic()
  -- Test data generated from https, http://www.lammertbies.nl/comm/info/crc-calculation.html
  assert_equal(0xBB3D, CRC.crc_16(str_to_arr("123456789")))
  assert_equal(0xE9D9, CRC.crc_16("abcdefg"))
  assert_equal(0x0F65, CRC.crc_16(str_to_arr("0123456789ABCDEF")))
end

function test_crc_connect()
  assert_equal(0x8fd7, CRC.crc_16(str_to_arr(string.char(0x01, 0x76, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00)))) --request
  assert_equal(0x3320, CRC.crc_16(string.char(0x01, 0xc8, 0x04, 0x00, 0xd6, 0xcd, 0x00, 0x00))) --response
  assert_equal(0x47c8, CRC.crc_16(str_to_arr(string.char(0x01, 0xc8, 0x04, 0x00, 0x54, 0xf1, 0x00, 0x00)))) --response
end

function test_crc_real_log()
  assert_equal(0xf687, CRC.crc_16(str_to_arr(string.char(0x01, 0x0b, 0x04, 0x00, 0x3e, 0xe3, 0x02, 0x00)))) --request
  assert_equal(0xbf72, CRC.crc_16(string.char(0x01, 0x0b, 0x04, 0x00, 0x78, 0xe5, 0x02, 0x00))) --request
  assert_equal(0xcd2c, CRC.crc_16(str_to_arr(string.char(0x01, 0xc8, 0x14, 0x00, 0x78, 0xe5, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x01, 0xff, 0x00, 0x00, 0x33, 0x75, 0x21)))) --response
  assert_equal(0x4f24, CRC.crc_16(string.char(0x01, 0xc8, 0x14, 0x00, 0x54, 0xf1, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x01, 0xff, 0x00, 0xda, 0x3e, 0x75, 0x21))) --response
end

function test_crc_disconnect()
  assert_equal(0x0fde, CRC.crc_16(str_to_arr(string.char(0x01, 0x02, 0x04, 0x00, 0x3a, 0xcf, 0x02, 0x00)))) --request  
  assert_equal(0x6a75, CRC.crc_16(str_to_arr(string.char(0x01, 0xc8, 0x04, 0x00, 0x3e, 0xe3, 0x03, 0x00)))) --request
end
