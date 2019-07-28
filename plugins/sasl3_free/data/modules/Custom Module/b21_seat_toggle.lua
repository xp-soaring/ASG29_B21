-- B21
-- This plugin provides the command "b21/seat_toggle" which moves the pilot viewpoint from P1 <-> P2

-- COMMANDS
local command_seat_toggle = sasl.createCommand("b21/seat_toggle", "Toggle pilot position between P1 and P2")

-- WRITE datarefs
local DATAREF_PILOT_Y = globalPropertyf("sim/graphics/view/pilots_head_y") -- +up/-down
local DATAREF_PILOT_Z = globalPropertyf("sim/graphics/view/pilots_head_z") -- +aft/-forward

print("b21_seat_toggle.lua starting ")

local seat_p1 = true -- start as P1

-- 
function clicked_seat_toggle(phase)
    if phase == SASL_COMMAND_BEGIN
    then
      print("seat toggle")
      if seat_p1
      then -- current seat is P1, so set view for P2
        seat_p1 = false
        set(DATAREF_PILOT_Y, 0.29)
        set(DATAREF_PILOT_Z, -0.1)
      else -- current seat is P2 so set view for P1
        seat_p1 = true
        set(DATAREF_PILOT_Y, 0.21)
        set(DATAREF_PILOT_Z, -1.22)
      end
    end
end

sasl.registerCommandHandler(command_seat_toggle, 0, clicked_seat_toggle)
