local spoilers_unlock = loadSample('sounds/systems/BrakesOut.wav')
local spoilers_lock = loadSample('sounds/systems/BrakesIn.wav')
local acoustic_vario = loadSample('sounds/alert/vario_climb.wav')
local acoustic_vario_descend = loadSample('sounds/alert/vario_descend.wav')

defineProperty("spoiler_ratio", globalPropertyf("sim/cockpit2/controls/speedbrake_ratio")) -- get value of spoiler lever setting
defineProperty("pause", globalPropertyf("sim/time/paused")) -- check if sim is paused
defineProperty("acousticswitch", globalPropertyi("sim/auriel/acoustic_switch")) -- dataref for the "sensitivity" rheostat
defineProperty("climbrate", globalPropertyf("sim/auriel/te_vario")) -- 'smoothed' vario dataref, will be used to set pitch of vario sound

local status = 0
local loop = 0

setSampleGain(spoilers_lock, 500)
setSampleGain(spoilers_unlock, 500)

function update()


--------------- generate airbrake lock / unlock sounds
if get(spoiler_ratio) > 0.03 and status == 0 then 
		playSample(spoilers_unlock, 0)
		status = 1
	end

if get(spoiler_ratio) < 0.03 and status == 1 then
		playSample(spoilers_lock, 0)
		status = 0
	end


--------------- Acoustic variometer volume dial
if get(acousticswitch) == 1 then
	setSampleGain(acoustic_vario, 100)
	setSampleGain(acoustic_vario_descend, 100)
	elseif get(acousticswitch) == 2 then
		setSampleGain(acoustic_vario, 200)
		setSampleGain(acoustic_vario_descend, 200)
    elseif get(acousticswitch) == 3 then
		setSampleGain(acoustic_vario, 300)
		setSampleGain(acoustic_vario_descend, 300)
	elseif get(acousticswitch) == 4 then
		setSampleGain(acoustic_vario, 400)
		setSampleGain(acoustic_vario_descend, 400)
	elseif get(acousticswitch) == 0 then
		setSampleGain(acoustic_vario, 0)
		setSampleGain(acoustic_vario_descend, 0)
end		


--------------- Acoustic variometer sounds
if get(pause) == 1 then stopSample(acoustic_vario_descend) end

if get(acousticswitch) > 0 and get(pause) == 0 and get(climbrate) < 0 then

	    if get(climbrate) < 0 and get(climbrate) >= -50 and loop ~= 1 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 625)
		playSample(acoustic_vario_descend, 1)
		loop = 1
		end
		if get(climbrate) < -50 and get(climbrate) >= -100 and loop ~= 2 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 600)
		playSample(acoustic_vario_descend, 1)
		loop = 2
		end	
		if get(climbrate) < -100 and get(climbrate) >= -150 and loop ~= 3 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 575)
		playSample(acoustic_vario_descend, 1)
		loop = 3
		end	
		if get(climbrate) < -150 and get(climbrate) >= -200 and loop ~= 4 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 550)
		playSample(acoustic_vario_descend, 1)
		loop = 4
		end	
		if get(climbrate) < -200 and get(climbrate) >= -250 and loop ~= 5 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 525)
		playSample(acoustic_vario_descend, 1)
		loop = 5
		end	
		if get(climbrate) < -250 and get(climbrate) >= -300 and loop ~= 6 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 500)
		playSample(acoustic_vario_descend, 1)
		loop = 6
		end	
		if get(climbrate) < -300 and get(climbrate) >= -350 and loop ~= 7 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 475)
		playSample(acoustic_vario_descend, 1)
		loop = 7
		end	
		if get(climbrate) < -350 and get(climbrate) >= -400 and loop ~= 8 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 450)
		playSample(acoustic_vario_descend, 1)
		loop = 8
		end	
		if get(climbrate) < -400 and get(climbrate) >= -450 and loop ~= 9 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 425)
		playSample(acoustic_vario_descend, 1)
		loop = 9
		end	
		if get(climbrate) < -450 and get(climbrate) >= -500 and loop ~= 10 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 400)
		playSample(acoustic_vario_descend, 1)
		loop = 10
		end	
		if get(climbrate) < -500 and get(climbrate) >= -550 and loop ~= 11 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 375)
		playSample(acoustic_vario_descend, 1)
		loop = 11
		end	
		if get(climbrate) < -550 and get(climbrate) >= -600 and loop ~= 12 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 350)
		playSample(acoustic_vario_descend, 1)
		loop = 12
		end	
		if get(climbrate) < -600 and get(climbrate) >= -650 and loop ~= 13 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 325)
		playSample(acoustic_vario_descend, 1)
		loop = 13
		end	
		if get(climbrate) < -650 and loop ~= 14 then 
		stopSample(acoustic_vario_descend)
		setSamplePitch(acoustic_vario_descend, 300)
		playSample(acoustic_vario_descend, 1)
		loop = 14
		end	

end

if get(acousticswitch) > 0 and isSamplePlaying(acoustic_vario) == false and get(pause) == 0 and get(climbrate) >= 0 then
stopSample(acoustic_vario_descend)

	if get(climbrate) >= 0 then 
		setSamplePitch(acoustic_vario, 650)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 50 then 
		setSamplePitch(acoustic_vario, 675)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 100 then 
		setSamplePitch(acoustic_vario, 700)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 150 then 
		setSamplePitch(acoustic_vario, 725)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 200 then 
		setSamplePitch(acoustic_vario, 750)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 250 then 
		setSamplePitch(acoustic_vario, 775)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 300 then 
		setSamplePitch(acoustic_vario, 800)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 350 then 
		setSamplePitch(acoustic_vario, 825)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 400 then 
		setSamplePitch(acoustic_vario, 850)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 450 then 
		setSamplePitch(acoustic_vario, 875)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 500 then 
		setSamplePitch(acoustic_vario, 900)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 550 then 
		setSamplePitch(acoustic_vario, 925)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 600 then 
		setSamplePitch(acoustic_vario, 950)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 650 then 
		setSamplePitch(acoustic_vario, 975)
		playSample(acoustic_vario, 0)
	end
		if get(climbrate) > 700 then 
		setSamplePitch(acoustic_vario, 1000)
		playSample(acoustic_vario, 0)
	end
	
end			
	
end

