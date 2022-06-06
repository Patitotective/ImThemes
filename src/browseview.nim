import nimgl/imgui

import utils

proc drawBrowseView*(app: var App) = 
  let style = igGetStyle()
  let avail = igGetContentRegionAvail()

  # Keep splitter proportions on resize
  # And hide the editing zone when not editing
  if app.prevAvail != igVec2(0, 0) and app.prevAvail != avail:
    app.browseSplitterSize = ((app.browseSplitterSize.a / app.prevAvail.x) * avail.x, (app.browseSplitterSize.b / app.prevAvail.x) * avail.x)

  app.prevAvail = avail

  # First time
  if app.browseSplitterSize.a == 0:
    app.browseSplitterSize = (avail.x * 0.5f, avail.x * 0.5f)

  igSplitter(true, 8, app.browseSplitterSize.a.addr, app.browseSplitterSize.b.addr, style.windowMinSize.x, style.windowMinSize.x, avail.y)
  # List
  if igBeginChild("##browseList", igVec2(app.browseSplitterSize.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
    igText("List")
  igEndChild(); igSameLine()

  # Preivew
  if igBeginChild("##browsePreview", igVec2(app.browseSplitterSize.b, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
    igText("Preview")
  igEndChild()
