--@noindex
--- Load Functions 
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
-- require('Functions/Takes Compiler Functions')
require('Functions/Copy Paste Selected Media Items')
require('Functions/Create Incremented Region')
require('Functions/Dynamic Split + Implode')


local ctx = reaper.ImGui_CreateContext('MC_Variation Generator Tool')
local window_name = ScriptName..' '..ScriptVersion
local guiW = 280
local guiH = 458
local font = reaper.ImGui_CreateFont('Cleon Sans', 12)
local menufont = reaper.ImGui_CreateFont('Cleon Sans', 22)
local buttonfont = reaper.ImGui_CreateFont('Cleon Sans', 18)
local font_small = reaper.ImGui_CreateFont('Cleon Sans', 9)
local font_presets = reaper.ImGui_CreateFont('Cleon Sans', 11)
local tooltip_font = reaper.ImGui_CreateFont('Cleon Sans', 12)
local pin = true
local FLOATMIN = reaper.ImGui_NumericLimits_Float() -- returns a very small number cslose to 0

-- local demo = require('Functions/ReaImGui_Demo1')

-- attaching font
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, font_small)
reaper.ImGui_Attach(ctx, font_presets)
reaper.ImGui_Attach(ctx, menufont) 
reaper.ImGui_Attach(ctx, buttonfont) 
reaper.ImGui_Attach(ctx, tooltip_font) 

