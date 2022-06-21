import std/[tables, sugar]
import niprefs

const configPath = "config.toml"
let config {.compileTime.} = Toml.decode(static(slurp(configPath)), TomlValueRef)

const resourcesPaths = [
  configPath, 
  config["iconPath"].getString(), 
  config["stylePath"].getString(), 
  config["strongFontPath"].getString(), 
  config["fontPath"].getString(), 
  config["iconFontPath"].getString()
]

const resources* = collect(initTable):
  for path in resourcesPaths:
    {path: slurp(path)}
