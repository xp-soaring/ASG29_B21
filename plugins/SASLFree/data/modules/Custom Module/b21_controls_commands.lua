-- B21
-- controls commands: issue X-Plane commands on control movements
-- e.g. waggle aileron left-right-left-right for WINGS LEVEL

print("b21_controls_commands.lua starting")

local COMMAND_AILERONS = sasl.findCommand("b21/wings_level_on")

-- READ datarefs
local DATAREF_AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
-- left/right position of control yoke (-1..+1, left roll is negative)
local DATAREF_YOKE_ROLL = globalPropertyf("sim/cockpit2/controls/yoke_roll_ratio")
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")
-- 
-- convenience constants
local LEFT = 0
local RIGHT = 1

-- AILERON WAGGLE VARS
-- constants
local ROLL_THRESHOLD = 0.55 -- amount of movement necessary to be recognized as waggle
local ROLL_TIME = 5 -- time in seconds that waggle must complete within
-- globals
local roll_mode = 99 -- i.e. start not in roll mode left or right
-- vars to record times when yoke was left and right
local roll_left_times = { 0.0, 0.0 }
local roll_right_times = { 0.0, 0.0 }

function reset_aileron()
    roll_left_times = { 0.0, 0.0 }
    roll_right_times = { 0.0, 0.0 }
    roll_mode = 99
end

-- detect aileron waggle
-- We record the timestamps the control yoke passes the left/right thresholds
-- and see if multiple opposite moves occurred within the 'ROLL_TIME'
function update_aileron()
    local now_s = get(DATAREF_TIME_S)
    local roll_now = get(DATAREF_YOKE_ROLL)
    if roll_now > ROLL_THRESHOLD -- yoke = roll right
    then
        if roll_mode ~= RIGHT
        then
            -- have just entered right roll so push previous right time
            roll_right_times[2] = roll_right_times[1]
            roll_mode = RIGHT
            -- store this right roll time
            roll_right_times[1] = now_s
            --print("RIGHT")
            if (roll_right_times[2] > 0 and roll_right_times[1] - roll_right_times[2] < ROLL_TIME)
            then
                reset_aileron()
                --print("WAGGLE AILERONS COMMAND")
                sasl.commandOnce(COMMAND_AILERONS)
            end
        end
    elseif roll_now < -ROLL_THRESHOLD -- yoke = roll left
    then
        if roll_mode ~= LEFT
        then
            --print("LEFT")
            -- have just entered left roll so push previous time
            roll_left_times[2] = roll_left_times[1]
            roll_mode = LEFT
            -- store this left roll time
            roll_left_times[1] = now_s
            if (roll_left_times[2] > 0 and roll_left_times[1] - roll_left_times[2] < ROLL_TIME)
            then
                reset_aileron()
                --print("WAGGLE AILERONS COMMAND")
                sasl.commandOnce(COMMAND_AILERONS)
            end
        end
    end
end

-- update the actual trim setting gradually
function update()
    update_aileron()
end
