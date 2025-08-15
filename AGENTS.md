# Agent Guidelines for Aseprite Python Project

- **No tests configured** - this is a simple file watcher utility

## Code Style
- **Python version**: 3.13+
- **Package manager**: uv
- **Imports**: Standard library first, then third-party (watchdog), group with blank lines
- **Classes**: PascalCase (e.g., `LuaFileHandler`)
- **Functions/variables**: snake_case (e.g., `dest_dir`, `on_modified`)
- **Error handling**: Use try/except blocks, pass silently for non-critical errors
- **Logging**: Disable debug logging for third-party libraries when not needed
- **File paths**: Use `os.path.join()` for cross-platform compatibility
- **Time formatting**: Use `time.strftime('%H:%M:%S')` for consistent timestamps

## Aseprite Lua Scripting Context
- **Purpose**: This watcher copies .lua files to Aseprite's scripts folder for hot-reloading
- **Aseprite API**: Lua scripts use `app` global namespace (app.sprite, app.command, etc.)
- **Common patterns**: `app.command.CommandName{}`, `Dialog()`, `Sprite()` constructors
- **File locations**: Scripts copied to `scripts/` folder in Aseprite user directory
- **API version**: Check `app.apiVersion` for compatibility in Lua scripts
- **Key globals**: `app`, `json`, Color, Rectangle, Point, Size, Sprite, Dialog
- **Commands**: Use `app.command.CommandName{param=value}` syntax for Aseprite operations

## Project Context
This is a file watcher that copies .lua files from the project directory to Aseprite's scripts folder.
The main functionality is in `main.py` with a `LuaFileHandler` class that extends `FileSystemEventHandler`.
Dependencies are minimal (only watchdog) and managed via uv/pyproject.toml.

## Architecture
- Single-file application with file system monitoring
- Event-driven architecture using watchdog observers
- Cross-platform file operations with proper error handling
- Automatic initial sync of all .lua files on startup

## USE Context7 mcp tool to get infomation about API of ASEPRITE
- `Context7_get_library_docs /aseprite/api` 