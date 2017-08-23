-- Imports
local socket = require("socket")
local CRC = require("crc_16")
require "utils"


-- Defaults
local PORT_DEFAULT = 4370

-- COMMANDS
local C3_MESSAGE_START        = 0xAA
local C3_MESSAGE_END          = 0x55
local C3_PROTOCOL_VERSION     = 0x01
local C3_COMMAND_CONNECT      = { request=0x76, reply=0xC8 }
local C3_COMMAND_DISCONNECT   = { request=0x02, reply=0xC8 }
local C3_COMMAND_DATATABLECFG = { request=0x06, reply=0xC8 }
local C3_COMMAND_CONTROL      = { request=0x05, reply=0xC8 }
local C3_COMMAND_RTLOG        = { request=0x0B, reply=0xC8 }

-- constants and tables
local C3_CONTROL_OPERATION_OUTPUT         = 1
local C3_CONTROL_OPERATION_CANCEL_ALARM   = 2
local C3_CONTROL_OPERATION_RESTART_DEVICE = 3
local C3_CONTROL_OPERATION_ENDIS_NO_STATE = 4
local C3_CONTROL_OPERATION  = { [C3_CONTROL_OPERATION_OUTPUT]         = "Output operation (door or auxilary)",
                                [C3_CONTROL_OPERATION_CANCEL_ALARM]   = "Cancel alarm",
                                [C3_CONTROL_OPERATION_RESTART_DEVICE] = "Restart Device",
                                [C3_CONTROL_OPERATION_ENDIS_NO_STATE] = "Enable/disable normal open state" }

local C3_CONTROL_OUTPUT_ADDRESS_DOOR_OUTPUT = 1
local C3_CONTROL_OUTPUT_ADDRESS_AUX_OUTPUT  = 2
local C3_CONTROL_OUTPUT_ADDRESS  = { [C3_CONTROL_OUTPUT_ADDRESS_DOOR_OUTPUT] = "Door output",
                                     [C3_CONTROL_OUTPUT_ADDRESS_AUX_OUTPUT]  = "Auxiliary output" }

local C3_VERIFIED_MODE      = { [1]   = "Only finger",
                                [3]   = "Only password",
                                [4]   = "Only card",
                                [11]  = "Card and password",
                                [200] = "Others" }

local C3_EVENT_TYPE_DOOR_ALARM_STATUS = 255
local C3_EVENT_TYPE         = { [0]   = "Normal Punch Open",
                                [1]   = "Punch during Normal Open Time Zone",
                                [2]   = "First Card Normal Open (Punch Card)",
                                [3]   = "Multi-Card Open (Punching Card)",
                                [4]   = "Emergency Password Open",
                                [5]   = "Open during Normal Open Time Zone",
                                [6]   = "Linkage Event Triggered",
                                [7]   = "Cancel Alarm",
                                [8]   = "Remote Opening",
                                [9]   = "Remote Closing",
                                [10]  = "Disable Intraday Normal Open Time Zone",
                                [11]  = "Enable Intraday Normal Open Time Zone",
                                [12]  = "Open Auxiliary Output",
                                [13]  = "Close Auxiliary Output",
                                [14]  = "Press Fingerprint Open",
                                [15]  = "Multi-Card Open (Press Fingerprint)",
                                [16]  = "Press Fingerprint during Normal Open Time Zone",
                                [17]  = "Card plus Fingerprint Open",
                                [18]  = "First Card Normal Open (Press Fingerprint)",
                                [19]  = "First Card Normal Open (Card plus Fingerprint)",
                                [20]  = "Too Short Punch Interval",
                                [21]  = "Door Inactive Time Zone (Punch Card)",
                                [22]  = "Illegal Time Zone",
                                [23]  = "Access Denied",
                                [24]  = "Anti-Passback",
                                [25]  = "Interlock",
                                [26]  = "Multi-Card Authentication (Punching Card)",
                                [27]  = "Unregistered Card",
                                [28]  = "Opening Timeout:",
                                [29]  = "Card Expired",
                                [30]  = "Password Error",
                                [31]  = "Too Short Fingerprint Pressing Interval",
                                [32]  = "Multi-Card Authentication (Press Fingerprint)",
                                [33]  = "Fingerprint Expired",
                                [34]  = "Unregistered Fingerprint",
                                [35]  = "Door Inactive Time Zone (Press Fingerprint)",
                                [36]  = "Door Inactive Time Zone (Exit Button)",
                                [37]  = "Failed to Close during Normal Open Time Zone",
                                [101] = "Duress Password Open",
                                [102] = "Opened Accidentally",
                                [103] = "Duress Fingerprint Open",
                                [200] = "Door Opened Correctly",
                                [201] = "Door Closed Correctly",
                                [202] = "Exit button Open",
                                [203] = "Multi-Card Open (Card plus Fingerprint)",
                                [204] = "Normal Open Time Zone Over",
                                [205] = "Remote Normal Opening",
                                [206] = "Device Start",
                                [220] = "Auxiliary Input Disconnected",
                                [221] = "Auxiliary Input Shorted",
                                [C3_EVENT_TYPE_DOOR_ALARM_STATUS] = "Current door and alarm status" }

