-- B21

-- #################################################
-- Vario sound controlled by this DataRef:
local vario_sound_fpm = createGlobalPropertyf("b21/vario_sound_fpm", 0.0, false, true, true)
-- #################################################

local QUIET_CLIMB = project_settings.QUIET_CLIMB
local QUIET_SINK = project_settings.QUIET_SINK
local prev_volume = project_settings.VARIO_VOLUME
local prev_mode = 0 -- sound mode 0 .. 1 (used for alternate sounds, TE=0, STF=1)

local sound_spoilers_unlock = loadSample(sasl.getAircraftPath()..'/sounds/systems/BrakesOut.wav')
local sound_spoilers_lock = loadSample(sasl.getAircraftPath()..'/sounds/systems/BrakesIn.wav')
local sound_spoilers_deployed = loadSample(sasl.getAircraftPath()..'/sounds/systems/spoilers.wav')

local sounds = { climb = loadSample(sasl.getAircraftPath()..'/sounds/systems/vario_climb.wav'),
                 sink = loadSample(sasl.getAircraftPath()..'/sounds/systems/vario_sink.wav'),
                 stf_climb = loadSample(sasl.getAircraftPath()..'/sounds/systems/stf_climb.wav'),
				 stf_sink = loadSample(sasl.getAircraftPath()..'/sounds/systems/stf_sink.wav')
               }

local dataref_spoiler_ratio = globalPropertyf("sim/cockpit2/controls/speedbrake_ratio") -- get value of spoiler lever setting
local dataref_airspeed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")
local DEBUG1 = globalPropertyf("b21/debug/1")
local DEBUG2 = globalPropertyf("b21/debug/2")
local DEBUG3 = globalPropertyf("b21/debug/3")

pause = globalPropertyf("sim/time/paused") -- check if sim is paused
DATAREF_VOLUME = createGlobalPropertyi("b21/vario_sound_volume", project_settings.VARIO_VOLUME, false, true, false) -- dataref for the "off/volume" switch
DATAREF_MODE = createGlobalPropertyi("b21/vario_sound_mode", 0, false, true, false) -- dataref for the sound mode 0..1 (TE/STF)

local spoilers_deployed = 0 -- flag to ensure spoiler sounds played once on open/close

setSampleGain(sound_spoilers_lock, 500)
setSampleGain(sound_spoilers_unlock, 500)
setSampleGain(sound_spoilers_deployed, 0)

setSampleGain(sounds.climb, project_settings.VARIO_VOLUME)
setSampleGain(sounds.sink, project_settings.VARIO_VOLUME)
setSampleGain(sounds.stf_climb, project_settings.VARIO_VOLUME)
setSampleGain(sounds.stf_sink, project_settings.VARIO_VOLUME)

setSampleEnv(sounds.climb, SOUND_INTERNAL)
setSampleEnv(sounds.sink, SOUND_INTERNAL)
setSampleEnv(sounds.stf_climb, SOUND_INTERNAL)
setSampleEnv(sounds.stf_sink, SOUND_INTERNAL)

local current_climb = sounds.climb
local current_sink = sounds.sink -- start off with sounds in TE mode, will update quickly if not

--playSample(sound_spoilers_unlock)

function update_spoilers()
    local spoiler_ratio = get(dataref_spoiler_ratio)
    -- spoiler sound volume due to airspeed
    local spoiler_volume_speed = (get(dataref_airspeed_mps) - 20) / 20
    if spoiler_volume_speed < 0
    then
        spoiler_volume_speed = 0
    elseif spoiler_volume_speed > 1
    then
        spoiler_volume_speed = 1
    end
    -- spoiler noise volume do to extension of spoilers
    local spoiler_volume_extent = spoiler_ratio * 0.75
    if spoiler_volume_extent > 0.06
    then
        spoiler_volume_extent = spoiler_volume_extent + 0.25
    end

    local spoiler_volume = spoiler_volume_speed * spoiler_volume_extent * 500

    setSampleGain(sound_spoilers_deployed, spoiler_volume)

    set(DEBUG1, spoiler_volume_speed)
    set(DEBUG2, spoiler_volume_extent)
    set(DEBUG3, spoiler_volume)

	-------------- generate airbrake lock / unlock sounds
	if get(dataref_spoiler_ratio) > 0.03 and spoilers_deployed == 0 
	then 
        playSample(sound_spoilers_unlock, false)
        playSample(sound_spoilers_deployed, true)
        spoilers_deployed = 1
        return
	end

	if get(dataref_spoiler_ratio) < 0.03 and spoilers_deployed == 1 
	then
        playSample(sound_spoilers_lock, false)
        stopSample(sound_spoilers_deployed)
		spoilers_deployed = 0
	end
end

-- if either climb or sink sounds are playing, stop them
function stop_sounds()
	if isSamplePlaying(sounds.climb)
	then
		stopSample(sounds.climb) 
	end
	if isSamplePlaying(sounds.sink)
	then
		stopSample(sounds.sink) 
    end	
    if isSamplePlaying(sounds.stf_climb)
	then
		stopSample(sounds.stf_climb) 
	end
	if isSamplePlaying(sounds.stf_sink)
	then
		stopSample(sounds.stf_sink) 
	end
end

function update_volume()
	local new_volume = get(DATAREF_VOLUME)

	if new_volume ~= prev_volume
	then
        if new_volume == 0
        then
            stop_sounds()
        else
		    setSampleGain(sounds.climb, new_volume)
            setSampleGain(sounds.sink, new_volume)
		    setSampleGain(sounds.stf_climb, new_volume)
            setSampleGain(sounds.stf_sink, new_volume)
        end
        prev_volume = new_volume
	end
end --update_volume()

-- adjust which wav file is playing at what pitch
function update_vario()
    local vario_climbrate = get(vario_sound_fpm)
    local mode = get(DATAREF_MODE)
    local pitch -- pitch rate required by setSamplePitch (1000 = normal)

	-- if paused then kill sound and return
	if (get(pause) == 1) or (prev_volume == 0)
	then
		stop_sounds()
		return
	end

    -- if mode has changed 0..1 or 1..0 then update current sounds
    if mode ~= prev_mode
    then
        prev_mode = mode

        stop_sounds()

        if mode == 0
        then
            current_climb = sounds.climb
            current_sink = sounds.sink
        else
            current_climb = sounds.stf_climb
            current_sink = sounds.stf_sink
        end

    end

	-- if the climbrate is above the dead band, play sounds.climb

    if vario_climbrate > QUIET_CLIMB
    then
        if isSamplePlaying(current_sink)
        then
            stopSample(current_sink)
        end
        -- play climb sound
        pitch = math.floor(vario_climbrate / 2.0) + 650.0
        setSamplePitch(current_climb, pitch)
        if not isSamplePlaying(current_climb)
        then
            playSample(current_climb, true) -- looping
        end
        return
    elseif vario_climbrate < QUIET_SINK
	then
        if isSamplePlaying(current_climb)
        then
            stopSample(current_climb)
        end
        -- play sink sound
        pitch = math.floor( -39000.0 / vario_climbrate + 235.0 )
        setSamplePitch(current_sink, pitch)
        if not isSamplePlaying(current_sink)
        then
            playSample(current_sink, true) -- looping
        end
        return
    else
        -- otherwise, in quiet band, stop both sounds
        if isSamplePlaying(current_climb)
        then
            stopSample(current_climb)
        end
        if isSamplePlaying(current_sink)
        then
            stopSample(current_sink)
        end
    end
end -- update_vario()

-- The main UPDATE function
function update()
	update_spoilers()
	update_volume()
	update_vario()
end --update()

