-- B21

print("flap_indicator.lua loaded", 1.0)

----------------------------------- LOCATE DATAREFS OR COMMANDS -----------------------------------
-- write datarefs
local DATAREF_FLAP_INDICATOR = createGlobalPropertyf("b21/flap_indicator",0.0,false,true,true)

-- read datarefs
local DATAREF_FLAPRQST = globalPropertyf("sim/flightmodel/controls/flaprqst")
local DATAREF_SPEEDBRAKE = globalProperty("sim/cockpit2/controls/speedbrake_ratio")
local DATAREF_GEAR = globalPropertyi("sim/cockpit/switches/gear_handle_status") -- =1 when gear DOWN
local DATAREF_ALT_AGL_FT = globalProperty("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec") -- time in seconds
local DATAREF_BALLAST_KG = globalPropertyf("sim/flightmodel/weight/m_jettison") -- Kg water ballast

local WHEEL_DOWN_ALT_LIMIT_FT = 2000 -- warning if gear down above 2000 feet AGL

local MAX_WARNING_DURATION_S = 5 -- only leave warning on indicator for max time
local warning_time_s = 0.0 -- record time of issuing warning
local warning_gear_up = false
local warning_gear_down = false
local warning_ballast = false

-- X-PLANE per-frame update
function update()
    -- if SPOILERS OUT & GEAR UP:
    local spoilers_out = get(DATAREF_SPEEDBRAKE) > 0.0

    local gear_down = get(DATAREF_GEAR) == 1

    local carrying_ballast = get(DATAREF_BALLAST_KG) > 20

    local time_now_s = get(DATAREF_TIME_S)

    -- SPOILERS / GEAR UP WARNING
    if spoilers_out and not gear_down
    then
        if not warning_gear_up
        then
            set(DATAREF_FLAP_INDICATOR, 3) -- SPOILERS / GEAR UP warning
            print("gear up")
            warning_time_s = time_now_s
        end
        warning_gear_up = true
    else
        warning_gear_up = false
    end

    local alt_agl_ft = get(DATAREF_ALT_AGL_FT)

    -- AT HEIGHT / GEAR DOWN WARNING
    if gear_down and alt_agl_ft > WHEEL_DOWN_ALT_LIMIT_FT
    then
        if not warning_gear_down
        then
            set(DATAREF_FLAP_INDICATOR, 2) -- GEAR DOWN warning
            print("gear down")
            warning_time_s = time_now_s
        end
        warning_gear_down = true
    else
        warning_gear_down = false
    end

    -- SPOILERS / BALLAST WARNING
    if (spoilers_out or gear_down) and carrying_ballast
    then
        if not warning_ballast
        then
            set(DATAREF_FLAP_INDICATOR, 4) -- SPOILERS / BALLAST warning
            print("warning - ballast")
            warning_time_s = time_now_s
        end
        warning_ballast = true
    else
        warning_ballast = false
    end
    
    local warning_expired = time_now_s > warning_time_s + MAX_WARNING_DURATION_S

    local no_warning = not warning_gear_down and not warning_gear_up and not warning_ballast

    if no_warning or warning_expired
    then
        -- All seems fine, so set flap_indicator to flaprqst
        local flaprqst = get(DATAREF_FLAPRQST)
        set(DATAREF_FLAP_INDICATOR, flaprqst)
    end
end
