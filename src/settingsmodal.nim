import std/[strutils, options, tables, os]

import kdl/prefs
import tinydialogs
import nimgl/imgui

import utils, icons, types

proc drawSettings(settings: var object, settingsConfig: OrderedTable[string, Setting], maxLabelWidth: float32) = 
  for name, field in settings.fieldPairs:
    var key: string
    
    for k in settingsConfig.keys:
      if k.eqIdent name:
        key = k
        break

    let data = settingsConfig[key]
    let label = cstring (if data.display.len > 0: data.display else: key.capitalizeAscii()) & ": "
    let id = cstring "##" & name
    if data.kind != stSection:
      igText(label); igSameLine(0, 0)
      igDummy(igVec2(maxLabelWidth - igCalcTextSize(label).x, 0))
      igSameLine(0, 0)

    case data.kind
    of stInput:
      assert field is string
      when field is string:
        let flags = parseMakeFlags[ImGuiInputTextFlags](data.flags)
        let buffer = newString(int data.maxbuf, field)

        if data.hint.isSome:
          if igInputTextWithHint(id, cstring data.hint.get, cstring buffer, data.maxbuf, flags):
            field = buffer.cleanString()
        else:
          if igInputText(id, cstring buffer, data.maxbuf, flags):
            field = buffer.cleanString()
    of stCheck:
      assert field is bool
      when field is bool:
        igCheckbox(id, field.addr)
    of stSlider:
      assert field is int32
      assert data.min.isSome and data.max.isSome
      when field is int32:
        igSliderInt(
          id, 
          field.addr, 
          int32 data.min.get, 
          int32 data.max.get, 
          cstring (if data.format.isSome: data.format.get else: "%d"), 
          parseMakeFlags[ImGuiSliderFlags](data.flags)
        )
    of stFSlider:
      assert field is float32
      assert data.min.isSome and data.max.isSome
      when field is float32:
        igSliderFloat(
          id, 
          field.addr, 
          data.min.get, 
          data.max.get, 
          cstring (if data.format.isSome: data.format.get else: "%.3f"), 
          parseMakeFlags[ImGuiSliderFlags](data.flags)
        )
    of stSpin:    
      assert field is int32
      when field is int32:
        var temp = field
        if igInputInt(
          id, 
          temp.addr, 
          int32 data.step, 
          int32 data.stepfast, 
          parseMakeFlags[ImGuiInputTextFlags](data.flags)
        ) and (data.min.isNone or temp >= int32(data.min.get)) and (data.max.isNone or temp <= int32(data.max.get)): 
          field = temp
    of stFSpin:
      assert field is float32
      when field is float32:
        var temp = field
        if igInputFloat(
          id, 
          temp.addr, 
          data.step, 
          data.stepfast, 
          cstring (if data.format.isSome: data.format.get else: "%.3f"), 
          parseMakeFlags[ImGuiInputTextFlags](data.flags)
        ) and (data.min.isNone or temp >= data.min.get) and (data.max.isNone or temp <= data.max.get): 
          field = temp
    of stCombo:
      assert field is enum
      when field is enum:
        if igBeginCombo(id, cstring $field, parseMakeFlags[ImGuiComboFlags](data.flags)):
          for item in data.items:
            let itenum = parseEnum[typeof field](item)
            if igSelectable(cstring item, field == itenum):
              field = itenum

          igEndCombo()
    of stRadio: 
      assert field is enum
      when field is enum:
        for e, item in data.items:
          let itenum = parseEnum[typeof field](item)
          if igRadioButton(cstring $itenum & "##" & name & $e, itenum == field):
            field = itenum
        
          if e < data.items.high:
            igSameLine()
    of stRGB:
      assert field is tuple[r, g, b: float32]
      when field is tuple[r, g, b: float32]:
        var colArray = [field.r, field.g, field.b]
        if igColorEdit3(id, colArray, parseMakeFlags[ImGuiColorEditFlags](data.flags)):
          field = (colArray[0], colArray[1], colArray[2])
    of stRGBA:
      assert field is tuple[r, g, b, a: float32]
      when field is tuple[r, g, b, a: float32]:
        var colArray = [field.r, field.g, field.b, field.a]
        if igColorEdit4(id, colArray, parseMakeFlags[ImGuiColorEditFlags](data.flags)):
          field = (colArray[0], colArray[1], colArray[2], colArray[3])
    of stFile:
      assert field is string
      when field is string:
        igPushID(id)
        igInputTextWithHint(id, "Nothing selected", cstring field, uint field.len, flags = ImGuiInputTextFlags.ReadOnly)
        igSameLine()
        if (igIsItemHovered(flags = AllowWhenDisabled) and igIsMouseDoubleClicked(ImGuiMouseButton.Left)) or igButton("Browse " & FA_FolderOpen):
          if (let path = openFileDialog("Choose File", getCurrentDir() / "\0", data.filterPatterns, data.singleFilterDescription); path.len > 0):
            field = path
        igPopID()
    of stFiles:
      assert field is seq[string]
      when field is seq[string]:
        let str = field.join(",")
        igPushID(id)
        igInputTextWithHint(id, "Nothing selected", cstring str, uint str.len, flags = ImGuiInputTextFlags.ReadOnly)
        igSameLine()
        if (igIsItemHovered(flags = AllowWhenDisabled) and igIsMouseDoubleClicked(ImGuiMouseButton.Left)) or igButton("Browse " & FA_FolderOpen):
          if (let paths = openMultipleFilesDialog("Choose Files", getCurrentDir() / "\0", data.filterPatterns, data.singleFilterDescription); paths.len > 0):
            field = paths
        igPopID()
    of stFolder:
      assert field is string
      when field is string:
        igPushID(id)
        igInputTextWithHint(id, "Nothing selected", cstring field, uint field.len, flags = ImGuiInputTextFlags.ReadOnly)
        igSameLine()
        if (igIsItemHovered(flags = AllowWhenDisabled) and igIsMouseDoubleClicked(ImGuiMouseButton.Left)) or igButton("Browse " & FA_FolderOpen):
          if (let path = selectFolderDialog("Choose Folder", getCurrentDir() / "\0"); path.len > 0):
            field = path
        igPopID()
    of stSection:
      assert field is object
      when field is object:
        igPushID(id)
        if igCollapsingHeader(label, parseMakeFlags[ImGuiTreeNodeFlags](data.flags)):
          igIndent()
          drawSettings(field, data.content, maxLabelWidth)
          igUnindent()
        igPopID()

    if data.help.len > 0:
      igSameLine()
      igHelpMarker(data.help)

