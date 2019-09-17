-- B21

--sasl.options.setAircraftPanelRendering(true)
--sasl.options.setInteractivity(true)
--sasl.options.set3DRendering(false)
--sasl.options.setRenderingMode2D(SASL_RENDER_2D_DEFAULT)
--sasl.options.setPanelRenderingMode(SASL_RENDER_PANEL_DEFAULT)
--panel2d = true

panel2d = false

size = { 2048, 2048 }

project_settings = { } -- Project Globals, i.e. plugin data values shared between modules

-- INCLUDE USER SETTINGS (e.g. vario sound volume) IN AIRCRAFT ROOT FOLDER
-- i.e. <X-Plane Install Folder>/Aircraft/<something>/ASK21_B21
include(sasl.getAircraftPath().."/USER_SETTINGS.lua") -- adds values to project_settings

-- INCLUDE GLIDER POLAR (from 'Custom Modules'/B21_POLAR.lua)
include("B21_POLAR.lua") -- adds values to project_settings

-- put units values into DataRefs so they can be read by gauges
createGlobalPropertyi("b21/units_vario",project_settings.VARIO_UNITS,false,true,true)
createGlobalPropertyi("b21/units_speed",project_settings.SPEED_UNITS,false,true,true)
createGlobalPropertyi("b21/units_altitude",project_settings.ALTITUDE_UNITS,false,true,true)
createGlobalPropertyi("b21/units_distance",project_settings.DISTANCE_UNITS,false,true,true)

-- create debug datarefs to be used by any module
createGlobalPropertyf("b21/debug/1",0.1,false,true,false)
createGlobalPropertyf("b21/debug/2",0.1,false,true,false)
createGlobalPropertyf("b21/debug/3",0.1,false,true,false)

components = {
                b21_wings_level {}, -- load before b21_controls_commands
                b21_total_energy {}, -- load before variometers
                b21_sounds {}, -- load before variometers
                b21_vario_302 {},
                b21_vario_57 {},
                b21_airbrakes {},
                popupCloseButton {
                    position = { 360, 850, 40, 25 },
                    --cursor = {x = 0, y = 0, width = 16, height = 16, shape = loadImage("interactive.png")},
                    --onMouseDown = function() print("HELLO") return true end,
                    --onMouseUp = function() print("HELLO END") return true end,
                },
	            b21_panel { -- digital nav panel
                    position = { 360, 620, 135, 220},
                    cursor = {
					    x = -8,
					    y = -8,
					    width = 16,
					    height = 16,
					    shape = sasl.gl.loadImage ("interactive.png"),
					    hideOSCursor = true
                    },
                    onMouseDown = function() print("MOUSE DOWN") return true end
                },
                b21_clock {}, -- moves hands of watch on panel
                b21_trim {}, -- provides trigger trim command and gradual movement of trim
                b21_altimeter {}, -- moves needles of altimeter, supports imperial/metric units
                b21_yawstring {}, -- moves yawstring
                b21_ballast {}, -- provides ballast % indicator and "b21/ballast/[open,close,fill]"
                b21_controls_commands {}
             }

function draw()
    drawAll(components)
end

function update()
    updateAll(components)
end
