import math,tables,strutils,ml_utils,zipfiles,os    

type
    TTextFileType* = enum
        ftWindows,
        ftUnix

    PSyParam* =  ref TSyParam
    TSyParam* =  object of TObject
        Description* : string
        index* : int
        vmin* : int
        vmax* : int
        default* : int
        current* : int
        

    

    PSyPatch* = ref TSyPatch
    TSyPatch* = object of TObject
        Description*: string
        Version*: string
        Color*: string
        Params*: TTable[int,PSyParam]
        Percentage* : float
        Deviation*: float
        Genetic*: bool
        Impact* : int
        Directory* : string
        Patchset* : PPatchSet


    TPatchCode* = range[0..128]

    PPatchset* = ref TPatchset
    TPatchset* = object of TObject
        Name* : string
        Directory*  : string
        Percentage* : float
        Genetic* : bool
        Patches*: seq[PSyPatch]
        Impact*:  int
        FullRandom* : bool
        DefaultPatch* : PSyPatch
        MorphPatch*  : PSyPatch



var colors= ["cyan", "red", "green", "blue", "yellow", "magenta"]
var vow = ["a","e","i","o","u","y"]
var con = ["b","c","d","f","g","k","l","m","n","p","r","s","t","v","x","z"]

var TextFileType* : TTextFileType = ftWindows

proc newLine* () : string = 
    var s: string; s = if TextFileType == ftWindows:  "\r\n" else : "\n"
    result = s

## ---------------------------------------
## SyParam methods
## ---------------------------------------

proc initWithDefaultParam* (filename : string = "") : TTable[int,PSyParam] 

proc getColor* () : string =  "color=" & colors[random(colors.len)]
proc getVer*  () : string = "ver=108"

proc word* () : string = 
    var x = random(2)
    let lung = random(5)+3
    var s = ""
    var gu = ""
    for idx in 0..lung:
        if x mod 2 ==  0:
            gu =   if (idx mod 2 == 0):  vow[random(vow.len)] else: con[random(con.len)]
        else:
            gu =   if idx mod 2 == 0:  con[random(con.len)] else: vow[random(vow.len)]
        if (random(9) == 2):
            x = x +1
        s = s & gu
    gu =  if x mod 2 == 0 : toUpper(con[random(con.len)]) else : toUpper(vow[random(vow.len)])
    result = gu & s

proc newSyParam* (index: int, vmin: int, vmax: int, Description: string) : PSyParam = 
    var p = PSyParam (Description: description,
        Index:index, 
        VMin:vmin,
        Vmax:vmax,
        default : vmin,
        current : vmin)
    result = p

proc `$`* (p: PSyParam) : string = 
    result = "[" &  p.Description & "," & $(p.index) & "," &  $(p.vmin)  & "," & $(p.vmax) & "," & $(p.default) & "," & $(p.current) & "]"

proc randomizeParam* (p: PSyParam, genetic: bool = false) = 
    case p.index
    of 9: p.current = 0
    of 29: p.current = 100
    else:
        if p.vmax > 1:
            var d = p.vmax -p.vmin
            var h = p.vmin + random(d+1)
            p.current = h
        else:
            p.current = random(100) mod 2
    if genetic:
        p.default = p.current 
 
proc paramString* (p: PSyParam) : string =  $(p.index) & "," & $(p.current)

proc deviation* (p: PSyParam , percentage : float = 0.5,  genetic : bool = false)  =
    case p.index
    of 9: p.current = 0
    of 29: p.current = 100
    else:
        var res : int
        if (p.vmax > 4):
            var d = cast[int](percentage * cast[float](p.vmax-p.vmin))
            if (d < 1):
                d =1
            var rng = random(1+ d*2)-d
            if ((p.vmin + rng +p.default)  < p.vmin) or ((p.vmin+p.default+rng ) > p.vmax):
                res =  p.vmin +  p.default - rng
            else:
                res = p.vmin + p.default + rng
            p.current = res
        else:
            var v1: float = percentage*100.0
            var v2 = round(v1)
            if random(100) < v2:
                p.randomizeParam(genetic)
    if genetic:
        p.default = p.current


proc newSyPatch* (filename : string = "") : PSyPatch = 
    if (filename != ""):
        echo "Initializing with ",filename
        
    var p : PSyPatch
    new(p)
    p.Description = word()
    p.Version = getVer()
    p.Color =  getColor()
    p.Params = initWithDefaultParam( filename)
    p.Percentage = -1.0
    p.Genetic = false
    return p


