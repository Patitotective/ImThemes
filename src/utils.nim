import std/[strutils, strformat, typetraits, enumutils, macros, times, json, os]
import chroma
import niprefs
import stb_image/read as stbi
import nimgl/[imgui, glfw, opengl]

export enumutils

type
  SettingTypes* = enum
    Input # Input text
    Check # Checkbox
    Slider # Int slider
    FSlider # Float slider
    Spin # Int spin
    FSpin # Float spin
    Combo
    Radio # Radio button
    Color3 # Color edit RGB
    Color4 # Color edit RGBA
    Section

  ImageData* = tuple[image: seq[byte], width, height: int]

  App* = ref object
    win*: GLFWWindow
    font*, bigFont*: ptr ImFont
    prefs*: Prefs
    cache*: PObjectType # Settings cache
    config*: PObjectType # Prefs table
    prefsCache*: PObjectType

    # Views
    currentView*, hoveredView*: int
    
    # Edit view
    currentTheme*: int
    currentExportTab*: int
    themeName*, themeAuthor*: string # Create theme popup
    currentThemeTemplate*: int # Create theme popup
    editing*, saved*, copied*: bool # Editing theme, saved theme, copied export text
    prevAvail*: ImVec2 # Previous avail content
    editSplitterSize1*, editSplitterSize2*: tuple[a, b: float32]
    themeStyle*: ImGuiStyle # Current theme style
    prevThemeStyle*: ImGuiStyle # Current theme style before saving
    # Preview window
    previewSlider*: float32
    previewBuffer*: string
    previewValues*: array[90, float32]
    previewValuesOffset*: int32
    previewRefreshTime*: float32
    previewPhase*: float32
    # Editor
    sizesBuffer*, colorsBuffer*: string

    # Browse view
    browseSplitterSize*: tuple[a, b: float32]

proc `+`*(vec1, vec2: ImVec2): ImVec2 = 
  ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)

proc `-`*(vec1, vec2: ImVec2): ImVec2 = 
  ImVec2(x: vec1.x - vec2.x, y: vec1.y - vec2.y)

proc `*`*(vec1, vec2: ImVec2): ImVec2 = 
  ImVec2(x: vec1.x * vec2.x, y: vec1.y * vec2.y)

proc `/`*(vec1, vec2: ImVec2): ImVec2 = 
  ImVec2(x: vec1.x / vec2.x, y: vec1.y / vec2.y)

proc `+`*(vec: ImVec2, val: float32): ImVec2 = 
  ImVec2(x: vec.x + val, y: vec.y + val)

proc `-`*(vec: ImVec2, val: float32): ImVec2 = 
  ImVec2(x: vec.x - val, y: vec.y - val)

proc `*`*(vec: ImVec2, val: float32): ImVec2 = 
  ImVec2(x: vec.x * val, y: vec.y * val)

proc `/`*(vec: ImVec2, val: float32): ImVec2 = 
  ImVec2(x: vec.x / val, y: vec.y / val)

proc `+=`*(vec1: var ImVec2, vec2: ImVec2) = 
  vec1.x += vec2.x
  vec1.y += vec2.y

proc `-=`*(vec1: var ImVec2, vec2: ImVec2) = 
  vec1.x -= vec2.x
  vec1.y -= vec2.y

proc `*=`*(vec1: var ImVec2, vec2: ImVec2) = 
  vec1.x *= vec2.x
  vec1.y *= vec2.y

proc `/=`*(vec1: var ImVec2, vec2: ImVec2) = 
  vec1.x /= vec2.x
  vec1.y /= vec2.y

proc igVec2*(x, y: float32): ImVec2 = ImVec2(x: x, y: y)

proc igVec4*(x, y, z, w: float32): ImVec4 = ImVec4(x: x, y: y, z: z, w: w)

proc igVec4*(color: Color): ImVec4 = ImVec4(x: color.r, y: color.g, z: color.b, w: color.a)

proc igHSV*(h, s, v: float32, a: float32 = 1f): ImColor = 
  result.addr.hSVNonUDT(h, s, v, a)

proc igGetContentRegionAvail*(): ImVec2 = 
  igGetContentRegionAvailNonUDT(result.addr)

