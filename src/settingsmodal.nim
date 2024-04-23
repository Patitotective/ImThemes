import std/[typetraits, strutils, options, tables, macros, os] # threadpool
import micros
import kdl/prefs
# import tinydialogs
import nimgl/imgui

import utils, icons, types

proc settingLabel(name: string, setting: Setting[auto]): string =
  (if setting.display.len == 0: name else: setting.display) & ": "

proc drawSettings(settings: var object, maxLabelWidth: float32): bool =
  ## Returns wheter or not to open the block dialog (because a file dailog or so was open)

  for name, setting in settings.fieldPairs:
    let label = settingLabel(name, setting)
    let id = cstring "##" & name
    if setting.kind != stSection:
      igText(cstring label); igSameLine(0, 0)
      if igIsItemHovered():
        if igIsMouseReleased(ImGuiMouseButton.Right):
          igOpenPopup(cstring label)
        elif setting.help.len > 0:
          igSetToolTip(cstring setting.help)

      igDummy(igVec2(maxLabelWidth - igCalcTextSize(cstring label).x, 0))
      igSameLine(0, 0)

    case setting.kind
    of stInput:
      let flags = makeFlags(setting.inputFlags)
      let buffer = newString(setting.limits.b, setting.inputCache)

      if setting.hint.len > 0:
        if igInputTextWithHint(id, cstring setting.hint, cstring buffer, uint setting.limits.b, flags) and (let newBuffer = buffer.cleanString(); newBuffer.len >= setting.limits.a):
          setting.inputCache = newBuffer
      else:
        if igInputText(id, cstring buffer, uint setting.limits.b, flags) and (let newBuffer = buffer.cleanString(); newBuffer.len >= setting.limits.a):
          setting.inputCache = newBuffer
    of stCheck:
      igCheckbox(id, setting.checkCache.addr)
    of stSlider:
      igSliderInt(
        id,
        setting.sliderCache.addr,
        setting.sliderRange.a,
        setting.sliderRange.b,
        cstring setting.sliderFormat,
        makeFlags(setting.sliderFlags)
      )
    of stFSlider:
      igSliderFloat(
        id,
        setting.fsliderCache.addr,
        setting.fsliderRange.a,
        setting.fsliderRange.b,
        cstring setting.fsliderFormat,
        makeFlags(setting.fsliderFlags)
      )
    of stSpin:
      var temp = setting.spinCache
      if igInputInt(
        id,
        temp.addr,
        setting.step,
        setting.stepFast,
        makeFlags(setting.spinflags)
      ) and temp in setting.spinRange:
        setting.spinCache = temp
    of stFSpin:
      var temp = setting.fspinCache
      if igInputFloat(
        id,
        temp.addr,
        setting.fstep,
        setting.fstepFast,
        cstring setting.fspinFormat,
        makeFlags(setting.fspinflags)
      ) and temp in setting.fspinRange:
        setting.fspinCache = temp
    of stCombo:
      if igBeginCombo(id, cstring $setting.comboCache, makeFlags(setting.comboFlags)):
        for item in setting.comboItems:
          if igSelectable(cstring $item, item == setting.comboCache):
            setting.comboCache = item
        igEndCombo()
    of stRadio:
      for e, item in setting.radioItems:
        if igRadioButton(cstring $item & "##" & name, item == setting.radioCache):
          setting.radioCache = item

        if e < setting.radioItems.high:
          igSameLine()
    of stRGB:
      igColorEdit3(id, setting.rgbCache, makeFlags(setting.rgbFlags))
    of stRGBA:
      igColorEdit4(id, setting.rgbaCache, makeFlags(setting.rgbaFlags))
    # of stFile:
    #   if not setting.fileCache.flowvar.isNil and setting.fileCache.flowvar.isReady and (let val = ^setting.fileCache.flowvar; val.len > 0):
    #     setting.fileCache = (val: val, flowvar: nil) # Here we set flowvar to nil because once we acquire it's value it's not neccessary until it's spawned again

    #   igPushID(id)
    #   igInputTextWithHint("##input", "No file selected", cstring setting.fileCache.val, uint setting.fileCache.val.len, flags = ImGuiInputTextFlags.ReadOnly)
    #   igSameLine()
    #   if igButton("Browse " & FA_FolderOpen):
    #     setting.fileCache.flowvar = spawn openFileDialog("Choose File", getCurrentDir() / "\0", setting.fileFilterPatterns, setting.fileSingleFilterDescription)
    #     result = true
    #   igPopID()
    # of stFiles:
    #   if not setting.filesCache.flowvar.isNil and setting.filesCache.flowvar.isReady and (let val = ^setting.filesCache.flowvar; val.len > 0):
    #     setting.filesCache = (val: val, flowvar: nil) # Here we set flowvar to nil because once we acquire it's value it's not neccessary until it's spawned again

    #   let files = setting.filesCache.val.join(";")
    #   igPushID(id)
    #   igInputTextWithHint("##input", "No files selected", cstring files, uint files.len, flags = ImGuiInputTextFlags.ReadOnly)
    #   igSameLine()
    #   if igButton("Browse " & FA_FolderOpen):
    #     setting.filesCache.flowvar = spawn openMultipleFilesDialog("Choose Files", getCurrentDir() / "\0", setting.filesFilterPatterns, setting.filesSingleFilterDescription)
    #     result = true
    #   igPopID()
    # of stFolder:
    #   if not setting.folderCache.flowvar.isNil and setting.folderCache.flowvar.isReady and (let val = ^setting.folderCache.flowvar; val.len > 0):
    #     setting.folderCache = (val: val, flowvar: nil) # Here we set flowvar to nil because once we acquire it's value it's not neccessary until it's spawned again

    #   igPushID(id)
    #   igInputTextWithHint("##input", "No folder selected", cstring setting.folderCache.val, uint setting.folderCache.val.len, flags = ImGuiInputTextFlags.ReadOnly)
    #   igSameLine()
    #   if igButton("Browse " & FA_FolderOpen):
    #     setting.folderCache.flowvar = spawn selectFolderDialog("Choose Folder", getCurrentDir() / "\0")
    #     result = true
    #   igPopID()
    of stSection:
      if igCollapsingHeader(cstring label, makeFlags(setting.sectionFlags)):
        if igIsItemHovered():
          if igIsMouseReleased(ImGuiMouseButton.Right):
            igOpenPopup(cstring label)

        igPushID(id); igIndent()
        when setting.content is object:
          result = drawSettings(setting.content, maxLabelWidth)
        igUnindent(); igPopID()
      else: # When the header is closed
        if igIsItemHovered():
          if igIsMouseReleased(ImGuiMouseButton.Right):
            igOpenPopup(cstring label)

    if igBeginPopup(cstring label):
      if igSelectable(cstring("Reset " & label[0..^3] #[remove the ": "]# & " to default")):
        setting.cacheToDefault()
      igEndPopup()

    if setting.help.len > 0 and setting.kind != stSection:
      igSameLine()
      igHelpMarker(setting.help)

proc calcMaxLabelWidth(settings: object): float32 =
  when settings is object:
    for name, setting in settings.fieldPairs:
      when setting is Setting:
        let label = settingLabel(name, setting)

        let width =
          if setting.kind == stSection:
            when setting.content is object:
              calcMaxLabelWidth(setting.content)
            else: 0f
          else:
            igCalcTextSize(cstring label).x
        if width > result:
          result = width
      else:
        {.error: name & "is not a settings object".}

proc drawSettingsmodal*(app: var App) =
  if app.maxLabelWidth <= 0:
    app.maxLabelWidth = app.prefs[settings].calcMaxLabelWidth()

  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))

  if igBeginPopupModal("Settings", flags = makeFlags(AlwaysAutoResize, HorizontalScrollbar)):
    var close = false

    if drawSettings(app.prefs[settings], app.maxLabelWidth):
      igOpenPopup("###blockdialog")

    app.drawBlockDialogModal()

    igSpacing()

    if igButton("Save"):
      app.prefs[settings].save()
      igCloseCurrentPopup()

    igSameLine()

    if igButton("Cancel"):
      initCache(app.prefs[settings])
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
