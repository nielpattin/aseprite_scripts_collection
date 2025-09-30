# Aseprite Lua Script Development Environment

A file watcher that automatically copies `.lua` files to Aseprite's scripts folder for hot-reloading during development.

## Quick Start

### Install uv

https://docs.astral.sh/uv/getting-started/installation/

### Install Dependencies

```bash
uv sync
```


### Active the Virtual Environment
```bash
.venv\Scripts\activate
```
The virtual environment must be active to run scripts and commands in the project without uv run. Virtual environment activation differs per shell and platform.

### Run the File Watcher
- This also installs the required dependencies.
```bash
uv run main.py
```

The watcher will:
- Copy all existing `.lua` files to Aseprite's scripts folder on startup
- Monitor for changes and automatically copy updated files
- Display timestamps for each copy operation

## Included Aseprite Scripts

- **Export Group.lua** - Export groups at specific depths with optional parent path structure
- **Export Layers.lua** - Export individual layers with trimming and grouping options
- **Export Slices.lua** - Export sprite slices with management tools
- **Export Tags To Different Sprite Sheets.lua** - Export animation tags as separate sprite sheets
- **Get Cel Distance.lua** - Utility for measuring cel distances