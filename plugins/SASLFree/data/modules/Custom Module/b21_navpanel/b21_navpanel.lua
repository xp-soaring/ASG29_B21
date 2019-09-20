-- b21_navpanel.lua

local w = size[1]
local h = size[2]

print("b21_navpanel.lua starting v2.07 ",w,'x',h)

local geo = require "b21_geo" -- contains useful geographic function like distance between lat/longs

-- UNITS datarefs from USER_SETTINGS.lua
local DATAREF_UNITS_VARIO = globalPropertyi("b21/units_vario") -- 0 = knots, 1 = m/s
local DATAREF_UNITS_ALTITUDE = globalPropertyi("b21/units_altitude") -- 0 = feet, 1 = meters
local DATAREF_UNITS_SPEED = globalPropertyi("b21/units_speed") -- 0 = knots, 1 = km/h

-- datarefs READ
local DATAREF_HEADING_DEG = globalPropertyf("sim/flightmodel/position/hpath") -- aircraft ground path
local DATAREF_LATITUDE = globalProperty("sim/flightmodel/position/latitude") -- aircraft latitude
local DATAREF_LONGITUDE = globalProperty("sim/flightmodel/position/longitude") -- aircraft longitude
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec") -- time in seconds
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground
local DATAREF_WIND_DEG = globalPropertyf("sim/weather/wind_direction_degt") -- wind direction (degrees)
local DATAREF_WIND_KTS = globalPropertyf("sim/weather/wind_speed_kt") -- wind speed (knots)
local DATAREF_WEIGHT_TOTAL_KG = globalPropertyf("sim/flightmodel/weight/m_total")
local DATAREF_ALT_FT = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot") -- 3000

-- datarefs for aircraft panel
local DATAREF_MACCREADY_KNOB = createGlobalPropertyi("b21/maccready_knob") -- 1..N = Maccready steps in knots or m/s

--local font = sasl.gl.loadFont( "fonts/UbuntuMono-Regular.ttf" )
local font = sasl.gl.loadFont( "fonts/RubikMonoOne-Regular.ttf" )

-- images
local task_background_img = sasl.gl.loadImage("page_task.png")
local nav_background_img = sasl.gl.loadImage("page_nav.png")
local map_background_img = sasl.gl.loadImage("page_map.png")
local logo_img = sasl.gl.loadImage("navpanel_logo.png")
local nav_wp_pointer = sasl.gl.loadImage("wp_pointer.png")
local nav_wp2_pointer = sasl.gl.loadImage("wp2_pointer.png")
local wind_pointer = sasl.gl.loadImage("wind_pointer.png")

-- Unit conversion factors
M_TO_MI = 0.000621371
KM_TO_MI = 0.621371
FT_TO_M = 0.3048
M_TO_FT = 1.0 / FT_TO_M
DEG_TO_RAD = 0.0174533
KPH_TO_KTS = 1.852
KTS_TO_KPH = 1.0 / KPH_TO_KTS
KTS_TO_MPS = 0.514444
MPS_TO_FPM = 196.85
MPS_TO_KTS = 1.0 / KTS_TO_MPS
MPS_TO_KPH = 3.6
KPH_TO_MPS = 1 / MPS_TO_KPH

-- colors
local red =   { 1.0, 0.0, 0.0, 1.0 }
local green = { 0.0, 1.0, 0.0, 1.0 }
local blue =  { 0.0, 0.0, 1.0, 1.0 }
local black = { 0.0, 0.0, 0.0, 1.0 }
local white = { 1.0, 1.0, 1.0, 1.0 }

-- Pages:
-- 1 : TASK (load task button, display task)
-- 2 : NAV (direction arrow, arrival height)
-- 3 : MAP (lat/long view of task)
local page = 1
local page_count = 3

