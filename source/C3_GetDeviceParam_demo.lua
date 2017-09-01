#!/usr/bin/env lua5.1

local C3 = require("c3.c3")

if #arg ~= 1 then
  print "Usage: C3_GetDeviceParam_demo ip"
  os.exit(0)
end

local c3_ip = arg[1]
if c3_ip then
  C3.setDebug(false)

  print("Connecting to " .. c3_ip .. " ... ")
  local connected, err = C3.connect(c3_ip)
  if connected then
    local parameters = C3.getDeviceParameters({ "~SerialNumber",
                                                "LockCount",
                                                "ReaderCount",
                                                "AuxInCount",
                                                "AuxOutCount",
                                                "DateTime" })
    for k, v in pairs(parameters) do
      print(string.format("- %s: %s", k, v))
    end

    C3.disconnect()
    print("Disconnected.")
  else
    error("Connection failed:" .. err, 0)
  end
end
