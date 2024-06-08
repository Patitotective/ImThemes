import std/[tables, threadpool]
import std/macros except eqIdent # since it conflicts with kdl/util.eqIdent

import nimgl/[imgui, glfw]
import tinydialogs
import kdl, kdl/[types, utils]
import constructor/defaults
import downit

import configtype, settingstypes, themes

export configtype

proc toSeq[T: enum](_: typedesc[T]): seq[T] =
  for i in T:
    result.add i

type
  Settings* {.defaults: {}.} = object
    proxy* = inputSetting(display = "Proxy", default = "", hint = "http://127.0.0.1:8081/", help = "Leave empty to disable proxy")
    proxyUser* = inputSetting(display = "Proxy username", default = "")
    proxyPassword* = inputSetting(display = "Proxy password", default = "")

proc decodeSettingsObj*(a: KdlNode, v: var object) =
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
        of stFile:
          field.fileVal = decodeKdl(child, typeof(field.fileVal))
        of stFiles:
          field.filesVal = decodeKdl(child, typeof(field.filesVal))
        of stFolder:
          field.folderVal = decodeKdl(child, typeof(field.folderVal))

proc decodeKdl*(a: KdlNode, v: var Settings) =
  v = initSettings()
  decodeSettingsObj(a, v)

proc encodeKdl*[T](a: FlowVar[T], v: var KdlVal) =
   if a.isNil or not a.isReady:
     v = initKNull()
   else:
     v = encodeKdlVal(^a)

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
      of stFile:
        encodeKdlNode(field.fileVal, $fieldName)
      of stFiles:
        encodeKdlNode(field.filesVal, $fieldName)
      of stFolder:
        encodeKdlNode(field.folderVal, $fieldName)

    result.add node

proc encodeKdl*(a: Settings, v: var KdlNode, name: string) =
  v = initKNode(name, children = encodeSettingsObj(a))

type
  ExportKind* = enum
    Nim, Cpp, CSharp, ImStyle, Publish

  View = enum
    vEditView, vBrowseView

  Prefs* {.defaults: {defExported}.} = object
    maximized* = false
    winpos* = (x: -1i32, y: -1i32) # < 0: center the window
    winsize* = (w: 1500i32, h: 700i32)
    settings* = initSettings()
    currentView* = vBrowseView
    currentTheme* = 0
    currentSort* = 0
    themes* = [classicTheme, darkTheme, lightTheme, cherryTheme]
    starred*: seq[Theme]

  EditView* = object
    currentTheme*: int
    currentExportTab*: int
    newThemeName*: string # Create theme popup
    newThemeTemplate*: int # Create theme popup
    editingTheme*, themeSaved*, publishTextCopied*: bool # Editing theme, saved theme, copied publish text
    prevAvail*: ImVec2 # Previous avail content (to adjust the splitters ratio when changing window size)
    editSplitterSize1*, editSplitterSize2*: tuple[a, b: float32]
    # themeStyle*: ImGuiStyle # Current theme style
    # prevThemeStyle*: ImGuiStyle # Current theme style before saving

  BrowseView* = object
    # Browse view
    feed*: seq[Theme]
    browseSplitterSize*: tuple[a, b: float32]
    browseCurrentTheme*: Theme
    browseBuffer*: string
    currentSort*: int
    filters*: seq[string]
    authorFilter*: string


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
    currentView*, hoveredView*: View

    # Edit view

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

  ImageData* = tuple[image: seq[byte], width, height: int]

