-- Export selected tags into separate sprite sheets
local spr = app.activeSprite
if not spr then return print('No active sprite') end

-- Check if there are tags in the sprite
if #spr.tags == 0 then
    app.alert("No tags found in the sprite")
    return
end

-- Configuration file setup
local config_filename = "export_path.txt"
local config_path = app.fs.joinPath(app.fs.userConfigPath, config_filename)

-- Try to load last used path
local last_export_path = nil
if app.fs.isFile(config_path) then
    local file = io.open(config_path, "r")
    if file then
        last_export_path = file:read("*l") -- Read first line
        file:close()
        last_export_path = app.fs.normalizePath(last_export_path)
    end
end

-- Get original path details
local original_path, original_title = app.fs.filePath(spr.filename), app.fs.fileTitle(spr.filename)

-- Set default filename for dialog
local default_filename = app.fs.joinPath(
    last_export_path or original_path,
    original_title .. ".png"
)

-- Create output folder selection dialog
local dlg = Dialog("Export Location")

-- Function to update the export path label
local function update_export_path_label()
    local path
    if dlg.data.next_to_file then
        path = original_path
    else
        local selected_file = dlg.data.folder
        if selected_file and selected_file ~= "" then
            path = app.fs.filePath(selected_file)
        else
            path = "No folder selected"
        end
    end
    dlg:modify{id="export_path_label", text="Export to: " .. path}
end

-- Checkbox: "Next to this file"
dlg:check{
    id="next_to_file",
    text="Next to this file",
    selected=false,
    onclick=function()
        local checked = dlg.data.next_to_file
        dlg:modify{id="folder", enabled=not checked}
        update_export_path_label()
    end
}

-- Checkbox: "Include file name"
dlg:check{
    id="include_file_name",
    text="Include file name",
    selected=false  -- Default to unchecked as in original
}

-- File selector for output folder
dlg:file{
    id="folder",
    label="Output Folder:",
    title="Select output folder",
    save=true,
    filename=default_filename,
    onchange=update_export_path_label
}

-- Label to show current export path
dlg:label{
    id="export_path_label",
    text="Export to: " .. app.fs.filePath(default_filename)
}

-- Add tag selection checkboxes
dlg:separator{ text="Select tags to export:" }
for i, tag in ipairs(spr.tags) do
    dlg:check{ id="tag_"..i, text=tag.name, selected=true }
end

-- Dialog buttons
dlg:button{ id="ok", text="Export" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

-- Process dialog response
local data = dlg.data
if not data.ok then return end

-- Collect selected tags
local selected_tags = {}
for i, tag in ipairs(spr.tags) do
    if data["tag_"..i] then
        table.insert(selected_tags, tag)
    end
end

-- Check if any tags are selected
if #selected_tags == 0 then
    app.alert("No tags selected for export")
    return
end

-- Determine output directory based on checkbox state
local output_dir
if data.next_to_file then
    output_dir = original_path
else
    local selected_file = data.folder
    if selected_file and selected_file ~= "" then
        output_dir = app.fs.filePath(selected_file)
    else
        app.alert("No output folder selected")
        return
    end
end
output_dir = app.fs.normalizePath(output_dir)

-- Save the directory to config
local file = io.open(config_path, "w")
if file then
    file:write(output_dir)
    file:close()
end

-- Prepare confirmation message for selected tags
local msg = { "Do you want to export/overwrite the following files?" }
for _, tag in ipairs(selected_tags) do
    local base_name = data.include_file_name and (original_title .. "-" .. tag.name) or tag.name
    local fn = app.fs.joinPath(output_dir, base_name)
    table.insert(msg, "- " .. fn .. ".png")
end

-- Confirm export
if app.alert{ 
    title="Export Sprite Sheets", 
    text=msg,
    buttons={ "&Yes", "&No" } 
} ~= 1 then
    return
end

-- Export selected tags
for _, tag in ipairs(selected_tags) do
    local base_name = data.include_file_name and (original_title .. "-" .. tag.name) or tag.name
    local fn = app.fs.joinPath(output_dir, base_name)
    app.command.ExportSpriteSheet{
        ui=false,
        type=SpriteSheetType.HORIZONTAL,
        textureFilename=fn .. ".png",
        tag=tag.name,
        mergeLayers=true,
        listLayers=false,
        listTags=false,
        listSlices=false,
    }
end

-- Show completion message
app.alert{
    title="Export Complete",
    text="Sprite sheets exported to:\n" .. output_dir,
    buttons={ "OK" }
}