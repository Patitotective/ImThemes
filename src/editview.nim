import std/[strformat, strutils, tables]
import chroma
import niprefs
import imstyle
import nimgl/[imgui, glfw]

import editor, icons, utils

type
  ExportKind = enum
    Nim, Cpp

const
  nimExportTemplate = """
proc setupIgStyle() = 
  # $name style by $author from ImThemes
  let style = igGetStyle()
  
  style.alpha = $alpha
  style.disabledAlpha = $disabledAlpha
  style.windowPadding = $windowPadding
  style.windowRounding = $windowRounding
  style.windowBorderSize = $windowBorderSize
  style.windowMinSize = $windowMinSize
  style.windowTitleAlign = $windowTitleAlign
  style.windowMenuButtonPosition = $windowMenuButtonPosition
  style.childRounding = $childRounding
  style.childBorderSize = $childBorderSize
  style.popupRounding = $popupRounding
  style.popupBorderSize = $popupBorderSize
  style.framePadding = $framePadding
  style.frameRounding = $frameRounding
  style.frameBorderSize = $frameBorderSize
  style.itemSpacing = $itemSpacing
  style.itemInnerSpacing = $itemInnerSpacing
  style.cellPadding = $cellPadding
  style.indentSpacing = $indentSpacing
  style.columnsMinSpacing = $columnsMinSpacing
  style.scrollbarSize = $scrollbarSize
  style.scrollbarRounding = $scrollbarRounding
  style.grabMinSize = $grabMinSize
  style.grabRounding = $grabRounding
  style.tabRounding = $tabRounding
  style.tabBorderSize = $tabBorderSize
  style.tabMinWidthForCloseButton = $tabMinWidthForCloseButton
  style.colorButtonPosition = $colorButtonPosition
  style.buttonTextAlign = $buttonTextAlign
  style.selectableTextAlign = $selectableTextAlign

  style.colors[ord ImGuiCol.Text] = $Text
  style.colors[ord ImGuiCol.TextDisabled] = $TextDisabled
  style.colors[ord ImGuiCol.WindowBg] = $WindowBg
  style.colors[ord ImGuiCol.ChildBg] = $ChildBg
  style.colors[ord ImGuiCol.PopupBg] = $PopupBg
  style.colors[ord ImGuiCol.Border] = $Border
  style.colors[ord ImGuiCol.BorderShadow] = $BorderShadow
  style.colors[ord ImGuiCol.FrameBg] = $FrameBg
  style.colors[ord ImGuiCol.FrameBgHovered] = $FrameBgHovered
  style.colors[ord ImGuiCol.FrameBgActive] = $FrameBgActive
  style.colors[ord ImGuiCol.TitleBg] = $TitleBg
  style.colors[ord ImGuiCol.TitleBgActive] = $TitleBgActive
  style.colors[ord ImGuiCol.TitleBgCollapsed] = $TitleBgCollapsed
  style.colors[ord ImGuiCol.MenuBarBg] = $MenuBarBg
  style.colors[ord ImGuiCol.ScrollbarBg] = $ScrollbarBg
  style.colors[ord ImGuiCol.ScrollbarGrab] = $ScrollbarGrab
  style.colors[ord ImGuiCol.ScrollbarGrabHovered] = $ScrollbarGrabHovered
  style.colors[ord ImGuiCol.ScrollbarGrabActive] = $ScrollbarGrabActive
  style.colors[ord ImGuiCol.CheckMark] = $CheckMark
  style.colors[ord ImGuiCol.SliderGrab] = $SliderGrab
  style.colors[ord ImGuiCol.SliderGrabActive] = $SliderGrabActive
  style.colors[ord ImGuiCol.Button] = $Button
  style.colors[ord ImGuiCol.ButtonHovered] = $ButtonHovered
  style.colors[ord ImGuiCol.ButtonActive] = $ButtonActive
  style.colors[ord ImGuiCol.Header] = $Header
  style.colors[ord ImGuiCol.HeaderHovered] = $HeaderHovered
  style.colors[ord ImGuiCol.HeaderActive] = $HeaderActive
  style.colors[ord ImGuiCol.Separator] = $Separator
  style.colors[ord ImGuiCol.SeparatorHovered] = $SeparatorHovered
  style.colors[ord ImGuiCol.SeparatorActive] = $SeparatorActive
  style.colors[ord ImGuiCol.ResizeGrip] = $ResizeGrip
  style.colors[ord ImGuiCol.ResizeGripHovered] = $ResizeGripHovered
  style.colors[ord ImGuiCol.ResizeGripActive] = $ResizeGripActive
  style.colors[ord ImGuiCol.Tab] = $Tab
  style.colors[ord ImGuiCol.TabHovered] = $TabHovered
  style.colors[ord ImGuiCol.TabActive] = $TabActive
  style.colors[ord ImGuiCol.TabUnfocused] = $TabUnfocused
  style.colors[ord ImGuiCol.TabUnfocusedActive] = $TabUnfocusedActive
  style.colors[ord ImGuiCol.PlotLines] = $PlotLines
  style.colors[ord ImGuiCol.PlotLinesHovered] = $PlotLinesHovered
  style.colors[ord ImGuiCol.PlotHistogram] = $PlotHistogram
  style.colors[ord ImGuiCol.PlotHistogramHovered] = $PlotHistogramHovered
  style.colors[ord ImGuiCol.TableHeaderBg] = $TableHeaderBg
  style.colors[ord ImGuiCol.TableBorderStrong] = $TableBorderStrong
  style.colors[ord ImGuiCol.TableBorderLight] = $TableBorderLight
  style.colors[ord ImGuiCol.TableRowBg] = $TableRowBg
  style.colors[ord ImGuiCol.TableRowBgAlt] = $TableRowBgAlt
  style.colors[ord ImGuiCol.TextSelectedBg] = $TextSelectedBg
  style.colors[ord ImGuiCol.DragDropTarget] = $DragDropTarget
  style.colors[ord ImGuiCol.NavHighlight] = $NavHighlight
  style.colors[ord ImGuiCol.NavWindowingHighlight] = $NavWindowingHighlight
  style.colors[ord ImGuiCol.NavWindowingDimBg] = $NavWindowingDimBg
  style.colors[ord ImGuiCol.ModalWindowDimBg] = $ModalWindowDimBg
"""
  cppExportTemplate = """
void SetupImGuiStyle()
{
  // $name style by $author from ImThemes
  ImGuiStyle& style = igGetStyle();
  
  style.Alpha = $alpha;
  style.DisabledAlpha = $disabledAlpha;
  style.WindowPadding = $windowPadding;
  style.WindowRounding = $windowRounding;
  style.WindowBorderSize = $windowBorderSize;
  style.WindowMinSize = $windowMinSize;
  style.WindowTitleAlign = $windowTitleAlign;
  style.WindowMenuButtonPosition = $windowMenuButtonPosition;
  style.ChildRounding = $childRounding;
  style.ChildBorderSize = $childBorderSize;
  style.PopupRounding = $popupRounding;
  style.PopupBorderSize = $popupBorderSize;
  style.FramePadding = $framePadding;
  style.FrameRounding = $frameRounding;
  style.FrameBorderSize = $frameBorderSize;
  style.ItemSpacing = $itemSpacing;
  style.ItemInnerSpacing = $itemInnerSpacing;
  style.CellPadding = $cellPadding;
  style.IndentSpacing = $indentSpacing;
  style.ColumnsMinSpacing = $columnsMinSpacing;
  style.ScrollbarSize = $scrollbarSize;
  style.ScrollbarRounding = $scrollbarRounding;
  style.GrabMinSize = $grabMinSize;
  style.GrabRounding = $grabRounding;
  style.TabRounding = $tabRounding;
  style.TabBorderSize = $tabBorderSize;
  style.TabMinWidthForCloseButton = $tabMinWidthForCloseButton;
  style.ColorButtonPosition = $colorButtonPosition;
  style.ButtonTextAlign = $buttonTextAlign;
  style.SelectableTextAlign = $selectableTextAlign;

  style.Colors[ImGuiCol_Text] = $Text;
  style.Colors[ImGuiCol_TextDisabled] = $TextDisabled;
  style.Colors[ImGuiCol_WindowBg] = $WindowBg;
  style.Colors[ImGuiCol_ChildBg] = $ChildBg;
  style.Colors[ImGuiCol_PopupBg] = $PopupBg;
  style.Colors[ImGuiCol_Border] = $Border;
  style.Colors[ImGuiCol_BorderShadow] = $BorderShadow;
  style.Colors[ImGuiCol_FrameBg] = $FrameBg;
  style.Colors[ImGuiCol_FrameBgHovered] = $FrameBgHovered;
  style.Colors[ImGuiCol_FrameBgActive] = $FrameBgActive;
  style.Colors[ImGuiCol_TitleBg] = $TitleBg;
  style.Colors[ImGuiCol_TitleBgActive] = $TitleBgActive;
  style.Colors[ImGuiCol_TitleBgCollapsed] = $TitleBgCollapsed;
  style.Colors[ImGuiCol_MenuBarBg] = $MenuBarBg;
  style.Colors[ImGuiCol_ScrollbarBg] = $ScrollbarBg;
  style.Colors[ImGuiCol_ScrollbarGrab] = $ScrollbarGrab;
  style.Colors[ImGuiCol_ScrollbarGrabHovered] = $ScrollbarGrabHovered;
  style.Colors[ImGuiCol_ScrollbarGrabActive] = $ScrollbarGrabActive;
  style.Colors[ImGuiCol_CheckMark] = $CheckMark;
  style.Colors[ImGuiCol_SliderGrab] = $SliderGrab;
  style.Colors[ImGuiCol_SliderGrabActive] = $SliderGrabActive;
  style.Colors[ImGuiCol_Button] = $Button;
  style.Colors[ImGuiCol_ButtonHovered] = $ButtonHovered;
  style.Colors[ImGuiCol_ButtonActive] = $ButtonActive;
  style.Colors[ImGuiCol_Header] = $Header;
  style.Colors[ImGuiCol_HeaderHovered] = $HeaderHovered;
  style.Colors[ImGuiCol_HeaderActive] = $HeaderActive;
  style.Colors[ImGuiCol_Separator] = $Separator;
  style.Colors[ImGuiCol_SeparatorHovered] = $SeparatorHovered;
  style.Colors[ImGuiCol_SeparatorActive] = $SeparatorActive;
  style.Colors[ImGuiCol_ResizeGrip] = $ResizeGrip;
  style.Colors[ImGuiCol_ResizeGripHovered] = $ResizeGripHovered;
  style.Colors[ImGuiCol_ResizeGripActive] = $ResizeGripActive;
  style.Colors[ImGuiCol_Tab] = $Tab;
  style.Colors[ImGuiCol_TabHovered] = $TabHovered;
  style.Colors[ImGuiCol_TabActive] = $TabActive;
  style.Colors[ImGuiCol_TabUnfocused] = $TabUnfocused;
  style.Colors[ImGuiCol_TabUnfocusedActive] = $TabUnfocusedActive;
  style.Colors[ImGuiCol_PlotLines] = $PlotLines;
  style.Colors[ImGuiCol_PlotLinesHovered] = $PlotLinesHovered;
  style.Colors[ImGuiCol_PlotHistogram] = $PlotHistogram;
  style.Colors[ImGuiCol_PlotHistogramHovered] = $PlotHistogramHovered;
  style.Colors[ImGuiCol_TableHeaderBg] = $TableHeaderBg;
  style.Colors[ImGuiCol_TableBorderStrong] = $TableBorderStrong;
  style.Colors[ImGuiCol_TableBorderLight] = $TableBorderLight;
  style.Colors[ImGuiCol_TableRowBg] = $TableRowBg;
  style.Colors[ImGuiCol_TableRowBgAlt] = $TableRowBgAlt;
  style.Colors[ImGuiCol_TextSelectedBg] = $TextSelectedBg;
  style.Colors[ImGuiCol_DragDropTarget] = $DragDropTarget;
  style.Colors[ImGuiCol_NavHighlight] = $NavHighlight;
  style.Colors[ImGuiCol_NavWindowingHighlight] = $NavWindowingHighlight;
  style.Colors[ImGuiCol_NavWindowingDimBg] = $NavWindowingDimBg;
  style.Colors[ImGuiCol_ModalWindowDimBg] = $ModalWindowDimBg;
}
"""
let classicTheme* = toToml {
  name: "Classic", 
  author: "Default", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledalpha": 0.6000000238418579, "windowPadding": @[8.0, 8.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.0, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[4.0, 3.0], "frameRounding": 0.0, "frameBorderSize": 0.0, "itemspacing": @[8.0, 4.0], "iteminnerspacing": @[4.0, 4.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 21.0, "columnsminspacing": 6.0, "scrollbarSize": 14.0, "scrollbarRounding": 9.0, "grabMinSize": 10.0, "grabRounding": 0.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 0.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 3.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(229, 229, 229, 1.0)", "TextDisabled": "rgba(153, 153, 153, 1.0)", "WindowBg": "rgba(0, 0, 0, 0.8500000238418579)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(28, 28, 35, 0.9200000166893005)", "Border": "rgba(127, 127, 127, 0.5)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(109, 109, 109, 0.3899999856948853)", "FrameBgHovered": "rgba(119, 119, 175, 0.4000000059604645)", "FrameBgActive": "rgba(107, 104, 163, 0.6899999976158142)", "TitleBg": "rgba(68, 68, 137, 0.8299999833106995)", "TitleBgActive": "rgba(81, 81, 160, 0.8700000047683716)", "TitleBgCollapsed": "rgba(102, 102, 204, 0.2000000029802322)", "MenuBarBg": "rgba(102, 102, 140, 0.800000011920929)", "ScrollbarBg": "rgba(51, 63, 76, 0.6000000238418579)", "ScrollbarGrab": "rgba(102, 102, 204, 0.300000011920929)", "ScrollbarGrabHovered": "rgba(102, 102, 204, 0.4000000059604645)", "ScrollbarGrabActive": "rgba(104, 99, 204, 0.6000000238418579)", "Checkmark": "rgba(229, 229, 229, 0.5)", "Slidergrab": "rgba(255, 255, 255, 0.300000011920929)", "SlidergrabActive": "rgba(104, 99, 204, 0.6000000238418579)", "Button": "rgba(89, 102, 155, 0.6200000047683716)", "ButtonHovered": "rgba(102, 122, 181, 0.7900000214576721)", "ButtonActive": "rgba(117, 137, 204, 1.0)", "Header": "rgba(102, 102, 229, 0.449999988079071)", "HeaderHovered": "rgba(114, 114, 229, 0.800000011920929)", "HeaderActive": "rgba(135, 135, 221, 0.800000011920929)", "Separator": "rgba(127, 127, 127, 0.6000000238418579)", "SeparatorHovered": "rgba(153, 153, 178, 1.0)", "SeparatorActive": "rgba(178, 178, 229, 1.0)", "ResizeGrip": "rgba(255, 255, 255, 0.1000000014901161)", "ResizeGripHovered": "rgba(198, 209, 255, 0.6000000238418579)", "ResizeGripActive": "rgba(198, 209, 255, 0.8999999761581421)", "Tab": "rgba(85, 85, 174, 0.7860000133514404)", "TabHovered": "rgba(114, 114, 229, 0.800000011920929)", "TabActive": "rgba(103, 103, 185, 0.8420000076293945)", "TabUnfocused": "rgba(72, 72, 145, 0.8212000131607056)", "TabUnfocusedActive": "rgba(89, 89, 166, 0.8371999859809875)", "PlotLines": "rgba(255, 255, 255, 1.0)", "PlotLinesHovered": "rgba(229, 178, 0, 1.0)", "PlotHistogram": "rgba(229, 178, 0, 1.0)", "PlotHistogramHovered": "rgba(255, 153, 0, 1.0)", "TableHeaderBg": "rgba(68, 68, 96, 1.0)", "TableBorderStrong": "rgba(79, 79, 114, 1.0)", "TableBorderLight": "rgba(66, 66, 71, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(255, 255, 255, 0.07000000029802322)", "TextSelectedBg": "rgba(0, 0, 255, 0.3499999940395355)", "DragDropTarget": "rgba(255, 255, 0, 0.8999999761581421)", "NavHighlight": "rgba(114, 114, 229, 0.800000011920929)", "NavWindowingHighlight": "rgba(255, 255, 255, 0.699999988079071)", "NavWindowingDimBg": "rgba(204, 204, 204, 0.2000000029802322)", "ModalWindowDimBg": "rgba(51, 51, 51, 0.3499999940395355)"}}
} 
let darkTheme* = toToml {
  name: "Dark", 
  author: "Default", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledalpha": 0.6000000238418579, "windowPadding": @[8.0, 8.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.0, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[4.0, 3.0], "frameRounding": 0.0, "frameBorderSize": 0.0, "itemspacing": @[8.0, 4.0], "iteminnerspacing": @[4.0, 4.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 21.0, "columnsminspacing": 6.0, "scrollbarSize": 14.0, "scrollbarRounding": 9.0, "grabMinSize": 10.0, "grabRounding": 0.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 0.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 3.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(255, 255, 255, 1.0)", "TextDisabled": "rgba(127, 127, 127, 1.0)", "WindowBg": "rgba(15, 15, 15, 0.9399999976158142)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(20, 20, 20, 0.9399999976158142)", "Border": "rgba(109, 109, 127, 0.5)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(40, 73, 122, 0.5400000214576721)", "FrameBgHovered": "rgba(66, 150, 249, 0.4000000059604645)", "FrameBgActive": "rgba(66, 150, 249, 0.6700000166893005)", "TitleBg": "rgba(10, 10, 10, 1.0)", "TitleBgActive": "rgba(40, 73, 122, 1.0)", "TitleBgCollapsed": "rgba(0, 0, 0, 0.5099999904632568)", "MenuBarBg": "rgba(35, 35, 35, 1.0)", "ScrollbarBg": "rgba(5, 5, 5, 0.5299999713897705)", "ScrollbarGrab": "rgba(79, 79, 79, 1.0)", "ScrollbarGrabHovered": "rgba(104, 104, 104, 1.0)", "ScrollbarGrabActive": "rgba(130, 130, 130, 1.0)", "Checkmark": "rgba(66, 150, 249, 1.0)", "Slidergrab": "rgba(61, 132, 224, 1.0)", "SlidergrabActive": "rgba(66, 150, 249, 1.0)", "Button": "rgba(66, 150, 249, 0.4000000059604645)", "ButtonHovered": "rgba(66, 150, 249, 1.0)", "ButtonActive": "rgba(15, 135, 249, 1.0)", "Header": "rgba(66, 150, 249, 0.3100000023841858)", "HeaderHovered": "rgba(66, 150, 249, 0.800000011920929)", "HeaderActive": "rgba(66, 150, 249, 1.0)", "Separator": "rgba(109, 109, 127, 0.5)", "SeparatorHovered": "rgba(25, 102, 191, 0.7799999713897705)", "SeparatorActive": "rgba(25, 102, 191, 1.0)", "ResizeGrip": "rgba(66, 150, 249, 0.2000000029802322)", "ResizeGripHovered": "rgba(66, 150, 249, 0.6700000166893005)", "ResizeGripActive": "rgba(66, 150, 249, 0.949999988079071)", "Tab": "rgba(45, 89, 147, 0.8619999885559082)", "TabHovered": "rgba(66, 150, 249, 0.800000011920929)", "TabActive": "rgba(50, 104, 173, 1.0)", "TabUnfocused": "rgba(17, 26, 37, 0.9724000096321106)", "TabUnfocusedActive": "rgba(34, 66, 108, 1.0)", "PlotLines": "rgba(155, 155, 155, 1.0)", "PlotLinesHovered": "rgba(255, 109, 89, 1.0)", "PlotHistogram": "rgba(229, 178, 0, 1.0)", "PlotHistogramHovered": "rgba(255, 153, 0, 1.0)", "TableHeaderBg": "rgba(48, 48, 51, 1.0)", "TableBorderStrong": "rgba(79, 79, 89, 1.0)", "TableBorderLight": "rgba(58, 58, 63, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(255, 255, 255, 0.05999999865889549)", "TextSelectedBg": "rgba(66, 150, 249, 0.3499999940395355)", "DragDropTarget": "rgba(255, 255, 0, 0.8999999761581421)", "NavHighlight": "rgba(66, 150, 249, 1.0)", "NavWindowingHighlight": "rgba(255, 255, 255, 0.699999988079071)", "NavWindowingDimBg": "rgba(204, 204, 204, 0.2000000029802322)", "ModalWindowDimBg": "rgba(204, 204, 204, 0.3499999940395355)"}}
}
let lightTheme* = toToml {
  name: "Light", 
  author: "Default", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledalpha": 0.6000000238418579, "windowPadding": @[8.0, 8.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.0, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[4.0, 3.0], "frameRounding": 0.0, "frameBorderSize": 0.0, "itemspacing": @[8.0, 4.0], "iteminnerspacing": @[4.0, 4.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 21.0, "columnsminspacing": 6.0, "scrollbarSize": 14.0, "scrollbarRounding": 9.0, "grabMinSize": 10.0, "grabRounding": 0.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 0.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 3.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(0, 0, 0, 1.0)", "TextDisabled": "rgba(153, 153, 153, 1.0)", "WindowBg": "rgba(239, 239, 239, 1.0)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(255, 255, 255, 0.9800000190734863)", "Border": "rgba(0, 0, 0, 0.300000011920929)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(255, 255, 255, 1.0)", "FrameBgHovered": "rgba(66, 150, 249, 0.4000000059604645)", "FrameBgActive": "rgba(66, 150, 249, 0.6700000166893005)", "TitleBg": "rgba(244, 244, 244, 1.0)", "TitleBgActive": "rgba(209, 209, 209, 1.0)", "TitleBgCollapsed": "rgba(255, 255, 255, 0.5099999904632568)", "MenuBarBg": "rgba(219, 219, 219, 1.0)", "ScrollbarBg": "rgba(249, 249, 249, 0.5299999713897705)", "ScrollbarGrab": "rgba(175, 175, 175, 0.800000011920929)", "ScrollbarGrabHovered": "rgba(124, 124, 124, 0.800000011920929)", "ScrollbarGrabActive": "rgba(124, 124, 124, 1.0)", "Checkmark": "rgba(66, 150, 249, 1.0)", "Slidergrab": "rgba(66, 150, 249, 0.7799999713897705)", "SlidergrabActive": "rgba(117, 137, 204, 0.6000000238418579)", "Button": "rgba(66, 150, 249, 0.4000000059604645)", "ButtonHovered": "rgba(66, 150, 249, 1.0)", "ButtonActive": "rgba(15, 135, 249, 1.0)", "Header": "rgba(66, 150, 249, 0.3100000023841858)", "HeaderHovered": "rgba(66, 150, 249, 0.800000011920929)", "HeaderActive": "rgba(66, 150, 249, 1.0)", "Separator": "rgba(99, 99, 99, 0.6200000047683716)", "SeparatorHovered": "rgba(35, 112, 204, 0.7799999713897705)", "SeparatorActive": "rgba(35, 112, 204, 1.0)", "ResizeGrip": "rgba(89, 89, 89, 0.1700000017881393)", "ResizeGripHovered": "rgba(66, 150, 249, 0.6700000166893005)", "ResizeGripActive": "rgba(66, 150, 249, 0.949999988079071)", "Tab": "rgba(194, 203, 213, 0.9309999942779541)", "TabHovered": "rgba(66, 150, 249, 0.800000011920929)", "TabActive": "rgba(151, 185, 225, 1.0)", "TabUnfocused": "rgba(234, 236, 238, 0.9861999750137329)", "TabUnfocusedActive": "rgba(189, 209, 233, 1.0)", "PlotLines": "rgba(99, 99, 99, 1.0)", "PlotLinesHovered": "rgba(255, 109, 89, 1.0)", "PlotHistogram": "rgba(229, 178, 0, 1.0)", "PlotHistogramHovered": "rgba(255, 114, 0, 1.0)", "TableHeaderBg": "rgba(198, 221, 249, 1.0)", "TableBorderStrong": "rgba(145, 145, 163, 1.0)", "TableBorderLight": "rgba(173, 173, 188, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(76, 76, 76, 0.09000000357627869)", "TextSelectedBg": "rgba(66, 150, 249, 0.3499999940395355)", "DragDropTarget": "rgba(66, 150, 249, 0.949999988079071)", "NavHighlight": "rgba(66, 150, 249, 0.800000011920929)", "NavWindowingHighlight": "rgba(178, 178, 178, 0.699999988079071)", "NavWindowingDimBg": "rgba(51, 51, 51, 0.2000000029802322)", "ModalWindowDimBg": "rgba(51, 51, 51, 0.3499999940395355)"}}
}
let cherryTheme* = toToml {
  name: "Cherry", 
  author: "r-lyeh", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledAlpha": 0.6000000238418579, "windowPadding": @[6.0, 3.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.5, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[5.0, 1.0], "frameRounding": 3.0, "frameBorderSize": 1.0, "itemspacing": @[7.0, 1.0], "iteminnerspacing": @[1.0, 1.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 6.0, "columnsminspacing": 6.0, "scrollbarSize": 13.0, "scrollbarRounding": 16.0, "grabMinSize": 20.0, "grabRounding": 2.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 1.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 0.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(219, 237, 226, 0.8799999952316284)", "TextDisabled": "rgba(219, 237, 226, 0.2800000011920929)", "WindowBg": "rgba(33, 35, 43, 1.0)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(51, 56, 68, 0.8999999761581421)", "Border": "rgba(137, 122, 65, 0.1620000004768372)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(51, 56, 68, 1.0)", "FrameBgHovered": "rgba(116, 50, 76, 0.7799999713897705)", "FrameBgActive": "rgba(116, 50, 76, 1.0)", "TitleBg": "rgba(59, 51, 69, 1.0)", "TitleBgActive": "rgba(128, 19, 65, 1.0)", "TitleBgCollapsed": "rgba(51, 56, 68, 0.75)", "MenuBarBg": "rgba(51, 56, 68, 0.4699999988079071)", "ScrollbarBg": "rgba(51, 56, 68, 1.0)", "ScrollbarGrab": "rgba(22, 38, 40, 1.0)", "ScrollbarGrabHovered": "rgba(116, 50, 76, 0.7799999713897705)", "ScrollbarGrabActive": "rgba(116, 50, 76, 1.0)", "Checkmark": "rgba(181, 56, 68, 1.0)", "Slidergrab": "rgba(119, 196, 211, 0.1400000005960464)", "SlidergrabActive": "rgba(181, 56, 68, 1.0)", "Button": "rgba(119, 196, 211, 0.1400000005960464)", "ButtonHovered": "rgba(116, 50, 76, 0.8600000143051147)", "ButtonActive": "rgba(116, 50, 76, 1.0)", "Header": "rgba(116, 50, 76, 0.7599999904632568)", "HeaderHovered": "rgba(116, 50, 76, 0.8600000143051147)", "HeaderActive": "rgba(128, 19, 65, 1.0)", "Separator": "rgba(109, 109, 127, 0.5)", "SeparatorHovered": "rgba(25, 102, 191, 0.7799999713897705)", "SeparatorActive": "rgba(25, 102, 191, 1.0)", "ResizeGrip": "rgba(119, 196, 211, 0.03999999910593033)", "ResizeGripHovered": "rgba(116, 50, 76, 0.7799999713897705)", "ResizeGripActive": "rgba(116, 50, 76, 1.0)", "Tab": "rgba(45, 89, 147, 0.8619999885559082)", "TabHovered": "rgba(66, 150, 249, 0.800000011920929)", "TabActive": "rgba(50, 104, 173, 1.0)", "TabUnfocused": "rgba(17, 26, 37, 0.9724000096321106)", "TabUnfocusedActive": "rgba(34, 66, 108, 1.0)", "PlotLines": "rgba(219, 237, 226, 0.6299999952316284)", "PlotLinesHovered": "rgba(116, 50, 76, 1.0)", "PlotHistogram": "rgba(219, 237, 226, 0.6299999952316284)", "PlotHistogramHovered": "rgba(116, 50, 76, 1.0)", "TableHeaderBg": "rgba(48, 48, 51, 1.0)", "TableBorderStrong": "rgba(79, 79, 89, 1.0)", "TableBorderLight": "rgba(58, 58, 63, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(255, 255, 255, 0.05999999865889549)", "TextSelectedBg": "rgba(116, 50, 76, 0.4300000071525574)", "DragDropTarget": "rgba(255, 255, 0, 0.8999999761581421)", "NavHighlight": "rgba(66, 150, 249, 1.0)", "NavWindowingHighlight": "rgba(255, 255, 255, 0.699999988079071)", "NavWindowingDimBg": "rgba(204, 204, 204, 0.2000000029802322)", "ModalWindowDimBg": "rgba(204, 204, 204, 0.3499999940395355)"}}
}

