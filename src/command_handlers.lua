local log = require "log"
local capabilities = require "st.capabilities"
local cosock = require "cosock"
-- local http = require "socket.http"
local http = cosock.asyncify "socket.http"
local ltn12 = require "ltn12"
local preferencesMap = require "preferences"

local command_handlers = {}

local function send_request(device, requestBody, url)
  local success, code, headers, status = http.request {
      method = "POST",
      url = url,
      source = ltn12.source.string(requestBody),
      headers = 
              {
                      ["Accept"] = "*/*",
                      ["content-length"] = string.len(requestBody)
              },
      -- sink = ltn12.sink.table(respbody)
  }
  
  log.debug(string.format("Response success = [%s], code = [%s]", tostring(success), tostring(code)))
  if not success and code ~= "timeout" then
    local err = code -- in error case second param is error message

    error(string.format("error while setting switch status for %s: %s",
                        device.name,
                        err))
   elseif code ~= 200 then
     error(string.format("unexpected HTTP error response from %s: %s",
                         device.name,
                         status))
  end

  return code
end

-- callback to handle an `on` capability command
function command_handlers.switch_on(driver, device, command)
  log.debug(string.format("[%s] calling set_power(on)", device.device_network_id))
  local is_change_status = true

  for _, host in ipairs(preferencesMap.hosts) do
    local normalModePreset = preferencesMap.standardModePreset
    local req = string.format("{\"on\":true,\"ps\":%d}", normalModePreset)
    local status = send_request(device, req, host)
    log.debug(string.format("[%s] calling set_power(on): status = [%s]", device.device_network_id, status))

    if (status ~= 200) then
      is_change_status = false
    end
  end

  if (is_change_status) then
    device:emit_event(capabilities.switch.switch.on())
  end
end

-- callback to handle an `off` capability command
function command_handlers.switch_off(driver, device, command)
  log.debug(string.format("[%s] calling set_power(off)", device.device_network_id))
  local is_change_status = true

  for _, host in ipairs(preferencesMap.hosts) do
    local req = "{\"on\":false}"
    local status = send_request(device, req, host)

    log.debug(string.format("[%s] calling set_power(off): status = [%s]", device.device_network_id, status))
    if (status ~= 200) then
      is_change_status = false
    end
  end

  if (is_change_status) then
    device:emit_event(capabilities.switch.switch.off())
  end
end

return command_handlers
