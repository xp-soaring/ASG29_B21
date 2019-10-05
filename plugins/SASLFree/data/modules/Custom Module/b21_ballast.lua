-- b21_ballast
-- x-plane plugin to display ballast % and support fill/open/close commands

print("b21_ballast starting")

local BALLAST_MAX_KG = 200       -- Max ballast capacity in Kg
local BALLAST_DUMP_RATE = BALLAST_MAX_KG/240 -- Ballast dump rate in Kg/s => 4 minute dump

-- WRITE datarefs
local DATAREF_BALLAST_KG = globalPropertyf("sim/flightmodel/weight/m_jettison") -- Kg water ballast
-- using missles dataref as X-Plane Particle system not supporting plugin datarefs
local DATAREF_BALLAST_CONTROL = globalPropertyi("sim/cockpit/weapons/missiles_armed")

-- READ datarefs
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground

--

local command_fill = sasl.createCommand("b21/ballast/fill",
    "Fill water ballast")
local command_open = sasl.createCommand("b21/ballast/open",
    "Open ballast dump valve")
local command_close = sasl.createCommand("b21/ballast/close",
    "Close ballast dump valve")

-- bool to control dumping / not dumping status
local ballast_dumping = false

-- track time as only need update once per sec
local prev_time_s

function fill()
    set(DATAREF_BALLAST_KG, BALLAST_MAX_KG)
    ballast_dumping = false
    set(DATAREF_BALLAST_CONTROL, 0) -- set ballast dump particles to 'off'
end

function ballast_fill(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("BALLAST_FILL COMMAND")
        -- only fill on the ground
        if get(DATAREF_ONGROUND) == 1
        then
            fill()
        else
            print("BALLAST_FILL NOT ON GROUND")
        end
    end
    return 1
end

function ballast_open(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("BALLAST_OPEN COMMAND")
        ballast_dumping = true
        set(DATAREF_BALLAST_CONTROL, 1) -- set ballast dump particles to 'on'
        prev_time_s = get(DATAREF_TIME_S)
    end
    return 1
end

function ballast_close(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("BALLAST_CLOSE COMMAND")
        ballast_dumping = false
        set(DATAREF_BALLAST_CONTROL, 0) -- set ballast dump particles to 'off'
    end
    return 1
end

sasl.registerCommandHandler(command_fill, 0, ballast_fill)
sasl.registerCommandHandler(command_open, 0, ballast_open)
sasl.registerCommandHandler(command_close, 0, ballast_close)

-- setup boolean to trigger init code on first run of update()
local init_required = true

function ballast_init()
    set(DATAREF_BALLAST_KG, BALLAST_MAX_KG) -- fill ballast to max
    set(DATAREF_BALLAST_CONTROL, 0) -- set ballast dump particles to 'off'
end

-- apply a rotational force to aircraft while wings_level_running = 1 and roll not zero
function update()

    -- INIT code block
    if init_required
    then
        prev_time_s = get(DATAREF_TIME_S)
        fill()
        -- init complete, so prevent re-init of future update() calls
        init_required = false
    end

    local time_delta_s = get(DATAREF_TIME_S) - prev_time_s

    if ballast_dumping and time_delta_s > 1.0
    then
        local current_ballast_kg = get(DATAREF_BALLAST_KG)
        if current_ballast_kg > 0
        then
            current_ballast_kg = current_ballast_kg - BALLAST_DUMP_RATE * time_delta_s
            if current_ballast_kg < 0
            then
                current_ballast_kg = 0
                ballast_dumping = false
                set(DATAREF_BALLAST_CONTROL, 0) -- set ballast dump particles to 'off'
                print("ballast dump complete")
            end
            set(DATAREF_BALLAST_KG, current_ballast_kg)
        end
        prev_time_s = get(DATAREF_TIME_S)
    end
end
