-- B21

-- Computer vario simulation

--[[  THIS GAUGE READS THE POLAR FROM B21_POLAR.lua

    The 3 numbers displayed on the vario are referred to as 'top', 'bottom' and 'right'

    User input DataRefs:
        b21/vario_302/stf_te_switch   -- (1/0) toggles vario between STF and TE mode
        b21/vario_302/knob -- MacCready setting dialled in by pilot

    Input datarefs from other modules:
        b21/total_energy_mps

    Display output DataRefs:
        b21/vario_302/needle_fpm
        b21/vario_302/number_bottom
        b21/vario_302/number_bottom_sign
        b21/vario_302/number_right
        b21/vario_302/number_top
        b21/vario_302/number_top_minus
        b21/netto_fpm
        b21/vario_302/pull
        b21/vario_302/push
        b21/vario_sound_fpm
        b21/vario_sound_mode
        b21/vario_302/stf_te_ind

]]

-- include generally useful lat/long functions
local geo = require "b21_geo"

-- the datarefs we will READ to get time, altitude and speed from the sim
DATAREF = {}

-- datarefs from other B21 modules
DATAREF.TE_MPS = globalProperty("b21/total_energy_mps")

-- datarefs updated by panel:
DATAREF.KNOB = createGlobalPropertyf("b21/vario_302/knob", 0, false, true, false) -- 2.0
DATAREF.STF_TE_SWITCH = createGlobalPropertyi("b21/vario_302/stf_te_switch", project_settings.VARIO_302_MODE, false, true, false)
     -- (0=stf, 1=auto, 2=te)

-- datarefs from x-plane
DATAREF.TIME_S = globalPropertyf("sim/network/misc/network_time_sec") -- 100
DATAREF.ALT_FT = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot") -- 3000
-- (for calibration) local sim_alt_m = globalPropertyf("sim/flightmodel/position/elevation")
DATAREF.AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot") -- 60
-- (for calibration) local sim_speed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")
DATAREF.WEIGHT_TOTAL_KG = globalPropertyf("sim/flightmodel/weight/m_total") -- 430
DATAREF.WIND_DEG = globalPropertyf("sim/weather/wind_direction_degt", 0.0, false, true, true)
DATAREF.WIND_KTS = globalPropertyf("sim/weather/wind_speed_kt", 0.0, false, true, true)
DATAREF.TURN_RATE_DEG = globalProperty("sim/cockpit2/gauges/indicators/turn_rate_heading_deg_pilot")

-- datarefs from USER_SETTINGS.lua
DATAREF.UNITS_VARIO = globalProperty("b21/units_vario") -- 0 = knots, 1 = m/s (from settings.lua)
DATAREF.UNITS_ALTITUDE = globalProperty("b21/units_altitude") -- 0 = feet, 1 = meters (from settings.lua)
DATAREF.UNITS_SPEED = globalProperty("b21/units_speed") -- 0 = knots, 1 = km/h (from settings.lua)

-- create global DataRefs we will WRITE (name, default, isNotPublished, isShared, isReadOnly)
DATAREF.NETTO = createGlobalPropertyf("b21/netto_fpm", 0.0, false, true, true)
DATAREF.PULL = createGlobalPropertyi("b21/vario_302/pull", 0, false, true, true)
DATAREF.PUSH = createGlobalPropertyi("b21/vario_302/push", 0, false, true, true)
DATAREF.NEEDLE_FPM = createGlobalPropertyf("b21/vario_302/needle_fpm", 0.0, false, true, true)
DATAREF.VARIO_SOUND_FPM = globalPropertyf("b21/vario_sound_fpm")
DATAREF.VARIO_SOUND_MODE = globalPropertyi("b21/vario_sound_mode")
DATAREF.NUMBER_BOTTOM = createGlobalPropertyf("b21/vario_302/number_bottom",12.3,false,true,true)
DATAREF.NUMBER_BOTTOM_SIGN = createGlobalPropertyi("b21/vario_302/number_bottom_sign",0,false,true,true)
DATAREF.NUMBER_RIGHT = createGlobalPropertyf("b21/vario_302/number_right",34.5,false,true,true)
DATAREF.NUMBER_TOP = createGlobalPropertyi("b21/vario_302/number_top",123,false,true,true)
DATAREF.NUMBER_TOP_SIGN = createGlobalPropertyi("b21/vario_302/number_top_sign",0,false,true,true)
DATAREF.STF_TE_IND = createGlobalPropertyi("b21/vario_302/stf_te_ind",0,false,true,true) -- stf/te indicator on lcd

