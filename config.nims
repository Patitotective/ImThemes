switch("define", "ssl")
switch("backend", "cpp")
switch("warning", "HoleEnumConv:off")
switch("warning", "ImplicitDefaultValue:off")
switch("deepcopy", "on")

when defined(Windows):
  switch("passC", "-static")
  switch("passL", "-static")
