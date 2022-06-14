import std/[strutils, os]

import chroma
import imstyle
import niprefs
import nimgl/[opengl, glfw]
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]

import src/[prefsmodal, browseview, editview, utils, icons]
when defined(release):
  from resourcesdata import resources

const
  configPath = "config.toml"
  sidebarViews = [
    FA_PencilSquareO, # Edit view
    FA_Search, # Browse view
  ]

let classicTheme = toToml {
  name: "Classic", 
  author: "ocornut", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledalpha": 0.6000000238418579, "windowPadding": @[8.0, 8.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.0, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[4.0, 3.0], "frameRounding": 0.0, "frameBorderSize": 0.0, "itemspacing": @[8.0, 4.0], "iteminnerspacing": @[4.0, 4.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 21.0, "columnsminspacing": 6.0, "scrollbarSize": 14.0, "scrollbarRounding": 9.0, "grabMinSize": 10.0, "grabRounding": 0.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 0.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 3.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(229, 229, 229, 1.0)", "TextDisabled": "rgba(153, 153, 153, 1.0)", "WindowBg": "rgba(0, 0, 0, 0.8500000238418579)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(28, 28, 35, 0.9200000166893005)", "Border": "rgba(127, 127, 127, 0.5)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(109, 109, 109, 0.3899999856948853)", "FrameBgHovered": "rgba(119, 119, 175, 0.4000000059604645)", "FrameBgActive": "rgba(107, 104, 163, 0.6899999976158142)", "TitleBg": "rgba(68, 68, 137, 0.8299999833106995)", "TitleBgActive": "rgba(81, 81, 160, 0.8700000047683716)", "TitleBgCollapsed": "rgba(102, 102, 204, 0.2000000029802322)", "MenuBarBg": "rgba(102, 102, 140, 0.800000011920929)", "ScrollbarBg": "rgba(51, 63, 76, 0.6000000238418579)", "ScrollbarGrab": "rgba(102, 102, 204, 0.300000011920929)", "ScrollbarGrabHovered": "rgba(102, 102, 204, 0.4000000059604645)", "ScrollbarGrabActive": "rgba(104, 99, 204, 0.6000000238418579)", "Checkmark": "rgba(229, 229, 229, 0.5)", "Slidergrab": "rgba(255, 255, 255, 0.300000011920929)", "SlidergrabActive": "rgba(104, 99, 204, 0.6000000238418579)", "Button": "rgba(89, 102, 155, 0.6200000047683716)", "ButtonHovered": "rgba(102, 122, 181, 0.7900000214576721)", "ButtonActive": "rgba(117, 137, 204, 1.0)", "Header": "rgba(102, 102, 229, 0.449999988079071)", "HeaderHovered": "rgba(114, 114, 229, 0.800000011920929)", "HeaderActive": "rgba(135, 135, 221, 0.800000011920929)", "Separator": "rgba(127, 127, 127, 0.6000000238418579)", "SeparatorHovered": "rgba(153, 153, 178, 1.0)", "SeparatorActive": "rgba(178, 178, 229, 1.0)", "ResizeGrip": "rgba(255, 255, 255, 0.1000000014901161)", "ResizeGripHovered": "rgba(198, 209, 255, 0.6000000238418579)", "ResizeGripActive": "rgba(198, 209, 255, 0.8999999761581421)", "Tab": "rgba(85, 85, 174, 0.7860000133514404)", "TabHovered": "rgba(114, 114, 229, 0.800000011920929)", "TabActive": "rgba(103, 103, 185, 0.8420000076293945)", "TabUnfocused": "rgba(72, 72, 145, 0.8212000131607056)", "TabUnfocusedActive": "rgba(89, 89, 166, 0.8371999859809875)", "PlotLines": "rgba(255, 255, 255, 1.0)", "PlotLinesHovered": "rgba(229, 178, 0, 1.0)", "PlotHistogram": "rgba(229, 178, 0, 1.0)", "PlotHistogramHovered": "rgba(255, 153, 0, 1.0)", "TableHeaderBg": "rgba(68, 68, 96, 1.0)", "TableBorderStrong": "rgba(79, 79, 114, 1.0)", "TableBorderLight": "rgba(66, 66, 71, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(255, 255, 255, 0.07000000029802322)", "TextSelectedBg": "rgba(0, 0, 255, 0.3499999940395355)", "DragDropTarget": "rgba(255, 255, 0, 0.8999999761581421)", "NavHighlight": "rgba(114, 114, 229, 0.800000011920929)", "NavWindowingHighlight": "rgba(255, 255, 255, 0.699999988079071)", "NavWindowingDimBg": "rgba(204, 204, 204, 0.2000000029802322)", "ModalWindowDimBg": "rgba(51, 51, 51, 0.3499999940395355)"}}
} 
let darkTheme = toToml {
    name: "Dark", 
  author: "dougbinks", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledalpha": 0.6000000238418579, "windowPadding": @[8.0, 8.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.0, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[4.0, 3.0], "frameRounding": 0.0, "frameBorderSize": 0.0, "itemspacing": @[8.0, 4.0], "iteminnerspacing": @[4.0, 4.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 21.0, "columnsminspacing": 6.0, "scrollbarSize": 14.0, "scrollbarRounding": 9.0, "grabMinSize": 10.0, "grabRounding": 0.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 0.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 3.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(255, 255, 255, 1.0)", "TextDisabled": "rgba(127, 127, 127, 1.0)", "WindowBg": "rgba(15, 15, 15, 0.9399999976158142)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(20, 20, 20, 0.9399999976158142)", "Border": "rgba(109, 109, 127, 0.5)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(40, 73, 122, 0.5400000214576721)", "FrameBgHovered": "rgba(66, 150, 249, 0.4000000059604645)", "FrameBgActive": "rgba(66, 150, 249, 0.6700000166893005)", "TitleBg": "rgba(10, 10, 10, 1.0)", "TitleBgActive": "rgba(40, 73, 122, 1.0)", "TitleBgCollapsed": "rgba(0, 0, 0, 0.5099999904632568)", "MenuBarBg": "rgba(35, 35, 35, 1.0)", "ScrollbarBg": "rgba(5, 5, 5, 0.5299999713897705)", "ScrollbarGrab": "rgba(79, 79, 79, 1.0)", "ScrollbarGrabHovered": "rgba(104, 104, 104, 1.0)", "ScrollbarGrabActive": "rgba(130, 130, 130, 1.0)", "Checkmark": "rgba(66, 150, 249, 1.0)", "Slidergrab": "rgba(61, 132, 224, 1.0)", "SlidergrabActive": "rgba(66, 150, 249, 1.0)", "Button": "rgba(66, 150, 249, 0.4000000059604645)", "ButtonHovered": "rgba(66, 150, 249, 1.0)", "ButtonActive": "rgba(15, 135, 249, 1.0)", "Header": "rgba(66, 150, 249, 0.3100000023841858)", "HeaderHovered": "rgba(66, 150, 249, 0.800000011920929)", "HeaderActive": "rgba(66, 150, 249, 1.0)", "Separator": "rgba(109, 109, 127, 0.5)", "SeparatorHovered": "rgba(25, 102, 191, 0.7799999713897705)", "SeparatorActive": "rgba(25, 102, 191, 1.0)", "ResizeGrip": "rgba(66, 150, 249, 0.2000000029802322)", "ResizeGripHovered": "rgba(66, 150, 249, 0.6700000166893005)", "ResizeGripActive": "rgba(66, 150, 249, 0.949999988079071)", "Tab": "rgba(45, 89, 147, 0.8619999885559082)", "TabHovered": "rgba(66, 150, 249, 0.800000011920929)", "TabActive": "rgba(50, 104, 173, 1.0)", "TabUnfocused": "rgba(17, 26, 37, 0.9724000096321106)", "TabUnfocusedActive": "rgba(34, 66, 108, 1.0)", "PlotLines": "rgba(155, 155, 155, 1.0)", "PlotLinesHovered": "rgba(255, 109, 89, 1.0)", "PlotHistogram": "rgba(229, 178, 0, 1.0)", "PlotHistogramHovered": "rgba(255, 153, 0, 1.0)", "TableHeaderBg": "rgba(48, 48, 51, 1.0)", "TableBorderStrong": "rgba(79, 79, 89, 1.0)", "TableBorderLight": "rgba(58, 58, 63, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(255, 255, 255, 0.05999999865889549)", "TextSelectedBg": "rgba(66, 150, 249, 0.3499999940395355)", "DragDropTarget": "rgba(255, 255, 0, 0.8999999761581421)", "NavHighlight": "rgba(66, 150, 249, 1.0)", "NavWindowingHighlight": "rgba(255, 255, 255, 0.699999988079071)", "NavWindowingDimBg": "rgba(204, 204, 204, 0.2000000029802322)", "ModalWindowDimBg": "rgba(204, 204, 204, 0.3499999940395355)"}}
}
let lightTheme = toToml {
  name: "Light", 
  author: "dougbinks", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledalpha": 0.6000000238418579, "windowPadding": @[8.0, 8.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.0, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[4.0, 3.0], "frameRounding": 0.0, "frameBorderSize": 0.0, "itemspacing": @[8.0, 4.0], "iteminnerspacing": @[4.0, 4.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 21.0, "columnsminspacing": 6.0, "scrollbarSize": 14.0, "scrollbarRounding": 9.0, "grabMinSize": 10.0, "grabRounding": 0.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 0.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 3.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(0, 0, 0, 1.0)", "TextDisabled": "rgba(153, 153, 153, 1.0)", "WindowBg": "rgba(239, 239, 239, 1.0)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(255, 255, 255, 0.9800000190734863)", "Border": "rgba(0, 0, 0, 0.300000011920929)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(255, 255, 255, 1.0)", "FrameBgHovered": "rgba(66, 150, 249, 0.4000000059604645)", "FrameBgActive": "rgba(66, 150, 249, 0.6700000166893005)", "TitleBg": "rgba(244, 244, 244, 1.0)", "TitleBgActive": "rgba(209, 209, 209, 1.0)", "TitleBgCollapsed": "rgba(255, 255, 255, 0.5099999904632568)", "MenuBarBg": "rgba(219, 219, 219, 1.0)", "ScrollbarBg": "rgba(249, 249, 249, 0.5299999713897705)", "ScrollbarGrab": "rgba(175, 175, 175, 0.800000011920929)", "ScrollbarGrabHovered": "rgba(124, 124, 124, 0.800000011920929)", "ScrollbarGrabActive": "rgba(124, 124, 124, 1.0)", "Checkmark": "rgba(66, 150, 249, 1.0)", "Slidergrab": "rgba(66, 150, 249, 0.7799999713897705)", "SlidergrabActive": "rgba(117, 137, 204, 0.6000000238418579)", "Button": "rgba(66, 150, 249, 0.4000000059604645)", "ButtonHovered": "rgba(66, 150, 249, 1.0)", "ButtonActive": "rgba(15, 135, 249, 1.0)", "Header": "rgba(66, 150, 249, 0.3100000023841858)", "HeaderHovered": "rgba(66, 150, 249, 0.800000011920929)", "HeaderActive": "rgba(66, 150, 249, 1.0)", "Separator": "rgba(99, 99, 99, 0.6200000047683716)", "SeparatorHovered": "rgba(35, 112, 204, 0.7799999713897705)", "SeparatorActive": "rgba(35, 112, 204, 1.0)", "ResizeGrip": "rgba(89, 89, 89, 0.1700000017881393)", "ResizeGripHovered": "rgba(66, 150, 249, 0.6700000166893005)", "ResizeGripActive": "rgba(66, 150, 249, 0.949999988079071)", "Tab": "rgba(194, 203, 213, 0.9309999942779541)", "TabHovered": "rgba(66, 150, 249, 0.800000011920929)", "TabActive": "rgba(151, 185, 225, 1.0)", "TabUnfocused": "rgba(234, 236, 238, 0.9861999750137329)", "TabUnfocusedActive": "rgba(189, 209, 233, 1.0)", "PlotLines": "rgba(99, 99, 99, 1.0)", "PlotLinesHovered": "rgba(255, 109, 89, 1.0)", "PlotHistogram": "rgba(229, 178, 0, 1.0)", "PlotHistogramHovered": "rgba(255, 114, 0, 1.0)", "TableHeaderBg": "rgba(198, 221, 249, 1.0)", "TableBorderStrong": "rgba(145, 145, 163, 1.0)", "TableBorderLight": "rgba(173, 173, 188, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(76, 76, 76, 0.09000000357627869)", "TextSelectedBg": "rgba(66, 150, 249, 0.3499999940395355)", "DragDropTarget": "rgba(66, 150, 249, 0.949999988079071)", "NavHighlight": "rgba(66, 150, 249, 0.800000011920929)", "NavWindowingHighlight": "rgba(178, 178, 178, 0.699999988079071)", "NavWindowingDimBg": "rgba(51, 51, 51, 0.2000000029802322)", "ModalWindowDimBg": "rgba(51, 51, 51, 0.3499999940395355)"}}
}
let cherryTheme = toToml {
  name: "Cherry", 
  author: "r-lyeh", 
  readonly: true, 
  style: {"alpha": 1.0, "disabledAlpha": 0.6000000238418579, "windowPadding": @[6.0, 3.0], "windowRounding": 0.0, "windowBorderSize": 1.0, "windowMinSize": @[32.0, 32.0], "windowTitleAlign": @[0.5, 0.5], "windowmenubuttonposition": "Left", "childRounding": 0.0, "childBorderSize": 1.0, "popupRounding": 0.0, "popupBorderSize": 1.0, "framePadding": @[5.0, 1.0], "frameRounding": 3.0, "frameBorderSize": 1.0, "itemspacing": @[7.0, 1.0], "iteminnerspacing": @[1.0, 1.0], "cellPadding": @[4.0, 2.0], "touchextraPadding": @[0.0, 0.0], "indentspacing": 6.0, "columnsminspacing": 6.0, "scrollbarSize": 13.0, "scrollbarRounding": 16.0, "grabMinSize": 20.0, "grabRounding": 2.0, "logSliderDeadzone": 4.0, "tabRounding": 4.0, "tabBorderSize": 1.0, "tabminwidthforclosebutton": 0.0, "colorbuttonposition": "Right", "buttonTextAlign": @[0.5, 0.5], "selectableTextAlign": @[0.0, 0.0], "displayWindowPadding": @[19.0, 19.0], "displaySafeAreaPadding": @[3.0, 0.0], "mouseCursorScale": 1.0, "antiAliasedLines": true, "antiAliasedLinesUseTex": true, "antiAliasedFill": true, "curveTessellationTol": 1.25, "circleTessellationMaxError": 0.300000011920929, "colors": {"Text": "rgba(219, 237, 226, 0.8799999952316284)", "TextDisabled": "rgba(219, 237, 226, 0.2800000011920929)", "WindowBg": "rgba(33, 35, 43, 1.0)", "ChildBg": "rgba(0, 0, 0, 0.0)", "PopupBg": "rgba(51, 56, 68, 0.8999999761581421)", "Border": "rgba(137, 122, 65, 0.1620000004768372)", "BorderShadow": "rgba(0, 0, 0, 0.0)", "FrameBg": "rgba(51, 56, 68, 1.0)", "FrameBgHovered": "rgba(116, 50, 76, 0.7799999713897705)", "FrameBgActive": "rgba(116, 50, 76, 1.0)", "TitleBg": "rgba(59, 51, 69, 1.0)", "TitleBgActive": "rgba(128, 19, 65, 1.0)", "TitleBgCollapsed": "rgba(51, 56, 68, 0.75)", "MenuBarBg": "rgba(51, 56, 68, 0.4699999988079071)", "ScrollbarBg": "rgba(51, 56, 68, 1.0)", "ScrollbarGrab": "rgba(22, 38, 40, 1.0)", "ScrollbarGrabHovered": "rgba(116, 50, 76, 0.7799999713897705)", "ScrollbarGrabActive": "rgba(116, 50, 76, 1.0)", "Checkmark": "rgba(181, 56, 68, 1.0)", "Slidergrab": "rgba(119, 196, 211, 0.1400000005960464)", "SlidergrabActive": "rgba(181, 56, 68, 1.0)", "Button": "rgba(119, 196, 211, 0.1400000005960464)", "ButtonHovered": "rgba(116, 50, 76, 0.8600000143051147)", "ButtonActive": "rgba(116, 50, 76, 1.0)", "Header": "rgba(116, 50, 76, 0.7599999904632568)", "HeaderHovered": "rgba(116, 50, 76, 0.8600000143051147)", "HeaderActive": "rgba(128, 19, 65, 1.0)", "Separator": "rgba(109, 109, 127, 0.5)", "SeparatorHovered": "rgba(25, 102, 191, 0.7799999713897705)", "SeparatorActive": "rgba(25, 102, 191, 1.0)", "ResizeGrip": "rgba(119, 196, 211, 0.03999999910593033)", "ResizeGripHovered": "rgba(116, 50, 76, 0.7799999713897705)", "ResizeGripActive": "rgba(116, 50, 76, 1.0)", "Tab": "rgba(45, 89, 147, 0.8619999885559082)", "TabHovered": "rgba(66, 150, 249, 0.800000011920929)", "TabActive": "rgba(50, 104, 173, 1.0)", "TabUnfocused": "rgba(17, 26, 37, 0.9724000096321106)", "TabUnfocusedActive": "rgba(34, 66, 108, 1.0)", "PlotLines": "rgba(219, 237, 226, 0.6299999952316284)", "PlotLinesHovered": "rgba(116, 50, 76, 1.0)", "PlotHistogram": "rgba(219, 237, 226, 0.6299999952316284)", "PlotHistogramHovered": "rgba(116, 50, 76, 1.0)", "TableHeaderBg": "rgba(48, 48, 51, 1.0)", "TableBorderStrong": "rgba(79, 79, 89, 1.0)", "TableBorderLight": "rgba(58, 58, 63, 1.0)", "TableRowBg": "rgba(0, 0, 0, 0.0)", "TableRowBgAlt": "rgba(255, 255, 255, 0.05999999865889549)", "TextSelectedBg": "rgba(116, 50, 76, 0.4300000071525574)", "DragDropTarget": "rgba(255, 255, 0, 0.8999999761581421)", "NavHighlight": "rgba(66, 150, 249, 1.0)", "NavWindowingHighlight": "rgba(255, 255, 255, 0.699999988079071)", "NavWindowingDimBg": "rgba(204, 204, 204, 0.2000000029802322)", "ModalWindowDimBg": "rgba(204, 204, 204, 0.3499999940395355)"}}
}

