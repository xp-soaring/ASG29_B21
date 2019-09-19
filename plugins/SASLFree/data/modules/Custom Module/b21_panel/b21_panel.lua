-- b21_panel.lua

local w = size[1]
local h = size[2]

print("b21_panel.lua starting v2.06 ",w,'x',h)

-- WRITES these shared variables:
--
-- project_settings.gpsnav_wp_distance_m
-- project_settings.gpsnav_wp_heading_deg
-- project_settings.gpsnav_wp_altitude_m
--

-- size = { 100, 89 }

local geo = require "b21_geo" -- contains useful geographic function like distance between lat/longs

-- datarefs READ
local dataref_heading_deg = globalPropertyf("sim/flightmodel/position/hpath") -- aircraft ground path
local dataref_latitude = globalProperty("sim/flightmodel/position/latitude") -- aircraft latitude
local dataref_longitude = globalProperty("sim/flightmodel/position/longitude") -- aircraft longitude
local dataref_time_s = globalPropertyf("sim/network/misc/network_time_sec") -- time in seconds
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground

local font = sasl.gl.loadFont ( "fonts/UbuntuMono-Regular.ttf" )

local task_background_img = sasl.gl.loadImage("panel_task.png")
local nav_background_img = sasl.gl.loadImage("panel_nav.png")
local map_background_img = sasl.gl.loadImage("panel_map.png")

M_TO_MI = 0.000621371
FT_TO_M = 0.3048
M_TO_FT = 1.0 / FT_TO_M
DEG_TO_RAD = 0.0174533

local red =   { 1.0, 0.0, 0.0, 1.0 }
local green = { 0.0, 1.0, 0.0, 1.0 }
local blue =  { 0.0, 0.0, 1.0, 1.0 }
local black = { 0.0, 0.0, 0.0, 1.0 }
local white = { 1.0, 1.0, 1.0, 1.0 }

local bearing_index = 3

-- Pages:
-- 1 : TASK (load task button, display task)
-- 2 : NAV (direction arrow, arrival height)
-- 3 : MAP (lat/long view of task)
local page = 1
local page_count = 3

-- e.g { { type = 1, ref = "X1N7", alt_m = 375.0 (note METERS), lat = 40.971146, lng = -74.997475 }, ..}
local task = { }

local task_length_m = 0.0 -- length of current task in meters

local task_index = 0 -- which task entry is current

local wp_point = { } -- { lat, lng } of current wp

local prev_click_time_s = 0.0 -- time button was previously clicked (so only one action per click)

-- gpsnav vars shared with other instruments (e.g. 302 vario)
project_settings.gpsnav_wp_distance_m = 0.0 -- distance to next waypoint in meters

project_settings.gpsnav_wp_heading_deg = 0.0 -- heading (true) to next waypoint in degrees

project_settings.gpsnav_wp_altitude_m = 0.0 -- altitude MSL of next waypoint in meters

-- command callbacks from gpsnav buttons

local command_load = sasl.createCommand("b21/nav/load_task",
    "Sailplane GPSNAV load flightplan")

local command_left = sasl.createCommand("b21/nav/prev_waypoint",
    "Sailplane GPSNAV left-button function (e.g. prev waypoint)")

local command_right = sasl.createCommand("b21/nav/next_waypoint",
    "Sailplane GPSNAV right-button function (e.g. next waypoint)")

local xplane_load_flightplan = sasl.findCommand("sim/FMS/key_load")

-- delete all waypoints in FMS
function clear_fms()
    print("b21_panel","GPSNAV CLEAR")
    local fms_count = sasl.countFMSEntries()
    for i = fms_count - 1, 0, -1
    do
        sasl.clearFMSEntry(i) -- remove last entry (shortens flight plan)
        print("GPSNAV deleted wp ",i)
    end
    task = {}
    task_index = 0
end

-- load new flightplan
function load_fms()
    print("b21_panel","load_fms()")
    clear_fms() -- remove existing waypoints
    sasl.commandOnce(xplane_load_flightplan)
end

function prev_wp()
    set_waypoint(task_index - 1)
end

function next_wp()
    set_waypoint(task_index + 1)
end

-- set waypoint to task[i]
function set_waypoint(i)
-- e.g  { type = 1, ref = "X1N7", alt_m = 375.0 (METERS), lat = 40.971146, lng = -74.997475 }
    if i > 0 and i <= #task
    then
        task_index = i
        wp_point = task[task_index].point
        project_settings.gpsnav_wp_altitude_m = task[task_index].alt_m -- altitude MSL of next waypoint in meters
    end
end

function clicked_load(phase)
    if get(dataref_time_s) > prev_click_time_s + 2.0 and phase == SASL_COMMAND_BEGIN
    then
        prev_click_time_s = get(dataref_time_s)
        load_fms()
    end
    return 0
end

