import std/[strformat, strutils, sequtils, os]

import zippy/ziparchives
import niprefs

const configPath = "config.toml"
const binDir = "bin"
const desktop =
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

let config {.compileTime.} = Toml.decode(static(slurp(configPath)), TomlValueRef)

const name = config["name"].getString()
const version = config["version"].getString()

let arch =
  if existsEnv("ARCH"):
    getEnv("ARCH")
  else:
    "amd64"

let appimagePath = &"{name}-{version}-{arch}.AppImage"

proc exec(cmd: varargs[string, `$`]): int {.discardable.} =
  let cmd = cmd.join(" ")
  echo "> ", cmd
  result = execShellCmd(cmd)

proc buildWindows() =
  let outDir = &"{name}-{version}"
  let outPath = &"{name}-{version}.zip"

  createDir outDir
  exec fmt"set FLAGS=""--outdir:{outDir}"" && nimble buildBin"

  for kind, path in walkDir(binDir):
    if kind == pcFile:
      copyFileToDir(path, outDir)

  var entries = initTable[string, string]()
  for kind, path in walkDir(outDir):
    if kind == pcFile:
      entries[path.splitPath().tail] = readFile(path)

  writeFile(outPath, createZipArchive(entries))

  echo "Success -> ", outPath

proc buildAppImage() =
  discard existsOrCreateDir("AppDir")
  exec "FLAGS=\"--out:AppDir/AppRun -d:appimage\" nimble buildBin"

  let desktopContent =
    desktop % [
      "name",
      name,
      "categories",
      config["categories"].getArray().mapIt(it.getString()).join(";"),
      "version",
      config["version"].getString(),
      "comment",
      config["comment"].getString(),
      "arch",
      arch,
    ]

  writeFile(&"AppDir/{name}.desktop", desktopContent)
  copyFile(config["iconPath"].getString(), "AppDir/.DirIcon")
  copyFile(config["svgIconPath"].getString(), &"AppDir/{name}.svg")
  if "appstreamPath" in config:
    createDir("AppDir/usr/share/metainfo")
    copyFile(
      config["appstreamPath"].getString(),
      &"AppDir/usr/share/metainfo/{name}.appdata.xml",
    )

  const appimagetoolPath = "./appimagetool-x86_64.AppImage"
  echo "Checking for appimagetool"
  if exec("appimagetool", "--help") != 0 or not fileExists(appimagetoolPath) or
      exec(appimagetoolPath, "--help") != 0:
    echo &"Dowloading {appimagetoolPath}"
    exec &"wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O {appimagetoolPath}"
    exec &"chmod +x {appimagetoolPath}"

  var success = -1
  if "ghRepo" in config:
    echo "Building updateable AppImage"
    let ghInfo = config["ghRepo"].getString().split('/')
    success = exec(
      appimagetoolPath,
      "-u",
      &"\"gh-releases-zsync|{ghInfo[0]}|{ghInfo[1]}|latest|{name}-*-{arch}.AppImage.zsync\"",
      "AppDir",
      appimagePath,
    )
  else:
    echo &"ghRepo key not in {configPath}. Skipping updateable AppImage"
    success = exec(appimagetoolPath, "AppDir", appimagePath)

  if success == 0:
    echo "Success -> ", appimagePath

# let winBuild = existsEnv("BUILD") and getEnv("BUILD") == "WIN"
when defined(Windows):
  buildWindows()
else:
  buildAppImage()