proc isThemeReadOnly(app: App, index = app.currentTheme): bool = 
  if "readonly" in app.prefs["themes"][index]:
    app.prefs["themes"][index]["readonly"].getBool()
  else:
    false

proc drawCreateThemeModal(app: var App) = 
  const alignCount = 8
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if igBeginPopupModal("New Theme", flags = makeFlags(AlwaysAutoResize)):
    igText(cstring "Name: ".alignLeft(alignCount)); igSameLine(); igInputText("##themeName", cstring app.themeName, 64)
    igText(cstring "Author: ".alignLeft(alignCount)); igSameLine();igInputText("##themeAuthor", cstring app.themeAuthor, 64)
    
    let templates = app.prefs["themes"]
    igText(cstring "From: ".alignLeft(alignCount)); igSameLine();
    if igBeginCombo("##templateCombo", cstring templates[app.currentThemeTemplate]["name"].getString()):
      for e, theme in templates.getTables():
        if igSelectable(cstring theme["name"].getString() & "(" & theme["author"].getString() & ")", e == app.currentThemeTemplate):
          app.currentThemeTemplate = e

      igEndCombo()

    if app.themeName.cleanString().len == 0 or app.themeAuthor.cleanString().len == 0:
      igBeginDisabled()

    if igButton("Ok"):
      app.prefs["themes"].add toTTable({name: app.themeName.cleanString(), author: app.themeAuthor.cleanString(), style: templates[app.currentThemeTemplate]["style"]})
      app.currentTheme = app.prefs["themes"].getTables().high
      app.themeStyle = styleFromToml(app.prefs["themes"][app.currentTheme]["style"])

      igCloseCurrentPopup()

    if app.themeName.cleanString().len == 0 or app.themeAuthor.cleanString().len == 0:
      igEndDisabled()

    igSameLine()
    if igButton("Cancel"): igCloseCurrentPopup()
    
    igEndPopup()

