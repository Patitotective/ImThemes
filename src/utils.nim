import std/[typetraits, enumutils, strformat, strutils, macros, times, math, os]
import downit
import imstyle
import kdl, kdl/[prefs]
import openurl
import stb_image/read as stbi
import nimgl/[imgui, glfw, opengl]
import chroma

import types, icons

export enumutils

const styleProps* = ["alpha", "disabledAlpha", "windowPadding", "windowRounding", "windowBorderSize", "windowMinSize", "windowTitleAlign", "windowMenuButtonPosition", "childRounding", "childBorderSize", "popupRounding", "popupBorderSize", "framePadding", "frameRounding", "frameBorderSize", "itemSpacing", "itemInnerSpacing", "cellPadding", "indentSpacing", "columnsMinSpacing", "scrollbarSize", "scrollbarRounding", "grabMinSize", "grabRounding", "tabRounding", "tabBorderSize", "tabMinWidthForCloseButton", "colorButtonPosition", "buttonTextAlign", "selectableTextAlign"]
const stylePropsHelp* = ["Global alpha applies to everything in Dear ImGui.", "Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.", "Padding within a window", "Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.", "Thickness of border around windows. Generally set to 0.0f or 1.0f. Other values not well tested.", "Minimum window size", "Alignment for title bar text", "Position of the collapsing/docking button in the title bar (left/right). Defaults to ImGuiDir_Left.", "Radius of child window corners rounding. Set to 0.0f to have rectangular child windows", "Thickness of border around child windows. Generally set to 0.0f or 1.0f. Other values not well tested.", "Radius of popup window corners rounding. Set to 0.0f to have rectangular child windows", "Thickness of border around popup or tooltip windows. Generally set to 0.0f or 1.0f. Other values not well tested.", "Padding within a framed rectangle (used by most widgets)", "Radius of frame corners rounding. Set to 0.0f to have rectangular frames (used by most widgets).", "Thickness of border around frames. Generally set to 0.0f or 1.0f. Other values not well tested.", "Horizontal and vertical spacing between widgets/lines", "Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label)", "Padding within a table cell", "Horizontal spacing when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).", "Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).", "Width of the vertical scrollbar, Height of the horizontal scrollbar", "Radius of grab corners rounding for scrollbar", "Minimum width/height of a grab box for slider/scrollbar", "Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.", "Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.", "Thickness of border around tabs.", "Minimum width for close button to appears on an unselected tab when hovered. Set to 0.0f to always show when hovering, set to FLT_MAX to never show close button unless selected.", "Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.", "Alignment of button text when button is larger than text.", "Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line."]
const colors* = @["red", "blue", "green", "yellow", "orange", "purple", "magenta", "pink", "gray"]
const tags* = @["light", "dark", "high-contrast", "rounded"]

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

proc `<`*(vec1: ImVec2, vec2: ImVec2): bool =
  vec1.x < vec2.x and vec1.y < vec2.y

proc igVec2*(x, y: float32): ImVec2 = ImVec2(x: x, y: y)

proc igVec4*(x, y, z, w: float32): ImVec4 = ImVec4(x: x, y: y, z: z, w: w)

proc igVec4*(color: Color): ImVec4 = ImVec4(x: color.r, y: color.g, z: color.b, w: color.a)

proc igHSV*(h, s, v: float32, a: float32 = 1f): ImColor = 
  result.addr.hSVNonUDT(h, s, v, a)

proc igGetContentRegionAvail*(): ImVec2 = 
  igGetContentRegionAvailNonUDT(result.addr)

proc igGetWindowContentRegionMax*(): ImVec2 = 
  igGetWindowContentRegionMaxNonUDT(result.addr)

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

proc igGetItemRectMax*(): ImVec2 = 
  igGetItemRectMaxNonUDT(result.addr)

proc igGetItemRectMin*(): ImVec2 = 
  igGetItemRectMinNonUDT(result.addr)

proc igGetItemRectSize*(): ImVec2 = 
  igGetItemRectSizeNonUDT(result.addr)

proc igGetMousePos*(): ImVec2 = 
  igGetMousePosNonUDT(result.addr)

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

