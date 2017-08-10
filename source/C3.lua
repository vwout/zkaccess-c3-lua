-- Imports
local socket = require("socket")
local CRC = require("crc_16")

-- Defaults
local PORT_DEFAULT = 4370

-- COMMANDS
local C3_MESSAGE_START      = 0xAA
local C3_MESSAGE_END        = 0x55
local C3_PROTOCOL_VERSION   = 0x01
local C3_COMMAND_CONNECT    = { request=0x76, reply=0xC8 }
local C3_COMMAND_DISCONNECT = { request=0x02, reply=0xC8 }

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
local C3_CONTROL_OUTPUT_ADDRESS  = { [C3_CONTROL_OUTPUT_ADDRESS_DOOR_OUTPUT] = "Door ouptput",
                                     [C3_CONTROL_OUTPUT_ADDRESS_AUX_OUTPUT]  = "Auxiliary output" }
                                
local C3_VERIFIED_MODE      = { [1]   = "Only finger",
                                [3]   = "Only password",
                                [4]   = "Only card",
                                [11]  = "Card and password",
                                [200] = "Others" }

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
                                [255] = "Current door status and alarm status" }

local C3_INOUT_STATUS_ENTRY = 0
local C3_INOUT_STATUS_EXIT  = 3
local C3_INOUT_STATUS_NONE  = 2
local C3_INOUT_STATUS       = { [C3_INOUT_STATUS_ENTRY] = "Entry",
                                [C3_INOUT_STATUS_EXIT]  = "Exit",
                                [C3_INOUT_STATUS_NONE]  = "None" }



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

local function dump_message_arr(what, message)
  local s = ''
  for _,byte in ipairs(message) do
    s = s .. num2hex(byte) .. ' '
  end
  print(string.format(". %-40s", what), s)
end


-- Module declaration
local M = {_TYPE='module', _NAME='C3', _VERSION='0.1'}

-- Private member variables
local sock
local connected = false
local sessionID = {}
local requestNr = 0


M.byte_array_to_time = byte_array_to_time

local function M_get_message_header(data_arr)
  assert(data_arr[1] == C3_MESSAGE_START)
  assert(data_arr[2] == C3_PROTOCOL_VERSION)
  assert(data_arr[5] == 0)
  
  local command = data_arr[3]
  local size    = data_arr[4]
  
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
  
  message = { C3_PROTOCOL_VERSION,
              command.request or 0x00,
              message_length,
              0x00,
              sessionID[2] or 0x00, --LSB of sessionId first
              sessionID[1] or 0x00, --MSB of sessionId second
              CRC.lsb(requestNr),
              CRC.msb(requestNr)
            }

  -- Append data bytes
  if data then
    for _,byte in ipairs(data) do
      table.insert(message, byte)
    end
  end

  checksum = CRC.crc_16(message)
  table.insert(message, CRC.lsb(checksum))
  table.insert(message, CRC.msb(checksum))

  table.insert(message, 1, C3_MESSAGE_START)
  table.insert(message,    C3_MESSAGE_END)
  
  dump_message_arr("M_sock_send_data", message)
  bytes_written = assert(sock:send(arr_to_str(message)))
  
  requestNr = requestNr + 1
  
  return bytes_written
end

local function M_sock_receive_data(expected_command)
  -- Get the first 5 bytes
  local header_str, receive_status = assert(sock:receive(5))
  local header_arr = str_to_arr(header_str)

  --dump_message_arr("M_sock_receive_data Header", header_arr)
  local received_command, size = M_get_message_header(header_arr)
  assert(received_command == expected_command.reply)

  -- Get the message data and signature
  local payload_str, receive_status = assert(sock:receive(size + 3))
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

function M.SessionId()
  return bytes_to_num(sessionID)
end

function M.connect(host, port)
  port = port or PORT_DEFAULT
  
  if not connected then 
    sessionID = {}
    requestNr = 0
    sock = assert(socket.connect(host, port))
    sock:settimeout(2)
    
    local size, data_arr = M_sock_send_receive(C3_COMMAND_CONNECT)
    assert(size == 4)
    
    sessionID[1] = data_arr[2] --Second byte is MSB
    sessionID[2] = data_arr[1] --First byte is LSB
    connected = true
  end
end

function M.disconnect()
  if connected then
    M_sock_send_receive_data(C3_COMMAND_DISCONNECT)
    sock:close()

    sessionID = {}
    requestNr = 0
  end
end

return M