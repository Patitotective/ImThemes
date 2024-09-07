import std/[threadpool, strutils, strformat, os]

import imstyle
import openurl
import tinydialogs
import kdl, kdl/prefs
import nimgl/[opengl, glfw]
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import chroma

import src/[settingsmodal, utils, types, icons, browseview, editview]
when defined(release):
  import resources

proc getConfigDir(app: App): string =
  getConfigDir() / app.config.name

proc drawAboutModal(app: App) =
  igSetNextWindowPos(igGetMainViewport().getCenter(), Always, igVec2(0.5f, 0.5f))
  let unusedOpen = true # Passing this parameter creates a close button
  if igBeginPopupModal(cstring "About " & app.config.name & "###about", unusedOpen.unsafeAddr, flags = makeFlags(ImGuiWindowFlags.NoResize)):
    # Display icon image
    var texture: GLuint
    var image = app.res(app.config.iconPath).readImageFromMemory()

    image.loadTextureFromData(texture)

    igImage(cast[ptr ImTextureID](texture), igVec2(64, 64)) # Or igVec2(image.width.float32, image.height.float32)
    if igIsItemHovered() and app.config.website.len > 0:
      igSetTooltip(cstring app.config.website & " " & FA_ExternalLink)

      if igIsMouseClicked(ImGuiMouseButton.Left):
        app.config.website.openURL()

    igSameLine()

    igPushTextWrapPos(250)
    igTextWrapped(cstring app.config.comment)
    igPopTextWrapPos()

    igSpacing()

    # To make it not clickable
    igPushItemFlag(ImGuiItemFlags.Disabled, true)
    igSelectable("Credits", true, makeFlags(ImGuiSelectableFlags.DontClosePopups))
    igPopItemFlag()

    if igBeginChild("##credits", igVec2(0, 75)):
      for (author, url) in app.config.authors:
        if igSelectable(cstring author) and url.len > 0:
          url.openURL()
        if igIsItemHovered() and url.len > 0:
          igSetTooltip(cstring url & " " & FA_ExternalLink)

      igEndChild()

    igSpacing()

    igText(cstring app.config.version)

    if app.prefs.path.len > 0:
      igSameLine()

      igSetCursorPosX(igGetCurrentWindow().size.x - igCalcFrameSize("Open prefs file").x - igGetStyle().windowPadding.x)

      if igButton("Open prefs file"):
        openURL(app.prefs.path)

      if igIsItemHovered():
        igSetTooltip(cstring app.prefs.path & " " & FA_FileTextO)

    igEndPopup()

proc drawMainMenuBar(app: var App) =
  var openAbout, openPrefs = false

  if igBeginMainMenuBar():
    if igBeginMenu("File"):
      igMenuItem("Settings " & FA_Cog, nil, openPrefs.addr)
      if igMenuItem("Quit " & FA_Times, nil):
        app.win.setWindowShouldClose(true)
      igEndMenu()

    if igBeginMenu("Edit"):
      igMenuItem("Show framerate", nil, app.showFramerate.addr)
      if igMenuItem(cstring "Refresh Feed " & FA_Refresh) and not app.downloader.running("feed"):
        app.downloader.downloadAgain("feed")
      igEndMenu()

    if igBeginMenu("About"):
      if igMenuItem("Website " & FA_ExternalLink, enabled = app.config.website.len > 0):
        app.config.website.openURL()

      igMenuItem(cstring "About " & app.config.name, nil, openAbout.addr)

      igEndMenu() 

    igEndMainMenuBar()

  # See https:#github.com/ocornut/imgui/issues/331#issuecomment-751372071
  if openPrefs:
    igOpenPopup("Settings")
  if openAbout:
    igOpenPopup("###bout")

  # These modals will only get drawn when igOpenPopup(name) are called, respectly
  app.drawAboutModal()
  app.drawPrefsModal()

