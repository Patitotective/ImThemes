import std/[tables, sugar, os]
import niprefs

const configPath = currentSourcePath.parentDir() / "config.toml"
let config {.compileTime.} = Toml.decode(static(slurp(configPath)), TomlValueRef)

const resourcesPaths = [
  configPath,
  currentSourcePath.parentDir() / config["iconPath"].getString(),
  currentSourcePath.parentDir() / config["stylePath"].getString(),
  currentSourcePath.parentDir() / config["strongFontPath"].getString(),
  currentSourcePath.parentDir() / config["fontPath"].getString(),
  currentSourcePath.parentDir() / config["iconFontPath"].getString(),
]

const resources* = collect(initTable):
  for path in resourcesPaths:
    {path: slurp(path)}
