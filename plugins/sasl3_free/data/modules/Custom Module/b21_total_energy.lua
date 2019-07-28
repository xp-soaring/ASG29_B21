-- B21

DATAREF = {}
-- datarefs from x-plane
DATAREF.TIME_S = globalPropertyf("sim/network/misc/network_time_sec") -- 100
DATAREF.ALT_FT = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot") -- 3000
-- (for calibration) local sim_alt_m = globalPropertyf("sim/flightmodel/position/elevation")
DATAREF.AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot") -- 60
-- (for calibration) local sim_speed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")

-- create global DataRefs we will WRITE (name, default, isNotPublished, isShared, isReadOnly)
DATAREF.TE_MPS = createGlobalPropertyf("b21/total_energy_mps", 0.0, false, true, true)
DATAREF.TE_FPM = createGlobalPropertyf("b21/total_energy_fpm", 0.0, false, true, true)
DATAREF.TE_KTS = createGlobalPropertyf("b21/total_energy_kts", 0.0, false, true, true)

-- shared project data
local prev_total_energy_mps = 0.0

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

-- previous TE update time (float seconds)
te_prev_time_s = dataref_read("TIME_S")

-- previous altitude (float meters)
prev_alt_m = 0.0 -- debug 913

-- previous speed squared (float (m/s)^2 )
prev_speed_mps_2 = 0.0 -- 952.75 --debug 60knots

-- calculate TE value from time, altitude and airspeed
function update_total_energy()
    
	-- calculate time (float seconds) since previous update
	local time_delta_s = dataref_read("TIME_S") - te_prev_time_s
	--print("time_delta_s ",time_delta_s) --debug
	-- only update max 20 times per second (i.e. time delta > 0.05 seconds)
	if time_delta_s > 0.05
	then
		-- get current speed in m/s
		local speed_mps = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS
		-- (for calibration) local speed_mps = dataref_read(sim_speed_mps)

		-- calculate current speed squared (m/s)^2
		local speed_mps_2 = speed_mps * speed_mps
		--print("speed_mps^2 now",speed_mps_2)
		-- TE speed adjustment (m/s)
		local te_adj_mps = (speed_mps_2 - prev_speed_mps_2) / (2 * 9.81 * time_delta_s)
		--print("te_adj_mps", te_adj_mps) --debug
		-- calculate altitude delta (meters) since last update
		local alt_delta_m = dataref_read("ALT_FT") * FT_TO_M - prev_alt_m
		-- (for calibration) local alt_delta_m = dataref_read(sim_alt_m) - prev_alt_m
		--print("alt_delta_m",alt_delta_m) --debug
		-- calculate plain climb rate
		local climb_mps = alt_delta_m / time_delta_s
		--print("rate of climb m/s", climb_mps) -- debug
		-- calculate new vario compensated reading using 70% current and 30% new (for smoothing)
		local te_mps = prev_total_energy_mps * 0.7 + (climb_mps + te_adj_mps) * 0.3
		
		-- limit the reading to 7 m/s max to avoid a long recovery time from the smoothing
		if te_mps > 7
		then
			te_mps = 7
		end
		
		-- all good, transfer value to the needle
        -- write value to datarefs
        dataref_write("TE_MPS", te_mps) -- meters per second
        dataref_write("TE_FPM", te_mps * MPS_TO_FPM) -- feet per minute
        dataref_write("TE_KTS", te_mps * MPS_TO_KTS) -- knots
		
		-- store time, altitude and speed^2 as starting values for next iteration
		te_prev_time_s = dataref_read("TIME_S")
		prev_alt_m = dataref_read("ALT_FT") * FT_TO_M
		-- (for calibration) prev_alt_m = dataref_read(sim_alt_m)
        prev_speed_mps_2 = speed_mps_2
        -- finally write value
        prev_total_energy_mps = te_mps
        --print("B21_302_te_mps", B21_302_te_mps)
	end
		
end -- update_total_energy

-- Finally, here's the per-frame update() callback
function update()
    update_total_energy()
end
