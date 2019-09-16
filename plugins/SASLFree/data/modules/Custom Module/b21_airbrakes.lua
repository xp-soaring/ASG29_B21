-- B21

local debug = true

if debug then print("b21_airbrakes loaded")
end

----------------------------------- LOCATE DATAREFS OR COMMANDS -----------------------------------
local startup_running = globalProperty("sim/operation/prefs/startup_running")
local battery_on = globalProperty("sim/cockpit2/electrical/battery_on[0]")
local avionics_power_on = globalProperty("sim/cockpit2/switches/avionics_power_on")
local speedbrake_ratio = globalProperty("sim/cockpit2/controls/speedbrake_ratio")
local parking_brake_ratio = globalProperty("sim/cockpit2/controls/parking_brake_ratio")
local radio_altimeter_height_ft_pilot = globalProperty("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")

-- note previous values of brakes so change in 'update()'
local prev_speedbrake = 0.0

-- initialization
-- comply with user's 'startup_running' preference (power to 'on')
local start_power = get(startup_running) and 1 or 0 -- convert true/false to 1/0
set(battery_on, start_power)
set(avionics_power_on, start_power)

-- apply brakes if on ground
-- set ratio to 1.0 if on the ground or 0.0 if in the air
local brake_ratio = get(radio_altimeter_height_ft_pilot) < 10.0 and 1.0 or 0.0
set(parking_brake_ratio, brake_ratio)
set(speedbrake_ratio, brake_ratio)

-- X-PLANE per-frame update
function update()
    -- wheel brakes go 0..100% when speedbrake (spoilers) goes 75%..100%
    local speedbrake = get(speedbrake_ratio)
    if speedbrake ~= prev_speedbrake then
        if speedbrake < 0.75
        then
            set(parking_brake_ratio, 0.0)
        else
            set(parking_brake_ratio, (speedbrake - 0.75) * 4.0)
        end
        prev_speedbrake = speedbrake
	end
end
