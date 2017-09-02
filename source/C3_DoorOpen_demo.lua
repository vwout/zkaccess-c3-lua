#!/usr/bin/env lua5.1

local C3 = require("c3.c3")
local consts = require("c3.consts")

if #arg < 3 or #arg > 4 then
  print "Usage: C3_RTLog_demo ip door,door,... open|close [duration=180]"
  os.exit(0)
end

local c3_ip = arg[1]

local c3_doors = {}
for door in string.gmatch(arg[2] or "", "([^,]+)") do
  local idoor = tonumber(door)
  if idoor then
    table.insert(c3_doors, idoor)
  end
end

local c3_open = nil
if arg[3] == "open" then
  c3_open = true
elseif arg[3] == "close" then
  c3_open = false
end

local c3_duration = tonumber(arg[4]) or 10

if c3_ip and next(c3_doors) and c3_open ~= nil then
  C3.setDebug(false)

  print("Connecting to " .. c3_ip .. " ... ")
  local connected, err = C3.connect(c3_ip)
  if connected then
    if not c3_open then
      c3_duration = 0
    end
    if c3_duration > 254 then
      c3_duration = 254
    end

    for _,door in ipairs(c3_doors) do
      if c3_open then
        print(string.format("Open door %d for %d seconds.", door, c3_duration))
      else
        print(string.format("Close door %d.", door))
      end

      local doorOpenOperation = C3.ControlDeviceOutput(door, consts.C3_CONTROL_OUTPUT_ADDRESS_DOOR_OUTPUT, c3_duration)
      C3.controlDevice(doorOpenOperation)
    end

    C3.disconnect()
    print("Disconnected.")
  else
    error("Connection failed:" .. err, 0)
  end
end