proc igGetWindowPos*(): ImVec2 = 
  igGetWindowPosNonUDT(result.addr)

proc igGetWindowSize*(): ImVec2 = 
  igGetWindowSizeNonUDT(result.addr)

proc igCalcTextSize*(text: cstring, text_end: cstring = nil, hide_text_after_double_hash: bool = false, wrap_width: float32 = -1.0'f32): ImVec2 = 
  igCalcTextSizeNonUDT(result.addr, text, text_end, hide_text_after_double_hash, wrap_width)

proc igColorConvertU32ToFloat4*(color: uint32): ImVec4 = 
  igColorConvertU32ToFloat4NonUDT(result.addr, color)

proc igGetColor*(color: ImGuiCol): Color = 
  let vec = igColorConvertU32ToFloat4(igGetColorU32(color))
  Color(r: vec.x, g: vec.y, b: vec.z, a: vec.w)

proc igGetCursorPos*(): ImVec2 = 
  igGetCursorPosNonUDT(result.addr)

proc igGetItemRectMin*(): ImVec2 = 
  igGetItemRectMinNonUDT(result.addr)

proc igCalcItemSize*(size: ImVec2, default_w: float32, default_h: float32): ImVec2 = 
  igCalcItemSizeNonUDT(result.addr, size, default_w, default_h)

proc getCenter*(self: ptr ImGuiViewport): ImVec2 = 
  getCenterNonUDT(result.addr, self)

proc centerCursorX*(width: float32, align: float = 0.5f, availWidth: float32 = igGetContentRegionAvail().x) = 
  let off = (availWidth - width) * align
  
  if off > 0:
    igSetCursorPosX(igGetCursorPosX() + off)

proc igHelpMarker*(text: string, sameLineBefore = true) =
  if sameLineBefore: igSameLine() 
  igTextDisabled("(?)")
  if igIsItemHovered():
    igBeginTooltip()
    igPushTextWrapPos(igGetFontSize() * 35.0)
    igTextUnformatted(text)
    igPopTextWrapPos()
    igEndTooltip()

proc newImFontConfig*(mergeMode = false): ImFontConfig =
  result.fontDataOwnedByAtlas = true
  result.fontNo = 0
  result.oversampleH = 3
  result.oversampleV = 1
  result.pixelSnapH = true
  result.glyphMaxAdvanceX = float.high
  result.rasterizerMultiply = 1.0
  result.mergeMode = mergeMode

proc igAddFontFromMemoryTTF*(self: ptr ImFontAtlas, data: string, size_pixels: float32, font_cfg: ptr ImFontConfig = nil, glyph_ranges: ptr ImWchar = nil): ptr ImFont {.discardable.} = 
  let igFontStr = cast[cstring](igMemAlloc(data.len.uint))
  igFontStr[0].unsafeAddr.copyMem(data[0].unsafeAddr, data.len)
  result = self.addFontFromMemoryTTF(igFontStr, data.len.int32, sizePixels, font_cfg, glyph_ranges)

proc igSplitter*(split_vertically: bool, thickness: float32, size1, size2: ptr float32, min_size1, min_size2: float32, splitter_long_axis_size = -1f): bool {.discardable.} = 
  let context = igGetCurrentContext()
  let window = context.currentWindow
  let id = window.getID("##Splitter")
  var bb: ImRect
  bb.min = window.dc.cursorPos + (if split_vertically: igVec2(size1[], 0f) else: igVec2(0f, size1[]))
  bb.max = bb.min + igCalcItemSize(if split_vertically: igVec2(thickness, splitter_long_axis_size) else: igVec2(splitter_long_axis_size, thickness), 0f, 0f)
  result = igSplitterBehavior(bb, id, if split_vertically: ImGuiAxis.X else: ImGuiAxis.Y, size1, size2, min_size1, min_size2, 0f)

# To be able to print large holey enums
macro enumFullRange*(a: typed): untyped =
  newNimNode(nnkBracket).add(a.getType[1][1..^1])

iterator items*(T: typedesc[HoleyEnum]): T =
  for x in T.enumFullRange:
    yield x

proc getEnumValues*[T: enum](): seq[string] = 
  for i in T:
    result.add $i

proc parseEnum*[T: enum](node: PrefsNode): T = 
  case node.kind:
  of PInt:
    result = T(node.getInt())
  of PString:
    try:
      result = parseEnum[T](node.getString().capitalizeAscii())
    except:
      raise newException(ValueError, &"Invalid enum value {node.getString()} for {$T}. Valid values are {$getEnumValues[T]()}")
  else:
    raise newException(ValueError, &"Invalid kind {node.kind} for an enum. Valid kinds are PInt or PString")

proc makeFlags*[T: enum](flags: varargs[T]): T =
  ## Mix multiple flags of a specific enum
  var res = 0
  for x in flags:
    res = res or int(x)

  result = T res

proc getFlags*[T: enum](node: PrefsNode): T = 
  ## Similar to parseEnum but this one mixes multiple enum values if node.kind == PSeq
  case node.kind:
  of PString, PInt:
    result = parseEnum[T](node)
  of PSeq:
    var flags: seq[T]
    for i in node.getSeq():
      flags.add parseEnum[T](i)

    result = makeFlags(flags)
  else:
    raise newException(ValueError, "Invalid kind {node.kind} for {$T} enum. Valid kinds are PInt, PString or PSeq") 

proc parseColor3*(node: PrefsNode): array[3, float32] = 
  case node.kind
  of PString:
    let color = node.getString().parseHtmlColor()
    result[0] = color.r
    result[1] = color.g
    result[2] = color.b 
  of PSeq:
    result[0] = node[0].getFloat()
    result[1] = node[1].getFloat()
    result[2] = node[2].getFloat()
  else:
    raise newException(ValueError, &"Invalid color RGB {node}")

proc parseColor4*(node: PrefsNode): array[4, float32] = 
  case node.kind
  of PString:
    let color = node.getString().replace("#").parseHexAlpha()
    result[0] = color.r
    result[1] = color.g
    result[2] = color.b 
    result[3] = color.a
  of PSeq:
    result[0] = node[0].getFloat()
    result[1] = node[1].getFloat()
    result[2] = node[2].getFloat()
    result[3] = node[3].getFloat()
  else:
    raise newException(ValueError, &"Invalid color RGBA {node}")

proc initGLFWImage*(data: ImageData): GLFWImage = 
  result = GLFWImage(pixels: cast[ptr cuchar](data.image[0].unsafeAddr), width: int32 data.width, height: int32 data.height)

proc readImageFromMemory*(data: string): ImageData = 
  var channels: int
  result.image = stbi.loadFromMemory(cast[seq[byte]](data), result.width, result.height, channels, stbi.Default)

proc loadTextureFromData*(data: var ImageData, outTexture: var GLuint) =
    # Create a OpenGL texture identifier
    glGenTextures(1, outTexture.addr)
    glBindTexture(GL_TEXTURE_2D, outTexture)

    # Setup filtering parameters for display
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint) # This is required on WebGL for non power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint) # Same

    # Upload pixels into texture
    # if defined(GL_UNPACK_ROW_LENGTH) && !defined(__EMSCRIPTEN__)
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)

    glTexImage2D(GL_TEXTURE_2D, GLint 0, GL_RGBA.GLint, GLsizei data.width, GLsizei data.height, GLint 0, GL_RGBA, GL_UNSIGNED_BYTE, data.image[0].addr)

