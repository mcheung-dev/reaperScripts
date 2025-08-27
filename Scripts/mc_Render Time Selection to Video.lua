-- @author mcheung
-- @version 1.0 
-- Script that renders video from time selection

function main()

start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
if start_time ~= end_time then
    -- get
  render_settings = reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, false)
  render_boundsflag = reaper.GetSetProjectInfo(0, 'RENDER_BOUNDSFLAG', 0, false)
  render_tailflag = reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, false)
  render_addtoproj = reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, false)
  render_samplerate = reaper.GetSetProjectInfo(0, 'RENDER_SRATE', 0, true)
  render_normalize = reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE', 1536, false)
  render_fadein = reaper.GetSetProjectInfo(0, 'RENDER_FADEIN', 0.25, false)
  render_fadeout = reaper.GetSetProjectInfo(0, 'RENDER_FADEOUT', 0.25, false)
  
  -- Store original project settings
  original_srate_use = reaper.GetSetProjectInfo(0, 'PROJECT_SRATE_USE', 0, false)
  
  rfi_retval, render_file = reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', '', false)
  rp_retval, render_pattern = reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', '', false)
  rfo1_retval, render_format_01 = reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', '', false)
  rfo2_retval, render_format_02 = reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT2', '', false)
  
  -- prompt user for save location
  local retval, save_path = reaper.JS_Dialog_BrowseForFolder("Select folder to save video", "")
  
  if not retval then
    reaper.ShowMessageBox('Render cancelled by user.', 'Terromino_Render video from time selection', 0)
    return false
  end
  
  -- Set video render settings
  
  reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, true) -- 0 master mix
  reaper.GetSetProjectInfo(0, 'RENDER_BOUNDSFLAG', 2, true) -- 2 time selection
  reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, true)
  reaper.GetSetProjectInfo(0, 'RENDER_SRATE', 48000, true)
  reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, true)
  
  reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE', 1536, true) -- fade in & fade out
  reaper.GetSetProjectInfo(0, 'RENDER_FADEIN', 0.25, true)
  reaper.GetSetProjectInfo(0, 'RENDER_FADEOUT', 0.25, true)
  
  reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', save_path, true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', '$project_$date', true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', 'PMFF', true)
  --File: Render project, using the most recent render settings
  reaper.Main_OnCommand(41824, 0)
  -- Restore previous render settings

  reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', render_settings, true) -- 0 master mix
  reaper.GetSetProjectInfo(0, 'RENDER_BOUNDSFLAG', render_boundsflag, true) -- 2 time selection
  reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', render_tailflag, true)
  reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', render_addtoproj, true)
  reaper.GetSetProjectInfo(0, 'RENDER_SRATE', render_samplerate, true)
  reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE', render_normalize, true) -- fade in & fade out
  reaper.GetSetProjectInfo(0, 'RENDER_FADEIN', render_fadein, true)
  reaper.GetSetProjectInfo(0, 'RENDER_FADEOUT', render_fadeout, true)
  
  -- Restore original project settings
  reaper.GetSetProjectInfo(0, 'PROJECT_SRATE_USE', original_srate_use, true)
  
  reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', render_file, true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', render_pattern, true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', render_format_01, true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT2', render_format_02, true)
     
else
  
    reaper.ShowMessageBox('No time selection. Please select a time range to be rendered.', 'Terromino_Render video from time selection', 0)
  
end

end


reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() 

main()

reaper.Undo_EndBlock("Render video from time selection", - 1)

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)


