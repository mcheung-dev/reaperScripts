# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a collection of Lua scripts and tools for the Reaper DAW (Digital Audio Workstation), specifically designed for game audio and sound design workflows. The repository contains both standalone scripts and more complex GUI-based tools.

## Dependencies
All scripts require the following Reaper extensions to be installed via ReaPack:
- **SWS Extension**: Core functionality extension
- **js_ReaScriptAPI**: JavaScript ReaScript API
- **ReaImGui**: GUI framework (minimum version 0.9.3.2)

Scripts automatically check for these dependencies on startup and will display installation prompts if missing.

## Code Architecture

### Repository Structure
- **Scripts/**: Single-purpose utility scripts that perform specific tasks
- **Tools/**: Complex multi-function applications with GUI interfaces
  - Each tool has a main `.lua` file and a `Functions/` subdirectory
  - GUI logic is separated into `User Interface.lua` files
  - Shared functionality is modularized into separate function files

### Tools Architecture
The two main tools follow a consistent pattern:
- **Main script**: Dependency checking, global variables, and script initialization
- **Functions/ directory**: Modular components loaded via `require()`
  - `User Interface.lua`: ImGui-based interface logic
  - Task-specific function files (e.g., `Copy Paste Selected Media Items.lua`)
  - Utility files (`General Functions.lua`, `json.lua`)

### Key Patterns
- Dependency validation at script startup with user-friendly error messages
- ImGui context creation and font management for GUI tools
- Modular function architecture using Lua's `require()` system
- Script versioning and metadata in header comments using ReaPack format

## Development Commands
- **Testing**: Scripts are tested directly in Reaper DAW
- **Distribution**: Uses ReaPack system with `index.xml` for package management
- **Installation**: Via ReaPack repository: `https://raw.githubusercontent.com/mcheung-dev/reaperScripts/refs/heads/master/index.xml`

## Common Workflow Patterns
- Scripts use `reaper.defer()` for GUI event loops
- Dependency checking follows standard pattern with ReaPack integration
- Error handling includes user-friendly message boxes
- Scripts support re-triggering to close existing instances

## Script Metadata Format
All scripts include ReaPack-compatible headers:
```lua
-- @author mcheung
-- @version x.x
-- @provides 
--     [nomain] Functions/*.lua
--     [nomain] Presets/*.json
```