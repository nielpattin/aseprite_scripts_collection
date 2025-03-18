-- Check for active sprite
local sprite = app.activeSprite
if not sprite then
  app.alert("No active sprite. Open a sprite first.")
  return
end

local Sep = package.config:sub(1,1)
local frame = app.activeFrame or 1

-- Utility: get directory from a file path
local function Dirname(path)
  return path:match("(.*" .. Sep .. ")") or ""
end

-- (Optional) Calculate bounding box for trimming; if enabled, we'll trim the cel image.
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

-- Export a single non-group layer by creating a new image from its cel.
local n_layers = 0
local function exportLayer(layer, currentPath, frame, options)
  local cel = layer:cel(frame)
  if not cel then 
    return 
  end
  
  local fileName = currentPath .. Sep .. layer.name .. ".png"
  
  if options.trim then
    -- Trim: calculate bounding box from the cel's image
    local bbox = calculateBoundingBox(cel.image)
    if bbox then
      -- Create a new image of the bounding box size and copy the region from cel.image.
      local trimmed = Image(bbox.w, bbox.h, cel.image.colorMode)
      trimmed:clear(0)
      trimmed:drawImage(
        cel.image,
        -bbox.x, -bbox.y  -- shift so that bbox.x,y becomes (0,0)
      )
      trimmed:saveAs(fileName)
      n_layers = n_layers + 1
      return
    end
  end
  
  -- Without trimming, we create a new image of the full sprite size,
  -- then draw the cel image at its position.
  local new_image = Image(sprite.width, sprite.height, sprite.colorMode)
  new_image:clear(0)
  new_image:drawImage(
    cel.image,
    cel.position.x, cel.position.y,
    { blendMode = layer.blendMode, opacity = layer.opacity / 255.0 }
  )
  new_image:saveAs(fileName)
  n_layers = n_layers + 1
end

-- Recursive export function.
-- For group layers, create a subfolder and export its child layers into that folder.
local function exportLayers(layerContainer, currentPath, frame, options)
  for _, layer in ipairs(layerContainer.layers) do
    if layer.isGroup then
      local newPath = currentPath .. Sep .. layer.name
      os.execute("mkdir \"" .. newPath .. "\"")
      exportLayers(layer, newPath, frame, options)
    else
      exportLayer(layer, currentPath, frame, options)
    end
  end
end

-- Determine default output directory based on sprite's file path.
local default_dir = (sprite.filename ~= "") and Dirname(sprite.filename) or "."
local default_filename = (sprite.filename ~= "") and sprite.filename or (default_dir .. "untitled.aseprite")

-- Create dialog for export options.
local dlg = Dialog("Export Layers")
dlg:file{
  id = "output",
  label = "Output folder:",
  filename = default_filename,
  open = false,
}
dlg:check{
  id = "trim",
  label = "Trim exported image",
  selected = true,
}
dlg:check{
  id = "include_group",
  label = "Create subfolders for groups",
  selected = true,
}
dlg:button{
  id = "ok",
  text = "Export",
}
dlg:button{
  id = "cancel",
  text = "Cancel",
}
dlg:show()

if not dlg.data.ok then 
  return 
end

local options = {
  trim = dlg.data.trim,
  includeGroup = dlg.data.include_group,  -- (Currently always used to create subfolders.)
}

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

-- Create the base folder if it doesn't exist
os.execute("mkdir \"" .. output_dir .. "\"")

-- Export all layers recursively.
exportLayers(sprite, output_dir, frame, options)

app.alert("Export complete: " .. n_layers .. " layer(s) exported.")
