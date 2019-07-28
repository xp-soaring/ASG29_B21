-- B21
-- Wings level

print("b21_wings_level starting")

-- WRITE datarefs
local DATAREF_ROLL_NM = globalPropertyf("sim/flightmodel/forces/L_plug_acf") -- Newton-meters, +ve is right-roll
-- READ datarefs
local DATAREF_ROLL_DEG = globalPropertyf("sim/flightmodel/position/true_phi") -- deg
local DATAREF_ROLL_RATE_DEG_S = globalPropertyf("sim/flightmodel/position/P") -- deg/sec
local DATAREF_GROUNDSPEED_MS = globalPropertyf("sim/flightmodel/position/groundspeed")
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground
local dataref_time_s = globalPropertyf("sim/network/misc/network_time_sec")
--

local WING_LEVELLER_FORCE = 100 -- newtons
local WING_LENGTH = 10 -- meters

--local sound_trim = loadSample(sasl.getAircraftPath()..'/sounds/systems/trim.wav')
-- setSampleGain(sound_trim, 500)

local command_wings_level_on = sasl.createCommand("b21/wings_level_on",
    "Start level aircraft wings (e.g. sailplane)")
local command_wings_level_off = sasl.createCommand("b21/wings_level_off",
    "Stop level aircraft wings (e.g. sailplane)")
local command_wings_level_toggle = sasl.createCommand("b21/wings_level_toggle",
    "Start/Stop level aircraft wings (e.g. sailplane)")

local wings_level_running = 0

function wings_level_on(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("WINGS_LEVEL_ON COMMAND")
        wings_level_running = 1
    end
    return 1
end

function wings_level_off(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("WINGS_LEVEL_OFF COMMAND")
        wings_level_running = 0
    end
    return 1
end

function wings_level_toggle(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("WINGS_LEVEL_TOGGLE COMMAND")
        if wings_level_running == 0
        then
            wings_level_running = 1
        else
            wings_level_running = 0
        end
    end
    return 1
end

sasl.registerCommandHandler(command_wings_level_on, 0, wings_level_on)
sasl.registerCommandHandler(command_wings_level_off, 0, wings_level_off)
sasl.registerCommandHandler(command_wings_level_toggle, 0, wings_level_toggle)

function crew_force()
    local roll = get(DATAREF_ROLL_DEG)
    local roll_rate = get(DATAREF_ROLL_RATE_DEG_S)
    local roll_force = (-roll / 10.0) * WING_LEVELLER_FORCE * WING_LENGTH   -- roll force proportional to required move
    local roll_rate_force = -roll_rate * 100 -- create damping force based on roll speed
    --print("wings_level roll="..roll,"crew"..roll_force,"roll drag="..roll_rate_force,"total="..roll_force+roll_rate_force)
    return roll_force + roll_rate_force
end

-- apply a rotational force to aircraft while wings_level_running = 1 and roll not zero
function update()
    if wings_level_running == 1
    then
        if get(DATAREF_ONGROUND) ~= 1 -- wings can only be levelled while on ground
           or get(DATAREF_GROUNDSPEED_MS) > 3.0 -- assume wings levelled up to 3 m/s (~6 knots)
        then
            print("WINGS_LEVEL AUTOCANCEL")
            wings_level_running = 0 -- if airborn or rolling fast then cancel wings_level
        else
            local force_now_nm = get(DATAREF_ROLL_NM)
            local roll_force = crew_force()
            set(DATAREF_ROLL_NM, force_now_nm + roll_force)
            --print("FORCE NOW="..force_now_nm, roll_force)
        end
    end
end