proc getData(path: string): string = 
  when defined(release):
    resources[path]
  else:
    readFile(path)

proc getData(node: TomlValueRef): string = 
  assert node.kind == TomlKind.String
  node.getString().getData()

proc drawAboutModal(app: App) = 
  var center: ImVec2
  getCenterNonUDT(center.addr, igGetMainViewport())
  igSetNextWindowPos(center, Always, igVec2(0.5f, 0.5f))

  let unusedOpen = true # Passing this parameter creates a close button
  if igBeginPopupModal(cstring "About " & app.config["name"].getString(), unusedOpen.unsafeAddr, flags = makeFlags(ImGuiWindowFlags.NoResize)):
    # Display icon image
    var texture: GLuint
    var image = app.config["iconPath"].getData().readImageFromMemory()

    image.loadTextureFromData(texture)

    igImage(cast[ptr ImTextureID](texture), igVec2(64, 64)) # Or igVec2(image.width.float32, image.height.float32)
    if igIsItemHovered():
      igSetTooltip(cstring app.config["website"].getString() & " " & FA_ExternalLink)
      
      if igIsMouseClicked(ImGuiMouseButton.Left):
        app.config["website"].getString().openURL()

    igSameLine()
    
    igPushTextWrapPos(250)
    igTextWrapped(app.config["comment"].getString().cstring)
    igPopTextWrapPos()

    igSpacing()

    # To make it not clickable
    igPushItemFlag(ImGuiItemFlags.Disabled, true)
    igSelectable("Credits", true, makeFlags(ImGuiSelectableFlags.DontClosePopups))
    igPopItemFlag()

    if igBeginChild("##credits", igVec2(0, 75)):
      for author in app.config["authors"]:
        let (name, url) = block: 
          let (name,  url) = author.getString().removeInside('<', '>')
          (name.strip(),  url.strip())

        if igSelectable(cstring name) and url.len > 0:
            url.openURL()
        if igIsItemHovered() and url.len > 0:
          igSetTooltip(cstring url & " " & FA_ExternalLink)
      
      igEndChild()

    igSpacing()

    igText(app.config["version"].getString().cstring)

    igEndPopup()

