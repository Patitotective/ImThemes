switch("backend", "cpp")
switch("warning", "HoleEnumConv:off")
when defined(Windows):
  switch("passC", "-static")
  switch("passL", "-static")
