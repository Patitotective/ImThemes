import std/sequtils
import niprefs
import imstyle
import nimgl/imgui

import editor, utils

proc validThemeName(app: App): bool =
  let n = app.newThemeName.cleanString()
  n.len > 0 and not app.prefs[themes].anyIt(it.name == n) 

proc drawCreateThemeModal(app: var App) = 
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if igBeginPopupModal("New Theme", flags = makeFlags(AlwaysAutoResize)):
    igInputTextWithHint("##themeName", "Name", cstring app.newThemeName, 64)
    
    let templates = app.prefs[themes]
    if igBeginCombo("##templateCombo", cstring(if app.newThemeTemplate < 0: "Choose a template" else: templates[app.newThemeTemplate].name)):
      for e, theme in templates.getTables:
        if igSelectable(cstring theme.name, e == app.newThemeTemplate):
          app.newThemeTemplate = e

      igEndCombo()

    var okBtnDisabled = false
    if not app.validThemeName() or app.newThemeTemplate < 0:
      okBtnDisabled = true
      igBeginDisabled()

    if igButton("Ok"):
      app.prefs[themes].add Theme(name: app.newThemeName.cleanString(), style: templates[app.newThemeTemplate].style)
      app.switchTheme(app.prefs[themes].high)

      igCloseCurrentPopup()

    if okBtnDisabled:
      igEndDisabled()

    igSameLine()
    if igButton("Cancel"): igCloseCurrentPopup()
    
    igEndPopup()

proc drawDeleteThemeModal(app: var App) = 
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if igBeginPopupModal("Delete Theme", flags = AlwaysAutoResize):
    igText("Are you sure you want to delete it?\n You won't be able to undo this action.")

    if igButton("Yes"):
      app.prefs[themes].delete(app.currentTheme)
      app.switchTheme(0)
      igCloseCurrentPopup()

    igSameLine()
    if igButton("No"):
      igCloseCurrentPopup()

    igEndPopup()

proc drawEditNameModal(app: var App) = 
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if igBeginPopupModal("Edit Name", flags = makeFlags(AlwaysAutoResize)):
    igInputTextWithHint("##themeName", "Name", cstring app.newThemeName, 64)

    var okBtnDisabled = false
    if not app.validThemeName():
      okBtnDisabled = true
      igBeginDisabled()
    
    if (not okBtnDisabled and igIsItemActivePreviousFrame() and not igIsItemActive() and igIsKeyPressedMap(ImGuiKey.Enter)) or igButton("Ok"):
      app.prefs[themes][app.currentTheme].name = app.newThemeName.cleanString()

      igCloseCurrentPopup()

    if okBtnDisabled:
      igEndDisabled()

    igSameLine()
    if igButton("Cancel"): igCloseCurrentPopup()
    
    igEndPopup()

proc drawPublishThemeModal(app: var App) = 
  let unusedOpen = true

  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  if app.publishScreen == 0:
    igSetNextWindowSize(igVec2(365, 0))
  else:
    igSetNextWindowSize(igVec2(365, 400))

  if igBeginPopupModal("Publish Theme", unusedOpen.unsafeAddr, flags = ImGuiWindowFlags.NoResize):
    let style = igGetStyle()
    if app.publishScreen == 0:
      igSetNextItemWidth(igGetContentRegionAvail().x)
      if igInputTextWithHint("##themeName", "Name", cstring app.newThemeName, 64): app.publishTextCopied = false
      igSetNextItemWidth(igGetContentRegionAvail().x)
      if igInputTextWithHint("##themeDesc", "Description", cstring app.themeDesc, 128): app.publishTextCopied = false

      igText("Tag: "); igSameLine()
      if app.drawFilters(app.publishFilters, filterTag = tags, addBtnRight = false): app.publishTextCopied = false
      
      if igButton("Next"): app.publishScreen = 1

    else:
      let theme = app.prefs[themes][app.currentTheme]

      igText("Copy the following text and paste it at the end of")
      igURLText("https://github.com/Patitotective/ImThemes/edit/main/themes.toml", "themes.toml", sameLineBefore = false)
      igText(" at the root of the ImThemes GitHub")
      igText("repository and ")
      igURLText("https://github.com/Patitotective/ImThemes/compare", "make a pull request.", sameLineAfter = false)

      app.drawExportTabs(
        app.themeStyle, 
        app.newThemeName.cleanString(), 
        author = theme.author, 
        description = app.themeDesc.cleanString(), 
        forkedFrom = theme.forkedFrom.get(""), 
        tags = app.publishFilters, 
        tabs = {Publish}, 
        availDiff = igVec2(0, igGetFrameHeight() + style.itemSpacing.y)
      )
      if igButton("Back"): app.publishScreen = 0

    igEndPopup()

