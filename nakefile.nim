import std/[strformat, sequtils, os]

import nake
import zippy/ziparchives
import niprefs

const configPath = "config.toml"
const binDir = "bin"
const desktop = """
[Desktop Entry]
Name=$name
Exec=AppRun
Comment=$comment
Icon=$name
Type=Application
Categories=$categories

X-AppImage-Name=$name
X-AppImage-Version=$version
X-AppImage-Arch=$arch
"""

let config {.compileTime.} = Toml.decode(static(slurp(configPath)), TomlValueRef)

const name = config["name"].getString() 
const version = config["version"].getString()

let arch = if existsEnv("ARCH"): getEnv("ARCH") else: "amd64"
let appimagePath = fmt"{name}-{version}-{arch}.AppImage"

proc buildWindows() = 
  let outDir = fmt"{name}-{version}"

  createDir outDir
  shell fmt"set FLAGS=""--outdir:{outDir}"" && nimble buildBin"

  for kind, path in walkDir(binDir):
    if kind == pcFile:
      copyFileToDir(path, outDir)

  createZipArchive(outDir & "/", outDir & ".zip")

proc buildAppImage() = 
  discard existsOrCreateDir("AppDir")
  if "AppDir/AppRun".needsRefresh("main.nim"):
    shell "FLAGS=\"--out:AppDir/AppRun -d:appimage\" nimble buildBin"

  writeFile(
    fmt"AppDir/{name}.desktop", 
    desktop % [
      "name", name, 
      "categories", config["categories"].getArray().mapIt(it.getString()).join(";"), 
      "version", config["version"].getString(), 
      "comment", config["comment"].getString(), 
      "arch", arch
    ]
  )
  copyFile(config["iconPath"].getString(), "AppDir/.DirIcon")
  copyFile(config["svgIconPath"].getString(), fmt"AppDir/{name}.svg")
  if "appstreamPath" in config:
    createDir("AppDir/usr/share/metainfo")
    copyFile(config["appstreamPath"].getString(), fmt"AppDir/usr/share/metainfo/{name}.appdata.xml")

  var appimagetoolPath = "appimagetool"
  if not silentShell("Checking for appimagetool", appimagetoolPath, "--help"):
      appimagetoolPath = "./appimagetool-x86_64.AppImage"
      if not fileExists(appimagetoolPath):
        direSilentShell fmt"Dowloading {appimagetoolPath}", "wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O ", appimagetoolPath
        shell "chmod +x", appimagetoolPath

  if "ghRepo" in config:
    echo "Building updateable AppImage"
    let ghInfo = config["ghRepo"].getString().split('/')
    direShell appimagetoolPath, "-u", &"\"gh-releases-zsync|{ghInfo[0]}|{ghInfo[1]}|latest|{name}-*-{arch}.AppImage.zsync\"", "AppDir", appimagePath
  else:
    echo fmt"ghRepo key not in {configPath}. Skipping updateable AppImage"
    direShell appimagetoolPath, "AppDir", appimagePath

task "build", "Build the AppImage/Exe":
  # let winBuild = existsEnv("BUILD") and getEnv("BUILD") == "WIN"
  when defined(Windows):
    buildWindows()
  else:
    buildAppImage()

task "run", "Build and run the AppImage":
  if "AppDir/AppRun".needsRefresh("main.nim"):
    runTask("build")

  shell fmt"chmod a+x {appimagePath}" # Make it executable
  shell fmt"./{appimagePath}"
