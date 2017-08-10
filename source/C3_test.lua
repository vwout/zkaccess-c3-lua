require "lunit"
require "utils"
local C3 = require("C3")

module("c3_test", lunit.testcase, package.seeall)

function test_c3_time_decode()
  assert_equal(os.time({year=2017, month=07, day=30, hour=15, min=24, sec=32}), C3.byte_array_to_time({0x21, 0xad, 0x99, 0x30}))
  assert_equal(os.time({year=2017, month=07, day=30, hour=15, min=24, sec=32}), C3.byte_array_to_time(reverse_array({0x30, 0x99, 0xad, 0x21})))
  assert_equal(os.time({year=2013, month=10, day=8, hour=14, min=38, sec=32}),  C3.byte_array_to_time({0x1a, 0x61, 0x70, 0xe8}))
end

-- function test_c3_connect_disconnect()
--   C3.connect("192.168.3.103")
--   print("SessionId: " .. C3.SessionId())
--   C3.disconnect()
-- end

-- function test_c3_connect_rtlog()
  -- C3.connect("192.168.3.103")
  -- C3.getRTLog()
  -- C3.disconnect()
-- end