--debug waypoint for arrival height testing approx 26nm East of 1N7 (Blairstown)
local debug_wp_lat = 41.0
local debug_wp_lng = -74.5
local debug_wp_alt_m = 100.0

-- some development debug values for testing
DATAREF.DEBUG1 = globalPropertyf("b21/debug/1")
DATAREF.DEBUG2 = globalPropertyf("b21/debug/2")
DATAREF.DEBUG3 = globalPropertyf("b21/debug/3")

--shim functions to help testing in desktop Lua
function dataref_read(x)
    return get(DATAREF[x])
end

function dataref_write(x, value)
    set(DATAREF[x], value)
end

-- Conversion constants
FT_TO_M = 0.3048
M_TO_FT = 1 / FT_TO_M
KTS_TO_KPH = 1.852
KTS_TO_MPS = 0.514444
MPS_TO_FPM = 196.85
MPS_TO_KTS = 1.0 / KTS_TO_MPS
MPS_TO_KPH = 3.6
KPH_TO_MPS = 1 / MPS_TO_KPH
DEG_TO_RAD = 0.0174533

-- b21_302 globals
B21_302_maccready_kts = 0 -- user input maccready setting in kts
B21_302_maccready_mps = 0 -- user input maccready setting in m/s

B21_302_climb_average_mps = 0 -- calculated climb average

B21_polar_stf_best_mps = project_settings.polar_stf_best_kph * KPH_TO_MPS
B21_polar_stf_2_mps = project_settings.polar_stf_2_kph * KPH_TO_MPS

-- some constants derived from polar to use in the speed-to-fly calculation
B21_302_polar_const_r = (B21_polar_stf_2_mps^2 - B21_polar_stf_best_mps^2) / 2
B21_302_polar_const_v2stfx = 625 -- threshold speed-squared (m/s) figure to adjust speed-to-fly if below this (i.e. 25 m/s)
B21_302_polar_const_z = 300000

B21_302_ballast_ratio = 0.0 -- proportion of ballast carried 0..1
B21_302_ballast_adjust = 1.0 -- adjustment factor for ballast, shifts polar by sqrt of total_weight / weight_empty

-- vario modes
B21_302_mode_stf = project_settings.VARIO_302_MODE  -- 0 = speed to fly, 1 = TE, 2 = AUTO

-- netto
B21_302_polar_sink_mps = 0.0
B21_302_netto_mps = 0.0

-- Maccready speed-to-fly and polar sink value at that speed
B21_302_mc_stf_mps = 0.0
B21_302_mc_sink_mps = 0.0

-- height needed and arrivial height at next waypoint
B21_302_height_needed_m = 0.0
B21_302_arrival_height_m = 0.0

-- debug glide ratio
B21_302_glide_ratio = 0.0

-- vario needle value
B21_302_needle_fpm = 0.0


-- #############################################################
-- vars used by routines to track changes between update() calls

prev_ballast = 0.0

-- Maccready knob, so we can detect when it changes
prev_knob = 0

-- time period start used by average
average_start_s = 0.0

-- previous update time of the NUMBER_TOP altitude display
prev_number_top_s = 0.0

-- stf/te switch calculation
speed_prev_time_s = dataref_read("TIME_S")
average_speed_mps = 0.0
average_turn_rate_deg = 0.0
prev_mode = dataref_read("STF_TE_SWITCH") -- used to rotate through options in 'toggle' command

-- #################################################################################################
-- COMMANDS
-- #################################################################################################