proc igTextWithEllipsis*(text: string, maxWidth: float32 = igGetContentRegionAvail().x, ellipsisText: string = "...") = 
  var text = text
  var width = igCalcTextSize(cstring text).x
  let ellipsisWidth = igCalcTextSize(cstring ellipsisText).x

  if width > maxWidth:
    while width + ellipsisWidth > maxWidth and text.len > ellipsisText.len:
      text = text[0..^ellipsisText.len]
      width = igCalcTextSize(cstring text).x

    igText(cstring text & ellipsisText)
  else:
    igText(cstring text)

proc igAddUnderLine*(col: uint32) = 
  var min = igGetItemRectMin()
  let max = igGetItemRectMax()

  min.y = max.y
  igGetWindowDrawList().addLine(min, max, col, 1f)

proc igClickableText*(text: string, sameLineBefore, sameLineAfter = true): bool = 
  if sameLineBefore: igSameLine(0, 0)

  igPushStyleColor(ImGuiCol.Text, parseHtmlColor("#4296F9").igVec4())
  igText(cstring text)
  igPopStyleColor()

  if igIsItemHovered():
    if igIsMouseClicked(ImGuiMouseButton.Left):
      result = true

    igAddUnderLine(parseHtmlColor("#4296F9").igVec4().igColorConvertFloat4ToU32())

  if sameLineAfter: igSameLine(0, 0)

proc igURLText*(url: string, text = "", sameLineBefore, sameLineAfter = true) = 
  if igClickableText(if text.len > 0: text else: url, sameLineBefore, sameLineAfter):
    openURL(url)

  if igIsItemHovered():
    igSetTooltip(cstring url & " " & FA_ExternalLink)

proc igCalcFrameSize*(text: string): ImVec2 = 
  igCalcTextSize(cstring text) + (igGetStyle().framePadding * 2)

# https://github.com/ocornut/imgui/issues/589#issuecomment-238358689
proc igIsItemActivePreviousFrame*(): bool = 
  let context = igGetCurrentContext()
  result = context.activeIdPreviousFrame == context.lastItemData.id

proc makeFlags*[T: enum](flags: varargs[T]): T =
  ## Mix multiple flags of a specific enum
  var res = 0
  for x in flags:
    res = res or int(x)

  result = T res

proc parseMakeFlags*[T: enum](flags: seq[string]): T =
  var res = 0
  for x in flags:
    res = res or int parseEnum[T](x)

  result = T res

proc color*(vec: ImVec4): Color = color(vec.x, vec.y, vec.z, vec.w)

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

proc pushString*(str: var string, val: string) =
  if val.len < str.len:
    str[0..val.len] = val & '\0'
  else:
    str[0..str.high] = val[0..str.high]

proc newString*(length: Natural, default: string): string =
  result = newString(length)
  result.pushString(default)

proc cleanString*(str: string): string =
  for e, c in str:
    if c == '\0':
      return str[0..<e].strip()

  str.strip()

proc updatePrefs*(app: var App) = 
  # Update values depending on the preferences here
  # This procedure is also called at the start of the app
  if app.prefs[settings].proxy.inputVal.len > 0:
    app.downloader.setProxy(app.prefs[settings].proxy.inputVal & '/', app.prefs[settings].proxyUser.inputVal, app.prefs[settings].proxyPassword.inputVal)
  else:
    app.downloader.removeProxy()

proc cmpIgnoreStyle(a, b: openarray[char], ignoreChars = {'_', '-'}): int =
  let aLen = a.len
  let bLen = b.len
  var i = 0
  var j = 0

  while true:
    while i < aLen and a[i] in ignoreChars: inc i
    while j < bLen and b[j] in ignoreChars: inc j
    let aa = if i < aLen: toLowerAscii(a[i]) else: '\0'
    let bb = if j < bLen: toLowerAscii(b[j]) else: '\0'
    result = ord(aa) - ord(bb)
    if result != 0: return result
    # the characters are identical:
    if i >= aLen:
      # both cursors at the end:
      if j >= bLen: return 0
      # not yet at the end of 'b':
      return -1
    elif j >= bLen:
      return 1
    inc i
    inc j