function clicked_left(phase)
    if get(dataref_time_s) > prev_click_time_s + 0.2 and task_index > 1 and phase == SASL_COMMAND_BEGIN
    then
        print("b21_panel","GPSNAV LEFT")
        prev_click_time_s = get(dataref_time_s)
        prev_wp()
    end
    return 1
end

function clicked_right(phase)
    if get(dataref_time_s) > prev_click_time_s + 0.2 and task_index < #task and phase == SASL_COMMAND_BEGIN
    then
        print("b21_panel","GPSNAV RIGHT")
        prev_click_time_s = get(dataref_time_s)
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

-- calculate index into bearing PNG panel image to display correct turn indication
function update_bearing_index()
    if get(DATAREF_ONGROUND) == 1
    then
        bearing_index = 3 -- center
        return
    end
    local heading_delta_deg = get(dataref_heading_deg) - project_settings.gpsnav_wp_heading_deg
    local left_deg
    local right_deg
    if heading_delta_deg > 0
    then
        left_deg = heading_delta_deg
        right_deg = 360 - heading_delta_deg
    else
        left_deg = heading_delta_deg + 360
        right_deg = -heading_delta_deg
    end
    local turn_deg
    if left_deg < right_deg
    then
        turn_deg = -left_deg
    else
        turn_deg = right_deg
    end
    if turn_deg > 70 then bearing_index = 6
    elseif turn_deg > 40 then bearing_index = 5
    elseif turn_deg > 10 then bearing_index = 4
    elseif turn_deg > -10 then bearing_index = 3 -- center
    elseif turn_deg > -40 then bearing_index = 2
    elseif turn_deg > -70 then bearing_index = 1
    else bearing_index = 0
    end
end --calculate_bearing_index

-- update the shared variables for wp bearing and distance
function update_wp_distance_and_heading()
    if #task ~= 0
    then
        local aircraft_point = { lat= get(dataref_latitude),
                                lng= get(dataref_longitude)
                            }

        project_settings.gpsnav_wp_distance_m = geo.get_distance(aircraft_point, wp_point)

        project_settings.gpsnav_wp_heading_deg = geo.get_bearing(aircraft_point, wp_point)
    end
end

-- use X-Plane probeTerrain function to find ground elevation (meters) at waypoint lat/long
function get_elevation_m(point)
    local wp_x, wp_y, wp_z = sasl.worldToLocal(point.lat, point.lng, 0.0)
    local result, x, y, z, nx, ny, nz, vx, vy, vz, isWet = sasl.probeTerrain(wp_x, wp_y, wp_z)
    if result == PROBE_HIT_TERRAIN
    then
        local wp_lat, wp_lng, wp_elevation_m = localToWorld(x, y, z)
        -- print("gpsnav PROBE_HIT_TERRAIN", wp_lat, wp_lng, wp_elevation_m)
        return wp_elevation_m
    else
        print("gpsnav PROBE TERRAIN MISS", point.lat, point.lng)
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

    print("gpsnav fms_count",fms_count)

    task = {}

    task_length_m = 0.0 -- we will accumulate total task length

    for i=0, fms_count-1
    do
        -- get next waypoint from X-Plane flight plan
        local fms_type, fms_name, fms_id, fms_altitude_ft, fms_latitude, fms_longitude = sasl.getFMSEntryInfo(i)

        local wp_point = { fms_latitude, fms_longitude }

        -- try lookup ground elevation at the waypoint
        local wp_elevation_m = get_elevation_m(wp_point)
        if wp_elevation_m == 0
        then
            wp_elevation_m = fms_altitude_ft * FT_TO_M
        end

        local wp_distance_m = 0.0 -- distance from previous wp

        if i > 0
        then
            -- note first WP in task is task[1] as Lua arrays start from 1
            wp_distance_m = geo.get_distance(task[i].point, wp_point)
        end

        task_length_m = task_length_m + wp_distance_m

        print("GPSNAV["..i.."] "..fms_name,
                                 fms_latitude,
                                 fms_longitude,
                                 fms_altitude_ft,
                                 wp_elevation_m * M_TO_FT)
        table.insert(task,{ type = fms_type,
                            ref =  fms_name,
                            alt_m = wp_elevation_m,
                            point = wp_point,
                            dist_m = wp_distance_m
                        })
    end

    -- will set task_index = 1
    set_waypoint(1)
end

function update()
    update_wp_distance_and_heading()
    update_bearing_index()
    update_fms()
end --update

-- ******************************************************
-- ** BUTTON CLICKS *************************************
-- ******************************************************
function button_page_clicked()
    print("b21_panel","button PAGE clicked")
    page = page + 1
    if page > page_count
    then
        page = 1
    end
end

function button_load_clicked()
    print("b21_panel","button LOAD clicked")
    load_fms()
end

function button_left_clicked()
    print("b21_panel","button LEFT clicked")
    prev_wp()
end