proc generateRandomPatch* (p: PSyPatch) = 
    for k in p.Params.keys:
       var pa = p.Params[k]
       pa.randomizeParam(p.Genetic)

proc copyPatchValues* (p : PSyPatch, pDest : PSyPatch) = 
    for k in p.Params.Keys:
        var pa = p.Params[k]
        if (pDest.Params.hasKey(k)):
            pDest.Params[k].default = pa.default
            pDest.Params[k].current = pa.current
        


proc generateParametricPatch* (p: PSyPatch) = 
    if p.impact > 0:
        var s:seq[int]; s = @[]
        for k in p.Params.keys:
            s.add(k)
        shuffle(s)
        for w in 0..p.impact:
            var new_k = s[w]
            var pa = p.Params[new_k]
            # echo "Impacting", new_k
            pa.deviation(p.percentage)
    else:
        for k in p.Params.keys:
            var pa = p.Params[k]
            pa.deviation (p.percentage)

proc generatePatchText*(p: PSyPatch) : string =  
    var sbuf = p.Description & newLine()   & p.Color & newLine() & p.Version & newLine()
    for  k in p.Params.keys:
        var pa = p.Params[k]
        sbuf = sbuf & pa.paramString() & newLine()
    return sbuf
    

proc patchFileName * (i : int) : string = 
    var fp = $(i)
    case fp.len
    of 1: fp = "00" & fp
    of 2: fp = "0" & fp
    else:  fp  = fp
    return fp & ".sy1"
 

proc generatePatchFile* (p:PsyPatch, index: TPatchCode, )  : string {.discardable.} =  
    var fp = patchFileName(index)
    var fullPath = p.Directory & fp
    withFile(txt, fullPath, fmWrite):
        txt.write(p.generatePatchText)
    return fp

proc newPatchset* (filename : string = "") : PPatchset =
    var p : PPatchset 
    if (filename != ""):
        echo "Initializing patchset with ", filename
    new (p)
    p.directory = "." & os.DirSep
    p.percentage = 0.5
    p.genetic = false
    p.patches = @[]
    p.name = word()
    p.impact = -1
    p.DefaultPatch = newSyPatch(filename)
    for w in 0..128:
        var pa = newSyPatch()
        pa.PatchSet = p
        CopyPatchValues(p.DefaultPatch,pa)
        p.patches.add(pa)
    return p

proc `$`*(p:PPatchset) : string =
    result = p.Name & " (Dir: " & p.Directory & ", Perc:" & $(p.Percentage) & ", Genetic:" & $(p.Genetic) & ", Impact:" & $(p.Impact) & ", Fullrandom=" & $(p.Fullrandom) & ")"

        
proc createMorphing* (p: PPatchset, steps : int = 24) = 
    var s : seq[int] = @[]
    var dict = initTable[int, float]()
    var flSteps = toFloat(steps)
    var flVal : float
    var curDif : float
    var p1 : PSyParam
    var p2 : PSyParam
    ## var pDest = PSyPatch
    var k : int
    for k in p.DefaultPatch.Params.Keys:
        s.Add(k)
    for k in s:
        p1 = p.DefaultPatch.Params[k]
        if (p.MorphPatch.Params.HasKey(k)):
            p2 = p.MorphPatch.Params[k]
            curDif = toFloat(p2.Current - p1.Current)/24.0
            echo "curDif is ", curDif
            dict[k] = curDif
    for st in 0..steps+2:
        var pDest = p.Patches[st]
        for k in  dict.keys:
            if pDest.Params.HasKey(k):
                flVal = toFloat(p.DefaultPatch.Params[k].current) + dict[k]*toFloat(st)
                if (k == 60):
                    echo "flVal for k ",k ," is " , flVal
                pDest.Params[k].current = Math.round(flVal)
                
                

proc updateValues* (p: PPatchset)=
    for pa in p.patches:
        pa.directory = p.directory & os.DirSep
        pa.percentage = p.percentage
        pa.genetic = p.genetic
        pa.impact = p.impact
        pa.description = word()
        
proc generatePatches* (p: PPatchset) = 
    for l in 0..p.patches.len-1:
        var patch = p.patches[l]
        if (p.fullrandom):
            patch.generateRandomPatch()
        else:
            patch.generateParametricPatch()
        

