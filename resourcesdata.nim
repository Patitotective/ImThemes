import std/[tables, sugar, os]
import niprefs

const configPath = "config.toml"
let config {.compileTime.} = Toml.decode(static(slurp(currentSourcePath.parentDir() / configPath)), TomlValueRef)

const resourcesPaths = [
  configPath,
  config["iconPath"].getString(),
  config["stylePath"].getString(),
  config["strongFontPath"].getString(),
  config["fontPath"].getString(),
  config["iconFontPath"].getString(),
]

const resources* = collect(initTable):
  for path in resourcesPaths:
    {path: slurp(currentSourcePath.parentDir() / path)}
