-- panel button

local font = sasl.gl.loadFont ( "fonts/UbuntuMono-Regular.ttf" )

local white = { 1.0, 1.0, 1.0, 1.0 }
local black = { 0.0, 0.0, 0.0, 1.0 }

defineProperty("cursor", {
    x = -8,
    y = -8,
    width = 16,
    height = 16,
    shape = sasl.gl.loadImage ("interactive.png"),
    --hideOSCursor = true
})

function onMouseDown()
    print("Mouse DOWN in ",get(text))
    callback[get(id)]()
    return true
end

function draw()
    local pos = get(position)
    sasl.gl.drawFrame(0,0,pos[3],pos[4],white)
    sasl.gl.drawText(font,0,0, get(text), 12, true, false, TEXT_ALIGN_LEFT, black)

end
