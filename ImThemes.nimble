# Package

const name = "ImThemes"

version = "0.2.6"
author = "Patitotective"
description = "ImThemes is a Dear ImGui theme designer and browser written in Nim"
license = "MIT"
namedBin["main"] = name
backend = "cpp"

# Dependencies

requires "nim ^= 2.2.0"
requires "nake ^= 1.9.0"
requires "nimgl ^= 1.3.0"
requires "downit ^= 0.2.0"
requires "chroma ^= 0.2.0"
requires "imstyle ^= 0.3.0"
requires "niprefs ^= 0.3.0"
requires "stb_image ^= 2.5"
requires "zippy ^= 0.10.0"
requires "toml_serialization ^= 0.2.0"
requires "tinydialogs ^= 1.1.0"

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

requires "tinydialogs >= 1.1.0"