proc formatTemplate(app: App, exportKind: ExportKind): string = 
  template stringify(vec: ImVec2): string = 
    case exportKind
    of Nim: "ImVec2" & $vec
    of Cpp: "ImVec2(" & $vec.x & ", " & $vec.y & ")"

  template stringify(vec: ImVec4): string = 
    case exportKind
    of Nim: "ImVec4" & $vec
    of Cpp: "ImVec4(" & $vec.x & ", " & $vec.y & ", " & $vec.z & ", " & $vec.w & ")"
  
  template stringify(dir: ImGuiDir): string = 
    case exportKind
    of Nim: "ImGuiDir." & $dir
    of Cpp: "ImGuiDir_" & $dir

  template stringify(val: float32): string = 
    $val
    # case templateType
    # of "nim": "ImVec4" & $vec
    # of "cpp": "ImVec4(" & $vec.x & ", " & $vec.y & ", " & $vec.z & ", " & $vec.w & ")"

  let strTemplate = 
    case exportKind
    of Nim: nimExportTemplate
    of Cpp: cppExportTemplate

  strTemplate % [
    "name", $app.prefs["themes"][app.currentTheme]["name"].getString(), 
    "author", $app.prefs["themes"][app.currentTheme]["author"].getString(), 
    "alpha", app.prevThemeStyle.alpha.stringify(), 
    "disabledAlpha", app.prevThemeStyle.disabledAlpha.stringify(), 
    "windowPadding", app.prevThemeStyle.windowPadding.stringify(), 
    "windowRounding", app.prevThemeStyle.windowRounding.stringify(), 
    "windowBorderSize", app.prevThemeStyle.windowBorderSize.stringify(), 
    "windowMinSize", app.prevThemeStyle.windowMinSize.stringify(), 
    "windowTitleAlign", app.prevThemeStyle.windowTitleAlign.stringify(), 
    "windowMenuButtonPosition", app.prevThemeStyle.windowMenuButtonPosition.stringify(), 
    "childRounding", app.prevThemeStyle.childRounding.stringify(), 
    "childBorderSize", app.prevThemeStyle.childBorderSize.stringify(), 
    "popupRounding", app.prevThemeStyle.popupRounding.stringify(), 
    "popupBorderSize", app.prevThemeStyle.popupBorderSize.stringify(), 
    "framePadding", app.prevThemeStyle.framePadding.stringify(), 
    "frameRounding", app.prevThemeStyle.frameRounding.stringify(), 
    "frameBorderSize", app.prevThemeStyle.frameBorderSize.stringify(), 
    "itemSpacing", app.prevThemeStyle.itemSpacing.stringify(), 
    "itemInnerSpacing", app.prevThemeStyle.itemInnerSpacing.stringify(), 
    "cellPadding", app.prevThemeStyle.cellPadding.stringify(), 
    "indentSpacing", app.prevThemeStyle.indentSpacing.stringify(), 
    "columnsMinSpacing", app.prevThemeStyle.columnsMinSpacing.stringify(), 
    "scrollbarSize", app.prevThemeStyle.scrollbarSize.stringify(), 
    "scrollbarRounding", app.prevThemeStyle.scrollbarRounding.stringify(), 
    "grabMinSize", app.prevThemeStyle.grabMinSize.stringify(), 
    "grabRounding", app.prevThemeStyle.grabRounding.stringify(), 
    "tabRounding", app.prevThemeStyle.tabRounding.stringify(), 
    "tabBorderSize", app.prevThemeStyle.tabBorderSize.stringify(), 
    "tabMinWidthForCloseButton", app.prevThemeStyle.tabMinWidthForCloseButton.stringify(), 
    "colorButtonPosition", app.prevThemeStyle.colorButtonPosition.stringify(), 
    "buttonTextAlign", app.prevThemeStyle.buttonTextAlign.stringify(), 
    "selectableTextAlign", app.prevThemeStyle.selectableTextAlign.stringify(),

    "Text",$app.prevThemeStyle.colors[ord ImGuiCol.Text], 
    "TextDisabled", app.prevThemeStyle.colors[ord ImGuiCol.TextDisabled].stringify(), 
    "WindowBg", app.prevThemeStyle.colors[ord ImGuiCol.WindowBg].stringify(), 
    "ChildBg", app.prevThemeStyle.colors[ord ImGuiCol.ChildBg].stringify(), 
    "PopupBg", app.prevThemeStyle.colors[ord ImGuiCol.PopupBg].stringify(), 
    "Border", app.prevThemeStyle.colors[ord ImGuiCol.Border].stringify(), 
    "BorderShadow", app.prevThemeStyle.colors[ord ImGuiCol.BorderShadow].stringify(), 
    "FrameBg", app.prevThemeStyle.colors[ord ImGuiCol.FrameBg].stringify(), 
    "FrameBgHovered", app.prevThemeStyle.colors[ord ImGuiCol.FrameBgHovered].stringify(), 
    "FrameBgActive", app.prevThemeStyle.colors[ord ImGuiCol.FrameBgActive].stringify(), 
    "TitleBg", app.prevThemeStyle.colors[ord ImGuiCol.TitleBg].stringify(), 
    "TitleBgActive", app.prevThemeStyle.colors[ord ImGuiCol.TitleBgActive].stringify(), 
    "TitleBgCollapsed", app.prevThemeStyle.colors[ord ImGuiCol.TitleBgCollapsed].stringify(), 
    "MenuBarBg", app.prevThemeStyle.colors[ord ImGuiCol.MenuBarBg].stringify(), 
    "ScrollbarBg", app.prevThemeStyle.colors[ord ImGuiCol.ScrollbarBg].stringify(), 
    "ScrollbarGrab", app.prevThemeStyle.colors[ord ImGuiCol.ScrollbarGrab].stringify(), 
    "ScrollbarGrabHovered", app.prevThemeStyle.colors[ord ImGuiCol.ScrollbarGrabHovered].stringify(), 
    "ScrollbarGrabActive", app.prevThemeStyle.colors[ord ImGuiCol.ScrollbarGrabActive].stringify(), 
    "CheckMark", app.prevThemeStyle.colors[ord ImGuiCol.CheckMark].stringify(), 
    "SliderGrab", app.prevThemeStyle.colors[ord ImGuiCol.SliderGrab].stringify(), 
    "SliderGrabActive", app.prevThemeStyle.colors[ord ImGuiCol.SliderGrabActive].stringify(), 
    "Button", app.prevThemeStyle.colors[ord ImGuiCol.Button].stringify(), 
    "ButtonHovered", app.prevThemeStyle.colors[ord ImGuiCol.ButtonHovered].stringify(), 
    "ButtonActive", app.prevThemeStyle.colors[ord ImGuiCol.ButtonActive].stringify(), 
    "Header", app.prevThemeStyle.colors[ord ImGuiCol.Header].stringify(), 
    "HeaderHovered", app.prevThemeStyle.colors[ord ImGuiCol.HeaderHovered].stringify(), 
    "HeaderActive", app.prevThemeStyle.colors[ord ImGuiCol.HeaderActive].stringify(), 
    "Separator", app.prevThemeStyle.colors[ord ImGuiCol.Separator].stringify(), 
    "SeparatorHovered", app.prevThemeStyle.colors[ord ImGuiCol.SeparatorHovered].stringify(), 
    "SeparatorActive", app.prevThemeStyle.colors[ord ImGuiCol.SeparatorActive].stringify(), 
    "ResizeGrip", app.prevThemeStyle.colors[ord ImGuiCol.ResizeGrip].stringify(), 
    "ResizeGripHovered", app.prevThemeStyle.colors[ord ImGuiCol.ResizeGripHovered].stringify(), 
    "ResizeGripActive", app.prevThemeStyle.colors[ord ImGuiCol.ResizeGripActive].stringify(), 
    "Tab", app.prevThemeStyle.colors[ord ImGuiCol.Tab].stringify(), 
    "TabHovered", app.prevThemeStyle.colors[ord ImGuiCol.TabHovered].stringify(), 
    "TabActive", app.prevThemeStyle.colors[ord ImGuiCol.TabActive].stringify(), 
    "TabUnfocused", app.prevThemeStyle.colors[ord ImGuiCol.TabUnfocused].stringify(), 
    "TabUnfocusedActive", app.prevThemeStyle.colors[ord ImGuiCol.TabUnfocusedActive].stringify(), 
    "PlotLines", app.prevThemeStyle.colors[ord ImGuiCol.PlotLines].stringify(), 
    "PlotLinesHovered", app.prevThemeStyle.colors[ord ImGuiCol.PlotLinesHovered].stringify(), 
    "PlotHistogram", app.prevThemeStyle.colors[ord ImGuiCol.PlotHistogram].stringify(), 
    "PlotHistogramHovered", app.prevThemeStyle.colors[ord ImGuiCol.PlotHistogramHovered].stringify(), 
    "TableHeaderBg", app.prevThemeStyle.colors[ord ImGuiCol.TableHeaderBg].stringify(), 
    "TableBorderStrong", app.prevThemeStyle.colors[ord ImGuiCol.TableBorderStrong].stringify(), 
    "TableBorderLight", app.prevThemeStyle.colors[ord ImGuiCol.TableBorderLight].stringify(), 
    "TableRowBg", app.prevThemeStyle.colors[ord ImGuiCol.TableRowBg].stringify(), 
    "TableRowBgAlt", app.prevThemeStyle.colors[ord ImGuiCol.TableRowBgAlt].stringify(), 
    "TextSelectedBg", app.prevThemeStyle.colors[ord ImGuiCol.TextSelectedBg].stringify(), 
    "DragDropTarget", app.prevThemeStyle.colors[ord ImGuiCol.DragDropTarget].stringify(), 
    "NavHighlight", app.prevThemeStyle.colors[ord ImGuiCol.NavHighlight].stringify(), 
    "NavWindowingHighlight", app.prevThemeStyle.colors[ord ImGuiCol.NavWindowingHighlight].stringify(), 
    "NavWindowingDimBg", app.prevThemeStyle.colors[ord ImGuiCol.NavWindowingDimBg].stringify(), 
    "ModalWindowDimBg", app.prevThemeStyle.colors[ord ImGuiCol.ModalWindowDimBg].stringify(), 
  ]