proc generateZip* (p: PPatchset, filename : string) = 
    var z: TZipArchive
    var zipFileName =  p.directory &  os.DirSep & filename
    var fileToDelete : seq[string]
    
    fileToDelete = @[]
    echo "Creating zip in ", zipFileName
    if z.open (zipFileName, fmWrite):
        for l in 0..p.patches.len-1:
            var patch = p.patches[l]
            var fp = patch.generatePatchFile(l)
            z.addFile(fp,p.directory &  os.DirSep & fp)
            fileToDelete.add(p.directory &  os.DirSep & fp)
        z.close()
        for f in fileToDelete:
            removeFile(f)
            
    else:
        echo "Error creating zip file ", zipFileName

##### IMPLEMENTATION ##########################

const DEFAULT_DATA* = """METAL GTR
jcolor=magenta
ver=112
0,1
45,0
76,5
1,3
2,39
3,8
4,1
5,40
6,1
7,1
8,89
9,0
10,0
11,123
12,50
13,77
71,2
72,78
91,0
95,0
96,1
97,1
14,2
15,49
16,35
17,59
18,82
19,72
20,70
21,68
22,95
23,119
24,0
25,23
26,105
27,100
28,71
29,75
30,11
59,0
31,4
32,1
33,12
34,54
65,0
82,0
35,9
83,105
36,105
98,64
37,38
66,0
64,1
52,100
53,110
54,10
55,122
56,90
60,83
61,72
62,46
63,46
90,77
77,0
78,1
79,40
80,70
81,45
38,0
94,16
39,40
74,0
73,0
93,4
75,127
84,4
85,2
92,0
40,2
86,45057
50,64
87,44
88,45057
51,91
89,43
57,0
41,3
42,0
43,50
44,125
67,0
68,0
58,0
46,6
47,1
48,67
49,112
69,0
70,0"""


