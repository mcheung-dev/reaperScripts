# Reaper Scripts for Game Audio and Sound Design
This is a database of scripts that I wrote for Reaper DAW. Sharing them here for the game audio community as well. Enjoy!

SWS, js_ReaScriptAPI and ReaImGui extensions are required to be installed for scripts to work correctly.
# Installation 
You can install these scripts by using ReaPack. In Reaper, go to the menu bar: Extension > ReaPack > Import Repositories... and copy and past the link below into the dialogue box.

https://raw.githubusercontent.com/mcheung-dev/reaperScripts/refs/heads/master/index.xml

# Tools 
## MC_FastFileRenamer - Batch File Renamer Tool
This tool is designed to assist with renaming media items within Reaper. It replicates the functionality of the FastFileRenamer desktop app, enabling you to replace, remove, and insert naming patterns effortlessly—all with a single click.

![Untitledvideo-MadewithClipchamp1-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/7983ed5b-69e5-49f4-bd9c-79d50b4f5cd9)

## MC_Variation Generator - One-Click Variations!
This tool is designed to make variations creation easy. One tap to duplicates your layers, randomizes key parameters, and region creation for effortless variety.

![gif-001-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/e15c8622-5a9f-43a9-b3a0-6a183810f0dc)
### Implode Takes Feature
![gif-002-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/796e628f-b96e-41bc-b888-24b4b2a340eb)

## Scripts List

* *mc_Auto Increment Duplicate Regions*
   - Automatically renames duplicate regions with incremental numbers (_01, _02, etc.)
   - Particularly useful for organizing render export regions

* *mc_Auto Increment Items*
   - Automatically renames selected items with incremental numbers, works with different naming patterns (eg SFX_01, SFX_02, SFX_03, VO_01, VO_02, VO_03)

* *mc_Create Region from Selected Items*
   - Creates a new region that encompasses all currently selected items

* *mc_Mousewheel Item Rate*
   - Adjusts media item playback rate using the mousewheel

* *mc_Move items to mouse location*
   - Moves selected items to the current mouse cursor position
   - Quick repositioning of media without dragging

* *mc_Move Muted Tracks to Bottom Except VIDEO & REFERENCE*
   - Organizes project by moving muted tracks to the bottom
   - Preserves the position of tracks named "VIDEO" or "REFERENCE"

* *mc_Move Muted Tracks to Bottom of Folder Except VIDEO & REFERENCE*
   - Moves muted tracks to the bottom within their folder structure
   - Preserves the position of tracks named "VIDEO" or "REFERENCE"

* *mc_Move Selected Tracks to Top Below VIDEO & REFERENCE*
   - Repositions selected tracks to the top of the project just below tracks named "VIDEO" or "REFERENCE"

* *mc_Remove Unused Tracks*
   - Identifies and removes tracks that don't contain any media items (feel free to adjust the .lua for specific properties)
   - Helps clean up visual clutter

* *mc_Render Time Selection to Stereo*
   - Renders the current time selection to a stereo file to track below, mute original

* *mc_RepositionItems*
   - Arranges selected items sequentially with specified gaps (default 0.5, adjust .lua for time value)
   - Useful for organizing sound effects or dialogue clips

* *mc_Reset MediaItem Rate*
   - Resets playback rate of selected items to original speed
   - Adjusts item length & perserves fade properties

* *mc_Select items under length threshold on selected tracks*
   - Selects items that are shorter than a specified duration
   - Helps identify and manage very short audio clips for batch processing/deletion

* *mc_Set All Tracks to 0dB*
   - Resets the fader of all tracks to (unity gain)
   - Quick way to normalize track volumes






# Contact 
Shoot me an email at mcheungwork3@gmail.com! 
