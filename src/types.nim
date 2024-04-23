import std/[tables] # threadpool
import std/macros except eqIdent # since it conflicts with kdl/util.eqIdent

import nimgl/[imgui, glfw]
# import tinydialogs
import kdl, kdl/[types, utils]
import constructor/defaults
import downit

import configtype, themes

export configtype

type
  SettingType* = enum
    stInput # Input text
    stCheck # Checkbox
    stSlider # Int slider
    stFSlider # Float slider
    stSpin # Int spin
    stFSpin # Float spin
    stCombo
    stRadio # Radio button
    stRGB # Color edit RGB
    stRGBA # Color edit RGBA
    stSection
    # stFile # File picker
    # stFiles # Multiple files picker
    # stFolder # Folder picker

  RGB* = array[3, float32]
  RGBA* = array[4, float32]

  Empty* = object # https://forum.nim-lang.org/t/10565

  # T is the object for a section and the enum for a radio or combo
  Setting*[T: object or enum] = object
    display*: string
    help*: string
    case kind*: SettingType
    of stInput:
      inputVal*, inputDefault*, inputCache*: string
      inputFlags*: seq[ImGuiInputTextFlags]
      limits*: Slice[int]
      hint*: string
    of stCombo:
      comboVal*, comboDefault*, comboCache*: T
      comboFlags*: seq[ImGuiComboFlags]
      comboItems*: seq[T]
    of stRadio:
      radioVal*, radioDefault*, radioCache*: T
      radioItems*: seq[T]
    of stSection:
      content*: T
      sectionFlags*: seq[ImGuiTreeNodeFlags]
    of stSlider:
      sliderVal*, sliderDefault*, sliderCache*: int32
      sliderFormat*: string
      sliderRange*: Slice[int32]
      sliderFlags*: seq[ImGuiSliderFlags]
    of stFSlider:
      fsliderVal*, fsliderDefault*, fsliderCache*: float32
      fsliderFormat*: string
      fsliderRange*: Slice[float32]
      fsliderFlags*: seq[ImGuiSliderFlags]
    of stSpin:
      spinVal*, spinDefault*, spinCache*: int32
      spinRange*: Slice[int32]
      spinFlags*: seq[ImGuiInputTextFlags]
      step*, stepFast*: int32
    of stFSpin:
      fspinVal*, fspinDefault*, fspinCache*: float32
      fspinFormat*: string
      fspinRange*: Slice[float32]
      fspinFlags*: seq[ImGuiInputTextFlags]
      fstep*, fstepFast*: float32
    # of stFile:
    #   fileCache*: tuple[val: string, flowvar: FlowVar[string]] # Since flowvar may return an empty string, val keeps the actual value
    #   fileVal*, fileDefault*: string
    #   fileFilterPatterns*: seq[string]
    #   fileSingleFilterDescription*: string
    # of stFiles:
    #   filesCache*: tuple[val: seq[string], flowvar: FlowVar[seq[string]]]
    #   filesVal*, filesDefault*: seq[string]
    #   filesFilterPatterns*: seq[string]
    #   filesSingleFilterDescription*: string
    # of stFolder:
    #   folderCache*: tuple[val: string, flowvar: FlowVar[string]]
    #   folderVal*, folderDefault*: string
    of stCheck:
      checkVal*, checkDefault*, checkCache*: bool
    of stRGB:
      rgbVal*, rgbDefault*, rgbCache*: array[3, float32]
      rgbFlags*: seq[ImGuiColorEditFlags]
    of stRGBA:
      rgbaVal*, rgbaDefault*, rgbaCache*: RGBA
      rgbaFlags*: seq[ImGuiColorEditFlags]

# Taken from https://forum.nim-lang.org/t/6781#42294
proc ifNeqRetFalse(fld,w,v:NimNode):NimNode =
  quote do:
    if `w`.`fld` != `v`.`fld`: return false
proc genIfStmts(recList,i,j:NimNode):NimNode =
  result = newStmtList()
  case recList.kind
  of nnkRecList:
    for idDef in recList:
      expectKind(idDef,nnkIdentDefs)
      result.add idDef[0].ifNeqRetFalse(i,j)
  of nnkIdentDefs:
    result.add recList[0].ifNeqRetFalse(i,j)
  else: error "expected RecList or IdentDefs got" & recList.repr

