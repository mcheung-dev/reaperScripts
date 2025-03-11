-- @noindex

--- Load Functions 
require('Functions/Replace')
require('Functions/Remove')
require('Functions/Insert')

local ctx = reaper.ImGui_CreateContext('mc_fastfilerenamer')
local window_name = "mc_FastFileRenamer"
local samelinespacing = 115
local inputboxwidth = 130
local font = reaper.ImGui_CreateFont('Cleon Sans', 14)
local menufont = reaper.ImGui_CreateFont('Cleon Sans ', 24)
local buttonfont = reaper.ImGui_CreateFont('Cleon Sans ', 18)
local font_small = reaper.ImGui_CreateFont('Cleon Sans ', 9)
local tooltip_font = reaper.ImGui_CreateFont('Cleon Sans ', 12)
local pin = true
local FLOATMIN = reaper.ImGui_NumericLimits_Float() -- returns a very small number close to 0
local selected_item = 2

local mode = 0  -- 0 = replace, 1 = remove, 2 = insert

local mode_heights = {
    [0] = 240,  -- height for Replace mode
    [1] = 215,  -- height for Remove mode
    [2] = 246   -- height for Insert mode
}

-- local demo = require('Functions/ReaImGui_Demo') 

-- attaching font
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, font_small) 
reaper.ImGui_Attach(ctx, menufont) 
reaper.ImGui_Attach(ctx, buttonfont) 
reaper.ImGui_Attach(ctx, tooltip_font) 

