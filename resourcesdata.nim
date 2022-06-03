import std/[tables, sugar]
import niprefs

const configPath = "config.niprefs"
let config {.compileTime.} = readPrefs(configPath)

const resourcesPaths = [
  configPath, 
  config["iconPath"].getString(), 
  config["stylePath"].getString(), 
  config["fontPath"].getString(), 
  config["iconFontPath"].getString()
]

const resources* = collect(initTable):
  for path in resourcesPaths:
    {path: slurp(path)}