macro equalsImpl[T:object](a,b:T): untyped =
  template ifNeqRetFalse(fld:typed):untyped = ifNeqRetFalse(fld,a,b)
  template genIfStmts(recList:typed):untyped = genIfStmts(recList,a,b)

  let tImpl = a.getTypeImpl
  result = newStmtList()
  result.add quote do:
    result = true
  let records = tImpl[2]
  records.expectKind(nnkRecList)
  for field in records:
    case field.kind
    of nnkIdentDefs:
      result.add field[0].ifNeqRetFalse
    of nnkRecCase:
      let discrim = field[0][0]
      result.add discrim.ifNeqRetFalse
      var casestmt = newNimNode(nnkCaseStmt)
      casestmt.add newDotExpr(a,discrim)
      for ofbranch in field[1..^1]:
        case ofbranch.kind
        of nnkOfBranch:
          let testVal = ofbranch[0]
          let reclst = ofbranch[1]
          casestmt.add nnkOfBranch.newTree(testVal,reclst.genIfStmts)
        of nnkElse:
          let reclst = ofbranch[0]
          casestmt.add nnkElse.newTree(reclst.genIfStmts)
        else: error "Expected OfBranch or Else, got" & ofbranch.repr
      result.add casestmt
    else:
      error "Expected IdentDefs or RecCase, got " & field.repr

proc `==`*[T](a, b: Setting[T]): bool =
  equalsImpl(a, b)

proc inputSetting(display, help, default, hint = "", limits = 0..100, flags = newSeq[ImGuiInputTextFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stInput, inputDefault: default, inputVal: default, hint: hint, limits: limits, inputFlags: flags)

proc checkSetting(display, help = "", default: bool): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stCheck, checkDefault: default, checkVal: default)

proc comboSetting[T: enum](display, help = "", default: T, items: seq[T], flags = newSeq[ImGuiComboFlags]()): Setting[T] =
  Setting[T](display: display, help: help, kind: stCombo, comboItems: items, comboDefault: default, comboVal: default, comboFlags: flags)

proc radioSetting[T: enum](display, help = "", default: T, items: seq[T]): Setting[T] =
  Setting[T](display: display, help: help, kind: stRadio, radioItems: items, radioDefault: default, radioVal: default)

proc sectionSetting[T: object](display, help = "", content: T, flags = newSeq[ImGuiTreeNodeFlags]()): Setting[T] =
  Setting[T](display: display, help: help, kind: stSection, content: content, sectionFlags: flags)

