import nimgl/imgui

import types, utils

proc drawStylePreview*(app: var App, name: string, style: ImGuiStyle) = 
  let prevStyle = igGetStyle()[]
  igGetCurrentContext().style = style

  if igBegin(cstring name & " Preview", flags = makeFlags(ImGuiWindowFlags.NoResize, AlwaysUseWindowPadding, NoMove, MenuBar)):
    if igBeginMenuBar():
      if igBeginMenu("File"):
        igMenuItem("New")
        igMenuItem("Open", "Ctrl+O")
        if igBeginMenu("Open Recent"):
          igMenuItem("fish_hat.c")
          igMenuItem("fish_hat.inl")
          igMenuItem("fish_hat.h")
          igEndMenu()
        igEndMenu()

      igEndMenuBar()

    if igBeginTabBar("Tabs"):
      if igBeginTabItem("Basic"):
        igText("Hello World!")
        igTextDisabled("Bye World!"); if igIsItemHovered(): igSetTooltip("Disabled text")

        igCheckbox("Checkbox", app.previewCheck.addr)

        igButton("Click me"); igSameLine(); igButton("Me too")
        igSliderFloat("Slider", app.previewSlider.addr, 0, 50)
        igInputTextWithHint("##input", "Type here...", cstring app.previewBuffer, 64)

        igColorEdit4("Color Edit", app.previewCol)
        igColorEdit4("Color Edit HSV", app.previewCol2, makeFlags(PickerHueWheel, DisplayHSV))

        if igBeginChild("Child", igVec2(0, 150), true):
          for i in 1..50:
            igSelectable(cstring "I'm beef #" & $i)
          
        igEndChild()

        if igCollapsingHeader("Collapse me", DefaultOpen):
          igIndent()
          igButton("Popup")
          if igIsItemClicked():
            igOpenPopup("popup")

          igBeginDisabled(true)
          igButton("You cannot click me")
          if igIsItemHovered(AllowWhenDisabled):
            igSetTooltip("But you can see me")
          
          igSliderFloat("Slider shadow", app.previewSlider.addr, 0, 50)
          igEndDisabled()

          if igButton("Popup modal"):
            igOpenPopup("modal")

          igUnindent()
    
        if igBeginPopup("popup"):
          for i in ["We", "Are", "What", "We", "Think"]:
            igSelectable(cstring i)

          igEndPopup()

        if igBeginPopupModal("modal"):
          igText("I'm a popup modal")
          
          if igButton("Close me"):
            igCloseCurrentPopup()
          
          igEndPopup()

        igEndTabItem()

      if igBeginTabItem("Plots"):
        # Plots
        # Histogram
        let arr = [0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f]
        igPlotHistogram("Histogram", arr[0].unsafeAddr, int32 arr.len, 0, "Histogram", 0f, 1f, igVec2(0, 80f));

        # Lines
        if app.previewRefreshTime == 0:
          app.previewRefreshTime = igGetTime()

        while app.previewRefreshTime < igGetTime(): # Create data at fixed 60 Hz rate for the demo
            app.previewValues[app.previewValuesOffset] = cos(app.previewPhase)
            app.previewValuesOffset = int32 (app.previewValuesOffset + 1) mod app.previewValues.len
            app.previewPhase += 0.1f * float32 app.previewValuesOffset
            app.previewRefreshTime += 1f / 60f

        var average = 0f
        for n in app.previewValues:
          average += n
        average /= float32 app.previewValues.len

        igPlotLines("Lines", app.previewValues[0].addr, int32 app.previewValues.len, app.previewValuesOffset, "Average", -1f, 1f, igVec2(0, 80f));
        
        app.previewProgress += app.previewProgressDir * 0.4f * igGetIO().deltaTime
        
        if app.previewProgress >= 1.1f:
          app.previewProgress = 1.1f
          app.previewProgressDir *= -1f;
        if app.previewProgress <= -0.1f:
          app.previewProgress = -0.1f
          app.previewProgressDir *= -1f

        igProgressBar(app.previewProgress)

        let progressSaturated = if app.previewProgress < 0f: 0f elif app.previewProgress > 1f: 1f else: app.previewProgress
        igProgressBar(app.previewProgress, overlay = cstring &"{int(progressSaturated * 1753)}/1753")

        igEndTabItem()

      if igBeginTabItem("Tables"):
        if igBeginTable("table1", 4, makeFlags(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.Resizable, ImGuiTableFlags.Reorderable)):
          igTableSetupColumn("One")
          igTableSetupColumn("Two")
          igTableSetupColumn("Three")
          igTableHeadersRow()

          for row in 0..5:
            igTableNextRow()
            for col in 0..3:
              igTableNextColumn()
              igText(cstring &"Hello {row}, {col}")

          igEndTable()

        igEndTabItem()

      igEndTabBar()

  igEnd()

  igGetCurrentContext().style = prevStyle