proc drawExportThemeModal(app: var App) = 
  var currentText = ""
  let unusedOpen = true
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  igSetNextWindowSize(igVec2(500, 500))
  if igBeginPopupModal("Export Theme", unusedOpen.unsafeAddr, flags = makeFlags(ImGuiWindowFlags.NoResize)):
    if igBeginTabBar("##exportTabs"):
      if igBeginTabItem(cstring "Nim " & FA_Code):
        if app.currentExportTab != 0: app.copied = false
        app.currentExportTab = 0
        currentText = app.formatTemplate(Nim)
        
        igInputTextMultiline("##nim", cstring currentText, uint currentText.len, igGetContentRegionAvail(), ImGuiInputTextFlags.ReadOnly)
        igEndTabItem()
      
      if igBeginTabItem(cstring "C++ " & FA_Code):
        if app.currentExportTab != 1: app.copied = false
        app.currentExportTab = 1
        currentText = app.formatTemplate(Cpp)
        
        igInputTextMultiline("##cpp", cstring currentText, uint currentText.len, igGetContentRegionAvail(), ImGuiInputTextFlags.ReadOnly)
        igEndTabItem()
      
      if igBeginTabItem("ImStyle"):
        if app.currentExportTab != 2: app.copied = false
        app.currentExportTab = 2

        currentText = &"# {app.prefs[\"themes\"][app.currentTheme][\"name\"].getString()} style by {app.prefs[\"themes\"][app.currentTheme][\"author\"].getString()} from ImThemes\n" & Toml.encode(app.prevThemeStyle.styleToToml(colorProc = proc(col: ImVec4): TomlValueRef = Color(r: col.x, g: col.y, b: col.z, a: col.w).toHtmlRgba().newTString()))

        igInputTextMultiline("##imstyle", cstring currentText, uint currentText.len, igGetContentRegionAvail(), ImGuiInputTextFlags.ReadOnly)
        igEndTabItem()
      
      if igTabItemButton(cstring (if not app.copied: "Copy " & FA_FilesO else: "Copied"), Trailing):
        app.copied = true
        app.win.setClipboardString(cstring currentText)

      igEndTabBar()

    igEndPopup()

