import sy1_structs, tables,math, parseOpt2, strutils

when defined(windows):
    {.passL: "-LC:/opt/nim32/dist/mingw/i686-w64-mingw32/lib -lz".}

randomize()

var p = newPatchset()             # patch
var directory = "./"              # default output directory (--directory, -d )
var percentage =  0.5             # deviation from current value (--percentage, -p)
var genetic = false               # set result as new default (--genetic, -g)
var fullrandom = false            # randomization or parametric (--fullrandom -f)
var impact = -1                   # number of parameters to process, -1 all (--impact, -i)
var name =  word()                # patchset name (--name, -n)

proc usage() =
    var sOut : string = """
sy1 -- a Synth1 Patch Generator

usage: sy1 [--directory:dir|-d:dir] [--percentage:<float>| -p float] [--genetic | -g] [--fullrandom | -f] [--impact:<int>| -i int] [--name:filename | -n filename] [--help | -h] filename

-- directory, -d : sets up output directory. Default: current directory
-- percentage, p : it's a float value between 0.0 and 1.0. Default is 0.5. 
                   It represents random deviation from param's current value. 
                   Ignored when -f or --full random are specified
-- genetic, -g   : if specified, sets up 'genetic': the new value
                   of patch becomes its new default, so when generating new 
                   patches the default is used as a reference. Ignored when
                   fullrandom is specified
--impact, -i     : an integer that defines the number of parameter that must
                   be modified. Useful to trigger partial modifications. When
                   used with --genetic and a low --percentage (say 0.2) can 
                   create "morphing" patchsets.
--fullrandom, -f : create a fully randomized patchset
--textFile, -t   : 0=windows, 1= linux. Default 0
--help, -h       : shows this help


"""
    echo sOut


try:
    var optParse = initOptParser()
    var showHelp = false
    for kind, key, val  in getOpt():
        case kind
        of cmdArgument:
            name = key
        of cmdLongOption, cmdShortOption:
            case key:
            of "help","h" : usage(); showHelp = true
            of "directory", "d" :   directory = val
            of "percentage", "p" :  percentage = parseFloat(val)
            of "genetic", "g" : genetic =  true
            of "fullrandom","f" : fullrandom =  true
            of "name","n" : name = val
            of "impact","i" : impact = parseInt(val)
            of "textFile", "t" :  TextFileType = if val == "1" : ftUnix else: ftWindows
        of cmdEnd : assert(false)
        else: assert(false)

    if not showHelp:
        p.name = name
        p.impact = impact
        p.directory = directory
        p.genetic = genetic
        p.fullrandom = fullrandom
        p.impact = impact
        p.percentage = percentage

        p.updateValues()
        echo "Generating patchset:\n",p,"\n\n"
        p.generateZip(name & ".zip")
        echo "\n\nThat's all!"
except:
    let
        e = getCurrentException()
        m = getCurrentExceptionMsg()
    echo "Error: ", repr(e), "\nMessage: ",m,"\n----------------------------\n"
    usage()