proc drawMainMenuBar(app: var App) =
  var openAbout, openPrefs = false

  if igBeginMainMenuBar():
    if igBeginMenu("File"):
      igMenuItem("Preferences " & FA_Cog, "Ctrl+P", openPrefs.addr)
      if igMenuItem("Quit " & FA_Times, "Ctrl+Q"):
        app.win.setWindowShouldClose(true)
      igEndMenu()

    if igBeginMenu("Edit"):
      if igMenuItem("Hello"):
        echo "Hello"

      igEndMenu()

    if igBeginMenu("About"):
      if igMenuItem("Website " & FA_ExternalLink):
        app.config["website"].getString().openURL()

      igMenuItem(cstring "About " & app.config["name"].getString(), shortcut = nil, p_selected = openAbout.addr)

      igEndMenu() 

    igEndMainMenuBar()

  # See https:#github.com/ocornut/imgui/issues/331#issuecomment-751372071
  if openPrefs:
    igOpenPopup("Preferences")
  if openAbout:
    igOpenPopup(cstring "About " & app.config["name"].getString())

  # These modals will only get drawn when igOpenPopup(name) are called, respectly
  app.drawAboutModal()
  app.drawPrefsModal()

proc drawSidebar(app: var App) = 
  const sidebarWidth = 50
  var anyHovered = false
  igPushFont(app.sidebarIconFont)
  igPushStyleColor(ImGuiCol.WindowBg, igGetColor(WindowBg).darken(0.02).igVec4())
  igPushStyleColor(ImGuiCol.Text, "#9A9996".parseHtmlHex().igVec4())
  igPushStyleVar(ImGuiStyleVar.WindowPadding, igVec2(0, 20))
  igPushStyleVar(ImGuiStyleVar.ItemSpacing, igVec2(0, 7))

  if igBeginViewportSideBar("##sidebar", igGetMainViewport(), ImGuiDir.Left, sidebarWidth, ImGuiWindowFlags.None):
    for e, view in sidebarViews:
      if app.currentView == e:
        igPushStyleColor(ImGuiCol.Text, "#FFFFFF".parseHtmlHex().igVec4())

      if app.hoveredView == e:
        igPushStyleColor(ImGuiCol.Text, igGetColor(Text).lighten(0.2).igVec4())

      igCenterCursorX(igCalcTextSize(cstring view).x, avail = sidebarWidth)
      igText(cstring view)

      if app.currentView == e:
        igPopStyleColor()
      if app.hoveredView == e:
        igPopStyleColor()

      if app.currentView != e and igIsItemHovered():
        anyHovered = true
        app.hoveredView = e
      if igIsItemClicked():
        app.currentView = e

    igEnd()

  if not anyHovered:
    app.hoveredView = -1

  igPopStyleVar(2)
  igPopStyleColor(2)
  igPopFont()