proc eqIdent*(v, a: openarray[char], ignoreChars = {'_', '-'}): bool = cmpIgnoreStyle(v, a, ignoreChars) == 0

proc initCacheSettingsObj(a: var object)
proc saveSettingsObj(a: var object)

proc valToCache*(s: var Setting) =
  case s.kind
  of stInput:
    s.inputCache = s.inputVal
  of stCombo:
    s.comboCache = s.comboVal
  of stCheck:
    s.checkCache = s.checkVal
  of stSlider:
    s.sliderCache = s.sliderVal
  of stFSlider:
    s.fsliderCache = s.fsliderVal
  of stSpin:
    s.spinCache = s.spinVal
  of stFSpin:
    s.fspinCache = s.fspinVal
  of stRadio:
    s.radioCache = s.radioVal
  of stSection:
    when s.content is object:
      initCacheSettingsObj(s.content)
    else:
      raise newException(ValueError, $s & " must be an object, got " & $typeof(s.content))
  of stRGB:
    s.rgbCache = s.rgbVal
  of stRGBA:
    s.rgbaCache = s.rgbaVal
  # of stFile:
  #   s.fileCache.val = s.fileVal
  # of stFiles:
  #   s.filesCache.val = s.filesVal
  # of stFolder:
  #   s.folderCache.val = s.folderVal

proc cacheToVal*(s: var Setting) =
  case s.kind
  of stInput:
    s.inputVal = s.inputCache
  of stCombo:
    s.comboVal = s.comboCache
  of stCheck:
    s.checkVal = s.checkCache
  of stSlider:
    s.sliderVal = s.sliderCache
  of stFSlider:
    s.fsliderVal = s.fsliderCache
  of stSpin:
    s.spinVal = s.spinCache
  of stFSpin:
    s.fspinVal = s.fspinCache
  of stRadio:
    s.radioVal = s.radioCache
  of stSection:
    when s.content is object:
      saveSettingsObj(s.content)
    else:
      raise newException(ValueError, $s & " must be an object, got " & $typeof(s.content))
  of stRGB:
    s.rgbVal = s.rgbCache
  of stRGBA:
    s.rgbaVal = s.rgbaCache
  # of stFile:
  #   s.fileVal = s.fileCache.val
  # of stFiles:
  #   s.filesVal = s.filesCache.val
  # of stFolder:
  #   s.folderVal = s.folderCache.val

proc cacheToDefault*(s: var Setting) =
  case s.kind
  of stInput:
    s.inputCache = s.inputDefault
  of stCombo:
    s.comboCache = s.comboDefault
  of stCheck:
    s.checkCache = s.checkDefault
  of stSlider:
    s.sliderCache = s.sliderDefault
  of stFSlider:
    s.fsliderCache = s.fsliderDefault
  of stSpin:
    s.spinCache = s.spinDefault
  of stFSpin:
    s.fspinCache = s.fspinDefault
  of stRadio:
    s.radioCache = s.radioDefault
  of stSection:
    when s.content is object:
      initCacheSettingsObj(s.content)
    else:
      raise newException(ValueError, $s & " must be an object, got " & $typeof(s.content))
  of stRGB:
    s.rgbCache = s.rgbDefault
  of stRGBA:
    s.rgbaCache = s.rgbaDefault
  # of stFile:
  #   s.fileCache.val = s.fileDefault
  # of stFiles:
  #   s.filesCache.val = s.filesDefault
  # of stFolder:
  #   s.folderCache.val = s.folderDefault

proc saveSettingsObj(a: var object) =
  for field in a.fields:
    field.cacheToVal()

proc initCacheSettingsObj(a: var object) =
  for field in a.fields:
    field.valToCache()

proc initCache*(a: var Settings) =
  ## Sets all a's cache values to the current values (`inputCache = inputVal`)
  initCacheSettingsObj(a)

proc save*(a: var Settings) =
  ## Sets all a's current values to the cache values (`inputVal = inputCache`)
  saveSettingsObj(a)

