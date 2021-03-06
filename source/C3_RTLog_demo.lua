#!/usr/bin/env lua5.1

local socket = require("socket")  -- for having a sleep function
local C3 = require("c3.c3")

if #arg ~= 1 then
  print "Usage: C3_RTLog_demo ip"
  os.exit(0)
end

local c3_ip = arg[1]
if c3_ip then
  C3.setDebug(false)

  print("Connecting to " .. c3_ip .. " ... ")
  local connected, err = C3.connect(c3_ip)
  if connected then
    print("SessionId: " .. C3.getSessionId())
    print("Press Ctrl-C to stop.")

    while true do
      local has_da_status = false

      local rtlogs = C3.getRTLog()
      print("Received RT logs:" .. #rtlogs)

      for n,rtlog in pairs(rtlogs) do
        has_da_status = has_da_status or rtlog.is_dastatus()
        print(n)
        rtlog.print()
      end

      if has_da_status then
        if not pcall(socket.sleep, 15) then
          break
        end
      end
    end

    C3.disconnect()
    print("Disconnected.")
  else
    error("Connection failed:" .. err, 0)
  end
end