proc switchTheme*(app: var App, themeIndex: int) = 
  app.editing = false
  app.currentTheme = themeIndex
  app.editSplitterSize1.a = 0f
  app.editSplitterSize2.b = 0f
  app.previewBuffer = newString(64)
  app.themeStyle = styleFromToml(app.prefs["themes"][themeIndex]["style"])

proc saveCurTheme(app: var App) = 
  app.saved = true
  app.prevThemeStyle = app.themeStyle
  app.prefs["themes"][app.currentTheme]["style"] = app.themeStyle.styleToToml(colorProc = proc(col: ImVec4): TomlValueRef = col.color().toHtmlRgba().newTString())

proc drawNotSavedModal(app: var App) = 
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if igBeginPopupModal("Not Saved", flags = AlwaysAutoResize):
    igText("Do you want to save the current changes?")
    if igButton("Yes"):
      app.saveCurTheme()
      igCloseCurrentPopup()
    
    igSameLine()
    if igButton("No"):
      app.themeStyle = app.prevThemeStyle
      app.switchTheme(app.currentTheme)
      igCloseCurrentPopup()

    igEndPopup()

proc drawDeleteThemeModal(app: var App) = 
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if igBeginPopupModal("Delete Theme", flags = AlwaysAutoResize):
    igText("Are you sure you want to delete it? You won't be able to undo this action.")
    if igButton("Yes"):
      app.prefs["themes"].delete(app.currentTheme)
      app.currentTheme = 0
      igCloseCurrentPopup()

    igSameLine()
    if igButton("No"):
      igCloseCurrentPopup()

    igEndPopup()

