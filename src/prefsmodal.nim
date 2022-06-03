import std/strutils

import niprefs
import nimgl/imgui
import niprefs/utils as prefsUtils

import utils

proc drawSettings(app: var App, settings: PrefsNode, alignCount: Natural, parent = "")

proc drawSetting(app: var App, name: string, data: PObjectType, alignCount: Natural, parent = "") = 
  proc getCacheVal(app: var App): PrefsNode = 
    if parent.len > 0:
      app.cache.getNested(parent, name)
    else:
      app.cache[name]
  proc addToCache(app: var App, val: PrefsNode) = 
    if parent.len > 0:
      app.cache = app.cache.changeNested(parent, name, val)
    else:
      app.cache[name] = val

  let settingType = parseEnum[SettingTypes](data["type"])
  let label = if "display" in data: data["display"].getString() else: name.capitalizeAscii()
  if settingType != Section:
    igText(cstring (label & ": ").alignLeft(alignCount))
    igSameLine()

  case settingType
  of Input:
    let
      flags = getFlags[ImGuiInputTextFlags](data["flags"])
      text = app.getCacheVal().getString()

    var buffer = newString(data["max"].getInt())
    buffer[0..text.high] = text

    if igInputTextWithHint(cstring "##" & name, if "hint" in data: data["hint"].getString().cstring else: "".cstring, buffer.cstring, data["max"].getInt().uint, flags):
      app.addToCache(buffer.newPString())
  of Check:
    var checked = app.getCacheVal().getBool()
    if igCheckbox(cstring "##" & name, checked.addr):
      app.addToCache(checked.newPBool())
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
      app.addToCache(val.newPInt())
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
      app.addToCache(val.newPFloat())
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
      app.addToCache(val.newPInt())
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
      app.addToCache(val.newPFloat())
  of Combo:
    let flags = getFlags[ImGuiComboFlags](data["flags"])
    var currentItem = app.getCacheVal()

    if currentItem.kind == PInt:
      currentItem = data["items"][int currentItem.getInt()]

    if igBeginCombo(cstring "##" & name, currentItem.getString().cstring, flags):

      for i in data["items"].getSeq():
        let selected = currentItem == i
        if igSelectable(i.getString().cstring, selected):
          app.addToCache(i)

        if selected:
          igSetItemDefaultFocus()

      igEndCombo()
  of Radio:
    var currentItem: int32

    if app.getCacheVal().kind == PString:
      currentItem = data["items"].getSeq().find(app.getCacheVal().getString()).int32
    else:
      currentItem = app.getCacheVal().getInt().int32

    for e, i in data["items"].getSeq():
      if igRadioButton(i.getString().cstring, currentItem.addr, e.int32):
        app.addToCache(i)
      
      if e < data["items"].getSeq().high:
        igSameLine()
  of Color3:
    let flags = getFlags[ImGuiColorEditFlags](data["flags"])
    var col = app.getCacheVal().parseColor3()

    if igColorEdit3(cstring "##" & name, col, flags):
      var color = newPSeq()
      color.add col[0].newPFloat()
      color.add col[1].newPFloat()
      color.add col[2].newPFloat()
      app.addToCache(color)
  of Color4:
    let flags = getFlags[ImGuiColorEditFlags](data["flags"])
    var col = app.getCacheVal().parseColor4()
    
    if igColorEdit4(cstring "##" & name, col, flags):
      var color = newPSeq()
      color.add col[0].newPFloat()
      color.add col[1].newPFloat()
      color.add col[2].newPFloat()
      color.add col[3].newPFloat()
      app.addToCache(color)
  of Section:
    let flags = getFlags[ImGuiTreeNodeFlags](data["flags"])
    if igCollapsingHeader(label.cstring, flags):
      if parent.len > 0:
        app.drawSettings(data["content"], alignCount, parent & "/" & name)
      else:
        app.drawSettings(data["content"], alignCount, name)

  if "help" in data:
    igSameLine()
    igHelpMarker(data["help"].getString())

proc drawSettings(app: var App, settings: PrefsNode, alignCount: Natural, parent = "") = 
  assert settings.kind == PObject

  for name, data in settings:
    if parseEnum[SettingTypes](data["type"]) != Section:
      if parent.len > 0:
        if parent notin app.cache: app.cache[parent] = newPObject()
        if name notin app.cache[parent]:
          app.cache = app.cache.changeNested(parent, name, app.prefs[parent, name])
      else:
        if name notin app.cache:
          app.cache[name] = app.prefs[name]

    app.drawSetting(name, data.getObject(), alignCount, parent)

proc drawPrefsModal*(app: var App) = 
  proc calcAlignCount(settings: PrefsNode, margin: int = 6): Natural = 
    for name, data in settings:
      if parseEnum[SettingTypes](data["type"]) == Section:
        let alignCount = calcAlignCount(data["content"])
        if alignCount > result: result = alignCount+margin
      else:
        if name.len > result: result = name.len+margin

  var close = false

  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

  if igBeginPopupModal("Preferences", flags = makeFlags(AlwaysAutoResize, HorizontalScrollbar)):
    app.drawSettings(app.config["settings"], calcAlignCount(app.config["settings"]))

    igSpacing()

    if igButton("Save"):
      for name, val in app.cache:
        app.prefs[name] = val
      
      app.updatePrefs()
      igCloseCurrentPopup()
    
    igSameLine()

    if igButton("Cancel"):
      app.cache = default PObjectType
      igCloseCurrentPopup()

    igSameLine()

    # Right aling button
    igSetCursorPosX(igGetCurrentWindow().size.x - (igCalcTextSize("Reset").x + (igGetStyle().framePadding.x * 2)) - igGetStyle().windowPadding.x)
    if igButton("Reset"):
      igOpenPopup("Reset?")

    igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

    if igBeginPopupModal("Reset?", flags = makeFlags(AlwaysAutoResize)):
      igPushTextWrapPos(250)
      igTextWrapped("Are you sure you want to reset the preferences?\nYou won't be able to undo this action")
      igPopTextWrapPos()

      if igButton("Yes"):
        close = true
        app.prefs.overwrite()
        app.initConfig(app.config["settings"])
        app.cache = default PObjectType
        app.updatePrefs()

        igCloseCurrentPopup()

      igSameLine()
    
      if igButton("Cancel"):
        igCloseCurrentPopup()

      igEndPopup()

    if close:
      igCloseCurrentPopup()

    igEndPopup()
