defineProperty("vario_raw", globalPropertyf("sim/cockpit2/gauges/indicators/total_energy_fpm")) -- source dataref, raw, float 
defineProperty("climbrate", globalPropertyf("sim/auriel/te_vario")) -- target dataref, smoothed, float
defineProperty("vario_samplerate", globalPropertyi("sim/auriel/vario_samplerate")) -- dataref to read the sensitivity setting from, integer

--[[ 
"Sensitivity" really means the size of the sample buffer in X-plane's frames per second. So a setting of 100 means a delay of 100 
frames until the smoothed data is fed back to the sim. Of course for a slow computer, a delay of 100 frames is much longer than for a fast computer,
so having a dial in the cockpit is nice, the user can set adjust the sensitivity to get the desired result in regards to their in-game frame rate.
--]]

--------------- initialise, set sample rate to 100 when plane loads
done = false
set(vario_samplerate, 100)


function update()
--------------- read rheostat dataref and change "samplerate/sensitivity" if needed 
if done == false then
	samplerate = get(vario_samplerate)
	samplebuffer = { }
	for i = 1, samplerate do
		samplebuffer[i] = get(vario_raw)
	end
	done = true
end	
--------------- main function, moving average calc
    smoothed_vario = get(vario_raw)
    for i = 2, samplerate do
        smoothed_vario = smoothed_vario + samplebuffer[i]
        samplebuffer[i-1] = samplebuffer[i]
    end
    samplebuffer[samplerate] = get(vario_raw)
	set(climbrate, (smoothed_vario / samplerate))
	if samplerate ~= get(vario_samplerate) then
		done = false
	end	
end