-- b21_altimeter.lua


local w = size[1]
local h = size[2]

print("b21_altimeter.lua starting v0.1 ",w,'x',h)

-- datarefs READ from X-Plane
local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec") -- time in seconds
local DATAREF_ALT_FT = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot") -- 3000

-- conversion constants
local FT_TO_M = 0.3048

-- FONTS
local font = sasl.gl.loadFont( "fonts/OpenSans-Regular.ttf" )

-- COLORS
local white = { 1.0, 1.0, 1.0, 1.0 }

-- TEXTURES
local altimeter_background_img = sasl.gl.loadImage("altimeter_background.png")
local digits1_img = sasl.gl.loadImage("digits1.png")
local digits2_img = sasl.gl.loadImage("digits2.png")

local ALT_UNITS_STR = "FEET"
local ALT_CONVERT = 1
if project_settings.ALTITUDE_UNITS == 1 -- (0=feet, 1=meters)
then
    ALT_UNITS_STR = "METERS"
    ALT_CONVERT = FT_TO_M
end

-- x,y,w,h of rightmost small digit
local C1 = { x=104, y=71, w=14, h=21 }
-- x,y,w,h of rightmost large digit
local C2 = { x= 58, y=62, w=16, h=30 }

local cy = {} -- char y offsets in texture

function update()

    local alt = get(DATAREF_ALT_FT) * ALT_CONVERT

    -- e.g. alt = 12345.6

    -- get int and fraction for first digit
    local n,nf = math.modf(alt % 10) -- n = 5, nf = 0.6
    cy[1] = (n+nf)*C1.h

    if n < 9
    then
        nf = 0
    end
    n = math.modf(alt / 10 % 10) -- n = 4, ignore fractional return part
    cy[2] = (n+nf) * C1.h -- add fractional move of digit 1 if it was a "9"

    if n < 9
    then
        nf = 0
    end
    n = math.modf(alt / 100 % 10) -- n = 3, ignore fractional return part
    cy[3] = (n+nf) * C1.h -- add fractional move of digit 1 if digit 2 = "9"

    if n < 9
    then
        nf = 0
    end
    n = math.modf(alt / 1000 % 10) -- n = 2, ignore fractional return part
    -- now using larger digits (C2)
    cy[4] = (n+nf) * C2.h -- add fractional move of digit 1 if digit 2 = "9"

    if n < 9
    then
        nf = 0
    end
    n = math.modf(alt / 10000 % 10) -- n = 1, ignore fractional return part
    cy[5] = (n+nf) * C2.h -- add fractional move of digit 1 if digit 4 = "9"

end

function draw()

    -- draw instrument background
    sasl.gl.drawTexture(altimeter_background_img, 0, 0, w, h, {1.0,1.0,1.0,1.0}) -- draw background

    -- draw units string (METERS or FEET)
    sasl.gl.drawText(font,77,59, ALT_UNITS_STR 18, true, false, TEXT_ALIGN_LEFT, white)

    -- draw smaller digits
    local x, y = C1.x, C1.y
    sasl.gl.drawTexturePart(digits1_img, C1.x, y, C1.w, C1.h, 0, cy[1], white)
    x = x - C1.w
    sasl.gl.drawTexturePart(digits1_img, C1.x, y, C1.w, C1.h, 0, cy[2], white)
    x = x - C1.w
    sasl.gl.drawTexturePart(digits1_img, C1.x, y, C1.w, C1.h, 0, cy[3], white)
    -- draw larger digits
    local x,y = C2.x, C2.y
    sasl.gl.drawTexturePart(digits2_img, C2.x, C2.y, C2.w, C2.h, 0, cy[4], white)
    x = x - C2.w
    sasl.gl.drawTexturePart(digits2_img, C2.x, C2.y, C2.w, C2.h, 0, cy[5], white)

end