proc drawSidebar(app: var App) = 
  const
    sidebarWidth = 50
    sidebarViews = [
      FA_PencilSquareO, # Edit view
      FA_Search, # Browse view
    ]

  var anyHovered = false
  igPushFont(app.sidebarIconFont)
  igPushStyleColor(ImGuiCol.WindowBg, igGetColor(WindowBg).darken(0.02).igVec4())
  igPushStyleColor(ImGuiCol.Text, "#9A9996".parseHtmlHex().igVec4())
  igPushStyleVar(ImGuiStyleVar.WindowPadding, igVec2(0, 20))
  igPushStyleVar(ImGuiStyleVar.ItemSpacing, igVec2(0, 7))

  if igBeginViewportSideBar("##sidebar", igGetMainViewport(), ImGuiDir.Left, sidebarWidth, ImGuiWindowFlags.None):
    for e, view in sidebarViews:
      if app.currentView == e:
        igPushStyleColor(ImGuiCol.Text, "#FFFFFF".parseHtmlHex().igVec4())

      if app.hoveredView == e:
        igPushStyleColor(ImGuiCol.Text, igGetColor(Text).lighten(0.2).igVec4())

      igCenterCursorX(igCalcTextSize(cstring view).x, avail = sidebarWidth)
      igText(cstring view)

      if app.currentView == e:
        igPopStyleColor()
      if app.hoveredView == e:
        igPopStyleColor()

      if app.currentView != e and igIsItemHovered():
        anyHovered = true
        app.hoveredView = e
      if igIsItemClicked():
        app.currentView = e

    igEnd()

  if not anyHovered:
    app.hoveredView = -1

  igPopStyleVar(2)
  igPopStyleColor(2)
  igPopFont()

proc drawMain(app: var App) = # Draw the main window
  let viewport = igGetMainViewport()  
  
  app.drawMainMenuBar()
  app.drawSidebar()
  # Work area is the entire viewport minus main menu bar, task bars, etc.
  igSetNextWindowPos(viewport.workPos)
  igSetNextWindowSize(viewport.workSize)

  if igBegin(cstring app.config.name, flags = makeFlags(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoBringToFrontOnFocus, NoDecoration, NoMove)):
    if app.showFramerate:
      igText(FA_Info & " Application average %.3f ms/frame (%.1f FPS)", 1000f / igGetIO().framerate, igGetIO().framerate)
    
    case app.currentView
    of vEditView:
      app.drawEditView()
    of vBrowseView:
      app.drawBrowseView()

  igEnd()

  # GLFW clipboard -> ImGui clipboard
  if (let clip = app.win.getClipboardString(); not clip.isNil and $clip != app.lastClipboard):
    igSetClipboardText(clip)
    app.lastClipboard = $clip

  # ImGui clipboard -> GLFW clipboard
  if (let clip = igGetClipboardText(); not clip.isNil and $clip != app.lastClipboard):
    app.win.setClipboardString(clip)
    app.lastClipboard = $clip

proc render(app: var App) = # Called in the main loop
  # Poll and handle events (inputs, window resize, etc.)
  glfwPollEvents() # Use glfwWaitEvents() to only draw on events (more efficient)

  # Start Dear ImGui Frame
  igOpenGL3NewFrame()
  igGlfwNewFrame()
  igNewFrame()

  # Draw application
  app.drawMain()

  # Render
  igRender()

  var displayW, displayH: int32
  let bgColor = igColorConvertU32ToFloat4(uint32 WindowBg)

  app.win.getFramebufferSize(displayW.addr, displayH.addr)
  glViewport(0, 0, displayW, displayH)
  glClearColor(bgColor.x, bgColor.y, bgColor.z, bgColor.w)
  glClear(GL_COLOR_BUFFER_BIT)

  igOpenGL3RenderDrawData(igGetDrawData())

  app.win.makeContextCurrent()
  app.win.swapBuffers()

proc initWindow(app: var App) =
  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)
  if app.prefs[maximized]:
    glfwWindowHint(GLFWMaximized, GLFW_TRUE)

  app.win = glfwCreateWindow(
    app.prefs[winsize].w,
    app.prefs[winsize].h,
    cstring app.config.name,
    # glfwGetPrimaryMonitor(), # Show the window on the primary monitor
    icon = false # Do not use default icon
  )

  if app.win == nil:
    quit(-1)

  # Set the window icon
  var icon = initGLFWImage(app.res(app.config.iconPath).readImageFromMemory())
  app.win.setWindowIcon(1, icon.addr)

  # min width, min height, max widht, max height
  app.win.setWindowSizeLimits(app.config.minSize.w, app.config.minSize.h, GLFW_DONT_CARE, GLFW_DONT_CARE)

  # If negative pos, center the window in the first monitor
  if app.prefs[winpos].x < 0 or app.prefs[winpos].y < 0:
    var monitorX, monitorY, count, width, height: int32
    let monitor = glfwGetMonitors(count.addr)[0]#glfwGetPrimaryMonitor()
    let videoMode = monitor.getVideoMode()

    monitor.getMonitorPos(monitorX.addr, monitorY.addr)
    app.win.getWindowSize(width.addr, height.addr)
    app.win.setWindowPos(
      monitorX + int32((videoMode.width - width) / 2),
      monitorY + int32((videoMode.height - height) / 2)
    )
  else:
    app.win.setWindowPos(app.prefs[winpos].x, app.prefs[winpos].y)

