local initialisation = 0

function properties_init() 
if initialisation ~= 1 then
createProp("sim/auriel/te_vario", "int",0); -- this is where we will feed the processed vario signal to
createProp("sim/auriel/acoustic_switch", "int",0); -- this dataref will be used for a rheostat that turns the audio vario off (0), and sets the volume (1-4)
createProp("sim/auriel/vario_samplerate", "int",0); -- this dataref is later used for the switch that changes the "sample rate" (aka sensitivity) of the raw signal in te_variometer.lua

initialisation = 1

end
end

properties_init()

components = {
te_variometer{},
sounds{},
} 