proc drawThemesList(app: var App) = 
  let style = igGetStyle()

  # To make it not clickable
  igPushItemFlag(ImGuiItemFlags.Disabled, true)
  igSelectable("Themes", true)
  igPopItemFlag()

  if igBeginListBox("##themes", igVec2(app.editSplitterSize1.a, igGetContentRegionAvail().y - igGetFrameHeight() - style.windowPadding.y)):
    for e, theme in app.prefs["themes"].getTables():
      let selected = e == app.currentTheme

      if igSelectable(cstring theme["name"].getString() & (if app.isThemeReadOnly(e): " (Read-Only)" else: ""), selected) and (not selected or (selected and app.editing)):
        if not app.saved and app.editing:
          igOpenPopup("Not Saved")
        else:
          app.switchTheme(e)

    app.drawNotSavedModal()
    igEndListBox()

  var selected = app.currentTheme >= 0

  if igButton("Create"):
    (app.themeName, app.themeAuthor) = (newString(64), newString(64))
    igOpenPopup("New Theme")

  if not selected:
    igBeginDisabled()

  igSameLine()
  var editBtnDisabled = false
  if app.isThemeReadOnly() or (app.editing and app.saved):
    editBtnDisabled = true
    igBeginDisabled()

  if app.editing:
    if igButton(cstring "Save") and not app.saved:
      app.saveCurTheme()
  else:
    if igButton("Edit"):
      app.saved = true
      app.editing = true
      app.prevThemeStyle = app.themeStyle

  if editBtnDisabled:
    igEndDisabled()
    if igIsItemHovered(AllowWhenDisabled):
      if app.isThemeReadOnly():
        igSetTooltip("Read-Only")
      elif app.saved:
        igSetTooltip("No changes to save")

  if app.isThemeReadOnly():
    igBeginDisabled()

  igSameLine()
  if igButton("Delete"):
    igOpenPopup("Delete Theme")

  if app.isThemeReadOnly():
    igEndDisabled()
    if igIsItemHovered(AllowWhenDisabled):
      igSetTooltip("Read-Only")

  igSameLine()
  if igButton("Export"):
    igOpenPopup("Export Theme")

  if not selected:
    igEndDisabled()

  app.drawCreateThemeModal()
  app.drawExportThemeModal()
  app.drawDeleteThemeModal()

