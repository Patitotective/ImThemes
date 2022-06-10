import std/[httpclient, strutils, os]
import niprefs
import imstyle
import nimgl/imgui

import utils

const feedURL = "https://github.com/Patitotective/ImThemes/blob/main/themes.toml?raw=true"
var
  fetched = false
  fetchThread: Thread[string]

proc fetch(path: string) = 
  newHttpClient().downloadFile(feedURL, path)
  fetched = true

proc drawBrowseView*(app: var App) = 
  if not fetched and not fetchThread.running:
    fetchThread.createThread(fetch, app.getCacheDir() / "themes.toml")
  elif fetched and app.feed.isNil:
    app.feed = Toml.loadFile(app.getCacheDir() / "themes.toml", TomlValueRef)["themes"]

  let style = igGetStyle()
  let avail = igGetContentRegionAvail()

  # Keep splitter proportions on resize
  # And hide the editing zone when not editing
  if app.prevAvail != igVec2(0, 0) and app.prevAvail != avail:
    app.browseSplitterSize = ((app.browseSplitterSize.a / app.prevAvail.x) * avail.x, (app.browseSplitterSize.b / app.prevAvail.x) * avail.x)

  app.prevAvail = avail

  # First time
  if app.browseSplitterSize.a == 0:
    app.browseSplitterSize = (avail.x * 0.2f, avail.x * 0.8f)

  if fetched and not app.feed.isNil:
    igSplitter(true, 8, app.browseSplitterSize.a.addr, app.browseSplitterSize.b.addr, style.windowMinSize.x, style.windowMinSize.x, avail.y)
    # List
    if igBeginChild("##browseList", igVec2(app.browseSplitterSize.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
      igInputTextWithHint("##search", "Search...", cstring app.browseBuffer, 64)
      igSeparator()

      for e, theme in app.feed.getArray():
        if app.browseBuffer.passFilter(theme["name"].getString()) and igSelectable(cstring theme["name"].getString()):
          app.browseCurrentTheme = e

    igEndChild(); igSameLine()

    # Preivew
    if igBeginChild("##browsePreview", igVec2(app.browseSplitterSize.b, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
      if app.browseCurrentTheme >= 0:
        igSetNextWindowPos(igGetWindowPos())
        igSetNextWindowSize(igGetWindowSize())

        app.drawStylePreview(app.feed[app.browseCurrentTheme]["name"].getString(), app.feed[app.browseCurrentTheme]["style"].styleFromToml())
    
    igEndChild()
  else:
    igCenterCursor(ImVec2(x: 15 * 2, y: (15 + igGetStyle().framePadding.y) * 2))
    igSpinner("##spinner", 15, 6, igGetColorU32(ButtonHovered))
