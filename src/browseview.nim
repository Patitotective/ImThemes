import std/[httpclient, algorithm, sequtils, strutils, math, os]
import niprefs
import imstyle
import nimgl/imgui

import utils, icons

const feedURL = "https://github.com/Patitotective/ImThemes/blob/main/themes.toml?raw=true"
const colors* = @["red", "blue", "green", "yellow", "orange", "purple", "magenta", "pink", "gray"]
const tags* = @["light", "dark", "high-contrast", "rounded"]

var
  fetched = false
  fetchThread: Thread[string]

proc fetch(path: string) = 
  # FIXME
  # newHttpClient().downloadFile(feedURL, path)
  fetched = true

proc getFeed(app: App): TomlTables = 
  result = app.feed
  # Filter feed
  # By author
  if app.authorFilter.len > 0:
    result = result.filterIt(it["author"] == app.authorFilter)
  # By tags/starred
  if app.filters.len > 0:
    for filter in app.filters:
      if filter in colors & tags:
        result = result.filterIt(filter.newTString() in it["tags"])
      elif filter == "starred":
        result = result.filterIt(it["name"] in app.prefs["starred"])
      else: raise newException(ValueError, "Invalid filter" & filter)
  
  # Sort feed
  case app.currentSort
  of 0: # Alpha asc
    result = result.sortedByIt(it["name"].getString())
  of 1: # Alpha desc
    result = result.sortedByIt(it["name"].getString())
    result.reverse()
  of 2: # Newest
    result = result.sortedByIt(it["date"].getDateTime())
    result.reverse()
  of 3: # Oldest
    result = result.sortedByIt(it["date"].getDateTime())
  else: raise newException(ValueError, "Invalid sort value " & $app.currentSort)

proc drawBrowseListHeader(app: var App) = 
  let style = igGetStyle()
  let drawlist = igGetWindowDrawList()

  igInputTextWithHint("##search", "Search...", cstring app.browseBuffer, 64); igSameLine()
  if igButton(FA_Sort):
    igOpenPopup("sort")
  igSameLine()
  if igButton(FA_Plus):
    igOpenPopup("addFilter")

  igDummy(igVec2(style.framePadding.x, 0)); igSameLine()

  let filtersCopy = app.deepCopy().filters & (if app.authorFilter.len > 0: @[app.authorFilter] else: @[])
  for e, filter in filtersCopy:
    drawList.channelsSplit(2)

    drawList.channelsSetCurrent(1)
    igAlignTextToFramePadding()
    igText(cstring filter.capitalizeAscii())
    
    drawList.channelsSetCurrent(0)
    drawlist.addRectFilled(igGetItemRectMin() - style.framePadding, igGetItemRectMax() + style.framePadding, igGetColorU32(ImGuiCol.Tab))

    drawList.channelsMerge()

    igSameLine()
    igPushStyleVar(FrameRounding, 0f)
    igPushStyleColor(ImGuiCol.Button, igGetColorU32(ImGuiCol.Tab))
    igPushStyleColor(ImGuiCol.ButtonHovered, igGetColorU32(ImGuiCol.TabHovered))
    igPushStyleColor(ImGuiCol.ButtonActive, igGetColorU32(ImGuiCol.TabActive))

    if igButton(cstring FA_Times & "##" & $e):
      if filter == app.authorFilter:
        app.authorFilter.reset()
      else:
        app.filters.delete filtersCopy.find(filter)

    igPopStyleColor(3)
    igPopStyleVar()

    let lastButton = igGetItemRectMax().x
    # Expected position if next button was on same line
    let nextButton = lastButton + 0.5 + (if e < filtersCopy.high: igCalcTextSize(cstring filtersCopy[e+1].capitalizeAscii()).x + style.itemSpacing.x + igCalcTextSize(FA_Times).x + (style.framePadding.x * 4) else: 0)
    
    if e < filtersCopy.high:
      if nextButton < igGetWindowPos().x + igGetWindowContentRegionMax().x:
        igSameLine(); igDummy(igVec2(0.5, 0)); igSameLine()
      else:
        igDummy(igVec2(style.framePadding.x, 0)); igSameLine()

  if igBeginPopup("sort"):
    for e, ele in [FA_SortAlphaAsc, FA_SortAlphaDesc, "Newest", "Oldest"]:
      if igSelectable(cstring ele, e == app.currentSort):
        app.currentSort = e

    igEndPopup()

  if igBeginPopup("addFilter"):
    for e, tag in @["starred"] & tags:
      if tag notin app.filters:
        if igMenuItem(cstring tag.capitalizeAscii()):
          app.filters.add tag

    if igBeginMenu("Colors"):
      for e, col in colors:
        if col notin app.filters:
          if igMenuItem(cstring col.capitalizeAscii()):
            app.filters.add col

      igEndMenu()

    igEndPopup() 