local C3_INOUT_STATUS_ENTRY = 0
local C3_INOUT_STATUS_EXIT  = 3
local C3_INOUT_STATUS_NONE  = 2
local C3_INOUT_STATUS       = { [C3_INOUT_STATUS_ENTRY] = "Entry",
                                [C3_INOUT_STATUS_EXIT]  = "Exit",
                                [C3_INOUT_STATUS_NONE]  = "None" }

local C3_ALARM_STATUS       = { [0] = "None",
                                [1] = "Alarm",
                                [2] = "Door opening timeout" }

local C3_DSS_STATUS_UNKNOWN = 0
local C3_DSS_STATUS_CLOSED  = 1
local C3_DSS_STATUS_OPEN    = 2
local C3_DSS_STATUS         = { [C3_DSS_STATUS_UNKNOWN] = "No Door Status Sensor",
                                [C3_DSS_STATUS_CLOSED]  = "Door closed",
                                [C3_DSS_STATUS_OPEN]    = "Door open" }


--- Returns HEX representation of num
local function num2hex(num)
  local hexstr = '0123456789abcdef'
  local s = ''

  while num > 0 do
    local mod = math.fmod(num, 16)
    s = string.sub(hexstr, mod+1, mod+1) .. s
    num = math.floor(num / 16)
  end

  if #s == 0 then s = '0' end
  if #s == 1 then s = '0' .. s end
  return s
end

local function bytes_to_num(byte_array)
  local num = 0;

  for _,byte in ipairs(byte_array) do
    num = (num * 256) + byte
  end

  return num
end

function byte_array_to_time(byte_array)
  local seconds_since_2000 = bytes_to_num(byte_array)

  local time_t = {}
  time_t.sec = math.fmod(seconds_since_2000, 60)
  seconds_since_2000 = math.floor(seconds_since_2000 / 60)
  time_t.min = math.fmod(seconds_since_2000, 60)
  seconds_since_2000 = math.floor(seconds_since_2000 / 60)
  time_t.hour = math.fmod(seconds_since_2000, 24)
  seconds_since_2000 = math.floor(seconds_since_2000 / 24)
  time_t.day = math.fmod(seconds_since_2000, 31) + 1
  seconds_since_2000 = math.floor(seconds_since_2000 / 31)
  time_t.month = math.fmod(seconds_since_2000, 12) + 1
  seconds_since_2000 = math.floor(seconds_since_2000 / 12)
  time_t.year = seconds_since_2000 + 2000

  return os.time(time_t)
end

local debug_enabled = false    -- Internal flag to enable debugging, see M.set_debug()

local function dump_message_arr(what, message)
  local s = ''

  if debug_enabled then
    for _,byte in ipairs(message) do
      s = s .. num2hex(byte) .. ' '
    end
    print(string.format(". %-40s", what), s)
  end