proc openURL*(url: string) = 
  when defined(MacOS) or defined(MacOSX):
    discard execShellCmd("open " & url)
  elif defined(Windows):
    discard execShellCmd("start " & url)
  else:
    discard execShellCmd("xdg-open " & url)

proc removeInside*(text: string, open, close: char): tuple[text: string, inside: string] = 
  ## Remove the characters inside open..close from text, return text and the removed characters
  runnableExamples:
    assert "Hello<World>".removeInside('<', '>') == ("Hello", "World")
  var inside = false
  for i in text:
    if i == open:
      inside = true
      continue

    if not inside:
      result.text.add i

    if i == close:
      inside = false

    if inside:
      result.inside.add i

proc initconfig*(app: var App, settings: PrefsNode, parent = "", overwrite = false) = 
  # Add the preferences with the values defined in config["settings"]
  for name, data in settings: 
    let settingType = parseEnum[SettingTypes](data["type"])
    if settingType == Section:
      app.initConfig(data["content"], parent = name)  
    elif parent.len > 0:
      if parent notin app.prefsCache or overwrite:
        app.prefsCache[parent] = newPObject()
      elif name notin app.prefsCache[parent] or overwrite:
        app.prefsCache[parent][name] = data["default"]
    else:
      if name notin app.prefsCache or overwrite:
        app.prefsCache[name] = data["default"]