-- task contains the list [1..N] of waypoints
local task = { }
--[[ e.g { {
             -- loaded from FMS
             type = 1,
             ref = "X1N7",
             alt_m = 375.0, (note METERS),
             point = { lat=40.971146, lng=-74.997475 },
             -- added during FMS load
             length_m = 123456.7, (task leg length in meters)
             -- updated during update():
             distance_m (aircraft distance to waypoint, meters)
             bearing_deg (true bearing to waypoint from aircraft position, degrees)
             heading_deg (relative directional heading to waypoint from aircraft (e.g. +10 deg = starboard))
              ..}
 ]]

local task_length_m = 0.0 -- length of current task in meters

local task_index = 0 -- which task entry is current

local prev_click_time_s = 0.0 -- time button was previously clicked (so only one action per click)

local maccready_whole = "0" -- display value for Maccready 'whole numbers' (e.g "3")
local maccready_decimal = "0" -- display value for Maccready 'decimal' (e.g. "5")
local maccready_knob_prev = 0 -- history of knob value so we can efficiently detect change
local maccready_mps = 0.0 -- meters/second Maccready value used in the calculations

local aircraft_heading_deg = 0.0 -- current aircraft heading degrees true

-- command callbacks from navpanel buttons

local command_load = sasl.createCommand("b21/nav/load_task",
    "Sailplane load flightplan")

local command_left = sasl.createCommand("b21/nav/prev_waypoint",
    "Sailplane select previous waypoint")

local command_right = sasl.createCommand("b21/nav/next_waypoint",
    "Sailplane select next waypoint")

local xplane_load_flightplan = sasl.findCommand("sim/FMS/key_load")

-- delete all waypoints in FMS
function clear_fms()
    print("b21_navpanel","CLEAR")
    local fms_count = sasl.countFMSEntries()
    for i = fms_count - 1, 0, -1
    do
        sasl.clearFMSEntry(i) -- remove last entry (shortens flight plan)
        print("b21_navpanel deleted wp ",i)
    end
    task = {}
    task_index = 0
end

-- load new flightplan
function load_fms()
    print("b21_navpanel","load_fms()")
    clear_fms() -- remove existing waypoints
    sasl.commandOnce(xplane_load_flightplan)
    print("b21_navpanel","load_fms() complete")
end

function prev_wp()
    set_waypoint(task_index - 1)
end

function next_wp()
    set_waypoint(task_index + 1)
end

-- set waypoint to task[i]
function set_waypoint(i)
    if i > 0 and i <= #task
    then
        task_index = i
    end
end

function clicked_load(phase)
    if get(DATAREF_TIME_S) > prev_click_time_s + 2.0 and phase == SASL_COMMAND_BEGIN
    then
        prev_click_time_s = get(DATAREF_TIME_S)
        load_fms()
    end
    return 0
end

function clicked_left(phase)
    if get(DATAREF_TIME_S) > prev_click_time_s + 0.2 and task_index > 1 and phase == SASL_COMMAND_BEGIN
    then
        print("b21_navpanel","LEFT")
        prev_click_time_s = get(DATAREF_TIME_S)
        prev_wp()
    end
    return 1
end

function clicked_right(phase)
    if get(DATAREF_TIME_S) > prev_click_time_s + 0.2 and task_index < #task and phase == SASL_COMMAND_BEGIN
    then
        print("b21_navpanel","RIGHT")
        prev_click_time_s = get(DATAREF_TIME_S)
        next_wp()
    end
    return 1
end

sasl.registerCommandHandler(command_load, 0, clicked_load)
sasl.registerCommandHandler(command_left, 1, clicked_left)
sasl.registerCommandHandler(command_right, 1, clicked_right)

-- *********************************************************
-- ************ update()           *************************
-- *********************************************************

-- update Maccready value from knob rotation 0..15
-- note we update differently for mps / knots so display moves 0.5 units in each units setting.
-- will WRITE globals:
--     maccready_whole
--     maccready_decimal
--     maccready_mps
--     maccready_knob_prev
function update_maccready()
    local knob = get(DATAREF_MACCREADY_KNOB) -- 0..15
    if knob == maccready_knob_prev -- only update if knob position changes
    then
        return
    end
    if get(DATAREF_UNITS_VARIO) == 1 -- UNITS = meters per second
    then
        maccready_mps = knob / 2
        local units = math.floor(maccready_mps)
        maccready_whole = tostring(units)
        maccready_decimal = tostring(math.floor((macready_mps - units)*10+0.5)
    else                              -- UNITS = knots
        -- for Knots knob will move in 0.5 knot increments to 5.0, then 1 Knot increments to 9.99
        local maccready_kts
        if knob < 10.1                          -- i.e. knob = 0..10
        then
            maccready_kts = knob / 2
        elseif knob < 14.1                      -- i.e. knob = 11..14
        then
            maccready_kts = knob - 5
        else                                    -- i.e. knob = 15
            maccready_kts = 9.9 -- MAX display as 9.9
        end
        local whole = math.floor(maccready_kts)
        maccready_whole = tostring(whole)
        maccready_decimal = tostring(math.floor((macready_kts - whole)*10+0.5)
        maccready_mps = maccready_kts * KTS_TO_MPS
    end
    maccready_knob_prev = knob -- record knob position so we detect another change
    print("maccready_mps", maccready_mps, maccready_whole.."."..maccready_decimal) --debug
end

-- update waypoint info:
--  wp.distance_m - aircraft distance to waypoint, meters
--  wp.bearing_deg - true bearing to waypoint from aircraft, degrees
--  wp.heading_deg - relative directional heading to waypoint from aircraft (e.g. +10 deg = starboard)
function update_wp_distance_and_bearing()
    if #task ~= 0
    then
        aircraft_heading_deg = get(DATAREF_HEADING_DEG)

        local aircraft_point = { lat= get(DATAREF_LATITUDE),
                                 lng= get(DATAREF_LONGITUDE)
                            }

        task[task_index].distance_m = geo.get_distance(aircraft_point, task[task_index].point)
        task[task_index].bearing_deg = geo.get_bearing(aircraft_point, task[task_index].point)
        task[task_index].heading_deg = aircraft_heading_deg - task[task_index].bearing_deg

        if task_index < #task
        then
            task[task_index+1].distance_m = geo.get_distance(aircraft_point, task[task_index+1].point)
            task[task_index+1].bearing_deg = geo.get_bearing(aircraft_point, task[task_index+1].point)
            task[task_index+1].heading_deg = aircraft_heading_deg - task[task_index+1].bearing_deg
        end
    end
end

-- use X-Plane probeTerrain function to find ground elevation (meters) at waypoint lat/long
function get_elevation_m(point)
    local wp_x, wp_y, wp_z = sasl.worldToLocal(point.lat, point.lng, 0.0)
    local result, x, y, z, nx, ny, nz, vx, vy, vz, isWet = sasl.probeTerrain(wp_x, wp_y, wp_z)
    if result == PROBE_HIT_TERRAIN
    then
        local wp_lat, wp_lng, wp_elevation_m = localToWorld(x, y, z)
        -- print("b21_navpanel PROBE_HIT_TERRAIN", wp_lat, wp_lng, wp_elevation_m)
        return wp_elevation_m
    else
        print("navpanel PROBE TERRAIN MISS", point.lat, point.lng)
        return 0.0
    end
end

-- detect when FMS has loaded a new flightplan
-- load flightplan into task table
-- accumulate task distance in task_length_m
function update_fms()
    local fms_count = sasl.countFMSEntries()
    if fms_count <= #task
    then
        return
    end

    print("navpanel fms_count",fms_count)

    task = {}

    task_length_m = 0.0 -- we will accumulate total task length

    for i=0, fms_count-1
    do
        -- get next waypoint from X-Plane flight plan
        local fms_type, fms_name, fms_id, fms_altitude_ft, fms_latitude, fms_longitude = sasl.getFMSEntryInfo(i)

        local wp_point = { lat = fms_latitude, lng = fms_longitude }

        -- try lookup ground elevation at the waypoint
        local wp_elevation_m = get_elevation_m(wp_point)
        if wp_elevation_m == 0
        then
            wp_elevation_m = fms_altitude_ft * FT_TO_M
        end

        local leg_length_m = 0.0 -- distance from previous wp

        if i > 0
        then
            -- note first WP in task is task[1] as Lua arrays start from 1
            leg_length_m = geo.get_distance(task[i].point, wp_point)
        end

        task_length_m = task_length_m + leg_length_m

        print("navpanel["..i.."] "..fms_name,
                                 fms_latitude,
                                 fms_longitude,
                                 fms_altitude_ft,
                                 wp_elevation_m * M_TO_FT)
        table.insert(task,{ type = fms_type,
                            ref =  fms_name,
                            alt_m = wp_elevation_m,
                            point = wp_point,
                            length_m = leg_length_m
                        })
    end

    -- will set task_index = 1
    set_waypoint(1)
    update_wp_distance_and_bearing()
end

-- add arrival height to each WP in task
function update_arrival_height(wp_index)
    -- get current waypoint
    local wp = task[wp_index]

    -- READ shared vars set by gpsnav for waypoint altitude, distance and heading
    local theta_radians = math.rad(get(DATAREF_WIND_DEG)) - math.rad(wp.bearing_deg) - math.pi

    local wind_velocity_mps = get(DATAREF_WIND_KTS) * KTS_TO_MPS

    local x_mps = math.cos(theta_radians) * wind_velocity_mps

    local y_mps = math.sin(theta_radians) * wind_velocity_mps

    local vw_mps = math.sqrt(maccready_mps^2 - y_mps^2) + x_mps

    local height_needed_m = wp.distance_m / vw_mps * B21_302_mc_sink_mps

    wp.arrival_height_m = get(DATAREF_ALT_FT) * FT_TO_M - height_needed_m - wp.alt_m

    --print("Wind",dataref_read("WIND_RADIANS"),"radians",dataref_read("WIND_MPS"),"mps") --debug
    --print("B21_302_height_needed_m", B21_302_height_needed_m) --debug
    --print("B21_302_arrival_height_m", B21_302_arrival_height_m) --debug
    -- dataref_write("DEBUG1", math.floor(project_settings.gpsnav_wp_distance_m / 1000))
    -- dataref_write("DEBUG2", math.floor(project_settings.gpsnav_wp_heading_deg))
end

function update_arrival_heights()
    update_arrival_height(task_index)
    if task_index < #task
    then
        update_arrival_height(task_index+1)
    end
end


function update()
    update_wp_distance_and_bearing()
    update_fms()
    update_maccready()
    update_arrival_heights()
end --update

-- ******************************************************
-- ** BUTTON CLICKS *************************************
-- ******************************************************
function button_page_clicked()
    print("b21_navpanel","button PAGE clicked")
    page = page + 1
    if page > page_count
    then
        page = 1
    end
end

function button_load_clicked()
    print("b21_navpanel","button LOAD clicked")
    load_fms()
end

function button_left_clicked()
    print("b21_navpanel","button LEFT clicked")
    prev_wp()
end

function button_right_clicked()
    print("b21_navpanel","button RIGHT clicked")
    next_wp()
end

-- ************************************************************
-- ************ draw()             ****************************
-- ************************************************************
-- h,w defined at startup as size[1],size[2] given to this plugin

-- ---------------------------------------------------------
-- Draw current waypoint at top of panel
-- e.g. "2/5:SUNFISH "
function draw_current_wp()
   local wp_string = task_index .. "/" .. #task .. ":" .. task[task_index].ref

   --  WP STRING                          size isBold isItalic
   sasl.gl.drawText(font,25,h-42, wp_string, 20, true, false, TEXT_ALIGN_LEFT, blue)
end

-- *****************
-- ** TASK PAGE ****
-- *****************

-- Draw text list of waypoints
-- e.g.
-- 1: 1N7
-- 2: SUNFISH
-- 3: SLATGTN
-- 4: WINDGAP
-- 5: 1N7
function draw_task()
    local line_x = 10
    local line_y = h - 75
    local length_x = 100
    local length_y = h-60
    local altitude_x = 150
    local altitude_y = h-60

    local length_units_str = "MI"
    if project_settings.DISTANCE_UNITS == 1 -- (0=mi, 1=km)
    then
        length_units_str = "KM"
    end

    sasl.gl.drawText(font,length_x,length_y, length_units_str, 18, true, false, TEXT_ALIGN_RIGHT, black)

    local altitude_units_str = "FT"
    if project_settings.ALTITUDE_UNITS == 1 -- (0=feet, 1=meters)
    then
        altitude_units_str = "M"
    end
    sasl.gl.drawText(font,altitude_x,altitude_y, altitude_units_str, 18, true, false, TEXT_ALIGN_RIGHT, black)

    for i = 1, #task
    do
        local wp = task[i]

        local length_string
        if project_settings.DISTANCE_UNITS == 0 -- (0=mi, 1=km)
        then
            length_string = (math.floor(wp.length_m * M_TO_MI+0.5))
        else
            length_string = (math.floor(wp.length_m / 1000.0 + 0.5))
        end

        local altitude_string
        if project_settings.ALTITUDE_UNITS == 0 -- (0=feet, 1=meters)
        then
            altitude_string = math.floor(wp.alt_m * M_TO_FT + 0.5)
        else
            altitude_string = math.floor(wp.alt_m + 0.5)
        end

        --  wp.ref                                        size isBold isItalic
        sasl.gl.drawText(font,line_x,line_y, wp.ref, 14, true, false, TEXT_ALIGN_LEFT, black)

        -- leg length mi/km
        sasl.gl.drawText(font,length_x,line_y, length_string, 18, true, false, TEXT_ALIGN_RIGHT, black)

        -- wp altitude ft/m
        sasl.gl.drawText(font,altitude_x,line_y, altitude_string, 18, true, false, TEXT_ALIGN_RIGHT, black)

        line_y = line_y - 20
    end

    local task_length_string
    if project_settings.DISTANCE_UNITS == 0 -- (0=mi, 1=km)
    then
        task_length_string = (math.floor(task_length_m * M_TO_MI * 10.0) / 10.0) .. " MI"
    else
        task_length_string = (math.floor(task_length_m / 100.0) / 10.0) .. " KM"
    end

    task_length_string = "TOTAL: "..task_length_string

    --  TASK LENGTH STRING                                 size isBold isItalic
    sasl.gl.drawText(font,line_x,line_y, task_length_string, 20, true, false, TEXT_ALIGN_LEFT, black)

end

-- if no task is loaded, put message on task page
function draw_no_task()
    local msg_string = "LOAD TASK"
    sasl.gl.drawText(font,20,h-60, msg_string, 24, true, false, TEXT_ALIGN_LEFT, red)
    sasl.gl.drawTexture(logo_img, 20, h-190, 115, 112, {1.0,1.0,1.0,1.0}) -- draw logo
end

-- top-level TASK page draw function
function draw_page_task()
    -- logInfo("navpanel draw called")
    sasl.gl.drawTexture(task_background_img, 0, 0, w, h, {1.0,1.0,1.0,1.0}) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    if #task == 0
    then
        draw_no_task()
        return
    end

    draw_current_wp()

    draw_task()
end

-- ***************************************************
-- ** NAV PAGE ***************************************
-- ***************************************************

-- draw distance to current and next waypoints on page
function draw_distance_to_go()
    local distance_units_str = "MI"
    if project_settings.DISTANCE_UNITS == 1 -- 0 = MI, 1 = KM
    then
        distance_units_str = "KM"
    end
    -- draw distance units i.e. "MI" or "KM"
    sasl.gl.drawText(font,135,104, distance_units_str, 12, true, false, TEXT_ALIGN_LEFT, black)

    local dist = task[task_index].distance_m / 1000 -- initially in KM
    if project_settings.DISTANCE_UNITS == 0 -- 0 = MI, 1 = KM
    then
        dist = dist * KM_TO_MI
    end
    -- build the actual distance number string "123" or "6.7"
    local dist_str = tostring(math.floor(dist))
    if dist < 10
    then
        dist_str = tostring(math.floor(dist * 10)/10)
    end
    -- draw distance value e.g. "123" or "6.7"
    sasl.gl.drawText(font,135,80, dist_str, 20, true, false, TEXT_ALIGN_RIGHT, black)

    -- debug still need to do distance to second waypoint
end

function draw_arrival_height()
    local altitude_units_str = "FT"
    if project_settings.ALTITUDE_UNITS == 1 -- 0 = FT, 1 = M
    then
        altitude_units_str = "M"
    end
    -- draw distance units i.e. "FT" or "M"
    sasl.gl.drawText(font,135,70, altitude_units_str, 12, true, false, TEXT_ALIGN_LEFT, black)

    local arrival_height = task[task_index].arrival_height_m -- meters
    if project_settings.DISTANCE_UNITS == 0 -- 0 = FT, 1 = M
    then
        arrival_height = arrival_height * M_TO_FT
    end
    -- build the actual arrival height number string "123" or "6.7"
    local arrival_height_str = tostring(math.floor(arrival_height))
    if arrival_height < 0
    then
        arrival_height_str = "-"..arrival_height_str
    -- draw arrival_height value e.g. "123"
    sasl.gl.drawText(font,135,55, arrival_height_str, 20, true, false, TEXT_ALIGN_RIGHT, black)

end

-- write wind speed in circle graphic and add pointer to circle
function draw_wind()

    local wind_speed = get(DATAREF_WIND_KTS)
    -- convert to km/h if necessary
    if get(DATAREF_UNITS_SPEED) == 1 -- km/h
    then
        wind_speed = wind_speed * KTS_TO_KPH
    end

    -- remove decimals and convert to string
    local wind_string = tostring(math.floor(wind_speed))

    -- write numeric wind speed (knots or km/h) in circle
    sasl.gl.drawText(font,64,110, wind_str, 12, true, false, TEXT_ALIGN_LEFT, black)

    --
    -- now position pointer on wind circle graphic
    --
    local wind_heading_deg = aircraft_heading_deg - get(DATAREF_WIND_DEG)
    local wind_heading_rad = math.rad(wind_heading_deg)

    -- coordinates for wind circle graphic on NAV page
    local center_x = 77
    local center_y = 118
    local radius = 25
    local px = center_x + math.sin(wind_heading_rad) * radius
    local py = center_y + math.cos(wind_heading_rad) * radius
    -- We offset px,py by half the width and the whole height of the pointer, to align point to px,py
    -- and then we rotate around the point.
    -- sasl.gl.drawRotatedTextureCenter(d, angle, rx, ry, x, y, width, height, color )
    sasl.gl.drawRotatedTextureCenter(wind_pointer, wind_heading_deg, 8, 8, px-8, py-8, 15, 8, {1.0,1.0,1.0,1.0})

end

function draw_maccready()
    sasl.gl.drawText(font,12,63, maccready_whole..".", 20, true, false, TEXT_ALIGN_LEFT, black)
    sasl.gl.drawText(font,41,77, maccready_decimal, 12, true, false, TEXT_ALIGN_LEFT, black)
end

-- convert the relative heading of waypoint into px,py on oval graphic
function heading_to_xy(heading_deg)
    -- x,y coords of center of oval graphic
    local center_x = 78
    local center_y = 133
    local radius = 50
    local px
    local py

    local a = math.rad(heading_deg)

    if a > math.pi / 2 and a < 3 * math.pi / 2
    then
        if a < math.pi
        then
            px = 0.75 + math.sin(a)*0.25
        else
            px = -0.75 + math.sin(a)*0.25
        end
        py = math.cos(a)*0.25
    else
        px = math.sin(a)
        py = math.cos(a)*0.5
    end

    --debug this doesn't match the oval properly
    return center_x + radius * px, center_y + radius * py
end

-- draw the pointers for waypoint bearings on the oval graphic
function draw_nav_headings()

    local heading_deg = task[task_index].heading_deg
    -- x,y coords for bearing to current wp
    local px, py = heading_to_xy(heading_deg)

    -- Draw pointer to current waypoint, rotated about point at top center of pointer.
    -- We offset px,py by half the width and the whole height of the pointer, to align point to px,py
    -- and then we rotate around the point.
    -- sasl.gl.drawRotatedTextureCenter(d, angle, rx, ry, x, y, width, height, color )
    sasl.gl.drawRotatedTextureCenter(nav_wp_pointer, heading_deg, 8, 16, px-8, py-16, 15,16, {1.0,1.0,1.0,1.0})

    -- draw pointer to second waypoint if available
    if task_index < #task
    then
        heading_deg = task[task_index+1].heading_deg
        px, py = heading_to_xy(heading_deg)
        -- draw pointer to next waypoint
        sasl.gl.drawRotatedTextureCenter(nav_wp2_pointer, heading_deg, 8, 8, px-8, py-8, 15, 8, {1.0,1.0,1.0,1.0})
    end
end

-- top-level NAV page draw function
function draw_page_nav()
    -- logInfo("navpanel draw called")
    sasl.gl.drawTexture(nav_background_img, 0, 0, w, h, {1.0,1.0,1.0,1.0}) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    -- "1/5: 1N7"
    local top_string
    if #task == 0
    then
        top_string = "LOAD TASK"
        sasl.gl.drawText(font,35,h-40, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)
        return
    end

    draw_current_wp()

    draw_nav_headings()

    draw_maccready()

    draw_wind()
end

-- *****************
-- ** MAP PAGE *****
-- *****************

-- top-level MAP page draw function
function draw_page_map()
    -- logInfo("navpanel draw called")
    sasl.gl.drawTexture(map_background_img, 0, 0, w, h, {1.0,1.0,1.0,1.0}) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    -- "1/5: 1N7"
    local top_string
    if #task == 0
    then
        top_string = "LOAD TASK"
        sasl.gl.drawText(font,5,h-50, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)
        return
    end

    top_string = "MAP "..task_index .. "/" .. #task .. ":" .. task[task_index].ref

    local mid_string = "This is the Map page"

    local bottom_string = "-*-*-*-"

    --  TOP STRING                         size isBold isItalic
    sasl.gl.drawText(font,5,h-30, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)

    -- MIDDLE STRING
    sasl.gl.drawText(font,5,h-75, mid_string, 18, true, false, TEXT_ALIGN_LEFT, black)

    -- BOTTOM STRING
    sasl.gl.drawText(font,5,55, bottom_string, 18, true, false, TEXT_ALIGN_LEFT, black)

end

callback = {}
callback["page"] = button_page_clicked
callback["load"] = button_load_clicked
callback["wp_prev"] = button_left_clicked
callback["wp_next"] = button_right_clicked

function draw()
    if page == 1
    then
        draw_page_task()
    elseif page == 2
    then
        draw_page_nav()
    else
        draw_page_map()
    end
    drawAll(components)
end

components = {
    panel_button { id="page", position = { 6, 189, 34, 18} },
    panel_button { id="load", position = { 42, 189, 34, 18} },
    panel_button { id="wp_prev", position = { 79, 189, 34, 18} },
    panel_button { id="wp_next", position = { 116, 189, 34, 18} }
}