end

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
--            0: disable, 255: normal open state, 1~254: normal open duration
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
  -- the new instance
  local self = {
    operation = _operation or 0,
    param1    = _param1 or 0,
    param2    = _param2 or 0,
    param3    = _param3 or 0,
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
    data = { self.operation, self.param1, self.param2, self.param3, self.param4 }
    return data
  end

  function self.print()
    print("ControlDevice Command:")
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "operation" then
          print("", string.format("%-10s", key), value, C3_CONTROL_OPERATION[value])
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

function ControlDeviceOutput(door_number, address, duration)
  local self = ControlDeviceBase(C3_CONTROL_OPERATION_OUTPUT, door_number, address, duration)

  function self.print()
    print("ControlDeviceOutput Command:")
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "operation" then
          print("", string.format("%-10s", key), value, C3_CONTROL_OPERATION[value])
        elseif key == "param1" then
          print("", string.format("%-10s", key), value, "Door number")
        elseif key == "param2" then
          print("", string.format("%-10s", key), value, C3_CONTROL_OUTPUT_ADDRESS[value])
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

function ControlDeviceCancelAlarm()
  local self = ControlDeviceBase(C3_CONTROL_OPERATION_CANCEL_ALARM)
  -- return the instance
  return self
end

function ControlDeviceNOState(door_number, enable_disable)
  local self = ControlDeviceBase(C3_CONTROL_OPERATION_ENDIS_NO_STATE, door_number, enable_disable)

  function self.print()
    print("ControlDeviceNOState Command:")
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "operation" then
          print("", string.format("%-10s", key), value, C3_CONTROL_OPERATION[value])
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

function ControlDeviceRestartDevice()
  local self = ControlDeviceBase(C3_CONTROL_OPERATION_RESTART_DEVICE)
  -- return the instance
  return self
end


-- An RTLog is a binary message of 16 bytes send by the C3 access panel.
-- If the value of byte 10 (the event type) is 255, the RTLog is a Door/Alarm Realtime status.
-- All multi-byte values are stored as Little-endian.
--
-- Byte:                    0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
--                          01:4f:86:00:99:92:98:00:04:01:00:00:a5:ad:ad:21
-- Alarm status (byte 4-7):             |
--                                      99:92:98:00 => (big endian:) 00989299 = 9999001
-- DSS status (byte 0-3):   |
--                          01:4f:86:00 => (big endian:) 00864f01 = 8802049
-- Verified (byte 8):                               |
--                                                  04
-- Unused (byte 9):                                    |
--                                                     01
-- EventType (byte 10):                                   |
--                                                        00
-- Unused (byte 11):                                         |
--                                                           00
--                                                              |
-- Time_second (byte 12-15)                                     a5:ad:ad:21 => (big endian:) 21ADADA5 = 2017-7-30 16:51:49
local function RTDAStatusRecord()
  local self = {
    alarm_status = 0,
    dss_status   = 0,
    verified     = 0,
    event_type   = 0,
    time_second  = 0
  }

  function self.is_dastatus()
    return true
  end

  function self.is_event()
    return false
  end

  function self.from_byte_array(data_arr, from_idx)
    self.alarm_status = { [1] = data_arr[from_idx + 0],
                          [2] = data_arr[from_idx + 1],
                          [3] = data_arr[from_idx + 2],
                          [4] = data_arr[from_idx + 3] }
    self.dss_status   = { [1] = data_arr[from_idx + 4],
                          [2] = data_arr[from_idx + 5],
                          [3] = data_arr[from_idx + 6],
                          [4] = data_arr[from_idx + 7] }
    self.verified     = data_arr[from_idx + 8]
    self.event_type   = data_arr[from_idx + 10]
    self.time_second  = byte_array_to_time({ data_arr[from_idx + 15],
                                             data_arr[from_idx + 14],
                                             data_arr[from_idx + 13],
                                             data_arr[from_idx + 12] })

    return self
  end

  function self.get_alarms(door_nr)
    local alarms = {}

    for i,status in ipairs(self.alarm_status) do
      if door_nr == i or not door_nr then
        for k,_ in pairs(C3_ALARM_STATUS) do
          if k ~= 0 then
            if CRC.bit.band(status, k) == k then
              table.insert(alarms, k)
            end
          end
        end
      end
    end

    return alarms
  end

  function self.has_alarm(door_nr, alarm_status)
    local result = false

    for _,alarm in ipairs(self.get_alarms(door_nr)) do
      if alarm == alarm_status or not alarm_status then
        result = true
      end
    end

    return result
  end

  function self.is_open(door_nr)
    assert(door_nr)

    local open = nil
    if self.dss_status[door_nr] == C3_DSS_STATUS_OPEN then
      open = true
    elseif self.dss_status[door_nr] == C3_DSS_STATUS_CLOSED then
      open = false
    end

    return open
  end

  function self.print()
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "time_second" then
          print("", string.format("%-10s", key), value, os.date("%c", value))
        elseif key == "event_type" then
          print("", string.format("%-10s", key), value, C3_EVENT_TYPE[value])
        elseif key == "verified" then
          print("", string.format("%-10s", key), value, C3_VERIFIED_MODE[value])
        elseif key == "alarm_status" then
          print("", string.format("%-10s", key))

          local function concat_if_in_bitset(value, tbl, str_arr)
            str_arr = str_arr or {}

            if tbl[0] and value == 0 then
              table.insert(str_arr, tbl[0])
            else
              for k,v in pairs(tbl) do
                if k ~= 0 then
                  if CRC.bit.band(value, k) == k then
                    table.insert(str_arr, v)
                  end
                end
              end
            end

            return table.concat(str_arr, ", ")
          end

          for i,v in ipairs(value) do
            print("", "", string.format("Door %-10i", i), v, concat_if_in_bitset(v, C3_ALARM_STATUS))
          end
        elseif key == "dss_status" then
          print("", string.format("%-10s", key))
          for i,v in ipairs(value) do
            print("", "", string.format("Door %-10i", i), v, C3_DSS_STATUS[v])
          end
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

-- An RTLog is a binary message of 16 bytes send by the C3 access panel.
-- If the value of byte 10 (the event type) is not 255, the RTLog is a Realtime Event.
-- All multi-byte values are stored as Little-endian.
--
-- Byte:              0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
--                    01:4f:86:00:99:92:98:00:04:01:00:00:a5:ad:ad:21
-- Cardno (byte 4-7):             |
--                                99:92:98:00 => (big endian:) 00989299 = 9999001
-- Pin (byte 0-3):    |
--                    01:4f:86:00 => (big endian:) 00864f01 = 8802049
-- Verified (byte 8):                         |
--                                            04
-- DoorID (byte 9):                              |
--                                               01
-- EventType (byte 10):                             |
--                                                  00
-- InOutState (byte 11):                               |
--                                                     00
--                                                        |
-- Time_second (byte 12-15)                               a5:ad:ad:21 => (big endian:) 21ADADA5 = 2017-7-30 16:51:49
local function RTEventRecord()
  -- the new instance
  local self = {
    card_no      = 0,
    pin          = 0,
    verified     = 0,
    door_id      = 0,
    event_type   = 0,
    in_out_state = C3_INOUT_STATUS_NONE,
    time_second  = 0
  }

  function self.is_dastatus()
    return false
  end

  function self.is_event()
    return true
  end

  function self.from_byte_array(data_arr, from_idx)
    self.card_no      = bytes_to_num({ data_arr[from_idx + 3],
                                       data_arr[from_idx + 2],
                                       data_arr[from_idx + 1],
                                       data_arr[from_idx + 0] })
    self.pin          = bytes_to_num({ data_arr[from_idx + 7],
                                       data_arr[from_idx + 6],
                                       data_arr[from_idx + 5],
                                       data_arr[from_idx + 4] })
    self.verified     = data_arr[from_idx + 8]
    self.door_id      = data_arr[from_idx + 9]
    self.event_type   = data_arr[from_idx + 10]
    self.in_out_state = data_arr[from_idx + 11]
    self.time_second  = byte_array_to_time({ data_arr[from_idx + 15],
                                             data_arr[from_idx + 14],
                                             data_arr[from_idx + 13],
                                             data_arr[from_idx + 12] })

    return self
  end

  function self.print()
    for key,value in pairs(self) do
      if type(value) ~= 'function' then
        if key == "time_second" then
          print("", string.format("%-10s", key), value, os.date("%c", value))
        elseif key == "in_out_state" then
          print("", string.format("%-10s", key), value, C3_INOUT_STATUS[value])
        elseif key == "event_type" then
          print("", string.format("%-10s", key), value, C3_EVENT_TYPE[value])
        elseif key == "verified" then
          print("", string.format("%-10s", key), value, C3_VERIFIED_MODE[value])
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

-- Module declaration
local M = {_TYPE='module', _NAME='C3', _VERSION='0.1'}

-- Private member variables
local sock = nil            -- Socket for TCP connection to C3 panel
local connected = false
local sessionID = {}
local requestNr = 0
local dataTableConfig = {}


M.byte_array_to_time = byte_array_to_time
M.ControlDeviceOutput = ControlDeviceOutput
M.ControlDeviceCancelAlarm = ControlDeviceCancelAlarm
M.ControlDeviceRestartDevice = ControlDeviceRestartDevice
M.ControlDeviceNOState = ControlDeviceNOState

local function M_get_message_header(data_arr)
  assert(#data_arr >= 5)
  assert(data_arr[1] == C3_MESSAGE_START)
  assert(data_arr[2] == C3_PROTOCOL_VERSION)

  local command = data_arr[3]
  local size    = (data_arr[5] * 255) + data_arr[4]

  return command, size
end

local function M_get_message(data_arr)
  assert(data_arr[#data_arr] == C3_MESSAGE_END)

  -- Get the message payload, without start, crc and end bytes
  local message_payload = {}
  for i = 2, #data_arr-3 do
    message_payload[i-1] = data_arr[i]
  end

  local checksum = CRC.crc_16(message_payload)
  assert(CRC.lsb(checksum) == data_arr[#data_arr-2])
  assert(CRC.msb(checksum) == data_arr[#data_arr-1])

  -- Remove the header (4 bytes)
  for i = 1, 4 do
    table.remove(message_payload, 1)
  end

  return message_payload
end

local function M_sock_send_data(command, data)
  local message_length = 0x04 + #(data or {})

  local message = { C3_PROTOCOL_VERSION,
                    command.request or 0x00,
                    CRC.lsb(message_length),
                    CRC.msb(message_length),
                    sessionID[2] or 0x00,    --LSB of sessionId first
                    sessionID[1] or 0x00,    --MSB of sessionId second
                    CRC.lsb(requestNr),
                    CRC.msb(requestNr)
                  }

  -- Append data bytes
  if data then
    for _,byte in ipairs(data) do
      table.insert(message, byte)
    end
  end

  local checksum = CRC.crc_16(message)
  table.insert(message, CRC.lsb(checksum))
  table.insert(message, CRC.msb(checksum))

  table.insert(message, 1, C3_MESSAGE_START)
  table.insert(message,    C3_MESSAGE_END)

  dump_message_arr("M_sock_send_data", message)
  -- TODO: Replace assert by pcall and handle error
  local bytes_written = assert(sock:send(arr_to_str(message)))

  requestNr = requestNr + 1

  return bytes_written
end

local function M_sock_receive_data(expected_command)
  -- Get the first 5 bytes
  -- TODO: Replace assert by pcall and handle error
  local header_str, _ = assert(sock:receive(5))
  local header_arr = str_to_arr(header_str)

  --dump_message_arr("M_sock_receive_data Header", header_arr)
  local received_command, size = M_get_message_header(header_arr)
  assert(received_command == expected_command.reply)

  -- Get the message data and signature
  -- TODO: Replace assert by pcall and handle error
  local payload_str, _ = assert(sock:receive(size + 3))
  local payload_arr = str_to_arr(payload_str, header_arr)

  dump_message_arr("M_sock_receive_data Header with payload", payload_arr)

  local data_arr = M_get_message(payload_arr)
  assert(size == #data_arr)

  dump_message_arr("M_sock_receive_data Data", data_arr)

  return size, data_arr
end

local function M_sock_send_receive(command, send_data)
  M_sock_send_data(command, send_data)
  return M_sock_receive_data(command)
end

local function M_sock_send_receive_data(command, send_data)
  local size,receive_data = M_sock_send_receive(command, send_data)

  -- Remove the sessionId (2 bytes) and message counter (2 bytes), to only return the data
  for i = 1, 4 do
    table.remove(receive_data, 1)
  end

  return size,receive_data
end

function M.setDebug(debug_on_off)
  debug_enabled = debug_on_off
end

function M.getSessionId()
  return bytes_to_num(sessionID)
end

function M.connect(host, port)
  port = port or PORT_DEFAULT

  if not connected then
    sessionID = {}
    requestNr = 0

    sock = assert(socket.tcp())
    local success, err = sock:connect(host, port)
    if success then
      sock:settimeout(2)

      local size, data_arr = M_sock_send_receive(C3_COMMAND_CONNECT)
      assert(size == 4)

      sessionID[1] = data_arr[2] --Second byte is MSB
      sessionID[2] = data_arr[1] --First byte is LSB
      connected = true
    end
  end

  return connected, err
end

function M.disconnect()
  if connected then
    M_sock_send_receive_data(C3_COMMAND_DISCONNECT)
    pcall(sock:close())

    sessionID = {}
    requestNr = 0
    connected = false
  end
end

function M.datatableconfig_decode(data_arr)
  -- The table config response is a list of strings separated by a newline (0x0A) character.
  -- Each line starts with the table and its identifier,
  -- followed by the fields and their index and type (i=integer, s=string)
  --   user=1,UID=i1,CardNo=i2,Pin=i3,Password=s4,Group=i5,StartTime=i6,EndTime=i7,Name=s8,SuperAuthorize=i9
  --   userauthorize=2,Pin=i1,AuthorizeTimezoneId=i2,AuthorizeDoorId=i3

  local data_str = arr_to_str(data_arr)
  local table_configs = {}

  local function DataTableConfig(table_name, table_id)
    local self = {
      name   = table_name,
      id     = table_id,
      fields = {}
    }

    function self.add_field(field_index, field_name, field_format)
       local index = tonumber(field_index)

       self.fields[index] = {
         name = field_name,
         fmt  = field_format
       }
    end

    function self.print()
      print(string.format("Table %s (id: %d)", self.name, self.id))
      for i,field in pairs(self.fields) do
        print("", i, field.name, field.fmt == "i" and "Integer" or field.fmt == "s" and "String" or "Unknown")
      end
    end

    return self
  end

  -- Split the string by whitespace, iterating over the lines
  for iter in string.gmatch(data_str, "%S+") do
    local config = {}

    -- Extract the key=value pairs from the line
    for k, v in string.gmatch(iter, "(%w+)=(%w+)") do
       if next(config) == nil then
         config = DataTableConfig(k, tonumber(v))
       else
         config.add_field(string.sub(v, 2), k, string.sub(v, 1, 1))
       end
    end

    table_configs[config.name] = config
  end

  return table_configs
end

function M.getDataTableConfig()
  if next(dataTableConfig) == nil then
    local size, data_arr = M_sock_send_receive_data(C3_COMMAND_DATATABLECFG)
    dataTableConfig = M.datatableconfig_decode(data_arr)
  end

  return dataTableConfig
end

function M.rtlog_decode(data_arr)
  -- One RT log is 16 bytes
  -- Ensure the data array is not empty and a multiple of 16
  assert(data_arr)
  assert(math.fmod(#data_arr, 16) == 0)

  local rtlogs = {}

  for i = 1, #data_arr, 16 do
    if data_arr[i + 10] == C3_EVENT_TYPE_DOOR_ALARM_STATUS then
      local rt_status = RTDAStatusRecord()
      rt_status.from_byte_array(data_arr, i)
      table.insert(rtlogs, rt_status)
    else
      local rt_event = RTEventRecord()
      rt_event.from_byte_array(data_arr, i)
      table.insert(rtlogs, rt_event)
    end
  end

  return rtlogs
end

function M.getRTLog()
  assert(connected)

  local size, data_arr = M_sock_send_receive_data(C3_COMMAND_RTLOG)
  return M.rtlog_decode(data_arr)
end

function M.controlDevice(control_command_object)
  assert(connected)

  local size, data_arr = M_sock_send_receive_data(C3_COMMAND_CONTROL, control_command_object.to_byte_array)
end

return M