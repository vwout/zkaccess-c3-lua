local consts = require("c3.consts")

local ControlDevice = {}

-- A ControlDevice is a binary message of 5 bytes send to the C3 access panel.
-- It changes the states of the doors, auxilary relays and alarms.
-- All multi-byte values are stored as Little-endian.
--
-- Byte       0  1  2  3  4
--            01:01:01:c8:00
-- Operation: |
--            01 => 1 (1: output, 2: cancel alarm, 3: restart device, 4: enable/disable normal open state)
-- Param 1:      |
-- Param 2:         |
-- Param 3:            |
-- Param 4:               |
--
-- The meaning of the parameters is depending on the Operation code.
-- Param 4 is reserved for future use (defaults to 0)
-- Operation 1: Output operation
--   Param 1: Door number or auxiliary output number
--   Param 2: The address type of output operation (1: Door ouptput, 2: Auxiliary output)
--   Param 3: Duration of the open operation, only for address type = 1 (door output).
--            0: close, 255: normal open state, 1~254: normal open duration
-- Operation 2: Cancel alarm
--   Param 1: 0 (null)
--   Param 2: 0 (null)
--   Param 3: 0 (null)
-- Operation 3: Restart device
--   Param 1: 0 (null)
--   Param 2: 0 (null)
--   Param 3: 0 (null)
-- Operation 3: Enable/disable normal open state
--   Param 1: Door number
--   Param 2: Enable / disable (0: disable, 1: enable'
--   Param 3: 0 (null)
local function ControlDeviceBase(_operation, _param1, _param2, _param3)
  local function tobyte(val)
    val = tonumber(val) or 0
    if val < 0   then val = 0   end
    if val > 255 then val = 255 end
    return val
  end

  -- the new instance
  local self = {
    operation = _operation or 0,
    param1    = tobyte(_param1),
    param2    = tobyte(_param2),
    param3    = tobyte(_param3),
    param4    = 0
  }

  function self.from_byte_array(data_arr, from_idx)
    self.operation = data_arr[from_idx + 0]
    self.param1    = data_arr[from_idx + 1]
    self.param2    = data_arr[from_idx + 2]
    self.param3    = data_arr[from_idx + 3]
    self.param4    = data_arr[from_idx + 4]

    return self
  end

  function self.to_byte_array()
    local data = { self.operation, self.param1, self.param2, self.param3, self.param4 }
    return data
  end

  function self.print()
    print("ControlDevice Command:")
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "operation" then
          print("", string.format("%-10s", key), value, consts.C3_CONTROL_OPERATION[value])
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

function ControlDevice.Output(door_number, address, duration)
  local self = ControlDeviceBase(consts.C3_CONTROL_OPERATION_OUTPUT, door_number, address, duration)

  function self.print()
    print("ControlDeviceOutput Command:")
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "operation" then
          print("", string.format("%-10s", key), value, consts.C3_CONTROL_OPERATION[value])
        elseif key == "param1" then
          print("", string.format("%-10s", key), value, "Door number")
        elseif key == "param2" then
          print("", string.format("%-10s", key), value, consts.C3_CONTROL_OUTPUT_ADDRESS[value])
        elseif key == "param3" then
          print("", string.format("%-10s", key), value, "Duration")
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

function ControlDevice.CancelAlarm()
  local self = ControlDeviceBase(consts.C3_CONTROL_OPERATION_CANCEL_ALARM)
  -- return the instance
  return self
end

function ControlDevice.NOState(door_number, enable_disable)
  local self = ControlDeviceBase(consts.C3_CONTROL_OPERATION_ENDIS_NO_STATE, door_number, enable_disable)

  function self.print()
    print("ControlDeviceNOState Command:")
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "operation" then
          print("", string.format("%-10s", key), value, consts.C3_CONTROL_OPERATION[value])
        elseif key == "param1" then
          print("", string.format("%-10s", key), value, "Door number")
        elseif key == "param2" then
          print("", string.format("%-10s", key), value, value and "Enable" or "Disable")
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

function ControlDevice.RestartDevice()
  local self = ControlDeviceBase(consts.C3_CONTROL_OPERATION_RESTART_DEVICE)
  -- return the instance
  return self
end


return ControlDevice
