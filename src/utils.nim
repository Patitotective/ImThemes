import std/[strutils, strformat, typetraits, enumutils, macros, math, times, json, os]
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
    previewValuesOffset*: int32
    previewRefreshTime*: float32
    previewPhase*: float32
    previewValues*: array[90, float32]
    previewCol*: array[4, float32]
    # Editor
    sizesBuffer*, colorsBuffer*: string

    # Browse view
    feed*: seq[JsonNode]
    browseSplitterSize*: tuple[a, b: float32]

const styleProps* = ["alpha", "disabledAlpha", "windowPadding", "windowRounding", "windowBorderSize", "windowMinSize", "windowTitleAlign", "windowMenuButtonPosition", "childRounding", "childBorderSize", "popupRounding", "popupBorderSize", "framePadding", "frameRounding", "frameBorderSize", "itemSpacing", "itemInnerSpacing", "cellPadding", "indentSpacing", "columnsMinSpacing", "scrollbarSize", "scrollbarRounding", "grabMinSize", "grabRounding", "tabRounding", "tabBorderSize", "tabMinWidthForCloseButton", "colorButtonPosition", "buttonTextAlign", "selectableTextAlign"]
const stylePropsHelp* = ["Global alpha applies to everything in Dear ImGui.", "Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.", "Padding within a window", "Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.", "Thickness of border around windows. Generally set to 0.0f or 1.0f. Other values not well tested.", "Minimum window size", "Alignment for title bar text", "Position of the collapsing/docking button in the title bar (left/right). Defaults to ImGuiDir_Left.", "Radius of child window corners rounding. Set to 0.0f to have rectangular child windows", "Thickness of border around child windows. Generally set to 0.0f or 1.0f. Other values not well tested.", "Radius of popup window corners rounding. Set to 0.0f to have rectangular child windows", "Thickness of border around popup or tooltip windows. Generally set to 0.0f or 1.0f. Other values not well tested.", "Padding within a framed rectangle (used by most widgets)", "Radius of frame corners rounding. Set to 0.0f to have rectangular frames (used by most widgets).", "Thickness of border around frames. Generally set to 0.0f or 1.0f. Other values not well tested.", "Horizontal and vertical spacing between widgets/lines", "Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label)", "Padding within a table cell", "Horizontal spacing when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).", "Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).", "Width of the vertical scrollbar, Height of the horizontal scrollbar", "Radius of grab corners rounding for scrollbar", "Minimum width/height of a grab box for slider/scrollbar", "Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.", "Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.", "Thickness of border around tabs.", "Minimum width for close button to appears on an unselected tab when hovered. Set to 0.0f to always show when hovering, set to FLT_MAX to never show close button unless selected.", "Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.", "Alignment of button text when button is larger than text.", "Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line."]

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

proc igCenterCursorX*(width: float32, align: float = 0.5f, avail = igGetContentRegionAvail().x) = 
  let off = (avail - width) * align
  
  if off > 0:
    igSetCursorPosX(igGetCursorPosX() + off)

proc igCenterCursorY*(height: float32, align: float = 0.5f, avail = igGetContentRegionAvail().y) = 
  let off = (avail - height) * align
  
  if off > 0:
    igSetCursorPosY(igGetCursorPosY() + off)

proc igCenterCursor*(size: ImVec2, alignX: float = 0.5f, alignY: float = 0.5f, avail = igGetContentRegionAvail()) = 
  igCenterCursorX(size.x, alignX, avail.x)
  igCenterCursorY(size.y, alignY, avail.y)

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

proc igSpinner*(label: string, radius: float, thickness: float32, color: uint32) = 
  let window = igGetCurrentWindow()
  if window.skipItems:
    return
  
  let
    context = igGetCurrentContext()
    style = context.style
    id = igGetID(label)
  
    pos = window.dc.cursorPos
    size = ImVec2(x: radius * 2, y: (radius + style.framePadding.y) * 2)

    bb = ImRect(min: pos, max: ImVec2(x: pos.x + size.x, y: pos.y + size.y));
  igItemSize(bb, style.framePadding.y)

  if not igItemAdd(bb, id):
      return
  
  window.drawList.pathClear()
  
  let
    numSegments = 30
    start = abs(sin(context.time * 1.8f) * (numSegments - 5).float)
  
  let
    aMin = PI * 2f * start / numSegments.float
    aMax = PI * 2f * ((numSegments - 3) / numSegments).float

    centre = ImVec2(x: pos.x + radius, y: pos.y + radius + style.framePadding.y)

  for i in 0..<numSegments:
    let a = aMin + i / numSegments * (aMax - aMin)
    window.drawList.pathLineTo(ImVec2(x: centre.x + cos(a + context.time * 8) * radius, y: centre.y + sin(a + context.time * 8) * radius))

  window.drawList.pathStroke(color, thickness = thickness)

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

proc initConfig*(app: var App, settings: PrefsNode, parent = "", overwrite = false) = 
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

proc toJson*(style: ImGuiStyle): JsonNode = 
  result = newJObject()
  for name, field in style.fieldPairs:
    when name in styleProps:
      result[name] = 
        when field is float32:
          field.newJFloat()
        elif field is ImVec2:
          %[field.x, field.y]
        elif field is ImGuiDir:
          newJString($field)

  result["colors"] = newJObject()
  for col in ImGuiCol:
    result["colors"][$col] = %[style.colors[ord col].x, style.colors[ord col].y, style.colors[ord col].z, style.colors[ord col].w]

proc styleFromJson*(node: JsonNode): ImGuiStyle = 
  for name, field in result.fieldPairs:
    when name in styleProps:
      if name in node:
        case node[name].kind
        of JFloat:
          when field is float32:
            field = node[name].getFloat()
          else:
            raise newException(ValueError, "Got " & $node[name].kind & " expected " & $typeOf(field) & " for " & name)
        of JArray:
          when field is ImVec2:
            field = igVec2(node[name][0].getFloat(), node[name][1].getFloat())
          elif field is ImVec4:
            field = igVec4(node[name][0].getFloat(), node[name][1].getFloat(), node[name][2].getFloat(), node[name][3].getFloat())
          else:
            raise newException(ValueError, "Got " & $node[name].kind & " expected " & $typeOf(field) & " for " & name)
        of JString:
          when field is ImGuiDir:
            field = parseEnum[ImGuiDir](node[name].getStr())
          else:
            raise newException(ValueError, "Got " & $node[name].kind & " expected " & $typeOf(field) & " for " & name)
        else:
          raise newException(ValueError, "Got " & $node[name].kind & " expected " & $typeOf(field) & " for " & name)

  if "colors" in node:
    for col in ImGuiCol:
      if $col in node["colors"]:
        let colorNode = node["colors"][$col]
        if colorNode.kind != JArray:
          raise newException(ValueError, "Got " & $colorNode.kind & " expected ImVec4 for color " & $col)

        result.colors[ord col] = igVec4(colorNode[0].getFloat(), colorNode[1].getFloat(), colorNode[2].getFloat(), colorNode[3].getFloat())

proc getCacheDir*(app: App): string = 
  getCacheDir(app.config["name"].getString())
