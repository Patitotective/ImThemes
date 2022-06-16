import std/[tables, sugar]
import niprefs

# FIXME https://github.com/status-im/nim-toml-serialization/issues/46
const configPath = "config.toml"
let config {.compileTime.} = Toml.loadFile(configPath, TomlValueRef)

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
