-- require st provided libraries
local capabilities = require "st.capabilities"
local lightMode = capabilities["signalonion37562.lightMode"]
local Driver = require "st.driver"
local log = require "log"
local inspect = require('inspect')

-- require custom handlers from driver package
local command_handlers = require "command_handlers"
local discovery = require "discovery"
local preferencesMap = require "preferences"

-----------------------------------------------------------------
-- local functions
-----------------------------------------------------------------
-- this is called once a device is added by the cloud and synchronized down to the hub
local function device_added(driver, device)
  log.info("[" .. device.id .. "] Adding new Hello World device")

  -- set a default or queried state for each capability attribute
  device:emit_event(capabilities.switch.switch.on())

  device:emit_event(lightMode.lightMode.normal())
end


local function device_info_changed(driver, device, event, args)
  local hosts = device.preferences.hosts
  preferencesMap.hosts = {}
  local i = 1
  for host in string.gmatch(hosts, "([a-z0-9:/.]+),?") do
    preferencesMap.hosts[i] = host;
    i = i + 1
  end

  preferencesMap.standardModePreset = device.preferences.standardModePreset
  preferencesMap.nightModePreset = device.preferences.nightModePreset
end

-- this is called both when a device is added (but after `added`) and after a hub reboots.
local function device_init(driver, device)
  log.info("[" .. device.id .. "] Initializing Hello World device")
  device_info_changed(driver, device, nil, nil)

  -- mark device as online so it can be controlled from the app
  device:online()
end

-- this is called when a device is removed by the cloud and synchronized down to the hub
local function device_removed(driver, device)
  log.info("[" .. device.id .. "] Removing Hello World device")
end

-- create the driver object
local intellect_lamp_driver = Driver("intellect_lamp", {
  discovery = discovery.handle_discovery,
  lifecycle_handlers = {
    added = device_added,
    init = device_init,
    removed = device_removed,
    infoChanged = device_info_changed
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = command_handlers.switch_on,
      [capabilities.switch.commands.off.NAME] = command_handlers.switch_off,
    },
    [lightMode.ID] = {
      [lightMode.commands.setMode.NAME] = command_handlers.set_mode,
    },
  }
})

-- run the driver
intellect_lamp_driver:run()