proc initApp(): App =
  result = App(
    config: Config(), 
    currentView: -1, hoveredView: -1, currentTheme: -1, 
    sizesTabFilter: newString(32), colorsTabFilter: newString(32), previewBuffer: newString(64), browseBuffer: newString(64), 
    previewProgressDir: 1f, 
  )

  when defined(release):
    result.resources = readResources()

  let filename =
    when defined(release): "prefs"
    else: "prefs_dev"

  let path = (result.getConfigDir() / filename).changeFileExt("kdl")

  try:
    result.prefs = initKPrefs(
      path = path,
      default = initPrefs()
    )
  except KdlError:
    let m = messageBox(result.config.name, &"Corrupt preferences file {path}.\nYou cannot continue using the app until it is fixed.\nYou may fix it manually or do you want to delete it and reset its content? You cannot undo this action", DialogType.OkCancel, IconType.Error, Button.No)
    if m == Button.Yes:
      discard tryRemoveFile(path)
      result.prefs = initKPrefs(
        path = path,
        default = initPrefs()
      )
    else:
      raise

  result.updatePrefs()
  result.switchTheme(result.prefs[currentTheme])
  result.currentSort = result.prefs[currentSort]
  result.currentView = result.prefs[currentView]

template initFonts(app: var App) =
  # Merge ForkAwesome icon font
  let config = utils.newImFontConfig(mergeMode = true)
  let iconFontGlyphRanges = [uint16 FA_Min, uint16 FA_Max]

  for e, font in app.config.fonts:
    let glyph_ranges =
      case font.glyphRanges
      of GlyphRanges.Default: io.fonts.getGlyphRangesDefault()
      of ChineseFull: io.fonts.getGlyphRangesChineseFull()
      of ChineseSimplified: io.fonts.getGlyphRangesChineseSimplifiedCommon()
      of Cyrillic: io.fonts.getGlyphRangesCyrillic()
      of Japanese: io.fonts.getGlyphRangesJapanese()
      of Korean: io.fonts.getGlyphRangesKorean()
      of Thai: io.fonts.getGlyphRangesThai()
      of Vietnamese: io.fonts.getGlyphRangesVietnamese()

    app.fonts[e] = io.fonts.igAddFontFromMemoryTTF(app.res(font.path), font.size, glyph_ranges = glyph_ranges)

    # Here we add the icon font to every font
    if app.config.iconFontPath.len > 0:
      io.fonts.igAddFontFromMemoryTTF(app.res(app.config.iconFontPath), font.size, config.unsafeAddr, iconFontGlyphRanges[0].unsafeAddr)

proc terminate(app: var App) =
  sync() # Wait for spawned threads

  var x, y, width, height: int32

  app.win.getWindowPos(x.addr, y.addr)
  app.win.getWindowSize(width.addr, height.addr)

  app.prefs[winpos] = (x, y)
  app.prefs[winsize] = (width, height)
  app.prefs[maximized] = app.win.getWindowAttrib(GLFWMaximized) == GLFW_TRUE

  app.prefs.save()

  # app.prefs[currentView] = app.currentView
  # app.prefs[currentSort] = app.currentSort
  # app.prefs[currentTheme] = app.currentTheme

proc main() =
  var app = initApp()

  # Setup Window
  doAssert glfwInit()
  app.initWindow()

  app.win.makeContextCurrent()
  glfwSwapInterval(1) # Enable vsync

  doAssert glInit()

  # Setup Dear ImGui context
  igCreateContext()
  let io = igGetIO()
  io.iniFilename = nil # Disable .ini config file

  # Setup Dear ImGui style using ImStyle
  app.res(app.config.stylePath).parseKdl().loadStyle().setCurrent()

  # Setup Platform/Renderer backends
  doAssert igGlfwInitForOpenGL(app.win, true)
  doAssert igOpenGL3Init()

  app.initFonts()

  # Main loop
  while not app.win.windowShouldClose:
    app.render()

  # Cleanup
  igOpenGL3Shutdown()
  igGlfwShutdown()

  igDestroyContext()

  app.terminate()
  app.win.destroyWindow()
  glfwTerminate()

when isMainModule:
  main()