proc drawMain(app: var App) = # Draw the main window
  let viewport = igGetMainViewport()  
  
  app.drawMainMenuBar()
  app.drawSidebar()
  # Work area is the entire viewport minus main menu bar, task bars, etc.
  igSetNextWindowPos(viewport.workPos)
  igSetNextWindowSize(viewport.workSize)

  if igBegin(cstring app.config["name"].getString(), flags = makeFlags(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoBringToFrontOnFocus, NoDecoration, NoMove)):
    igText(FA_Info & " Application average %.3f ms/frame (%.1f FPS)", 1000f / igGetIO().framerate, igGetIO().framerate)
    if app.currentView == 0:
      app.drawEditView()
    elif app.currentView == 1:
      app.drawBrowseView()
    else:
      igText("hello")

  igEnd()

  # GLFW clipboard -> ImGui clipboard
  if not app.win.getClipboardString().isNil and $app.win.getClipboardString() != app.lastClipboard:
    igsetClipboardText(app.win.getClipboardString())
    app.lastClipboard = $app.win.getClipboardString()

  # ImGui clipboard -> GLFW clipboard
  if not igGetClipboardText().isNil and $igGetClipboardText() != app.lastClipboard:
    app.win.setClipboardString(igGetClipboardText())
    app.lastClipboard = $igGetClipboardText()