function button_right_clicked()
    print("b21_panel","button RIGHT clicked")
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
   sasl.gl.drawText(font,5,h-50, wp_string, 20, true, false, TEXT_ALIGN_LEFT, blue)
end

-- Draw text list of waypoints
-- e.g.
-- 1: 1N7
-- 2: SUNFISH
-- 3: SLATGTN
-- 4: WINDGAP
-- 5: 1N7
function draw_task()
    local line_x = 10
    local line_y = h - 90

    for i = 1, #task
    do
        local wp = task[i]

        -- "DIST: 37.5km"
        local distance_string
        if project_settings.DISTANCE_UNITS == 0 -- (0=mi, 1=km)
        then
            distance_string = (math.floor(wp.dist_m * M_TO_MI * 10.0) / 10.0) .. " MI"
        else
            distance_string = (math.floor(wp.dist_m / 100.0) / 10.0) .. " KM"
        end

        local altitude_string
        if project_settings.ALTITUDE_UNITS == 0 -- (0=feet, 1=meters)
        then
            altitude_string = math.floor(wp.alt_m * M_TO_FT) .. " FT"
        else
            altitude_string = math.floor(wp.alt_m) .. " M"
        end

        local wp_string = i..":" .. wp.ref.." "..distance_string.." "..altitude_string

        --  WP STRING                          size isBold isItalic
        sasl.gl.drawText(font,line_x,line_y, wp_string, 20, true, false, TEXT_ALIGN_LEFT, black)
        line_y = line_y - 30
    end

    local task_length_string
    if project_settings.DISTANCE_UNITS == 0 -- (0=mi, 1=km)
    then
        task_length_string = (math.floor(task_length_m * M_TO_MI * 10.0) / 10.0) .. " MI"
    else
        task_length_string = (math.floor(task_length_m / 100.0) / 10.0) .. " KM"
    end

    task_length_string = "TOTAL: "+task_length_string

    --  TASK LENGTH STRING                                 size isBold isItalic
    sasl.gl.drawText(font,line_x,line_y, task_length_string, 20, true, false, TEXT_ALIGN_LEFT, black)

end

-- if no task is loaded, put message on task page
function draw_no_task()
    local top_string = " LOAD TASK"
    sasl.gl.drawText(font,5,h-80, top_string, 24, true, false, TEXT_ALIGN_LEFT, red)
end

-- *****************
-- ** TASK PAGE ****
-- *****************
function draw_page_task()
    -- logInfo("gpsnav draw called")
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

-- *****************
-- ** NAV PAGE *****
-- *****************
function draw_page_nav()
    -- logInfo("gpsnav draw called")
    sasl.gl.drawTexture(nav_background_img, 0, 0, w, h, {1.0,1.0,1.0,1.0}) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    -- "1/5: 1N7"
    local top_string
    if #task == 0
    then
        top_string = " LOAD TASK"
        sasl.gl.drawText(font,5,h-30, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)
        return
    end

    top_string = "NAV "..task_index .. "/" .. #task .. ":" .. task[task_index].ref

    -- "DIST: 37.5km"
    local distance_string
    if project_settings.DISTANCE_UNITS == 0 -- (0=mi, 1=km)
    then
        distance_string = (math.floor(project_settings.gpsnav_wp_distance_m * M_TO_MI * 10.0) / 10.0) .. " MI"
    else
        distance_string = (math.floor(project_settings.gpsnav_wp_distance_m / 100.0) / 10.0) .. " KM"
    end
    local mid_string = distance_string

    local altitude_string
    if project_settings.ALTITUDE_UNITS == 0 -- (0=feet, 1=meters)
    then
        altitude_string = math.floor(project_settings.gpsnav_wp_altitude_m * M_TO_FT) .. " FT"
    else
        altitude_string = math.floor(project_settings.gpsnav_wp_altitude_m) .. " M"
    end
    local bottom_string = altitude_string

    --  TOP STRING                         size isBold isItalic
    sasl.gl.drawText(font,5,h-30, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)

    -- MIDDLE STRING
    sasl.gl.drawText(font,5,h-75, mid_string, 18, true, false, TEXT_ALIGN_LEFT, black)

    -- BOTTOM STRING
    sasl.gl.drawText(font,5,55, bottom_string, 18, true, false, TEXT_ALIGN_LEFT, black)

end

-- *****************
-- ** MAP PAGE *****
-- *****************
function draw_page_map()
    -- logInfo("gpsnav draw called")
    sasl.gl.drawTexture(map_background_img, 0, 0, w, h, {1.0,1.0,1.0,1.0}) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    -- "1/5: 1N7"
    local top_string
    if #task == 0
    then
        top_string = " LOAD TASK"
        sasl.gl.drawText(font,5,h-30, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)
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
callback["wp_next"] = button_left_clicked
callback["wp_prev"] = button_right_clicked

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
    panel_button { id="wp_next", position = { 79, 189, 34, 18} },
    panel_button { id="wp_prev", position = { 116, 189, 34, 18} }
}