local command_mode_toggle = sasl.createCommand("b21/vario_302/mode_toggle",
    "Switch the 302 computer vario between STF, AUTO, TE")
local command_mode_stf = sasl.createCommand("b21/vario_302/mode_stf",
    "Set the 302 computer vario to STF mode")
local command_mode_auto = sasl.createCommand("b21/vario_302/mode_auto",
    "Set the 302 computer vario to Auto mode")
local command_mode_te = sasl.createCommand("b21/vario_302/mode_te",
    "Set the 302 computer vario to TE mode")

function mode_toggle(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        local current_mode = dataref_read("STF_TE_SWITCH")
        print("MODE_TOGGLE COMMAND "..current_mode)
        if current_mode == 0 or current_mode == 2
        then
            dataref_write("STF_TE_SWITCH", 1)
            prev_mode = current_mode
        else -- current_mode == 1 i.e. AUTO
            if prev_mode == 0
            then
                dataref_write("STF_TE_SWITCH", 2)
            else
                dataref_write("STF_TE_SWITCH", 0)
            end
        end
    end
    return 1
end

function mode_stf(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("MODE_STF COMMAND")
        dataref_write("STF_TE_SWITCH", 0)
    end
    return 1
end

function mode_auto(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("MODE_AUTO COMMAND")
        dataref_write("STF_TE_SWITCH", 1)
    end
    return 1
end

function mode_te(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("MODE_TE COMMAND")
        dataref_write("STF_TE_SWITCH", 2)
    end
    return 1
end

sasl.registerCommandHandler(command_mode_toggle, 0, mode_toggle)
sasl.registerCommandHandler(command_mode_stf, 0, mode_stf)
sasl.registerCommandHandler(command_mode_auto, 0, mode_auto)
sasl.registerCommandHandler(command_mode_te, 0, mode_te)

-- #################################################################################################

-- Calculate B21_302_ballast_adjust which is:
--  the square root of the proportion glider weight is above polar_weight_empty, i.e.
--  ballast = 0.0 (zero ballast, glider at empty weight) => polar_adjust = 1
--  ballast = 1.0 (full ballast, glider at full weight) => polar_adjust = sqrt(weight_full/weight_empty)
function update_ballast()
    B21_302_ballast_ratio = (dataref_read("WEIGHT_TOTAL_KG") - project_settings.polar_weight_empty_kg) /
                            (project_settings.polar_weight_full_kg - project_settings.polar_weight_empty_kg)

    B21_302_ballast_adjust = math.sqrt(dataref_read("WEIGHT_TOTAL_KG")/ project_settings.polar_weight_empty_kg)
    --print("B21_302_ballast_ratio",B21_302_ballast_ratio) --debug
    --print("B21_302_ballast_adjust",B21_302_ballast_adjust) --debug
end

-- update Maccready value from knob rotation 0..15
-- note we update differently for mps / knots so display moves 0.5 units in each units setting.
function update_maccready()
    local knob = dataref_read("KNOB") -- 0..15
    if knob ~= prev_knob -- only update if knob position changes
    then
        --debug read knob on cockpit panel
        if dataref_read("UNITS_VARIO") == 1 -- meters per second
        then
            B21_302_maccready_mps = knob / 2
        else                                -- knots
            -- for Knots knob will move in 0.5 knot increments to 5.0, then 1 Knot increments to 9.99
            if knob < 10.1                          -- i.e. knob = 0..10
            then
                B21_302_maccready_kts = knob / 2
            elseif knob < 14.1                      -- i.e. knob = 11..14
            then
                B21_302_maccready_kts = knob - 5
            else                                    -- i.e. knob = 15
                B21_302_maccready_kts = 9.9 -- display as 9.9
            end
            B21_302_maccready_mps = B21_302_maccready_kts * KTS_TO_MPS
        end
        prev_knob = knob -- record knob position so we detect another change
    end
    --print("B21_302_maccready_kts", B21_302_maccready_kts) --debug
end

-- update STF/TE mode based on switch setting or AUTO calculation
function update_stf_te_mode()
    -- get current STF/TE switch setting
    local switch = dataref_read("STF_TE_SWITCH")

    if switch == 0 -- 'STF' mode
    then
        B21_302_mode_stf = true
    elseif switch == 2 -- 'TE' mode
    then
        B21_302_mode_stf = false
    else -- in 'AUTO' STF/TE mode (switch == 1)
        local time_delta_s = dataref_read("TIME_S") - speed_prev_time_s
        if time_delta_s < 1.0
        then
            return -- we don't need to update STF/TE mode more than once per second
        end
        -- ok more than a second since last update, so test auto stf for a change
        speed_prev_time_s = dataref_read("TIME_S")

        local speed_now_mps = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS
        average_speed_mps = average_speed_mps + (speed_now_mps - average_speed_mps) * time_delta_s * 0.1

        local turn_rate_now_deg = math.abs(dataref_read("TURN_RATE_DEG"))
        average_turn_rate_deg = average_turn_rate_deg + (turn_rate_now_deg - average_turn_rate_deg) * time_delta_s * 0.2

        if B21_302_mode_stf
        then
            -- currently in STF mode
            -- if slow and turning then change to TE
            if speed_now_mps < 37.0 and turn_rate_now_deg > 50.0
            then
                B21_302_mode_stf = false
            end
        else
            -- currently in TE mode                       change to STF if
            if speed_now_mps > 35 or                      -- flying faster than 35 mps
               average_turn_rate_deg < 30                 -- not turning much lately
            then
                B21_302_mode_stf = true
            end
        end
    end
    -- update STF/TE indicator
    -- if in STF mode then set indicator to 0 (= STF on lcd), else set indicator to 1 (= TE on lcd)
    dataref_write("STF_TE_IND", B21_302_mode_stf and 0 or 1)

    if project_settings.VARIO_302_DUAL_SOUND == 1
    then
        dataref_write("VARIO_SOUND_MODE", B21_302_mode_stf and 1 or 0) -- sound mode 0=TE, 1=STF
    end
end

-- calcular polar sink in m/s for given airspeed in km/h
function sink_mps(speed_kph, ballast_adjust)
    local prev_point = { 0, 2 } -- arbitrary starting polar point (for speed < polar[1][SPEED])
    for i, point in pairs(project_settings.polar) -- each point is { speed_kph, sink_mps }
    do
        -- adjust this polar point to account for ballast carried
        local adjusted_point = { point[1] * ballast_adjust, point[2] * ballast_adjust }
        if ( speed_kph < adjusted_point[1])
        then
            return interp(speed_kph, prev_point, adjusted_point )
        end
        prev_point = adjusted_point
    end
    return 10 -- we fell off the end of the polar, so guess sink value (10 m/s)
end

-- interpolate sink for speed between between points p1 and p2 on the polar
-- p1 and p2 are { speed_kph, sink_mps } where sink is positive
function interp(speed, p1, p2)
    local ratio = (speed - p1[1]) / (p2[1] - p1[1])
    return p1[2] + ratio * (p2[2]-p1[2])
end

function update_polar_sink()
    local airspeed_kph = dataref_read("AIRSPEED_KTS") * KTS_TO_KPH
    B21_302_polar_sink_mps = sink_mps(airspeed_kph, B21_302_ballast_adjust)
    --print("B21_302_polar_sink_mps",B21_302_polar_sink_mps) --debug
end

--[[ *******************************************************
CALCULATE NETTO (sink is negative)
Inputs:
    dataref(b21_total_energy_mps) from b21_total_energy.lua
    B21_302_polar_sink_mps
Outputs:
    L:B21_302_netto_mps

Simply add the calculated polar sink (+ve) back onto the TE reading
E.g. TE says airplane sinking at 2.5 m/s (te = -2.5)
 Polar says aircraft should be sinking at 1 m/s (polar_sink = +1)
 Netto = te + netto = (-2.5) + 1 = -1.5 m/s
]]

function update_netto()
    B21_302_netto_mps = dataref_read("TE_MPS") + B21_302_polar_sink_mps

    local airspeed_mps = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS

    -- correct for low airspeed when instrument would not be fully working
    -- i.e.
    -- at 0 mps airspeed, netto will be forced to zero
    -- at 0..20 mps, value will be scaled from x0 .. x1 using square of airspeed
    -- 20+ mps (~40 knots) value will be 100% of calculated value
    if airspeed_mps < 20
    then
        B21_302_netto_mps = B21_302_netto_mps * (airspeed_mps^2 / 400)
    end
    -- write the netto value to our global dataref so it can be used directly in other gauges
    dataref_write("NETTO",B21_302_netto_mps * MPS_TO_FPM)
    --print("B21_302_netto_mps",B21_302_netto_mps) --debug
end

--[[
                    CALCULATE STF
                    Outputs:
                        (L:B21_302_stf, meters per second)
                    Inputs:
                        (L:B21_302_polar_const_r, number)
                        (L:B21_302_polar_const_v2stfx, number) = if temp_a is less than this, then tweak stf (high lift)
                        (L:B21_302_polar_const_z, number)
                        (L:B21_302_netto, meters per second)
                        (L:B21_302_maccready, meters per second)
                        (L:B21_302_ballast_adjust, number)

                     Vstf = sqrt(R*(maccready-netto) + sqr(stf_best))*sqrt(polar_adjust)

                     if in high lift area then this formula has error calculating negative speeds, so adjust:
                     if R*(maccready-netto)+sqr(Vbest) is below a threshold (v2stfx) instead use:
                        1 / ((v2stfx - [above calculation])/z + 1/v2stfx)
                     this formula decreases to zero at -infinity instead of going negative
]]

-- writes B21_302_stf_mps (speed to fly in m/s)
function update_stf()
    -- stf_temp_a is the initial speed-squared value representing the speed to fly
    -- it will be adjusted if it's below (25 m/s)^2 i.e. vario is proposing a very slow stf (=> strong lift)
    -- finally it will be adjusted according to the ballast ratio
    local B21_302_stf_temp_a =  B21_302_polar_const_r * (B21_302_maccready_mps - B21_302_netto_mps) + B21_polar_stf_best_mps^2
    if B21_302_stf_temp_a < B21_302_polar_const_v2stfx
    then
        B21_302_stf_temp_a = 1.0 / ((B21_302_polar_const_v2stfx - B21_302_stf_temp_a) / B21_302_polar_const_z + (1.0 / B21_302_polar_const_v2stfx))
    end
    B21_302_stf_mps = math.sqrt(B21_302_stf_temp_a) * math.sqrt(B21_302_ballast_adjust)
    --print("B21_302_stf_mps",B21_302_stf_mps, "(",B21_302_stf_mps * MPS_TO_KPH,"kph)") -- debug
end

--[[
                    CALCULATE STF FOR CURRENT MACCREADY (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_stf, meters per second)
]]

-- calculate speed-to-fly in still air for current maccready setting
function update_maccready_stf()
    B21_302_mc_stf_mps = math.sqrt(B21_302_maccready_mps * B21_302_polar_const_r + B21_polar_stf_best_mps^2) *
                         math.sqrt(B21_302_ballast_adjust)
    --print("B21_302_mc_stf_mps", B21_302_mc_stf_mps,"(", B21_302_mc_stf_mps * MPS_TO_KPH, "kph)") --debug
end

--[[
                    CALCULATE POLAR SINK RATE AT MACCREADY STF (SINK RATE IS +ve)
                    (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_sink, meters per second)
                    Inputs:
                        (L:B21_302_mc_stf, meters per second)
                        (L:B21_302_ballast_adjust, number)
]]

function update_maccready_sink()
    B21_302_mc_sink_mps = sink_mps(B21_302_mc_stf_mps * MPS_TO_KPH, B21_302_ballast_adjust)
    --print("B21_302_mc_sink_mps", B21_302_mc_sink_mps,"(", B21_302_mc_stf_mps / B21_302_mc_sink_mps,"mc L/D)") --debug
end

--[[                    CALCULATE ARRIVAL HEIGHT
                Outputs:
                    (L:B21_302_arrival_height, meters)
                    (L:B21_302_height_needed, meters)
                Inputs:
                    (A:AMBIENT WIND DIRECTION, radians)
                    (A:AMBIENT WIND VELOCITY, meters per second)
                    (A:PLANE ALTITUDE, meters)
                    (L:B21_302_mc_stf, meters per second)
                    (L:B21_302_mc_sink, meters per second)
                    (L:B21_302_wp_bearing, radians)
                    (L:B21_302_distance_to_go, meters)
                    (L:B21_302_wp_msl, meters)
                    <Script>
                        (A:AMBIENT WIND DIRECTION, radians) (L:B21_302_wp_bearing, radians) - pi - (&gt;L:B21_theta, radians)
                        (A:AMBIENT WIND VELOCITY, meters per second) (&gt;L:B21_wind_velocity, meters per second)
                        (L:B21_theta, radians) cos (L:B21_wind_velocity, meters per second) * (&gt;L:B21_x, meters per second)
                        (L:B21_theta, radians) sin (L:B21_wind_velocity, meters per second) * (&gt;L:B21_y, meters per second)
                        (L:B21_302_mc_stf, meters per second) sqr (L:B21_y, meters per second) sqr - sqrt
                        (L:B21_x, meters per second) + (&gt;L:B21_vw, meters per second)
                        (L:B21_302_distance_to_go, meters) (L:B21_vw, meters per second) /
                        (L:B21_302_mc_sink, meters per second) * (&gt;L:B21_302_height_needed, meters)

                        (A:PLANE ALTITUDE, meters) (L:B21_302_height_needed, meters) -
                        (L:B21_302_wp_msl, meters) -
                        (&gt;L:B21_302_arrival_height, meters)
]]

function update_arrival_height()

    -- READ shared vars set by gpsnav for waypoint altitude, distance and heading
    local wp_alt_m = project_settings.gpsnav_wp_altitude_m

    local wp_distance_m = project_settings.gpsnav_wp_distance_m

    local wp_bearing_rad = project_settings.gpsnav_wp_heading_deg * DEG_TO_RAD

    local theta_radians = dataref_read("WIND_DEG") * DEG_TO_RAD - wp_bearing_rad - math.pi

    local wind_velocity_mps = dataref_read("WIND_KTS") * KTS_TO_MPS

    local x_mps = math.cos(theta_radians) * wind_velocity_mps

    local y_mps = math.sin(theta_radians) * wind_velocity_mps

    local vw_mps = math.sqrt(B21_302_mc_stf_mps^2 - y_mps^2) + x_mps

    B21_302_height_needed_m = wp_distance_m / vw_mps * B21_302_mc_sink_mps

    B21_302_arrival_height_m = dataref_read("ALT_FT") * FT_TO_M - B21_302_height_needed_m - wp_alt_m
    --print("Wind",dataref_read("WIND_RADIANS"),"radians",dataref_read("WIND_MPS"),"mps") --debug
    --print("B21_302_height_needed_m", B21_302_height_needed_m) --debug
    --print("B21_302_arrival_height_m", B21_302_arrival_height_m) --debug
    -- dataref_write("DEBUG1", math.floor(project_settings.gpsnav_wp_distance_m / 1000))
    -- dataref_write("DEBUG2", math.floor(project_settings.gpsnav_wp_heading_deg))
end

--[[                    CALCULATE ACTUAL GLIDE RATIO
                    <Script>
                        (A:AIRSPEED TRUE, meters per second) (L:B21_302_te, meters per second) neg / d
                        99 &gt;
                        if{
                            99
                        }
                        d
                        0 &lt;
                        if{
                            0
                        }
                        (&gt;L:B21_302_glide_ratio, number)

]]
function update_glide_ratio()
    local sink = -dataref_read("TE_MPS") -- sink is +ve
    if sink < 0.1 -- sink rate obviously below best glide so cap to avoid meaningless high L/D or divide by zero
    then
        B21_302_glide_ratio = 99
    else
        B21_302_glide_ratio = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS / sink
    end
    --print("B21_302_glide_ratio",B21_302_glide_ratio) --debug
end

--[[                CALCULATE AVERAGE CLIMB (m/s) (L:B21_302_climb_average, meters per second)
                    <Minimum>-20.000</Minimum>
                    <Maximum>20.000</Maximum>
                    <Script>
                        (E:ABSOLUTE TIME, seconds) 2 - (L:B21_302_average_start, seconds) &gt;
                        if{
                            (E:ABSOLUTE TIME, seconds) (&gt;L:B21_302_average_start, seconds)

                            (L:B21_302_climb_average, meters per second) 0.85 *
                            (L:B21_302_te, meters per second) 0.15 *
                            +
                            (&gt;L:B21_302_climb_average, meters per second)
                        }
                        (L:B21_302_climb_average, meters per second) (L:B21_302_te, meters per second) - abs 3 &gt;
                        if{
                            (L:B21_302_te, meters per second) (&gt;L:B21_302_climb_average, meters per second)
                        }

]]

-- calculate B21_302_climb_average_mps
function update_climb_average()
    -- only update 2+ seconds after last update
    if dataref_read("TIME_S") - 2 > average_start_s
    then
        average_start_s = dataref_read("TIME_S")

        -- update climb average with smoothing
        B21_302_climb_average_mps = B21_302_climb_average_mps * 0.85 + dataref_read("TE_MPS") * 0.15

        -- if the gap between average and TE > 3m/s then reset to average = TE
        if math.abs(B21_302_climb_average_mps - dataref_read("TE_MPS")) > 3.0
        then
            B21_302_climb_average_mps = dataref_read("TE_MPS")
        end
    end
    --print("B21_302_climb_average_mps",B21_302_climb_average_mps) --debug
end

--[[                    CALCULATE STF NEEDLE VALUE (m/s)
                    STF:
                            (A:AIRSPEED INDICATED, meters per second)
                            (L:B21_302_stf, meters per second) -
                            7 /
                            (&gt;L:B21_302_stf_needle, meters per second)
                    NEEDLE:
                        (L:B21_302_mode_stf, number) 0 == if{
                            (L:B21_302_te, meters per second) (&gt;L:B21_302_needle, meters per second)
                        } els{
                            (L:B21_302_stf_needle, meters per second) (&gt;L:B21_302_needle, meters per second)
                        }
]]

-- write value to B21_302_needle_fpm
function update_needle()
    local needle_mps
    if B21_302_mode_stf
    then
        needle_mps = (dataref_read("AIRSPEED_KTS") * KTS_TO_MPS - B21_302_stf_mps)/ 7
    else
        needle_mps = dataref_read("TE_MPS")
    end

    -- correct for speed
    local airspeed_mps = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS
    -- correct for low airspeed when instrument would not be fully working
    -- i.e.
    -- at 0 mps airspeed, needle_mps will be forced to zero
    -- at 0..20 mps, value will be scaled from x0 .. x1 using square of airspeed
    -- 20+ mps (~40 knots) value will be 100% of calculated value
    if airspeed_mps < 20
    then
        needle_mps = needle_mps * (airspeed_mps^2 / 400)
    end

    B21_302_needle_fpm = needle_mps * MPS_TO_FPM
    dataref_write("NEEDLE_FPM", B21_302_needle_fpm)
    --print("B21_302_needle_fpm",B21_302_needle_fpm)--debug
end

-- write value to b21/vario_sound_fpm dataref
function update_vario_sound()
    dataref_write("VARIO_SOUND_FPM", B21_302_needle_fpm)
end

-- show the 'PULL' indicator on the vario display
function update_pull()
    if B21_302_mode_stf and B21_302_needle_fpm > 100.0
    then
        dataref_write("PULL", 1)
    else
        dataref_write("PULL", 0)
    end
end

function update_push()
    if B21_302_mode_stf and B21_302_needle_fpm < -100
    then
        dataref_write("PUSH", 1)
    else
        dataref_write("PUSH", 0)
    end
end

--update top number of 302 vario with altitude
function update_top_number()
    -- only update every 1 seconds max
    local now_s = dataref_read("TIME_S")
    if now_s < prev_number_top_s + 1
    then
        return
    end

    local reading -- numerical value to display, feet or meters

    if dataref_read("UNITS_ALTITUDE") == 1 -- 0=feet, 1=meters
    then -- write meters
        reading = B21_302_arrival_height_m -- dataref_read("ALT_FT") * FT_TO_M
    else -- write feet
        reading = B21_302_arrival_height_m * M_TO_FT --dataref_read("ALT_FT")
    end

    -- limit reading to 4 digits
    if reading < -9999
    then
        reading = -9999
    elseif reading > 9999
    then
        reading = 9999
    end

    dataref_write("NUMBER_TOP", math.abs(reading))

    prev_number_top_s = now_s -- record the time we just updated the display

    -- if negative we'll overlay a '-' to the left of the leftmost digit
    -- we use a gen_LED overlay which displays a '-' for '9' and blank for '0'
    -- e.g. 9000 will display "-   ", so overlaid over " 123" will show "-123"

    local number_sign -- will be 9XXX where the X's represent the existing digits

    if reading >= 0
    then
        if reading > 9999
        then
            reading = 9999
        end
        number_sign = 10^math.floor(math.log10(reading)+1)*8
    else
        if reading < -9999
        then
            reading = -9999
        end
        -- create number 'mask' to put '-' in the right place
        -- e.g. reading = 123 => number_minus=9000, hence '-123'
        number_sign = 10^math.floor(math.log10(-reading)+1)*9
    end
    -- fixup for readings 0.X, change 8 to 80, 9 to 90.
    if number_sign < 10
    then
        number_sign = number_sign * 10
    end

    dataref_write("NUMBER_TOP_SIGN", number_sign)

end

--update bottom number of 302 vario with climb average
function update_bottom_number()

    local reading

    if dataref_read("UNITS_VARIO") == 1 -- meters per second
    then
        reading = math.floor(B21_302_climb_average_mps * 10.0 + 0.5) / 10.0
    else                                -- knots
        reading = math.floor(B21_302_climb_average_mps * MPS_TO_KTS * 10.0 + 0.5) / 10.0
    end

    dataref_write("NUMBER_BOTTOM", math.abs(reading))

    -- put a +/- in front of the first digit

    local number_sign

    if reading >= 0
    then
        if reading > 999
        then
            reading = 999
        end
        local digits
        if reading < 1
        then
            number_sign = 80
        else
            number_sign = 10^math.floor(math.log10(reading)+1)*8
        end
    else
        if reading < -9999
        then
            reading = -9999
        end
        -- create number 'mask' to put '-' in the right place
        -- e.g. reading = 123 => number_minus=9000, hence '-123'
        if reading > -1
        then
            number_sign = 80
        else
            number_sign = 10^math.floor(math.log10(-reading)+1)*9
        end
    end

    dataref_write("NUMBER_BOTTOM_SIGN", number_sign)

end

--update right number of 302 vario with maccready setting
function update_right_number()
    if dataref_read("UNITS_VARIO") == 1 -- meters per second
    then
        dataref_write("NUMBER_RIGHT", math.floor(B21_302_maccready_mps * 10.0 + 0.5) / 10.0)
    else                                -- knots
        dataref_write("NUMBER_RIGHT", math.floor(B21_302_maccready_kts * 10.0 + 0.5) / 10.0)
    end
end

-- Finally, here's the per-frame update() callabck
function update()
    update_ballast()
    update_maccready()
    update_stf_te_mode()

    update_polar_sink()
    update_netto()
    update_stf()
    update_maccready_stf()
    update_maccready_sink()
    update_arrival_height()
    update_glide_ratio()
    update_climb_average()
    update_needle()
    update_vario_sound()
    update_pull()
    update_push()
    update_top_number()
    update_bottom_number()
    update_right_number()
end
