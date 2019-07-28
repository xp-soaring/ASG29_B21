-- B21
-- This plugin calculates the position of the min/max g-meter bugs.
-- No plugin code needed for needle as that is directly driven by dataref "sim/flightmodel/forces/g_nrml"

-- COMMANDS
local command_reset = sasl.createCommand("b21/gmeter/reset", "Reset min/max bugs on G meter")

-- WRITE datarefs
-- min/max bug positions on rim of meter - start at 1g +/- 0.25
local DATAREF_G_MIN = createGlobalPropertyf("b21/gmeter/min_g", 0.75, false, true, true)
local DATAREF_G_MAX = createGlobalPropertyf("b21/gmeter/max_g", 1.25, false, true, true)

-- READ datarefs
local DATAREF_G = globalPropertyf("sim/flightmodel/forces/g_nrml") -- note this can be briefly 0 on startup (should be 1)
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")

print("b21_gmeter.lua starting "..get(DATAREF_G))

local g_min -- we're using local vars for min/max to reduce dataref reads
local g_max
local load_time_s = 0 -- record startup time so we can create startup delay

function reset()
    g_min = 0.75
    g_max = 1.25
    set(DATAREF_G_MIN, g_min)
    set(DATAREF_G_MAX, g_max)
end

-- G meter reset button command handler
function clicked_reset(phase)
    if phase == SASL_COMMAND_BEGIN
    then
      print("gmeter reset")
      reset()
    end
end

-- on load start with bugs reset
reset()

-- XPlane pre-frame update loop
function update()
    local now_s = get(DATAREF_TIME_S)
    -- set load time on first call of update()
    if load_time_s == 0
    then
        load_time_s = now_s
    end
    if now_s > load_time_s + 5 -- only update after startup delay so XPlane 'G' reading can stabilize
    then
        -- get the current G reading (steady flight will be close to 1.0)
        local g = get(DATAREF_G)

        -- If the current G is smaller than the min or bigger than the max then update those
        if g < g_min
        then
            g_min = g
            set(DATAREF_G_MIN, g)
        elseif g > g_max
        then
            g_max = g
            set(DATAREF_G_MAX, g)
        end
    end
end

sasl.registerCommandHandler(command_reset, 0, clicked_reset)
