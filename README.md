# Intellect UA Lamp

Simple SmartThings Edge driver for a WLED Led Lamp [Intellect UA](https://www.intellect-ua.com/).

## Shortcuts

Hub should be subscribed on a channel where a driver is gonna be published.

`smartthings edge:drivers:package intellect-lamp` - compiles the driver.
`smartthings edge:channels:assign` - assigns to a channel
`smartthings edge:drivers:install` - installs on a hub.
`smartthings capabilities:presentation:update -i ./capabilities/lightMode.presentation.yaml` - updates the presentation of a capability.
`smartthings presentation:device-config:create -i presentation/intellect-lamp.presentation.yaml` - creates device config.

Steps to get the driver working:

1. Create a new capability.
1. Create a new capability presentation.
1. Create a new device-config.
1. Change capability name and vid in driver profile.
1. Change capability name on calls in driver code (and also do a build_cap_from_json).
1. Install the driver.
1. Reinstall the affected device.
1. Sometimes I also need to reboot the Hub and reinstall the device again.