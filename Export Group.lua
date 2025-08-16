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

-- Function to calculate bounding box for trimming
local function calculateBoundingBox(image)
    local minX, minY, maxX, maxY = nil, nil, nil, nil
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) ~= 0 then
                if not minX or x < minX then minX = x end
                if not minY or y < minY then minY = y end
                if not maxX or x > maxX then maxX = x end
                if not maxY or y > maxY then maxY = y end
            end
        end
    end
    if not minX or not minY then return nil end
    return { x = minX, y = minY, w = maxX - minX + 1, h = maxY - minY + 1 }
end

-- Function to get the full path of a group including parent groups
local function getGroupPath(group)
    local path = {}
    local current = group
    
    while current and current.parent do
        table.insert(path, 1, current.name)
        current = current.parent
        if current.sprite then break end -- Stop when we reach the sprite level
    end
    
    return table.concat(path, "/")
end

-- Function to collect groups at a specific depth with their paths
local function collectGroupsAtDepth(layers, currentDepth, targetDepth, groups, parentPath)
    groups = groups or {}
    parentPath = parentPath or ""
    
    for _, layer in ipairs(layers) do
        if layer.isGroup then
            local currentPath = parentPath == "" and layer.name or (parentPath .. "/" .. layer.name)
            
            if currentDepth == targetDepth then
                table.insert(groups, {group = layer, path = parentPath})
            elseif currentDepth < targetDepth then
                collectGroupsAtDepth(layer.layers, currentDepth + 1, targetDepth, groups, currentPath)
            end
        end
    end
    
    return groups
end

-- Function to export a group as a PNG
local function exportGroup(group, output_dir, frame, groupPath, withGroupPath, trim)
    local spr = group.sprite
    local new_image = Image(spr.width, spr.height, spr.colorMode)
    flatten_group(group, frame, new_image)
    
    -- Apply trimming if enabled
    if trim then
        local bbox = calculateBoundingBox(new_image)
        if bbox then
            local trimmed = Image(bbox.w, bbox.h, new_image.colorMode)
            trimmed:clear(0)
            trimmed:drawImage(new_image, -bbox.x, -bbox.y)
            new_image = trimmed
        end
    end
    
    local filename
    if withGroupPath and groupPath ~= "" then
        -- Create subdirectory if needed
        local subdir = output_dir .. groupPath .. Sep
        app.fs.makeAllDirectories(subdir)
        filename = subdir .. group.name .. ".png"
    else
        filename = output_dir .. group.name .. ".png"
    end
    
    new_image:saveAs(filename)
    return filename
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
    
    dlg:check{
        id = "withGroupPath",
        label = "With Group Path",
        selected = true
    }
    
    dlg:check{
        id = "trim",
        label = "Trim",
        selected = true
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
    local withGroupPath = dlg.data.withGroupPath or false
    local trim = dlg.data.trim or false
    
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
    local exported_files = {}
    for _, groupData in ipairs(groups_to_export) do
        local group = groupData.group
        local groupPath = groupData.path
        
        if withGroupPath and groupPath ~= "" then
            table.insert(group_names, groupPath .. "/" .. group.name .. ".png")
        else
            table.insert(group_names, group.name .. ".png")
        end
    end

    -- Export each group
    local startExportTime = os.clock()
    for _, groupData in ipairs(groups_to_export) do
        local group = groupData.group
        local groupPath = groupData.path
        local filename = exportGroup(group, output_dir, frame, groupPath, withGroupPath, trim)
        table.insert(exported_files, filename)
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