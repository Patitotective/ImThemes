# Package

const name = "ImThemes"

version = "0.2.6"
author = "Patitotective"
description = "ImThemes is a Dear ImGui theme designer and browser written in Nim"
license = "MIT"
namedBin["main"] = name
backend = "cpp"

# Dependencies

requires "nim ^= 2.2.4"
requires "nake ^= 1.9.4"
requires "nimgl ^= 1.3.2"
requires "downit ^= 0.2.1"
requires "chroma ^= 0.2.4"
requires "imstyle ^= 0.3.2"
requires "niprefs ^= 0.3.4"
requires "stb_image ^= 2.5"
requires "zippy ^= 0.10.16"
requires "toml_serialization ^= 0.2.18"

import std/[strformat, os]

let arch =
  if existsEnv("ARCH"):
    getEnv("ARCH")
  else:
    "amd64"
let outPath =
  if existsEnv("OUTPATH"):
    getEnv("OUTPATH")
  else:
    &"{name}-{version}-{arch}" & (when defined(Windows): ".exe" else: "")

let flags = getEnv("FLAGS")

task buildBin, "Build the application":
  exec "nimble install -d -y"
  exec fmt"nimble cpp -d:release --app:gui --out:{outPath} --cpu:{arch} {flags} main.nim"

task runBin, "Build and run the application":
  exec "nimble buildBin"

  exec fmt"./{outPath}"