proc calcMaxLabelWidth(settings: OrderedTable[string, Setting]): float32 = 
  for name, data in settings:
    let label = cstring (if data.display.len > 0: data.display else: name.capitalizeAscii()) & ": "

    if (let width = (
      if data.kind == stSection:
        calcMaxLabelWidth(data.content)
      else:
        igCalcTextSize(label).x
      ); width > result):
      result = width

proc drawSettingsmodal*(app: var App) = 
  if app.settingsmodal.maxLabelWidth <= 0:
    app.settingsmodal.maxLabelWidth = app.config.settings.calcMaxLabelWidth()

  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

  if igBeginPopupModal("Settings", flags = makeFlags(AlwaysAutoResize, HorizontalScrollbar)):
    var close = false

    # app.settingsmodal.cache must be set to app.prefs[settings] once when opening the modal
    drawSettings(app.settingsmodal.cache, app.config.settings, app.settingsmodal.maxLabelWidth)

    igSpacing()

    if igButton("Save"):
      app.prefs.content.settings = app.settingsmodal.cache
      igCloseCurrentPopup()
    
    igSameLine()

    if igButton("Cancel"):
      app.settingsmodal.cache = app.prefs[settings]
      igCloseCurrentPopup()

    igSameLine()

    # Right aling button
    igSetCursorPosX(igGetCurrentWindow().size.x - igCalcFrameSize("Reset").x - igGetStyle().windowPadding.x)
    if igButton("Reset"):
      igOpenPopup("Reset")

    igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

    if igBeginPopupModal("Reset", flags = makeFlags(AlwaysAutoResize)):
      igPushTextWrapPos(250)
      igTextWrapped("Are you sure?\nYou won't be able to undo this action")
      igPopTextWrapPos()

      if igButton("Yes"):
        close = true
        app.prefs[settings] = app.prefs{settings}
        igCloseCurrentPopup()

      igSameLine()
    
      if igButton("Cancel"):
        igCloseCurrentPopup()

      igEndPopup()

    if close:
      igCloseCurrentPopup()

    igEndPopup()