proc sliderSetting(display, help = "", default = 0i32, range: Slice[int32], format = "%d", flags = newSeq[ImGuiSliderFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stSlider, sliderDefault: default, sliderVal: default, sliderRange: range, sliderFormat: format, sliderFlags: flags)

proc fsliderSetting(display, help = "", default = 0f, range: Slice[float32], format = "%.2f", flags = newSeq[ImGuiSliderFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stFSlider, fsliderDefault: default, fsliderVal: default, fsliderRange: range, fsliderFormat: format, fsliderFlags: flags)

proc spinSetting(display, help = "", default = 0i32, range: Slice[int32], step = 1i32, stepFast = 10i32, flags = newSeq[ImGuiInputTextFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stSpin, spinDefault: default, spinVal: default, spinRange: range, step: step, stepFast: stepFast, spinFlags: flags)

proc fspinSetting(display, help = "", default = 0f, range: Slice[float32], step = 0.1f, stepFast = 1f, format = "%.2f", flags = newSeq[ImGuiInputTextFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stFSpin, fspinDefault: default, fspinVal: default, fspinRange: range, fstep: step, fstepFast: stepFast, fspinFormat: format, fspinFlags: flags)

# proc fileSetting(display, help, default = "", filterPatterns = newSeq[string](), singleFilterDescription = ""): Setting[Empty] =
#   Setting[Empty](display: display, help: help, kind: stFile, fileDefault: default, fileVal: default, fileFilterPatterns: filterPatterns, fileSingleFilterDescription: singleFilterDescription)

# proc filesSetting(display, help = "", default = newSeq[string](), filterPatterns = newSeq[string](), singleFilterDescription = ""): Setting[Empty] =
#   Setting[Empty](display: display, help: help, kind: stFiles, filesDefault: default, filesVal: default, filesFilterPatterns: filterPatterns, filesSingleFilterDescription: singleFilterDescription)

# proc folderSetting(display, help, default = ""): Setting[Empty] =
#   Setting[Empty](display: display, help: help, kind: stFolder, folderDefault: default, folderVal: default)

proc rgbSetting(display, help = "", default: RGB, flags = newSeq[ImGuiColorEditFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stRGB, rgbDefault: default, rgbVal: default, rgbFlags: flags)

proc rgbaSetting(display, help = "", default: RGBA, flags = newSeq[ImGuiColorEditFlags]()): Setting[Empty] =
  Setting[Empty](display: display, help: help, kind: stRGBA, rgbaDefault: default, rgbaVal: default, rgbaFlags: flags)

proc toSeq[T: enum](_: typedesc[T]): seq[T] =
  for i in T:
    result.add i

type
  Settings* {.defaults: {}.} = object
    proxy* = inputSetting(display = "Proxy", default = "", hint = "http://127.0.0.1:8081/", help = "Leave empty to disable proxy")
    proxyUser* = inputSetting(display = "Proxy username", default = "")
    proxyPassword* = inputSetting(display = "Proxy password", default = "")

proc decodeSettingsObj*(a: KdlNode, v: var object) =
  # echo "decoding settings ", a
  for fieldName, field in v.fieldPairs:
    for child in a.children:
      if child.name.eqIdent fieldName:
        case field.kind
        of stInput:
          field.inputVal = decodeKdl(child, typeof(field.inputVal))
        of stCombo:
          when field.comboVal is enum:
            field.comboVal = decodeKdl(child, typeof(field.comboVal))
          else:
            raise newException(ValueError, $fieldName & " must be an enum, got " & $typeof(field.comboVal))
        of stCheck:
          field.checkVal = decodeKdl(child, typeof(field.checkVal))
        of stSlider:
          field.sliderVal = decodeKdl(child, typeof(field.sliderVal))
        of stFSlider:
          field.fsliderVal = decodeKdl(child, typeof(field.fsliderVal))
        of stSpin:
          field.spinVal = decodeKdl(child, typeof(field.spinVal))
        of stFSpin:
          field.fspinVal = decodeKdl(child, typeof(field.fspinVal))
        of stRadio:
          when field.radioVal is enum:
            field.radioVal = decodeKdl(child, typeof(field.radioVal))
          else:
            raise newException(ValueError, $fieldName & " must be an enum, got " & $typeof(field.radioVal))
        of stSection:
          when field.content is object:
            decodeSettingsObj(child, field.content)
          else:
            raise newException(ValueError, $fieldName & " must be an object, got " & $typeof(field.content))
        of stRGB:
          field.rgbVal = decodeKdl(child, typeof(field.rgbVal))
        of stRGBA:
          field.rgbaVal = decodeKdl(child, typeof(field.rgbaVal))
        # of stFile:
        #   field.fileVal = decodeKdl(child, typeof(field.fileVal))
        # of stFiles:
        #   field.filesVal = decodeKdl(child, typeof(field.filesVal))
        # of stFolder:
        #   field.folderVal = decodeKdl(child, typeof(field.folderVal))

proc decodeKdl*(a: KdlNode, v: var Settings) =
  v = initSettings()
  decodeSettingsObj(a, v)

# proc encodeKdl*[T](a: FlowVar[T], v: var KdlVal) =
#   if a.isNil or not a.isReady:
#     v = initKNull()
#   else:
#     v = encodeKdlVal(^a)

proc encodeKdl*(a: Empty, v: var KdlVal) =
  v = initKNull()

proc encodeKdl*(a: seq[string], b: var KdlNode, name: string) =
  b = initKNode(name)
  for i in a:
    b.args.add initKString(i)

proc encodeKdl*[T: Ordinal](a: array[T, float32], b: var KdlNode, name: string) =
  b = initKNode(name)
  for i in a:
    b.args.add initKFloat(i)

proc encodeSettingsObj(a: object): KdlDoc =
  for fieldName, field in a.fieldPairs:
    let node =
      case field.kind
      of stInput:
        encodeKdlNode(field.inputVal, $fieldName)
      of stCombo:
        when field.comboVal is enum:
          encodeKdlNode(field.comboVal, $fieldName)
        else:
          raise newException(ValueError, $fieldName & " must be an enum, got " & $typeof(field.comboVal))
      of stCheck:
        encodeKdlNode(field.checkVal, $fieldName)
      of stSlider:
        encodeKdlNode(field.sliderVal, $fieldName)
      of stFSlider:
        encodeKdlNode(field.fsliderVal, $fieldName)
      of stSpin:
        encodeKdlNode(field.spinVal, $fieldName)
      of stFSpin:
        encodeKdlNode(field.fspinVal, $fieldName)
      of stRadio:
        when field.comboVal is enum:
          encodeKdlNode(field.radioVal, $fieldName)
        else:
          raise newException(ValueError, $fieldName & " must be an enum, got " & $typeof(field.radioVal))
      of stSection:
        when field.content is object:
          initKNode($fieldName, children = encodeSettingsObj(field.content))
        else:
          raise newException(ValueError, $fieldName & " must be an object, got " & $typeof(field.content))
      of stRGB:
        encodeKdlNode(field.rgbVal, $fieldName)
      of stRGBA:
        encodeKdlNode(field.rgbaVal, $fieldName)
      # of stFile:
      #   encodeKdlNode(field.fileVal, $fieldName)
      # of stFiles:
      #   encodeKdlNode(field.filesVal, $fieldName)
      # of stFolder:
      #   encodeKdlNode(field.folderVal, $fieldName)

    result.add node

proc encodeKdl*(a: Settings, v: var KdlNode, name: string) =
  v = initKNode(name, children = encodeSettingsObj(a))

type
  ExportKind* = enum
    Nim, Cpp, CSharp, ImStyle, Publish

  Prefs* {.defaults: {defExported}.} = object
    maximized* = false
    winpos* = (x: -1i32, y: -1i32) # < 0: center the window
    winsize* = (w: 1500i32, h: 700i32)
    settings* = initSettings()
    currentView* = 1
    currentTheme* = 0
    currentSort* = 0
    themes* = [classicTheme, darkTheme, lightTheme, cherryTheme]
    starred*: seq[Theme]

  App* = object
    win*: GLFWWindow
    config*: Config
    prefs*: KdlPrefs[Prefs] # These are the values that will be saved in the prefs file
    fonts*: array[Config.fonts.len, ptr ImFont]
    resources*: Table[string, string]

    maxLabelWidth*: float32 # For the settings modal

    lastClipboard*: string
    showFramerate*: bool
    downloader*: Downloader

    # Publish popup
    themeDesc*: string
    publishFilters*: seq[string]
    publishScreen*: int

    # Views
    currentView*, hoveredView*: int

    # Edit view
    currentTheme*: int
    currentExportTab*: int
    newThemeName*: string # Create theme popup
    newThemeTemplate*: int # Create theme popup
    editingTheme*, themeSaved*, publishTextCopied*: bool # Editing theme, saved theme, copied publish text
    prevAvail*: ImVec2 # Previous avail content (to adjust the splitters ratio when changing window size)
    editSplitterSize1*, editSplitterSize2*: tuple[a, b: float32]
    # themeStyle*: ImGuiStyle # Current theme style
    # prevThemeStyle*: ImGuiStyle # Current theme style before saving

    # Preview window
    previewCheck*: bool
    previewBuffer*: string
    previewValuesOffset*: int32
    previewCol*, previewCol2*: array[4, float32]
    previewValues*: array[90, float32]
    previewProgress*, previewProgressDir*: float32
    previewSlider*, previewRefreshTime*, previewPhase*: float32

    # Editor
    sizesBuffer*, colorsBuffer*: string

    # Browse view
    feed*: seq[Theme]
    browseSplitterSize*: tuple[a, b: float32]
    browseCurrentTheme*: Theme
    browseBuffer*: string
    currentSort*: int
    filters*: seq[string]
    authorFilter*: string

  ImageData* = tuple[image: seq[byte], width, height: int]

