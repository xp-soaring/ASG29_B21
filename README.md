# ASG29_B21

## Credits
* Windsock team for original 3D model (2007)
* rhb migrating the model forward through X-Plane 8,9,10 & 11

## Modification list

* DONE move flap position indicator texture
* DONE graduate/darken texture for leg area cockpit
* DONE make darker background texture for panel
* DONE change canopy open from dihedral hack to sim/flightmodel2/misc/canopy_open_ratio
* speed up canopy open/close
* add sound to canopy open/close
* DONE add flap indicator to panel
* DONE calibrate current flight performance
* create aileron/flap move plugin to support flaperons, update .obj to these datarefs
* create flightmodel best l/d polar (flap 4)
* create flightmodel accurate for all flap settings
* create flightmodel accurate for all ballast settings
* add instruments to panel
* make yawstring more realistic
* add gear up/down indicator or warning
* add airbrake open + gear up warning
* DONE fix canopy visibility in 11.36
* add tow release handle
* DONE quieter wind noise
* correct spoilers L/D
* DONE correct pitch change on flaps deployment
* weaken wheelbrake effectiveness
* DONE adjust pilot view
* slight increase to flap Cl
* DONE improve aileron effectiveness
* DONE remove 'dihedral' handle hack patches used for canopy open/close
* add canopy toggle command to under-panel button (for close)
* DONE add ballast indicator and open/close/fill commands
* DONE update polar calibration data for ASG29
* have netto include ballast
* have gpsnav calculations include ballast
* DONE add particle emitter for water ballast
* check netto, STF correct for zero/max ballast
* check flap, spoiler, ground run, wheel down wind sounds
* check aileron authority
* check rudder authority
* check canopy open/close sounds (birdsong?)
* add 'Flaps' label to indicator on panel
* tidy up bezel highlight/shadow for ballast gauge
* check Win CE tablet in cockpit properly disabled
* add pilot model for external view
* DONE create navpanel TASK page
* DONE create navpanel NAV page
* DEFERRED create navpanel MAP page
* DONE create navpanel CHECKLIST page
* remove arrival height / stf from vario_302 (make vario_301)
* DONE create electronic ASI with STF bug
* fix negative alpha, negative G (inverted loop) instability
* correct yaw stability
* correct pitch stability
* adjust ailerons for correct roll rate
* change ailerons to plugin control to animate droop with flaps
* adjust Center of Mass and place ballast slightly forward
* adjust trim max-min effect
* add NO LANDING warning to ballast checklist
* add GEAR UP warning to flaps_indicator
* add GEAR DOWN warning to flaps_indicator
* add DUMP BALLAST warning to flaps_indicator
* tune elevator movement speed
* set time for gear up/down animations
* confirm STF adjustment should use netto or te