proc getCacheDir*(app: App): string = 
  getCacheDir(app.config.name)

proc passFilter*(buffer: string, str: string): bool = 
  buffer.cleanString().toLowerAscii() in str.toLowerAscii()

proc str*(x: float32, exportKind: ExportKind): string = 
  case exportKind
  of Nim, Cpp, CSharp:
    $x & 'f'
  else:
    $x

proc str*(obj: object, exportKind: ExportKind, objName = true, fieldNames = true): string = 
  ## Modified version of dollars.`$`(object)

  if objName:
    result = $typeof obj

  result.add "("

  var count = 0

  for name, field in obj.fieldPairs:
    if count > 0: result.add ", "
    
    if fieldNames:
      result.add(name)
      result.add(": ")

    inc count

    when compiles($field):
      when field isnot (string or seq) and compiles(field.isNil):
        if field.isNil: result.add "nil"
        else:
          when compiles(result.add field.str(exportKind)):
            result.add field.str(exportKind)
          else:
            result.addQuoted(field)
      else:
        when compiles(result.add field.str(exportKind)):
          result.add field.str(exportKind)
        else:
          result.addQuoted(field)    else:
      result.add("...")

  result.add ")"

proc formatTemplate*(style: ImGuiStyle, themeName: string, exportKind: ExportKind, author, description, forkedFrom = "", tags = newSeq[string]()): string = 
  result = 
    case exportKind
    of Nim:
      "proc setupIgStyle() = \n"
    of Cpp:
      "void SetupImGuiStyle()\n{\n"
    of CSharp:
      "public static void SetupImGuiStyle()\n{\n"
    of Publish:
      "[[themes]]\n"
    of ImStyle: ""

  let authorText = 
    if author.len > 0:
      " by " & author
    else: 
      ""
  var body = 
    case exportKind
    of Nim:
      &"# {themeName} style{authorText} from ImThemes\nlet style = igGetStyle()\n\n"
    of Cpp:
      &"// {themeName} style{authorText} from ImThemes\nImGuiStyle& style = ImGui::GetStyle();\n\n"
    of CSharp:
      &"// {themeName} style{author} from ImThemes\nvar style = ImGuiNET.ImGui.GetStyle();\n\n"
    of ImStyle:
      &"# {themeName} style{authorText} from ImThemes\n"
    of Publish:
      let forkText = 
        if forkedFrom.len > 0:
          &"forkedFrom = \"{forkedFrom}\"\n"
        else: ""

      let authorText = 
        if author.len > 0: author
        else: "github-username"

      &"name = \"{themeName}\"\nauthor = \"{authorText}\"\ndescription = \"{description}\"\n{forkText}tags = {($tags)[1..^1]}\ndate = \"pr-merge-date\"\n"

  if exportKind == Publish:
    body.add &"[themes.style]\n"

  # Here we do not use strformat because fieldPairs has a bug that doesn't allow that
  for name, field in style.fieldPairs:
    when name in styleProps:
      case exportKind
      of Nim:
        body.add("style." & name & " = ")
      of Cpp, CSharp:
        body.add("style." & name.capitalizeAscii() & " = ")
      of ImStyle, Publish:
        if exportKind == Publish:
          body.add("  ") # Indentation

        body.add(name & " = ")

      when field is ImVec2:
        case exportKind
        of Cpp:
          body.add(field.str(exportKind, fieldNames = false))
        of CSharp:
          body.add("new Vector2" & field.str(exportKind, objName = false, fieldNames = false))
        of Nim:
          body.add(field.str(exportKind))
        of ImStyle, Publish:
          body.add('[' & $field.x & ", " & $field.y & ']')
      elif field is enum:
        case exportKind
        of Cpp:
          body.add($typeof(field) & '_' & $field)
        of Nim, CSharp:
          body.add($typeof(field) & '.' & $field)
        of ImStyle, Publish:
          body.add('"' & $field & '"')
      elif field is float32:
        body.add(field.str(exportKind))

      if exportKind in {Cpp, CSharp}:
        body.add(';')

      body.add('\n')

  if exportKind != Publish:
    body.add('\n')

  if exportKind == ImStyle:
    body.add("[colors]\n")
  elif exportKind == Publish:
    body.add("[themes.style.colors]\n")

  for col in ImGuiCol:
    let colVec = style.colors[ord col]
    case exportKind
    of Cpp:
      body.add(&"style.Colors[ImGuiCol_{col}] = {colVec.str(exportKind, fieldNames = false)};")
    of CSharp:
      body.add(&"style.Colors[(int)ImGuiCol.{col}] = new Vector4{colVec.str(exportKind, objName = false, fieldNames = false)};")
    of Nim:
      body.add(&"style.colors[ord ImGuiCol.{col}] = {colVec.str(exportKind)}")
    of ImStyle, Publish:
      if exportKind == Publish:
        body.add("  ") # Indentation
      body.add(&"{col} = \"{colVec.color().toHtmlRgba()}\"")

    body.add('\n')

  body.stripLineEnd()

  case exportKind
  of Cpp, CSharp:
    result.add(body.indent(1, "\t"))
    result.add("\n}")
  of Nim, Publish:
    result.add(body.indent(2))
  of ImStyle:
    result.add(body)