proc render(app: var App) = # Called in the main loop
  # Poll and handle events (inputs, window resize, etc.)
  glfwPollEvents() # Use glfwWaitEvents() to only draw on events (more efficient)

  # Start Dear ImGui Frame
  igOpenGL3NewFrame()
  igGlfwNewFrame()
  igNewFrame()

  # Draw application
  app.drawMain()

  # Render
  igRender()

  var displayW, displayH: int32
  let bgColor = igColorConvertU32ToFloat4(uint32 WindowBg)

  app.win.getFramebufferSize(displayW.addr, displayH.addr)
  glViewport(0, 0, displayW, displayH)
  glClearColor(bgColor.x, bgColor.y, bgColor.z, bgColor.w)
  glClear(GL_COLOR_BUFFER_BIT)

  igOpenGL3RenderDrawData(igGetDrawData())  

  app.win.makeContextCurrent()
  app.win.swapBuffers()

proc initWindow(app: var App) = 
  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  app.win = glfwCreateWindow(
    app.prefs["win"]["width"].getInt().int32, 
    app.prefs["win"]["height"].getInt().int32, 
    app.config["name"].getString().cstring, 
    icon = false # Do not use default icon
  )

  if app.win == nil:
    quit(-1)

  # Set the window icon
  var icon = initGLFWImage(app.config["iconPath"].getData().readImageFromMemory())
  app.win.setWindowIcon(1, icon.addr)

  app.win.setWindowSizeLimits(app.config["minSize"][0].getInt().int32, app.config["minSize"][1].getInt().int32, GLFW_DONT_CARE, GLFW_DONT_CARE) # minWidth, minHeight, maxWidth, maxHeight

  # If negative pos, center the window in the first monitor
  if app.prefs["win"]["x"].getInt() < 0 or app.prefs["win"]["y"].getInt() < 0:
    var monitorX, monitorY, count: int32
    let monitors = glfwGetMonitors(count.addr)
    let videoMode = monitors[0].getVideoMode()

    monitors[0].getMonitorPos(monitorX.addr, monitorY.addr)
    app.win.setWindowPos(
      monitorX + int32((videoMode.width - int app.prefs["win"]["width"].getInt()) / 2), 
      monitorY + int32((videoMode.height - int app.prefs["win"]["height"].getInt()) / 2)
    )
  else:
    app.win.setWindowPos(app.prefs["win"]["x"].getInt().int32, app.prefs["win"]["y"].getInt().int32)

