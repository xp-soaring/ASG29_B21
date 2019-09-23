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

-- the datarefs we will READ to get time, altitude and speed from the sim
DATAREF = {}

-- datarefs from other B21 modules
DATAREF.TE_MPS = globalPropertyf("b21/total_energy_mps")
DATAREF.STF_KTS = globalPropertyf("b21/stf_kts")

-- datarefs updated by panel:
DATAREF.KNOB = createGlobalPropertyf("b21/vario_302/knob", 0, false, true, false) -- 2.0
DATAREF.STF_TE_SWITCH = createGlobalPropertyi("b21/vario_302/stf_te_switch", project_settings.VARIO_302_MODE, false, true, false)
     -- (0=stf, 1=auto, 2=te)

-- datarefs from x-plane
DATAREF.TIME_S = globalPropertyf("sim/network/misc/network_time_sec") -- 100
DATAREF.ALT_FT = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot") -- 3000
-- (for calibration) local sim_alt_m = globalPropertyf("sim/flightmodel/position/elevation")
DATAREF.AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot") -- 60
DATAREF.TURN_RATE_DEG = globalProperty("sim/cockpit2/gauges/indicators/turn_rate_heading_deg_pilot")

-- datarefs from USER_SETTINGS.lua
DATAREF.UNITS_VARIO = globalProperty("b21/units_vario") -- 0 = knots, 1 = m/s (from settings.lua)
DATAREF.UNITS_ALTITUDE = globalProperty("b21/units_altitude") -- 0 = feet, 1 = meters (from settings.lua)
DATAREF.UNITS_SPEED = globalProperty("b21/units_speed") -- 0 = knots, 1 = km/h (from settings.lua)

-- create global DataRefs we will WRITE (name, default, isNotPublished, isShared, isReadOnly)
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

-- vario modes
B21_302_mode_stf = project_settings.VARIO_302_MODE  -- 0 = speed to fly, 1 = TE, 2 = AUTO

-- debug glide ratio
B21_302_glide_ratio = 0.0

-- vario needle value
B21_302_needle_fpm = 0.0

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

-- write value to B21_302_needle_fpm
function update_needle()
    local needle_mps
    if B21_302_mode_stf
    then
        needle_mps = (dataref_read("AIRSPEED_KTS") * KTS_TO_MPS - dataref_read("STF_KTS") * KTS_TO_MPS)/ 7
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

    local reading = B21_302_glide_ratio -- numerical value to display, feet or meters

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
        dataref_write("NUMBER_RIGHT", 1.2)
end

-- Finally, here's the per-frame update() callabck
function update()
    update_stf_te_mode()
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