proc newString*(lenght: int, default: string): string = 
  result = newString(lenght)
  result[0..default.high] = default

proc cleanString*(str: string): string = 
  if '\0' in str:
    str[0..<str.find('\0')].strip()
  else:
    str.strip()

proc pushString*(str: var string, val: string) = 
  if val.len < str.len:
    str[0..val.len] = val & '\0'
  else:
    str[0..str.high] = val[0..str.high]

proc updatePrefs*(app: var App) = 
  # Update the values depending on the preferences here
  echo "Updating preferences..."

proc color*(vec: ImVec4): Color = 
  color(vec.x, vec.y, vec.z, vec.w)

proc toVec2(node: seq[JsonNode]): ImVec2 = 
  ImVec2(x: node[0].getFloat(), y: node[1].getFloat())

proc toVec4(node: seq[JsonNode]): ImVec4 = 
  ImVec4(x: node[0].getFloat(), y: node[1].getFloat(), z: node[2].getFloat(), w: node[3].getFloat())

proc toArray(vec: ImVec2): array[2, float32] = 
  [vec.x, vec.y]

proc toArray(vec: ImVec4): array[4, float32] = 
  [vec.x, vec.y, vec.z, vec.w]

proc toJson*(style: ImGuiStyle): JsonNode = 
  %* {
    "alpha": style.alpha, 
    "disabledAlpha": style.disabledAlpha, 
    "windowPadding": style.windowPadding.toArray(), 
    "windowRounding": style.windowRounding, 
    "windowBorderSize": style.windowBorderSize, 
    "windowMinSize": style.windowMinSize.toArray(), 
    "windowTitleAlign": style.windowTitleAlign.toArray(), 
    "windowMenuButtonPosition": $style.windowMenuButtonPosition, 
    "childRounding": style.childRounding, 
    "childBorderSize": style.childBorderSize, 
    "popupRounding": style.popupRounding, 
    "popupBorderSize": style.popupBorderSize, 
    "framePadding": style.framePadding.toArray(), 
    "frameRounding": style.frameRounding, 
    "frameBorderSize": style.frameBorderSize, 
    "itemSpacing": style.itemSpacing.toArray(), 
    "itemInnerSpacing": style.itemInnerSpacing.toArray(), 
    "cellPadding": style.cellPadding.toArray(), 
    "indentSpacing": style.indentSpacing, 
    "columnsMinSpacing": style.columnsMinSpacing, 
    "scrollbarSize": style.scrollbarSize, 
    "scrollbarRounding": style.scrollbarRounding, 
    "grabMinSize": style.grabMinSize, 
    "grabRounding": style.grabRounding, 
    "tabRounding": style.tabRounding, 
    "tabBorderSize": style.tabBorderSize, 
    "tabMinWidthForCloseButton": style.tabMinWidthForCloseButton, 
    "colorButtonPosition": $style.colorButtonPosition, 
    "buttonTextAlign": style.buttonTextAlign.toArray(), 
    "selectableTextAlign": style.selectableTextAlign.toArray(), 
    "colors": {
      "Text": style.colors[ord ImGuiCol.Text].toArray(), 
      "TextDisabled": style.colors[ord ImGuiCol.TextDisabled].toArray(), 
      "WindowBg": style.colors[ord ImGuiCol.WindowBg].toArray(), 
      "ChildBg": style.colors[ord ImGuiCol.ChildBg].toArray(), 
      "PopupBg": style.colors[ord ImGuiCol.PopupBg].toArray(), 
      "Border": style.colors[ord ImGuiCol.Border].toArray(), 
      "BorderShadow": style.colors[ord ImGuiCol.BorderShadow].toArray(), 
      "FrameBg": style.colors[ord ImGuiCol.FrameBg].toArray(), 
      "FrameBgHovered": style.colors[ord ImGuiCol.FrameBgHovered].toArray(), 
      "FrameBgActive": style.colors[ord ImGuiCol.FrameBgActive].toArray(), 
      "TitleBg": style.colors[ord ImGuiCol.TitleBg].toArray(), 
      "TitleBgActive": style.colors[ord ImGuiCol.TitleBgActive].toArray(), 
      "TitleBgCollapsed": style.colors[ord ImGuiCol.TitleBgCollapsed].toArray(),
      "MenuBarBg": style.colors[ord ImGuiCol.MenuBarBg].toArray(), 
      "ScrollbarBg": style.colors[ord ImGuiCol.ScrollbarBg].toArray(), 
      "ScrollbarGrab": style.colors[ord ImGuiCol.ScrollbarGrab].toArray(), 
      "ScrollbarGrabHovered": style.colors[ord ImGuiCol.ScrollbarGrabHovered].toArray(), 
      "ScrollbarGrabActive": style.colors[ord ImGuiCol.ScrollbarGrabActive].toArray(), 
      "CheckMark": style.colors[ord ImGuiCol.CheckMark].toArray(), 
      "SliderGrab": style.colors[ord ImGuiCol.SliderGrab].toArray(), 
      "SliderGrabActive": style.colors[ord ImGuiCol.SliderGrabActive].toArray(), 
      "Button": style.colors[ord ImGuiCol.Button].toArray(), 
      "ButtonHovered": style.colors[ord ImGuiCol.ButtonHovered].toArray(), 
      "ButtonActive": style.colors[ord ImGuiCol.ButtonActive].toArray(), 
      "Header": style.colors[ord ImGuiCol.Header].toArray(), 
      "HeaderHovered": style.colors[ord ImGuiCol.HeaderHovered].toArray(), 
      "HeaderActive": style.colors[ord ImGuiCol.HeaderActive].toArray(), 
      "Separator": style.colors[ord ImGuiCol.Separator].toArray(), 
      "SeparatorHovered": style.colors[ord ImGuiCol.SeparatorHovered].toArray(), 
      "SeparatorActive": style.colors[ord ImGuiCol.SeparatorActive].toArray(), 
      "ResizeGrip": style.colors[ord ImGuiCol.ResizeGrip].toArray(), 
      "ResizeGripHovered": style.colors[ord ImGuiCol.ResizeGripHovered].toArray(), 
      "ResizeGripActive": style.colors[ord ImGuiCol.ResizeGripActive].toArray(), 
      "Tab": style.colors[ord ImGuiCol.Tab].toArray(), 
      "TabHovered": style.colors[ord ImGuiCol.TabHovered].toArray(), 
      "TabActive": style.colors[ord ImGuiCol.TabActive].toArray(), 
      "TabUnfocused": style.colors[ord ImGuiCol.TabUnfocused].toArray(), 
      "TabUnfocusedActive": style.colors[ord ImGuiCol.TabUnfocusedActive].toArray(), 
      "PlotLines": style.colors[ord ImGuiCol.PlotLines].toArray(), 
      "PlotLinesHovered": style.colors[ord ImGuiCol.PlotLinesHovered].toArray(), 
      "PlotHistogram": style.colors[ord ImGuiCol.PlotHistogram].toArray(), 
      "PlotHistogramHovered": style.colors[ord ImGuiCol.PlotHistogramHovered].toArray(), 
      "TableHeaderBg": style.colors[ord ImGuiCol.TableHeaderBg].toArray(), 
      "TableBorderStrong": style.colors[ord ImGuiCol.TableBorderStrong].toArray(), 
      "TableBorderLight": style.colors[ord ImGuiCol.TableBorderLight].toArray(), 
      "TableRowBg": style.colors[ord ImGuiCol.TableRowBg].toArray(), 
      "TableRowBgAlt": style.colors[ord ImGuiCol.TableRowBgAlt].toArray(), 
      "TextSelectedBg": style.colors[ord ImGuiCol.TextSelectedBg].toArray(), 
      "DragDropTarget": style.colors[ord ImGuiCol.DragDropTarget].toArray(), 
      "NavHighlight": style.colors[ord ImGuiCol.NavHighlight].toArray(), 
      "NavWindowingHighlight": style.colors[ord ImGuiCol.NavWindowingHighlight].toArray(), 
      "NavWindowingDimBg": style.colors[ord ImGuiCol.NavWindowingDimBg].toArray(), 
      "ModalWindowDimBg": style.colors[ord ImGuiCol.ModalWindowDimBg].toArray(), 
    }
  }