proc initWithDefaultParam* (filename : string = "") : TTable[int,PSyParam]  = 
    var dict = initTable[int, PSyParam]()
    dict[0] = newSyParam ( Index=0, VMin=0, Vmax=3, Description="OSCILLATOR 1 WAVE" )
    dict[45] = newSyParam ( Index=45, VMin=0, Vmax=127, Description="FM" )
    dict[76] = newSyParam ( Index=76, VMin=0, Vmax=127, Description="DETUNE" )
    dict[1] = newSyParam ( Index=1, VMin=1, Vmax=4, Description="OSCILLATOR 2 WAVE" )
    dict[2] = newSyParam ( Index=2, VMin=0, Vmax=127, Description="PITCH" )
    dict[3] = newSyParam ( Index=3, VMin=0, Vmax=127, Description="FINE" )
    dict[4] = newSyParam ( Index=4, VMin=0, Vmax=1, Description="TRACK" )
    dict[5] = newSyParam ( Index=5, VMin=0, Vmax=127, Description="MIX" )
    dict[6] = newSyParam ( Index=6, VMin=0, Vmax=1, Description="SYNC" )
    dict[7] = newSyParam ( Index=7, VMin=0, Vmax=1, Description="RING" )
    dict[8] = newSyParam ( Index=8, VMin=0, Vmax=127, Description="PW" )
    dict[9] = newSyParam ( Index=9,  VMin= -24, Vmax=24, Description="TRANSPOSE" )
    dict[10] = newSyParam ( Index=10, VMin=0, Vmax=1, Description="M. ENV SWITCH" )
    dict[11] = newSyParam ( Index=11, VMin=0, Vmax=127, Description="AMOUNT" )
    dict[12] = newSyParam ( Index=12, VMin=0, Vmax=127, Description="ATTACK" )
    dict[13] = newSyParam ( Index=13, VMin=0, Vmax=127, Description="DECAY" )
    dict[71] = newSyParam ( Index=71, VMin=0, Vmax=2, Description="DEST" )
    dict[72] = newSyParam ( Index=72, VMin=0, Vmax=127, Description="TUNE" )
    dict[14] = newSyParam ( Index=14, VMin=0, Vmax=3, Description="FILTER TYPE" )
    dict[15] = newSyParam ( Index=15, VMin=0, Vmax=127, Description="ATTACK" )
    dict[16] = newSyParam ( Index=16, VMin=0, Vmax=127, Description="DECAY" )
    dict[17] = newSyParam ( Index=17, VMin=0, Vmax=127, Description="SUSTAIN" )
    dict[18] = newSyParam ( Index=18, VMin=0, Vmax=127, Description="RELEASE" )
    dict[19] = newSyParam ( Index=19, VMin=0, Vmax=127, Description="FREQUENCY" )
    dict[20] = newSyParam ( Index=20, VMin=0, Vmax=127, Description="RESONANCE" )
    dict[21] = newSyParam ( Index=21, VMin=0, Vmax=127, Description="AMOUNT" )
    dict[22] = newSyParam ( Index=22, VMin=0, Vmax=127, Description="TRACK" )
    dict[23] = newSyParam ( Index=23, VMin=0, Vmax=127, Description="SATURATION" )
    dict[24] = newSyParam ( Index=24, VMin=0, Vmax=1, Description="VELOCITY AMOUNT" )
    dict[25] = newSyParam ( Index=25, VMin=0, Vmax=127, Description="ATTACK" )
    dict[26] = newSyParam ( Index=26, VMin=0, Vmax=127, Description="DECAY" )
    dict[27] = newSyParam ( Index=27, VMin=0, Vmax=127, Description="SUSTAIN" )
    dict[28] = newSyParam ( Index=28, VMin=0, Vmax=127, Description="RELEASE" )
    dict[29] = newSyParam ( Index=29, VMin=0, Vmax=127, Description="GAIN" )
    dict[30] = newSyParam ( Index=30, VMin=0, Vmax=127, Description="VELOCITY AMOUNT" )
    dict[59] = newSyParam ( Index=59, VMin=0, Vmax=1, Description="ARP SWITCH" )
    dict[31] = newSyParam ( Index=31, VMin=1, Vmax=4, Description="TYPE" )
    dict[32] = newSyParam ( Index=32, VMin=0, Vmax=3, Description="RANGE" )
    dict[33] = newSyParam ( Index=33, VMin=0, Vmax=18, Description="BEAT" )
    dict[34] = newSyParam ( Index=34, VMin=5, Vmax=127, Description="GATE" )
    dict[65] = newSyParam ( Index=65, VMin=0, Vmax=1, Description="DELAY SWITCH" )
    dict[82] = newSyParam ( Index=82, VMin=0, Vmax=2, Description="TYPE" )
    dict[35] = newSyParam ( Index=35, VMin=0, Vmax=19, Description="TIME" )
    dict[83] = newSyParam ( Index=83, VMin=0, Vmax=127, Description="SPREAD" )
    dict[36] = newSyParam ( Index=36, VMin=1, Vmax=120, Description="FEEDBACK" )
    dict[37] = newSyParam ( Index=37, VMin=0, Vmax=127, Description="DRY/WET" )
    dict[66] = newSyParam ( Index=66, VMin=0, Vmax=1, Description="CHORUS SWITCH" )
    dict[64] = newSyParam ( Index=64, VMin=1, Vmax=4, Description="TYPE" )
    dict[52] = newSyParam ( Index=52, VMin=0, Vmax=127, Description="TIME" )
    dict[53] = newSyParam ( Index=53, VMin=0, Vmax=127, Description="DEPTH" )
    dict[54] = newSyParam ( Index=54, VMin=0, Vmax=127, Description="RATE" )
    dict[55] = newSyParam ( Index=55, VMin=0, Vmax=127, Description="FEEDBACK" )
    dict[56] = newSyParam ( Index=56, VMin=0, Vmax=127, Description="LEVEL" )
    dict[60] = newSyParam ( Index=60, VMin=0, Vmax=127, Description="EQ TONE" )
    dict[61] = newSyParam ( Index=61, VMin=0, Vmax=127, Description="FREQUENCY" )
    dict[62] = newSyParam ( Index=62, VMin=0, Vmax=127, Description="LEVEL" )
    dict[63] = newSyParam ( Index=63, VMin=0, Vmax=127, Description="Q" )
    dict[90] = newSyParam ( Index=90, VMin=32, Vmax=96, Description="L-R" )
    dict[77] = newSyParam ( Index=77, VMin=0, Vmax=1, Description="EFFECT SWITCH" )
    dict[78] = newSyParam ( Index=78, VMin=0, Vmax=9, Description="TYPE" )
    dict[79] = newSyParam ( Index=79, VMin=0, Vmax=127, Description="CTRL1" )
    dict[80] = newSyParam ( Index=80, VMin=0, Vmax=127, Description="CTRL2" )
    dict[81] = newSyParam ( Index=81, VMin=0, Vmax=127, Description="LEVEL" )
    dict[38] = newSyParam ( Index=38, VMin=0, Vmax=2, Description="PLAY MODE" )
    dict[39] = newSyParam ( Index=39, VMin=0, Vmax=127, Description="PORTAMENTO" )
    dict[74] = newSyParam ( Index=74, VMin=0, Vmax=1, Description="AUTO" )
    dict[40] = newSyParam ( Index=40, VMin=0, Vmax=24, Description="PB RANGE" )
    dict[73] = newSyParam ( Index=73, VMin=0, Vmax=1, Description="UNISON" )
    dict[75] = newSyParam ( Index=75, VMin=0, Vmax=127, Description="DETUNE" )
    dict[84] = newSyParam ( Index=84, VMin=0, Vmax=127, Description="SPREAD" )
    dict[85] = newSyParam ( Index=85, VMin=0, Vmax=48, Description="PITCH" )
    dict[50] = newSyParam ( Index=50, VMin=0, Vmax=127, Description="LFO1 WHEEL SENS" )
    dict[51] = newSyParam ( Index=51, VMin=0, Vmax=127, Description="SPEED" )
    dict[57] = newSyParam ( Index=57, VMin=0, Vmax=1, Description="LFO1 SWITCH" )
    dict[41] = newSyParam ( Index=41, VMin=1, Vmax=7, Description="DEST" )
    dict[42] = newSyParam ( Index=42, VMin=0, Vmax=4, Description="WAVEFORM" )
    dict[43] = newSyParam ( Index=43, VMin=0, Vmax=127, Description="SPEED" )
    dict[44] = newSyParam ( Index=44, VMin=0, Vmax=127, Description="AMOUNT" )
    dict[67] = newSyParam ( Index=67, VMin=0, Vmax=1, Description="TEMPO SYNC" )
    dict[68] = newSyParam ( Index=68, VMin=0, Vmax=1, Description="KEY SYNC" )
    dict[58] = newSyParam ( Index=58, VMin=0, Vmax=1, Description="LFO2 SWITCH" )
    dict[46] = newSyParam ( Index=46, VMin=1, Vmax=7, Description="DEST" )
    dict[47] = newSyParam ( Index=47, VMin=0, Vmax=4, Description="WAVEFORM" )
    dict[48] = newSyParam ( Index=48, VMin=0, Vmax=127, Description="SPEED" )
    dict[49] = newSyParam ( Index=49, VMin=0, Vmax=127, Description="AMOUNT" )
    dict[69] = newSyParam ( Index=69, VMin=0, Vmax=1, Description="TEMPO SYNC" )
    dict[70] = newSyParam ( Index=70, VMin=0, Vmax=1, Description="KEY SYNC" )
   
    if (filename != ""):
        try:
            var sData = ""
            echo ("Initializing with " & filename)
            withFile (txt,filename, fmRead):
                sData = txt.readAll()
                #echo("Read all data ")
                var sy_lines = splitLines(sData)
                #echo("Split lines")
                for h in 3..sy_lines.len-1:
                    #echo "Reading... ", h
                    block protection:
                        var line = strip(sy_lines[h])
                        try:
                            echo "Line: ", line
                            var tokens = line.split(',')
                            #echo "Tokens: ", tokens
                            if tokens.len > 0:
                                var i_key = parseInt(tokens[0])
                                var i_value = parseInt(tokens[1])
                                echo "Setting value ", i_value, " to key ", i_key
                                if dict.hasKey(i_key):
                                    dict[i_key].default = i_value; dict[i_key].current = i_value
                        except:
                            echo "Error reading line: ", line
        except:
            let
                e = getCurrentException()
                m = getCurrentExceptionMsg()
            echo "Error reading from file ", repr(e), "\nMessage: ",m,"\n----------------------------\n"
        
    else:
        var sy_lines = splitLines(DEFAULT_DATA)
        for h in 3..sy_lines.len-1:
            var line = strip(sy_lines[h])
            try:
                var tokens = line.split(',')
                var i_key = parseInt(tokens[0])
                var i_value = parseInt(tokens[1])
                if dict.hasKey(i_key):
                    dict[i_key].default = i_value; dict[i_key].current = i_value

            except  EInvalidIndex:
                    echo "Error reading default data:\n",repr(getCurrentException())

    result =  dict


var defaultParams* = initWithDefaultParam()

