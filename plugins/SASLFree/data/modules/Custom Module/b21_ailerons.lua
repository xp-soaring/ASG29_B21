-- B21 b21_ailerons.lua

-- animate the ASG29 ailerons to droops with flaps
-- Note this is only for the VISUAL animation. The underlying flight model is tuned separately.
--

print("b21_ailerons loaded")

----------------------------------- READ DATAREFS -----------------------------------
local DATAREF_ROLL = globalPropertyf("sim/joystick/FC_roll")
local DATAREF_FLAPS = globalPropertyfa("sim/flightmodel2/wing/flap1_deg")
----------------------------------- WRITE DATAREFS -----------------------------------
local DATAREF_AILERON_LEFT = createGlobalPropertyf("b21/asg29/aileron_left", 0.0, false, true, true)
local DATAREF_AILERON_RIGHT = createGlobalPropertyf("b21/asg29/aileron_right", 0.0, false, true, true)

-- I've slightly over-engineered this mapping, which adjusts the CENTRE point, MAX UP and MAX DOWN range
-- of the ailerons for every flap setting, as a map table with points that can be interpolated between.
-- In the implementation in update() I'm only offsetting based on the CENTER and keeping the up/down range the
-- same.
--
-- ASG29 aileron deflection ranges based on flap angle, for interpolation
-- e.g. flaps at 23 deg means ailerons +35..-5 deg with center stick at 21
--             flap, down, center, up
local map = { { -10, 9, 0, -20 }, -- we're not expecting flaps here
              { 0, 9, 0, -20 }, -- flap 1
              { 3, 12, 3, -17 }, -- flap 2
              { 8, 18, 8, -13 }, -- flap 3
              { 14, 26, 13, -12 }, -- flap 4
              { 23, 35, 21, -5 }, -- flap 5
              { 26, 39, 22, -3 }, -- flap 6
              { 50, 26, 14, -11}, -- flap L
              {100, 26, 14, -11} -- not expecting flaps here either
}

-- interpolate between map points and return { down, center, up} degrees for ailerons
function interp(flap_deg, p1, p2)
    local ratio = (flap_deg - p1[1]) / (p2[1] - p1[1])
    return p1[2] + ratio * (p2[2]-p1[2]),
           p1[3] + ratio * (p2[3]-p1[3]),
           p1[4] + ratio * (p2[4]-p1[4])
end

function aileron_range(flaps_deg)
    local prev_point = { -20, 9, 0, -20 }
    for i, point in pairs(map) -- each point is { flaps_deg, down, center, up }
    do
        if flaps_deg < point[1]
        then
            return interp(flaps_deg, prev_point, point )
        end
        prev_point = point
    end
    print("NO AILERON MAP FOR FLAPS", flaps_deg)
end

local prev_flaps_deg = 0

local down, center, up = aileron_range(prev_flaps_deg)

-- acf file aileron deflection range down/up
local DOWN_MAX = 20
local UP_MAX = 28

-- X-PLANE per-frame update
function update()
    local roll = get(DATAREF_ROLL)
    local flaps_deg = get(DATAREF_FLAPS,1)
    if flaps_deg ~= prev_flaps_deg
    then
        down, center, up = aileron_range(flaps_deg)
        print("New aileron range", flaps_deg, down, center, up)
        prev_flaps_deg = flaps_deg
    end

    local aileron_adjust = center / DOWN_MAX
    set(DATAREF_AILERON_LEFT, roll + aileron_adjust)
    set(DATAREF_AILERON_RIGHT, roll - aileron_adjust)
    
end
