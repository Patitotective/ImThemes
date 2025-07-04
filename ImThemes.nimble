# Package

author = "Patitotective"
description = "ImThemes is a Dear ImGui theme designer and browser written in Nim"
license = "MIT"
backend = "cpp"

# Dependencies

requires "nim ^= 2.2.4"
requires "kdl ^= 2.0.1"
requires "nimgl ^= 1.3.2"
requires "stb_image ^= 2.5"
requires "imstyle ^= 3.0.0"
requires "openurl ^= 2.0.4"
requires "tinydialogs ^= 1.0.0"
requires "constructor ^= 1.2.0"
requires "downit ^= 0.3.3"
requires "chroma ^= 0.2.4"
# requires "nake ^= 1.9.4"
# requires "https://github.com/status-im/nim-zippy ^= 0.5.7"

import std/[strformat, options]
import src/configtype

const config = Config()

version = config.version
namedBin["main"] = config.name

let arch = getEnv("ARCH", "amd64")
let outPath = getEnv("OUTPATH", toExe &"{config.name}-{version}-{arch}")
let flags = getEnv("FLAGS")

let args = &"--app:gui --out:{outPath} --cpu:{arch} {flags}"

task buildr, "Build the application for release":
  exec &"nimble c -d:release {args} main.nim"

const desktopTemplate =
  """
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

task buildapp, "Build the AppImage":
  let appimagePath = &"{config.name}-{version}-{arch}.AppImage"

  # Compile applicaiton executable
  if not dirExists("AppDir"):
    mkDir("AppDir")
  exec &"nimble c -d:release -d:appimage {args} --out:AppDir/AppRun main.nim"

  # Make desktop file
  writeFile(
    &"AppDir/{config.name}.desktop",
    desktopTemplate % [
      "name",
      config.name,
      "categories",
      config.categories.join(";"),
      "version",
      config.version,
      "comment",
      config.comment,
      "arch",
      arch,
    ],
  )
  # Copy icons
  cpFile(config.iconPath, "AppDir/.DirIcon")
  cpFile(config.svgIconPath, &"AppDir/{config.name}.svg")

  if config.appstreamPath.len > 0:
    mkDir("AppDir/usr/share/metainfo")
    cpFile(config.appstreamPath, &"AppDir/usr/share/metainfo/{config.name}.appdata.xml")

  # Get appimagetool
  var appimagetoolPath = "appimagetool"
  try:
    echo "Checking for appimagetool..."
    exec(&"{appimagetoolPath} --help")
  except OSError:
    appimagetoolPath = "./appimagetool-x86_64.AppImage"
    if not fileExists(appimagetoolPath):
      echo &"Downloading {appimagetoolPath}"
      exec &"wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O {appimagetoolPath}"
      exec &"chmod +x {appimagetoolPath}"

  # Actually use appimagetool to build the AppImage
  if config.ghRepo.isSome:
    echo "Building updateable AppImage"
    exec &"{appimagetoolPath} -u \"gh-releases-zsync|{config.ghRepo.get.user}|{config.ghRepo.get.repo}|latest|{config.name}-*-{arch}.AppImage.zsync\" AppDir {appimagePath}"
  else:
    echo &"ghRepo not defined. Skipping updateable AppImage"
    exec &"{appimagetoolPath} AppDir {appimagePath}"
