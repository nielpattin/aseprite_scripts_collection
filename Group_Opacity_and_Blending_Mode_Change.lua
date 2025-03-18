local dlg = Dialog { title = "Group Opacity and Blending Mode Change" }

dlg:combobox {
    id = "bm",
    label = "Blend Mode: ",
    option = "NORMAL",
    options = {
        "Normal",
		"Darken",
		"Multiply",
		"Color Burn",
		"Lighten",
		"Screen",
		"Color Dodge",
		"Addition",
		"Overlay",
		"Soft Light",
		"Hard Light",
		"Difference",
		"Exclusion",
		"Subtract",
		"Divide",
		"Hue",
		"Saturation",
		"Color",
		"Luminosity" }
}

dlg:slider {
    id = "op",
    label = "Opacity: ",
    min = 0,
    max = 255,
    value = 127
}

dlg:button{
    id = "ok",
    text = "OK",
    focus = true,
	hexpand=100,
    onclick = function()
        
		local args = dlg.data
		local layer = app.activeLayer
		local l = layer.layers
		local bm
		if layer.isGroup then
			local xl = #layer.layers
			if args.bm == "Normal" then
				bm = BlendMode.NORMAL
			elseif args.bm == "Darken" then
				bm = BlendMode.DARKEN
			elseif args.bm == "Multiply" then
				bm = BlendMode.MULTIPLY
			elseif args.bm == "Color Burn" then
				bm = BlendMode.COLOR_BURN
			elseif args.bm == "Lighten" then
				bm = BlendMode.LIGHTEN
			elseif args.bm == "Screen" then
				bm = BlendMode.SCREEN
			elseif args.bm == "Color Dodge" then
				bm = BlendMode.COLOR_DODGE
			elseif args.bm == "Addition" then
				bm = BlendMode.ADDITION
			elseif args.bm == "Overlay" then
				bm = BlendMode.OVERLAY
			elseif args.bm == "Soft Light" then
				bm = BlendMode.SOFT_LIGHT
			elseif args.bm == "Hard Light" then
				bm = BlendMode.HARD_LIGHT
			elseif args.bm == "Difference" then
				bm = BlendMode.DIFFERENCE
			elseif args.bm == "Exclusion" then
				bm = BlendMode.EXCLUSION
			elseif args.bm == "Subtract" then
				bm = BlendMode.SUBTRACT
			elseif args.bm == "Divide" then
				bm = BlendMode.DIVIDE
			elseif args.bm == "Hue" then
				bm = BlendMode.HSL_HUE
			elseif args.bm == "Saturation" then
				bm = BlendMode.HSL_SATURATION
			elseif args.bm == "Color" then
				bm = BlendMode.HSL_COLOR
			elseif args.bm == "Luminosity" then
				bm = BlendMode.HSL_LUMINOSITY
			end
			for i = 1, xl, 1 do
				--l[i].isVisible = false
				l[i].blendMode = bm
				l[i].opacity = args.op
			end
		else
			print("Please select group folder.")
		end

        app.refresh()
    end
}

dlg:button {
    id = "cancel",
    text = "CANCEL",
	hexpand=false,
	vexpand=false,
    onclick = function()
        dlg:close()
    end
}

dlg:show { wait = false }