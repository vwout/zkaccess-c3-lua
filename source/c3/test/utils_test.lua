require "lunit"
require "c3.utils"

module("utils_test", lunit.testcase, package.seeall)

function test_str_to_arr()
  local str = "AB0!"
  local arr = str_to_arr(str)

  assert_equal(4, #str)
  assert_equal(4, #arr)
  assert_equal(65, arr[1])
  assert_equal(66, arr[2])
  assert_equal(48, arr[3])
  assert_equal(33, arr[4])

  local str2 = arr_to_str(str_to_arr(str))
  assert_equal(str, str2)
end

function test_arr_to_str()
  local arr = {116, 69, 115, 84}
  local str = arr_to_str(arr)

  assert_equal(4, #arr)
  assert_equal(4, #str)
  assert_equal("tEsT", str)
end
