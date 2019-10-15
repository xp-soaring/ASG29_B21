-- b21_startup.lua
print("b21_startup.lua starting")

local DATAREF_BALLAST_KG = globalPropertyf("sim/flightmodel/weight/m_jettison")
local DATAREF_FLAPS = globalPropertyf("sim/flightmodel/controls/flaprqst")
local DATAREF_ALT_AGL_FT = globalPropertyf("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")

-- *******************************
-- Startup
-- *******************************
-- flag set during init() so it only runs once, on startup
local init_completed = false

-- init() is called in update()
function init()
    -- if init already done, then do nothing and return
    if init_completed
    then
        return
    end

    local alt_agl_ft = get(DATAREF_ALT_AGL_FT)

    print("b21_startup in init mode, alt agl ft = "..alt_agl_ft)

    local onground = alt_agl_ft < 10

    print("init, onground=",onground)

    -- If on ground
    if onground
    then
        -- startup water ballast
        set(DATAREF_BALLAST_KG, project_settings.STARTUP_BALLAST_KG)
        print("Set startup ballast to "..project_settings.STARTUP_BALLAST_KG, "actual=", get(DATAREF_BALLAST_KG))
        -- startup flaps
        set(DATAREF_FLAPS, project_settings.STARTUP_FLAPS / 7)
        print("Set startup flap to "..project_settings.STARTUP_FLAPS)
    end

    init_completed = true
end

function update()
    init() -- will do nothing after first update
end

function onAirportLoaded()
    print("onAirportLoaded")
    init_completed = false -- re-run init() on next update
end

function onPlaneLoaded()
    print("onPlaneLoaded")
end
