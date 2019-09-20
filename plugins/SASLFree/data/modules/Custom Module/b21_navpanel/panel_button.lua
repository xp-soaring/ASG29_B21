-- panel button

defineProperty("cursor", {
    x = -8,
    y = -8,
    width = 16,
    height = 16,
    shape = sasl.gl.loadImage ("button_cursor.png"),
    --hideOSCursor = true
})

function onMouseDown()
    callback[get(id)]()
    return true
end
