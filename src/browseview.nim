import std/[httpclient, json, os]
import nimgl/imgui

import utils

const feedURL = "https://raw.githubusercontent.com/Patitotective/ImThemes/main/themes.json"
var
  fetched = false
  fetchThread: Thread[string]

proc fetch(path: string) = 
  newHttpClient().downloadFile(feedURL, path)
  fetched = true

proc drawBrowseView*(app: var App) = 
  if not fetched and not fetchThread.running:
    fetchThread.createThread(fetch, app.getCacheDir() / "themes.json")
  elif fetched and app.feed.len == 0:
    app.feed = parseJson(readFile(app.getCacheDir() / "themes.json")).getElems()

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

  if fetched or app.feed.len == 0:
    igSplitter(true, 8, app.browseSplitterSize.a.addr, app.browseSplitterSize.b.addr, style.windowMinSize.x, style.windowMinSize.x, avail.y)
    # List
    if igBeginChild("##browseList", igVec2(app.browseSplitterSize.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
      for theme in app.feed:
        igText(cstring theme["name"].getStr())
    igEndChild(); igSameLine()

    # Preivew
    if igBeginChild("##browsePreview", igVec2(app.browseSplitterSize.b, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
      igText("Preview")
    igEndChild()
  else:
    igCenterCursor(ImVec2(x: 15 * 2, y: (15 + igGetStyle().framePadding.y) * 2))
    igSpinner("##spinner", 15, 6, igGetColorU32(ButtonHovered))
