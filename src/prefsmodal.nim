import std/strutils

import niprefs
import nimgl/imgui

import utils

proc drawSettings(app: var App, settings: TomlValueRef, alignWidth: float32, parent = "")

proc drawSetting(app: var App, data: TomlValueRef, alignWidth: float32, parent = "") = 
  let name = data["name"].getString()
  proc getCacheVal(app: var App): TomlValueRef = 
    if parent.len > 0:
      app.cache{parent, name}
    else:
      app.cache[name]
  proc addToCache(app: var App, val: TomlValueRef) = 
    if parent.len > 0:
      app.cache{parent, name} = val
    else:
      app.cache[name] = val

  let settingType = parseEnum[SettingTypes](data["type"])
  let label = if "display" in data: data["display"].getString() else: name.capitalizeAscii()
  if settingType != Section:
    igText(cstring label.capitalizeAscii() & ": "); igSameLine(0, 0)
    igDummy(igVec2(alignWidth - igCalcTextSize(cstring label.capitalizeAscii() & ": ").x, 0)); igSameLine(0, 0)

  case settingType
  of Input:
    let
      flags = getFlags[ImGuiInputTextFlags](data["flags"])
      text = app.getCacheVal().getString()

    var buffer = newString(data["max"].getInt())
    buffer[0..text.high] = text

    if igInputTextWithHint(cstring "##" & name, if "hint" in data: data["hint"].getString().cstring else: "".cstring, buffer.cstring, data["max"].getInt().uint, flags):
      app.addToCache(buffer.newTString())
  of Check:
    var checked = app.getCacheVal().getBool()
    if igCheckbox(cstring "##" & name, checked.addr):
      app.addToCache(checked.newTBool())
  of Slider:
    let flags = getFlags[ImGuiSliderFlags](data["flags"])
    var val = app.getCacheVal().getInt().int32
    
    if igSliderInt(
      cstring "##" & name, 
      val.addr, 
      data["min"].getInt().int32, 
      data["max"].getInt().int32, 
      cstring data["format"].getString(), 
      flags
    ):
      app.addToCache(val.newTInt())
  of FSlider:
    let flags = getFlags[ImGuiSliderFlags](data["flags"])
    var val: float32 = app.getCacheVal().getFloat()
    
    if igSliderFloat(
      cstring "##" & name, 
      val.addr, 
      data["min"].getFloat(), 
      data["max"].getFloat(), 
      cstring data["format"].getString(), 
      flags
    ):
      app.addToCache(val.newTFloat())
  of Spin:
    let flags = getFlags[ImGuiInputTextFlags](data["flags"])
    var val = app.getCacheVal().getInt().int32
    
    if igInputInt(
      cstring "##" & name, 
      val.addr, 
      data["step"].getInt().int32, 
      data["step_fast"].getInt().int32, 
      flags
    ):
      app.addToCache(val.newTInt())
  of FSpin:
    let flags = getFlags[ImGuiInputTextFlags](data["flags"])
    var val = app.getCacheVal().getFloat().float32

    if igInputFloat(
      cstring "##" & name, 
      val.addr, 
      data["step"].getFloat(), 
      data["step_fast"].getFloat(), 
      data["format"].getString().cstring,
      flags
    ):
      app.addToCache(val.newTFloat())
  of Combo:
    let flags = getFlags[ImGuiComboFlags](data["flags"])
    var currentItem = app.getCacheVal()

    if currentItem.kind == TomlKind.Int:
      currentItem = data["items"][int currentItem.getInt()]

    if igBeginCombo(cstring "##" & name, currentItem.getString().cstring, flags):

      for i in data["items"].getArray():
        let selected = currentItem == i
        if igSelectable(i.getString().cstring, selected):
          app.addToCache(i)

        if selected:
          igSetItemDefaultFocus()

      igEndCombo()
  of Radio:
    var currentItem: int32

    if app.getCacheVal().kind == TomlKind.String:
      currentItem = data["items"].getArray().find(app.getCacheVal().getString()).int32
    else:
      currentItem = app.getCacheVal().getInt().int32

    for e, i in data["items"].getArray():
      if igRadioButton(i.getString().cstring, currentItem.addr, e.int32):
        app.addToCache(i)
      
      if e < data["items"].getArray().high:
        igSameLine()
  of Color3:
    let flags = getFlags[ImGuiColorEditFlags](data["flags"])
    var col = app.getCacheVal().parseColor3()

    if igColorEdit3(cstring "##" & name, col, flags):
      var color = newTArray()
      color.add col[0].newTFloat()
      color.add col[1].newTFloat()
      color.add col[2].newTFloat()
      app.addToCache(color)
  of Color4:
    let flags = getFlags[ImGuiColorEditFlags](data["flags"])
    var col = app.getCacheVal().parseColor4()
    
    if igColorEdit4(cstring "##" & name, col, flags):
      var color = newTArray()
      color.add col[0].newTFloat()
      color.add col[1].newTFloat()
      color.add col[2].newTFloat()
      color.add col[3].newTFloat()
      app.addToCache(color)
  of Section:
    let flags = getFlags[ImGuiTreeNodeFlags](data["flags"])

    if igCollapsingHeader(label.cstring, flags):
      if parent.len > 0:
        raise newException(ValueError, "Nested sections are not supported. Implement your own")
      else:
        app.drawSettings(data["content"], alignWidth, name)

  if "help" in data:
    igSameLine()
    igHelpMarker(data["help"].getString())

