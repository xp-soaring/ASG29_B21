-- B21
-- Trigger trim: set trim for aircraft to match current airspeed
-- Take current airspeed for range Min-Mid-Max and set trim dataref to +1 .. 0 .. -1

-- TRIM trigger calibration, must match aircraft for trigger trim to set accurately
TRIM_SPEED_KTS = { 46, 64, 87 } -- cruise speeds (knots) for trim range +1..0..-1

print("b21_trim starting, v0.89")

-- WRITE datarefs
local DATAREF_TRIM = globalPropertyf("sim/cockpit2/controls/elevator_trim") -- -1.0 .. +1.0
--local DATAREF_TRIM_DEBUG = 0.3

-- READ datarefs
local DATAREF_AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")
local DATAREF_YOKE_PITCH = globalPropertyf("sim/joystick/yoke_pitch_ratio") -- -1..+1
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground
--

local sound_trim = loadSample(sasl.getAircraftPath()..'/sounds/systems/trim.wav')
setSampleGain(sound_trim, 500)

local command_time_s = 0.0 -- time button was previously clicked (so only one action per click)
local command_trim = 0.0
local prev_trim_time_s = 0.0

local command_trim_trigger = sasl.createCommand("b21/trim/trigger",
    "Sailplane elevator trim set immediately to current speed")

-- Handler for the "b21/trim/trigger" command.
-- Will set value of global command_trim
function clicked_trim_trigger(phase)
    local time_now_s = get(DATAREF_TIME_S)
    if time_now_s > command_time_s + 0.2 and phase == SASL_COMMAND_BEGIN
    then
        
        command_time_s = time_now_s

        print("b21_trim command b21/trigger/trim started at",command_time_s)

        playSample(sound_trim, false)

        -- if on ground then use yoke pitch position
        if true or get(DATAREF_ONGROUND) == 1
        then
            command_trim = get(DATAREF_YOKE_PITCH) * 1.5
            if command_trim > 1
            then
                command_trim = 1
            elseif command_trim < -1
            then
                command_trim = -1
            end
            print("b21_trim (yoke position): command trim set to",command_trim)
            return
        end

        -- note this code below currently disabled as we try 'stick position' for trim setting

        -- otherwise set trim according to current airspeed
        local Smin = TRIM_SPEED_KTS[1]
        local Szero = TRIM_SPEED_KTS[2]
        local Smax = TRIM_SPEED_KTS[3]

        local S = get(DATAREF_AIRSPEED_KTS) -- current speed

        if S < Smin
        then
            command_trim = 1.0                           -- i.e. set +1
        elseif S < Szero
        then
            command_trim = (Szero - S) / (Szero - Smin)  -- i.e. set +1 .. 0
        elseif S < Smax
        then
            command_trim = (Szero - S)/(Smax - Szero)    -- i.e. set 0 .. -1
        else
            command_trim = -1.0                          -- i.e. set -1
        end
        print("b21_trim (airspeed) command trim set to",command_trim)
    end
    return 1
end

sasl.registerCommandHandler(command_trim_trigger, 0, clicked_trim_trigger)

local TRIM_PER_SECOND = 1.0 -- amount of trim smoothing

-- update the actual trim setting to value of "command_trim" gradually
function update()
    local time_now_s = get(DATAREF_TIME_S)
    local time_delta_s = time_now_s - prev_trim_time_s
    -- print("time_delta_s = "..time_delta_s)

    -- Only apply the adjustments within 5 seconds of command
    -- (otherwise will always override other trim inputs)
    -- Also only update every half-second
    local trim_time_step = 0.25  -- update 2 per second max
    if  (time_now_s < command_time_s + 5.0) and (time_delta_s > trim_time_step)
    then
        --local current_trim = DATAREF_TRIM_DEBUG --get(DATAREF_TRIM)
        local current_trim = get(DATAREF_TRIM)
        print("b21_trim read DATAREF_TRIM at", time_now_s, time_delta_s, current_trim)
        local trim_delta = command_trim - current_trim
        --print("update trim trim_delta="..trim_delta)
        if  math.abs(trim_delta) > 0.05
        then
            if math.abs(trim_delta) > 0.2
            then
                trim_delta = trim_delta > 0 and 0.2 or -0.2
            end
            local new_trim = current_trim + trim_delta * trim_time_step * TRIM_PER_SECOND
            if new_trim > 1.0
            then
                new_trim = 1.0
            elseif new_trim < -1.0
            then
                new_trim = -1.0
            end
            --print("new trim", new_trim)
            print("b21_trim writing DATAREF_TRIM",new_trim,time_delta_s, current_trim, trim_delta)
            --DATAREF_TRIM_DEBUG = new_trim --set(DATAREF_TRIM, new_trim)
            set(DATAREF_TRIM, new_trim)
        end
        prev_trim_time_s = time_now_s
    end
end