proc drawExportTabs*(app: var App, style: ImGuiStyle, name: string, author, description, forkedFrom = "", tags = newSeq[string](), tabs = {Nim, Cpp, CSharp, ImStyle}, availDiff = igVec2(0, 0)) = 
  if igBeginTabBar("##exportTabs"):      
    var currentText = ""
    let avail = igGetContentRegionAvail() - availDiff
    
    if Nim in tabs and igBeginTabItem(cstring "Nim " & FA_Code):
      if app.currentExportTab != 0: app.copied = false
      app.currentExportTab = 0
      currentText = style.formatTemplate(name, Nim, author)
      igInputTextMultiline("##nim", cstring currentText, uint currentText.len, avail, ImGuiInputTextFlags.ReadOnly)
      igEndTabItem()
    
    if Cpp in tabs and igBeginTabItem(cstring "C++ " & FA_Code):
      if app.currentExportTab != 1: app.copied = false
      app.currentExportTab = 1
      currentText = style.formatTemplate(name, Cpp, author)
      
      igInputTextMultiline("##cpp", cstring currentText, uint currentText.len, avail, ImGuiInputTextFlags.ReadOnly)
      igEndTabItem()

    if CSharp in tabs and igBeginTabItem(cstring "C# " & FA_Code):
      if app.currentExportTab != 1: app.copied = false
      app.currentExportTab = 1
      currentText = style.formatTemplate(name, CSharp, author)
      
      igInputTextMultiline("##csharp", cstring currentText, uint currentText.len, avail, ImGuiInputTextFlags.ReadOnly)
      igEndTabItem()
    
    if ImStyle in tabs and igBeginTabItem("TOML"):
      if app.currentExportTab != 2: app.copied = false
      app.currentExportTab = 2

      currentText = style.formatTemplate(name, ImStyle, author)

      igInputTextMultiline("##toml", cstring currentText, uint currentText.len, avail, ImGuiInputTextFlags.ReadOnly)
      igEndTabItem()

    if Publish in tabs and igBeginTabItem("TOML"):
      if app.currentExportTab != 2: app.copied = false
      app.currentExportTab = 2

      currentText = style.formatTemplate(name, Publish, author, description, forkedFrom, tags)

      igInputTextMultiline("##publish", cstring currentText, uint currentText.len, avail, ImGuiInputTextFlags.ReadOnly)
      igEndTabItem()
    
    if igTabItemButton(cstring (if not app.copied: "Copy " & FA_FilesO else: "Copied"), Trailing):
      app.copied = true
      app.win.setClipboardString(cstring currentText)

    igEndTabBar()

