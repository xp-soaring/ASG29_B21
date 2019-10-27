-- panel button to set QNE 29.92

-- datarefs to WRITE
local DATAREF_BARO_HG = globalPropertyf("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")

defineProperty("cursor", {
    x = -8,
    y = -8,
    width = 16,
    height = 16,
    shape = sasl.gl.loadImage ("button_cursor.png"),
    --hideOSCursor = true
})

function onMouseDown()
    set(DATAREF_BARO_HG, 29.92 )
    return true
end
