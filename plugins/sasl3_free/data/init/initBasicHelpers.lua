---------------------------------------------------------------------------------------------------------------------------
-- BASIC HELPERS -----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

-- Consider 0 as false
function toboolean(value)
    if 0 == value then
        return false
    else
        return value
    end
end

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

-- Check if coord lay inside rectangle. Rectangle is array of 
-- { x, y, width, height }
function isInRect(rect, x, y)
    local x1 = rect[1]
    local y1 = rect[2]
    local x2 = x1 + rect[3]
    local y2 = y1 + rect[4]
    return (x1 <= x) and (x2 > x) and (y1 <= y) and (y2 > y)
end

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------