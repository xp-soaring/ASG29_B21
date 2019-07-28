-- B21

print("b21_altimeter starting, ALTITUDE_UNITS =", project_settings.ALTITUDE_UNITS)

-- The cockpit clock instrument (e.g. the 'watch') has its hands driven by
-- the project datarefs b21/clock/hours,minutes,seconds respectively.
-- This module writes the values into those datarefs based on USER_SETTINGS.lua

local FT_TO_M = 0.3048

-- READ datarefs
local dataref_knob = createGlobalPropertyi("b21/altimeter/knob", 0, false, true, false)
local dataref_alt_ft = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot")

-- WRITE datarefs
local dataref_baro_pilot = 
    globalPropertyf("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")
local needle_1_deg = createGlobalPropertyf("b21/altimeter/needle_1_deg", 0.0, false, true, true)
local needle_2_deg = createGlobalPropertyf("b21/altimeter/needle_2_deg", 0.0, false, true, true)
local needle_3_deg = createGlobalPropertyf("b21/altimeter/needle_3_deg", 0, false, true, true)

-- initialize pilot baro to standard setting
set(dataref_baro_pilot, 29.92)

-- 
local prev_knob = 0

function update_baro()
    local knob = get(dataref_knob)
    if knob ~= prev_knob
    then
        -- altimeter baro pressure knob has been moved
        if knob > prev_knob or (prev_knob == 3 and knob == 1)
        then
            -- +ve
            set(dataref_baro_pilot, get(dataref_baro_pilot) + 0.06)
        else
            -- -ve
            set(dataref_baro_pilot, get(dataref_baro_pilot) - 0.06)
        end
        prev_knob = knob
    end
end

function update_needles()
    local alt_ft = get(dataref_alt_ft)
    if project_settings.ALTITUDE_UNITS == 0
    then
        set(needle_3_deg, (alt_ft % 100000.0) / 100000.0 * 360)
        set(needle_2_deg, (alt_ft % 10000.0) / 10000.0 * 360)
        set(needle_1_deg, (alt_ft % 1000.0) / 1000.0 * 360)
    else
        local alt_m = alt_ft * FT_TO_M
        set(needle_3_deg, (alt_m % 100000.0) / 100000.0 * 360)
        set(needle_2_deg, (alt_m % 10000.0) / 10000.0 * 360)
        set(needle_1_deg, (alt_m % 1000.0) / 1000.0 * 360)
    end
end

function update()
    update_baro()
    update_needles()
end