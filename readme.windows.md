Compiling sy1gen for windows
----------------------------

These warnings hold true for my machine, a Win7-32 bit laptop running Nimrod 0.9.4. YMMV. 

Since sy1gen includes libzip for windows, you're bound to stumble into compilation errors if you don't fix these things:

1. In the directory <nimrod_inst>\lib\wrappers\lib\ you must edit libzip_all.c to make it compile under Windows:

Go to line 1112 and find these two lines:

    torrenttime.tm_gmtoff = l->tm_gmtoff;
    torrenttime.tm_zone = l->tm_zone;
    
To avoid compilation error, wrap them in a couple of ifndefs

    #ifndef __MINGW32__
    #ifndef __MINGW64__
    torrenttime.tm_gmtoff = l->tm_gmtoff;
    torrenttime.tm_zone = l->tm_zone;
    #endif
    #endif

This way, libzip_all.c will be correctly compiled. 

2. the function `mkstemp` is not defined under Windows. In `libzip_all.c` you must go to line 2126 and change the occurrence of `mkstemp` to `_zip_mkstemp`

3. In `sy1gen.nim`, change the path in the passL pragma with the appropriate one for your machine `<nimrod_inst_dir>/dist/mingw/i686-w64-mingw32/lib` if you compile for Win32

4. In `<nimrod_inst_dir>\dist\mingw\i686-w64-mingw32\include`  open `zconf.h`, go to line 368 and place a colon ( ; ) before *typedef*. 

*now* you can compile sy1gen by running: `nim c sygen1.nim`