proc drawEditView*(app: var App) = 
  let style = igGetStyle()
  let avail = igGetContentRegionAvail()

  # Keep splitter proportions on resize
  # And hide the editing zone when not editing
  if app.prevAvail != igVec2(0, 0) and app.prevAvail != avail:
    if app.editing:
      (app.editSplitterSize1, app.editSplitterSize2) = (
        ((app.editSplitterSize1.a / app.prevAvail.x) * avail.x, 0f), 
        ((app.editSplitterSize2.a / app.prevAvail.x) * avail.x, (app.editSplitterSize2.b / app.prevAvail.x) * avail.x)
      )
    else:
      (app.editSplitterSize1, app.editSplitterSize2) = (
        ((app.editSplitterSize1.a / app.prevAvail.x) * avail.x, 0f), 
        ((app.editSplitterSize2.a / app.prevAvail.x) * avail.x, 0f)
      )

  app.prevAvail = avail

  # First time or when switch editing
  if app.editing and app.editSplitterSize2.b == 0f:
    (app.editSplitterSize1, app.editSplitterSize2) = ((avail.x * 0.15f, 0f), (avail.x * 0.425f, avail.x * 0.425f))
  elif app.editSplitterSize1.a == 0f:
    (app.editSplitterSize1, app.editSplitterSize2) = ((avail.x * 0.5f, 0f), (avail.x * 0.5f, 0f))

  igSplitter(true, 8, app.editSplitterSize1.a.addr, app.editSplitterSize2.a.addr, style.windowMinSize.x, style.windowMinSize.x, avail.y)
  # List
  if igBeginChild("##editViewThemes", igVec2(app.editSplitterSize1.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
    app.drawThemesList()
  igEndChild(); igSameLine()

  # Second Splitter
  if igBeginChild("##editViewSplitter2", igVec2(app.editSplitterSize2.a + app.editSplitterSize2.b, avail.y)):
    igSplitter(true, 8, app.editSplitterSize2.a.addr, app.editSplitterSize2.b.addr, style.windowMinSize.x, if app.editing: style.windowMinSize.x else: 0, avail.y)
    # Preview
    if igBeginChild("##editViewPreviewer", igVec2(app.editSplitterSize2.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)) and app.currentTheme >= 0:
      igSetNextWindowPos(igGetWindowPos())
      igSetNextWindowSize(igGetWindowSize())

      app.drawStylePreview(app.prefs["themes"][app.currentTheme]["name"].getString() & (if app.isThemeReadOnly(): " (Read-Only)" else: ""), app.themeStyle)

    igEndChild(); igSameLine()

    # Editor
    if app.editing:
      app.saved = app.themeStyle == app.prevThemeStyle
        
      if igBeginChild("##editViewEditor", igVec2(app.editSplitterSize2.b, avail.y), flags = makeFlags(AlwaysUseWindowPadding, HorizontalScrollbar)):
        app.drawEditor(app.themeStyle)
      igEndChild()

  igEndChild()
