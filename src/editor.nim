import std/[sequtils, strutils]
import nimgl/imgui
import utils

proc drawSizesTab(app: var App, style: var ImGuiStyle, alignWidth: float32) = 
  igDummy(igVec2(0, 5))

  igInputTextWithHint("##filter", "Filter properties", cstring app.sizesTabFilter, 32)
  igDummy(igVec2(0, 5)); igSeparator(); igDummy(igVec2(0, 5))

  if igBeginChild("##properties", flags = HorizontalScrollbar):
    for name, field in style.fieldPairs:
      when name in styleProps:
        if app.sizesTabFilter.passFilter(name):
          igText(cstring name.capitalizeAscii() & ": "); igSameLine(0, 0)
          igDummy(igVec2(alignWidth - igCalcTextSize(cstring name.capitalizeAscii() & ": ").x, 0)); igSameLine(0, 0)

          let minVal = 
            if name.toLowerAscii().endsWith("alpha") or name.toLowerAscii() == "scrollbarsize":
              0.1f
            else:
              0f
          let maxVal = 
            if name.toLowerAscii().endsWith("bordersize") or name.toLowerAscii().endsWith("alpha") or name.toLowerAscii().endsWith("align"):
              1f
            else:
              20f

          let format = 
            if name.toLowerAscii().endsWith("bordersize"):
              "%.0f"
            else:
              "%.1f"

          when field is float32:
            igSliderFloat(cstring "##" & name, field.addr, minVal, maxVal, cstring format)
          elif field is ImVec2:
            var arrayVec = [field.x, field.y]

            if igSliderFloat2(cstring "##" & name, arrayVec, minVal, maxVal, cstring format):
              field = igVec2(arrayVec[0], arrayVec[1])
          elif field is ImGuiDir:
            let currentItem = ord field

            if igBeginCombo(cstring "##" & name, cstring $currentItem.ImGuiDir):
              for dir in [ImGuiDir.None, ImGuiDir.Left, ImGuiDir.Right]:
                if igSelectable(cstring $dir, currentItem == dir.int32):  
                  field = dir

              igEndCombo()

          igHelpMarker(stylePropsHelp[styleProps.find(name)])

  igEndChild()

proc drawColorTab(app: var App, style: var ImGuiStyle) = 
  igDummy(igVec2(0, 5))

  igInputTextWithHint("##filter", "Filter colors", cstring app.colorsTabFilter, 32)
  igDummy(igVec2(0, 5)); igSeparator(); igDummy(igVec2(0, 5))

  if igBeginChild("##colors"):
    for color in ImGuiCol:
      if not app.colorsTabFilter.passFilter($color):
        continue
      
      var colorArray = [style.colors[ord color].x, style.colors[ord color].y, style.colors[ord color].z, style.colors[ord color].w]

      if igColorEdit4(cstring "##" & $color, colorArray, makeFlags(AlphaPreviewHalf, AlphaBar)):
        style.colors[ord color] = igVec4(colorArray[0], colorArray[1], colorArray[2], colorArray[3])
  
      igSameLine(); igText(cstring $color)

  igEndChild()

proc drawEditor*(app: var App, style: var ImGuiStyle) = 
  if igBeginTabBar("##tabs"):
    if igBeginTabItem("Sizes"):
      app.drawSizesTab(style, styleProps.mapIt(igCalcTextSize(cstring it & ": ").x).max())
      igEndTabItem()

    if igBeginTabItem("Color"):
      app.drawColorTab(style)
      igEndTabItem()

    igEndTabBar()
