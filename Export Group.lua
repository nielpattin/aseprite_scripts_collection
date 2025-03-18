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

-- Function to export a group as a PNG
local function exportGroup(group, output_dir, frame)
    local spr = group.sprite
    local new_image = Image(spr.width, spr.height, spr.colorMode)
    flatten_group(group, frame, new_image)
    local filename = output_dir .. group.name .. ".png"
    new_image:saveAs(filename)
    print("Saved " .. filename)
end

-- Main function to handle the export process
local function main()
    if not app.activeSprite then
        app.alert("No active sprite")
        return
    end

    local spr = app.activeSprite
    local frame = app.activeFrame or 1

    -- Collect all top-level groups
    local top_groups = {}
    for _, layer in ipairs(spr.layers) do
        if layer.isGroup then
            table.insert(top_groups, layer)
        end
    end

    if #top_groups == 0 then
        app.alert("No top-level groups found")
        return
    end

    -- Determine the default directory
    local default_dir = spr.filename ~= "" and Dirname(spr.filename) or ""
    local default_filename
    if spr.filename ~= "" then
        default_filename = spr.filename  -- Use the full path, e.g., "/path/to/my_sprite.aseprite"
    else
        default_filename = default_dir .. "untitled.aseprite"  -- Fallback for unsaved sprites
    end

    -- Create a dialog to select the output location and show all groups
    local dlg = Dialog("Export Top-Level Groups")

    -- Inform the user what will be exported
    dlg:label{ text = "The following groups will be exported as PNGs:" }

    -- List all groups with their .png filenames
    for _, group in ipairs(top_groups) do
        local filename = group.name .. ".png"
        dlg:label{ text = filename }
    end

    -- Add a separator for clarity
    dlg:separator()

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
        print("Export cancelled")
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

    -- Export each group with the full path displayed in the console
    for _, group in ipairs(top_groups) do
        exportGroup(group, output_dir, frame)
    end

    print("Export complete")
end

-- Run the script
main()