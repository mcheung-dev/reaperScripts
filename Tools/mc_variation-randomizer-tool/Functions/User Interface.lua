--- Load Functions 
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require('Functions/Takes Compiler Functions')
require('Functions/Copy Paste Selected Media Items')
require('Functions/Create Incremented Region')


local ctx = reaper.ImGui_CreateContext('MC_Variation Generator Tool')
local window_name = ScriptName..' '..ScriptVersion
local guiW = 300 
local guiH = 650
local font = reaper.ImGui_CreateFont('futura', 14)
local font_small = reaper.ImGui_CreateFont('futura', 10)
local pin = true
local FLOATMIN = reaper.ImGui_NumericLimits_Float() -- returns a very small number close to 0

--local demo = require('Functions/ReaImGui_Demo1') - style editor

-- attaching font
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, font_small) 

function loop()
    PushTheme() --- push style theme 
    --demo.PushStyle(ctx) -- style editor
    --demo.ShowDemoWindow(ctx)
   
     -- Window settings
    local window_flags = reaper.ImGui_WindowFlags_MenuBar() | reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_TopMost()
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
        if reaper.ImGui_BeginMenuBar(ctx) then 

            if reaper.ImGui_BeginMenu(ctx, 'Settings') then 
                reaper.ImGui_MenuItem(ctx, 'test')
                reaper.ImGui_EndMenu(ctx)
            end

            if reaper.ImGui_BeginMenu(ctx, 'Presets') then 
                reaper.ImGui_MenuItem(ctx, 'test')

                reaper.ImGui_EndMenu(ctx)
            end

            if reaper.ImGui_BeginMenu(ctx, 'About') then 
                reaper.ImGui_MenuItem(ctx, 'This is a tool developed to')
                reaper.ImGui_EndMenu(ctx)
            end
            local _
            _, pin = reaper.ImGui_MenuItem(ctx, 'Pin', nil, pin)
            reaper.ImGui_EndMenuBar(ctx)
        end

        -- Ui Body 
        reaper.ImGui_SeparatorText(ctx, 'Position')
        do
            local min_pos = -200        
            local max_pos = 200
            local changemin, changemax 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25)
            changemin, Settings.pos.min = reaper.ImGui_SliderDouble(ctx, 'Min##pos', Settings.pos.min, min_pos, max_pos, '%.0f ms')-- need to add ## to differentiate duplicate strings, or else imgui will go crazy
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25)
            changemax, Settings.pos.max = reaper.ImGui_SliderDouble(ctx, 'Max##pos', Settings.pos.max, min_pos, max_pos, '%.0f ms')
            if changemin and Settings.pos.min > Settings.pos.max then 
                Settings.pos.max = Settings.pos.min
            elseif changemax and Settings.pos.max < Settings.pos.min then 
                Settings.pos.min = Settings.pos.max         
            end
        end

        reaper.ImGui_SeparatorText(ctx, 'Rate')
        do
            small_value = 0.00001
            local min_rate = 0.1
            local max_rate = 2
            local changemin, changemax 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25) -- setting window size 
            changemin, Settings.rate.min = reaper.ImGui_SliderDouble(ctx, 'Min##rate', Settings.rate.min, min_rate, max_rate, '%.2f') 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25)
            changemax, Settings.rate.max = reaper.ImGui_SliderDouble(ctx, 'Max##rate', Settings.rate.max, min_rate, max_rate, '%.2f')
            if changemin then 
                Settings.rate.min = ((Settings.rate.min > 0) and Settings.rate.min) or small_value -- checking to make sure rate can never be 0
                if changemin and Settings.rate.min > Settings.rate.max then 
                    Settings.rate.max = Settings.rate.min
                end
            elseif changemax then 
                Settings.rate.max = ((Settings.rate.max > 0) and Settings.rate.max) or small_value
                if Settings.rate.max < Settings.rate.min then 
                Settings.rate.min = Settings.rate.max         
                end
            end
        end

        reaper.ImGui_SeparatorText(ctx, 'Pitch')
        do
            small_value = 0.00001
            local min_pitch = -12
            local max_pitch = 12
            local changemin, changemax 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25) -- setting window size 
            changemin, Settings.pitch.min = reaper.ImGui_SliderDouble(ctx, 'Min##pitch', Settings.pitch.min, min_pitch, max_pitch, '%.0f st') 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25)
            changemax, Settings.pitch.max = reaper.ImGui_SliderDouble(ctx, 'Max##pitch', Settings.pitch.max, min_pitch, max_pitch, '%.0f st')
            if changemin and Settings.pitch.min > Settings.pitch.max then 
                    Settings.pitch.max = Settings.pitch.min
            elseif changemax and Settings.pitch.max < Settings.pitch.min then 
                Settings.pitch.min = Settings.pitch.max         
            end
        end

        reaper.ImGui_SeparatorText(ctx, 'Volume')
        do
            small_value = 0.00001
            local min_vol = -12
            local max_vol = 12
            local changemin, changemax 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25) -- setting window size 
            changemin, Settings.vol.min = reaper.ImGui_SliderDouble(ctx, 'Min##vol', Settings.vol.min, min_vol, max_vol, '%.1f dB') 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25)
            changemax, Settings.vol.max = reaper.ImGui_SliderDouble(ctx, 'Max##vol', Settings.vol.max, min_vol, max_vol, '%.1f dB')
            if changemin and Settings.vol.min > Settings.vol.max then 
                    Settings.vol.max = Settings.vol.min
            elseif changemax and Settings.vol.max < Settings.vol.min then 
                Settings.vol.min = Settings.vol.max         
            end
        end
        
        reaper.ImGui_SeparatorText(ctx, 'Content')
        do
            small_value = 0.00001
            local min_cont = -10
            local max_cont = 10
            local changemin, changemax 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25) -- setting window size 
            changemin, Settings.content.min = reaper.ImGui_SliderDouble(ctx, 'Min##cont', Settings.content.min, min_cont, max_cont, '%.1f s') 
            reaper.ImGui_SetNextItemWidth(ctx, FLOATMIN - 25)
            changemax, Settings.content.max = reaper.ImGui_SliderDouble(ctx, 'Max##ImGui_CreateContext', Settings.content.max, min_cont, max_cont, '%.1f s')
            if changemin and Settings.content.min > Settings.content.max then 
                    Settings.content.max = Settings.content.min
            elseif changemax and Settings.content.max < Settings.content.min then 
                Settings.content.min = Settings.content.max         
            end
        end
        
        reaper.ImGui_SeparatorText(ctx, 'Takes')
        local _
        _, Settings.takes = reaper.ImGui_Checkbox(ctx, 'Randomize Takes', Settings.takes)

        reaper.ImGui_SameLine(ctx)

        if reaper.ImGui_Button(ctx, 'Implode to Takes', 0, 30) then -- checks to see if user clicks the button, and will call function 
            reaper.Undo_BeginBlock()
            CompileTakes()
            reaper.Undo_EndBlock("Implode to Takes", -1)
        end

        
        _, Settings.region = reaper.ImGui_Checkbox(ctx, 'Create Regions', Settings.region)
 
        if reaper.ImGui_Button(ctx, 'Duplicate Items', (-FLOATMIN/2), 30) then -- -FLOATMIN, 50
            reaper.Undo_BeginBlock()
            Gettoptrack()
            copy_selected_items()
            if Settings.region then 
                CreateIncrementedRegion()
            end
            reaper.Undo_EndBlock("Duplicate Items", -1)
        end 

        reaper.ImGui_SameLine(ctx)

        if reaper.ImGui_Button(ctx, 'Randomize Items', (-FLOATMIN/2), 30) then -- -FLOATMIN, 50
            reaper.Undo_BeginBlock()
            
            RandomizeSelectedItems(proj)
            reaper.Undo_EndBlock("Randomize Items", -1)
        end 

        reaper.ImGui_SeparatorText(ctx, '')


        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xAC373FFF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xEF4958FF)

        if reaper.ImGui_Button(ctx, 'Create Variations',-FLOATMIN, 50) then
            reaper.Undo_BeginBlock()
            Gettoptrack()
            if Settings.region then 
                copy_selected_items_randomize_regions() -- seperate functions because of reselecting originals has to happen AFTER regions are created
            else
                copy_selected_items_randomize()
            end
            reaper.Undo_EndBlock("Create Variations", -1)
        end 
        reaper.ImGui_PopStyleColor(ctx, 2) 

        reaper.ImGui_Dummy(ctx, 100, 0) -- Add space
        reaper.ImGui_SameLine(ctx, 160)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_Text(ctx, "developed by Michael Cheung")
        reaper.ImGui_PopFont(ctx) -- Restore to previous f

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