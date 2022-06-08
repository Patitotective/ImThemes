import std/[strutils, os]

import chroma
import imstyle
import niprefs
import nimgl/[opengl, glfw]
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]

import src/[prefsmodal, browseview, editview, utils, icons]
when defined(release):
  from resourcesdata import resources

const
  configPath = "config.niprefs"
  sidebarViews = [
    FA_PencilSquareO, # Edit view
    FA_Search,  # Browse view
  ]

proc getData(path: string): string = 
  when defined(release):
    resources[path]
  else:
    readFile(path)

proc getData(node: PrefsNode): string = 
  node.getString().getData()

proc drawAboutModal(app: App) = 
  var center: ImVec2
  getCenterNonUDT(center.addr, igGetMainViewport())
  igSetNextWindowPos(center, Always, igVec2(0.5f, 0.5f))

  let unusedOpen = true # Passing this parameter creates a close button
  if igBeginPopupModal(cstring "About " & app.config["name"].getString(), unusedOpen.unsafeAddr, flags = makeFlags(ImGuiWindowFlags.NoResize)):
    # Display icon image
    var texture: GLuint
    var image = app.config["iconPath"].getData().readImageFromMemory()

    image.loadTextureFromData(texture)

    igImage(cast[ptr ImTextureID](texture), igVec2(64, 64)) # Or igVec2(image.width.float32, image.height.float32)
    if igIsItemHovered():
      igSetTooltip(cstring app.config["website"].getString() & " " & FA_ExternalLink)
      
      if igIsMouseClicked(ImGuiMouseButton.Left):
        app.config["website"].getString().openURL()

    igSameLine()
    
    igPushTextWrapPos(250)
    igTextWrapped(app.config["comment"].getString().cstring)
    igPopTextWrapPos()

    igSpacing()

    # To make it not clickable
    igPushItemFlag(ImGuiItemFlags.Disabled, true)
    igSelectable("Credits", true, makeFlags(ImGuiSelectableFlags.DontClosePopups))
    igPopItemFlag()

    if igBeginChild("##credits", igVec2(0, 75)):
      for author in app.config["authors"]:
        let (name, url) = block: 
          let (name,  url) = author.getString().removeInside('<', '>')
          (name.strip(),  url.strip())

        if igSelectable(cstring name) and url.len > 0:
            url.openURL()
        if igIsItemHovered() and url.len > 0:
          igSetTooltip(cstring url & " " & FA_ExternalLink)
      
      igEndChild()

    igSpacing()

    igText(app.config["version"].getString().cstring)

    igEndPopup()

proc drawMainMenuBar(app: var App) =
  var openAbout, openPrefs = false

  if igBeginMainMenuBar():
    if igBeginMenu("File"):
      igMenuItem("Preferences " & FA_Cog, "Ctrl+P", openPrefs.addr)
      if igMenuItem("Quit " & FA_Times, "Ctrl+Q"):
        app.win.setWindowShouldClose(true)
      igEndMenu()

    if igBeginMenu("Edit"):
      if igMenuItem("Hello"):
        echo "Hello"

      igEndMenu()

    if igBeginMenu("About"):
      if igMenuItem("Website " & FA_ExternalLink):
        app.config["website"].getString().openURL()

      igMenuItem(cstring "About " & app.config["name"].getString(), shortcut = nil, p_selected = openAbout.addr)

      igEndMenu() 

    igEndMainMenuBar()

  # See https:#github.com/ocornut/imgui/issues/331#issuecomment-751372071
  if openPrefs:
    igOpenPopup("Preferences")
  if openAbout:
    igOpenPopup(cstring "About " & app.config["name"].getString())

  # These modals will only get drawn when igOpenPopup(name) are called, respectly
  app.drawAboutModal()
  app.drawPrefsModal()

