local dlg = Dialog("Get Distance")
dlg.bounds = Rectangle(1300, 850, 150, 200)
local posX = 0
local posY = 0

local function updateDistance()
    local cel = app.cel
    if cel then
        local position = cel.position
        posX = position.x < 0 and 0 or position.x
        posY = position.y < 0 and 0 or position.y
    else
        posX = 0
        posY = 0
    end
    dlg:modify{id = "xLabel", text = "X: " .. posX}
    dlg:modify{id = "yLabel", text = "Y: " .. posY}
end

dlg:label{id = "xLabel", text = "X: 0"}
dlg:label{id = "yLabel", text = "Y: 0"}

-- Initial update to set the starting position
updateDistance()

-- Set up the event listener for automatic updates
app.events:on("sitechange", updateDistance)

-- Show the dialog and keep it open
dlg:show{wait = false}