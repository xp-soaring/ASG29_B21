-- B21

-- This is a workaround to allow a han_dihed (Dihedral handle) instrument on the
-- 3D panel to open/close the canopy as we are now using the proper xplane command

print("b21_canopy starting")

-- READ datarefs
DATAREF_DIHED_RQ = globalPropertyf("sim/flightmodel/controls/dihed_rqst") -- 0 (open) .. 0.499 (close)
DATAREF_CANOPY_OPEN = globalPropertyf("sim/flightmodel2/misc/canopy_open_ratio") -- 0 (close)..1 (open)
DATAREF_CANOPY_CONTROL = globalPropertyf("sim/cockpit2/switches/canopy_open") -- 0 (close)..1 (open)
local init = true
local prev_canopy_control

function update()
    -- on startup get initial canopy_open_ratio (so we can detect if user changes it via command)
    if init
    then
        prev_canopy_control = get(DATAREF_CANOPY_CONTROL)
        print("b21_canopy starting with canopy_control=",prev_canopy_control)
        init = false
    end

    local canopy_control = get(DATAREF_CANOPY_CONTROL)

    if canopy_control < prev_canopy_control
    then
        -- user command = canopy closing
        set(DATAREF_DIHED_RQ,0.499) -- this will trigger animation
        prev_canopy_control = 0.0
        print("canopy down")
        return
    end

    if canopy_control > prev_canopy_control
    then
        -- user command = canopy opening
        set(DATAREF_DIHED_RQ,0.0) -- this will trigger animation
        prev_canopy_control = 1.0
        print("canopy up")
        return
    end

end
