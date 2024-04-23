import std/[sequtils, tables]
import kdl
import src/configtype

const config = Config()

const resourcesPaths = @[
  config.stylePath,
  config.iconPath,
  config.iconFontPath,
] & config.fonts.mapIt(it.path)

proc readResources*(): Table[string, string] {.compileTime.} =
  for path in resourcesPaths:
    result[path] = slurp(path)