proc drawExportThemeModal*(app: var App, style: ImGuiStyle, name: string, author, description, forkedFrom = "", tags = newSeq[string](), tabs = {Nim, Cpp, CSharp, ImStyle}) = 
  let unusedOpen = true
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  igSetNextWindowSize(igVec2(500, 500))
  if igBeginPopupModal(cstring &"{name} Theme###exportTheme", unusedOpen.unsafeAddr, flags = ImGuiWindowFlags.NoResize):
    app.drawExportTabs(style, name, author, description, forkedFrom, tags, tabs)
    igEndPopup()

proc drawFilters*(app: var App, filters: var seq[string], authorFilter = "", filterTags = @["starred"] & tags, addBtnRight = false): bool {.discardable.} = 
  let style = igGetStyle()
  let drawlist = igGetWindowDrawList()
  let filtersCopy = filters.deepCopy() & (if authorFilter.len > 0: @[authorFilter] else: @[])
  
  if not addBtnRight:
    if igButton(FA_Plus): igOpenPopup("addFilter")
    if filters.len > 0: igDummy(igVec2(style.itemSpacing.x, 0)); igSameLine()
  elif filters.len > 0:
    igSameLine(0, style.itemSpacing.x)

  for e, filter in filtersCopy:
    drawList.channelsSplit(2)

    drawList.channelsSetCurrent(1)
    igAlignTextToFramePadding()
    igText(cstring filter.capitalizeAscii())
    
    drawList.channelsSetCurrent(0)
    drawlist.addRectFilled(igGetItemRectMin() - style.framePadding, igGetItemRectMax() + style.framePadding, igGetColorU32(ImGuiCol.Tab))

    drawList.channelsMerge()

    igSameLine()
    igPushStyleVar(FrameRounding, 0f)
    igPushStyleColor(ImGuiCol.Button, igGetColorU32(ImGuiCol.Tab))
    igPushStyleColor(ImGuiCol.ButtonHovered, igGetColorU32(ImGuiCol.TabHovered))
    igPushStyleColor(ImGuiCol.ButtonActive, igGetColorU32(ImGuiCol.TabActive))

    if igButton(cstring FA_Times & "##" & $e):
      result = true
      if filter == authorFilter:
        app.authorFilter.reset()
      else:
        filters.delete filtersCopy.find(filter)

    igPopStyleColor(3)
    igPopStyleVar()

    let lastButton = igGetItemRectMax().x
    # Expected position if next button was on same line
    let nextButton = lastButton + 0.5 + 
      (if e < filtersCopy.high: igCalcFrameSize(filtersCopy[e+1].capitalizeAscii()).x + style.itemSpacing.x + igCalcFrameSize(FA_Times).x + 
      (if addBtnRight: igCalcFrameSize(FA_Plus).x + style.itemSpacing.x else: 0) 
      else: 0)
    
    if e < filtersCopy.high:
      if nextButton < igGetWindowPos().x + igGetWindowContentRegionMax().x:
        igSameLine(0, style.itemSpacing.x * 2)
      else:
        igDummy(igVec2(style.itemSpacing.x, 0)); igSameLine()

  if addBtnRight:
    if filters.len > 0: igSameLine()
    if igButton(FA_Plus): igOpenPopup("addFilter")

  if igBeginPopup("addFilter"):
    for e, tag in filterTags:
      if tag notin filters:
        if igMenuItem(cstring tag.capitalizeAscii()):
          result = true
          filters.add tag

    if igBeginMenu("Colors"):
      for e, col in colors:
        if col notin filters:
          if igMenuItem(cstring col.capitalizeAscii()):
            result = true
            filters.add col

      igEndMenu()

    igEndPopup()

proc switchTheme*(app: var App, themeIndex: int) = 
  app.editing = false
  app.currentTheme = themeIndex
  app.editSplitterSize1.a = 0f
  app.editSplitterSize2.b = 0f

  app.themeStyle = app.prefs[themes][themeIndex].style

  if app.prefs[themes][themeIndex].prevStyle.isNone:
    app.prefs[themes][themeIndex].prevStyle = app.prefs[themes][themeIndex].style.some

  if not app.saved:
    app.prevthemeStyle = app.prefs["themes"][themeIndex]["prevStyle"].styleFromToml()
  else:
    app.prevThemeStyle = app.themeStyle
