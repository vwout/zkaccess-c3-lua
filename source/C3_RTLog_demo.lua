#!/usr/bin/env lua5.1

require 'socket' -- for having a sleep function
local C3 = require("C3")

local c3_ip = arg[1]
if c3_ip == nil then
  print "Program requires one argument: IP address of the C3 device."
  os.exit(0)
end

C3.setDebug(false)

print("Connecting to " .. c3_ip .. " ... ")
local connected, err = C3.connect(c3_ip)
if connected then
  print("SessionId: " .. C3.getSessionId())
  print("Press Ctrl-C to stop.")

  while true do
    local rtlogs = C3.getRTLog()
    print("Received RT logs:" .. #rtlogs)
    
    for n,rtlog in pairs(rtlogs) do
      print(n)
      rtlog.print()
    end

    if not pcall(socket.sleep, 15) then
      break
    end
  end

  C3.disconnect()
  print("Disconnected.")
else 
  error("Connection failed:" .. err, 0)
end