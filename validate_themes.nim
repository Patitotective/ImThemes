import std/[strformat, strutils, os]
import niprefs
import imstyle

const themesPath = "themes.toml"
const tags = [
  "light", "dark", "red", "blue", "green", "yellow", "orange", "purple", "magenta",
  "pink", "gray", "high-contrast", "rounded",
]
const props = [
  "alpha", "disabledAlpha", "windowPadding", "windowRounding", "windowBorderSize",
  "windowMinSize", "windowTitleAlign", "windowMenuButtonPosition", "childRounding",
  "childBorderSize", "popupRounding", "popupBorderSize", "framePadding",
  "frameRounding", "frameBorderSize", "itemSpacing", "itemInnerSpacing", "cellPadding",
  "indentSpacing", "columnsMinSpacing", "scrollbarSize", "scrollbarRounding",
  "grabMinSize", "grabRounding", "tabRounding", "tabBorderSize",
  "tabMinWidthForCloseButton", "colorButtonPosition", "buttonTextAlign",
  "selectableTextAlign", "colors",
]
const colors = [
  "Text", "TextDisabled", "WindowBg", "ChildBg", "PopupBg", "Border", "BorderShadow",
  "FrameBg", "FrameBgHovered", "FrameBgActive", "TitleBg", "TitleBgActive",
  "TitleBgCollapsed", "MenuBarBg", "ScrollbarBg", "ScrollbarGrab",
  "ScrollbarGrabHovered", "ScrollbarGrabActive", "CheckMark", "SliderGrab",
  "SliderGrabActive", "Button", "ButtonHovered", "ButtonActive", "Header",
  "HeaderHovered", "HeaderActive", "Separator", "SeparatorHovered", "SeparatorActive",
  "ResizeGrip", "ResizeGripHovered", "ResizeGripActive", "Tab", "TabHovered",
  "TabActive", "TabUnfocused", "TabUnfocusedActive", "PlotLines", "PlotLinesHovered",
  "PlotHistogram", "PlotHistogramHovered", "TableHeaderBg", "TableBorderStrong",
  "TableBorderLight", "TableRowBg", "TableRowBgAlt", "TextSelectedBg", "DragDropTarget",
  "NavHighlight", "NavWindowingHighlight", "NavWindowingDimBg", "ModalWindowDimBg",
]

proc hasValid(
    theme: TomlTableRef, name: string, key: string, kind: TomlKind, optional = false
): bool =
  if not optional and key notin theme:
    echo &"E: {name} has no {key}"
  elif (not optional or (optional and key in theme)) and theme[key].kind != kind:
    echo &"E: {name}'s {key} is of type {theme[key].kind} expected {kind}"
  elif (not optional or (optional and key in theme)) and
      kind in {TomlKind.Array, TomlKind.Tables, TomlKind.Table, TomlKind.String} and
      theme[key].len == 0:
    echo &"W: {name}'s {key} is empty"
    result = true
  else:
    result = true

proc check(): seq[tuple[idx: int, name: string]] =
  assert fileExists(getCurrentDir() / themesPath),
    &"E: Could not find {themesPath} in the current directory"

  var themes: TomlTables
  try:
    let data = Toml.loadFile(themesPath, TomlValueRef)
    assert "themes" in data, &"E: Could not find the themes keys in {themesPath}"
    assert data["themes"].kind == TomlKind.Tables,
      "E: The themes key is not an array of tables"
    themes = data["themes"].getTables()
  except TomlError:
    echo &"E: Could not parse {themesPath}"
    raise

  var valid: bool
  var names: seq[string]

  for e, theme in themes:
    valid = true
    var name = &"theme at index {e}"

    if theme.hasValid(name, "name", TomlKind.String):
      if theme["name"].getString().strip() != theme["name"].getString():
        echo &"W: {name}'s name has trailing or leading whitespaces"

      if theme["name"].getString() in names:
        echo &"E: repeated name {name}"
        valid = false
      else:
        names.add name
        name = theme["name"].getString() & " theme at index " & $e
    else:
      valid = false

    if not theme.hasValid(name, "author", TomlKind.String):
      valid = false
    if not theme.hasValid(name, "description", TomlKind.String):
      valid = false
    if not theme.hasValid(name, "tags", TomlKind.Array):
      valid = false
    if not theme.hasValid(name, "date", TomlKind.DateTime):
      valid = false
    if not theme.hasValid(name, "forkedFrom", TomlKind.String, optional = true):
      valid = false
    if theme.hasValid(name, "style", TomlKind.Table):
      for prop in props:
        if prop notin theme["style"]:
          echo &"E: {name}'s style misses {prop} property"
          valid = false

      if "colors" in theme["style"]:
        for col in colors:
          if col notin theme["style"]["colors"]:
            echo &"E: {name}'s style colors misses {col} color"
            valid = false

      try:
        discard styleFromToml(theme["style"])
      except ValueError, AssertionDefect:
        echo &"E: Could not loaded {name}'s style with ImStyle"
        valid = false
        echo getCurrentExceptionMsg()
    else:
      valid = false

    if not valid:
      result.add(
        (
          e,
          if "name" in theme:
            theme["name"].getString()
          else:
            "",
        )
      )

when isMainModule:
  let result = check()
  if result.len > 0:
    echo &"Check failed. {result.len} invalid themes: ", result
  else:
    echo "All themes are valid :]"

  quit(result.len)