function loop()
    PushTheme() --- push style theme 
    -- demo.PushStyle(ctx) -- style editor
    -- demo.ShowDemoWindow(ctx)
   
     -- Window settings
    local window_flags = reaper.ImGui_WindowFlags_MenuBar() | reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_TopMost() | reaper.ImGui_WindowFlags_NoScrollbar()
    if pin then 
        window_flags = window_flags | reaper.ImGui_WindowFlags_TopMost()
    end
      reaper.ImGui_SetNextWindowSize(ctx, guiW, guiH, reaper.ImGui_Cond_Once())

     -- Font 
     reaper.ImGui_PushFont(ctx, font)

     -- Begin
     local visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    if visible then
        -- Menu Bar
        reaper.ImGui_PushFont(ctx, font_presets)    
        if reaper.ImGui_BeginMenuBar(ctx) then 

            if reaper.ImGui_BeginMenu(ctx, 'Save Preset') then
                _, PresetName = reaper.GetUserInputs("Save Preset", 1, "Name:", "" )

                if PresetName ~= '' then
                    SavePreset(presets_path, PresetName)
                    PresetName = nil 
                else
                    reaper.ShowMessageBox('Name Invalid', 'Error', 0)
                end
                reaper.ImGui_EndMenu(ctx)
            end

            if reaper.ImGui_BeginMenu(ctx, 'Load Preset') then 
                presets_table = GetPreset(presets_path)
                for name, value in pairs(presets_table) do 
                    if reaper.ImGui_MenuItem(ctx, name.."##presetsmenuitem") then 
                        Settings = value 
                    end
                end

                reaper.ImGui_EndMenu(ctx)
            end

            local presets_table = GetPreset(presets_path) or {}
            if next(presets_table) then
                if reaper.ImGui_BeginMenu(ctx, 'Delete Preset') then 
                    for name, value in pairs(presets_table) do 
                        if reaper.ImGui_MenuItem(ctx, name.."##presetsmenuitem") then 
                            DeletePreset(presets_path, name)
                        end
                    end
                    reaper.ImGui_EndMenu(ctx)
                end
            end
            reaper.ImGui_EndMenuBar(ctx)
            reaper.ImGui_PopFont(ctx)     
        end

        reaper.ImGui_PushFont(ctx, menufont)
        reaper.ImGui_PushTextWrapPos(ctx, 0) 
        reaper.ImGui_Text(ctx, "MC_Variation Generator")
        reaper.ImGui_Dummy(ctx, 0, 1)
        reaper.ImGui_PopTextWrapPos(ctx)  
        reaper.ImGui_PopFont(ctx)

        -- Ui Body 
        reaper.ImGui_SeparatorText(ctx, 'Position')

        local slider_flags = reaper.ImGui_SliderFlags_AlwaysClamp() 
        -- | reaper.ImGui_SliderFlags_Logarithmic() 
       
        do
            local slider_min, slider_max = 0, 150
            local changed            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 5)
            changed, Settings.pos.range = reaper.ImGui_SliderDouble(
                ctx,
                '##pos',            
                Settings.pos.range or 0, 
                slider_min,              
                slider_max,              
                '%.0f ms',
                slider_flags
            )
            Settings.pos.min = -(Settings.pos.range or 0)
            Settings.pos.max =  (Settings.pos.range or 0)
        end

            reaper.ImGui_SeparatorText(ctx, 'Rate')

            do
                local slider_min = 1.0  -- Leftmost position = neutral (1.0x rate)
                local slider_max = 3.0
            
                -- Ensure valid initial value
                Settings.rate.range = Settings.rate.range or slider_min
            
                -- Prevent negative width
                reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 5)

                -- Slider returns changed, new_value
                local changed, new_range = reaper.ImGui_SliderDouble(ctx, '##rate',
                    Settings.rate.range,
                    slider_min, slider_max,
                    "%.1f x",  -- Format string to show multiplier with 3 decimal places
                    slider_flags
                )
            
                if changed then
                    -- Store the raw slider value
                    Settings.rate.range = new_range
            
                    -- Calculate min/max rates relative to neutral (1.0)
                    -- Example: if slider is at 1.5, you get rates from 0.67x to 1.5x
                    Settings.rate.min = 1 / Settings.rate.range  -- Reciprocal for logarithmic symmetry
                    Settings.rate.max = Settings.rate.range
            
                    -- Clamp minimum rate to prevent extreme values
                    Settings.rate.min = math.max(0.5, Settings.rate.min)
                end
            end        reaper.ImGui_SeparatorText(ctx, 'Pitch')
        do
            local slider_min, slider_max = 0, 12
            local changed

            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 5)
            changed, Settings.pitch.range = reaper.ImGui_SliderDouble(
                ctx,
                '##pitch',            
                Settings.pitch.range or 0, 
                slider_min,              
                slider_max,              
                '%.0f st',
                slider_flags
            )
            Settings.pitch.min = -(Settings.pitch.range or 0)
            Settings.pitch.max =  (Settings.pitch.range or 0)
        end        reaper.ImGui_SeparatorText(ctx, 'Volume')
        do
            local slider_min, slider_max = 0.0, 6.0
            local changed

            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 5)
            changed, Settings.vol.range = reaper.ImGui_SliderDouble(
                ctx,
                '##vol',            
                Settings.vol.range or 0, 
                slider_min,              
                slider_max,              
                '%.0f db',
                slider_flags
            )
            Settings.vol.min = -(Settings.vol.range or 0)
            Settings.vol.max =  (Settings.vol.range or 0)
        end
        
        reaper.ImGui_SeparatorText(ctx, 'Content')
        do
            local slider_min, slider_max = 0, 10
            local changed            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 5)
            changed, Settings.content.range = reaper.ImGui_SliderDouble(
                ctx,
                '##content',            
                Settings.content.range or 0, 
                slider_min,              
                slider_max,              
                '%.1f ms',
                slider_flags
            )
           
            Settings.content.min = -(Settings.content.range or 0)
            Settings.content.max =  (Settings.content.range or 0)
        end
        reaper.ImGui_SeparatorText(ctx, 'Takes')
        local _
        _, Settings.takes = reaper.ImGui_Checkbox(ctx, 'Randomize Takes', Settings.takes)

        reaper.ImGui_SameLine(ctx, 140)

        if reaper.ImGui_Button(ctx, 'Implode to Takes', 125, 25) then -- checks to see if user clicks the button, and will call function 
            reaper.Undo_BeginBlock()
            implode_takes()
            reaper.Undo_EndBlock("Implode to Takes", -1)
        end

        _, create_variation = reaper.ImGui_Checkbox(ctx, 'Create Variations?', create_variation)
        

        if create_variation then 
            reaper.ImGui_SameLine(ctx, 135)
            _, Settings.region = reaper.ImGui_Checkbox(ctx, 'Create Regions?', Settings.region)
            
        end

        reaper.ImGui_SeparatorText(ctx, '')

        local btn_text = create_variation and "Create Variations!" or "Randomize!"
        if reaper.ImGui_Button(ctx, btn_text,-FLOATMIN, 60) then
            if create_variation then 
                reaper.Undo_BeginBlock()
                Gettoptrack()
                if Settings.region then 
                    copy_selected_items_randomize_regions() -- seperate functions because of reselecting originals has to happen AFTER regions are created
                else
                    copy_selected_items_randomize()
                end
                reaper.Undo_EndBlock("Create Variations", -1)
            else
                reaper.Undo_BeginBlock()
                Gettoptrack()
                RandomizeSelectedItems(proj)
                reaper.Undo_EndBlock("Randomize!", -1)
            end
        end 

        reaper.ImGui_Dummy(ctx, 100, 0) 
        reaper.ImGui_SameLine(ctx, 160)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_Text(ctx, "developed by Michael Cheung")
        reaper.ImGui_PopFont(ctx)

        reaper.ImGui_End(ctx)
    end
    
    --  demo.PopStyle(ctx) --- style editor
    PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
        reaper.defer(loop)
    end
