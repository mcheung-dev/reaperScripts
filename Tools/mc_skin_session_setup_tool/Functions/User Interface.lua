-- @noindex


-- password protection setup
local ext_state_key = "MC_Skin_Import_Tool"
local password_set = reaper.GetExtState(ext_state_key, "authenticated")

if password_set ~= "1" then
    local correct_password = "riotaudio"  
    local retval, user_input = reaper.GetUserInputs("Enter Password", 1, "Password:", "")

    if not retval or user_input ~= correct_password then
        reaper.ShowMessageBox("Incorrect Password. Access Denied.", "Error", 0)
        goto eof
    end

    -- save authentication state so user doesn't need to enter again
    reaper.SetExtState(ext_state_key, "authenticated", "1", true)
end




--- global variables 
ScriptVersion = "1.0"
ScriptName = 'MC_Skin Import Tool'

--- Load Functions 
require('Functions/Create Subproject')
require('Functions/Organize By Name') --- 


local ctx = reaper.ImGui_CreateContext('MC_Skins_Import_Reaper')
local window_name = ScriptName..' '..ScriptVersion
local guiW = 340
local guiH = 470
local spacing = 10
local font = reaper.ImGui_CreateFont('roboto', 15)
local menufont = reaper.ImGui_CreateFont('roboto', 24)

local font_small = reaper.ImGui_CreateFont('roboto', 10)
local pin = true
local FLOATMIN = reaper.ImGui_NumericLimits_Float() -- returns a very small number close to 0

function import_selected_items_wwise() -- calling python function to import selected items
     reaper.Main_OnCommand(reaper.NamedCommandLookup("_RSd18f9e705831271ddbd73351717444f8c07bf82c"), 0)
end


-- attaching font
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, font_small) 
reaper.ImGui_Attach(ctx, menufont) 

function loop()
    PushTheme() --- push style theme 
    --demo.PushStyle(ctx) -- style editor
    --demo.ShowDemoWindow(ctx)
   
     -- Window settings
    local window_flags = reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_TopMost()
    if pin then 
        window_flags = window_flags | reaper.ImGui_WindowFlags_TopMost()
    end
      reaper.ImGui_SetNextWindowSize(ctx, guiW, guiH, reaper.ImGui_Cond_Once())

     -- Font 
     reaper.ImGui_PushFont(ctx, font)

     -- Begin
     local visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    if visible then

        

        -- instructions  
        reaper.ImGui_PushFont(ctx, menufont)
        reaper.ImGui_PushTextWrapPos(ctx, 0) 
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_Text(ctx, "Riot Skins Session Setup Tool")
        reaper.ImGui_PopTextWrapPos(ctx)  
        reaper.ImGui_PopFont(ctx)

        reaper.ImGui_Separator(ctx)

        reaper.ImGui_Dummy(ctx, 5, 5) 

        reaper.ImGui_PushTextWrapPos(ctx, 0) 
        reaper.ImGui_Text(ctx, 'This tool is designed to streamline skin set up by \nimporting and organizing all needed assets and help save you time.')
        reaper.ImGui_Dummy(ctx, 0, spacing)
        reaper.ImGui_PopTextWrapPos(ctx)  

        reaper.ImGui_PushFont(ctx, menufont)
        reaper.ImGui_SeparatorText( ctx, 'Instructions')
        reaper.ImGui_PopFont(ctx)
        -- reaper.ImGui_Dummy(ctx, 0, spacing)
      

        reaper.ImGui_PushTextWrapPos(ctx, 0) 
        reaper.ImGui_Text(ctx, '1. Select the Skin Work Unit in Wwise to bring in your assets')
        reaper.ImGui_Dummy(ctx, 0, spacing)
        reaper.ImGui_Text(ctx, '2. Customize your import with the available checkboxes')
        reaper.ImGui_Dummy(ctx, 0, spacing)
        reaper.ImGui_Text(ctx, '3. Click Import, and your Reaper template will be ready in seconds!')
        reaper.ImGui_Dummy(ctx, 0, spacing)
        reaper.ImGui_PopTextWrapPos(ctx)  

        reaper.ImGui_Separator(ctx)

        -- Ui Body 

        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xAC373FFF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xEF4958FF)


        --- Create Subprojects
         _, subprojects = reaper.ImGui_Checkbox(ctx, 'Generate Subprojects only', subprojects)

         reaper.ImGui_Dummy(ctx, 0, spacing)
         
        --- Create Regions 
        _, regions = reaper.ImGui_Checkbox(ctx, 'Generate Subprojects & Regions', regions)
        
        reaper.ImGui_Dummy(ctx, 0, spacing)

    

        --- Big Button
        if reaper.ImGui_Button(ctx, 'Create Session', -FLOATMIN, 50) then
            reaper.Undo_BeginBlock()
        
            if regions and subprojects then
                DeleteAllTracks()------ used to cleanup session so there are no empty subprojects being made 
                import_selected_items_wwise()
                OrganizeByName()
                CreateSubprojectsWithRegions()        
                reaper.ShowMessageBox("Import Complete! Your assets are now organized into subprojects by ability, with regions set up and ready for export.", "Success", 0) 
        
            elseif regions then
                DeleteAllTracks()
                import_selected_items_wwise()
                OrganizeByName()
                CreateSubprojectsWithRegions()
                reaper.ShowMessageBox("Import Complete! Your assets are now organized into subprojects by ability, with regions set up and ready for export.t", "Success", 0)
            elseif subprojects then 
                DeleteAllTracks()
                import_selected_items_wwise()
                OrganizeByName()
                CreateSubprojects()
                reaper.ShowMessageBox("Import Complete! Your assets are now organized into separate subprojects by ability", "Success", 0) -- "0" is OK button type
            else 
                DeleteAllTracks()
                import_selected_items_wwise()
                OrganizeByName()
                reaper.ShowMessageBox("Import Complete! Your assets are now organized into tracks by ability", "Success", 0) -- "0" is OK button type
            end
        
            reaper.Undo_EndBlock("Create Session", -1)
        end

        
        reaper.ImGui_PopStyleColor(ctx, 2) 

        reaper.ImGui_Dummy(ctx, 100, 0) -- Add space
        reaper.ImGui_SameLine(ctx, 210)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_Text(ctx, "developed by Michael Cheung")
        reaper.ImGui_PopFont(ctx) -- Restore to previous font

        reaper.ImGui_End(ctx)
    end
    
    -- demo.PopStyle(ctx) --- style editor
    PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
        reaper.defer(loop)
    end
end

function PushTheme()
    --style
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),          8)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),            3, 3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),           8)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),             8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),            3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextBorderSize(), 2)
    
    --colors 
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x2D2E3CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),       0x0A0A0ABB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x0A0A0AC1)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),     0x1E1E1ED8)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),          0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),   0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),    0x353645FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),    0x0A0A0AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),        0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),        0xEF4958FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),       0xF04A58FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), 0xF04A58FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),           0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),    0xAC373FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),     0xEF4958FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),           0xAC373FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),    0xAC373FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),     0xEF4958FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),        0x424242FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(),   0xAC373FFF)
end

function PopTheme()
    --style
    reaper.ImGui_PopStyleVar(ctx, 6)
    --color
    reaper.ImGui_PopStyleColor(ctx, 20)
end

::eof::

