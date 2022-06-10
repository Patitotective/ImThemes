import std/strutils
import nimgl/imgui
import utils

const alignCount = 28 # For the properties

proc drawSizesTab(app: var App, style: var ImGuiStyle) = 
  igDummy(igVec2(0, 5))

  igInputTextWithHint("##filter", "Filter properties", cstring app.sizesBuffer, 32)
  igDummy(igVec2(0, 5)); igSeparator(); igDummy(igVec2(0, 5))

  if igBeginChild("##properties"):
    for name, field in style.fieldPairs:
      when name in styleProps:
        if app.sizesBuffer.passFilter(name):
          igText(cstring capitalizeAscii(name & ": ").alignLeft(alignCount)); igSameLine()
          
          let minVal = 
            if name.toLowerAscii().endsWith("alpha"):
              0.1f
            else:
              0f
          let maxVal = 
            if name.toLowerAscii().endsWith("bordersize") or name.toLowerAscii().endsWith("alpha"):
              1f
            else:
              20f

          when field is float32:
            igSliderFloat(cstring "##" & name, field.addr, minVal, maxVal, "%.1f")
          elif field is ImVec2:
            var arrayVec = [field.x, field.y]

            if igSliderFloat2(cstring "##" & name, arrayVec, minVal, maxVal, "%.1f"):
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

proc drawColorsTab(app: var App, style: var ImGuiStyle) = 
  igDummy(igVec2(0, 5))

  igInputTextWithHint("##filter", "Filter colors", cstring app.colorsBuffer, 32)
  igDummy(igVec2(0, 5)); igSeparator(); igDummy(igVec2(0, 5))

  if igBeginChild("##colors"):
    for color in ImGuiCol:
      if not app.colorsBuffer.passFilter($color):
        continue
      
      var colorArray = [style.colors[ord color].x, style.colors[ord color].y, style.colors[ord color].z, style.colors[ord color].w]

      if igColorEdit4(cstring "##" & $color, colorArray, makeFlags(AlphaPreviewHalf, AlphaBar)):
        style.colors[ord color] = igVec4(colorArray[0], colorArray[1], colorArray[2], colorArray[3])
  
      igSameLine(); igText(cstring $color)

  igEndChild()

proc drawEditor*(app: var App, style: var ImGuiStyle) = 
  if igBeginTabBar("##tabs"):
    if igBeginTabItem("Sizes"):
      app.drawSizesTab(style)
      igEndTabItem()

    if igBeginTabItem("Colors"):
      app.drawColorsTab(style)
      igEndTabItem()

    igEndTabBar()