end

function PushTheme()
    --style
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_Alpha(),                       1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_DisabledAlpha(),               0.6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),               8, 8)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),              12)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(),            1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowMinSize(),               32, 32)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),            0, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),                3.5, 3.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),               4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),                 8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),            4, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_IndentSpacing(),               21)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),                 4, 2)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarSize(),               14)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(),           9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(),                 16)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),                6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(),                 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBorderSize(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBarBorderSize(),            1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersAngle(),     0.610865)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersTextAlign(), 0.5, 0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ButtonTextAlign(),             0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(),         0, 0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextBorderSize(),     1.8)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextAlign(),          0, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(),        20, 3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),        9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),         9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(), 19, 0)


    
    --colors 

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),                      0xFFFFFFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(),              0x808080FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),                  0x1A1A1AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(),                   0x00000000)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),                   0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),                    0x3A3737CC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(),              0x0000001A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),                   0x1F1F1FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),            0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),             0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),                   0x0A0A0ABB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),             0x0A0A0AC6)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(),          0x0A0A0AC7)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),                 0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),               0x1F1F1FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),             0x4F4F4FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(),      0x696969FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),       0x828282FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),                 0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),                0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),          0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),                    0x28289CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),             0x3434C7FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),              0x3434C7FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),                    0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),             0x28289CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),              0x28289CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),                 0x2A2A2AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(),          0x1A66BFC7)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(),           0x1A66BFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),                0x4296FA33)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),         0x4296FAAB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),          0x4296FAF2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),                0x4296FACC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),                       0x2E5994DC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(),               0x3369ADFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelectedOverline(),       0x4296FAFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmed(),                 0x111A26F8)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelected(),         0x23436CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelectedOverline(), 0x808080FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(),            0xAC373FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingEmptyBg(),            0x333333FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLines(),                 0x9C9C9CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLinesHovered(),          0xFF6E59FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(),             0xE6B300FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogramHovered(),      0xFF9900FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableHeaderBg(),             0x303033FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderStrong(),         0x4F4F59FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderLight(),          0x3B3B40FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBg(),                0x00000000)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBgAlt(),             0xFFFFFF0F)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),            0x4296FA59)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DragDropTarget(),            0xFFFF00E6)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavHighlight(),              0x4296FAFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingHighlight(),     0xFFFFFFB3)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingDimBg(),         0xCCCCCC33)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ModalWindowDimBg(),          0xCCCCCC59)

end

function PopTheme()
    --style
    reaper.ImGui_PopStyleVar(ctx, 35)
    --color
    reaper.ImGui_PopStyleColor(ctx, 57)
end
