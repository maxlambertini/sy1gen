import macros, math

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


proc shuffle* [T] (x: var seq[T]) =
  for i in countdown(x.high, 0):
    let j = random(i + 1)
    swap(x[i], x[j])