proc drawSettings(app: var App, settings: TomlValueRef, alignWidth: float32, parent = "") = 
  assert settings.kind == TomlKind.Tables

  for data in settings:
    let name = data["name"].getString()
    if parseEnum[SettingTypes](data["type"]) != Section:
      if parent.len > 0:
        if parent notin app.cache: app.cache[parent] = newTTable()
        if name notin app.cache[parent]:
          app.cache{parent, name} = app.prefs{parent, name}
      else:
        if name notin app.cache:
          app.cache[name] = app.prefs[name]

    app.drawSetting(data, alignWidth, parent)

proc calcAlignWidth(settings: TomlValueRef): float32 = 
  for data in settings:
    let label = if "display" in data: data["display"].getString() else: data["name"].getString().capitalizeAscii()
    var width: float32

    if parseEnum[SettingTypes](data["type"]) == Section:
      width = calcAlignWidth(data["content"])
    else:
      width = igCalcTextSize(cstring label & ": ").x

    if width > result: 
      result = width

proc drawPrefsModal*(app: var App) = 
  var close = false

  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

  if igBeginPopupModal("Preferences", flags = makeFlags(AlwaysAutoResize, HorizontalScrollbar)):
    app.drawSettings(app.config["settings"], calcAlignWidth(app.config["settings"]))

    igSpacing()

    if igButton("Save"):
      for name, val in app.cache:
        app.prefs[name] = val
      
      app.updatePrefs()
      igCloseCurrentPopup()
    
    igSameLine()

    if igButton("Cancel"):
      app.cache = newTTable()
      igCloseCurrentPopup()

    igSameLine()

    # Right aling button
    igSetCursorPosX(igGetCurrentWindow().size.x - igCalcFrameSize("Reset").x - igGetStyle().windowPadding.x)
    if igButton("Reset"):
      igOpenPopup("Reset?")

    igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

    if igBeginPopupModal("Reset?", flags = makeFlags(AlwaysAutoResize)):
      igPushTextWrapPos(250)
      igTextWrapped("Are you sure you want to reset the preferences?\nYou won't be able to undo this action")
      igPopTextWrapPos()

      if igButton("Yes"):
        close = true
        app.cache = newTTable()
        app.initConfig(app.config["settings"], overwrite = true)
        app.updatePrefs()

        igCloseCurrentPopup()

      igSameLine()
    
      if igButton("Cancel"):
        igCloseCurrentPopup()

      igEndPopup()

    if close:
      igCloseCurrentPopup()

    igEndPopup()
