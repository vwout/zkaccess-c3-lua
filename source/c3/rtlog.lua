local CRC = require("crc16.crc16")
local utils = require("c3.utils")
local consts = require("c3.consts")


local RTLog = {}

-- An RTLog is a binary message of 16 bytes send by the C3 access panel.
-- If the value of byte 10 (the event type) is 255, the RTLog is a Door/Alarm Realtime Status.
-- If the value of byte 10 (the event type) is not 255, the RTLog is a Realtime Event.

-- Door/Alarm Realtime Status record
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
-- Time_second (byte 12-15)                                     a5:ad:ad:21 => (big endian:) 21ADADA5 =
--                                                                                           2017-7-30 16:51:49
function RTLog.DAStatusRecord()
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
    self.time_second  = utils.byte_array_to_time({ data_arr[from_idx + 15],
                                                   data_arr[from_idx + 14],
                                                   data_arr[from_idx + 13],
                                                   data_arr[from_idx + 12] })

    return self
  end

  function self.get_alarms(door_nr)
    local alarms = {}

    for i,status in ipairs(self.alarm_status) do
      if door_nr == i or not door_nr then
        for k,_ in pairs(consts.C3_ALARM_STATUS) do
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
    if self.dss_status[door_nr] == consts.C3_DSS_STATUS_OPEN then
      open = true
    elseif self.dss_status[door_nr] == consts.C3_DSS_STATUS_CLOSED then
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
          print("", string.format("%-10s", key), value, consts.C3_EVENT_TYPE[value])
        elseif key == "verified" then
          print("", string.format("%-10s", key), value, consts.C3_VERIFIED_MODE[value])
        elseif key == "alarm_status" then
          print("", string.format("%-10s", key))

          local function concat_if_in_bitset(bitset, tbl, str_arr)
            str_arr = str_arr or {}

            if tbl[0] and bitset == 0 then
              table.insert(str_arr, tbl[0])
            else
              for k,v in pairs(tbl) do
                if k ~= 0 then
                  if CRC.bit.band(bitset, k) == k then
                    table.insert(str_arr, v)
                  end
                end
              end
            end

            return table.concat(str_arr, ", ")
          end

          for i,v in ipairs(value) do
            print("", "", string.format("Door %-10i", i), v, concat_if_in_bitset(v, consts.C3_ALARM_STATUS))
          end
        elseif key == "dss_status" then
          print("", string.format("%-10s", key))
          for i,v in ipairs(value) do
            print("", "", string.format("Door %-10i", i), v, consts.C3_DSS_STATUS[v])
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

-- Realtime Event record
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
function RTLog.EventRecord()
  -- the new instance
  local self = {
    card_no      = 0,
    pin          = 0,
    verified     = 0,
    door_id      = 0,
    event_type   = 0,
    in_out_state = consts.C3_INOUT_STATUS_NONE,
    time_second  = 0
  }

  function self.is_dastatus()
    return false
  end

  function self.is_event()
    return true
  end

  function self.from_byte_array(data_arr, from_idx)
    self.card_no      = utils.bytes_to_num({ data_arr[from_idx + 3],
                                             data_arr[from_idx + 2],
                                             data_arr[from_idx + 1],
                                             data_arr[from_idx + 0] })
    self.pin          = utils.bytes_to_num({ data_arr[from_idx + 7],
                                             data_arr[from_idx + 6],
                                             data_arr[from_idx + 5],
                                             data_arr[from_idx + 4] })
    self.verified     = data_arr[from_idx + 8]
    self.door_id      = data_arr[from_idx + 9]
    self.event_type   = data_arr[from_idx + 10]
    self.in_out_state = data_arr[from_idx + 11]
    self.time_second  = utils.byte_array_to_time({ data_arr[from_idx + 15],
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
          print("", string.format("%-10s", key), value, consts.C3_INOUT_STATUS[value])
        elseif key == "event_type" then
          print("", string.format("%-10s", key), value, consts.C3_EVENT_TYPE[value])
        elseif key == "verified" then
          print("", string.format("%-10s", key), value, consts.C3_VERIFIED_MODE[value])
        else
          print("", string.format("%-10s", key), value)
        end
      end
    end
  end

  -- return the instance
  return self
end

return RTLog
