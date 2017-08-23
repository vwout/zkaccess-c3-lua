require "lunit"
require "utils"
local C3 = require("C3")

module("c3_test", lunit.testcase, package.seeall)

function assert_table_equal(expected, actual)
  assert_table(expected)
  assert_table(actual)
  
  assert_equal(#expected, #actual)
  for i = 1, #expected do
    assert_equal(expected[i], actual[i], "Mismatch at entry " .. i)
  end
end


function test_c3_time_decode()
  assert_equal(os.time({year=2017, month=07, day=30, hour=15, min=24, sec=32}), C3.byte_array_to_time({0x21, 0xad, 0x99, 0x30}))
  assert_equal(os.time({year=2013, month=10, day=8, hour=14, min=38, sec=32}),  C3.byte_array_to_time({0x1a, 0x61, 0x70, 0xe8}))
end

function test_c3_tableconfig_decode()
  local raw_data = { 0x75, 0x73, 0x65, 0x72, 0x3d, 0x31, 0x2c, 0x55, 0x49, 0x44, 0x3d, 0x69, 0x31, 0x2c, 0x43, 0x61, 0x72, 0x64, 0x4e, 0x6f, 0x3d, 0x69, 0x32, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x33, 0x2c, 0x50, 0x61, 0x73, 0x73, 0x77, 0x6f, 0x72, 0x64, 0x3d, 0x73, 0x34, 0x2c, 0x47, 0x72, 0x6f, 0x75, 0x70, 0x3d, 0x69, 0x35, 0x2c, 0x53, 0x74, 0x61, 0x72, 0x74, 0x54, 0x69, 0x6d, 0x65, 0x3d, 0x69, 0x36, 0x2c, 0x45, 0x6e, 0x64, 0x54, 0x69, 0x6d, 0x65, 0x3d, 0x69, 0x37, 0x2c, 0x4e, 0x61, 0x6d, 0x65, 0x3d, 0x73, 0x38, 0x2c, 0x53, 0x75, 0x70, 0x65, 0x72, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x7a, 0x65, 0x3d, 0x69, 0x39, 0x0a, 
                     0x75, 0x73, 0x65, 0x72, 0x61, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x7a, 0x65, 0x3d, 0x32, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x31, 0x2c, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x7a, 0x65, 0x54, 0x69, 0x6d, 0x65, 0x7a, 0x6f, 0x6e, 0x65, 0x49, 0x64, 0x3d, 0x69, 0x32, 0x2c, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x7a, 0x65, 0x44, 0x6f, 0x6f, 0x72, 0x49, 0x64, 0x3d, 0x69, 0x33, 0x0a, 
                     0x68, 0x6f, 0x6c, 0x69, 0x64, 0x61, 0x79, 0x3d, 0x33, 0x2c, 0x48, 0x6f, 0x6c, 0x69, 0x64, 0x61, 0x79, 0x3d, 0x69, 0x31, 0x2c, 0x48, 0x6f, 0x6c, 0x69, 0x64, 0x61, 0x79, 0x54, 0x79, 0x70, 0x65, 0x3d, 0x69, 0x32, 0x2c, 0x4c, 0x6f, 0x6f, 0x70, 0x3d, 0x69, 0x33, 0x0a, 
                     0x74, 0x69, 0x6d, 0x65, 0x7a, 0x6f, 0x6e, 0x65, 0x3d, 0x34, 0x2c, 0x54, 0x69, 0x6d, 0x65, 0x7a, 0x6f, 0x6e, 0x65, 0x49, 0x64, 0x3d, 0x69, 0x31, 0x2c, 0x53, 0x75, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x32, 0x2c, 0x53, 0x75, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x33, 0x2c, 0x53, 0x75, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x34, 0x2c, 0x4d, 0x6f, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x35, 0x2c, 0x4d, 0x6f, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x36, 0x2c, 0x4d, 0x6f, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x37, 0x2c, 0x54, 0x75, 0x65, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x38, 0x2c, 0x54, 0x75, 0x65, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x39, 0x2c, 0x54, 0x75, 0x65, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x31, 0x30, 0x2c, 0x57, 0x65, 0x64, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x31, 0x31, 0x2c, 0x57, 0x65, 0x64, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x31, 0x32, 0x2c, 0x57, 0x65, 0x64, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x31, 0x33, 0x2c, 0x54, 0x68, 0x75, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x31, 0x34, 0x2c, 0x54, 0x68, 0x75, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x31, 0x35, 0x2c, 0x54, 0x68, 0x75, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x31, 0x36, 0x2c, 0x46, 0x72, 0x69, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x31, 0x37, 0x2c, 0x46, 0x72, 0x69, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x31, 0x38, 0x2c, 0x46, 0x72, 0x69, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x31, 0x39, 0x2c, 0x53, 0x61, 0x74, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x32, 0x30, 0x2c, 0x53, 0x61, 0x74, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x32, 0x31, 0x2c, 0x53, 0x61, 0x74, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x32, 0x32, 0x2c, 0x48, 0x6f, 0x6c, 0x31, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x32, 0x33, 0x2c, 0x48, 0x6f, 0x6c, 0x31, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x32, 0x34, 0x2c, 0x48, 0x6f, 0x6c, 0x31, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x32, 0x35, 0x2c, 0x48, 0x6f, 0x6c, 0x32, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x32, 0x36, 0x2c, 0x48, 0x6f, 0x6c, 0x32, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x32, 0x37, 0x2c, 0x48, 0x6f, 0x6c, 0x32, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x32, 0x38, 0x2c, 0x48, 0x6f, 0x6c, 0x33, 0x54, 0x69, 0x6d, 0x65, 0x31, 0x3d, 0x69, 0x32, 0x39, 0x2c, 0x48, 0x6f, 0x6c, 0x33, 0x54, 0x69, 0x6d, 0x65, 0x32, 0x3d, 0x69, 0x33, 0x30, 0x2c, 0x48, 0x6f, 0x6c, 0x33, 0x54, 0x69, 0x6d, 0x65, 0x33, 0x3d, 0x69, 0x33, 0x31, 0x0a, 
                     0x74, 0x72, 0x61, 0x6e, 0x73, 0x61, 0x63, 0x74, 0x69, 0x6f, 0x6e, 0x3d, 0x35, 0x2c, 0x43, 0x61, 0x72, 0x64, 0x6e, 0x6f, 0x3d, 0x69, 0x31, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x32, 0x2c, 0x56, 0x65, 0x72, 0x69, 0x66, 0x69, 0x65, 0x64, 0x3d, 0x69, 0x33, 0x2c, 0x44, 0x6f, 0x6f, 0x72, 0x49, 0x44, 0x3d, 0x69, 0x34, 0x2c, 0x45, 0x76, 0x65, 0x6e, 0x74, 0x54, 0x79, 0x70, 0x65, 0x3d, 0x69, 0x35, 0x2c, 0x49, 0x6e, 0x4f, 0x75, 0x74, 0x53, 0x74, 0x61, 0x74, 0x65, 0x3d, 0x69, 0x36, 0x2c, 0x54, 0x69, 0x6d, 0x65, 0x5f, 0x73, 0x65, 0x63, 0x6f, 0x6e, 0x64, 0x3d, 0x69, 0x37, 0x0a, 
                     0x66, 0x69, 0x72, 0x73, 0x74, 0x63, 0x61, 0x72, 0x64, 0x3d, 0x36, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x31, 0x2c, 0x44, 0x6f, 0x6f, 0x72, 0x49, 0x44, 0x3d, 0x69, 0x32, 0x2c, 0x54, 0x69, 0x6d, 0x65, 0x7a, 0x6f, 0x6e, 0x65, 0x49, 0x44, 0x3d, 0x69, 0x33, 0x0a, 
                     0x6d, 0x75, 0x6c, 0x74, 0x69, 0x6d, 0x63, 0x61, 0x72, 0x64, 0x3d, 0x37, 0x2c, 0x49, 0x6e, 0x64, 0x65, 0x78, 0x3d, 0x69, 0x31, 0x2c, 0x44, 0x6f, 0x6f, 0x72, 0x49, 0x64, 0x3d, 0x69, 0x32, 0x2c, 0x47, 0x72, 0x6f, 0x75, 0x70, 0x31, 0x3d, 0x69, 0x33, 0x2c, 0x47, 0x72, 0x6f, 0x75, 0x70, 0x32, 0x3d, 0x69, 0x34, 0x2c, 0x47, 0x72, 0x6f, 0x75, 0x70, 0x33, 0x3d, 0x69, 0x35, 0x2c, 0x47, 0x72, 0x6f, 0x75, 0x70, 0x34, 0x3d, 0x69, 0x36, 0x2c, 0x47, 0x72, 0x6f, 0x75, 0x70, 0x35, 0x3d, 0x69, 0x37, 0x0a, 
                     0x69, 0x6e, 0x6f, 0x75, 0x74, 0x66, 0x75, 0x6e, 0x3d, 0x38, 0x2c, 0x49, 0x6e, 0x64, 0x65, 0x78, 0x3d, 0x69, 0x31, 0x2c, 0x45, 0x76, 0x65, 0x6e, 0x74, 0x54, 0x79, 0x70, 0x65, 0x3d, 0x69, 0x32, 0x2c, 0x49, 0x6e, 0x41, 0x64, 0x64, 0x72, 0x3d, 0x69, 0x33, 0x2c, 0x4f, 0x75, 0x74, 0x54, 0x79, 0x70, 0x65, 0x3d, 0x69, 0x34, 0x2c, 0x4f, 0x75, 0x74, 0x41, 0x64, 0x64, 0x72, 0x3d, 0x69, 0x35, 0x2c, 0x4f, 0x75, 0x74, 0x54, 0x69, 0x6d, 0x65, 0x3d, 0x69, 0x36, 0x2c, 0x52, 0x65, 0x73, 0x65, 0x72, 0x76, 0x65, 0x64, 0x3d, 0x69, 0x37, 0x0a, 
                     0x74, 0x65, 0x6d, 0x70, 0x6c, 0x61, 0x74, 0x65, 0x3d, 0x39, 0x2c, 0x53, 0x69, 0x7a, 0x65, 0x3d, 0x69, 0x31, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x32, 0x2c, 0x46, 0x69, 0x6e, 0x67, 0x65, 0x72, 0x49, 0x44, 0x3d, 0x69, 0x33, 0x2c, 0x56, 0x61, 0x6c, 0x69, 0x64, 0x3d, 0x69, 0x34, 0x2c, 0x54, 0x65, 0x6d, 0x70, 0x6c, 0x61, 0x74, 0x65, 0x3d, 0x73, 0x35, 0x0a, 
                     0x74, 0x65, 0x6d, 0x70, 0x6c, 0x61, 0x74, 0x65, 0x76, 0x31, 0x30, 0x3d, 0x31, 0x30, 0x2c, 0x53, 0x69, 0x7a, 0x65, 0x3d, 0x69, 0x31, 0x2c, 0x55, 0x49, 0x44, 0x3d, 0x69, 0x32, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x33, 0x2c, 0x46, 0x69, 0x6e, 0x67, 0x65, 0x72, 0x49, 0x44, 0x3d, 0x69, 0x34, 0x2c, 0x56, 0x61, 0x6c, 0x69, 0x64, 0x3d, 0x69, 0x35, 0x2c, 0x54, 0x65, 0x6d, 0x70, 0x6c, 0x61, 0x74, 0x65, 0x3d, 0x42, 0x36, 0x2c, 0x52, 0x65, 0x73, 0x76, 0x65, 0x72, 0x64, 0x3d, 0x69, 0x37, 0x2c, 0x45, 0x6e, 0x64, 0x54, 0x61, 0x67, 0x3d, 0x69, 0x38, 0x0a, 
                     0x6c, 0x6f, 0x73, 0x73, 0x63, 0x61, 0x72, 0x64, 0x3d, 0x31, 0x31, 0x2c, 0x43, 0x61, 0x72, 0x64, 0x4e, 0x6f, 0x3d, 0x69, 0x31, 0x2c, 0x52, 0x65, 0x73, 0x65, 0x72, 0x76, 0x65, 0x64, 0x3d, 0x69, 0x32, 0x0a,
                     0x75, 0x73, 0x65, 0x72, 0x74, 0x79, 0x70, 0x65, 0x3d, 0x31, 0x32, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x31, 0x2c, 0x54, 0x79, 0x70, 0x65, 0x3d, 0x69, 0x32, 0x0a, 
                     0x77, 0x69, 0x65, 0x67, 0x61, 0x6e, 0x64, 0x66, 0x6d, 0x74, 0x3d, 0x31, 0x33, 0x2c, 0x50, 0x69, 0x6e, 0x3d, 0x69, 0x31, 0x2c, 0x4e, 0x61, 0x6d, 0x65, 0x3d, 0x73, 0x32, 0x2c, 0x57, 0x67, 0x43, 0x6f, 0x75, 0x6e, 0x74, 0x3d, 0x69, 0x33, 0x2c, 0x46, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x3d, 0x73, 0x34, 0x0a }
  local configs = C3.datatableconfig_decode(raw_data)

  local config_count = 0
  for _,config in pairs(configs) do 
    config.print()
    config_count = config_count + 1
  end
  assert_equal(13, config_count)
  assert_equal(1, configs['user'].id)
  assert_equal(5, configs['transaction'].id)
  assert_equal('DoorID', configs['transaction'].fields[4].name)
  assert_equal('i', configs['transaction'].fields[4].fmt)
  assert_equal('s', configs['wiegandfmt'].fields[4].fmt)
  assert_equal('FriTime2', configs['timezone'].fields[18].name)
  
end

function test_c3_rtlog_decode()
  local rtlog_raw_data = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0x66, 0x02, 0x32, 0x8f, 0xae, 0x21, 
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xc9, 0x02, 0xea, 0x8f, 0xae, 0x21, 
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xca, 0x02, 0x33, 0x27, 0xaf, 0x21,
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xc8, 0x02, 0x34, 0x27, 0xaf, 0x21, 
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xca, 0x02, 0x80, 0x27, 0xaf, 0x21, 
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xc9, 0x02, 0x94, 0x27, 0xaf, 0x21, 
                           0x17, 0x30, 0x64, 0x12, 0xe2, 0xb1, 0x04, 0x00, 0x04, 0x01, 0x00, 0x00, 0x74, 0x2c, 0xaf, 0x21, 
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xc8, 0x02, 0x75, 0x2c, 0xaf, 0x21, 
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xca, 0x02, 0x88, 0x2c, 0xaf, 0x21,
                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xc9, 0x02, 0x9d, 0x2c, 0xaf, 0x21 }
  local rtlogs = C3.rtlog_decode(rtlog_raw_data)

  assert_equal(10, #rtlogs)
  assert_equal(1501491250, rtlogs[1].time_second) -- Mon Jul 31 08:54:10 2017
  assert_equal(1501531508, rtlogs[7].time_second) -- Mon Jul 31 20:05:08 2017
  for n,rtlog in pairs(rtlogs) do
    assert_false(rtlog.is_dastatus())
    assert_true(rtlog.is_event())

    print(n)
    rtlog.print()
  end
end

function test_c3_rtlog_decode_status()
  local rtlog_raw_data = { 0x03, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x01, 0xff, 0x00, 0xf2, 0x31, 0xb3, 0x21,
                           -- 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0x08, 0x02, 0xf4, 0x31, 0xb3, 0x21,   --Remote Opening
                           -- 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0xc8, 0x02, 0xf5, 0x31, 0xb3, 0x21,   --Door Opened Correctly
                           0x03, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0xff, 0x00, 0xfc, 0x31, 0xb3, 0x21 }

                           
                           
  local rtlogs = C3.rtlog_decode(rtlog_raw_data)

  assert_equal(2, #rtlogs)
  assert_not_nil(next(rtlogs[1].get_alarms()))
  assert_true(rtlogs[2].has_alarm())
  assert_true(rtlogs[1].has_alarm(1))
  assert_false(rtlogs[1].has_alarm(2))
  assert_true(rtlogs[1].has_alarm(1, 1))
  assert_true(rtlogs[1].has_alarm(1, 2))
  assert_false(rtlogs[1].has_alarm(1, 3))
  assert_nil(rtlogs[1].is_open(1))
  assert_nil(rtlogs[1].is_open(3))
  assert_true(rtlogs[2].is_open(1))
  assert_nil(rtlogs[2].is_open(2))
  
  for n,rtlog in pairs(rtlogs) do
    assert_true(rtlog.is_dastatus())
    assert_false(rtlog.is_event())

    print(n)
    rtlog.print()
  end
end


function test_c3_device_control_message_output()
  local output_operation = C3.ControlDeviceOutput(1, 1, 200)
  assert_table(output_operation)
  assert_table_equal({0x01, 0x01, 0x01, 0xc8, 0x00}, output_operation.to_byte_array())
  output_operation.print()
end

function test_c3_device_control_message_cancel()
  local output_operation = C3.ControlDeviceCancelAlarm()
  assert_table(output_operation)
  assert_table_equal({0x02, 0x00, 0x00, 0x00, 0x00}, output_operation.to_byte_array())
  output_operation.print()
end

function test_c3_device_control_message_restart()
  local output_operation = C3.ControlDeviceRestartDevice()
  assert_table(output_operation)
  assert_table_equal({0x03, 0x00, 0x00, 0x00, 0x00}, output_operation.to_byte_array())
  output_operation.print()
end

function test_c3_device_control_message_nostate()
  local output_operation = C3.ControlDeviceNOState(2, 1)
  assert_table(output_operation)
  assert_table_equal({0x04, 0x02, 0x01, 0x00, 0x00}, output_operation.to_byte_array())
  output_operation.print()
end
