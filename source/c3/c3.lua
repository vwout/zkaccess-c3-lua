-- Imports
local socket = require("socket")
local CRC = require("crc16.crc16")
local ControlDevice = require("C3.controldevice")
local RTLog = require("C3.rtlog")
local consts = require("C3.consts")
local utils = require("C3.utils")


local debug_enabled = false    -- Internal flag to enable debugging, see M.set_debug()

local function dump_message_arr(what, message)
  local s = ''

  if debug_enabled then
    for _,byte in ipairs(message) do
      s = s .. utils.num2hex(byte) .. ' '
    end
    print(string.format(". %-40s", what), s)
  end
end


-- Module declaration
local M = {_TYPE='module', _NAME='C3', _VERSION='0.1'}

-- Private member variables
local sock = nil            -- Socket for TCP connection to C3 panel
local connected = false
local sessionID = {}
local requestNr = 0
local dataTableConfig = {}

M.ControlDeviceOutput = ControlDevice.Output
M.ControlDeviceCancelAlarm = ControlDevice.CancelAlarm
M.ControlDeviceRestartDevice = ControlDevice.RestartDevice
M.ControlDeviceNOState = ControlDevice.NOState

local function M_get_message_header(data_arr)
  assert(#data_arr >= 5)
  assert(data_arr[1] == consts.C3_MESSAGE_START)
  assert(data_arr[2] == consts.C3_PROTOCOL_VERSION)

  local command = data_arr[3]
  local size    = (data_arr[5] * 255) + data_arr[4]

  return command, size
end

local function M_get_message(data_arr)
  assert(data_arr[#data_arr] == consts.C3_MESSAGE_END)

  -- Get the message payload, without start, crc and end bytes
  local message_payload = {}
  for i = 2, #data_arr-3 do
    message_payload[i-1] = data_arr[i]
  end

  local checksum = CRC.crc16(message_payload)
  assert(CRC.lsb(checksum) == data_arr[#data_arr-2])
  assert(CRC.msb(checksum) == data_arr[#data_arr-1])

  -- Remove the header (4 bytes)
  for _ = 1, 4 do
    table.remove(message_payload, 1)
  end

  return message_payload
end

local function M_sock_send_data(command, data)
  local message_length = 0x04 + #(data or {})

  local message = { consts.C3_PROTOCOL_VERSION,
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

  local checksum = CRC.crc16(message)
  table.insert(message, CRC.lsb(checksum))
  table.insert(message, CRC.msb(checksum))

  table.insert(message, 1, consts.C3_MESSAGE_START)
  table.insert(message,    consts.C3_MESSAGE_END)

  dump_message_arr("M_sock_send_data", message)
  -- TODO: Replace assert by pcall and handle error
  local bytes_written = assert(sock:send(utils.arr_to_str(message)))

  requestNr = requestNr + 1

  return bytes_written
end

local function M_sock_receive_data(expected_command)
  -- Get the first 5 bytes
  -- TODO: Replace assert by pcall and handle error
  local header_str, _ = assert(sock:receive(5))
  local header_arr = utils.str_to_arr(header_str)

  --dump_message_arr("M_sock_receive_data Header", header_arr)
  local received_command, size = M_get_message_header(header_arr)
  assert(received_command == expected_command.reply)

  -- Get the message data and signature
  -- TODO: Replace assert by pcall and handle error
  local payload_str, _ = assert(sock:receive(size + 3))
  local payload_arr = utils.str_to_arr(payload_str, header_arr)

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
  for _ = 1, 4 do
    table.remove(receive_data, 1)
  end

  return size,receive_data
end

function M.setDebug(debug_on_off)
  debug_enabled = debug_on_off
end

function M.getSessionId()
  return utils.bytes_to_num(sessionID)
end

function M.connect(host, port)
  port = port or consts.C3_PORT_DEFAULT

  local err = nil
  if not connected then
    sessionID = {}
    requestNr = 0

    local success

    sock = assert(socket.tcp())
    success, err = sock:connect(host, port)
    if success then
      sock:settimeout(2)

      local size, data_arr = M_sock_send_receive(consts.C3_COMMAND_CONNECT)
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
    M_sock_send_receive_data(consts.C3_COMMAND_DISCONNECT)
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

  local data_str = utils.arr_to_str(data_arr)
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
    local _, data_arr = M_sock_send_receive_data(consts.C3_COMMAND_DATATABLECFG)
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
    if data_arr[i + 10] == consts.C3_EVENT_TYPE_DOOR_ALARM_STATUS then
      local rt_status = RTLog.DAStatusRecord()
      rt_status.from_byte_array(data_arr, i)
      table.insert(rtlogs, rt_status)
    else
      local rt_event = RTLog.EventRecord()
      rt_event.from_byte_array(data_arr, i)
      table.insert(rtlogs, rt_event)
    end
  end

  return rtlogs
end

function M.getRTLog()
  assert(connected)

  local _, data_arr = M_sock_send_receive_data(consts.C3_COMMAND_RTLOG)
  return M.rtlog_decode(data_arr)
end

function M.param_decode(data_arr)
  assert(data_arr)

  local param_data = {}
  local param_str = utils.arr_to_str(data_arr)
  for k, v in string.gmatch(param_str, "([%w~]+)=(%w+)") do
    param_data[k] = v
  end

  return param_data
end

function M.getDeviceParameters(params_arr)
  assert(connected)

  local param_data = ""
  for i,param in ipairs(params_arr) do
    if i == 1 then
      param_data = param_data .. param
    elseif i <= 30 then
      param_data = param_data .. "," .. param
    else
      break
    end
  end

  local _, data_arr = M_sock_send_receive_data(consts.C3_COMMAND_GETPARAM,
                                               utils.str_to_arr(param_data))
  return M.param_decode(data_arr)
end

function M.controlDevice(control_command_object)
  assert(connected)

  M_sock_send_receive_data(consts.C3_COMMAND_CONTROL,
                           control_command_object.to_byte_array())
end

return M