proc drawThemesList(app: var App) = 
  let style = igGetStyle()

  # To make it not clickable
  igPushItemFlag(ImGuiItemFlags.Disabled, true)
  igSelectable("Themes", true)
  igPopItemFlag()

  if igBeginListBox("##themes", igVec2(app.editSplitterSize1.a, igGetContentRegionAvail().y - igGetFrameHeight() - style.windowPadding.y)):
    var openRename, openDelete = false

    for e, theme in app.prefs[themes]:
      let selected = e == app.currentTheme
      let name = cstring theme.name & (if app.isThemeReadOnly(e): " (Read-Only)" else: "")

      if igSelectable(name, selected) and (not selected or (selected and app.editing)):
        app.switchTheme(e)

      if not app.isThemeReadOnly(e) and igIsItemHovered() and (igIsMouseDoubleClicked(ImGuiMouseButton.Left) or igIsMouseClicked(ImGuiMouseButton.Right)):
        if not selected: app.switchTheme(e)
        igOpenPopup("contextMenu")

    if igBeginPopup("contextMenu"):
      if igMenuItem("Rename"):
        app.newThemeName = newString(64, app.prefs[themes][app.currentTheme].name)
        openRename = true
      if igMenuItem("Delete"):
        openDelete = true
      igEndPopup()

    if openRename: igOpenPopup("Edit Name")
    if openDelete: igOpenPopup("Delete Theme")

    app.drawEditNameModal()
    app.drawDeleteThemeModal()

    igEndListBox()

  if igButton("Create"):
    (app.newThemeName, app.newThemeTemplate) = (newString(64), -1)
    igOpenPopup("New Theme")

  igSameLine()
  
  let readOnly = app.isThemeReadOnly(app.currentTheme)
  var editBtnDisabled = false # When editing editBtn means discardBtn and SaveBtn

  if readOnly or (app.editingTheme and app.themeS+aved): # Cannot edit a read-only theme or an already saved theme
    editBtnDisabled = true
    igBeginDisabled()

  if app.editingTheme:
    if igButton("Discard") :
      app.themeStyle = app.prevThemeStyle
      app.prefs[themes][app.currentTheme].style = app.prefs[themes][app.currentTheme].prevStyle.get() ## FIXME check if prevstyle isSome

    if igIsItemHovered(AllowWhenDisabled):
      if editBtnDisabled:
        igEndDisabled() # To show tooltips with normal alpha
        igSetTooltip("No changes to discard")
        igBeginDisabled() # Restore disabled alpha
      else:
        igSetTooltip("Discard changes")

    igSameLine()
    if igButton("Save"):
      app.prevThemeStyle = app.themeStyle
      app.prefs[themes][app.currentTheme].prevStyle = app.prefs[themes][app.currentTheme].style.some()

    if igIsItemHovered(AllowWhenDisabled):
      if editBtnDisabled:
        igEndDisabled() # To show tooltips with normal alpha
        igSetTooltip("No changes to save")
        igBeginDisabled()
      else:
        igSetTooltip("Save changes")
  else:
    if igButton("Edit"):
      app.editing = true

    if editBtnDisabled and igIsItemHovered(AllowWhenDisabled):
      igEndDisabled() # To show tooltips with normal alpha
      igSetTooltip("Read-Only")
      igBeginDisabled()

  if editBtnDisabled:
    igEndDisabled()

  if readOnly:
    igBeginDisabled()

  if not app.editing:
    igSameLine()
    if igButton("Publish"):
      app.themeName = newString(64, app.prefs[themes][app.currentTheme].name)
      app.themeDesc = newString(128)
      app.publishScreen = 0
      app.publishFilters.reset()
      igOpenPopup("Publish Theme")

  if readOnly:
    igEndDisabled()
    if igIsItemHovered(AllowWhenDisabled):
      igSetTooltip("Read-Only")

  igSameLine()
  if igButton("Export"):
    app.copied = false
    igOpenPopup("###exportTheme")

  app.drawCreateThemeModal()
  app.drawPublishThemeModal()
  app.drawExportThemeModal(app.themeStyle, app.prefs[themes][app.currentTheme].name)