proc drawSidebar(app: var App) = 
  const sideBarWidth = 50
  var anyHovered = false
  igPushFont(app.bigFont)
  igPushStyleColor(ImGuiCol.WindowBg, igGetColor(WindowBg).darken(0.02).igVec4())
  igPushStyleColor(ImGuiCol.Text, "#9A9996".parseHtmlHex().igVec4())
  igPushStyleVar(ImGuiStyleVar.WindowPadding, igVec2(0, 0))
  igPushStyleVar(ImGuiStyleVar.ItemSpacing, igVec2(0, 7))

  if igBeginViewportSideBar("##sidebar", igGetMainViewport(), ImGuiDir.Left, sideBarWidth, ImGuiWindowFlags.None):
    igDummy(igVec2(0, 10))
    for e, view in sidebarViews:
      if app.currentView == e:
        igPushStyleColor(ImGuiCol.Text, "#FFFFFF".parseHtmlHex().igVec4())

      if app.hoveredView == e:
        igPushStyleColor(ImGuiCol.Text, igGetColor(Text).lighten(0.2).igVec4())

      igCenterCursorX(igCalcTextSize(cstring view).x + (igGetStyle().framePadding.x * 2), 0.5, sideBarWidth)
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

  if igBegin(cstring app.config["name"].getString(), flags = makeFlags(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoBringToFrontOnFocus, NoDecoration, NoMove)):
    igText(FA_Info & " Application average %.3f ms/frame (%.1f FPS)", 1000f / igGetIO().framerate, igGetIO().framerate)
    if app.currentView == 0:
      app.drawEditView()
    elif app.currentView == 1:
      app.drawBrowseView()
    else:
      igText("hello")

  igEnd()

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

  app.win = glfwCreateWindow(
    app.prefsCache["win"]["width"].getInt().int32, 
    app.prefsCache["win"]["height"].getInt().int32, 
    app.config["name"].getString().cstring, 
    icon = false # Do not use default icon
  )

  if app.win == nil:
    quit(-1)

  # Set the window icon
  var icon = initGLFWImage(app.config["iconPath"].getData().readImageFromMemory())
  app.win.setWindowIcon(1, icon.addr)

  app.win.setWindowSizeLimits(app.config["minSize"][0].getInt().int32, app.config["minSize"][1].getInt().int32, GLFW_DONT_CARE, GLFW_DONT_CARE) # minWidth, minHeight, maxWidth, maxHeight

  # If negative pos, center the window in the first monitor
  if app.prefsCache["win"]["x"].getInt() < 0 or app.prefsCache["win"]["y"].getInt() < 0:
    var monitorX, monitorY, count: int32
    let monitors = glfwGetMonitors(count.addr)
    let videoMode = monitors[0].getVideoMode()

    monitors[0].getMonitorPos(monitorX.addr, monitorY.addr)
    app.win.setWindowPos(
      monitorX + int32((videoMode.width - int app.prefsCache["win"]["width"].getInt()) / 2), 
      monitorY + int32((videoMode.height - int app.prefsCache["win"]["height"].getInt()) / 2)
    )
  else:
    app.win.setWindowPos(app.prefsCache["win"]["x"].getInt().int32, app.prefsCache["win"]["y"].getInt().int32)

proc initPrefs(app: var App) = 
  app.prefs = toPrefs({
    win: {
      x: -1, # Negative numbers center the window
      y: -1,
      width: 1000,
      height: 600
    }, 
    currentTheme: 0, 
    themes: [classicTheme, darkTheme, lightTheme, cherryTheme], 
  }).initPrefs((app.getCacheDir() / app.config["name"].getString()).changeFileExt("niprefs"))

proc initApp(config: PObjectType): App = 
  result = App(
    config: config, 
    currentView: -1, hoveredView: -1, currentTheme: -1, browseCurrentTheme: -1, 
    sizesBuffer: newString(32), colorsBuffer: newString(32), previewBuffer: newString(64), browseBuffer: newString(64)
  )
  result.initPrefs()
  result.prefsCache = result.prefs.content
  result.initConfig(result.config["settings"])

  result.switchTheme(int result.prefsCache["currentTheme"].getInt())

proc terminate(app: var App) = 
  var x, y, width, height: int32

  app.win.getWindowPos(x.addr, y.addr)
  app.win.getWindowSize(width.addr, height.addr)
  
  app.prefsCache["win"]["x"] = x
  app.prefsCache["win"]["y"] = y
  app.prefsCache["win"]["width"] = width
  app.prefsCache["win"]["height"] = height

  app.prefsCache["currentTheme"] = app.currentTheme

  app.prefs.overwrite(app.prefsCache)

proc main() =
  var app = initApp(configPath.getData().parsePrefs())

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
  setIgStyle(app.config["stylePath"].getData().parsePrefs())

  # Setup Platform/Renderer backends
  doAssert igGlfwInitForOpenGL(app.win, true)
  doAssert igOpenGL3Init()

  # Load fonts
  app.font = io.fonts.igAddFontFromMemoryTTF(app.config["fontPath"].getData(), app.config["fontSize"].getFloat())

  # Merge ForkAwesome icon font
  var config = utils.newImFontConfig(mergeMode = true)
  var ranges = [FA_Min.uint16,  FA_Max.uint16]

  io.fonts.igAddFontFromMemoryTTF(app.config["iconFontPath"].getData(), app.config["fontSize"].getFloat(), config.addr, ranges[0].addr)

  app.bigFont = io.fonts.igAddFontFromMemoryTTF(app.config["fontPath"].getData(), app.config["fontSize"].getFloat()+15)
  io.fonts.igAddFontFromMemoryTTF(app.config["iconFontPath"].getData(), app.config["fontSize"].getFloat()+15, config.addr, ranges[0].addr)

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
