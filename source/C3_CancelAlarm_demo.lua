#!/usr/bin/env lua5.1

local C3 = require("c3.c3")

if #arg ~= 1 then
  print "Usage: C3_AlarmReset_demo ip"
  os.exit(0)
end

local c3_ip = arg[1]
if c3_ip then
  C3.setDebug(false)

  print("Connecting to " .. c3_ip .. " ... ")
  local connected, err = C3.connect(c3_ip)
  if connected then
    local cancelAlarmOperation = C3.ControlDeviceCancelAlarm()
    C3.controlDevice(cancelAlarmOperation)

    C3.disconnect()
    print("Disconnected.")
  else
    error("Connection failed:" .. err, 0)
  end
end
