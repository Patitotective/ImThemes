import std/options

type

  GlyphRanges* = enum
    Default, ChineseFull, ChineseSimplified, Cyrillic, Japanese, Korean, Thai, Vietnamese

  Font* = object
    path*: string
    size*: float32
    glyphRanges*: GlyphRanges

proc font*(path: string, size: float32, glyphRanges = GlyphRanges.Default): Font =
  Font(path: path, size: size, glyphRanges: glyphRanges)

type
  Config* = object
    name* = "ImThemes"
    comment* = "ImThemes is a Dear ImGui theme designer and browser written in Nim"
    version* = "2.0.0"
    website* = "https://github.com/Patitotective/ImThemes"
    authors* = [
      (name: "Patitotective", url: "https://github.com/Patitotective"),
    ]
    categories* = ["Utility"]

    stylePath* = "assets/style.kdl"
    iconPath* = "assets/icon.png"
    svgIconPath* = "assets/icon.svg"

    iconFontPath* = "assets/forkawesome-webfont.ttf"
    fonts* = [
      font("assets/Karla-Regular.ttf", 18f),
      font("assets/Karla-Bold.ttf", 16f),
      font("assets/forkawesome-webfont.ttf", 16f), # Sidebar icon font
    ]

    # AppImage
    ghRepo* = (user: "Patitotective", repo: "ImThemes").some
    appstreamPath* = ""

    # Window
    minSize* = (w: 700i32, h: 500i32) # < 0: don't care