function loop()
    PushTheme() --- push style theme 

    -- demo.PushStyle(ctx) -- style editor
    -- demo.ShowDemoWindow(ctx)
   
     -- Window settings
    local window_flags = reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_TopMost() | reaper.ImGui_WindowFlags_NoScrollbar()
    if pin then 
        window_flags = window_flags | reaper.ImGui_WindowFlags_TopMost()
    end
     reaper.ImGui_SetNextWindowSize(ctx, 255, mode_heights[mode]) ------------- setting window height based off mode 

     -- Font 
     reaper.ImGui_PushFont(ctx, font)

     -- Begin
     local visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    if visible then

        function HoverTooltip(ctx, text)
              reaper.ImGui_SameLine(ctx, 0)
              reaper.ImGui_PushFont(ctx, tooltip_font)

              local gray = reaper.ImGui_ColorConvertDouble4ToU32(0.5, 0.5, 0.5, 1.0)
              reaper.ImGui_TextColored(ctx, gray, "?")


              reaper.ImGui_PopFont(ctx)
          
              if reaper.ImGui_IsItemHovered(ctx) then
                if reaper.ImGui_BeginTooltip(ctx) then
                  reaper.ImGui_Text(ctx, text)
                  reaper.ImGui_EndTooltip(ctx)
                end
              end
            
          end
          
        -- instructions  
        
        reaper.ImGui_PushFont(ctx, menufont)
        reaper.ImGui_PushTextWrapPos(ctx, 0) 
        reaper.ImGui_Text(ctx, "FastFileRenamer")
        reaper.ImGui_PopTextWrapPos(ctx)  
        reaper.ImGui_PopFont(ctx)


        HoverTooltip(ctx, 'This tool replicates the functionality of FastFileRenamer app,\nintegrated into the Reaper environment for seamless file renaming.')


        reaper.ImGui_Separator(ctx)

        reaper.ImGui_Spacing(ctx)

        if reaper.ImGui_RadioButton(ctx, 'Replace', mode == 0) then
            mode = 0
        end
        reaper.ImGui_SameLine(ctx, 175/2)
        if reaper.ImGui_RadioButton(ctx, 'Remove', mode == 1) then
            mode = 1
        end
        reaper.ImGui_SameLine(ctx, 175/2 + 175/2)
        if reaper.ImGui_RadioButton(ctx, 'Insert', mode == 2) then
            mode = 2
        end

        reaper.ImGui_Dummy(ctx, 5, 5) 


        -- UI for different modes (Replace, Remove, Insert)
        if mode == 0 then -----------------

            reaper.ImGui_Text(ctx, "Original Pattern:")
            reaper.ImGui_SameLine(ctx, samelinespacing)
            reaper.ImGui_SetNextItemWidth(ctx,inputboxwidth) --- change width
            retval, original_pattern = reaper.ImGui_InputTextMultiline(ctx, '##ogpattern', original_pattern, inputboxwidth, 23, reaper.ImGui_InputTextFlags_None())
            reaper.ImGui_Spacing(ctx)
    
            reaper.ImGui_Text(ctx, "New Pattern:")
            reaper.ImGui_SameLine(ctx, samelinespacing)
            reaper.ImGui_SetNextItemWidth(ctx,inputboxwidth)
            retval, new_pattern = reaper.ImGui_InputTextMultiline(ctx, '##newpattern', new_pattern, inputboxwidth, 23, reaper.ImGui_InputTextFlags_None())
            reaper.ImGui_Spacing(ctx)

        elseif mode == 1 then --------------------

            reaper.ImGui_Text(ctx, "Pattern to \nRemove:")
            reaper.ImGui_SameLine(ctx, samelinespacing)
            reaper.ImGui_SetNextItemWidth(ctx,inputboxwidth) --- change width
            retval, pattern_remove = reaper.ImGui_InputTextMultiline(ctx, '##ogpattern', pattern_remove, inputboxwidth, 23, reaper.ImGui_InputTextFlags_None())

            reaper.ImGui_Spacing(ctx)

        elseif mode == 2 then ----------------
            reaper.ImGui_Text(ctx, "Pattern to \nInsert:")
            reaper.ImGui_SameLine(ctx, samelinespacing)
            reaper.ImGui_SetNextItemWidth(ctx, inputboxwidth) --- change width
            retval, pattern_to_insert = reaper.ImGui_InputTextMultiline(ctx, '##pattern', pattern_to_insert, inputboxwidth, 23, reaper.ImGui_InputTextFlags_None())
            reaper.ImGui_Spacing(ctx) 

            local items = {"Before", "After",}
            reaper.ImGui_SetNextItemWidth(ctx, 80) 
            if reaper.ImGui_BeginCombo(ctx, "##n", items[selected_item]) then
                for i, item in ipairs(items) do
                    if reaper.ImGui_Selectable(ctx, item, selected_item == i) then
                        selected_item = i  -- Update the selected item
                    end
                end
                reaper.ImGui_EndCombo(ctx)
            end
            reaper.ImGui_SameLine(ctx, samelinespacing)
            reaper.ImGui_SetNextItemWidth(ctx, inputboxwidth) --- change width
            retval, insert_location = reaper.ImGui_InputText(ctx, '##insertlocation', insert_location, reaper.ImGui_InputTextFlags_None())
            reaper.ImGui_Spacing(ctx) 
        end
        -- reaper.ImGui_Spacing(ctx)
        --- Big Button ---------------------- 

        if reaper.ImGui_Button(ctx, 'Rename!', -FLOATMIN, 50) then
            if mode == 0 then 
                Replace(original_pattern, new_pattern)
            elseif mode == 1 then 
                Remove(pattern_remove)
            elseif mode == 2 then 
                if selected_item == 1 then 
                    InsertBefore(pattern_to_insert, insert_location)
                    
                elseif selected_item == 2 then 
                    InsertAfter(pattern_to_insert, insert_location)
                end
            end   
        end
       
        -- footer 
        reaper.ImGui_Dummy(ctx, 100, 80)
        reaper.ImGui_SameLine(ctx, 130)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_Text(ctx, "developed by Michael Cheung")
        reaper.ImGui_PopFont(ctx) 


        -- reaper.ImGui_PopStyleColor(ctx, 2) 
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
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),                3, 3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),               4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),                 8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),            4, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_IndentSpacing(),               21)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),                 4, 2)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarSize(),               14)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(),           9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(),                 12)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),                3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(),                 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBorderSize(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBarBorderSize(),            1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersAngle(),     0.610865)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersTextAlign(), 0.5, 0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ButtonTextAlign(),             0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(),         0, 0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextBorderSize(),     2)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextAlign(),          0, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(),        20, 3)
    
    
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
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),             0x353645FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),                   0x0A0A0ABB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),             0x0A0A0AC6)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(),          0x0A0A0AC7)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),                 0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),               0x1F1F1FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),             0x4F4F4FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(),      0x696969FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),       0x828282FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),                 0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),                0xF04A58FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),          0xF04A58FF)
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
    reaper.ImGui_PopStyleVar(ctx, 32)
    --color
    reaper.ImGui_PopStyleColor(ctx, 57)
end

