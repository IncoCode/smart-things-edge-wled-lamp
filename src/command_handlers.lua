local log = require "log"
local capabilities = require "st.capabilities"
local lightMode = capabilities["signalonion37562.lightMode"]
local cosock = require "cosock"
-- local http = require "socket.http"
local http = cosock.asyncify "socket.http"
local ltn12 = require "ltn12"
local preferencesMap = require "preferences"
local inspect = require('inspect')

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
    local req = "{\"on\":true}"
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

function command_handlers.set_mode(driver, device, command)
  local value = command.args.lightMode
  log.debug(string.format("[%s] calling set_mode, command value = %s, command = %s", device.device_network_id, value, inspect(command)))

  local is_change_status = true
  local isNight = value == 'night'
  local isNormal = value == 'normal'
  local presetId = 0
  if isNight then
    presetId = preferencesMap.nightModePreset
  elseif isNormal then
    presetId = preferencesMap.standardModePreset
  end

  for _, host in ipairs(preferencesMap.hosts) do
    local req = string.format("{\"ps\":%d}", presetId)
    local status = send_request(device, req, host)
    log.debug(string.format("[%s] calling change playlist: status = [%s]", device.device_network_id, status))

    if (status ~= 200) then
      is_change_status = false
    end
  end

  if is_change_status then
    if (isNormal) then
      device:emit_event(lightMode.lightMode.normal())
    elseif (isNight) then
      device:emit_event(lightMode.lightMode.night())
    end
  end
end

return command_handlers
