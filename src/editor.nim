import std/strutils
import nimgl/imgui
import utils

const alignCount = 26

proc passFilter(buffer: string, str: string): bool = 
  buffer.cleanString().toLowerAscii() in str.toLowerAscii()

template drawVec2StyleVar(styleVar: untyped, minVal: float32 = 0, maxVal: float32 = 12, format = "%.1f", help = "") = 
  if sizesFilterBuffer.passFilter(astToStr(styleVar)):
    var styleVar = [style.styleVar.x, style.styleVar.y]
    igText(cstring (astToStr(styleVar) & ": ").capitalizeAscii().alignLeft(alignCount)); igSameLine()
    if igSliderFloat2(cstring "##" & astToStr(styleVar), styleVar, minVal, maxVal, format):
      style.styleVar = ImVec2(x: styleVar[0], y: styleVar[1])

    if help.len > 0: igHelpMarker(help)

template drawFloatStyleVar(styleVar: untyped, minVal: float32 = 0, maxVal: float32 = 12, format = "%.1f", help = "") = 
  if sizesFilterBuffer.passFilter(astToStr(styleVar)):
    igText(cstring (astToStr(styleVar) & ": ").capitalizeAscii().alignLeft(alignCount)); igSameLine()
    igSliderFloat(cstring "##" & astToStr(styleVar), style.styleVar.addr, minVal, maxVal, format)

    if help.len > 0: igHelpMarker(help)

template drawComboStyleVar[T: enum](styleVar: untyped, enumElems: openArray[T], help = "") = 
  if sizesFilterBuffer.passFilter(astToStr(styleVar)):
    let currentItem = style.styleVar.int32
    igText(cstring (astToStr(styleVar) & ": ").capitalizeAscii().alignLeft(alignCount)); igSameLine()
    if igBeginCombo(cstring "##" & astToStr(styleVar), cstring $T(currentItem)):
      for elem in enumElems:
        if igSelectable(cstring $elem, currentItem == elem.int32):  
          style.styleVar = elem

      igEndCombo()

    if help.len > 0: igHelpMarker(help)

template drawSizesTab() = 
  igDummy(igVec2(0, 7))

  igInputTextWithHint("##filter", "Filter properties", cstring sizesFilterBuffer, 32)
  igDummy(igVec2(0, 7)); igSeparator(); igDummy(igVec2(0, 7))

  drawFloatStyleVar(alpha, 0.1, 1, format = "%.2f", help = "Global alpha applies to everything in Dear ImGui.")
  drawFloatStyleVar(disabledAlpha, 0.1, 1, format = "%.2f", help = "Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawVec2StyleVar(windowPadding, help = "Padding within a window.")
  drawFloatStyleVar(windowRounding, help = "Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.")
  drawFloatStyleVar(windowBorderSize, 0, 1, "%.0f", help = "Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).")
  drawVec2StyleVar(windowMinSize, 1, 20, help = "Minimum window size. This is a global setting. If you want to constraint individual windows, use SetNextWindowSizeConstraints().")
  drawVec2StyleVar(windowTitleAlign, help = "Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawFloatStyleVar(childRounding, help = "Radius of child window corners rounding. Set to 0.0f to have rectangular windows.")
  drawFloatStyleVar(childBorderSize, 0, 1, "%.0f", help = "Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawFloatStyleVar(popupRounding, help = "Radius of popup window corners rounding. (Note that tooltip windows use WindowRounding)")
  drawFloatStyleVar(popupBorderSize, 0, 1, "%.0f", help = "Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawVec2StyleVar(framePadding, help = "Padding within a framed rectangle (used by most widgets).")
  drawFloatStyleVar(frameRounding, help = "Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).")
  drawFloatStyleVar(frameBorderSize, 0, 1, "%.0f", help = "Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawVec2StyleVar(itemSpacing, help = "Horizontal and vertical spacing between widgets/lines.")
  drawVec2StyleVar(itemInnerSpacing, help = "Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawFloatStyleVar(scrollbarSize, help = "Width of the vertical scrollbar, Height of the horizontal scrollbar.")
  drawFloatStyleVar(scrollbarRounding, help = "Radius of grab corners for scrollbar.")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawFloatStyleVar(grabMinSize, help = "Minimum width/height of a grab box for slider/scrollbar.")
  drawFloatStyleVar(grabRounding, help = "Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawComboStyleVar(windowMenuButtonPosition, [ImGuiDir.None, ImGuiDir.Left, ImGuiDir.Right], help = "Side of the collapsing/docking button in the title bar (None/Left/Right). Defaults to ImGuiDir_Left.")
  drawComboStyleVar(colorButtonPosition, [ImGuiDir.None, ImGuiDir.Left, ImGuiDir.Right], help = "Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.")
  drawVec2StyleVar(buttonTextAlign, help = "Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).")
  drawVec2StyleVar(selectableTextAlign, help = "Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.")
  if sizesFilterBuffer.cleanString().len == 0:
    igDummy(igVec2(0, 10))
  drawFloatStyleVar(tabBorderSize, 0, 1, "%.0f", help = "Thickness of border around tabs.")
  drawFloatStyleVar(tabRounding, help = "Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.")
  drawFloatStyleVar(indentSpacing, help = "Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).")
  drawVec2StyleVar(cellPadding, help = "Padding within a table cell")

template drawColorsTab() = 
  igDummy(igVec2(0, 7))

  var colorsFilterBuffer {.global.} = newString(32)
  igInputTextWithHint("##filter", "Filter colors", cstring colorsFilterBuffer, 32)
  igDummy(igVec2(0, 7)); igSeparator(); igDummy(igVec2(0, 7))

  if igBeginChild("##colors"):
    for color in ImGuiCol:
      if not colorsFilterBuffer.passFilter($color):
        continue
      
      var colorArray = [style.colors[ord color].x, style.colors[ord color].y, style.colors[ord color].z, style.colors[ord color].w]
      
      igText(cstring ($color & ": ").alignLeft(alignCount)); igSameLine()
      if igColorEdit4(cstring "##" & $color, colorArray, makeFlags(AlphaPreview, AlphaBar)):
        style.colors[ord color] = igVec4(colorArray[0], colorArray[1], colorArray[2], colorArray[3])

    igEndChild()

proc drawImStyleEditor*(refStyle: ptr ImGuiStyle = nil) = 
  var sizesFilterBuffer {.global.} = newString(32)
  let style = if refStyle.isNil: igGetStyle() else: refStyle

  if igBeginTabBar("##tabs"):
    if igBeginTabItem("Sizes"):
      drawSizesTab()
      igEndTabItem()

    if igBeginTabItem("Colors"):
      drawColorsTab()
      igEndTabItem()

    igEndTabBar()