proc initPrefs(app: var App) = 
  app.prefs = initPrefs(
    path = (app.getCacheDir() / app.config["name"].getString()).changeFileExt("toml"), 
    default = toToml {
      win: {
        x: -1, # Negative numbers center the window
        y: -1,
        width: 1500,
        height: 700
      }, 
      currentView: 1, 
      currentTheme: 0, 
      currentSort: 0, 
      themes: toTTables [classicTheme, darkTheme, lightTheme, cherryTheme], 
      starred: [],  
    }
  )

proc initApp(config: TomlValueRef): App = 
  result = App(
    config: config, 
    currentView: -1, hoveredView: -1, currentTheme: -1, 
    cache: newTTable(), browseCurrentTheme: new TomlTableRef, 
    sizesBuffer: newString(32), colorsBuffer: newString(32), previewBuffer: newString(64), browseBuffer: newString(64), 
    previewProgressDir: 1f, 
  )
  result.initPrefs()
  result.initConfig(result.config["settings"])

  result.switchTheme(int result.prefs["currentTheme"].getInt())
  result.currentSort = int result.prefs["currentSort"].getInt()
  result.currentView = int result.prefs["currentView"].getInt()

proc terminate(app: var App) = 
  var x, y, width, height: int32

  app.win.getWindowPos(x.addr, y.addr)
  app.win.getWindowSize(width.addr, height.addr)
  
  app.prefs{"win", "x"} = x
  app.prefs{"win", "y"} = y
  app.prefs{"win", "width"} = width
  app.prefs{"win", "height"} = height

  app.prefs["currentView"] = app.currentView
  app.prefs["currentSort"] = app.currentSort
  app.prefs["currentTheme"] = app.currentTheme

  app.prefs.save()

