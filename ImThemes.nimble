# Package

version          = "0.3.6"
author           = "Patitotective"
description      = "ImThemes is a Dear ImGui theme designer and browser written in Nim"
license          = "MIT"
namedBin["main"] = "ImThemes"
backend          = "cpp"

# Dependencies

requires "nim >= 1.6.2"
requires "nake >= 1.9.4"
requires "nimgl >= 1.3.2"
requires "downit#devel" # DEVEL >= 0.3.2 & < 1.3.0
requires "chroma >= 0.2.4"
requires "imstyle >= 0.3.2 & < 1.0.0"
requires "niprefs >= 0.3.4 & < 1.0.0"
requires "stb_image >= 2.5"
requires "https://github.com/status-im/nim-zippy >= 0.5.7"

import std/[strformat, os]

let arch = if existsEnv("ARCH"): getEnv("ARCH") else: "amd64"
let outPath = if existsEnv("OUTPATH"): getEnv("OUTPATH") else: &"{namedBin[\"main\"]}-{version}-{arch}" & (when defined(Windows): ".exe" else: "")
let flags = getEnv("FLAGS")

task buildBin, "Build the application":
  exec "nimble install -d -y"
  exec fmt"nim cpp -d:release --app:gui --out:{outPath} --cpu:{arch} {flags} main.nim"

task runBin, "Build and run the application":
  exec "nimble buildBin"

  exec fmt"./{outPath}"

