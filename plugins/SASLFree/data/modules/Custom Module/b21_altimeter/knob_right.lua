-- panel button

-- datarefs to WRITE
local DATAREF_BARO_PILOT = globalPropertyf("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")

defineProperty("cursor", {
    x = -8,
    y = -8,
    width = 16,
    height = 16,
    shape = sasl.gl.loadImage ("rotate_left.png"),
    --hideOSCursor = true
})

function onMouseDown()
    set(DATAREF_BARO_PILOT, get(DATAREF_BARO_PILOT) - 0.06 )
    return true
end