proc main() =
  var app = initApp(Toml.decode(configPath.getData(), TomlValueRef))

  # Setup Window
  doAssert glfwInit()
  app.initWindow()
  
  app.win.makeContextCurrent()
  glfwSwapInterval(1) # Enable vsync

  doAssert glInit()

  # Setup Dear ImGui context
  igCreateContext()
  let io = igGetIO()
  io.iniFilename = nil # Disable .ini config file

  # Setup Dear ImGui style using ImStyle
  setStyleFromToml(Toml.decode(app.config["stylePath"].getData(), TomlValueRef))

  # Setup Platform/Renderer backends
  doAssert igGlfwInitForOpenGL(app.win, true)
  doAssert igOpenGL3Init()

  # Load fonts
  app.font = io.fonts.igAddFontFromMemoryTTF(app.config["fontPath"].getData(), app.config["fontSize"].getFloat())

  # Merge ForkAwesome icon font
  var config = utils.newImFontConfig(mergeMode = true)
  var ranges = [FA_Min.uint16,  FA_Max.uint16]

  io.fonts.igAddFontFromMemoryTTF(app.config["iconFontPath"].getData(), app.config["fontSize"].getFloat(), config.addr, ranges[0].addr)

  app.bigFont = io.fonts.igAddFontFromMemoryTTF(app.config["bigFontPath"].getData(), app.config["fontSize"].getFloat() + 2)
  io.fonts.igAddFontFromMemoryTTF(app.config["iconFontPath"].getData(), app.config["fontSize"].getFloat() + 2, config.addr, ranges[0].addr)

  app.sidebarIconFont = io.fonts.igAddFontFromMemoryTTF(app.config["iconFontPath"].getData(), app.config["fontSize"].getFloat() + 18, glyph_ranges = ranges[0].addr)

  # Main loop
  while not app.win.windowShouldClose:
    app.render()

  # Cleanup
  igOpenGL3Shutdown()
  igGlfwShutdown()
  
  igDestroyContext()
  
  app.terminate()
  app.win.destroyWindow()
  glfwTerminate()

when isMainModule:
  main()