proc colorsFromJson(node: JsonNode): array[53, ImVec4] = 
  for col in ImGuiCol:
    if $col in node:
      result[ord col] = node[$col].getElems().toVec4()

proc styleFromJson*(node: JsonNode): ImGuiStyle = 
  if "alpha" in node: result.alpha = node["alpha"].getFloat()
  if "disabledAlpha" in node: result.disabledAlpha = node["disabledAlpha"].getFloat()
  if "windowPadding" in node: result.windowPadding = node["windowPadding"].getElems().toVec2()
  if "windowRounding" in node: result.windowRounding = node["windowRounding"].getFloat()
  if "windowBorderSize" in node: result.windowBorderSize = node["windowBorderSize"].getFloat()
  if "windowMinSize" in node: result.windowMinSize = node["windowMinSize"].getElems().toVec2()
  if "windowTitleAlign" in node: result.windowTitleAlign = node["windowTitleAlign"].getElems().toVec2()
  if "windowMenuButtonPosition" in node: result.windowMenuButtonPosition = parseEnum[ImGuiDir](node["windowMenuButtonPosition"].getStr().capitalizeAscii())
  if "childRounding" in node: result.childRounding = node["childRounding"].getFloat()
  if "childBorderSize" in node: result.childBorderSize = node["childBorderSize"].getFloat()
  if "popupRounding" in node: result.popupRounding = node["popupRounding"].getFloat()
  if "popupBorderSize" in node: result.popupBorderSize = node["popupBorderSize"].getFloat()
  if "framePadding" in node: result.framePadding = node["framePadding"].getElems().toVec2()
  if "frameRounding" in node: result.frameRounding = node["frameRounding"].getFloat()
  if "frameBorderSize" in node: result.frameBorderSize = node["frameBorderSize"].getFloat()
  if "itemSpacing" in node: result.itemSpacing = node["itemSpacing"].getElems().toVec2()
  if "itemInnerSpacing" in node: result.itemInnerSpacing = node["itemInnerSpacing"].getElems().toVec2()
  if "cellPadding" in node: result.cellPadding = node["cellPadding"].getElems().toVec2()
  if "indentSpacing" in node: result.indentSpacing = node["indentSpacing"].getFloat()
  if "columnsMinSpacing" in node: result.columnsMinSpacing = node["columnsMinSpacing"].getFloat()
  if "scrollbarSize" in node: result.scrollbarSize = node["scrollbarSize"].getFloat()
  if "scrollbarRounding" in node: result.scrollbarRounding = node["scrollbarRounding"].getFloat()
  if "grabMinSize" in node: result.grabMinSize = node["grabMinSize"].getFloat()
  if "grabRounding" in node: result.grabRounding = node["grabRounding"].getFloat()
  if "tabRounding" in node: result.tabRounding = node["tabRounding"].getFloat()
  if "tabBorderSize" in node: result.tabBorderSize = node["tabBorderSize"].getFloat()
  if "tabMinWidthForCloseButton" in node: result.tabMinWidthForCloseButton = node["tabMinWidthForCloseButton"].getFloat()
  if "colorButtonPosition" in node: result.colorButtonPosition = parseEnum[ImGuiDir](node["colorButtonPosition"].getStr().capitalizeAscii())
  if "buttonTextAlign" in node: result.buttonTextAlign = node["buttonTextAlign"].getElems().toVec2()
  if "selectableTextAlign" in node: result.selectableTextAlign = node["selectableTextAlign"].getElems().toVec2()
  if "colors" in node: result.colors = node["colors"].colorsFromJson()
