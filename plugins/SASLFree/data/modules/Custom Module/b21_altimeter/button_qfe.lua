-- panel button to set QFE to current field elevation. Only operates if on ground.

-- datarefs to WRITE
local DATAREF_BARO_HG = globalPropertyf("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")
-- datarefs to read
local DATAREF_ALT_M = globalPropertyf("sim/cockpit/pressure/cabin_altitude_actual_m_msl")
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground

defineProperty("cursor", {
    x = -8,
    y = -8,
    width = 16,
    height = 16,
    shape = sasl.gl.loadImage ("button_cursor.png"),
    --hideOSCursor = true
})

function onMouseDown()
    if get(DATAREF_ONGROUND) == 1
    then
        alt_m = get(DATAREF_ALT_M)
        set(DATAREF_BARO_HG, 29.92 - alt_m / 915 )
    end
    return true
end
