local lunit = require("lunit")
local utils = require("c3.utils")

module("utils_test", lunit.testcase, package.seeall)

function test_str_to_arr()
  local str = "AB0!"
  local arr = utils.str_to_arr(str)

  lunit.assert_equal(4, #str)
  lunit.assert_equal(4, #arr)
  lunit.assert_equal(65, arr[1])
  lunit.assert_equal(66, arr[2])
  lunit.assert_equal(48, arr[3])
  lunit.assert_equal(33, arr[4])

  local str2 = utils.arr_to_str(utils.str_to_arr(str))
  lunit.assert_equal(str, str2)
end

function test_arr_to_str()
  local arr = {116, 69, 115, 84}
  local str = utils.arr_to_str(arr)

  lunit.assert_equal(4, #arr)
  lunit.assert_equal(4, #str)
  lunit.assert_equal("tEsT", str)
end
