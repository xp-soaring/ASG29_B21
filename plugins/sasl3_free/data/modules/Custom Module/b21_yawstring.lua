-- B21
-- 
print("b21_yawstring.lua starting")

-- WRITE datarefs
-- angle of stuck on bit of yawstring (0=vertical along canopy)
local DATAREF_YAWSTRING_1_DEG = createGlobalPropertyf("b21/yawstring/1", 0.0, false, true, true) -- -90..90
-- angle of main section of yawstring (i.e. yaw)
local DATAREF_YAWSTRING_2_DEG = createGlobalPropertyf("b21/yawstring/2", 30.0, false, true, true) -- -90..90

-- READ datarefs
local DATAREF_BETA = globalPropertyf("sim/flightmodel/position/beta")
local DATAREF_AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")
-- 

function update()
    local yaw_deg = get(DATAREF_BETA)
    local yaw_now_deg = yaw_deg * 4 + (math.random() - 0.5) * get(DATAREF_AIRSPEED_KTS) / 25.0
    set(DATAREF_YAWSTRING_2_DEG, yaw_now_deg)
end
