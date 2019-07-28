
-- WRITE datarefs
local DATAREF_SMOKE = globalPropertyi("sim/cockpit/weapons/missiles_armed") -- X-Plane Particle system not supporting plugin datarefs

print("b21_smoke loading "..get(DATAREF_SMOKE))

-- COMMANDS
local command_smoke_toggle = sasl.createCommand("b21/smoke/toggle", "Toggle wingtip smoke emitters")
local command_smoke_on = sasl.createCommand("b21/smoke/on", "Enable wingtip smoke emitters")
local command_smoke_off = sasl.createCommand("b21/smoke/off", "Disable wingtip smoke emitters")

-- READ datarefs
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")

local command_time_s = 0.0

function clicked_smoke_on(phase)
  if phase == SASL_COMMAND_BEGIN
  then
    set(DATAREF_SMOKE,1)
    print("smoke on")
  end
end

function clicked_smoke_off(phase)
  if phase == SASL_COMMAND_BEGIN
  then
    set(DATAREF_SMOKE,0)
    print("smoke off")
  end
end

function clicked_smoke_toggle(phase)
  local time_now_s = get(DATAREF_TIME_S) -- use time delay to protect from switch bounce
  if time_now_s > command_time_s + 0.2 and phase == SASL_COMMAND_BEGIN
  then
    command_time_s = time_now_s
    if get(DATAREF_SMOKE) <= 0.1
    then
      set(DATAREF_SMOKE,1)
	    print("smoke toggle to on")
    else
      set(DATAREF_SMOKE,0)
	    print("smoke toggle to off")
	  end
  end
  return 0
end

sasl.registerCommandHandler(command_smoke_toggle, 0, clicked_smoke_toggle)
sasl.registerCommandHandler(command_smoke_on, 0, clicked_smoke_on)
sasl.registerCommandHandler(command_smoke_off, 0, clicked_smoke_off)
