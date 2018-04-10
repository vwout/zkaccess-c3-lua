-- Constants for use with C3
local consts = {}

-- Defaults
consts.C3_PORT_DEFAULT = 4370

-- Protocol commands
consts.C3_MESSAGE_START        = 0xAA
consts.C3_MESSAGE_END          = 0x55
consts.C3_PROTOCOL_VERSION     = 0x01
consts.C3_COMMAND_CONNECT      = { request=0x76, reply=0xC8 }
consts.C3_COMMAND_DISCONNECT   = { request=0x02, reply=0xC8 }
consts.C3_COMMAND_GETPARAM     = { request=0x04, reply=0xC8 }
consts.C3_COMMAND_DATATABLECFG = { request=0x06, reply=0xC8 }
consts.C3_COMMAND_CONTROL      = { request=0x05, reply=0xC8 }
consts.C3_COMMAND_RTLOG        = { request=0x0B, reply=0xC8 }

-- Control operations
consts.C3_CONTROL_OPERATION_OUTPUT         = 1
consts.C3_CONTROL_OPERATION_CANCEL_ALARM   = 2
consts.C3_CONTROL_OPERATION_RESTART_DEVICE = 3
consts.C3_CONTROL_OPERATION_ENDIS_NO_STATE = 4
consts.C3_CONTROL_OPERATION  = { [consts.C3_CONTROL_OPERATION_OUTPUT]         = "Output operation (door or auxilary)",
                                 [consts.C3_CONTROL_OPERATION_CANCEL_ALARM]   = "Cancel alarm",
                                 [consts.C3_CONTROL_OPERATION_RESTART_DEVICE] = "Restart Device",
                                 [consts.C3_CONTROL_OPERATION_ENDIS_NO_STATE] = "Enable/disable normal open state" }

consts.C3_CONTROL_OUTPUT_ADDRESS_DOOR_OUTPUT = 1
consts.C3_CONTROL_OUTPUT_ADDRESS_AUX_OUTPUT  = 2
consts.C3_CONTROL_OUTPUT_ADDRESS  = { [consts.C3_CONTROL_OUTPUT_ADDRESS_DOOR_OUTPUT] = "Door output",
                                      [consts.C3_CONTROL_OUTPUT_ADDRESS_AUX_OUTPUT]  = "Auxiliary output" }

-- Event values
consts.C3_VERIFIED_MODE      = { [0]   = "None",
                                 [1]   = "Only finger",
                                 [3]   = "Only password",
                                 [4]   = "Only card",
                                 [11]  = "Card and password",
                                 [200] = "Others" }

consts.C3_EVENT_TYPE_DOOR_ALARM_STATUS = 255
consts.C3_EVENT_TYPE         = { [0]   = "Normal Punch Open",
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
                                 [consts.C3_EVENT_TYPE_DOOR_ALARM_STATUS] = "Current door and alarm status" }

consts.C3_INOUT_STATUS_ENTRY = 0
consts.C3_INOUT_STATUS_EXIT  = 3
consts.C3_INOUT_STATUS_NONE  = 2
consts.C3_INOUT_STATUS       = { [consts.C3_INOUT_STATUS_ENTRY] = "Entry",
                                 [consts.C3_INOUT_STATUS_EXIT]  = "Exit",
                                 [consts.C3_INOUT_STATUS_NONE]  = "None" }

consts.C3_ALARM_STATUS       = { [0] = "None",
                                 [1] = "Alarm",
                                 [2] = "Door opening timeout" }

consts.C3_DSS_STATUS_UNKNOWN = 0
consts.C3_DSS_STATUS_CLOSED  = 1
consts.C3_DSS_STATUS_OPEN    = 2
consts.C3_DSS_STATUS         = { [consts.C3_DSS_STATUS_UNKNOWN] = "No Door Status Sensor",
                                 [consts.C3_DSS_STATUS_CLOSED]  = "Door closed",
                                 [consts.C3_DSS_STATUS_OPEN]    = "Door open" }

-- Trick to create constants, credits  http://andrejs-cainikovs.blogspot.nl/2009/05/lua-constants.html
local function protect(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(_, key, value)
            error("attempting to change constant " ..
                   tostring(key) .. " to " .. tostring(value), 2)
        end
    })
end

return protect(consts)
