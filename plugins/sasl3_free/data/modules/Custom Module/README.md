# B21 Soaring Instruments

These instruments have all have both the plugin script in this folder, and also
"<aircraft>/cockpit/generic/..." directories containing the instrument images.

Note that the gpsnav is partially implemented as x-plane
generic instrument components on the panel (e.g. the buttons) but the writing onto
its display is done with SASL code in the plugin here "b21_gpsnav"). This means the
'position' information for the gpsnav in main.lua MUST line up with the placement of
the underlying image on the panel.

## Installation

1. Some of these instruments rely upon USER_SETTINGS.lua in the *aircraft base folder*, e.g.
"<X-Plane>/Aircraft/Extra Aircraft/ASK21_B21"

2. The file B21_POLAR.lua contains the 'glider polar' i.e. its sink rate at various speeds. The
data is used to calibrate the various variometers. In the file you'll see hints to help
with the required settings.

3. Comments at the top of each b21_XXXX.lua file explain which X-Plane DataRefs are read, and 
which custom ones are written to - it is these custom DataRefs that are used to control
animations on the cockpit panel. 

4. In general a custom dataref will be written to control each
element (e.g. b21/vario_winter/needle_fpm), rather than link things like variometer needles
directly to actual in-flight variables (like b21/total_energy_fpm). This enables things like
needle smoothing to be implemented without messing with the underlying TE calculation.
