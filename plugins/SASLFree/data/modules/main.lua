-- B21


size = { 1024, 1024 }


components = {	
	popupCloseButton {
		position = { 400, 700, 40, 25 },
		cursor = {x = 0, y = 0, width = 16, height = 16, shape = loadImage("interactive.png")},
	}
}

function draw()
    drawAll(components)
end

function update()
    updateAll(components)
end