proc drawBrowseList(app: var App) = 
  let style = igGetStyle()
  let feed = app.getFeed()

  for e, theme in feed:
    if app.browseBuffer.passFilter(theme["name"].getString()):
      let starred = theme["name"] in app.prefs["starred"]
      let starText = if starred: FA_Star else: FA_StarO
      if igSelectable(cstring "##" & $e, size = igVec2(0, igGetFrameHeight() + app.bigFont.fontSize + (style.framePadding.y * 2)), flags = ImGuiSelectableFlags.AllowItemOverlap):
        app.browseCurrentTheme = feed[e]

      igSameLine(); igBeginGroup()
      app.bigFont.igPushFont()
      igText(cstring theme["name"].getString())
      igPopFont()
      
      igTextWithEllipsis(
        theme["description"].getString(), 
        maxWidth = igGetContentRegionAvail().x - style.itemSpacing.x - igCalcTextSize(cstring starText).x - (style.framePadding.x * 2)
      )
      igSameLine(); igCenterCursorX(igCalcTextSize(cstring starText).x + (style.framePadding.x * 2), align = 1)
      
      if igButton(cstring starText & "##" & $e):
        if starred:
          app.prefs["starred"].delete app.prefs["starred"].find(theme["name"])
        else:
          app.prefs["starred"].add theme["name"]

      igEndGroup()

proc drawBrowsePreview(app: var App) = 
  let style = igGetStyle()
  let avail = igGetContentRegionAvail()

  igPushStyleVar(WindowPadding, igVec2(150, 20))
  if igBeginChild("##browsePreview", igVec2(app.browseSplitterSize.b, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
    if app.browseCurrentTheme.len > 0:
      let theme = app.browseCurrentTheme

      app.bigFont.igPushFont()
      igText(cstring theme["name"].getString())
      igPopFont()
    
      igSameLine()

      # app.smallFont.igPushFont()
      igText(cstring "By ")
      if igClickableText(theme["author"].getString(), sameLineAfter = false):
        app.authorFilter = theme["author"].getString()
      # igPopFont()
      
      igTextWrapped(cstring theme["description"].getString())

      if igButton("Get it"):
        echo "Open export modal"

      if theme["tags"].len > 0:
        igSameLine()
    
        igPushStyleVar(FrameRounding, 0f)
        igPushStyleColor(ImGuiCol.Button, igGetColorU32(ImGuiCol.Tab))
        igPushStyleColor(ImGuiCol.ButtonHovered, igGetColorU32(ImGuiCol.TabHovered))
        igPushStyleColor(ImGuiCol.ButtonActive, igGetColorU32(ImGuiCol.TabActive))

        let themesWidth = 
          theme["tags"].mapIt(igCalcTextSize(cstring it.getString().capitalizeAscii()).x).sum() + 
          (style.framePadding.x * float32(theme["tags"].len * 2)) + 
          (style.itemSpacing.x * float32 theme["tags"].len-1)

        igCenterCursorX(themesWidth, align = 1)
        for e, tag in theme["tags"].getArray():
          if igButton(cstring tag.getString().capitalizeAscii()) and tag.getString() notin app.filters:
            app.filters.add tag.getString()
          
          if e < theme["tags"].len-1:
            igSameLine()

        igPopStyleColor(3)
        igPopStyleVar()


      if igBeginChild("##preview"):
        igSetNextWindowPos(igGetWindowPos())
        igSetNextWindowSize(igGetWindowSize())

        app.drawStylePreview(theme["name"].getString(), theme["style"].styleFromToml())
      
      igEndChild()

  igEndChild()
  igPopStyleVar()

proc drawBrowseView*(app: var App) = 
  if not fetched and not fetchThread.running:
    fetchThread.createThread(fetch, app.getCacheDir() / "themes.toml")
  elif fetched and app.feed.len == 0:
    # FIXME
    # app.feed = Toml.loadFile(app.getCacheDir() / "themes.toml", TomlValueRef)["themes"]
    app.feed = Toml.loadFile("themes.toml", TomlValueRef)["themes"].getTables()

  let avail = igGetContentRegionAvail()

  # Keep splitter proportions on resize
  # And hide the editing zone when not editing
  if app.prevAvail != igVec2(0, 0) and app.prevAvail != avail:
    app.browseSplitterSize = ((app.browseSplitterSize.a / app.prevAvail.x) * avail.x, (app.browseSplitterSize.b / app.prevAvail.x) * avail.x)

  app.prevAvail = avail

  # First time
  if app.browseSplitterSize.a == 0:
    app.browseSplitterSize = (avail.x * 0.2f, avail.x * 0.8f)

  if fetched and app.feed.len > 0:
    igSplitter(true, 8, app.browseSplitterSize.a.addr, app.browseSplitterSize.b.addr, 200, 800, avail.y)
    # List
    if igBeginChild("##browseList", igVec2(app.browseSplitterSize.a, avail.y), flags = makeFlags(AlwaysUseWindowPadding)):
      app.drawBrowseListHeader()
      igSeparator()
      app.drawBrowseList()

    igEndChild(); igSameLine()
    app.drawBrowsePreview()

  else:
    igCenterCursor(ImVec2(x: 15 * 2, y: (15 + igGetStyle().framePadding.y) * 2))
    igSpinner("##spinner", 15, 6, igGetColorU32(ButtonHovered))
