-- B21

print("b21_clock starting, CLOCK_MODE =", project_settings.CLOCK_MODE)

-- The cockpit clock instrument (e.g. the 'watch') has its hands driven by
-- the project datarefs b21/clock/hours,minutes,seconds respectively.
-- This module writes the values into those datarefs based on USER_SETTINGS.lua

-- READ datarefs
local dataref_hours
local dataref_minutes
local dataref_seconds

if project_settings.CLOCK_MODE == 0 -- simulator local
then
    dataref_hours = globalPropertyi("sim/cockpit2/clock_timer/local_time_hours")
    dataref_minutes = globalPropertyi("sim/cockpit2/clock_timer/local_time_minutes")
    dataref_seconds = globalPropertyi("sim/cockpit2/clock_timer/local_time_seconds")
elseif project_settings.CLOCK_MODE == 1 -- simulator zulu
then
    dataref_hours = globalPropertyi("sim/cockpit2/clock_timer/zulu_time_hours")
    dataref_minutes = globalPropertyi("sim/cockpit2/clock_timer/zulu_time_minutes")
    dataref_seconds = globalPropertyi("sim/cockpit2/clock_timer/zulu_time_seconds")
end

-- WRITE datarefs
local needle_hours = createGlobalPropertyf("b21/clock/hours", 1, false, true, true)
local needle_minutes = createGlobalPropertyf("b21/clock/minutes", 0, false, true, true)
local needle_seconds = createGlobalPropertyf("b21/clock/seconds", 0, false, true, true)

-- 
function update()
    if project_settings.CLOCK_MODE == 0 or project_settings.CLOCK_MODE == 1
    then
        local mins = get(dataref_minutes)
        set(needle_hours, get(dataref_hours) + mins / 60.0)
        set(needle_minutes, mins)
        set(needle_seconds, get(dataref_seconds))
    elseif project_settings.CLOCK_MODE == 2
    then
        local t = os.date("*t",os.time()) -- get local system time
        set(needle_hours, t.hour + t.min / 60.0)
        set(needle_minutes, t.min)
        set(needle_seconds, t.sec)
    end
end
