-- Get the path separator based on the operating system
local Sep = package.config:sub(1,1)

-- Function to extract the directory from a file path
local function Dirname(str)
    return str:match("(.*" .. Sep .. ")") or ""
end

-- Function to flatten a group by drawing all visible layers onto an image
local function flatten_group(group, frame, image)
    for _, layer in ipairs(group.layers) do
        if layer.isGroup then
            flatten_group(layer, frame, image)
        elseif layer.isVisible then
            local cel = layer:cel(frame)
            if cel then
                local options = { blendMode = layer.blendMode, opacity = layer.opacity / 255.0 }
                image:drawImage(cel.image, cel.position.x, cel.position.y, options)
            end
        end
    end
end

-- Function to collect groups at a specific depth
local function collectGroupsAtDepth(layers, currentDepth, targetDepth, groups)
    groups = groups or {}
    
    for _, layer in ipairs(layers) do
        if layer.isGroup then
            if currentDepth == targetDepth then
                table.insert(groups, layer)
            elseif currentDepth < targetDepth then
                collectGroupsAtDepth(layer.layers, currentDepth + 1, targetDepth, groups)
            end
        end
    end
    
    return groups
end

-- Function to export a group as a PNG
local function exportGroup(group, output_dir, frame)
    local spr = group.sprite
    local new_image = Image(spr.width, spr.height, spr.colorMode)
    flatten_group(group, frame, new_image)
    local filename = output_dir .. group.name .. ".png"
    new_image:saveAs(filename)
end

-- Main function to handle the export process
local function main()
    if not app.activeSprite then
        app.alert("No active sprite")
        return
    end

    local spr = app.activeSprite
    local frame = app.activeFrame or 1

    -- Create a dialog to get the depth and output location
    local dlg = Dialog("Export Groups at Depth")
    
    dlg:label{ text = "Depth = 1: Top-level groups" }
    
    dlg:number{
        id = "depth",
        label = "Depth:",
        text = "2",
        decimals = 0
    }
    
    dlg:separator()

    -- Determine the default directory
    local default_dir = spr.filename ~= "" and Dirname(spr.filename) or ""
    local default_filename
    if spr.filename ~= "" then
        default_filename = spr.filename
    else
        default_filename = default_dir .. "untitled.aseprite"
    end

    -- File selection for the output directory
    dlg:file{
        id = "output",
        label = "Output directory:",
        filename = default_filename,
        open = false
    }

    -- Add buttons
    dlg:button{ id = "ok", text = "Export" }
    dlg:button{ id = "cancel", text = "Cancel" }

    -- Show the dialog
    dlg:show()

    if not dlg.data.ok then
        return
    end

    local depth = dlg.data.depth or 2
    if depth < 1 then
        app.alert("Depth must be at least 1")
        return
    end

    local selected_path = dlg.data.output
    if not selected_path or selected_path == "" then
        app.alert("No output location selected")
        return
    end

    local output_dir = Dirname(selected_path)
    if output_dir == "" then
        app.alert("Invalid output directory")
        return
    end

    -- Collect groups at the specified depth
    local groups_to_export = collectGroupsAtDepth(spr.layers, 1, depth)

    if #groups_to_export == 0 then
        app.alert("No groups found at depth " .. depth)
        return
    end

    -- Build list of groups that will be exported
    local group_names = {}
    for _, group in ipairs(groups_to_export) do
        table.insert(group_names, group.name .. ".png")
    end

    -- Export each group
    local startExportTime = os.clock()
    for _, group in ipairs(groups_to_export) do
        exportGroup(group, output_dir, frame)
    end
    local exportTime = os.clock() - startExportTime

    -- Create detailed completion message
    local message = {
        "Found " .. #groups_to_export .. " groups at depth " .. depth .. ":",
        "",
    }
    for _, name in ipairs(group_names) do
        table.insert(message, "✓ " .. name)
    end
    table.insert(message, "")
    table.insert(message, "Exported in " .. string.format("%.3f", exportTime) .. " seconds")

    app.alert{
        title="Export Complete", 
        text=message,
        buttons="OK"
    }
end

-- Run the script
main()