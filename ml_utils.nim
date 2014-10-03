import macros

template withFile* (f: expr, filename: string, mode: TFileMode,
                  body: stmt): stmt {.immediate.} =
  let fn = filename
  var f: TFile
  if open(f, fn, mode):
    try:
      body
    finally:
      close(f)
  else:
    quit("cannot open: " & fn)