proc drawEditView*(app: var App) = 
  const splitterWidth = 8f
  let avail = igGetContentRegionAvail() - igVec2(splitterWidth * 2, 0)
  let minSize = igGetStyle().windowMinSize.x

  # Keep splitter proportions on resize
  # And hide the editing zone when not editing
  if app.prevAvail != igVec2(0, 0) and app.prevAvail != avail:
    if app.editing:
      (app.editSplitterSize1, app.editSplitterSize2) = (
        ((app.editSplitterSize1.a / app.prevAvail.x) * avail.x, 0f), 
        ((app.editSplitterSize2.a / app.prevAvail.x) * avail.x, (app.editSplitterSize2.b / app.prevAvail.x) * avail.x)
      )
    else:
      (app.editSplitterSize1, app.editSplitterSize2) = (
        ((app.editSplitterSize1.a / app.prevAvail.x) * avail.x, 0f), 
        ((app.editSplitterSize2.a / app.prevAvail.x) * avail.x, 0f)
      )

  app.prevAvail = avail

  # First time or when switch editing
  if app.editing and app.editSplitterSize2.b == 0f:
    (app.editSplitterSize1, app.editSplitterSize2) = ((avail.x * 0.15f, 0f), (avail.x * 0.425f, avail.x * 0.425f))
  elif app.editSplitterSize1.a == 0f:
    (app.editSplitterSize1, app.editSplitterSize2) = ((avail.x * 0.5f, 0f), (avail.x * 0.5f, 0f))

  igSplitter(true, splitterWidth, app.editSplitterSize1.a.addr, app.editSplitterSize2.a.addr, minSize, minSize, avail.y)

  # List
  if igBeginChild("##editViewThemes", igVec2(app.editSplitterSize1.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding, NoScrollWithMouse)):
    app.drawThemesList()
  igEndChild(); igSameLine(spacing = splitterWidth)

  # Second Splitter
  if igBeginChild("##editViewSplitter2", igVec2(app.editSplitterSize2.a + app.editSplitterSize2.b, avail.y), flags = NoScrollWithMouse):
    igSplitter(true, splitterWidth, app.editSplitterSize2.a.addr, app.editSplitterSize2.b.addr, minSize, if app.editing: minSize else: 0, avail.y)
    # Preview
    if igBeginChild("##editViewPreviewer", igVec2(app.editSplitterSize2.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
      igSetNextWindowPos(igGetWindowPos())
      igSetNextWindowSize(igGetWindowSize())

      app.drawStylePreview(app.prefs[themes][app.currentTheme].name & (if app.isThemeReadOnly(app.currentTheme): " (Read-Only)" else: ""), app.themeStyle)

    igEndChild(); igSameLine(spacing = splitterWidth)

    # Editor
    if app.editing:
      app.prefs[themes][app.currentTheme].style = app.themeStyle.styleToToml()
      app.saved = app.themeStyle == app.prevThemeStyle

      if igBeginChild("##editViewEditor", igVec2(app.editSplitterSize2.b, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
        app.drawEditor(app.themeStyle)
      igEndChild()

  igEndChild()
